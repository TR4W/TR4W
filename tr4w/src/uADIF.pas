unit uADIF;

{
  TR4W ADIF lexer + helpers — focused, dependency-light, testable.

  This unit contains the migration-touchy core of ADIF import: the
  string-slicing lexer and the small helpers that map ADIF field text
  into TR4W types (band, mode, date, time, contest).

  It deliberately depends only on SysUtils / StrUtils / Log4D / VC so
  the unit-test runner can link it without pulling MainUnit and its
  window / contest-state globals.

  Issue #887 — second incremental commit.  This commit adds:
    - TADIF_Fields enum (moved from MainUnit)
    - GetADIFBand / GetADIFMode / GetADIFSubMode (moved)
    - ADIFDateStringToQSOTime / ADIFTimeStringToQSOTime (moved)
    - GetContestByADIFName (moved; cache preserved as unit-private)
    - IsValidGUID (local copy; avoids dragging trdos/LOGSTUFF.PAS)

  Previously shipped (first incremental commit):
    - ParseADIFFieldsList (the lexer)
    - TADIFField / TADIFFieldList types

  Still in MainUnit, will move in follow-up commits:
    - The field-name -> ContestExchange mapping case statement
    - The contest-specific post-processing tail
    - ImportADIFFromString multi-record entry point

  See docs/tr4w-migration-strategy.md.  ADIF string handling is the
  highest-risk surface for Phase 2 (Unicode correctness); each function
  here is reachable from the unit-test runner without MainUnit baggage.

  Delphi 12 migration note:
    Bare `string` is used here.  In D7 this is AnsiString; in D12 it
    becomes UnicodeString.  ADIF is fundamentally a text format with
    UTF-8 in NAME/QTH/COMMENT fields, so the UnicodeString transition
    is the correct semantic.  Wire-byte data (CI-V, etc.) elsewhere in
    TR4W explicitly types AnsiString.
}

interface

uses
   SysUtils,
   StrUtils,
   Log4D,
   VC,
   utils_text;

type
   TADIFField = record
      Name  : string;
      Value : string;
   end;

   TADIFFieldList = array of TADIFField;

   // Transient fields populated by ApplyADIFFieldsToExchange that the
   // contest-specific post-processing (in MainUnit) needs.  Some ADIF
   // tags map directly to ContestExchange fields; others need contest-
   // aware re-interpretation (e.g. STATE in ARRL_RTTY_ROUNDUP becomes
   // part of QTHString in a contest-defined format).  This record
   // carries the raw field values forward so the contest tail can do
   // its job without re-parsing.
   TADIFRecordTemps = record
      SRX_String : string;
      STX_String : string;
      State      : string;
      ARRL_Sect  : string;
      VE_Prov    : string;
      POTARef    : string;
      SIG        : string;
      SIG_Info   : string;
      GridSquare : string;
      FOC_Num    : string;
      APP_HQ     : string;
      FromWSJTX  : Boolean;
   end;

   TContestExchangeArray = array of ContestExchange;

   // ADIF field-name dispatch enum.  Order MUST match the AnsiIndexText
   // string array in MainUnit.ParseADIFRecord (and in the future, in
   // ApplyADIFFieldsToExchange when that moves here).  Adding entries
   // requires updating both the enum and the lookup array.
   TADIF_Fields = (tAdifARRL_SECT = 0, tAdifBAND, tAdifCALL, tAdifCHECK,
      tAdifCLASS, tAdifCQ_Z,
      tAdifCONTEST_ID, tAdifCNTY, tadifFOC_NUM, tAdifGRIDSQUARE, tAdifFREQ,
      tAdifFREQ_RX,
      tAdifIOTA, tAdifITUZ, tAdifMODE, tAdifNAME, tAdifOPERATOR, tAdifPRECEDENCE,
      tAdifQSO_DATE, tAdifQSO_DATE_OFF, tAdifTIME_ON, tAdifTIME_OFF,
      tAdifRST_RCVD, tAdifRST_SENT, tAdifRX_PWR, tAdifSRX, tAdifSRX_STRING,
      tAdifSTATE, tAdifSTX, tAdifSTX_STRING, tAdifSUBMODE, tAdifTEN_TEN,
      tAdifVE_PROV, tAdifAPP_TR4W_HQ, tAdifAPP_N1MM_HQ, tAdifSTATION_CALLSIGN,
      tAdifQTH, tAdifPROGRAMID, tAdifAPP_N1MM_EXCHANGE1, tAdifAPP_N1MM_ID,
      tAdifAPP_TR4W_ID, tAdifSIG, tAdifSIG_INFO, tAdifPOTAREF,
      tAdifAPP_TR4W_ROVERCALL,
      // X-QSO / "not claimed" markers -- Issue #750.  Three different
      // conventions in the wild, all recognized on import:
      //   APP_TR4W_CLAIMEDQSO  value '1' = normal, '0' = X-QSO  (TR4W)
      //   APP_N1MM_CLAIMEDQSO  value '1' = normal, '0' = X-QSO  (N1MM)
      //   APP_DXLOG_XQSO       value 'Y' = X-QSO                (DXLog.net)
      // Export emits only APP_TR4W_CLAIMEDQSO; the others are import-only.
      tAdifAPP_TR4W_CLAIMEDQSO, tAdifAPP_N1MM_CLAIMEDQSO,
      tAdifAPP_DXLOG_XQSO);

// =========================================================================
// Lexer
// =========================================================================

// Parse a single ADIF record's field list from `s`.
//
// The lexer reads fields of the form `<NAME:n>VALUE` (optionally
// `<NAME:n:T>` where T is the ADIF data-type indicator — type is
// discarded).  Whitespace and free-form text between fields is ignored.
// The lexer stops at the first `<EOR>` or `<EOH>` it encounters
// (case-insensitive).
//
// Returns True if a terminator (<EOR> or <EOH>) was found.  Returns False
// when the end of `s` is reached without a terminator OR when a malformed
// tag is encountered.  Even on False, `fields` contains the fields that
// were successfully parsed before the error/end.
function ParseADIFFieldsList(const s: string;
                             out fields: TADIFFieldList): Boolean;

// =========================================================================
// Per-field type-conversion helpers
// =========================================================================

// Convert an ADIF BAND string ("20m", "70cm") to a TR4W BandType.
// Returns NoBand for unrecognized input.  Case-insensitive.
function GetADIFBand(sBand: string): BandType;

// Convert an ADIF MODE string ("CW", "SSB", "FT8", ...) to a TR4W
// (Mode, ExtendedMode) pair.  Returns NoMode for unrecognized input.
// Case-insensitive.
function GetADIFMode(sMode: string): ModeAndExtendedModeType;

