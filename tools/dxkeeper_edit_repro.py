#!/usr/bin/env python3
"""
DXKeeper "edit a QSO" harness  (TR4W Issue #957)
================================================

Standalone driver for DXKeeper's TCP/IP Network Service. No TR4W required --
this speaks DXKeeper's protocol directly so the edit-a-QSO behavior can be
reproduced and verified independently of TR4W.

Sequence:

  STEP 1  Log a contact for W7SPA           (externallog, MODE = CW)
  STEP 2  Wait (default 10 s)               (operator reviews the QSO)
  STEP 3  Edit it: deleteqso, then re-log    <-- TR4W's edit mechanism deletes
          the contact with ONE field             the old record and re-logs the
          changed (MODE CW -> FT8)                edited one

Why connection handling matters (Issue #957)
--------------------------------------------
Tracing showed DXKeeper reads exactly ONE command per TCP connection, processes
it, and then CLOSES the connection -- discarding anything else already in the
read buffer. So if a client sends `deleteqso` immediately followed by
`externallog` on the same connection, the two coalesce into one TCP segment;
DXKeeper runs the delete and silently drops the trailing re-log.

DEFAULT (works): each command is sent on its OWN fresh connection, waiting for
DXKeeper to close after each (which confirms it was processed). The delete and
the re-log therefore never share a connection, so both take effect.

--single-connection (reproduces the bug): send the delete and the re-log
back-to-back on one connection -- DXKeeper logs the delete and drops the re-log.

Message format matches TR4W (uExternalLogger.pas), per the DXKeeper TCP/IP
Messages v5 spec:
  externallog : <command:11>externallog<parameters:N><ExternalLogADIF:M>...<EOR><options>
  deleteqso   : <command:9>deleteqso<parameters:N><CALL..><QSO_DATE..><TIME_ON..><EOR>
deleteqso matches the logged QSO by CALL + QSO_DATE + TIME_ON, so all three
messages share one fixed date/time stamped at start.

DXKeeper listens on the 2nd port of its block: default base 52000 -> 52001.
(Change the base in DXKeeper's Configuration > Defaults > Network Service.)

Usage:
  python dxkeeper_edit_repro.py                    # default: edit succeeds (one connection per command)
  python dxkeeper_edit_repro.py --single-connection  # reproduce the bug (re-log dropped)
  python dxkeeper_edit_repro.py --host 192.168.1.50 --port 52001 --station AA6YQ

Python 3, standard library only.
"""

import argparse
import socket
import threading
import time
from datetime import datetime, timezone

# TR4W sends each message via Indy's WriteLn, which appends a line break. The
# protocol is self-delimiting (every field carries its own length), so this is
# cosmetic -- included only to match TR4W's bytes on the wire.
TERMINATOR = "\r\n"

# Option flags TR4W currently sends with externallog. Enrichment + membership
# lookups ON; QSL-server uploads OFF (so there is time to edit before upload).
OPTIONS = (
    "<DeduceMissing:1>Y<QueryCallbook:1>Y<CheckOverrides:1>Y"
    "<UpdateeQSL:1>Y<UpdateLoTW:1>Y"
    "<UploadeQSL:1>N<UploadLoTW:1>N<UploadClubLog:1>N<UploadQRZ:1>N"
)


def ts():
    return datetime.now().strftime("%H:%M:%S.%f")[:-3]


def log(msg):
    print("[%s] %s" % (ts(), msg), flush=True)


def adif(field, value):
    """One ADIF field: <FIELD:len>value (length is the character count of value)."""
    return "<%s:%d>%s" % (field, len(value), value)


def build_core_adif(call, rst_s, rst_r, freq, band, mode, qso_date, time_on, station):
    return (
        adif("CALL", call)
        + adif("RST_SENT", rst_s)
        + adif("RST_RCVD", rst_r)
        + adif("FREQ", freq)
        + adif("BAND", band)
        + adif("MODE", mode)
        + adif("QSO_DATE", qso_date)
        + adif("TIME_ON", time_on)
        + adif("STATION_CALLSIGN", station)
        + "<EOR>"
    )


def build_externallog(core_adif, options):
    # <parameters:N> = length of everything from the ExternalLogADIF field onward
    # (the wrapped ADIF record + the option fields), per the v5 spec.
    ext_field = adif("ExternalLogADIF", core_adif)
    params = ext_field + options
    return "<command:11>externallog<parameters:%d>%s" % (len(params), params)


def build_deleteqso(call, qso_date, time_on):
    core = (
        adif("CALL", call)
        + adif("QSO_DATE", qso_date)
        + adif("TIME_ON", time_on)
        + "<EOR>"
    )
    return "<command:9>deleteqso<parameters:%d>%s" % (len(core), core)


