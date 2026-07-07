         {
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LogStuff;

{ This unit has a bunch of subroutines that are generic for the logging
  program.  They are stuck here because they can stand alone, or need
  very little VAR interfacing.  This is so they will be out of the way
  and be common to all programs.                                      }

{$IMPORTEDDATA OFF}
interface

uses {Dos, Printer,}Tree,
  utils_text,
  uRussiaOblasts,
  uCallSignRoutines,
  uCTYDAT,
  uCommctrl,
  TF,
  VC,
  Math,
  utils_file,
  //Country9,
  ZoneCont,
  LogSCP, {Crt,}
  LogWind,
  LogCW,
  LogDupe,
  LogGrid,
  //  Help,
  LogK1EA,
  LOGDVP,
  LogDom, {SlowTree,}
  LogNet,
  LogRadio,
  Messages,
  idUDPClient, // ny4i 4.44.9
  idGlobal, // ny4i 4.44.9
  SysUtils, // ny4i 4.44.9
  StrUtils, // 4.90.11
  PerlRegEx,
  uMults,
  Windows
  ;

var
  MRC: Str10;
  MyCo: string[14];

const
  SSPrec: set of Char = ['A', 'B', 'Q', 'U', 'M', 'S'];

  { Control Byte Constants for Multi-Multi communications }

  MultiMessageBufferSize = 32;

  MultiTalkMessage = 1; { TR6.75 - Supported by K1EANetwork }
  MultiPacketReceivedSpot = 2; { No longer used.  Uses 4 all the time }
  MultiPacketMessageToSend = 3;
  MultiPacketReceivedMessage = 4;
  MultiQSOData = 5; { TR6.75 - Supported by CT Network }
  MultiBandMapMessage = 6; { TR6.76 - Supported by CT Network }
  MultiTimeMessage = 7; { TR6.75 - Reception only from CT Network }
  MultiInformationMessage = 8;
  MultiConfigurationMessage = 9; { Not supported on CT Network }

  DefaultTimeToLive = 30;
  LookForDupes = True;
  DoNotLookForDupes = not LookForDupes;

  ProcessedMultiMessageBufferLength = 256;

  ChampionshipRFPointsArray: array[1..49] of Byte =
    (

    11, 12, 13, 14, 16, 20, 25,
    12, 11, 12, 13, 15, 19, 23,
    13, 12, 11, 12, 14, 18, 21,
    14, 13, 12, 11, 12, 15, 18,
    16, 15, 14, 12, 11, 12, 14,
    20, 19, 18, 15, 12, 11, 12,
    25, 23, 21, 18, 14, 12, 11

    );

  ZeroZuluOffsetCQZoneArray: array[1..39] of Byte =
    (
    14,
    19,
    16,
    18,
    19,
    17,
    18,
    19,
    18,
    19,
    21,
    19,
    20,
    0,
    1,
    2,
    4,
    6,
    9,
    2,
    4,
    5,
    7,
    8,
    9,
    7,
    8,
    7,
    8,
    10,
    14,
    12,
    0,
    2,
    0,
    0,
    2,
    1,
    3

    );

  ZeroZuluOffsetITUZoneArray: array[1..66] of Byte =
    (
    14,
    16,
    17,
    18,
    19,
    16,
    18,
    19,
    19,
    17,

    19,
    19,
    21,
    19,
    21,
    20,
    23,
    1,
    2,
    4,

    4,
    5,
    6,
    7,
    8,
    9,
    1,
    2,
    3,
    4,

    5,
    6,
    7,
    8,
    9,
    1,
    1,
    3,
    3,
    4,

    5,
    5,
    6,
    8,
    9,
    0,
    1,
    2,
    6,
    8,

    9,
    0,
    3,
    7,
    9,
    12,
    2,
    8,
    10,
    11,

    13,
    13,
    13,
    10,
    10,
    22

    );

type

  FederalOkrugs =
    (
    UnKnownOkrug,
    DalneVostochnyiy,
    Privolzhskiy,
    SeveroZapadniy,
    Sibirskiy,
    Uralskiy,
    Centralniy,
    Yuzhniy
    );

  SSExchangeType = record
    Number: string[4];
    Check: string[2];
    Section: Str10;
    Prec: Char;
  end;

  RememberRecord = record
    Frequency: LONGINT;
    Band: BandType;
    Mode: ModeType;
  end;

  RememberRadioType = array[RadioOne..RadioTwo] of RememberRecord;

  HelloRecPtr = ^HelloRec;

  HelloRec = record
    ID: string[6];
    Greeting: string[6];
    NextRecord: HelloRecPtr;
  end;

  EntryArray = array[1..10] of Str20;

  QuickQSLKeyType = (NoQuickQSLKey,
    QuickKey1,
    QuickKey2);

  ParameterOkayModeType = (
    NoParameterOkayMode,
    Standard,
    QSLButDoNotLog,
    QSLAndLog);

  EntryName = (Unknown,
    Number,
    Precedence,
    Call,
    Check,
    Section,
    NumberPrecedence,
    CheckSection,
    NumberPrecedenceCheckSection);

  KeyHistoryRecord = record
    Key: Char;
    Time: Cardinal {TimeRecord};
  end;

  DirectionType = (DirectionDown, DirectionUp);

  TwoRadioAction = (CallPutUp,
    SpaceBarPressed,
    F1Pressed,
    F2Pressed,
    FootSwitchWasPressed,
    ReturnPressed,
    EscapePressed,
    ContactDone);

  DualingCQStates = (NoDualingCQs,
    DualGettingExchange,
    DualSendingCQ,
    DualSendingExchange,
    DualSendingQSL,
    SendingDupeMessage,
    WaitingForCallsignInput);

  DupeCheckSoundType =
    (
    DupeCheckNoSound,
    DupeCheckBeepIfDupe,
    DupeCheckGratsIfMult
    );

  ProcessedMultiMessageRecord = record
    Source: Byte;
    Serial: Byte;
    Check: integer;
  end;

  ProcessedMultiMessageBufferType = array[0..ProcessedMultiMessageBufferLength -
    1] of
    ProcessedMultiMessageRecord;

  ExchangeElementType = (eetUnknown, eetAlpha, eetNumber, eetMixed);

  ParserRecord = record
    prString: string[23];
    prType: ExchangeElementType;
    prInteger: integer;
  end;

  ParsedRecordType = record
    prTotalElements: Cardinal;
    prTotalNumbers: Cardinal;
    prTotalStrings: Cardinal;
    prNumbers: array[0..3] of Cardinal;
    prStrings: array[0..3] of array[0..31] of Char;
  end;

  // PaserArrayStatusType = array[0..3] of Byte;

  ParserArrayType = record
    paCount: integer;
    paStatus: array[0..3] of ExchangeElementType;
    paElements: array[0..3] of ParserRecord;
  end;

  MultiMessageMemoryRecord = record
    Message: string[100];
    TimeMark: Cardinal {TimeRecord};
    RetryCount: Byte;
    QSL: boolean;
    Warnings: Byte;
  end;

  MultiMessageListArrayType = array[0..MultiMessageBufferSize - 1] of
    MultiMessageMemoryRecord;
  MultiMessageListPointer = ^MultiMessageListArrayType;

const
  DupeCheckSoundTypeSA: array[DupeCheckSoundType] of PChar =
    (
    'NONE',
    'DUPE BEEP',
    'MULT FANFARE'
    );

  ParameterOkayModeTypeStringArray: array[ParameterOkayModeType] of PChar = (
    'NONE',
    'STANDARD',
    'QSL BUT DO NOT LOG',
    'QSL AND LOG'
    );

var
  ParserArray: ParserArrayType;
  ParsedRecord: ParsedRecordType;

  SSEx: SSExchangeType;

  //  _showstarttime                        : boolean;
  //  _networktest                          : boolean;

  AllCWMessagesChainable: boolean;
  AlwaysCallBlindCQ: boolean;
  //  AskIfContestOver                      : boolean = True;
  AutoAltDWindowString: Str20;
  AutoCallTerminate: boolean;
  AutoAltDEnable: boolean;
  AutoDisplayDupeQSO: boolean;
  AutoQSLCount: Byte {= 0};
  AutoQSLInterval: integer;
  AutoQSONumberDecrement: boolean;
  AutoSAPEnable: boolean;

  BandMapCallWindowEnable: boolean = True;
  BandMapInfoCall: CallString {= ''};
  BeepEvery10QSOs: boolean;
  BeSilent: boolean;

  CallAlreadySent: boolean;
  CallWindowString: CallString {string};
  tCallWindowStringIsDupe: boolean;
  CallWindowEmpty: boolean = True;
  CallsignIsPastedFromBandMap: boolean;
  CallsignIsTypedByOperator: boolean;

  CallsignICameBackTo: CallString;
  CheckLogFileSize: boolean;
  ColumnDupeSheetColor: boolean;
  ColumnDupeSheetEnable: boolean = False;
  ComputerID: Char { = CHR(0)};
  ComputerName: Str10 = 'New';
  ControlBreakStatus: boolean;
  CountryInformationFile: ShortString;

  DebugFlag: boolean;
  DEEnable: boolean = True;
  DefaultRST: Word;
  DisplayRefresh: integer = 1;
  //  DoingRescore                     : boolean; {KK1L: 6.71}
  DualingCQState: DualingCQStates {= NoDualingCQs};
  DupeCheckSound: DupeCheckSoundType = DupeCheckBeepIfDupe;
  DupeInfoCall: CallString;
  DupeInfoCallPrompt: CallString; {KK1L: 6.73}
  DupeSheetFileEnable: boolean;
  DVKPlaying: boolean;
  DVKStartTime: Cardinal {TimeRecord};

  EscapeDeletedCallEntry: CallString;
  EscapeDeletedExchangeEntry: Str40;
  EscapeExitsSearchAndPounce: boolean = True;
  ExchangeHasBeenSent: boolean;
  ExchangeErrorMessage: PChar;
  ExchangeErrorToken: Str40;   // Issue #1010: the offending exchange token, so the caller can place the caret right after it
  ExchangeMemoryFileEnable: boolean;
  ExchangeWindowString: Str40;
  ExternalLoggerAddress: string[255] = '127.0.0.1';
  ExternalLoggerEnabled: boolean = false;
  ExternalLoggerPort: integer = 52001;
  // In DXKeeper case, it is 52000 base port + 1

  FakePacket: boolean;
  FakeBandMap: boolean;
  FirstHelloRecord: HelloRecPtr;
  FirstMultiMessage: integer;
  FloppyFileSaveFrequency: integer;
  //  FloppyFileSaveName                    : ShortString = 'LOGBACK.TRW';
  ForcedEntry: boolean;
  {KK1L: 6.70 switch used in JCTRL2 to add comments to LOGCFG}

  GridMapCenter: GridString;

  InactiveRigCallingCQ: boolean;
  InitialExchangePutUp: boolean;
  InitialExchangeOverwrite: boolean; {KK1L: 6.70}
  InsertMode: boolean = True;
  IntercomFileenable: boolean;
  //  IntercomFileOpen                 : boolean;
  //  IntercomFileWrite                : Text;

  KeyHistory: KeyHistoryRecord;
  KeypadCWMemories: boolean;

  //   LastDeletedLogEntry             : Str160;
  tLastLogEntryIsDeleted: boolean;
  //  LastDeletedContestExchange       : ContestExchange;
  LastDisplayedBreakTime: integer = -1;
  LastHelloRecord: HelloRecPtr;
  LastMultiMessage: integer;
  LastMultiInfoMessageSum: array[BandType, ModeType] of Byte;
  //  LastQSOLogged                    : ContestExchange;

  LeaveCursorInCallWindow: boolean;

  LogFileRead: Text;

  LogRSSent: Word = 59;
  LogRSTSent: Word = 599;
  LogWithSingleEnter: boolean;
  LookForRSTSent: boolean;
  LookingForCQExchange: boolean;

  MessageEnable: boolean = True;
  //   ModemPortBaudRate               : integer;
  MultiInfoMessageTimeout: TimeRecord;
  MultiMultsOnly: boolean;
  MultiplierFileEnable: boolean;
  //  MultiMessageBuffer               : array[1..5] of Str80;
  MultiRememberBuffer: MultiMessageListPointer;
  MultiRetryTime: integer = 30;
  MultiSerialNumber: integer;
  MultiUpdateMultDisplay: boolean = True;
  MultReportMinimumBands: integer = 4;
  MyIOTA: Str20;

  NameCallsignPutUp: CallString;

  NoLog: boolean;

  OldCWTone: integer;

  PacketAutoCR: boolean;
  PacketFile: boolean;
  PacketFileRead: file;
  PacketSpotDisable: boolean;
  PacketSpotEditEnable: boolean;
  ParameterOkayMode: ParameterOkayModeType = Standard;
  PartialCallFileEnable: boolean;
  //  PartialCallMultsEnable                : boolean = True;
  PossibleCallAcceptKey: Char = ';';
  PossibleCallEnable: boolean = True;
  PossibleCallLeftKey: Char = ',';
  PossibleCallRightKey: Char = '.';
  PreviousQSOReceivedData: ContestExchange;
  //W_L_I  PrinterEnabled: boolean;
  ProcessedMultiMessages: ProcessedMultiMessageBufferType;

  ProcessedMultiMessagesStart: integer;
  ProcessedMultiMessagesEnd: integer;

  QSONumberByBand: boolean;
  QSXEnable: boolean = True;

  QuickQSL: QuickQSLKeyType; { to indicate a quick QSL is desired }
  QuickQSLKey1: Char = '\';
  QuickQSLKey2: Char = '=';
  RadioServerTCPPort: integer = 52002;
  // Commander Interface (inbound for WSJT-X)

  RadioSetFreq: LONGINT;
  RandomCQMode: boolean;
  RandomNameEnable: boolean;
  ReadInCallsign: CallString;
  ReadInLogComputerID: Char;
  //  ReadInLog                        : boolean;
  ReadInLogBand: BandType;
  ReadInLogDateString: Str10;
  ReadInLogExchange: ShortString {Str40};
  ReadInLogFileName: Str40;
  ReadInLogFileOpen: boolean;
  ReadInLogFileRead: Text;
  ReadInLogMode: ModeType;
  ReadInLogRST: Str10;
  ReadinLogTimeString: Str10;

  ReceivedData: ContestExchange;
  Remember: RememberRadioType;
  RememberBand: BandType;
  RememberMode: ModeType;
  {
    RemoteTerminalBand                    : BandType;
    RemoteTerminalMode                    : ModeType;
    RemoteTerminalPort                    : PortType = NoPort;
  }

  SayHiRateCutOff: integer = 200;
  SendCompleteFourLetterCall: boolean;
  SendQSOImmediately: boolean = True;
  SeventyThreeMessageSent: boolean;
  SCPMinimumLetters: integer;

  SendExchangeKeyWhenCWHasStopped: Char = NullKey;

  Sheet: DupeAndMultSheet = (tAutoReset: True);
  ShortIntegers: boolean;
  ShowQSOStatusCall: CallString;
  //  ShowSearchAndPounce                   : boolean;
  SkipActiveBand: boolean;
  SpaceBarDupeCheckEnable: boolean = True;
  StartSendingNowKey: Char = '''';

  StationInformationCall: CallString;
  SwitchRadioKey: Char;

  TailEnding: boolean;
  TailEndKey: Char = ']';
  TailEndCallString: CallString;

  TotalDomesticContacts: integer;
  TotalDXContacts: integer;
  TotalIntermediateContacts: integer;

  UpdateRestartFileEnable: boolean;

  UDPBroadcastAppInfo: boolean; // ny4i 4.44.8
  UDPBroadcastContact: boolean; // ny4i 4.44.8
  UDPBroadcastScore: boolean; // ny4i Issue 304
  UDPBroadcastRadio: boolean; // ny4i 4.44.8
  UDPBroadcastRotor: boolean; // ny4i 4.44.8
  UDPBroadcastLookup: boolean; // ny4i Issue 612
  UDPBroadcastPort: integer = 12060;
  // ny4i 4.44.9   // Kept for backward compatibilty - no longer used
  UDPBroadcastPortApp: integer = 12060; // ny4i Issue 590
  UDPBroadcastPortContact: integer = 12060; // ny4i Issue 590
  UDPBroadcastPortRadio: integer = 12060; // ny4i Issue 590
  UDPBroadcastPortScore: integer = 12060; // ny4i Issue 590
  UDPBroadcastPortLookup: integer = 12060; // ny4i Issue 612

  UDPBroadcastAddress: string[255] = '127.0.0.1'; // ny4i 4.44.9
  UDPBroadcastRotorPort: integer = 12040; // ny4i 4.44.9
  UDPBroadcastAllQSOs: boolean; // ny4i Issue 82

  // Issue #732 -- PSTRotator native UDP interface (separate from the N1MM
  // broadcast above).  Active when ActiveRotatorType = PSTRotator.  PstRotator
  // listens on its "UDP Control Port" (default 12000) at the configured host.
  PSTRotatorIPAddress: string[255] = '127.0.0.1';
  PSTRotatorUDPPort: integer = 12000;

  WaitForStrength: boolean = True;

  WindowDupeCheckCall: CallString;

  WSJTXUDPPort: integer = 2237;
  WSJTXMulticastGroup: Str20 = '';   // e.g. '224.0.0.1' to join WSJT-X multicast group
  psw: integer = 0;
  tPreviousDupeQSOsShowed: boolean;
  tPreviousDupeQSOsWndHandle: HWND;
  //const  tr4w_StartSendingNowKey                    : ;
  udp: TIdUDPClient; // ny4i 4.44.9 Uses to broadcast info
  //procedure AgeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
  //procedure AgeReceivedHeader(var LogString: Str80; var Underline: Str80);
procedure BandChange(var ActiveBand: BandType; Direction: DirectionType);

procedure CalculateQSOPoints(var RXData: ContestExchange);
//procedure ChapterReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure ChapterReceivedHeader(var LogString: Str80; var Underline: Str80);

procedure CheckForLostMultiMessages;
procedure CreateAndSendCQMultiInfoMessage;
procedure CreateAndSendSAPMultiInfoMessage;

procedure DisplayGridSquareStatus(Call: CallString);
procedure DisplayMultiMessageBuffer;
function DomStringParse(InputString: Str14): Str14; //Gav 4.44.8

function DVKRecentlyStarted(MaxElaspedSec100: LONGINT): boolean;
procedure DVKStamp;

function GetCorrectedCallFromExchangeString(var ExchangeString: ShortString
  {Str80}): Str80;
function GetMultiPortCommand: string;
function GetSentRSTFromExchangeString(var ExchangeString: ShortString {Str40}):
  smallInt {Word};

procedure IncrementQTCCount(Call: CallString);
function IsValidPOTAPark(const park: string): boolean;
function IsValidCallsign(const callsign: string): boolean;
function IsValidGUID(const guid: string): boolean;
function IsValidUSCallsign(const callsign: string): boolean;
function IsValidUSPrefix(const callsign: string): boolean;

function KeyRecentlyPressed(Key: Char; MaxElaspedSec100: LONGINT): boolean;
procedure KeyStamp(Key: Char);

procedure LoadSpecialHelloFile;
procedure EnumHelloDAT(FileString: PShortString);

function LogFileLooksOkay: boolean;
procedure LogStringToRXData(LogString: Str80; var RXData: ContestExchange);
function LooksLikeACallSign(Call: Str40): boolean;

function MarineOrAirMobileStation(Call: CallString): boolean;
{KK1L: 6.68 Used in WRTC 2002}

procedure NextPage;
{
procedure NewBandMapEntry(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: integer;
  SendToMulti: boolean;
  Source: CallString);
}
function NumberQTCsThisStation(Call: CallString): integer;
//procedure NameReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure NameReceivedHeader(var LogString: Str80; var Underline: Str80);

procedure ParseFourFields(sExch: Str80; var s1, s2, s3, s4: Str20);
procedure PassStationToCTNetwork;

//procedure PrintLogHeader;
function ProcessClassAndDomesticOrDXQTHExchange(Exchange: string {Str80}; var
  RXData: ContestExchange): boolean;
function ProcessExchange(ExchangeString: Str80; var RData: ContestExchange):
  boolean;
function ParseArray(e: Str80): boolean;
function ParseArray2(ExchangeString: Str80): boolean;
function SetRST(Ex: integer; var RST: smallInt {Word}): boolean;

procedure ProcessPartialCallAndInitialExchange(RXData: ContestExchange);
function ProperSalutation(Call: CallString): Str80;

procedure PushMultiMessageBuffer(Message: Str80);

procedure RestoreRadioFrequency(Radio: RadioType);

procedure ReviewBackCopyFiles;
procedure RotorControl(Heading: integer);

procedure SaveLogFileToFloppy;
procedure SayHello(Call: CallString);
procedure SayName(Call: CallString);
procedure SendMultiInfoMessage(Band: BandType; Mode: ModeType; Message: Str80);
procedure SendMultiCommand(Source: Byte; Destination: Byte; ControlByte: Byte;
  Message: string);

procedure SendSalutation(Call: CallString);
procedure ShowName(Call: CallString);

procedure ShowPreviousDupeQSOs(Call: CallString;
  Band: BandType;
  Mode: ModeType);
procedure SlowDown;
procedure SpeedUp;

procedure StuffInit;
procedure SendUDPRotorCommand(Heading: integer);
procedure SendPSTRotorCommand(Heading: integer);   // Issue #732
function ValidClass(sClass: Str10): boolean;

{ Header and Stamp routines - used when generating a log string }

//procedure BandModeDateTimeNumberCallNameSentStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure BandModeDateTimeNumberCallNameSentHeader(var LogString: Str80; var Underline: Str80);
//procedure CheckReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure CheckReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure ClassReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure ClassReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure KidsReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure KidsReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure MultiplierHeader(var LogString: Str80; var Underline: Str80);
//procedure MultiplierStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure PowerReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure PowerReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure PrecedenceReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure PrecedenceReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure QSONumberReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure QSONumberReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure QSOPointHeader(var LogString: Str80; var Underline: Str80);
//procedure QSOPointStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure QTHReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure QTHReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure PostalCodeReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure PostalCodeReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure RandomCharsSentAndReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure RandomCharsSentAndReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure RSTReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure RSTReceivedStamp(Exchange: ContestExchange; var LogString: Str80);
//procedure RSTSentHeader(var LogString: Str80; var Underline: Str80);
//procedure RSTSentStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure TenTenNumReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure TenTenNumReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure ZoneReceivedHeader(var LogString: Str80; var Underline: Str80);
//procedure ZoneReceivedStamp(Exchange: ContestExchange; var LogString: Str80);

//procedure WriteLogEntry(Entry: Str80);

//function GetFederalOkrug(OblastDigit, OblastChar: Char): FederalOkrugs;
function InSameFederalOkrug(HisCallsign: CallString): boolean;
//function IsR150Country(OblastDigit, OblastChar: Char): boolean;

implementation

uses uNet,
  PostUnit,
  MainUnit,
  uPOTAParks,
  uPendingCounties,
  Classes; // TStringList — used by ProcessRSTAndDomesticQTHExchange

procedure BandChange(var ActiveBand: BandType; Direction: DirectionType);

label
  NextBand;
const
  MAXBANDS = 21;
  BandChangeArray: array[1..MAXBANDS] of BandChangeType =
    (

    (bcBand: Band160; bcWARC: False; bcVHF: False),
    (bcBand: Band80; bcWARC: False; bcVHF: False),
//    (bcBand: Band60; bcWARC: True; bcVHF: False),
    (bcBand: Band40; bcWARC: False; bcVHF: False),
    (bcBand: Band30; bcWARC: True; bcVHF: False),
    (bcBand: Band20; bcWARC: False; bcVHF: False),
    (bcBand: Band17; bcWARC: True; bcVHF: False),
    (bcBand: Band15; bcWARC: False; bcVHF: False),
    (bcBand: Band12; bcWARC: True; bcVHF: False),
    (bcBand: Band10; bcWARC: False; bcVHF: False),
    (bcBand: Band6; bcWARC: False; bcVHF: True),
    (bcBand: Band2; bcWARC: False; bcVHF: True),
    (bcBand: Band222; bcWARC: False; bcVHF: True),
    (bcBand: Band432; bcWARC: False; bcVHF: True),
    (bcBand: Band902; bcWARC: False; bcVHF: True),
    (bcBand: Band1296; bcWARC: False; bcVHF: True),
    (bcBand: Band2304; bcWARC: False; bcVHF: True),
    (bcBand: Band3456; bcWARC: False; bcVHF: True),
    (bcBand: Band5760; bcWARC: False; bcVHF: True),
    (bcBand: Band10G; bcWARC: False; bcVHF: True),
    (bcBand: Band24G; bcWARC: False; bcVHF: True),
    (bcBand: BandLight; bcWARC: False; bcVHF: True)
    );

var
  TempInteger: integer;
begin

  NextBand:

  for TempInteger := 1 to MAXBANDS do
    if BandChangeArray[TempInteger].bcBand = ActiveBand then
      Break;

  if ActiveBand = NoBand then
    TempInteger := MAXBANDS;

  if Direction = DirectionDown then
  begin
    TempInteger := TempInteger - 1;
    if TempInteger = 0 then
      TempInteger := MAXBANDS;
  end;

  if Direction = DirectionUp then
  begin

    TempInteger := TempInteger + 1;
    if TempInteger >= MAXBANDS + 1 then
      TempInteger := 1;

  end;

  ActiveBand := BandChangeArray[TempInteger].bcBand;

  if (CONTEST <> GeneralQSO) and (BandChangeArray[TempInteger].bcWARC) then
    goto NextBand; //n4af 04.37.11
  if (not WarcBandsEnabled) and (BandChangeArray[TempInteger].bcWARC) then
    goto NextBand; // n4af 04.40.7
  if (not VHFBandsEnabled) and (BandChangeArray[TempInteger].bcVHF) then
    goto NextBand;

  if VHFBandsEnabled then
    if (not HFBandEnable) and (not BandChangeArray[TempInteger].bcVHF) then
      goto NextBand;

  if SkipActiveBand then
  begin
    if (Radio1.BandMemory = ActiveBand) then
      goto NextBand;
    if (Radio2.BandMemory = ActiveBand) then
      goto NextBand;
  end;

  SendStationStatus(sstBandModeFreq);

  //{WLI}
  DisplayBandMode(ActiveBand, ActiveMode, True);

  //?? ??? ???? ?????? ? ?????????
  {
      IF ((ActiveRadio = RadioOne) AND (Radio1Type <> NoInterfacedRadio)) OR
         ((ActiveRadio = RadioTwo) AND (Radio2Type <> NoInterfacedRadio)) THEN
             DisplayBandMode (ActiveBand, ActiveMode, True)
         ELSE
             DisplayBandMode (ActiveBand, ActiveMode, False);
  }

end;

function NumberQTCsThisStation(Call: CallString): integer;

var
  Station: integer;
begin
  NumberQTCsThisStation := 0;
  if NumberQTCStations = 0 then
    Exit;

  for Station := 0 to NumberQTCStations - 1 do
    if QTCDataArray^[Station].Call = Call then
    begin
      Result := QTCDataArray^[Station].NumberQTCs;
      Exit;
    end;
end;

procedure IncrementQTCCount(Call: CallString);
var
  Station: integer;
begin
  inc(TotalNumberQTCsProcessed);
  if NumberQTCStations = 0 then
  begin
    QTCDataArray^[NumberQTCStations].Call := Call;
    QTCDataArray^[NumberQTCStations].NumberQTCs := 1;
    inc(NumberQTCStations);
    Exit;
  end;

  for Station := 0 to NumberQTCStations - 1 do
    if QTCDataArray^[Station].Call = Call then
    begin
      inc(QTCDataArray^[Station].NumberQTCs);
      Exit;
    end;

  //  if NumberQTCStations > 499 then showint(NumberQTCStations);
  //  if NumberQTCStations < 0 then showint(NumberQTCStations);

  QTCDataArray^[NumberQTCStations].Call := Call;
  QTCDataArray^[NumberQTCStations].NumberQTCs := 1;
  inc(NumberQTCStations);
  //  Windows.SetWindowText(tr4whandle, inttopchar(NumberQTCStations));
end;

function ProperSalutation(Call: CallString): Str80;

var
  TempQTHData: QTHRecord;
  Hours, ZeroZuluOffset: Word;
  CurrentHelloRecord: HelloRecPtr;
  ID: CallString;

begin
  ctyLocateCall(Call, TempQTHData);

  if FirstHelloRecord <> nil then
  begin
    ID := TempQTHData.CountryID;
    CurrentHelloRecord := FirstHelloRecord;

    repeat
      if UpperCase(CurrentHelloRecord^.ID) = ID then
      begin
        ProperSalutation := CurrentHelloRecord^.Greeting;
        Exit;
      end;

      CurrentHelloRecord := CurrentHelloRecord^.NextRecord;
    until CurrentHelloRecord = nil;
  end;

  if CTY.ctyZoneMode = CQZoneMode then
  begin
    if (TempQTHData.Zone >= 1) and (TempQTHData.Zone <= 39) then
      ZeroZuluOffset := ZeroZuluOffsetCQZoneArray[TempQTHData.Zone];

    if TempQTHData.Zone = -1 then
      ZeroZuluOffset := 18;
    if TempQTHData.Zone = 40 then
    begin
      ProperSalutation := 'TU';
      Exit;
    end;

    {
        case TempQTHData.Zone of
          -1: ZeroZuluOffset := 18; // These are US calls not in a proper zone
          1: ZeroZuluOffset := 14;
          2: ZeroZuluOffset := 19;
          3: ZeroZuluOffset := 16;
          4: ZeroZuluOffset := 18;
          5: ZeroZuluOffset := 19;
          6: ZeroZuluOffset := 17;
          7: ZeroZuluOffset := 18;
          8: ZeroZuluOffset := 19;
          9: ZeroZuluOffset := 18;
          10: ZeroZuluOffset := 19;
          11: ZeroZuluOffset := 21;
          12: ZeroZuluOffset := 19;
          13: ZeroZuluOffset := 20;
          14: ZeroZuluOffset := 0;
          15: ZeroZuluOffset := 1;
          16: ZeroZuluOffset := 2;
          17: ZeroZuluOffset := 4;
          18: ZeroZuluOffset := 6;
          19: ZeroZuluOffset := 9;
          20: ZeroZuluOffset := 2;
          21: ZeroZuluOffset := 4;
          22: ZeroZuluOffset := 5;
          23: ZeroZuluOffset := 7;
          24: ZeroZuluOffset := 8;
          25: ZeroZuluOffset := 9;
          26: ZeroZuluOffset := 7;
          27: ZeroZuluOffset := 8;
          28: ZeroZuluOffset := 7;
          29: ZeroZuluOffset := 8;
          30: ZeroZuluOffset := 10;
          31: ZeroZuluOffset := 14;
          32: ZeroZuluOffset := 12;
          33: ZeroZuluOffset := 0;
          34: ZeroZuluOffset := 2;
          35: ZeroZuluOffset := 0;
          36: ZeroZuluOffset := 0;
          37: ZeroZuluOffset := 2;
          38: ZeroZuluOffset := 1;
          39: ZeroZuluOffset := 3;
          40:
            begin
              ProperSalutation := 'TU';
              Exit;
            end;

        end;
    }
  end
  else
  begin
    if (TempQTHData.Zone >= 1) and (TempQTHData.Zone <= 66) then
      ZeroZuluOffset :=
        ZeroZuluOffsetITUZoneArray[TempQTHData.Zone]
    else
    begin
      ProperSalutation := 'TU';
      Exit;
    end;

  end;

  Hours := GetIntegerTime div 100;
  Hours := (Hours + ZeroZuluOffset) mod 24;

  if (Hours >= 2) and (Hours <= 11) then
    ProperSalutation := 'GM';
  if (Hours >= 12) and (Hours <= 17) then
    ProperSalutation := 'GA';
  if (Hours >= 18) or (Hours <= 1) then
    ProperSalutation := 'GE';
end;

procedure EnumHelloDAT(FileString: PShortString);
var
  Greeting, ID: Str20;
begin
  GetRidOfPrecedingSpaces(FileString^);
  ID := RemoveFirstString(FileString^);
  GetRidOfPrecedingSpaces(FileString^);
  GetRidOfPostcedingSpaces(FileString^);
  Greeting := FileString^;

  if FirstHelloRecord = nil then
  begin
    FirstHelloRecord := New(HelloRecPtr);
    FirstHelloRecord^.ID := ID;
    FirstHelloRecord^.Greeting := Greeting;
    FirstHelloRecord^.NextRecord := nil;
    LastHelloRecord := FirstHelloRecord;
  end
  else
  begin
    LastHelloRecord^.NextRecord := New(HelloRecPtr);
    LastHelloRecord := LastHelloRecord^.NextRecord;
    LastHelloRecord^.ID := ID;
    LastHelloRecord^.Greeting := Greeting;
    LastHelloRecord^.NextRecord := nil;
  end;
end;

procedure LoadSpecialHelloFile;

begin
  if FirstHelloRecord <> nil then
    Exit;
  EnumerateLinesInFile('HELLO.DAT', EnumHelloDAT, True);
  {
    if OpenFileForRead(FileRead, 'HELLO.DAT') then
    begin
      while not Eof(FileRead) do
      begin
        ReadLn(FileRead, FileString);
        GetRidOfPrecedingSpaces(FileString);
        ID := RemoveFirstString(FileString);
        GetRidOfPrecedingSpaces(FileString);
        GetRidOfPostcedingSpaces(FileString);
        Greeting := FileString;

        if FirstHelloRecord = nil then
        begin
          FirstHelloRecord := New(HelloRecPtr);
          FirstHelloRecord^.ID := ID;
          FirstHelloRecord^.Greeting := Greeting;
          FirstHelloRecord^.NextRecord := nil;
          LastHelloRecord := FirstHelloRecord;
        end
        else
        begin
          LastHelloRecord^.NextRecord := New(HelloRecPtr);
          LastHelloRecord := LastHelloRecord^.NextRecord;
          LastHelloRecord^.ID := ID;
          LastHelloRecord^.Greeting := Greeting;
          LastHelloRecord^.NextRecord := nil;
        end;
      end;

      Close(FileRead);
    end;
  }
end;

procedure SendSalutation(Call: CallString);

begin
  if Call = '' then
    Exit;
  AddStringToBuffer(ProperSalutation(Call), CWTone);
end;

procedure SayHello(Call: CallString);

var
  Salutation, Name: Str20;
  RandomNumber: integer;

begin
  Call := RootCall(Call);
  Name := UpperCase(CD.GetName(Call));

  if (Name <> '') and (Name <> 'CLUB') then
  begin
    Salutation := ProperSalutation(Call);
    if Salutation = 'TU' then
      Salutation := 'HI';
    RandomNumber := Random(10);
    if RandomNumber >= 7 then
      Salutation := 'HI';
    AddStringToBuffer(Salutation + ' ' + Name + ' ', CWTone);
    ReceivedData.NameSent := True;
  end
  else
    //    ReceivedData.NameSent := False;
end;

procedure ShowName(Call: CallString);

var
  Name: CallString;
  p: PChar;
begin
  Call := RootCall(Call);

  NameCallsignPutUp := Call;
  Windows.ZeroMemory(@Name, SizeOf(Name));
  Name := CD.GetName(Call);

  if Name <> '' then
    p := @Name[1]
  else
    p := nil;

  SetMainWindowText(mweName, p);
end;

procedure SayName(Call: CallString);

var
  Name: Str20;

begin
  Call := RootCall(Call);
  Name := UpperCase(CD.GetName(Call));

  if (Name <> '') and (Name <> 'CLUB') then
  begin
    AddStringToBuffer(Name + ' ', CWTone);
    ReceivedData.NameSent := True;
  end
  else
    //    RemoveWindow(NameSentWindow);
end;

function DVKRecentlyStarted(MaxElaspedSec100: LONGINT): boolean;

begin
  if not DVKPlaying then
  begin
    DVKRecentlyStarted := False;
    Exit;
  end;

  DVKRecentlyStarted := MaxElaspedSec100 >= ElaspedSec100(DVKStartTime);
end;

procedure DVKStamp;

begin
  //???? ?? ???? ??? ??? ???? ??????? ??? ????????
  {
    DVKPlaying := True;

    GetTime(DVKStartTime.Hour,
      DVKStartTime.Minute,
      DVKStartTime.Second,
      DVKStartTime.Sec100);
  }
end;

function KeyRecentlyPressed(Key: Char; MaxElaspedSec100: LONGINT): boolean;

begin
  KeyRecentlyPressed := False;
  if Key <> KeyHistory.Key then
    Exit;
  KeyRecentlyPressed := MaxElaspedSec100 >= ElaspedSec100(KeyHistory.Time);
end;

procedure KeyStamp(Key: Char);

begin
  KeyHistory.Key := Key;
  KeyHistory.Time := GetTickCount;
  {  with KeyHistory do
    begin
      GetTime(Time.Hour, Time.Minute, Time.Second, Time.Sec100);
    end;
  }
end;

procedure ParseExchange(Exchange: ShortString {Str80} {WLI}; var FirstString,
  SecondString, ThirdString: Str10 {Str20});

begin
  FirstString := '';
  SecondString := '';
  ThirdString := '';

  if length(Exchange) = 0 then
    Exit;

  if StringHas(Exchange, ' ') then
  begin
    FirstString := PrecedingString(Exchange, ' ');
    Delete(Exchange, 1, length(FirstString) + 1);
    GetRidOfPrecedingSpaces(Exchange);

    if StringHas(Exchange, ' ') then
    begin
      SecondString := PrecedingString(Exchange, ' ');
      Delete(Exchange, 1, length(SecondString));
      GetRidOfPrecedingSpaces(Exchange);
      ThirdString := Exchange;
    end
    else
      SecondString := Exchange;
  end
  else
    FirstString := Exchange;
end;

function ProcessKidsExchange(ExchangeString: Str80; var RData: ContestExchange):
  boolean;

begin
  RData.Kids := ExchangeString;
  ProcessKidsExchange := True;
end;

function ProcessClassAndDomesticOrDXQTHExchange(Exchange: string {Str80}; var
  RXData: ContestExchange): boolean;

{ If the call is a domestic call, there must be a space with the Class
  before the space and the Domestic QTH after it.  If it is a not a domestic
  call the exchange must just be the Class.  In both cases, the Class must
  be at least two characters in length. }
{KK1L: 6.68 This needed to change for the new FD rules which allow all of Region 2 to participate.}
{           Now DX can send a class. Let's still force a check for domesticity and require both a }
{           class and section. For others if the second string of the exchange is blank I will }
{           "let it slide" and assume the first string is class (likely "DX"). }

var
  TempString, TempString2: Str10 {Str20};
  isClassValid: boolean;
  dx: boolean;
begin
  ProcessClassAndDomesticOrDXQTHExchange := False;
  logger.debug('Entered ProcessClassAndDomesticOrDXQTHExchange with Exchange of (%s)', [Exchange]);
  if DomesticCountryCall(RXData.Callsign) then
  begin
    dx := false;
    Windows.ZeroMemory(@RXData.ceClass, SizeOf(RXData.ceClass));
    // Both ZOT added to prevent errors with bad data in log from corrected entry ny4i
    Windows.ZeroMemory(@RXData.QTHString, SizeOf(RXData.QTHString));
    ParseExchange(Exchange, Str10(RXData.ceClass), RXData.QTHString,
      TempString);

    if RXData.QTHString[1] in ['0'..'9'] then
      // This is the code that flips it around if given in section class order // ny4i
    begin
      Windows.ZeroMemory(@TempString, SizeOf(TempString));
      Windows.ZeroMemory(@TempString2, SizeOf(TempString2));

      TempString := RXData.ceClass;
      TempString2 := RXData.QTHString;

      Windows.ZeroMemory(@RXData.ceClass, SizeOf(RXData.ceClass));
      Windows.ZeroMemory(@RXData.QTHString, SizeOf(RXData.QTHString));

      RXData.ceClass := TempString2;
      RXData.QTHString := TempString;
    end;
    // if I enter 999D wtx, then correct it to 99d wtx, then length is of class is still 4. Fix that.
    logger.debug('Calling FoundDomesticQTH from ProcessClassAndDomesticOrDXQTHExchange - QTHString = (%s)', [RXData.QTHString]);
    if not FoundDomesticQTH(RXData) then
    begin
      ExchangeErrorMessage := 'Invalid ARRL Section'; {TC_IMPROPERDOMESITCQTH;}
      ExchangeErrorToken := RXData.QTHString;   // Issue #1010: caret goes after the bad section
      logger.error('[ProcessClassAndDomesticOrDXQTHExchange] Improper Domestic QTH = Exchange = (%s), DomesticQTH = (%s)', [Exchange, RXData.QTHString]);
      // misspelled in the constants file //ny4i 4.45.3
      Exit; // This was before the above code that flips the values. // ny4i 4.45.3
    end;
    isClassValid := ValidClass(RXData.ceClass);
    if not isClassValid then
      ExchangeErrorToken := RXData.ceClass;   // Issue #1010: caret goes after the bad class
    Result := IsClassValid;
  end
  else
  begin
    dx := true;
    {ParseExchange (Exchange, RXData.Class, RXData.QTHString, TempString);} {pre 6.68 statement}
    Windows.ZeroMemory(@RXData.ceClass, SizeOf(RXData.ceClass));
    // Both ZOT added to prevent errors with bad data in log from corrected entry ny4i
    Windows.ZeroMemory(@RXData.QTHString, SizeOf(RXData.QTHString));

    ParseExchange(Exchange, Str10(RXData.ceClass), TempString, TempString2);
    // It used to be that only IARu Region 2 send a class butr the current ARRL FD rules simpl;y
    // state the following:
    //  DX stations send operating class and the term DX (i.e. 2A DX).
    if true {RxData.QTH.Continent in [NorthAmerica, SouthAmerica] } then
      // If IARU Region 2 then we get class (most likely 1D if they are home).
    begin
      isClassValid := ValidClass(RxData.ceClass);
      Result := isClassValid;
    end
    else
    begin
      Result := length(RXData.ceClass) in [2, 3];
      // If it is non-Region 2 DX, just make sure it is two or three characters.
      if not Result then
      begin
        ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
      end;
    end;
    if Result then // If class passes, check QTH is DX
    begin
      if TempString = 'DX' then
      begin
        RXData.QTHString := 'DX';
      end
      else if TempString = '' then
      begin
        // Set this to DX
        RXData.QTHString := 'DX';
      end
      else if ((contest = WINTERFIELDDAY) and (TempString = 'MX')) then
      begin
        RxData.QTHString := 'MX';
      end
      else
      begin
        Result := False;
        ExchangeErrorMessage := TC_ARRLFIELDDAYIMPROPERDXEXCHANGE;
      end;
    end;
    //if TempString <> '' then RXData.QTHString := TempString;
  end;

  // Result is set in one of two paths above...

  //  ProcessClassAndDomesticOrDXQTHExchange :=
   // ProcessClassAndDomesticOrDXQTHExchange := (length(RXData.ceClass) in [2, 3]) and ((RxData.ceClass = 'A') or (RxData.ceClass = 'B') or (RxData.ceClass = 'C') or (RxData.ceClass = 'D') or (RxData.ceClass = 'E') or (RxData.ceClass = 'F'));
  logger.debug('Leaving ProcessClassAndDomesticOrDXQTHExchange with ceClass = (%s) and QTHString = (%s)', [RXData.ceclass, RXData.QTHString]);
end;

function ProcessRSTAgeAndPossibleSK(Exchange: ShortString; var RXData:
  ContestExchange): boolean;
const
  exNNUU: array[0..3] of ExchangeElementType = (eetNumber, eetNumber,
    eetUnknown, eetUnknown);
  exNMNU: array[0..3] of ExchangeElementType = (eetNumber, eetMixed, eetNumber,
    eetUnknown);
  exNNMN: array[0..3] of ExchangeElementType = (eetNumber, eetNumber, eetMixed,
    eetNumber);
begin
  Result := False;
  if ParseArray2(Exchange) then // 4.66.2
    case ParserArray.paCount of
      1:
        if ParserArray.paElements[0].prType = eetNumber then
        begin
          RXData.Age := ParserArray.paElements[0].prInteger;
          Result := True;
        end;

      2:
        if Cardinal(ParserArray.paStatus) = Cardinal(exNNUU) then
        begin
          if not SetRST(ParserArray.paElements[0].prInteger, RXData.RSTReceived)
            then
            Exit;
          RXData.Age := ParserArray.paElements[1].prInteger;
          Result := True;
        end;

      3:
        if Cardinal(ParserArray.paStatus) = Cardinal(exNMNU) then
        begin
          RXData.Age := ParserArray.paElements[0].prInteger;
          if not GoodCallSyntax(ParserArray.paElements[1].prString) then
            Exit;
          if not (ParserArray.paElements[2].prInteger in [0..255]) then
            Exit;
          RXData.QTHString := ParserArray.paElements[1].prString + ' ' +
            IntToStr(ParserArray.paElements[2].prInteger);
          Result := True;
        end;

      4:
        if Cardinal(ParserArray.paStatus) = Cardinal(exNNMN) then
        begin
          if not SetRST(ParserArray.paElements[0].prInteger, RXData.RSTReceived)
            then
            Exit;
          RXData.Age := ParserArray.paElements[1].prInteger;
          if not GoodCallSyntax(ParserArray.paElements[2].prString) then
            Exit;
          if not (ParserArray.paElements[3].prInteger in [0..255]) then
            Exit;
          RXData.QTHString := ParserArray.paElements[2].prString + ' ' +
            IntToStr(ParserArray.paElements[3].prInteger);
          Result := True;
        end;
    end;
end;

function ProcessRSTAndContinentExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

{ Any digits found at the start of the exchange will be used to determine
  the RS(T).  If the first character is not a digit, the default RS(T)
  will be used and the whole exchange will be used as the QTH. }

var
  TempString: Str80;
  QTHFound: boolean;
  ContPrefix: Str20;

begin
  QTHFound := False;
  RXData.QTH.Continent := UnknownContinent;

  ProcessRSTAndContinentExchange := False;
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if not StringHas(Exchange, ' ') and not StringIsAllNumbers(Exchange) then
  begin
    RXData.RSTReceived := DefaultRST;

    ContPrefix := UpperCase(Copy(Exchange, 1, 2));
    RXData.QTH.Continent := GetContinentFromString(ContPrefix);
    RXData.QTHString := Exchange;

    Result := RXData.QTH.Continent <> UnknownContinent;

    if not Result then
      ExchangeErrorMessage := TC_IMPROPERCONTINENT;

    Exit;
  end;

  while Exchange <> '' do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) then
    begin
      if length(TempString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 5 + (Ord(TempString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TempString)
    end
    else if not QTHFound then
    begin
      ContPrefix := UpperCase(Copy(Exchange, 1, 2));
      RXData.QTH.Continent := GetContinentFromString(ContPrefix);
      {
                  if ContPrefix = 'AF' then RXData.QTH.Continent := Africa;
                  if ContPrefix = 'AS' then RXData.QTH.Continent := Asia;
                  if ContPrefix = 'OC' then RXData.QTH.Continent := Oceania;
                  if ContPrefix = 'EU' then RXData.QTH.Continent := Europe;

                  if (ContPrefix = 'SO') or (ContPrefix = 'SA') then RXData.QTH.Continent := SouthAmerica;
                  if (ContPrefix = 'NO') or (ContPrefix = 'NA') then RXData.QTH.Continent := NorthAmerica;
      }
      RXData.QTHString := Exchange;

      if RXData.QTH.Continent <> UnknownContinent then
      begin
        QTHFound := True;
        RXData.QTHString := TempString;
      end;
    end;
  end;

  if QTHFound then
  begin
    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    ProcessRSTAndContinentExchange := True;
  end;
end;

function ProcessNameQTHAndPossibleTenTenNumberExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

var
  TempString: ShortString {Str80};
  ThirdString, NumberString: Str10 {Str20};
  Result1: integer;
  //   tempstr20                       : Str20;
begin
  ProcessNameQTHAndPossibleTenTenNumberExchange := False;

  if Exchange = '' then
    Exit;

  TempString := Exchange;
  Exchange := '';

  RXData.TenTenNum := MAXWORD {-1};

  while TempString <> '' do
  begin
    NumberString := RemoveFirstString(TempString);

    if StringIsAllNumbers(NumberString) then
      Val(NumberString, RXData.TenTenNum, Result1)
    else
      Exchange := Exchange + NumberString + ' ';
  end;

  ParseExchange(Exchange, RXData.Name, RXData.QTHString, ThirdString);

  if not DomesticCountryCall(RXData.Callsign) then
    ProcessNameQTHAndPossibleTenTenNumberExchange := True
  else
    ProcessNameQTHAndPossibleTenTenNumberExchange := FoundDomesticQTH(RXData);

end;

function ProcessNameAndDomesticOrDXQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Two entries with space, name is first. IF DX, then no QTH. }

var
  FirstString: Str10;
  SecondString: Str10;
  ThirdString: Str10;

begin
  ProcessNameAndDomesticOrDXQTHExchange := False;
  if Exchange = '' then
    Exit;
  // ParseExchange(Exchange, RXData.Name, RXData.QTHString, ThirdString);   // old parse
  ParseExchange(Exchange, FirstString, SecondString, ThirdString); //4.51.7
  // check for a corrected number
  if StringIsAllNumbers(ThirdString) then // n4af 4.51.7
  begin
    RXData.Name := FirstString;
    RXData.QTHString := ThirdString;
  end
  else
    {// check for a corrected name}if IsAlpha(ThirdString) then // 4.51.7
    begin
      RXData.Name := ThirdString;
      RXData.QTHString := SecondString;
    end
    else
    begin
      RXData.Name := FirstString;
      RXData.QTHString := SecondString;
    end;
  if not DomesticCountryCall(RXData.Callsign) then
    ProcessNameAndDomesticOrDXQTHExchange := True
  else
  begin
    logger.debug('Calling FoundDomesticQTH from ProcessNameAndDomesticOrDXQTHExchange');
    ProcessNameAndDomesticOrDXQTHExchange := FoundDomesticQTH(RXData);
  end;
  if Result = False then
    ExchangeErrorMessage := TC_IMPROPERDOMESITCQTHORMISSINGNAME;

end;

function ProcessQSONumberAndDomesticQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ If the the two entries are separated by a space, they may appear in either
  order.  If only one entry appears, it is assumed to be the Domestic QTH
  and the QSO number will be one.  }

var
  Str1, Str2 {, Str3, Str4}: Str10 {Str20};
  i: integer;
begin
  ProcessQSONumberAndDomesticQTHExchange := False;
  if length(Exchange) = 0 then
    Exit;

  Str1 := '';
  Str2 := '';
  //  Str3 := '';
  //  Str4 := '';

  //  NumberString := '';

  RXData.QTHString := '';

  for i := 1 to length(Exchange) - 1 do
  begin
    if (tCharIsNumbers(Exchange[i]) <> tCharIsNumbers(Exchange[i + 1])) or
      (Exchange[i + 1] = ' ') then
    begin
      Str1 := Copy(Exchange, 1, i);
      Break;
    end;
  end;

  for i := length(Exchange) downto 2 do
  begin
    if (tCharIsNumbers(Exchange[i]) <> tCharIsNumbers(Exchange[i - 1])) or
      (Exchange[i - 1] = ' ') then
    begin
      Str2 := Copy(Exchange, i, 80);

      // ?
      // Break;

    end;
  end;

  if Str1 = '' then
    Exit;
  if Str2 = '' then
    Exit;

  if StringIsAllNumbers(Str1) then
  begin
    RXData.NumberReceived := StrToInt(Str1);
    RXData.QTHString := Str2;
  end
  else if StringIsAllNumbers(Str2) then
  begin
    RXData.NumberReceived := StrToInt(Str2);
    RXData.QTHString := Str1;
  end
  else
    Exit;
  ProcessQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
  if not Result then
  begin
    ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;
    logger.error('[ProcessQSONumberAndDomesticQTHExchange] Improper Domestic QTH');
  end;
  {
    Exit;

    ParseExchange(Exchange, Str1, Str2, Str3);

    if StringHas(Str3, ' ') then
    begin
      Str4 := PostcedingString(Str3, ' ');
      Str3 := PrecedingString(Str3, ' ');
    end;

    // Do the number - it is easy

    if StringIsAllNumbers(Str4) then
      NumberString := Str4
    else
      if StringIsAllNumbers(Str3) then
        NumberString := Str3
      else
        if StringIsAllNumbers(Str2) then
          NumberString := Str2
        else
          if StringIsAllNumbers(Str1) then
            NumberString := Str1;
    //wli        else          NumberString := '1';

      // Now the QTH - which isn't so hard either

    if (not StringIsAllNumbers(Str4)) and (Str4 <> '') then
      RXData.QTHString := Str4
    else
      if (not StringIsAllNumbers(Str3)) and (Str3 <> '') then
        RXData.QTHString := Str3
      else
        if (not StringIsAllNumbers(Str2)) and (Str2 <> '') then
          RXData.QTHString := Str2
        else
          if (not StringIsAllNumbers(Str1)) and (Str1 <> '') then
            RXData.QTHString := Str1;

    if RXData.QTHString = '' then Exit;
    if NumberString = '' then
    begin
      Parsed := False;
      for Result1 := 1 to length(RXData.QTHString) - 1 do
        if (not tCharIsNumbers(RXData.QTHString[Result1])) and (tCharIsNumbers(RXData.QTHString[Result1 + 1])) then
        begin
          Parsed := True;
          Break;
        end;
      if Parsed then
      begin
        NumberString := Copy(RXData.QTHString, Result1 + 1, 10);
        RXData.QTHString := Copy(RXData.QTHString, 1, Result1);
      end;

      if Parsed = False then
      begin
        for Result1 := 1 to length(RXData.QTHString) - 1 do
          if (tCharIsNumbers(RXData.QTHString[Result1])) and (not tCharIsNumbers(RXData.QTHString[Result1 + 1])) then
          begin
            Parsed := True;
            Break;
          end;
        if Parsed then
        begin
          NumberString := Copy(RXData.QTHString, 1, Result1);
          RXData.QTHString := Copy(RXData.QTHString, Result1 + 1, 10);
        end;
      end;

    end;

    Val(NumberString, RXData.NumberReceived, Result1);
    if Result1 <> 0 then Exit;
    ProcessQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
  }
end;

function ProcessQSONumberAndGridSquareExchange(Exchange: ShortString; var
  RXData: ContestExchange): boolean;
var
  TempString, NumberString: Str40;
  GridString: Str20;
  Result1: integer;

begin
  NumberString := '';
  GridString := '';

  Result := False;

  while (Exchange <> '') and ((NumberString = '') or (GridString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
      GridString := TempString;

  end;

  if GridString = '' then
    Exit;
  if NumberString = '' then
  begin
    NumberString := Copy(GridString, 1, length(GridString) - 4);
    if not StringIsAllNumbers(NumberString) then
      Exit;
    GridString := Copy(GridString, length(GridString) - 3, 4);
  end;

  if not GoodLookingGrid(GridString) then
    Exit;

  RXData.QTHString := GridString;

  Val(NumberString, RXData.NumberReceived, Result1);

  if Result1 <> 0 then
    Exit;

  Result := FoundDomesticQTH(RXData);
end;

function ProcessQSONumberAndNameExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

var
  TempString, NumberString, NameString: Str40;
  Result1: integer;

begin
  NumberString := '';
  NameString := '';

  ProcessQSONumberAndNameExchange := False;

  while (Exchange <> '') and ((NumberString = '') or (NameString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
      NameString := TempString;

  end;

  if (NumberString = '') or (NameString = '') then
    Exit;

  RXData.Name := NameString;

  Val(NumberString, RXData.NumberReceived, Result1);

  ProcessQSONumberAndNameExchange := Result1 = 0;
end;

function ProcessQSONumberAndZoneExchange(Exchange: ShortString; var RXData:
  ContestExchange): boolean;
var
  string1, string2, string3: Str10;
begin

  Result := False;

  if StringIsAllNumbersOrSpaces(Exchange) then
  begin
    ParseExchange(Exchange, string1, string2, string3);
    if string2 <> '' then
    begin
      RXData.Zone := StrToInt(string1);
      RXData.NumberReceived := StrToInt(string2);
      Result := True;
      Exit;
    end;
  end;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  if not StringIsAllNumbers(Exchange) then
    Exit;

  RXData.Zone := Ord(Exchange[1]) - 48;
  RXData.NumberReceived := StrToInt(Copy(Exchange, 2, 4));
  {
    if (Contest = UA4N) then
    begin
      if length(Exchange) > 4 then
      begin
        RXData.Zone := StrToInt(Copy(Exchange, 1, 2));
        RXData.NumberReceived := StrToInt(Copy(Exchange, 3, 4));
      end
      else
        Exit;
    end;
  }
  Result := True;
end;

function ProcessQSONumberAndGeoCoordinatesExchange(Exchange: ShortString
  {Str80}; var RXData: ContestExchange): boolean;

var
  TempString, NumberString, QTHString: Str20;
  Result1: integer;
  Lat, Long: integer;
begin

  NumberString := '';
  QTHString := '';

  Result := False;

  while (Exchange <> '') and ((NumberString = '') or (QTHString = '')) do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) then
      NumberString := TempString
    else
    begin
      //      if Contest = RUSSIAN160 then if LooksLikeRadio160Square(TempString) then QTHString := TempString;
      if LooksLikeAGeoCoordinates(TempString, Lat, Long) then
        QTHString := TempString;
    end;

  end;

  if (NumberString = '') or (QTHString = '') then
    Exit;

  RXData.QTHString := QTHString;

  Val(NumberString, RXData.NumberReceived, Result1);

  Result := Result1 = 0;

end;

function ProcessQSONumberAndCoordinatesSumExchange(Exchange: ShortString; var
  RXData: ContestExchange): boolean;
var
  NumberString, QTHString: Str20;
  Result1, i: integer;

begin

  NumberString := '';
  QTHString := '';

  Result := False;

  NumberString := RemoveLastString(Exchange);
  QTHString := RemoveLastString(Exchange);
  if not StringIsAllNumbers(NumberString) then
    Exit;
  if not StringIsAllNumbers(QTHString) then
  begin
    if length(NumberString) < 3 then
      Exit;
    if (NumberString[1] = '1') or (NumberString[2] = '1') then
      i := 3
    else
      i := 2;

    QTHString := Copy(NumberString, 1, i);
    NumberString := Copy(NumberString, i + 1, 10);
    if QTHString = '' then
      Exit;
  end;

  if length(QTHString) = 1 then
    Exit;
  if length(QTHString) > 3 then
    Exit;

  RXData.QTHString := QTHString;
  Val(NumberString, RXData.NumberReceived, Result1);
  Result := Result1 = 0;
end;

{
function ProcessQSONumberAndCoordinatesSumExchange(Exchange: string; var RXData: ContestExchange): boolean;
var
  NumberString, QTHString          : Str20;
  Result1                          : integer;
begin

  NumberString := '';
  QTHString := '';

  Result := False;

  NumberString := RemoveLastString(Exchange);
  QTHString := RemoveLastString(Exchange);
  if not StringIsAllNumbers(NumberString) then Exit;
  if not StringIsAllNumbers(QTHString) then Exit;
  if length(QTHString) = 1 then Exit;
  if length(QTHString) > 3 then Exit;

  RXData.QTHString := QTHString;
  Val(NumberString, RXData.NumberReceived, Result1);
  Result := Result1 = 0;
end;
}

function ProcessRSTAndOrGridSquareExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

var
  TestString: Str20;

begin
  ProcessRSTAndOrGridSquareExchange := False;
  RXData.DomesticQTH := '';
  //RXData.RSTReceived := 0;  // This seems like it should not be here. If it is set, why would we zero it out?   // ny4i

  if length(Exchange) = 0 then
    Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.DomesticQTH = '' then
      begin
        RXData.DomesticQTH := TestString;
        RXData.QTHString := TestString;
        ProcessRSTAndOrGridSquareExchange := True;
      end;
    end
    else if (RXData.RSTReceived = 0) and StringIsAllNumbers(TestString) then
    begin
      if length(TestString) = 1 then
      begin

        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TestString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 50 + (Ord(TestString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TestString);

      ProcessRSTAndOrGridSquareExchange := True;
    end;
  end;

  {ua4wli}
  if (RXData.DomesticQTH <> '') and (RXData.RSTReceived = 0) then
  begin
    case ActiveMode of
      Phone: RXData.RSTReceived := 59;
    else
      RXData.RSTReceived := 599;
    end;
  end;

end;

function ProcessGridSquareExchange(Exchange: ShortString {Str80}; var RXData:
  ContestExchange): boolean;
begin
  Result := False;
  RXData.DomesticQTH := '';

  if length(Exchange) = 0 then
    Exit;

  if GoodLookingGrid(Exchange) then
  begin
    if RXData.DomesticQTH = '' then
    begin
      RXData.DomesticQTH := Exchange;
      RXData.QTHString := Exchange;
      Result := True;
    end;
  end

end;

function ProcessGrid2Exchange(Exchange: ShortString {Str80}; var RXData:
  // 4.90.11
  ContestExchange): boolean;
begin
  Result := False;
  RXData.DomesticQTH := '';

  if length(Exchange) = 0 then
    Exit;

  if GoodLookingGrid2(Exchange) then
  begin
    if RXData.DomesticQTH = '' then
    begin
      RXData.DomesticQTH := LeftStr(Exchange, 2);
      RXData.QTHString := Exchange;
      Result := True;
    end;
  end

end;

function ProcessRSTAndGrid3Exchange(Exchange: ShortString {Str80}; var RXData:
  // 4.96.3
  ContestExchange): boolean;
var
  FirstString, SecondString, ThirdString: Str10;

begin

  Result := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);
  if SecondString = '' then
  begin
    Exchange := FirstString;
    RXData.RSTReceived := DefaultRST;
  end
  else
  begin
    RXData.RSTReceived := StrToInt(FirstString);
    Exchange := SecondString;
  end;

  if GoodLookingGrid3(Exchange) then
  begin
    //    if RXData.DomesticQTH = '' then
    RXData.DomesticQTH := leftstr(Exchange, 2);

    RXData.QTHString := Exchange;
    Result := True;

  end

end;

function ProcessRSTAndGridSquareExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

var
  TestString: Str20;

begin
  ProcessRSTAndGridSquareExchange := False;
  RXData.DomesticQTH := '';
  RXData.RSTReceived := 0;

  if length(Exchange) = 0 then
    Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.QTHString = '' then
        RXData.QTHString := TestString;
    end
    else if (RXData.RSTReceived = 0) and StringIsAllNumbers(TestString) then
    begin
      if length(TestString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TestString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 50 + (Ord(TestString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TestString);

    end;
  end;

  if (RXData.DomesticQTH <> '') and (RXData.RSTReceived = 0) then
  begin
    case ActiveMode of
      Phone: RXData.RSTReceived := 59;
    else
      RXData.RSTReceived := 599;
    end;
  end;

  ProcessRSTAndGridSquareExchange := FoundDomesticQTH(RXData);
end;

function ProcessNameAndPossibleGridSquareExchange(Exchange: ShortString {Str80};
  var RXData: ContestExchange): boolean;

var
  TestString: Str80;

begin
  ProcessNameAndPossibleGridSquareExchange := False;
  RXData.DomesticQTH := '';
  RXData.Name := '';

  if length(Exchange) = 0 then
    Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if GoodLookingGrid(TestString) then
    begin
      if RXData.DomesticQTH = '' then
      begin
        RXData.DomesticQTH := TestString;
        RXData.QTHString := TestString;
      end;
    end
    else if RXData.Name = '' then
      RXData.Name := TestString;
  end;

  ProcessNameAndPossibleGridSquareExchange := RXData.Name <> '';
end;

function ProcessQSONumberAndDomesticOrDXQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

var
  Result1: integer;
  FirstString, SecondString, ThirdString: Str10 {Str20};

begin
  ProcessQSONumberAndDomesticOrDXQTHExchange := False;
  if length(Exchange) = 0 then
    Exit;

  if not DomesticCountryCall(RXData.Callsign) then
  begin
    ParseExchange(Exchange, FirstString, SecondString, ThirdString);
    getridofprecedingspaces(FirstString);
    getridofprecedingspaces(SecondString);
    getridofprecedingspaces(ThirdString);
    if StringIsAllNumbers(FirstString) then
    begin
      Val(FirstString, RXData.NumberReceived, Result1);
      ProcessQSONumberAndDomesticOrDXQTHExchange := Result1 = 0;
    end
    else if StringIsAllNumbers(SecondString) then
    begin
      Val(SecondString, RXData.NumberReceived, Result1);
      ProcessQSONumberAndDomesticOrDXQTHExchange := Result1 = 0;
    end;

    RXData.QTHString := RXData.QTH.CountryID;
  end
  else
    ProcessQSONumberAndDomesticOrDXQTHExchange :=
      ProcessQSONumberAndDomesticQTHExchange(Exchange, RXData);

end;

procedure ParseExchangeIntoFields(Exchange: ShortString {Str80};
  var Entries: EntryArray;
  var NumberEntries: integer);

begin
  NumberEntries := 0;

  while Exchange <> '' do
  begin
    inc(NumberEntries);
    Entries[NumberEntries] := RemoveFirstString(Exchange);
    if NumberEntries = 10 then
      Exit;
  end;
end;

procedure ParseFourFields(sExch: Str80; var s1, s2, s3, s4: Str20);

type
  pSTRING = ^string;

var
  CharIndex, iDstPtrIndex: integer;
  bInField: boolean;
  aps: array[0..3] of pShortString;
  ps: pShortString;
  c: Char;

begin

  s1 := '';
  s2 := '';
  s3 := '';
  s4 := '';

  aps[0] := @s1;
  aps[1] := @s2;
  aps[2] := @s3;
  aps[3] := @s4;

  CharIndex := 1;
  iDstPtrIndex := 0;
  bInField := False;

  while (CharIndex <= length(sExch)) and (iDstPtrIndex <= 3) do
  begin
    c := sExch[CharIndex];
    inc(CharIndex);
    if c <> ' ' then
    begin
      if not bInField then
      begin
        bInField := True;
        ps := aps[iDstPtrIndex];
        ps^ := ps^ + c;
      end
      else
        ps^ := ps^ + c;
    end
    else if bInField then
    begin
      bInField := False;
      inc(iDstPtrIndex);
    end
  end;

end;

function LooksLikeACallSign(Call: Str40): boolean;

type
  GOT = (gotNIL, gotLETTER, gotNUMBER);

var
  CharIndex, nChanges: integer;
  gotWhat: GOT;

begin
  LooksLikeACallSign := false;
  if (contest = PCC) then // 4.83.7
  begin
    if (length(Call) = 3) and (Call[2] = '/') then
    begin
      LooksLikeACallSign := False;
      Exit;
    end;
  end;

  {MMAA contest}
  if length(Call) > 3 then
  begin
    if Call[1] in ['S', 'N'] then
      if Call[2] = 'A' then
        if Call[3] = '/' then
          if Call[4] in ['M', 'Y', 'Q', 'C'] then
            Exit;
  end;

  gotWhat := gotNIL;
  nChanges := 0;

  for CharIndex := 1 to length(Call) do
  begin
    if (Call[CharIndex] >= 'A') and (Call[CharIndex] <= 'Z') then
    begin
      if gotWhat = gotNUMBER then
        inc(nChanges);
      gotWhat := gotLETTER;
    end
    else if (Call[CharIndex] >= '0') and (Call[CharIndex] <= '9') then
    begin
      { Calls don't end with numbers unless already have '/' }

      if CharIndex = length(Call) then
        Exit;

      { Calls don't start with two numbers }

      if (gotWhat = gotNUMBER) and (CharIndex = 2) then
        Exit;

      if gotWhat = gotLETTER then
        inc(nChanges);

      gotWhat := gotNUMBER;
    end
    else if Call[CharIndex] = '/' then
    begin
      // A '/' at the very start or very end of the token cannot belong
      // to a callsign (no prefix or no body to suffix).
      if (CharIndex = 1) or (CharIndex = length(Call)) then
      begin
        LooksLikeACallSign := False;
        Exit;
      end;
      // Otherwise: do NOT return True here just because we found a '/'.
      // The legacy code returned True at the first interior '/' which
      // misfires for state-QP multi-county exchanges like "PIN/HIL" --
      // both halves are all-letter county codes that resemble nothing
      // like a real callsign.  Real callsigns require a letter<->digit
      // transition in the prefix/body, which the end-of-function
      // `nChanges >= 2` check enforces.  Tokens like "PIN/HIL" have
      // nChanges = 0 and correctly fail that check.  See the
      // Callsign-Update-Enable / Howie / county-line discussion.
    end;
  end;

  LooksLikeACallSign := (nChanges >= 2) and (gotWhat = gotLETTER);

end;

function ProcessQSONumberNameChapterAndQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Used for the QCWA contest.  The Chapter might be 2 or 3 integers, of AL
  for At Large.

  Valid formats:
      QSO# NAME CHAPTER QTH or NAME CHAPTER QTH QSO#

  }

var
  FirstString, SecondString, ThirdString, FourthString: Str20;
  Result1: integer;

begin
  ProcessQSONumberNameChapterAndQTHExchange := False;

  if length(Exchange) < 9 then
    Exit;

  ParseFourFields(Exchange, FirstString, SecondString, ThirdString,
    FourthString);

  if StringIsAllNumbers(FirstString) then
  begin
    if not (StringIsAllNumbers(ThirdString) or (UpperCase(ThirdString) = 'AL'))
      then
      Exit;

    Val(FirstString, RXData.NumberReceived, Result1);

    RXData.Name := SecondString;
    RXData.Chapter := UpperCase(ThirdString);
    RXData.DomesticQTH := FourthString;
  end

  else { Number at end? }

  begin
    if not StringIsAllNumbers(FourthString) then
      Exit;
    if not (StringIsAllNumbers(SecondString) or (UpperCase(SecondString) = 'AL'))
      then
      Exit;

    Val(FourthString, RXData.NumberReceived, Result1);

    RXData.Name := FirstString;
    RXData.Chapter := UpperCase(SecondString);
    RXData.DomesticQTH := ThirdString;
  end;

  ProcessQSONumberNameChapterAndQTHExchange := True;
end;

function ProcessCheckAndChapterOrQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Used for the QCWA Golden Anniversay contest.  The Chapter might be 2 or 3
  integers, or AL for At Large with QTH.  The CHECK is two numbers (year).

  Valid formats:
      CHECK CHAPTER or CHECK QTH

  }

var
  FirstString, SecondString, ThirdString, FourthString: Str20;
  //    Result1: INTEGER;

begin
  ProcessCheckAndChapterOrQTHExchange := False;

  if length(Exchange) < 4 then
    Exit;

  ParseFourFields(Exchange, FirstString, SecondString, ThirdString,
    FourthString);

  if StringIsAllNumbers(FirstString) then
  begin
    RXData.Check := StrToInt(FirstString);

    if SecondString <> '' then
    begin
      RXData.DomesticQTH := SecondString;
      RXData.QTHString := SecondString;
      ProcessCheckAndChapterOrQTHExchange := True;
      Exit;
    end;
  end;
end;

function ProcessQSONumberNameAndDomesticOrDXQTHExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ $Id: proc-nas.pas 1.2 94/09/09 01:48:52 jzap Exp $ }

{ The exchange must be at least 6 characters in length, with each entry
  separated by a space.

  > The new parse routine will put the first four exchange fields into
  > separate strings.  Each is checked to see if it looks like a callsign.
  > If it does, it is used to update the call and is removed; the other
  > strings move up.  What's left constitute the first, second, and third
  > entries described below.

  If the first entry is the QSO number, the second
  entry must be the name and the last entry the QTH string.  If the second
  entry is the QSO number, the first entry must be the name and the last
  entry the QTH.  If the last entry is to be the QSO number (this is
  normal if the program already knew the name and QTH as an initial
  exchange), then the first entry is the name, the second the QTH.  The
  QTH string is ignored if the call is outside the 49 states or Canada.
  If the name is different than that in the name database, it will be
  changed.  }

var
  TempString: Str20;
  NumberEntries, Result1: integer;
  DX: boolean;
  EntryList: EntryArray;

begin
  ProcessQSONumberNameAndDomesticOrDXQTHExchange := False;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  DX := not DomesticCountryCall(RXData.Callsign);

  ParseExchangeIntoFields(Exchange, EntryList, NumberEntries);

  { If we have multiple number entries at the end of the exchange,
    filter out the previous ones }

  while (NumberEntries > 3) and
    StringIsAllNumbers(EntryList[NumberEntries]) and
    StringIsAllNumbers(EntryList[NumberEntries - 1]) do
  begin
    EntryList[NumberEntries - 1] := EntryList[NumberEntries];
    dec(NumberEntries);
  end;

  if NumberEntries <= 3 then { Use old method }
  begin
    if StringIsAllNumbers(EntryList[1]) then
    begin
      Val(EntryList[1], RXData.NumberReceived, Result1);
      RXData.Name := EntryList[2];
      if NumberEntries >= 3 then
        RXData.QTHString := EntryList[3];
    end
    else if StringIsAllNumbers(EntryList[2]) then
    begin
      Val(EntryList[2], RXData.NumberReceived, Result1);
      RXData.Name := EntryList[1];
      if NumberEntries >= 3 then
        RXData.QTHString := EntryList[3];
    end
    else if StringIsAllNumbers(EntryList[3]) then
    begin
      Val(EntryList[3], RXData.NumberReceived, Result1);
      RXData.Name := EntryList[1];
      RXData.QTHString := EntryList[2];
    end
    else
    begin
      ExchangeErrorMessage := TC_NOQSONUMBERFOUND;
      Exit;
    end;
  end

  else
    { We have four or more entries, use new procedure }if (NumberEntries = 4)
      then
    begin
      if StringIsAllNumbers(EntryList[2]) then
      begin
        Val(EntryList[2], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[3];
        RXData.QTHString := EntryList[4];
      end
      else if StringIsAllNumbers(EntryList[3]) then
      begin
        Val(EntryList[3], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[4];
        RXData.QTHString := EntryList[2];
      end
      else if StringIsAllNumbers(EntryList[1]) and
        StringIsAllNumbers(EntryList[4]) then
      begin
        Val(EntryList[4], RXData.NumberReceived, Result1);
        RXData.Name := EntryList[2];
        RXData.QTHString := EntryList[3];

      end
      else

        { Last chance - five or more entries }if
        StringIsAllNumbers(EntryList[NumberEntries - 2]) then
        begin
          Val(EntryList[NumberEntries - 2], RXData.NumberReceived, Result1);
          RXData.Name := EntryList[NumberEntries - 1];
          RXData.QTHString := EntryList[NumberEntries];
        end
        else if (NumberEntries = 4) then // n4af 4.51.6 allow name correction
          if ((IsAlpha(EntryList[4])) and (StringIsAllNumbers(EntryList[1])))
            then
          begin
            Val(EntryList[1], RXData.NumberReceived, Result1);
            RXData.Name := EntryList[4];
            RXData.QTHString := EntryList[3];
          end;
    end;
  if (RXData.Name = '') or ((RXData.QTHString = '') and not DX) then
  begin
    ExchangeErrorMessage := TC_MISSINGQTHANDORNAME;
    Exit;
  end;

  if length(RXData.Name) < length(RXData.QTHString) then
  begin
    if RXData.Name <> CD.GetName(RXData.Callsign) then
      if (length(RXData.Name) = 2) or (length(RXData.Name) = 3) then
      begin
        TempString := RXData.Name;
        RXData.Name := RXData.QTHString;
        RXData.QTHString := TempString;
      end;
  end;

  { The DX QTH gets put in by the GetDXQTH routine in LogDupe when the mult
    check was performmed.  Otherwise, FoundDomesticQTH will put the domestic
    QTH in there for us.  }

  if not DomesticCountryCall(RXData.Callsign) then
    ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
  else if FoundDomesticQTH(RXData) then
    ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
  else
  begin
    TempString := RXData.Name;
    RXData.Name := RXData.QTHString;
    RXData.QTHString := TempString;

    if FoundDomesticQTH(RXData) then
      ProcessQSONumberNameAndDomesticOrDXQTHExchange := True
    else
      ExchangeErrorMessage := TC_IMPROPERDOMESITCQTHORMISSINGNAME;

  end;
end;

procedure ProcessSSEntry(InputString: Str80);

var
  NumberStr, TempString: Str20;

begin
  TempString := InputString;

  NumberStr := '';

  { Gobble up all the leading numbers }

  while StringIsAllNumbers(Copy(TempString, 1, 1)) do
  begin
    NumberStr := NumberStr + Copy(TempString, 1, 1);
    Delete(TempString, 1, 1);
  end;

  if length(NumberStr) > 4 then
    Exit; { I don't like this! }

  if (TempString = '') then { All we had was numbers.  Is it a check? }
  begin
    if (length(NumberStr) = 2) then
    begin
      if SSEx.Check = '' then
        SSEx.Check := NumberStr
      else if (SSEx.Number = '') {and (SSEx.Prec <> CHR(0))} then
        SSEx.Number := NumberStr;
    end
    else if SSEx.Number = '' then
      SSEx.Number := NumberStr;

    Exit;
  end;

  { Gee, this next one works even if the guy only entered A B or Q! }
  if length(TempString) = 1 then
    if TempString[1] in SSPrec then
      {
          IF (TempString = 'A') OR (TempString = 'B') OR (TempString = 'Q') OR
             (TempString = 'U') OR (TempString = 'M') OR (TempString = 'S') THEN
          }
    begin
      if SSEx.Number = '' then
        SSEx.Number := NumberStr;
      if SSEx.Prec = CHR(0) then
        SSEx.Prec := TempString[1];
      Exit;
    end;

  { There is more than one character left in the string. }

  if length(TempString) > 0 then
    if TempString[1] in SSPrec then
      {
          IF (Copy (TempString, 1, 1) = 'A') OR
             (Copy (TempString, 1, 1) = 'B') OR
             (Copy (TempString, 1, 1) = 'Q') OR
             (Copy (TempString, 1, 1) = 'U') OR
             (Copy (TempString, 1, 1) = 'M') OR
             (Copy (TempString, 1, 1) = 'S') THEN
      }
        { We might have a precedence and more info.  The only legal thing after
          a real precedence is a number.  Otherwise, it must be part of the
          section (ie: AB or AL) }

      if StringIsAllNumbers(Copy(TempString, 2, 1)) then

        { Okay, we have the A/B/Q/U/M/S followed by a number.  We will
          assume this to be the precedence. }

      begin
        if SSEx.Number = '' then
          SSEx.Number := NumberStr;
        if SSEx.Prec = CHR(0) then
          SSEx.Prec := TempString[1];
        if SSEx.Check = '' then
          SSEx.Check := Copy(TempString, 2, 2);
        Delete(TempString, 1, 3);
        if SSEx.Section = '' then
          SSEx.Section := TempString;
        Exit;
      end;

  { We must be looking at a check and section, or maybe just a section }

  if length(NumberStr) = 2 then
    if SSEx.Check = '' then
      SSEx.Check := NumberStr;

  if SSEx.Section = '' then
    SSEx.Section := TempString;
end;

function ProcessQSONumberPrecedenceCheckDomesticQTHExchange(Exchange: ShortString
  {Str80};
  var RXData: ContestExchange): boolean;

{ A new improved version!  It tries to maintain compatability with the old
  version, but allows the following:

  If an entry has one, two, three or four digits and the letter A, B or Q
  at the end, then it is assumed to be a number and a precedence.  The last
  of any of these type of entries is used.

  If an entry has two numbers and then at least two letters after it, it is
  assumed to be a check and a section.  Again, the last of any of these type
  of entries is used.

  If an entry is at least four chars long and does not start or end with a
  number or if it has a / in it, then it is assumed to be a callsign.  The
  call will override the callsign window call if it is different.  Again,
  the last on of these is used.
}

var
  Entries: array[0..10] of Str20;
  NumberEntries: integer;
  Entry, Result1: integer;

begin
  ProcessQSONumberPrecedenceCheckDomesticQTHExchange := False;

  Windows.ZeroMemory(@SSEx, SizeOf(SSEx));
  Windows.ZeroMemory(@Entries, SizeOf(Entries));
  if length(Exchange) < 6 then
    Exit;

  NumberEntries := 0;

  while (Exchange <> '') and (NumberEntries <= 10) do
  begin
    Entries[NumberEntries] := RemoveFirstString(Exchange);
    inc(NumberEntries);
  end;

  for Entry := NumberEntries - 1 downto 0 do
  begin
    ProcessSSEntry(Entries[Entry]);

    if (SSEx.Number <> '') and
      (SSEx.Prec <> CHR(0)) and
      (SSEx.Check <> '') and
      (SSEx.Section <> '') then
    begin
      Val(SSEx.Number, RXData.NumberReceived, Result1);
      if Result1 <> 0 then
        Exit;

      RXData.Precedence := SSEx.Prec;
      RXData.Check := StrToInt(SSEx.Check);

      if (length(SSEx.Check) <> 2) or not StringIsAllNumbers(SSEx.Check) then
        Exit;

      RXData.QTHString := SSEx.Section;

      if FoundDomesticQTH(RXData) then
      begin
        ProcessQSONumberPrecedenceCheckDomesticQTHExchange := True;
        Exit;
      end;
    end;
  end;
end;

function LooksLikeRST(Ex: Str80; var RST: smallInt {Word} {RSTString}; Mode:
  ModeType):
  boolean;

begin
  LooksLikeRST := False;
  if Mode = DIGITAL then
  begin
    LooksLikeRST := true;
    RST := StrToIntDef(Ex, -86);
    Exit;
  end;
  if Mode = CW then
  begin
    if length(Ex) <> 3 then
      Exit;

    if (Ex[1] >= '1') and (Ex[1] <= '5') and
      (Ex[2] >= '1') and (Ex[2] <= '9') and
      (((Ex[3] >= '1') and (Ex[3] <= '9')) or (UpCase(Ex[3]) = 'A')) then
    begin
      LooksLikeRST := True;
      RST := StrToInt(Ex);
    end;
    Exit;
  end
  else
    case length(Ex) of

      2:
        if (Ex[1] >= '1') and (Ex[1] <= '5') and
          (Ex[2] >= '1') and (Ex[2] <= '9') then
        begin
          LooksLikeRST := True;
          RST := StrToInt(Ex);
        end;

      3:
        if UpperCase(Copy(Ex, length(Ex), 1)) = 'A' then
          if (ActiveBand = Band6) or (ActiveBand = Band2) then
            if (Ex[1] >= '1') and (Ex[1] <= '5') and
              (Ex[2] >= '1') and (Ex[2] <= '9') then
            begin
              LooksLikeRST := True;
              RST := StrToInt(Ex);
            end;
    end;

end;

function ValidAllJAPrefecture(Prefecture: Str20): boolean;

var
  PrefectureValue, Result1: integer;

begin
  if Copy(Prefecture, 1, 1) = 'p' then
    Delete(Prefecture, 1, 1);

  Val(Prefecture, PrefectureValue, Result1);

  if Result1 <> 0 then
  begin
    ValidAllJAPrefecture := False;
    Exit;
  end;

  ValidAllJAPrefecture := ((PrefectureValue > 1) and (PrefectureValue < 51)) or
    ((PrefectureValue > 100) and (PrefectureValue < 115));
end;

function ProcessRSTAllJAPrefectureAndPrecedenceExchange(Exchange: ShortString
  {Str80}; var RXData: ContestExchange): boolean;

{ Updated for new rules.  Exchange now RS(T) + Prefixture # + Power (A/B/C) }

var
  ExchangeString: ShortString; {STR20} {WLI}
  Entries: array[0..10] of ShortString {Str20}; {WLI}
  NumberEntries: integer;

begin
  Exchange := UpperCase(Exchange);
  //su(Exchange);

  RXData.RSTReceived := DefaultRST;

  ProcessRSTAllJAPrefectureAndPrecedenceExchange := False;

  { Get power out of the way }

  if StringHas(Exchange, 'H') then
  begin
    RXData.Precedence := 'H';
    Delete(Exchange, pos('H', Exchange), 1);
  end
  else if StringHas(Exchange, 'M') then
  begin
    RXData.Precedence := 'M';
    Delete(Exchange, pos('M', Exchange), 1);
  end
  else if StringHas(Exchange, 'L') then
  begin
    RXData.Precedence := 'L';
    Delete(Exchange, pos('L', Exchange), 1);
  end
  else if StringHas(Exchange, 'P') then
  begin
    RXData.Precedence := 'P';
    Delete(Exchange, pos('P', Exchange), 1);
  end;

  GetRidOfPostcedingSpaces(Exchange);

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if NumberEntries = 1 then { Everything as one entry }
  begin
    if ActiveMode = CW then
    begin
      case length(Entries[0]) of
        2, 3:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0];

        4:
          if Copy(Entries[0], 2, 1) = '1' then { S + 3 dig Pref? }
            if ValidAllJAPrefecture(Copy(Entries[0], 2, 3)) then
            begin
              RXData.QTHString := 'p' + Copy(Entries[0], 2, 3);
              //              RXData.RSTReceived[2] := Entries[0][1];
            end;

        5:
          if ValidAllJAPrefecture(Copy(Entries[0], 4, 2)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 4, 2);
            //            RXData.RSTReceived := Copy(Entries[0], 1, 3);
          end;

        6:
          if ValidAllJAPrefecture(Copy(Entries[0], 4, 3)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 4, 3);
            //            RXData.RSTReceived := Copy(Entries[0], 1, 3);
          end;

      end;
    end
    else
    begin { SSB }
      case length(Entries[0]) of

        2:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0];

        3:
          if ValidAllJAPrefecture(Entries[0]) then
            RXData.QTHString := 'p' + Entries[0]
          else if ValidAllJAPrefecture(Copy(Entries[0], 2, 2)) then
          begin
            RXData.QTHString := Copy(Entries[0], 2, 2);
            //              RXData.RSTReceived[2] := Entries[0][1];
          end;

        4:
          if Copy(Entries[0], 2, 1) = '1' then
          begin
            if ValidAllJAPrefecture(Copy(Entries[0], 2, 3)) then
            begin
              RXData.QTHString := 'p' + Copy(Entries[0], 2, 3);
              //              RXData.RSTReceived[2] := Entries[0][1];
            end;
          end
          else if ValidAllJAPrefecture(Copy(Entries[0], 3, 2)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 3, 2);
            //              RXData.RSTReceived := Copy(Entries[0], 1, 2);
          end;

        5:
          if ValidAllJAPrefecture(Copy(Entries[0], 3, 3)) then
          begin
            RXData.QTHString := 'p' + Copy(Entries[0], 3, 3);
            //            RXData.RSTReceived := Copy(Entries[0], 1, 2);
          end;

      end;

    end;
  end;

  { Two entries to look at }

  if NumberEntries = 2 then
  begin
    if ValidAllJAPrefecture(Entries[0]) then
      if not ValidAllJAPrefecture(Entries[1]) then
      begin
        {
                RXData.QTHString := Entries[0];

                case length(Entries[1]) of
                  1: RXData.RSTReceived[2] := Entries[1][1];

                  2:
                    if ActiveMode = Phone then
                      RXData.RSTReceived := Entries[1];

                  3:
                    if ActiveMode = CW then
                      RXData.RSTReceived := Entries[1];
                end;
        }
      end;

    if ValidAllJAPrefecture(Entries[1]) then
      if not ValidAllJAPrefecture(Entries[0]) then
      begin
        RXData.QTHString := Entries[1];
        {
                case length(Entries[0]) of
                  1: RXData.RSTReceived[2] := Entries[0][1];

                  2:
                    if ActiveMode = Phone then
                      RXData.RSTReceived := Entries[0];

                  3:
                    if ActiveMode = CW then
                      RXData.RSTReceived := Entries[0];

                end;
              }
      end;

    if ValidAllJAPrefecture(Entries[0]) then
      if ValidAllJAPrefecture(Entries[1]) then { Both valid }
      begin
        {
                case length(Entries[0]) of
                  1: RXData.RSTReceived[2] := Entries[0][1];
                  2:
                    if ActiveMode = Phone then RXData.RSTReceived := Entries[0];
                  3:
                    if ActiveMode = CW then RXData.RSTReceived := Entries[0];
                end;
        }
        RXData.QTHString := Entries[1];
      end;

  end;

  if not ValidAllJAPrefecture(RXData.QTHString) then
    Exit;
  if not FoundDomesticQTH(RXData) then
    Exit;

  ProcessRSTAllJAPrefectureAndPrecedenceExchange := RXData.Precedence <> '';
end;

function ProcessRSTAndAgeExchange(Exchange: Str80; var RXData: ContestExchange):
  boolean;

{ The exchange must be made of only digits and spaces.  If the exchange has
  a space, the RS(T) is assumed to be the first entry, and the age the
  second.  You can enter just the strength of the RS(T) or the full report.
  The age must be two digits.  You can omit the space if you like.  The
  last two digits will be used for the age and the digits before that for
  the RS(T) information.                        }

var
  ExchangeString: ShortString;
  Entries: array[0..10] of ShortString {Str20};
  NumberEntries: integer;
  TempInt: integer;
begin
  RXData.RSTReceived := DefaultRST;

  ProcessRSTAndAgeExchange := False;

  if not StringIsAllNumbersOrSpaces(Exchange) then
    Exit;

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if (NumberEntries = 1) and ((length(Entries[0]) = 1) or (length(Entries[0]) =
    // 4.99.3
    2)) then
  begin
    TempInt := StrToInt(Entries[0]);
    if TempInt > 255 then
      Exit;
    RXData.Age := Byte(TempInt);
    ProcessRSTAndAgeExchange := True;
    Exit;
  end;

  if NumberEntries = 2 then
  begin
    if LooksLikeRST(Entries[0], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[1])
    else if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[0])
    else
      RXData.Age := StrToInt(Entries[1]);

    ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
    Exit;
  end;

  if NumberEntries = 3 then
  begin
    if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[2])
    else if LooksLikeRST(Entries[2], RXData.RSTReceived, ActiveMode) then
      RXData.Age := StrToInt(Entries[1])
    else
      RXData.Age := StrToInt(Entries[2]);

    ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
    Exit;
  end;

  case length(Exchange) of
    2:
      begin
        RXData.Age := StrToInt(Exchange);
        ProcessRSTAndAgeExchange := True;
      end;

    3:
      begin
        //        Delete(DefaultRST, 2, 1);
        //        Insert(Exchange[1], DefaultRST, 2);
        //        RXData.RSTReceived := DefaultRST;
        Delete(Exchange, 1, 1);
        RXData.Age := StrToInt(Exchange);
        ProcessRSTAndAgeExchange := RXData.Age <> 0 {length(RXData.Age) = 2};
      end;

    4:
      begin
        if ActiveMode <> Phone then
          Exit;
        //        RXData.RSTReceived := Copy(Exchange, 1, 2);
        RXData.Age := StrToInt(Copy(Exchange, 3, 2));
        ProcessRSTAndAgeExchange := True;
      end;

    5:
      begin
        if ActiveMode <> CW then
          Exit;
        //        RXData.RSTReceived := Copy(Exchange, 1, 3);
        RXData.Age := StrToInt(Copy(Exchange, 4, 2));
        ProcessRSTAndAgeExchange := True;
      end;
  end; { of case Length (Exchange) }
end;

function ProcessRSTAndPrefectureExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

var
  ExchangeString: Str80;
  Entries: array[0..3] of Str80;
  NumberEntries: integer;

begin
  RXData.RSTReceived := DefaultRST;

  ProcessRSTAndPrefectureExchange := False;

  if not StringIsAllNumbersOrSpaces(Exchange) then
    Exit;

  if length(RXData.QTH.CountryID) < 2 then
    Exit;
  if not ((RXData.QTH.CountryID[1] = 'J') and (RXData.QTH.CountryID[2] in ['A',
    'D'])) then
    Exit;

  NumberEntries := 0;

  ExchangeString := Exchange;

  while ExchangeString <> '' do
  begin
    Entries[NumberEntries] := RemoveFirstString(ExchangeString);
    GetRidOfPrecedingSpaces(Entries[NumberEntries]);
    inc(NumberEntries);
  end;

  if (NumberEntries = 1) then
  begin
    RXData.QTHString := {'p' +}Entries[0];
    ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

  if NumberEntries = 2 then
  begin
    if LooksLikeRST(Entries[0], RXData.RSTReceived, ActiveMode) then
      RXData.QTHString := Entries[1]
    else if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
      RXData.QTHString := Entries[0]
    else
      RXData.QTHString := Entries[1];

    ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

  {
    if NumberEntries = 3 then
    begin
      if LooksLikeRST(Entries[1], RXData.RSTReceived, ActiveMode) then
        RXData.QTHString := 'p' + Entries[2]
      else
        if LooksLikeRST(Entries[2], RXData.RSTReceived, ActiveMode) then
          RXData.QTHString := 'p' + Entries[1]
        else
          RXData.QTHString := 'p' + Entries[2];

      ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
      Exit;
    end;
  }
  case length(Exchange) of
    2:
      begin
        //        RXData.QTHString := 'p' + Exchange;
        //        ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
      end;

    3:
      begin
        {
                Delete(DefaultRST, 2, 1);
                Insert(Exchange[1], DefaultRST, 2);
                RXData.RSTReceived := DefaultRST;
                Delete(Exchange, 1, 1);
                RXData.QTHString := 'p' + Exchange;
                ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
        }
      end;

    4:
      begin
        {
                if ActiveMode <> Phone then Exit;
                RXData.RSTReceived := Copy(Exchange, 1, 2);
                RXData.QTHString := 'p' + Copy(Exchange, 3, 2);
                ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
        }
      end;

    5:
      begin
        {
                if ActiveMode <> CW then Exit;
                RXData.RSTReceived := Copy(Exchange, 1, 3);
                RXData.QTHString := 'p' + Copy(Exchange, 4, 2);
                ProcessRSTAndPrefectureExchange := FoundDomesticQTH(RXData);
        }
      end;
  end; { of case Length (Exchange) }
end;

function ProcessRSTAgeAndQSONumberExchange(Exchange: ShortString; var RXData:
  ContestExchange): boolean; // 4.55.4
var
  firststring, secondstring, thirdstring: str10;
begin
  ColumnsArray[logColNumberSent].Enable := True;
  ColumnsArray[logColNumberReceive].Enable := True;
  ColumnsArray[logColCheck].Enable := True;
  ParseExchange(exchange, FirstString, SecondString, ThirdString);
  if SecondString = '' then
    exit;
  if thirdstring <> '' then
  begin
    if ActiveMode = CW then
      if (length(FirstString) <> 3) then
        exit;
    if ActiveMode = Phone then
      if length(FirstString) <> 2 then
        exit;
    case ActiveMode of
      CW: RXData.RSTReceived := StrToInt(Copy(Exchange, 1, 3));
      Phone: Rxdata.RSTReceived := StrToInt(Copy(Exchange, 1, 2));
    end;
  end;
  if thirdstring = '' then
  begin

    case ActiveMode of
      CW: RXData.RSTReceived := 599;
      Phone: RXData.RSTReceived := 59;
    end;
    RXData.Age := StrToInt(FirstString);
    RXData.NumberReceived := StrToInt(SecondString);
  end
  else
  begin
    RXData.Age := StrToInt(SecondString);
    RXData.NumberReceived := StrToInt(ThirdString);
  end;

  Result := True;

end;

function ProcessAgeAndQSONumberExchange(Exchange: ShortString; var RXData:
  ContestExchange): boolean;
var
  firststring, secondstring, thirdstring: str10;

begin
  ParseExchange(exchange, FirstString, SecondString, ThirdString); //n4af 04.42.4
  Result := False;
  if (SecondString = '') and (ThirdString = '') then
    exit; // n4af 4.45.7
  if length(Exchange) < 3 then
    Exit;
  if not StringIsAllNumbers(FirstString) then
    Exit;
  RXData.Age := StrToInt(FirstString);
  if ThirdString <> '' then
  begin
    RXData.DomesticQTH := SecondString;
    RXData.NumberReceived := StrToInt(ThirdString)
  end
  else
  begin
    RXData.NumberReceived := StrToInt(SecondString);
    RXData.DomesticQTH := '';
  end;
  { if (ActiveMode = CW) or (ActiveMode = Digital) then  // 4.1193
   begin
     RXData.RSTReceived := 599;
     RXData.RSTSent := 599;
   end
   else
   begin
     RXData.RSTReceived := 59;
     RXData.RSTSent := 59;
   end;  }
  Result := True;
end;

function ProcessQSONumberAndAgeExchange(Exchange: ShortString; var RXData:
  ContestExchange): boolean;
var
  firststring, secondstring, thirdstring: str10;

begin
  ParseExchange(exchange, FirstString, SecondString, ThirdString);
  Result := False;
  if (SecondString = '') then
    exit; //
  if length(Exchange) < 3 then
    Exit;
  if (not StringIsAllNumbers(FirstString)) or (not
    StringIsAllNumbers(SecondString)) then
    Exit;
  RXData.NumberReceived := StrToInt(FirstString);
  RXData.Age := StrToInt(SecondString);
  if (ActiveMode = CW) or (ActiveMode = Digital) then
  begin
    RXData.RSTReceived := 599;
    RXData.RSTSent := 599;
  end
  else
  begin
    RXData.RSTReceived := 59;
    RXData.RSTSent := 59;
  end;
  Result := True;
end;

function ProcessRSTAndDomesticQTHExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

{ Any digits found at the start of the exchange will be used to determine
  the RS(T).  If the first character is not a digit, the default RS(T)
  will be used and the whole exchange will be used as the QTH.

  Multi-county handling (Issue #885): the operator can give more than one
  county in a single exchange when working a station bridging county lines:
    "DAL/BAY"      -- slash-separated
    "DAL BAY"      -- space-separated
    "599 DAL/BAY"  -- with RST
    "DAL/BAY CIT"  -- mixed forms / three counties
  All '/'-characters are mapped to spaces before tokenizing so both formats
  travel the same code path.  Every valid domestic QTH found in user-typed
  order is collected; the first becomes RXData.QTHString for THIS QSO and
  the rest are pushed onto uPendingCounties so TryLogContact can drain the
  queue and write a separate QSO for each. }

var
  TempString : Str80;
  i          : Integer;
  ProbeRX    : ContestExchange;
  ValidQTHs  : TStringList;

begin
  ProcessRSTAndDomesticQTHExchange := False;
  ClearPendingCounties;

  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  // Treat slash-separated counties as space-separated (e.g. "DAL/BAY" =>
  // "DAL BAY") so a single tokenizer handles both formats.
  for i := 1 to Length(Exchange) do
    if Exchange[i] = '/' then
      Exchange[i] := ' ';

  // Single-token, non-numeric branch: still a single QTH after slash mapping
  // (e.g. plain "DAL").  Behavior unchanged from prior code.
  if not StringHas(Exchange, ' ') and not StringIsAllNumbers(Exchange) then
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := Exchange;
    if length(Exchange) < 9 then // n4af 4.43.12
      ProcessRSTAndDomesticQTHExchange := FoundDomesticQTH(RXData)
    else
      Result := False;
    if Result = False then
    begin
      logger.Error('[ProcessRSTAndDomesticQTHExchange] Improper DOmestic QTH');
      ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;
    end;
    { The code below to handle IARU-HF was commented out but it is not quite right anyway.
      The issue is that when the exchange is a member society like IARU, the RXData.Zone is
      not being set from the callsign. This is only a factor for external processors like
      UDP as the Society, not the zone goes in the exchange in Cabrillo for example.
      So I am adding the following code to check if we the ActiveExchange is
      RSTZoneOrSocietyExchange and RXData.Zone is 255 (initialized value apparently),
      then I lookup the zone from the call and set that. - NY4I 2026JUL07
     }
     if ActiveExchange = RSTZoneOrSocietyExchange then
        begin
        if (CONTEST = IARU)     and
            (RXData.Zone = 255) then
            begin
            RXData.Zone := ctyGetZone(RXData.Callsign);
            end;
        end;
    {WLI}
//    if ActiveExchange = RSTZoneOrSocietyExchange then
//      if CONTEST <> IARU then RXData.Zone := CountryTable.GetITUZone(RXData.Callsign);
    Exit;
  end;

  // Multi-token branch.  Walk right-to-left (RemoveLastString returns the
  // rightmost token).  Numeric tokens become RST.  Probe every other token
  // against the domestic-mults table and collect every match in a list,
  // preserving user-typed order via Insert(0, ...).
  ValidQTHs := TStringList.Create;
  try
    while Exchange <> '' do
    begin
      TempString := RemoveLastString(Exchange);
      if TempString = '' then
        Continue;

      if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) then
      begin
        if length(TempString) = 1 then
        begin
          case ActiveMode of
            CW    : RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
            Phone : RXData.RSTReceived := 50  + (Ord(TempString[1]) - 48);
          end;
        end
        else
          RXData.RSTReceived := StrToInt(TempString);
      end
      else
      begin
        // Probe with a scratch ContestExchange so we can keep walking after
        // the first match.  FoundDomesticQTH writes DomMultQTH/DomesticQTH
        // on the record passed in; we only want to update the real RXData
        // once, with the first user-typed QTH.
        FillChar(ProbeRX, SizeOf(ProbeRX), 0);
        ProbeRX.QTHString := TempString;
        if FoundDomesticQTH(ProbeRX) then
          ValidQTHs.Insert(0, TempString);  // user-typed order
      end;
    end;

    if ValidQTHs.Count = 0 then
    begin
      logger.error('[ProcessRSTAndDomesticQTHExchange] Improper Domestic QTH - Exchange = (%s)', [Exchange]);
      ExchangeErrorMessage := TC_IMPROPERDOMESITCQTH;
      Exit;
    end;

    // First valid QTH (in user-typed order) is for this QSO.  Re-run
    // FoundDomesticQTH against the real RXData to populate DomMultQTH /
    // DomesticQTH from the canonical name.
    RXData.QTHString := ValidQTHs[0];
    FoundDomesticQTH(RXData);

    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;

    // Queue any additional valid QTHs.  TryLogContact will drain the queue
    // immediately after writing the QSO above, logging one extra QSO per
    // queued county.
    for i := 1 to ValidQTHs.Count - 1 do
      QueuePendingCounty(ValidQTHs[i]);

    ProcessRSTAndDomesticQTHExchange := True;
  finally
    ValidQTHs.Free;
  end;
end;

function ProcessRSTAndJAPrefectureExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

{ A single entry is assumed to be the exchange and not RST. Two entries assume }
{ the RS(T) is the first provided it is 3 characters or less                   }

var
  TempString: Str80;
  QTHFound: boolean;

begin
  QTHFound := False;

  ProcessRSTAndJAPrefectureExchange := False;
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if not StringHas(Exchange, ' ') then
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := Exchange;
    ProcessRSTAndJAPrefectureExchange := FoundDomesticQTH(RXData);
    Exit;
  end;

  while Exchange <> '' do
  begin
    TempString := RemoveLastString(Exchange);

    if StringIsAllNumbers(TempString) and (RXData.RSTReceived = 0) and
      (length(TempString) < 4) then
    begin
      if length(TempString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TempString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 5 + (Ord(TempString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TempString)

    end
    else if not QTHFound then
    begin
      RXData.QTHString := TempString;
      if FoundDomesticQTH(RXData) then
        QTHFound := True;
    end;
  end;

  if QTHFound then
  begin
    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    ProcessRSTAndJAPrefectureExchange := True;
    Exit;
  end;

end;

function ProcessRSTAndQTHExchange(Exchange: ShortString {Str80}; var RXData:
  ContestExchange): boolean;

var
  RSTString: Str20;

begin
  GetRidOfPrecedingSpaces(Exchange);
  GetRidOfPostcedingSpaces(Exchange);

  if Exchange = '' then
  begin
    ProcessRSTAndQTHExchange := False;
    Exit;
  end;

  ProcessRSTAndQTHExchange := True;

  RSTString := PrecedingString(Exchange, ' ');

  if StringIsAllNumbersOrSpaces(RSTString) then
  begin
    RXData.RSTReceived := StrToInt(RSTString);
    RXData.QTHString := PostcedingString(Exchange, ' ');
  end
  else
  begin
    RSTString := Exchange;

    while StringHas(RSTString, ' ') do
      RSTString := PostcedingString(RSTString, ' ');

    if StringIsAllNumbersOrSpaces(RSTString) then
    begin
      RXData.RSTReceived := StrToInt(RSTString);
      RXData.QTHString := Copy(Exchange, 1, length(Exchange) - length(RSTString)
        - 1);
    end
    else
    begin
      RXData.RSTReceived := DefaultRST;
      RXData.QTHString := Exchange;
    end;
  end;
end;
{
function ProcessRSTAndFOCNumberExchange(Exchange:Str80; var RXData:ContestExchange):boolean;     //n4af function added 4.32.5
//    ProcessExchange := ProcessRSTNAMEAndNumber(ExchangeString, RData);             //n4af add foc marathon
var
NumberEntries,  Result1       : integer;
 EntryList                             : EntryArray;
 Exch : Str10;
begin
ProcessRSTAndFOCNumberExchange := False;
ParseExchangeIntoFields(Exchange, EntryList, NumberEntries);
if NumberEntries = 1 then
begin
RXData.RSTReceived := DefaultRST;
RXData.FOCNumber := EntryList[1];
   end
else
if ((EntryList[2][1] = '5') and (EntryList[2][3] = '9'))     then
begin
RXData.RSTReceived := StrToInt(EntryList[2]);
RXData.FOCNumber := EntryList[1];
end
else
begin
RXData.RSTReceived := StrToInt(EntryList[1]);
RXData.FOCNumber := EntryList[2];
end;
RXData.FOCNumber := Exchange;
ProcessRSTAndFOCNumberExchange := RXData.FOCNumber <> '';

ProcessRSTAndFOCNumberExchange := True;
end;
}
{
if StringIsAllNumbers(FirstString) then
FirstString := StrToInt(FirstString);
else
FirstString := DefaultRST;

 SecondString := RXData.Name;
if StringIsAllNumbers(ThirdString)  then
  ThirdString := StrToInt(ThirdString);

 if ThirdString <> '' then
 begin
   if StringIsAllNumbers(ThirdString) then
   RXData.NumberReceived := StrToInt(ThirdString);
 end
 else
   RXData.NumberReceived := ' ';
 Exit;      }

function ProcessRSTAndDomesticOrDXQTHExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;
var
  // State-QP rover detection (KG1S/MON): the country lookup in
  // ParametersOkay treats /M as a Great Britain prefix indicator and
  // sets RXData.QTH.Country to G, which causes DomesticCountryCall
  // below to return False and routes the exchange to the DX parser
  // (which discards the county).  Detect the rover form here and
  // force the domestic-parser route so MON gets logged as the county.
  RoverSlashPos : Integer;
  RoverProbeRX  : ContestExchange;
begin
  ProcessRSTAndDomesticOrDXQTHExchange := False;

  // Rover-form override: if the call has a /COUNTY suffix and COUNTY
  // validates as a domestic QTH, treat as domestic regardless of
  // DomesticCountryCall's verdict on the slashed form.
  RoverSlashPos := Pos('/', string(RXData.Callsign));
  if RoverSlashPos > 0 then
     begin
     FillChar(RoverProbeRX, SizeOf(RoverProbeRX), 0);
     RoverProbeRX.QTHString := UpperCase(
        Copy(string(RXData.Callsign), RoverSlashPos + 1,
             Length(string(RXData.Callsign)) - RoverSlashPos));
     if FoundDomesticQTH(RoverProbeRX) then
        begin
        ProcessRSTAndDomesticOrDXQTHExchange :=
          ProcessRSTAndDomesticQTHExchange(Exchange, RXData);
        Exit;
        end;
     end;

  if DomesticCountryCall(RXData.Callsign) then
  begin
    ProcessRSTAndDomesticOrDXQTHExchange :=
      ProcessRSTAndDomesticQTHExchange(Exchange, RXData);
    Exit;
  end;

  //  if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then Exit;
  //  ProcessRSTAndDomesticOrDXQTHExchange := True;

  ProcessRSTAndDomesticOrDXQTHExchange := ProcessRSTAndQTHExchange(Exchange,
    RXData);
end;

function ProcessRSTNameAndQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
                                         (RS(T) = default, no QTH or name)
   Name                                  (RS(T) = default, no QTH)
   Name        QTH                       (RS(T) = default)
   Name        QTH         RS(T)         (Enter whole RS(T))
   Name        RS(T)                     (No QTH)
   Name        RS(T)       QTH           (Enter whole RS(T))
   RS(T)                                 (Enter whole RS(T), no QTH or name)
   RS(T)       Name                      (Enter whole RS(T), no QTH)
   RS(T)       QTH         Name          (Enter whole RS(T))             }

var
  FirstString, SecondString, ThirdString: Str10 {Str20};

begin
  ProcessRSTNameAndQTHExchange := True;

  if Exchange = '' then
  begin
    if RXData.RSTReceived = 0 then
    begin
      RXData.RSTReceived := DefaultRST;
    end;
    Exit;
  end;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if StringIsAllNumbers(FirstString) then
  begin
    RXData.RSTReceived := StrToInt(FirstString);
    if ThirdString <> '' then
    begin
      RXData.QTHString := ThirdString;
      RXData.Name := SecondString;
    end
    else
      RXData.Name := SecondString;
    Exit;
  end;

  if StringIsAllNumbers(SecondString) then
  begin
    RXData.Name := FirstString;
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := SecondString;
    Exit;
  end;

  if StringIsAllNumbers(ThirdString) then
  begin
    RXData.Name := FirstString;
    RXData.QTHString := SecondString;
    RXData.RSTReceived := StrToInt(ThirdString);
    Exit;
  end;

  if ThirdString <> '' then
  begin
    {
        ProcessRSTNameAndQTHExchange := False;
        Exit;
    }
    SecondString := SecondString + ' ' + ThirdString;
  end;

  RXData.Name := FirstString;
  RXData.QTHString := SecondString;
  RXData.RSTReceived := DefaultRST;
end;

procedure LookForCutNumbers(var Exchange: ShortString {Str80});

var
  TempString, NewExchange: ShortString {Str80};
  Address: integer;

begin
  NewExchange := '';

  while Exchange <> '' do
  begin
    TempString := RemoveFirstString(Exchange);

    if not StringIsAllNumbers(TempString) then
    begin
      for Address := 1 to length(TempString) do
        case TempString[Address] of

          'T', 'O': TempString[Address] := '0';
          'A': TempString[Address] := '1';
          'U': TempString[Address] := '2';
          'E': TempString[Address] := '5';
          'N': TempString[Address] := '9';
        end;
    end;

    NewExchange := NewExchange + TempString + ' '
  end;

  GetRidOfPostcedingSpaces(NewExchange);
  Exchange := NewExchange;
end;

function ProcessRSTAndQSONumberExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       QSO Number
   QSO Number                (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.

  Cut QSO numbers are changed to numeric. }

var
  code: integer;

begin
  ProcessRSTAndQSONumberExchange := False;
  if (CallWindowString <> '') then // 4.123.10
    if ((contest = SACCW) or (contest = SACSSB)) then
      if (rxdata.qth.countryid = 'UA') or (rxdata.qth.countryid = 'EU') or
        (rxdata.qth.countryid = 'UA9') or (rxdata.qth.countryid = 'UA2') then
      begin
        initializeqso;
        exit;
      end;
  LookForCutNumbers(Exchange);

  if StringIsAllNumbers(Exchange) then
  begin
    Val(Exchange, RXData.NumberReceived, code);
    if code <> 0 then
      Exit;
    RXData.RSTReceived := DefaultRST;
    ProcessRSTAndQSONumberExchange := True;
  end
  else if ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then
  begin
    Exchange := RemoveFirstString(Exchange);
    Val(Exchange, RXData.NumberReceived, code);
    if code <> 0 then
      exit;
    ProcessRSTAndQSONumberExchange := True;
  end
  else
    ExchangeErrorMessage := TC_NOQSONUMBERFOUND;

end;

function LooksLikePower(TestString: Str20): boolean;

{ Returns true if entry is all numbers, or all numbers with a W at the end }

var
  CharPos: integer;

begin
  LooksLikePower := False;

  if TestString = '' then
    Exit;

  TestString := UpperCase(TestString);

  for CharPos := 1 to length(TestString) do
  begin
    if not (TestString[CharPos] in ['0'..'9', 'W', 'M', 'R']) then
      Exit;
    {
    if ((TestString[CharPos] < '0') or (TestString[CharPos] > '9')) and
      (TestString[CharPos] <> 'W') and (TestString[CharPos] <> 'M') and
      (TestString[CharPos] <> 'R') then Exit;
    }
  end;

  LooksLikePower := True;
end;

function ProcessRSTPossibleDomesticQTHAndPowerExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ RST MaybeQTH and Power.  Power will either have numbers and a W in it, or
  four numbers (for ARCI member number) }

var
  FirstString, SecondString, ThirdString: {STRING}Str10;
  ThirdStringRST, SecondStringRST, FirstStringRST: ShortString;

begin
  ProcessRSTPossibleDomesticQTHAndPowerExchange := False;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if StringIsAllNumbers(ThirdString) and (length(ThirdString) <= 3) then
  begin
    ThirdStringRST := ThirdString;
    if not ValidRST(ThirdStringRST, RXData.RSTReceived, ActiveMode) then
      Exit;
  end
  else if StringIsAllNumbers(SecondString) and (length(SecondString) <= 3) then
  begin
    SecondStringRST := SecondString;
    if not ValidRST(SecondStringRST, RXData.RSTReceived, ActiveMode) then
      Exit;
  end
  else if StringIsAllNumbers(FirstString) and (length(FirstString) <= 3) then
  begin
    FirstStringRST := FirstString;
    if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then
      Exit;
  end
  else if ActiveMode = CW then
    RXData.RSTReceived := 599
  else
    RXData.RSTReceived := 59;

  if LooksLikePower(ThirdString) then
    RXData.Power := ThirdString
  else if LooksLikePower(SecondString) then
    RXData.Power := SecondString
  else if LooksLikePower(FirstString) then
    RXData.Power := FirstString;

  if (ThirdString <> '') and (not LooksLikePower(ThirdString)) then
    RXData.QTHString := ThirdString
  else if (SecondString <> '') and (not LooksLikePower(SecondString)) then
    RXData.QTHString := SecondString
  else if (FirstString <> '') and (not LooksLikePower(FirstString)) then
    RXData.QTHString := FirstString;

  if RXData.Power = '' then
    Exit;

  { RXData.DXQTH is only there if it is a DX call }

  if RXData.DXQTH = '' then
    ProcessRSTPossibleDomesticQTHAndPowerExchange := FoundDomesticQTH(RXData)
  else
    ProcessRSTPossibleDomesticQTHAndPowerExchange := True;
end;

function ProcessQSONumberAndPreviousQSONumber(Exchange: Str80; var RXData:
  ContestExchange): boolean;
var
  l: integer;

begin
  Result := False;
  l := length(Exchange);
  if not (l in [4..6]) then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;
  if not StringIsAllNumbers(Exchange) then
    Exit;
  temprxdata.NumberReceived := StrToInt(Exchange);
  rxdata.NumberReceived := StrToInt(Exchange);
  PrevNr := Copy(Exchange, 1, 3); // 4.53.2

  Result := True;
end;

function ProcessRSTQSONumberAndDomesticQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QTH                                    (RS(T) = default, QSO number = 1)
   QTH         QSO Number                 (RS(T) = default)
   QTH         RS(T)       QSO Number
   QSO Number  QTH                        (RS(T) = default)
   RS(T)       QTH         QSO Number
   RS(T)       QSO Number  QTH

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndDomesticQTHExchange := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;
    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else if not StringIsAllNumbers(SecondString) then
  begin
    RXData.QTHString := SecondString;
    if ThirdString <> '' then
      NumberString := FirstString + ' ' + ThirdString
    else
      NumberString := FirstString;
  end
  else
  begin
    RXData.QTHString := ThirdString;
    NumberString := FirstString + ' ' + SecondString;
  end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    if RXData.QTHString <> '' then
      ProcessRSTQSONumberAndDomesticQTHExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTQSONumberAndGridSquareExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   Grid                                    (RS(T) = default, QSO number = 1)
   Grid        QSO Number                  (RS(T) = default)
   Grid        RS(T)       QSO Number
   QSO Number  Grid                        (RS(T) = default)
   RS(T)       Grid        QSO Number
   RS(T)       QSO Number  Grid

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndGridSquareExchange := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;

    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else if not StringIsAllNumbers(SecondString) then
  begin
    RXData.QTHString := SecondString;
    if ThirdString <> '' then
      NumberString := FirstString + ' ' + ThirdString
    else
      NumberString := FirstString;
  end
  else
  begin
    RXData.QTHString := ThirdString;
    NumberString := FirstString + ' ' + SecondString;
  end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    if GoodLookingGrid(RXData.QTHString) then
      ProcessRSTQSONumberAndGridSquareExchange := FoundDomesticQTH(RXData);
end;
// n4af 4.51.2

function ProcessRSTQSONumberOrDomesticQTHExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;
var
  NumberString, FirstString, SecondString, ThirdString: Str10;
  //n: integer;
begin
  ProcessRSTQSONumberOrDomesticQTHExchange := False;

  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);
  { n := pos('/',SecondString) ;
   if n > 0 then

     RXData.QTHString := Rightstr(SecondString,n+1)
     else
      rxdata.QTHString := SecondString;

  }
  if not StringIsAllNumbers(FirstString) then // n4af 4.40.5
    if SecondString = '' then
    begin
      ProcessRSTAndDomesticQTHExchange(Exchange, RXData); // n4af 4.40.5
      Result := True;
      exit;
    end;
  if not StringIsAllNumbers(FirstString) then // n4af 4.42.7
  begin
    RXData.QTHString := FirstString;
    RXData.NumberReceived := StrToInt(SecondString);
    ProcessRSTQSONumberOrDomesticQTHExchange := FoundDomesticQTH(RXData);
    Result := True;
    exit;
  end;
  if ThirdString <> '' then
    NumberString := SecondString + ' ' + ThirdString;
  //  else                                           // N4AF 4.42.9
  //    NumberString := SecondString;

  if (not StringIsAllNumbers(SecondString)) and (SecondString <> '') then
  begin
    RXData.QTHString := SecondString;
    if ThirdString <> '' then
      NumberString := FirstString + ' ' + ThirdString
    else
      NumberString := FirstString;
  end
  else
  begin
    RXData.QTHString := ThirdString;
    NumberString := FirstString + ' ' + SecondString;
  end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
  begin
    if RXData.QTHString = '' then
      ProcessRSTQSONumberOrDomesticQTHExchange := True
    else
      ProcessRSTQSONumberOrDomesticQTHExchange := FoundDomesticQTH(RXData)
  end
  else
    ExchangeErrorMessage := TC_NOQSONUMBERFOUND;
end;

function ProcessRSTQSONumberAndPossibleDomesticQTHExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QSO Number                             (RS(T) = default, No QTH)
   QTH                                    (RS(T) = default, QSO number = 1)
   QTH         QSO Number                 (RS(T) = default)
   QTH         RS(T)       QSO Number
   QSO Number  QTH                        (RS(T) = default)
   RS(T)       QTH         QSO Number
   RS(T)       QSO Number                 (No QTH)
   RS(T)       QSO Number  QTH

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;
begin

  ProcessRSTQSONumberAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);
  if Contest = UKEI then
  begin
    if (UKEIStation(RXData.Callsign)) then
      if (SecondString = '') then
      begin
        ExchangeErrorMessage := TC_INVALID;
        exit;
      end;
  end;
  {  if Contest = '
      if pos(SecondString,'/') > 0 then
       SecondString[1] := ' ';
  }
  if not stringisallnumbers(FirstString) then //   n4af 4.42.9
    if not stringisallnumbers(SecondString) then
      if not stringisallnumbers(ThirdString) then
      begin
        ExchangeErrorMessage := TC_NOQSONUMBERFOUND;
        exit;
      end;

  if not StringIsAllNumbers(FirstString) then // n4af 4.40.5
    if SecondString = '' then
    begin
      ProcessRSTAndDomesticQTHExchange(Exchange, RXData); // n4af 4.40.5
      Result := True;
      exit;
    end;
  if not StringIsAllNumbers(FirstString) and StringIsAllNumbers(SecondString)
    then // n4af 4.42.7
  begin
    RXData.QTHString := FirstString;
    RXData.NumberReceived := StrToInt(SecondString);
    ProcessRSTQSONumberAndPossibleDomesticQTHExchange :=
      FoundDomesticQTH(RXData);
    Result := True;
    exit;
  end;
  if ThirdString <> '' then
    NumberString := SecondString + ' ' + ThirdString;
  //  else                                           // N4AF 4.42.9
  //    NumberString := SecondString;

  if not StringIsAllNumbers(SecondString) then
  begin
    RXData.QTHString := SecondString;
    if ThirdString <> '' then
      NumberString := FirstString + ' ' + ThirdString
    else
      NumberString := FirstString;
  end
  else
  begin
    RXData.QTHString := ThirdString;
    NumberString := FirstString + ' ' + SecondString;
  end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
  begin
    if RXData.QTHString = '' then
      ProcessRSTQSONumberAndPossibleDomesticQTHExchange := True
    else
      ProcessRSTQSONumberAndPossibleDomesticQTHExchange :=
        FoundDomesticQTH(RXData)
  end;

end;
{KK1L: 6.73 For Michigan QSO Party NOT WORKING!!!!!!}

function ProcessQSONumberAndPossibleDomesticQTHExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   QSO Number                             (No QTH)
   QTH                                    (QSO number = 1)
   QTH         QSO Number
   QSO Number  QTH                                            }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessQSONumberAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString := FirstString;
    NumberString := SecondString;
  end
  else if (not StringIsAllNumbers(FirstString)) then
    if SecondString = '' then
    begin
      RXData.QTHString := FirstString;
      NumberString := '';
      Result := False;
    end;
  if not StringIsAllNumbers(SecondString) then // 4,93.2
  begin
    RXData.QTHString := SecondString;
    NumberString := FirstString;
  end;

  if StringIsAllNumbers(NumberString) then
    if RXData.QTHString = '' then
      ProcessQSONumberAndPossibleDomesticQTHExchange := True
    else
      ProcessQSONumberAndPossibleDomesticQTHExchange :=
        FoundDomesticQTH(RXData);

  if Result = True then
  begin
    RXData.NumberReceived := StrToInt(NumberString);
  end;
end;

function ProcessNZFieldDayExchange(Exchange: ShortString {Str80}; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The RST is
  optional.  The following formats will work:

  If in New Zealand:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   RST         QSO Number  Zone
   QSO Number  Zone

  You can enter just the strength of the RS(T) if desired.

  If not in New Zealand:

   Entry  #1   Entry  #2
   ---------   ---------
   RST         QSO Number
   QSO Number

    }

var
  FirstString, SecondString, ThirdString: Str10;

begin
  ProcessNZFieldDayExchange := False;
  if Exchange = '' then
    Exit;

  if RXData.QTH.CountryID = 'ZL' then
  begin
    ParseExchange(Exchange, FirstString, SecondString, ThirdString);

    if ThirdString <> '' then
    begin
      if length(ThirdString) > 2 then
        Exit;
      RXData.Zone := StrToInt(ThirdString);
    end
    else
    begin
      if (SecondString = '') or (length(SecondString) > 2) then
        Exit;
      RXData.Zone := StrToInt(SecondString);
      //      if length(RXData.Zone) = 1 then RXData.Zone := '0' + RXData.Zone;
    end;

    //    if length(RXData.Zone) = 1 then RXData.Zone := '0' + RXData.Zone;
    RemoveLastString(Exchange);

    //    if not StringIsAllNumbers(RXData.Zone) then Exit;
  end;

  if ProcessRSTAndQSONumberExchange(Exchange, RXData) then
    ProcessNZFieldDayExchange := True;

end;

function ProcessRSTQTHNameAndFistsNumberOrPowerExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ 599 QTH NAME FISTS# or 599 QTH NAME POWER.  Assumed to be FISTS # unless
  the number has a W at the end of it.  RST is optional.  QTH is required
  even for DX.  Name can only be one word.  Spaces required for each entry. }

var
  NumberEntries, Address, Result1: integer;
  DX: boolean;
  EntryList: EntryArray;

begin
  ProcessRSTQTHNameAndFistsNumberOrPowerExchange := False;

  if length(Exchange) < 4 then
  begin
    ExchangeErrorMessage := TC_NOTENOUGHINFOINEXCHANGE;
    Exit;
  end;

  DX := not DomesticCountryCall(RXData.Callsign);

  ParseExchangeIntoFields(Exchange, EntryList, NumberEntries);

  if StringIsAllNumbers(EntryList[1]) then
  begin
    RXData.RSTReceived := StrToInt(EntryList[1]);

    { Remove the RST from the entry list }

    if NumberEntries > 1 then
      for Address := 1 to NumberEntries - 1 do
        EntryList[Address] := EntryList[Address + 1];
    dec(NumberEntries);
  end
  else
    RXData.RSTReceived := 599; { Use default RST }

  { We have removed the RST if it was there.  Should have QTH, Name
    and power or member # }

  if NumberEntries < 2 then
    Exit; { Not enough data }

  if (NumberEntries = 2) and DX then
  begin
    RXData.QTHString := RXData.QTH.CountryID;
    RXData.Name := EntryList[1];

    if NumberEntries > 1 then
      for Address := 1 to NumberEntries - 1 do
        EntryList[Address] := EntryList[Address + 1];
    dec(NumberEntries);
  end
  else
  begin
    RXData.QTHString := EntryList[1];
    RXData.Name := EntryList[2];

    for Address := 1 to NumberEntries - 2 do
      EntryList[Address] := EntryList[Address + 2];
    NumberEntries := NumberEntries - 2;
  end;

  { We should now just have the power or member number left }

  if NumberEntries <> 1 then
    Exit;

  if StringIsAllNumbers(EntryList[1]) then { member number }
    Val(EntryList[1], RXData.NumberReceived, Result1)
  else
    RXData.Power := EntryList[1];

  if DX then
    ProcessRSTQTHNameAndFistsNumberOrPowerExchange := True
  else
    ProcessRSTQTHNameAndFistsNumberOrPowerExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTQSONumberAndRandomCharactersExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   Chars                                  (RS(T) = default, QSO number = 1)
   Chars       QSO Number                 (RS(T) = default)
   Chars       RS(T)       QSO Number
   QSO Number  Chars                      (RS(T) = default)
   RS(T)       Chars       QSO Number
   RS(T)       QSO Number  Chars

  You can enter just the strength of the RS(T) if desired.      }

var
  NumberString, FirstString, SecondString, ThirdString: Str10;

begin
  ProcessRSTQSONumberAndRandomCharactersExchange := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.RandomCharsReceived := FirstString;
    if ThirdString <> '' then
      NumberString := SecondString + ' ' + ThirdString
    else
      NumberString := SecondString;
  end
  else if not StringIsAllNumbers(SecondString) then
  begin
    RXData.RandomCharsReceived := SecondString;
    if ThirdString <> '' then
      NumberString := FirstString + ' ' + ThirdString
    else
      NumberString := FirstString;
  end
  else
  begin
    RXData.RandomCharsReceived := ThirdString;
    NumberString := FirstString + ' ' + SecondString;
  end;

  if ProcessRSTAndQSONumberExchange(NumberString, RXData) then
    ProcessRSTQSONumberAndRandomCharactersExchange :=
      (length(RXData.RandomCharsReceived) = 5) and
      (length(RXData.RandomCharsSent) = 5);

end;

function ProcessRSTAndPostalCodeExchange(Exchange: Str80; var RXData:
  ContestExchange): boolean;

{ Legal entries HA1 1TA, RS(T) HA1 1TA or HA1 1TA RS(T) }

var
  FirstString, SecondString, ThirdString: Str10;

begin
  Result := False;
  if Exchange = '' then
    Exit;

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);

  if not StringIsAllNumbers(FirstString) then
  begin
    RXData.QTHString {PostalCode} := FirstString + ' ' + SecondString;
    RXData.RSTReceived := StrToInt(ThirdString);

    if RXData.RSTReceived = 0 then
      RXData.RSTReceived := DefaultRST;
    Result := True;
  end
  else
  begin
    RXData.QTHString {PostalCode} := SecondString + ' ' + ThirdString;
    RXData.RSTReceived := StrToInt(FirstString);
    Result := True;
  end;

  //  RXData.QTHString := Copy(RXData.PostalCode, 1, 2);

  //  ProcessRSTAndPostalCodeExchange := FoundDomesticQTH(RXData);
end;

function ProcessRSTAndQSONumberOrFrenchDepartmentExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;
begin
  Result := False;

  if ParserArray.paCount = 2 then
  begin
    if (ParserArray.paElements[0].prType <> eetNumber) or not
      (sETrst(ParserArray.paElements[0].prInteger, RXData.RSTReceived)) then
      Exit;
  end;

  if FrenchID(RXData.QTH.CountryID) then
  begin
    RXData.QTHString := Exchange; //n4af 4.36.5
    //    RXData.QTHString := ParserArray.paElements[ParserArray.paCount - 1].prString;
    if length(RXData.QTHString) = 1 then
      RXData.QTHString := '0' + RXData.QTHString;
    if FoundDomesticQTH(RXData) then
      Result := True;
  end
  else
  begin
    if ParserArray.paElements[ParserArray.paCount - 1].prType = eetNumber then
    begin
      RXData.NumberReceived := ParserArray.paElements[ParserArray.paCount -
        1].prInteger;
      Result := True;
    end;
  end;
end;

function ProcessRSTAndQSONumberOrDomesticQTHExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

label
  1;

begin
  if (ActiveQSOPointMethod = RACQSOPointMethod) and (Copy(RXData.Callsign, 1, 3)
    = 'VE0') then
  begin
    ProcessRSTAndQSONumberOrDomesticQTHExchange :=
      ProcessRSTAndQSONumberExchange(Exchange, RXData);
    Exit;
  end;

  if ActiveQSOPointMethod = PCCQSOPointMethod then // 4.83.2
  begin
    //    if RXData.DomesticQTH <> ''  then
    if not StringIsAllNumbers(Exchange) then
      ProcessRSTAndQSONumberOrDomesticQTHExchange :=
        ProcessRSTAndDomesticQTHExchange(Exchange, RXData)
    else

      ProcessRSTAndQSONumberOrDomesticQTHExchange :=
        ProcessRSTAndQSONumberExchange(Exchange, RXData);

    Exit;
  end;

  if ActiveQSOPointMethod = ArktikaSpringQSOPointMethod then
  begin
    if StringIsAllNumbersOrSpaces(Exchange) then
      ProcessRSTAndQSONumberOrDomesticQTHExchange :=
        ProcessRSTAndQSONumberExchange(Exchange, RXData)
    else
      ProcessRSTAndQSONumberOrDomesticQTHExchange :=
        ProcessRSTAndDomesticQTHExchange(Exchange, RXData);
    Exit;
  end;

  1:
  if DomesticCountryCall(RXData.Callsign) then
    ProcessRSTAndQSONumberOrDomesticQTHExchange :=
      ProcessRSTAndDomesticQTHExchange(Exchange, RXData)
  else
    ProcessRSTAndQSONumberOrDomesticQTHExchange :=
      ProcessRSTAndQSONumberExchange(Exchange, RXData);
end;

function ProcessRSTAndPOTAPark(Exchange: ShortString; var RXData:
  ContestExchange): boolean;
// Parses a POTA exchange of the form:
//   RST PARK              e.g. "57 US-0663"
//   RST PARK PARK         e.g. "57 US-0663 US-1234"   (2fer)
//   RST PARK PARK PARK    e.g. "57 US-0663 US-1234 US-5678"  (3fer, etc.)
//   PARK                  e.g. "US-0663"              (no RST)
//
// We tokenize the raw exchange string ourselves rather than using ParseExchange,
// which is hard-limited to three tokens and truncates the third field to
// Str10 (10 chars).  That truncation makes it impossible to carry two park
// refs in one field (e.g. "US-0663 US-1234" = 15 chars).
//
// Delimiter rules:
//   - Tokens are separated by spaces and/or commas, so the operator can type
//     "57 US-0663 US-1234" or "57 US-0663, US-1234" interchangeably.
//
// Multi-park handling:
//   - The first valid park found becomes RXData.QTHString (logged in this QSO).
//   - Any additional valid parks are pushed onto the FPendingParks queue in
//     uPOTAParks.  TryLogContact checks HasPendingParks after writing the QSO
//     and auto-refills the exchange for the next park so the operator just
//     presses Enter again.
//
// RST handling:
//   - The first numeric token is RSTSent; the second (rare in POTA) is RSTReceived.
//   - Non-numeric, non-park tokens are silently ignored.
var
  S          : string;    // Working copy of the exchange for easy manipulation
  Token      : string;    // Current token being examined
  Normalized : string;    // Token after NormalizePOTAPark()
  SpacePos   : Integer;   // Index of the next space delimiter
  RSTFound   : Boolean;   // True once we have consumed the RST token
  AllParks   : string;    // Space-separated list of all parks (for SetLastPOTAExchange)
begin
  // POTA is free-form — any exchange (including empty) is valid. Always True.
  Result             := True;
  RXData.RSTReceived := DefaultRST;
  RXData.RSTSent     := DefaultRST;
  RXData.QTHString   := '';
  RXData.DomesticQTH := '';
  RXData.Name        := '';
  RXData.ExchString  := '';

  if Length(Exchange) = 0 then
     begin
     // Empty exchange is acceptable in POTA (defaults apply).
     Result := True;
     Exit;
     end;

  // Always rebuild the queue from this exchange.  TryLogContact drains the
  // queue inline immediately after the first LogContact, so by the time we
  // re-enter for the next contact the queue is empty already.
  ClearPendingParks;

  // Normalise delimiters: replace commas with spaces so the main loop only
  // needs to handle space-separated tokens.
  S := Exchange;
  for SpacePos := 1 to Length(S) do
     if S[SpacePos] = ',' then
        S[SpacePos] := ' ';

  RSTFound  := False;
  AllParks  := '';

  // Walk token by token until the string is exhausted.
  while S <> '' do
     begin
     // Skip any run of leading spaces left by the previous iteration.
     while (S <> '') and (S[1] = ' ') do
        Delete(S, 1, 1);
     if S = '' then
        Break;

     // Extract the next whitespace-delimited token.
     SpacePos := Pos(' ', S);
     if SpacePos > 0 then
        begin
        Token := Copy(S, 1, SpacePos - 1);
        Delete(S, 1, SpacePos);
        end
     else
        begin
        Token := S;
        S := '';
        end;

     if Token = '' then
        Continue;

     // Try to interpret the token as a park reference.
     // NormalizePOTAPark returns the original token unchanged when it is not
     // a park reference (e.g. an RST value like "57" or "599").
     Normalized := NormalizePOTAPark(Token, MyPark);

     if IsValidPOTAPark(Normalized) then
        begin
        if RXData.QTHString = '' then
           begin
           // First park found — this is the QTH for the QSO being logged.
           RXData.QTHString := Normalized;
           Result := True;
           end
        else
           begin
           // Additional park (2fer/Nfer) — queue for inline drain in
           // TryLogContact: one extra LogContact per queued ref, no refill.
           QueuePendingPark(Normalized);
           end;
        // Accumulate all parks for SetLastPOTAExchange below.
        if AllParks = '' then
           AllParks := Normalized
        else
           AllParks := AllParks + ' ' + Normalized;
        end
     else if StringIsAllNumbers(Token) then
        begin
        // Numeric token — treat as signal report.
        // POTA operators give one RST for the contact regardless of how many
        // parks the station is activating.
        if not RSTFound then
           begin
           RXData.RSTSent := StrToIntDef(Token, DefaultRST);
           RSTFound := True;
           end
        else
           begin
           // A second numeric token is RSTReceived (uncommon in POTA but valid).
           RXData.RSTReceived := StrToIntDef(Token, DefaultRST);
           end;
        end
     else if LooksLikeAState(UpperCase(Token)) then
        begin
        // State abbreviation (US or Canadian province) — store in DomesticQTH.
        // First one wins; extras fall through to ExchString below.
        if RXData.DomesticQTH = '' then
           RXData.DomesticQTH := UpperCase(Token)
        else
           begin
           if RXData.ExchString = '' then
              RXData.ExchString := UpperCase(Token)
           else
              RXData.ExchString := RXData.ExchString + ' ' + UpperCase(Token);
           end;
        end
     else if LooksLikeASection(UpperCase(Token)) then
        begin
        // ARRL section — store in DomesticQTH if not already taken by a state.
        if RXData.DomesticQTH = '' then
           RXData.DomesticQTH := UpperCase(Token)
        else
           begin
           if RXData.ExchString = '' then
              RXData.ExchString := UpperCase(Token)
           else
              RXData.ExchString := RXData.ExchString + ' ' + UpperCase(Token);
           end;
        end
     else
        begin
        // Check the token against the TRMASTER.DTA name database.
        // If it matches a known operator name, store it in Name (first match
        // wins).  Unknown tokens go to ExchString as free-form notes.
        // Either way the QSO is always saved — POTA exchange is free-form.
        if NameInOperatorSet(Token) and (RXData.Name = '') then
           RXData.Name := Token
        else
           begin
           if RXData.ExchString = '' then
              RXData.ExchString := Token
           else
              RXData.ExchString := RXData.ExchString + ' ' + Token;
           end;
        end;
     end;

  // Store the full exchange (RST + all parks) so "Repeat POTA Parks (2nd Op)"
  // can re-fill it for a second operator at the same station.
  if AllParks <> '' then
     SetLastPOTAExchange(IntToStr(RXData.RSTSent) + ' ' + AllParks);
end;

function ProcessRSTZoneAndPossibleDomesticQTHExchange(Exchange: Str80; var
  RXData: ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2   Entry  #3
   ---------   ---------   ---------
   RS(T)       Zone        QTH
   RS(T)       Zone                      (No QTH)
   Zone                                  (RS(T) = default, no QTH)
   Zone        QTH                       (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.       }

var

  FirstString, SecondString, ThirdString: Str10;
  FirstStringRST: ShortString;

begin
  ProcessRSTZoneAndPossibleDomesticQTHExchange := False;
  if Exchange = '' then
    Exit;

  RXData.QTHString := '';

  ParseExchange(Exchange, FirstString, SecondString, ThirdString);
  if (IsAlpha(FirstString) and (StringIsAllNumbers(SecondString))) then
    // n4af 4.52.2
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.QTHString := FirstString;
    RXData.Zone := StrtoInt(SecondString);
    ProcessRSTZoneAndPossibleDomesticQTHExchange := FoundDomesticQTH(RXData);
    exit;
  end;

  if ThirdString <> '' then
  begin
    FirstStringRST := FirstString;
    if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then
      Exit;
    RXData.Zone := StrToInt(SecondString);
    RXData.QTHString := ThirdString;
  end
  else if SecondString <> '' then
  begin
    if IsAlpha(SecondString) then
    begin
      RXData.RSTReceived := DefaultRST;
      RXData.Zone := StrToInt(FirstString);
      RXData.QTHString := SecondString;
    end
    else
    begin
      if not ValidRST(FirstStringRST, RXData.RSTReceived, ActiveMode) then
        Exit;
      RXData.Zone := StrToInt(SecondString);
    end;
  end;

  if ((length(FirstString) > 2) or (isalpha(Firststring))) then
  begin
    QuickDisplay(TC_INVALID);
    exit
  end
  else if (SecondString = '') and (ThirdString = '') then // 4.52.5
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.Zone := StrToInt(Exchange);
  end;

  if RXData.QTHString <> '' then
    ProcessRSTZoneAndPossibleDomesticQTHExchange := FoundDomesticQTH(RXData)
  else
    ProcessRSTZoneAndPossibleDomesticQTHExchange := True;
end;

function ProcessRSTAndPowerExchange(Exchange: ShortString {Str80}; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       Power
   Power                     (RS(T) = default)

  You can enter just the strength of the RS(T) if you like.       }

begin
  ProcessRSTAndPowerExchange := False;

  if StringHas(Exchange, ' ') then
  begin
    if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then
      Exit;
    GetRidOfPrecedingSpaces(Exchange);
    RXData.Power := Exchange;
  end
  else
  begin
    RXData.RSTReceived := DefaultRST;
    RXData.Power := Exchange;
  end;

  ProcessRSTAndPowerExchange := RXData.Power <> '';
end;

function ProcessRSTAndZoneExchange(Exchange: ShortString {Str80}; var RXData:
  ContestExchange): boolean;

{ Each entry of the exchange must be separated by spaces.  The following
  formats work:

   Entry  #1   Entry  #2
   ---------   ---------
   RS(T)       Zone
   Zone                       (RS(T) = default)
   Zone        RST            (RST must be three characters, CW only)

  You can enter just the strength of the RS(T) if you like.    }

var
  FirstString, SecondString, ThirdString: Str10;

begin
  ExchangeErrorMessage := TC_IMPROPERZONENUMBER;
  ProcessRSTAndZoneExchange := False;
  if not StringIsAllNumbersOrSpaces(Exchange) then
    Exit;
  RXData.RSTReceived := DefaultRST;

  if StringHas(Exchange, ' ') then
  begin
    if ActiveMode = CW then
    begin
      ParseExchange(Exchange, FirstString, SecondString, ThirdString);

      if (length(SecondString) = 3) and (length(FirstString) < 3) then
      begin
        RXData.RSTReceived := StrToInt(SecondString);
        RXData.Zone := StrToInt(FirstString);
        //        if length(RXData.Zone) = 1 then          Insert('0', RXData.Zone, 1);
        ProcessRSTAndZoneExchange := True;
        ExchangeErrorMessage := nil;
        Exit;
      end;
    end;

    if not ValidRST(Exchange, RXData.RSTReceived, ActiveMode) then
      Exit;
    GetRidOfPrecedingSpaces(Exchange);
  end;

  case length(Exchange) of
    1:
      begin
        RXData.Zone := StrToInt(Exchange);
        ProcessRSTAndZoneExchange := True;
        ExchangeErrorMessage := nil;
      end;

    2:
      begin
        RXData.Zone := StrToInt(Exchange);

        if ActiveZoneMult = EUHFCYear then
        begin
          if not (RXData.Zone in [0..99]) then
            Exit;
          ProcessRSTAndZoneExchange := True;
          ExchangeErrorMessage := nil;
          Exit;
        end;

        if (CTY.ctyZoneMode = CQZoneMode) and (ActiveZoneMult <> JAPrefectures)
          then
          if (Exchange[1] > '5') or ((Exchange[1] = '4') and (Exchange[2] >=
            '1')) then
            Exit;

        if ActiveZoneMult = JAPrefectures then
          if (Exchange[1] > '6') or ((Exchange[1] = '5') and (Exchange[2] >=
            '1')) then
            Exit;

        ProcessRSTAndZoneExchange := True;
        ExchangeErrorMessage := nil;
      end;

  end;
end;

procedure SaveLogFileToFloppy;
var
  ErrorMsg: string;
begin
  if TR4W_FLOPPY_FILENAME[0] = #0 then
     Exit;

  Format(QuickDisplayBuffer, TC_SAVINGTO, TR4W_LOG_FILENAME, TR4W_FLOPPY_FILENAME);
  QuickDisplay(QuickDisplayBuffer);

  if not Windows.CopyFile(TR4W_LOG_FILENAME, TR4W_FLOPPY_FILENAME, False) then
     begin
     ErrorMsg := SysErrorMessage(GetLastError);
     Format(QuickDisplayBuffer, '%s: %s', TR4W_FLOPPY_FILENAME, PChar(ErrorMsg));
     QuickDisplay(QuickDisplayBuffer);
     DoABeep(Warning);
     end
  else
     begin
     Format(QuickDisplayBuffer, TC_FILESAVEDTOSUCCESSFULLY, TR4W_FLOPPY_FILENAME);
     QuickDisplay(QuickDisplayBuffer);
     end;
  {
    if FloppyFileSaveName = '' then Exit;
    Windows.ZeroMemory(@TR4W_FLOPPY_FILENAME, SizeOf(TR4W_FLOPPY_FILENAME));
    I := pos(':', FloppyFileSaveName);
    if I = 0 then I := 3 else I := 0;
    TR4W_FLOPPY_FILENAME[0] := 'A';
    TR4W_FLOPPY_FILENAME[1] := ':';
    TR4W_FLOPPY_FILENAME[2] := '/';
    Windows.CopyMemory(@TR4W_FLOPPY_FILENAME[I], @FloppyFileSaveName[1], length(FloppyFileSaveName));
    asm
    lea  eax,TR4W_FLOPPY_FILENAME
    push eax
    lea  eax,TR4W_LOG_FILENAME
    push eax
    end;
    wsprintf(QuickDisplayBuffer, TC_SAVINGTO);
    asm add esp,16  end;
    QuickDisplay(QuickDisplayBuffer);

    if not Windows.CopyFile(TR4W_LOG_FILENAME, TR4W_FLOPPY_FILENAME, False) then
    begin
      SysErrorMessage(GetLastError);
      asm
      push eax
      lea  eax,TR4W_FLOPPY_FILENAME
      push eax
      end;
      wsprintf(QuickDisplayBuffer, '%s: %s');
      asm add esp,16  end;
      QuickDisplay(QuickDisplayBuffer);

      DoABeep(Warning);
    end
    else
    begin
      if I <> 0 then QuickDisplay(TC_FILESAVEDTOFLOPPYSUCCESSFULLY)
      else
      begin
        asm
        lea  eax,FloppyFileSaveName[1]
        push eax
        end;
        wsprintf(QuickDisplayBuffer, TC_FILESAVEDTOSUCCESSFULLY);
        asm add esp,12 end;
        QuickDisplay(QuickDisplayBuffer);
      end;
    end;
  }
end;

procedure RestoreRadioFrequency(Radio: RadioType);

begin
  {    IF Remember [Radio].Frequency = 0 THEN Exit;
      WITH Remember [Radio] DO SetRadioFreq (Radio, Frequency, Mode, 'A');
     }
end;

procedure ReviewBackCopyFiles;

begin
  {WLI}

end;

function GetCorrectedCallFromExchangeString(var ExchangeString: ShortString
  {Str80}): Str80;

var
  PotentialCall, TempString: ShortString {Str40};

begin
  GetCorrectedCallFromExchangeString := '';

  TempString := ExchangeString;

  if CallsignUpdateEnable {and StringHas(TempString, ' ')} then
    while TempString <> '' do
    begin
      PotentialCall := RemoveLastString(TempString);

      if LooksLikeACallSign(PotentialCall) then
      begin
        GetCorrectedCallFromExchangeString := PotentialCall;

        { Delete all the stuff we have }

        Delete(ExchangeString, 1, length(TempString));

        { Remove the callsign }

        RemoveFirstString(ExchangeString);

        { Rebuild the exchange string without the callsign }

        ExchangeString := TempString + ' ' + ExchangeString;
        Exit;
      end;
    end;
end;

function ISentThisMultiMessage(MultMessage: string): boolean;

{ Works for both N6TR and K1EA network }

begin
  ISentThisMultiMessage := False;

  if NetDebug then
  begin
    //    SaveSetAndClearActiveWindow(DupeSheetWindow);

    WriteLn('ISentThisMultiMessage called with : ');

    WriteLn;
    WriteLn('The following messages are in the message list : ');
  end;

  if NetDebug then
  begin
    WriteLn('Entry not found.');
    //RestorePreviousWindow;
  end;
end;

procedure CheckForLostMultiMessages;

{ This procedure will look at the MultiMessageMemory and see if there are
  any entries that should either be resent or deleted.  It will stop after
  it finds one to send so it doesn't hog the computer too long. }

var
  LookAddress: integer;

begin
  LookAddress := LastMultiMessage;

  while LookAddress <> FirstMultiMessage do
  begin
    with MultiRememberBuffer^[LookAddress] do
      if not QSL then
      begin
        if RetryCount <= 10 then
        begin

          if ((RetryCount < 2) and (ElaspedSec100(TimeMark) > MultiRetryTime *
            100) or
            (RetryCount >= 2) and (ElaspedSec100(TimeMark) > 3000)) then
          begin
            if RetryCount >= 3 then
              DoABeep(Beepsingle);
            SendMultiMessage(Message);
            MarkTime(TimeMark);
            inc(RetryCount);
          end;
        end;

        if (RetryCount >= 5) and (Warnings = 0) then
        begin
          DoABeep(Warning);
          QuickDisplay('Please check multi network');
          //                        ReminderPostedCount := 60;
          Warnings := 1;
        end;

        if (RetryCount > 10) and (Warnings = 1) then
        begin
          DoABeep(Warning);
          QuickDisplay('Possible data loss on multi network.');
          //                        ReminderPostedCount := 60;
          Warnings := 2;
        end;

      end;

    LookAddress := (LookAddress + 1) mod MultiMessageBufferSize;
  end;
end;

function ValidCheckSum(Message: string): boolean;

{ Returns TRUE if the check sum looks valid for the message.  Works for
  both K1EA and N6TR network. }

var
  CharPointer: integer;
  CheckSum: Word;
  K1EACheckSum: Byte;
  TempString: string;

begin
  if length(Message) < 8 then
  begin
    ValidCheckSum := False;
    Exit;
  end;

  if 1 = 1 {K1EANetworkEnable} then { K1EA network }
  begin
    K1EACheckSum := 0;

    { We count up to all but the last character }

    for CharPointer := 1 to length(Message) - 1 do
      K1EACheckSum := K1EACheckSum + Ord(Message[CharPointer]);

    K1EACheckSum := K1EACheckSum or $80;

    ValidCheckSum := K1EACheckSum = Ord(Message[length(Message)]);

    {       ValidCheckSum := True;}

    if K1EACheckSum <> Ord(Message[length(Message)]) then
      if NetDebug then
      begin
        TempString := '*** NOT VALID CHECKSUM BUT USED ANYWAY ***';
        BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
      end;
  end

  else { TR network }
  begin
    CheckSum := 0;

    for CharPointer := 1 to 5 do
      CheckSum := CheckSum + Ord(Message[CharPointer]);

    for CharPointer := 8 to length(Message) do
      CheckSum := CheckSum + Ord(Message[CharPointer]);

    ValidCheckSum := (Hi(CheckSum) = Ord(Message[6])) and
      (Lo(CheckSum) = Ord(Message[7]));
  end;
end;

function TimeToDie(var Message: string): boolean;

{ This function will decrement the hop count in the message.  If it has
  expired, it will return TRUE.  Will always return False if we are in
  the K1EANetworkMode }

var
  TimeToLive: Byte;
  CheckSum: Word;

begin
  {
    if K1EANetworkEnable then
    begin
      TimeToDie := False;
      Exit;
    end;
  }
  TimeToLive := Ord(Message[9]);
  dec(TimeToLive);

  if TimeToLive <= 0 then
  begin
    TimeToDie := True;
    Exit;
  end;

  TimeToDie := False;
  Message[9] := CHR(TimeToLive);

  CheckSum := Ord(Message[6]);
  CheckSum := Swap(CheckSum);
  CheckSum := CheckSum + Ord(Message[7]);
  dec(CheckSum);
  Message[6] := CHR(Hi(CheckSum));
  Message[7] := CHR(Lo(CheckSum));
end;

function ThisMessageIsForMe(Message: string): boolean;
var
  Destination: Byte;
  { This function will return TRUE if the message is addressed to us or is
    a broadcast message. }

begin
  if not 1 = 1 {K1EANetworkEnable} then { N6TR Network mode }
  begin
    Destination := Ord(Message[2]);

    ThisMessageIsForMe := (Destination = $FF) or
      (Destination = MultiBandAddressArray[ActiveBand]);
  end
  else
    { At this point, I am not aware of any commands on the K1EA network
      that would not be for me.  This might change as I get into it
      more }

    ThisMessageIsForMe := True;
end;

function Trim(const s: string; c: Char): string;
var
  First, Last: Integer;
begin
  First := 1;
  Last := Length(s);
  while (First <= Last) and (s[First] = c) do
    Inc(First);
  while (First < Last) and (s[Last] = c) do
    Dec(last);
  Result := Copy(s, First, Last - First + 1);
end;

function WeHaveProcessedThisMessage(Message: string): boolean;

{ This function will look at the message passed to it and see if we have
  seen this message before.  If we have, it will return TRUE.  If not, it
  will add it to the list of messages we have seen and return FALSE. }

var
  Source, Serial: Byte;
  ActiveMessage: integer;
  CheckSum: Word;

begin
  {
    if K1EANetworkEnable then // Do not expect repeat messages without retries
    begin
      WeHaveProcessedThisMessage := False;
      Exit;
    end

    else
    begin // N6TR Network Mode
      Source := ord(message[1]);
      Serial := ord(message[5]);

      CheckSum := ord(message[6]);
      CheckSum := Swap(CheckSum);
      CheckSum := CheckSum + ord(message[7]);

      CheckSum := CheckSum - ord(message[9]); // Make sure TTL isn't a factor
    end;
  }
     { See if we have a virgin list.  If so, add the entry }

  if ProcessedMultiMessagesStart = ProcessedMultiMessagesEnd then
  begin
    WeHaveProcessedThisMessage := False;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Source := Source;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Serial := Serial;
    ProcessedMultiMessages[ProcessedMultiMessagesStart].Check := CheckSum;
    inc(ProcessedMultiMessagesEnd); { Increments to one }
    Exit;
  end;

  { Start at the end of the list }

  ActiveMessage := ProcessedMultiMessagesEnd - 1;

  if ActiveMessage < 0 then
    ActiveMessage := ProcessedMultiMessageBufferLength - 1;

  repeat
    if (ProcessedMultiMessages[ActiveMessage].Source = Source) and
      (ProcessedMultiMessages[ActiveMessage].Serial = Serial) and
      (ProcessedMultiMessages[ActiveMessage].Check = CheckSum) then
    begin
      WeHaveProcessedThisMessage := True;
      Exit;
    end;

    if ActiveMessage = ProcessedMultiMessagesStart then { End of list }
    begin
      ActiveMessage := ProcessedMultiMessagesEnd;
      ProcessedMultiMessages[ActiveMessage].Source := Source;
      ProcessedMultiMessages[ActiveMessage].Serial := Serial;
      ProcessedMultiMessages[ActiveMessage].Check := CheckSum;

      inc(ProcessedMultiMessagesEnd);

      if ProcessedMultiMessagesEnd >= ProcessedMultiMessageBufferLength then
        ProcessedMultiMessagesEnd := 0;

      if ProcessedMultiMessagesEnd = ProcessedMultiMessagesStart then
      begin
        inc(ProcessedMultiMessagesStart);

        if ProcessedMultiMessagesStart >= ProcessedMultiMessageBufferLength then
          ProcessedMultiMessagesStart := 0;
      end;

      WeHaveProcessedThisMessage := False;
      Exit;
    end;

    dec(ActiveMessage);

    if ActiveMessage < 0 then
      ActiveMessage := ProcessedMultiMessageBufferLength - 1;

  until False;
end;

function ThisIsAMultiTalkMessage(MessageString: string): boolean;

begin
  {
    if K1EANetworkEnable then
      ThisIsAMultiTalkMessage := MessageString[1] = 'T'
    else
      ThisIsAMultiTalkMessage := ord(MessageString[3]) = MultiTalkMessage;
     }
end;

function GetMultiPortCommand: string;

{ This will retrieve a multi command string from the MultiReceiveCharBuffer.
  It works for either K1EA or N6TR network modes!! }

var
  TempString: string;

begin
  //WLI ????????
//  Result := TR4W_MULTIMESSAGE_STRING;
  Exit;

  GetMultiPortCommand := '';

  if TempString = '' then
    Exit;

  if NetDebug then
    BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));

  if not ValidCheckSum(TempString) then { Works for TR and CT }
  begin
    if NetDebug then
    begin
      TempString := '*** NOT VALID CHECKSUM ***';
      BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
    end;

    Exit;
  end;

  { Okay, we have a valid message to deal with.  If it is one of ours,
    we will ignore it, unless it was MultiTalkMessage }

  if ISentThisMultiMessage(TempString) then { It is one of ours }
  begin
    if ThisMessageIsForMe(TempString) then
      if not WeHaveProcessedThisMessage(TempString) then
        if ThisIsAMultiTalkMessage(TempString) then
          GetMultiPortCommand := TempString; { Process my own message }

    Exit;
  end;

  { If this message has been hoping around too long, ignore it }

  if TimeToDie(TempString) then
    Exit;

  { Okay, we have a valid message, and it isn't ours, pass it on. }

  if not ThisMessageIsForMe(TempString) then
    Exit;

  { We have a message for me to act on (unless I have already seen it) }

  if WeHaveProcessedThisMessage(TempString) then
  begin
    if NetDebug then
    begin
      TempString := '*** PROCESSED BEFORE ***';
      BlockWrite(NetDebugBinaryInput, TempString[1], length(TempString));
    end;

    Exit;
  end;

  GetMultiPortCommand := TempString;
end;

procedure RememberSentMessage(MultMessage: string);

{ This procedure will take the message that was sent and remember it along
  with a time stamp, so that if it doesn't get QSLed after a certain amount
  of time, the message can be resent. }

begin
  with MultiRememberBuffer^[FirstMultiMessage] do
  begin
    Message := MultMessage;
    MarkTime(TimeMark);
    RetryCount := 0;
    QSL := False;
    Warnings := 0;
  end;

  FirstMultiMessage := (FirstMultiMessage + 1) mod MultiMessageBufferSize;

  if FirstMultiMessage = LastMultiMessage then
    LastMultiMessage := (LastMultiMessage + 1) mod MultiMessageBufferSize;

end;

procedure SendMultiCommand(Source: Byte; Destination: Byte; ControlByte: Byte;
  Message: string);

begin

end;

procedure StuffInit;
begin
  DVKStamp;
end;

procedure SpeedUp;
begin
  if CodeSpeed < (99 - CodeSpeedIncrement) then {KK1L: 6.72}
  begin
    SetSpeed(CodeSpeed + CodeSpeedIncrement); {KK1L: 6.72}
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end;
end;

procedure ShowPreviousDupeQSOs(Call: CallString;
  Band: BandType;
  Mode: ModeType);
label
  1;
  { This routine will display previous duplicate QSOs with the station
    indicated. }

var
  TempIndex: integer;
  FirstTime: boolean;
begin
  if Call = '' then
    Exit;
  TempIndex := 0;
  FirstTime := True;
  if not OpenLogFile then
    Exit;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if ((Band = TempRXData.Band) or not QSOByBand) and
      ((Mode = TempRXData.Mode) or not QSOByMode) then

      if TempRXData.Callsign = Call then
      begin
        if FirstTime then
        begin
          ShowPreviousDupeQSOsWnd(True);
          ListView_DeleteAllItems(tPreviousDupeQSOsWndHandle);
          FirstTime := False;
        end;
        tAddContestExchangeToLog(TempRXData, tPreviousDupeQSOsWndHandle,
          TempIndex);

      end;
    goto 1;
  end;
  if not FirstTime then
    EnsureListViewColumnVisible(tPreviousDupeQSOsWndHandle);
  CloseLogFile;
end;

procedure SlowDown;

begin
  {IF CodeSpeed > 4 THEN}
  if CodeSpeed > (CodeSpeedIncrement + 1) then {KK1L: 6.72}
  begin
    {SetSpeed (CodeSpeed - 3);}
 //   CW_SPEED1 := CW_SPEED1 - CodeSpeedIncrement;
    SetSpeed(CodeSpeed - CodeSpeedIncrement); {KK1L: 6.72}
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end;
end;


procedure PushMultiMessageBuffer(Message: Str80);

begin

end;

procedure DisplayMultiMessageBuffer;

begin
  //   if ActiveMultiPort <> NoPort then
  begin

  end;
end;

procedure DisplayGridSquareStatus(Call: CallString);

var
  Range, Address: integer;
  Change: boolean;
  TempCall: CallString;

begin
  NumberGridSquaresInList := 0;

  if (ActiveDomesticMult = GridSquares) {wli and RoverCall(Call)} then
  begin
    CreateGridSquareList(Call, ActiveBand);

    if NumberGridSquaresInList > 0 then
    begin
      if NumberGridSquaresInList > 1 then
      begin
        Range := NumberGridSquaresInList - 2;

        repeat
          Change := False;

          for Address := 0 to Range do
            if GridSquareList[Address] > GridSquareList[Address + 1] then
            begin
              TempCall := GridSquareList[Address];
              GridSquareList[Address] := GridSquareList[Address + 1];
              GridSquareList[Address + 1] := TempCall;
              Change := True;
            end;

          dec(Range);
        until (not Change) or (Range < 0);
      end;

      //      SaveSetAndClearActiveWindow(EditableLogWindow);

      for Address := 0 to NumberGridSquaresInList - 1 do
      begin
        //{WLI}                IF WhereX >= 76 THEN WriteLn;

        //{WLI}                IF WhereX > 1 THEN Write (' ');

        //{WLI}                Write (GridSquareList [Address]);

        //   FRM.POSSIBLECALLWINDOW.Items.Add(GridSquareList [Address]);
      end;

      //            //RestorePreviousWindow;

      GridSquareListShown := True;
    end;
  end;
end;

function LogFileLooksOkay: boolean;

{ Returns TRUE if the LOG.DAT file looks about right for the number of
  QSOs the program thinks we have }

begin
  Result := False;
  if not OpenLogFile then
    Exit;
  if Windows.GetFileSize(LogHandle, nil) = tRestartInfo.riTotalRecordsInLog
    {QSOTotals[All, Both] } * SizeOf(ContestExchange) + SizeOfTLogHeader then
    Result := True;
  CloseLogFile;

  
end;

procedure NextPage;

begin

  //W_L_I  if PrinterEnabled then
  //W_L_I  begin
{$I-}
  //{WLI}        Write (Lst, ControlL);
  //{WLI}        IF IOResult <> 0 THEN SendMorse ('     PRINTER FAILURE');
{$I+}
  //W_L_I  end;

end;

procedure CalculateQSOPoints(var RXData: ContestExchange);

var
  PtsMult, Points, MyZoneValue, Result: integer;
  Distance: LONGINT;
  RTCDistKm: Double; // Issue #902 -- RTC contest Haversine distance
  {RRC, MRC,} RXCty, TheirID, CountryID: CallString; // 4.72.5
  TempOblast: string[2];
  la1, la2, lo1, lo2: integer;
  Grid1, Grid2: GridString;
  russianRegion1, russianRegion2: RussianRegionType;
  temphour: byte; // 4.58.2
  iotastate, k: string[10];
  i, j: integer;
  //s1, s2, s3, s4: string[10];
  Str1: string[4];
  Str2: string[2];
  Str3: string[4];
  Str4: string[2];
begin
  RXData.QSOPoints := 0;
  RXCty := RXData.QTH.CountryID; // 4.67.1

  if (QSOPointsDomesticCW >= 0) and (RXData.Mode = CW) and (RXData.DomesticQTH  <>  '') then
  begin
    RXData.QSOPoints := QSOPointsDomesticCW;
    Exit;
  end;

  if (QSOPointsDXCW >= 0) and (RXData.Mode = CW) and (RXData.DomesticQTH = '')
    then
  begin
    RXData.QSOPoints := QSOPointsDXCW;
    Exit;
  end;

  if (QSOPointsDomesticPhone >= 0) and (RXData.Mode = Phone) and
    (RXData.DomesticQTH <> '') then
  begin
    RXData.QSOPoints := QSOPointsDomesticPhone;
    Exit;
  end;

  if (QSOPointsDXPhone >= 0) and (RXData.Mode = Phone) and (RXData.DomesticQTH =
    '') then
  begin
    RXData.QSOPoints := QSOPointsDXPhone;
    Exit;
  end;

  case ActiveQSOPointMethod of

    CFOQP:
      begin
        RXData.QSOPoints := 0;
        if RXData.Mode = Phone then
          RXData.QSOPoints := 4
        else
          RXData.QSOPoints := 2;
        if RXData.QTHString = MyGrid then
          points := 0
        else
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.QTHString);
          Points := Floor(Distance / 1000);
          if Points = 0 then
            Points := 1;
          RXData.QSOPoints := Points + RXData.QSOPoints;
        end;
      end;

    AllAsianQSOPointMethod:
      begin
        if MyContinent = Asia then
        begin
          if RXData.QTH.Continent <> Asia then
          begin
            case RXData.Band of
              Band160: RXData.QSOPoints := 9;
              Band80: RXData.QSOPoints := 6;
              Band10: RXData.QSOPoints := 6;
            else
              RXData.QSOPoints := 3;
            end;
          end
          else if MyCountry <> RXCty then
          begin
            case RXData.Band of
              Band160: RXData.QSOPoints := 3;
              Band80: RXData.QSOPoints := 2;
              Band10: RXData.QSOPoints := 2;
            else
              RXData.QSOPoints := 1;
            end;
          end
          else
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True; { Same country }
          end;

        end

        else { I am not in Asia }if RXData.QTH.Continent = Asia then
          begin
            case RXData.Band of
              Band160: RXData.QSOPoints := 3;
              Band80: RXData.QSOPoints := 2;
              Band10: RXData.QSOPoints := 2;
            else
              RXData.QSOPoints := 1;
            end;
          end
          else
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True;
          end;

      end;

    ARCIQSOPointMethod:
      begin
        if StringIsAllNumbers(RXData.Power) then
          RXData.QSOPoints := 5
        else if MyContinent = RXData.QTH.Continent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 4;
      end;

    ARIQSOPointMethod:
      if (RXCty = 'I') or (RXCty = 'IS') or (RXCty = '*IT9') then
        //      if RXCty[1] = 'I' then
        RXData.QSOPoints := 10
      else if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else if RXCty <> MyCountry then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 0;

    ARRLDXQSOPointMethod:
      if (MyCountry = 'K') or
        (MyCountry = 'VE') then
      begin
        if (RXCty <> 'K') and (RXCty <> 'VE') then
          RXData.QSOPoints := 3
        else
        begin
          RXData.QSOPoints := 0;
          RXData.InhibitMults := True;
        end;
      end
      else if (RXCty = 'K') or (RXCty = 'VE') then
        RXData.QSOPoints := 3
      else
      begin
        RXData.QSOPoints := 0;
        RXData.InhibitMults := True;
      end;

    ARRLFieldDayQSOPointMethod:
      {      // Why was this commented out? For this year?
            if StringHas(UpperCase(MyFDClass), 'D') and
              StringHas(UpperCase(RXData.ceClass), 'D') then
              RXData.QSOPoints := 0
            else
      }
      begin
        if RXData.Mode in [Phone, FM] then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 2;

        {if StringHas(UpperCase(MyFDClass), 'D') and
          StringHas(UpperCase(RXData.ceClass), 'D') then
        begin
          RXData.QSOPoints := 0;
        end;} // Removed this restriction at it continues for 2022 and perhaps beyond. // Issue 575
      end;
    ARRLDIGIQSOPointMethod: // Issue 577
      if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
      begin
        if AnsiCompareStr(MyGrid, RXData.QTHString) = 0 then
        begin
          RXData.QSOPoints := 2;
        end
        else
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.QTHString);
          RXData.QSOPoints := Ceil((Distance / 500)) + 1;
        end;
      end;

    ARRL160QSOPointMethod:
      if DomesticCountryCall(RXData.Callsign) then
        RXData.QSOPoints := 2
      else if DomesticCountryCall(MyCall) then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 0;

    ARRL10QSOPointMethod:
      {
            if ((Copy(RXData.Callsign, length(RXData.Callsign) - 1, 2) = '/T') or
              (Copy(RXData.Callsign, length(RXData.Callsign) - 1, 2) = '/N')) and
              (RXData.Mode = CW) then
              RXData.QSOPoints := 8
            else
      }
      if RXData.Mode = CW then
        RXData.QSOPoints := 4
      else
        RXData.QSOPoints := 2;

    ARRLVHFJUNPointMethod:

      case RXData.Band of
        Band6: RXData.QSOPoints := 1;
        Band2: RXData.QSOPoints := 1;
        Band222: RXData.QSOPoints := 2;
        Band432: RXData.QSOPoints := 2;
        Band902: RXData.QSOPoints := 3;
        Band1296: RXData.QSOPoints := 3;
        Band2304: RXData.QSOPoints := 4;
        Band3456: RXData.QSOPoints := 4;
        Band5760: RXData.QSOPoints := 4;
        Band10G: RXData.QSOPoints := 4;
        Band24G: RXData.QSOPoints := 4;
        BandLight: RXData.QSOPoints := 4;
      else
        RXData.QSOPoints := 0;
      end;

    ARRLVHFSSPointMethod:
      case RXData.Band of
        Band6: RXData.QSOPoints := 1;
        Band2: RXData.QSOPoints := 1;
        Band222: RXData.QSOPoints := 2;
        Band432: RXData.QSOPoints := 2;
        Band902: RXData.QSOPoints := 4;
        Band1296: RXData.QSOPoints := 4;
        Band2304: RXData.QSOPoints := 8;
        Band3456: RXData.QSOPoints := 8;
        Band5760: RXData.QSOPoints := 8;
        Band10G: RXData.QSOPoints := 8;
        Band24G: RXData.QSOPoints := 8;
        BandLight: RXData.QSOPoints := 8;
      else
        RXData.QSOPoints := 0;
      end;

    ALRSUA1DZCupQSOPointMethod:
      begin
        Windows.ZeroMemory(@Grid1, SizeOf(Grid1));
        Windows.ZeroMemory(@Grid2, SizeOf(Grid2));

        russianRegion1 := rtUnknownRegion;
        russianRegion2 := rtUnknownRegion;

        Windows.ZeroMemory(@TempOblast, SizeOf(TempOblast));
        if RussianID(MyCountry) then
        begin
          TempOblast := GetOblast(MyCall);
          russianRegion1 := GetRussiaOblastByTwoChars(TempOblast[1],
            TempOblast[2]);
        end;

        Windows.ZeroMemory(@TempOblast, SizeOf(TempOblast));
        if RussianID(RXData.Callsign) then
        begin
          TempOblast := GetOblast(RXData.Callsign);
          russianRegion2 := GetRussiaOblastByTwoChars(TempOblast[1],
            TempOblast[2]);
        end;

        if (russianRegion1 in [rtUA1A, rtUA1C]) then
          Grid1 := 'KO59'
        else
          Grid1 := MyState;

        if (russianRegion2 in [rtUA1A, rtUA1C]) then
          Grid2 := 'KO59'
        else
          Grid2 := RXData.QTHString;

        if ((Grid1[1] = Grid2[1]) and (Grid1[2] = Grid2[2])) then
          RXData.QSOPoints := 5
        else
        begin
          Distance := GetDistanceBetweenGrids(Grid1, Grid2);
          RXData.QSOPoints := round(10 * ln(Distance) / ln(10));
        end;

        if not (russianRegion1 in [rtUA1A, rtUA1C]) then
          if (russianRegion2 in [rtUA1A, rtUA1C]) then
          begin
            RXData.QSOPoints := RXData.QSOPoints + 50;
          end;

        {
                if RussianID(MyCountry) then
                begin

        TempOblast

        GetDistanceBetweenGrids
          Oblast := GetOblast(Call);
          if length(Oblast) < 2 then Exit;
          reg := GetRussiaOblastByTwoChars(Oblast[1], Oblast[2]);
          }
      end;

    BalticQSOPointMethod:
      begin
        if (MyCountry = 'ES') or (MyCountry = 'YL') or (MyCountry = 'LY') then
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
        end
        else if (RXCty = 'ES') or (RXCty = 'YL') or (RXCty = 'LY') then
        begin
          if MyContinent = Europe then
            RXData.QSOPoints := 10
          else
            RXData.QSOPoints := 20;
        end
        else
          RXData.QSOPoints := 1;
      end;

    BWQPQSOPointMethod:

      if StringIsAllNumbers(RXData.QTHString) then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 0;

    CISQSOPointMethod:
      begin
        RXData.QSOPoints := 1;

        if RXCty <> MyCountry then
        begin
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;

        if not CISCountry(MyCountry) then
          if CISCountry(RXCty) then
            RXData.QSOPoints := 5;

      end;

    CQ160QSOPointMethod: // 4.77.6
      begin

        if RXCty = MyCountry then

          RXData.QSOPoints := 2
        else if (RXCty <> MyCountry) and (RXData.QTH.Continent = MyContinent)
          then
          RXData.QSOPoints := 5
        else
          RXData.QSOPoints := 10;
      end;

    CQMQSOPointMethod:
      begin
        if RussianID(MyCountry) then
        begin
          if not RussianID(RXCty) then
          begin
            if (RXData.QTH.Continent in [Europe, Asia]) then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 3;
          end
          else if InSameFederalOkrug(RXData.Callsign) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
        end
          {Outside Russia}
        else
        begin
          if RussianID(RXCty) then
          begin
            if (MyContinent in [Europe, Asia]) then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 3;
            Exit;
          end;
          if MyCountry = RXCty then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
          if MyContinent <> RXData.QTH.Continent then
            RXData.QSOPoints := 3;
        end;

      end;

    CQVHFQSOPointMethod:
      begin
        case RXData.Band of
          { Band6, Band2:      RXData.QSOPoints := 1;} {KK1L: 6.73 new rules for 2002}
          { Band222, Band432:  RXData.QSOPoints := 2;} {KK1L: 6.73 new rules for 2002}
          { Band902, Band1296: RXData.QSOPoints := 4;} {KK1L: 6.73 new rules for 2002}
          { Band2304:          RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          { Band3456:          RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          { Band5760:          RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          { Band10G:           RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          { Band24G:           RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          { BandLight:         RXData.QSOPoints := 6;} {KK1L: 6.73 new rules for 2002}
          Band2: RXData.QSOPoints := 2; {KK1L: 6.73 new rules for 2002}
          Band6: RXData.QSOPoints := 1; {KK1L: 6.73 new rules for 2002}
          //      else RXData.QSOPoints := 0;
        end;

        //        if (RXData.Mode = CW) and (RXData.QSOPoints > 0) then inc(RXData.QSOPoints);
      end;

    HolyLand: // 4.120.3
      begin
        if MyCountry = '4X' then
        begin
          if RXCTY = '4X' then
          begin
            RXData.QSOPoints := 1;
            exit;
          end;
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 8;
        end
        else // outside of 4X
        begin
          if MyCountry = RXCTY then // 4x to 4x qso
          begin
            RXData.QSOPoints := 1;
            exit;
          end;
          if RXCTY = '4X' then // DX to 4X
          begin
            RXData.QSOPoints := 8;
            exit;
          end;
          if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 4
          else
            RXData.QSOPoints := 2;
        end;
      end;

    OQPQSOPointMethod: // 4.70.7
      // 3ODX, 3RAC and 3CCO -   10 points (CW and SSB)
      begin
        if RXData.QTH.CountryID = 'VE' then
        begin
          if ((pos('3ODX', RXData.Callsign) > 0) or (pos('3RAC',
            RXData.Callsign)
            > 0) or (pos('3CCO', RXData.Callsign) > 0)) then
          begin
            RXData.QSOPoints := 10;
            exit;
          end;
        end;
        if ActiveMode = CW then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;
      end;

    CQWPXQSOPointMethod:
      if RXData.QTH.Continent = MyContinent then
      begin
        if RXCty = MyCountry then
          RXData.QSOPoints := 1
        else
        begin
          case RXData.Band of
            Band160: RXData.QSOPoints := 2;
            Band80: RXData.QSOPoints := 2;
            Band40: RXData.QSOPoints := 2;
            Band20: RXData.QSOPoints := 1;
            Band15: RXData.QSOPoints := 1;
            Band10: RXData.QSOPoints := 1;
          end;

          if MyContinent = NorthAmerica then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
        end;
      end
      else
        case RXData.Band of
          Band160: RXData.QSOPoints := 6;
          Band80: RXData.QSOPoints := 6;
          Band40: RXData.QSOPoints := 6;
          Band20: RXData.QSOPoints := 3;
          Band15: RXData.QSOPoints := 3;
          Band10: RXData.QSOPoints := 3;
        end;

    CQWPXRTTYQSOPointMethod:
      begin
        if RXData.QTH.Continent = MyContinent then
        begin
          if RXCty = MyCountry then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2
        end
        else
          RXData.QSOPoints := 3;

        if (RXData.Band = Band80) or (RXData.Band = Band40) then
          RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
      end;

    DLRTTY:
      { QSO with own country: 5 points.
      QSO with other countries in own continent: 10 points.
      QSO with other continents: 15 points.
      QSO with DL-Station by stations in Europe: 3 additional points
      QSO with DL-Station by stations outside Europe: 5 additional points
      }
      begin
        if (MyCountry = '') or (MyContinent = UnknownContinent) then
        begin
          RXData.QSOPoints := 10;
          exit;
        end;

        if MyCountry = RxData.QTH.countryid then
          RXData.QSOPoints := 5
        else if rxdata.QTH.Continent = MyContinent then
          RXData.QSOPoints := 10
        else
          RXData.QSOPoints := 15;

        if ContestTitle = 'DL-DX-RTTY' then
          if RXCty = 'DL' then
            if rxdata.QTH.Continent <> MyContinent then
              RXData.QSOPoints := RXData.QSOPoints + 5
            else
              RXData.QSOPoints := RXData.QSOPoints + 3;
      end;

    JAKARTARTTY: // 4.74.2
      if RXCty = 'YB' then
        RXData.QSOPoints := 50
      else if rxdata.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 3;

    CQWWQSOPointMethod:
      if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else if RXCty <> MyCountry then
        if MyContinent <> NorthAmerica then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 0;

    CQWWRTTYQSOPointMethod:
      if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 3
      else if RXCty <> MyCountry then
        RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 1;

    CroatianQSOPointMethod:
     begin
      if (MyCountry = '9A') and (RxData.QTH.countryid = '9A') then
       begin
        RXData.QSOPoints := 1;
        exit;
       end;

       if MyCountry = '9A' then
        begin
         if RXData.QTH.Continent = Europe then

           case RXData.Band of
             Band160: RXData.QSOPoints := 4;
             Band80:  RXData.QSOPoints := 4;
             Band40:  RXData.QSOPoints := 2;
             Band20:  RXData.QSOPoints := 2;
             Band15:  RXData.QSOPoints := 2;
             Band10:  RXData.QSOPoints := 2;
           end;
         if RXData.QTH.Continent <> Europe then

           case RXData.Band of
             Band160: RXData.QSOPoints := 10;
             Band80:  RXData.QSOPoints := 10;
             Band40:  RXData.QSOPoints := 8;
             Band20:  RXData.QSOPoints := 6;
             Band15:  RXData.QSOPoints := 6;
             Band10:  RXData.QSOPoints := 6;
          end;
          exit;
         end;


      if (MyCountry <> '9A') and (RXCty = '9A') then
      
        case RXData.Band of
          Band160: RXData.QSOPoints := 10;
          Band80: RXData.QSOPoints := 10;
          Band40: RXData.QSOPoints := 10;
          Band20: RXData.QSOPoints := 6;
          Band15: RXData.QSOPoints := 6;
          Band10: RXData.QSOPoints := 6;
        end;
     if RXData.QTH.Continent = MyContinent then
        case RXData.Band of
          Band160: RXData.QSOPoints := 2;
          Band80: RXData.QSOPoints := 2;
          Band40: RXData.QSOPoints := 2;
          Band20: RXData.QSOPoints := 1;
          Band15: RXData.QSOPoints := 1;
          Band10: RXData.QSOPoints := 1;
        end;

    if (MyCountry <> '9A') and (MyContinent <> RXData.QTH.Continent) and (RXCTY <> '9A') then
        case RXData.Band of
          Band160: RXData.QSOPoints := 6;
          Band80: RXData.QSOPoints := 6;
          Band40: RXData.QSOPoints := 6;
          Band20: RXData.QSOPoints := 3;
          Band15: RXData.QSOPoints := 3;
          Band10: RXData.QSOPoints := 3;
        end;
         tGetSystemTime;
          TempHour := UTC.wHour;
          if (TempHour >= 23) or (TempHour < 05) then
            RxData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;  
          // double points if gmthours
      end;

    EuropeanFieldDayQSOPointMethod:
      begin
        RXData.QSOPoints := 1;

        CountryID := MyCountry;

        if (CountryID = 'F') or (CountryID = 'OE') then
        begin
          if RXCty = MyCountry then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 50
            else
              RXData.QSOPoints := 10;
          end
          else if RXData.QTH.Continent = Europe then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 5
            else
              RXData.QSOPoints := 1;
          end
          else
            RXData.QSOPoints := 3;

          Exit;
        end;

        if CountryID = 'OZ' then
        begin
          if RXCty = MyCountry then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 10
            else
              RXData.QSOPoints := 1;
          end
          else if RXData.QTH.Continent = Europe then
          begin
            if PortableStation(RXData.Callsign) then
              RXData.QSOPoints := 5
            else
              RXData.QSOPoints := 3;
          end
          else
            RXData.QSOPoints := 6;

          Exit;
        end;

        if CountryID = 'HB' then
        begin
          if PortableStation(RXData.Callsign) then
            RXData.QSOPoints := 5
          else if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
          Exit;
        end;

        if CountryID = 'I' then
        begin
          if PortableStation(RXData.Callsign) then
            RXData.QSOPoints := 6
          else if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;

          if (RXData.Band = Band160) or (RXData.Band = Band80) then
            RXData.QSOPoints := RXData.QSOPoints * 2;
          Exit;
        end;

        { Anywhere else, including DL and PA }

        if PortableStation(RXData.Callsign) then
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 4
          else
            RXData.QSOPoints := 6;
        end
        else
        begin
          if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;

        if CountryID[1] = 'G' then
          if (RXData.Band = Band160) or (RXData.Band = Band10) then
            RXData.QSOPoints := RXData.QSOPoints * 2;

      end;

    EuropeanSprintQSOPointMethod:
      if MyContinent = Europe then
        RXData.QSOPoints := 1
      else if RXData.QTH.Continent = Europe then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 0;

    FOCMarathonQSOPointMethod:

      if RXData.Callsign = 'G4FOC' then
        //    if RXData.Callsign = GM4FOC then
        RXData.QSOPoints := 2

      else
        RXData.QSOPoints := 1;

    RadioVHFFDQSOPointMethod {, ChampionshipRFVHFQSOPointMethod}:
      begin
        if MyGrid <> '' then
        begin
          Points := GetDistanceBetweenGrids
            {GetEuropeanDistanceBetweenGrids}(MyGrid,
            RXData.DomesticQTH);
          if RXData.Band = Band2 then
            RXData.QSOPoints := Points * 1 // 4.60.4
          else if RXData.Band = Band432 then
            RXData.QSOPoints := Points * 2 // 4.60.4
          else if RXData.Band = Band1296 then
            RXData.QSOPoints := Points * 4 // 4.60.6
          else if RXData.Band in [Band2304, Band3456, Band5760, Band10G,
            Band24G, BandLight] then // 4.81.2
            RXData.QSOPoints := Points * 6 // 4.60.6
          else
            RXData.QSOPoints := 0;

        end;
      end;

    MakrothenQSOPointMethod:
      begin
        if MyGrid <> '' then
        begin
          if Copy(MyGrid, 1, 4) = Copy(RXData.DomesticQTH, 1, 4) then
            RXData.QSOPoints := 100
          else
          begin
            RXData.QSOPoints := GetDistanceBetweenGrids(MyGrid,
              RXData.DomesticQTH);
            if RXData.Band = Band40 then
              RXData.QSOPoints := round(RXData.QSOPoints * 1.5);

            if RXData.Band = Band80 then
              RXData.QSOPoints := RXData.QSOPoints * 2;
          end;

        end;
      end;

    NCQSOPointMethod: // 4.66.1      // updated 4.97.9
      begin

        if RXData.Mode = PHONE then
          RXDATA.QSOPoints := 2
        else if RXData.Mode = CW then
          RXDATA.QSOPoints := 3
        else
          RXDATA.QSOPoints := 5; // digital
        if RXData.Callsign = 'N4T' then
          rxdata.QSOPoints := rxdata.qsopoints + 50; // 4.86.3
        if RXData.Callsign = 'N4A' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if RXData.Callsign = 'N4R' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if RXData.Callsign = 'N4H' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if RXData.Callsign = 'N4E' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if RXData.Callsign = 'W4E' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if RXData.Callsign = 'N4L' then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
        if (RXData.DomesticQTH = 'ALL') or (RXData.DomesticQTH = 'COL') then
          rxdata.QSOPoints := rxdata.qsopoints + 50;
      end;

    BCQPQSOPointMethod:
      begin
        if RXData.Mode = PHONE then
          RXDATA.QSOPoints := 2
        else
          RXDATA.QSOPoints := 4;
        {   if RXData.Callsign = 'VA7ODX' then
             rxdata.QSOPoints := rxdata.qsopoints + 20;    }
      end;

    PAQSOPointMethod: // 4.74.3
      begin

        if RXData.Mode = PHONE then
          RXDATA.QSOPoints := 1
        else
          RXDATA.QSOPoints := 2;
      end;

    RCCVHFQP:
      begin
        if MyGrid <> '' then
        begin
          Points := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
          if RXData.Band = Band2 then
            RXData.QSOPoints := Points
          else if RXData.Band = Band432 then
            RXData.QSOPoints := 2 * Points
          else if RXData.Band = Band1296 then
            RXData.QSOPoints := 4 * points
          else if RXData.Band > Band1296 then
            RXData.QSOPoints := 6 * points;
        end;
      end;

    OZHCRVHFQSOPointMethod:
      if MyGrid <> '' then
      begin
        Points := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
        if RXData.Band = Band2 then
          RXData.QSOPoints := Points;
        if RXData.Band = Band432 then
          RXData.QSOPoints := Points * 2;
        if RXData.Band = Band1296 then
          RXData.QSOPoints := Points * 4;
        if RXData.Band > Band1296 then
          RXData.QSOPoints := Points * 6;
      end;

    EuropeanVHFQSOPointMethod:
      //      if MyGrid <> '' then
      //        if RXData.DomesticQTH <> '' then
      begin
        //    RXData.QSOPoints := GetEuropeanDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
        if ContestName = 'EURASIA' then // 4.96.3
          RXData.QSOPoints := GetDistanceBetweenGrids(MyGrid, RXData.QTHString)
            // domestic truncated to 2 bytes. need this 6bytes
        else
          RXData.QSOPoints := GetDistanceBetweenGrids(MyGrid,
            RXData.DomesticQTH);
        //n4af 4.36.11
        if MyCountry = '9A' then
        begin
          if RXData.Band = Band432 then
            RXData.QSOPoints := RXData.QSOPoints * 5;
          if RXData.Band = Band1296 then
            RXData.QSOPoints := RXData.QSOPoints * 10;
          if RXData.Band = Band2304 then
            RXData.QSOPoints := RXData.QSOPoints * 20;
          if RXData.Band in [Band3456, Band5760, Band10G] then
            RXData.QSOPoints := RXData.QSOPoints * 30;
          if RXData.Band = Band24G then
            RXData.QSOPoints := RXData.QSOPoints * 100;
        end;
      end;

    TeslaQSOPointMethod: // 4.79.1
      //      if MyGrid <> '' then
      //        if RXData.DomesticQTH <> '' then
      begin
        Distance := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
        case distance of
          0..600: RXData.QSOPoints := 10;
          601..1200: RXData.QSOPoints := 13;
          1201..1800: RXData.QSOPoints := 16;
          1801..2400: RXData.QSOPoints := 20;
          2401..3600: RXData.QSOPoints := 24;
          3601..4800: RXData.QSOPoints := 28;
          4801..6000: RXData.QSOPoints := 32;
          6001..7200: RXData.QSOPoints := 36;
          7201..8400: RXData.QSOPoints := 40;
        else
          RXData.QSOPoints := 45;
        end;

        { revised points 2019 rules:    // 4.79.1
        Points are calculated based on the distance between the centers of the middle of QTH grids:

       Up to 600 km = 10 points

       601 - 1200 km = 13 points

       1201 - 1800 km = 16 points

       1801 - 2400 km = 20 points

       2401 - 3600 km = 24 points

       3600 - 4800 km = 28 points

       4801 - 6000 km = 32 points

       6001 - 7200 km = 36 points

       7201 - 8400 km = 40 points

       above 8401 km = 45 points

          //n4af 4.36.11
         if RXData.DomesticQTH = MyGrid then
           RXData.QSOPoints := 90; }
        DisplayTotalScore;
      end;

    FistsQSOPointMethod:
      if RXData.NumberReceived > 0 then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 2;

    HADXQSOPointMethod: // 4.84.2
      begin

        if RXData.QTH.CountryID = 'HA' then // 4.67.11
        begin
          RXData.QSOPoints := 10;
          exit;
        end;

        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 5
        else
          RXData.QSOPoints := 2;
      end;

    TRCDIGITAL:
      begin
        if rxdata.domesticqth = 'TRC' then
          RXData.QSOPoints := 10
        else if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;
        if (MyState = 'TRC') and (RXData.DomesticQTH = 'TRC') then
          // throw away above & use one point -if- fellow TRC
          RXData.QSOPoints := 1;
      end;

    XERTTY: // 4.77.5
      begin
        if MyCountry = 'XE' then
          if RXCty <> 'XE' then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 4;

        if RXData.QTH.CountryID = 'XE' then
        begin
          RXData.QSOPoints := 4;
          exit;
        end;
        if RXData.QTH.CountryID <> MyCountry then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 2;
      end;

    YUDXQSOPointMethod: // 4.57.5
      if (MyCountry <> 'YU') and (RXCty = 'YU') then
        RXData.QSOPoints := 10
      else if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 4
      else if RXCty <> MyCountry then
        RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 1;

    UKEIQSOPointMethod: // 4.58.2
      begin
        if (MyContinent <> Europe) then // if OOUTSIDE EUROPE
        begin
          if UKEIStation(RXData.Callsign) then
            RXData.QSOPoints := 4
          else if RxData.QTH.Continent = Europe then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;
        end;

        if ((MyContinent = Europe) and (not UKEIStation(MyCountry))) then
          // if IN Europe
        begin
          if (RxData.QTH.Continent = Europe) and (not
            UKEIStation(RxData.CallSign)) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
        end;

        if UKEIStation(MyCountry) then // if IN UK/EI
        begin
          if RxData.QTH.Continent = Europe then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 4;
          tGetSystemTime;
          TempHour := UTC.wHour;
          if (TempHour >= 01) and (TempHour < 05) then
            RxData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
          // double points if gmthours
        end;

        case RxData.Band of
          Band80, Band40: RxData.QSOPoints := RXData.QSOPoints +
            RXData.QSOPoints;
        end;

      end;

    MWCQP: // 4.98.1
      begin
        RXData.QSOPoints := 1;
        j := length(rxdata.callsign); // 4.98.3
        k := RXdata.callsign;
        for i := 1 to j do // 4.98.3
          if ((k[i] = '/') and (k[i + 1] in ['A'..'Z'])) then
            // rules only speicify mult number following slash
          begin
            RXData.DomMultQTH := k[i - 1];
            //[length(call)];    // throw away all after '/'
            exit;
          end;
        RXData.DomMultQTH := k[j]; //[length(call)];   // 4.98.
      end;

    HelvetiaQSOPointMethod: // issue 214
      if RXCty = 'HB' then
        RXData.QSOPoints := 10
      else if RXData.QTH.Continent = MyContinent then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 3;

    BSCIQSOPointMethod:
      begin
        Val(MyZone, MyZoneValue, Result);
        if RXData.Zone = MyZoneValue then
          RXData.QSOPoints := 1
        else if RXData.QTH.Continent = MyContinent then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 5;

        if (BlackSeaRegionCountry(RXCty)) or (Copy(RXData.QTHString, 1, 2) =
          'BS') then
          RXData.QSOPoints := 10;
      end;

    SRRQSOPointMethod: // 4.90.4
      if RXData.DomesticQTH = '' then
      begin
        Val(MyZone, MyZoneValue, Result);

        if RXData.Zone = MyZoneValue then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 3;
      end
      else
        RXData.QSOPoints := 1;

    IARUQSOPointMethod:
      if RXData.DomesticQTH = '' then
      begin
        //        Val(RXData.Zone, RXDataZoneValue, RESULT);
        Val(MyZone, MyZoneValue, Result);

        if RXData.Zone = MyZoneValue then
          RXData.QSOPoints := 1
        else if RXData.QTH.Continent = MyContinent then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 5;
      end
      else
        RXData.QSOPoints := 1;
    {
      if RXData.DomesticQTH = '' then
      begin
        Val(RXData.Zone, RXDataZoneValue, RESULT);
        Val(MyZone, MyZoneValue, RESULT);

        if RXDataZoneValue = MyZoneValue then
          RXData.QSOPoints := 1
        else
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
      end
      else
        RXData.QSOPoints := 1;
        }
    InternetSixQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else if MyContinent <> NorthAmerica then
          RXData.QSOPoints := 1
        else
        begin
          TheirID := RXCty;
          if TheirID = 'VE' then
            TheirID := 'K';

          if {(MyCounty <> 'K') and}(MyCountry <> 'VE') then
          begin { I am DX }
            if TheirID = 'K' then
              RXData.QSOPoints := 3
            else
              RXData.QSOPoints := 1;
          end
          else if TheirID <> 'K' then { I am W/VE }
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 1;
        end;
      end;

    IOTAQSOPointMethod: // 4.102.6
      begin
        if MyState = '' then // 4.61.3 change points
        begin
          if RXData.domesticQTH <> '' then
            RXData.QSOpoints := 15
          else
            RXData.QSOpoints := 2;
          exit;
        end;
        IOTASTATE := RXDATA.DomesticQTH;
        if pos('-', MyState) > 0 then
          if (MyState = IOTAState) or (RXData.DomesticQTH = '') then
            RXData.QSOPoints := 5
          else
            RXData.QSOPoints := 15;

        if (RXData.DomesticQTH <> '') and (MyState <> RXData.DomesticQTH) then
          RXData.QSOPoints := 15
        else
          RXData.QSOPoints := 5;

      end;
    {    if length(mystate)> 3 then
           i := pos('-',MyState);

           j := length(MyState)-i; // length of #
           inc(i); // point to begin of numbers
           k := copy(mystate,i,j);
           if k[1] <> '0' then
            exit
             else
          k := copy(k,2,j);
            if k[1] <> '0' then
             exit

             else
              begin
                k := copy(k,2,1);

              end;

          if k[i+1] <> '0' then
           MyState := copy(MyState,i,j);
     //        inc(i);
             while (MyState[i] = '0') do
              begin
              copy(MyState,i ,j);
              inc(i);
              j := j -1;
              if MyState[i] <> '0' then break;
              end;
               exit;

         //   end;
         //  MyState:=StringReplace(MyState,'0' , '', [rfReplaceAll]);
         //  RXData.DomesticQTH := StringReplace(RXData.DomesticQTH,'0','',[rfreplaceall]);
           if length(MyState) > 3  then
           begin
           if   (RXData.DomesticQTH = MyState)  then
            RXData.QSOpoints := 5
             else
              if (RXData.DomesticQTH <> '') and (MyState <> RXData.DomesticQTH) then
              RXData.QSOPoints := 15
               else
                RXData.QSOPoints := 5;
            exit;
            end;

             if length(MyState) < 3 then
              begin
               if (RXData.DomesticQTH = '') then
                RXData.QSOpoints := 2
                 else
                  RXData.QSOPoints := 15;
             end;
         end;

              if pos('-',rxdata.domesticqth) > 0 then     // 4.61.4 assumes dash delineates continent from #
               delete(iotastate,(pos('-',rxdata.domesticqth)),1);
          if ((RXData.DomesticQTH <> '') and (MyState <> IOTAState)) then
            RXData.QSOPoints := 15
          else
            RXData.QSOPoints := 5;

        end;     }
    JapanInternationalDXQSOPointMethod:
      begin
        case RXData.Band of
          Band160: RXData.QSOPoints := 4;
          Band80: RXData.QSOPoints := 2;
          Band40: RXData.QSOPoints := 1;
          Band20: RXData.QSOPoints := 1;
          Band15: RXData.QSOPoints := 1;
          Band10: RXData.QSOPoints := 2;
        end;

        if MyCountry = 'JA' then
        begin
          if RXCty = 'JA' then
          begin
            RXData.QSOPoints := 0;
            RXData.InhibitMults := True;
          end;
        end
        else if (RXCty <> 'JA') and (Copy(RXCty, 1, 2) <> 'JD') then
        begin
          RXData.QSOPoints := 0;
          RXData.InhibitMults := True;
        end;
      end;

    IRTSQSOPointMethod: // 4.93.2
      begin
        RXData.QSOPoints := 0;
        if RXData.Mode = CW then
          RXData.QSOPoints := 0;
        if (MyCountry = 'EI') or (MyCountry = 'GI') then
          if (RXCty = 'EI') or (RXCty = 'GI') then
          begin
            RXData.DXQTH := '';
            if RXData.Mode = CW then
              RXData.QSOPoints := 8
            else
              RXDATA.QSOPoints := 4;
          end
          else if RXData.Mode = CW then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;
        if (MyCountry <> 'EI') and (MyCountry <> 'GI') then
          if (RXCty <> 'EI') and (RXCty <> 'GI') then
          begin
            RXData.InhibitMults := True;
            exit;
          end;
        if (RXCty = 'EI') or (RXCty = 'GI') then
        begin
          if RXData.Mode = CW then
            RXData.QSOPoints := 8
          else
            RXData.QSOPoints := 4;
        end;
      end;

    KCJQSOPointMethod:
      if MyCountry = 'JA' then
      begin
        if (RXCty = 'JA') or (RXCty = 'JD1') then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 2;
      end
      else
      begin
        if (RXCty = 'JA') or (RXCty = 'JD1') then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1

      end;
    {
        MQPQSOPointMethod:
          if RXData.Callsign = 'W0EF' then
            RXData.QSOPoints := 10
          else
            if RXData.Mode = CW then
              RXData.QSOPoints := 2
            else
              RXData.QSOPoints := 1;
    }
    NZFieldDayQSOPointMethod:
      begin
        if RXCty = 'ZL' then
        begin
          if RXData.Mode = CW then
            RXData.QSOPoints := 5
          else
            RXData.QSOPoints := 3;
        end
        else
          RXData.QSOPoints := 10;

        if RXData.Zone = StrToInt(MyZone) then
          RXData.ZoneMult := False;

      end;

    OKDXQSOPointMethod:
      begin
        if OKOMStation(MyCountry) then // I am in okom
        begin
          if (RXCty <> MyCountry) then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 2;
          if not OKOMStation(RXCty) then
          begin
            if (RXData.QTH.Continent = Europe) then
              RXData.QSOPoints := 3
            else
              RXData.QSOPoints := 5;
          end;
        end;

        if not OKOMStation(MyCountry) then // I am not in OK/OM
        begin
          if RXCty = MyCountry then
            RXData.QSOPoints := 1;
          if RXCty <> MyCountry then
            RXData.QSOPoints := 3;
          if MyContinent <> RXData.QTH.Continent then
            RXData.QSOPoints := 5;
          if OKOMStation(RXCty) then
            RXData.QSOPoints := 10;
        end;
      end;

    OKOMSSBQSOPointMethod: // 4.80.1

      if OKOMStation(MyCountry) then
      begin
        if ((MyCountry = 'OK') and (RXData.QTH.CountryID = 'OM')) or
          ((MyCountry = 'OM') and (RXData.QTH.CountryID = 'OK')) then
          RXdata.QSOPoints := 3
        else if (RXCty = 'OK') or (RXCty = 'OM') then
          RXData.QSOPoints := 2
        else if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 5;
      end
      else if (RXCty = 'OK') or (RXCty = 'OM') then
        RXData.QSOPoints := 10
      else if RXCTY = MyCountry then
        RXData.QSOPoints := 1
      else if RXData.QTH.Continent <> MyContinent then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 3;

    RAEMQSOPointMethod:
      begin

        if LooksLikeAGeoCoordinates(MyState, la1, lo1) then
          if LooksLikeAGeoCoordinates(RXData.QTHString, la2, lo2) then
          begin
            Distance := Abs(lo1 - lo2);
            if Distance > 180 then
              Distance := 360 - Distance;
            RXData.QSOPoints := 50 + Abs(la2 - la1) + Distance;
            if RXData.Callsign = 'RAEM' then
              RXData.QSOPoints := RXData.QSOPoints + 300;
            if la2 > 65 + 90 then
              RXData.QSOPoints := RXData.QSOPoints + 100;
            if la1 > 65 + 90 then
              RXData.QSOPoints := round(RXData.QSOPoints * 1.1);
          end;
      end;

    RACQSOPointMethod:
      if RXCty = 'VE' then
      begin
        if pos('RAC', RXData.Callsign) > 0 then
          RXData.QSOPoints := 20
        else
          RXData.QSOPoints := 10;
      end
      else
        RXData.QSOPoints := 2;

    RSGBQSOPointMethod:
      if MyCountry = RXCty then
        RXData.QSOPoints := 0
      else
        case RXData.QTH.Continent of
          Europe: RXData.QSOPoints := 5;
          Oceania: RXData.QSOPoints := 30;
        else
          RXData.QSOPoints := 15;
        end;

    RSGB160Method: // 4.67.1
      begin
        if (RXData.DomMultQTH <> '') and (mo.isdmmult(rxdata.dommultqth,
          AllBands, both, ActiveDomesticMult) =
          TRUE) then
          rxdata.qsopoints := 7
        else if mo.isdxmult(RXData.QTH.Country, AllBands, both) = TRUE then
          rxdata.qsopoints := 7
        else
          rxdata.qsopoints := 2;
        exit;
      end;

    {    RSGBDXMethod: // 4.116.1
        {The same station may be contacted on each band and both modes for points and multipliers.

         UK&CD stations - 1 point per contact with UK&CD stations on any band, 2 points per contact for UK&CD to EU contacts on any band and
         6 points per contact for UK&CD to other continents.
         Multipliers are the countries of the DXCC list, on each band and each mode,
         except that JA, W, VE, VK, ZL and ZS call areas count as separate countries, and the UK call areas do not count for multiplier credit.

         Non-UK stations - 1 point per contact with the same counitry, 2 points per contact with the same continent
         and 6 points per contact with a different continent. A multiplier for the first contact with each UK&CD prefix,
         for example, G3, GJ0, MM0 etc., on each band and each mode.
        }

      //               if ((copy(RXData.QTH.CountryID,1,1) <> 'G') and  (copy(RXData.QTH.CountryID,1,1) <> 'M')) then
      {          if (MyCountry[1] = 'G') or  (MyCountry[1] = 'M') then       // ukorcd
                begin
                 ActiveDXMult := CQDXCC;
                  if (RXCty[1] = 'G') or (RXCty[1] = 'M') then
                   begin
                    ActiveDXMult := NoDXMults;
                    RXData.QSOPoints := 1 ;
                   end
                  else
                   if MyContinent <>  RXData.QTH.Continent then
                     RXData.QSOPoints := 6
                    else
                     RXData.QSOPoints := 2;
                   end
               else       // my country not uk
                begin
                if ((RXData.Callsign[1] = 'G') or (RXData.Callsign[1] = 'M')) then
                  begin
                   ActivePrefixMult := Prefix;
                   RXData.QSOPoints := 1 ;
                  end
                   else               // QSO is not UK
                   begin
                    rxdata.Prefix := '';
                    if RXData.QTH.Continent <> MyContinent then
                      RXData.QSOPoints := 6
                   else
                    if (RXData.QTH.Continent = MyContinent) and (MyCountry <> RXCty) then
                    RXData.QSOPoints := 2
                   else
                    RXData.QSOPoints := 1;
                  end;
               end;
           end;
        }
    RDAQSOPointMethod:
      begin
        RXData.QSOPoints := 0;
        if RussianID(MyCountry) then
        begin
          if RussianID(RXCty) then
          begin
            if pos('/P', RXData.Callsign) = length(RXData.Callsign) - 1 then
            begin
              RXData.QSOPoints := 10;
              Exit;
            end;
            RXData.QSOPoints := 1;
            if RXData.QTH.Continent <> MyContinent then
              RXData.QSOPoints := 2;
            Exit;
          end;
          if RXData.QTH.Continent = MyContinent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 5;
        end
        else if RussianID(RXCty) then
          RXData.QSOPoints := 10;
      end;

    RussianDXQSOPointMethod:
      begin

        if RussianID(MyCountry) then
        begin
          if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 5
          else if RXCty <> MyCountry then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 2;
        end

          { I am not in Russia }

        else if RussianID(RXCty) then
          RXData.QSOPoints := 10
        else if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 5
        else if RXCty <> MyCountry then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 2;
        if Contest = RU3AXMEMORIAL then
          if rxdata.Mode = Phone then
            RXData.QSOPoints := RXData.QSOPoints * 2;
      end;

    SalmonRunQSOPointMethod:
      begin
        if RXData.Mode = CW then
          RXData.QSOPoints := 4
        else
          RXData.QSOPoints := 2;
      end;

    ScandinavianQSOPointMethod:
      begin
        if ScandinavianCountry(MyCountry) then
        begin
          if ScandinavianCountry(RXCty) then
            RXData.QSOPoints := 0
          else if RXData.QTH.Continent = Europe then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end
        else
        begin
          if ScandinavianCountry(RXCty) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 0;

          if MyContinent <> Europe then
            if RXData.Band in [Band80, Band40] then
              RXData.QSOPoints := RXData.QSOPoints * 3;
        end;
        if RXData.Band = Band160 then
          RXData.QSOPoints := 0;
      end;

    IndonesianQSOPointMethod: // 4.64.1
      begin
        if IndonesianCountry(MyCountry) then
        begin
          if IndonesianCountry(RXCty) then
            RXData.QSOPoints := 0
          else if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 10
          else
            RXData.QSOPoints := 5;
        end
        else
        begin
          if IndonesianCountry(RXCty) then
            RXData.QSOPoints := 10
          else if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 3
          else if RXCty <> MyCountry then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;
        end;

      end;

    YBFT8QP: // 4.90.7    4.104.4
      begin

        if IndonesianCountry(MyCountry) then
        begin
          if IndonesianCountry(RXCty) then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 2;
        end
        else
        begin
          if IndonesianCountry(RXCty) then
            RXData.QSOPoints := 2
          else if RXCty <> MyCountry then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 0;
        end;
        if ContestTitle = 'YBDXDI-FT8' then
          if RXCty = 'XYZ' then
            RXData.QSOPoints := 5;

      end;

    SLFivePointQSOMethod:
      if Copy(RXData.Callsign, 1, 2) = 'SL' then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 1;

    SouthAmericanWWQSOPointMethod:
      begin
        if MyContinent = SouthAmerica then
        begin
          if RXData.QTH.Continent = SouthAmerica then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 10;
        end
        else if RXData.QTH.Continent = SouthAmerica then
          RXData.QSOPoints := 10
        else
          RXData.QSOPoints := 2;
      end;

    StewPerryQSOPointMethod:
      begin
        if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
          RXData.QSOPoints := (Distance div 500) + 1;
          if CategoryPower = cpQRP then
            RXDATA.QSOPoints := RXDATA.QSOPoints * 3;
          if CategoryPower = cpLOW then
            RXDATA.QSOPoints := Round(RXData.QSOPoints * 1.5);
        end
        else
          RXData.QSOPoints := 1;
      end;

    WWDigiQP: // 4.90.8
      if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
      begin
        Distance := GetDistanceBetweenGrids(MyGrid, RXData.QTHString);
        RXData.QSOPoints := (Distance div 3000) + 1;
      end;

    RTCQSOPointMethod: // Issue #902 -- RTC: Haversine grid-center distance, tiers at 2000/4000/8000 km
      begin
      // Rules permit only 40/20/15/10 m on CW and SSB.  TR4W has no per-band
      // disable, so we enforce here: any QSO outside those bands or modes
      // scores 0 and does NOT count as a multiplier.
      if not (RXData.Band in [Band40, Band20, Band15, Band10]) then
         begin
         RXData.QSOPoints := 0;
         RXData.InhibitMults := True;
         end
      else if not (RXData.Mode in [CW, Phone]) then
         begin
         RXData.QSOPoints := 0;
         RXData.InhibitMults := True;
         end
      else if (MyGrid <> '') and (RXData.QTHString <> '') then
         begin
         RTCDistKm := RTCGridDistance(MyGrid, RXData.QTHString);
         if RTCDistKm < 2000.0 then
            begin
            RXData.QSOPoints := 1;
            end
         else if RTCDistKm < 4000.0 then
            begin
            RXData.QSOPoints := 2;
            end
         else if RTCDistKm < 8000.0 then
            begin
            RXData.QSOPoints := 3;
            end
         else
            begin
            RXData.QSOPoints := 4;
            end;
         end;
      end;

    TenTenQSOPointMethod:
      if RXData.TenTenNum <> -1 then
        RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 1;

    TOECQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else if StringHas(RXData.Callsign, '/M') then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;
      end;

    UBAQSOPointMethod: // 4.106.5
      begin
        {  if RXData.QTHString = 'XXX' then
           begin
            RXData.DomesticMult := False;
            if MyCountry <> 'ON' then
             RXData.QSOPoints := 10
              else
                RXData.QSOPoints := 1;
              exit;
          end;   }
        if MyCountry = 'ON' then
        begin
          if RXCty = 'ON' then
          begin
            RXData.QSOPoints := 1;
            if RXData.QTHString = 'XXX' then
              RXData.DomesticMult := False;
          end
          else if UBACountry(RXData.DXQTH) then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
          exit;
        end;

        if RXCty = 'ON' then
        begin
          { if (RXData.DXMult) and (RXData.PrefixMult) then
             MultString := MultString + MULT_DX; //TempRXData.DXQTH + ' ';   }
          RXData.QSOPoints := 10;
        end
        else if UBACountry(RXCty) then // 4.97.10
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;

      end;
    UkrainianQSOPointMethod:
      begin

        if RXCty = 'UR' then
          RXData.QSOPoints := 10
        else if RXCty = MyCountry then
          RXData.QSOPoints := 1
        else if RXData.QTH.Continent = MyContinent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 3;
        if MyCountry = 'UR' then
        begin
          if RXCty = 'UR' then
            RXData.QSOPoints := 1;
          RXData.DomesticMult := False;
        end;
      end;

    VKZLQSOPointMethod:
      if ((MyContinent = Oceania) or (RXData.QTH.Continent = Oceania)) then
      begin
        case RXData.Band of
          Band160: RXData.QSOPoints := 20;
          Band80: RXData.QSOPoints := 10;
          Band40: RXData.QSOPoints := 5;
          Band20: RXData.QSOPoints := 1;
          Band15: RXData.QSOPoints := 2;
          Band10: RXData.QSOPoints := 3;
        end;
      end
      else
        RXData.QSOPoints := 0;

    WAGQSOPointMethod:
      if MyCountry = 'DL' then
      begin
        if RXCty = 'DL' then
          RXData.QSOPoints := 1
        else if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 5;
      end
      else
      begin
        if RXCty = 'DL' then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 0;
      end;

    WAEQSOPointMethod:
      if MyContinent = Europe then
        if (RXData.QTH.Continent <> Europe) and (RXData.Band <> Band160) then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 0
      else if (RXData.QTH.Continent = Europe) and (RXData.Band <> Band160) then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 0;

    WWLQSOPointMethod:
      begin
        if (MyGrid <> '') and (RXData.DomesticQTH <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.DomesticQTH);
          RXData.QSOPoints := (Distance div 500) + 1;

          if (RXData.Band = Band80) or (RXData.Band = Band160) then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;

          if RXData.Band = Band160 then
            RXData.QSOPoints := RXData.QSOPoints + RXData.QSOPoints;
        end
        else
          RXData.QSOPoints := 1;
      end;

    YODXQSOPointMethod:
      begin
        if RXCty = 'YO' then
          RXData.QSOPoints := 8
        else if MyCountry <> RXCty then
          if RXData.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 4
          else
            RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1; {KK1L: 6.71 Same country QSO}
      end;
    NoQSOPointMethod: RXData.QSOPoints := 0;

    AlwaysOnePointPerQSO: RXData.QSOPoints := 1;
    OnePointPerQSO: RXData.QSOPoints := 1;
    TwoPointsPerQSO: RXData.QSOPoints := 2;
    ThreePointsPerQSO: RXData.QSOPoints := 3;
    TenPointsPerQSO: RXData.QSOPoints := 10;

    ThreePhoneFiveCWFourRTTY: // 4.55.4
      case RXData.Mode of
        CW: RXData.QSOPoints := 5;
        Phone: RXData.QSOPoints := 3;
      else
        RXData.QSOPoints := 4;
      end;

    TwoPhoneFourCW:
      if RXData.Mode = CW then
        RXData.QSOPoints := 4
      else
        RXData.QSOPoints := 2;

    TwoPhoneThreeCW:
      if RXData.Mode = CW then
        RXData.QSOPoints := 3
      else
        RXData.QSOPoints := 2;

    OnePhoneTwoCW:
      if RXData.Mode = CW then
        RXData.QSOPoints := 2
      else
        RXData.QSOPoints := 1;

    ThreePhoneFiveCW:
      if RXData.Mode = CW then
        RXData.QSOPoints := 5
      else
        RXData.QSOPoints := 3;

    OneEuropeTwoOther: {KK1L: 6.68 Used for WRTC 2002}
      if MarineOrAirMobileStation(RXData.Callsign) then
        RXData.QSOPoints := 2
      else if RXData.QTH.Continent = Europe then
        RXData.QSOPoints := 1
      else
        RXData.QSOPoints := 2;

    CupRFMethod:
      begin

        if (MyGrid <> '') and (RXData.QTHString { .DomesticQTH} <> '') then
        begin
          Distance := GetDistanceBetweenGrids(MyGrid, RXData.QTHString
            {DomesticQTH});

          if Distance > 7000 then
            RXData.QSOPoints := 62;
          if Distance <= 7000 then
            RXData.QSOPoints := 57;
          if Distance <= 6000 then
            RXData.QSOPoints := 52;
          if Distance <= 5000 then
            RXData.QSOPoints := 47;
          if Distance <= 4000 then
            RXData.QSOPoints := 42;
          if Distance <= 3000 then
            RXData.QSOPoints := 38;
          if Distance <= 2000 then
            RXData.QSOPoints := 35;

        end
        else
          RXData.QSOPoints := 1;

      end;
    UA4WMethod:
      begin
        RXData.QSOPoints := 2;

        if GetOblast(MyCall) = '4W' then
        begin
          if RXData.DomesticQTH <> MyState then
            RXData.QSOPoints := 4;
          Exit;
        end;

        if RXData.DomesticQTH <> MyState then
        begin
          if RXData.Band = Band80 then
            RXData.QSOPoints := 3;
          if RXData.Band = Band160 then
            RXData.QSOPoints := 5;

          if GetOblast(RXData.Callsign) = '4W' then
          begin
            if RXData.Band = Band80 then
              RXData.QSOPoints := 5;
            if RXData.Band = Band160 then
              RXData.QSOPoints := 10;
            MyZoneValue := ctyGetCQZone(MyCall);
            if MyZoneValue in [18, 19] then
            begin
              if RXData.Band = Band80 then
                RXData.QSOPoints := 10;
              if RXData.Band = Band160 then
                RXData.QSOPoints := 20;
            end;
          end;
        end;

      end;

    ChampionshipRFMethod:
      begin
        if RussianID(RXCty) then
        begin
          RXData.DomMultQTH := GetRussiaOblastID(RXData.Callsign);
          if MyState = '' then
            Exit;
          if not (MyState[1] in ['1'..'7']) then
            Exit;
          if not (RXData.Zone in [1..7]) then
            Exit;
          RXData.QSOPoints := ChampionshipRFPointsArray[Ord(MyState[1]) - 48 +
            (RXData.Zone - 1) * 7];
        end;
      end;

    ChampionshipUkrMethod:
      begin
        if RXCty <> 'UR' then
          Exit;
        //if (RXData.Band = Band80) or (RXData.Band = Band160) then
        RXData.QSOPoints := 2;
      end;

    WWPMCQSOPointMethod:
      begin
        RXData.QSOPoints := 5;
        if MyState = '' then
        begin
          if RXData.QTHString <> '' then
            RXData.QSOPoints := 25;
        end
        else
        begin
          if RXData.QTHString <> '' then
            if MyState <> RXData.QTHString then
              RXData.QSOPoints := 10;
        end;
      end;

    JTDXQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else if RXCty <> MyCountry then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;

        if RXCty = 'JT' then
          if MyCountry = 'JT' then
            RXData.QSOPoints := 0;

      end;

    MMCQSOPointMethod: //n4af added for marcon memorial contest
      begin

        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 5
        else if RXCty = MyCountry then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 3;

      end;

    LABREQSOPointMethod:
     begin
     if RXData.QTH.Continent <> MyContinent then   // different continents
       Case RXData.Band of
        Band160: RXData.QSOPoints := 6;
        Band80:  RXData.QSOPoints := 6;
        Band40:  RXData.QSOPoints := 6;
         else
          RXData.QSOPoints := 3;
        end;
     if RXData.QTH.Continent = MyContinent then
      if RXCty <> MyCountry then                  // same continent but different countries
       Case RXDATA.Band of
        Band160: RXData.QSOPoints := 4;
        Band80:  RXData.QSOPoints := 4;
        Band40:  RXData.QSOPoints := 4;
         else
          RXData.QSOPoints := 2;
        end;
      if RXCty = MyCountry then                   // same country
       Case RXDATA.Band of
        Band160: RXData.QSOPoints := 2;
        Band80:  RXData.QSOPoints := 2;
        Band40:  RXData.QSOPoints := 2;
         else
          RXData.QSOPoints := 1;
        end;
     end;
//     if MyState = '' then

     

    LZDXQSOPointMethod:
      begin

        if RXCty = 'LZ' then
        begin
          if MyCountry = 'LZ' then
            RXData.QSOPoints := 1
          else
            RXData.QSOPoints := 10;
        end
        else
        begin
          if MyContinent <> RXData.QTH.Continent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 1;
        end;
      end;

    ONY:

      begin
        RXData.QSOPoints := RXData.Age;
      end;

    OldNewYearQSOPointMethod:
      begin
        RXData.QSOPoints := StrToInt(RXData.Power);
      end;

    YouthChampionshipRFMethod:
      begin
        //        if RussianID(RXCty) then
        if RXData.Band in [Band40, Band20] then
        begin

          RXData.QSOPoints := 1;
          RXData.DomMultQTH := GetRussiaOblastID(RXData.Callsign);

        end;
      end;

    {   YOKQSOPointMethod:             // 4.55.4
         RXData.QSOPoints:= 3;  }

    ChampionshipRFASMethod:
      if (MyState <> '') and (RXData.QTHString { .DomesticQTH} <> '') then
        if StringIsAllNumbers(MyState) then
        begin
          la1 := StrToInt(RXData.QTHString[1]);
          lo1 := StrToInt(Copy(RXData.QTHString, 2, 2));

          la2 := StrToInt(MyState[1]);
          lo2 := StrToInt(Copy(MyState, 2, 2));
          RXData.QSOPoints := Abs(la1 - la2) + Abs(lo1 - lo2) + 5;
          if RXData.Mode = CW then
            RXData.QSOPoints := RXData.QSOPoints + 5;
        end;

    RegionOneFieldDayRCCQSOPointMethod:
      begin
        if MyContinent = RXData.QTH.Continent then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 3;
        Result := pos('/P', RXData.Callsign);
        if Result = 0 then
          Result := pos('/M', RXData.Callsign);
        if Result = length(RXData.Callsign) - 1 then
          RXData.QSOPoints := 4;
      end;

    YL_ARCK_YL: // 4.66.3 YL-ARCK-YL
      begin
        if (RXData.NumberReceived = 88) then // YL # rcvd
        begin
          RXData.QSOPoints := 5;
          exit; // now exit points processing
        end;
        RXData.Prefix := ''; // if <> yl # then clear the multiplier
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1
      end;

    GACWWWSACWQSOPointMethod:
      begin

        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else if RXCty <> MyCountry then
          RXData.QSOPoints := 1
        else
          RXData.QSOPoints := 0; // end YL-ARCK-YL hooks
        if RXData.QTH.Continent = SouthAmerica then
          RXData.QSOPoints := 5;
      end;

    LQPQSOPointMethod:
      begin
        RXData.QSOPoints := 1000;
        if (RXData.Name = 'LOCUST') or (RXData.Callsign = 'K6VVA') then
          RXData.QSOPoints := 5000;
      end;

    ArktikaSpringQSOPointMethod:
      begin
        if RXData.DomMultQTH <> '' then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;
      end;

    REFQSOPointMethod:
      begin
        if not FrenchID(RXData.QTH.CountryID) then
          Exit;

        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 1;
      end;

    RadioMemoryQSOPointMethod:
      begin
        RXData.QSOPoints := RXData.Age;
        Result := pos(' ', RXData.QTHString);
        if Result <> 0 then
        begin
          TheirID := Copy(RXData.QTHString, Result + 1, 3);

          if StringIsAllNumbers(TheirID) then
            inc(RXData.QSOPoints, StrToInt(TheirID));
        end;
      end;

    PCCQSOPointMethod: // 4.83.2
      begin
        if RXData.Band in [Band80..Band10] then

          RXData.QSOPoints := 0;
        result := length(RXData.QTHString); // found 'M' in recvd nr ?
        if RXCty <> MyCountry then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 1;

        if (RXData.QTHString[result] = 'M') and (StringIsAllNumbers(MyState))
          then
          inc(RXData.QSOPoints, 6)
        else if (RXData.QTHString[result] = 'M') and (not
          StringIsAllNumbers(MyState)) then
          inc(RXData.QSOPoints, 2);

      end;
    
      UNDXQSOPointMethod:
      begin
        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 5
        else if RXCty <> MyCountry then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 2;

        if RXCty = 'UN' then
          if MyCountry <> 'UN' then
            RXData.QSOPoints := 10;
      end;

    KingOfSpainQSOPointMethod:
      begin
        if not SpanishStation(RXCty) then
          RXData.QSOPoints := 1
        else
        begin
          if SpanishStation(MyCountry) then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 3;
        end;
      end;

    GagarinCupQSOPointMethod:
      begin

        if RXData.QTH.Continent <> MyContinent then
          RXData.QSOPoints := 4
        else if RXCty <> MyCountry then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 2;

        if RXData.Band in [Band160, Band80] then
          RXData.QSOPoints := RXData.QSOPoints * 3;
        if RXData.Band in [Band40] then
          RXData.QSOPoints := RXData.QSOPoints * 2;
        if RXData.Band = Band2 then
          RXData.QSOPoints := 100;
        if RXData.Band = Band2304 then
          RXData.QSOPoints := 50;
        if RXData.Mode = PHONE then
          RXDATA.QSOPoints := RXData.QSOPoints * 2;

      end;

    CQMMQSOPointMethod:
      begin
        if RXData.Band in [Band80..Band10] then
        begin
          PtsMult := integer(RXData.Band in [Band40, Band80]) + 1;
          if RXData.QTH.Continent <> MyContinent then
          begin
            RXData.QSOPoints := 3 * PtsMult;
          end
          else if RXCty <> MyCountry then
            RXData.QSOPoints := 2 * PtsMult
          else
            RXData.QSOPoints := 1;

          if (length(RXData.QTHString) = 3) then
            if (RXData.QTHString[3] in ['M', 'Q', 'Y']) then
              RXData.QSOPoints := 10;

        end;
      end;

    Radio160QSOPointMethod:
      begin
        if length(RXData.DomMultQTH) = 2 then
        begin
          if RXData.DomMultQTH[1] in ['A'..'Z'] then
          begin
            if RXData.DomMultQTH[2] in ['0'..'9'] then
              if length(MyState) >= 2 then
              begin
                la1 := Abs(Ord(UpCase(RXData.DomMultQTH[1])) - Ord(MyState[1]))
                  + 1;
                la2 := Abs(Ord(UpCase(RXData.DomMultQTH[2])) - Ord(MyState[2]))
                  + 1;
                if la1 >= la2 then
                  RXData.QSOPoints := la1
                else
                  RXData.QSOPoints := la2;
                Exit;
              end;
            if RXData.DomMultQTH[2] = 'X' then
              RXData.QSOPoints := 30;
          end;
        end;
      end;

    R9WUW9WKMemorialQSOPointMethod:
      begin
        //        if RXData.Callsign = 'R100W' then RXData.QSOPoints := 10
        //        else
        case RXData.Zone of
          1, 2: RXData.QSOPoints := 3;
          3: RXData.QSOPoints := 4;
          5: RXData.QSOPoints := 10;
        end;
      end;

    WRTCQSOPointMethod: // 4.72.10
      if RXData.Band in [Band80..Band10] then
      begin

        if RXData.QTH.Continent = Europe then
          RXData.QSOPoints := 2
        else
          RXData.QSOPoints := 5;

      end;

    PortugalDay: // 4.71.4   4.100.11
      begin

        if (MyCountry <> 'CT') or (MyCountry <> 'CT3') or (MyCountry <> 'CU')
          then
        begin
          if (RXCty = 'CT') or (RXCty = 'CT3') or (RXCty = 'CU') then
            RXData.QSOPoints := 10
          else if (RXData.QTH.Continent <> MyContinent) then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;
        end;
        if (MyCountry = 'CT') or (MyCountry = 'CT3') or (MyCountry = 'CU') then
        begin
          if (RXCty = 'CT') or (RXCty = 'CT3') or (RXCty = 'CU') then
            RXdata.QSOPoints := 5
          else
            RXData.QSOPoints := 1;
        end;
      end;

    HamSpirit: // 4.115.5
      begin
        if length(RXData.DomesticQTH) < 3 then
          exit;
        if length(RXData.DomesticQTH) = 3 then
        begin
          Str1 := '0' + Copy(RXData.DomesticQTH, 1, 1);
          str2 := Copy(RXData.DomesticQTH, 2, 2);
        end
        else
        begin
          Str1 := Copy(RXData.DomesticQTH, 1, 2);
          str2 := Copy(RXData.DomesticQTH, 3, 2);
        end;
        if length(MyState) < 3 then
          exit;
        if length(MyState) = 3 then
        begin
          Str3 := '0' + Copy(MyState, 1, 1);
          Str4 := Copy(MyState, 2, 2);
        end
        else
        begin
          Str3 := Copy(MyState, 1, 2);
          Str4 := Copy(MyState, 3, 2);
        end;
        if Str1 = Str3 then
          RXData.QSOPoints := 1;
        if MyContinent <> RXData.QTH.Continent then
        begin
          RXData.QSOPoints := 5;
          exit;
        end
        else if Str1 <> Str3 then
          RXData.QSOPoints := 3;

      end;

    RPX:
      begin

        if (RXCty = 'UA') or (RXCty = 'UA2') or (RXCty = 'UA9') then
          RXData.QSOPoints := 10
        else
          RXData.QSOPoints := 5;

      end;

    UQRQCPM: // 4.82.3
      begin
        if (RXData.QTH.Continent <> MyContinent) then
          RXData.QSOPoints := 4
        else if (RXCty <> MyCountry) then
          RXData.QSOPoints := 3
        else
          RXData.QSOPoints := 2;
      end;

    OKOMRTTY: // 4.83.4
      begin
        if RXData.Band in [Band80..Band40] then
          if (RXData.QTH.Continent <> MyContinent) then
            RXData.QSOPoints := 6
          else
            RXData.QSOPoints := 3;

        if RXData.Band in [Band20..Band10] then
          if (RXData.QTH.Continent <> MyContinent) then
            RXData.QSOPoints := 2
          else
            RXData.QSOPoints := 1;
      end;

    VAQSOPOINTMETHOD:
      begin
        if RXData.Mode = PHONE then
          RXData.QSOPoints := 1
        else if MarineOrAirMobileStation(RXData.Callsign) then
          RXDATA.QSOPoints := 3
        else
          RXDATA.QSOPoints := 2;
      end;

    EUDXQSOPOINTMETHOD:
      { 3. QSO Points
 a. European Union stations:
 QSO with your own country � 2 point,
 QSO with another European Union country � 10 points,
 QSO with a non-European Union country on your continent � 3 points,
 QSO with another continent � 5 points.
 b. Non- European Union stations:
 QSO with European Union � 10 points,
 QSO with your own country � 2 points,
 QSO with a different country on your continent � 3 points,
 QSO with another continent � 5 points.
     }
      begin
        if length(MyState) = 4 then // i am in EU region
        begin
          if (RXData.DomMultQTH[4] <> '') then // he is in EU
          begin
            if (RXCty <> MyCountry) then // Not same country as me
              RXData.QSOPoints := 10
            else
              RXData.QSOPoints := 2;
            exit;
          end
          else
            {// i am eu and he is not}if (RXData.QTH.Continent <> MyContinent)
              then
              RXData.QSOPoints := 5
            else
              RXData.QSOPoints := 3;
        end
        else {// I am not in EU region}if (RXData.DomMultQTH[4] <> '') then
            // he is in EU
            RXData.QSOPoints := 10
          else if (RXData.QTH.Continent <> MyContinent) then
            RXData.QSOPoints := 5
          else if (RXCty <> MyCountry) then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 2;
      end;

    YOTAQSOPointMethod: // 4.99.3
      begin
        RXData.DomMultQTH := inttostr(RXData.Age);
        if (RXData.Age > 25) or (RXData.Age = 0) then
        begin
          if rxdata.QTH.Continent <> MyContinent then
            RXData.QSOPoints := 3
          else
            RXData.QSOPoints := 1;
          exit;
        end;
        case RXData.Age of
          1..11: RXData.QSOPoints := RXData.QSOPoints + 13;
          12..16: RXData.QSOPoints := RXData.QSOPoints + 12;
          17..21: RXData.QSOPoints := RXData.QSOPoints + 11;
          22..25: RXData.QSOPoints := RXData.QSOPoints + 10;
        end;
      end;
  end;

end;

procedure SendMultiInfoMessage(Band: BandType; Mode: ModeType; Message: Str80);

var
  Sum: Byte;

begin
  Sum := CheckSum(Message);

  if Sum = LastMultiInfoMessageSum[Band, Mode] then
    Exit;

  LastMultiInfoMessageSum[Band, Mode] := Sum;

  Message := AddBand(Band) + AddMode(Mode) + Message;

  SendMultiCommand(MultiBandAddressArray[Band], $FF, MultiInformationMessage,
    Message);
end;

procedure RotorControl(Heading: integer);
var
  nNumberOfBytesToWrite: Cardinal;
  TempPchar: PChar;
begin
  if UDPBroadcastRotor then
    // Even if there is no rotator set, if the UDP option is requested, send the command // ny4i 4.44.9
  begin
    SendUDPRotorCommand(Heading);
  end;

  // Issue #732 -- PSTRotator is a UDP-only rotator type: send its native
  // command and stop (it has no serial port, so the serial path below is N/A).
  if ActiveRotatorType = PSTRotator then
  begin
    SendPSTRotorCommand(Heading);
    Exit;
  end;

  if ActiveRotatorPort = NoPort then
    Exit;
  case ActiveRotatorType of
    OrionRotator: TempPchar := '#%03u'#$D;
    DCU1Rotator: TempPchar := 'AP1%03u;AM1;';
    YaesuRotator: TempPchar := 'M%03u'#$D;
    AlfaSpidRotator:
      begin
        TempPchar := 'W%03u0'#01;
        inc(Heading, 360);
      end;
  end;
  Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
  // Issue #997: asm wsprintf-push -> TF.Format. TempPchar is the per-rotator
  // runtime format (e.g. 'M%03u'#$D); heading fills %03u. Format == wsprintfA,
  // so the runtime C format and the returned byte count are preserved.
  nNumberOfBytesToWrite := Format(wsprintfBuffer, TempPchar, heading);

  if ActiveRotatorType = AlfaSpidRotator then
  begin
    nNumberOfBytesToWrite := 13;
    wsprintfBuffer[11] := #$2F;
    wsprintfBuffer[12] := #$20;
  end;

  sWriteFile(CPUKeyer.SerialPortConfigured_Handle[ActiveRotatorPort],
    wsprintfBuffer, nNumberOfBytesToWrite);

  logger.Trace('[RotorControl] serial rotor (%s) on %s, %u bytes: %s',   // Issue #989
    [RotatorTypeSA[ActiveRotatorType], PortTypeSA[ActiveRotatorPort],
     nNumberOfBytesToWrite, PChar(@wsprintfBuffer)]);
end;

function MarineOrAirMobileStation(Call: CallString): boolean;

{KK1L: 6.68 This function will return TRUE if the callsign passed to it is marine
  or air mobile station. }

var

  l: integer;
begin
  MarineOrAirMobileStation := False;
  l := length(Call);
  if l < 4 then
    Exit;
  if Call[l - 2] <> '/' then
    Exit;
  if (Call[l] = 'M') and (Call[l - 1] in ['A', 'M']) then
    MarineOrAirMobileStation := True;
  {
    MarineOrAirMobileStation := False;
    TempString := PostcedingString(Call, '/');
    if StringHas(TempString, '/') then TempString := PostcedingString(TempString, '/');
    if length(TempString) = 2 then if ((TempString = 'MM') or (TempString = 'AM')) then MarineOrAirMobileStation := True;
  }
end;
{
function IsR150Country(OblastDigit, OblastChar: Char): boolean;
begin
  Result := True;
  case OblastDigit of
    '0': if OblastChar in ['F', 'O', 'Q', 'Y', 'W'] then Exit;
    '1': if OblastChar = 'N' then Exit;
    '4': if OblastChar in ['P', 'S', 'U', 'W', 'Y'] then Exit;
    '6': if OblastChar in ['E', 'I', 'J', 'W', 'X', 'Y'] then Exit;
    '9': if OblastChar in ['W', 'X', 'Z'] then Exit;
  end;
  Result := False;
end;
}

function InSameFederalOkrug(HisCallsign: CallString): boolean;
var
  MyOBlast, HisOblast: string[2];
  o1, o2: OkrugType;
begin
  Result := True;
  if StringHas(MyCall, '/') then
    Exit;
  MyOBlast := GetOblast(MyCall);
  if MyOBlast = '' then
    Exit;

  if StringHas(HisCallsign, '/') then
    Exit;
  HisOblast := GetOblast(HisCallsign);
  if HisOblast = '' then
    Exit;

  o1 := GetOkrugByOblast(GetRussiaOblastByTwoChars(MyOBlast[1], MyOBlast[2]));
  if o1 = foUnKnownOkrug then
    Exit;

  o2 := GetOkrugByOblast(GetRussiaOblastByTwoChars(HisOblast[1], HisOblast[2]));
  if o2 = foUnKnownOkrug then
    Exit;

  Result := o1 = o2;
end;
{
function GetFederalOkrug(OblastDigit, OblastChar: Char): FederalOkrugs;

begin
  Result := UnKnownOkrug;
  case OblastDigit of
    '1', '2': Result := SeveroZapadniy;
    '3':
      begin
        if OblastChar = 'T' then Result := Privolzhskiy else
          Result := Centralniy;
      end;
    '4':
      begin
        if OblastChar = 'A' then Result := Yuzhniy else
          Result := Privolzhskiy;
      end;
    '6': Result := Yuzhniy;
    '8': Result := Sibirskiy;
    '9':
      begin
        if OblastChar = 'X' then Result := SeveroZapadniy
        else
          if OblastChar in ['F', 'T', 'S', 'W'] then Result := Privolzhskiy
          else
            if OblastChar in ['A', 'C', 'D', 'J', 'L', 'K', 'Q'] then Result := Uralskiy
            else
              Result := Sibirskiy;
      end;
    '0':
      begin
        if OblastChar in ['A', 'B', 'H', 'O', 'S', 'U', 'W', 'Y'] then Result := Sibirskiy
        else
          Result := DalneVostochnyiy;
      end;
  end;
end;
}

function SetRST(Ex: integer; var RST: smallInt {Word}): boolean;
begin
  Result := False;

  case ActiveMode of
    CW:
      begin
        if Ex in [1..9] then
        begin
          RST := 509 + Ex;
          Result := True;
        end
        else
        begin
          if (Ex >= 111) and (Ex <= 599) then
          begin
            RST := Ex;
            Result := True;
          end;
        end;
      end;
    Phone:
      begin
        if Ex in [1..9] then
        begin
          RST := 50 + Ex;
          Result := True;
        end
        else if Ex in [11..59] then
        begin
          RST := Ex;
          Result := True;
        end
      end;
  end;
  {
    if Ex in [1..9] then
    begin
      case ActiveMode of
        CW: RST := 509 + Ex;
        Phone: RST := 5 + Ex;
      end;
      Result := True;
    end;

    if Ex in [111..599] then
    begin
      case ActiveMode of
        CW: RST := 509 + Ex;
        Phone: RST := 5 + Ex;
      end;
      Result := True;
    end;
  }
end;

function ParseArray(e: Str80): boolean;
var
  i: integer;
  TmpBuf: array[0..31] of Char;
  St: Cardinal;
  en: Cardinal;
  copyCounter: Cardinal;
  isN: boolean;
begin
  Windows.ZeroMemory(@ParsedRecord, SizeOf(ParsedRecord));

  if e = '' then
  begin
    Result := False;
    Exit;
  end;

  St := 0;
  en := 0;

  for i := 1 to length(e) do
  begin
    if (e[i] <> ' ') and (St = 0) then
    begin
      St := i;
      Continue;
    end;

    if St > 0 then
    begin
      if e[i] = ' ' then
      begin
        en := i - 1;
      end
      else if i = length(e) then
      begin
        en := i;
      end;

      if en > 0 then
      begin
        isN := True;
        Windows.ZeroMemory(@TmpBuf, SizeOf(TmpBuf));
        for copyCounter := St to en do
        begin
          if not (e[copyCounter] in ['0'..'9']) then
            isN := False;
          TmpBuf[copyCounter - St] := e[copyCounter];
        end;
        inc(ParsedRecord.prTotalElements);
        if (isN) then
        begin
          ParsedRecord.prNumbers[ParsedRecord.prTotalNumbers] :=
            PCharToInt(@TmpBuf);
          inc(ParsedRecord.prTotalNumbers);
        end
        else
        begin
          Windows.CopyMemory(@ParsedRecord.prStrings[ParsedRecord.prTotalStrings], @TmpBuf, SizeOf(TmpBuf));
          inc(ParsedRecord.prTotalStrings);
        end;

        en := 0;
        St := 0;
      end;
    end;

  end;

  Result := True;

end;

function ParseArray2(ExchangeString: Str80): boolean;
var
  Element: integer;
  i: integer;
  Alpha: boolean;
  Number: boolean;
  PositionCounter: integer;
begin
  Windows.ZeroMemory(@ParserArray, SizeOf(ParserArray));
  if ExchangeString = '' then
  begin
    Result := False;
    Exit;
  end;
  Element := 0;
  PositionCounter := 0;
  Alpha := False;
  Number := False;

  for i := 1 to length(ExchangeString) + 1 do
  begin
    if (ExchangeString[i] = ' ') or (i = length(ExchangeString) + 1) then
    begin
      if PositionCounter = 0 then
        Continue;

      ParserArray.paElements[Element].prString[0] := CHR(PositionCounter);

      inc(ParserArray.paCount);

      if Alpha then
        ParserArray.paElements[Element].prType := eetAlpha;
      if Number then
        ParserArray.paElements[Element].prType := eetNumber;
      if Alpha and Number then
        ParserArray.paElements[Element].prType := eetMixed;

      if ParserArray.paElements[Element].prType = eetNumber then
        ParserArray.paElements[Element].prInteger :=
          StrToInt(ParserArray.paElements[Element].prString);

      ParserArray.paStatus[Element] := ParserArray.paElements[Element].prType;

      inc(Element);
      PositionCounter := 0;
      Alpha := False;
      Number := False;

      if (Element = 4) or (i = length(ExchangeString) + 1) then
      begin
        Result := True;
        Exit;
      end
      else
        Continue;

    end;
    inc(PositionCounter);
    ParserArray.paElements[Element].prString[PositionCounter] :=
      ExchangeString[i];
    if ExchangeString[i] in ['0'..'9'] then
      Number := True
    else
      Alpha := True;
  end;
end;

function ProcessRSTAndGridSquareOrRDAExchange(Exchange: ShortString {Str80}; var
  RXData: ContestExchange): boolean;
var
  TestString: Str20;
  Oblast: Str2;
  RussianRegionMy: RussianRegionType;
  RussianRegionHis: RussianRegionType;
begin
  Result := False;
  //RXData.DomesticQTH := '';
  RXData.RSTReceived := 0;

  if length(Exchange) = 0 then
    Exit;

  while Exchange <> '' do
  begin
    TestString := RemoveLastString(Exchange);

    if (GoodLookingGrid(TestString) or GoodLookingRDA(TestString)) then
    begin
      if RXData.QTHString = '' then
        RXData.QTHString := TestString;
    end
    else if (RXData.RSTReceived = 0) and StringIsAllNumbers(TestString) then
    begin
      if length(TestString) = 1 then
      begin
        case ActiveMode of
          CW: RXData.RSTReceived := 509 + (Ord(TestString[1]) - 48) * 10;
          Phone: RXData.RSTReceived := 50 + (Ord(TestString[1]) - 48);
        end;
      end
      else
        RXData.RSTReceived := StrToInt(TestString);

    end;
  end;

  Result := RXData.QTHString <> '';

  if (Result) then

    if Contest = UA4WCHAMPIONSHIP then
    begin
      RXData.DomesticQTH := RXData.QTHString;
    end;

  if Contest = ALRS_UA1DZ_CUP then
  begin

    Windows.ZeroMemory(@Oblast, SizeOf(Oblast));
    Oblast := Tree.GetOblast(RXData.Callsign);
    RussianRegionHis := GetRussiaOblastByTwoChars(Oblast[1], Oblast[2]);
    RXData.DomesticQTH := RXData.QTHString;
    if (RussianID(MyCall)) then
    begin
      Windows.ZeroMemory(@Oblast, SizeOf(Oblast));
      Oblast := Tree.GetOblast(MyCall);
      RussianRegionMy := GetRussiaOblastByTwoChars(Oblast[1], Oblast[2]);
      if not (RussianRegionMy in [rtUA1A, rtUA1C]) then
      begin
        if RussianRegionHis in [rtUA1A, rtUA1C] then
        begin
          RXData.DomesticQTH := RXData.QTHString;
        end;
        Exit;
      end;
    end;

    if (RussianID(RXData.QTH.CountryID)) then
    begin
      RXData.DomesticQTH := RussianRegionsTypeIdArray[RussianRegionHis];
    end;

  end;

end;

function ProcessExchange(ExchangeString: Str80; var RData: ContestExchange):
  boolean;

begin
  Result := False;
  if not ParseArray(ExchangeString) then
    if not (ActiveExchange in [RSTNameAndQTHExchange, RSTAndPOTAPark]) then
      Exit;


  case ActiveExchange of

    RSTAndGridSquareOrRDAExchange:
      ProcessExchange := ProcessRSTAndGridSquareOrRDAExchange(ExchangeString,
        RData);

    CheckAndChapterOrQTHExchange:
      ProcessExchange := ProcessCheckAndChapterOrQTHExchange(ExchangeString,
        RData);

    ClassDomesticOrDXQTHExchange:
      begin
        logger.debug('Calling ProcessClassAndDomesticOrDXQTHExchange from ProcessExchange');
        ProcessExchange :=
          ProcessClassAndDomesticOrDXQTHExchange(ExchangeString, RData);
      end;

    KidsDayExchange:
      ProcessExchange := ProcessKidsExchange(ExchangeString, RData);

    NameQTHAndPossibleTenTenNumber:
      ProcessExchange :=
        ProcessNameQTHAndPossibleTenTenNumberExchange(ExchangeString, RData);

    NameAndDomesticOrDXQTHExchange:
      ProcessExchange := ProcessNameAndDomesticOrDXQTHExchange(ExchangeString,
        RData);

    NameAndPossibleGridSquareExchange:
      ProcessExchange :=
        ProcessNameAndPossibleGridSquareExchange(ExchangeString, RData);

    QSONumberAndNameExchange:
      ProcessExchange := ProcessQSONumberAndNameExchange(ExchangeString, RData);

    QSONumberAndGeoCoordinates:
      ProcessExchange :=
        ProcessQSONumberAndGeoCoordinatesExchange(ExchangeString, RData);

    QSONumberAndCoordinatesSum:
      ProcessExchange :=
        ProcessQSONumberAndCoordinatesSumExchange(ExchangeString, RData);

    QSONumberAndZone:
      ProcessExchange := ProcessQSONumberAndZoneExchange(ExchangeString, RData);

    QSONumberDomesticOrDXQTHExchange:
      ProcessExchange :=
        ProcessQSONumberAndDomesticOrDXQTHExchange(ExchangeString, RData);

    QSONumberDomesticQTHExchange:
      ProcessExchange := ProcessQSONumberAndDomesticQTHExchange(ExchangeString,
        RData);

    QSONumberAndGridSquare:
      ProcessExchange := ProcessQSONumberAndGridSquareExchange(ExchangeString,
        RData);

    QSONumberNameChapterAndQTHExchange:
      ProcessExchange :=
        ProcessQSONumberNameChapterAndQTHExchange(ExchangeString, RData);

    QSONumberNameDomesticOrDXQTHExchange:
      ProcessExchange :=
        ProcessQSONumberNameAndDomesticOrDXQTHExchange(ExchangeString, RData);

    RSTAgeExchange:
      ProcessExchange := ProcessRSTAndAgeExchange(ExchangeString, RData);

    RSTAndFOCNumberExchange: //n4af
      ProcessExchange := ProcessRSTAndPowerExchange(ExchangeString, RData);
    //n4af

    AgeAndQSONumberExchange: ProcessExchange :=
      ProcessAgeAndQSONumberExchange(ExchangeString, RData);

    QSONumberAndAgeExchange: ProcessExchange :=
      ProcessQSONumberAndAgeExchange(ExchangeString, Rdata);

    RSTAgeAndPossibleSK:
      ProcessExchange := ProcessRSTAgeAndPossibleSK(ExchangeString, RData);

    RSTAndContinentExchange:
      ProcessExchange := ProcessRSTAndContinentExchange(ExchangeString, RData);

    RSTALLJAPrefectureAndPrecedenceExchange:
      ProcessExchange :=
        ProcessRSTAllJAPrefectureAndPrecedenceExchange(ExchangeString, RData);

    RSTAndGridExchange:
      ProcessExchange := ProcessRSTAndGridSquareExchange(ExchangeString, RData);

    RSTAndOrGridExchange:
      ProcessExchange := ProcessRSTAndOrGridSquareExchange(ExchangeString,
        RData);

    GridExchange:
      ProcessExchange := ProcessGridSquareExchange(ExchangeString, RData);

    Grid2Exchange:
      ProcessExchange := ProcessGrid2Exchange(ExchangeString, RData);

    RSTAndGrid3Exchange:
      ProcessExchange := ProcessRSTAndGrid3Exchange(ExchangeString, RData);
    // 4.96.3

    RSTAndPostalCodeExchange:
      ProcessExchange := ProcessRSTAndPostalCodeExchange(ExchangeString, RData);

    RSTAndPOTAPark:
      ProcessExchange := ProcessRSTAndPOTAPark(ExchangeString, RData);

    RSTAndQSONumberOrDomesticQTHExchange:
      ProcessExchange :=
        ProcessRSTAndQSONumberOrDomesticQTHExchange(ExchangeString, RData);

    RSTAndQSONumberOrFrenchDepartmentExchange:
      ProcessExchange :=
        ProcessRSTAndQSONumberOrFrenchDepartmentExchange(ExchangeString, RData);

    RSTDomesticQTHExchange:
      ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData);

    RSTDomesticOrDXQTHExchange:
      if (Contest = LABRE) and (RData.qth.countryid = 'PY') then
      ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString, RData)
       else
        ProcessExchange := ProcessRSTAndDomesticOrDXQTHExchange(ExchangeString,
         RData);

    RSTDomesticQTHOrQSONumberExchange:
      if DomesticCountryCall(RData.Callsign) and
        (StringHasLetters(ExchangeString)) then //n4af 4.44.4 HADX
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString,
          RData)
      else
        ProcessExchange := ProcessRSTAndQSONumberExchange(ExchangeString,
          RData);

    RSTNameAndQTHExchange:
      ProcessExchange := ProcessRSTNameAndQTHExchange(ExchangeString, RData);

    RSTPossibleDomesticQTHAndPower:
      ProcessExchange :=
        ProcessRSTPossibleDomesticQTHAndPowerExchange(ExchangeString, RData);

    RSTPowerExchange:
      ProcessExchange := ProcessRSTAndPowerExchange(ExchangeString, RData);

    RSTPrefectureExchange:
      ProcessExchange := ProcessRSTAndPrefectureExchange(ExchangeString, RData);

    RSTQSONumberExchange:
      ProcessExchange := ProcessRSTAndQSONumberExchange(ExchangeString, RData);

    NZFieldDayExchange:
      ProcessExchange := ProcessNZFieldDayExchange(ExchangeString, RData);

    RSTQSONumberAndDomesticQTHExchange:
      ProcessExchange :=
        ProcessRSTQSONumberAndDomesticQTHExchange(ExchangeString, RData);

    QSONumberAndPreviousQSONumber:
      ProcessExchange := ProcessQSONumberAndPreviousQSONumber(ExchangeString,
        RData);

    RSTQSONumberAndGridSquareExchange:
      ProcessExchange :=
        ProcessRSTQSONumberAndGridSquareExchange(ExchangeString, RData);

    RSTQSONumberOrDomesticQTHExchange:
      ProcessExchange :=
        ProcessRSTQSONumberorDomesticQTHExchange(ExchangeString, RData);
    // 4.53.2

    RSTQSONumberAndPossibleDomesticQTHExchange:
      ProcessExchange :=
        ProcessRSTQSONumberAndPossibleDomesticQTHExchange(ExchangeString,
        RData);

    QSONumberAndPossibleDomesticQTHExchange:
      ProcessExchange :=
        ProcessQSONumberAndPossibleDomesticQTHExchange(ExchangeString, RData);
    {KK1L: 6.73}

    RSTQSONumberAndRandomCharactersExchange:
      ProcessExchange :=
        ProcessRSTQSONumberAndRandomCharactersExchange(ExchangeString, RData);

    RSTQTHNameAndFistsNumberOrPowerExchange:
      ProcessExchange :=
        ProcessRSTQTHNameAndFistsNumberOrPowerExchange(ExchangeString, RData);

    RSTQTHExchange:
      ProcessExchange := ProcessRSTAndQTHExchange(ExchangeString, RData);

    RSTZoneAndPossibleDomesticQTHExchange:
      ProcessExchange :=
        ProcessRSTZoneAndPossibleDomesticQTHExchange(ExchangeString, RData);

    RSTZoneExchange:
      ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData);

    RSTZoneOrSocietyExchange:
      if StringIsAllNumbersOrSpaces(ExchangeString) then
        ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData)
      else
      begin
        ExchangeString := UpperCase(ExchangeString);
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString,
          RData);
      end;

    QSONumberPrecedenceCheckDomesticQTHExchange:
      ProcessExchange :=
        ProcessQSONumberPrecedenceCheckDomesticQTHExchange(ExchangeString,
        RData);

    RSTLongJAPrefectureExchange: {KK1L: 6.72 JA}
      begin
        ExchangeString := UpperCase(ExchangeString);
        ProcessExchange := ProcessRSTAndJAPrefectureExchange(ExchangeString,
          RData);
      end;

    RSTZoneOrDomesticQTH:
      if (DomesticCountryCall(RData.Callsign) or (not
        (StringisAllNumbersorSpaces(exchangestring)))) then // 4.77.6
        ProcessExchange := ProcessRSTAndDomesticQTHExchange(ExchangeString,
          RData)
      else
        ProcessExchange := ProcessRSTAndZoneExchange(ExchangeString, RData);

  end; { of case }
end;

procedure LogStringToRXData(LogString: Str80; var RXData: ContestExchange);

var
  ExchangeString: ShortString {Str80};

begin
  ExchangeString := GetLogEntryExchangeString(LogString);

  if ExchangeInformation.RST then
    RemoveFirstString(ExchangeString);
  logger.debug('Calling ProcessExchange from LogStringToRXData - LogString = (%s)', [LogString]);
  ProcessExchange(ExchangeString, RXData);
end;

procedure ProcessPartialCallAndInitialExchange(RXData: ContestExchange);

begin
  if PartialCallEnable or ExchangeMemoryEnable then // n4af 40.40.1
    //     AddCallToPartialList(RXData.Callsign, GetInitialExchangeStringFromContestExchange(RXData));
    GetInitialExchangeStringFromContestExchange(RXData); // n4af 40.40.1       }
end;

procedure CreateAndSendSAPMultiInfoMessage;

begin
  {
    if K1EANetworkEnable then Exit;

    TempString := MultiInfoMessage;

    if TempString = '' then Exit;

    if pos('$', TempString) > 0 then
    begin
      Index := pos('$', TempString);
      Delete(TempString, Index, 1);
      Insert('S&P', TempString, Index);
    end;

    if pos('%', MultiInfoMessage) > 0 then
    begin
      Index := pos('%', TempString);
      Delete(TempString, Index, 1);
      Str(Rate, NumberString);
      Insert(NumberString, TempString, Index);
    end;

    SendMultiInfoMessage(ActiveBand, ActiveMode, TempString);
  }
end;

procedure CreateAndSendCQMultiInfoMessage;

begin
  {
    TempString := MultiInfoMessage;

    if K1EANetworkEnable then
    begin

           //Send run message with current stable frequency

      case ActiveRadio of
        radioone: Freq := Radio1.FilteredStatus.Freq;
        RadioTwo: Freq := Radio2.FilteredStatus.Freq;
      else Freq := 0;
      end;

      if Freq > 0 then
      begin
        Str(Freq, FreqStr);
        TempString := 'M' + K1EAStationID + ' ' + FreqStr + ' ';
        SendMultiMessage(TempString);
        UpdateK1EAStationInfo(Run, K1EAStationID, FreqStr);
      end;

      Exit;
    end;

     // TR Network

    if MultiInfoMessage = '' then Exit;

    if pos('$', TempString) > 0 then
    begin
      Index := pos('$', TempString);
      Delete(TempString, Index, 1);

      if LastDisplayedFreq[radioone] > 0 then
        Str(LastDisplayedFreq[radioone], NumberString)
      else
        if RadioSetFreq > 0 then
          Str(RadioSetFreq, NumberString)
        else
          NumberString := '00000';

      Delete(NumberString, length(NumberString), 1);
      Delete(NumberString, length(NumberString), 1);
      Insert('.', NumberString, length(NumberString));
      Insert(NumberString, TempString, Index);
    end;

    if pos('%', MultiInfoMessage) > 0 then
    begin
      Index := pos('%', TempString);
      Delete(TempString, Index, 1);
      Str(Rate, NumberString);
      Insert(NumberString, TempString, Index);
    end;

    SendMultiInfoMessage(ActiveBand, ActiveMode, TempString);
  }
end;

function DomStringParse(InputString: Str14): Str14;
//Gav 4.44.8     Formats DOM from Initial Exchange to be used for Mult Needed display. Most DOM pass through untouched

var
  Index: integer;
  TempMultiplier, NumberString: Str14;

begin

  strU(InputString);

  result := InputString;

  if ActiveDomesticMult = RDADistrict then
  begin
    result := '';
    if length(InputString) = 4 then
      if InputString[1] in ['A'..'Z'] then
        if InputString[2] in ['A'..'Z'] then
          if InputString[3] in ['0'..'9'] then
            if InputString[4] in ['0'..'9'] then
            begin
              result := InputString;
            end;
    Exit;
  end;

  if ActiveDomesticMult = DOKCodes then
  begin
    result := '';
    for Index := 1 to length(InputString) do
    begin
      if InputString[Index] in ['A'..'Z'] then
      begin
        TempMultiplier := Copy(InputString, Index, 1);
        Break;
      end;
    end;
    result := TempMultiplier;
    Exit;
  end;

  if ActiveDomesticMult = IOTADomestic then
  begin
    result := '';
    if (length(InputString) < 3) or (length(InputString) > 5) then
      Exit;

    ContinentString := UpperCase(Copy(InputString, 1, 2));
    if GetContinentFromString(ContinentString) <> UnknownContinent then
    begin
      NumberString := Copy(InputString, 3, length(InputString) - 2);

      if not StringIsAllNumbers(NumberString) then
        Exit;

      while length(NumberString) < 3 do
        NumberString := '0' + NumberString;

      TempMultiplier := ContinentString + '-' + NumberString;
      result := TempMultiplier;
    end;
  end;

  if ActiveDomesticMult = GridSquares then
  begin
    result := '';
    if (length(InputString) <> 4) and (length(InputString) <> 6) then
      Exit;

    if (InputString[1] < 'A') or (InputString[1] > 'R') or
      (InputString[2] < 'A') or (InputString[2] > 'R') or
      (InputString[3] > '9') or (InputString[3] < '0') or
      (InputString[4] > '9') or (InputString[4] < '0') then
      Exit;

    if length(InputString) = 6 then
      if (InputString[5] < 'A') or (InputString[5] > 'Z') or
        (InputString[6] < 'A') or (InputString[6] > 'Z') then
        Exit;

    TempMultiplier := Copy(InputString, 1, 4);
    result := TempMultiplier;
    Exit;
  end;

  if ActiveDomesticMult = GridFields then
  begin
    result := '';
    if (length(InputString) <> 4) or (InputString[1] < 'A') or (InputString[1] >
      'R') or
      (InputString[2] < 'A') or (InputString[2] > 'R') or
      (InputString[3] > '9') or (InputString[3] < '0') or
      (InputString[4] > '9') or (InputString[4] < '0') then
      Exit;

    TempMultiplier := Copy(InputString, 1, 2);
    result := TempMultiplier;
    Exit;
  end;

end;

function GetSentRSTFromExchangeString(var ExchangeString: ShortString {Str40}):
  smallInt {Word};

var
  PotentialRSTSent: Str80 {40};
  TempString: ShortString {Str40};
  //  RSTString                   : string[3] {Str20};

begin
  GetSentRSTFromExchangeString := 0;

  if not LookForRSTSent then
    Exit;

  TempString := ExchangeString;

  while TempString <> '' do
  begin
    PotentialRSTSent := RemoveLastString(TempString);

    if Copy(PotentialRSTSent, 1, 1) = 'S' then
    begin
      Delete(PotentialRSTSent, 1, 1);

      if StringIsAllNumbers(PotentialRSTSent) then
        if LooksLikeRST(PotentialRSTSent, Result, ActiveMode) then
        begin
          GetSentRSTFromExchangeString := Result;

          { Delete all the stuff we have }

          Delete(ExchangeString, 1, length(TempString));

          { Remove the callsign }

          RemoveFirstString(ExchangeString);

          { Rebuild the exchange string without the callsign }

          ExchangeString := TempString + ' ' + ExchangeString;
          Exit;
        end;

    end;
  end;
end;

function SpecAndExchangeMatch(Spec: Str40; Exchange: Str40): boolean;

begin
  SpecAndExchangeMatch := False;
end;

function FoundExchangeFromTemplate(Template: string; ExchangeString: Str40; var
  RData: ContestExchange): boolean;

var
  FormatSpec, Exchange: ShortString;
  TestSpec, TestExchange: Str40;

begin
  FoundExchangeFromTemplate := False;

  FormatSpec := PrecedingString(Template, '|');

  Exchange := ExchangeString;

  while (FormatSpec <> '') and (Exchange <> '') do
  begin
    TestSpec := RemoveFirstString(FormatSpec);
    TestExchange := RemoveFirstString(Exchange);

    if not SpecAndExchangeMatch(TestSpec, TestExchange) then
      Exit;
  end;

  { We have found that the format spec and the exchange match up }

end;

function ProcessTemplateExchange(ExchangeString: Str40; var RData:
  ContestExchange): boolean;

var
  Entry: integer;

begin
  ProcessTemplateExchange := False;

  if NumberExchangeTemplates = 0 then
    Exit;

  for Entry := 0 to NumberExchangeTemplates - 1 do
    if FoundExchangeFromTemplate(ExchangeTemplateList[Entry]^, ExchangeString,
      RData) then
    begin
      ProcessTemplateExchange := True;
      Exit;
    end;

end;

procedure PassStationToCTNetwork;

begin

end;

function GoodLookingRDA(rda: Str20): boolean;

{ Verifies that the grid square is legitimate }

var
  CharPosition: integer;

begin
  result := False;

  if not ((length(rda) = 4)) then
    Exit;

  strU(rda);

  for CharPosition := 1 to 4 do
    case CharPosition of
      1, 2:
        if not (rda[CharPosition] in ['A'..'Z']) then
          Exit;

      3, 4:
        if not (rda[CharPosition] in ['0'..'9']) then
          Exit;

    end;

  result := True;
end;

procedure SendUDPRotorCommand(Heading: integer); // ny4i 4.44.9
var
  // msg: TIdBytes;
  sBuf: AnsiString;
  freq: integer;
  sFreqBand: AnsiString;
begin
  case ActiveRadio of
    radioone: freq := Radio1.FilteredStatus.Freq;
    RadioTwo: freq := Radio2.FilteredStatus.Freq;
  else
    freq := 0;
  end; // case

  case freq of
    1800000..1899999: sFreqBand := '1.8';
    3500000..3999999: sFreqBand := '3.5';
    7000000..7999999: sFreqBand := '7';
    10000000..10100000: sFreqBand := '10';
    14201000..14999999: sFreqBand := '14';
    18000000..18999999: sFreqBand := '18';
    21000000..21999999: sFreqBand := '21';
    24000000..24999999: sFreqBand := '24';
    28000000..29999999: sFreqBand := '28';
  else
    sFreqBand := ' ';
  end; // case
  sBuf := '<N1MMRotor>' +
    '<rotor>rotor name</rotor>' +
    '<goazi>' + SysUtils.Format('%0.0d', [Heading]) + '</goazi>' +
    '<offset>0.0</offset>' +
    '<bidirectional>0</bidirectional>' +
    '<freqband>' + sFreqBand + '<freqband>' +
    '</N1MMRotor>';
  //SetLength(msg,Length(sBuf));
  //msg := RawToBytes(sBuf[1], Length(sBuf));
  //udp.Broadcast(msg, UDPBroadcastRotorPort);     // ny4i 4.44.9
  udp.BroadcastEnabled := true;
  logger.Trace('[SendUDPRotorCommand] N1MM -> %s:%d %s',   // Issue #989
    [UDPBroadcastAddress, UDPBroadcastRotorPort, sBuf]);
  udp.Send(UDPBroadcastAddress, UDPBroadcastRotorPort, sBuf);

end; // SendUDPRotatorCommand

procedure SendPSTRotorCommand(Heading: integer); // Issue #732
// Send an azimuth to PstRotator via its native UDP interface.  PstRotator
// listens on its "UDP Control Port" (PSTRotatorUDPPort, default 12000) at
// PSTRotatorIPAddress.  Reuses the shared 'udp' Indy client, same as the N1MM
// path above.  Command format per the PstRotator UDP spec:
//   <PST><AZIMUTH>nnn</AZIMUTH></PST>
var
  sBuf: AnsiString;
begin
  sBuf := '<PST><AZIMUTH>' + SysUtils.Format('%d', [Heading]) + '</AZIMUTH></PST>';
  logger.Trace('[SendPSTRotorCommand] -> %s:%d %s',   // Issue #989
    [PSTRotatorIPAddress, PSTRotatorUDPPort, sBuf]);
  udp.Send(PSTRotatorIPAddress, PSTRotatorUDPPort, sBuf);
end; // SendPSTRotorCommand

function ValidClass(sClass: Str10): boolean; // ny4i 4.45.3
var
  i: integer;
  sXmit: string;
  sCategory: string;
  classSet: boolean;
begin
  classSet := false;
  for i := 1 to length(sClass) do
  begin
    if sClass[i] in ['0'..'9'] then
    begin
      sXmit := sXmit + sClass[i];
    end
    else if (((contest = ARRLFIELDDAY) and (sClass[i] in ['A'..'F'])) or
      ((contest = WINTERFIELDDAY) and (sClass[i] in ['I', 'O', 'H', 'M']))) then

    begin
      if classSet then
      begin
        sCategory := '';
        break;
      end
      else
      begin
        classSet := true;
        sCategory := sCategory + sClass[i];
      end;
    end
    else
    begin // ny4i Issue163 There is something else here - Error
      sCategory := '';
      // Used to force an TC_IMPROPERARRLFIELDDAYCLASS error later
      break; // jump to next part to evaluate error
    end;
  end;
  if (length(sXmit) = 0) or
    (not (StrToInt(sXmit) in [1..99])) then
  begin
    ExchangeErrorMessage := TC_IMPROPERTRANSMITTERCOUNT;
  end
  else if length(sCategory) <> 1 then
  begin
    if contest = ARRLFIELDDAY then
    begin
      ExchangeErrorMessage := TC_IMPROPERARRLFIELDDAYCLASS;
    end
    else if contest = WINTERFIELDDAY then
    begin
      ExchangeErrorMessage := TC_IMPROPERWINTERFIELDDAYCLASS;
    end;

  end
  else
  begin
    Result := true;
  end;
  // Result := (StrToInt(sXmit) in [1..99]) and (length(sCategory) = 1);
end;

// ^[AaWaKkNn][a-zA-Z]?[0-9][a-zA-Z]{1,3}$/

function IsValidGUID(const guid: string): boolean;
var
  regex: TPerlRegEx;
begin
  // create our regex instance, and we want to do a case insensitive search, in multiline mode
  Result := false;
  regex := TPerlRegEx.Create;
  try
     logger.debug('Checking if %s is a valid guid', [guid]);
     regex.RegEx := '^[{]?[0-9a-fA-F]{8}-?([0-9a-fA-F]{4}-?){3}[0-9a-fA-F]{12}[}]?$';  // letters-hyphen-digits only;
     regex.Subject := guid;

     Result := regex.MatchAgain;
  finally
     regex.Free;
  end;
  if Result then
     begin
     logger.debug('%s is a valid GUID', [guid]);
     end;
end;

function IsValidUSPrefix(const callsign: string): boolean;
var
  regex: TPerlRegEx;
begin
  // create our regex instance, and we want to do a case insensitive search, in multiline mode
  Result := false;
  regex := TPerlRegEx.Create;
  try
    logger.debug('Checking if %s is a valid US prefix', [callsign]);
    regex.RegEx := '^[AaWaKkNn][a-zA-Z]?';
    // Valid against all of LOTW file

    regex.Subject := callsign;

    Result := regex.MatchAgain;
  finally
    regex.Free;
  end;
  if Result then
  begin
    logger.debug('%s is a valid US prefix', [callsign]);
  end;
end;

function IsValidUSCallsign(const callsign: string): boolean;
var
  regex: TPerlRegEx;
begin
  // create our regex instance, and we want to do a case insensitive search, in multiline mode
  Result := false;
  regex := TPerlRegEx.Create;
  try
    logger.debug('Checking if %s is a valid US call', [callsign]);
    regex.RegEx := '^[AaWaKkNn][a-zA-Z]?[0-9][a-zA-Z]{1,3}$';
    // Valid against all of LOTW file

    regex.Subject := callsign;

    Result := regex.MatchAgain;
  finally
    regex.Free;
  end;
  if Result then
  begin
    logger.debug('%s is a valid US call', [callsign]);
  end;
end;

// Add Uses PerlRegEx to unit and code from https://regular-expressions.mobi/delphi.html?wlr=1

function IsValidCallsign(const callsign: string): boolean;
var
  regex: TPerlRegEx;
begin
  // create our regex instance, and we want to do a case insensitive search, in multiline mode
  Result := false;
  regex := TPerlRegEx.Create;
  try
    logger.debug('Checking if %s is a valid call', [callsign]);
    regex.RegEx := '^(?:\w{1,2}\d\/|\d\w\/|\w{1,2}\/)?+\w+[0-9]+\w+\/?\w*\s*$';
    // Valid against all of LOTW file

    regex.Subject := callsign;

    Result := regex.MatchAgain;
  finally
    regex.Free;
  end;
  if Result then
  begin
    logger.debug('%s is a valid call', [callsign]);
  end;
end;

function IsValidPOTAPark(const park: string): boolean;
var
  regex: TPerlRegEx;
begin
  // create our regex instance, and we want to do a case insensitive search, in multiline mode
  Result := false;
  regex := TPerlRegEx.Create;
  try
    logger.debug('Checking if %s is a valid park', [park]);
   // regex.RegEx := '^([A-Za-z]{1,4})-(\d{1,5})$';  // letters-hyphen-digits only; rejects RST values like '59'      - Claude's version but this does not follow US-12345
   regex.RegEx := '^([A-Za-z]{2})-(\d{4,5})$';  // letters-hyphen-digits only; rejects RST values like '59'
    //regex.RegEx := '^(?:\w{1,2}\d\/|\d\w\/|\w{1,2}\/)?+\w+[0-9]+\w+\/?\w*\s*$';  // Valid against all of LOTW file

    regex.Subject := park;

    Result := regex.MatchAgain;
  finally
    regex.Free;
  end;
  if Result then
  begin
    logger.debug('%s is a valid park', [park]);
  end;
end;

begin
  CD.CellBuffer.MaximumMemoryToUse := 40000 * ua4wliscpconst {*4 - ua4wli};
  StuffInit;
end.

