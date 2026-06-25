unit uRadioIcomBase;

{
  Icom Radio Base Class with CI-V Protocol Support

  Implements the Icom CI-V (Computer Interface V) protocol for Icom transceivers.

  CI-V Frame Format:
    FE FE [To Address] [From Address] [Command] [Sub-command/Data] FD

  Where:
    FE FE = Preamble
    To Address = Radio address (e.g., 0x94 for IC-7300)
    From Address = Controller address (usually 0xE0)
    Command = Command byte
    Sub-command/Data = Optional data bytes
    FD = End of message

  Common Commands:
    0x03 = Read operating frequency
    0x04 = Read operating mode
    0x05 = Set operating frequency
    0x06 = Set operating mode
    0x07 = Read/Set VFO mode (Main/Sub)
    0x14 = Read/Set various levels
    0x15 = Read/Set meter
    0x1C = TX/RX control

  Usage:
    Create derived classes (e.g., TIcom7300Radio) that set the radioAddress
    and override any radio-specific behavior.
}

interface

uses
  Windows, uNetRadioBase, uRadioBand, uIcomNetworkTransport, uIcomNetworkTypes, SysUtils, StrUtils, VC, Log4D,
  uIcomCIV, Classes, SyncObjs;

type
  TIcomRadio = class; // forward — TCIVSendThread holds a back-reference

  TCIVPriority = (civpNormal, civpUrgent);

  // Serializes all outbound CI-V commands through a single thread with a minimum
  // inter-command delay. Prevents any combination of callers (poll, user actions,
  // transceive follow-ups) from flooding the radio's CI-V input buffer.
  TCIVSendThread = class(TThread)
  private
    FOwner: TIcomRadio;
    FNormalQueue: TStringList;   // FIFO — index 0 is head
    FUrgentQueue: TStringList;   // Drained before normal queue
    FLock: TCriticalSection;
    FHasWork: TEvent;            // Auto-reset; signaled on each Enqueue call
    procedure DrainQueues;
  public
    constructor Create(AOwner: TIcomRadio);
    destructor Destroy; override;
    procedure Execute; override;
    procedure Enqueue(const cmd: string; priority: TCIVPriority = civpNormal);
    procedure Stop;
  end;

  TIcomRadio = class(TNetRadioBase)
  private
    FRadioAddress: Byte;          // CI-V address of radio (e.g., 0x94 for IC-7300)
    FControllerAddress: Byte;     // CI-V address of controller (usually 0xE0)
    FCIVBuffer: string;           // Buffer for accumulating CI-V frames
    FCWBuffer: string;            // Buffer for CW text to send

    // Network transport (Icom UDP protocol)
    FNetworkTransport: TIcomNetworkTransport;
    FNetworkUsername: string;
    FNetworkPassword: string;

    // CI-V send queue — serializes outbound commands with inter-command spacing
    FCIVSendThread: TCIVSendThread;

    // Band memory: remembers last frequency per band (like TR4QT)
    FBandMemory: array[TRadioBand] of LongInt;
    FTransceiveChecked: Boolean;  // True after we've queried and logged the transceive state once
    FVFOQueryPending: Boolean;    // True while $25 $00/$01 query pair is in flight; prevents flooding
    FVFOQuerySentTick: DWORD;    // GetTickCount when query was sent; used to expire FVFOQueryPending
    FLastBaseMode: TRadioMode;    // Base mode before data mode overlay (restored when data mode goes off)
    FActiveVFO: TVFO;             // Which VFO is currently active (main); updated via $07 $D2 query/push
    FInitialQueryPending: Boolean; // True after $19 sent; triggers $03/$04 on $19 response
    FFirstMessage: Boolean;        // True until first valid frame received; triggers initial VFO/mode queries
    FPollPhase: Integer;            // Rotates through query groups to avoid flooding radio
    FLastSetCWSpeedTick: DWORD;   // GetTickCount at last SetCWSpeed call — suppresses stale echoes
    FDataModeID: Byte;            // Icom data sub-mode: $01=D1 (default), $02=D2, $03=D3 — configurable via RADIO x ICOM DATA MODE ID

    // Actual UDP send — only called by TCIVSendThread.DrainQueues
    procedure DoSendDirect(const s: string);


    procedure ProcessCIVMessage(msg: string);
    procedure ProcessNetworkCivData(msg: string);
    procedure OnNetworkStateChange(Sender: TObject);

  protected
    FTransceiveMenuBytes: string;  // 2-byte menu item for CI-V transceive query (radio-specific)
    FSupportsExtendedVFOBCommands: Boolean;  // True if radio supports $25/$26 direct VFO B set (almost all modern Icoms)
    FSupportsActiveVFOQuery: Boolean;        // True if radio supports $07 $D2 to read which VFO is active (e.g. IC-7760)
    FDirectFreqRoute: Boolean;               // True → $00 transceive routed directly to FActiveVFO (no round-trip $25 query)
                                             //   Use for radios where $07 $D2 is unreliable but $00 always reflects active VFO
                                             //   (e.g. IC-9700). Overrides FSupportsExtendedVFOBCommands path in $00 handler.
    FMainBandProcessingOnly: Boolean;        // True → radio only supports $25/$26 for MAIN band (IC-9700, IC-9100).
                                             //   In satellite mode these radios return FA (NG) for $25; demotes that
                                             //   NAK log from Warn to Debug so it does not spam the log.
    FActiveVFOInverted: Boolean;             // True → $07 $D2 response byte semantics are inverted:
                                             //   $00 = VFO B active, $01 = VFO A active (IC-9700).
                                             //   IC-7610/IC-7760 use $00 = VFO A active (default False).
    // Frequency BCD helpers — delegate to standalone functions in uIcomCIV
    function BuildCIVCommand(command: Byte; data: string): string;
    function FreqToBCD(freq: LongInt): string;
    function BCDToFreq(bcd: string): LongInt;
    procedure ProcessCIVFrame(frame: string); virtual;
    function GetIsConnected: boolean; override;
    function GetIsOperational: boolean; override;             // Strict: true only when handshake fully complete
    function GetCanRecycleOnStuckHandshake: boolean; override; // True for network -- fresh AYH is the recovery
    function GetAuthFailed: boolean; override;
    function IsNetworkConnection: boolean;
    function SupportsDataMode: Boolean; virtual;  // Override to True on radios that support $1A $06

  public
    constructor Create; reintroduce;
    destructor Destroy; override;
    procedure ProcessMsg(msg: string); override;
    function Connect: integer; override;
    procedure Disconnect; override;
    procedure SendToRadio(s: string); overload; override;
    procedure SendToRadioUrgent(const s: string);  // Bypasses normal queue order (PTT, CW stop)

    // Polling interface implementation
    procedure QueryVFOAFrequency; override;
    procedure QueryVFOBFrequency; override;
    procedure QueryVFOAMode;              // $26 $00 — VFO A mode (when VFO B is active)
    procedure QueryVFOBMode; override;    // $26 $01 — VFO B mode
    procedure QueryActiveVFO; override;   // $07 $D2 — which VFO is active (if FSupportsActiveVFOQuery)
    procedure QueryMode; override;
    procedure QueryTXStatus; override;
    procedure QueryRITState; override;
    procedure QueryXITState; override;
    procedure QueryBand; override;
    procedure QuerySplitState; override;
    procedure PollRadioState; override;

    // Radio control methods
    procedure Transmit; override;
    procedure Receive; override;
    procedure BufferCW(cwChars: string); override;
    procedure SendCW; override;
    procedure StopCW; override;
    procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;
    procedure SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA); override;
    function  ToggleMode(vfo: TVFO = nrVFOA): TRadioMode; override;
    procedure SetCWSpeed(speed: integer); override;
    procedure RITClear(whichVFO: TVFO); override;
    procedure XITClear(whichVFO: TVFO); override;
    procedure RITBumpDown; override;
    procedure RITBumpUp; override;
    procedure RITOn(vfo: TVFO); override;
    procedure RITOff(vfo: TVFO); override;
    procedure XITOn(vfo: TVFO); override;
    procedure XITOff(vfo: TVFO); override;
    procedure Split(splitOn: boolean); override;
    procedure SetRITFreq(vfo: TVFO; hz: integer); override;
    procedure SetXITFreq(vfo: TVFO; hz: integer); override;
    procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); override;
    function  ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
    procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); override;
    procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload; override;
    function  MemoryKeyer(mem: integer): boolean; override;
    function  SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer; override;
    procedure VFOBumpDown(whichVFO: TVFO); override;
    procedure VFOBumpUp(whichVFO: TVFO); override;

    property RadioAddress: Byte read FRadioAddress write FRadioAddress;
    property ControllerAddress: Byte read FControllerAddress write FControllerAddress;
    property NetworkUsername: string read FNetworkUsername write FNetworkUsername;
    property NetworkPassword: string read FNetworkPassword write FNetworkPassword;
    property DataModeID: Byte read FDataModeID write FDataModeID;
    property NetworkTransport: TIcomNetworkTransport read FNetworkTransport;
  end;

implementation

var
  logger: TLogLogger;

// CI-V send queue tuning
const
  CIV_INTER_COMMAND_DELAY_MS = 25;  // Minimum gap between outbound CI-V commands.
                                    // Icom CI-V over network needs ~20-30ms between
                                    // commands to avoid overflowing the radio's input buffer.
  CIV_QUEUE_MAX_NORMAL       = 50;  // Safety cap: drop normal items beyond this depth.
                                    // In normal operation the queue depth is 4 (one poll burst).

// ---- TCIVSendThread --------------------------------------------------------

constructor TCIVSendThread.Create(AOwner: TIcomRadio);
begin
  inherited Create(True);  // Suspended — caller calls Resume
  FOwner := AOwner;
  FNormalQueue := TStringList.Create;
  FUrgentQueue := TStringList.Create;
  FLock := TCriticalSection.Create;
  FHasWork := TEvent.Create(nil, False, False, '');  // Auto-reset, initially non-signaled
  FreeOnTerminate := False;
end;

destructor TCIVSendThread.Destroy;
begin
  FHasWork.Free;
  FLock.Free;
  FUrgentQueue.Free;
  FNormalQueue.Free;
  inherited Destroy;
end;

procedure TCIVSendThread.Execute;
begin
  while not Terminated do
     begin
     FHasWork.WaitFor(50);  // 50ms timeout so we wake even if a signal is missed
     DrainQueues;
     end;