class DXKeeperClient:
    """Talks to DXKeeper's Network Service.

    A single background reader prints whatever DXKeeper sends back and notices
    when DXKeeper closes the connection (recv returns 0). It tolerates the
    socket being replaced on reconnect.
    """

    def __init__(self, host, port):
        self.host = host
        self.port = port
        self.sock = None
        self.peer_closed = False
        self.stop = threading.Event()
        self.reader_thread = None

    def connect(self, attempts=5, delay=1.0):
        """Open a fresh connection, retrying if DXKeeper is not yet ready."""
        self._close_socket()
        last = None
        for i in range(1, attempts + 1):
            try:
                s = socket.create_connection((self.host, self.port), timeout=10)
                s.settimeout(0.5)
                self.peer_closed = False
                self.sock = s
                log("Connected to %s:%d" % (self.host, self.port))
                if self.reader_thread is None:
                    self.reader_thread = threading.Thread(target=self._reader, daemon=True)
                    self.reader_thread.start()
                return
            except OSError as e:
                last = e
                log("  connect failed (attempt %d/%d): %s -- retrying in %.1f s"
                    % (i, attempts, e, delay))
                time.sleep(delay)
        raise SystemExit("Could not connect to DXKeeper at %s:%d (%s). "
                         "Is DXKeeper running with the Network Service enabled?"
                         % (self.host, self.port, last))

    def _close_socket(self):
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
            self.sock = None

    def _reader(self):
        while not self.stop.is_set():
            s = self.sock
            if s is None:
                time.sleep(0.05)
                continue
            try:
                data = s.recv(4096)
            except socket.timeout:
                continue
            except OSError:
                time.sleep(0.05)
                continue
            if not data:
                # recv of 0 bytes => DXKeeper performed an orderly close.
                if s is self.sock and not self.peer_closed:
                    log("<< DXKeeper closed the connection")
                    self.peer_closed = True
                time.sleep(0.05)
                continue
            log("<< RESPONSE: " + data.decode("latin-1", "replace").strip())

    def _raw_send(self, label, msg):
        log(">> %s" % label)
        log("   %s" % msg)
        if self.sock is None:
            log("   !! no socket; cannot send")
            return
        try:
            self.sock.sendall((msg + TERMINATOR).encode("latin-1"))
        except OSError as e:
            log("   !! send failed: %s" % e)

    def wait_for_close(self, timeout=5.0):
        """Block until DXKeeper closes the connection (it does so after processing
        one command), or until timeout. Returns True if it closed."""
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.peer_closed:
                return True
            time.sleep(0.02)
        return False

    def send_command(self, label, msg, new_connection=True, wait_close=True, timeout=5.0):
        """Send one command. By default on its own fresh connection -- which is
        how DXKeeper expects it (one command per connection)."""
        if new_connection or self.sock is None or self.peer_closed:
            self.connect()
        self._raw_send(label, msg)
        if wait_close:
            if self.wait_for_close(timeout):
                log("   (DXKeeper closed after this command -- processed)")
            else:
                log("   (no close within %.1f s; continuing)" % timeout)

    def close(self):
        self.stop.set()
        self._close_socket()


def main():
    ap = argparse.ArgumentParser(
        description="Drive DXKeeper's edit-a-QSO sequence (TR4W Issue #957).")
    ap.add_argument("--host", default="127.0.0.1",
                    help="DXKeeper host (default 127.0.0.1)")
    ap.add_argument("--port", type=int, default=52001,
                    help="DXKeeper Network Service port (default 52001 = base 52000 + 1)")
    ap.add_argument("--call", default="W7SPA",
                    help="Worked station callsign (default W7SPA)")
    ap.add_argument("--station", default="NY4I",
                    help="STATION_CALLSIGN -- the logging station (default NY4I; set to your call)")
    ap.add_argument("--freq", default="14.074",
                    help="Frequency in MHz, unchanged across the edit (default 14.074)")
    ap.add_argument("--band", default="20M",
                    help="Band, unchanged across the edit (default 20M)")
    ap.add_argument("--wait", type=float, default=10.0,
                    help="Seconds to wait after logging before the edit (default 10)")
    ap.add_argument("--gap", type=float, default=0.0,
                    help="Extra seconds between the deleteqso and the re-log "
                         "(default 0; not needed in the default one-connection-per-command mode)")
    ap.add_argument("--single-connection", action="store_true",
                    help="Send the delete and re-log back-to-back on ONE connection "
                         "to reproduce the bug (DXKeeper drops the re-log).")
    args = ap.parse_args()

    # Fixed QSO identity: deleteqso matches the create by CALL + QSO_DATE + TIME_ON,
    # so the create, delete, and re-log must all carry the same date/time.
    now = datetime.now(timezone.utc)
    qso_date = now.strftime("%Y%m%d")
    time_on = now.strftime("%H%M%S")

    core_cw = build_core_adif(args.call, "599", "599", args.freq, args.band,
                              "CW", qso_date, time_on, args.station)
    core_ft8 = build_core_adif(args.call, "599", "599", args.freq, args.band,
                               "FT8", qso_date, time_on, args.station)

    create = build_externallog(core_cw, OPTIONS)
    delete = build_deleteqso(args.call, qso_date, time_on)
    recreate = build_externallog(core_ft8, OPTIONS)

    mode = "SINGLE CONNECTION (reproduce bug)" if args.single_connection \
        else "one connection per command (edit should succeed)"
    log("Mode: %s" % mode)

    client = DXKeeperClient(args.host, args.port)
    try:
        log("STEP 1: log QSO  call=%s  MODE=CW  QSO_DATE=%s  TIME_ON=%s"
            % (args.call, qso_date, time_on))
        client.send_command("externallog (create, MODE=CW)", create)

        log("STEP 2: waiting %.0f s (operator reviews the QSO)..." % args.wait)
        time.sleep(args.wait)

        log("STEP 3: edit -> deleteqso, then re-log with MODE CW -> FT8")
        if args.single_connection:
            # Both on one connection, back-to-back -> reproduces the drop.
            client.send_command("deleteqso", delete, new_connection=True, wait_close=False)
            if args.gap > 0:
                time.sleep(args.gap)
            client.send_command("externallog (re-log, MODE=FT8)", recreate,
                                new_connection=False, wait_close=False)
        else:
            # Each on its own fresh connection -> both take effect.
            client.send_command("deleteqso", delete)
            if args.gap > 0:
                time.sleep(args.gap)
            client.send_command("externallog (re-log, MODE=FT8)", recreate)

        log("Done sending. Listening 3 s for any final responses...")
        time.sleep(3)
    finally:
        client.close()
        log("Closed. Done.")


if __name__ == "__main__":
    main()
