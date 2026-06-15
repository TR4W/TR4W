
{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
 Public License along with TR4W in GPL_License.TXT.
If not, ref:
http://www.gnu.org/licenses/gpl-3.0.txt
 }

unit MainUnit;

{$IMPORTEDDATA OFF}

interface

uses
  ShellAPI,
  Logstuff,
  uADIF,
  uMenu,
  uAltD,
  uMessagesList,
  uMMTTY,
  utils_net,
  utils_text,
  uCallSignRoutines,
  uCallSigns,
  uCTYDAT,
  uBMCF,
  uIO,
  uQuickEdit,
  utils_file,
  { $ IF LANG = 'RUS'}
  HtmlHelp,
  { $ IFEND}

  // ShellAPI,
  uMults,
  // uSelectFile,
  // uHardWare,
  uErmak,
  uCheckLatestVersion,
  // uMakeHelpFile,
  uAltP,
  MMSystem,
  uMP3Recorder,
  uCRC32,
  uCFG,
  // uRemMults_DX,
  // uRemMults_DOM,
  // uRemMults_Zone,
  // uAbout,
  uWinKey,
  // uDXSSpotsFilter,
  // uSpotsFilter,
  // uMultsFrequencies,
  // uStack,
  uStations,
  uGetScores,
  uSpots,
  uIntercom,
  uLogEdit,
  uGetServerLog,
  uMessages,
  uCommctrl,
  uMixW,
  LPT,
  uQTCS,
  uQTCR,
  uCbrSum,
  PostUnit,
  uWinManager,
  uBandmap,
  TF,
  Version,
  VC,
  uGradient,
  uNet,
  uCAT,
  uAutoCQ,
  uFileView,
  uTelnet,
  uFunctionKeys,
  uRadio12,
  uOption,
  uSendKeyboard,
  uSendSpot,
  uDupesheet,
  uRemMults,
  // uReminder,
  uTotal,
  uMaster,
  uInputQuery,
  uEditQSO,
  uSynTime,
  uBeacons,
  uDialogs,
  uMissingMults,
  uLogSearch,
  Windows,
  Messages,
  LogK1EA,
  BeepUnit,
  //LOGDDX,
  LogDom,
  LogDupe,
  LOGDVP,
  LogEdit,
  LogGrid,
  // LOGMENU,
  LogNet,
  LogPack,
  LogRadio,
  LogSCP,
  LOGSUBS1,
  LOGSUBS2,
  LOGWAE,
  LogWind,
  Tree,
  SysUtils,
  StrUtils,
  Dialogs,
  ZoneCont,
  classes,
  IdGlobal,
  uWSJTX,
  uDXLabPathfinder,
  Math,
  Log4D,
  Controls,
  uNetRadioBase,
  uRadioBand,
  uExternalLogger,
  IdURI
  ;

var
  Begin_QSO: boolean = False; // 4.115.3
  JA_Switch: boolean = False; // 4.72.5
  VK_Switch: boolean = False; // 4.72.5
  K_Switch: boolean = False; // 4.72.5
  VE_Switch: boolean = False; // 4.72.5
  PTT_SET: boolean = False; //4.53.9
  InSplit: boolean = False;
  StartCPU: DWORD;
  STString: Str10; // 4.56.7
  Switch: boolean = False;
  SwitchNext: boolean = False; // 4.52.3
  CallWinKeyDown: boolean = False; // 4.52.4
  CallWindowCharConsumed: boolean = False; // set by CallWindowKeyDownProc when it fully handles a char
  FontS: integer;
  FirstQSO: Cardinal;
  T1: Cardinal;
  Esc_Counter: integer = 0;
  Call_Found: Boolean = False;
  Second: Boolean = False;
  Third: Boolean = False;
  wsjtx: TWSJTXServer;
  externalLogger: TExternalLogger;
  // saveLastADIFName / saveLastContest cache moved to uADIF.pas with
  // GetContestByADIFName (Issue #887).
  logger: TLogLogger;
  appender: TLogFileAppender;
  s1, s2, s3, s4: str20;
  Exchw: str20;
  Callw: str20;
  Act_Freq: Cardinal = 0;
  Act_Band: BandType;
  Inact_Freq: Cardinal = 0;
  Inact_Band: BandType;
  so2r_swap: boolean = false;
function CreateToolTip(Control: HWND; Text: PChar): HWND;

function DeviceIoControlHandler
  (
  code: ULONG;
  pBuffer: PChar;
  InputBufferLength:
  ULONG; OutputBufferLength:
  ULONG; pOutputLength: PULONG
  ): Cardinal;

function IsWin64: Boolean;
function ConvertPortTypeToCOMString(port: PortType): string;
function GetLocalComputerName: string;
procedure CheckNumber;
procedure RunPlugin(PluginNumber: integer);
procedure LoadInPlugins();
procedure OpenListOfMessages;
procedure OpenStationInformationWindow(dwInitParam: lParam);
procedure RenameCommands();
procedure RichEditOperation(Load: boolean);
function GetAddMultBand(Mult: TAdditionalMultByBand; Band: BandType): BandType;
procedure scWK_RESET; // n4af 4.43.10
procedure SetCommand(c: PChar);
procedure ChangeFocus(Text: PChar);
procedure ImportFromADIF;
procedure StartNewContest;
procedure CheckQuestionMark;
function Get101Window(h: HWND): HWND;
function TelnetWantsClipboardKey(const aMsg: TMsg): boolean;   // Issue #23
procedure InvertBooleanCommand(Command: PBoolean);
procedure RunExplorer(Command: PChar);
procedure OpenInDefaultTextEditor(FileName: PChar);   // Issue #986
procedure RunOptionsDialog(f: CFGFunc);
procedure OpenUrl(url: PChar);
function ParseADIFRecord(sADIF: string; var exch: ContestExchange): boolean;
procedure ProcessImportedSRX_String(fieldValue: string; var exch:
  ContestExchange);
// GetContestByADIFName moved to uADIF.pas (Issue #887).
procedure SetExtendedModeFromMode(RData: ContestExchange);
function GetTR4WBandFromNetworkBand(band: TRadioBand): BandType;
function GetRadioBandFromBandType(band: BandType): TRadioBand;
procedure GetTRModeAndExtendedModeFromNetworkMode(netMode: TRadioMode; var mode:
  ModeType; var extMode: extendedModeType);

{$IF MORSERUNNER}
function GetMorseRunnerWindow: boolean;
function EnumMorseRunnerChildProc(wnd: HWND; l: lParam): BOOL; stdcall;
{$IFEND}

procedure ShowHelp(Topic: PChar);
procedure LoadinLog;
procedure tAddContestExchangeToLog(RXData: ContestExchange; ListViewHandle:
  HWND; var Index: integer);

function CreateEditableLog(Parent: HWND; X, Y, Width, Height: integer;
  DefaultSize: boolean): HWND;
procedure CreateListView(Parent: WindowsType; Window: TMainWindowElement; Style:
  integer);

procedure GenerateCallsignsList(FileName: PChar);
procedure MakeAllCallsignsList;

procedure showint(Num: integer);
procedure ShowMessage(Text: PChar);
procedure ShowMessage2(Text: PChar);
procedure ShowMessageParent(Text: PChar; Parent: HWND);
procedure ShowSyserror(ErrorCode: Cardinal);
procedure FilePreview;

procedure tCallWindowSetFocus;
procedure tExchangeWindowSetFocus;
procedure tRuntPaddleAndFootSwitchThread;
//procedure TryToLoadRICHED32DLL;
procedure InitializeQSO;
function CreateCallOrExchangeWin(Top, ID: integer): HWND;
procedure TimeApplet(i: Cardinal);

function YesOrNo(h: HWND; Text: PChar): integer;
function YesOrNo2(h: HWND; Text: PChar): integer;
procedure PTTOffWhenStopWAV(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;
procedure OneSecTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;
procedure BandMapRefreshTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;

procedure SaveTR4WPOSFILE;
procedure LoadTR4WPOSFILE;

procedure FrmSetFocus;
procedure tAltE;
procedure SetWindowSize;
procedure WINDOWPOSCHANGINGPROC(var p: PWindowPos);
function OpenLogFile: boolean;
function tSetFilePointer(lDistanceToMove: LONGINT; dwMoveMethod: DWORD):
  Cardinal;

procedure CloseLogFile;
function ReadLogFile: boolean;
procedure ShowPreviousDupeQSOsWnd(show: boolean);
procedure DestroyPreviousDupeQSOsWnd;
procedure FlashPreviousDupeQSOsWnd(show: boolean);
procedure TryPutSpaceinExchangeWindow;
procedure ShowInformation;
procedure QuickQSLProcedure(Key: Char);
procedure StartSendingNow(FromKeyBoard: boolean);
procedure ClearLog;
procedure ReadVersionBlock;
procedure MakeTestLog;
procedure PlaceCaretToTheEnd(wnd: HWND);
//function TryToCheckTheLatestVersion: boolean;
procedure tGetSystemTime;
procedure ShowLogPopupMenu(wnd: HWND);
procedure SystemTimeChanging;
procedure DefTR4WProc(Msg: Cardinal; var lp: integer; wnd: HWND);
function AddRecordToLogAndSendToNetwork(var CE: ContestExchange): boolean;
procedure CompleteCallsign;
function NewCallWindowProcedure(hwnddlg: HWND; Msg: UINT; wParam: wParam;
  lParam: lParam): UINT; stdcall;
function GetRealVirtualKey(var Key: integer): Byte;
procedure Escape_proc;
function GetCPU: int64;
function TuneOnFreqFromCallWindow: boolean;
procedure ReturnInCQOpMode;
procedure ReturnInSAPOpMode;
function Send_DE: boolean;
procedure SendB4;
// procedure ProcessKeyDownTerm; // 4.46.2
function TryLogContact: boolean;
procedure SpaceBarProc;
procedure SpaceBarProc2;

procedure FindAndSaveRectOfAllWindows;
procedure sm1;
function TryKillAutoCQ: boolean;
procedure RunAutoCQ;

procedure TestMP;
procedure tSetWindowLeft(h: HWND; Left: integer);
procedure FlashCallWindow;
procedure ProcessCommandLine;
procedure PutCallToCallWindow(Call: CallString);
procedure SetColumnsWidth;
procedure EnsureListViewColumnVisible(h: HWND);
procedure SaveColumnWidthToConfig(ColIndex: Integer; NewWidth: Integer);
procedure ExecuteConfigurationFile(f: ShortString);
procedure CheckEditableWindowHeight;
function CheckCommandInCallsignWindow: boolean;
procedure ClearMultSheet_CtrlC;
procedure tClearMultSheet;
procedure ReCalculateHourDisplay;
procedure SetRemMultsColumnWidth;
procedure tEnumeratePorts;
function KeyerDebugDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
procedure CheckInactiveRigCallingCQ;
function CheckWindowAndColor(Window: HWND; var Brush: HBRUSH; var Color:
  integer): boolean;
procedure tAltI;
procedure tr4w_alt_n_transmit_frequency;
procedure tr4w_toggle_sidetone;
procedure tClearDupesheet_Ctrl_K;
procedure tClearDupesheet;
procedure tr4w_add_note_in_log;
procedure tr4w_log_qso_without_cw;
procedure tr4w_ShutDown;
procedure CallWindowChange;
procedure ExchangeWindowChange;
procedure CreateFonts;
//procedure CreateMWFonts;
function tCreateFont(nHeight, fnWeight: integer; lpszFace: PChar): HFONT;
function DrawWindows(lParam: lParam; wParam: wParam): Cardinal;
//function DrawEdit(lParam: lParam; wParam: wParam): Cardinal;
procedure ProcessMenu(menuID: integer);
procedure ProcessTAB(lowparam: Word);
procedure ProcessReturn;
procedure CreateMainWindow;
procedure CreateMultsWindows;
procedure CreateQSONeedWindows;
procedure CallWindowKeyDownProc(wParam: integer);
procedure CallWindowKeyUpProc;
procedure ExchangeWindowKeyDownProc(wParam: integer);
procedure RepeatLastCWMessage;
procedure OpenTR4WWindow(ID: WindowsType);
procedure OpenOtherWindows;
procedure CloseTR4WWindow(ID: WindowsType);
function CreateTR4WStaticWindow(X: Word; Y: Word; w: Word; Style: Cardinal):
  HWND;
function CreateTR4WStaticWindowID(X: Word; Y: Word; w: Word; Style: Cardinal;
  ID: HMENU): HWND;
function nfCreateTR4WStaticWindow(Text: PChar; X: Word; Y: Word; w: Word; Style:
  Cardinal): HWND;

procedure EditSetSelLength(h: HWND; Value: integer);
procedure SetOpMode(OperationMode: OpModeType);
procedure ProcessFuntionKeys(Key: integer);
procedure CreateDirectoryIfNotExist;
procedure CheckAndSetInitialExchangeCursorPos;
procedure ClearInfoWindows;
procedure CPUButtonProc;
procedure TREscapeCommFunction(hFile: THandle; dwFunc: Byte);
function Get_Ctl_Code(nr: integer): Cardinal;
procedure DebugMsg(s: string); // ny4i
procedure DebugRadioTempBuffer(sDecorator: string; var bRay: array of char);
// ny4i Issue 145
function IsCWByCATActive(theRadio: RadioPtr): boolean; overload;
// ny4i Issue # 111
function IsCWByCATActive: boolean; overload; // ny4i Issue # 111

// ADIFDateStringToQSOTime, ADIFTimeStringToQSOTime moved to uADIF.pas (Issue #887).
function DigitsIn(n: smallInt): byte;
function GetModeFromExtendedMode(extMode: ExtendedModeType): ModeType;

function ParametersOkay(Call: CallString;
  ExchangeString: Str40 {CallString};
  Band: BandType;
  Mode: ModeType;
  Freq: LONGINT;
  var RData: ContestExchange): boolean;

procedure PossibleCallsProc(PCDRAWITEMSTRUCT: PDrawItemStruct);

procedure CreateTotalWindow;
procedure ChangeCaret(h: HWND);
procedure EditableLogWindowDblClick;
procedure tClearDupeInfoCall;
procedure tCleareCallWindow;
procedure tCleareExchangeWindow;
procedure tSetExchWindInitExchangeEntry;
procedure HandleRepeatPOTAParks;
procedure tListBoxClientAlign(Parent: HWND);
//function AddCallsignAndExchangeToInitialExchangesList(Call: CallString; InitialExchangeString: CallString): boolean;
//function FindStringInInitCallsignListBox(s: CallString; var Index: integer): boolean;

procedure tWinHelp(WindowHelpID: Byte);

function AskConvertLog(sVersion: string): boolean; // ny4i

function tCreateStaticWindow(lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;
function tCreateButtonWindow(dwxStyle: DWORD; lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;

function tCreateEditWindow(dwxStyle: DWORD; lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;
procedure CreateOKCancelButtons(nWidthhwndParent: HWND);

function tCreateComboBoxWindow(dwStyle: DWORD; X, Y, nWidth,
  {nHeight: integer; }hwndParent: HWND; HMENU: HMENU): HWND;

procedure UpdateWindows;
function CreateProgress32InMainWindow(Left: integer; Top: integer; Color:
  integer): HWND;
procedure tUpdateLog(UpdAction: UpadateAction);
//procedure SelectFileOfFolder(Parent: HWND; FileName: PChar; Mask: PChar; SelectType: CFGType);

//procedure main(LogFileName: pchar; var CreatedReport: pchar; var ReLoadLog: boolean); stdcall external 'Plugins/tr4wSortLog.dll' name 'main';

procedure PTTOn;
procedure PTTOff;

procedure ResetRadioPorts;
procedure WagCheck;

type
  Tmain = procedure(
    LogFileName: PChar;
    var CreatedReport: PChar;
    var ReLoadLog: boolean;
    var MakeRescore: boolean;
    ExchangeInformation: ExchangeInformationRecord;
    ActiveExchange: ExchangeType;
    reserved1: integer;
    reserved2: integer;
    reserved3: integer
    ) stdcall;

  Ttr4wGetPlugin = function(): PChar; stdcall;

// TADIF_Fields enum moved to uADIF.pas (Issue #887).

var
  FreeMemCount: integer;
  ReallocMemCount: integer;
  OldMemMgr: TMemoryManager;
  PreviousProcAddress: integer;
  debugstr: string;
const
  PCharDayTags: array[0..6] of PChar = (TC_SUN, TC_MON, TC_TUE, TC_WED, TC_THU,
    TC_FRI, TC_SAT);
  CWByCATBufferTerminator = Chr(242);
  tAboutText =
    TR4W_CURRENTVERSION +
    ' - ' +
    TR4W_CURRENTVERSIONDATE +
    #13 +
    '2006 - 2012 Dmitriy Gulyaev UA4WLI' + #13 +
    'TR4WSERVER version - ' + TR4WSERVER_CURRENTVERSION + #13#13 +
    'http://www.tr4w.net'#13#10

  // 'Log format version - v.1.' + LOGVERSION4 + #13 +
  // 'Compiler directives: ['{$IFOPT I+} + 'I'{$ENDIF}{$IFOPT R+} + 'R'{$ENDIF}{$IFOPT Q+} + 'Q'{$ENDIF} + ']'
{$IF LANG <> 'ENG'} + #13'Language: ' + TC_TRANSLATION_LANGUAGE + ' (by ' +
  TC_TRANSLATION_AUTHOR + ')'{$IFEND} + #13#10 +
  'On basis of the source code of the TRLog v.6.80 UA4WLI + Larry Tyree N6TR' + #13
    + //n4af 4.30.0
  'Current development team = N4AF, NY4I, UR7QM '; //n4af 4.30.0
  // Radio1AsPchar : PChar = TC_RADIO1;
  // Radio2AsPchar : PChar = TC_RADIO2;

implementation

uses
{$IF tDebugMode}
  // uDocumentation,
{$IFEND}

  uRadioPolling,
  uHamScore,        // Issue #783 -- HamScoreResyncFromScratch (Tools menu)
  LogCfg,
  LogCW,
  uCT1BOH,
  CFGCMD,
  CFGDEF,
  // ColorCfg,
  // Country9,
  FCONTEST,
  uPOTAParks,
  uPendingCounties,
  uCTYUpdate,
  Types;

function GetCPU: int64;
begin
  asm
db 0fh,31h
mov dword ptr result,eax
mov dword ptr result[4],edx
  end;
  Result := Result;
end;

function GetLocalComputerName: string;
var
  c1: dword;
  arrCh: array[0..MAX_PATH] of char;
begin
  c1 := MAX_PATH;
  GetComputerName(arrCh, c1);
  if c1 > 0 then
    result := arrCh
  else
    result := '';
end;

// Logs additional QSO records when the operator entered multiple POTA park
// references or multiple counties in a single exchange.  The parser
// (ProcessRSTAndPOTAPark / ProcessRSTAndDomesticQTHExchange) places extras
// onto uPOTAParks's or uPendingCounties's queue; this procedure drains both
// queues and writes one extra QSO per queued ref.
//
// Kept in its own procedure rather than inlined into TryLogContact so the
// extra ReceivedData accesses do not push TryLogContact past the threshold
// where Delphi 7 pins @ReceivedData into ESI as an optimization (an
// optimization that interacts badly with the calls in this drain logic and
// produced an AV at TryLogContact's later @ReceivedData accesses).
//
// Issue #885 (county lines) and POTA Nfer.

// Build the per-QSO exchange string in <RST> <QTH> form so each multi-ref
// QSO gets its own ADIF SRX_STRING instead of the combined original input.
// Issue #889.
function PerQSOExchString(const RXData: ContestExchange): string;
begin
  Result := IntToStr(RXData.RSTReceived) + ' ' + string(RXData.QTHString);
end;

procedure DrainPendingMultiQSORefs;
var
  TempRX : ContestExchange;
begin
  if (not HasPendingParks) and (not HasPendingCounties) then
    Exit;
  TempRX := ReceivedData;
  while HasPendingParks do
    begin
    TempRX.QTHString := DequeuePendingPark;
    TempRX.ExchString := PerQSOExchString(TempRX);   // Issue #889
    LogContact(TempRX, True);
    end;
  while HasPendingCounties do
    begin
    TempRX.QTHString := DequeuePendingCounty;
    FoundDomesticQTH(TempRX);  // refresh DomMultQTH/DomesticQTH
    TempRX.ExchString := PerQSOExchString(TempRX);   // Issue #889
    // QSO-party rule: a station that changes county is a new station and
    // is NOT a dupe of an earlier QSO with the same call.  The follow-up
    // county records share callsign+band+mode with the first one, so the
    // generic dupe check would otherwise flag them, blank their points,
    // and emit "AF4O is a dupe and will be logged with zero QSO points."
    // Setting ceClearDupeSheet=True bypasses both LogContact's and
    // tUpdateLog(actRescore)'s dupe-stamping for this record only.
    TempRX.ceClearDupeSheet := True;
    // NumberSent is intentionally NOT incremented for county-line follow-up
    // records: per CQ Magazine guidance for the California QSO Party (and
    // other state QPs that combine serial numbers with county-line ops),
    // ALL legs of a single on-air exchange share the one transmitted serial
    // number.  Both records inherit it from the first.  See issue #892 for
    // the related "next station's serial jumps by N" question, which is a
    // separate architectural concern (TotalContacts/QSOTotals is bumped per
    // LogContact call rather than per distinct station worked).
    LogContact(TempRX, True);
    end;
end;

// State-QP rover slash-in-call ("KG1S/MON"):
//
// The operator types a call with a /COUNTY suffix to indicate the rover's
// current county.  TR4W keeps the call AS-IS in the log (KG1S/MON) so the
// operator's intent is preserved end-to-end.  Cabrillo emits the literal
// KG1S/MON; ADIF emits the bare call in the standard <CALL> field plus the
// full form in a TR4W-specific <APP_TR4W_ROVERCALL> field (handled at
// export time in PostUnit.PAS).
//
// At submit time (Enter, just before TryLogContact runs), if the operator
// has not already typed an exchange, move the county from the call's slash-
// suffix into the exchange field so the standard exchange parser sees a
// clean "MON" and produces the right multiplier / log row.  No keystroke-
// time interference — the operator can edit the call freely while typing.

// Detect a state-QP rover slash-in-call.  Returns True when:
//   - active exchange is a state-QP type
//   - CallWindowString contains a '/'
//   - the suffix validates as a domestic QTH (so /M, /P, /4 etc. are left
//     alone for other code paths to handle)
// On True, RoverCounty is populated with the validated county abbreviation.

// Wrap ctyLocateCall so a state-QP rover suffix (KG1S/MON) is stripped
// off the call before the country/zone lookup.  /M would otherwise be
// interpreted as a Great Britain prefix indicator, mislabeling the QSO
// with country=G.  The caller's Call value is unchanged; only the lookup
// uses the bare form.
//
// Falls through to plain ctyLocateCall behaviour when:
//   - active exchange is not a state-QP type
//   - the call has no '/'
//   - the suffix doesn't validate as a domestic QTH (e.g. /M, /P, /4)
//
// Used by ParametersOkay (live entry) and ParseADIFRecord at EOR (import).

function ctyLocateCallStripRover(const Call: CallString; var QTH: QTHRecord): Boolean;
var
  LookupCall  : CallString;
  SlashPos    : Integer;
  ProbeRX     : ContestExchange;
  FoundQTH    : Boolean;
  ProbeSuffix : string;
begin
  LookupCall := Call;
  logger.Info('[ctyLocateCallStripRover] ENTER Call=[%s] ActiveExchange=%d',
              [string(Call), Ord(ActiveExchange)]);
  if ((ActiveExchange = RSTDomesticQTHExchange) or
      (ActiveExchange = RSTQTHExchange) or
      (ActiveExchange = RSTDomesticOrDXQTHExchange)) then
     begin
     SlashPos := Pos('/', string(LookupCall));
     logger.Info('[ctyLocateCallStripRover] QP exchange, SlashPos=%d', [SlashPos]);
     if SlashPos > 0 then
        begin
        FillChar(ProbeRX, SizeOf(ProbeRX), 0);
        ProbeSuffix := UpperCase(
           Copy(string(LookupCall), SlashPos + 1,
                Length(string(LookupCall)) - SlashPos));
        ProbeRX.QTHString := ProbeSuffix;
        FoundQTH := FoundDomesticQTH(ProbeRX);
        logger.Info('[ctyLocateCallStripRover] suffix=[%s] FoundDomesticQTH=%s',
                    [ProbeSuffix, BoolToStr(FoundQTH, True)]);
        if FoundQTH then
           LookupCall := Copy(string(LookupCall), 1, SlashPos - 1);
        end;
     end
  else
     begin
     logger.Info('[ctyLocateCallStripRover] NOT a QP exchange, skipping strip', []);
     end;
  Result := ctyLocateCall(LookupCall, QTH);
  logger.Info('[ctyLocateCallStripRover] EXIT LookupCall=[%s] Result=%s CountryID=[%s] Prefix=[%s]',
              [string(LookupCall), BoolToStr(Result, True),
               string(QTH.CountryID), string(QTH.Prefix)]);
end;

function DetectRoverSlashInCall(out RoverCounty: string): Boolean;
var
  CallStr  : string;
  SlashPos : Integer;
  ProbeRX  : ContestExchange;
begin
  Result := False;
  RoverCounty := '';

  if not ((ActiveExchange = RSTDomesticQTHExchange) or
          (ActiveExchange = RSTQTHExchange) or
          (ActiveExchange = RSTDomesticOrDXQTHExchange)) then
     Exit;

  CallStr := string(CallWindowString);
  SlashPos := Pos('/', CallStr);
  if SlashPos = 0 then
     Exit;

  RoverCounty := UpperCase(Copy(CallStr, SlashPos + 1, Length(CallStr) - SlashPos));
  if RoverCounty = '' then
     Exit;

  // Validate the suffix against the domestic-mults table using a scratch
  // ContestExchange so we don't disturb any global state.
  FillChar(ProbeRX, SizeOf(ProbeRX), 0);
  ProbeRX.QTHString := RoverCounty;
  if not FoundDomesticQTH(ProbeRX) then
     Exit;  // /M, /P, /4 or any non-county suffix — leave alone

  Result := True;
end;

// When the operator hits Enter in the call window with a rover call
// ("KG1S/MON") and no exchange typed yet, copy the county from the call's
// slash-suffix into the exchange field and move focus there so the
// operator can confirm with another Enter to log.
//
// Called from the start of ReturnInCQOpMode / ReturnInSAPOpMode (the
// Enter-in-call-window handlers) — NOT from TryLogContact, which fires
// only when both call and exchange are filled.
//
// The call itself is left untouched: KG1S/MON is the operator's intent
// and survives through the log, Cabrillo, and the ADIF APP_TR4W_ROVERCALL
// field.

procedure PrefillExchangeFromRoverCallSuffix;
var
  RoverCounty : string;
begin
  if ExchangeWindowString <> '' then
     Exit;
  if not DetectRoverSlashInCall(RoverCounty) then
     Exit;
  ExchangeWindowString := RoverCounty;
  Windows.SetWindowText(wh[mweExchange], PChar(string(ExchangeWindowString)));
  // Move focus to exchange.  The caller's existing focus-move logic only
  // fires when ExchangeWindowString is empty (which won't be true after
  // we just populated it), so we have to do it ourselves here.
  if not LeaveCursorInCallWindow then
     tExchangeWindowSetFocus;
end;

function TryLogContact: boolean;
var
  // Saved before ClearContestExchange wipes ReceivedData; passed to
  // SetPendingContactInfo so the WM_POTA_NEXT_PARK handler can restore
  // the call and pre-fill the exchange after the caller's window clears.
  SavedCall    : CallString;
  SavedRSTSent : Integer;
  begin
  Result := False;

  if ParametersOkay(CallWindowString, ExchangeWindowString, ActiveBand,
    ActiveMode, ActiveRadioPtr.LastDisplayedFreq
    {LastDisplayedFreq[ActiveRadio]},
    ReceivedData) then
  begin
{$IF MORSERUNNER}
    if MorseRunnerWindow <> 0 then
      Windows.SendMessage(MorseRunner_Number, WM_KEYDOWN, VK_RETURN, 0);
{$IFEND}
    ReceivedData.ceSearchAndPounce := OpMode = SearchAndPounceOpMode;
    ReceivedData.ceComputerID := ComputerID;

    // Issue #889: when this is a multi-county or multi-park entry, the
    // parser has queued additional refs and ParametersOkay just stamped
    // ReceivedData.ExchString with the COMBINED original input
    // (e.g. "57 PIN/HIL").  Rewrite to per-QSO form for the first QSO so
    // each ADIF SRX_STRING reflects only its own ref.
    if HasPendingParks or HasPendingCounties then
       ReceivedData.ExchString := PerQSOExchString(ReceivedData);

    LogContact(ReceivedData, True);
    DrainPendingMultiQSORefs;

    // Capture before ClearContestExchange zeroes out ReceivedData.
    // Needed for 2fer refill below.
    SavedCall    := ReceivedData.Callsign;
    SavedRSTSent := ReceivedData.RSTSent;

    tElapsedTimeFromLastQSO := Windows.GetTickCount;
    UpdateWindows;
    // It is not clear to me why we would call SHowStationInformation again.
    ShowStationInformation(@ReceivedData.Callsign);
    ClearContestExchange(ReceivedData);
    LastTwoLettersCrunchedOn := '';
    CallAlreadySent := False;
    ExchangeHasBeenSent := False;
    EditingCallsignSent := False;
    SeventyThreeMessageSent := False;
    EscapeDeletedCallEntry := CallWindowString;

    if (CallWindowString = DupeInfoCall) and (CallWindowString <> MyCall) then
      // n4af issue 158
    begin
      DupeInfoCallWindowState := diNone;
      SetMainWindowText(mweDupeInfoCall, nil);
    end;
    // showint(1);
    tCleareCallWindow;
    // showint(2);

    tCleareExchangeWindow;

    tCallWindowSetFocus;
    CleanUpDisplay;

    // A prior bad-exchange attempt (e.g. TC_IMPROPERARRLFIELDDAYCLASS) leaves
    // an error in the QuickCommand window on its own 30s flash timer.  Once a
    // corrected QSO is logged that error is stale, so clear it now.
    ClearQuickDisplayText;

    Result := True;

    if OpMode = SearchAndPounceOpMode then
      SendSerialNumberChange(sntReserved);

    SendSerialNumberChange(sntFree);
    StationInformationCall := '';
    // Moved this to the very end of the process to log a contact. ny4i
  end;
end;

procedure ResetRadioPorts;
begin
  logger.info('Resetting radio ports');
  // CheckAndInitializePorts_ForThisRadio -> SetUpRadioInterface handles stopping
  // the old polling thread, disconnecting, freeing, and recreating the radio object.
  ActiveRadioPtr.CheckAndInitializePorts_ForThisRadio;
  InActiveRadioPtr.CheckAndInitializePorts_ForThisRadio;
end;

procedure Escape_proc;
var
  pRadio: RadioPtr;
  // ny4i used to make code cleaner Issue 94. Moved here with Issue #111
begin

  if CallWindowString <> '' then
    Call_Found := True
  else
    Call_Found := False;

  if ActiveMode in [Phone, FM] then
  begin
    if (ActiveRadioPtr^.RadioModel in RadioSupportsPlayDVK) { and
    (ActiveRadioPtr^.tPTTStatus = PTT_ON) } then
    begin
      ActiveRadioPtr^.MemoryKeyer(0); // Playing memory 0 stops the message.
    end;
  end;

  if (ActiveMode = CW) then
    // ny4i Issue 130 and (IsCWByCATActive) then // n4af 4.45.5 proposed to allow
  begin
    if IsCWByCatActive(ActiveRadioPtr) then // Esc always stops sending
      ActiveRadioPtr^.StopSendingCW
    else if ISCWByCATActive(InactiveRadioPtr) then
    begin
      InactiveRadioPtr^.StopSendingCW;
    end;
  end;

  // SetOpMode(CQOpMode); // n4af 4.46.12

{$IF MORSERUNNER}
  if MorseRunnerWindow <> 0 then
  begin
    Windows.SendMessage(MorseRunnerWindow, WM_COMMAND, 0, 0);
  end;
  Exit;
{$IFEND}

  TryKillAutoCQ;

{$IF MMTTYMODE}
  if ActiveMode = Digital then
    if MMTTY.mmttyTXIsOn then
    begin
      PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_IMMEDIATELY);
      Exit;
    end;
{$IFEND}

  pRadio := ActiveRadioPtr;
  if (ActiveMode = CW) then
  begin
    if KeyersSwapped then // ny4i Issue 94
    begin
      pRadio := InactiveRadioPtr;
    end
    else
    begin
      pRadio := ActiveRadioPtr;
    end;
    {if IsCWByCATActive(pRadio) then
    begin
    pRadio^.StopSendingCW;
    PTTOff;
    // Exit;
    end;}
  end;

  if ((ActiveMode = CW) and
    ((CWThreadID <> 0) or wkBUSY or pRadio.CWByCAT_Sending)) or
    ((ActiveMode in [Phone, FM]) and (DVPOn = True)) then
  begin
    if tAutoSendMode then
      EditingCallsignSent := True;
    tAutoSendMode := False;
    FlushCWBufferAndClearPTT; //n4af 4.33.3

    if DVPOn then
    begin
      tExitFromDVPThread := True;
      sndPlaySound(nil, SND_ASYNC);
      Windows.SetEvent(tDVP_Event);
      timeKillEvent(tDVPTimerEventID);
      DVPOn := False;
      PTTOff;
      DisplayCodeSpeed;
    end;
    exit; // 4.97.4
  end;

  if ActiveRadioPtr^.tTwoRadioMode = TR2 then
    if (not Call_Found) then
    begin
      tCleareCallWindow;
      tCleareExchangeWindow;
      tCallWindowSetFocus;
      ActiveRadioPtr^.tTwoRadioMode := TR0;
      InActiveRadioPtr^.tTwoRadioMode := TR0;
      SwapRadios;
      SetOpMode(CQOpMode);
      Exit;
    end;

  // if tr4w_ExchangeWindowActive then
  if ActiveMainWindow = awExchangeWindow then
    // if ExchangeWindowString <> '' then // 4.97.2
  begin
    tCleareExchangeWindow;
    tCallWindowSetFocus;
    Exit;
  end;

  if Call_Found = True then
  begin
    EscapeDeletedCallEntry := CallWindowString;
    tCleareCallWindow;
    EditingCallsignSent := False;
    CallAlreadySent := False;
    ExchangeHasBeenSent := False;
    SeventyThreeMessageSent := False;
    ClearInfoWindows;
    if OpMode = CQOpMode then
    begin
      if OpMode2 = SearchAndPounceOpMode then
        if (not Call_Found) then
        begin
          OpMode2 := CQOpMode;
          ShowFMessages(0);
        end;
    end;
  end;

  if ExchangeWindowString <> '' then
  begin
    tCleareExchangeWindow;
    Exit; //4.90.5
  end;

  if ActiveRadioPtr^.tTwoRadioMode = TR1 then
  begin
    ActiveRadioPtr^.tTwoRadioMode := TR0;
    InActiveRadioPtr^.tTwoRadioMode := TR0;
    SwapRadios;
    if OpMode = SearchAndPounceOpMode then
      if (not Call_Found) then
        SetOpMode(CQOpMode);
  end;

  if tPreviousDupeQSOsShowed then
    ShowPreviousDupeQSOsWnd(False); //DestroyPreviousDupeQSOsWnd;

  if Call_Found = False then
  begin
    ClearMasterListBox;
    ClearAltD; // n4af 4.65.2
    tClearDupeInfoCall; //n4af 4.65.2
  end;
  if TwoRadioState = CallReady then
    TwoRadioState := Idle;

  tCallWindowSetFocus;

  if OpMode = SearchAndPounceOpMode then
    if not Call_Found then
      if (EscapeExitsSearchAndPounce) then
        SetOpMode(CQOpMode);

end;

procedure SpaceBarProc2;
begin
  if (DupeInfoCall = '') and (CallWindowString = '') and (OpMode = SearchAndPounceOpMode) then // 4.102.3
    if not DEEnable then
      SendStringAndStop(MyCall)
    else
      SendStringAndStop(DEPlusMyCall);

  if (DupeInfoCall <> '') and (CallWindowString = '') then
  begin
    ActiveRadioPtr^.StopSendingCW;
    inActiveRadioPtr^.StopSendingCW;

    if TwoRadioMode then
    begin
      SwitchNext := False; // 4.56.1
      InActiveRadioPtr^.tTwoRadioMode := TR2;
    end
    else
      InActiveRadioPtr^.tTwoRadioMode := TR1;

    SwapRadios;
    SetOpMode(SearchAndPounceOpMode);
    PutCallToCallWindow(DupeInfoCall);
    ShowStationInformation(@DupeInfoCall);
    if TwoRadioMode then
    begin
      Send_DE;
      if (length(CallWindowString) >= 3) and (ExchangeWindowString = '') then
      begin
        tExchangeWindowSetFocus;
        tSetExchWindInitExchangeEntry;
        CheckAndSetInitialExchangeCursorPos;
      end;
    end;
    ShowStationInformation(@CallWindowString);
    DisplayGridSquareStatus(CallWindowString);
  end
  else
  begin
    if (OpMode <> SearchAndPounceOpMode) and ((CallWindowString = '') or not SpaceBarDupeCheckEnable) then
    begin
      if CWStillBeingSent then
        FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}

      SetUpToSendOnActiveRadio;

      InactiveRigCallingCQ := False;

      if MessageEnable then
      begin
        if ActiveMode = CW then
        begin
          if DEEnable then
            SendStringAndStop(DEPlusMyCall)
          else
            SendStringAndStop(MyCall);
        end
        else if ActiveMode = Digital then
          SendStringAndStop(CallWindowString + ' DE ' + MyCall + ' KK')
        else
      end;

      KeyStamp(F1);
      DisplayNextQSONumber;
      ClearContestExchange(ReceivedData);
      ExchangeHasBeenSent := False;
      SetOpMode(SearchAndPounceOpMode);

      if ActiveRadio = RadioOne then
      begin
        CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
      end
      else
        CQRITEnabled := Radio2.RadioModel in KenwoodRadios;
      DisplayAutoSendCharacterCount;
      EscapeDeletedCallEntry := CallWindowString;
    end
    else
    begin
      if (StartSendingNowKey = ' ') and (OpMode = CQOpMode) then
        StartSendingNow(True)
      else
        WindowDupeCheck;
      tempRXData.Callsign := CallWindowString;
      if UDPBroadcastLookup then
      begin
        LookupInfoToUDP(tempRXData);
      end;
    end;
  end;
end;

procedure SpaceBarProc;

begin

  if (DupeInfoCall <> '') and (CallWindowString = '') then
  begin

    FlushCWBufferAndClearPTT;

    if (TwoRadioState = CallReady) then
      CheckTwoRadioState(SpaceBarPressed)
        {KK1L: 6.73 Should modify to handle Alt-D from SAP mode}
    else
    begin
      SwapRadios; { Changes band/mode and display }
    end;

    if TwoRadioState <> CallReady then
    begin
      SetOpMode(SearchAndPounceOpMode);
      ShowStationInformation(@CallWindowString);
      DisplayGridSquareStatus(CallWindowString);
      VisibleLog.DoPossibleCalls(CallWindowString);

      if (length(CallWindowString) >= 3) and (ExchangeWindowString = '') then
      begin
        tExchangeWindowSetFocus;
        tSetExchWindInitExchangeEntry;
        CheckAndSetInitialExchangeCursorPos;
      end;

      DisplayNextQSONumber;
      ClearContestExchange(ReceivedData);
      ExchangeHasBeenSent := False;

      if ActiveRadio = RadioOne then
      begin
        CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
      end
      else
        CQRITEnabled := Radio2.RadioModel in KenwoodRadios;
      DisplayAutoSendCharacterCount;
    end;
  end

    { Still a SpaceBar, but not doing DupeInfoCall }

  else if ((OpMode <> SearchAndPounceOpMode) and ((CallWindowString = '') or not
    SpaceBarDupeCheckEnable)) then
  begin

    FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}

    SetUpToSendOnActiveRadio;

    InactiveRigCallingCQ := False;

    if MessageEnable then
    begin
      if ActiveMode = CW then
      begin
        if DEEnable then
          SendStringAndStop(DEPlusMyCall)
        else
          SendStringAndStop(MyCall);
      end
      else if ActiveMode = Digital then
        SendStringAndStop(CallWindowString + ' DE ' + MyCall + ' KK')
      else
        //wli SendFunctionKeyMessage (F1, SearchAndPounceOpMode);
    end;

    KeyStamp(F1);

    // repeat
    // PutUpExchangeWindow;
    DisplayNextQSONumber;
    ClearContestExchange(ReceivedData);
    ExchangeHasBeenSent := False;
    // until not SearchAndPounce;
    SetOpMode(SearchAndPounceOpMode);
    ClearContestExchange(ReceivedData);

    if ActiveRadio = RadioOne then
    begin
      CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
    end
    else
      CQRITEnabled := Radio2.RadioModel in KenwoodRadios;

    // RemoveWindow(ExchangeWindow);

    DisplayAutoSendCharacterCount;

    EscapeDeletedCallEntry := CallWindowString;

    // if CallWindowString = '' then ResetSavedWindowListAndPutUpCallWindow;
  end
  else
  begin
    if WindowDupeCheck then //RemoveWindow(ExchangeWindow);
      // Windows.SetWindowText(ExchangeWindowHandle, '');
      SetMainWindowText(mweExchange, nil);
    // RestorePreviousWindow;

  end;
end;

procedure SetOpMode(OperationMode: OpModeType);
begin

  OpMode := OperationMode;
  OpMode2 := OperationMode;
  SearchAndPounceMode := OpMode = SearchAndPounceOpMode;
  SetMainWindowText(mweOpMode, OpModeString[OperationMode]);
  if OperationMode = CQOpMode then
    EditingCallsignSent := False;
  tCallWindowSetFocus;
  DisplayAutoSendCharacterCount;
  InvalidateRect(wh[mweExchange], nil, False);
  ShowFMessages(0);
  SendStationStatus(sstOpMode);
end;

procedure ReturnInCQOpMode;
begin
  if InactiveRigCallingCQ and Switch then // n4af 4.44.10
  begin
    Switch := False;
    CheckInactiveRigCallingCQ; // swapradios
    InactiveRigCallingCQ := False; // n4af 4.44.3
    if (length(CallWindowString) > 0) then
      exit; // n4af 4.44.2
  end;

  if (length(CallWindowString) = 0) and (length(ExchangeWindowString) = 0) then
  begin
    if MessageEnable then
    begin
      TryKillAutoCQ;
      SendFunctionKeyMessage(F1, CQOpMode);
      InactiveRigCallingCQ := False; // n4af 4.44.3
    end;
    Exit;
  end;

  // State-QP rover (KG1S/MON): if call has /COUNTY suffix and exchange
  // is empty, copy the county to the exchange and move focus there so
  // the operator can confirm with another Enter.
  PrefillExchangeFromRoverCallSuffix;

  if (length(CallWindowString) <> 0) and (length(ExchangeWindowString) = 0) and
    SwitchNext then // 4.52.8
    if tAutoSendMode and (AutoSendCharacterCount > 0) then
    begin
      SwitchNext := False;
      InactiveRigCallingCQ := False;
      CallAlreadySent := True;
      SwapRadios;
    end;

  if SCPMinimumLetters > 0 then
  begin
    DisplayUserInfo(CallWindowString);
    ShowName(CallWindowString);
  end;
  DisplayGridSquareStatus(CallWindowString);

  if Contest <> GENERALQSO then
  begin
    ShowStationInformation(@CallWindowString); //gav 4.44.8
    VisibleLog.DoPossibleCalls(CallWindowString);
  end;

  if AutoDupeEnableCQ and tCallWindowStringIsDupe then
  begin
    CallAlreadySent := False;
    // ShowFMessages(0);
    // FlashCallWindow;
    // EscapeDeletedCallEntry := CallWindowString;
    // if tAutoSendMode = True then CallAlreadySent := True;
    // if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
    // if tAutoSendMode = True then CallAlreadySent := True;
    // tAutoSendMode := False;
    SendB4;
    // DispalayDupe; // 4.108.6
    // tCleareCallWindow;
  end;
  if CallAlreadySent = False then
  begin
    if ActiveMode in [CW, Digital] then // WLI
    begin
      OpMode2 := SearchAndPounceOpMode;
      ShowFMessages(0);
    end;
    if ActiveMode = Digital then
      SendMessageToMixW('<TX>');
    // CheckInactiveRigCallingCQ;
    if not tAutoSendMode then
      if MessageEnable then
      begin
        SetSpeed(DisplayedCodeSpeed); // 4.106.1
        if not SendCrypticMessage(CallWindowString) then
          Exit;
      end;
    tAutoSendMode := False;
    CallAlreadySent := True;
    ExchangeHasBeenSent := True;
    CallsignICameBackTo := CallWindowString;
    if MessageEnable then
      AddOnCQExchange;

    if QTCsEnabled then
      DisplayQTCNumber(NumberQTCsThisStation(CallWindowString));

    if (ExchangeWindowString = '') and (ExchangeMemoryEnable) then // 4.83.3
    begin
      if not LeaveCursorInCallWindow then
        tExchangeWindowSetFocus;
      tSetExchWindInitExchangeEntry; // 4.83.9
      CheckAndSetInitialExchangeCursorPos;
    end;

    if not LogWithSingleEnter then
      Exit;
  end;

  // IF K5KA.ModeEnabled THEN DupeCheckOnInactiveRadio;

  if ExchangeHasBeenSent = False then
    if MessageEnable and not BeSilent then
      if not (DebugFlag and (CWTone = 0)) then
      begin
        // Frm.ExchangeWindow . SetFocus;
        tExchangeWindowSetFocus;
        CallsignICameBackTo := CallWindowString;
        tAutoSendMode := False;
        AddOnCQExchange;
      end;

  if ParametersOkay(CallWindowString, ExchangeWindowString, ActiveBand,
    ActiveMode, ActiveRadioPtr.LastDisplayedFreq, ReceivedData) then
  begin
    if ActiveMode = CW then
    begin

      if not Send73Message then
        Exit;
      OpMode2 := CQOpMode;
      ShowFMessages(0);

      //SendCorrectCallIfNeeded;

    end

    else
      {................phone.....................}if MessageEnable and not
      BeSilent then
      begin
        if QuickQSL <> NoQuickQSLKey then
          SendCrypticMessage(QuickQSLPhoneMessage)
        else
          Send73Message;
      end;
    {................phone.....................}

    if DualingCQState = DualGettingExchange then
      DualingCQState := DualSendingQSL;
    BeSilent := False;

    if not TailEnding then
    begin
      // ReceivedData.ceSearchAndPounce := False;
      TryLogContact;
      ShowStationInformation(@ReceivedData.Callsign);
      UpdateTotals2;

      //{WLI}

      EscapeDeletedCallEntry := CallWindowString;
      tCleareCallWindow;
      tCleareExchangeWindow;
      tCallWindowSetFocus;
      // sendmessage(CallWindowHandle,wm_setfocus,0,0);
      // CallWindow . SetFocus;
      if OnDeckCall <> '' then // 4.102.4
        PutCallToCallWindow(OnDeckCall);
      Exit;
    end;
  end;
end;

procedure ReturnInSAPOpMode;
label
  loop;
var
  n: integer;
  TempString: Str10;
begin
  n := 0;
  DebugMsg('>>>>Entering ReturnInSAPOpMode');
  ExchangeHasBeenSent := False;
  Exchw := ExchangeWindowString;
  Callw := CallWindowString;
  ParseFourFields(ExchangeWindowString, s1, s2, s3, s4);
  loop:
  if (ExchangeWindowString = '') and (CallWindowString = '') then
    if AutoReturnToCQMode then
    begin
      //     tClearDupeInfoCall; // 4.126.1
      //     clearAltD;         //4.126.1
      NameCallsignPutUp := '';
      CleanUpDisplay;
      if ActiveRadioPtr^.tTwoRadioMode = TR1 then
      begin
        ActiveRadioPtr^.tTwoRadioMode := TR0;
        InActiveRadioPtr^.tTwoRadioMode := TR0;
        SwapRadios;
      end;

      SetOpMode(CQOpMode);
      if MessageEnable then
        SendFunctionKeyMessage(F1, OpMode);
      Exit;
    end;

  // State-QP rover (KG1S/MON): if call has /COUNTY suffix and exchange
  // is empty, copy the county to the exchange and move focus there so
  // the operator can confirm with another Enter.
  PrefillExchangeFromRoverCallSuffix;

  // if tr4w_CallWindowActive then
  if (length(CallWindowString) >= 3) then
  begin
    tCreateAndAddNewSpot(CallWindowString, tCallWindowStringIsDupe,
      ActiveRadioPtr);
    if not AutoDupeEnableSandP then // n4af 4.49.5
      tExchangeWindowSetFocus; // n4af issue155 4.47.12
  end;
  if (ExchangeWindowString = '') then
    if (length(CallWindowString) >= 3) and
      ((not tCallWindowStringIsDupe) or
      (not AutoDupeEnableSandP)) then

    begin
      // ExchangeHasBeenSent := False;
      if GoodCallSyntax(CallWindowString) then
      begin
        if not Send_DE then
          Exit;
        tExchangeWindowSetFocus;
      end;
    end;

  if QTCsEnabled then
    DisplayQTCNumber(NumberQTCsThisStation(CallWindowString));

  if tCallWindowStringIsDupe and {not }AutoDupeEnableSandP then
  begin
    DispalayDupe;
    // if WindowDupeCheck then
    Exit;
  end;

  DisplayGridSquareStatus(CallWindowString);
  ShowStationInformation(@CallWindowString);

  if (ExchangeWindowString = '') {and (ExchangeMemoryEnable)} then // 4.84.1
  begin
    if ExchangeMemoryEnable then
      tSetExchWindInitExchangeEntry;
    CheckAndSetInitialExchangeCursorPos;
    Exit;
  end;

  VisibleLog.DoPossibleCalls(CallWindowString);
  // DDX(MaybeRespondToMyCall);

 // if TwoRadioState = StationCalled then CheckTwoRadioState(ReturnPressed)
 // else
  if MessageEnable and (not ExchangeHasBeenSent) and (not BeSilent) and
    MessageEnable then

  begin
    if ActiveMode = Digital then
      // ny4i Issue153 Just reformatted these few 'IFs' for readability
    begin
      SendMessageToMixW('<TX>');
    end;

    // Multi-county exchanges (e.g. "DAL/BAY", "DAL BAY") are handled at the
    // parser level: ProcessRSTAndDomesticQTHExchange splits and queues the
    // extras, and the drain loop in TryLogContact logs the additional QSOs
    // immediately.  No pre-split is needed here -- Issue #885.

    if ActiveMode in [CW, Digital] then

      if not SendCrypticMessage(SearchAndPounceExchange) then
        Exit;

    if ActiveMode = Digital then
    begin
      SendMessageToMixW('<RXANDCLEAR>');
    end;

    if ActiveMode in [Phone, FM] then
    begin
      SendCrypticMessage(SearchAndPouncePhoneExchange);
    end;

    ExchangeHasBeenSent := True;

    //if activeradioptr^.cwbycat then backtoinactiveradioafterqso; // ny4i Issue130 Moving this to after LogContact
    {TODO } // Uncomment above and comment below to check for CWBC_AutoSend ny4i 9-mar-2016
    //if activeradioptr^.cwbycat then backtoinactiveradioafterqso; // ny4i Issue153 commented out

  end;

  if TryLogContact then
  begin
    if ActiveRadioPtr^.tTwoRadioMode = TR2 then
      ActiveRadioPtr^.tTwoRadioMode := TR3;
    // TwoRadioState := SendingExchange;
    if ReceivedData.DomesticMult or ReceivedData.DXMult or ReceivedData.ZoneMult
      then
      VisibleLog.ShowRemainingMultipliers;
    if ReceivedData.DomesticMult then
      VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
    if SprintQSYRule then
    begin
      QuickDisplay(TC_SPRINTQSYRULE);
      if OpMode = SearchAndPounceOpMode then
        SetOpMode(CQOpMode);
    end;
  end;
  if (ActiveExchange = RSTDomesticQTHExchange) or (ActiveExchange =
    RSTQTHEXCHANGE) then
  begin
    if (IsAlpha(S2)) and (S2 <> '') then
    begin

      CallWindowString := callw;
      // S3 := '';
      exchangewindowstring := s1;
      BeSilent := True;
   //   S2 := '';
      goto loop;
    end;
  end;
end;

function Send_DE: boolean;
begin
  Result := True;
  if ActiveMode = CW then
  begin
    // SetSpeed(DisplayedCodeSpeed);
    // InactiveRigCallingCQ := False;
    if MessageEnable and not BeSilent then
    begin
      if DEEnable then
        Result := SendCrypticMessage(DEPlusMyCall)
      else
        Result := SendCrypticMessage(MyCall);
      // DebugMsg('<<<<SendCrypticMessage(MyCall)');
      KeyStamp(F1);
    end;
    Exit;
  end;

  if ActiveMode = Digital then
    SendCrypticMessage(#13#10 + CallWindowString + ' DE ' + MyCall + ' ' +
      MyCall)

  else
  begin
    if DVKEnable and MessageEnable and not BeSilent then
      SendFunctionKeyMessage(F1, SearchAndPounceOpMode);
    // if (ActiveDVKPort <> NoPort) and not BeSilent then
    {KK1L: 6.73 Added mode to GetExMemoryString}
    //{WLI} (GetEXMemoryString (ActiveMode, F1));
  end;

end;

procedure SendB4;
var
  QTC: integer;
begin
  if AutoDisplayDupeQSO then
  begin
    ShowPreviousDupeQSOs(CallWindowString, ActiveBand, ActiveMode);
    // EditableLogDisplayed := True;
  end;

  if ActiveMode in [CW, Digital] then //wli issue 276
  begin
    if QTCsEnabled then
    begin
      QTC := NumberQTCsThisStation(StandardCallFormat(CallWindowString, False));
      DisplayQTCNumber(QTC);
      if QTC < 10 then
      begin
        if QTCsEnabled and (MyContinent = Europe) then
        begin
          AddStringToBuffer(' B4 ', CWTone);
          // WAEQTC (CallWindowString);
        end
        else if MessageEnable and not BeSilent then
          SendCrypticMessage(CallWindowString + ' ' + QSOBeforeMessage);
      end;
      // else
      // if MessageEnable and not BeSilent then
      // SendCrypticMessage(CallWindowString + ' ' + QSOBeforeMessage);

    end
    else if MessageEnable and not BeSilent then
      { if CallAlreadySent = False then
      SendCrypticMessage(CallWindowString + ' ' + QSOBeforeMessage)
      else
      SendCrypticMessage(QSOBeforeMessage); }
      if DualingCQState <> NoDualingCQs then
        DualingCQState := SendingDupeMessage;
  end;

  if ActiveMode = Phone then
  begin
    //wli
    SendCrypticMessage(QSOBeforePhoneMessage);

    // Write (' DUPE!!');
    EscapeDeletedCallEntry := CallWindowString;

    if QTCsEnabled then
      DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)))
  end;

  CallAlreadySent := False;
  SeventyThreeMessageSent := False;
  // DispalayB4(SW_HIDE);
  // Windows.ShowWindow(B4StatusWindowHandle, SW_HIDE);

  // tCleareCallWindow

end;

procedure SaveTR4WPOSFILE;
var
  h: HWND;
begin
  FindAndSaveRectOfAllWindows;
  if not tOpenFileForWrite(h, TR4W_POS_FILENAME) then
    Exit;
  sWriteFile(h, tr4w_WindowsArray, SizeOf(tr4w_WindowsArray));
  CloseHandle(h);
end;

procedure LoadTR4WPOSFILE;
label
  1, 2;
var
  h: HWND;
  pNumberOfBytesRead: Cardinal;
  i: WindowsType;
  Left: integer;
begin

{$IF MAKE_DEFAULT_VALUES = true}
  Exit;
{$IFEND}
  if not TF.tOpenFileForRead(h, TR4W_POS_FILENAME) then
    goto 2;
  if Windows.GetFileSize(h, nil) <> SizeOf(tr4w_WindowsArray) then
    goto 1;
  Windows.ReadFile(h, tr4w_WindowsArray, SizeOf(tr4w_WindowsArray),
    pNumberOfBytesRead, nil);
  1:
  CloseHandle(h);
  2:
  for i := tw_BANDMAPWINDOW_INDEX to tw_HAMSCOREWINDOW_INDEX do
    if tr4w_WindowsArray[i].WndRect.Right = 0 then
    begin
      tr4w_WindowsArray[i].WndRect.Top := 400;
      tr4w_WindowsArray[i].WndRect.Left := Ord(i) * 30;
      tr4w_WindowsArray[i].WndRect.Right := Ord(i) * 30 + 220;
      tr4w_WindowsArray[i].WndRect.Bottom := 600;
    end;
  // Issue #783 Phase 4: give the HamScore status window enough room for
  // the URL line and the multi-line status edit.  Default 220 x N is too
  // narrow / short.  Min: 410 wide x 270 tall.
  if tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Right -
     tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Left < 410 then
    tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Right :=
      tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Left + 410;
  if tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Bottom -
     tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Top < 270 then
    tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Bottom :=
      tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndRect.Top + 270;

  if tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Right = 0 then
  begin
    Left := (GetSystemMetrics(SM_CXSCREEN) - 46 * 17) div 2;
    tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Top := 100;
    tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Left := Left;

    tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndVisible := True;
    tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndRect.Top := 24 * 17 + 100;
    tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndRect.Left := Left;
    tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndRect.Right := 46 * 17 +
      Left;
    tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndRect.Bottom := 24 * 17 +
      130 + 40;

    tr4w_WindowsArray[tw_NETWINDOW_INDEX].WndRect.Right := 500;
    tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndRect.Right := 650;
  end;
  for i := tw_BANDMAPWINDOW_INDEX to tw_HAMSCOREWINDOW_INDEX do
    tr4w_WindowsArray[i].WndHandle := 0;

  tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndProcAdr := @BandmapDlgProc;
  tr4w_WindowsArray[tw_DUPESHEETWINDOW1_INDEX].WndProcAdr := @DupesheetDlgProc;
  tr4w_WindowsArray[tw_DUPESHEETWINDOW2_INDEX].WndProcAdr := @DupesheetDlgProc;
  tr4w_WindowsArray[tw_FUNCTIONKEYSWINDOW_INDEX].WndProcAdr :=
    @FunctionKeysWindowDlgProc;
  tr4w_WindowsArray[tw_MASTERWINDOW_INDEX].WndProcAdr := @MasterDlgProc;
  tr4w_WindowsArray[tw_REMMULTSWINDOW_INDEX].WndProcAdr :=
    @RemainingMultsDlgProc;
  tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndProcAdr := @TelnetWndDlgProc;
  tr4w_WindowsArray[tw_RADIOINTERFACEWINDOW1_INDEX].WndProcAdr :=
    @RadioInterfaceWindowDlgProc;
  tr4w_WindowsArray[tw_RADIOINTERFACEWINDOW2_INDEX].WndProcAdr :=
    @RadioInterfaceWindowDlgProc;
  tr4w_WindowsArray[tw_NETWINDOW_INDEX].WndProcAdr := @NetDlgProc;
  tr4w_WindowsArray[tw_INTERCOMWINDOW_INDEX].WndProcAdr := @IntercomDlgProc;
  tr4w_WindowsArray[tw_POSTSCORESWINDOW_INDEX].WndProcAdr := @GetScoresDlgProc;
  // Issue #783 Phase 4 -- HamScore RTC status window dialog
  tr4w_WindowsArray[tw_HAMSCOREWINDOW_INDEX].WndProcAdr := @HamScoreDlgProc;
  tr4w_WindowsArray[tw_STATIONS_INDEX].WndProcAdr := @StationsDlgProc;
  tr4w_WindowsArray[tw_STATIONS_RM_DX].WndProcAdr := @RemainingMultsDlgProc
    {RemainingMultsDXDlgProc};
  tr4w_WindowsArray[tw_STATIONS_RM_DOM].WndProcAdr := @RemainingMultsDlgProc
    {RemainingMultsDOMDlgProc};
  tr4w_WindowsArray[tw_STATIONS_RM_ZONE].WndProcAdr := @RemainingMultsDlgProc
    {RemainingMultsZoneDlgProc};
  tr4w_WindowsArray[tw_STATIONS_RM_PREFIX].WndProcAdr := @RemainingMultsDlgProc
    {RemainingMultsZoneDlgProc};
  tr4w_WindowsArray[tw_MP3RECORDER].WndProcAdr := @MP3RecDlgProc;
{$IF MMTTYMODE}
  tr4w_WindowsArray[tw_MMTTYWINDOW_INDEX].WndProcAdr := @MMTTYDlgProc;
{$IFEND}

end;

procedure scWK_RESET; // n4af 4.43.10
begin
  wkSendAdminCommand(wkRESET);
end;

procedure OneSecTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;
begin
  UpdateTimeAndRateDisplays(True, True);

{$IF tDebugMode}
  // Windows.SetWindowText(tr4whandle, inttopchar({GetHeapStatus.TotalFree}AllocMemSize));
 // Windows.SetWindowText(InsertWindowHandle, inttopchar(FreeMemCount));
{$IFEND}
end;

procedure BandMapRefreshTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;
begin
  if BandMapNeedsRefresh then
     begin
     BandMapNeedsRefresh := False;
     DisplayBandMap;
     end;
end;

procedure PTTOffWhenStopWAV(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD)
  stdcall;
begin
  // ShowMessage('end;');
  Windows.KillTimer(tr4whandle, WAV_STOP_PTT_TIMER_IDENTIFIER);
  PTTOff;
  WAV_STOP_PTT_TIMER_IDENTIFIER := 0;
  DVPOn := False;
  DisplayCodeSpeed;
end;

procedure FrmSetFocus;
begin
  // ChangeFocus('FrmSetFocus');
  Windows.SetFocus(tr4whandle);
end;

function GetRealVirtualKey(var Key: integer): Byte;

begin
  Result := 0;

  // if GetKeyState(VK_CONTROL or VK_MENU) < -126 then Exit;

  if GetKeyState(VK_CONTROL) < -126 then
  begin
    Key := Key + 12;
    Result := 1;
    Exit;
  end;

  if GetKeyState(VK_MENU) < -126 then
  begin
    Key := Key + 24;
    Result := 2;
  end;

end;

procedure ShowSyserror(ErrorCode: Cardinal);
begin
  MessageBox(0, TF.SysErrorMessage(ErrorCode), tr4w_ClassName, MB_OK or
    MB_ICONERROR or MB_TASKMODAL);
end;

function YesOrNo(h: HWND; Text: PChar): integer;
begin
  // DoABeep(PromptBeep);
  // Windows.MessageBeep(MB_ICONASTERISK);
  Result := MessageBox(h, Text, tr4w_ClassName, MB_YESNO or MB_ICONQUESTION or
    MB_TOPMOST or MB_DEFBUTTON2);
end;

function YesOrNo2(h: HWND; Text: PChar): integer;
begin
  Result := MessageBox(h, Text, tr4w_ClassName, MB_OKCANCEL or MB_ICONQUESTION
    or
    MB_TOPMOST or MB_DEFBUTTON1);
end;

function TuneOnFreqFromCallWindow: boolean;
var
  TempFreq: Cardinal;
  TempMode: ModeType;
  TempBand: BandType;
  TempVFO: Char;
  TempString: CallString;
const
  QSYSHIFT = 20000;
begin
  Result := False;
  logger.debug('[TuneOnFreq] Enter: CallWindowString="%s"', [CallWindowString]);
  if CheckCommandInCallsignWindow then
  begin
    tCleareCallWindow;
    Result := True;
    Exit;
  end;
  if length(CallWindowString) < 2 then
  begin
    logger.debug('[TuneOnFreq] Exit: length < 2');
    Exit;
  end;

  TempVFO := 'A';
  TempString := CallWindowString;

  if TempString[length(TempString)] = 'B' then
  begin
    TempVFO := 'B';
    TempString[0] := Char(Ord(TempString[0]) - 1);
  end;

  if StringIsAllNumbersOrDecimal(TempString) = False then
  begin
    logger.debug('[TuneOnFreq] Exit: not all numbers/decimal, TempString="%s"', [TempString]);
    Exit;
  end;

  TempBand := ActiveBand;
  logger.debug('[TuneOnFreq] TempBand=%d, TempString="%s"', [Ord(TempBand), TempString]);

  if not (TempBand in [Band160..Band2]) then
  begin
    GetBandMapBandModeFromFrequency(ActiveRadioPtr.FilteredStatus.Freq +
      QSYSHIFT, TempBand, TempMode);

    if not (TempBand in [Band160..Band2]) then
      GetBandMapBandModeFromFrequency(ActiveRadioPtr.FilteredStatus.Freq -
        QSYSHIFT, TempBand, TempMode);

    if not (TempBand in [Band160..Band2]) then
    begin
      logger.debug('[TuneOnFreq] Exit: TempBand not in HF range after fallback, FilteredFreq=%d', [ActiveRadioPtr.FilteredStatus.Freq]);
      Exit;
    end;
  end;

  TempFreq := StrToInt(TempString);
  //3500
  // 620
  // 34
  if (TempFreq >= 0) and (TempFreq <= 999) then
  begin
    if TempFreq < 100 then
    begin
      TempFreq := TempFreq * 1000 + StartingFrequencies[TempBand];
    end
    else
      TempFreq := TempFreq * 1000 + (StartingFrequencies[TempBand] div 1000000)
        * 1000000;
  end
  else
    TempFreq := TempFreq * 1000;

  logger.debug('[TuneOnFreq] TempFreq=%u before GetBandMap', [TempFreq]);
  GetBandMapBandModeFromFrequency(TempFreq, TempBand, TempMode);
  logger.debug('[TuneOnFreq] After GetBandMap: TempBand=%d, TempMode=%d', [Ord(TempBand), Ord(TempMode)]);
  if TempBand <> NoBand then
  begin
    SetRadioFreq(ActiveRadio, TempFreq, TempMode, TempVFO);
    tCleareCallWindow; // 4.139.2
    Result := True;
    logger.debug('[TuneOnFreqFromCallWindow] Clearing Mults and QSO Needs Headers');
    SetMainWindowText(mweMultNeedsHeader, PChar(''));
    SetMainWindowText(mweQSONeedsHeader, PChar(''));
  end;

  {
  i := 0;
  if length(TempString) = 3 then i := tBaseFrequencys[ActiveBand];
  if pos('.', TempString) in [3, 4] then i := tBaseFrequencys[ActiveBand];
  Val(TempString, f, code);

  if f > (maxdword / 1000) then Exit;
  TempFreq := round((i + f) * 1000);
  TempMode := NoMode;
  GetBandMapBandModeFromFrequency(TempFreq, TempBand, TempMode);
  // CalculateBandMode(TempFreq, TempBand, TempMode);
  if TempBand <> NoBand then
  begin
  SetRadioFreq(ActiveRadio, TempFreq, TempMode, TempVFO);
  tCleareCallWindow;
  Result := True;
  end;
  }
end;

{
procedure TR4W_WM_SetTest(h: HWND; Control: Byte; Text: string);
begin
 Windows.SetDlgItemText(h, integer(Control), PChar(Text));
end;
}

procedure FindAndSaveRectOfAllWindows;
label
  1;
var
  tipos: WindowsType;
  temprect: TRect;
  TempBool: boolean;
begin
  for tipos := tw_MAINWINDOW_INDEX to tw_DUPESHEETWINDOW2_INDEX do
  begin
    TempBool := Windows.GetWindowRect(tr4w_WindowsArray[tipos].WndHandle,
      temprect);
    tr4w_WindowsArray[tipos].WndVisible := TempBool;
    if temprect.Left >= 0 then
      if TempBool = True then
        tr4w_WindowsArray[tipos].WndRect := temprect;
  end;
end;

procedure sm1;
begin
  ShowMessage(TR4W_INI_FILENAME);
end;

function TryKillAutoCQ: boolean;
begin
  Result := False;
  if tAutoCQMode = True then
  begin
    Windows.KillTimer(tr4whandle, AUTOCQ_TIMER_HANDLE);
    tAutoCQMode := False;
    SetMainWindowText(mweOpMode, 'CQ');
    QuickDisplay(nil);
    Result := True;
  end;

end;

procedure RunAutoCQ;

begin
  if tAutoCQMode = False then
  begin
    SetUpToSendOnActiveRadio;
    SetOpMode(CQOpMode);
    tAutoCQMode := True;
    SetMainWindowText(mweOpMode, 'AutoCQ');
    SendFunctionKeyMessage(AutoCQMemory, OpMode);
    tDisplayAutoCQStatus;
  end;
end;

procedure TestMP;
var
  F1, F2, F3: integer;
  PartialRadioResponse: string;
  TempFreq: integer;
  TempBand: BandType;
  TempMode: ModeType;

begin
  PartialRadioResponse :=
    #$11 + #$01 + #$56 + #$76 + #$B4 + #$20 + #$20 + #$02 + #$33 + #$20 + #$11 +
    #$33 + #$33 + #$91 + #$11 + #$20 +
    #$0B + #$00 + #$AB + #$F8 + #$D4 + #$20 + #$20 + #$02 + #$33 + #$20 + #$11 +
    #$33 + #$33 + #$91 + #$11 + #$20
    ;
  // PartialRadioResponse := ' ' + PartialRadioResponse;
  with Radio1.CurrentStatus do
  begin
    F1 := Ord(PartialRadioResponse[2]);
    F1 := F1 * 256 * 256 * 256;
    F2 := Ord(PartialRadioResponse[3]);
    F2 := F2 * 256 * 256;
    F3 := Ord(PartialRadioResponse[4]);
    F3 := F3 * 256;

    TempFreq := F1 + F2 + F3 + Ord(PartialRadioResponse[5]);

    { Frequency corrections }

    if Radio1.RadioModel = FT1000MP then
      TempFreq := round(TempFreq * 0.625);
    if Radio1.RadioModel = FT100 then
      TempFreq := round(TempFreq * 1.25);

    { Calculate default band/mode }

    CalculateBandMode(TempFreq, TempBand, TempMode);

    { Look at band/mode information from radio }

    if Radio1.RadioModel = FT1000MP then
      case (Ord(PartialRadioResponse[8]) and $07) of
        2, 5, 6: TempMode := CW;
      else
        TempMode := Phone;
      end;

    if Radio1.RadioModel = FT100 then
      case (Ord(PartialRadioResponse[6]) and $07) of
        2, 3, 5: TempMode := CW;
      else
        TempMode := Phone;
      end;

    VFO[VFOA].Frequency := TempFreq;
    VFO[VFOA].Band := TempBand;
    VFO[VFOA].Mode := TempMode;

    Delete(PartialRadioResponse, 1, 16);
    if PartialRadioResponse[2] = #$20 then
      PartialRadioResponse[2] := #0;
    F1 := Ord(PartialRadioResponse[2]);
    F1 := F1 * 256 * 256 * 256;
    F2 := Ord(PartialRadioResponse[3]);
    F2 := F2 * 256 * 256;
    F3 := Ord(PartialRadioResponse[4]);
    F3 := F3 * 256;

    TempFreq := F1 + F2 + F3 + Ord(PartialRadioResponse[5]);

    { Frequency corrections }
   {
   11270352 MUST
   548141268
   7043.970
   }
    if Radio1.RadioModel = FT1000MP then
      TempFreq := round(TempFreq * 0.625);
    if Radio1.RadioModel = FT100 then
      TempFreq := round(TempFreq * 1.25);

    { Calculate default band/mode }

    CalculateBandMode(TempFreq, TempBand, TempMode);

    { Look at band/mode information from radio }

    if Radio1.RadioModel = FT1000MP then
      case (Ord(PartialRadioResponse[8]) and $07) of
        2, 5, 6: TempMode := CW;
      else
        TempMode := Phone;
      end;

    if Radio1.RadioModel = FT100 then
      case (Ord(PartialRadioResponse[6]) and $07) of
        2, 3, 5: TempMode := CW;
      else
        TempMode := Phone;
      end;

    VFO[VFOB].Frequency := TempFreq;
    VFO[VFOB].Band := TempBand;
    VFO[VFOB].Mode := TempMode;

  end;

end;

procedure tSetWindowLeft(h: HWND; Left: integer);
var
  tr4w_ThisWindowRect: TRect;

begin
  Windows.GetWindowRect(h, tr4w_ThisWindowRect);
  MapWindowPoints(0, tr4whandle, tr4w_ThisWindowRect, 2);
  Windows.SetWindowPos(h, HWND_TOP, Left, tr4w_ThisWindowRect.Top, 0, 0,
    SWP_NOSIZE);
end;

procedure tAltI;
var
  lpTranslated: LongBool;
  Value: Cardinal;
begin
  Value := Windows.GetDlgItemInt(tr4whandle, EXCHANGEWINDOWID, lpTranslated, False);
  if lpTranslated then
  begin
    // Issue #997: asm `inc eax; push eax; wsprintf(' %u')` -> TF.Format. The
    // Integer() cast is load-bearing: it forces the Format(...; i: integer)
    // wsprintfA overload. Without it, the Cardinal arg can bind a different
    // overload and the field doesn't update.
    Format(wsprintfBuffer, ' %u', Integer(Value + 1));
    SetMainWindowText(mweExchange, wsprintfBuffer);
    PlaceCaretToTheEnd(wh[mweExchange]);
  end;
end;

procedure tr4w_alt_n_transmit_frequency;
var
  Freq: integer;
  RadioToSet: RadioPtr {RadioType};
begin
  begin

    if InSplit then
    begin
      PutRadioOutOfSplit(ActiveRadio); // n4af 4.47.5
      PutRadioOutOfSplit(InActiveRadio);
      InSplit := False;
      exit;
    end;

    Freq := QuickEditFreq(TC_TRANSMITFREQUENCYKILOHERTZ, 10);

    RadioToSet := ActiveRadioPtr {ActiveRadio};

    if Freq < -2 then
    begin
      Freq := Freq * (-1);
      RadioToSet := InActiveRadioPtr {InactiveRadio};
    end;

    if (Freq = 0) then
      PutRadioOutOfSplit(ActiveRadio);
    if (Freq = -0) then
      PutRadioOutOfSplit(InactiveRadio);
    if (Freq > 1000) and (Freq < 1000000) then
      case RadioToSet.BandMemory {BandMemory[RadioToSet]} of
        Band80: Freq := Freq + 3000000;
        //      Band60: Freq := Freq  +5300000;
        Band40: Freq := Freq + 7000000;
        Band20: Freq := Freq + 14000000;
        Band15: Freq := Freq + 21000000;
        Band10: Freq := Freq + 28000000;
      end;
    InSplit := True;
    if Freq > 1000000 then
    begin
      // SetRadioFreq(ActiveRadio, Freq, ActiveMode, 'B');
      RadioToSet.SetRadioFreq(Freq, RadioToSet.ModeMemory, 'B');
      // SetRadioFreq(RadioToSet, Freq, ModeMemory[RadioToSet], 'B'); {KK1L: 6.73}
      // PutRadioIntoSplit(RadioToSet); {KK1L: 6.73}
      RadioToSet.PutRadioIntoSplit;
      SplitFreq := Freq;
      InSplit := True;
    end;
    BandMapCursorFrequency := Freq; {KK1L: 6.68 Band map tracks transmit freq}
    DisplayBandMap;
  end;
end;

procedure tr4w_toggle_sidetone;
begin
  if (ActiveMode = Phone) and DVPActive then
    ReviewBackCopyFiles
  else if CWTone <> 0 then
  begin
    OldCWTone := CWTone;
    CWTone := 0;
    AddStringToBuffer('', CWTone);
    NoSound;
  end
  else
  begin
    if OldCWTone = 0 then
      OldCWTone := 700;
    CWTone := OldCWTone;
    AddStringToBuffer('', CWTone);
  end;
end;

procedure tClearDupesheet_Ctrl_K;
begin
  tInputDialogWarning := True;
  if QuickEditResponse(TC_YESTOCLEARTHEDUPESHEET, 3) = 'YES' then
    tClearDupesheet;
end;

procedure tClearDupesheet;

begin

  tUpdateLog(actSetClearDupesheetBit);
  UpdateTotals2;
  CallsignsList.ClearDupes;

  QuickDisplay(TC_DUPESHEETCLEARED
    { To restore, delete RESTART.BIN and start program over.'});

  // callsignsList.DisplayDupeSheet(@Radio1 {ActiveBand, ActiveMode}); //n4af 4.38.7
  CallsignsList.DisplayDupeSheet(@Radio2 {ActiveBand, ActiveMode});
  // n4af 4.38.7
  SpotsList.ResetSpotsDupes;
  // ResetBandMapDupes;
  DisplayBandMap;
  UpdateAllStationsList;

  ShowInformation;
end;

procedure tr4w_add_note_in_log;
var
  s: ShortString;
  i: integer;
begin
  tInputDialogLowerCase := True;
  s := QuickEditResponse(TC_NOTE, 80);
  i := length(s);
  logger.info('******* User added note: [%s]', [s]);
  if i = 0 then
    Exit
  else if i > 80 then
    i := 80;
  Windows.ZeroMemory(@TempRXData, SizeOf(ContestExchange));
  TempRXData.ceRecordKind := rkNote;
  Windows.MoveMemory(@TempRXData.Prefix, @s[1], i);
  AddRecordToLogAndSendToNetwork(TempRXData);
end;

procedure tr4w_log_qso_without_cw;
var
  PeviousCWEnable: boolean;
  PeviousDVPEnable: boolean;
  PreviousBeSilent: boolean;
begin
  PeviousCWEnable := CWEnable;
  PeviousDVPEnable := DVKEnable;
  PreviousBeSilent := BeSilent;

  CWEnable := False;
  DVKEnable := False;
  BeSilent := True;

  ProcessReturn;

  CWEnable := PeviousCWEnable;
  DVKEnable := PeviousDVPEnable;
  BeSilent := PreviousBeSilent;
end;

procedure tr4w_ShutDown;
begin
  { PTTOff; // 4.113.1
  scWK_RESET; // 4.113.1
  WkClose; // 4.113.1 }
  if IsDXLabPathfinderRunning then
    StopDXLabPathfinder;
  if Assigned(wsjtx) then
  begin
    wsjtx.Stop;
    FreeAndNil(wsjtx);
  end;

  if assigned(externalLogger) then
  begin
    FreeAndNil(externalLogger);
  end;

  if Radio1.tNetObject <> nil then
  begin
    FreeAndNil(Radio1.tNetObject);
  end;

  if Radio2.tNetObject <> nil then
  begin
    FreeAndNil(Radio2.tNetObject);
  end;


  if Assigned(logger) then
  begin
    logger.Info('------------------------------Program shutdown----------------------------');
    FreeAndNil(logger);
  end;
  Windows.UnregisterClass(tr4w_ClassName, hInstance);
  // ny4i Issue 145. UnregisterClass was not qualifies and it conflicted with classes.UnregisterClass
  ExitProcess(hInstance);

end;

procedure ShowBeamAndHeadingInVHFContest(WindowString: CallString);
var
  Grid: GridString;
label
  1;
begin
  if VHFBandsEnabled then
  begin
    1:
    Grid := RemoveFirstString(WindowString);
    if Grid = '' then
      Exit;
    if length(Grid) >= 4 then
      if LooksLikeAGrid(Grid) then
        DisplayBeamHeading(CallWindowString, Grid);
    goto 1;
  end;
end;

procedure ExchangeWindowChange;
var
  TestString, TempString: Str40;
  TempExchange: ContestExchange;
  DQTH: boolean;
begin
  ExchangeWindowString[0] := Char(Windows.GetWindowText(wh[mweExchange],
    @ExchangeWindowString[1], SizeOf(ExchangeWindowString)));
  if VHFBandsEnabled then
    ShowBeamAndHeadingInVHFContest(ExchangeWindowString);

  if DomesticCountryCall(CallWindowString) then
    if DoingDomesticMults then
    begin
      TempString := ExchangeWindowString;
      while TempString <> '' do
      begin
        TestString := RemoveFirstString(TempString);

        // if Contest in [NAQSOCW, NAQSOSSB] then
        // if TempString <> '' then Continue;

        // if ActiveDomesticMult = RDADistrict then
        // if length(TestString) <> 4 then TestString := '';
        if TestString = '' then
          Exit;
        logger.debug('[ExchangeWindowChange] Setting TempExchange.QTHString to (%s)', [TestString]);
        TempExchange.QTHString := TestString;
        DQTH := FoundDomesticQTH(TempExchange);
        if not DQTH then
        begin
          DispalayNewMult(SW_HIDE);
          //Exit;
          Continue;

        end;
        // if not DQTH then TempExchange.DomMultQTH := '' ;
        // strU(TempExchange.DomMultQTH);
        VisibleLog.SetMultStatus(CallWindowString, TempExchange.DomMultQTH);
        if DQTH then
          Exit;
      end;
    end;

  // POTA: look up park name from exchange as typed and show via QuickDisplay.
  if (ActiveExchange = RSTAndPOTAPark) and POTAParksLoaded then
     begin
     TempString := ExchangeWindowString;
     while TempString <> '' do
        begin
        TestString := RemoveFirstString(TempString);
        TestString := NormalizePOTAPark(TestString, MyPark);
        if TestString <> '' then
           begin
           if GetPOTAParkName(TestString) <> '' then
              begin
              QuickDisplay(PChar(GetPOTAParkName(TestString)));
              Exit;
              end;
           end;
        end;
     end;

{$IF MORSERUNNER}
  if MorseRunnerWindow <> 0 then
    Windows.SendMessage(MorseRunner_Number, WM_SETTEXT, 0,
      integer(@ExchangeWindowString[1]));
{$IFEND}
end;

procedure WagCheck; //added by n4af at behest of wag contest mgr
var
  ARF: integer;

begin
  ARF := ActiveRadioPtr.CurrentStatus.Freq div 1000;

  if (ARF > 3650) and (ARF < 3700) then
  begin
    QuickDisplay(TC_WagWarn); // 4.90.3
    exit;
  end;

  if (ARF > 7043) and (ARF < 7080) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;

  if (ARF > 7080) and (ARF < 7143) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;

  if (ARF > 14060) and (ARF < 14125) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;

  if (ARF > 14280) and (ARF < 14350) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;

  if (ARF > 21347) and (ARF < 21450) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;

  if (ARF > 28225) and (ARF < 28400) then
  begin
    QuickDisplay(TC_WagWarn);
    exit;
  end;
end;

procedure CallWindowChange;
var
  nCmdShow: integer;
begin

  // Split warning is driven by DisplayCurrentStatus (uRadioPolling) on confirmed
  // state transitions — not here, where CurrentStatus.Split may be stale.
  // SetMainWindowText(mweName, nil);
  // CallDataBase.ClearDataEntry;
  SetMainWindowText(mweName, '');
  SetMainWindowText(mweUserInfo, '');

  // SetMainWindowText(mweUserInfo, nil); //N4AF 4.31.3
  if Contest = WAG then //n4af 4.31.4
    WagCheck; //n4af

  CallWindowString[0] := Char(Windows.SendMessage(wh[mweCall], WM_GETTEXT,
    CallstringLength, integer(@CallWindowString[1])));

  CallWindowEmpty := CallWindowString[0] = #0;
  if CallWindowEmpty then
    CallsignIsTypedByOperator := False;

  CallsignIsPastedFromBandMap := False;

  CallWindowKeyUpProc;
  ShowPartialCallMults(@CallWindowString);
  // if VHFBandsEnabled then ShowBeamAndHeadingInVHFContest(CallWindowString);

  if CallWindowString = '' then
  begin
    Windows.ShowWindow(wh[mweNewMultStatus], SW_HIDE);
    if OpMode = CQOpMode then
    begin
      if OpMode2 = SearchAndPounceOpMode then
      begin
        OpMode2 := CQOpMode;
        ShowFMessages(0);
        tCleareExchangeWindow;
      end;
    end;
  end;

  CallsignsList.CreatePartialsList(CallWindowString);

  {MASTER}

  nCmdShow := SW_HIDE;
  if length(CallWindowString) > 2 then
  begin
{$IF SCPDEBUG}
    nCmdShow := integer(scpFoundCallsign(@CallWindowString, MasterListBox,
      nil));
{$ELSE}
    if (SCPMinimumLetters > 0) then
    begin
      ClearMasterListBox;
      if VisibleLog.SuperCheckPartial(CallWindowString, True, ActiveRadioPtr)
        then
        nCmdShow := SW_SHOWNORMAL;
    end;
{$IFEND}
  end;

  Windows.ShowWindow(wh[mweMasterStatus], nCmdShow);
  if not InactiveRigCallingCQ then //n4af 04.40.2
    ShowInformation;

  if tShowTypedCallsign then
    SendStationStatus(sstCallsign);

{$IF MORSERUNNER}
  if MorseRunnerWindow <> 0 then
    Windows.SendMessage(MorseRunner_Callsign, WM_SETTEXT, 0,
      integer(@CallWindowString[1]));
{$IFEND}

end;

procedure CreateQSONeedWindows;
var
  Band: BandType;
  w: integer;
begin
  w := (ws * 2);
  for Band := Band160 to Band10 do
  begin
    QSONeedWindowsHandles1[Band] := CreateTR4WStaticWindow(MainWindowChildsWidth
      - RightTopWidth + (integer(Band) + 1) * w, ws, w - 2,
      QSOMULTSWINDOWSTYLE);
    Windows.SetWindowText(QSONeedWindowsHandles1[Band], BandStringsArray[Band])
  end;
  QSONeedWindowHandle1 := CreateTR4WStaticWindow(MainWindowChildsWidth -
    RightTopWidth, ws, w, QSOMULTSMODEWINDOWSTYLE);
  Windows.SetWindowText(QSONeedWindowHandle1, nil);

  if QSOByMode then
  begin
    for Band := Band160 to Band10 do
    begin
      QSONeedWindowsHandles2[Band] :=
        CreateTR4WStaticWindow(MainWindowChildsWidth - RightTopWidth +
        (integer(Band) + 1) * w, ws * 2, w - 2, QSOMULTSWINDOWSTYLE);
      Windows.SetWindowText(QSONeedWindowsHandles2[Band], BandStringsArray[Band])
    end;
    QSONeedWindowHandle2 := CreateTR4WStaticWindow(MainWindowChildsWidth -
      RightTopWidth, ws * 2, w, QSOMULTSMODEWINDOWSTYLE);
    Windows.SetWindowText(QSONeedWindowHandle1, 'CW:');
    Windows.SetWindowText(QSONeedWindowHandle2, 'SSB:');
  end;
end;

procedure CreateMultsWindows;
var
  Band: BandType;
  w: integer;
begin
  w := (ws * 2);
  for Band := Band160 to Band10 do
  begin
    MultsWindowsHandles1[Band] := CreateTR4WStaticWindowID(MainWindowChildsWidth
      - RightTopWidth + (integer(Band) + 1) * w, ws * 4, w - 2,
      QSOMULTSWINDOWSTYLE, MULTSARRAYWINDOW);
    Windows.SetWindowText(MultsWindowsHandles1[Band], BandStringsArray[Band])
  end;
  MultWindowHandle1 := CreateTR4WStaticWindow(MainWindowChildsWidth -
    RightTopWidth, ws * 4, w, QSOMULTSMODEWINDOWSTYLE);
  Windows.SetWindowText(MultWindowHandle1, 'Both:');

  if MultByMode then
  begin
    for Band := Band160 to Band10 do
    begin
      MultsWindowsHandles2[Band] :=
        CreateTR4WStaticWindowID(MainWindowChildsWidth - RightTopWidth +
        (integer(Band) + 1) * w, ws * 5, w - 2, QSOMULTSWINDOWSTYLE,
        MULTSARRAYWINDOW);
      Windows.SetWindowText(MultsWindowsHandles2[Band], BandStringsArray[Band])
    end;
    MultWindowHandle2 := CreateTR4WStaticWindow(MainWindowChildsWidth -
      RightTopWidth, ws * 5, w, QSOMULTSMODEWINDOWSTYLE);
    Windows.SetWindowText(MultWindowHandle1, 'CW:');
    Windows.SetWindowText(MultWindowHandle2, 'SSB:');
  end;
end;



procedure ApplyDWMRoundedCorners;
{ On Windows 11: ask the DWM compositor to round window corners natively
  (title bar included) via DwmSetWindowAttribute(DWMWA_WINDOW_CORNER_PREFERENCE).
  On Windows 10 fallback: clip the window region with CreateRoundRectRgn,
  which rounds the visible corners of the title bar and client area. }
const
   CORNER_RADIUS = 20;
type
   TDwmSetWindowAttribute = function(hwnd: HWND; dwAttribute: DWORD;
                                     pvAttribute: Pointer;
                                     cbAttribute: DWORD): HRESULT; stdcall;
var
   hDwm: THandle;
   DwmSetAttr: TDwmSetWindowAttribute;
   preference: DWORD;
   hr: HRESULT;
   R: TRect;
   Rgn: HRGN;
begin
   if tr4whandle = 0 then
      Exit;

   { Try Windows 11 DWM path first }
   hr := -1; { assume failure until proven otherwise }
   hDwm := LoadLibrary('dwmapi.dll');
   if hDwm <> 0 then
      begin
      try
         DwmSetAttr := GetProcAddress(hDwm, 'DwmSetWindowAttribute');
         if Assigned(DwmSetAttr) then
            begin
            preference := 2; { DWMWCP_ROUND }
            hr := DwmSetAttr(tr4whandle, 33 { DWMWA_WINDOW_CORNER_PREFERENCE },
                             @preference, SizeOf(preference));
            end;
      finally
         FreeLibrary(hDwm);
      end;
      end;

   { Windows 10 fallback: clip window region to a rounded rectangle }
   if hr <> 0 then
      begin
      Windows.GetWindowRect(tr4whandle, R);
      Rgn := CreateRoundRectRgn(0, 0,
               R.Right - R.Left,
               R.Bottom - R.Top,
               CORNER_RADIUS, CORNER_RADIUS);
      SetWindowRgn(tr4whandle, Rgn, True);
      end;
end;

procedure CreateMainWindow;
//var PanelWidth : array[0..1] of Integer;
var
  e: TMainWindowElement;
  temprect: TRect;
  // OffsetY : integer;
begin
  tr4whandle := CreateWindowEx($00010100 { WS_EX_CONTROLPARENT or WS_EX_WINDOWEDGE },
    tr4w_ClassName, nil,
    WS_SYSMENU or WS_MINIMIZEBOX,
    0, 30, MainWindowWidth, 0 {MainWindowHeight},
    0, tr4w_main_menu,
    hInstance, nil);
  tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndHandle := tr4whandle;
  wh[mweWholeScreen] := tr4whandle;
  wh[mweEditableLog] := CreateEditableLog(tr4whandle, 0, ws * 7,
    MainWindowChildsWidth, 0 {EditableLogWindowHeight}, False);
  SetListViewColor(mweEditableLog);
  DispalayLogGridLines;

  Windows.GetWindowRect(wh[mweEditableLog], temprect);

  EditableLogHeight := temprect.Bottom - temprect.Top;

  Windows.GetWindowRect(tr4whandle, temprect);
  Windows.SetWindowPos(tr4whandle, HWND_TOP, 0, 0, ws * 46, 6
    + MainWindowCaptionAndHeader + EditableLogHeight + ws * 14,
    {SWP_SHOWWINDOW or }SWP_NOMOVE);
   { Round the four corners of the main window - radius 12px, adjust as needed }
  for e := Low(TMainWindowElement) to High(TMainWindowElement) do
  begin
    if TWindows[e].mweiStyle <= 2 then
      Continue;
    wh[e] :=

    // Result := tCreateStaticWindow(nil, Style, X, Y, w, StaticWindowHeight, tr4whandle, 0);

    tCreateStaticWindow(
      nil,
      TWindows[e].mweiStyle and (not (Cardinal(NoBorder) * SS_SUNKEN))
      {or SS_ETCHEDFRAME},
      TWindows[e].mweiX * ws,
      TWindows[e].mweiY * ws + TWindows[e].mweB * EditableLogHeight,
      round(TWindows[e].mweiWidth * ws),
      TWindows[e].mweiHeight * ws,
      tr4whandle, 0
      );
    tWM_SETFONT(wh[e], MainFont);

    if TWindows[e].mweText <> nil then
      SetMainWindowText(e, TWindows[e].mweText)
  end;

  tWM_SETFONT(wh[mweAutoSendCount], SymbolFont);
  DisplayAutoSendCharacterCount;

  tWM_SETFONT(wh[mweQSONumber], MainWindowEditFont {QSONumberFont});

  wh[mweCall] := CreateCallOrExchangeWin(EditableLogHeight + ws * 8 {Line2},
    CALLSIGNWINDOWID);

{$IF OZCR2008}
  // QuickMemoryWindowHandle := nfCreateTR4WStaticWindow('Quick M.', col9, Line5, 4 * ws, DefStyleDis);
{$IFEND}

  DisplayInsertMode;

  Radio1.FreqWindowHandle   := wh[mweRadioOneFreq];
  Radio1.RadioNameWndHandle := wh[mweRadioOne];
  Radio2.FreqWindowHandle   := wh[mweRadioTwoFreq];
  Radio2.RadioNameWndHandle := wh[mweRadioTwo];

  LastProgressBar := CreateProgress32InMainWindow(ws * 28 {col6},
    EditableLogHeight + 10 * ws {Line4}, $000000FF);
  RateProgressBar := CreateProgress32InMainWindow(ws * 33 {col8},
    EditableLogHeight + 10 * ws {Line4}, $00FF0000);

  wh[mweExchange] := CreateCallOrExchangeWin(EditableLogHeight + ws * 8
    {+ round(ws * 1.5)} + MainWindowEditHeight + 1, EXCHANGEWINDOWID);

  SendMessage(wh[mweExchange], EM_LIMITTEXT, 35, 0);

  if TourDuration <> 0 then
  begin
    // Windows.GetWindowRect(wh[mweQuickCommand], temprect);
    Windows.SetWindowPos(wh[mweQuickCommand], HWND_TOP, 0, EditableLogHeight + ws
      * 12, ws * 33, ws, SWP_SHOWWINDOW);
    TorDurationWindow := CreateTR4WStaticWindow(38 * ws {col9}, EditableLogHeight
      + ws * 12 {Line7}, 8 * ws, defStyle);
    TorDurationPrBarWindow := CreateProgress32InMainWindow(33 * ws {col8},
      EditableLogHeight + ws * 12 {Line7}, $0000FFFF);
    SendMessage(TorDurationPrBarWindow, PBM_SETRANGE, 0, MakeLParam(0,
      TourDuration));
    SendMessage(TorDurationPrBarWindow, PBM_SETBKCOLOR, 0, $000000);
    SendMessage(TorDurationPrBarWindow, PBM_SETSTEP, 1, 0);
    ShowTourDuration;
  end;

  wh[mwePossibleCall] := CreateWindowEx(0, LISTBOX, nil,
    LBS_NOTIFY or LBS_OWNERDRAWFIXED or {LBS_HASSTRINGS or }LBS_NOINTEGRALHEIGHT
    or LBS_MULTICOLUMN or WS_CHILD or WS_VISIBLE,
    0, EditableLogHeight + ws * 13 {line6}, MainWindowChildsWidth, ws,
    tr4whandle, MainWindowPCLID, hInstance, nil);
  // Issue #997: asm tWM_SETFONT (EAX = wh[mwePossibleCall] above).
  tWM_SETFONT(wh[mwePossibleCall], MainFont);
  SendMessage(wh[mwePossibleCall], LB_SETCOLUMNWIDTH, 5 * ws {19 * ws2}, 0);

  CreateTotalWindow;

  Format(wsprintfBuffer, TC_RULESONQRZRU, ContestTypeSA[Contest]);
  ModifyMenu(tr4w_main_menu, menu_qrzru_calendar, MF_BYCOMMAND + MF_STRING,
    menu_qrzru_calendar, wsprintfBuffer);

  Format(wsprintfBuffer, TC_RULESONSM3CER, ContestTypeSA[Contest]);
  ModifyMenu(tr4w_main_menu, menu_WA7BNM_calendar, MF_BYCOMMAND + MF_STRING,
    menu_WA7BNM_calendar, wsprintfBuffer);
  if (pos('CQ-WW', ContestTypeSA[Contest]) <> 0) or (pos('IARU-HF',
    ContestTypeSA[Contest]) <> 0) then //n4af 4.35.5 // 4.115.4
    T1 := 3600000 // 60 min break criteria
  else
    T1 := 1800000; // normal 30min break
  if ContestsArray[Contest].QRZRUID = 0 then
    Windows.EnableMenuItem(tr4w_main_menu, menu_qrzru_calendar, MF_BYCOMMAND or
      MF_GRAYED);
  if ContestsArray[Contest].WA7BNM = 0 then
    Windows.EnableMenuItem(tr4w_main_menu, menu_WA7BNM_calendar, MF_BYCOMMAND or
      MF_GRAYED);
  if Contest = WRTC then
  begin
    Windows.EnableMenuItem(tr4w_main_menu, menu_windows_trmasterdta, MF_BYCOMMAND
      or MF_GRAYED);
    Windows.EnableMenuItem(tr4w_main_menu, menu_windows_telnet, MF_BYCOMMAND or
      MF_GRAYED);
    Windows.EnableMenuItem(tr4w_main_menu, menu_windows_getscores, MF_BYCOMMAND
      or MF_GRAYED);
  end;

  EnableNetworkMenuItem(MF_GRAYED + MF_BYPOSITION);

{$IF MMTTYMODE}
  // Windows.EnableMenuItem(tr4w_main_menu, menu_windows_mmtty, MF_BYCOMMAND or MF_ENABLED);
{$IFEND}

{$IF not OZCR2008}
  // DeleteMenu(tr4w_main_menu, menu_windows_stack, MF_BYCOMMAND or MF_GRAYED);
  // DeleteMenu(tr4w_main_menu, menu_windows_mf, MF_BYCOMMAND or MF_GRAYED);
{$IFEND}

  if not (Contest in [DARCWAEDCCW..DARCWAEDCSSB]) then
    Windows.EnableMenuItem(tr4w_main_menu, menu_ctrl_qtcfunctions, MF_BYCOMMAND
      or MF_GRAYED);

  // Remove POTA-specific menu items entirely when not in a POTA contest.
  // DeleteMenu is used rather than MF_GRAYED so the items are invisible —
  // they are irrelevant outside POTA and would clutter the menu.
  // Note: once deleted they are not re-added if the operator switches contests
  // mid-session, but that is consistent with TR4W's existing per-contest menu
  // state pattern (other items are also only grayed/deleted at load time).
  if Contest <> POTA then
     begin
     Windows.DeleteMenu(tr4w_main_menu, menu_download_pota_parks, MF_BYCOMMAND);
     Windows.DeleteMenu(tr4w_main_menu, menu_repeat_pota_parks,   MF_BYCOMMAND);
     end;
  // if ContestsArray[Contest].e <> 0 then
  ErmakSpecification := ((ContestsBooleanArray[Contest] and (1 shl ERMAK_BIT))
    <> 0) and (RussianID(MyCall));

  if ErmakSpecification then
    ModifyMenu(tr4w_main_menu, menu_cabrillo, MF_BYCOMMAND + MF_STRING,
      menu_cabrillo, ERMAK_);

  // AppendMenu(GetSubMenu(tr4w_main_menu, menu_rescore), MF_POPUP , 11010, 'NepItem');
  // InsertMenu(tr4w_main_menu, menu_rescore, MF_BYCOMMAND, 177, 'aa');
  { Ask DWM to round window corners natively (Windows 11+, no-op on older) }
  ApplyDWMRoundedCorners;
end;

procedure OpenOtherWindows;
var
  i: WindowsType;
begin
  for i := tw_BANDMAPWINDOW_INDEX to tw_HAMSCOREWINDOW_INDEX do  // Issue #783 -- include HamScore in restore
    if tr4w_WindowsArray[i].WndVisible then
      OpenTR4WWindow(i);
  Windows.SetWindowPos(tr4whandle, HWND_TOP,
    tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Left,
    tr4w_WindowsArray[tw_MAINWINDOW_INDEX].WndRect.Top, 0, 0, SWP_NOSIZE or
    SWP_SHOWWINDOW);
     { DWM rounding is compositor-managed; no reapplication needed after move }
    ApplyDWMRoundedCorners;
end;

function tCreateFont(nHeight, fnWeight: integer; lpszFace: PChar): HFONT;
begin
  Result := Windows.CreateFont
    (
    nHeight + FontSize - 1,
    0,
    0,
    0,
    fnWeight,
    0,
    0,
    0,
    DEFAULT_CHARSET {ANSI_CHARSET},
    OUT_DEFAULT_PRECIS,
    Clip_Default_Precis,
    Default_Quality,
    DEFAULT_PITCH,
    lpszFace
    );
end;

procedure CreateFonts;
var
  lcfn: PChar;
begin
{(*}
 if LuconSZLoadded then lcfn := 'Lucida Console SZ' else lcfn := 'Lucida Console';

 DeleteObject(MainFixedFont);
 MainFixedFont := tCreateFont(12+BandMapSize-2,FW_BOLD * Ord(BoldFont), @MainFontName[1]);
 MainFont := tCreateFont(ws - 2+FontSize, FW_BOLD * ord(BoldFont), @MainFontName[1]);
 CATWindowFont := tCreateFont(22, FW_EXTRABOLD, 'Lucida Console');

 MainWindowEditFont := tCreateFont(ws + 3, FW_EXTRABOLD, lcfn);

 {AutoSend}
 SymbolFont := tCreateFont(ws, FW_SEMIBOLD, 'Symbol');
 {Alt-P}
 TerminalFont :=
 Windows.CreateFont(
 18, 0, 0, 0,
 FW_DONTCARE,
 0, 0, 0,
 {$IF LANG = 'UKR'}
 EastEurope_Charset
 {$ELSEIF LANG = 'RUS'}
 russian_charset
 {$ELSE}
 DEFAULT_CHARSET
{$IFEND}

,
 OUT_DEFAULT_PRECIS,
 Clip_Default_Precis,
 Default_Quality, FIXED_PITCH, 'Terminal');

 {Dupesheet,Telnet}
 LucidaConsoleFont := tCreateFont(13, FW_BOLD * ord(BoldFont){FW_DONTCARE}, 'Lucida Console');
{*)}
end;

function DrawWindows(lParam: lParam; wParam: wParam): Cardinal;
label
  DrawWindow;
var
  TempBrush: HBRUSH;
  TempWindowColor: integer;
  //charText: array [0..255] of char;
const
  DupeInfoCallWindowColorArray: array[DupeInfoState] of tr4wColors = (trBtnFace,
    trRed, trYellow, trLightBlue);
begin
  TempWindowColor := 0;

  TempBrush := tr4wBrushArray[TWindows[mweWholeScreen].mweBackG];
  //tr4wBrushArray[trBtnFace];
  TempWindowColor := tr4wColorsArray[TWindows[mweWholeScreen].mweColor];

  if CheckWindowAndColor(HWND(lParam), TempBrush, TempWindowColor) then
  begin

    if lParam = integer(wh[mweExchange]) then
      if OpMode = SearchAndPounceOpMode then
        TempBrush := tr4wBrushArray[trGreen];

    if DupeInfoCallWindowState <> diNone then
      if lParam = integer(wh[mweDupeInfoCall]) then
        TempBrush :=
          tr4wBrushArray[DupeInfoCallWindowColorArray[DupeInfoCallWindowState]];

    if lParam = integer(wh[mwePTTStatus]) then
    begin
      if ActiveRadioPtr.tPTTStatus = PTT_ON then
      begin
        if ActiveRadio = RadioOne then
          TempBrush := tr4wBrushArray[trRed] // n4af 4.46.4
        else
          TempBrush := tr4wBrushArray[trYellow];
      end;
    end;

    if lParam = integer(wh[mweWSJTX]) then
    begin
      if Assigned(wsjtx) then
      begin
        if wsjtx.Connected then
        begin
          SetMainWindowText(mweWSJTX, 'WSJTX');
          TempBrush := tr4wBrushArray[trGreen];
        end
        else
        begin
          TempBrush := tr4wBrushArray[trRed];
        end;
      end;
    end;

    if (lParam = integer(wh[mweRadioOneFreq])) or
       (lParam = integer(wh[mweRadioOne])) then
       begin
       if Radio1.RadioDisconnected then
          TempWindowColor := tr4wColorsArray[AlertColor];
       end;

    if (lParam = integer(wh[mweRadioTwoFreq])) or
       (lParam = integer(wh[mweRadioTwo])) then
       begin
       if Radio2.RadioDisconnected then
          TempWindowColor := tr4wColorsArray[AlertColor];
       end;

    goto DrawWindow;
  end;

  if TotWinCurrrentColumn in [1..7] then
  begin
    if lParam = integer(TotWinheadHandles[TotWinCurrrentColumn]) then
    begin
      TempBrush := tr4wBrushArray[trBlue];
      TempWindowColor := tr4wColorsArray[trWhite];
      goto DrawWindow;
    end;
    {
    if (lParam = integer(TotWinHandles[TotWinCurrrentColumn, 0])) or
    (lParam = integer(TotWinHandles[TotWinCurrrentColumn, 1])) or
    (lParam = integer(TotWinHandles[TotWinCurrrentColumn, 2])) or
    (lParam = integer(TotWinHandles[TotWinCurrrentColumn, 3]) )then
    begin
    TempBrush := tr4wBrushArray[trWhite];
    goto DrawWindow;
    end;
    }
  end;

  if Windows.GetDlgCtrlID(HWND(lParam)) = MULTSARRAYWINDOW then
  begin
    TempBrush := tr4wBrushArray[TWindows[mweNewMultStatus].mweBackG];
    //tr4wBrushArray[trYellow];
    TempWindowColor := tr4wColorsArray[TWindows[mweNewMultStatus].mweColor];
    //tr4wColorsArray[trBlack];
    goto DrawWindow;
  end;

  // Exit;

  DrawWindow:
  SetBkMode(HDC(wParam), TRANSPARENT);
  SetTextColor(HDC(wParam), TempWindowColor);
  Result := TempBrush;
end;

// Issue #20 -- shared body for Ctrl-P (short path) and Alt-Ctrl-P (long path).
// Redoes the possible-calls display, then turns the rotor either to the typed
// heading (when the Call window holds a 2-3 digit bearing) or to the last beam
// heading shown.  When longPath is True the bearing is reflected 180 degrees.
procedure RedoPossibleCallsAndTurnRotor(longPath: boolean);
var
   heading: integer;
begin
   ShowStationInformation(@CallWindowString);
   DisplayGridSquareStatus(CallWindowString);
   VisibleLog.DoPossibleCalls(CallWindowString);

   if
      (
      (length(CallWindowString) in [2, 3]) and
      (StringIsAllNumbers(CallWindowString)) and
      ((StrToInt(CallWindowString) div 2) in [0..180])
      ) then
      begin
      heading := StrToInt(CallWindowString);
      tCleareCallWindow;
      end
   else
      begin
      heading := LastHeadingShown;
      end;

   if longPath then
      begin
      heading := (heading + 180) mod 360;
      end;

   RotorControl(heading);
end;

procedure ProcessMenu(menuID: integer);
var
  LowordWparam: integer;
  ID: WindowsType;
  tCardinal: HWND;
  focus: HWND;
  TempCallstring: CallString;
  //http : TidHttp;
 // page : String;
begin
  LowordWparam := LoWord(menuID);

  if LowordWparam >= menu_windows_bandmap then
    if LowordWparam <= menu_windows_hamscore then  // Issue #783 -- extended past dupesheet2
    begin
      ID := WindowsType(LowordWparam - menu_windows_bandmap + 1);
      if not tWindowsExist(ID) then
        OpenTR4WWindow(ID)
      else
        CloseTR4WWindow(ID);
      Exit;
    end;

  case LowordWparam of
    menu_alt_increment_time_1..menu_alt_increment_time_0:
      begin
        IncrementTime(LowordWparam - menu_alt_increment_time_1 + 1);
      end;

    menu_options:
      RunOptionsDialog(cfAll);

    // menu_bandplan:
    // tDialogBox(44, @BMCFDlgProc);

    menu_appearance:
      RunOptionsDialog(cfAppearance);

    menu_colors:
      RunOptionsDialog(cfCol);

    // tDialogBox(61, @SettingsDlgProc2);
    // DialogBoxParam(hInstance, MAKEINTRESOURCE(61), tr4whandle, @SettingsDlgProc2, integer(cfAll));

    menu_messages: //tDialogBox(71, @MESDlgProc);
      CreateModalDialog(205, 70, tr4whandle, @MESDlgProc, 0);

    menu_import_adif:
      begin
        ImportFromADIF;
        (*Windows.ZeroMemory(@TR4W_ADIF_FILENAME, SizeOf(TR4W_ADIF_FILENAME));
        if OpenFileDlg(nil, tr4whandle, 'ADIF (*.adi)'#0'*.adi', TR4W_ADIF_FILENAME, OFN_HIDEREADONLY or OFN_ENABLESIZING or OFN_FILEMUSTEXIST) then
        begin
        if QSOTotals[All, Both] > 0 then
        if YesOrNo(tr4whandle, TC_APPENDIMPORTEDQSOSTOCURRENTLOG) = IDno then Exit;
       // if ImportFromADIFThreadID = 0 then tCreateThread(@ImportFromADIF, ImportFromADIFThreadID);
        ImportFromADIF;
        end;
        *)
      end;

    menu_export_notes: MakeNotesList;

    menu_cat_radio_one:
      begin
        CATWTR := @Radio1;
        // DialogBoxParam(hInstance, MAKEINTRESOURCE(66), tr4whandle, @CATDlgProc, integer(@Radio1));
        tDialogBox(66, @CATDlgProc);
        // RunOptionsDialog(cfRadio1);
      end;

    menu_cat_radio_two:
      begin
        CATWTR := @Radio2;
        tDialogBox(66, @CATDlgProc);
        // DialogBoxParam(hInstance, MAKEINTRESOURCE(66), tr4whandle, @CATDlgProc, integer(@Radio2));
      end;

    menu_lpt:
      CreateModalDialog(145, 170, tr4whandle, @LPTDlgProc, 0);
    // tDialogBox(64, @LPTDlgProc);

    // menu_winkeyer2: tDialogBox(67, @WinKeyer2SettingsDlgProc);
    menu_winkeyer2: RunOptionsDialog(cfWK);

    menu_alt_WkMode: // 4.60.1
      begin
        wkClose;
        wkOpen;
      end;

    //alt
    menu_alt_dupecheck: DupeCheckOnInactiveRadio(False);

    menu_alt_tooglerigs:
      begin
        ActiveRadioPtr^.tTwoRadioMode := TR0;
        InActiveRadioPtr^.tTwoRadioMode := TR0;
        SwapRadios;
        // InactiveRigCallingCQ := False;
        Str(InActiveRadioPtr.SpeedMemory, SpeedString);
        {KK1L: 6.73 Used to use a variable CheckSpeed}
      end;

    menu_alt_autocqresume:
      RunAutoCQ;

    menu_alt_SO2R_edit:
      begin
        tAltE;
        if SO2R_Swap then
          processreturn;
      end;

    menu_alt_savetofloppy:
      SaveLogFileToFloppy;

    menu_alt_swapmults:
      SwapMultDisplay;

    menu_alt_incnumber:
      tAltI;

    menu_alt_multbell:
      begin
        InvertBoolean(MultiplierAlarm);

        if MultiplierAlarm then
          DoABeep(BeepCongrats);
      end;
    menu_alt_p: OpenListOfMessages;
    menu_alt_killcw: ToggleCW(True);
    menu_alt_searchlog:
      // tDialogBox(47, @LogSearchDlgProc);
      CreateModalDialog(387, 150, tr4whandle, @LogSearchDlgProc, 0);

    menu_alt_transfreq: tr4w_alt_n_transmit_frequency;

    menu_alt_x: ExitProgram(True);

    menu_alt_autocq:
      begin
        // if ActiveMode = CW then
        if tAutoCQMode = False then
          // tDialogBox(70, @AutoCQDlgProc);
          CreateModalDialog(145, 60, tr4whandle, @AutoCQDlgProc, 0);
        //QuickDisplay('Enter Time XX:YY GMT:');
        //Readln(junk);
      end;

    menu_alt_cwspeed:
      SetNewCodeSpeed;

    menu_alt_settime:
      TimeApplet(0);

    menu_alt_setnettime:
      if YesOrNo(tr4whandle, TC_SENDTIMETOCOMPUTERSONTHENETWORK) = IDYES then
      begin
        Windows.GetSystemTime(NetTimeSync.tsTime);
        SendToNet(NetTimeSync, SizeOf(NetTimeSync));
      end;

    menu_alt_flushlogtodisk:
      begin
        // MoveEditableLogIntoLogFile;
        UpdateTotals2;
      end;

    menu_alt_deleteqso:
      begin
        DeleteLastContact;
        LastTwoLettersCrunchedOn := '';
      end;

    menu_alt_initialexhange:
      begin
        LOGSUBS2.DoAltZ();
      end;

    menu_alt_tooglesidetone:
      tr4w_toggle_sidetone;

    menu_alt_toogleautosend:
      begin
        if AutoSendCharacterCount > 0 then
          InvertBoolean(AutoSendEnable);
        DisplayAutoSendCharacterCount;
      end;

    menu_alt_bandup:
      begin
        RememberFrequency;
        LastDisplayedBand := NoBand; // Force DisplayBandMode to always call SetRadioFreq
        BandDownOrUp(DirectionUp);
        ShowInformation;
      end;

    menu_alt_banddown:
      begin
        RememberFrequency;
        LastDisplayedBand := NoBand; // Force DisplayBandMode to always call SetRadioFreq
        BandDownOrUp(DirectionDown);
        ShowInformation;
      end;

    menu_alt_ssbcwmode:
      begin
        RememberFrequency;
        ToggleModes;
        DisplayAutoSendCharacterCount;
        ShowInformation;
        VisibleLog.ShowQSOStatus(@CallWindowString);
        ShowFMessages(0);
      end;

    menu_ctrl_trpath:
      begin
        quickdisplay(tr4w_path_name);
      end;

    menu_ctrl_ptt: // 4.53.9
      begin
        if PTT_Set then
        begin
          PTTOFF;
          PTT_Set := False;
        end
        else
        begin
          PTTON;
          PTT_Set := True;
        end;
      end;

    menu_ctrl_sendkeyboardinput:
      // if (ActiveMode = CW) or (ActiveMode = Digital) then
      begin
        // Issue #1006: if a Send Keyboard Input dialog is already open, do not
        // open a second one. Clicking a (send from keyboard) function-key button
        // re-enters here while the dialog is up -- the modal disables only the
        // main window, not the function-key window -- and the nested modal plus
        // the single SendKeyboardWindow handle leaves the dialog unclosable.
        if SendKeyboardInputDialogOpen then Exit;
        focus := GetFocus;
        if ActiveMode = CW then
          if not CWEnable then
             begin
             logger.Warn('Trying menu_ctrl_sendkeyboardinput while CWEnable is false');
             Exit;
             end;
        tCardinal := tr4whandle;
        if QTCRWindow <> 0 then
          tCardinal := QTCRWindow;
        if QTCSWindow <> 0 then
          tCardinal := QTCSWindow;
        // DialogBox(hInstance, MAKEINTRESOURCE(60), tCardinal, @SendKeyboardCWDlgProc);
        CreateModalDialog(230, 20, tCardinal, @SendKeyboardCWDlgProc, 0);
        SetFocus(focus);
      end;
    // tDialogBox(60, @SendKeyboardCWDlgProc);

    menu_ctrl_cleardupesheet:
      tClearDupesheet_Ctrl_K;

    menu_ctrl_viewlogdat:
      // tDialogBox(74, @LogEditDlgProc);
      CreateModalDialog(396, 212, tr4whandle, @LogEditDlgProc, 0);

    menu_ctrl_note:
      tr4w_add_note_in_log;

    menu_ctrl_missmultsreport:
      begin
        if (ActiveDXMult = NoDXMults) or (not MultByBand) then
          Exit;
        tDialogBox(74 {45}, @MissingMultsReportProc);
      end;

    menu_ctrl_redoposscalls:
      begin
        RedoPossibleCallsAndTurnRotor(False);   // Ctrl-P -- short path
      end;

    menu_alt_ctrl_redoposscalls:                // Issue #20
      begin
        RedoPossibleCallsAndTurnRotor(True);    // Alt-Ctrl-P -- long path
      end;

    menu_ctrl_qtcfunctions:
      begin

        WAEQTC2;
        DisplayTotalScore;
        UpdateTotals2;
        // FrmSetFocus;
        tCallWindowSetFocus;

      end;

    menu_ctrl_recalllastentry:

      if EscapeDeletedCallEntry <> '' then
        PutCallToCallWindow(EscapeDeletedCallEntry);

    menu_ctrl_refreshbandmap:
      // UpdateBlinkingBandMapCall;
      Windows.SetFocus(BandMapListBox); // 4.84.1

    menu_ctrl_cursorinbandmap:
      begin
        if tWindowsExist(tw_BANDMAPWINDOW_INDEX) then
          begin
          BandMapSettingFocus := True;
          Windows.SetFocus(BandMapListBox);
          BandMapSettingFocus := False;
          end;
      end;

    menu_ctrl_cursorintelnet:
      begin
        if TelnetListBox = 0 then
          Exit;

        // if tr4w_CallWindowActive or tr4w_ExchangeWindowActive then
        {?}
        // if ActiveMainWindow in [awExchangeWindow, awCallWindow] then
        if Windows.GetFocus <> TelnetListBox then
        begin
          Windows.SetFocus(TelnetListBox);
          LowordWparam := Windows.SendMessage(TelnetListBox, LB_GETCURSEL, 0,
            0);
          if (LowordWparam = LB_ERR) or (LowordWparam <
            Windows.SendMessage(TelnetListBox, LB_GETTOPINDEX, 0, 0)) then
          begin
            LowordWparam := Windows.SendMessage(TelnetListBox, LB_GETCOUNT, 0, 0)
              - 1;
            Windows.SendMessage(TelnetListBox, LB_SETCURSEL, LowordWparam, 0);
            ActiveMainWindow := awUnknown;
          end;
        end
        else
        begin
          FrmSetFocus;
          Exit;
        end;

      end;

    menu_ctrl_incAQSLinterval:
      if AutoQSLInterval < 6 then
      begin
        inc(AutoQSLInterval);
        AutoQSLCount := AutoQSLInterval;
        DisplayAutoQSLInterval;
      end;

    menu_ctrl_decAQSLinterval:
      if AutoQSLInterval > 0 then
      begin
        dec(AutoQSLInterval);
        AutoQSLCount := AutoQSLInterval;
        DisplayAutoQSLInterval;
      end;

    menu_ctrl_showCallsign:
      begin
        if CallWindowString <> '' then
        begin
          Format(wsprintfBuffer, 'Callsign %s', @CallWindowString[1]);
          ShowMessage(wsprintfBuffer);
        end
        else
          ShowMessage('Empty');
      end;

    menu_ctrl_showSpeed:
      begin
        if ActiveMode = CW then
        begin
          Format(wsprintfBuffer, 'Speed %u', CodeSpeed);
          ShowMessage(wsprintfBuffer);
        end;
      end;

    menu_ctrl_showBand:
      begin
        Format(wsprintfBuffer, 'Band %s',
          BandStringsArrayWithOutSpaces[ActiveBand]);
        ShowMessage(wsprintfBuffer);
      end;

    menu_ctrl_showQSONumber:
      begin

{$IF tDebugMode}
        CPUButtonProc;
{$ELSE}
        Format(wsprintfBuffer, 'QSO number %u', TotalContacts);
        ShowMessage(wsprintfBuffer);
{$IFEND}
      end;

    menu_ctrl_logqsowithoutcw:
      tr4w_log_qso_without_cw;

    menu_ctrl_sendspot:
      // if TelnetSock <> 0 then
      // tDialogBox(59, @SendSpotDlgProc);
      CreateModalDialog(150, 90, tr4whandle, @SendSpotDlgProc, 0);

    menu_ctrl_clearmultsheet:
      begin
        ClearMultSheet_CtrlC;
      end;

    menu_send_message:
      begin
        NetIntercomMessage.imSender := ComputerID;
        Windows.ZeroMemory(@NetIntercomMessage.imMessage,
          SizeOf(NetIntercomMessage.imMessage));
        tInputDialogLowerCase := True;
        NetIntercomMessage.imMessage :=
          QuickEditResponse(TC_MESSAGETOSENDVIANETWORK, 80);
        if NetIntercomMessage.imMessage <> '' then
          SendToNet(NetIntercomMessage, SizeOf(NetIntercomMessage));
      end;

    menu_ctrl_ct1bohscreen:
      // tDialogBox(40, @ct1bohDlgProc);
      CreateModalDialog(330 + 10, 68 + 10, tr4whandle, @ct1bohDlgProc, 0);

    menu_ctrl_PlaceHolder: AddBandMapPlaceHolder;

    menu_mainwindow_setfocus: FrmSetFocus;

    menu_insertmode: InvertBooleanCommand(@InsertMode);

    menu_ctrl_SplitOff: // n4af 4.47.5
      tr4w_alt_n_transmit_frequency;

    menu_escape:
      Escape_proc;

    menu_csv:
      ExportToCSV;

    menu_inactiveradio_cwspeedup:
      if InActiveRadioPtr.SpeedMemory < (99 - CodeSpeedIncrement) then
        inc(InActiveRadioPtr.SpeedMemory, CodeSpeedIncrement);

    menu_inactiveradio_cwspeeddown:
      if InActiveRadioPtr.SpeedMemory > (CodeSpeedIncrement + 1) then
        dec(InActiveRadioPtr.SpeedMemory, CodeSpeedIncrement);

    menu_cwspeedup:
      begin
        if tAutoCQMode = True then
        begin
          inc(AutoCQDelayTime, 500);
          tDisplayAutoCQStatus;
          Exit;
        end;
        if ActiveMode = CW then
          SpeedUp;
      end;

    menu_cwspeeddown:
      begin
        if tAutoCQMode = True then
        begin
          if AutoCQDelayTime > 500 then
            dec(AutoCQDelayTime, 500);
          tDisplayAutoCQStatus;
          Exit;
        end;
        if ActiveMode = CW then
          SlowDown;
      end;

    menu_syncpctime:
      begin
        //tDialogBox(48, @SynchronizeTimeDlgProc);
        CreateModalDialog(235, 90, tr4whandle, @SynchronizeTimeDlgProc, 0);
        {
        WinExec('w32tm /config /syncfromflags:manual,domhier /manualpeerlist:pool.ntp.org', SW_NORMAL);
        WinExec('w32tm /config /update', SW_NORMAL);
        WinExec('w32tm /resync', SW_NORMAL);
        }
      end;

    //C:\>w32tm /config /syncfromflags:manual /manualpeerlist:ntp5.tamu.edu
    //C:\>w32tm /config /update

    // menu_get_offset:
    // WinExec('w32tm /stripchart /computer:pool.ntp.org /dataonly /samples:5', SW_NORMAL);

    // WinExec('cmd.exe /k start /b "w32tm /stripchart /computer:pool.ntp.org /dataonly /samples:5"', SW_NORMAL);
    //'cmd.exe /k start /b ????\conp.exe'

    // WinExec('w32tm /resync', SW_NORMAL);
    //w32tm /resync
    // w32tm /stripchart /computer:pool.ntp.org /dataonly /samples:1

    menu_beaconsmonitor:
      // tDialogBox(49, @BeaconsMonitorDlgProc);
      CreateModalDialog(170, 175, tr4whandle, @BeaconsMonitorDlgProc, 0);

    // menu_COAX_Length_Calculator:
    // tDialogBox(51, @COAX_Length_CalculatorDlgProc);

    // menu_Distance:
    // tDialogBox(53, @DistanceDlgProc);

    // menu_Grid:
    // tDialogBox(55, @GridDlgProc);

    // menu_lc:
    // tDialogBox(56, @LCDlgProc);

    item_calculator: WinExec('calc.exe', SW_SHOW);

    menu_reset_radio_ports:
      begin
        ResetRadioPorts;
        {logger.info('Resetting radio ports');
        if ActiveRadioPtr.tNetObject <> nil then
           begin
           ActiveRadioPtr.tNetObject.Disconnect;
           ActiveRadioPtr.tNetObject.Connect;
        end;

        ActiveRadioPtr.CheckAndInitializePorts_ForThisRadio;
        //
        // Handle radio two
        //
        if InActiveRadioPtr.tNetObject <> nil then
           begin
           InActiveRadioPtr.tNetObject.Disconnect;
           InActiveRadioPtr.tNetObject.Connect;
           end
         else if InActiveRadioPtr.tNetObject <> nil then
            begin
            InActiveRadioPtr.tNetObject.Disconnect;
            InActiveRadioPtr.tNetObject.Connect;
            end;

         InActiveRadioPtr.CheckAndInitializePorts_ForThisRadio;
         }
      end;

    menu_pingserver:
      begin
        Format(wsprintfBuffer, 'ping %s -w 2000 -n 10', @ServerAddress[1]);
        WinExec(wsprintfBuffer, SW_SHOW);
      end;

    menu_runserver:
      begin
        Format(wsprintfBuffer, '%sserver\tr4wserver.exe', TR4W_PATH_NAME);
        WinExec(wsprintfBuffer, SW_NORMAL);
      end;

    menu_windowsmanager:
      begin
        //tDialogBox(57, @WindowsManagerDlgProc);
        CreateModalDialog(150, 120, tr4whandle, @WindowsManagerDlgProc, 0);
        if ManageWindow = 0 then
          Exit;
        Windows.GetWindowRect(ManageWindow, tr4w_TempRect);
        SendMessage(ManageWindow, $313, 0, MakeLong(tr4w_TempRect.Left,
          tr4w_TempRect.Top + 20));
        FrmSetFocus;
      end;

    menu_volume_control: WinExec('SNDVOL32.EXE', SW_SHOWNORMAL);
    menu_recording_control: WinExec('SNDVOL32.EXE -r', SW_SHOWNORMAL);
    // menu_soundrecorder: WinExec('SNDREC32.EXE', SW_SHOWNORMAL);

    menu_cabrillo: OpenStationInformationWindow(integer(@CreateCabrilloFile));
    menu_summary: OpenStationInformationWindow(integer(@SummarySheet));
    menu_3830scores: ExportTo3830Scores;  // Issue: 3830 quick-submission report
    menu_edit_cabrillo_summary: OpenStationInformationWindow(0);  // Issue #914
    menu_export_edi: OpenStationInformationWindow(integer(@ExportToEDI));

    menu_scorebyhour: ScoreByHour;
    menu_continentlist: ContinentReport;
    menu_qsobycountry:
      {ShowReport(rtQSOsByCountryByBand);//}QSOsByCountryByBand;
    menu_adif: ExportToADIF;

    menu_trlog:
      begin
        if EscapeDeletedCallEntry <> '' then
          PutCallToCallWindow(EscapeDeletedCallEntry);
      end;

    menu_initial_ex_list:
      begin
        MakeReportFileName('CUSTOM_INITIAL.EX');
        GenerateCallsignsList(@ReportsFilename[1]);
        FilePreview;
      end;
    menu_allcallsigns_list: MakeAllCallsignsList;
    menu_first_call_work_ineachcountry:
      {ShowReport(rtFirstCountry);//}tFirstCallInEachCountry;
    menu_first_call_work_InEachZone:
      {ShowReport(rtFirstZone);//}tFirstCallInEachZone;

    // menu_POSSIBLEBADZONE: ZoneReport;

    menu_band_changes: BandChangeReport;

    menu_log_file_properties:
      RunExplorer(@TR4W_LOG_PATH_NAME);

    menu_exit: ExitProgram(True);

    menu_clear_log:
      if YesOrNo(tr4whandle, TC_REALLYWANTTOCLEARTHELOG) = IDYES then
        ClearLog;

{$IF OGLVERSION}
    menu_about:
      tDialogBox(68, @AboutDlgProc);
{$ELSE}
    menu_about:
      MessageBox(tr4whandle, tAboutText, tr4w_ClassName, MB_TOPMOST
        {or MB_RTLREADING});
    //tDialogBox(68, @AboutDlgProc);
{$IFEND}

    // menu_send_bug: SendMail('tr4w@qrz.ru', True);

    menu_historytxt:
      begin
        // Issue #986 -- open in the system default text editor, not Notepad.
        Format(wsprintfBuffer, '%shistory.txt', TR4W_PATH_NAME);
        OpenInDefaultTextEditor(wsprintfBuffer);
      end;

    menu_wiki_rus:
      OpenUrl('http://www.tr4w.com/wiki/');

    menu_home_page:
      OpenUrl('http://www.tr4w.net/'); // n4af 04.42.5

{$IF LANG = 'RUS'}
    menu_contents:
      // WinHelp(tr4whandle, TR4W_HLP_FILENAME, HELP_CONTENTS, 0);
      // Shellexecute(0, 'open', TR4W_HLP_FILENAME, nil, nil, SW_SHOWNORMAL);
      ShowHelp('index');
{$IFEND}

    menu_download_latest_cty_dat:
      begin
      QuickDisplay(PChar('Downloading CTY.DAT...'));
      DownloadCTYAsync(string(PChar(@TR4W_CTY_FILENAME)), tr4whandle);
      end;

    menu_download_pota_parks:
      begin
      QuickDisplay('Downloading POTA parks...');
      DownloadPOTAParksAsync(POTAParksFilePath, tr4whandle);
      end;

    menu_repeat_pota_parks:
      HandleRepeatPOTAParks;

    menu_hamscore_resync:                 // Issue #783 Phase 3
      begin
      QuickDisplay('HamScore: queueing full log resync...');
      HamScoreResyncFromScratch;       // enqueue <deletelog>
      SendFullLogToHamScore;           // enqueue every QSO from the binary log
      end;

    menu_spmode_ortab:
      ProcessTAB(LowordWparam);

    menu_cqmode: SetOpMode(CQOpMode);
    tr4w_accelerator_vkreturn: ProcessReturn;

    // menu_alt_resetwakeup:
    // WakeUpCount := 0;
    menu_alt_init_qso: InitializeQSO;

    menu_settimezone:
      TimeApplet(1);

    menu_rescore:
      begin
        tUpdateLog(actRescore);
        LoadinLog;
      end;

    //tLoadinLog({True, }True);
    // RunRescoreDialog(UPDATEALLQSOS);

    // menu_fast_rescore: RunRescoreDialog(FASTRESCORE);

    menu_login:
      begin
        Windows.ZeroMemory(@TempCallstring, SizeOf(TempCallstring));
        TempCallstring := QuickEditResponse(TC_CURRENT_OPERATOR_CALLSIGN, 6);
        if length(TempCallstring) > 0 then
        begin
          if IsValidUSPrefix(TempCallString) then
          begin
            if IsValidUSCallsign(TempCallString) then
            begin
              Windows.CopyMemory(@CurrentOperator, @TempCallstring[1], 6);
              SetMainWindowText(mweCurrentOperator, CurrentOperator);
              Sheet.SaveRestartFile; // Issue 661 ny4i
              SendStationStatus(sstOperator);
            end
            else
            begin
              ShowMessage('Login call does not look like a callsign');
            end;
          end
          else if IsValidCallsign(TempCallString) then
          begin
            Windows.CopyMemory(@CurrentOperator, @TempCallstring[1], 6);
            SetMainWindowText(mweCurrentOperator, CurrentOperator);
            Sheet.SaveRestartFile; // Issue 661 ny4i
            SendStationStatus(sstOperator);
          end
          else
          begin
            ShowMessage('Login call does not look like a callsign');
          end;
        end;
        // ShowMessage(CurrentOperator);
      end;

    menu_getserverlog:
      SendToNet(NET_LOGINFO_MESSAGE, SizeOf(NET_LOGINFO_MESSAGE));
    // tDialogBox(73, @GetServerLogDlgProc);

    menu_clearserverlog:
      begin
        tInputDialogWarning := True;
{$IF NOT tDebugMode}
        if QuickEditResponse(TC_CLEARALLLOGS, 12) = 'CLEARALLLOGS' then
{$IFEND}

        begin
          ServerMessage.smMessage := SM_CLEARALLLOGS_MESSAGE;
          SendToNet(ServerMessage, SizeOf(ServerMessage));
        end;
      end;

    menu_clear_dupesheet_in_network:
      begin
        tInputDialogWarning := True;
{$IF NOT tDebugMode}
        if QuickEditResponse(TC_CLEAR_DUPESHEET_NET, 14) = 'CLEARDUPESHEET' then
{$IFEND}
        begin
          ServerMessage.smMessage := SM_CLEAR_DUPESHEET_MESSAGE;
          SendToNet(ServerMessage, SizeOf(ServerMessage));
        end;
      end;

    menu_clear_multsheet_in_network:
      begin
        tInputDialogWarning := True;
{$IF NOT tDebugMode}
        if QuickEditResponse(TC_CLEAR_MULTSHEET_NET, 14) = 'CLEARMULTSHEET' then
{$IFEND}
        begin
          ServerMessage.smMessage := SM_CLEAR_MULTSHEET_MESSAGE;
          SendToNet(ServerMessage, SizeOf(ServerMessage));
        end;
      end;

    // menu_compare_logs: SendToNet(NET_LOGINFO_MESSAGE, SizeOf(NET_LOGINFO_MESSAGE));

  {  menu_wa7bnm_calendar:
      OpenUrl('http://www.hornucopia.com/contestcal/weeklycont.php');
    // Shellexecute(0, 'open', 'http://www.hornucopia.com/contestcal/weeklycont.php', nil, nil, SW_NORMAL); // 4.75.3
    {begin
    http := TidHttp.Create(nil);
    try
    page := http.get('http://www.hornucopia.com/contestcal/weeklycont.php');
    finally
    http.Free;
    end;
    end;
    }
    menu_3830_scores_posting: // 4.51.8
      // OpenUrl('http://www.3830scores.com/');
      Shellexecute(0, 'open', 'http://www.3830scores.com/', nil, nil,
        SW_NORMAL);
    // 4.75.3
    menu_arrl_submit: // 4.53.3
      // OpenUrl('http://contest-log-submission.arrl.org/');
      Shellexecute(0, 'open', 'http://contest-log-submission.arrl.org/', nil,
        nil, SW_NORMAL); // 4.75.3

    menu_qrzru_calendar:
      begin
        Format(TempBuffer1, 'http://www.qrz.ru/contest/detail/%d.html',
          ContestsArray[Contest].QRZRUID);
        // OpenUrl(TempBuffer1);
        Shellexecute(0, 'open', TempBuffer1, nil, nil, SW_NORMAL); // 4.75.3
      end;

    menu_WA7BNM_calendar:
      begin
        Format(TempBuffer1,
          'https://contestcalendar.com/contestdetails.php?ref=%u', // 4.127.1',
          ContestsArray[Contest].WA7BNM);
        //   OpenUrl(TempBuffer1);
        Shellexecute(0, 'open', tempbuffer1, nil, nil, SW_NORMAL); // 4.127.1

      end;

    menu_run_devicemanager:
      // tEnumeratePorts;
      WinExec('rundll32.exe devmgr.dll, DeviceManager_Execute', SW_SHOWNORMAL);

    menu_ctrl_execute_config: // 4.67.5
      begin
        if OpenFileDlg(nil, tr4whandle, TC_CONFIGURATION_FILE +
          ' (*.cfg)'#0'*.cfg'#0#0, TR4W_EXECONFIGFILE_FILENAME, OFN_HIDEREADONLY
          or
          OFN_ENABLESIZING) then
          ExecuteConfigurationFile(ShortString(TR4W_EXECONFIGFILE_FILENAME));
      end;

    menu_ctrl_shdxcallsign:
      begin
        Windows.ZeroMemory(@TempCallstring, SizeOf(TempCallstring));
        if CallWindowString <> '' then
          TempCallstring := CallWindowString
        else
          TempCallstring := VisibleLog.LastEntry(False, letCallsign);

        if TempCallstring <> '' then
        begin
          Format(wsprintfBuffer, 'SH/DX %s 5', @TempCallstring[1]);
          SendViaTelnetSocket(wsprintfBuffer);
        end;
      end;

  end;
end;

procedure ProcessTAB(lowparam: Word);
begin
{$IF NOT MORSERUNNER}
  if lowparam = menu_spmode_ortab then
    if OpMode = CQOpMode then
    begin
      SetOpMode(SearchAndPounceOpMode);
      Exit;
    end;
{$IFEND}

  // ChangeFocus('ProcessTAB');

  if ActiveMainWindow = awCallWindow then
    tExchangeWindowSetFocus
  else if ActiveMainWindow = awExchangeWindow then
    tCallWindowSetFocus;
  {
  if tr4w_CallWindowActive then
  begin
  tExchangeWindowSetFocus;
  tr4w_CallWindowActive := False;
  end
  else
  if tr4w_ExchangeWindowActive then
  begin
  tCallWindowSetFocus;
  tr4w_CallWindowActive := True;
  end
  }
end;

procedure ProcessKeyDownTerm; // 4.46.2
begin
  if activeradioptr^.cwbycat and autosendenable and autocallterminate then
    if length(CallWindowString) = AutoSendCharacterCount then
    begin
      tExchangeWindowSetFocus;
      tSetExchWindInitExchangeEntry;
      CheckAndSetInitialExchangeCursorPos;
      processreturn;
    end;
end;

procedure ProcessReturn;
var
  TempHWND: HWND;
  revnr: string[6];

label
  SetFreq;
begin
  tDispalyOnAirTime;
  TempHWND := Windows.GetFocus;
  if {TempHWND}Windows.GetParent(TempHWND) = TelnetCommandWindow then
  begin
    if TelnetSock <> 0 then
      PostMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle,
        WM_COMMAND, 104, TempHWND);
    Exit;
  end;

  if TempHWND = BandMapListBox then
  begin
    PostMessage(tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle, WM_COMMAND,
      131173, TempHWND);
    Exit;
  end;

  if TempHWND = TelnetListBox then
  begin
    PostMessage(tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle, WM_COMMAND,
      131173, TempHWND);
    Exit;
  end;

  // if tr4w_ExchangeWindowActive = False then if tr4w_CallWindowActive = False then
  if ActiveMainWindow = awEditableLog then
    if TempHWND = wh[mweEditableLog] then
    begin
      EditableLogWindowDblClick;
      Exit;
    end;

  // check if membership # entered
  // n4af 4.67.2 check for reverse lookup of membership #
  // 4.67.3 look for member # in trmaster.asc
  if (CallWindowString[1]) = 'R' then
  begin
    RevNr := copy(CallWindowString, 2, length(callwindowstring) - 1);
    if StringIsAllNumbers(RevNr) then
    begin
      if not CallsignsList.FindNumber(RevNr) then
        exit;
      PutCallToCallWindow(CallWindowString);
      exit;
    end;
  end;
  SetFreq:
  if TuneOnFreqFromCallWindow then
    Exit;
  if CallWindowString = 'TXON' then
  begin
    logger.debug('Calling tPTTVIACAT with true');
    tPTTVIACAT(true);
  end
  else if CallWindowString = 'TXOFF' then
  begin
    tPTTVIACAT(false);
  end;
  if (ActiveExchange = RSTDomesticQTHExchange) then
    if (CallWindowString <> '') and (ExchangeWindowString <> '') then
      ParseFourFields(ExchangeWindowString, s1, s2, s3, s4);
  {    if S3 <> '' then
       begin
        ExchangeWindowString := S3

      }
  if OpMode = CQOpMode then
  begin
    ctyGetCountryID(callwindowstring);
    if SwitchNext then //4.52.3
    begin
      if (CallWindowString <> '') then // 4.92.2
      begin
        SwitchNext := False; // 4.92.2
        Switch := False;
        if ((WKBusy) or (CWThreadID <> 0)) then // 4.52.4 issue 192
        begin
          FlushCWBuffer;
          ReturnInCQOpMode;
          exit;
        end
        else
          swapradios;
        if (AutoSendEnable) and (AutoSendCharacterCount > 0) then
        begin // end 4.52.4
          SwapRadios;
          InactiveRigCallingCQ := False;
        end;
      end;
    end;

    if switch = False then // n4af 4.44.7
      InactiveRigCallingCQ := False // n4af 4.42.11
    else
    begin
      if autosendenable then // n4af 4.44.7
      begin // do not swap yet if autosend
        switch := False;
        ReturnInCQOpMode;
        exit;
      end;
      checkinactiverigcallingcq;
      Switch := False;
      if CallWindowString = '' then // 4.52.3
        SwitchNext := False;
      // exit;
    end;
    ReturnInCQOpMode;
    Exit;
  end;

  if OpMode = SearchAndPounceOpMode then
  begin
    ReturnInSAPOpMode;
    // Exit;
  end;

end;

procedure RepeatLastCWMessage;
   // '=' repeat-last-CW-message: replay the exact characters last sent on CW.
   // Centralized so it works in both the call and exchange windows -- it is
   // dispatched from the main message loop (tr4w.dpr), the same way the
   // function keys are, rather than from a single window's key handler.
begin
   if LastCWMessage <> '' then
      begin
      AddStringToBuffer(LastCWMessage, CWTone);
      if IsCWByCATActive then
         begin
         AddStringToBuffer(CWByCATBufferTerminator, CWTone);
         end;
      end;
end;

procedure CallWindowKeyDownProc(wParam: integer);
var
  Key: Char;
  itempos: integer;
  p: HWND;
  c: HWND;
label
  wait;
begin
  CallWinKeyDown := True; // 4.52.4
  CallsignIsTypedByOperator := True;
  Key := Char(wParam);
  logger.trace('[CallWindowKeyDownProc] Key pressed = ' + key);
  if tAutoCQMode then
    if TryKillAutoCQ then
      Escape_proc;

  if key = '-' then
  begin
    tr4w_alt_n_transmit_frequency; // Note this is a toggle
    tCleareCallWindow;
    CallWindowCharConsumed := True; // prevent WM_CHAR from inserting '-' into the cleared field
    Exit;
  end;

  // '=' repeat-last-CW-message is handled centrally in the main message loop
  // (tr4w.dpr WM_CHAR) so it works in both the call and exchange windows.
  // start sending now code
  if Key = StartSendingNowKey then
    if tAutoSendMode = False then
      if OpMode = CQOpMode then
        if ActiveMode = CW then
          if CallWindowString <> '' then
            // if (not StringHas(CallWindowString, '/')) then
          begin
            if MessageEnable then
            begin
              CheckInactiveRigCallingCQ;
              DebugMsg('[CallWindowKeyDownProc] Call AddStringToBuffer with ' +
                CallWindowString);
              AddStringToBuffer(CallWindowString, CWTone);
              if IsCWByCATActive then
              begin
                DebugMsg('[CallWindowKeyDownProc] Calling AddStringToBuffer with CWByCATBufferTerminator');
                AddStringToBuffer(CWByCATBufferTerminator, CWTone);
              end;
              // PTTForceOn;
              tAutoSendMode := True;
            end;
          end;
  // autosend code here
  if (tAutoSendMode = True) then
  begin
    if Key = BackSpace then
    begin
      if EditingCallsignSent then
      begin
        // if length(CallWindowString) > 0 then
       { begin
        // Delete(CallWindowString, length(CallWindowString), 1);
        end }
      end

      else if (CWEnabled and DeleteLastCharacter) or not CWEnabled then
      begin
      end
      else
      begin
        logger.trace('[CallWindowKeyDownProc] Calling AddStringToBuffer with !');
        AddStringToBuffer('!', CWTone);
        EditingCallsignSent := True;
      end;

    end
    else
    begin
      if Key <> StartSendingNowKey then
      begin
        if IsCWByCATActive then
        begin // Send the character now - No buffering
          if true then
            // (length(CallWindowString) = AutosendCharacterCount) then //n4af 4.46.12
          begin
            logger.trace('[CallWindowKeyDownProc] Call RadioObject.SendCW with '
              + Key);
            //ActiveRadioPtr.AddTimeToCWByCATTimer(Round(1200 / DisplayedCodeSpeed) * 5); // Give us more time but this does not work yet.
            ActiveRadioPtr.SendCW(Key); // start sending if = autosend cc
            ActiveRadioPtr.SendCW(CWByCATBufferTerminator);
            // ny4i If we are sending (timer is enabled), add this element time to the timer. ny4i. That is a bit scary if it works :)

            // end;
          end;

        end
        else if wkActive then
        begin
          logger.trace('[CallWindowKeyDownProc] Calling wsSendByte with ' +
            key);
          wkSendByte(Ord(UpCase(Key)));
        end
        else
        begin

          //localMsg := Format('After AutoChar - key = %s;', [key]);
          //AddStringToTelnetConsole(PChar(localMsg),tstAlert);

          CPUKeyer.AddCharacterToCWBuffer(Key); //
        end;
      end;
      EditingCallsignSent := False;
    end;
  end;
  if (SwitchNext {and (CallWindowString<>'')} and
    ((CWThreadID <> 0) or wkBUSY or ActiveRadioPtr.CWByCAT_Sending)) then
    // 4.52.10
  begin
    FlushCWBuffer;
    SwapRadios;
    logger.trace('[CallWindowKeyDownProc] SwapExit');
    exit;
  end;
  // CallsignsList.CreatePartialsList(CallWindowString);
  p := wh[mwePossibleCall];
  c := wh[mweCall];
  if not InsertMode then
    EditSetSelLength(c, 1);
  if ((CWThreadID <> 0) or wkBUSY or ActiveRadioPtr.CWByCAT_Sending) then
    //4.52.10
  begin
    Switch := False;
    SwitchNext := False;
    InactiveRigCallingCQ := False;
    InactiveSwapRadio := False;
  end;

  itempos := SendMessage(p, LB_GETCURSEL, 0, 0);
  logger.trace('[CallWindowKeyDownProc] itemrpos');
  if Key = PossibleCallLeftKey then
    dec(itempos);
  if Key = PossibleCallRightKey then
  begin
    inc(itempos);
    logger.trace('[CallWindowKeyDownProc] itemright set ' + Key);
  end;
  if itempos = -1 then
    itempos := 0;
  SendMessage(p, LB_SETCURSEL, itempos, 0);

  itempos := SendMessage(p, LB_GETCURSEL, 0, 0);

  if Key = PossibleCallAcceptKey then

    if SendMessage(p, LB_GETCOUNT, 0, 0) > 0 then
    begin
      logger.trace('[CallWindowKeyDownProc] PutCallToCallWindow ' + Key);
      PutCallToCallWindow(LogSCP.PossibleCallList.List[itempos].Call);
    end;

end;

procedure CallWindowKeyUpProc;
begin
  if AutoSendEnable then
  begin
    if AutoSendCharacterCount = length(CallWindowString) then
    begin
      DebugMsg('[CallWindowKeyUpProc] Calling StartSendingNow with False');
      StartSendingNow(False);
    end;
  end;
end;

{------------------------------------------------------------------------------}

procedure ExchangeWindowKeyDownProc(wParam: integer);
var
  p: hwnd;
  //c: hwnd;
  itempos: integer;
  key: char;

begin
  p := wh[mwePossibleCall];
  c := wh[mweExchange];
  Key := Char(wParam);
  itempos := SendMessage(p, LB_GETCURSEL, 0, 0);
  if Key = PossibleCallLeftKey then
    dec(itempos);
  if Key = PossibleCallRightKey then
    inc(itempos);
  if itempos = -1 then
    itempos := 0;
  SendMessage(p, LB_SETCURSEL, itempos, 0);

  itempos := SendMessage(p, LB_GETCURSEL, 0, 0);

  if Key = PossibleCallAcceptKey then

    if SendMessage(p, LB_GETCOUNT, 0, 0) > 0 then
      PutCallToCallWindow(LogSCP.PossibleCallList.List[itempos].Call);

  // If the contest type uses sections and we see a section starting to be typed,
  // start pre-filling the fields where the cals are placed for SCP
  // This code is a shell at the moment for implementation of Issue 87
  // Uncomment call in MsgLoop to call this when the window is mweExchange
end;
{------------------------------------------------------------------------------}

procedure OpenTR4WWindow(ID: WindowsType);
const
  NORESIZEEDWINDOW = SWP_SHOWWINDOW or SWP_NOSIZE;
  wi: array[WindowsType] of WindowsType = (
    tw_MAINWINDOW_INDEX,
    tw_BANDMAPWINDOW_INDEX,
    tw_MASTERWINDOW_INDEX,
    tw_FUNCTIONKEYSWINDOW_INDEX,
    tw_MASTERWINDOW_INDEX,
    tw_REMMULTSWINDOW_INDEX,
    tw_RADIOINTERFACEWINDOW1_INDEX,
    tw_RADIOINTERFACEWINDOW1_INDEX,
    tw_TELNETWINDOW_INDEX,
    tw_NETWINDOW_INDEX,
    tw_MMTTYWINDOW_INDEX,
    tw_INTERCOMWINDOW_INDEX,
    tw_POSTSCORESWINDOW_INDEX,
    tw_STATIONS_INDEX,
    tw_REMMULTSWINDOW_INDEX,
    tw_REMMULTSWINDOW_INDEX,
    tw_REMMULTSWINDOW_INDEX,
    tw_MP3RECORDER,
    tw_REMMULTSWINDOW_INDEX,
    tw_MASTERWINDOW_INDEX,
    tw_HAMSCOREWINDOW_INDEX,   // Issue #783 Phase 4 -- HamScore status window
    tw_Dummy11
    );
var
  TempFlag: Cardinal;
  h: HWND;
  hMode: HWND;
  temprect: TRect;
  ctrlPt: TPoint;
  Radio: RadioPtr;
  i: integer;
begin
  if Contest = WRTC then
    if ID in [tw_MASTERWINDOW_INDEX, tw_TELNETWINDOW_INDEX,
      tw_POSTSCORESWINDOW_INDEX] then
      Exit;

{$IF NOT MMTTYMODE}
  if ID = tw_MMTTYWINDOW_INDEX then
    Exit;
{$IFEND}

  if ID = tw_NETWINDOW_INDEX then
    if not (ComputerID in ['A'..'Z']) then
    begin
      // showwarning(TC_SETCOMPUTERIDVALUE);

      SetCommand('COMPUTER ID');
      Exit;
    end;

{$IF MMTTYMODE}
  if ID = tw_MMTTYWINDOW_INDEX then
  begin
    if TR4W_MMTTYPATH[0] = #0 then
    begin
      SetCommand('MMTTY ENGINE');
      Exit;
    end;
    RichEditOperation(True);
  end;
{$IFEND}

  if tWindowsExist(ID) then
    Exit;

  Windows.CheckMenuItem(tr4w_main_menu, 10199 + Ord(ID), MF_CHECKED);
  tr4w_WindowsArray[ID].WndVisible := True;

  // if ID = tw_MixWWINDOW_INDEX then TryToLoadRICHED32DLL;
 {
  if ID = tw_RADIOINTERFACEWINDOW2_INDEX then
  h := CreateDialogParam(hInstance, MAKEINTRESOURCE(tw_RADIOINTERFACEWINDOW1_INDEX), tr4whandle, tr4w_WindowsArray[tw_RADIOINTERFACEWINDOW1_INDEX].WndProcAdr, integer(ID))
  else
  h := CreateDialogParam(hInstance, MAKEINTRESOURCE(ID), tr4whandle, tr4w_WindowsArray[ID].WndProcAdr, integer(ID));
 }

  //h := CreateDialogParam(hInstance, MAKEINTRESOURCE(wi[ID]), tr4whandle, tr4w_WindowsArray[ID].WndProcAdr, integer(ID));
  h := CreateDialogIndirectParam(hInstance, PDlgTemplate(@MAINTR4WDLGTEMPLATE)^,
    tr4whandle, tr4w_WindowsArray[ID].WndProcAdr, integer(ID));

  Windows.GetMenuString(tr4w_main_menu, 10199 + Ord(ID), TempBuffer1,
    SizeOf(TempBuffer1), MF_BYCOMMAND);

  for i := 0 to SizeOf(TempBuffer1) - 1 do
    if TempBuffer1[i] = #9 then
    begin
      TempBuffer1[i] := #0;
      Break;
    end;

  Windows.SetWindowText(h, TempBuffer1);
  {
  Windows.GetMenuString(tr4w_main_menu, 10199 + Ord(ID), wsprintfBuffer, SizeOf(wsprintfBuffer), MF_BYCOMMAND);
  for TempFlag := 0 to 100 do if wsprintfBuffer[TempFlag] = #9 then wsprintfBuffer[TempFlag] := #0;
  Windows.SetWindowText(h, wsprintfBuffer);
  }
  tr4w_WindowsArray[ID].WndHandle := h;

  if NoCaption then
    // if ID <> tw_FUNCTIONKEYSWINDOW_INDEX then
    Windows.SetWindowLong(h, GWL_STYLE, GetWindowLong(h, GWL_STYLE) -
   //   WS_CAPTION);
        WS_POPUP);

  Radio := nil;
  if ID = tw_RADIOINTERFACEWINDOW1_INDEX then
    Radio := @Radio1;
  if ID = tw_RADIOINTERFACEWINDOW2_INDEX then
    Radio := @Radio2;

  if Radio <> nil then
  begin
    Radio.tRadioInterfaceWndHandle := h;
    Radio.RITWndHandle := Windows.GetDlgItem(h, 121);
    Radio.XITWndHandle := Windows.GetDlgItem(h, 122);
    Radio.SplitWndHandle := Windows.GetDlgItem(h, 123);
    // Dynamically create mode labels to the right of each VFO frequency (Issue #566).
    // VFO A mode: right of control 102
    Windows.GetWindowRect(Windows.GetDlgItem(h, 102), temprect);
    ctrlPt.X := temprect.Right + 4;
    ctrlPt.Y := temprect.Top;
    Windows.ScreenToClient(h, ctrlPt);
    hMode := Windows.CreateWindow('STATIC', '',
       WS_CHILD or WS_VISIBLE or SS_LEFT,
       ctrlPt.X, ctrlPt.Y,
       55, temprect.Bottom - temprect.Top,
       h, 0, hInstance, nil);
    Windows.SendMessage(hMode, WM_SETFONT, Windows.SendMessage(h, WM_GETFONT, 0, 0), 1);
    Radio.ModeVFOAWndHandle := hMode;
    // VFO B mode: right of control 104
    Windows.GetWindowRect(Windows.GetDlgItem(h, 104), temprect);
    ctrlPt.X := temprect.Right + 4;
    ctrlPt.Y := temprect.Top;
    Windows.ScreenToClient(h, ctrlPt);
    hMode := Windows.CreateWindow('STATIC', '',
       WS_CHILD or WS_VISIBLE or SS_LEFT,
       ctrlPt.X, ctrlPt.Y,
       55, temprect.Bottom - temprect.Top,
       h, 0, hInstance, nil);
    Windows.SendMessage(hMode, WM_SETFONT, Windows.SendMessage(h, WM_GETFONT, 0, 0), 1);
    Radio.ModeVFOBWndHandle := hMode;
    DisplayCurrentStatus(Radio);
  end;

  TempFlag := SWP_SHOWWINDOW;
  // if ID in [tw_RADIOINTERFACEWINDOW1_INDEX, tw_RADIOINTERFACEWINDOW2_INDEX, tw_MP3RECORDER, tw_GETSCORESWINDOW_INDEX]
  // then TempFlag := NORESIZEEDWINDOW;

  Windows.SetWindowPos(tr4w_WindowsArray[ID].WndHandle, HWND_TOP,
    tr4w_WindowsArray[ID].WndRect.Left,
    tr4w_WindowsArray[ID].WndRect.Top,
    tr4w_WindowsArray[ID].WndRect.Right - tr4w_WindowsArray[ID].WndRect.Left,
    tr4w_WindowsArray[ID].WndRect.Bottom - tr4w_WindowsArray[ID].WndRect.Top,
    TempFlag);

  if NoCaption then
    if TempFlag = NORESIZEEDWINDOW then
    begin
      Windows.GetWindowRect(h, temprect);
      temprect.Bottom := temprect.Bottom - GetSystemMetrics(SM_CYSMCAPTION);
      Windows.SetWindowPos(h, HWND_TOP, temprect.Left, temprect.Top,
        temprect.Right - temprect.Left, temprect.Bottom - temprect.Top,
        SWP_SHOWWINDOW);
    end;

  FrmSetFocus;
end;

procedure CheckNumber;
begin
  if StringIsAllNumbers(CallWindowString) then
    if CallsignsList.FindNumber(CallWindowString) then
      PutCallToCallWindow(CallWindowString);

end;

procedure CloseTR4WWindow(ID: WindowsType);
begin
  if not tWindowsExist(ID) then
    Exit;
  FindAndSaveRectOfAllWindows;
  if tr4w_WindowsArray[ID].WndHandle = Radio1.tRadioInterfaceWndHandle then
    Radio1.tRadioInterfaceWndHandle := 0;
  if tr4w_WindowsArray[ID].WndHandle = Radio2.tRadioInterfaceWndHandle then
    Radio2.tRadioInterfaceWndHandle := 0;
  DestroyWindow(tr4w_WindowsArray[ID].WndHandle);
  tr4w_WindowsArray[ID].WndHandle := 0;
  tr4w_WindowsArray[ID].WndVisible := False;
  Windows.CheckMenuItem(tr4w_main_menu, 10199 + Ord(ID), MF_UNCHECKED);
  FrmSetFocus;
end;

function CreateTR4WStaticWindow(X: Word; Y: Word; w: Word; Style: Cardinal):
  HWND;
begin
  Result := tCreateStaticWindow(nil, Style, X, Y, w, ws, tr4whandle, 0);
  tWM_SETFONT(Result, MainFont);
end;

function CreateTR4WStaticWindowID(X: Word; Y: Word; w: Word; Style: Cardinal;
  ID: HMENU): HWND;
begin
  Result := tCreateStaticWindow(nil, Style, X, Y, w, ws, tr4whandle, ID);
  tWM_SETFONT(Result, MainFont);
end;

function nfCreateTR4WStaticWindow(Text: PChar; X: Word; Y: Word; w: Word; Style:
  Cardinal): HWND;
begin
  Result := tCreateStaticWindow(Text, Style, X, Y, w, ws, tr4whandle, 0);
  tWM_SETFONT(Result, MainFont);
end;

procedure EditSetSelLength(h: HWND; Value: integer);
var
  Selection: TSelection;
begin
  SendMessage(h, EM_GETSEL, LONGINT(@Selection.StartPos),
    LONGINT(@Selection.EndPos));
  Selection.EndPos := Selection.StartPos + Value;
  SendMessage(h, EM_SETSEL, Selection.StartPos, Selection.EndPos);
  SendMessage(h, EM_SCROLLCARET, 0, 0);
end;

procedure ProcessFuntionKeys(Key: integer);
begin
  GetRealVirtualKey(Key);

{$IF MORSERUNNER}
  if Key in [VK_F1..VK_F8] then
    if MorseRunnerWindow <> 0 then
      Windows.SendMessage(MorseRunnerWindow, WM_COMMAND, Key - 96, 0);
  Exit;
{$IFEND}

  if (OpMode2 = SearchAndPounceOpMode) then
    ProcessExchangeFunctionKey(CHR(Key))
  else
    SendFunctionKeyMessage(CHR(Key), OpMode);
end;

procedure CreateDirectoryIfNotExist;
const
  DirArray: array[0..5] of PChar = ('dvk', 'dvk\lettersandnumbers',
    'dvk\fullcallsigns', 'dvk\fullserialnumbers', 'settings', 'dxcluster');
var
  i: integer;
begin
  //GetLastError = Cannot create a file when that file already exist s.

  for i := 0 to length(DirArray) - 1 do
    Windows.CreateDirectory(DirArray[i], nil);
  // Windows.CreateDirectory(GetYearString, nil);

end;

procedure CheckAndSetInitialExchangeCursorPos;
begin
  if InitialExchangeCursorPos = AtEnd then
    PlaceCaretToTheEnd(wh[mweExchange]);
  if InitialExchangeCursorPos = AtStart then
    // SetCursorPos(0,1); // n4af 4.42.7
    SendMessage(wh[mweExchange], EM_SETSEL, 0, 0); // 4.108.8

  if InitialExchangeOverwrite then
    Windows.SendMessage(wh[mweExchange], EM_SETSEL, 0, -1);
end;

procedure ClearInfoWindows;
begin
  Windows.ShowWindow(wh[mweMasterStatus], SW_HIDE);
  DispalayB4(SW_HIDE);
  // Windows.ShowWindow(B4StatusWindowHandle, SW_HIDE);
  CleanUpDisplay;
end;

procedure CPUButtonProc;
label
  1;

var
  Start, Stop: int64;

begin

  Start := GetCPU;
{$IF tDebugMode}
  // GenerateSupportedContestsNew;
  // uDocumentation.MakeContestsPagesHTML;
  // GenerateSupportedContestsNew;
  // uDocumentation.MakeCommandsListForIniFile;

{$IFEND}

  Stop := GetCPU;
  if Stop - Start < MAXLONG then
    Windows.SetWindowText(CPUButtonHandle, inttopchar(Stop - Start));

end;

procedure TREscapeCommFunction(hFile: THandle; dwFunc: Byte);
begin
  EscapeCommFunction(hFile, Cardinal(dwFunc));
{$IF tKeyerDebug}
  if (hFile = Radio1.tCATPortHandle) or (hFile = Radio1.tKeyerPortHandle) then
  begin
    if dwFunc = SETRTS then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 102, BM_SETCHECK,
        BST_CHECKED, 0);
    if dwFunc = CLRRTS then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 102, BM_SETCHECK,
        BST_UNCHECKED, 0);

    if dwFunc = SETDTR then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 103, BM_SETCHECK,
        BST_CHECKED, 0);
    if dwFunc = CLRDTR then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 103, BM_SETCHECK,
        BST_UNCHECKED, 0);
  end;
  if (hFile = Radio2.tCATPortHandle) or (hFile = Radio2.tKeyerPortHandle) then
  begin
    if dwFunc = SETRTS then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 105, BM_SETCHECK,
        BST_CHECKED, 0);
    if dwFunc = CLRRTS then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 105, BM_SETCHECK,
        BST_UNCHECKED, 0);

    if dwFunc = SETDTR then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 106, BM_SETCHECK,
        BST_CHECKED, 0);
    if dwFunc = CLRDTR then
      Windows.SendDlgItemMessage(tKeyerDebugWindowHandle, 106, BM_SETCHECK,
        BST_UNCHECKED, 0);
  end;
{$IFEND}

end;

function Get_Ctl_Code(nr: integer): Cardinal;
const
  FILE_DEVICE_UNKNOWN = $00000022;
  FILE_DEVICE_SERIAL_PORT = $0000001B;
  method_buffered = 0;
  FILE_ANY_ACCESS = $0000;
  FILE_DEVICE_PARALLEL_PORT = $00000016;
begin
  Result :=
    (FILE_DEVICE_PARALLEL_PORT shl 16) or
    (FILE_ANY_ACCESS shl 14) or
    (nr shl 2) or
    method_buffered;
end;

// Issue #1010: after an exchange-parsing error, drop the caret right after the
// offending token in the exchange window so the operator can fix it in place
// instead of arrowing back from end-of-line. No-op if no token was recorded or
// it isn't found in the current exchange text. Kept as its own procedure (not
// inlined into the long ParametersOkay) per the Delphi 7 codegen caution.
procedure PositionExchangeCursorAtErrorToken;
var
  p: integer;
begin
  if ExchangeErrorToken = '' then
    Exit;
  p := Pos(ExchangeErrorToken, ExchangeWindowString);
  if p > 0 then
  begin
    p := (p - 1) + Length(ExchangeErrorToken);   // 0-based caret just past the token
    Windows.SendMessage(wh[mweExchange], EM_SETSEL, p, p);
  end;
end;

function ParametersOkay(Call: CallString;
  ExchangeString: Str40 {CallString};
  Band: BandType;
  Mode: ModeType;
  Freq: LONGINT;
  var RData: ContestExchange): boolean;

{ This function get called when a carriage return has been pressed when
 entering exchange data. It will look at the data in the exchange
 window and decide if enough information is there to log the contact.
 If something is missing, a False response will be generated. It the
 correct information is there, a True response will be generated and
 the appropriate fields in the ContestExchange record will be updated.

 It is the responsibility of this function to put the proper multiplier
 information into the proper fields in the RData record. The
 information in the RData.QTH is "raw" information and may need
 to be modified before putting it into the DomesticQTH, DXQTH, Prefix or
 Zone fields of RData. This has the effect of doing away with
 most of the meaning of the active multiplier flags except to know that
 the multiplier is switched on. }

var
  RST: Word;
  //s1, s2, s3, s4: str20;
begin
  logger.debug('>>>Entering ParametersOkay');
  logger.debug('Calling ParametersOkay with call = %s, Band = %s, Mode = %s, freq = %d, ExchangeString = %s', [call, BandStringsArray[Band], ModeStringArray[Mode], freq, ExchangeString]);

  // RData.QTHString :='';
  ParametersOkay := False;

  GetRidOfPostcedingSpaces(ExchangeString);

  LookForOnDeckCall(ExchangeString);

  ExchangeErrorMessage := nil;
  ExchangeErrorToken := '';   // Issue #1010

  if NoLog then
  begin
    ParametersOkay := False;
    QuickDisplay(TC_SORRYNOLOG);
    DoABeep(ThreeHarmonics);
    Exit;
  end;

  LogBadQSOString := '';

  { Need this in case we exit soon }
  Windows.ZeroMemory(@RData.Callsign, SizeOf(RData.Callsign));
  RData.ID := GetGUID;
  RData.Callsign := Call;
  if (ExchangeString = '') and not (ActiveExchange in [RSTNameAndQTHExchange,
    RSTAndPOTAPark]) then // These two exchanges allow blank exchanges
  begin
    logger.debug('Exiting ParametersOkay early: ExchangeString=<%s>',
      [ExchangeString]);
    Exit;
  end;
  { if length(ExchangeString) > 5 then // 4.96.3
  CallsignUpdateEnable := False;}
  if CallsignUpdateEnable then
  begin // This looks like the secxond line should be under IF but it was not.
    RData.Callsign := GetCorrectedCallFromExchangeString(ExchangeString);
    RData.Callsign[Ord(RData.Callsign[0]) + 1] := #0;
  end;

  RST := GetSentRSTFromExchangeString(ExchangeString);

  if RST <> 0 then
    RData.RSTSent := RST;

  if RData.Callsign = '' then
    RData.Callsign := Call
  else
  begin
  end;
  logger.debug('[ParametersOkay] Setting RData.QTHString to zero');
  Windows.ZeroMemory(@RData.QTHString, SizeOf(RData.QTHString));

  if ParameterOkayMode = QSLAndLog then
  begin
    RData.Band := Band;
    RData.Mode := Mode;
    if RData.ExtMode = eNoMode then
    begin
      if ActiveRadioPtr^.nextExtendedMode = eNoMode then
      begin
        SetExtendedModeFromMode(RData);
      end;
    end;

    // Not the way to do this as the radio does not know the extendedMode--just Mode. NY4I
    //RData.ExtMode := ActiveRadioptr.CurrentStatus.ExtendedMode; // 4.93.3
    RData.NumberSent := NextSerialToSend;  // Issue #954: highest sent serial + 1, not a QSO count
    RData.Frequency := Freq;

    if ActiveMode in [Phone, FM] then
      DefaultRST := 59
    else
      DefaultRST := 599;

    if RData.RSTSent = 0 then
      if ActiveMode = Phone then
        RData.RSTSent := (LogRSSent)
      else
        RData.RSTSent := (LogRSTSent);

    // LocateCall(RData.Callsign, RData.QTH, True);

    if DoingDXMults then
      GetDXQTH(RData);

    if DoingPrefixMults then
      SetPrefix(RData);

    GetRidOfPrecedingSpaces(ExchangeString);
    GetRidOfPostcedingSpaces(ExchangeString);

    ParametersOkay := True;
    LogBadQSOString := ExchangeString;
    logger.debug('Calling ProcessExchange from ParametersOkay QSLAndLog');
    ProcessExchange(ExchangeString, RData); {wli}
    CalculateQSOPoints(RData);
    Exit;
  end;

  if not GoodCallSyntax(RData.Callsign) then
  begin
    Format(QuickDisplayBuffer, TC_HASIMPROPERSYNTAX, @RData.Callsign[1]);
    QuickDisplay(QuickDisplayBuffer);
    DoABeep(Warning);
    Exit;
  end;

  RData.Band := Band;
  RData.Mode := Mode;
  if RData.ExtMode = eNoMode then
    // if ExtMode was already set, no reason to look to the radio for it. WSJT-X sets it for example ny4i Issue 658
  begin
    if ActiveRadioPtr^.CurrentStatus.ExtendedMode = eNoMode then
      // This should have been set by radio object but what is nextExtendedMode
    begin
      SetExtendedModeFromMode(RData);
    end
    else
    begin
      Rdata.ExtMode := ActiveRadioPtr^.CurrentStatus.ExtendedMode;
    end;
  end;
  // ny4i Don't do this please - Issue 466 -=> Rdata.ExtMode := ActiveRadioptr^.CurrentStatus.ExtendedMode ; // 4.93.3
  RData.NumberSent := NextSerialToSend;  // Issue #954: highest sent serial + 1, not a QSO count
  RData.Frequency := Freq;

  if RData.RSTSent = 0 then
  begin
    Windows.ZeroMemory(@RData.RSTSent, SizeOf(RData.RSTSent));
    if ActiveMode in [Phone, FM] then
    begin
      RData.RSTSent := LogRSSent;
    end
    else
    begin
      RData.RSTSent := LogRSTSent;
    end;
  end;

  if ActiveMode in [Phone, FM] then
    DefaultRST := 59
  else
    DefaultRST := 599;

  // State-QP rover (KG1S/MON): use ctyLocateCallStripRover so the
  // country/zone lookup runs on the bare call (KG1S) instead of the
  // slashed form (which would be misinterpreted as a GB prefix
  // indicator).  RData.Callsign itself is preserved.
  ctyLocateCallStripRover(RData.Callsign, RData.QTH);

  if DoingDXMults then
    GetDXQTH(RData);

  if DoingPrefixMults then
    SetPrefix(RData);
  case ActivePrefixMult of
    BelgiumPrefixes: if RData.QTH.CountryID = 'ON' then
        RData.Prefix := RData.QTH.Prefix;
    SACDistricts: RData.Prefix := SACDistrict(RData.QTH);
    IndonesianDistricts:
      begin
        RData.Prefix := IndonesianDistrict(Rdata.QTH); // 4.64.1
        if (Contest = YBDX) and (IndonesianCountry(MyCountry)) then
          SetPrefix(RData);
      end;
    Prefix: RData.Prefix := RData.QTH.Prefix;
    SouthAmericanPrefixes: if RData.QTH.Continent = SouthAmerica then
        RData.Prefix := RData.QTH.Prefix;
    NonSouthAmericanPrefixes: if RData.QTH.Continent <> SouthAmerica then
        RData.Prefix := RData.QTH.Prefix;
  end;

  GetRidOfPrecedingSpaces(ExchangeString);
  GetRidOfPostcedingSpaces(ExchangeString);
  logger.debug('Calling ProcessExchange from ParametersOkay');
  ParametersOkay := ProcessExchange(ExchangeString, RData);

  if ExchangeErrorMessage <> nil then
  begin
    QuickDisplayError(ExchangeErrorMessage);
    PositionExchangeCursorAtErrorToken;   // Issue #1010: caret after the offending token
  end;

  if Result = False then
    Exit;

  if RData.RSTReceived = 0 then
    if ActiveMode in [Phone, FM] then
      RData.RSTReceived := LogRSSent
    else
      RData.RSTReceived := LogRSTSent;

  RData.ExchString := ExchangeString;
  CalculateQSOPoints(Rdata);
end;

procedure PossibleCallsProc(PCDRAWITEMSTRUCT: PDrawItemStruct);
label
  draw;
const
  nWidth = 2;
var
  TempColor: tcolor;
  Pen, PenOld: HPEN;
begin

  if (PCDRAWITEMSTRUCT^.itemAction = ODA_FOCUS) then
  begin
    DrawFocusRect(PCDRAWITEMSTRUCT^.HDC, PCDRAWITEMSTRUCT^.rcItem);
    Exit;
  end;

  if lobyte(PCDRAWITEMSTRUCT^.itemState) = ODS_SELECTED then
  begin
    Pen := CreatePen(PS_SOLID, nWidth, $FF0000 {RGB(255, 0, 0)});
    SetBkMode(PCDRAWITEMSTRUCT^.HDC, TRANSPARENT);
    PenOld := SelectObject(PCDRAWITEMSTRUCT^.HDC, Pen);

    Rectangle(PCDRAWITEMSTRUCT^.HDC,
      PCDRAWITEMSTRUCT^.rcItem.Left + 1,
      PCDRAWITEMSTRUCT^.rcItem.Top + 1,
      PCDRAWITEMSTRUCT^.rcItem.Right,
      PCDRAWITEMSTRUCT^.rcItem.Bottom);

    SelectObject(PCDRAWITEMSTRUCT^.HDC, PenOld);
    DeleteObject(Pen);

    PCDRAWITEMSTRUCT^.rcItem.Top := PCDRAWITEMSTRUCT^.rcItem.Top + nWidth;
    PCDRAWITEMSTRUCT^.rcItem.Left := PCDRAWITEMSTRUCT^.rcItem.Left + nWidth;
    PCDRAWITEMSTRUCT^.rcItem.Right := PCDRAWITEMSTRUCT^.rcItem.Right - nWidth;
    PCDRAWITEMSTRUCT^.rcItem.Bottom := PCDRAWITEMSTRUCT^.rcItem.Bottom - nWidth;
  end;

  if PossibleCallList.List[PCDRAWITEMSTRUCT^.ItemID].Dupe then
  begin
    TempColor := clred;
    Windows.SetTextColor(PCDRAWITEMSTRUCT^.HDC, $00FFFFFF);
    // InflateRect(PCDRAWITEMSTRUCT^.rcItem,-1,-1);
  end
  else
  begin
    TempColor := tr4wColorsArray[TWindows[mwePossibleCall].mweBackG];
    //clbtnface;
    Windows.SetTextColor(PCDRAWITEMSTRUCT^.HDC,
      tr4wColorsArray[TWindows[mwePossibleCall].mweColor] { $ 00000000});
  end;

  GradientRect(PCDRAWITEMSTRUCT^.HDC, PCDRAWITEMSTRUCT^.rcItem, TempColor,
    TempColor {tr4wColorsArray[TWindows[mwePossibleCall].mweBackG]},
    gdHorizontal);

  SetBkMode(PCDRAWITEMSTRUCT^.HDC, TRANSPARENT);
  Windows.DrawText(PCDRAWITEMSTRUCT^.HDC,
    @PossibleCallList.List[PCDRAWITEMSTRUCT^.ItemID].Call[1],
    length(PossibleCallList.List[PCDRAWITEMSTRUCT^.ItemID].Call),
    PCDRAWITEMSTRUCT^.rcItem, DT_END_ELLIPSIS + DT_SINGLELINE + DT_CENTER +
    DT_VCENTER);
end;

procedure CreateTotalWindow;
var
  r: integer;
  c, LabelWidth, Right, X: integer;
const
  w = 2.5;
begin

  for r := 0 to 3 do
    for c := 0 to 7 do
    begin

      if c = 0 then
      begin
        LabelWidth := ws * 5 {ws2 * 20};
        Right := 0;
      end
      else
      begin
        LabelWidth := round(ws * w) {ws2 * 10};
        if c = 7 then
          LabelWidth := round(ws * 3);
        Right := round(ws * 2.5); //ws2 * 10 + 2 - 2;
      end;

      TotWinHandles[c, r] :=
        CreateTR4WStaticWindow(
        Right + c * (round(ws * w)),
        ws * 2 + r * ws,
        LabelWidth,
        defStyle and (not (Cardinal(NoBorder) * SS_SUNKEN))
        );

    end;
  for c := 1 to 7 do
  begin
    X := Right + c * (round(ws * w) {+ 2});
    if c = 7 then
      TotWinheadHandles[7] :=
        tCreateStaticWindow(nil,
        (defStyle + SS_CENTERIMAGE) and (not (Cardinal(NoBorder) * SS_SUNKEN))
        , X, 0, round(ws * 3) {ws2 * 10}, ws * 2, tr4whandle, 0)
    else

      TotWinheadHandles[c] :=

      tCreateStaticWindow(

        nil,
        (defStyle + SS_CENTERIMAGE) and (not (Cardinal(NoBorder) * SS_SUNKEN)),
        X,
        0,
        round(ws * w) {ws2 * 10},
        ws * 2,
        tr4whandle,
        999 + c);
    // Issue #997: asm tWM_SETFONT (EAX = TotWinheadHandles[c]; both branches store it).
    tWM_SETFONT(TotWinheadHandles[c], MainFont);

  end;

  // TotalScoreWindowHandle := CreateTR4WStaticWindow(X, 0, MainWindowChildsWidth - RightTopWidth - X, defStyle);
  {
  DupeInfoCallWindowHandle :=

  tCreateStaticWindow(
  nil,
  defStyle,
  X,
  ws,
  MainWindowChildsWidth - RightTopWidth - X,
  StaticWindowHeight * 2,
  tr4whandle,
  0);
  tWM_SETFONT(DupeInfoCallWindowHandle, MainFont);
  }
{$IF tDebugMode}
  X := X + round(ws * 3) {ws2 * 10};
  CPUButtonHandle := tCreateButtonWindow(0, nil, BS_FLAT + WS_CHILD or BS_TEXT
    or
    BS_PUSHLIKE or WS_VISIBLE, X, ws * 4, MainWindowChildsWidth - RightTopWidth
    -
    X, ws * 2, tr4whandle, 0);
{$IFEND}

  // Windows.EnableWindow(TotWinheadHandles[7], False);
  // TotWinheadHandles[c] := CreateTR4WStaticWindow(310, 1, 35);
 // UpdateTotals2;

end;

procedure ChangeCaret(h: HWND);
begin
  if tr4w_CustomCaret = False then
    Exit;
  CreateCaret(h, CursorBitmap, ws - 4, MainWindowEditHeight);
  ShowCaret(h);
end;

procedure EditableLogWindowDblClick;
var
  Size: Cardinal;
begin

  IndexOfItemInLogForEdit := ListView_GetNextItem(wh[mweEditableLog], -1,
    LVNI_SELECTED);
  if IndexOfItemInLogForEdit = -1 then
    Exit;
  if not OpenLogFile then
    Exit;
  Size := Windows.GetFileSize(LogHandle, nil);
  CloseLogFile;

  if Size > LinesInEditableLog * SizeOf(ContestExchange) + SizeOf(TLogHeader)
    then
    IndexOfItemInLogForEdit := Size - LinesInEditableLog *
      SizeOf(ContestExchange) + IndexOfItemInLogForEdit * SizeOf(ContestExchange)
  else
    IndexOfItemInLogForEdit := IndexOfItemInLogForEdit * SizeOf(ContestExchange)
      + SizeOf(TLogHeader);

  ;

  // tDialogBox(46, @EditQSODlgProc);
  OpenEditQSOWindow(tr4whandle);
  FrmSetFocus;

end;

procedure tWinHelp(WindowHelpID: Byte);
begin
  // WinHelp(tr4whandle, TR4W_HLP_FILENAME, HELP_CONTEXT, Cardinal(WindowHelpID));
end;

function CreateProgress32InMainWindow(Left: integer; Top: integer; Color:
  integer): HWND;

begin
  Result := Createmsctls_progress32(Left, Top, 5 * ws, ws, tr4whandle, 0);
  SendMessage(Result, PBM_SETBARCOLOR, 0, Color);
  SendMessage(Result, PBM_SETBKCOLOR, 0, 16777215);
  SendMessage(Result, PBM_SETSTEP, 1, 0);
  SendMessage(Result, PBM_SETRANGE, 0, 0 or tr4w_MAX_RATE shl 16
    {MakeLParam(0, tr4w_MAX_RATE)});

end;

{
procedure DecrementTimeInDupesArray;
var
 i : cardinal;
 TemeLeft : byte;
begin
 for i := 0 to 1000 do
 begin
 if tDupesArray[i].tActive = False then Break;
 TemeLeft := tDupesArray[i].tMinutsLeft;
 if TemeLeft > 0 then
 begin
 Dec(TemeLeft);
 tDupesArray[i].tMinutsLeft := TemeLeft;
 end;

 end;

end;
}

procedure tClearDupeInfoCall;
begin
  Windows.ZeroMemory(@DupeInfoCall, SizeOf(DupeInfoCall));
end;

procedure tCleareCallWindow;
begin
  logger.debug('Clearing main call window');
  Windows.SetWindowText(wh[mweCall], nil);

end;

procedure tCleareExchangeWindow;
begin
  // Windows.SetWindowText(ExchangeWindowHandle, nil);
  // SetMainWindowText(mweExchange, nil);
  Windows.SetWindowText(wh[mweExchange], nil);
  
end;

procedure tSetExchWindInitExchangeEntry;
var
  ie: Str80;
begin
  Windows.ZeroMemory(@ie, SizeOf(ie));
  ie := InitialExchangeEntry(CallWindowString);
  SetMainWindowText(mweExchange, @ie[1]);
  if LeaveCursorInCallWindow then
    tCallWindowSetFocus;
end;

procedure HandleRepeatPOTAParks;
// Called from the "Repeat POTA Parks (2nd Op)" Commands menu item.
// Pre-fills the exchange with the parks from the last logged POTA contact so
// the operator only needs to type the new callsign and press Enter.
// The call window is left blank — the operator types the second op's call.
var
  ExchStr : string;
  ExchBuf : array[0..80] of Char;
begin
  ExchStr := GetLastPOTAExchange;
  if ExchStr = '' then
     begin
     QuickDisplay('No POTA parks logged yet this session');
     Exit;
     end;

  // Pre-fill exchange window; leave call window empty for the new callsign.
  Windows.ZeroMemory(@ExchBuf[0], SizeOf(ExchBuf));
  Move(ExchStr[1], ExchBuf[0], Length(ExchStr));
  ExchangeWindowString := ExchStr;
  Windows.SetWindowText(wh[mweExchange], ExchBuf);

  tCallWindowSetFocus;
  QuickDisplay(PChar('2nd op: type callsign, verify exchange, then Enter - ' + ExchStr));
end;

procedure tListBoxClientAlign(Parent: HWND);
var
  TR: TRect;
begin
  Windows.GetClientRect(Parent, TR);
  if Parent = tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle then
    TR.Bottom := TR.Bottom - 25;
  Windows.SetWindowPos(Windows.GetDlgItem(Parent, 101), HWND_TOP, 0, 0, TR.Right
    - TR.Left, TR.Bottom - TR.Top, SWP_SHOWWINDOW);
end;

function tCreateComboBoxWindow(dwStyle: DWORD; X, Y, nWidth,
  {nHeight: integer;}hwndParent: HWND; HMENU: HMENU): HWND;
begin
  // Result := CreateWindowEx(WS_EX_NOPARENTNOTIFY {WS_EX_STATICEDGE}, COMBOBOX, nil, dwStyle, X, Y, nWidth, 300 {nHeight}, hwndParent, HMENU, hInstance, nil);
  Result := CreateWindowEx(WS_EX_NOPARENTNOTIFY {WS_EX_STATICEDGE}, COMBOBOX,
    nil, dwStyle, X, Y, nWidth, 340 {nHeight}, hwndParent, HMENU, hInstance,
    nil);
  // 4.117.3
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function tCreateStaticWindow(lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;
//var
  //x1, y1, x2, y2, x3, y3: integer;
begin
  {x1 := 20;
  y1 := 20;
  x2 := 160;
  y2 := 200;
  x3 := 3;
  y3 := 3;
  }
  //Result := CreateRoundRectRgn(x1,y1,x2,y2,x3,y3);
  Result := CreateWindowEx(0 {WS_EX_DLGMODALFRAME}, StaticPChar, lpWindowName,
    dwStyle, X, Y, nWidth, nHeight, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function tCreateButtonWindow(dwxStyle: DWORD; lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(dwxStyle, ButtonPChar, lpWindowName, dwStyle, X, Y,
    nWidth, nHeight, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function tCreateEditWindow(dwxStyle: DWORD; lpWindowName: PChar;
  dwStyle: DWORD; X, Y, nWidth, nHeight: integer; hwndParent: HWND;
  HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(dwxStyle, EditPChar, lpWindowName, dwStyle, X, Y,
    nWidth, nHeight, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

procedure CreateOKCancelButtons(nWidthhwndParent: HWND);
var
  temprect: TRect;
  X, Y: integer;
const
  button_width = 80;
begin
  Windows.GetClientRect(nWidthhwndParent, temprect);
  X := (temprect.Right div 2) - (button_width + 5);
  Y := temprect.Bottom - temprect.Top - 27 {35};
  // ny4i changed this for the Cabrillo dialog as the buttons were too close to the last text field. The window may need to be a bit longer.
  CreateButton(0, OK_WORD, X, Y, button_width, nWidthhwndParent, 1);
  CreateButton(0, CANCEL_WORD, X + button_width + 10, Y, button_width,
    nWidthhwndParent, 2);
end;

procedure UpdateWindows;
begin
  UpdateTotals2;
  VisibleLog.ShowRemainingMultipliers;
  VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
  DisplayTotalScore {(TotalScore)};
  // DisplayInsertMode;
  DisplayNextQSONumber;
  SpotsList.UpdateSpotsMultiplierStatus;
  //UpdateBandMapMultiplierStatus;
  CallsignsList.DisplayDupeSheet(@Radio1 {ActiveBand, ActiveMode});
  CallsignsList.DisplayDupeSheet(@Radio2);
  DisplayQSOsByOpMode;
end;

procedure showint(Num: integer);
begin
  logger.Error(IntToStr(Num));
  //Format(wsprintfBuffer, '%i', Num);
  //ShowMessage(wsprintfBuffer);
end;

procedure ShowMessageParent(Text: PChar; Parent: HWND);
begin
  logger.Info('Sending to MessageBox: ' + Text);
  MessageBox(Parent, Text, tr4w_ClassName, MB_OK or MB_ICONINFORMATION
    {or MB_RTLREADING } or MB_TASKMODAL);
end;

procedure ShowMessage2(Text: PChar);
begin
  logger.Info('Sending to MessageBox: ' + Text);
  MessageBox(tr4whandle, Text, nil, MB_OK or MB_ICONINFORMATION
    {or MB_RTLREADING } or MB_TASKMODAL);
end;

procedure ShowMessage(Text: PChar);
//var MsgInfo : TMsgBoxParams;
begin
  logger.Info('Sending to MessageBox: ' + Text);
  MessageBox(tr4whandle, Text, tr4w_ClassName, MB_OK or MB_ICONINFORMATION
    {or MB_RTLREADING } or MB_TASKMODAL);

end;

procedure FilePreview;
begin
  // TryToLoadRICHED32DLL;
  // if RICHED32DLLHANDLE = 0 then RICHED32DLLHANDLE := Windows.LoadLibrary('RICHED32.DLL');
  RichEditOperation(True);
  //DialogBox(hInstance, MAKEINTRESOURCE(69), 0, @FullLogDlgProc);
  //tDialogBox(69, @FullLogDlgProc);
  CreateModalDialog(450, 300, tr4whandle, @FullLogDlgProc, 0);
  if CreateCabrilloWindow <> 0 then
    Windows.SetFocus(CreateCabrilloWindow);
end;

procedure tCallWindowSetFocus;
begin
  // if ActiveMainWindow <> awCallWindow then
  // if not tr4w_CallWindowActive then

  begin
    // ChangeFocus('call');
    Windows.SetFocus(wh[mweCall]);
    // Windows.SetWindowText(InsertWindowHandle, inttopchar(Windows.GetTickCount));

{$IF MORSERUNNER}
    // Windows.SendMessage(MorseRunner_Callsign, WM_SETFOCUS, 0, 0);
{$IFEND}
  end;
end;

procedure tExchangeWindowSetFocus;
var
  h: hWnd;
begin
  // if ActiveMainWindow <> awExchangeWindow then
  // if not tr4w_ExchangeWindowActive then
  // ChangeFocus('exchange');
  { ny4i Issue 131
  For some reason, SetFocus would return an Access Denied error when using CWBC.
  The error was documented in various postings and it was suggested that
  SetForegroundWindow should now be used. I changed this and it appears to work
  now for CWBC but this also needs to be checked in earlier versions of
  Windows. The MSDN docs state Windows 2000 is the first version so that should
  cover most. As this can get dicey with threads, this needs through testing with
  WinKey and K1EA keyer because of the threading used there.
  Note that I left the call to SetFocus first so the code works as it did.
  If that call fails, then I try SetForegroundWindow.
  }
  begin
    h := Windows.SetFocus(wh[mweExchange]);
    if h = 0 then
    begin
      if not Windows.SetForegroundWindow(wh[mweExchange]) then
      begin
        DebugMsg('SetForegroundWindow Failed');
      end;
    end;

{$IF MORSERUNNER}
    // Windows.SendMessage(MorseRunner_Number, WM_SETFOCUS, 0, 0);
{$IFEND}
  end;

end;

procedure tRuntPaddleAndFootSwitchThread;
begin
  if tPaddleFootSwitchThread <> INVALID_HANDLE_VALUE then
    Exit;
  tExitFromPaddleFootSwitchThread := False;
  logger.Info('Calling tCreateThread from tRuntPaddleAndFootSwitchThread');
  tPaddleFootSwitchThread := tCreateThread(@tPaddleFootSwitchThreadProc,
    tPaddleThreadID);
  logger.Info('Created PaddleAndFootSwitch thread with threadid of %d',
    [tPaddleThreadID]);
  // Issue #997: asm SetThreadPriority -> Pascal call. The old `push eax` pushed a
  // stale handle (clobbered by the preceding logger.Info), so this never applied;
  // now set it on the real handle. BEHAVIOR CHANGE: paddle/foot-switch thread now
  // actually runs LOWEST.
  SetThreadPriority(tPaddleFootSwitchThread, THREAD_PRIORITY_LOWEST);
end;
{
procedure TryToLoadRICHED32DLL;
begin
 if RICHED32DLLHANDLE = 0 then RICHED32DLLHANDLE := Windows.LoadLibrary('RICHED32.DLL');
end;
}

procedure InitializeQSO;
begin
  tAutoSendMode := False;
  ExchangeHasBeenSent := False;
  CallAlreadySent := False;
  tCleareCallWindow;
  tCleareExchangeWindow;
  tCallWindowSetFocus;
  ClearAltD; // 4.65.2
  tClearDupeInfoCall; // 4.65.2
  if OpMode = CQOpMode then
  begin
    OpMode2 := CQOpMode;
    ShowFMessages(0);
  end;
end;

function CreateCallOrExchangeWin(Top, ID: integer): HWND;
begin
  Result := CreateWindowEx(Cardinal(not NoBorder) * WS_EX_STATICEDGE, EditPChar,
    nil, CallsignExchangeWinStyle,
    ws * 15 {col4}, Top, 13 * ws, MainWindowEditHeight, tr4whandle, ID,
    hInstance, nil);
  // Issue #997: asm tWM_SETFONT (EAX = Result above).
  tWM_SETFONT(Result, MainWindowEditFont);
  SendMessage(Result, EM_LIMITTEXT, 12, 0);
end;

procedure TimeApplet(i: Cardinal);
begin
  Format(TempBuffer2,
    'rundll32.exe shell32.dll,Control_RunDLL timedate.cpl,,%u', i);
  WinExec(TempBuffer2, SW_SHOWNORMAL);
end;

procedure LoadinLog;
label
  1, 2, start;
var
  pNumberOfBytesRead: Cardinal;
  Size: Cardinal;
  CurrentRecord, FirstRecord: integer;
  TempMode: ModeType;

begin

  start:
{$IF tDebugMode}
  T1 := Windows.GetTickCount;
  // m :=0;
{$IFEND}
  LogHandle := CreateFile
    (
    TR4W_LOG_FILENAME,
    GENERIC_WRITE or GENERIC_READ,
    FILE_SHARE_WRITE or FILE_SHARE_READ,
    nil,
    OPEN_ALWAYS,
    FILE_FLAG_SEQUENTIAL_SCAN,
    0
    );
  if LogHandle = INVALID_HANDLE_VALUE then
    Exit;

  // PreviousBand := NoBand;
  CurrentRecord := 0;
  // LoadingInLogFile := True;
  tLogIndex := 0;
  ListView_DeleteAllItems(wh[mweEditableLog]);

  Size := Windows.GetFileSize(LogHandle, nil);

  if Size >= SizeOf(TLogHeader) then
  begin
    Windows.ReadFile(LogHandle, TempBuffer1, SizeOf(TLogHeader),
      pNumberOfBytesRead, nil);
    TempBuffer1[4] := #0; //temp
    if PInteger(@TempBuffer1)^ <> CURRENTVERSIONASINTEGER then
    begin
      // If the file is NEWER than this program we cannot safely open or convert
      // it. Show a clear error and stop — never attempt a downgrade conversion.
      if StrPas(TempBuffer1) > LOGVERSION then
         begin
         logger.Fatal('Log file version ' + StrPas(TempBuffer1) +
            ' is newer than this program (' + LOGVERSION + ').' +
            ' Upgrade TR4W to open this log.');
         ShowMessage(PChar(
            'This log file was created by a newer version of TR4W (' +
            StrPas(TempBuffer1) + ').' + #13#10 +
            'This program understands up to version ' + LOGVERSION + '.' + #13#10 +
            'Please upgrade TR4W to open this log.'));
         CloseLogFile;
         Halt;
         end;
 
      Format(wsprintfBuffer, TC_DIFVERSION, _LOGFILE, LogHeader.lhVersionString,
        TempBuffer1);
      showwarning(wsprintfBuffer);
      CloseLogFile;
      if not AskConvertLog(TempBuffer1) then
      begin
        logger.Fatal(wsprintfBuffer);
        halt;
      end
      else
      begin
        goto start;
      end;
    end
    else
    begin
      (* When adding something to ContestExchange, this causes an error since
      the size is wrong. From this code, it appears the the TRW file is
      simply a serialization of the ContestExchanges. So the size of the
      file should always be evenly divisible by the SizeOf(ContestExchange).
      NY4I 3 JUL 2020
      *)
      if (Size mod SizeOf(ContestExchange)) <> 0 {SizeOf(TLogHeader)} then
      begin
        showwarning(TC_ERRORINLOGFILE);
        CloseLogFile;
        logger.Fatal('Log file is not the correct size');
        halt; // 4.84.3
      end;

    end;
  end
  else
  begin
    // LogHeader.lhContest := Contest;
    sWriteFile(LogHandle, LogHeader, SizeOf(TLogHeader));
    goto 2;
  end;

  FirstRecord := (Size div SizeOf(ContestExchange)) - 1;
  if FirstRecord > LinesInEditableLog then
    FirstRecord := FirstRecord - LinesInEditableLog
  else
    FirstRecord := 0;
  Sheet.DisposeOfMemoryAndZeroTotals;
  // LoadingInLogFile := True;
  1:
  if ReadLogFile then
  begin
    if CurrentRecord >= FirstRecord then
      tAddContestExchangeToLog(TempRXData, wh[mweEditableLog], tLogIndex);

    if TempRXData.ceSendToServer = False then
      inc(tUSQ);
    if TempRXData.ceNeedSendToServerAE = True then
      inc(tUSQE);

    inc(tRestartInfo.riTotalRecordsInLog);
    // if tRestartInfo.riTotalRecordsInLog = 3057 then
    // tRestartInfo.riTotalRecordsInLog := 3057;
    // if tTotalRecordsInLog mod 1000 = 0 then DispalyLoadedQSOs(tTotalRecordsInLog);
    if TempRXData.ceRecordKind in [rkQTCR, rkQTCS] then
      IncrementQTCCount(TempRXData.Callsign);

    if TempRXData.ceRecordKind = rkQTCS then
      NumberQTCBooksSent := TempRXData.QSOPoints;

    if TempRXData.ceRecordKind = rkQSO then
      if (not TempRXData.ceQSO_Skiped) and (TempRXData.Band <> NoBand) and
        (TempRXData.Mode <> NoMode) then
      begin
        // Issue #954: feed the serial high-water mark.  This counts every
        // non-deleted QSO that consumed a number -- INCLUDING X-QSO -- which is
        // exactly why it lives OUTSIDE the #750 guard below: marking a QSO X-QSO
        // (or deleting a mid-log QSO) must not roll the sent serial backward.
        // Range/sentinel filtering is handled inside UpdateMaxSerialSent.
        if not TempRXData.ceQSO_Deleted then
          UpdateMaxSerialSent(TempRXData.Band, TempRXData.NumberSent);
        // Issue #750: X-QSO records are kept in the log (and the
        // editable log view -- they paint grayed) but contribute
        // nothing to QSOTotals, multipliers, points, or the dupe
        // sheet.  tUpdateLog(actRescore) has the same guard for the
        // same reason; this load-time path (LoadinLog) also needs
        // it so totals are correct after a fresh log open / load.
        if (TempRXData.ceQSO_Deleted = False) and
           (TempRXData.ceXQSO        = False) then
        begin
          TempMode := TempRXData.Mode;
          if TempMode = FM then
            TempMode := Phone;
          inc(QSOTotals[TempRXData.Band, TempMode]);
          inc(QSOTotals[TempRXData.Band, Both]);
          inc(QSOTotals[AllBands, TempMode]);

          if (SingleBand = TempRXData.Band) or (SingleBand = AllBands) then
            TotalQSOPoints := TotalQSOPoints + TempRXData.QSOPoints;

          if Contest = MOQSOPARTY then
             CheckMOQSOPartyBonusStation(TempRXData.Callsign);

          Sheet.AddQSOToSheets(@TempRXData, True);
          CallsignsList.AddCallsign(TempRXData.Callsign, TempMode,
            TempRXData.Band, TempRXData.ceClearDupeSheet);
          if not IntitialExLoaded then
            CallsignsList.AddIniitialExchange(TempRXData.Callsign,
              GetInitialExchangeStringFromContestExchange(TempRXData));

          if TempRXData.Band in [Band160..Band10] then // 4.115.3
          begin
            inc(ContinentQSOCount[TempRXData.Band, TempRXData.QTH.Continent]);
            inc(ContinentQSOCount[AllBands, TempRXData.QTH.Continent]);
            inc(TimeSpentByBand[TempRXData.Band]);
            // PreviousBand := TempRXData.Band;
          end;
          // Issue #750 follow-up: this increment was previously OUTSIDE
          // the X-QSO guard, so the score grid's "All" column counted
          // X-QSO records even though every per-band/per-mode counter
          // skipped them. Moved inside so the totals are consistent.
          inc(QSOTotals[AllBands, Both]);
        end;
      end;
    // else
    // asm nop end;

    inc(CurrentRecord);
    {                                              c
    if CurrentRecord = 1976 then
    asm
    nop
    end;
    }
    goto 1;
  end;
  2:
  // LoadingInLogFile := False;
  CloseLogFile;
  // DispalyLoadedQSOs(-1);
  IntitialExLoaded := True;
  Sheet.SetUpRemainingMultiplierArrays;
  UpdateWindows;
  Sheet.SaveRestartFile;

  if tRestartInfo.riTotalRecordsInLog > 0 then
    EnsureListViewColumnVisible(wh[mweEditableLog]);
  ReCalculateHourDisplay;
{$IF tDebugMode}
  QuickDisplay(inttopchar(Windows.GetTickCount - T1));
  // showint(m);
{$IFEND}
  if contest = RADIOYOC then // 4.53.2 // 4.72.9
  begin
    PrevNr := copy(IntToStr(TempRXData.NumberReceived), 1, 3); // 4.53.2
  end;
end;

function CreateEditableLog(Parent: HWND; X, Y, Width, Height: integer;
  DefaultSize: boolean): HWND;
var
  elvc: tagLVCOLUMNA;
  Column: LogColumnsType;
  Factor: integer;
  Style: Cardinal;
const
  style1 = WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_NOSORTHEADER or
    LVS_NOSCROLL or {LVS_NOCOLUMNHEADER or }LVS_SINGLESEL
  {or LVS_NOCOLUMNHEADER};
  style2 = WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_NOSORTHEADER or
    WS_TABSTOP;
begin
  if DefaultSize then
    Style := style2
  else
    Style := style1;
  Factor := ws;
  Result := CreateWindowEx(Cardinal(not NoBorder) * WS_EX_STATICEDGE,
    WC_LISTVIEW, nil, Style + integer(NoColumnHeader) * LVS_NOCOLUMNHEADER, X,
    Y,
    Width, Height, Parent, 0, hInstance, nil);
  // Issue #997: asm tWM_SETFONT (EAX = Result above).
  tWM_SETFONT(Result, MainFont);
  if DefaultSize then
  begin
    Factor := 17;
    tWM_SETFONT(Result, MainFixedFont);
  end;
  ListView_SetExtendedListViewStyle(Result, LVS_EX_FULLROWSELECT);
  // ListView_SetExtendedListViewStyle(Result, LVS_EX_TRACKSELECT );

  elvc.Mask := LVCF_TEXT or LVCF_WIDTH or LVCF_FMT;
  for Column := logColBand to High(LogColumnsType) {Pred(logColDummy)} do
    if ColumnsArray[Column].Enable then
    begin
      elvc.fmt := ColumnsArray[Column].Align;
      elvc.pszText := ColumnsArray[Column].Text;
      elvc.cx := ColumnsArray[Column].Width * Factor;
      ListView_InsertColumn(Result, ColumnsArray[Column].pos, elvc);
    end;

  Windows.SendMessage(Result, LVM_SETSELECTEDCOLUMN,
    ColumnsArray[logColCallsign].pos, 0);

  // ListView_SetColumnWidth(Result, integer(logColBand), ws * 4);

end;

procedure CreateListView(Parent: WindowsType; Window: TMainWindowElement; Style:
  integer);
begin
  wh[Window] :=
    CreateWindowEx
    (
    WS_EX_STATICEDGE,
    WC_LISTVIEW,
    nil,
    Style or WS_CHILD or WS_VISIBLE or LVS_REPORT or LVS_SINGLESEL or
    LVS_SHOWSELALWAYS or LVS_NOSORTHEADER or integer(NoColumnHeader) *
    LVS_NOCOLUMNHEADER,
    0,
    0,
    0,
    0,
    tr4w_WindowsArray[Parent].WndHandle,
    101,
    hInstance,
    nil
    );

  tWM_SETFONT(wh[Window], MainFixedFont);
  SetListViewColor(Window);

  ListView_SetExtendedListViewStyle(wh[Window], integer(tShowGridlines) *
    LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT);
end;

// Stash the X-QSO flag on a fully-populated editable-log row in the
// row's per-item lParam slot.  Used by the NM_CUSTOMDRAW handler in
// tr4w.dpr to gray out X-QSO rows without re-reading the binary log
// on every paint.  Called from tAddContestExchangeToLog after the
// row's text subitems are all set -- doing this as a separate
// LVM_SETITEM with LVIF_PARAM avoids the bug where putting LVIF_PARAM
// in the shared TLVItem mask causes every subsequent SetItem (one per
// subitem column) to also try to set lParam, which Windows rejects
// for subitems (lParam is per-item, not per-subitem).  Issue #750.
procedure SetRowXQSOFlag(ListViewHandle: HWND; rowIndex: Integer;
                         isXQSO: Boolean);
var
   lvi: TLVItem;
begin
   FillChar(lvi, SizeOf(lvi), 0);
   lvi.Mask     := LVIF_PARAM;
   lvi.iItem    := rowIndex;
   lvi.iSubItem := 0;
   if isXQSO then
      lvi.lParam := 1
   else
      lvi.lParam := 0;
   SendMessage(ListViewHandle, LVM_SETITEM, 0, LPARAM(@lvi));
end;

procedure tAddContestExchangeToLog(RXData: ContestExchange; ListViewHandle:
  HWND; var Index: integer);
label
  SetItem, Domestic; //n4af
var
  elvi: TLVItem;
  Mults: Cardinal;
  MultString: array[0..7] of Char;
begin

  elvi.Mask := LVIF_TEXT;
  elvi.iItem := Index;

  inc(Index);
  elvi.iSubItem := ColumnsArray[logColBand].pos; //Ord(logColBand);

  // Issue #750: stash the X-QSO flag in the row's per-item lParam so the
  // editable log's NM_CUSTOMDRAW handler (tr4w.dpr WM_NOTIFY) can gray
  // out the row without re-reading the binary log on every paint.  This
  // happens in SetRowXQSOFlag below, AFTER all the text subitems are
  // set: lParam is per-item, not per-subitem, and including LVIF_PARAM
  // in elvi.Mask here would cause every subsequent ListView_SetItem
  // (via the asm `call setitem` thunks below) to also try to set
  // lParam on a subitem, which Windows rejects -- only the first
  // column would render.  Issue #750 v0.1 hit exactly that bug.

  if RXData.ceRecordKind = rkNote then
  begin
    elvi.pszText := RC_NOTE;
    ListView_InsertItem(ListViewHandle, elvi);
    elvi.iSubItem := ColumnsArray[logColCallsign].pos; //(logColCallsign);
    elvi.pszText := @RXData.Prefix;
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if RXData.ceQSO_Skiped then
  begin
    elvi.pszText := nil;
    ListView_InsertItem(ListViewHandle, elvi);
    Exit;
  end;

  if RXData.ceQSO_Deleted then
  begin
    elvi.pszText := RC_DELETED;
    ListView_InsertItem(ListViewHandle, elvi);
    Exit;
  end;

  // if RXData.ceFMMode then TempMode := FM else TempMode := RXData.Mode;

  // P1 := BandStringsArray[RXData.Band];
  // P2 := ModeString[RXData.Mode];
  // Issue #997: removed empty asm (commented push p1/p2); Format below does it.
  Format(LogDisplayBuffer, TWO_STRINGS, BandStringsArray[RXData.Band],
    ModeStringArray[RXData.Mode]);

  elvi.pszText := LogDisplayBuffer;
  ListView_InsertItem(ListViewHandle, elvi);

  {
  aYear := (RXData.tSysTime.qtYear + 2000) mod 100;
  aMonthString := MonthTags[RXData.tSysTime.qtMonth];
  asm
  push aYear
  push aMonthString
  movzx eax, RXData.tSysTime.qtDay
  push eax
  end;
  wsprintf(LogDisplayBuffer, '%02d-%s-%02d');
  asm add esp,20
  end;
  }
  elvi.iSubItem := ColumnsArray[logColDate].pos;
  // elvi.pszText := LogDisplayBuffer;
  elvi.pszText := tGetDateFormat(RXData.tSysTime);
  ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  Format(LogDisplayBuffer, '%02d:%02d', RXData.tSysTime.qtHour,
    RXData.tSysTime.qtMinute);
  elvi.iSubItem := ColumnsArray[logColTime].pos; //Ord(logColTime);
  elvi.pszText := LogDisplayBuffer;
  ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  CID_TWO_BYTES[0] := RXData.ceComputerID;
  elvi.iSubItem := ColumnsArray[logColComputerID].pos; //Ord(logColComputerID);
  elvi.pszText := @CID_TWO_BYTES;
  ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  if RXData.ceRecordKind = rkNote then
    Exit;
  if RXData.NumberSent <> -1 then
  begin
    elvi.iSubItem := ColumnsArray[logColNumberSent].pos; //Ord(logColNumberSent);
    elvi.pszText := inttopchar(RXData.NumberSent {+10020});
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  elvi.iSubItem := ColumnsArray[logColCallsign].pos; //Ord(logColCallsign);

  if RXData.ceRecordKind in [rkQTCR, rkQTCS] then
  begin
    Format(LogDisplayBuffer, 'QTC: %s', @RXData.Callsign[1]);
    elvi.pszText := LogDisplayBuffer;
  end
  else
    elvi.pszText := @RXData.Callsign[1]; //@RXData.Callsign[1];
  ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  if ColumnsArray[logColNumberReceive].Enable then
    if RXData.NumberReceived <> -1 then
    begin
      elvi.iSubItem := ColumnsArray[logColNumberReceive].pos;
      //Ord(logColNumberReceive);
      elvi.pszText := inttopchar(RXData.NumberReceived);
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;

  if RXData.ceRecordKind in [rkQTCR, rkQTCS] then
  begin
    elvi.iSubItem := ColumnsArray[logColQTC].pos; //Ord(logColQTC);
    Format(LogDisplayBuffer, '%04d %s', RXData.NumberSent, @RXData.Kids[1]);
    elvi.pszText := LogDisplayBuffer;
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

    elvi.iSubItem := ColumnsArray[logColNumberSent].pos; //Ord(logColNumberSent);
    elvi.pszText := @RXData.RandomCharsReceived[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    Exit;
  end;

  if ColumnsArray[logColClass].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColClass].pos; //Ord(logColDXMult);
    elvi.pszText := @RXData.ceClass[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if ColumnsArray[logColDXMult].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColDXMult].pos; //Ord(logColDXMult);
    elvi.pszText := @RXData.DXQTH[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if ColumnsArray[logColZoneMult].Enable then
  begin
    if RXData.Zone <> DUMMYZONE then
    begin
      elvi.iSubItem := ColumnsArray[logColZoneMult].pos; //Ord(logColZoneMult);
      elvi.pszText := inttopchar(RXData.Zone);
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end;

  if ((ColumnsArray[logColPower].Enable) and (Contest <> FOCMARATHON)) then
    //n4af 4.32.5
  begin
    if RXData.Power <> '' then
    begin
      elvi.iSubItem := ColumnsArray[logColPower].pos;
      elvi.pszText := @RXData.Power[1];
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end
  else if (ColumnsArray[logColFOC].Enable) then
  begin
    elvi.iSubItem := ColumnsArray[logColFOC].pos;
    elvi.pszText := @RXData.Power[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  end;

  if ColumnsArray[logColPrefixMult].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColPrefixMult].pos; //Ord(logColPrefixMult);
    elvi.pszText := @RXData.Prefix[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  Mults := 0;
  if RXData.DXMult then
    if RXdata.DomesticMult then
      goto Domestic //n4af
    else
    begin
      MultString[Mults] := 'x';
      inc(Mults);
    end;
  Domestic:

  if RXData.DomesticMult then
  begin
    MultString[Mults] := 'd';
    inc(Mults);
  end;

  if RXData.ZoneMult then
  begin
    MultString[Mults] := 'z';
    inc(Mults);
  end;

  if RXData.PrefixMult then
  begin
    MultString[Mults] := 'p';
    inc(Mults);
  end;

  // Mults := Ord(RXData.DXMult) + Ord(RXData.DomesticMult) + Ord(RXData.ZoneMult) + Ord(RXData.PrefixMult);

  if Mults <> 0 then
  begin
    MultString[Mults] := #0;
    elvi.iSubItem := ColumnsArray[logColTotalMults].pos; //Ord(logColTotalMults);
    elvi.pszText := MultString; //inttopchar(Mults);
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if ColumnsArray[logColPrecedence].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColPrecedence].pos; //rd(logColPrecedence);
    CID_TWO_BYTES[0] := RXData.Precedence;
    elvi.pszText := CID_TWO_BYTES;
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if ColumnsArray[logColCheck].Enable then
  begin
    // if RXData.Check <> 0 then //n4af 4.34.7
    begin
      elvi.iSubItem := ColumnsArray[logColCheck].pos; //Ord(logColCheck);
      elvi.pszText := inttopchar(RXData.Check);
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end;

  if ColumnsArray[logColChapter].Enable then
  begin
    if RXData.Chapter <> '' then
    begin
      elvi.iSubItem := ColumnsArray[logColChapter].pos; //Ord(logColCheck);
      elvi.pszText := @RXData.Chapter[1];
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end;

  if ColumnsArray[logColQTH].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColQTH].pos; //Ord(logColQTH);
    if DoingDomesticMults then
    begin
      if LiteralDomesticQTH then
        elvi.pszText := @RXData.QTHString[1]
      else
        elvi.pszText := @RXData.DomesticQTH {DomMultQTH} [1];
    end
    else
      elvi.pszText := @RXData.QTHString[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  elvi.iSubItem := ColumnsArray[logColPoints].pos; //Ord(logColPoints);
  elvi.pszText := inttopchar(RXData.QSOPoints);
  ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem

  if ColumnsArray[logColAge].Enable then
  begin
    // if RXData.Age <> 0 then // 4.99.3
    begin
      elvi.iSubItem := ColumnsArray[logColAge].pos; //Ord(logColAge);
      elvi.pszText := inttopchar(RXData.Age);
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end;

  if ColumnsArray[logColKids].Enable then
  begin
    elvi.iSubItem := ColumnsArray[logColKids].pos; //Ord(logColAge);
    elvi.pszText := @RXData.Kids[1];
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if ColumnsArray[logColName].Enable then
  begin
    if RXData.Name <> '' then
    begin
      elvi.iSubItem := ColumnsArray[logColName].pos; //Ord(logColName);
      elvi.pszText := @RXData.Name[1];
      ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
    end;
  end;
  if RXData.ceSearchAndPounce then
    // if RXData.tSearchAndPounce then
  begin
    elvi.iSubItem := ColumnsArray[logColSearchAndPounce].pos;
    //Ord(logColSearchAndPounce);
    elvi.pszText := '$';
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if RXData.ceDupe then
  begin
    elvi.iSubItem := ColumnsArray[logColDupe].pos; //Ord(logColDupe);
    elvi.pszText := 'D';
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if RXData.Frequency <> 0 then
  begin
    elvi.iSubItem := ColumnsArray[logColFreq].pos; //Ord(logColFreq);
    elvi.pszText := FreqToPChar {FreqToPCharWithoutHZ}(RXData.Frequency);
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  if RXData.ceOperator[0] <> #0 then
  begin
    elvi.iSubItem := ColumnsArray[logColOperator].pos;
    elvi.pszText := RXData.ceOperator;
    ListView_SetItem(ListViewHandle, elvi);   // Issue #997: was asm call setitem
  end;

  // Issue #750: stash the X-QSO flag on the just-built row so the
  // NM_CUSTOMDRAW handler (tr4w.dpr WM_NOTIFY) can gray out X-QSO
  // rows without re-reading the binary log.  Uses elvi.iItem because
  // the var-parameter Index has already been inc'd (the row we just
  // populated is at elvi.iItem, which equals Index - 1 by now).
  SetRowXQSOFlag(ListViewHandle, elvi.iItem, RXData.ceXQSO);

  Exit;

  // Issue #997: setitem label-subroutine removed; call sites inline ListView_SetItem.
end;

procedure LogEnsureVisible;
begin

  if ActiveMainWindow <> awEditableLog then
    ListView_EnsureVisible(wh[mweEditableLog], tLogIndex - 1, True);
end;

procedure GenerateCallsignsList(FileName: PChar);
var
  h: HWND;
  i: integer;
  nNumberOfBytesToWrite: Cardinal;
  InitialExchange: CallString;
  Callsign: CallString;
begin
  // MakeReportFileName('CUSTOM_INITIAL.EX');
  if not tOpenFileForWrite(h, FileName {@ReportsFilename[1]}) then
    Exit;
  sWriteFile(h, ';callsign exchange'#13#10#13#10, 29);
  for i := 0 to CallsignsList.Count - 1 do
  begin
    Windows.ZeroMemory(@InitialExchange, SizeOf(InitialExchange));
    InitialExchange := CallsignsList.GetIniitialExchangeByIndex(i);
    if InitialExchange <> '' then

    begin
      Windows.ZeroMemory(@Callsign, SizeOf(Callsign));
      Callsign := CallsignsList.Get(i);
      // if tPos(Callsign, '/') = 0 then
      begin
        //if StringHas(InitialExchange, '255 ') then
        // InitialExchange := GetLastString(initialexchange); // 4.90.6
        nNumberOfBytesToWrite := Format(wsprintfBuffer, '%-15s %s'#13#10,
          @Callsign[1], @InitialExchange[1]);
        sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
      end;

    end;
  end;
  CloseHandle(h);
end;

procedure MakeAllCallsignsList;
var
  h: HWND;
  i: integer;
  counter: integer;
  QSOs: integer;
  WriteHeader: boolean;
  TempCall: CallString;
begin
  MakeReportFileName('ALLCALLSIGNS.TXT');
  if not tOpenFileForWrite(h, @ReportsFilename[1]) then
    Exit;

  sWriteFile(h, wsprintfBuffer, Format(wsprintfBuffer,
    #13#10' %s'#13#10#13#10' Unique callsigns: %u '#13#10, @ContestTitle[1],
    CallsignsList.GetTotalWorkedStations));

  for QSOs := 20 downto 1 do
  begin
    WriteHeader := True;
    counter := 0;
    for i := 0 to CallsignsList.Count - 1 do
    begin
      if CallsignsList.GetQSOs(i) = QSOs then
      begin
        inc(counter);
        if WriteHeader then
        begin

          sWriteFile(h, wsprintfBuffer, Format(wsprintfBuffer,
            #13#10#13#10' %u QSOs:'#13#10' -----------------'#13#10#13#10,
            QSOs));
        end;
        ZeroMemory(@TempCall, SizeOf(TempCall));
        TempCall := CallsignsList.Get(i);
        sWriteFile(h, wsprintfBuffer, Format(wsprintfBuffer,
          ' %4u. %s '#13#10, counter, @TempCall[1]));
        WriteHeader := False;
      end;
    end;
  end;

  CloseHandle(h);
  FilePreview;
end;

procedure tAltE;
label
  1;
begin
  if tPreviousDupeQSOsShowed then
    Exit;
  Act_Freq := ActiveRadioPtr.filteredstatus.freq;
  Act_Band := ActiveBand;
  if InactiveRadioptr.LastDisplayedFreq = 0 then
    goto 1;
  inAct_Band := InActiveRadioPtr.BandMemory;

  InAct_Freq := InactiveRadioptr.LastDisplayedFreq;
  so2r_swap := true;
  1:
  Windows.SetFocus(wh[mweEditableLog]);
  ListView_SetItemState(wh[mweEditableLog], tLogIndex - 1, LVIS_FOCUSED or
    LVIS_SELECTED, LVIS_FOCUSED or LVIS_SELECTED);
  //   processreturn;
        // LogEnsureVisible;
end;

procedure SetWindowSize;
//const
// ewh : array[1 + 12..15 + 12] of REAL = (12.6, 13.7, 13.7, 15.7, 16.8, 18, 18, 20, 20.6, 20.6, 22.8, 23.8, 23.8, 25.8, 25.75);
begin

  ws := WindowSize + 12;

  ws2 := ws div 4;
  // EditableLogWindowHeight := //Trunc((LinesInEditableLog + 1) * ewh[ws]) + 1;
  // (LinesInEditableLog + 1) * ws + ws2 + 12;

  MainWindowCaptionAndHeader := Windows.GetSystemMetrics(SM_CYMENU) +
    Windows.GetSystemMetrics(SM_CYCAPTION);

  //MainWindowHeight := EditableLogWindowHeight + 14 * ws + 7 + MainWindowCaptionAndHeader;

  RightTopWidth := 14 * ws;

  //line1 := ws * 7 + EditableLogWindowHeight + 0;
  //Line2 := line1 + ws;
  //Line3 := line1 + ws * 2;
  //Line4 := line1 + ws * 3 {+ 12};
  //Line5 := line1 + ws * 4;
  //line6 := line1 + ws * 5;
  //Line7 := line1 + ws * 6;
  //line8 := line1 + ws * 7;

  //col2 := 4 * ws;
  //col3 := 8 * ws;
  //col4 := 15 * ws;

  //col5 := col4 + 10 * ws;
  //col6 := col5 + 3 * ws;
  //col7 := col6 + 3 * ws;
  //col8 := col7 + 2 * ws;
  //col9 := col8 + 5 * ws;
  //col10 := col9 + 4 * ws;
  //col11 := col10 + 2 * ws {50};

  MainWindowChildsWidth := 46 * ws; //col11 + ws * 2; //MainWindowWidth - 8+8;
  MainWindowWidth := MainWindowChildsWidth + 7;

  MainWindowEditHeight := ((ws * 3) div 2) - 1 {ws + 4};
  FKButtonWidth := ws * 4 - 3;
end;

procedure tUpdateLog(UpdAction: UpadateAction);
label
  1, 2, 3, 4;
var
  MapFin: Cardinal;
  MapBase: Pointer;
  RescoredRXData: ContestExchangePtr;
  LogSize: Cardinal;
  QSOCounter: Cardinal;
  // Snapshot of fields that actRescore can mutate, captured before the
  // rescore work so we can log a single line per record describing the
  // before/after when anything actually changed.  Useful for catching
  // silent rescore-induced corruption (e.g. rover-call /M -> DX=G).
  beforeCountryID : DXMultiplierString;
  beforePrefix    : PrefixMultiplierString;
  beforeDXQTH     : DXMultiplierString;
  beforeDomMult   : Boolean;
  beforeDXMult    : Boolean;
  beforePrefixMult: Boolean;
  beforeZoneMult  : Boolean;
  beforeQSOPoints : Word;
  beforeDupe      : Boolean;
begin

  if not OpenLogFile then
    Exit;
  LogSize := Windows.GetFileSize(LogHandle, nil);
  if UpdAction <> actGetCRC32 then
  begin
    if LogSize <= SizeOf(TLogHeader) then
      goto 2;
    LogSize := ((LogSize - SizeOf(TLogHeader)) div SizeOfContestExchange);
  end;
  QSOCounter := 0;
  MapFin := Windows.CreateFileMapping(LogHandle, nil, PAGE_READWRITE, 0, 0,
    nil);
  if MapFin = 0 then
    goto 2;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_ALL_ACCESS, 0, 0, 0);
  if MapBase = nil then
    goto 3;
  // Issue #997: asm pointer-arith that assumed EAX still held MapViewOfFile's
  // return -> explicit (same pattern as the advance-by-record near the end of
  // this function).
  RescoredRXData := Pointer(Cardinal(MapBase) + SizeOfTLogHeader);

  if UpdAction = actGetCRC32 then
  begin
    tCRC32 := GetCRC32(MapBase^, LogSize);
    goto 4;
  end;

  if UpdAction = actRescore then
  begin
    // LoadingInLogFile := True;
    Sheet.DisposeOfMemoryAndZeroTotals;
  end;
  1:

  if RescoredRXData^.ceRecordKind = rkQSO then
  begin
    if UpdAction = actSetClearDupesheetBit then
      RescoredRXData^.ceClearDupeSheet := True;

    if UpdAction = actResetClearDupesheetBit then
      RescoredRXData^.ceClearDupeSheet := False;

    if UpdAction = actRescore then
      // Issue #750: X-QSO records stay in the log (for NIL protection
      // of the worked station) but are deliberately excluded from
      // every scoring artifact -- the rescore rebuilds the dupe
      // sheet, mult sheet, and totals from this loop, so skipping
      // X-QSO from the main scoring path makes them invisible to
      // dupe checking, mults, and totals.  We ALSO zero out the
      // record's own QSOPoints and ceDupe fields so the editable log
      // displays a consistent "0" in the Pts column for every
      // X-QSO record (matches DXLog.net's convention -- N1MM keeps
      // the historical points, but a consistent visual signal is
      // more useful at a glance).  The contact still exports to
      // ADIF and Cabrillo (with the `X-QSO:` prefix instead of `QSO:`).
      if RescoredRXData^.ceQSO_Deleted = False then
        if RescoredRXData^.ceQSO_Skiped = False then
        if RescoredRXData^.ceXQSO then
          begin
          RescoredRXData^.QSOPoints := 0;
          RescoredRXData^.ceDupe    := False;
          end
        else
        begin
          // Snapshot before rescore so we can report what (if anything) changed.
          beforeCountryID  := RescoredRXData^.QTH.CountryID;
          beforePrefix     := RescoredRXData^.Prefix;
          beforeDXQTH      := RescoredRXData^.DXQTH;
          beforeDomMult    := RescoredRXData^.DomesticMult;
          beforeDXMult     := RescoredRXData^.DXMult;
          beforePrefixMult := RescoredRXData^.PrefixMult;
          beforeZoneMult   := RescoredRXData^.ZoneMult;
          beforeQSOPoints  := RescoredRXData^.QSOPoints;
          beforeDupe       := RescoredRXData^.ceDupe;

          if DoingPrefixMults then
          begin
            Windows.ZeroMemory(@RescoredRXData.QTH, SizeOf(RescoredRXData.QTH));
            Windows.ZeroMemory(@RescoredRXData.DXQTH,
              SizeOf(RescoredRXData.DXQTH));
            // State-QP rover (KG1S/MON): strip suffix for country lookup so
            // /M doesn't get misread as a GB prefix.  Without this the
            // rescore wipes the correct USA lookup done at log-time and
            // restamps the record as DX=G.
            ctyLocateCallStripRover(RescoredRXData^.Callsign, RescoredRXData.QTH);
            SetPrefix(RescoredRXData^);
          end;
          // if (RXData.Prefix <> '') and DoingPrefixMults then
          {
          if RescoredRXData^.Callsign = 'RP7X' then
          asm
          nop
          end;
          }

          if DoingZoneMults or DoingDXMults then
          begin
            Windows.ZeroMemory(@RescoredRXData.QTH, SizeOf(RescoredRXData.QTH));
            Windows.ZeroMemory(@RescoredRXData.DXQTH,
              SizeOf(RescoredRXData.DXQTH));
            // State-QP rover (KG1S/MON): strip suffix for country lookup so
            // /M doesn't get misread as a GB prefix.  Without this the
            // rescore wipes the correct USA lookup done at log-time and
            // restamps the record as DX=G.
            ctyLocateCallStripRover(RescoredRXData^.Callsign, RescoredRXData.QTH);
            GetDXQTH(RescoredRXData^);
            //.DXQTH := RescoredRXData.QTH.CountryID;
          end;

          {rk4wwq}
          // RescoredRXData.ceContest := Contest;
          {
          if RescoredRXData.Zone = 255 then
          begin
          if (RescoredRXData.NumberReceived > 999) and (RescoredRXData.NumberReceived < 9999) then
          begin
          asm nop end;
          RescoredRXData.Zone := RescoredRXData.NumberReceived div 1000;
          RescoredRXData.NumberReceived := RescoredRXData.NumberReceived mod 1000;
          end;
          end;
          }
          {rk4wwq}

          if RescoredRXData^.id = '' then
             RescoredRXData^.id := GetGUID;

          Sheet.SetMultFlags(RescoredRXData^);
          CalculateQSOPoints(RescoredRXData^);
          if (not tAllowDupeQSOs) and (RescoredRXData^.ceClearDupeSheet = False)
            and (VisibleLog.CallIsADupe(RescoredRXData^.Callsign,
            RescoredRXData^.Band, RescoredRXData^.Mode)) then
          begin
            RescoredRXData^.QSOPoints := 0;
            RescoredRXData^.ceDupe := True;
          end
          else
            RescoredRXData^.ceDupe := False;

          // Report whenever actRescore actually mutated a record.  One line
          // per changed record makes silent rescore-induced corruption
          // (rover-call DX=G, mult-flag flip, points change, etc.) visible.
          if (beforeCountryID  <> RescoredRXData^.QTH.CountryID) or
             (beforePrefix     <> RescoredRXData^.Prefix)        or
             (beforeDXQTH      <> RescoredRXData^.DXQTH)         or
             (beforeDomMult    <> RescoredRXData^.DomesticMult)  or
             (beforeDXMult     <> RescoredRXData^.DXMult)        or
             (beforePrefixMult <> RescoredRXData^.PrefixMult)    or
             (beforeZoneMult   <> RescoredRXData^.ZoneMult)      or
             (beforeQSOPoints  <> RescoredRXData^.QSOPoints)     or
             (beforeDupe       <> RescoredRXData^.ceDupe) then
             begin
             logger.Info('[actRescore] %s [%d] changed: ' +
                'CountryID [%s]->[%s] Prefix [%s]->[%s] DXQTH [%s]->[%s] ' +
                'DomMult %s->%s DXMult %s->%s PrefixMult %s->%s ZoneMult %s->%s ' +
                'QSOPoints %d->%d Dupe %s->%s',
                [string(RescoredRXData^.Callsign), QSOCounter,
                 string(beforeCountryID),  string(RescoredRXData^.QTH.CountryID),
                 string(beforePrefix),     string(RescoredRXData^.Prefix),
                 string(beforeDXQTH),      string(RescoredRXData^.DXQTH),
                 BoolToStr(beforeDomMult,    True), BoolToStr(RescoredRXData^.DomesticMult, True),
                 BoolToStr(beforeDXMult,     True), BoolToStr(RescoredRXData^.DXMult,       True),
                 BoolToStr(beforePrefixMult, True), BoolToStr(RescoredRXData^.PrefixMult,   True),
                 BoolToStr(beforeZoneMult,   True), BoolToStr(RescoredRXData^.ZoneMult,     True),
                 beforeQSOPoints, RescoredRXData^.QSOPoints,
                 BoolToStr(beforeDupe, True), BoolToStr(RescoredRXData^.ceDupe, True)]);
             end;

          Sheet.AddQSOToSheets(@RescoredRXData^, False);
          CallsignsList.AddCallsign(RescoredRXData^.Callsign,
            RescoredRXData^.Mode, RescoredRXData^.Band,
            RescoredRXData^.ceClearDupeSheet);
        end;

    if UpdAction = actClearMults then
    begin
      RescoredRXData^.ceClearMultSheet := True;
      RescoredRXData^.DomesticMult := False;
      RescoredRXData^.DXMult := False;
      RescoredRXData^.PrefixMult := False;
      RescoredRXData^.ZoneMult := False;
    end;
  end;
  inc(QSOCounter);
  if QSOCounter <> LogSize then
  begin
    // Issue #997: asm pointer arith -> Pascal (advance to the next log record).
    RescoredRXData := Pointer(Cardinal(RescoredRXData) + SizeOfContestExchange);
    goto 1;
  end;
  4:
  FlushViewOfFile(MapBase, 0);
  Windows.UnmapViewOfFile(MapBase);
  3:
  CloseHandle(MapFin);
  2:
  CloseLogFile;

  if UpdAction = actRescore then
  begin
    Sheet.SetUpRemainingMultiplierArrays;
    Sheet.SaveRestartFile;
    // LoadingInLogFile := False;
  end;
end;

procedure WINDOWPOSCHANGINGPROC(var p: PWindowPos);
const
  f = 20;
begin
  if (p.X < f) and (p.X > -f) then
    p.X := 0;
  if (p.Y < f) and (p.Y > -f) then
    p.Y := 0;
  if Abs(tWorkingAreaRect.Bottom - (p.cy + p.Y)) < f then
    p.Y := tWorkingAreaRect.Bottom - p.cy;
  if Abs(tWorkingAreaRect.Right - (p.cx + p.X)) < f then
    p.X := tWorkingAreaRect.Right - p.cx;
end;

function tSetFilePointer(lDistanceToMove: LONGINT; dwMoveMethod: DWORD):
  Cardinal;
begin
  result := Low(cardinal);
  // Initialize as it was not previously // ny4i Isssue 116
  SetFilePointer(LogHandle, lDistanceToMove, nil, dwMoveMethod);
end;

function OpenLogFile {(dwCreationDisposition: DWORD)}: boolean;
var
  h: HWND;
begin
  h := CreateFile(
    TR4W_LOG_FILENAME,
    GENERIC_WRITE or GENERIC_READ,
    FILE_SHARE_WRITE or FILE_SHARE_READ,
    nil,
    OPEN_EXISTING,
    FILE_FLAG_SEQUENTIAL_SCAN,
    0
    );
  Result := h <> INVALID_HANDLE_VALUE;
  if Result = True then
    LogHandle := h;
end;

procedure CloseLogFile;
begin
  CloseHandle(LogHandle);
end;

function ReadLogFile: boolean;
var
  lpNumberOfBytesWritten: Cardinal;
begin
  Windows.ReadFile(LogHandle, TempRXData, SizeOf(ContestExchange),
    lpNumberOfBytesWritten, nil);
  Result := lpNumberOfBytesWritten = SizeOf(ContestExchange);
end;

procedure ShowPreviousDupeQSOsWnd(show: boolean);
const
  ewha: array[boolean] of PLongword = (@tPreviousDupeQSOsWndHandle,
    @wh[mweEditableLog]);
begin
  tPreviousDupeQSOsShowed := show;
  Windows.SetWindowPos(ewha[show]^, HWND_TOP, 0, 0, 0, 0, SWP_NOMOVE);
  Windows.SetWindowPos(ewha[not show]^, HWND_TOP, 0, 0, MainWindowChildsWidth,
    EditableLogHeight, SWP_NOMOVE);
  // Windows.SetWindowPos(ewha[show], HWND_TOP, 0, 0, ws * 46, 6 + MainWindowCaptionAndHeader + OffsetY + ws * 14, SWP_NOMOVE);
  // Windows.ShowWindow(tPreviousDupeQSOsWndHandle, integer(show));
  // CreateThread(nil, 0, @FlashPreviousDupeQSOsWnd, Pointer(show), 0, lpThreadId);
  // Windows.AnimateWindow(tPreviousDupeQSOsWndHandle, 100, AW_HIDE * (integer(show) + 1) or AW_VER_POSITIVE * (integer(show) + 1));
end;

procedure FlashPreviousDupeQSOsWnd(show: boolean);
begin
  Windows.AnimateWindow(tPreviousDupeQSOsWndHandle, 300, AW_HIDE * (integer(show)
    + 1) or AW_HOR_POSITIVE);
end;

procedure DestroyPreviousDupeQSOsWnd;
begin
  // DestroyWindow(tPreviousDupeQSOsWndHandle);
  // Windows.ShowWindow(tPreviousDupeQSOsWndHandle, SW_HIDE);
  Windows.AnimateWindow(tPreviousDupeQSOsWndHandle, 300, AW_HIDE or
    AW_HOR_POSITIVE);
  tPreviousDupeQSOsShowed := False;
  Windows.EnableWindow(wh[mweEditableLog], True);
end;

procedure TryPutSpaceinExchangeWindow;
var
  Selection: TSelection;
begin
  SendMessage(wh[mweExchange], EM_GETSEL, LONGINT(@Selection.StartPos),
    LONGINT(@Selection.EndPos));

  if Selection.StartPos = Selection.EndPos then
    if Selection.StartPos = length(ExchangeWindowString) then
      if (Selection.StartPos = 0) or
        (ExchangeWindowString[length(ExchangeWindowString)] <> ' ') then
        PostMessage(wh[mweExchange], WM_KEYDOWN, 32, 0);

end;

procedure ShowInformation;
var
  // TempMode : ModeType;
  // TempBand : BandType;
  Index: integer;
  QSOs: integer;
begin

  DisplayCountryName(CallWindowString);

  DisplayBeamHeading(CallWindowString, '');

  tCallWindowStringIsDupe := VisibleLog.CallIsADupe(CallWindowString,
    ActiveBand, ActiveMode);
  DispalayB4(integer(tCallWindowStringIsDupe));

  if not CallsignsList.FindCallsign(CallWindowString, Index) then
    Exit;
  QSOs := CallsignsList.GetQSOs(Index);
  DisplayQSOsWithThisStation(QSOs);
end;

procedure QuickQSLProcedure(Key: Char);
begin
  if CallWindowString = '' then
    Exit;

  // if (Key = QuickQSLKey1) or (Key = QuickQSLKey2) then
  begin
    if ParametersOkay(CallWindowString, ExchangeWindowString, ActiveBand,
      ActiveMode, ActiveRadioPtr.LastDisplayedFreq, ReceivedData) then
      // if ProcessExchange(ExchangeWindowString, ReceivedData) then

    begin
      if MessageEnable then
      begin

        SendCorrectCallIfNeeded;
        if Key = QuickQSLKey1 then
        begin
          if ActiveMode = Phone then
            SendCrypticMessage(QuickQSLPhoneMessage)
          else
            SendCrypticMessage(QuickQSLMessage1);
        end;
        if Key = QuickQSLKey2 then
          SendCrypticMessage(QuickQSLMessage2);
      end;
      TryLogContact;
    end;
  end;
end;

procedure StartSendingNow(FromKeyBoard: boolean);
begin

  if AutoSendCharacterCount > LoWord(Windows.SendMessage(wh[mweCall], EM_GETSEL,
    0, 0)) then
    Exit;

  if not CheckPTTLockout then
    if (CallWindowString <> '') then
      if not CallAlreadySent then
        if (ActiveMode = CW) then
          if (OpMode = CQOpMode) then
            if (EditingCallsignSent = False) then
              if (not StringIsAllNumbersOrDecimal(CallWindowString)) then
                // if StringHasNumber(CallWindowString) then
                if not (CallWindowString[1] = '\') then
                begin
                  if not FromKeyBoard then
                    if StringHas(CallWindowString, '/') then
                      Exit;
                  CallWindowKeyDownProc(integer(StartSendingNowKey));
                end;
end;

function NewCallWindowProcedure(hwnddlg: HWND; Msg: UINT; wParam: wParam;
  lParam: lParam): UINT; stdcall;
begin
  Result := 0;
  // Initialize as it it possible to not be initialized // ny4i Issue 116
  case Msg of

    WM_CHAR:
      begin
        if Char(wParam) = StartSendingNowKey then
          CallWindowKeyDownProc(wParam);
        if (Char(wParam) = QuickQSLKey1) or (Char(wParam) = QuickQSLKey2) then
          QuickQSLProcedure(Char(wParam));
        // wParam := CallsignChar(wParam, False);
      end;

    WM_SYSKEYDOWN, WM_KEYDOWN:
      begin
        if KeypadCWMemories then
          if wParam in [VK_NUMPAD0..VK_NUMPAD9] then
          begin
            if wParam <> VK_NUMPAD0 then
              ProcessFuntionKeys(wParam + 27)
            else
              ProcessFuntionKeys(wParam + 37);
            Exit;
          end;
      end;
  end;
  // if Msg = WM_KEYDOWN then showint(wParam);
  // if Msg = WM_KEYUP then showint(wParam);
  // if Msg = WM_char then showint(wParam);
  Result := CallWindowProc(NCWP, hwnddlg, Msg, wParam, lParam);

end;

procedure ClearLog;
begin
  // Windows.CopyFile(NewLogFileName, 'NewLogFileName', False);
  ReplaceLogByServerLog(False);
  if not OpenLogFile then
    Exit;

  Windows.ZeroMemory(@tRestartInfo, SizeOf(tRestartInfo));
  ReadVersionBlock;
  SetEndOfFile(LogHandle);
  CloseLogFile;

  LoadinLog;
  if wh[mweStations] <> 0 then
  begin
    SendMessage(wh[mweStations], LVM_DELETEALLITEMS, 0, 0);
    FillStationsColumn;
  end;
  SendStationStatus(sstQSOs);
end;
{
procedure GetLogColumnsWidth;
var
 col : LogColumnsType;
begin
// for col := logColBand to logColDummy do
// tRestartInfo.riColumnsWidthArray[col] := Windows.SendMessage(_NewELogWindow, LVM_GETCOLUMNWIDTH, integer(col), 0);
end;

procedure SetLogColumnsWidth;
var
 col : LogColumnsType;
begin

// if tRestartInfo.riColumnsWidthArray[logColBand] < 1 then Exit;
// for col := logColBand to logColDummy do
// Windows.SendMessage(
// _NewELogWindow,
// LVM_SETCOLUMNWIDTH,
// integer(col),
// tRestartInfo.riColumnsWidthArray[col]);

end;
}

procedure EnumLogRecords();
begin

end;

procedure ReadVersionBlock;
begin
  tSetFilePointer(SizeOfTLogHeader, FILE_BEGIN);
end;

procedure MakeTestLog;
var
  h: HWND;
  i: integer;
begin

  if not tOpenFileForWrite(h, 'C:\test.trw') then
    Exit;
  sWriteFile(h, LogHeader, SizeOfTLogHeader);

  for i := 1 to 30000 do
  begin

    ClearContestExchange(TempRXData);
    tGetQSOSystemTime(TempRXData.tSysTime);
    TempRXData.Band := Band40;
    TempRXData.Band := BandType(Random(6));
    TempRXData.Mode := ModeType(Random(2));
    SetExtendedModeFromMode(TempRXData);
    TempRXData.Callsign := CD.GetRandomCall;
    TempRXData.NumberSent := i;
    ctyLocateCall(TempRXData.Callsign, TempRXData.QTH);
    TempRXData.DXQTH := TempRXData.QTH.CountryID;
    TempRXData.Zone := ctyGetCQZone(TempRXData.Callsign);
    TempRXData.NumberSent := i;
    TempRXData.NumberReceived := i + 100;
    sWriteFile(h, TempRXData, SizeOf(ContestExchange));
  end;
  CloseHandle(h);
end;

procedure CompleteCallsign;
var
  MaskPos: integer;
  TempCallsign: CallString;
  MaskInserted: boolean;
begin
  if CompleteCallsignMask = '' then
    Exit;
  if pos('*', CompleteCallsignMask) = 0 then
    Exit;
  MaskInserted := False;
  TempCallsign := '';
  for MaskPos := 1 to length(CompleteCallsignMask) do
  begin
    if CompleteCallsignMask[MaskPos] <> '*' then
    begin
      TempCallsign := TempCallsign + CompleteCallsignMask[MaskPos];
    end
    else
    begin
      if MaskInserted = False then
        TempCallsign := TempCallsign + CallWindowString;
      MaskInserted := True;
    end;
  end;
  PutCallToCallWindow(TempCallsign);
end;

procedure PlaceCaretToTheEnd(wnd: HWND);
begin
  SendMessage(wnd, EM_SETSEL, 255, 255); // hh
end;

{
function TryToCheckTheLatestVersion: boolean;
begin
 Result := False;
 tGetSystemTime;

 if UTC.wYear * 12 * 30 + UTC.wMonth * 30 + UTC.wDay >= EXPIREDDAY then
 if YesOrNo(tr4whandle,
 TC_THISVERSION +
 TR4W_CURRENTVERSION +
 TC_WASBUILDIN +
 TR4W_CURRENTVERSIONDATE +
}

{$IF LANG = 'ENG'}
// ')' +
{$IFEND}
{
 '.' +
 #13 +
 TC_DOYOUWANTTOCHECKTHELATESTVERSION
 ) = IDYES then
 begin
 OpenURL(TR4W_DOWNLOAD_LINK);
 Result := True;
 end;

end;
}

procedure tGetSystemTime;
begin
  if not tHandLogMode then
    GetSystemTime(UTC);
{$IF tDebugMode}
  // inc(GetSystemTimeCounter);
  // Windows.SetWindowText(tr4whandle, inttopchar(GetSystemTimeCounter));
{$IFEND}
end;

procedure ShowLogPopupMenu(wnd: HWND);
var
  CPos: TPoint;
  LOGMENU: HMENU;
begin
  LOGMENU := LoadMenu(hInstance, 'E');
  GetCursorPos(CPos);
  TrackPopupMenu(GetSubMenu(LOGMENU, 0), TPM_LEFTALIGN or TPM_TOPALIGN, CPos.X,
    CPos.Y, 0, wnd, nil);
  DestroyMenu(LOGMENU);
  FrmSetFocus;
end;

procedure SystemTimeChanging;
begin
  if not tHandLogMode then
    GetSystemTime(UTC);
  SetMainWindowText(mweClock, GetTimeString);
  SetMainWindowText(mweFullTime, GetFullTimeString(False));
  SetMainWindowText(mweDate, GetDateString);
end;

procedure DefTR4WProc(Msg: Cardinal; var lp: integer; wnd: HWND);
begin
  case Msg of
    WM_EXITSIZEMOVE: FrmSetFocus;
    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lp));
    WM_SIZE: tListBoxClientAlign(wnd);
    WM_LBUTTONDOWN: DragWindow(wnd);
    
  end;
end;

function AddRecordToLogAndSendToNetwork(var CE: ContestExchange): boolean;
begin
  CE.ceQSOID1 := STARTTIMEOFTHETR4W;
  CE.ceQSOID2 := Windows.GetTickCount;
  CE.ceComputerID := ComputerID;
  CE.ceContest := Contest;
  CE.Band := ActiveBand;
  CE.Mode := ActiveMode;
  SetExtendedModeFromMode(CE);
  tGetQSOSystemTime(CE.tSysTime);
  CE.ceOperator := CurrentOperator;

  Result := SendRecordToServer(NET_QSOINFO_ID, CE);
  if not Result then
    inc(tUSQ);

  tAddQSOToLog(CE);
end;

procedure FlashCallWindow;
begin
  Windows.ShowWindow(wh[mweCall], SW_HIDE);
  Sleep(100);
  Windows.ShowWindow(wh[mweCall], SW_SHOW);
end;

procedure ProcessCommandLine;

begin
  {
  p := GetCommandLine;
  ShowMessage(p);
  l := Windows.lstrlen(p);

  for i := 0 to l - 4 do
  begin
  // Issue #997: asm pointer arith -> Pascal (p := p + i, preserved exactly).
  p := Pointer(Cardinal(p) + Cardinal(i));
  if PInteger(p)^ = 0 then sm;
  end;
  }
end;

procedure PutCallToCallWindow(Call: CallString);
begin
  logger.debug('[PutCallToCallWindow] Putting %s into main call window',
    [Call]);
  Call[Ord(Call[0]) + 1] := #0;
  if call = MyCall then
  begin
    logger.debug('[PutCallToCallWindow] Exiting early because call (%s) = MyCall (%s)', [call, MyCall]);
    exit; // n4af issue 158
  end;
  logger.debug('Calling Windows.SetWindowText wh[mweCall] to %s',[call]);
  Windows.SetWindowText(wh[mweCall], @Call[1]);
  PlaceCaretToTheEnd(wh[mweCall]);
end;

procedure SetColumnsWidth;
var
  i: integer;
  TempColumn: LogColumnsType;
begin
  ColumnsArray[logColPrecedence].Enable := ActiveExchange =
    QSONumberPrecedenceCheckDomesticQTHExchange;
  ColumnsArray[logColCheck].Enable := ActiveExchange =
    QSONumberPrecedenceCheckDomesticQTHExchange;
  ColumnsArray[logColQTC].Enable := QTCsEnabled;
  ColumnsArray[logColAge].Enable := ExchangeInformation.Age;

  ColumnsArray[logColQTH].Enable := ExchangeInformation.QTH;
  ColumnsArray[logColClass].Enable := ExchangeInformation.ClassEI;

  // ColumnsArray[logColDomMult].Enable := ExchangeInformation.QTH and (ActiveDomesticMult <> NoDomesticMults);
  // if ColumnsArray[logColDomMult].Enable then ColumnsArray[logColQTH].Enable := False;

  ColumnsArray[logColName].Enable := ExchangeInformation.Name;
  ColumnsArray[logColZoneMult].Enable := ExchangeInformation.Zone;
  if Contest <> FOCMARATHON then //n4af 4.32.5
    ColumnsArray[logColPower].Enable := ExchangeInformation.Power;
  if Contest = FOCMARATHON then //n4af 4.32.5
    ColumnsArray[logColFOC].Enable := ExchangeInformation.Power; //n4af 4.32.5
  ColumnsArray[logColChapter].Enable := ExchangeInformation.Chapter;

  ColumnsArray[logColNumberReceive].Enable := ExchangeInformation.QSONumber;
  ColumnsArray[logColPrefixMult].Enable := ActivePrefixMult <> NoPrefixMults;
  ColumnsArray[logColDXMult].Enable := ActiveDXMult <> NoDXMults;
  // ColumnsArray[logColPostCode].Enable := ExchangeInformation.PostalCode;
  ColumnsArray[logColKids].Enable := ExchangeInformation.Kids;
  i := -1;
  for TempColumn := logColBand to High(LogColumnsType) {Pred(logColDummy)} do
    if ColumnsArray[TempColumn].Enable then
    begin
      inc(i);
      ColumnsArray[TempColumn].pos := i;
    end;
end;

procedure EnsureListViewColumnVisible(h: HWND);
var
  TempColumn: LogColumnsType;
  ActualWidth: Integer;
begin
  for TempColumn := logColBand to High(LogColumnsType) do
    if ColumnsArray[TempColumn].Enable then
      begin
      if ColumnWidthOverride[TempColumn] > 0 then
         begin
         // User has manually sized this column — restore their saved width
         ListView_SetColumnWidth(h, ColumnsArray[TempColumn].pos, ColumnWidthOverride[TempColumn]);
         ActualWidth := ListView_GetColumnWidth(h, ColumnsArray[TempColumn].pos);
         logger.Debug('EnsureListViewColumnVisible: %s pos=%d override=%d actual=%d',
            [ColumnsArray[TempColumn].Text, ColumnsArray[TempColumn].pos,
             ColumnWidthOverride[TempColumn], ActualWidth]);
         end
      else if (TempColumn >= logColNumberReceive) and ColumnAutoSize then
        // Original auto-size behavior: unchanged from before Issue 866
        ListView_SetColumnWidth(h, integer(TempColumn), LVSCW_AUTOSIZE_USEHEADER);
      end;
end;

procedure SaveColumnWidthToConfig(ColIndex: Integer; NewWidth: Integer);
var
   TempColumn: LogColumnsType;
   KeyName: ShortString;
   WidthStr: ShortString;
begin
   for TempColumn := Low(LogColumnsType) to High(LogColumnsType) do
      begin
      if ColumnsArray[TempColumn].Enable and (ColumnsArray[TempColumn].pos = ColIndex) then
         begin
         if NewWidth > 0 then
            begin
            ColumnWidthOverride[TempColumn] := NewWidth;
            // Use language-neutral canonical name (see VC.pas) so the CFG
            // file is portable across language builds. ColumnsArray[].Text
            // is translated at compile time and would lock the CFG to the
            // language it was written under.
            KeyName := 'COLUMN WIDTH ' + StrPas(ColumnCanonicalName[TempColumn]);
            KeyName[Ord(KeyName[0]) + 1] := #0;
            Str(NewWidth, WidthStr);
            WidthStr[Ord(WidthStr[0]) + 1] := #0;
            Windows.WritePrivateProfileString('COMMANDS', @KeyName[1], @WidthStr[1], @TR4W_CFG_FILENAME);
            end;
         Exit;
         end;
      end;
end;

procedure ExecuteConfigurationFile(f: ShortString);
var
  FirstCommand: boolean;

begin
  RunningConfigFile := True;
  ClearDupeSheetCommandGiven := False;
  FirstCommand := False;
  if utils_file.FileExists(@f[1]) then
    LoadInSeparateConfigFile(f, FirstCommand, MyCall);
  if ClearDupeSheetCommandGiven then
    tClearDupesheet;
  RunningConfigFile := False;

end;

function NewGetMem(Size: integer): Pointer;
begin
  // inc(GetMemCount);
  // RESULT := OldMemMgr.GetMem(Size);

  asm
 add esp,12
 pop PreviousProcAddress
 sub esp,16
  end;

  // inc(GetMemCount);
  try
    Result := OldMemMgr.GetMem(Size);
  except
    begin
      asm
 push PreviousProcAddress
      end;
      wsprintf(wsprintfBuffer,
        'If you see this message, please send this code: '#13#10#13#10'GM-%X'#13#10#13#10'to ny4i@ny4i.com.');
      asm add esp,12
      end;
      showwarning(wsprintfBuffer);
    end;

  end;
end;

function NewFreeMem(p: Pointer): integer;
begin

  asm
 add esp,12
 pop PreviousProcAddress
 sub esp,16
  end;

  inc(FreeMemCount);
  Result := OldMemMgr.FreeMem(p);
  if Result <> 0 then
  begin
    asm
 push PreviousProcAddress
    end;
    wsprintf(wsprintfBuffer,
      'If you see this message, please send this code: '#13#10#13#10'FM-%X'#13#10#13#10'to tr4w@qrz.ru.');
    asm add esp,12
    end;
    showwarning(wsprintfBuffer);
  end;
end;

function NewReallocMem(p: Pointer; Size: integer): Pointer;
begin

  inc(ReallocMemCount);
  Result := OldMemMgr.ReallocMem(p, Size);
end;

const
  NewMemMgr: TMemoryManager = (
    GetMem: NewGetMem;
    FreeMem: NewFreeMem;
    ReallocMem: NewReallocMem);

procedure SetNewMemMgr;
begin
  GetMemoryManager(OldMemMgr);
  SetMemoryManager(NewMemMgr);
end;

procedure CheckEditableWindowHeight;
var
  h, guard: integer;
begin
  // Size the editable-log list so ALL LinesInEditableLog loaded rows are fully
  // visible.  The old loop shrank to the largest height where only
  // LinesInEditableLog-1 rows fit, which always left the next (loaded) row
  // clipped at the bottom with no border.  Instead: shrink if too many rows
  // fit, then grow to the SMALLEST height where every LinesInEditableLog row
  // shows whole -- the list's static edge then forms a clean bottom border
  // matching the top.  (Reported: editable-log bottom row cut off.)
  h := 30 + LinesInEditableLog * (ws + 2) {EditableLogWindowHeight};
  Windows.SetWindowPos(wh[mweEditableLog], HWND_TOP, 0, ws * 7,
    MainWindowChildsWidth, h, SWP_SHOWWINDOW);

  guard := 0;
  while (ListView_GetCountPerPage(wh[mweEditableLog]) > LinesInEditableLog)
        and (guard < 200) do
    begin
    h := h - 1;
    Inc(guard);
    Windows.SetWindowPos(wh[mweEditableLog], HWND_TOP, 0, ws * 7,
      MainWindowChildsWidth, h, SWP_SHOWWINDOW);
    end;

  guard := 0;
  while (ListView_GetCountPerPage(wh[mweEditableLog]) < LinesInEditableLog)
        and (guard < 200) do
    begin
    h := h + 1;
    Inc(guard);
    Windows.SetWindowPos(wh[mweEditableLog], HWND_TOP, 0, ws * 7,
      MainWindowChildsWidth, h, SWP_SHOWWINDOW);
    end;
end;

function CheckCommandInCallsignWindow: boolean;
begin
  Result := true;
  case AnsiIndexText(AnsiUpperCase(CallWindowString),
    ['ADIF', 'CAB', 'CMD', 'COL', 'CWOFF', 'CWON', 'EXIT', 'NOTE', 'OPON',
    'SCORE',
      'SUM', 'UDP', 'WCY', 'WWV']) of
    0: ProcessMenu(menu_adif);
    1: ProcessMenu(menu_cabrillo);
    2: WinExec('cmd.exe', SW_SHOW);
    3: ProcessMenu(menu_colors);
    4:
      // TODO: candidate for LogCW.SetCWState(False, ...) once the 'CW Off'/'CW On'
      // quick-display text is parameterized (Issue 380 cleanup). Left inline for now.
      begin
        if CWEnabled or CWEnable then
        begin
          QuickDisplay('CW Off');
          FlushCWBufferAndClearPTT;
          CWEnabled := False;
          CWEnable := false;
          DisplayCodeSpeed;
        end;
      end;
    5:
      // TODO: candidate for LogCW.SetCWState(True, ...) (Issue 380 cleanup). Left inline for now.
      begin
        CWEnabled := True;
        CWEnable := true;
        QuickDisplay('CW On');
        DisplayCodeSpeed;
        SetSpeed(CodeSpeed);
      end;
    6: ProcessMenu(menu_exit);
    7: ProcessMenu(menu_ctrl_note);
    8: ProcessMenu(menu_login);
    9: SendScoreToUDP;
    10: ProcessMenu(menu_summary);
    11: SendFullLogToUDP;
    12: SendViaTelnetSocket('SH/WCY');
    13: SendViaTelnetSocket('SH/WWV');
  else
    Result := false; // False result does not clear call window
  end; // case
  Exit;

end;

procedure ClearMultSheet_CtrlC;
begin
  tInputDialogWarning := True;
  if QuickEditResponse(TC_CLEARMULTTOCLEARMULTSHEET, 9) = 'CLEARMULT' then
    tClearMultSheet;
end;

procedure tClearMultSheet;
begin
  tUpdateLog(actClearMults);
  LoadinLog;
  QuickDisplay(TC_MULTSHEETCLEARED);
end;

procedure ReCalculateHourDisplay;
label
  1, 2, 3;
var
  FilePointer: integer;
  TempBand: BandType;
  TempHour: Byte;
  TempFileSize: integer;
begin
  FilePointer := -1;
  TempBand := NoBand;
  tGetSystemTime;
  TempHour := UTC.wHour;
  tThisHourBandChanges := 0;
  if not OpenLogFile then
    Exit;
  begin
    TempFileSize := (Windows.GetFileSize(LogHandle, nil) div 256) * -1;
    1:
    tSetFilePointer(FilePointer * SizeOf(ContestExchange), FILE_END);
    if ReadLogFile then
    begin
      if GoodLookingQSO then
      begin
        if TempHour = TempRXData.tSysTime.qtHour then
        begin
          if tThisHourPreviousBand = NoBand then
            tThisHourPreviousBand := TempRXData.Band;
          if TempBand <> TempRXData.Band then
          begin
            if HourDisplay = BandChangesThisComputer then
              if TempRXData.ceComputerID <> ComputerID then
                goto 3;
            if TempBand <> NoBand then
              inc(tThisHourBandChanges);
            TempBand := TempRXData.Band;
          end;
        end
        else
          goto 2;
      end;
      3:
      dec(FilePointer);
      if FilePointer <> TempFileSize then
        goto 1;
    end;
    2:
    CloseLogFile;
  end;
  DisplayHour;
end;

procedure SetRemMultsColumnWidth;
var
  Width: integer;
 // DomWidth: integer;

begin
  // 4.71.2 attempt to allow longer column width for long DOM MULTS by setting SHOW DOMESTIC MULTIPLIER NAME to TRUE
  // windows.ZeroMemory(@RemMultsColumnWidthArray, sizeof(RemMultsColumnWidthArray));

  if (tShowDomesticMultiplierName) or (DoingPrefixMults) then
    Width := PREFIXCOLUMNWIDTH
  else
    Width := BASECOLUMNWIDTH;

  tLB_SETCOLUMNWIDTH(tr4w_WindowsArray[tw_REMMULTSWINDOW_INDEX].WndHandle,
    Width);

end;

procedure tEnumeratePorts;
//var
// BytesNeeded, Returned, i : DWORD;
// Success : boolean;
// PortsPtr : Pointer;
// InfoPtr : PPortInfo1;
begin
  {

  Success := EnumPorts(nil, 1, nil, 0, BytesNeeded, Returned);

  if (not Success) and (GetLastError = ERROR_INSUFFICIENT_BUFFER) then
  begin
  Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
  Windows.lstrcat(wsprintfBuffer, 'Available ports: '#13#10);

  GetMem(PortsPtr, BytesNeeded);
  try

  Success := EnumPorts(nil, 1, PortsPtr, BytesNeeded, BytesNeeded, Returned);

  for I := 0 to Returned - 1 do
  begin
  InfoPtr := PPortInfo1(DWORD(PortsPtr) + I * SizeOf(InfoPtr));
  if InfoPtr^.pName[0] in ['C', 'L'] then
  begin
  Windows.lstrcat(wsprintfBuffer, InfoPtr^.pName);
  Windows.lstrcat(wsprintfBuffer, ' ');
  end;

  end;
  finally
  FreeMem(PortsPtr);
  end;
  ShowMessage(wsprintfBuffer);
  end;
  }
end;

function KeyerDebugDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam:
  lParam): BOOL; stdcall;
begin
  Result := False;
  case Msg of
    WM_INITDIALOG:
      begin
        tKeyerDebugWindowHandle := hwnddlg;
        Windows.SetWindowPos(hwnddlg, HWND_TOP, 0, 0, 200, 200, SWP_SHOWWINDOW);

        Windows.SetWindowText(hwnddlg, 'TWO RADIO debug');

        CreateButton(BS_CHECKBOX, 'RTS1', 10, 10, 50, hwnddlg, 102);
        CreateButton(BS_CHECKBOX, 'DTR1', 10, 30, 50, hwnddlg, 103);

        CreateButton(BS_CHECKBOX, 'RTS2', 70, 10, 50, hwnddlg, 105);
        CreateButton(BS_CHECKBOX, 'DTR2', 70, 30, 50, hwnddlg, 106);

      end;

    WM_CLOSE: EndDialog(hwnddlg, 0);

  end;

end;

procedure CheckInactiveRigCallingCQ;

begin
  if SwitchNext then //n4af 4.30.1
    if ((length(CallWindowString) > 0) {or (InactiveSwapRadio)}) and ((not
      WKBusy) and (not (CWThreadID <> 0))) then // n4af 4.52.6
    begin
      InactiveRigCallingCQ := False;
      scWk_Reset;
      SwapRadios;
      SwitchNext := False; // 4.52.8
      if (not AutoSendEnable) or (not AutoSendCharacterCount > 0) then
        //n4af 4.42.10 Redrive dupe check
        ReturninCQopmode;
      ShowInformation;
    end;
  // pRadio := ActiveRadioPtr;
  // if ((ActiveMode = CW) and autosendenable and (not WKBusy)) then
  // {((CWThreadID <> 0) or wkBUSY or pRadio.CWByCAT_Sending))} then
  // begin
  // SwapRadios;
  // inactiverigcallingcq := False;
  // end

end;

function CheckWindowAndColor(Window: HWND; var Brush: HBRUSH; var Color:
  integer): boolean;
var
  TempWindowElement: TMainWindowElement;
begin
  Result := False;
  for TempWindowElement := Low(TMainWindowElement) to High(TMainWindowElement)
    do
  begin
    if wh[TempWindowElement] = Window then
    begin
      Brush := tr4wBrushArray[TWindows[TempWindowElement].mweBackG];
      Color := tr4wColorsArray[TWindows[TempWindowElement].mweColor];
      Result := True;
      Break;
    end;
  end;

end;

(*----------------------------------------------------------------------------*)

// GetADIFMode, GetADIFSubMode, GetADIFBand moved to uADIF.pas (Issue #887).

// ---------------------------------------------------------------------------
// Contest-specific post-processing for an imported ADIF record.
//
// Most ADIF tag-to-ContestExchange mapping is done by uADIF.ApplyADIFFields-
// ToExchange (a pure function, no MainUnit globals).  But for several
// contests, the tag-level value needs contest-aware reinterpretation:
// e.g. for ARRL_RTTY_ROUNDUP, the QTHString is built from RST + STATE in
// a contest-defined format; for POTA, the QTHString comes from POTA_REF
// or SIG_INFO depending on which was supplied.
//
// This routine takes the temps captured during field mapping and applies
// the contest-specific logic.  It uses MainUnit-scope globals
// (currentOperator, ActiveDomesticMult, ActiveExchange, DoingDomesticMults)
// which is why it stays in MainUnit rather than moving to uADIF.
// ---------------------------------------------------------------------------
procedure ApplyContestSpecificADIFTail(const temps: TADIFRecordTemps;
                                       var exch: ContestExchange);
var
  j : Integer;
begin
  // fix up operator
  if exch.ceOperator = '' then
    exch.ceOperator := currentOperator;

  if Length(temps.SRX_String) > 0 then
    exch.ExchString := temps.SRX_String;

  case exch.ceContest of
    GENERALQSO:
      // Use grid square as exchange for any ADIF source, not just WSJT-X.
      // WSJT-X does not always include PROGRAMID, so gating on FromWSJTX
      // caused ExchString to stay empty when PROGRAMID was absent.
      if temps.GridSquare <> '' then
        begin
        exch.ExchString  := temps.GridSquare;
        exch.QTHString   := temps.GridSquare;
        exch.DomesticQTH := temps.GridSquare;
        end;

    WAG:
      exch.QTHString := temps.SRX_String;

    ARRL160, CQ160CW, CQ160SSB, UBACW, UBASSB:
      exch.DomesticQTH := temps.SRX_String;

    ARRL_RTTY_ROUNDUP:
      begin
        logger.Debug('[ParseADIF] exch.QTH.CountryID = %s',
                     [exch.QTH.CountryID]);
        if (exch.QTH.CountryID = 'K') or (exch.QTH.CountryID = 'VE') then
          exch.QTHString := IntToStr(exch.RSTReceived) + ' ' + temps.State
        else
          exch.QTHString := IntToStr(exch.RSTReceived) + ' ' +
                            IntToStr(exch.NumberReceived);
        exch.ExchString := exch.QTHString;
      end;

    ARRLSSCW, ARRLSSSSB, WINTERFIELDDAY, ARRLFIELDDAY:
      begin
        exch.DomesticQTH := temps.ARRL_Sect;
        exch.QTHString   := temps.ARRL_Sect;
      end;

    CWOPS:
      exch.Age := StrToIntDef(exch.QTHString, 0);

    CQWWCW, CQWWSSB:
      begin
        // For CQWW the QTHString is the zone (as a string); the SRX_STRING
        // carries the zone numerically.
        exch.QTHString := temps.SRX_String;
        exch.zone      := StrToIntDef(temps.SRX_String, 0);
      end;

    FOCMARATHON:
      exch.Power := temps.FOC_Num;

    IARU:
      exch.QTHString := temps.SRX_String;

    NAQSOCW, NAQSOSSB, NAQSORTTY, NCCCSPRINT:
      begin
        exch.QTHString   := temps.State;
        exch.DomesticQTH := temps.State;
        exch.ExchString  := temps.State;
      end;

    UKRAINIAN, OKDX, LZDX:
      if IsAlpha(temps.SRX_String) then
        exch.DomesticQTH := temps.SRX_String
      else
        exch.QTHString := temps.SRX_String;

    POTA:
      if IsValidPOTAPark(temps.POTARef) then
        begin
        if Length(temps.POTARef) = 0 then
          begin
          if AnsiUpperCase(temps.SIG) = 'POTA' then
            if IsValidPOTAPark(temps.SIG_Info) then
              exch.QTHString := temps.SIG_Info;
          end
        else
          exch.QTHString := temps.POTARef;
        end
      else
        if LooksLikeAState(temps.State) then
          begin
          exch.QTHString   := temps.State;
          exch.DomesticQTH := temps.State;
          end;

    WWDIGI, ARRLDIGI:
      begin
        exch.ExchString  := temps.GridSquare;
        exch.DomesticQTH := temps.GridSquare;
      end;

  else
    if (ActiveDomesticMult = GridSquares) or
       (ActiveExchange = RSTAndOrGridExchange) or
       (ActiveExchange = Grid2Exchange) or
       (ActiveExchange = RSTAndGrid3Exchange) or
       (ActiveExchange = GridExchange) then
      begin
      exch.QTHString   := temps.GridSquare;
      exch.DomesticQTH := temps.GridSquare;
      exch.ExchString  := IntToStr(exch.RSTReceived) + ' ' + temps.GridSquare;
      end
    else if DoingDomesticMults then
      begin
      if exch.QTHString <> '' then
        // ADIF QTH tag carries the county/state code unambiguously
        // for state QSO parties.  Prefer it when present -- the
        // alpha-prefix-of-SRX_STRING heuristic below was already
        // unreliable, and now fails outright because SRX_STRING is
        // normalized to include a leading RST ("59 MON") on export.
        exch.DomesticQTH := exch.QTHString
      else
        begin
        // Legacy fallback for ADIF imports that lack a QTH tag.
        // Loads DomesticQTH with the ALPHA prefix of SRX_STRING.
        j := 1;
        while (j <= Length(temps.SRX_String)) and
              not (temps.SRX_String[j] in ['0'..'9']) do
          Inc(j);
        exch.DomesticQTH := Copy(temps.SRX_String, 1, j - 1);
        end;
      end
    else
      exch.ExchString := temps.SRX_String;
  end;
end;

function ParseADIFRecord(sADIF: string; var exch: ContestExchange): boolean;
var
  fields : TADIFFieldList;
  temps  : TADIFRecordTemps;
begin
  logger.debug('[ParseADIFRecord] Parsing %s', [sADIF]);
  Result := ParseADIFFieldsList(sADIF, fields);
  // Even when no terminator is found, apply whatever fields the lexer
  // managed to parse -- same forgiving behaviour as the legacy
  // implementation, which logged at error but kept the partial exch.
  ApplyADIFFieldsToExchange(fields, exch, temps);
  ApplyContestSpecificADIFTail(temps, exch);
  // State-QP rover (KG1S/MON): strip suffix for country lookup so /M
  // doesn't get misread as a GB prefix indicator.  Done here (rather
  // than inside uADIF) because the strip uses MainUnit-scope state
  // (DomQTHTable, ActiveExchange).
  ctyLocateCallStripRover(exch.Callsign, exch.QTH);
end; // of ParseADIFRecord
(*----------------------------------------------------------------------------*)

procedure ImportFromADIF;
var
  openDlg: TOpenDialog;
  buttonSelected: integer;
  adif: TextFile;
  adifFileName: string;
  sBuffer: string;
  FoundEOH: boolean;
  QSOCounter: integer;
  lpNumberOfBytesWritten: Cardinal;
  // County-line detection during import.  Within a single ImportFromADIF
  // pass we remember the first QTHString seen for each (call|band|mode)
  // tuple.  When a later record reuses the same (call|band|mode) with a
  // different QTHString AND the contest's CountyLineAllowed flag is True,
  // we set ceClearDupeSheet on the later record so the post-import
  // rescore (tUpdateLog(actRescore)) does NOT flag it as a dupe.
  // ContestsArray[ceContest].CountyLineAllowed is set to True only for
  // the 13 single-state QSO parties (VC.pas).  Multi-state QPs (7QP /
  // NEQP / etc.) are deliberately not flagged -- they need their own
  // per-state county-line handling, tracked separately.
  seenCallBandMode    : TStringList;
  cbmKey              : string;
  cbmKeyIdx           : Integer;
  priorQTHForKey      : string;

  procedure DisplayLoadedQSOs;
  begin
    Format(QuickDisplayBuffer, '%u ' + TC_QSO_IMPORTED, QSOCounter);
    SetTextInQuickCommandWindow(QuickDisplayBuffer);
  end;
begin
  { This is a total rewrite of the ADIF import processing. - NY4I 2020 Jul 2
  }
  FoundEOH := false;
  try
    openDlg := TOpenDialog.Create(nil);
    openDlg.InitialDir := GetCurrentDir;
    openDlg.Options := [ofFileMustExist, ofHideReadOnly, ofEnableSizing];
    openDlg.Filter := 'ADIF (*.adi, *.adif)|*.adi;*.adif';
    openDlg.FilterIndex := 1;
    if openDlg.Execute then
    begin // File was selected in openDlg.FileName
      adifFileName := openDlg.FileName;
      if QSOTotals[AllBands, Both] > 0 then
      begin
        buttonSelected := MessageDlg(TC_APPENDIMPORTEDQSOSTOCURRENTLOG
          , mtConfirmation
          , [mbYes, mbNo]
          , 0
          );
        if buttonSelected = mrNo then
        begin
          exit;
        end;
      end;
    end;
  finally
    openDlg.Free;
  end;

  if not FileExists(adifFileName) then
  begin
    MessageDlg({TC_IMPORTFILENOTFOUND} 'The import file is not available' + ' '
      + adifFileName, mtError, [mbOK], 0);
    exit;
  end;

  if not OpenLogFile then
  begin
    MessageDlg({TC_CANNOTOPENLOG} 'Cannot open log file', mtError, [mbOK], 0);

    exit;
  end;
  tSetFilePointer(0, FILE_END);
  // Now open te file and process

  if not FileExists(adifFileName) then
  begin
    DebugMsg('In ImportADIF, ADIF file ' + adifFilename + ' does not exists');
    Exit;
  end;

  AssignFile(adif, adifFileName);
  //ReWrite(adif);
  QSOCounter := 0;
  Reset(adif);
  seenCallBandMode := TStringList.Create;
  try
    seenCallBandMode.CaseSensitive := False;
    while not Eof(adif) do
    begin
      ReadLn(adif, sBuffer);
      if not FoundEOH then
      begin
        if trim(AnsiUpperCase(sBuffer)) = '<EOH>' then
        begin
          FoundEOH := true;
        end;
      end
      else
      begin
        ClearContestExchange(TempRXData);
        if ParseADIFRecord(sBuffer, TempRXData) then // processed a record if true
        begin
          // State-QP rover (KG1S/MON): strip suffix for country lookup so
          // the /M tail isn't misread as a GB prefix indicator.  Without
          // this wrapper the post-ParseADIFRecord lookup overwrites the
          // QTH set inside ParseADIFRecord and we end up with DX=G.
          ctyLocateCallStripRover(TempRXData.Callsign, TempRXData.QTH);

          // County-line follow-up detection.  If the imported record
          // reuses (call|band|mode) with a different QTHString AND the
          // contest's CountyLineAllowed flag is True (see VC.pas), set
          // ceClearDupeSheet so the post-import rescore does not
          // dupe-flag this record.  Otherwise leave the flag alone --
          // the standard dupe check stays in effect.
          cbmKey := string(TempRXData.Callsign) + '|' +
                    IntToStr(Ord(TempRXData.Band)) + '|' +
                    IntToStr(Ord(TempRXData.Mode));
          cbmKeyIdx := seenCallBandMode.IndexOfName(cbmKey);
          if cbmKeyIdx >= 0 then
            begin
            priorQTHForKey := seenCallBandMode.ValueFromIndex[cbmKeyIdx];
            if (priorQTHForKey <> string(TempRXData.QTHString)) and
               ContestsArray[TempRXData.ceContest].CountyLineAllowed then
              TempRXData.ceClearDupeSheet := True;
            end
          else
            seenCallBandMode.Add(cbmKey + '=' + string(TempRXData.QTHString));

          CalculateQSOPoints(TempRXData);
          tWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange),
            lpNumberOfBytesWritten);
          inc(QSOCounter);
          if QSOCounter mod 100 = 0 then
          begin
            DisplayLoadedQSOs;
          end;
        end;
      end;
    end;
  finally
    seenCallBandMode.Free;
  end;

  CloseFile(adif);

  CloseLogFile;

  tUpdateLog(actRescore);
  LoadinLog;
  DisplayLoadedQSOs;
  ImportFromADIFThreadID := 0;

end; // of ImportFromADIF
(*

procedure ImportFromADIF;
label
 1, 2, 3, 4, Increment, again;
var
 MapFin : Cardinal;
 MapBase : Pointer;
 LogSize : Cardinal;
 h : HWND;
 CurrentPos : PChar;
 StartPos : PChar;
 PosDecimal : integer; // 4.55.1
 QSOCounter : integer;
 FieldLength : integer;
// delta : integer;
 lpNumberOfBytesWritten : Cardinal;
 Switch : Boolean;
 TempBand : BandType;
 TempMode : ModeType;
 TempBuffer : array[0..8] of Char;
 TempInteger : integer;
const
 ADIF_CALL = Ord('L') * $1000000 + Ord('L') * $10000 + Ord('A') * $100 + Ord('C');
 ADIF_FREQ = Ord('Q') * $1000000 + Ord('E') * $10000 + Ord('R') * $100 + Ord('F');
 ADIF_NAME = Ord('E') * $1000000 + Ord('M') * $10000 + Ord('A') * $100 + Ord('N');

 ADIF_QTH = Ord(':') * $1000000 + Ord('H') * $10000 + Ord('T') * $100 + Ord('Q');
 ADIF_STATE = Ord('T') * $1000000 + Ord('A') * $10000 + Ord('T') * $100 + Ord('S');
 ADIF_PRECEDENCE = Ord('C') * $1000000 + Ord('E') * $10000 + Ord('R') * $100 + Ord('P');
 ADIF_CHECK = Ord('C') * $1000000 + Ord('E') * $10000 + Ord('H') * $100 + Ord('C');
 ADIF_ARRL_SECT = Ord('L') * $1000000 + Ord('R') * $10000 + Ord('R') * $100 + Ord('A');

 ADIF_QSO_ = Ord('_') * $1000000 + Ord('O') * $10000 + Ord('S') * $100 + Ord('Q');
 ADIF_DATE = Ord('E') * $1000000 + Ord('T') * $10000 + Ord('A') * $100 + Ord('D');
 ADIF_TIME = Ord('E') * $1000000 + Ord('M') * $10000 + Ord('I') * $100 + Ord('T');
 ADIF_STX = Ord(':') * $1000000 + Ord('X') * $10000 + Ord('T') * $100 + Ord('S');
 ADIF_SRX = Ord(':') * $1000000 + Ord('X') * $10000 + Ord('R') * $100 + Ord('S');

 ADIF_RST_ = Ord('_') * $1000000 + Ord('T') * $10000 + Ord('S') * $100 + Ord('R');
 ADIF_RCVD = Ord('D') * $1000000 + Ord('V') * $10000 + Ord('C') * $100 + Ord('R');
 ADIF_SENT = Ord('T') * $1000000 + Ord('N') * $10000 + Ord('E') * $100 + Ord('S');

 ADIF_MODE = Ord('E') * $1000000 + Ord('D') * $10000 + Ord('O') * $100 + Ord('M');
 ADIF_BAND = Ord('D') * $1000000 + Ord('N') * $10000 + Ord('A') * $100 + Ord('B');

 ADIF_ITUZ = Ord('Z') * $1000000 + Ord('U') * $10000 + Ord('T') * $100 + Ord('I');
 ADIF_CQZ = Ord(':') * $1000000 + Ord('Z') * $10000 + Ord('Q') * $100 + Ord('C');

 ADIF_RXPWR = Ord('P') * $1000000 + Ord('_') * $10000 + Ord('X') * $100 + Ord('R');

 ADIF_EOR = Ord('>') * $1000000 + Ord('R') * $10000 + Ord('O') * $100 + Ord('E');

 procedure DisplayLoadedQSOs;
 begin

 Format(QuickDisplayBuffer, '%u ' + TC_QSO_IMPORTED, QSOCounter);
 SetTextInQuickCommandWindow(QuickDisplayBuffer);
 end;

begin

 h := CreateFile(TR4W_ADIF_FILENAME, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
 if h = INVALID_HANDLE_VALUE then Exit;
 LogSize := Windows.GetFileSize(h, nil);

 MapFin := Windows.CreateFileMapping(h, nil, PAGE_READONLY, 0, 0, nil);
 if MapFin = 0 then goto 2;

 MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_READ, 0, 0, 0);
 if MapBase = nil then goto 3;

 if not OpenLogFile then goto 3;
 tSetFilePointer(0, FILE_END);

 CurrentPos := MapBase;
// PosCounter := 0;
 QSOCounter := 0;
 TempBuffer[8] := #0;
 ClearContestExchange(TempRXData);
 1:

 if CurrentPos[0] = '<' then
 begin
 StartPos := CurrentPos;
 Switch := False;
 while (StartPos[0] <> '>') and (StartPos - CurrentPos < 15) do inc(StartPos);
// asm nop end;

 inc(CurrentPos);
 inc(StartPos);

 Windows.CopyMemory(@TempBuffer, CurrentPos, 8);
 StrUpper(@TempBuffer);

 if PInteger(@TempBuffer)^ = ADIF_CALL then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[5]);
 TempRXData.Callsign[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.Callsign[1], StartPos, FieldLength);
 end;

 if PInteger(@TempBuffer)^ = ADIF_CQZ then
 if ActiveZoneMult = CQZones then
 TempRXData.Zone := GetNumberFromCharBuffer(StartPos);

 if PInteger(@TempBuffer)^ = ADIF_ITUZ then
 begin
// if not (TempBuffer[7] in ['0'..'9']) then
// asm nop end;

// if ActiveZoneMult = ITUZones then
 TempRXData.Zone := GetNumberFromCharBuffer(StartPos);

 end;

 if PInteger(@TempBuffer)^ = ADIF_QSO_ then
 if PInteger(@TempBuffer[4])^ = ADIF_DATE then
 begin
 TempRXData.tSysTime.qtYear := (Ord(StartPos[3]) - Ord('0')) + (Ord(StartPos[2]) - Ord('0')) * 10;
 TempRXData.tSysTime.qtMonth := (Ord(StartPos[5]) - Ord('0')) + (Ord(StartPos[4]) - Ord('0')) * 10;
 TempRXData.tSysTime.qtDay := (Ord(StartPos[7]) - Ord('0')) + (Ord(StartPos[6]) - Ord('0')) * 10;
 end;

 if PInteger(@TempBuffer)^ = ADIF_TIME then
 begin
 TempRXData.tSysTime.qtHour := (Ord(StartPos[1]) - Ord('0')) + (Ord(StartPos[0]) - Ord('0')) * 10;
 TempRXData.tSysTime.qtMinute := (Ord(StartPos[3]) - Ord('0')) + (Ord(StartPos[2]) - Ord('0')) * 10;
 end;

 if PInteger(@TempBuffer)^ = ADIF_STX then
 TempRXData.NumberSent := GetNumberFromCharBuffer(StartPos);

 if PInteger(@TempBuffer)^ = ADIF_SRX then
 TempRXData.NumberReceived := GetNumberFromCharBuffer(StartPos);

 if PInteger(@TempBuffer)^ = ADIF_RST_ then
 begin
 if PInteger(@TempBuffer[4])^ = ADIF_RCVD then
 TempRXData.RSTReceived := GetNumberFromCharBuffer(StartPos);

 if PInteger(@TempBuffer[4])^ = ADIF_SENT then
 TempRXData.RSTSent := GetNumberFromCharBuffer(StartPos);
 end;

 if PInteger(@TempBuffer)^ = ADIF_MODE then
 begin
 TempMode := NoMode;
 case StartPos[0] of
 'C': TempMode := CW;
 'S': TempMode := Phone;
 'P', 'R': TempMode := Digital;
 'F': TempMode := Phone;
 end;
 TempRXData.Mode := TempMode;
 end;

 if PInteger(@TempBuffer)^ = ADIF_NAME then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[5]);
 if FieldLength > SizeOf(TempRXData.Name) - 2 then FieldLength := SizeOf(TempRXData.Name) - 2;
 TempRXData.Name[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.Name[1], StartPos, FieldLength);
 end;

 if PInteger(@TempBuffer)^ = ADIF_PRECEDENCE then
 begin
 TempRXData.Precedence := CurrentPos[13];
 end;

 if PInteger(@TempBuffer)^ = ADIF_CHECK then
 begin
 TempRXData.Check := GetNumberFromCharBuffer(StartPos);
 end;

 if PInteger(@TempBuffer)^ = ADIF_QTH then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[4]);
 if FieldLength > SizeOf(TempRXData.QTHString) - 2 then FieldLength := SizeOf(TempRXData.QTHString) - 2;
 TempRXData.QTHString[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.QTHString[1], StartPos, FieldLength);
 DomQTHTable.GetDomQTH(TempRXData.QTHString, TempRXData.DomMultQTH, TempRXData.DomesticQTH);
 end;

 if PInteger(@TempBuffer)^ = ADIF_RXPWR then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[7]);
 if FieldLength > SizeOf(TempRXData.Power) - 2 then FieldLength := SizeOf(TempRXData.Power) - 2;
 TempRXData.Power[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.Power[1], StartPos, FieldLength);
 end;

 if PInteger(@TempBuffer)^ = ADIF_STATE then
 if TempBuffer[4] = 'E' then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[6]);
 TempRXData.QTHString[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.QTHString[1], StartPos, FieldLength);
 DomQTHTable.GetDomQTH(TempRXData.QTHString, TempRXData.DomMultQTH, TempRXData.DomesticQTH);
 end;

 if PInteger(@TempBuffer)^ = ADIF_ARRL_SECT then
 if TempBuffer[4] = '_' then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[10]);
 TempRXData.QTHString[0] := CHR(FieldLength);
 Windows.CopyMemory(@TempRXData.QTHString[1], StartPos, FieldLength);
 DomQTHTable.GetDomQTH(TempRXData.QTHString, TempRXData.DomMultQTH, TempRXData.DomesticQTH);
 end;

 if (PInteger(@TempBuffer)^ = ADIF_FREQ) then
 begin
 FieldLength := GetNumberFromCharBuffer(@CurrentPos[5]);
 again:
 for TempInteger := 0 to FieldLength-1 do
 begin
 if StartPos[TempInteger] = '.' then
 begin
 PosDecimal := TempInteger;
 if Switch = False then
 begin
 FieldLength := FieldLength + 1;
 Switch := True;
 // goto again;
 end;
 end;
 if StartPos[TempInteger] in ['0'..'9'] then
 TempRXData.Frequency := Ord(StartPos[TempInteger]) - Ord('0') + TempRXData.Frequency * 10
 else
 if StartPos[TempInteger] = '' then
 TempRXData.Frequency := TempRXData.Frequency * 10;
 end;
 if PosDecimal >0 then
 begin
 while FieldLength - PosDecimal < 8 do // 4.55.1
 begin
 TempRXData.Frequency := TempRXData.Frequency * 10;
 FieldLength := FieldLength + 1 ;
 end;
 end;

 if TempRXData.Frequency < 30000 then
 TempRXData.Frequency := TempRXData.Frequency * 1000;

 end;

 if PInteger(@TempBuffer)^ = ADIF_BAND then
 begin
 TempBand := NoBand;
 case StartPos[0] of
 '1':
 case StartPos[1] of
 '6': TempBand := Band160;
 '5': TempBand := Band15;
 '2': TempBand := Band12;
 '7': TempBand := Band17;
 '0': TempBand := Band10;
 end;
 '2':
 case StartPos[1] of
 '0': TempBand := Band20;
 'M': TempBand := Band2;
 end;
 '3': TempBand := Band30;
 '4': TempBand := Band40;
 '6': TempBand := Band6;
 '7': TempBand := Band222;
 '8': TempBand := Band80;

 end;
 TempRXData.Band := TempBand;
 end;

 if PInteger(@TempBuffer)^ = ADIF_EOR then
 begin
 ctyLocateCall(TempRXData.Callsign, TempRXData.QTH);
// if DoingDXMults then GetDXQTH(TempRXData);
// if DoingPrefixMults then SetPrefix(TempRXData);
// Sheet.SetMultFlags(TempRXData);

 tWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange), lpNumberOfBytesWritten);

 inc(QSOCounter);
 ClearContestExchange(TempRXData);
 if QSOCounter mod 100 = 0 then DisplayLoadedQSOs;
// if QSOCounter > 4446 then
// asm nop end;
 end;

 end;
{

 if PInteger(CurrentPos)^ = EORAsInteger then
 begin
 LocateCall(TempRXData.Callsign, TempRXData.QTH, True);
// if DoingDXMults then GetDXQTH(TempRXData);
// if DoingPrefixMults then SetPrefix(TempRXData);
// Sheet.SetMultFlags(TempRXData);

 tWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange), lpNumberOfBytesWritten);

 inc(QSOCounter);
 ClearContestExchange(TempRXData);
 if QSOCounter mod 100 = 0 then DisplayLoadedQSOs;

 end;
}
 Increment:

 if CurrentPos - MapBase < LogSize then
 begin
 inc(CurrentPos);
// inc(PosCounter);
 goto 1;
 end;
 CloseLogFile;
 4:
// FlushViewOfFile(MapBase, 0);
 Windows.UnmapViewOfFile(MapBase);
 3:
 CloseHandle(MapFin);
 2:
 CloseHandle(h);

 tUpdateLog(actRescore);
 LoadinLog;
 DisplayLoadedQSOs;
 ImportFromADIFThreadID := 0;
 // showint(QSOCounter);

end;
*)

procedure StartNewContest;
begin
  // ReleaseMutex(tMutex);
  CloseHandle(tMutex);
  Windows.SetCurrentDirectory(TR4W_PATH_NAME);
  Windows.WinExec('D:\TR4W_WinAPI\out\tr4w.exe', 0);
  ExitProgram(False);
end;

procedure CheckQuestionMark;
var
  i: integer;
begin
  if CallWindowString = '' then
    Exit;
  for i := 1 to CallstringLength do
  begin
    if CallWindowString[i] = '?' then
    begin
      SendMessage(wh[mweCall], EM_SETSEL, i - 1, i);
      Break;
    end;
  end;
end;

procedure ChangeFocus(Text: PChar);
var
  h: HWND;
  t: Cardinal;
  r: integer;
begin
  h := CreateFile('D:\TR4W_WinAPI\out\TEST\focus.txt', GENERIC_WRITE or
    GENERIC_READ, FILE_SHARE_WRITE or FILE_SHARE_READ, nil, OPEN_EXISTING,
    FILE_FLAG_SEQUENTIAL_SCAN, 0);
  SetFilePointer(h, 0, nil, FILE_END);

  // Issue #997: asm wsprintf-push -> TF.Format (cdecl-reverse: GetTickCount, Text).
  r := Format(TempBuffer1, '%u %s'#13#10, Windows.GetTickCount, Text);
  Windows.WriteFile(h, TempBuffer1, r, t, nil);
  CloseHandle(h);
  // AddStringToTelnetConsole(Text, tstSend);
end;

procedure SetCommand(c: PChar);
begin
  Format(TempBuffer1, TC_SET_VALUE_OF_SET_NOW, c);
  if YesOrNo(tr4whandle, TempBuffer1) = IDno then
    Exit;
  CommandToSet := c;
  ProcessMenu(menu_options);
end;

function Get101Window(h: HWND): HWND;
begin
  Result := Windows.GetDlgItem(h, 101)
end;

procedure InvertBooleanCommand(Command: PBoolean);
var
  i: integer;
  cmdProc: procedure;   // Issue #997: typed call of a Pointer change-handler
begin
  for i := 1 to CommandsArraySize do
    if CFGCA[i].crAddress = Command then
    begin
      InvertBoolean(Command^);
      Windows.WritePrivateProfileString(_COMMANDS, CFGCA[i].crCommand,
        BA[Command^], TR4W_INI_FILENAME);
      // Issue #997: asm `call p` (untyped Pointer change-handler) -> typed call,
      // nil-guarded against a nil entry in the CommandsProcArray definition.
      @cmdProc := CommandsProcArray[CFGCA[i].crP];
      if Assigned(cmdProc) then
         cmdProc;
    end;
end;

procedure ShowHelp(Topic: PChar);
{$IF LANG = 'RUS'}
var
  HelpBuffer: array[0..127] of Char;
{$IFEND}
begin
{$IF LANG = 'RUS'}
  Format(HelpBuffer, '%str4w_manual_' + LANG + '.chm::/%s.html', TR4W_PATH_NAME,
    Topic);
  HtmlHelp.hh(tr4whandle {GetDesktopWindow()}, HelpBuffer, HH_DISPLAY_TOPIC, 0);
{$IFEND}
end;

procedure RunExplorer(Command: PChar);
var
  TempPchar: PChar;
begin

  if strpos(Command, '.') <> nil then
    TempPchar := 'explorer /select, %s'
  else
    TempPchar := 'explorer %s';

  Format(wsprintfBuffer, TempPchar, Command);
  WinExec(wsprintfBuffer, SW_SHOW);
end;

const
  ASSOCF_NONE         = $00000000;   // Issue #986
  ASSOCSTR_EXECUTABLE = 2;           // the executable registered for the type

// AssocQueryStringA asks Windows which executable is registered for a file
// extension (here, ".txt").  Declared directly because Delphi 7's ShlwApi
// import unit does not expose it.
function AssocQueryStringA(flags: DWORD; str: DWORD; pszAssoc, pszExtra,
  pszOut: PChar; pcchOut: PDWORD): HRESULT; stdcall;
  external 'shlwapi.dll' name 'AssocQueryStringA';

// Issue #986 -- open FileName in the user's default text editor (the program
// registered for the ".txt" extension) instead of hard-coding Notepad.  Shared
// by every "open in editor" path (the file-preview window, history.txt, ...).
// Falls back to Notepad if no .txt association can be resolved or the editor
// fails to launch, so the behavior never regresses on a misconfigured system.
procedure OpenInDefaultTextEditor(FileName: PChar);
var
  editor   : array[0..1023] of Char;
  cmdBuf   : array[0..1279] of Char;   // local: caller may pass wsprintfBuffer
  len      : DWORD;
  launched : boolean;
begin
  launched := False;
  len := SizeOf(editor);
  editor[0] := #0;
  if AssocQueryStringA(ASSOCF_NONE, ASSOCSTR_EXECUTABLE, '.txt', nil,
        editor, @len) = S_OK then
     begin
     if editor[0] <> #0 then
        begin
        // The file path may contain spaces, so pass it as a quoted argument.
        Format(cmdBuf, '"%s"', FileName);
        if ShellExecute(0, nil, editor, cmdBuf, nil,
              SW_SHOWNORMAL) > 32 then
           begin
           launched := True;
           end;
        end;
     end;

  if not launched then
     begin
     // Fallback: Notepad, opened in a normal (non-maximized) window.
     Format(cmdBuf, 'Notepad %s', FileName);
     WinExec(cmdBuf, SW_SHOWNORMAL);
     end;
end;

// Issue #23 -- let the DX Cluster window's command field handle the standard
// clipboard/edit keys (Ctrl-C/V/X, plus Select-All/Undo) itself, instead of the
// main accelerator table stealing them (Ctrl-V = Execute Config File, Ctrl-C =
// Clear Mult Sheet).  Returns True when aMsg is one of those keystrokes AND
// focus is inside the telnet (cluster) window, so the main loop can skip
// TranslateAccelerator and let the keystroke reach the edit via DispatchMessage.
// Deliberately scoped to the telnet window only for now so other windows can be
// vetted separately before extending this behavior.
function TelnetWantsClipboardKey(const aMsg: TMsg): boolean;
var
   hTelnet: HWND;
begin
   Result := False;
   if aMsg.message <> WM_KEYDOWN then Exit;
   if (GetKeyState(VK_CONTROL) and $8000) = 0 then Exit;   // Ctrl not held
   case aMsg.wParam of
      Ord('A'), Ord('C'), Ord('V'), Ord('X'), Ord('Z'): ;   // clipboard / edit keys
   else
      Exit;
   end;

   hTelnet := tr4w_WindowsArray[tw_TELNETWINDOW_INDEX].WndHandle;
   if hTelnet = 0 then Exit;
   if aMsg.hwnd = hTelnet then
      begin
      Result := True;
      end
   else if IsChild(hTelnet, aMsg.hwnd) then
      begin
      Result := True;
      end;
end;

procedure RunOptionsDialog(f: CFGFunc);
begin
  CommandsFilter := f;
  // tDialogBox(61, @SettingsDlgProc2);
  CreateModalDialog(390, 250, tr4whandle, @SettingsDlgProc2, 0);
end;

procedure OpenUrl(url: PChar);
var
 // lpcbValue: DWORD;
 // phkResult: hkey;
  sURI: string;
begin
  // This code no longer works so just do the SHellExecute
  {lpcbValue := SizeOf(TempBuffer2);

  if RegOpenKeyEx(HKEY_CLASSES_ROOT, 'http\shell\open\command', 0,
    KEY_ALL_ACCESS, phkResult) = ERROR_SUCCESS then
  begin
    RegQueryValueEx(phkResult, nil, nil, nil, @TempBuffer2, @lpcbValue);
    RegCloseKey(phkResult);

    for lpcbValue := 0 to SizeOf(TempBuffer2) - 2 do
      if TempBuffer2[lpcbValue] = '"' then
        if TempBuffer2[lpcbValue + 1] = ' ' then
          TempBuffer2[lpcbValue + 1] := #0;

    Format(wsprintfBuffer, '%s "%s"', TempBuffer2, url);

    WinExec(wsprintfBuffer, SW_SHOWNORMAL);
  end
  else
     begin}
  sURI := TIDURI.URLEncode(url);
  ShellExecute(0, 'open', PChar(sURI), nil, nil, SW_SHOWNORMAL);
  { end;}
  //RunExplorer(url);
end;

function GetAddMultBand(Mult: TAdditionalMultByBand; Band: BandType): BandType;
begin
  case Mult of
    dmbbDefauld: Result := Band;
    dmbbAllBand: Result := AllBands;
  end;

end;

function DeviceIoControlHandler
  (
  code: ULONG;
  pBuffer: PChar;
  InputBufferLength:
  ULONG; OutputBufferLength:
  ULONG; pOutputLength: PULONG
  ): Cardinal;

var
  store_count: DWORD;
  data_ptr: PUCHAR;
  data: UCHAR;
  adr: PUCHAR;
begin
  asm
 mov eax,Code // ???. ?????????, ??? ?? ??? ? ??? ??????.

 cmp eax,IOCTL_READ_PORTS // ?????? ????????? LPT-?????
 jz @@loc_read_port
 cmp eax,IOCTL_WRITE_PORTS // ?????? ? ???????? LPT-?????
 jz @@loc_write_port
 mov eax,0//STATUS_NOT_IMPLEMENTED // ????????????????? ??? ???????
 ret

 // ?????? ?? ????????? ????? LPT
@@loc_read_port:
 mov eax,InputBufferLength // ????? ????????? ?????? ?????? ???? ????? ????? ????????
 cmp eax,OutputBufferLength
 jnz @@loc_fault_ioctl

 and eax,0FFFEH // ????? ?????????? ??? ?????-??????
 mov store_count,eax
 cmp eax,0 // ????????? ?????
 jz @@loc_fault_ioctl

 mov eax,pBuffer
 mov data_ptr,eax

@@in_loop: // ???? ????? ??????
 push ebx
 push edx
 mov ebx,data_ptr
 xor eax,eax
 mov al,BYTE ptr [ebx] // ?????? ???? -- ????? ????? ? ???????? ????????
 inc ebx
 mov data_ptr,ebx
 mov ah,al
 shr al,1
 shr al,1
 shr al,1
 shr al,1 // al -- ????? ????? LPT -- 1,2 ??? 3
 and al,3
 mov edx,3BCH // LPT1
 cmp al,1
 jz @@1
 mov edx,378H // LPT2
 cmp al,2
 jz @@1
 mov edx,278H // LPT3
 @@1:
 mov al,ah
 mov ah,0
 and al,7 // ???????? ???????? LPT -- 0..7
 add edx,eax // ???? ????? + ???????? ????????
 mov adr,edx
 pop edx
 pop ebx

// invoke READ_PORT_UCHAR, adr // ?????? ????

 push ebx
 mov ebx,data_ptr
 mov BYTE ptr [ebx],0//al //????????? ??????????? ???? ? ??????
 inc ebx
 mov data_ptr,ebx
 pop ebx

 mov eax,store_count // ???????? ??????? ??????
 sub eax,2
 mov store_count,eax
 cmp eax,0
 jnz @@in_loop // ???? ?? ??? ???? ?????????? -- ?????.

 push ebx
 mov eax,OutputBufferLength
 mov ebx,pOutputLength // ????? ??????, ???????????? ??????? ?????????? ????????????.
 mov DWORD ptr [ebx],eax
 pop ebx

 mov eax,0//STATUS_SUCCESS
// ret
jmp @@all


 // ?????? ? ???????? ????? LPT
@@loc_write_port:
// mov eax,InputBufferLength
// and eax,0FFFEH // ????? ?????????? ??? ?????-??????
// mov store_count,eax
// cmp eax,0 // ????????? ?????!!!
// jz @@loc_fault_ioctl

 mov eax,pBuffer
 mov data_ptr,eax

@@out_loop: // ???? ?????? ??????
 push ebx
 push edx
 mov ebx,data_ptr
 inc ebx
 inc ebx
 xor eax,eax
 mov ax,word ptr [ebx] // ?????? ???? -- ????? ????? ? ???????? ????????
 inc ebx
 add ebx,4

 mov ah,al
 shr al,1
 shr al,1
 shr al,1
 shr al,1 // al -- ????? ????? LPT -- 1,2 ??? 3;
 and al,3
 mov edx,3BCH // LPT1
 cmp al,1
 jz @@2
 mov edx,378H // LPT2
 cmp al,2
 jz @@2
 mov edx,278H // LPT3
 @@2:
 mov al,ah
 mov ah,0
 and al,7 // ???????? ???????? LPT -- 0..7
 add edx,eax // ???? ????? + ???????? ????????
 mov adr,edx

 mov al,BYTE ptr [ebx] // ???? ??????
 mov data,al
 inc ebx
 mov data_ptr,ebx

 pop edx
 pop ebx

// invoke WRITE_PORT_UCHAR, adr, data // ????? ? ????

 mov eax,store_count // ???????? ??????? ??????
 sub eax,2
 mov store_count,eax
 cmp eax,0
 jnz @@out_loop // ???? ?? ??? ???? ?????????? -- ?????.

 mov eax,0//STATUS_SUCCESS
 ret

@@loc_fault_ioctl:
 mov eax,0//STATUS_UNSUCCESSFULL
 ret

@@all:
  end;
end;

function CreateToolTip(Control: HWND; Text: PChar): HWND;
const
  TOOLTIPS_CLASS = 'tooltips_class32';
  TTS_ALWAYSTIP = $01;
  TTS_NOPREFIX = $02;
  TTS_BALLOON = $40;
  TTF_SUBCLASS = $0010;
  TTF_TRANSPARENT = $0100;
  TTF_TRACK = $0020;
  TTF_CENTERTIP = $0002;
  TTF_ABSOLUTE = $0080;
  TTM_ADDTOOL = $0400 + 4;   // TTM_ADDTOOLA (ANSI). $0400+50 is TTM_ADDTOOLW, which reads our ANSI PChar as UTF-16 -> garbage/CJK.
  TTM_SETTITLE = (WM_USER + 32);
  ICC_WIN95_CLASSES = $000000FF;

var
  ti: TOOLINFO;
begin
  Result := CreateWindow(TOOLTIPS_CLASS, nil, WS_POPUP or TTS_NOPREFIX
    {or TTS_BALLOON } or TTS_ALWAYSTIP, 100, 100, 100, 100, Control, 0,
    hInstance,
    nil);
  if Result <> 0 then
  begin
    SetWindowPos(Result, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOACTIVATE or SWP_NOMOVE
      or SWP_NOSIZE);
    Windows.ZeroMemory(@ti, SizeOf(ti));
    ti.cbSize := SizeOf(ti);
    //ti.uFlags := 0;//TTF_ABSOLUTE or TTF_TRACK;
    ti.uFlags := {TTF_CENTERTIP or }TTF_TRANSPARENT or TTF_SUBCLASS;
    ti.HWND := Control;
    ti.lpszText := Text;
    Windows.GetClientRect(Control, ti.rect);
    SendMessage(Result, TTM_ADDTOOL, 0, integer(@ti));
  end;
end;

{$IF MORSERUNNER}

function GetMorseRunnerWindow: boolean;
begin
  Result := False;
  MorseRunnerWindow := Windows.FindWindow('TMainForm', 'Morse Runner');
  if MorseRunnerWindow = 0 then
    Exit;
  MorseRunnerWindowsCounter := 0;
  EnumChildWindows(MorseRunnerWindow, @EnumMorseRunnerChildProc, 0);
end;

function EnumMorseRunnerChildProc(wnd: HWND; l: lParam): BOOL; stdcall;
begin
  Windows.GetClassName(wnd, wsprintfBuffer, SizeOf(wsprintfBuffer));
  if Windows.lstrcmp(wsprintfBuffer, 'TEdit') = 0 then
  begin
    if MorseRunnerWindowsCounter = 0 then
      MorseRunner_MyCallsign := wnd;
    if MorseRunnerWindowsCounter = 1 then
      MorseRunner_Number := wnd;
    if MorseRunnerWindowsCounter = 2 then
      MorseRunner_RST := wnd;
    if MorseRunnerWindowsCounter = 3 then
      MorseRunner_Callsign := wnd;
    inc(MorseRunnerWindowsCounter);
  end;
  Result := True;

end;

{$IFEND}

procedure RunPlugin(PluginNumber: integer);
var
  CreatedReport: PChar;
  MakeRescore, ReLoadLog: boolean;
  module: HWND;
  TempFunc: Tmain;
begin
  Format(TempBuffer1, '%sPlugins\%s', TR4W_PATH_NAME, PluginsArray[PluginNumber
    - 10700]);
  module := LoadLibrary(TempBuffer1);
  TempFunc := GetProcAddress(module, 'main');
  CreatedReport := nil;
  ReLoadLog := False;
  MakeRescore := False;
  TempFunc(TR4W_LOG_FILENAME, CreatedReport, ReLoadLog, MakeRescore,
    ExchangeInformation, ActiveExchange, 0, 0, 0);
  if ReLoadLog then
    LoadinLog;

  if CreatedReport <> nil then
  begin
    PreviewFileNameAddress := CreatedReport; //TR4W_CFG_FILENAME;
    FilePreview;
  end;

  FreeLibrary(module);

end;

procedure LoadInPlugins();
label
  1, Next;
var
  lpFindFileData: TWIN32FindData;
  hFindFile: HWND;
  module: HWND;
  TempFunc: Ttr4wGetPlugin;
  pop: HMENU;
const
  MAXLOADEDPLUGINS = 10;
begin
  Format(TempBuffer1, '%sPlugins\tr4w*.dll', TR4W_PATH_NAME);

  hFindFile := Windows.FindFirstFile(TempBuffer1, lpFindFileData);
  if hFindFile <> INVALID_HANDLE_VALUE then
    goto 1
  else
    Exit;

  Next:
  if FindNextFile(hFindFile, lpFindFileData) then
  begin
    1:
    Format(TempBuffer1, '%sPlugins\%s', TR4W_PATH_NAME,
      lpFindFileData.cFileName);

    module := LoadLibrary(TempBuffer1);
    TempFunc := GetProcAddress(module, 'tr4wGetPlugin');
    if @TempFunc <> nil then
    begin
      if LoadedPlugins = 0 then
      begin
        pop := CreatePopupMenu;
        Windows.InsertMenu(tr4w_main_menu, menu_exit, MF_BYCOMMAND or MF_POPUP,
          pop, 'Plugins');
      end;
      inc(LoadedPlugins);
      Windows.AppendMenu(pop, MF_STRING, 10700 + LoadedPlugins, TempFunc());
      Windows.lstrcat(PluginsArray[LoadedPlugins], lpFindFileData.cFileName);
    end;
    FreeLibrary(module);
    goto Next;
  end;
  Windows.FindClose(hFindFile);
  if LoadedPlugins > 0 then
    Windows.InsertMenu(tr4w_main_menu, menu_exit, MF_BYCOMMAND or MF_SEPARATOR,
      0, nil);

end;

procedure RichEditOperation(Load: boolean);
begin

  if Load then
  begin
    if RichEditObject.reLibModule = 0 then
    begin
      RichEditObject.reLibModule := Windows.LoadLibrary('RICHED32.DLL');
    end;
    inc(RichEditObject.reUsers);
  end
  else
  begin
    dec(RichEditObject.reUsers);
    if RichEditObject.reUsers = 0 then
    begin
      FreeLibrary(RichEditObject.reLibModule);
      RichEditObject.reLibModule := 0;
    end;
  end;

end;

procedure OpenStationInformationWindow(dwInitParam: lParam);
begin
  CreateModalDialog(187, 260, tr4whandle, @CreateCabrilloDlgProc, dwInitParam);
end;

procedure OpenListOfMessages;
begin
  CreateModalDialog(397, 177, tr4whandle, @AltPDlgProc, 0);
end;

procedure RenameCommand(Old, New: PChar);
begin
  if GetPrivateProfileString(_COMMANDS, Old, nil, TempBuffer1,
    SizeOf(TempBuffer1), TR4W_INI_FILENAME) = 0 then
    Exit;
  Windows.WritePrivateProfileString(_COMMANDS, Old, nil, TR4W_INI_FILENAME);
  Windows.WritePrivateProfileString(_COMMANDS, New, TempBuffer1,
    TR4W_INI_FILENAME);
end;

procedure RenameCommands();
begin
  RenameCommand('DVP ENABLE', 'DVK ENABLE');
  RenameCommand('DVP PATH', 'DVK PATH');
  RenameCommand('DVP RECORDER', 'DVK RECORDER');
end;

procedure PTTOn;
label
  DrawPTTLabel;
var
  // hand : HWND;
  TempPTTValue: Byte;
  TempPortInterface: PortInterface;
  TempByte: Byte;
begin
  DebugMsg('Enter MainUnit.PTTOn');
  if not PTTEnable then
  begin

    if ActiveRadioPtr.tKeyerPort in [Parallel1..Parallel3] then
      if DriverIsLoaded() then
      begin
        TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
        DriverBitOperation(TempByte, STROBE_SIGNAL, boSet1);
        SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);
      end;

    Exit;
  end;

  begin
    if wkTurnPTT(True) then
      goto DrawPTTLabel;
    if tPTTVIACAT(True) then
      goto DrawPTTLabel;
    TempPortInterface := tGetPortType(ActiveRadioPtr.tKeyerPort);
    if TempPortInterface <> NoInterface then
    begin
      if TempPortInterface = SerialInterface then
      begin
        TempPTTValue := 0;
        if ActiveRadioPtr.tr4w_keyer_rts_state = RtsDtr_PTT then
          TempPTTValue := SETRTS;
        if ActiveRadioPtr.tr4w_keyer_DTR_state = RtsDtr_PTT then
          TempPTTValue := SETDTR;

        if TempPTTValue = 0 then
          Exit;
        if ActiveRadioPtr.tKeyerPortHandle <> INVALID_HANDLE_VALUE then
        begin
          TREscapeCommFunction(ActiveRadioPtr.tKeyerPortHandle, TempPTTValue);
          goto DrawPTTLabel;
        end;
        Exit;
      end;

      if not DriverIsLoaded() then
        Exit;

      TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
      DriverBitOperation(TempByte, STROBE_SIGNAL, boSet1);
      DriverBitOperation(TempByte, PTT_SIGNAL, boSet1);
      // TempByte := TempByte or BIT0; //1pin (Inverted)
      // TempByte := TempByte or BIT2; //16pin
      SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);

      DrawPTTLabel:
      logger.debug('Entering Main.PTTOn');
      ActiveRadioPtr.tPTTStatus := PTT_ON;
      PTTStatusChanged;

      Sleep(PTTTurnOnDelay);
    end;
  end;
end;

procedure PTTOff;
label
  DrawPTTLabel;
var
  PTT_value: Byte;
  TempPortInterface: PortInterface;
  TempByte: Byte;
begin
  DebugMsg('Enter MainUnit.PTTOff');
  if not PTTEnable then
  begin
    if ActiveRadioPtr.tKeyerPort in [Parallel1..Parallel3] then
      if DriverIsLoaded() then
      begin
        TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
        DriverBitOperation(TempByte, STROBE_SIGNAL, boSet0);
        SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);
      end;

    Exit;

  end;
  if IsCWByCATActive(ActiveRadioPtr) then // ny4i Issue 131
  begin
    DEBUGMsg('Stopping CW from PTTOff');
    ActiveRadioPtr^.StopSendingCW;
    goto DrawPTTLabel; // Fix this goto...Put the code below in an IF... TODO
  end;
  if wkTurnPTT(False) then
    goto DrawPTTLabel;
  if tPTTVIACAT(False) then
    goto DrawPTTLabel;
  TempPortInterface := tGetPortType(ActiveRadioPtr.tKeyerPort);
  if TempPortInterface <> NoInterface then
  begin
    if TempPortInterface = SerialInterface then
    begin
      PTT_value := 0;
      if ActiveRadioPtr.tr4w_keyer_rts_state = RtsDtr_PTT then
        PTT_value := CLRRTS;
      if ActiveRadioPtr.tr4w_keyer_DTR_state = RtsDtr_PTT then
        PTT_value := CLRDTR;
      if PTT_value = 0 then
        Exit;

      if ActiveRadioPtr.tKeyerPortHandle <> INVALID_HANDLE_VALUE then
      begin
        TREscapeCommFunction(ActiveRadioPtr.tKeyerPortHandle, PTT_value);
        goto DrawPTTLabel;
      end;
      Exit;
    end;

    if not DriverIsLoaded() then
      Exit;

    TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
    DriverBitOperation(TempByte, STROBE_SIGNAL, boSet0);
    DriverBitOperation(TempByte, PTT_SIGNAL, boSet0);
    SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);

    DrawPTTLabel:
    ActiveRadioPtr.tPTTStatus := PTT_OFF;
    PTTStatusChanged;

  end;
end;

procedure DebugRadioTempBuffer(sDecorator: string; var bRay: array of char);
// ny4i Added in Issue 145
{$IF NEWER_DEBUG}
var
  i: integer;
  s: string;
  Buf: array[0..100 * 2] of Char;
  nLen: integer;
{$IFEND}
begin
{$IF NEWER_DEBUG}
  // Only do this stuff if the log level is set right (future change) ny4i
  nLen := Ord(bRay[0]);
  BinToHex(@bRay[1], Buf, nLen);
  Buf[(nLen * 2) - 2] := #0;
  DebugMsg(sDecorator + ': ' + Buf);
{$IFEND}
end;

procedure CreateLogfile(aLine: string);
var
  aFileName: string;
  myFile: TextFile;
  aFilePath: string;
begin
  try
    //aLine := 'The line which you want to print. You can change this line dynamically by passing aLine as parameter to CreateLogfile function';
    aFileName := 'TR4WLogfile_' + FormatDateTime('dd-mm-yyyy', Now) + '.log';
    aFilePath := aFileName;
    AssignFile(myFile, aFilePath);
    try
      if FileExists(aFilePath) then
        Append(myFile)
      else
        Rewrite(myFile);
      WriteLn(myFile, FormatDateTime('dd-mmm-yyyy hh:nn:ss.zzz', Now) + ': ' +
        ALine);
      Flush(myFile);
    except
    end;
  finally
    CloseFile(myFile);
  end;
end;
{--------------------------------------------------------------------
 We always write to the Logger facility. If NEWER_DEBUG is set, we also write to the TELNET window
}

procedure DebugMsg(s: string);
{$IF NEWER_DEBUG}
var
  formattedDate: string;
  bytesToWrite: integer;
  first: boolean;
{$IFEND}
begin
  if Assigned(logger) then
  begin
    logger.Debug(s);
  end;
{$IF NEWER_DEBUG}
  // Switched to write a file

  first := true;
  LongTimeFormat := 'hh nn ss (zzz)';
  DateTimeToString(formattedDate, 'tt', Now);
  if length(s) > 60 then
  begin
    while Length(s) > 0 do
    begin
      bytesToWrite := min(length(s), 60);
      if first then
      begin
        AddStringToTelnetConsole(PChar('[' + ' ' + '] ' +
          AnsiLeftStr(s, bytesToWrite)), tstSend);
        first := false;
      end
      else
      begin
        AddStringToTelnetConsole(PChar('[' + formattedDate + '] ' +
          AnsiLeftStr(s, bytesToWrite)), tstSend);
      end;
      s := AnsiRightStr(s, length(s) - bytesToWrite);
    end;
  end;

  AddStringToTelnetConsole(PChar('[' + formattedDate + '] ' + s), tstSend);
{$IFEND}

end;

// These two functions are overloaded so on can call without any parameters to
// test the active radio. Or pass a ptr to the radio of one's choosing. If the
// radio pointer is nil, then it just uses the active radio.

function IsCWByCATActive(theRadio: RadioPtr): boolean; // ny4i Issue # 111
var
  ptr: RadioPtr;
begin
  if not Assigned(theRadio) then
  begin
    ptr := ActiveRadioPtr;
  end
  else
  begin
    ptr := theRadio;
  end;
  Result := (ptr.CWByCAT) and
    (ptr.RadioModel in RadioSupportsCWByCAT);
end;

function IsCWByCATActive: boolean; // ny4i Issue # 111
begin
  Result := IsCWByCatActive(ActiveRadioPtr);
  // Call base function with active radio // ny4i Issue 111
end;

// ADIFDateStringToQSOTime, ADIFTimeStringToQSOTime moved to uADIF.pas (Issue #887).

function GetTR4WBandFromNetworkBand(band: TRadioBand): BandType;
begin
  case band of
    rbNone: Result := NoBand;
    rb160m: Result := Band160;
    rb80m: Result := Band80;
    //   rb60m: Result := Band60;
    rb40m: Result := Band40;
    rb30m: Result := Band30;
    rb20m: Result := Band20;
    rb17m: Result := Band17;
    rb15m: Result := Band15;
    rb12m: Result := Band12;
    rb10m: Result := Band10;
    rb6m: Result := Band6;
    rb4m: Result := NoBand;
    rb2m: Result := Band2;
    rb70cm: Result := Band432;
  else
    begin
      logger.Error('[GetTR4WBandFromNetworkBand] band is invalid - Ord is %d',
        [Ord(band)]);
    end;
  end; // of case

end;

function GetRadioBandFromBandType(band: BandType): TRadioBand;
begin

  case band of
    NoBand: Result := rbNone;
    Band160: Result := rb160m;
    Band80: Result := rb80m;
    //    Band60: Result := rb60m;
    Band40: Result := rb40m;
    Band30: Result := rb30m;
    Band20: Result := rb20m;
    Band17: Result := rb17m;
    Band15: Result := rb15m;
    Band12: Result := rb12m;
    Band10: Result := rb10m;
    Band6: Result := rb6m;
    Band2: Result := rb2m;
    Band432: Result := rb70cm;
  else
    begin
      logger.Error('[GetRadioBandFromBandType] band is invalid - Ord is %d',
        [Ord(band)]);
    end;
  end; // of case

end;

procedure GetTRModeAndExtendedModeFromNetworkMode(netMode: TRadioMode; var mode:
  ModeType; var extMode: extendedModeType);
begin
  case netMode of
    rmNone:
      begin
      end;
    rmLSB:
      begin
        extMode := eLSB;
        mode := Phone;
      end;
    rmUSB:
      begin
        extMode := eUSB;
        mode := Phone;
      end;
    rmCW:
      begin
        extMode := eCW;
        mode := CW;
      end;
    rmFM:
      begin
        extMode := eFM;
        mode := FM;
      end;
    rmAM:
      begin
        extMode := eAM;
        mode := Phone;
      end;
    rmData:
      begin
        extMode := eData;
        mode := Digital;
      end;
    rmCWRev:
      begin
        extMode := eCW_R;
        mode := CW;
      end;
    rmDATARev:
      begin
        extMode := eData_R;
        mode := Digital;
      end;
    rmFSK:
      begin
        extMode := eRTTY;
        mode := Digital;
      end;
    rmAFSK:
      begin
        extMode := eRTTY;
        mode := Digital;
      end;
    rmPSK:
      begin
        extMode := ePSK31;
        mode := Digital;
      end;
    rmPSKRev:
      begin
        extMode := ePSK31;
        mode := Digital;
      end;
    rmFSKRev:
      begin
        extMode := eRTTY_R;
        mode := Digital;
      end;
    rmDV:
      begin
        extMode := eDStar;
        mode := Phone;
      end;
  else
    begin
      logger.Warn('[GetTRModeAndExtendedModeFromNetworkMode] Unhandled netMode from Net Object - Ord = %d', [Ord(netMode)]);
    end;
  end; // of case
end;

function GetModeFromExtendedMode(extMode: ExtendedModeType): ModeType;
begin
  //ExtendedModeStringArray : array[ExtendedModeType] of string = ('CW', 'RTTY', 'FT8', 'FT4', 'JT65', 'PSK31', 'PSK63', 'SSB', 'FM', 'AM', 'MFSK', 'JS8', 'USB', 'SSB');
  case extMode of
    eCW, eCW_R: Result := CW;
    eSSB, eAM, eAM_N, eUSB, eLSB:
      Result := Phone;
    eFM, eFM_N, eDstar, eC4FM, eWFM: Result := FM;
  else
    Result := Digital;
  end;
end;

function DigitsIn(n: smallInt): byte;
// byte is 0 to 255 so more than enough, smallInt is -32768..32767
var
  isNegative: boolean;
begin
  isNegative := false;
  if n < 0 then
  begin
    isNegative := true;
    n := n * -1;
  end;
  if n > 9999 then
    Result := 5
  else if n > 999 then
    Result := 4
  else if n > 99 then
    Result := 3
  else if n > 9 then
    Result := 2
  else
    Result := 1;

  if isNegative then
    Result := Result + 1;
end;

(*----------------------------------------------------------------------------*)
function AskConvertLog(sVersion: string): boolean;
{ Converts a log file from a prior binary format to the current v1.7 format.
  Supported source versions: v1.5, v1.6.
  For each source version there is a corresponding frozen record type:
    v1.5 -> ContestExchangev1_5  (no ExtMode, no ExchString, no id)
    v1.6 -> ContestExchangev1_6  (no id field)
  The original log is renamed to <logname>.<vN_N> and a read-only backup
  copy is created as <logname>-<version>.bkup before any conversion begins.
  The id field is left blank after conversion. }
var
  OldFile, NewFile, fName, sVersionTag: string;
  fileSetCode, attrs: integer;
  oldFH_v1_6: file of ContestExchangev1_6;
  oldFH_v1_5: file of ContestExchangev1_5;
  newFH: file of ContestExchange;
  headerFH: file of TLogHeader;
  oldRXData_v1_6: ContestExchangev1_6;
  oldRXData_v1_5: ContestExchangev1_5;
  newRXData: ContestExchange;
begin
  Result := false;

  logger.Info('AskConvertLog: converting log from version ' + sVersion + ' to ' + LOGVERSION);

  if (sVersion <> 'v1.5') and (sVersion <> 'v1.6') then
     begin
     ShowMessage(PChar('Cannot convert log version ' + sVersion + ' to ' + LOGVERSION + '. Unknown source version.'));
     logger.Fatal('AskConvertLog: unknown source version: ' + sVersion);
     Exit;
     end;

  { The general logic here is as follows:
    Read the log header and confirm the version differs from current.
    If the user agrees to convert, back up the original file, then
    rename it with a version-tagged extension so the conversion reads it. }
  if YesOrNo(0, PChar('This log is version ' + sVersion + '. Would you like to convert it to ' + LOGVERSION + '?')) = mrNo then
     begin
     logger.Fatal('User opted to not upgrade log format');
     Halt;
     end;

  NewFile := StrPas(TR4W_LOG_FILENAME) + '-' + sVersion + '.bkup';
  if not FileExists(TR4W_LOG_FILENAME) then
     begin
     ShowMessage(PChar(TC_LOGFILENOTFOUND));
     Exit;
     end;

  if FileExists(PChar(NewFile)) then
     begin
     attrs := FileGetAttr(NewFile);
     if attrs and faReadOnly > 0 then
        begin
        ShowMessage(PChar(TC_CANNOTCOPYLOGREADONLY));
        Exit;
        end;
     end;

  if not CopyFile(TR4W_LOG_FILENAME, PChar(NewFile), false) then
     begin
     ShowMessage(PChar(TC_CANNOTBACKUPLOG + StrPas(TR4W_LOG_FILENAME)));
     Exit;
     end;

  ShowMessage(PChar(TC_BACKUPCREATED));
  fileSetCode := FileSetAttr(NewFile, faReadOnly);
  if fileSetCode = 0 then
     begin
     logger.Info(NewFile + ' made into a read only file');
     end
  else
     begin
     ShowMessage(TC_CANNOTCOPYLOGREADONLY);
     Exit;
     end;

  // Rename the original log to TR4W_LOG_FILENAME + '.<vN_N>' (e.g. .v1_5, .v1_6, .v1_7)
  sVersionTag := StringReplace(sVersion, '.', '_', [rfReplaceAll]);
  OldFile := StrPas(TR4W_LOG_FILENAME) + '.' + sVersionTag;
  fName := StrPas(TR4W_LOG_FILENAME);
  if not RenameFile(fName, OldFile) then
     begin
     ShowMessage(PChar(TC_CANNOTRENAME + ' ' + fName + ' >>> ' + OldFile));
     Exit;
     end;

  //***
  // Original is backed up and renamed. Write the new v1.7 header and convert.
  //***

  AssignFile(headerFH, TR4W_LOG_FILENAME);
  ReWrite(headerFH);
  Write(headerFH, LogHeader);
  CloseFile(headerFH);

  if sVersion = 'v1.5' then
     begin
     // --- v1.5 to v1.7 ---
     // v1.5 has no ExtMode or ExchString fields; derive ExtMode from Mode
     // and use QTHString as a fallback for ExchString.
     AssignFile(oldFH_v1_5, OldFile);
     FileMode := fmOpenRead;
     Reset(oldFH_v1_5);
     AssignFile(newFH, TR4W_LOG_FILENAME);
     FileMode := fmOpenWrite;
     Reset(newFH);
     Seek(newFH, 1);
     Seek(oldFH_v1_5, 1);
     while not EOF(oldFH_v1_5) do
        begin
        Read(oldFH_v1_5, oldRXData_v1_5);
        ClearContestExchange(newRXData);
        newRXData.tSysTime := oldRXData_v1_5.tSysTime;
        newRXData.Band := oldRXData_v1_5.Band;
        newRXData.Mode := oldRXData_v1_5.Mode;
        newRXData.ceQSOID1 := oldRXData_v1_5.ceQSOID1;
        newRXData.ceQSOID2 := oldRXData_v1_5.ceQSOID2;
        newRXData.Frequency := oldRXData_v1_5.Frequency;
        newRXData.ceQSO_Deleted := oldRXData_v1_5.ceQSO_Deleted;
        newRXData.ceComputerID := oldRXData_v1_5.ceComputerID;
        newRXData.ceOperatorID := oldRXData_v1_5.ceOperatorID;
        newRXData.ceRecordKind := oldRXData_v1_5.ceRecordKind;
        newRXData.ceQSO_Skiped := oldRXData_v1_5.ceQSO_Skiped;
        newRXData.ceSendToServer := oldRXData_v1_5.ceSendToServer;
        newRXData.ceNeedSendToServerAE := oldRXData_v1_5.ceNeedSendToServerAE;
        newRXData.ceDupe := oldRXData_v1_5.ceDupe;
        newRXData.PostalCode_old := oldRXData_v1_5.PostalCode_old;
        newRXData.Prefix := oldRXData_v1_5.Prefix;
        newRXData.Callsign := oldRXData_v1_5.Callsign;
        newRXData.Age := oldRXData_v1_5.Age;
        newRXData.ceWasSendInQTC := oldRXData_v1_5.ceWasSendInQTC;
        newRXData.DomesticMult := oldRXData_v1_5.DomesticMult;
        newRXData.DXMult := oldRXData_v1_5.DXMult;
        newRXData.PrefixMult := oldRXData_v1_5.PrefixMult;
        newRXData.ZoneMult := oldRXData_v1_5.ZoneMult;
        newRXData.ceClass := oldRXData_v1_5.ceClass;
        newRXData.Precedence := oldRXData_v1_5.Precedence;
        newRXData.ceRadio := oldRXData_v1_5.ceRadio;
        newRXData.Check := oldRXData_v1_5.Check;
        newRXData.QTH := oldRXData_v1_5.QTH;
        newRXData.DXQTH := oldRXData_v1_5.DXQTH;
        newRXData.Radio := oldRXData_v1_5.Radio;
        newRXData.DomMultQTH := oldRXData_v1_5.DomMultQTH;
        newRXData.DomesticQTH := oldRXData_v1_5.DomesticQTH;
        newRXData.Name := oldRXData_v1_5.Name;
        newRXData.Power := oldRXData_v1_5.Power;
        newRXData.NumberReceived := oldRXData_v1_5.NumberReceived;
        newRXData.NumberSent := oldRXData_v1_5.NumberSent;
        newRXData.RSTSent := oldRXData_v1_5.RSTSent;
        newRXData.RSTReceived := oldRXData_v1_5.RSTReceived;
        newRXData.QTHString := oldRXData_v1_5.QTHString;
        newRXData.RandomCharsSent := oldRXData_v1_5.RandomCharsSent;
        newRXData.TenTenNum := oldRXData_v1_5.TenTenNum;
        newRXData.Chapter := oldRXData_v1_5.Chapter;
        newRXData.ceClearDupeSheet := oldRXData_v1_5.ceClearDupeSheet;
        newRXData.ceSearchAndPounce := oldRXData_v1_5.ceSearchAndPounce;
        newRXData.Prefecture := oldRXData_v1_5.Prefecture;
        newRXData.InhibitMults := oldRXData_v1_5.InhibitMults;
        newRXData.Zone := oldRXData_v1_5.Zone;
        newRXData.NameSent := oldRXData_v1_5.NameSent;
        newRXData.Kids := oldRXData_v1_5.Kids;
        newRXData.ceContest := oldRXData_v1_5.ceContest;
        newRXData.QSOPoints := oldRXData_v1_5.QSOPoints;
        newRXData.RandomCharsReceived := oldRXData_v1_5.RandomCharsReceived;
        newRXData.ceClearMultSheet := oldRXData_v1_5.ceClearMultSheet;
        newRXData.MP3Record := oldRXData_v1_5.MP3Record;
        newRXData.ceOperator := oldRXData_v1_5.ceOperator;
        // Derive ExtMode from Mode (v1.5 has no ExtMode field)
        if oldRXData_v1_5.Mode = CW then
           begin
           newRXData.ExtMode := eCW;
           end
        else if oldRXData_v1_5.Mode = Phone then
           begin
           newRXData.ExtMode := eSSB;
           end
        else if oldRXData_v1_5.Mode = Digital then
           begin
           newRXData.ExtMode := eRTTY;
           end;
        // Use QTHString as ExchString fallback (v1.5 has no ExchString field)
        newRXData.ExchString := oldRXData_v1_5.QTHString;
        // id (GUID) left blank; rescore will backfill if needed
        Write(newFH, newRXData);
        end;
     CloseFile(oldFH_v1_5);
     CloseFile(newFH);
     end
  else
     begin
     // --- v1.6 to v1.7 ---
     // v1.6 has no id field; id is left blank after conversion.
     AssignFile(oldFH_v1_6, OldFile);
     FileMode := fmOpenRead;
     Reset(oldFH_v1_6);
     AssignFile(newFH, TR4W_LOG_FILENAME);
     FileMode := fmOpenWrite;
     Reset(newFH);
     Seek(newFH, 1);
     Seek(oldFH_v1_6, 1);
     while not EOF(oldFH_v1_6) do
        begin
        Read(oldFH_v1_6, oldRXData_v1_6);
        ClearContestExchange(newRXData);
        newRXData.tSysTime := oldRXData_v1_6.tSysTime;
        newRXData.Band := oldRXData_v1_6.Band;
        newRXData.Mode := oldRXData_v1_6.Mode;
        newRXData.ceQSOID1 := oldRXData_v1_6.ceQSOID1;
        newRXData.ceQSOID2 := oldRXData_v1_6.ceQSOID2;
        newRXData.Frequency := oldRXData_v1_6.Frequency;
        newRXData.ceQSO_Deleted := oldRXData_v1_6.ceQSO_Deleted;
        newRXData.ceComputerID := oldRXData_v1_6.ceComputerID;
        newRXData.ceOperatorID := oldRXData_v1_6.ceOperatorID;
        newRXData.ceRecordKind := oldRXData_v1_6.ceRecordKind;
        newRXData.ceQSO_Skiped := oldRXData_v1_6.ceQSO_Skiped;
        newRXData.ceSendToServer := oldRXData_v1_6.ceSendToServer;
        newRXData.ceNeedSendToServerAE := oldRXData_v1_6.ceNeedSendToServerAE;
        newRXData.ceDupe := oldRXData_v1_6.ceDupe;
        newRXData.PostalCode_old := oldRXData_v1_6.PostalCode_old;
        newRXData.Prefix := oldRXData_v1_6.Prefix;
        newRXData.Callsign := oldRXData_v1_6.Callsign;
        newRXData.Age := oldRXData_v1_6.Age;
        newRXData.ceWasSendInQTC := oldRXData_v1_6.ceWasSendInQTC;
        newRXData.DomesticMult := oldRXData_v1_6.DomesticMult;
        newRXData.DXMult := oldRXData_v1_6.DXMult;
        newRXData.PrefixMult := oldRXData_v1_6.PrefixMult;
        newRXData.ZoneMult := oldRXData_v1_6.ZoneMult;
        newRXData.ExtMode := oldRXData_v1_6.ExtMode;
        newRXData.ExchString := oldRXData_v1_6.ExchString;
        newRXData.ceClass := oldRXData_v1_6.ceClass;
        newRXData.Precedence := oldRXData_v1_6.Precedence;
        newRXData.ceRadio := oldRXData_v1_6.ceRadio;
        newRXData.Check := oldRXData_v1_6.Check;
        newRXData.QTH := oldRXData_v1_6.QTH;
        newRXData.DXQTH := oldRXData_v1_6.DXQTH;
        newRXData.Radio := oldRXData_v1_6.Radio;
        newRXData.DomMultQTH := oldRXData_v1_6.DomMultQTH;
        newRXData.DomesticQTH := oldRXData_v1_6.DomesticQTH;
        newRXData.Name := oldRXData_v1_6.Name;
        newRXData.Power := oldRXData_v1_6.Power;
        newRXData.NumberReceived := oldRXData_v1_6.NumberReceived;
        newRXData.NumberSent := oldRXData_v1_6.NumberSent;
        newRXData.RSTSent := oldRXData_v1_6.RSTSent;
        newRXData.RSTReceived := oldRXData_v1_6.RSTReceived;
        newRXData.QTHString := oldRXData_v1_6.QTHString;
        newRXData.RandomCharsSent := oldRXData_v1_6.RandomCharsSent;
        newRXData.TenTenNum := oldRXData_v1_6.TenTenNum;
        newRXData.Chapter := oldRXData_v1_6.Chapter;
        newRXData.ceClearDupeSheet := oldRXData_v1_6.ceClearDupeSheet;
        newRXData.ceSearchAndPounce := oldRXData_v1_6.ceSearchAndPounce;
        newRXData.Prefecture := oldRXData_v1_6.Prefecture;
        newRXData.InhibitMults := oldRXData_v1_6.InhibitMults;
        newRXData.Zone := oldRXData_v1_6.Zone;
        newRXData.NameSent := oldRXData_v1_6.NameSent;
        newRXData.Kids := oldRXData_v1_6.Kids;
        newRXData.ceContest := oldRXData_v1_6.ceContest;
        newRXData.QSOPoints := oldRXData_v1_6.QSOPoints;
        newRXData.RandomCharsReceived := oldRXData_v1_6.RandomCharsReceived;
        newRXData.ceClearMultSheet := oldRXData_v1_6.ceClearMultSheet;
        newRXData.MP3Record := oldRXData_v1_6.MP3Record;
        newRXData.ceOperator := oldRXData_v1_6.ceOperator;
        // id left blank — not present in v1.6 files
        Write(newFH, newRXData);
        end;
     CloseFile(oldFH_v1_6);
     CloseFile(newFH);
     end;

  Result := true;
end;
(*----------------------------------------------------------------------------*)
// NY4I
// Note we cache last returned one to avoid a subsequent lookup since the
// contest most likely did not change. An example is an ADIF file import.

// GetContestByADIFName moved to uADIF.pas (Issue #887).

procedure SetExtendedModeFromMode(RData: ContestExchange);
begin
  if RData.ExtMode = eNoMode then
  begin
    if RData.Mode = PHONE then
      // We cannot really pick eUSB here. It depends upon the radio mode
    begin
      RData.ExtMode := eSSB;
      // Maybe call someting to guess based on the freqwuency but set it ahead of time
    end
    else if RData.Mode = CW then
    begin
      RData.ExtMode := eCW;
    end
    else if RData.Mode = Digital then
    begin
      RData.ExtMode := eDATA;
    end
    else if RData.Mode = FM then
    begin
      RData.ExtMode := eFM;
    end;
  end;

end;

procedure ProcessImportedSRX_String(fieldValue: string; var exch:
  ContestExchange);
begin
  case exch.ceContest of
    ARRLFIELDDAY, WINTERFIELDDAY:
      begin
        // parse SRX_STRING of 1A EPA into class 1A and QTHString of EPA
        logger.debug('Calling ProcessClassAndDomesticOrDXQTHExchange from ProcessImportedSRX_String');
        ProcessClassAndDomesticOrDXQTHExchange(fieldValue, exch);
        exch.exchString := fieldValue;
        if length(exch.DomesticQTH) = 0 then
        begin
          exch.DomesticQTH := exch.QTHString;
        end;
      end;
  end; // case
end;

function IsWin64: Boolean;
var
  IsWow64Process: function(hProcess: THandle; var Wow64Process: BOOL): BOOL;
  stdcall;
  Wow64Process: BOOL;
begin
  Result := False;
  IsWow64Process := GetProcAddress(GetModuleHandle(Kernel32), 'IsWow64Process');
  if Assigned(IsWow64Process) then
  begin
    if IsWow64Process(GetCurrentProcess, Wow64Process) then
    begin
      Result := Wow64Process;
    end;
  end;
end;

function ConvertPortTypeToCOMString(port: PortType): string;
begin
  Result := '';
  if IntegerBetween(Ord(port), 1, 20) then
  begin
    Result := 'COM' + IntToStr(Ord(port));
  end
  else if Ord(port) = 21 then
  begin
    Result := 'socket';
  end
  else if IntegerBetween(Ord(port), 22, 25) then
  begin
    Result := 'LPT' + IntToStr(Ord(port) - 21);
  end;
end;
{
procedure SelectFileOfFolder(Parent: HWND; FileName: PChar; Mask: PChar; SelectType: CFGType);
begin
 SelectedFileName := FileName;
 SelectedFileNameMask := Mask;
 SelectedFileType := SelectType;
 if SelectType = ctFileName then SelectedFileNameFlag := DDL_ARCHIVE or DDL_READWRITE or DDL_DIRECTORY;
 if SelectType = ctDirectory then SelectedFileNameFlag := DDL_ARCHIVE or DDL_EXCLUSIVE or DDL_DIRECTORY;
 tDialogBox(77, @SelectFileDlgProc);
end;
}
begin
{$IF tDebugMode}
  SetNewMemMgr;
  //Msidle.dll GetIdleMinutes(
{$IFEND}

end.