end;

procedure TCIVSendThread.DrainQueues;
var
  cmd: string;
  hasItem: Boolean;
begin
  repeat
     cmd := '';
     hasItem := False;
     FLock.Acquire;
     try
        if FUrgentQueue.Count > 0 then
           begin
           cmd := FUrgentQueue[0];
           FUrgentQueue.Delete(0);
           hasItem := True;
           end
        else if FNormalQueue.Count > 0 then
           begin
           cmd := FNormalQueue[0];
           FNormalQueue.Delete(0);
           hasItem := True;
           end;
     finally
        FLock.Release;
     end;

     if hasItem then
        begin
        FOwner.DoSendDirect(cmd);
        if not Terminated then
           Sleep(CIV_INTER_COMMAND_DELAY_MS);
        end;
  until (not hasItem) or Terminated;
end;

procedure TCIVSendThread.Enqueue(const cmd: string; priority: TCIVPriority = civpNormal);
begin
  FLock.Acquire;
  try
     if priority = civpUrgent then
        FUrgentQueue.Add(cmd)
     else
        begin
        if FNormalQueue.Count >= CIV_QUEUE_MAX_NORMAL then
           begin
           logger.Warn('[TCIVSendThread.Enqueue] Normal queue full (%d items) — dropping command',
                       [FNormalQueue.Count]);
           Exit;
           end;
        FNormalQueue.Add(cmd);
        end;
  finally
     FLock.Release;
  end;
  FHasWork.SetEvent;
end;

procedure TCIVSendThread.Stop;
begin
  Terminate;         // Sets Terminated := True
  FHasWork.SetEvent; // Wake up immediately if waiting
end;

// ---- CI-V Protocol Constants -----------------------------------------------
const
  CIV_PREAMBLE1 = #$FE;
  CIV_PREAMBLE2 = #$FE;
  CIV_EOM = #$FD;

  // CI-V Commands
  CIV_CMD_READ_FREQ = #$03;
  CIV_CMD_READ_MODE = #$04;
  CIV_CMD_SET_FREQ = #$05;
  CIV_CMD_SET_MODE = #$06;
  CIV_CMD_VFO_MODE = #$07;
  CIV_CMD_SPLIT = #$0F;
  CIV_CMD_LEVELS = #$14;
  CIV_CMD_CW_SEND = #$17;
  CIV_CMD_FILTER = #$1A;
  CIV_CMD_TX_RX = #$1C;
  CIV_CMD_RIT_XIT = #$21;
  CIV_CMD_VFO_SELECT = #$25;

  // CI-V Sub-commands for TX/RX
  CIV_SUBCMD_TX = #$00;
  CIV_SUBCMD_RX = #$01;

  // CI-V Sub-commands for RIT/XIT ($21)
  // Modern Icom layout (IC-7610, IC-7760, confirmed via pcap):
  //   $21 $00 = shared RIT/XIT offset (read/write, BCD + sign)
  //   $21 $01 = RIT on/off (read: no data, write: $00/$01)
  //   $21 $02 = XIT on/off (read: no data, write: $00/$01)
  CIV_SUBCMD_RIT_OFFSET_READ = #$00;  // Read:  $21 $00 = read shared RIT/XIT offset
  CIV_SUBCMD_RIT_ONOFF_READ  = #$01;  // Read:  $21 $01 = read RIT on/off
  CIV_SUBCMD_XIT_ONOFF_READ  = #$02;  // Read:  $21 $02 = read XIT on/off
  CIV_SUBCMD_RIT_OFF = #$01;          // Write: $21 $01 $00 = RIT off
  CIV_SUBCMD_RIT_ON  = #$01;          // Write: $21 $01 $01 = RIT on
  CIV_SUBCMD_XIT_OFF = #$02;          // Write: $21 $02 $00 = XIT off
  CIV_SUBCMD_XIT_ON  = #$02;          // Write: $21 $02 $01 = XIT on
  CIV_SUBCMD_RIT_FREQ = #$00;         // Write: $21 $00 <BCD> <sign> = set offset

  // CI-V Sub-commands for Split ($0F)
  CIV_SUBCMD_SPLIT_OFF = #$00;
  CIV_SUBCMD_SPLIT_ON = #$01;

  // CI-V Sub-commands for VFO Select ($25)
  CIV_SUBCMD_VFO_A = #$00;
  CIV_SUBCMD_VFO_B = #$01;

  // CI-V Sub-commands for CW ($17)
  CIV_SUBCMD_CW_SEND = #$00;

  // CI-V Sub-commands for Filter ($1A)
  CIV_SUBCMD_FILTER_WIDTH = #$03;

  // CI-V Sub-commands for Levels ($14)
  CIV_SUBCMD_CW_SPEED = #$0C;

constructor TIcomRadio.Create;
begin
  inherited Create(ProcessMsg);

  // Icom radios require polling
  requiresPolling := True;
  autoUpdateCommand := '';
  pollingInterval := 1000;  // Poll every 1s — transceive pushes handle real-time freq/mode updates;
                             // polling only covers RIT/split/TX/ActiveVFO which change slowly.

  // Default addresses (derived classes override)
  FControllerAddress := $E0;  // Standard controller address
  FRadioAddress := $00;       // Set by derived class

  FCIVBuffer := '';
  FCWBuffer := '';
  readTerminator := CIV_EOM;  // CI-V frames end with FD

  // Initialize band memory with typical calling frequencies
  FillChar(FBandMemory, SizeOf(FBandMemory), 0);

  FNetworkTransport := nil;
  FNetworkUsername := '';
  FNetworkPassword := '';
  FLastBaseMode := rmNone;
  FDataModeID := $01;  // Default to D1; override via RADIO x ICOM DATA MODE ID config command
  FInitialQueryPending := False;
  FFirstMessage        := True;
  FDirectFreqRoute          := False;  // Override True in subclass for radios where $07 $D2 is unreliable
  FMainBandProcessingOnly   := False;  // Override True for IC-9700, IC-9100 (satellite-mode $25 returns FA)
  FActiveVFOInverted        := False;  // Override True for IC-9700 ($00=$B active, $01=$A active)
  FPollPhase := 0;
  FTransceiveMenuBytes := #$01 + #$50;  // Default: IC-7610/IC-7760 menu item; IC-9700 overrides to $01 $28
  FSupportsExtendedVFOBCommands := True;  // All modern Icoms support $25 $01 <freq> for direct VFO B freq set
  FSupportsActiveVFOQuery := False;       // Overridden True by radios that support $07 $D2 (e.g. IC-7760)
  FActiveVFO := nrVFOA;                  // Safe default; updated by $07 $D2 response on connect

  radioModel := 'Icom';  // Will be overridden by derived classes
end;

destructor TIcomRadio.Destroy;
begin
  if FNetworkTransport <> nil then
  begin
    FNetworkTransport.Disconnect;
    FreeAndNil(FNetworkTransport);
  end;
  inherited Destroy;
end;

// Returns a human-readable hex string for a raw CI-V frame, e.g. "FE FE A2 E0 1A FD"
// Used for trace-level logging of all sent and received CI-V bytes.
function CIVDataToHex(const s: string): string;
var
  i: integer;
begin
  Result := '';
  for i := 1 to Length(s) do
    begin
    if i > 1 then
      Result := Result + ' ';
    Result := Result + IntToHex(Ord(s[i]), 2);
    end;
end;

function TIcomRadio.SupportsDataMode: Boolean;
begin
  Result := True;  // Most Icom radios made in last ~12 years support $1A $06 data mode
                   // Override to False in derived class for older radios that do not
end;

function TIcomRadio.IsNetworkConnection: boolean;
begin
  // Network connection when serial port is not set and IP address is provided
  // Use TNetRadioBase() cast to access base class radioAddress (string),
  // not TIcomRadio.RadioAddress which is the CI-V address (Byte)
  Result := (serialPort = NoPort) and
            (Length(TNetRadioBase(Self).radioAddress) > 0) and
            (radioPort > 0);
end;

function TIcomRadio.Connect: integer;
begin
  // Start the CI-V send queue for BOTH serial and network connections.
  // Serial: the polling thread and the reading thread both call SendToRadio
  //   concurrently; without a queue they race each other on the serial port,
  //   flooding the radio's CI-V buffer and causing dropped responses.
  // Network: prevents flooding the radio's UDP CI-V input buffer.
  if FCIVSendThread = nil then
     begin
     FCIVSendThread := TCIVSendThread.Create(Self);
     FCIVSendThread.Resume;
     logger.Info('[TIcomRadio.Connect] CI-V send queue thread started');
     end;

  if IsNetworkConnection then
  begin
    logger.Info('[TIcomRadio.Connect] Connecting via Icom network protocol to %s:%d',
                [TNetRadioBase(Self).radioAddress, radioPort]);

    // Create transport if needed
    if FNetworkTransport = nil then
    begin
      FNetworkTransport := TIcomNetworkTransport.Create;
      FNetworkTransport.OnCivData := ProcessNetworkCivData;
      FNetworkTransport.OnStateChange := OnNetworkStateChange;
      if rigLabel <> '' then
        FNetworkTransport.RadioName := rigLabel + ' ' + radioModel
      else
        FNetworkTransport.RadioName := radioModel;
    end;

    // Network mode: frequency and mode arrive via CI-V transceive pushes.
    // RIT, XIT, and split do NOT push — poll those only.
    requiresPolling := True;
    pollingInterval := 1000;  // Poll every 1s; PollRadioState queries RIT/XIT/split/TX only
    FTransceiveChecked := False;

    Result := FNetworkTransport.Connect(TNetRadioBase(Self).radioAddress,
                                         radioPort,
                                         FNetworkUsername, FNetworkPassword);
    if Result = 0 then
      logger.Info('[TIcomRadio.Connect] Network connection initiated to %s:%d',
                  [TNetRadioBase(Self).radioAddress, radioPort])
    else
      logger.Error('[TIcomRadio.Connect] Network connection failed: %d', [Result]);
  end
  else
  begin
    // Serial connection - use base class
    Result := inherited Connect;
  end;
end;