// Convert an ADIF SUBMODE string ("FT4", "USB", "LSB", ...) to a TR4W
// (Mode, ExtendedMode) pair.  Returns NoMode for unrecognized input.
// Case-insensitive.
function GetADIFSubMode(sSubMode: string): ModeAndExtendedModeType;

// Parse an ADIF QSO_DATE string ("YYYYMMDD", 8 chars).  Returns True on
// success and sets qsoTime.qtYear/qtMonth/qtDay.  Returns False (without
// modifying qsoTime) on invalid input.
function ADIFDateStringToQSOTime(sDate: string;
                                 var qsoTime: TQSOTime): Boolean;

// Parse an ADIF TIME_ON / TIME_OFF string ("HHMM" or "HHMMSS").  Returns
// True on success and sets qsoTime.qtHour/qtMinute/qtSecond (seconds = 0
// when only HHMM provided).  Returns False on invalid input.
function ADIFTimeStringToQSOTime(sTime: string;
                                 var qsoTime: TQSOTime): Boolean;

// Look up a contest by its ADIF CONTEST_ID value.  Returns the first
// ContestType whose ContestsArray[].ADIFName matches sADIFName; otherwise
// returns the contest at Low(ContestsArray) (DummyContest).  Caller must
// then verify ContestsArray[Result].ADIFName = sADIFName to distinguish
// "not found" from "first contest".  Cached single-entry for the common
// case of all QSOs in a file sharing the same contest.
function GetContestByADIFName(sADIFName: string): ContestType;

// Validate an ADIF GUID/UUID string.  Accepts 32 hex characters with
// optional 8-4-4-4-12 hyphens and optional `{...}` braces.  Used to gate
// the APP_N1MM_ID / APP_TR4W_ID assignment to exch.id.
function IsValidGUID(const guid: string): Boolean;

// =========================================================================
// Field-to-ContestExchange mapping
// =========================================================================

// Clear a TADIFRecordTemps to empty/false state.
procedure InitADIFRecordTemps(var temps: TADIFRecordTemps);

// Initialize a ContestExchange to a sane "no record yet" state for use
// by the ADIF parser.  Mirrors the relevant parts of the legacy
// ClearContestExchange (trdos/LOGDUPE.PAS) -- specifically the
// sentinels the parser depends on, e.g. Mode = NoMode so the MODE-
// handler's `if exch.Mode = NoMode` guard fires.  Does NOT touch
// MainUnit-global fields like ceContest's contest-specific defaults.
procedure InitContestExchangeForParse(var exch: ContestExchange);

// Apply a parsed field list to a ContestExchange record, populating
// "obvious" exch.X fields (CALL, BAND, MODE, FREQ, RST, SRX, STX, etc.)
// directly, and capturing the contest-aware temp values (SRX_STRING,
// STATE, ARRL_SECT, POTA_REF, etc.) into `temps` for the caller's
// contest-specific post-processing step.
//
// Returns False on parse error inside an individual field (e.g.
// StrToInt failure on RST_RCVD); the function continues processing the
// remaining fields and the partial exch is preserved.  Returns True
// when all fields were processed without exception.
function ApplyADIFFieldsToExchange(const fields: TADIFFieldList;
                                   var exch: ContestExchange;
                                   var temps: TADIFRecordTemps): Boolean;

// =========================================================================
// Multi-record entry point
// =========================================================================

// Parse a multi-record ADIF string into `records`.  Splits on <EOR>
// (case-insensitive), lexes each record, and applies the field mapping
// for each.  The contest-specific post-processing tail is NOT applied
// here -- the caller is responsible for that (e.g. MainUnit.ImportFromADIF
// applies it via ApplyContestSpecificADIFTail).
//
// Skips an optional ADIF header section (everything up to the first
// <EOH>, also case-insensitive).
//
// `records` is resized via SetLength to fit the parsed records.  Returns
// the count of records successfully parsed (= Length(records)).
function ImportADIFFromString(const s: string;
                              var records: TContestExchangeArray): Integer;

// =========================================================================
// Export side
// =========================================================================

type
   // Caller-supplied tail emitter.  Returns ADIF text to append between
   // EmitADIFRecord's output and the closing <EOR> for a single record.
   // Used by PostUnit.ExportToADIF to add contest-specific fields
   // (GRIDSQUARE / IOTA / ARRL_SECT / POTA MY_SIG / CLASS / STATION_CALLSIGN /
   // STX_STRING built from MainUnit globals / CQZ/ITUZ / CNTY from mo.DomList).
   // Tests pass nil to skip the tail entirely.
   TContestTailEmitter = function(const rec: ContestExchange): string;

// Build one ADIF field as `<NAME:LEN>VALUE ` (trailing space for tag
// separation).  Empty value returns ''.
function EmitADIFField(const name, value: string): string;

// Build the ADIF header (ADIF_VER, CREATED_TIMESTAMP, PROGRAMID,
// PROGRAMVERSION, <EOH>).  Pure -- caller can prepend a banner line
// if desired.
function EmitADIFHeader(const programVersion: string): string;

// Build a single ADIF record from a ContestExchange.  Emits the
// "ContestExchange-driven" fields only -- fields whose values come
// from the record itself (call, band, mode, RST, etc.).  Does NOT
// emit `<EOR>` -- caller appends.
//
// Excludes fields that need MainUnit/trdos globals (STATION_CALLSIGN,
// STX_STRING via GetMyExchangeForExport, CNTY via mo.DomList,
// CQZ/ITUZ via ActiveZoneMult, POTA MY_* fields via myPark, ARRL-FD
// CLASS via MyFDClass etc.).  PostUnit.ExportToADIF provides those
// via the TContestTailEmitter callback.
function EmitADIFRecord(const rec: ContestExchange): string;

// Build the entire ADIF document for the given records: header +
// (EmitADIFRecord(r) + tailEmitter(r) + <EOR>) for each record.
// `programVersion` is the value for the PROGRAMVERSION ADIF tag in
// the header.  `tailEmitter` may be nil -- in which case no contest-
// specific extras are added per record (suitable for tests).
function ExportADIFToString(const records: TContestExchangeArray;
                            const programVersion: string;
                            tailEmitter: TContestTailEmitter): string;

// Return the host state's 2-letter postal code for the 13 known
// single-state QSO parties (CA/FL/MI/MN/MO/NC/OH/TX/WI/TN/CO/PA/IN).
// Returns '' for any other contest.  Used by EmitADIFRecord to emit
// STATE when QTHString carries a county code instead of a 2-letter
// state code.  Originally lived in PostUnit; moved here so it is
// reachable from both uADIF (export) and the test runner.
function GetStateForContest(c: ContestType): string;

// Build the RST-normalized SRX_STRING value: if ExchString already
// starts with the literal RSTReceived (e.g. operator typed `599 HIL`),
// return ExchString unchanged; otherwise prepend `RSTReceived ` so
// the field is symmetric with STX_STRING.  Used by the export tail
// emitter for contests whose exchange convention includes an implied
// RST (ExchangeInformation.RST = True) -- state QPs and zone
// contests.  Contests whose exchange has no RST (FD, SS, Winter FD,
// etc.) should emit SRX_STRING = ExchString directly, NOT call this.
function ResolveSRXString(const rec: ContestExchange): string;

implementation

var
   logger : TLogLogger;

   // Single-entry cache for GetContestByADIFName.  All QSOs in a typical
   // import file share the same CONTEST_ID, so this is a hot path.
   saveLastADIFName : string;
   saveLastContest  : ContestType;

// ---------------------------------------------------------------------------
// Lexer helpers
// ---------------------------------------------------------------------------

procedure AppendField(var fields: TADIFFieldList;
                     const name, value: string);
var
   idx : Integer;
begin
   idx := Length(fields);
   SetLength(fields, idx + 1);
   fields[idx].Name := name;
   fields[idx].Value := value;
end;

// ---------------------------------------------------------------------------
// Lexer
// ---------------------------------------------------------------------------

function ParseADIFFieldsList(const s: string;
                             out fields: TADIFFieldList): Boolean;
var
   p           : Integer;
   sLen        : Integer;
   gtPos       : Integer;
   tagBody     : string;
   tagUpper    : string;
   tagName     : string;
   tagLenStr   : string;
   tagLen      : Integer;
   colonPos    : Integer;
   secondColon : Integer;
   value       : string;
begin
   Result := False;
   SetLength(fields, 0);
   sLen := Length(s);
   p := 1;

   while p <= sLen do
      begin
      // Skip text between tags
      while (p <= sLen) and (s[p] <> '<') do
         Inc(p);
      if p > sLen then
         Break;

      Inc(p);  // skip '<'

      // Find matching '>'
      gtPos := p;
      while (gtPos <= sLen) and (s[gtPos] <> '>') do
         Inc(gtPos);
      if gtPos > sLen then
         begin
         // '<' without matching '>' — malformed; stop with what we have
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] unclosed tag at position %d', [p - 1]);
         Exit;
         end;

      tagBody := Copy(s, p, gtPos - p);
      p := gtPos + 1;  // advance past '>'

      // <EOR> terminates a QSO record.  <EOH> only ends the optional
      // ADIF header (spec IV.A.2: an ADI file is an optional Header,
      // terminated by <EOH>, followed by one or more <EOR> records; a
      // headerless file starts straight into records).  A full document
      // reaches this single-record lexer -- the WSJT-X "Logged ADIF" UDP
      // message is <adif_ver><programid><EOH><call...><EOR> -- so skip
      // <EOH> and keep parsing the record that follows rather than
      // stopping at the header boundary.  Restores the pre-Issue-#887
      // behaviour, where the inline parser terminated on <EOR> only.
      tagUpper := AnsiUpperCase(tagBody);
      if tagUpper = 'EOR' then
         begin
         Result := True;
         Exit;
         end;
      if tagUpper = 'EOH' then
         Continue;

      // Parse '<NAME:LEN>' or '<NAME:LEN:TYPE>'
      colonPos := AnsiPos(':', tagBody);
      if colonPos = 0 then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag without length: <%s>', [tagBody]);
         Continue;
         end;

      tagName   := Copy(tagBody, 1, colonPos - 1);
      tagLenStr := Copy(tagBody, colonPos + 1, Length(tagBody) - colonPos);

      // Strip optional ':TYPE' suffix
      secondColon := AnsiPos(':', tagLenStr);
      if secondColon > 0 then
         tagLenStr := Copy(tagLenStr, 1, secondColon - 1);

      if not TryStrToInt(tagLenStr, tagLen) then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s> has non-numeric length [%s]',
                        [tagName, tagLenStr]);
         Continue;
         end;

      if tagLen < 0 then
         begin
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s> has negative length %d',
                        [tagName, tagLen]);
         Continue;
         end;

      // Read exactly tagLen characters as the value
      if p + tagLen - 1 > sLen then
         begin
         // truncated value — take whatever is left, then stop
         value := Copy(s, p, sLen - p + 1);
         AppendField(fields, tagName, value);
         if Assigned(logger) then
            logger.Warn('[ADIF lexer] tag <%s:%d> truncated; got %d bytes',
                        [tagName, tagLen, Length(value)]);
         Exit;
         end;

      value := Copy(s, p, tagLen);
      p := p + tagLen;
      AppendField(fields, tagName, value);
      end;

   // Ran off the end without seeing <EOR> or <EOH>
   Result := False;
end;

// ---------------------------------------------------------------------------
// Per-field type-conversion helpers
// ---------------------------------------------------------------------------

function GetADIFBand(sBand: string): BandType;
var
   sBandLower : string;
   iBand      : BandType;
   entry      : PChar;
begin
   Result := NoBand;
   // Reject empty input — ADIFBANDSTRINGSARRAY has nil entries for the
   // tail of BandType (placeholders), and an empty string would match
   // those PChar(nil) entries on string comparison, yielding a spurious
   // band.  No legitimate ADIF input has BAND=''.
   if sBand = '' then
      Exit;
   sBandLower := AnsiLowerCase(sBand);
   for iBand := Low(BandType) to High(BandType) do
      begin
      entry := ADIFBANDSTRINGSARRAY[iBand];
      if (entry <> nil) and (sBandLower = entry) then
         begin
         Result := iBand;
         Break;
         end;
      end;
end;