procedure TIcomRadio.Disconnect;
begin
  // Stop the send queue first — prevents the queue thread from writing to a
  // port/socket that is about to be closed by inherited Disconnect below.
  if FCIVSendThread <> nil then
     begin
     logger.Debug('[TIcomRadio.Disconnect] Stopping CI-V send queue thread');
     FCIVSendThread.Stop;
     FCIVSendThread.WaitFor;
     FreeAndNil(FCIVSendThread);
     logger.Debug('[TIcomRadio.Disconnect] CI-V send queue thread stopped');
     end;

  if IsNetworkConnection and (FNetworkTransport <> nil) then
     begin
     logger.Debug('[TIcomRadio.Disconnect] Calling FNetworkTransport.Disconnect (state=%s)',
                 [IcomStateToString(FNetworkTransport.State)]);
     FNetworkTransport.Disconnect;
     logger.Debug('[TIcomRadio.Disconnect] FNetworkTransport.Disconnect returned, calling FreeAndNil');
     FreeAndNil(FNetworkTransport);
     logger.Debug('[TIcomRadio.Disconnect] FreeAndNil complete');
     end
  else
     inherited Disconnect;
end;

// DoSendDirect — the only place that calls FNetworkTransport.SendCivData.
// Must only be called from TCIVSendThread.DrainQueues to preserve inter-command spacing.
procedure TIcomRadio.DoSendDirect(const s: string);
begin
  if logger.IsTraceEnabled then
     logger.Trace('[%s] CIV TX: %s', [radioModel, CIVDataToHex(s)]);
  if IsNetworkConnection and (FNetworkTransport <> nil) then
     FNetworkTransport.SendCivData(s)
  else
     inherited SendToRadio(s);
end;

// SendToRadio — enqueues at normal priority.
// All existing callers (poll, set freq/mode, RIT/XIT, etc.) use this path.
// Queue is active for BOTH serial and network; see Connect for rationale.
procedure TIcomRadio.SendToRadio(s: string);
begin
  if FCIVSendThread <> nil then
     FCIVSendThread.Enqueue(s, civpNormal)
  else
     DoSendDirect(s);  // Fallback: queue not yet started (should not happen after Connect)
end;

// SendToRadioUrgent — enqueues at urgent priority, ahead of any normal items.
// Use for time-critical commands: PTT on/off, CW stop.
procedure TIcomRadio.SendToRadioUrgent(const s: string);
begin
  if FCIVSendThread <> nil then
     FCIVSendThread.Enqueue(s, civpUrgent)
  else
     DoSendDirect(s);
end;

function TIcomRadio.GetIsConnected: boolean;
begin
  if IsNetworkConnection then
  begin
    if FNetworkTransport <> nil then
      // Return True for any active state (connecting OR connected).
      // The polling thread checks IsConnected to decide whether to reconnect.
      // If we return False while in WaitingForLogin the polling thread will
      // call Connect() every ~1 second, aborting the auth handshake before
      // the radio has time to respond.  Only return False when truly disconnected.
      Result := (FNetworkTransport.State <> icsDisconnected)
    else
      Result := False;
  end
  else
    Result := inherited GetIsConnected;
end;

// "Operational" is the strict counterpart to IsConnected: True only once the
// transport has finished its full handshake and reached icsConnected.
// Distinct from IsConnected (which stays True during the WaitingForHere /
// WaitingForReady / WaitingForLogin / Authenticated / StreamRequested
// reconnect dance so the polling thread does not interrupt the handshake).
//
// The UI alert color (uRadioPolling.SetRadioAlertState) keys off
// IsOperational so the operator sees "radio lost" magenta the entire time
// the radio is unreachable, instead of clearing back to normal the moment
// a reconnect attempt fires (which is what happened before this override --
// the base class's GetIsOperational returned True unconditionally).
function TIcomRadio.GetIsOperational: boolean;
begin
  if IsNetworkConnection then
    // Operational requires BOTH a completed handshake (state = icsConnected)
    // AND fresh inbound CI-V data.  Icom's UDP transport is connectionless and
    // has no socket-close signal, so a powered-off radio leaves the session in
    // icsConnected indefinitely (unlike the K4's TCP socket, which simply
    // breaks).  The CI-V-freshness gate is what surfaces "radio lost" -- it
    // drives the red freq display and the UDP RadioInfo IsConnected=False via
    // the polling thread's SetRadioAlertState.  Issue #1062.
    Result := (FNetworkTransport <> nil) and
              (FNetworkTransport.State = icsConnected) and
              FNetworkTransport.CivDataFresh
  else
    Result := inherited GetIsOperational;
end;

// Tell the polling thread it's safe to force a Disconnect+Connect cycle
// when we sit in IsConnected=True / IsOperational=False for too long.
// For network Icom this means "the multi-step handshake stalled" and a
// fresh AYH packet is the only recovery (the transport doesn't auto-retry
// the initial $0003).  For serial Icom this state can't really happen, so
// return True only for the network path.
function TIcomRadio.GetCanRecycleOnStuckHandshake: boolean;
begin
  Result := IsNetworkConnection;
end;

function TIcomRadio.GetAuthFailed: boolean;
begin
   if IsNetworkConnection and (FNetworkTransport <> nil) then
      begin
      Result := FNetworkTransport.AuthFailed;
      end
   else
      begin
      Result := False;
      end;
end;

procedure TIcomRadio.ProcessNetworkCivData(msg: string);
begin
  // Called from transport thread when CI-V data arrives via UDP
  // Forward to CI-V message parser
  logger.Trace('[TIcomRadio.ProcessNetworkCivData] Received CI-V data, length: %d', [Length(msg)]);
  ProcessCIVMessage(msg);
end;