function GetADIFMode(sMode: string): ModeAndExtendedModeType;
begin
   // Default extended mode in case lookup hits the else branch — keeps
   // the field deterministic when MODE is unrecognized.
   Result.msmExtendedMode := eNoMode;

   // The lookup list mirrors what TR4W's export side emits.  Several
   // entries (CW-R, RTTY-R, FM-N, C4FM, etc.) are TR4W-specific
   // extended modes that the export puts in the ADIF MODE field
   // (not SUBMODE), so the import must accept them there too for
   // round-trip.  Whether that is fully ADIF-spec-correct is a
   // separate question; this matches existing export behaviour.
   case AnsiIndexText(AnsiUpperCase(sMode),
                      ['CW', 'SSB', 'AM', 'FM', 'FT8',
                       'RTTY', 'MFSK', 'PSK31', 'PSK', 'DATA',
                       'CW-R', 'RTTY-R', 'DATA-R', 'PSK-R',
                       'JT65', 'PSK63', 'DATA-FM',
                       'FM-N', 'AM-N', 'WFM', 'C4FM', 'D-STAR']) of
      0:                              // CW
         begin
         Result.msmMode := CW;
         Result.msmExtendedMode := eCW;
         end;
      1:                              // SSB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eSSB;
         end;
      2:                              // AM
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eAM;
         end;
      3:                              // FM
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eFM;
         end;
      4:                              // FT8
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eFT8;
         end;
      5:                              // RTTY
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eRTTY;
         end;
      6:                              // MFSK
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eMFSK;
         end;
      7, 8:                           // PSK31, PSK
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK31;
         end;
      9:                              // DATA  (generic digital)
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eData;
         end;

      // --- CW family ---
      10:                             // CW-R
         begin
         Result.msmMode := CW;
         Result.msmExtendedMode := eCW_R;
         end;

      // --- Digital family (reverses + protocols) ---
      11:                             // RTTY-R
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eRTTY_R;
         end;
      12:                             // DATA-R
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eData_R;
         end;
      13:                             // PSK-R
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK_R;
         end;
      14:                             // JT65
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eJT65;
         end;
      15:                             // PSK63
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK63;
         end;
      16:                             // DATA-FM
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eData_FM;
         end;

      // --- Phone family (narrowband + digital voice) ---
      17:                             // FM-N
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eFM_N;
         end;
      18:                             // AM-N
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eAM_N;
         end;
      19:                             // WFM
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eWFM;
         end;
      20:                             // C4FM (Yaesu digital voice)
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eC4FM;
         end;
      21:                             // D-STAR (Icom digital voice)
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eDStar;
         end;
   else
      Result.msmMode := NoMode;
   end;
end;

function GetADIFSubMode(sSubMode: string): ModeAndExtendedModeType;
begin
   case AnsiIndexText(AnsiUpperCase(sSubMode),
                      ['FT4', 'JS8', 'USB', 'LSB', 'PSK31']) of
      0:                              // FT4
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eFT4;
         end;
      1:                              // JS8
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := eJS8;
         end;
      2:                              // USB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eUSB;
         end;
      3:                              // LSB
         begin
         Result.msmMode := Phone;
         Result.msmExtendedMode := eLSB;
         end;
      4:                              // PSK31
         begin
         Result.msmMode := Digital;
         Result.msmExtendedMode := ePSK31;
         end;
   else
      Result.msmMode := NoMode;
   end;
end;

function ADIFDateStringToQSOTime(sDate: string;
                                 var qsoTime: TQSOTime): Boolean;
begin
   Result := False;
   try
      if Length(sDate) = 8 then
         begin
         qsoTime.qtYear  := Ord(StrToInt(MidStr(sDate, 1, 4)) mod 100);
         qsoTime.qtMonth := Ord(StrToInt(MidStr(sDate, 5, 2)));
         qsoTime.qtDay   := Ord(StrToInt(MidStr(sDate, 7, 2)));
         Result := True;
         end;
   except
      Result := False;
   end;
end;

function ADIFTimeStringToQSOTime(sTime: string;
                                 var qsoTime: TQSOTime): Boolean;
begin
   Result := False;
   if Length(sTime) in [4, 6] then
      begin
      try
         qsoTime.qtHour   := Ord(StrToInt(MidStr(sTime, 1, 2)));
         qsoTime.qtMinute := Ord(StrToInt(MidStr(sTime, 3, 2)));
         if Length(sTime) = 6 then
            qsoTime.qtSecond := Ord(StrToInt(MidStr(sTime, 5, 2)))
         else
            qsoTime.qtSecond := 0;
         Result := True;
      except
         Result := False;
      end;
      end;
end;

function GetContestByADIFName(sADIFName: string): ContestType;
var
   i : ContestType;
begin
   if sADIFName = saveLastADIFName then
      begin
      Result := saveLastContest;
      Exit;
      end;

   Result := Low(ContestsArray); // first contest = DummyContest
   for i := Low(ContestsArray) to High(ContestsArray) do
      begin
      if ContestsArray[i].ADIFName = sADIFName then
         begin
         Result := i;
         saveLastADIFName := sADIFName;
         saveLastContest  := i;
         Break;
         end;
      end;
end;

// ---------------------------------------------------------------------------
// IsValidGUID
//
// Standalone GUID validator that does NOT depend on TPerlRegEx (the
// LOGSTUFF.PAS version uses TPerlRegEx, which would drag in a much
// heavier dependency surface).  Accepts:
//   - 32 raw hex characters (no separators)
//   - 8-4-4-4-12 hyphenated form (36 characters)
//   - Either of the above wrapped in `{...}` braces
// ---------------------------------------------------------------------------

function IsValidGUID(const guid: string): Boolean;
const
   HEX_CHARS = ['0'..'9', 'a'..'f', 'A'..'F'];
var
   s        : string;
   i        : Integer;
   hexCount : Integer;
begin
   Result := False;
   if guid = '' then
      Exit;

   s := guid;

   // Strip optional surrounding braces
   if (Length(s) >= 2) and (s[1] = '{') and (s[Length(s)] = '}') then
      s := Copy(s, 2, Length(s) - 2);

   if (Length(s) <> 32) and (Length(s) <> 36) then
      Exit;

   hexCount := 0;
   for i := 1 to Length(s) do
      begin
      if s[i] in HEX_CHARS then
         Inc(hexCount)
      else if s[i] = '-' then
         begin
         // Hyphens only at positions 9, 14, 19, 24 in 8-4-4-4-12 layout
         if (Length(s) <> 36) or
            ((i <> 9) and (i <> 14) and (i <> 19) and (i <> 24)) then
            Exit;
         end
      else
         Exit;
      end;

   Result := hexCount = 32;
end;

// ---------------------------------------------------------------------------
// Field-to-ContestExchange mapping
// ---------------------------------------------------------------------------

procedure InitADIFRecordTemps(var temps: TADIFRecordTemps);
begin
   temps.SRX_String := '';
   temps.STX_String := '';
   temps.State      := '';
   temps.ARRL_Sect  := '';
   temps.VE_Prov    := '';
   temps.POTARef    := '';
   temps.SIG        := '';
   temps.SIG_Info   := '';
   temps.GridSquare := '';
   temps.FOC_Num    := '';
   temps.APP_HQ     := '';
   temps.FromWSJTX  := False;
end;

const
   // Order MUST match the TADIF_Fields enum declaration.  Adding a field
   // requires updating BOTH this array AND the enum.
   ADIF_FIELD_NAMES : array[0..47] of string = (
      // ADIF spec field name is `CQZ` (no underscore).  The original
      // import lookup had `CQ_Z` which never matched real-world ADIF
      // exports -- the tAdifCQ_Z handler was effectively dead until
      // this fix.  Zone parsing for CQ-WW used to rely on the SRX_STRING
      // post-processing in MainUnit's contest tail.  Surfaced by the
      // CQ-WW-CW fixture test (uTestADIFFixtures).
      'ARRL_SECT', 'BAND', 'CALL', 'CHECK', 'CLASS', 'CQZ',
      'CONTEST_ID', 'CNTY', 'FOC_NUM', 'GRIDSQUARE', 'FREQ', 'FREQ_RX',
      'IOTA', 'ITUZ', 'MODE', 'NAME', 'OPERATOR', 'PRECEDENCE',
      'QSO_DATE', 'QSO_DATE_OFF', 'TIME_ON', 'TIME_OFF',
      'RST_RCVD', 'RST_SENT', 'RX_PWR', 'SRX', 'SRX_STRING',
      'STATE', 'STX', 'STX_STRING', 'SUBMODE', 'TEN_TEN',
      'VE_PROV', 'APP_TR4W_HQ', 'APP_N1MM_HQ', 'STATION_CALLSIGN',
      'QTH', 'PROGRAMID', 'APP_N1MM_EXCHANGE1', 'APP_N1MM_ID',
      'APP_TR4W_ID', 'SIG', 'SIG_INFO', 'POTA_REF',
      'APP_TR4W_ROVERCALL',
      // X-QSO marker fields (Issue #750) -- order must match the enum
      'APP_TR4W_CLAIMEDQSO', 'APP_N1MM_CLAIMEDQSO', 'APP_DXLOG_XQSO');

function ApplyADIFFieldsToExchange(const fields: TADIFFieldList;
                                   var exch: ContestExchange;
                                   var temps: TADIFRecordTemps): Boolean;
var
   i                    : Integer;
   fieldName            : string;
   fieldValue           : string;
   tempRST              : string;
   neFreq               : Extended;
   msm                  : ModeAndExtendedModeType;
   contest              : ContestType;
   saveDecimalSeparator : Char;
   haveRoverCall        : Boolean;
begin
   Result := True;
   InitADIFRecordTemps(temps);
   haveRoverCall := False;

   for i := 0 to High(fields) do
      begin
      fieldName  := fields[i].Name;
      fieldValue := fields[i].Value;

      try
         case TADIF_Fields(AnsiIndexText(AnsiUpperCase(fieldName),
                                         ADIF_FIELD_NAMES)) of

            tAdifARRL_SECT:
               temps.ARRL_Sect := fieldValue;

            tAdifBAND:
               exch.Band := GetADIFBand(fieldValue);

            tAdifCALL:
               // If we have already seen APP_TR4W_ROVERCALL in this
               // record, it carries the full rover form (KG1S/MON)
               // and we keep that instead of the bare CALL value.
               if not haveRoverCall then
                  exch.Callsign := AnsiUpperCase(fieldValue);

            tAdifAPP_TR4W_ROVERCALL:
               begin
               exch.Callsign := AnsiUpperCase(fieldValue);
               haveRoverCall := True;
               end;

            tAdifCHECK:
               exch.Check := StrToInt(fieldValue);

            tAdifCLASS:
               exch.ceClass := AnsiUpperCase(fieldValue);

            tAdifCQ_Z:
               exch.Zone := StrToInt(fieldValue);

            tAdifCONTEST_ID:
               begin
               contest := GetContestByADIFName(fieldValue);
               if ContestsArray[contest].ADIFName = fieldValue then
                  exch.ceContest := contest;
               end;

            tAdifCNTY:
               logger.Info('[ApplyADIFFields] CNTY=%s but no destination field',
                           [fieldValue]);

            tAdifFOC_NUM:
               temps.FOC_Num := fieldValue;

            tAdifGRIDSQUARE:
               temps.GridSquare := fieldValue;

            tAdifFREQ:
               begin
               saveDecimalSeparator := DecimalSeparator;
               try
                  DecimalSeparator := '.';
                  neFreq := StrToFloat(fieldValue);
                  neFreq := neFreq * 1000000;
                  exch.Frequency := Trunc(neFreq);
               finally
                  DecimalSeparator := saveDecimalSeparator;
               end;
               end;

            tAdifITUZ:
               exch.Zone := StrToInt(fieldValue);

            tAdifMODE:
               if exch.Mode = NoMode then
                  begin
                  msm := GetADIFMode(fieldValue);
                  exch.Mode    := msm.msmMode;
                  exch.ExtMode := msm.msmExtendedMode;
                  end;

            tAdifNAME:
               exch.Name := fieldValue;

            tAdifOPERATOR:
               StrPLCopy(exch.ceOperator, fieldValue, High(exch.ceOperator));

            tAdifPRECEDENCE:
               if Length(fieldValue) > 0 then
                  exch.Precedence := fieldValue[1];

            tAdifQSO_DATE:
               ADIFDateStringToQSOTime(fieldValue, exch.tSysTime);

            tAdifTIME_ON, tAdifTIME_OFF:
               ADIFTimeStringToQSOTime(fieldValue, exch.tSysTime);

            tAdifRST_RCVD:
               begin
               tempRST := fieldValue;
               // WSJT-X uses signed dB SNR like "+05" / "-12".  Strip
               // the sign so StrToIntDef can parse the magnitude.  The
               // sign is dropped (TR uses a Word; negative SNRs are
               // not representable in the legacy log format).
               if temps.FromWSJTX and (Pos('+', fieldValue) > 0) then
                  tempRST := AnsiMidStr(fieldValue, 2, Length(fieldValue));
               exch.RSTReceived := StrToIntDef(tempRST, 599);
               end;

            tAdifRST_SENT:
               begin
               tempRST := fieldValue;
               if temps.FromWSJTX and (Pos('+', fieldValue) > 0) then
                  tempRST := AnsiMidStr(fieldValue, 2, Length(fieldValue));
               exch.RSTSent := StrToIntDef(tempRST, 599);
               end;

            tAdifRX_PWR:
               exch.Power := fieldValue;

            tAdifSRX:
               exch.NumberReceived := StrToInt(fieldValue);

            tAdifSRX_STRING:
               temps.SRX_String := fieldValue;

            tAdifSTATE:
               temps.State := fieldValue;

            tAdifSTX:
               exch.NumberSent := StrToInt(fieldValue);

            tAdifSTX_STRING:
               temps.STX_String := fieldValue;

            tAdifSUBMODE:
               begin
               msm := GetADIFSubMode(fieldValue);
               exch.Mode    := msm.msmMode;
               exch.ExtMode := msm.msmExtendedMode;
               end;

            tAdifTEN_TEN:
               exch.TenTenNum := StrToInt(fieldValue);

            tAdifVE_PROV:
               temps.VE_Prov := fieldValue;

            tAdifAPP_TR4W_HQ, tAdifAPP_N1MM_HQ:
               temps.APP_HQ := fieldValue;

            tAdifSTATION_CALLSIGN:
               ; // ignored on import

            tAdifQTH:
               exch.QTHString := fieldValue;

            tAdifPROGRAMID:
               if fieldValue = 'WSJT-X' then
                  temps.FromWSJTX := True;

            tAdifAPP_N1MM_EXCHANGE1:
               // N1MM stores CLASS in APP_N1MM_EXCHANGE1 instead of
               // the standard CLASS field.  Map back depending on
               // the active contest.
               if exch.ceContest in [ARRLFIELDDAY, WINTERFIELDDAY] then
                  exch.ceClass := AnsiUpperCase(fieldValue)
               else if exch.ceContest in [FOCMARATHON] then
                  exch.Power := fieldValue;

            tAdifAPP_N1MM_ID, tAdifAPP_TR4W_ID:
               if IsValidGUID(fieldValue) then
                  exch.id := fieldValue;

            tAdifSIG:
               temps.SIG := fieldValue;

            tAdifSIG_INFO:
               temps.SIG_Info := fieldValue;

            tAdifPOTAREF:
               temps.POTARef := fieldValue;

            // X-QSO markers (Issue #750).  Three different field
            // conventions in the wild; recognize all of them so an ADIF
            // exported from TR4W, N1MM, or DXLog.net round-trips into
            // TR4W with the X-QSO flag preserved.  TR4W and N1MM use
            // CLAIMEDQSO = '0' to mean "X-QSO"; DXLog.net uses XQSO = 'Y'.
            // Any non-claimed value sets the flag; presence with the
            // claimed value (TR4W/N1MM '1', DXLog '0' or 'N') leaves it
            // False so we don't overwrite a True already set by an
            // earlier field on the same record.
            tAdifAPP_TR4W_CLAIMEDQSO, tAdifAPP_N1MM_CLAIMEDQSO:
               if Trim(fieldValue) = '0' then
                  exch.ceXQSO := True;

            tAdifAPP_DXLOG_XQSO:
               if (Trim(fieldValue) = 'Y') or (Trim(fieldValue) = 'y') then
                  exch.ceXQSO := True;

         else
            // Unknown / unhandled field.  Silently accept anything
            // prefixed with APP_ (third-party extensions).  Log others.
            if Copy(fieldName, 1, 4) <> 'APP_' then
               logger.Warn('[ApplyADIFFields] %s is present but no handler',
                           [fieldName]);
         end;

      except
         on e: Exception do
            begin
            Result := False;
            logger.Warn('[ApplyADIFFields] %s=[%s] threw: %s',
                        [fieldName, fieldValue, e.Message]);
            end;
      end;
      end;