procedure TIcomRadio.OnNetworkStateChange(Sender: TObject);
begin
  if FNetworkTransport = nil then Exit;

  logger.Debug('[TIcomRadio.OnNetworkStateChange] Transport state: %s',
              [IcomStateToString(FNetworkTransport.State)]);

  { At StreamRequested the capabilities packet has been received and the transport
    has populated CivAddress with the radio's actual CI-V address. Update
    FRadioAddress now — before the CI-V socket is opened — so all subsequent
    CI-V frames use the correct address. This handles user-customised addresses
    and model variants (e.g. IC-7300MK2 factory default $B6 vs user-set $94).
    NOTE: do NOT check at icsAuthenticated — CivAddress is 0 at that point
    because the capabilities packet arrives after the state transition fires. }
  if FNetworkTransport.State = icsStreamRequested then
     begin
     if FNetworkTransport.CivAddress <> 0 then
        begin
        if FNetworkTransport.CivAddress <> FRadioAddress then
           logger.Info('[TIcomRadio.OnNetworkStateChange] CI-V address override: ' +
                       'class default $%.2x replaced by radio-reported $%.2x. ' +
                       'All CI-V commands will use $%.2x.',
                       [FRadioAddress, FNetworkTransport.CivAddress,
                        FNetworkTransport.CivAddress]);
        FRadioAddress := FNetworkTransport.CivAddress;
        end;
     end;

  if FNetworkTransport.State = icsConnected then
  begin
    // CI-V stream is now open. Send Icom-specific one-shot queries.
    // Freq/mode/RIT/XIT/split/TX are handled by the polling thread's connected
    // block (pNetworkRadio), which owns the display-update path.
    // Queries here are for state that the polling thread doesn't know about.
    SendToRadio(BuildCIVCommand($1A, #$05 + FTransceiveMenuBytes));  // Transceive state
    if SupportsDataMode then
      SendToRadio(BuildCIVCommand($1A, #$06));                       // Data mode on/off
    SendToRadio(BuildCIVCommand($14, CIV_SUBCMD_CW_SPEED));          // CW speed ($14 $0C)
  end;
end;


function TIcomRadio.BuildCIVCommand(command: Byte; data: string): string;
begin
  Result := CIV_PREAMBLE1 + CIV_PREAMBLE2 +
            Chr(FRadioAddress) + Chr(FControllerAddress) +
            Chr(command) + data + CIV_EOM;
end;

function TIcomRadio.FreqToBCD(freq: LongInt): string;
begin
   Result := IcomFreqToBCD(freq);
end;

function TIcomRadio.BCDToFreq(bcd: string): LongInt;
begin
   Result := IcomBCDToFreq(bcd);
end;

// FreqToRadioBand is defined in uRadioBand (implementation uses above).
// All call sites below remain unchanged.


procedure TIcomRadio.ProcessMsg(msg: string);
begin
  logger.trace('[%s.ProcessMsg] CALLED with length: %d', [radioModel, Length(msg)]);
  // Forward to ProcessCIVMessage to maintain compatibility
  ProcessCIVMessage(msg);
end;

procedure TIcomRadio.ProcessCIVMessage(msg: string);
var
  frameStart, frameEnd: Integer;
  frame: string;
begin
  logger.trace('[%s.ProcessCIVMessage] CALLED with msg length: %d', [radioModel, Length(msg)]);  // Removed String2Hex to avoid circular dependency

  // TReadingThread strips the terminator, so add it back
  if (Length(msg) > 0) and (msg[Length(msg)] <> CIV_EOM) then
    msg := msg + CIV_EOM;

  // Add received data to buffer
  FCIVBuffer := FCIVBuffer + msg;
  logger.trace('[%s.ProcessCIVMessage] Buffer length: %d', [radioModel, Length(FCIVBuffer)]);

  // Process complete CI-V frames (FE FE ... FD)
  while True do
  begin
    frameStart := Pos(CIV_PREAMBLE1 + CIV_PREAMBLE2, FCIVBuffer);
    if frameStart = 0 then
    begin
      logger.trace('[%s.ProcessCIVMessage] No preamble found in buffer', [radioModel]);
      Break;  // No complete preamble found
    end;

    frameEnd := Pos(CIV_EOM, FCIVBuffer);
    if frameEnd = 0 then
    begin
      logger.trace('[%s.ProcessCIVMessage] Preamble found but no EOM yet', [radioModel]);
      Break;  // No end-of-message found
    end;

    if frameEnd < frameStart then
    begin
      // EOM before preamble - remove garbage
      Delete(FCIVBuffer, 1, frameEnd);
      Continue;
    end;

    // Extract complete frame including preamble and EOM
    frame := Copy(FCIVBuffer, frameStart, frameEnd - frameStart + 1);
    Delete(FCIVBuffer, 1, frameEnd);

    logger.trace('[%s.ProcessCIVMessage] Extracted frame, length: %d', [radioModel, Length(frame)]);

    // Process the frame
    ProcessCIVFrame(frame);
  end;

  // Prevent buffer from growing too large
  if Length(FCIVBuffer) > 1024 then
    FCIVBuffer := '';
end;

procedure TIcomRadio.ProcessCIVFrame(frame: string);
var
  command: Byte;
  data: string;
  freq: LongInt;
  modeNum: Byte;
  radioMode: TRadioMode;
  subCmd: Byte;
  vfoSlot: TVFO;
  offset: LongInt;
begin
  // Minimum frame: FE FE [To] [From] [Cmd] FD = 6 bytes
  if Length(frame) < 6 then
    Exit;

  // Verify preamble
  if (frame[1] <> CIV_PREAMBLE1) or (frame[2] <> CIV_PREAMBLE2) then
    Exit;

  // Verify EOM
  if frame[Length(frame)] <> CIV_EOM then
    Exit;

  // CI-V frame layout: FE FE [dest] [src] [cmd] [data...] FD
  // frame[3] = destination, frame[4] = source.
  // Discard frames addressed TO the radio (echoes of our own outgoing commands).
  // Only process frames FROM the radio: dest = FControllerAddress or $00 (broadcast).
  if (Ord(frame[3]) = FRadioAddress) then
  begin
    if logger.IsTraceEnabled then
      logger.Trace('[%s] CIV echo (discarded): %s', [radioModel, CIVDataToHex(frame)]);
    Exit;
  end;

  // Valid frame received - update timestamp for disconnect detection
  UpdateLastValidResponse;

  // On first valid frame from the radio, query current VFO/mode state.
  // This covers the case where CI-V transceive is enabled but no $00/$01 push
  // has arrived yet — the display would otherwise be blank until the operator
  // tunes the VFO.
  if FFirstMessage then
     begin
     FFirstMessage := False;
     logger.trace('[%s] First valid CI-V frame — querying initial VFO frequency and mode', [radioModel]);
     // IC-9700 (FMainBandProcessingOnly): $04 returns only the Main Band mode and cannot
     // distinguish VFO A from VFO B. Use $26 $00/$01 for literal-addressed mode queries.
     // Query freq+mode together per VFO so both arrive as a pair.
     if FMainBandProcessingOnly then
        begin
        QueryVFOAFrequency;   // $25 $00 → nrVFOA
        QueryVFOAMode;        // $26 $00 → nrVFOA
        QueryVFOBFrequency;   // $25 $01 → nrVFOB
        QueryVFOBMode;        // $26 $01 → nrVFOB
        end
     else
        begin
        QueryVFOAFrequency;
        QueryVFOBFrequency;
        QueryMode;            // $04 → active VFO mode (other radios)
        end;
     QueryActiveVFO;  // No-op unless FSupportsActiveVFOQuery = True
     end;

  if logger.IsTraceEnabled then
    logger.Trace('[%s] CIV RX: %s', [radioModel, CIVDataToHex(frame)]);

  // Extract command and data
  command := Ord(frame[5]);
  data := Copy(frame, 6, Length(frame) - 6);  // Everything between command and EOM

  case command of
    $00:  // Unsolicited frequency push — active VFO changed frequency
      begin
        if Length(data) >= 5 then
        begin
          freq := BCDToFreq(Copy(data, 1, 5));
          if (FSupportsActiveVFOQuery or FDirectFreqRoute) and not FActiveVFOInverted then
          begin
            // Route directly to FActiveVFO — only for radios where FActiveVFO is
            // reliably current and $00 is the best frequency source.
            // FActiveVFOInverted radios (IC-9700) fall through to the $25 pair path
            // below — $25/$00 and $25/$01 give unambiguous VFO A/B data and avoid
            // the FActiveVFO staleness window that occurs on VFO switch.
            logger.Debug('[%s] $00 freq push: %d Hz → VFO %s (direct)',
               [radioModel, freq, IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
            Self.vfo[FActiveVFO].Frequency := freq;
            Self.vfo[FActiveVFO].Band := FreqToRadioBand(freq);
            if Self.vfo[FActiveVFO].Band <> rbNone then
              FBandMemory[Self.vfo[FActiveVFO].Band] := freq;
          end
          else if FSupportsExtendedVFOBCommands then
          begin
            // Active VFO unknown — must query both slots.
            // Guard and timeout prevent flooding under heavy receive traffic.
            if FVFOQueryPending and (GetTickCount - FVFOQuerySentTick > 2000) then
            begin
              logger.Warn('[%s] $25 query timed out — clearing pending flag', [radioModel]);
              FVFOQueryPending := False;
            end;
            if not FVFOQueryPending then
            begin
              logger.Debug('[%s] $00 freq push (%d Hz) → querying $25/$26 for both VFOs', [radioModel, freq]);
              FVFOQueryPending := True;
              FVFOQuerySentTick := GetTickCount;
              // Query freq+mode together per VFO.
              // IC-9700 (FMainBandProcessingOnly): also refresh mode — $04 push may arrive
              // separately but $00 push alone doesn't carry mode data for both VFOs.
              QueryVFOAFrequency;   // $25 $00 → nrVFOA
              if FMainBandProcessingOnly then
                 QueryVFOAMode;    // $26 $00 → nrVFOA
              QueryVFOBFrequency;   // $25 $01 → nrVFOB
              if FMainBandProcessingOnly then
                 QueryVFOBMode;    // $26 $01 → nrVFOB
            end
            else
              logger.Debug('[%s] $00 freq push (%d Hz) skipped — query already in flight', [radioModel, freq]);
          end
          else
          begin
            // Older radios: $00 always refers to VFO A
            logger.Debug('[%s] $00 freq push: %d Hz → VFO A', [radioModel, freq]);
            Self.vfo[nrVFOA].Frequency := freq;
            Self.vfo[nrVFOA].Band := FreqToRadioBand(freq);
            if Self.vfo[nrVFOA].Band <> rbNone then
              FBandMemory[Self.vfo[nrVFOA].Band] := freq;
          end;
        end;
      end;

    $01:  // Unsolicited mode (CI-V transceive push)
      begin
        if Length(data) >= 1 then
        begin
          // IC-9700 (FActiveVFOInverted): FActiveVFO is unreliable during and after a
          // VFO swap — routing the $01 push directly to FActiveVFO would write the wrong
          // slot. Use the push as a trigger to refresh all four VFO slots via unambiguous
          // literal-addressed $25 and $26 queries. Both freq and mode are refreshed because
          // a mode change on IC-9700 (e.g. Main/Sub swap) may affect both VFOs.
          if FActiveVFOInverted then
             begin
             logger.Debug('[%s] $01 mode push → triggering $25/$26 full refresh', [radioModel]);
             QueryVFOAFrequency;  // $25 $00 → nrVFOA
             QueryVFOAMode;       // $26 $00 → nrVFOA
             QueryVFOBFrequency;  // $25 $01 → nrVFOB
             QueryVFOBMode;       // $26 $01 → nrVFOB
             end
          else
             begin
             modeNum := Ord(data[1]);
             case modeNum of
               $00: radioMode := rmLSB;
               $01: radioMode := rmUSB;
               $02: radioMode := rmAM;
               $03: radioMode := rmCW;
               $04: radioMode := rmFSK;
               $05: radioMode := rmFM;
               $07: radioMode := rmCWRev;
               $08: radioMode := rmFSKRev;
               $06: radioMode := rmFM;   // WFM — treat as FM
               $12: radioMode := rmPSK;
               $13: radioMode := rmPSKRev;
               $17: radioMode := rmDV;   // D-STAR digital voice
               else radioMode := rmNone;
             end;
             logger.debug('[%s] Transceive mode push: $%.2x → TRadioMode=%d → VFO %s',
                [radioModel, modeNum, Ord(radioMode), IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
             FLastBaseMode := radioMode;
             Self.vfo[FActiveVFO].Mode := radioMode;
             Self.vfo[FActiveVFO].dataMode := rmNone;  // Mode update clears data overlay
             localDataMode := rmNone;

             // Radio doesn't push $1A $06 on data mode change — query it after voice modes
             if SupportsDataMode and (radioMode in [rmUSB, rmLSB, rmFM, rmAM]) then
               SendToRadio(BuildCIVCommand($1A, #$06));

             // $01 = active VFO mode changed. Radio doesn't push $26 unsolicited,
             // so query the INACTIVE VFO mode to keep its display in sync.
             // If VFO A is active → VFO B is inactive ($26 $01).
             // If VFO B is active → VFO A is inactive ($26 $00).
             if FSupportsExtendedVFOBCommands then
                begin
                if FActiveVFO = nrVFOA then
                   QueryVFOBMode   // $26 $01 → nrVFOB (inactive)
                else
                   QueryVFOAMode;  // $26 $00 → nrVFOA (inactive)
                end;
             end;
        end;
      end;

    $27:  // Bandscope data — pushed unsolicited by radio, not used
      begin
        // Silently discard — frames can be hundreds of bytes
      end;

    $07:  // VFO selection response or transceive push
      begin
        // $07 $D2 <value> — active VFO query response or push when VFO changes.
        // Standard (IC-7610, IC-7760): $00 = VFO A active, $01 = VFO B active.
        // Inverted  (IC-9700):         $00 = VFO B active, $01 = VFO A active.
        if (Length(data) >= 2) and (Ord(data[1]) = $D2) then
          begin
          logger.Trace('[%s] $07 $D2 raw value = $%.2x (FActiveVFOInverted=%s)',
             [radioModel, Ord(data[2]), BoolToStr(FActiveVFOInverted, True)]);
          if FActiveVFOInverted then
             begin
             if Ord(data[2]) = $00 then
                vfoSlot := nrVFOB
             else
                vfoSlot := nrVFOA;
             end
          else
             begin
             if Ord(data[2]) = $00 then
                vfoSlot := nrVFOA
             else
                vfoSlot := nrVFOB;
             end;
          if vfoSlot <> FActiveVFO then
            begin
            // VFO selection changed — refresh both frequencies and modes
            FActiveVFO := vfoSlot;
            logger.Debug('[%s] $07 $D2: active VFO changed to VFO %s — refreshing',
               [radioModel, IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
            QueryVFOAFrequency;
            QueryVFOAMode;
            QueryVFOBFrequency;
            QueryVFOBMode;
            end
          else
            logger.Trace('[%s] $07 $D2: VFO %s active (unchanged)',
               [radioModel, IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
          end
        else if Length(data) >= 1 then
          logger.Debug('[%s] $07 response: byte[1]=$%.2x (unhandled sub-cmd)', [radioModel, Ord(data[1])]);
      end;

    $03:  // Read operating frequency response — returns the active VFO's frequency
      begin
        logger.Debug('[%s] $03 response received, data len=%d', [radioModel, Length(data)]);
        if Length(data) >= 5 then
        begin
          freq := BCDToFreq(Copy(data, 1, 5));
          // $03 returns the currently selected VFO. We only call $03 from the
          // initial connect block (before $25/$00 is available) so treat it as VFO A.
          logger.Debug('[%s] $03 freq: %d Hz -> VFO A', [radioModel, freq]);
          Self.vfo[nrVFOA].Frequency := freq;
          Self.vfo[nrVFOA].Band := FreqToRadioBand(freq);
          if Self.vfo[nrVFOA].Band <> rbNone then
            FBandMemory[Self.vfo[nrVFOA].Band] := freq;
        end
        else
          logger.Warn('[%s] $03 response too short (len=%d), expected >=5', [radioModel, Length(data)]);
      end;

    $25:  // VFO A/B frequency response (explicit read via $25 $00 / $25 $01)
      begin
        if Length(data) >= 6 then  // IC-7760 format: subcmd(1) + freq(5)
        begin
          subCmd := Ord(data[1]);
          freq := BCDToFreq(Copy(data, 2, 5));
          // $25 $00 = selected (active) VFO → nrVFOA (top display slot)
          // $25 $01 = unselected VFO       → nrVFOB (bottom display slot)
          // Applies to all Icoms including IC-9700 where $00=selected may be
          // physically VFO B — the selected VFO always displays on top.
          if subCmd = $00 then vfoSlot := nrVFOA else vfoSlot := nrVFOB;
          vfo[vfoSlot].Frequency := freq;
          vfo[vfoSlot].Band := FreqToRadioBand(freq);
          if vfo[vfoSlot].Band <> rbNone then
            FBandMemory[vfo[vfoSlot].Band] := freq;
          if subCmd = $00 then
            FVFOQueryPending := False;  // Query pair complete — allow next $00 to trigger
          logger.Debug('[%s] $25/$%.2x → radio object vfo[%s] freq = %d Hz',
             [radioModel, subCmd, IfThen(vfoSlot = nrVFOA, 'nrVFOA', 'nrVFOB'), freq]);
        end
        else if Length(data) = 5 then  // IC-7610/standard format: freq(5) only, no subcmd
        begin
          freq := BCDToFreq(data);
          vfo[nrVFOB].Frequency := freq;
          vfo[nrVFOB].Band := FreqToRadioBand(freq);
          if vfo[nrVFOB].Band <> rbNone then
            FBandMemory[vfo[nrVFOB].Band] := freq;
          logger.debug('[%s] VFO B freq ($25): %d Hz', [radioModel, freq]);
        end;
      end;

    $04:  // Read mode response
      begin
        // IC-9700 (FMainBandProcessingOnly): the radio pushes mode changes as $04 transceive.
        // The $04 data covers only the active VFO and cannot distinguish A from B.
        // Use its arrival as a trigger to refresh both VFOs via explicit $25/$26 queries.
        if FMainBandProcessingOnly then
           begin
           logger.Debug('[%s] $04 mode push → triggering $25/$26 full refresh', [radioModel]);
           QueryVFOAFrequency;   // $25 $00 → nrVFOA
           QueryVFOAMode;        // $26 $00 → nrVFOA
           QueryVFOBFrequency;   // $25 $01 → nrVFOB
           QueryVFOBMode;        // $26 $01 → nrVFOB
           end
        else
           begin
           logger.Debug('[%s] $04 response received, data len=%d', [radioModel, Length(data)]);
           if Length(data) >= 1 then
           begin
             modeNum := Ord(data[1]);
             case modeNum of
               $00: radioMode := rmLSB;
               $01: radioMode := rmUSB;
               $02: radioMode := rmAM;
               $03: radioMode := rmCW;
               $04: radioMode := rmFSK;
               $05: radioMode := rmFM;
               $07: radioMode := rmCWRev;
               $08: radioMode := rmFSKRev;
               $06: radioMode := rmFM;   // WFM — treat as FM
               $12: radioMode := rmPSK;
               $13: radioMode := rmPSKRev;
               $17: radioMode := rmDV;   // D-STAR digital voice
               else radioMode := rmNone;
             end;
             vfoSlot := FActiveVFO;
             logger.Debug('[%s] $04 mode: byte=$%.2x → TRadioMode=%d → VFO %s',
                [radioModel, modeNum, Ord(radioMode), IfThen(vfoSlot = nrVFOA, 'A', 'B')]);
             FLastBaseMode := radioMode;
             Self.vfo[vfoSlot].Mode := radioMode;
             Self.vfo[vfoSlot].dataMode := rmNone;
             localDataMode := rmNone;

             // $04 doesn't include data mode state — query it for voice modes.
             // Also query the inactive VFO mode, same logic as $01 handler.
             if SupportsDataMode and (radioMode in [rmUSB, rmLSB, rmFM, rmAM]) then
                SendToRadio(BuildCIVCommand($1A, #$06));
             if FSupportsExtendedVFOBCommands then
                begin
                if vfoSlot = nrVFOA then
                   QueryVFOBMode
                else
                   QueryVFOAMode;
                end;
           end
           else
             logger.Warn('[%s] $04 response empty (len=%d)', [radioModel, Length(data)]);
           end;
      end;

    $1A:  // Settings responses — transceive check and data mode
      begin
        if Length(data) >= 1 then
        begin
          // 1A 05 [menu byte 1] [menu byte 2] [value] — CI-V transceive setting query response
          // Menu bytes are radio-specific: IC-7610/IC-7760 = $01 $50; IC-9700 = $01 $28
          if (Ord(data[1]) = $05) and (Length(data) >= 4) and
             (data[2] = FTransceiveMenuBytes[1]) and (data[3] = FTransceiveMenuBytes[2]) then
          begin
            if not FTransceiveChecked then
            begin
              FTransceiveChecked := True;
              if Ord(data[4]) = $01 then
                logger.Info('[%s] CI-V Transceive confirmed ON', [radioModel])
              else
              begin
                logger.Warn('[%s] CI-V Transceive is OFF — frequency/mode will not update automatically', [radioModel]);
                MessageBox(0,
                  PChar(radioModel + ': CI-V Transceive is disabled on this radio.' + #13#10 +
                  'Frequency and mode will not update automatically in network mode.' + #13#10 + #13#10 +
                  'To fix: Set > Connectors > CI-V Transceive = ON'),
                  'TR4W - Radio Configuration Warning',
                  MB_OK or MB_ICONWARNING or MB_TASKMODAL);
              end;
            end;
          end
          // 1A 06 [dm] [filter] — data mode on/off (decorator on top of voice mode)
          // dm=00 → data off; dm=01/02/03 → D1/D2/D3 (all mean "data" to a logger)
          else if SupportsDataMode and (Ord(data[1]) = $06) and (Length(data) >= 2) then
          begin
            if Ord(data[2]) = $00 then
            begin
              // Data mode OFF — restore the base voice/CW mode
              vfo[FActiveVFO].Mode := FLastBaseMode;
              vfo[FActiveVFO].dataMode := rmNone;
              localDataMode := rmNone;
              logger.debug('[%s] Data mode OFF, restored base mode on VFO %s',
                 [radioModel, IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
            end
            else
            begin
              // Data mode ON (D1/D2/D3) — only apply if current mode is a voice mode
              // Ignore stale responses that arrive after switching to CW/FSK/PSK
              if vfo[FActiveVFO].Mode in [rmUSB, rmLSB, rmFM, rmAM] then
              begin
                FLastBaseMode := vfo[FActiveVFO].Mode;  // Save base mode for restore
                vfo[FActiveVFO].Mode := rmData;
                vfo[FActiveVFO].dataMode := rmData;
                localDataMode := rmData;
                logger.debug('[%s] Data mode ON (D%d) on VFO %s',
                   [radioModel, Ord(data[2]), IfThen(FActiveVFO = nrVFOA, 'A', 'B')]);
              end
              else
                logger.debug('[%s] Data mode ON ignored — current mode is not voice', [radioModel]);
            end;
          end;
        end;
      end;

    $26:  // VFO B frequency/mode (query response or transceive push)
      // IC-7760 format (FSupportsExtendedVFOBCommands): $01 <freq5> <mode> <filter>
      // Standard format: <freq5> <mode> <filter>
      begin
        logger.Debug('[%s] $26 response received, data len=%d, extended=%s',
           [radioModel, Length(data), BoolToStr(FSupportsExtendedVFOBCommands, True)]);
        if FSupportsExtendedVFOBCommands then
          begin
          if Length(data) = 1 then
            begin
            // Sub-command echo/ACK from radio — not a data frame, ignore
            logger.debug('[%s] $26 sub-command ACK, ignoring', [radioModel]);
            end
          else if Length(data) >= 7 then
            begin
            // Transceive push (full frame): $01 <freq5> <mode> <filter>
            freq := BCDToFreq(Copy(data, 2, 5));
            vfo[nrVFOB].Frequency := freq;
            vfo[nrVFOB].Band := FreqToRadioBand(freq);
            if vfo[nrVFOB].Band <> rbNone then
              FBandMemory[vfo[nrVFOB].Band] := freq;
            modeNum := Ord(data[7]);
            case modeNum of
              $00: radioMode := rmLSB;
              $01: radioMode := rmUSB;
              $02: radioMode := rmAM;
              $03: radioMode := rmCW;
              $04: radioMode := rmFSK;
              $05: radioMode := rmFM;
              $07: radioMode := rmCWRev;
              $08: radioMode := rmFSKRev;
              $06: radioMode := rmFM;
              $12: radioMode := rmPSK;
              $13: radioMode := rmPSKRev;
              $17: radioMode := rmDV;
              else radioMode := rmNone;
            end;
            vfo[nrVFOB].Mode := radioMode;
            logger.Debug('[%s] VFO B freq+mode ($26 push): %d Hz, mode=$%.2x → TRadioMode=%d',
               [radioModel, freq, modeNum, Ord(radioMode)]);
            end
          else if Length(data) >= 3 then
            begin
            // Mode-only query response: <subCmd> <mode> <filter> [<datamode>]
            // $26 $00 = selected (active) VFO mode → nrVFOA (top display slot)
            // $26 $01 = unselected VFO mode       → nrVFOB (bottom display slot)
            // Consistent with $25 mapping — selected VFO always on top.
            subCmd := Ord(data[1]);
            if subCmd = $00 then vfoSlot := nrVFOA else vfoSlot := nrVFOB;
            modeNum := Ord(data[2]);
            case modeNum of
              $00: radioMode := rmLSB;
              $01: radioMode := rmUSB;
              $02: radioMode := rmAM;
              $03: radioMode := rmCW;
              $04: radioMode := rmFSK;
              $05: radioMode := rmFM;
              $07: radioMode := rmCWRev;
              $08: radioMode := rmFSKRev;
              $06: radioMode := rmFM;
              $12: radioMode := rmPSK;
              $13: radioMode := rmPSKRev;
              $17: radioMode := rmDV;
              else radioMode := rmNone;
            end;
            // IC-7760 $26 mode-only response format: subCmd + mode + dataMode + filter
            // data[2]=mode, data[3]=dataMode ($00=off, $01-$03=D1-D3), data[4]=filter
            // NOTE: dataMode comes BEFORE filter — do not confuse with filter byte.
            if SupportsDataMode and (radioMode in [rmUSB, rmLSB, rmFM, rmAM]) and
               (Length(data) >= 3) and (Ord(data[3]) <> $00) then
              begin
              vfo[vfoSlot].Mode := rmData;
              vfo[vfoSlot].dataMode := rmData;
              logger.Debug('[%s] $26/$%.2x → radio object vfo[%s] mode=$%.2x + data mode D%d → rmData',
                 [radioModel, subCmd, IfThen(vfoSlot = nrVFOA, 'nrVFOA', 'nrVFOB'), modeNum, Ord(data[3])]);
              end
            else
              begin
              vfo[vfoSlot].Mode := radioMode;
              vfo[vfoSlot].dataMode := rmNone;
              logger.Debug('[%s] $26/$%.2x → radio object vfo[%s] mode=$%.2x → TRadioMode=%d',
                 [radioModel, subCmd, IfThen(vfoSlot = nrVFOA, 'nrVFOA', 'nrVFOB'), modeNum, Ord(radioMode)]);
              end;
            end
          else
            logger.Warn('[%s] $26 response unexpected length %d, ignoring',
               [radioModel, Length(data)]);
          end
        else
          begin
          // Standard format: <freq5> <mode> <filter>
          if Length(data) >= 5 then
            begin
            freq := BCDToFreq(Copy(data, 1, 5));
            vfo[nrVFOB].Frequency := freq;
            vfo[nrVFOB].Band := FreqToRadioBand(freq);
            if vfo[nrVFOB].Band <> rbNone then
              FBandMemory[vfo[nrVFOB].Band] := freq;
            logger.Debug('[%s] VFO B freq ($26): %d Hz', [radioModel, freq]);
            end;
          if Length(data) >= 6 then
            begin
            modeNum := Ord(data[6]);
            case modeNum of
              $00: radioMode := rmLSB;
              $01: radioMode := rmUSB;
              $02: radioMode := rmAM;
              $03: radioMode := rmCW;
              $04: radioMode := rmFSK;
              $05: radioMode := rmFM;
              $07: radioMode := rmCWRev;
              $08: radioMode := rmFSKRev;
              $06: radioMode := rmFM;   // WFM — treat as FM
              $12: radioMode := rmPSK;
              $13: radioMode := rmPSKRev;
              $17: radioMode := rmDV;   // D-STAR digital voice
              else radioMode := rmNone;
            end;
            vfo[nrVFOB].Mode := radioMode;
            logger.Debug('[%s] VFO B mode ($26): byte=$%.2x → TRadioMode=%d',
               [radioModel, modeNum, Ord(radioMode)]);
            end;
          end;
      end;

    $0F:  // Split on/off (transceive push or poll response)
      begin
        if Length(data) >= 1 then
        begin
          localSplitEnabled := (Ord(data[1]) = $01);
          logger.trace('[%s] Split: %s', [radioModel, BoolToStr(localSplitEnabled, True)]);
        end;
      end;

    $1C:  // TX/RX state (transceive push — radio went to TX or RX)
      begin
        // Sub-command $00 = TX/RX, value $00 = RX, $01 = TX
        if (Length(data) >= 2) and (Ord(data[1]) = $00) then
        begin
          if Ord(data[2]) = $01 then
            radioState := rsTransmit
          else
            radioState := rsReceive;
          logger.trace('[%s] TX state: %s', [radioModel, IfThen(radioState = rsTransmit, 'TX', 'RX')]);
        end;
      end;

    $21:  // RIT/XIT state or offset (poll response or transceive push)
      // Modern Icom layout (IC-7610, IC-7760, confirmed via pcap):
      //   $21 $00 [BCD lo] [BCD hi] [sign] = shared RIT/XIT offset
      //   $21 $01 [on/off]                 = RIT on/off
      //   $21 $02 [on/off]                 = XIT on/off
      begin
        if Length(data) >= 1 then
        begin
          subCmd := Ord(data[1]);
          case subCmd of
            $00:  // Shared RIT/XIT offset
              begin
                if Length(data) >= 4 then
                begin
                  offset := BCDToFreq(Copy(data, 2, 2));
                  if Ord(data[4]) <> $00 then
                    offset := -offset;
                  localRITOffset := offset;
                  localXITOffset := offset;  // Shared
                  vfo[nrVFOA].RITOffset := offset;
                  vfo[nrVFOA].XITOffset := offset;
                  logger.trace('[%s] RIT/XIT offset: %d Hz', [radioModel, offset]);
                end;
              end;
            $01:  // RIT on/off
              begin
                if Length(data) >= 2 then
                begin
                  RITState := (Ord(data[2]) = $01);
                  vfo[nrVFOA].RITState := RITState;
                  logger.trace('[%s] RIT %s', [radioModel, IfThen(RITState, 'ON', 'OFF')]);
                end;
              end;
            $02:  // XIT on/off
              begin
                if Length(data) >= 2 then
                begin
                  XITState := (Ord(data[2]) = $01);
                  vfo[nrVFOA].XITState := XITState;
                  logger.trace('[%s] XIT %s', [radioModel, IfThen(XITState, 'ON', 'OFF')]);
                end;
              end;
          end;
        end;
      end;

    $14:  // Levels response (CW speed, etc.)
      begin
        if (Length(data) >= 3) and (Ord(data[1]) = $0C) then
        begin
          // CW speed: 2 BCD bytes encoding 0-255, maps to 6-48 WPM
          // Format: $0C <bcd-high> <bcd-low> (e.g., $01 $08 = value 108)
          offset := ((Ord(data[2]) shr 4) * 10) + (Ord(data[2]) and $0F);  // high decimal
          freq := ((Ord(data[3]) shr 4) * 10) + (Ord(data[3]) and $0F);    // low decimal
          offset := offset * 100 + freq;  // combine: 0-255 value
          // Formula (spec): WPM = 6 + value * 42 / 255, round to nearest
          // Integer round-to-nearest: add half the divisor (127) before div
          freq := 6 + (offset * 42 + 127) div 255;
          // Debounce: ignore radio echo for 500ms after a program-initiated SetCWSpeed.
          // Without this, the radio echoes the old speed back and the polling sync loop
          // overwrites CodeSpeed with the stale value, causing the bouncing.
          if GetTickCount - FLastSetCWSpeedTick >= 500 then
            begin
            localCWSpeed := freq;
            logger.debug('[%s] CW speed from radio: %d WPM (BCD $%.2x $%.2x = value %d)',
                         [radioModel, localCWSpeed, Ord(data[2]), Ord(data[3]), offset]);
            end
          else
            begin
            logger.debug('[%s] CW speed echo suppressed (debounce): %d WPM (sent %d ms ago)',
                         [radioModel, freq, GetTickCount - FLastSetCWSpeedTick]);
            end;
        end;
      end;

    $19:  // Transceiver ID response (diagnostic — $19 broadcast sent on connect for address confirmation)
      begin
        // Radio replies: FE FE [ctrl] [radio] 19 00 [addr] FD
        // data[1] = $00 (sub-command echo), data[2] = CI-V address
        // Initial state queries are sent directly by the polling thread on connect —
        // this response is logged for diagnostics only.
        if Length(data) >= 2 then
          logger.Debug('[%s] Transceiver ID confirmed, CI-V address=$%.2x', [radioModel, Ord(data[2])])
        else
          logger.Debug('[%s] Transceiver ID response received (no address byte)', [radioModel]);
      end;

    $FB:  // Command OK (ACK)
      logger.debug('[%s] Command acknowledged', [radioModel]);

    $FA:  // Command NG (NAK)
      // Some commands are not supported by certain radios (e.g. IC-9700 rejects $21 $02 XIT).
      // Log at Debug for radios known to have unsupported commands; Warn for others.
      if FMainBandProcessingOnly then
         logger.Debug('[%s] Command rejected (FA) — unsupported command on this radio', [radioModel])
      else
         logger.Warn('[%s] Command rejected (FA)', [radioModel]);
  end;
end;

// Polling interface
procedure TIcomRadio.QueryVFOAFrequency;
begin
  // Prefer $25 $00 (VFO-addressed read) over $03 (active-VFO read).
  // $03 is relative to whichever VFO is selected: when VFO B is active
  // it returns VFO B's frequency and would overwrite the nrVFOA slot.
  // $25 $00 always returns VFO A regardless of selection state.
  // Fall back to $03 only for older radios that do not support $25.
  if FSupportsExtendedVFOBCommands then
     SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_A))
  else
     SendToRadio(BuildCIVCommand($03, ''));
end;

procedure TIcomRadio.QueryVFOBFrequency;
begin
  // $25 $01 returns VFO B frequency directly in its response
  SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_B));
end;

procedure TIcomRadio.QueryVFOAMode;
begin
  // $26 $00 — reads VFO A mode when VFO B is active (symmetric to $26 $01 for VFO B).
  // Only meaningful on extended-command radios; response handled in $26 handler by subCmd $00.
  if FSupportsExtendedVFOBCommands then
    SendToRadio(BuildCIVCommand($26, CIV_SUBCMD_VFO_A));
end;

procedure TIcomRadio.QueryVFOBMode;
begin
  // $26 $01 returns VFO B mode. Extended radios use sub-command $01, standard Icoms use plain $26.
  if FSupportsExtendedVFOBCommands then
    SendToRadio(BuildCIVCommand($26, CIV_SUBCMD_VFO_B))
  else
    SendToRadio(BuildCIVCommand($26, ''));
end;

procedure TIcomRadio.QueryActiveVFO;
begin
  // $07 $D2 read — returns $00 (main/VFO A active) or $01 (sub/VFO B active).
  // Only supported on radios with FSupportsActiveVFOQuery = True (e.g. IC-7760).
  if FSupportsActiveVFOQuery then
    SendToRadio(BuildCIVCommand($07, #$D2));
end;

procedure TIcomRadio.QueryMode;
begin
  SendToRadio(BuildCIVCommand($04, ''));  // Read operating mode
end;

procedure TIcomRadio.QueryTXStatus;
begin
  // Query TX/RX status using command $1C $00
  SendToRadio(BuildCIVCommand($1C, #$00));
end;

procedure TIcomRadio.QueryRITState;
begin
  // $21 $01 = RIT on/off, $21 $00 = shared RIT/XIT offset
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_ONOFF_READ));
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_OFFSET_READ));
end;

procedure TIcomRadio.QueryXITState;
begin
  // $21 $02 = XIT on/off (offset is shared with RIT, already queried)
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_ONOFF_READ));
end;

procedure TIcomRadio.QueryBand;
begin
  // Band is derived from frequency
end;

procedure TIcomRadio.QuerySplitState;
begin
  // Query split status using command $0F
  SendToRadio(BuildCIVCommand($0F, ''));
end;

procedure TIcomRadio.PollRadioState;
begin
  // Only poll states that CI-V transceive does NOT push automatically.
  // VFO A freq/mode arrive via $00/$01 transceive pushes — polling $25 $00 every
  // second would overwrite VFO A with physical VFO A when VFO B is active, fighting
  // the transceive push. Leave VFO A entirely to the transceive mechanism.
  // VFO B freq/mode are polled via $26 since transceive only pushes the active VFO.
  logger.trace('[%s.PollRadioState] Polling RIT/XIT/Split/TX/ActiveVFO', [radioModel]);
  QueryRITState;          // $21 $01
  QueryXITState;          // $21 $02
  QuerySplitState;        // $0F
  QueryTXStatus;          // $1C $00
  QueryActiveVFO;         // $07 $D2 — keep FActiveVFO current; triggers refresh only on change
end;

// Radio control methods - basic implementations
procedure TIcomRadio.Transmit;
begin
  SendToRadioUrgent(BuildCIVCommand($1C, CIV_SUBCMD_TX));  // PTT on — urgent
end;

procedure TIcomRadio.Receive;
begin
  SendToRadioUrgent(BuildCIVCommand($1C, CIV_SUBCMD_RX));  // PTT off — urgent
end;

procedure TIcomRadio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var
  bcdFreq: string;
begin
  logger.Debug('[%s.SetFrequency] freq=%d VFO=%s TRadioMode=%d', [radioModel, freq, IfThen(vfo = nrVFOA, 'A', 'B'), Ord(mode)]);
  bcdFreq := FreqToBCD(freq);
  if (vfo = nrVFOB) and FSupportsExtendedVFOBCommands then
     begin
     // $25 $01 <freq> sets VFO B frequency directly without disturbing the active VFO.
     // Supported by all modern Icom radios. FSupportsExtendedVFOBCommands defaults to
     // True; set to False in a subclass constructor for older radios that lack it.
     SendToRadio(BuildCIVCommand($25, CIV_SUBCMD_VFO_B + bcdFreq));
     end
  else
     begin
     // $05 sets the active VFO frequency. For VFO A this is always correct.
     // For VFO B on radios that lack $25 extended support, the caller must have
     // already selected VFO B before calling here (pre-existing limitation).
     SendToRadio(BuildCIVCommand($05, bcdFreq));
     end;
  logger.debug('[%s.SetFrequency] Set VFO %s to %d Hz', [radioModel, IfThen(vfo = nrVFOA, 'A', 'B'), freq]);
  // Optimistic update: Icom radios do not transceive-push $00 in response to a
  // CI-V $05 they received — only front-panel VFO changes trigger transceive.
  // Update vfo state immediately so the display reflects the new frequency
  // without waiting for the operator to touch the VFO knob.
  Self.vfo[vfo].Frequency := freq;
  Self.vfo[vfo].Band := FreqToRadioBand(freq);
  if Self.vfo[vfo].Band <> rbNone then
     FBandMemory[Self.vfo[vfo].Band] := freq;
  // Set mode if provided. Done after the frequency command so the radio sees
  // freq+mode arrive together. rmNone means "frequency only, leave mode alone".
  if mode <> rmNone then
     SetMode(mode, vfo);
  // Also queue a $03 query so the radio confirms the frequency it actually
  // landed on. If the frequency was rejected (out of band, etc.) this
  // corrects the optimistic update with the real value.
  if vfo = nrVFOA then
     QueryVFOAFrequency
  else
     QueryVFOBFrequency;
end;

procedure TIcomRadio.SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA);
var
  modeCmd: Byte;
  filterCmd: Byte;
  dataMode: Byte;
begin
  logger.Debug('[%s.SetMode] Setting VFO %s to TRadioMode=%d', [radioModel, IfThen(vfo = nrVFOA, 'A', 'B'), Ord(mode)]);

  // Map TRadioMode to Icom mode numbers
  filterCmd := $01;  // Default filter
  case mode of
    rmLSB:    modeCmd := $00;
    rmUSB:    modeCmd := $01;
    rmAM:     modeCmd := $02;
    rmCW:     modeCmd := $03;
    rmFSK:    modeCmd := $04;
    rmFM:     modeCmd := $05;
    rmCWRev:  modeCmd := $07;
    rmFSKRev: modeCmd := $08;
    rmAFSK,
    rmData:     modeCmd := $01;  // USB base mode + data sub-mode
    rmDataRev:  modeCmd := $00;  // LSB base mode + data sub-mode
    rmPSK:    modeCmd := $12;
    rmPSKRev: modeCmd := $13;
    rmDV:     modeCmd := $17;  // D-STAR digital voice
  else
    modeCmd := $01;  // Default to USB
  end;

  if (vfo = nrVFOB) and FSupportsExtendedVFOBCommands then
     begin
     // Use $26 $01 <mode> <dataMode> <filter> to set VFO B mode directly,
     // without any VFO-swap sequence. The $07 $01 / $06 / $07 $00 approach
     // races with CI-V transceive pushes over network connections — the $06
     // command lands on whichever VFO is active when the radio processes it,
     // which may still be VFO A. $26 $01 targets VFO B unconditionally.
     // This matches the serial path (LOGRADIO.PAS IcomRadiosThatSupportVFOB).
     if mode in [rmAFSK, rmData, rmDataRev] then
        dataMode := FDataModeID
     else
        dataMode := 0;
     logger.Debug('[%s.SetMode] Sending $26 $01 modeCmd=$%.2x dataMode=$%.2x filterCmd=$%.2x',
        [radioModel, modeCmd, dataMode, filterCmd]);
     SendToRadio(BuildCIVCommand($26, #$01 + Chr(modeCmd) + Chr(dataMode) + Chr(filterCmd)));
     end
  else
     begin
     // VFO A, or radios without $25/$26 support: use $06 targeting the active VFO.
     // For VFO B on older radios, swap to VFO B first, then restore VFO A after.
     if vfo = nrVFOB then
        SendToRadio(BuildCIVCommand($07, #$01));

     logger.Debug('[%s.SetMode] Sending $06 modeCmd=$%.2x filterCmd=$%.2x', [radioModel, modeCmd, filterCmd]);
     SendToRadio(BuildCIVCommand($06, Chr(modeCmd) + Chr(filterCmd)));

     // Set or clear the Icom data sub-mode flag ($1A $06):
     //   Entering data mode  → turn flag ON  ($1A $06 D1/D2/D3) via FDataModeID
     //   Leaving data mode for a voice mode → turn flag OFF ($1A $06 $00)
     //   Only send the clear command when the previous mode was actually a data
     //   mode; sending $1A $06 $00 unnecessarily (e.g. USB→USB on a retune) is
     //   known to kill the IC-7760 CI-V transceive stream.
     //   CW/CW-R: the radio auto-clears data mode on $06 $03 — no $1A $06 needed.
     //   FSK/PSK: use native Icom mode numbers and need no $1A $06 command.
     if SupportsDataMode then
        begin
        if mode in [rmAFSK, rmData, rmDataRev] then
           begin
           logger.Debug('[%s.SetMode] Sending $1A $06 $%.2x (data mode ON, D%d)', [radioModel, FDataModeID, FDataModeID]);
           SendToRadio(BuildCIVCommand($1A, #$06 + Chr(FDataModeID)));
           end
        else if (mode in [rmUSB, rmLSB, rmAM, rmFM]) and
                (Self.vfo[vfo].Mode in [rmData, rmDataRev, rmAFSK]) then
           begin
           logger.Debug('[%s.SetMode] Sending $1A $06 $00 (leaving data mode, prev TRadioMode=%d)', [radioModel, Ord(Self.vfo[vfo].Mode)]);
           SendToRadio(BuildCIVCommand($1A, #$06 + #$00));
           end;
        end;

     if vfo = nrVFOB then
        SendToRadio(BuildCIVCommand($07, #$00));
     end;

  // Optimistic update: reflect the new mode in our cached VFO state immediately.
  // The polling thread reads vfo.Mode on every cycle; without this update, the
  // stale mode triggers ProcessFilteredStatus to override the display back to
  // the old mode before the transceive-push confirmation from the radio arrives.
  // rmAFSK maps to rmData because that is what the radio confirms: a $01 $01
  // (USB) transceive push combined with the $1A $06 $01 (data ON) response.
  if mode = rmAFSK then
     Self.vfo[vfo].Mode := rmData
  else
     Self.vfo[vfo].Mode := mode;

  logger.Debug('[%s.SetMode] Done — VFO %s TRadioMode=%d modeCmd=$%.2x', [radioModel, IfThen(vfo = nrVFOA, 'A', 'B'), Ord(mode), modeCmd]);
end;

procedure TIcomRadio.BufferCW(cwChars: string);
begin
  FCWBuffer := FCWBuffer + cwChars;
  logger.debug('[%s.BufferCW] Buffered: "%s", Total buffer: "%s"', [radioModel, cwChars, FCWBuffer]);
end;

procedure TIcomRadio.SendCW;
begin
  if FCWBuffer = '' then
  begin
    logger.warn('[%s.SendCW] CW buffer is empty - nothing to send', [radioModel]);
    Exit;
  end;

  // Send CW message using CI-V command $17 $00
  SendToRadio(BuildCIVCommand($17, CIV_SUBCMD_CW_SEND + FCWBuffer));
  logger.info('[%s.SendCW] Sending CW: "%s"', [radioModel, FCWBuffer]);

  // Clear buffer after sending
  FCWBuffer := '';
end;

procedure TIcomRadio.StopCW;
begin
  // CI-V command $17 $FF stops CW sending — sent urgent to jump the queue
  SendToRadioUrgent(BuildCIVCommand($17, #$FF));
  logger.debug('[%s.StopCW] CW transmission stopped', [radioModel]);
end;

function TIcomRadio.MemoryKeyer(mem: integer): boolean;
begin
   Result := True; // default: error
   if mem = 0 then
      begin
      SendToRadio(BuildCIVCommand($28, #$00#$00));
      logger.debug('[%s.MemoryKeyer] Stopping DVK', [radioModel]);
      Result := False;
      end
   else if (mem >= 1) and (mem <= 8) then
      begin
      SendToRadio(BuildCIVCommand($28, #$00 + Chr(mem)));
      logger.debug('[%s.MemoryKeyer] Playing DVK memory %d', [radioModel, mem]);
      Result := False;
      end
   else
      logger.error('[%s.MemoryKeyer] Memory %d out of range (0-8)', [radioModel, mem]);
end;

function TIcomRadio.SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer;
begin
   // TODO: implement filter bandwidth control via CI-V $1A $03
   logger.debug('[%s.SetFilterHz] Not yet implemented (hz=%d)', [radioModel, hz]);
   Result := 0;
end;

procedure TIcomRadio.VFOBumpDown(whichVFO: TVFO);
begin
   // TODO: implement VFO bump via CI-V frequency step commands
   logger.debug('[%s.VFOBumpDown] Not yet implemented', [radioModel]);
end;

procedure TIcomRadio.VFOBumpUp(whichVFO: TVFO);
begin
   // TODO: implement VFO bump via CI-V frequency step commands
   logger.debug('[%s.VFOBumpUp] Not yet implemented', [radioModel]);
end;

function TIcomRadio.ToggleMode(vfo: TVFO = nrVFOA): TRadioMode;
var
  currentMode: TRadioMode;
  nextMode: TRadioMode;
begin
  // Get current mode from VFO
  currentMode := Self.vfo[vfo].Mode;

  // Toggle to next mode in sequence
  case currentMode of
    rmNone, rmLSB: nextMode := rmUSB;
    rmUSB:   nextMode := rmCW;
    rmCW:    nextMode := rmCWRev;
    rmCWRev: nextMode := rmAM;
    rmAM:    nextMode := rmFM;
    rmFM:    nextMode := rmLSB;  // Wrap around
  else
    nextMode := rmUSB;  // Default
  end;

  SetMode(nextMode, vfo);
  Result := nextMode;
end;

procedure TIcomRadio.SetCWSpeed(speed: integer);
var
  icomValue: Integer;
  bcdHigh, bcdLow: Byte;
begin
  // Icom CW speed: 6–48 WPM maps linearly to CI-V value 0–255
  // Encode formula: value = ceil((WPM - 6) * 255 / 42)
  // We use ceiling, NOT round-to-nearest, because the radio decodes with
  // truncation: WPM = 6 + floor(value * 42 / 255).  Round-nearest gives value 18
  // for 9 WPM, which the radio truncation-decodes back as 8 WPM.  Ceiling gives
  // value 19, which decodes correctly as 9 WPM.
  if speed < 6 then speed := 6;
  if speed > 48 then speed := 48;
  icomValue := ((speed - 6) * 255 + 41) div 42;
  if icomValue > 255 then icomValue := 255;

  // Encode 0-255 value as 2 BCD bytes: hundreds|tens, ones
  bcdHigh := IcomByteToBCD(icomValue div 100);    // 0-2
  bcdLow  := IcomByteToBCD(icomValue mod 100);    // 0-99
  FLastSetCWSpeedTick := GetTickCount;  // Start debounce window before sending
  SendToRadio(BuildCIVCommand($14, CIV_SUBCMD_CW_SPEED + Chr(bcdHigh) + Chr(bcdLow)));
  localCWSpeed := speed;
  logger.debug('[%s.SetCWSpeed] %d WPM -> icomValue=%d -> BCD $%s $%s',
               [radioModel, speed, icomValue,
                IntToHex(bcdHigh, 2), IntToHex(bcdLow, 2)]);
end;

procedure TIcomRadio.RITClear(whichVFO: TVFO);
begin
  // Clear RIT by setting offset to 0
  SetRITFreq(whichVFO, 0);
  logger.debug('[%s.RITClear] Cleared RIT offset', [radioModel]);
end;

procedure TIcomRadio.XITClear(whichVFO: TVFO);
begin
  // Clear XIT by setting offset to 0
  SetXITFreq(whichVFO, 0);
  logger.debug('[%s.XITClear] Cleared XIT offset', [radioModel]);
end;

procedure TIcomRadio.RITBumpDown;
begin
  // Bump RIT down by 10 Hz
  // Note: Would need to track current RIT offset to implement properly
  logger.debug('[%s.RITBumpDown] RIT bump down not fully implemented', [radioModel]);
end;

procedure TIcomRadio.RITBumpUp;
begin
  // Bump RIT up by 10 Hz
  // Note: Would need to track current RIT offset to implement properly
  logger.debug('[%s.RITBumpUp] RIT bump up not fully implemented', [radioModel]);
end;

procedure TIcomRadio.RITOn(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_ON + #$01));  // $21 $01 $01
  logger.debug('[%s.RITOn] RIT enabled', [radioModel]);
end;

procedure TIcomRadio.RITOff(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_OFF + #$00));  // $21 $01 $00
  logger.debug('[%s.RITOff] RIT disabled', [radioModel]);
end;

procedure TIcomRadio.XITOn(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_ON + #$01));  // $21 $02 $01
  logger.debug('[%s.XITOn] XIT enabled', [radioModel]);
end;

procedure TIcomRadio.XITOff(vfo: TVFO);
begin
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_XIT_OFF + #$00));  // $21 $02 $00
  logger.debug('[%s.XITOff] XIT disabled', [radioModel]);
end;

procedure TIcomRadio.Split(splitOn: boolean);
begin
  if splitOn then
    SendToRadio(BuildCIVCommand($0F, CIV_SUBCMD_SPLIT_ON))
  else
    SendToRadio(BuildCIVCommand($0F, CIV_SUBCMD_SPLIT_OFF));
  logger.debug('[%s.Split] Split %s', [radioModel, IfThen(splitOn, 'enabled', 'disabled')]);
end;

procedure TIcomRadio.SetRITFreq(vfo: TVFO; hz: integer);
var
  bcdOffset: string;
begin
  bcdOffset := IcomOffsetToBCD(hz);
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_FREQ + bcdOffset));
  logger.debug('[%s.SetRITFreq] Set RIT offset to %d Hz', [radioModel, hz]);
end;

procedure TIcomRadio.SetXITFreq(vfo: TVFO; hz: integer);
var
  bcdOffset: string;
begin
  // RIT/XIT share the same offset register on modern Icom radios ($21 $00)
  bcdOffset := IcomOffsetToBCD(hz);
  SendToRadio(BuildCIVCommand($21, CIV_SUBCMD_RIT_FREQ + bcdOffset));
  logger.debug('[%s.SetXITFreq] Set XIT offset to %d Hz', [radioModel, hz]);
end;

procedure TIcomRadio.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
var
  freq: LongInt;
begin
  // Use remembered frequency for this band; fall back to typical frequency
  freq := FBandMemory[band];
  if freq = 0 then
    freq := BandToFreq(band);
  SetFrequency(freq, vfo, rmNone);
  logger.debug('[%s.SetBand] Set band to %d, freq=%d', [radioModel, Ord(band), freq]);
end;

function TIcomRadio.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
var
  currentBand: TRadioBand;
  nextBand: TRadioBand;
begin
  // Get current band from VFO
  currentBand := Self.vfo[vfo].Band;

  // Toggle to next band in sequence
  case currentBand of
    rbNone, rb160m: nextBand := rb80m;
    rb80m:  nextBand := rb60m;
    rb60m:  nextBand := rb40m;
    rb40m:  nextBand := rb30m;
    rb30m:  nextBand := rb20m;
    rb20m:  nextBand := rb17m;
    rb17m:  nextBand := rb15m;
    rb15m:  nextBand := rb12m;
    rb12m:  nextBand := rb10m;
    rb10m:  nextBand := rb6m;
    rb6m:   nextBand := rb4m;
    rb4m:   nextBand := rb2m;
    rb2m:   nextBand := rb70cm;
    rb70cm: nextBand := rb160m;  // Wrap around
  else
    nextBand := rb20m;  // Default
  end;

  SetBand(nextBand, vfo);
  Result := nextBand;
end;

procedure TIcomRadio.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
var
  filterNum: Byte;
begin
  // Map TRadioFilter to Icom filter numbers
  // Note: Filter numbering varies by radio, this is a general mapping
  case filter of
    rfNarrow:  filterNum := $02;  // Narrow filter
    rfMid:     filterNum := $01;  // Medium/default filter
    rfWide:    filterNum := $03;  // Wide filter
  else
    filterNum := $01;  // Default filter
  end;

  SendToRadio(BuildCIVCommand($1A, CIV_SUBCMD_FILTER_WIDTH + Chr(filterNum)));
  logger.debug('[%s.SetFilter] Set filter to %d', [radioModel, filterNum]);
end;

procedure TIcomRadio.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
  // For Icom, commands are built differently - this is mainly for compatibility
  SendToRadio(sCmd + sData);
end;

initialization
  logger := TLogLogger.GetLogger('uRadioIcomBase');

end.