end;

// ---------------------------------------------------------------------------
// Multi-record entry point
// ---------------------------------------------------------------------------

// Initialize a ContestExchange to a sane "no record yet" state.  Matches
// the parts of MainUnit/trdos's ClearContestExchange that the ADIF
// parser depends on (specifically: Mode = NoMode so the MODE-handler
// guard `if exch.Mode = NoMode then ...` fires, and a few other
// sentinels that distinguish "not seen" from "seen as zero").  Does NOT
// touch ceContest (caller's job, normally via the ADIF CONTEST_ID
// field) or any field that depends on MainUnit globals.
procedure InitContestExchangeForParse(var exch: ContestExchange);
const
   // ClearContestExchange uses -1 / MAXWORD / MAXBYTE as "not set" sentinels.
   // Windows.MAXWORD is $FFFF; declared locally to avoid `uses Windows`.
   SENTINEL_WORD = $FFFF;
begin
   FillChar(exch, SizeOf(exch), 0);
   exch.Band           := NoBand;
   exch.Mode           := NoMode;
   exch.ExtMode        := eNoMode;
   exch.NumberReceived := SENTINEL_WORD;
   exch.NumberSent     := SENTINEL_WORD;
   exch.TenTenNum      := SENTINEL_WORD;
   exch.Zone           := DUMMYZONE;
   exch.QTH.Zone       := DUMMYZONE;
end;

function ImportADIFFromString(const s: string;
                              var records: TContestExchangeArray): Integer;
var
   p          : Integer;
   sLen       : Integer;
   eorPosUp   : Integer;
   eohPosUp   : Integer;
   sUpper     : string;
   chunk      : string;
   fields     : TADIFFieldList;
   exch       : ContestExchange;
   temps      : TADIFRecordTemps;
   recordEnd  : Integer;
begin
   Result := 0;
   SetLength(records, 0);
   sLen := Length(s);
   if sLen = 0 then
      Exit;

   sUpper := AnsiUpperCase(s);

   // Skip optional ADIF header (everything up to and including <EOH>).
   eohPosUp := AnsiPos('<EOH>', sUpper);
   if eohPosUp > 0 then
      p := eohPosUp + 5   // length of '<EOH>'
   else
      p := 1;

   while p <= sLen do
      begin
      // Find the next <EOR> (case-insensitive) starting at p.
      eorPosUp := PosEx('<EOR>', sUpper, p);
      if eorPosUp = 0 then
         Break;  // no more complete records

      recordEnd := eorPosUp + 5;  // include the '<EOR>' itself
      chunk := Copy(s, p, recordEnd - p);

      // Lex + apply
      ParseADIFFieldsList(chunk, fields);
      InitContestExchangeForParse(exch);
      InitADIFRecordTemps(temps);
      ApplyADIFFieldsToExchange(fields, exch, temps);

      SetLength(records, Result + 1);
      records[Result] := exch;
      Inc(Result);

      p := recordEnd;
      end;
end;

// ---------------------------------------------------------------------------
// Export side
// ---------------------------------------------------------------------------

function GetStateForContest(c: ContestType): string;
begin
   case c of
      CALQSOPARTY        : Result := 'CA';
      FLORIDAQSOPARTY    : Result := 'FL';
      MICHQSOPARTY       : Result := 'MI';
      MINNQSOPARTY       : Result := 'MN';
      MOQSOPARTY         : Result := 'MO';
      NCQSOPARTY         : Result := 'NC';
      OHIOQSOPARTY       : Result := 'OH';
      TEXASQSOPARTY      : Result := 'TX';
      WISCONSINQSOPARTY  : Result := 'WI';
      TENNESSEEQSOPARTY  : Result := 'TN';
      COLORADOQSOPARTY   : Result := 'CO';
      PAQSOPARTY         : Result := 'PA';
      INQSOPARTY         : Result := 'IN';
   else
      Result := '';
   end;
end;

function EmitADIFField(const name, value: string): string;
begin
   if value = '' then
      Result := ''
   else
      Result := SysUtils.Format('<%s:%u>%s ', [name, Length(value), value]);
end;

function EmitADIFHeader(const programVersion: string): string;
begin
   Result :=
      EmitADIFField('ADIF_VER', '3.1.0') + #13#10 +
      EmitADIFField('CREATED_TIMESTAMP',
                    FormatDateTime('yyyymmdd hhnnss', Now)) + #13#10 +
      EmitADIFField('PROGRAMID', 'TR4W') + #13#10 +
      EmitADIFField('PROGRAMVERSION', programVersion) + #13#10 +
      '<EOH>'#13#10;
end;

// ----- Per-field helpers used by EmitADIFRecord -----------------------

// Format an integer with at least minLen digits (zero-padded).
function PadInt(n: Integer; minLen: Integer): string;
begin
   Result := IntToStr(n);
   while Length(Result) < minLen do
      Result := '0' + Result;
end;

// Determine the (MODE, SUBMODE) ADIF tag pair for a ContestExchange
// based on its ExtMode.  Mirrors the mapping in PostUnit.ExportToADIF
// (the if/else chain on TempRXData.ExtMode).
procedure ResolveADIFModeSubmode(const rec: ContestExchange;
                                  out modeStr, subModeStr: string);
begin
   modeStr := '';
   subModeStr := '';

   if rec.ExtMode = eNoMode then
      begin
      // No extended mode -- use base Mode.  Special case kept from the
      // legacy export: Digital with no ExtMode emits as RTTY (issue 457).
      if rec.Mode = Digital then
         modeStr := 'RTTY'
      else
         modeStr := ADIFModeString[rec.Mode];
      end
   else if rec.ExtMode = eUSB then
      begin
      modeStr    := 'SSB';
      subModeStr := 'USB';
      end
   else if rec.ExtMode = eLSB then
      begin
      modeStr    := 'SSB';
      subModeStr := 'LSB';
      end
   else if rec.ExtMode = ePSK31 then
      begin
      modeStr    := 'PSK';
      subModeStr := ExtendedModeStringArray[rec.ExtMode];
      end
   else if rec.ExtMode = eFT4 then
      begin
      modeStr    := 'MFSK';
      subModeStr := ExtendedModeStringArray[rec.ExtMode];
      end
   else
      modeStr := ExtendedModeStringArray[rec.ExtMode];
end;

// Format a frequency (Hz) as an ADIF FREQ string in MHz.  Uses '.'
// as decimal regardless of locale (ADIF spec requires it).
function FormatADIFFreq(freqHz: LongInt): string;
var
   saveSep : Char;
begin
   if freqHz = 0 then
      begin
      Result := '';
      Exit;
      end;
   saveSep := DecimalSeparator;
   try
      DecimalSeparator := '.';
      Result := FloatToStr(freqHz / 1000000);
   finally
      DecimalSeparator := saveSep;
   end;
end;

// Compose a state-QP rover call's bare-and-rover form.  When the
// callsign has a '/<county>' suffix that matches the QSO's QTHString,
// returns (bareCall, fullCall).  Otherwise returns (callsign, '').
procedure ResolveRoverCall(const rec: ContestExchange;
                            out bareCall, roverFullCall: string);
var
   callStr     : string;
   slashPos    : Integer;
   suffix      : string;
begin
   bareCall := string(rec.Callsign);
   roverFullCall := '';
   // Only relevant for state-QP exchanges.
   if not ContestsArray[rec.ceContest].CountyLineAllowed then
      Exit;
   callStr := bareCall;
   slashPos := Pos('/', callStr);
   if slashPos = 0 then
      Exit;
   suffix := Copy(callStr, slashPos + 1, Length(callStr) - slashPos);
   if (suffix <> '') and
      (UpperCase(suffix) = UpperCase(string(rec.QTHString))) then
      begin
      roverFullCall := callStr;
      bareCall := Copy(callStr, 1, slashPos - 1);
      end;
end;

// Build the SRX_STRING value with RST normalization -- mirrors the
// commit f048dc7 logic in PostUnit.PAS.
function ResolveSRXString(const rec: ContestExchange): string;
var
   rstStr   : string;
   exch     : string;
   prefix   : string;
begin
   exch := string(rec.ExchString);
   rstStr := IntToStr(rec.RSTReceived);
   prefix := rstStr + ' ';
   if (exch <> '') and (Copy(exch, 1, Length(prefix)) = prefix) then
      Result := exch
   else if exch = '' then
      Result := rstStr
   else
      Result := rstStr + ' ' + exch;
end;

// ----- EmitADIFRecord -------------------------------------------------

function EmitADIFRecord(const rec: ContestExchange): string;
var
   bareCall       : string;
   roverFullCall  : string;
   bandStr        : string;
   modeStr        : string;
   subModeStr     : string;
   freqStr        : string;
   stateForQP     : string;
begin
   ResolveRoverCall(rec, bareCall, roverFullCall);

   // BAND string -- mirror the legacy 70cm/23cm rewrites.
   bandStr := string(ADIFBANDSTRINGSARRAY[rec.Band]);
   if bandStr = '432' then bandStr := '70cm';
   if bandStr = '1GH' then bandStr := '23cm';

   ResolveADIFModeSubmode(rec, modeStr, subModeStr);
   freqStr := FormatADIFFreq(rec.Frequency);

   Result := '';

   // Identification + timestamps
   Result := Result + EmitADIFField('CALL', bareCall);
   Result := Result + EmitADIFField('BAND', bandStr);
   Result := Result + EmitADIFField('QSO_DATE',
      SysUtils.Format('%.4d%.2d%.2d',
         [rec.tSysTime.qtYear + 2000,
          rec.tSysTime.qtMonth,
          rec.tSysTime.qtDay]));
   Result := Result + EmitADIFField('TIME_ON',
      SysUtils.Format('%.2d%.2d%.2d',
         [rec.tSysTime.qtHour,
          rec.tSysTime.qtMinute,
          rec.tSysTime.qtSecond]));
   Result := Result + EmitADIFField('TIME_OFF',
      SysUtils.Format('%.2d%.2d%.2d',
         [rec.tSysTime.qtHour,
          rec.tSysTime.qtMinute,
          rec.tSysTime.qtSecond]));

   // RST and exchange
   Result := Result + EmitADIFField('RST_SENT', IntToStr(rec.RSTSent));
   Result := Result + EmitADIFField('RST_RCVD', IntToStr(rec.RSTReceived));

   // APP_TR4W_ROVERCALL (full rover form, e.g. KG1S/MON)
   if roverFullCall <> '' then
      Result := Result + EmitADIFField('APP_TR4W_ROVERCALL', roverFullCall);

   // CONTEST_ID, unless POTA/GENERALQSO (legacy behaviour).
   // Mirror the fallback used by LOGSUBS2.PAS:2782, uGetScores.pas:435 and 564:
   // if ContestsArray[].ADIFName is empty (true for 156 of TR4W's contests),
   // fall back to the parallel ContestTypeSA[] string, which IS the standard
   // ADIF Contest_ID for the major contests (e.g. 'CQ-WPX-SSB', 'CQ-WW-CW',
   // 'ARRL-DX-CW').  This was the behaviour before Issue #887's extraction;
   // it did not survive the move into uADIF.pas.
   if not (rec.ceContest in [POTA, GENERALQSO]) then
      begin
      if Length(ContestsArray[rec.ceContest].ADIFName) = 0 then
         Result := Result + EmitADIFField('CONTEST_ID',
            string(ContestTypeSA[rec.ceContest]))
      else
         Result := Result + EmitADIFField('CONTEST_ID',
            string(ContestsArray[rec.ceContest].ADIFName));
      end;

   // MODE / SUBMODE
   Result := Result + EmitADIFField('MODE', modeStr);
   if subModeStr <> '' then
      Result := Result + EmitADIFField('SUBMODE', subModeStr);

   // FREQ (locale-independent, '.' separator)
   Result := Result + EmitADIFField('FREQ', freqStr);

   // SRX_STRING is NOT emitted here.  The correct shape depends on the
   // contest's exchange convention (does it include an implied RST?
   // is it a park ref?  is it the literal ExchString?), and that
   // knowledge lives in ExchangeInformation.RST (in trdos/LOGDUPE.PAS)
   // which uADIF deliberately does not depend on.  PostUnit's tail
   // emitter (EmitContestSpecificTailForExport) handles SRX_STRING
   // for all contests using ExchangeInformation -- see Issue #898.
   // ResolveSRXString below is exported as a helper for the tail
   // emitter's RST-normalizing branch.

   // STATE - only for single-state QSO parties, where the host state is
   // known from the contest type and QTHString is a county code.
   //
   // We deliberately do NOT infer STATE from a bare 2-char QTHString.
   // QTHString means different things per contest (an ARRL section, a
   // zone, a serial, a name, ...), so a "2 letters => it's a state"
   // heuristic mislabels section-based contests -- e.g. ARRL section
   // 'EB' (East Bay) is not the state 'EB'.  Contest-specific STATE that
   // must be derived (e.g. Field Day: section -> state) is emitted by the
   // PostUnit tail emitter, which has the contest knowledge to do it
   // correctly.  See Issue #1050.
   stateForQP := GetStateForContest(rec.ceContest);
   if (stateForQP <> '') and (rec.QTHString <> '') then
      Result := Result + EmitADIFField('STATE', stateForQP);

   // QTH - the "default" location field.  Always emit when QTHString
   // is non-empty.  Contests that prefer GRIDSQUARE/IOTA/ARRL_SECT
   // can override via the tail emitter.
   if rec.QTHString <> '' then
      Result := Result + EmitADIFField('QTH', string(rec.QTHString));

   // PRECEDENCE / CHECK
   if rec.Precedence <> #0 then
      Result := Result + EmitADIFField('PRECEDENCE', string(rec.Precedence));
   if rec.Check <> 0 then
      Result := Result + EmitADIFField('CHECK', PadInt(rec.Check, 2));

   // NAME / FOC_NUM / RX_PWR
   if rec.Name <> '' then
      Result := Result + EmitADIFField('NAME', string(rec.Name));
   if rec.Power <> '' then
      begin
      if rec.ceContest = FOCMARATHON then
         Result := Result + EmitADIFField('FOC_NUM', string(rec.Power))
      else
         Result := Result + EmitADIFField('RX_PWR', string(rec.Power));
      end;

   // SRX / STX (numeric serials).  Two "unset" sentinels are in use:
   //   $FFFF (65535) -- set by uADIF.InitContestExchangeForParse for
   //                    records built from imported ADIF
   //   -1            -- left in place by live-entry / binary-log
   //                    paths for contests that don't use a serial
   //                    (e.g. Field Day on the SRX side -- ExchString
   //                    carries class+section, NumberReceived stays
   //                    at its initialized value)
   // Without the >0 guard, FD records emit garbage like <SRX:5>000-1
   // because PadInt(-1, 5) produces the literal string "000-1".
   if (rec.NumberReceived > 0)      and
      (rec.NumberReceived <> $FFFF) then
      Result := Result + EmitADIFField('SRX', PadInt(rec.NumberReceived, 5));
   if (rec.NumberSent > 0)      and
      (rec.NumberSent <> $FFFF) then
      Result := Result + EmitADIFField('STX', PadInt(rec.NumberSent, 5));

   if rec.TenTenNum <> $FFFF then
      Result := Result + EmitADIFField('TEN_TEN', PadInt(rec.TenTenNum, 5));

   if rec.Age <> 0 then
      Result := Result + EmitADIFField('AGE', PadInt(rec.Age, 3));

   // OPERATOR + APP_TR4W_ID
   if rec.ceOperator <> '' then
      Result := Result + EmitADIFField('OPERATOR', string(rec.ceOperator));
   if rec.id <> '' then
      Result := Result + EmitADIFField('APP_TR4W_ID', string(rec.id));

   // APP_TR4W_CLAIMEDQSO (Issue #750).  Mirrors N1MM's
   // APP_N1MM_CLAIMEDQSO convention: '1' = normal QSO, '0' = X-QSO
   // (logged but not claimed for credit -- e.g. an off-band contact
   // kept for NIL protection of the other station).  Only emit for
   // X-QSO records so a grep of the ADIF for CLAIMEDQSO finds exactly
   // the not-claimed contacts; normal QSOs are implied by absence.
   // Lives in uADIF (not the tail emitter) because the value is
   // sourced directly from rec.ceXQSO -- no MainUnit/trdos globals
   // needed -- and because round-trip tests use a nil tail emitter.
   if rec.ceXQSO then
      Result := Result + EmitADIFField('APP_TR4W_CLAIMEDQSO', '0');
end;

function ExportADIFToString(const records: TContestExchangeArray;
                            const programVersion: string;
                            tailEmitter: TContestTailEmitter): string;
var
   i : Integer;
begin
   Result := EmitADIFHeader(programVersion);
   for i := 0 to High(records) do
      begin
      Result := Result + EmitADIFRecord(records[i]);
      if Assigned(tailEmitter) then
         Result := Result + tailEmitter(records[i]);
      Result := Result + '<EOR>'#13#10;
      end;
end;

initialization
   logger := TLogLogger.GetLogger('uADIF');
   saveLastADIFName := '';

end.
