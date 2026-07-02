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
unit LogWind;

{$IMPORTEDDATA OFF}
interface
uses
utils_text,
  uWinKey,
  uMults,
//  uTrayBalloon,
  uCTYDAT,
  uCallsigns,
  TF,
  uCommctrl,
  Messages,
  Version,
  VC,
  uInputQuery,
  LogNet,
  LogGrid,
  LogDom,
  LogRadio,
  LogK1EA, {SlowTree,}
  Tree, {Crt, Dos,}
  LogSCP,
  ZoneCont,
  Windows,
  utils_file,
  BeepUnit,
  uGradient
  ;

const
  tBaseFrequencys                       : array[Band160..Band12] of integer =
    (1000, 3000,  7000, 14000, 21000, 28000, 10000, 18000, 24000);
//T1 : Cardinal = 1800000;
var
  TMult                                 : str10 = ' ';
  BufLine                               : integer = 0;
  ie_check                              : boolean = false;
  tBandMapCutoffFrequency               : integer;
  IE_Switch                             : boolean = False;
  tBandMapPlaceHolder                   : CallString;
  tB4IndicatorPrevState                 : integer;
  tNewMultIndicatorPrevState            : integer;
  tQSOsWithThisStationPrevState         : integer;
  tCountryNamePrevState                 : Word;
  tBeamHeadingPrevState                 : GridString;
  tLocalTimePrevState                   : Word;
  Gate                                  : boolean = False;
  a                                     : cardinal = 0;
  b                                     : cardinal = 0;
  c                                     : cardinal = 0;
  e                                    : cardinal = 0;
  T2                                    : cardinal = 0;
  d2                                    : cardinal = 0;
  d3                                    : cardinal = 0;
 // d4                                    : cardinal = 0;
  Start                                 : boolean = False;
  Save                                  : cardinal = 0;
  d1                                    : cardinal = 0;
  BMp                                   : integer = 0;
  const
  PendingQTCArraySize                   = 600;

  Blink                                 = 128;

  NumberEditableLines                   = 5;
  MaximumReminderRecords                = 100;
  MaxExchangeTemplateEntries            = 20;

  QSOInformationWindowLX                = 55;
  QSOInformationWindowLY                = 4;
  QSOInformationWindowRX                = 80;
  QSOInformationWindowRY                = 7;

  RemainingMultsWindowLX                = 1;
  RemainingMultsWindowLY                = 8;
  RemainingMultsWindowRX                = 54;
  RemainingMultsWindowRY                = 13;

  BigRemainingMultsWindowLX             = 1;
  BigRemainingMultsWindowLY             = 8;
  BigRemainingMultsWindowRX             = 80;
  BigRemainingMultsWindowRY             = 13;

  MultiplierInformationWindowLX         = 55;
  MultiplierInformationWindowLY         = 8;
  MultiplierInformationWindowRX         = 80;
  MultiplierInformationWindowRY         = 12;

  EditableLogWindowLX                   = 1;
  EditableLogWindowLY                   = 14;
  EditableLogWindowRX                   = 80;
  EditableLogWindowRY                   = 18;

  BigWindowLX                           = 1;
  BigWindowLY                           = 2;
  BigWindowRX                           = 80;
  BigWindowRY                           = 18;

type

  TFreqMemoryType = array[BandType, CW..Phone] of LONGINT;

  K5KAStateType = (KAIdle, KAMessageStarted, KASendingMessage);
  K5KAObject = record // Used for fancy stuff with AltD while sending
    AltDString: Str20; // Working string of AltD contents
    CQOrExchangeStarted: boolean; // Tells WindowEditor to do something
    ModeEnabled: boolean; // On/Off switch for this mode
    State: K5KAStateType;
  end;

  RotatorType = (NoRotator, DCU1Rotator, OrionRotator, YaesuRotator, AlfaSpidRotator, PSTRotator); {KK1L: 6.71 Added YaesuRotator} {Issue #732: PSTRotator (UDP)}

  RateBandArrayType = array[Band160..Band10] of Byte;

  SpecialCommandType = (NoSpecialCommand, SendF1Message, AutoAltDSpaceBar);

  //  OpModeType = (CQOpMode, SearchAndPounceOpMode);

  MultiMessage = ^Str80;

  TenMinuteRuleType = (NoTenMinuteRule, TimeOfFirstQSO);

  TenMinuteTimeRecord = record
    Band: BandType;
    Mode: ModeType;
    Time: Cardinal {TimeRecord};
  end;

  UserInfoType = (
    NoUserInfo,
    NameInfo,
    QTHInfo,
    CheckSectionInfo,
    SectionInfo,
    OldCallInfo,
    FocInfo,
    GridInfo,
    CQZoneInfo,
    ITUZoneInfo,
    User1Info,
    User2Info,
    User3Info,
    User4Info,
    User5Info,
    CustomInfo);

  TwoRadioStates = (TwoRadiosDisabled, Idle, CallReady, StationCalled, SendingExchange);

  BandMapEntry = record
    Call: EightBytes;
    Frequency: LONGINT;
    QSXOffset: LONGINT; { + or - offset from Frequency }
    StatusByte: Byte; { Bits 0-5 = # minutes remaining (0-63)
    Bit 6   = Dupe   Bit 7 = Mult   }
//    Band: BandType;
    TelnetSpot: Byte;
    bmBand: BandType;
    bmMode: ModeType;
    NextEntry: Pointer;
    Source: CallString;
  end;

  tr4wBandMapEntry = record

    bmFrequency: LONGINT;
    bmQSXOffset: LONGINT; { + or - offset from Frequency }
    bmCall: CallString;
    bmTelnetSpot: Byte;
    bmMinutesRem: Byte;
    bmDupe: boolean;

    bmSource: CallString;
    bmMult: boolean;
    bmBand: BandType;
    bmMode: ModeType;
  end;

//  BandMapArray = array of {tr4wBandMapEntry} BandMapEntry;

  BandMapEntryPointer = ^BandMapEntry;

  BandMapSplitModeType = (ByCutoffFrequency, AlwaysPhone); {KK1L: 6.64}

  RateDisplayType = (QSOs, Points, BandQSOs);
  HourDisplayType = (ThisHour, LastSixtyMins, BandChanges, BandChangesThisComputer);

  K1EAStationInfoFieldType = (Pass, Run);

  K1EAMultiInfoRecord = record
    RunFreq, PassFreq: LONGINT;
  end;

  TotalScoreMessageRecord = record
    Score: LONGINT;
    MessageString: Str40;
  end;

  KeyerType = (NoKeyer, CPU, MM3);

//  PendingQTCArrayType = array[0..PendingQTCArraySize - 1] of PendingQTCDataType;
//  PendingQTCArrayPtr = ^PendingQTCArrayType;

  QTCDataType = record
    Call: CallString {EightBytes};
    NumberQTCs: Byte {integer};
  end;

  QTCDataArrayType = array[0..500 - 1] of QTCDataType;
  QTCDataArrayPtr = ^QTCDataArrayType;

  WindowType = (NoWindow,
    AlarmWindow,
    AltCallWindow, //KK1L: 6.73
    BandMapWindow,
    BandModeWindow,
    BeamHeadingWindow,
    BigWindow,
    CallWindow,
    ClockWindow,
    CodeSpeedWindow,
    ContestTitleWindow,
    DATEWINDOW,
    DupeInfoWindow,
    DupeSheetWindow,
    EditableLogWindow,
    ExchangeWindow,
    ExtraTimeWindow,
    FreeMemoryWindow,
    FrequencyOneWindow,
    FrequencyTwoWindow, //KK1L: 6.73
    FunctionKeyWindow,
    HourRateWindow,
    InsertWindow,
    MultiplierInformationWindow,
    NamePercentageWindow,
    NameSentWindow,
    POSSIBLECALLWINDOW,
    QSOInformationWindow,
    QSONumberWindow,
    QTCNumberWindow,
    UserInfoWindow,
    CountryNameWindow,
    QUICKCOMMANDWINDOW,
    QuickCommand2Window,
    RadioWindow,
    REMAININGMULTSWINDOW,
    RateWindow,
    RTTYWindow,
    RTTYInverseWindow,
    TotalScoreWindow,
    TotalWindow,
    WholeScreenWindow);

  LogEntryArray = array[1..NumberEditableLines] of string {[100]};

//  RemainingMultList = array[0..MaxNumberRemainingDomQTHs] of boolean;
//  RemainingMultListPointer = ^RemainingMultList;

  ColorRecord = record
    AlarmWindowBackground: tr4wColors;
    AlarmWindowColor: tr4wColors;
    AltCallWindowBackground: tr4wColors; {KK1L: 6.73}
    AltCallWindowColor: tr4wColors; {KK1L: 6.73}

    AutoSendArrowWindowBackground: tr4wColors;
    AutoSendArrowWindowColor: tr4wColors;

    BandMapWindowBackground: tr4wColors;
    BandMapWindowColor: tr4wColors;

    BandModeWindowBackground: tr4wColors;
    BandModeWindowColor: tr4wColors;
    BeamHeadingWindowBackground: tr4wColors;
    BeamHeadingWindowColor: tr4wColors;
    BigWindowBackground: tr4wColors;
    BigWindowColor: tr4wColors;

    CallWindowBackground: tr4wColors;
    CallWindowColor: tr4wColors;
    ClockWindowBackground: tr4wColors;
    ClockWindowColor: tr4wColors;
    CodeSpeedWindowBackground: tr4wColors;
    CodeSpeedWindowColor: tr4wColors;
    ContestTitleWindowBackground: tr4wColors;
    ContestTitleWindowColor: tr4wColors;
    CountryNameWindowBackground: tr4wColors;
    CountryNameWindowColor: tr4wColors;

    DateWindowBackground: tr4wColors;
    DateWindowColor: tr4wColors;
    DupeInfoWindowBackground: tr4wColors;
    DupeInfoWindowColor: tr4wColors;
    DupeSheetWindowBackground: tr4wColors;
    DupeSheetWindowColor: tr4wColors;

    EditableLogWindowBackground: tr4wColors;
    EditableLogWindowColor: tr4wColors;
    ExchangeWindowBackground: tr4wColors;
    ExchangeWindowColor: tr4wColors;
    ExchangeSAndPWindowBackground: tr4wColors;

    FreeMemoryWindowBackground: tr4wColors;
    FreeMemoryWindowColor: tr4wColors;

    FrequencyOneWindowBackground: tr4wColors;
    FrequencyTwoWindowBackground: tr4wColors; {KK1L: 6.73}

//    FrequencyOneWindowHighlight: tr4wColors; {KK1L: 6.73}
//    FrequencyTwoWindowHighlight: tr4wColors; {KK1L: 6.73}

    FrequencyOneWindowColor: tr4wColors;
    FrequencyTwoWindowColor: tr4wColors; {KK1L: 6.73}

    FunctionKeyWindowBackground: tr4wColors;
    FunctionKeyWindowColor: tr4wColors;

    InsertWindowBackground: tr4wColors;
    InsertWindowColor: tr4wColors;

    MultiplierInformationWindowBackground: tr4wColors;
    MultiplierInformationWindowColor: tr4wColors;

    NamePercentageWindowBackground: tr4wColors;
    NamePercentageWindowColor: tr4wColors;
    NameSentWindowBackground: tr4wColors;
    NameSentWindowColor: tr4wColors;

    PossibleCallWindowBackground: tr4wColors;
    PossibleCallWindowColor: tr4wColors;
    PossibleCallWindowDupeBackground: tr4wColors;
    PossibleCallWindowDupeColor: tr4wColors;

    QSOInformationWindowBackground: tr4wColors;
    QSOInformationWindowColor: tr4wColors;

    QSONumberWindowBackground: tr4wColors;
    QSONumberWindowColor: tr4wColors;

    QTCNumberWindowBackground: tr4wColors;
    QTCNumberWindowColor: tr4wColors;
    QuickCommandWindowBackground: tr4wColors;
    QuickCommandWindowColor: tr4wColors;

    RadioOneWindowBackground: tr4wColors; {KK1L: 6.73 Changed from RadioWindowBackground}
    RadioOneWindowColor: tr4wColors; {KK1L: 6.73 Changed from RadioWindowColor}
    RadioTwoWindowBackground: tr4wColors; {KK1L: 6.73}
    RadioTwoWindowColor: tr4wColors; {KK1L: 6.73}

    RateWindowBackground: tr4wColors;
    RateWindowColor: tr4wColors;

    RemainingMultsWindowSubdue: tr4wColors;
    RemainingMultsWindowBackground: tr4wColors;
    RemainingMultsWindowColor: tr4wColors;
    TotalScoreWindowBackground: tr4wColors;
    TotalScoreWindowColor: tr4wColors;
    TotalWindowBackground: tr4wColors;
    TotalWindowColor: tr4wColors;

    UserInfoWindowColor: tr4wColors;
    UserInfoWindowBackground: tr4wColors;

    WholeScreenColor: tr4wColors;
    WholeScreenBackground: tr4wColors;
  end;

  ReminderRecord = record
    Time: integer;
    DateString: string[10];
    DayString: string[10];
    RemMessage: Str80;
    Alarm: boolean;
  end;

  ReminderArray = array[0..MaximumReminderRecords - 1] of ReminderRecord;
  ReminderArrayPointer = ^ReminderArray;

  RateRecord = record
    TotalQSOs: integer {Byte};
    TotalPoints: integer {Byte};
    BandQSOs: RateBandArrayType;
  end;

  StringPointer = ^string;

  InitialExchangeCursorPosType = (AtEnd, AtStart);

  CallWindowPositionType = (NormalCallWindowPosition, UpOneCallWindowPosition);

const
  ZoneMultTypeSA                        : array[ZoneMultType] of PChar =
    (
    'NONE',
    'CQ ZONES',
    'ITU ZONES',
    'JA PREFECTURES',
    'BRANCH ZONES',
    'EU HFC YEAR',
    'RF CHAMP ZONES'
    );

  TenMinuteRuleTypeSA                   : array[TenMinuteRuleType] of PChar = ('NONE', 'TIME OF FIRST QSO');

  RotatorTypeSA                         : array[RotatorType] of PChar = ('NONE', 'DCU1', 'ORION', 'YAESU', 'ALFA SPID', 'PSTROTATOR');

  CallWindowPositionTypeSA              : array[CallWindowPositionType] of PChar = ('NORMAL', 'UP');

  BandMapSplitModeTypeSA                : array[BandMapSplitModeType] of PChar = ('BY CUTOFF FREQ', 'ALWAYS PHONE');

  HourDisplayTypeSA                     : array[HourDisplayType] of PChar = ('THIS HOUR', 'LAST SIXTY MINUTES', 'BAND CHANGES', 'BAND CHANGES ON THIS COMPUTER');

  RateDisplayTypeStringArray            : array[RateDisplayType] of PChar = ('QSOS', 'QSO POINTS', 'BAND QSOS');

  IECursorPosTypeStringArray            : array[InitialExchangeCursorPosType] of PChar = ('AT END', 'AT START');

  InitialExchangeTypeStringArray        : array[InitialExchangeType] of PChar =
    (
    'NONE',
    'NAME',
    'NAME QTH',
    'CHECK SECTION',
    'SECTION',
    'QTH',
    'FOC NUMBER',
    'GRID',
    'ZONE',
    'USER 1',
    'USER 2',
    'USER 3',
    'USER 4',
    'USER 5',
    'CUSTOM'
    );
  UserInfoTypeSA                        : array[UserInfoType] of PChar =
    (
    'NONE',
    'NAME',
    'QTH',
    'CHECK SECTION',
    'SECTION',
    'OLD CALL',
    'FOC NUMBER',
    'GRID',
    'CQ ZONE',
    'ITU ZONE',
    'USER 1',
    'USER 2',
    'USER 3',
    'USER 4',
    'USER 5',
    'CUSTOM'
    );
var

  k                                     : integer;
  //  BMDrawCounter                    : integer;

  ActiveBackground                      : Byte;
  ActiveBand                            : BandType {= Band160};
  ActiveColor                           : Byte;
  ActiveExchange                        : ExchangeType {= NoExchangeReceived};
  ActiveInitialExchange                 : InitialExchangeType {= NoInitialExchange};
  ActiveMode                            : ModeType{$IF MMTTYMODE} = Digital{$IFEND};

  //  ActiveModemPort: PortType;
  ActiveQSOPointMethod                  : QSOPointMethodType {= NoQSOPointMethod};
  ActiveRotatorPort                     : PortType;
  ActiveRotatorType                     : RotatorType {= NoRotator};
  //  ActiveRTTYPort                        : PortType;
  ActiveWindow                          : WindowType;
  ActiveZoneMult                        : ZoneMultType {= NoZoneMults};
  AlarmSet                              : boolean;
  AlarmMinute                           : integer;
  AlarmHour                             : integer;
  AltDBufferEnable                      : boolean;
  AltDCQEnable                          : boolean;
  AskForFrequencies                     : boolean;
  AutoReturnToCQMode                    : boolean = True;
  AutoSAPEnableRate                     : LONGINT = 500;
  AutoSendCharacterCount                : integer;
  AutoSendEnable                        : boolean;
  AutoTimeIncrementQSOs                 : integer;
  AutoTimeQSOCount                      : Byte;

  BandMapSO2RDisplay                    : boolean;
  BandMapAllBands                       : boolean;
  BandMapAllModes                       : boolean;
  BandMapBand                           : BandType {= Band160};
  BandMapMode                           : ModeType {= CW};
  BandMapBlinkingCall                   : CallString;
  BandMapBlinkingCallRecord             : BandMapEntryPointer;
  BandMapCursorData                     : BandMapEntryPointer;
  BandMapCursorFrequency                : LONGINT;
  BandMapDisplayCQ                      : boolean = True;
  BandMapModeCutoffFrequency            : array[Band160..Band2] of LONGINT =
    (
    1840000,
    3700000,
    7100000,
    14100000,
    21150000,
    28300000,
    10150000,
    18110000,
    24930000,
    50100000,
    144200000
    );

  BandMapDecayTime                      : integer = 60;
  BandMapDecayValue                     : integer = 60; {KK1L: 6.65}
  BandMapDecayMultiplier                : integer = 1; {KK1L: 6.65}
  BandMapDupeDisplay                    : boolean = True;
  BandMapEnable                         : boolean;
  BandMapNeedsRefresh                   : boolean = False;
  BandMapEntryInCallWindow              : boolean;
  BandMapFileVersion                    : Char = '1';
  {KK1L: 6.65 Expanded array to cover all cases to keep BM from going whacko when tuning out of band}
  BandMapFirstEntryList                 : array[Band160..NoBand, CW..FM] of BandMapEntryPointer;
  BandMapGuardBand                      : integer; // = 200;
  BandMapDisplayLimit                   : integer = 164;   //GAV added for centred   bandmap
  BandMapMultsOnly                      : boolean; {KK1L: 6.68}
  BandMapSplitMode                      : BandMapSplitModeType {= ByCutoffFrequency}; {KK1L: 6.64}
  BandMapTotalCalls                     : integer;
  BandMapWindowRY                       : integer;
  BandSave                              : BandType;

//  BandMemory                  : array[RadioType] of BandType;

  CalledFromCQMode                      : boolean = True; {KK1L: 6.73}
  CallLastTimeIWasHere                  : CallString; {KK1L: 6.73 Used in LOGSUBS2 to trigger band map info update}
  CallWindowPosition                    : CallWindowPositionType {= NormalCallWindowPosition};
  CallWindowShowAllSpots                : boolean; {KK1L: 6.65}

  CommandUseInactiveRadio               : boolean; {KK1L: 6.73}
  ContactsPerPage                       : integer = 50;
  ContinentString                       : Str20;
  //  tr4w_contest                          : string;

  ContestName                           : Str80; {KK1L: 6.68 shortened from Str80}
  ContestTitle                          : ShortString;
  ContinentQSOCount                     : array[BandType, ContinentType] of Word;
  ControlBMemory                        : CallString;
  CodeSpeedIncrement                    : integer = 3; {KK1L: 6.72}
  CountryString                         : Str20;
  //   CQMenu                          : Str80;
  CustomInitialExchangeString           : Str40; {KK1L: 6.67 was Str80;}
  CustomUserString                      : Str40; {KK1L: 6.68 shortened from Str80}
  CWEnabled                             : boolean  = True;
 // CWByCAT                               : boolean  = False;   // ny4i 4.44.5

  DigitalModeEnable                     : boolean;

  DisplayBandMapEnable                  : boolean = True; {KK1L: 6.73}
  DisplayedCodeSpeed                    : Byte;
  DVKEnable                             : boolean;

  DVKLocalizedMessagesEnable            : boolean;
//  DVPEnabled                            : boolean = True;
  DXMultLimit                           : integer = 32766; {KK1L: 6.65}

//  EditableLogDisplayed                  : boolean;
  EscapeFromEditBandMap                 : boolean;
  NeedToSynchBandMap                    : boolean = True; {KK1L: 6.69}
  //   EightBitRTTYPort                : boolean;
     //   ExchangeFunctionKeyMenu         : Str80;
  ExchangeTemplateList                  : array[0..MaxExchangeTemplateEntries - 1] of StringPointer;
  ExchangeWindowCursorPosition          : Byte;

  //   FirstDisplayableBandMapFrequency: LONGINT; {KK1L: 6.64}
  FirstDisplayedBandMapColumn           : integer; {KK1L: 6.64 allows tracking of bandmap display overflow}
  //  FirstDisplayedBandMapFrequency   : LONGINT; {KK1L: 6.64}

    {KK1L: 6.65 Made FoundCursor global. DisplayBandMap will set false if not within guardband}
  FoundCursor                           : boolean;

  FrequencyDisplayed                    : boolean;

  tFrequencyMemory                      : integer;

  FreqMemory                            : TFreqMemoryType;

  DefaultFreqMemory                     : TFreqMemoryType =
    (
    (0001820000, 1840000, 0001840000),
    (0003525000, 3580000, 0003850000),
    (0007025000, 7040000, 0007070000),
    (0014025000, 14080000, 0014225000),
    (0021025000, 21080000, 0021300000),
    (0028050000, 28080000, 0028400000),

    (0010105000, 10125000, 0010105000),
    (0018068000, 18110000, 0018110000),
    (0024890000, 24920000, 0024930000),
    (0050125000, 50125000, 0050125000),
    (0144100000, 144200000, 0144200000),
    (0222100000, 0, 0222100000),
    (0433100000, 0, 0433200000),
    (0902000000, 0, 0902000000),
    (1296200000, 0, 1296200000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000),
    (0000000000, 0, 0000000000)
    );

  FrequencyMemoryEnable                 : boolean = True;
  FreqPollRate                          : integer = 10; {KK1L: 6.71a Frequency Poll Rate in milliseconds}
  BMDelay                               :  integer = 0; // 4.93.3
  GridSquareListShown                   : boolean;

  HourDisplay                           : HourDisplayType {= ThisHour};

  tHandLogMode                          : boolean;
  InactiveSwapRadio                     : boolean;  // n4af 4.41.3
  IncrementTimeEnable                   : boolean;
  InEditBandMap                         : boolean; {KK1L 6.65}
  InitialExchangeCursorPos              : InitialExchangeCursorPosType { = AtEnd};

  JustLoadingBandMapWithNoRadio         : boolean; {KK1L: 6.68}

  K1EAMultiInfo                         : array[Band160..Band10] of K1EAMultiInfoRecord;

  K5KA                                  : K5KAObject {= (AltDString: ''; State: KAIdle)};
//  K5KAAltDString                        : Str20;

  LastCQFrequency                       : LONGINT;
  LastSPFrequency                       : LONGINT;

  LastCQMode                            : ModeType {= CW};
  LastSPMode                            : ModeType {= CW};
  //  LastDisplayableBandMapFrequency  : LONGINT; {KK1L: 6.64}
  LastDisplayedBand                     : BandType = NoBand;
  //  LastDisplayedBandMapFrequency    : LONGINT; {KK1L: 6.64}
    //  LastDisplayedDate                     : Str20;
  LastDisplayedFMMode                   : boolean;
//  LastDisplayedFreq           : array[RadioType] of LONGINT; {KK1L: 6.73}
  LastDisplayedMode                     : ModeType {= NoMode};
  //  LastDisplayedTime                     : Str20;
  //  LastDisplayedHour                     : Str20;
  LastEditedBandMapEntry                : integer;
  LastFullTimeString                    : Str20;
  LastSecond100                         : Word {= 0}; {KK1L: 6.71a Will store the hundredths of seconds since UpdateTimeAndRateDisplays }
  {           was called. Used to support wicked fast radio checking               }
  LastHeadingShown                      : integer;
//  LastQTCTimeSent                  : Str20;
//  LogConfigFileName           : string {Str80};
//  LogFileName                           : string {40};

//  LogRestartFileName          : string;
  LogSubTitle                           : Str40; {KK1L: 6.68 shortened from Str80}
  //  LogTempFileName                       : string {Str40};

  MaximumDisplayableRemainingMults      : Byte;
  MaxNumberOfZones                      : integer;
  MinutesSinceLastBMUpdate              : integer; {KK1L: 6.65}

  //  ModeMemory                        : array[RadioType] of ModeType;
  //  MonoColors                        : ColorRecord;
  //  MouseEnable                       : boolean;
  MultiInfoMessage                      : Str20;
//  MultiStatus                           : array[BandType, ModeType] of MultiMessage;
  MultipleBandsEnabled                  : boolean = True;
  MultipleModesEnabled                  : boolean = True;

  MyCall                                : CallString;
  DEPlusMyCall                          : Str160;
  MyCheck                               : Str10; {KK1L: 6.67 Was Str20}
  MultiplierItemWidth                   : integer = 40; // 4.91.4
  MyContinent                           : ContinentType {= UnknownContinent};
  MyCountry                             : Str20;
  MyZone                                : Str20; //ZoneMultiplierString;
  MyContinentIsSet                      : boolean;
  MyCountryIsSet                        : boolean;
  MyZoneIsSet                           : boolean;

//  MyZoneCustom                          : ZoneMultiplierString;

  //MyCounty                              : Str20 = '';
  MyFDClass                             : Str10;
  MyFOCNumber                           : Str10;
  MyName                                : Str20;
  MyPark                                : Str10;
  MyPostalCode                          : Str20;
  MyPrec                                : Str10; {KK1L: 6.67 Was Str20}
  MySection                             : Str10; {KK1L: 6.67 Was Str20}
  MyState                               : Str20; {KK1L: 6.67 Was Str20}

  NoMultMarineMobile                    : boolean; {KK1L: 6.68 Added for WRTC 2002 as flag to not count /MM or /AM as mults or countries}
  NumberBandMapEntries                  : integer; {KK1L: 6.64 needed a global version of NumberVisibleBMEntries}

  NumberBandQSOsThisMinute              : RateBandArrayType;

  NumberContactsThisMinute              : integer;
  NumberExchangeTemplates               : SHORTINT;
  NumberQSOPointsThisMinute             : integer;

  NextQTCToBeAdded                      : integer;
//  NextQTCToBeSent                  : integer;
  NumberQTCBooksSent                    : integer;
  NumberQTCStations                     : integer;

  NumberReminderRecords                 : Byte;
  NumberTotalScoreMessages              : Byte;

  OkayToPutUpBandMapCall                : boolean = True;
  OnDeckCall                            : CallString;
  OpMode                                : OpModeType;
  OpMode2                               : OpModeType;

  PacketAddLF                           : boolean;
  PacketMessMode                        : boolean;
  PacketReturnCount                     : integer = 2;
  PacketReturnPerMinute                 : integer;
  PacketSpotComment                     : Str20; {KK1L: 6.68 Need to change when added to LOGCFG.DAT read.}
//  PendingQTCArray                  : PendingQTCArrayPtr;
  //  PrefixInfoFileName               : String='';

  QSOPointsDomesticCW                   : integer = -1;
  QSOPointsDomesticPhone                : integer = -1;
  QSOPointsDXCW                         : integer = -1;
  QSOPointsDXPhone                      : integer = -1;

  QSYInactiveRadio                      : boolean;        // Gav     4.37.12
  QTCDataArray                          : QTCDataArrayPtr;
  QTCsEnabled                           : boolean;
  QTCMinutes                            : boolean;

  RadioOnTheMove                        : array[RadioType] of boolean; {KK1L: 6.73 slowly changing over to arrayed radio varibles}
  RadioMovingInBandMode                 : array[RadioType] of boolean; {KK1L: 6.73}

//  RadioOneName                : string[10] = 'Rig 1';
//  RadioTwoName                : string[10] = 'Rig 2';

  Rate                                  : integer;
  RateDisplay                           : RateDisplayType {= QSOs};
  RateMinuteArray                       : array[1..60] of RateRecord;
  //   ReminderPostedCount             : integer;
  Reminders                             : ReminderArrayPointer;

 S2SW                                   : boolean = False;

  SayHiEnable                           : boolean;

  SCPDupeBackground                     : tr4wColors = trCyan;
  SCPDupeColor                          : tr4wColors = trRed;

  ScreenHeight                          : integer;
  SearchAndPounceMode                   : boolean;
  SelectedColors                        : ColorRecord;
  SendAltDSpotsToPacket                 : boolean;
  SCount                                : integer = 0;
  SpecialCommand                        : SpecialCommandType {= NoSpecialCommand};
  SplitFreq                             : LONGINT;
  Spotcnt                               : integer = 0;
//  SpeedMemory                 : array[RadioType] of integer; {KK1L: 6.73}
  SpeedString                           : Str10; {KK1L: 6.73}

  SprintQSYRule                         : boolean;

  StartingFrequencies                   : array[BandType] of LONGINT =
    (
    1800000,
    3500000,
    7000000,
    14000000,
    21000000,
    28000000,

    10000000,
    18000000,
    24000000,
    50000000,
    144000000,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
    );

  //  StoppingFrequencies                   : array[BandType] of LONGINT;
  //  SuperDupeSheet                        : boolean;
  SuperDupeSheetWindowRY                : integer;
  SwapPacketSpotRadios                  : boolean;

  TenMinuteRule                         : TenMinuteRuleType {= NoTenMinuteRule};
  TenMinuteTime                         : TenMinuteTimeRecord = (Band: NoBand; Mode: NoMode);
  TimeSpentByBand                       : array[BandType] of integer;

  tThisHourBandChanges                  : integer;
  tThisHourPreviousBand                 : BandType {= NoBand};
  TotalThisHour                         : integer;
  TotalLastSixty                        : integer;

  TotalScoreMessages                    : array[0..10] of TotalScoreMessageRecord;
  //  TRFree                                : boolean;
  TwoRadioState                         : TwoRadioStates {= TwoRadiosDisabled};
  TuneDupeCheckEnable                   : boolean; {KK1L: 6.73}

  UnknownCountryFileEnable              : boolean;
  UnknownCountryFileName                : ShortString {= 'UNKNOWN.CTY'};
  UserInfoShown                         : UserInfoType {= NoUserInfo};

  //   VGADisplayEnable                : boolean;
  VHFBandsEnabled                       : boolean;
  VisibleDupeSheetChanged               : boolean = True;
  //   VisibleDupesheetEnable          : boolean;
  VisibleDupeSheetRemoved               : boolean;

  WakeUpTimeOut                         : integer;
  WakeUpCount                           : Byte;
  WARCBandsEnabled                      : boolean;
//  WideFreqDisplay                  : boolean; {KK1L: 6.73}

  DisplayedFreq                         : Str10; {wli}

  TourDuration                          : integer;
  //   tUpdateWindow                   : boolean;

procedure ActivateExchangeWindow;

procedure AddBandMapModeCutoffFrequency(Freq: LONGINT);

procedure AddBandMapEntry(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: Byte;
  Source: CallString);

procedure AddBandMapEntry_old(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: Byte;
  Source: CallString);

procedure AddBandMapPlaceHolder; {KK1L: 6.65}

//procedure AddQSOToPendingQTCList(Time: integer; Call: CallString; QSONumber: integer);

function BandMapExpandedString(Call: EightBytes): CallString;

procedure CalculateNumberVisibleBandMapEntries(var NumberVisibleBandMapEntries: integer;
  var CursorEntryNumber: integer;
  StartAtTop: boolean);

procedure ClearAutoSendDisplay;
procedure DecrementQTCCount(Call: CallString; Count: integer);
procedure DeleteBandMapEntry(var Entry: BandMapEntryPointer);
procedure DisplayAutoSendCharacterCount;

procedure DisplayBandMap_proc;
procedure DisplayBandMap;
procedure DisplayLocalTime(Country: Word);
//procedure DisplayQuickMemoryMode;

procedure DisplayBandMode(Band: BandType; Mode: ModeType; UpdateRadio: boolean);
procedure DisplayBeamHeading(Call: CallString; Grid: GridString);
procedure DispalyGrid(Grid: GridString);

procedure DisplayCodeSpeed {(WPM: integer;
SendingEnabled: boolean;
DVPEnabled: boolean;
Mode: ModeType)};

procedure DisplayContestTitle;
procedure DisplayCountryName(Call: CallString);
procedure DisplayQSOsWithThisStation(QSOs: integer);
//procedure DisplayCT1BOHData;
//procedure DisplayEditableLog(EditableLog: LogEntryArray);
//procedure DisplayFreeMemory;
//procedure DisplayFrequency(Freq: LONGINT; Radio: RadioType); {KK1L: 6.73 Added Radio}
procedure DisplayFrequency(RSR: RadioStatusRecord {Freq: LONGINT}; Radio: RadioType);
procedure DisplayInsertMode;
procedure DisplayMultiMessages;
procedure DisplayNameSent(Name: Str80);
procedure DisplayNamePercentage({TotalNamesSent: integer; QSONumber: integer});
procedure DisplayNextQSONumber {(QSONumber: integer)};
//procedure DisplayPossibleCalls(Call: CallString);
//procedure DisplayPrefixInfo(Prefix: Str20);
procedure DisplayQTCNumber(QTCNumber: integer);
procedure DisplayRadio(Radio: RadioType);
procedure DisplayRate(Rate: Cardinal);
procedure DisplayQSOsByOpMode;
procedure DisplayHour;

//procedure DisplayRemainingMults({RemainingMults: RemainingMultListPointer;}RemMultDisplay: RemainingMultiplierType);
//procedure DisplayAdditionalRemainingMults;
procedure DisplayTotalScore {(Score: LONGINT)};
procedure DisplayUserInfo(Call: CallString);

{KK1L: 6.64 Created procedure because I needed to get this info more than once}
procedure GetBandMapDisplayInfo(var MaxEntriesPerPage: integer; var NumberBandMapRows: integer);
procedure GetBandMapBandModeFromFrequency(Frequency: LONGINT;
  var Band: BandType;
  var Mode: ModeType);

{KK1L: 6.64 created a function for this step used in EditBandMap}
function GetRecordForBandMapCursor(var Entry: BandMapEntryPointer;
  CursorEntryNumber: integer): boolean;

procedure IncrementTime(Count: integer);
procedure tCalculateRate();
procedure LoadBandMap;
procedure LookForOnDeckCall(var ExchangeString: ShortString {Str80});
procedure NextBandMapEntry ;
procedure BMFirst;
function NextNonDupeEntryInBandMap(Band: BandType; Mode: ModeType): boolean;
function NextMultiplierEntryInBandMap(Band: BandType; Mode: ModeType): boolean; {KK1L: 6.68}
{KK1L: 6.64 created to allow traversal of entrire displayed bandmap}
function NextNonDupeEntryInDisplayedBandMap(Band: BandType; Mode: ModeType): boolean;
function NextMultiplierEntryInDisplayedBandMap(Band: BandType; Mode: ModeType): boolean; {KK1L: 6.68}

procedure OutputQSOorMultStatusString(OutputString_Milt: ShortString {Str160});

//function PopNextQTCToBeSent(var FullString: string; tQTCNR: integer): Str80;

//procedure PutUpCQMenu;
//procedure PutUpExchangeWindow;

procedure SetTextInQuickCommandWindow(Text: PChar);
procedure ClearQuickDisplayText;
procedure QuickDisplay(Prompt: PChar);

procedure QuickDisplayError(Prompt: PChar);

function QuickEditInteger(Prompt: PChar {str80}; MaxInputLength: integer): LONGINT;
function QuickEditFreq(Prompt: PChar {str80}; MaxInputLength: integer): LONGINT;
function QuickEditReal(Prompt: PChar {str80}; MaxInputLength: integer): REAL;
function QuickEditResponse(Prompt: PChar {str80}; MaxInputLength: Byte): ShortString;

//procedure RemoveAndRestorePreviousWindow;
//procedure RemoveWindow(WindowName: WindowType);
//procedure ResetBandMapTimes; {KK1L: 6.70}
//procedure ResetBandMapDupes;
procedure ResetSavedWindowListAndPutUpCallWindow;
//procedure RestorePreviousWindow;

//procedure SaveActiveWindow;
procedure SaveBandMap;
procedure SetColor(Color: integer);
//procedure SaveAndSetActiveWindow(WindowName: WindowType);
//procedure SaveSetAndClearActiveWindow(WindowName: WindowType);
procedure SetUpBandMapEntry(BandMapData: BandMapEntryPointer; Radio: RadioType); {KK1L: 6.73 Added Radio}
//procedure SetWindow(WindowName: WindowType);
//procedure SetActiveWindow(WindowName: WindowType); { Does not clear window }
{wli}

//function TotalNumberQTCsProcessed: integer;
var
  TotalNumberQTCsProcessed              : integer;
//function TotalPendingQTCs: integer;

procedure UpdateBlinkingBandMapCall;

procedure UpdateK1EAStationInfo(Field: K1EAStationInfoFieldType;
  StationIDChar: Char;
  MessageString: ShortString {Str20});

procedure UpdateTenMinuteDate(Band: BandType; Mode: ModeType);

procedure UpdateTimeAndRateDisplays(ShowTime: boolean; DoRadios: boolean);
procedure WindInit;

procedure DispalayLogGridLines;
procedure DispalayB4(nCmdShow: integer);
procedure DispalayDupe;
procedure DispalayNewMult(nCmndShow: integer);
procedure tDisplayAutoCQStatus;

procedure old_UpadateRadioStatus(RadioPointer: RadioPtr);
procedure UpadateRadioStatus(rig: RadioPtr);
procedure tDispalyPaddleAndFootSwitchStatus;
procedure tDisplayCQTotal;
procedure tDispalyOnAirTime;
procedure tDispalyMyComputerID;
procedure tDispalyTimeFromLastQSO;
function CQLabel(Callsign: CallString): boolean;
procedure tSetStartStopBandMode;
procedure DisplayCountryInformation(FileName: Str80; Call: CallString);
procedure FlashQickDisplay;
procedure ShowTourDuration;
procedure DisplayAutoQSLInterval;
procedure SetListViewColor(Window: TMainWindowElement);
procedure UpadateMainWindow;
procedure UpadateAutoSend;
//function GetInitialExchangeFromString(CMD: pShortString): InitialExchangeType;
//procedure write_in_BM(s1, s2: string);

implementation

uses
  //  OZCHR,
//  uStack,
  uNet,
  uMP3Recorder,
//  uRemMults_DX,
//  uRemMults_DOM,
//  uRemMults_Zone,
  uStations,
  uSpots,
  uRemMults,
 // uReminder,
  uFunctionKeys,
  LogPack,
  uTelnet,
  uBandmap,
  uOption,
  MainUnit,
  LogEdit,
  uTotal,
  LogCW,
  LogStuff,
  PostUnit,
  LogDupe;

//const
{  TotalScoreWindowLX = 1;
  TotalScoreWindowLY = 1;
  TotalScoreWindowRX = 14;
  TotalScoreWindowRY = 1;

  ContestTitleWindowLX = 15;
  ContestTitleWindowLY = 1;
  ContestTitleWindowRX = 65;
  ContestTitleWindowRY = 1;

  FreeMemoryWindowLX = 66;
  FreeMemoryWindowLY = 1;
  FreeMemoryWindowRX = 80;
  FreeMemoryWindowRY = 1;

  TotalWindowLX     = 1;
  TotalWindowLY     = 2;
  TotalWindowRX     = 53;
  TotalWindowRY     = 7;

  DupeInfoWindowLX  = 55;
  DupeInfoWindowLY  = 2;
  DupeInfoWindowRX  = 80;
  DupeInfoWindowRY  = 3;

  NormalDupeSheetWindowLX = 1;
  NormalDupeSheetWindowLY = 5;
  NormalDupeSheetWindowRX = 80;
  NormalDupeSheetWindowRY = 17;

  SuperDupeSheetWindowLX = 1;
  SuperDupeSheetWindowLY = 26;
  SuperDupeSheetWindowRX = 80;

  BeamHeadingWindowLX = 50;
  BeamHeadingWindowLY = 13;
  BeamHeadingWindowRX = 80;
  BeamHeadingWindowRY = 13;

  BandMapWindowLX   = 1;
  BandMapWindowLY   = 26;
  BandMapWindowRX   = 80;

  BandModeWindowLX  = 1;
  BandModeWindowLY  = 20;
  BandModeWindowRX  = 7;
  BandModeWindowRY  = 20;

  BandModeWindowUpLX = 1;
  BandModeWindowUpLY = 19;
  BandModeWindowUpRX = 7;
  BandModeWindowUpRY = 19;

  DateWindowLX      = 8;
  DateWindowLY      = 20;
  DateWindowRX      = 17;
  DateWindowRY      = 20;

  DateWindowUpLX    = 8;
  DateWindowUpLY    = 19;
  DateWindowUpRX    = 17;
  DateWindowUpRY    = 19;

  ClockWindowLX     = 18;
  ClockWindowLY     = 20;
  ClockWindowRX     = 23;
  ClockWindowRY     = 20;

  ClockWindowUpLX   = 18;
  ClockWindowUpLY   = 19;
  ClockWindowUpRX   = 23;
  ClockWindowUpRY   = 19;

  QSONumberWindowLX = 24;
  QSONumberWindowLY = 20;
  QSONumberWindowRX = 29;
  QSONumberWindowRY = 20;

  QSONumberWindowUpLX = 24;
  QSONumberWindowUpLY = 19;
  QSONumberWindowUpRX = 29;
  QSONumberWindowUpRY = 19;

  CallWindowLX      = 30;
  CallWindowLY      = 20;
  CallWindowRX      = 46;
  CallWindowRY      = 20;

  CallWindowUpLX    = 30;
  CallWindowUpLY    = 19;
  CallWindowUpRX    = 41;
  CallWindowUpRY    = 19;

  NameSentWindowLX  = 48;
  NameSentWindowLY  = 20;
  NameSentWindowRX  = 58;
  NameSentWindowRY  = 20;

  InsertWindowLX    = 60;
  InsertWindowLY    = 20;
  InsertWindowRX    = 67;
  InsertWindowRY    = 20;

  NamePercentageWindowLX = 69;
  NamePercentageWindowLY = 20;
  NamePercentageWindowRX = 79;
  NamePercentageWindowRY = 20;

  FrequencyOneWindowLX = 2;
  FrequencyOneWindowLY = 21;
  FrequencyOneWindowRX = 14;
  FrequencyOneWindowRY = 21;
  FrequencyTwoWindowLY = 21;
  FrequencyTwoWindowRY = 21;

 {IF WideFreqDisplay THEN                   }
 {    BEGIN                                 }
 {    FrequencyTwoWindowLX = 67; {KK1L: 6.73}
 {    FrequencyTwoWindowRX = 79; {KK1L: 6.73}
 {    END                                   }
 {ELSE                                      }
 {    BEGIN                                 }
//  FrequencyTwoWindowLX = 15; {KK1L: 6.73}
//  FrequencyTwoWindowRX = 27; {KK1L: 6.73}
 {    END;                                  }

//  AltCallWindowLX   = 58; {KK1L: 6.73}
//  AltCallWindowLY   = 21; {KK1L: 6.73}
//  AltCallWindowRX   = 80; {KK1L: 6.73}
//  AltCallWindowRY   = 21; {KK1L: 6.73}
 {
  QTCNumberWindowLX = 31;
  QTCNumberWindowLY = 21;
  QTCNumberWindowRX = 45;
  QTCNumberWindowRY = 21;

  UserInfoWindowLX  = 23;
  UserInfoWindowLY  = 21;
  UserInfoWindowRX  = 57;
  UserInfoWindowRY  = 21;

  CountryNameWindowLX = 57;
  CountryNameWindowLY = 20;
  CountryNameWindowRX = 80;
  CountryNameWindowRY = 20;

  RadioWindowLX     = 2;
  RadioWindowLY     = 22;
  RadioWindowRX     = 11;
  RadioWindowRY     = 22;

  CodeSpeedWindowLX = 13;
  CodeSpeedWindowLY = 22;
  CodeSpeedWindowRX = 21;
  CodeSpeedWindowRY = 22;

  ExchangeWindowLX  = 25;
  ExchangeWindowLY  = 22;
  ExchangeWindowRX  = 51;
  ExchangeWindowRY  = 22;

  AlarmWindowLX     = 53;
  AlarmWindowLY     = 22;
  AlarmWindowRX     = 67;
  AlarmWindowRY     = 22;

  RateWindowLX      = 69;
  RateWindowLY      = 22;
  RateWindowRX      = 79;
  RateWindowRY      = 22;

  RTTYWindowLX      = 1;
  RTTYWindowLY      = 26;
  RTTYWindowRX      = 80;

  RTTYInverseWindowLX = 1;
  RTTYInverseWindowRX = 80;

  QuickCommandWindowLX = 4;
  QuickCommandWindowLY = 23;
  QuickCommandWindowRX = 77;
  QuickCommandWindowRY = 23;

  QuickCommand2WindowLX = 4;
  QuickCommand2WindowLY = 24;
  QuickCommand2WindowRX = 77;
  QuickCommand2WindowRY = 24;

  PossibleCallWindowLX = 2;
  PossibleCallWindowLY = 24;
  PossibleCallWindowRX = 78;
  PossibleCallWindowRY = 24;

  FunctionKeyWindowLX = 1;
  FunctionKeyWindowLY = 25;
  FunctionKeyWindowRX = 80;
  FunctionKeyWindowRY = 25;
}
type
  SavedWindow = record
    CursorX: integer;
    CursorY: integer;
    UpperLeftCorner: Word;
    LowerRightCorner: Word;
    Color: integer;
    Background: integer;
    SavedActiveWindow: WindowType;
  end;

var
  //Band                                  : BandType;
 // Continent                             : ContinentType;

  //DupeSheetWindowX                      : integer;
  //DupeSheetWindowY                      : integer;

  NumberMinutesProgramRunning           : integer;

//  Radio1InquireCount               : integer;
//  Radio2InquireCount               : integer;

//  Radio1PollCount                  : integer;
//  Radio2PollCount                  : integer;

  //SavedWindowList                       : array[0..12] of SavedWindow;

  StartBand, StopBand                   : BandType;
  StartMode, StopMode                   : ModeType;

procedure LookForOnDeckCall(var ExchangeString: ShortString {Str80});

var
  TempString, WordString                : Str40;

begin
  OnDeckCall := '';

  if pos(' /', ExchangeString) > 0 then
  begin
    TempString := '';

    while length(ExchangeString) > 0 do
    begin
      WordString := RemoveFirstString(ExchangeString);

      if Copy(WordString, 1, 1) <> '/' then
        TempString := TempString + WordString + ' '
      else
      begin
        OnDeckCall := WordString;
        Delete(OnDeckCall, 1, 1);
      end;
    end;

    ExchangeString := TempString;
    Exit;
  end;

  { Added in 6.61 }

  if Copy(ExchangeString, 1, 1) = '/' then
  begin
    OnDeckCall := RemoveFirstString(ExchangeString);
    Delete(OnDeckCall, 1, 1);
  end;
end;

function BandMapExpandedString(Call: EightBytes): CallString;

var
  TempString                            : CallString;

begin
  TempString := BigExpandedString(Call);

  while pos(' ', TempString) > 0 do
    TempString[pos(' ', TempString)] := '/';

  BandMapExpandedString := TempString;
end;

procedure DisplayFrequency(RSR: RadioStatusRecord {Freq: LONGINT}; Radio: RadioType); {KK1L: 6.73 Added Radio switch}

var
  TempFreq                              : REAL;
  TempString                            : string[40];
  ch                                    : Char;

begin
  ch := '.';
//  if (RSR.Freq = LastDisplayedFreq[RadioOne]) and (Radio = RadioOne) then    Exit; {KK1L: 6.73 Added Radio}
//  if (RSR.Freq = LastDisplayedFreq[RadioTwo]) and (Radio = RadioTwo) then    Exit; {KK1L: 6.73}

//  LastDisplayedFreq[Radio] := RSR.Freq;

  case Radio of {KK1L: 6.73}
    RadioOne:
      begin

        {            IF ActiveRadio = RadioOne THEN
                        SetColor (SelectedColors.FrequencyOneWindowHighlight)
                    ELSE
                        SetColor (SelectedColors.FrequencyOneWindowColor);
        }
      end;

    RadioTwo:
      begin

        {            IF ActiveRadio = RadioTwo THEN
                        SetColor (SelectedColors.FrequencyTwoWindowHighlight)
                    ELSE
                        SetColor (SelectedColors.FrequencyTwoWindowColor);
        }
      end;
  end;

  TempString := IntToStr(RSR.VFO[VFOA].Frequency);
  Insert(ch, TempString, length(TempString) - 2);
  //   RIF.R1VFOA . Caption := TempString + ' kHz';

  TempString := IntToStr(RSR.VFO[VFOB].Frequency);
  Insert(ch, TempString, length(TempString) - 2);
  //   RIF.R1VFOB . Caption := TempString + ' kHz';

  if RSR.Freq <> 0 then
  begin
    TempFreq := RSR.Freq div 100;
    RSR.Freq := Trunc(TempFreq);
    TempString := '.';
    DisplayedFreq := IntToStr(RSR.Freq);
    Insert(TempString, DisplayedFreq, length(DisplayedFreq) - 0);
      //   t.label10 . Caption := DisplayedFreq; // + ' kHz';
//    length(IntToStr(RSR.Freq));
    FrequencyDisplayed := True;
  end
  else
    if FrequencyDisplayed then
      FrequencyDisplayed := False;

end;

procedure DispalyGrid(Grid: GridString);
begin
  Grid[5] := #0;
  SetMainWindowText(mweLocator, @Grid[1]);
//windows.CopyMemory(@TempBuffer1,
{  asm
  mov eax,Grid
  mov dword ptr TempBuffer1,eax
  end;
  TempBuffer1[4] := #0;
  Windows.SetWindowText(LocatorWindowHandle, @TempBuffer1);
}
end;

procedure DisplayBeamHeading(Call: CallString; Grid: GridString);

var
  Heading, Distance{, Country}            : integer;
  HeadingString, DistanceString         : Str20;
  HisGrid                               : GridString;
  CountryID                             : DXMultiplierString; //string[CallstringLength] {20};
  Lat, Lon                              : REAL;
  TempString                            : Str40;

begin
  if MyGrid <> '' then
  begin

    if Grid <> '' then HisGrid := Grid
    else
      HisGrid := ctyGetGrid(Call, CountryID);

    if HisGrid = '' then Exit;

    if tBeamHeadingPrevState = HisGrid then Exit;
    tBeamHeadingPrevState := HisGrid;

//    tSetWindowText(LocatorWindowHandle, 'string(HisGrid)');
    DispalyGrid(HisGrid);
    if Call = MyCall then
      GetLatLon(MyGrid, Lat, Lon)
    else
      GetLatLon(ctyGetGrid(Call, CountryID), Lat, Lon);

      //       SaveSetAndClearActiveWindow (BeamHeadingWindow);

    if HisGrid <> '' then
    begin
      Heading := round(GetBeamHeading(MyGrid, HisGrid));

      LastHeadingShown := Heading;

      Str(Heading, HeadingString);

      Windows.ZeroMemory(@TempString, SizeOf(TempString));
      TempString := CountryID + '   ' + HeadingString + '';

      if DistanceMode <> NoDistanceDisplay then
      begin
        Distance := GetDistanceBetweenGrids(MyGrid, HisGrid);

        if DistanceMode = DistanceMiles then
        begin
          Distance := round(Distance / 1.609344);
          Str(Distance, DistanceString);
          DistanceString := DistanceString + 'm';
        end
        else
        begin
          Str(Distance, DistanceString);
          DistanceString := DistanceString + 'km';
        end;

        TempString := TempString + '   ' + DistanceString;
      end;

      TempString := TempString + '   ' + GetSunriseSunsetString(Lat, Lon);
    end
    else
      TempString := TC_UNKNOWNCOUNTRY;

      //        WHILE Length (TempString) < (BeamHeadingWindowRX - BeamHeadingWindowLX) DO
      //            TempString := ' ' + TempString;

    SetMainWindowText(mweBeamHeading, @TempString[1]);
      //        Showmessage (TempString);
      //        RestorePreviousWindow;
  end;
end;

procedure SetColor(Color: integer);

begin
  //    ActiveColor := Color;
  //    TextColor (Color);
end;



function EffectiveBandFreq(Band: BandType; Mode: ModeType): longint;
begin
  // FreqMemory holds the last-used frequency per band/mode and is 0 until a
  // band has been visited. Fall back to the built-in DefaultFreqMemory so a
  // band change to an un-visited band tunes to that band's default instead of
  // 0 Hz (which the radio rejects). Microwave rows with no default stay 0 and
  // are caught by the freq<=0 guard in SetRadioFreq.
  Result := FreqMemory[Band, Mode];
  if Result = 0 then
    Result := DefaultFreqMemory[Band, Mode];
end;

procedure DisplayBandMode(Band: BandType; Mode: ModeType; UpdateRadio: boolean);
begin

  if (Band = LastDisplayedBand) and
    (Mode = LastDisplayedMode)
    //    and (FMMode = LastDisplayedFMMode)
  then
    Exit;

  LastDisplayedBand := Band;
  LastDisplayedMode := Mode;  
  //  LastDisplayedFMMode := FMMode;

  UpdateTotals2;

  Format(wsprintfBuffer, TWO_STRINGS, BandStringsArray[Band], ModeStringArray[Mode]);

  SetMainWindowText(mweBandMode, wsprintfBuffer);

  if MultByBand then MultBand := ActiveBand else MultBand := AllBands;
  if MultByMode then MultMode := ActiveMode else MultMode := Both;

         { Update the band output port for this radio }

  ActiveRadioPtr.BandMemory {BandMemory[ActiveRadio]} := Band; {UA4WLI: 2.26}
  ActiveRadioPtr.ModeMemory {ModeMemory[ActiveRadio]} := Mode; {UA4WLI: 2.26}

  wkSetKeyerOutput(ActiveRadioPtr);

  if ActiveRadio = RadioOne then
  begin
    Radio1.UpdateBandOutputInfo(Band, Mode);
    if UpdateRadio then Radio1.SetRadioFreq(EffectiveBandFreq(Band, Mode), ActiveMode, 'A');
  end
  else
  begin
    Radio2.UpdateBandOutputInfo(Band, Mode);
    if UpdateRadio then Radio2.SetRadioFreq(EffectiveBandFreq(Band, Mode), ActiveMode, 'A');
  end;
  UpdateAllStationsList;
  SendStationStatus(sstBandModeFreq);
end;

procedure DisplayContestTitle;
begin
  Format(wsprintfBuffer, TR4W_CURRENTVERSION + ' - %s'{$IF tDebugMode} + ' - DEBUG MODE'{$IFEND}, @ContestTitle[1]);
  Windows.SetWindowText(tr4whandle, wsprintfBuffer);
end;

procedure DisplayCodeSpeed {(WPM: integer; SendingEnabled: boolean; DVPEnabled: boolean; Mode: ModeType)};
var
  tPChar                                : PChar;
begin
  DisplayedCodeSpeed := CodeSpeed;
  if ActiveMode = CW then
  begin
    // CW-state desync fix: show the ACTUAL transmit gate (CWEnabled), not
    // CWEnable OR CWEnabled.  The OR let a stale CWEnable mask a disabled gate,
    // so the display read "WPM" while Enter sent nothing.  CWEnable and
    // CWEnabled are now kept in step at config load (see ReadInConfigFile), so
    // this matches CWEnable too -- but keying off the gate the sender checks
    // means the UI can never claim CW is on when it will not transmit.
    if CWEnabled then
       begin
       tPChar := '%u WPM';
       end
    else
       begin
       tPChar := '%u NO CW';
       end;
    Format(wsprintfBuffer, tPChar, CodeSpeed);
    SetMainWindowText(mweCodeSpeed, wsprintfBuffer);
    ActiveRadioPtr.SpeedMemory := CodeSpeed;
  end;

  if ActiveMode in [Phone, FM] then
  begin
    if DVKEnable then
    begin
      if DVPOn then
        tPChar := 'DVK ON'
      else
        tPChar := 'DVK OFF';
    end
    else
      tPChar := 'DVK Dis.';
    SetMainWindowText(mweCodeSpeed, tPChar);
  end;

  {
    DisplayedCodeSpeed := WPM;
    if SendingEnabled then
      TempString := IntToStr(WPM) + ' WPM'
    else
      TempString := IntToStr(WPM) + ' NO CW';
    if Mode = CW then

    begin
      Windows.EnableWindow(CodeSpeedWindowHandle, True);
      SpeedMemory[ActiveRadio] := WPM;
    end

    else

    begin

      if DVPEnable then
      begin
        if DVPEnabled then
          TempString := ' DVP ON'
        else
          TempString := ' DVP OFF';
      end;

  }
  {    if DVPEnable then
      begin
        if DVPEnabled then
          ShowMessage(' DVP ON')
        else
          ShowMessage(' DVP OFF');
      end
      else
        if (ActiveDVKPort <> NoPort) then
        begin
          if DVPEnabled then
            ShowMessage(' DVK ON')
          else
            ShowMessage(' DVK OFF');
        end
        else
          }
  //    Windows.EnableWindow(CodeSpeedWindowHandle, False);
  //    Windows.ShowWindow(CodeSpeedWindowHandle, SW_HIDE);

    //        RestorePreviousWindow;
  //      end;

  {IF ActiveRadio = RadioOne THEN  }
  {    RadioOneSpeed := WPM        }
  {ELSE                            }
  {    RadioTwoSpeed := WPM;       }

  //  end;

  //  tSetWindowText(CodeSpeedWindowHandle, TempString);
  //end;
  //procedure DisplayFreeMemory;

  //begin
   {    SaveSetAndClearActiveWindow (FreeMemoryWindow);
       Write ('Mem =', MemAvail:7);
       RestorePreviousWindow;
  }
end;

procedure DisplayMultiMessages;
{
var
   Band                            : BandType;
   Mode                            : ModeType;
   TempString                      : Str40;
   Index                           : integer;
   PassFreqStr, RunFreqStr         : Str20;
}
begin
  {    SaveSetAndClearActiveWindow (EditableLogWindow);

      IF K1EANetworkEnable THEN
          BEGIN
          FOR Band := Band160 TO Band10 DO
              WITH K1EAMultiInfo [Band] DO
                  BEGIN
                  Str (PassFreq, PassFreqStr);
                  Str (RunFreq, RunFreqStr);

                  Insert ('.', PassFreqStr, Length (PassFreqStr) - 2);
                  Delete (PassFreqStr, Length (PassFreqStr) - 1, 2);

                  Insert ('.', RunFreqStr, Length (RunFreqStr) - 2);
                  Delete (RunFreqStr, Length (RunFreqStr) - 1, 2);

                  Write ('Run: ', RunFreqStr:7, '  Pass: ', PassFreqStr:7);

                  IF WhereX > 40 THEN
                      BEGIN
                      WriteLn;
                      ClrEol;
                      END
                  ELSE
                      GoToXY (41, WhereY);
                  END;
          END

      ELSE  { TR network }
  {        FOR Band := Band160 TO BandLight DO
              FOR Mode := CW TO Phone DO
                  IF MultiStatus [Band, Mode] <> nil THEN
                      BEGIN
                      TempString := BandString [Band] + ModeString [Mode] + ' ' + MultiStatus [Band, Mode]^;

                      Write (TempString);

                      IF WhereX > 40 THEN
                          BEGIN
                          WriteLn;
                          ClrEol;
                          END
                      ELSE
                          GoToXY (41, WhereY);
                      END;

      RestorePreviousWindow;
 }
end;

procedure DisplayNameSent(Name: Str80);

begin

  SetMainWindowText(mweName, @Name[1]);
  {    IF Name = '' THEN
          BEGIN
          SaveSetAndClearActiveWindow (NameSentWindow);
          RemoveAndRestorePreviousWindow;
          END
      ELSE
          BEGIN
          SaveSetAndClearActiveWindow (NameSentWindow);
          Write (' ', Name);
          RestorePreviousWindow;
          END;
 }
end;

procedure DisplayInsertMode;
const
  InsertModeStringArray                 : array[boolean] of PChar = (TC_OVERRIDE, TC_INSERT);
begin
  SetMainWindowText(mweInsert, InsertModeStringArray[InsertMode]);
end;

procedure DisplayNamePercentage({TotalNamesSent: integer; QSONumber: integer});

//var
  //Percentage                            : REAL;
  //TNS                                   : integer;
begin
{
  if (TotalContacts > 0) and SayHiEnable then
  begin
    TNS := TotalNamesSent ;
    Percentage := TNS / TotalContacts;
    Percentage := Percentage * 100;
      //    SaveSetAndClearActiveWindow(NamePercentageWindow);
      //    SetTR4WWindowText(NameSentWindowHandle, IntToStr(Trunc(Percentage))+' %');
      //    Write(' ', Percentage: 3: 1, '%');
      //    RestorePreviousWindow;
  end;
}
end;

procedure DisplayNextQSONumber;
const
  QSONumberStringArray                  : array[boolean] of PChar = ('%d', '*%d');   
begin
  // Issue #954: show the next serial we will actually send (high-water mark of
  // numbers sent + 1), NOT a QSO count.  Count-based display reverted the number
  // whenever a QSO stopped counting (X-QSO, mid-log delete).  NextSerialToSend
  // also returns ServerSerialNumber in networked mode, matching the old value.
  Format(wsprintfBuffer, QSONumberStringArray[AutoQSONumberDecrement], NextSerialToSend);
  if ServerSerialNumber <> 0 then
    if PreviousSerialNumberType = sntReserved then
      Windows.lstrcat(wsprintfBuffer, 'L');
  SetMainWindowText(mweQSONumber, wsprintfBuffer);
end;

procedure SortPossibleCalls(var PossibleCalls: PossibleCallRecord);

var
  Change                                : boolean;
  Range, CallAddress                    : integer;
  temp                                  : PossibleCallEntry;

begin
  Range := PossibleCalls.NumberPossibleCalls - 1;

  repeat
    Change := False;
    for CallAddress := 1 to Range do
      with PossibleCalls do
        if List[CallAddress].Call < List[CallAddress + 1].Call then
        begin
          temp := List[CallAddress];
          List[CallAddress] := List[CallAddress + 1];
          List[CallAddress + 1] := temp;
          Change := True;
        end;

    dec(Range);
  until (not Change) or (Range < 1);
end;

procedure DisplayQTCNumber(QTCNumber: integer);
begin
  Format(wsprintfBuffer, TC_HAVEQTCS, QTCNumber);
  SetMainWindowText(mweUserInfo, wsprintfBuffer);
end;

procedure DisplayCountryName(Call: CallString);
var
  Country                               : Word;
begin

  Country := ctyGetCountry(Call);
  DisplayLocalTime(Country);
  if tCountryNamePrevState = Country then Exit;
  tCountryNamePrevState := Country;
  SetMainWindowText(mweCountryName, ctyGetCountryNamePchar(Country));
end;

procedure DisplayQSOsWithThisStation(QSOs: integer);
var
  p                                     : PChar;
begin
//  if tQSOsWithThisStationPrevState = QSOs then Exit;
  tQSOsWithThisStationPrevState := QSOs;

  if QSOs <> 0 then
    p := inttopchar(QSOs)
  else p := nil;
  SetMainWindowText(mweQSOsWithThisStation, p);
end;

procedure DisplayRadio(Radio: RadioType);
begin
  SetMainWindowText(mweRadioOne, @Radio1.RadioName[1]);
  SetMainWindowText(mweRadioTwo, @Radio2.RadioName[1]);
end;

procedure DisplayQSOsByOpMode;
begin

  Format(wsprintfBuffer, ' CQ: %u', tRestartInfo.riQSOByOpMode[CQOpMode]);
  SetMainWindowText(mweCQQSOCounter, wsprintfBuffer);

  Format(wsprintfBuffer, ' SP: %u', tRestartInfo.riQSOByOpMode[SearchAndPounceOpMode]);
  SetMainWindowText(mweSPQSOCounter, wsprintfBuffer);
end;

procedure DisplayHour;
var
  TempInteger                           : integer;
begin
  if AlarmSet then Exit;
  case HourDisplay of
    ThisHour:
      begin
        TempInteger := TotalThisHour;
        Format(wsprintfBuffer, TC_THISHR, TotalThisHour);
      end;
    LastSixtyMins:
      begin
        TempInteger := TotalLastSixty;
        Format(wsprintfBuffer, TC_LAST60, TotalLastSixty);
      end;
    BandChanges, BandChangesThisComputer:
      begin
        TempInteger := tThisHourBandChanges;
        Format(wsprintfBuffer, TC_BAND_CHANGES, tThisHourBandChanges);
      end;
  end;
  SetMainWindowText(mweHourRate, wsprintfBuffer);
  SendMessage(LastProgressBar, PBM_SETPOS, TempInteger, 0);
end;

procedure DisplayRate(Rate: Cardinal);
//var  TempString                            : string;

begin
  if not AlarmSet then
  begin

      {        REMOVECANDIDATE
          case HourDisplay of
            ThisHour:
              begin
                TempString := 'This hr = ' + IntToStr(TotalThisHour);
                SendMessage(LastProgressBar, PBM_SETPOS, TotalThisHour, 0);
              end;
            LastSixtyMins:
              begin
                TempString := 'Last 60 = ' + IntToStr(TotalLastSixty);
                SendMessage(LastProgressBar, PBM_SETPOS, TotalLastSixty, 0);
              end;
          end;

          tSetWindowText(HourRateWindowHandle, TempString);
      }
      //    tSetWindowText(RateWindowHandle, 'Rate = ' + IntToStr(Rate));

    Format(wsprintfBuffer, TC_RATE, Rate);

    SetMainWindowText(mweRate, wsprintfBuffer);
    SendMessage(RateProgressBar, PBM_SETPOS, Rate, 0);
  end;
end;

procedure DisplayAutoQSLInterval;
begin
  Format(QuickDisplayBuffer, 'AUTO QSL INTERVAL = %u', AutoQSLInterval);
  SetTextInQuickCommandWindow(QuickDisplayBuffer);
end;

procedure DisplayTotalScore {(Score: LONGINT)};

var
  i                                     : integer;
  Score                                 : integer;
begin

  Score := TotalScore;
  // Issue #997: asm-push wsprintf -> Format (the TF.Format idiom already used
  // ~18x in this unit; LOGWIND deliberately avoids SysUtils -- see the BoolToStr
  // note below).  The old code relied on `Score := TotalScore` leaving the value
  // in EAX for the `push eax` -- a fragile Delphi-7 codegen assumption that 64-bit
  // would break.  TC_PTS = '%d Pts'.
  Format(wsprintfBuffer, TC_PTS, Score);
  SetMainWindowText(mweTotalScore, wsprintfBuffer);

  //  tSetWindowText(TotalScoreWindowHandle, IntToStr(Score) + ' Pts');

  if NumberTotalScoreMessages > 0 then
    for i := 0 to NumberTotalScoreMessages - 1 do
      if TotalScoreMessages[i].Score < Score then
        if TotalScoreMessages[i].Score >= 0 then
        begin
            //                  SaveSetAndClearActiveWindow (QuickCommandWindow);

//          if WindowsOSversion = 2 then
//            ShowTrayTips(TotalScoreMessages[i].MessageString)
//          else
         QuickDisplay(@TotalScoreMessages[i].MessageString[1]);
            //          ShowAlarmWakeUpWindow(TotalScoreMessages[message].MessageString);
          DoABeep(Congrats);

          TotalScoreMessages[i].Score := -1;
            //                  RestorePreviousWindow;
        end;

end;

procedure QuickDisplay(Prompt: PChar);
begin
  SetTextInQuickCommandWindow(Prompt);
  logger.Info('[QuickDisplay] (' + Prompt + ')');
  if length(Prompt) > 0 then
     begin
     logger.Debug('Calling tCreateThread from QuickDisplay');
     if tFlashQDThreadID = 0 then
        begin
        tCreateThread(@FlashQickDisplay, tFlashQDThreadID);
        end;
     if ClearQuickDisplayTimer <> 0 then
        begin
        Windows.KillTimer(tr4whandle, ClearQuickDisplayTimer);
        end;
     ClearQuickDisplayTimer := Windows.SetTimer(tr4whandle, QUICK_REPORT_TIMER_HANDLE, 30000, @ClearQuickDisplayText);
     end;
end;

procedure SetTextInQuickCommandWindow(Text: PChar);
begin
  SetMainWindowText(mweQuickCommand, Text);
end;

procedure ClearQuickDisplayText;
begin
  SetTextInQuickCommandWindow(nil);
//  Windows.AnimateWindow(wh[mweQuickCommand], 500, AW_HIDE or AW_HOR_POSITIVE);
  Windows.KillTimer(tr4whandle, ClearQuickDisplayTimer);
  ClearQuickDisplayTimer := 0;
end;

procedure QuickDisplayError(Prompt: PChar);
begin
  QuickDisplay(Prompt);
  DoABeep(Warning);
end;

function QuickEditResponse(Prompt: PChar; MaxInputLength: Byte): ShortString;
var
  h                                     : HWND;
 // Window                                : Byte;
begin
  Format(IQPrompt, TC_ENTER, Prompt);
  IQMaxInputLength := MaxInputLength;
  if settingswindowhandle <> 0 then
    h := settingswindowhandle
  else
  begin
    h := tr4whandle;
  end;
  //DialogBox(hInstance, MAKEINTRESOURCE(41 {Window}), h, @IQDlgProc);
  CreateModalDialog(225, 55, h, @IQDlgProc, 0);
  Result := IQresult;
end;

function QuickEditInteger(Prompt: PChar {str80}; MaxInputLength: integer): LONGINT;

{ This function will put up the prompt specified and get the numeric input
  that is put in.  Only integers will be processed and if the number of
  integers specified is entered, a return will not be waited for.  The
  characters are converted to an integer.  If an escape is hit, the
  response will be -1.                                                }

var
  InputString                           : Str80;
  InputValue                            : LONGINT;
  Result1                               : integer;
begin
  tInputDialogInteger := True;
  QuickEditInteger := -1;
  InputString := QuickEditResponse(Prompt, MaxInputLength);

  if InputString <> '' then
  begin
    Val(InputString, InputValue, Result1);
    if Result1 = 0 then QuickEditInteger := InputValue;
  end;
end;

function QuickEditFreq(Prompt: PChar {str80}; MaxInputLength: integer): LONGINT;

{ This function will put up the prompt specified and get the numeric input
  that is put in.  Only integers will be processed and if the number of
  integers specified is entered, a return will not be waited for.  The
  characters are converted to an integer.  If an escape is hit, the
  response will be -1.                                                }

{KK1L: 6.73 Result will be negative if CTRL-Enter was used to enter the frequency}
{           and two radios are active. This is used to set the inactive radio.}

var
  InputString                           : Str80;
  KHzString, HertzString                : Str20;
  InputValue                            : LONGINT;
  Result1                               : integer;
//  Key                              : Char;
  CTRLStr{, TempStr}                      : Str80; {KK1L: 6.73}

begin
  QuickEditFreq := -1;

  {KK1L: 6.73 Changed to return a 'CTRL' at the end if CTRL-Enter was used and two radios are active.}

  InputString := QuickEditResponse(Prompt, MaxInputLength);
  if {(InputString = EscapeKey) or }(InputString = '') then
    Exit;

  CTRLStr := InputString; {KK1L: 6.73}
  Delete(CTRLStr, 1, (length(CTRLStr) - 4));

  if CTRLStr = 'CTRL' then
    Delete(InputString, (length(InputString) - 3), 4); {KK1L: 6.73}

  if StringHas(InputString, '.') then
  begin
    KHzString := PrecedingString(InputString, '.');
    HertzString := PostcedingString(InputString, '.');

    while length(HertzString) < 3 do
      HertzString := HertzString + '0';

    Val(KHzString + HertzString, InputValue, Result1);
  end
  else
  begin
    InputString := InputString + '000';
    Val(InputString, InputValue, Result1);
  end;

  if (CTRLStr = 'CTRL') and (Result1 = 0) then
    InputValue := InputValue * (-1) {KK1L: 6.73}
  else
    if Result1 <> 0 then
      Exit;

  { This used to be all over LOGSUBS2, I moved it here }

  if (InputValue > 1000) and (InputValue < 1000000) then
    case ActiveBand of
      Band160: InputValue := InputValue + 1000000;
      Band80: InputValue := InputValue + 3000000;
      Band40: InputValue := InputValue + 7000000;
      Band20: InputValue := InputValue + 14000000;
      Band15: InputValue := InputValue + 21000000;
      Band10: InputValue := InputValue + 28000000;
    end;

  QuickEditFreq := InputValue;
end;

function QuickEditReal(Prompt: PChar {str80}; MaxInputLength: integer): REAL;

{ This function will put up the prompt specified and get the numeric input
  that is put in.  Only integers will be processed and if the number of
  integers specified is entered, a return will not be waited for.  The
  characters are converted to an integer.  If an escape is hit, the
  response will be -1.                                                }

var
  InputString                           : Str80;
  Result1                               : integer;
  InputValue                            : REAL;
  //  Key                                   : Char;

begin
  QuickEditReal := -1;

  InputString := QuickEditResponse(Prompt, MaxInputLength);
  //wli  if InputString = EscapeKey then    Exit;

  if InputString <> '' then
  begin
    Val(InputString, InputValue, Result1);

    if Result1 = 0 then
      QuickEditReal := InputValue;
  end;
end;

procedure ResetSavedWindowListAndPutUpCallWindow;

begin
  {    ExchangeWindowCursorPosition := 0;
      NumberSavedWindows := 0;
      SetActiveWindow (CallWindow);
      ClrScr;
 }
end;

procedure PutUpExchangeWindow;

begin
  //  SaveSetAndClearActiveWindow(ExchangeWindow);
  //  RestorePreviousWindow;
end;

procedure ActivateExchangeWindow;

{ This procedure will make the exchange window active with the cursor
  at position it was at before.                                    }

begin
  {    SaveAndSetActiveWindow (ExchangeWindow);
      GoToXY (ExchangeWindowCursorPosition, WhereY)
 }
end;
{  REMOVECANDIDATE
procedure DisplayRemainingMults(RemMultDisplay: RemainingMultiplierType);
label
  AddMult, AddMultDX, AddMultDOM, AddMultZone, 1;
var
  NumberRemaining, RemainingMult        : integer;
begin
  CleanSweep := RemainingMultDisplayMode = Erase;

  case RemMultDisplay of
    rmDomestic: NumberRemaining := DomQTHTable.NumberRemainingMults;
    rmDX: NumberRemaining := CountryTable.NumberRemainingCountries;
    rmZone: NumberRemaining := MaxNumberOfZones;
  end;

  for RemainingMult := 0 to mo.PrfList.Count - 1 do
  begin
    SendMessage(RemainingMultsWindowHandle, LB_ADDSTRING, 0, RemainingMult);
  end;
  goto 1;

  for RemainingMult := 0 to NumberRemaining - 1 do
    if RemainingMults[RemainingMult] then
    begin
      CleanSweep := False;
      Break;
    end;

  if CleanSweep then
  begin
    SendDlgItemMessage(tr4w_WindowsArray[tw_REMMULTSWINDOW_INDEX].WndHandle, 101, LB_ADDSTRING, 0, 0);
    goto 1;
  end;

  for RemainingMult := 0 to NumberRemaining - 1 do
    case RemainingMultDisplayMode of
      Erase:
        if RemainingMults[RemainingMult] then goto AddMult;
      HiLight:
        begin
          AddMult:
          SendMessage(RemainingMultsWindowHandle, LB_ADDSTRING, 0, RemainingMult);
        end;
    end;

  1:
  tSetWindowRedraw(RemainingMultsWindowHandle, True);
end;
}

{
procedure DisplayAdditionalRemainingMults;
label
  AddMult, AddMultDX, AddMultDOM, AddMultZone, 1;
var
  NumberRemaining, RemainingMult        : integer;
begin

  if tWindowsExist(tw_STATIONS_RM_DX) then
  begin
    if RemainingMultsDX <> nil then
      for RemainingMult := 0 to CountryTable.NumberRemainingCountries - 1 do
        case RemainingMultDisplayMode of
          Erase:
            if RemainingMultsDX^[RemainingMult] then goto AddMultDX;
          HiLight:
            begin
              AddMultDX:
              SendMessage(RemainingMultsDXWindowHandle, LB_ADDSTRING, 0, RemainingMult);
            end;
        end;
    tSetWindowRedraw(RemainingMultsDXWindowHandle, True);
  end;

  if tWindowsExist(tw_STATIONS_RM_DOM) then
  begin
    if RemainingMultsDOM <> nil then
      for RemainingMult := 0 to DomQTHTable.NumberRemainingMults - 1 do
        case RemainingMultDisplayMode of
          Erase:
            if RemainingMultsDOM^[RemainingMult] then goto AddMultDOM;
          HiLight:
            begin
              AddMultDOM:
              SendMessage(RemainingMultsDOMWindowHandle, LB_ADDSTRING, 0, RemainingMult);
            end;
        end;
    tSetWindowRedraw(RemainingMultsDOMWindowHandle, True);
  end;

  if tWindowsExist(tw_STATIONS_RM_ZONE) then
  begin
    if RemainingMultsZone <> nil then
      for RemainingMult := 0 to MaxNumberOfZones - 1 do
        case RemainingMultDisplayMode of
          Erase:
            if RemainingMultsZone^[RemainingMult] then goto AddMultZone;
          HiLight:
            begin
              AddMultZone:
              SendMessage(RemainingMultsZoneWindowHandle, LB_ADDSTRING, 0, RemainingMult);
            end;
        end;
    tSetWindowRedraw(RemainingMultsZoneWindowHandle, True);
  end;

end;
}

procedure DecrementBandMapTimes;

{ Decrements all times by one.  Any that were at zero get deleted. }

var
  BandMapEntryRecord, {EntryToBeDisposed,} PreviousBandMapEntryRecord: BandMapEntryPointer;
  MinutesLeft                           : Byte;
  Band                                  : BandType;
  Mode                                  : ModeType;

begin
  for Band := Band160 to Band2 do
    for Mode := CW to Phone do
      if BandMapFirstEntryList[Band, Mode] <> nil then
      begin
        PreviousBandMapEntryRecord := nil;
        BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

        while BandMapEntryRecord <> nil do
        begin
          MinutesLeft := BandMapEntryRecord^.StatusByte and $3F;

          if MinutesLeft = 0 then { Time to die }
          begin
            if PreviousBandMapEntryRecord = nil then { This is the first one in list }
            begin
              BandMapFirstEntryList[Band, Mode] := BandMapEntryRecord^.NextEntry;
              Dispose(BandMapEntryRecord);
              BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];
              Continue;
            end;

                  { Wasn't the first record - change NextExtry of previous
                    record to point to the NextEntry }

            PreviousBandMapEntryRecord^.NextEntry := BandMapEntryRecord^.NextEntry;

                  { Free up the memory }

            Dispose(BandMapEntryRecord);

                  { We want to process the next band map entry next }

            BandMapEntryRecord := PreviousBandMapEntryRecord^.NextEntry;
            Continue;
          end;

              { We aren't going to delete this entry - decrement the minute count }

          dec(MinutesLeft);

          BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte and $C0;
          BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte or MinutesLeft;

              { Move to the next entry.  Remember the address of this entry in
                case I need to link its NextEntry to a different place }

          PreviousBandMapEntryRecord := BandMapEntryRecord;
          BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
        end;
      end;
end;
{
procedure ResetBandMapTimes;

//KK1L: 6.70 Sets all times to BandmapDecayTime. Called when BandMapDecayTime is changed.

var
  BandMapEntryRecord               : BandMapEntryPointer;
  Band                             : BandType;
  Mode                             : ModeType;

begin
  for Band := Band160 to Band2 do
    for Mode := CW to Phone do
      if BandMapFirstEntryList[Band, Mode] <> nil then
        begin
          BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

          while BandMapEntryRecord <> nil do
            begin
              BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte and $C0;
              BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte or BandMapDecayTime;
              BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
            end;
        end;
end;
}
{
procedure ResetBandMapDupes;
var
  BandMapEntryRecord               : BandMapEntryPointer;
  Band                             : BandType;
  Mode                             : ModeType;

begin
  for Band := Band160 to Band2 do
    for Mode := CW to Phone do
      if BandMapFirstEntryList[Band, Mode] <> nil then
        begin
          BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

          while BandMapEntryRecord <> nil do
            begin
              BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte and 191;
              //              BandMapEntryRecord^.StatusByte := BandMapEntryRecord^.StatusByte or BandMapDecayTime;
              BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
            end;
        end;
end;
}

procedure UpdateTimeAndRateDisplays(ShowTime: boolean; DoRadios: boolean);

label
  IgnoreRadioOneFreq, IgnoreRadioTwoFreq;

var
  DateString, DayString                 : Str20;
  Hour, Minute{, Second, Hundredths}      : Word;
  AlarmInteger, RecordNumber, IntegerTime {, RateMinute}: integer;
//  TempBand                              : BandType;
  TempPchar                             : PChar;
begin

  if DoRadios then
  begin

  end;

  //-----------------------time------------------------------------

  //  tGetSystemTime;

  if ShowTime then
  begin
    SetMainWindowText(mweFullTime, GetFullTimeString(False));

    if tElapsedTimeFromLastQSO <> 0 then tDispalyTimeFromLastQSO;

    if TenMinuteRule <> NoTenMinuteRule then
      TempPchar := ElaspedTimeString(TenMinuteTime.Time)
    else
      TempPchar := nil;
//    Windows.SetWindowText(TenMinutsWindow, TempPchar);
    SetMainWindowText(mweTenMinuts, TempPchar);
  end;

  {reminder}
  if UTC.wSecond = 1 then ShowTourDuration;

  if UTC.wSecond = 0 then { See if new minute }
  begin
    inc(MinutesSinceLastBMUpdate); {KK1L: 6.65}

      {if tDupesInteval > 0 then RefreshOZHRBandMap;}
   if ActiveBand in [Band160..Band10] then
         inc(TimeSpentByBand[ActiveBand]);

    AutoTimeQSOCount := 0;
      {KK1L: 6.65 Added this check to allow for > 63 minute BM decay}
    if MinutesSinceLastBMUpdate >= BandMapDecayMultiplier then
    begin
      MinutesSinceLastBMUpdate := 0;
          //DecrementBandMapTimes;
      SpotsList.DecrementSpotsTimes;
      DisplayBandMap;
    end;
    SetMainWindowText(mweClock, GetTimeString);

    if UTC.wMinute = 0 then
    begin
      SetMainWindowText(mweDate, GetDateString);
      TotalThisHour := 0;
      tThisHourBandChanges := 0;

      if MP3RecorderMode = mprRec then
        if RecorderDuration = rdEachHour then
        begin
          CloseTempMP3File;
          OpenTempMP3File;
        end;
    end;

    if NumberReminderRecords > 0 then
    begin
      IntegerTime := GetIntegerTime;
      DayString := UpperCase(GetDayString);
      DateString := UpperCase(GetDateString);

      for RecordNumber := 0 to NumberReminderRecords - 1 do
        if Reminders^[RecordNumber].Time = IntegerTime then
          if (Reminders^[RecordNumber].DateString = DateString) or
            (Reminders^[RecordNumber].DayString = DayString) or
            (Reminders^[RecordNumber].DayString = 'ALL') then
          begin

            if Reminders^[RecordNumber].Alarm then
              DoABeep(WakeUp)
            else
              DoABeep(Congrats);
//            if WindowsOSversion = 2 then
//              ShowTrayTips(Reminders^[RecordNumber].RemMessage)
//            else
            QuickDisplay(@Reminders^[RecordNumber].RemMessage[1]);
          end;
    end;

    if AlarmSet then
    begin
      AlarmInteger := AlarmHour * 100 + AlarmMinute;

      if AlarmInteger = GetIntegerTime then
      begin
              //{WLI}                WakeUp;
        AlarmMinute := AlarmMinute + 4;

        if AlarmMinute > 59 then
        begin
          AlarmMinute := AlarmMinute - 60;
          AlarmHour := AlarmHour + 1;
          if AlarmHour > 23 then
            AlarmHour := AlarmHour - 24;
        end;
      end;

      if (Hour = AlarmHour) and (Minute = AlarmMinute) then
      begin
              //{WLI}                WakeUp;
        AlarmMinute := AlarmMinute + 4;

        if AlarmMinute > 59 then
        begin
          AlarmMinute := AlarmMinute - 60;
          AlarmHour := AlarmHour + 1;
          if AlarmHour > 23 then
            AlarmHour := AlarmHour - 24;
        end;
      end;
    end;

    if (NumberContactsThisMinute = 0) and (WakeUpTimeOut > 0) then
    begin
      inc(WakeUpCount);
      if (WakeUpCount >= WakeUpTimeOut) and not AlarmSet then
        DoABeep(WakeUp);
    end
    else
      WakeUpCount := 0;
    tCalculateRate();
{
//       Fix up the rate array. First, shuffle the minutes

    for RateMinute := 60 downto 2 do
    begin
      RateMinuteArray[RateMinute].TotalQSOs := RateMinuteArray[RateMinute - 1].TotalQSOs;
      RateMinuteArray[RateMinute].TotalPoints := RateMinuteArray[RateMinute - 1].TotalPoints;
      RateMinuteArray[RateMinute].BandQSOs := RateMinuteArray[RateMinute - 1].BandQSOs;
    end;

//       Put new values on top

    RateMinuteArray[1].TotalQSOs := NumberContactsThisMinute;
    RateMinuteArray[1].TotalPoints := NumberQSOPointsThisMinute;
    RateMinuteArray[1].BandQSOs := NumberBandQSOsThisMinute;

//       Compute rate = # QSOs or points in last 10 minutes

    Rate := 0;

    for RateMinute := 1 to 10 do
      case RateDisplay of
        QSOs: Rate := Rate + RateMinuteArray[RateMinute].TotalQSOs;
        Points: Rate := Rate + RateMinuteArray[RateMinute].TotalPoints;
        BandQSOs: if ActiveBand in [Band160..Band10] then Rate := Rate + RateMinuteArray[RateMinute].BandQSOs[ActiveBand];
      end;

//       Compute last sixty minute totals

    TotalLastSixty := 0;

    for RateMinute := 1 to 60 do
      case RateDisplay of
        QSOs: TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].TotalQSOs;
        Points: TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].TotalPoints;
        BandQSOs: if ActiveBand in [Band160..Band10] then TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].BandQSOs[ActiveBand];
      end;

    case RateDisplay of
      QSOs: TotalThisHour := TotalThisHour + NumberContactsThisMinute;
      Points: TotalThisHour := TotalThisHour + NumberQSOPointsThisMinute;
      if tworadiomode then
      BandQSOs: if ActiveBand in [Band160..Band10] then TotalThisHour := TotalThisHour + NumberBandQSOsThisMinute[ActiveBand] + NumberBandQSOsThisMinute[InActiveBand]  // n4af 4.41.2
      else
     BandQSOs: if ActiveBand in [Band160..Band10] then TotalThisHour := TotalThisHour + NumberBandQSOsThisMinute[ActiveBand] ;
    end;

//       Zero out minute totals

    NumberContactsThisMinute := 0;
    NumberQSOPointsThisMinute := 0;

    for TempBand := Band160 to Band10 do NumberBandQSOsThisMinute[TempBand] := 0;

//       Compute rate

    if NumberMinutesProgramRunning >= 10 then
      Rate := Rate * 6
    else
    begin
      inc(NumberMinutesProgramRunning);

      if NumberMinutesProgramRunning > 0 then
        Rate := round(Rate * (60 / NumberMinutesProgramRunning))
      else
        Rate := 0;
    end;

//          if HourString <> LastDisplayedHour then
//          begin
//            TotalThisHour := 0;
//            LastDisplayedHour := HourString;
//          end;

    DisplayRate(Rate);
}
//          if (Packet.PacketSerialPort <> NoPort) and (PacketReturnPerMinute <> 0) then
//          begin
//            Dec(PacketReturnCount);

//            if PacketReturnCount = 0 then
//            begin
//              CPUKeyer.AddSerialPortCharacter(Packet.PacketSerialPort, CarriageReturn);
//              QuickDisplay('Carriage return sent to packet port.  (per PACKET RETURN PER MINUTE)');
//              PacketReturnCount := PacketReturnPerMinute;
//            end;
//          end;
  end;
end;

procedure tCalculateRate();
var
  RateMinute                            : integer;
  TempBand                              : BandType;
begin
//       Fix up the rate array. First, shuffle the minutes

  for RateMinute := 60 downto 2 do
  begin
    RateMinuteArray[RateMinute].TotalQSOs := RateMinuteArray[RateMinute - 1].TotalQSOs;
    RateMinuteArray[RateMinute].TotalPoints := RateMinuteArray[RateMinute - 1].TotalPoints;
    RateMinuteArray[RateMinute].BandQSOs := RateMinuteArray[RateMinute - 1].BandQSOs;
  end;

//       Put new values on top

  RateMinuteArray[1].TotalQSOs := NumberContactsThisMinute;
  RateMinuteArray[1].TotalPoints := NumberQSOPointsThisMinute;
  RateMinuteArray[1].BandQSOs := NumberBandQSOsThisMinute;

//       Compute rate = # QSOs or points in last 10 minutes

  Rate := 0;

  for RateMinute := 1 to 10 do
    case RateDisplay of
      QSOs: Rate := Rate + RateMinuteArray[RateMinute].TotalQSOs;
      Points: Rate := Rate + RateMinuteArray[RateMinute].TotalPoints;
      BandQSOs: if ActiveBand in [Band160..Band10] then Rate := Rate + RateMinuteArray[RateMinute].BandQSOs[ActiveBand] +  RateMinuteArray[RateMinute].BandQSOs[InactiveRadioPtr.BandMemory];  // n4af 4.76.4
    end;

//       Compute last sixty minute totals

  TotalLastSixty := 0;

  for RateMinute := 1 to 60 do
    case RateDisplay of
      QSOs: TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].TotalQSOs;
      Points: TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].TotalPoints;
      BandQSOs: if ActiveBand in [Band160..Band10] then TotalLastSixty := TotalLastSixty + RateMinuteArray[RateMinute].BandQSOs[ActiveBand];
    end;

  case RateDisplay of
    QSOs: TotalThisHour := TotalThisHour + NumberContactsThisMinute;
    Points: TotalThisHour := TotalThisHour + NumberQSOPointsThisMinute;
    BandQSOs: if ActiveBand in [Band160..Band10] then TotalThisHour := TotalThisHour + NumberBandQSOsThisMinute[ActiveBand];
  end;

//       Zero out minute totals

  NumberContactsThisMinute := 0;
  NumberQSOPointsThisMinute := 0;
  for TempBand := Band160 to Band10 do NumberBandQSOsThisMinute[TempBand] := 0;

//       Compute rate

  if NumberMinutesProgramRunning >= 10 then
    Rate := Rate * 6
  else
  begin
    inc(NumberMinutesProgramRunning);

    if NumberMinutesProgramRunning > 0 then
      Rate := round(Rate * (60 / NumberMinutesProgramRunning))
    else
      Rate := 0;
  end;
  DisplayHour;
  DisplayRate(Rate);
end;                          

procedure IncrementTime(Count: integer);

//var
 // LoopCount                             : integer;
 // Hours, Minutes, Seconds, Hundredths   : Word;
 // Year, Month, Day, DayOfWeek           : Word;

begin
  AutoTimeQSOCount := 0;
  IncSystemTime(UTC, 60 * 1000 * Count);
  UTC.wSecond := 0;
{
  GetTime(Hours, Minutes, Seconds, Hundredths);
  Minutes := Minutes + Count;

  if Minutes > 59 then
  begin
    Minutes := Minutes - 60;
    inc(Hours);

    if Hours > 23 then
    begin
      Hours := Hours - 24;
      GetDate(Year, Month, Day, DayOfWeek);
      inc(Day);
          //WLI            SetDate (Year, Month, Day);
    end;
  end;
}
  //WLI    SetTime (Hours, Minutes, 0, 0);
//  LastDisplayedTime := '';
//  LastDisplayedDate := '';
  SystemTimeChanging;
//  UpdateTimeAndRateDisplays(True, False);
end;

procedure ClearAutoSendDisplay;

begin
  //  SaveAndSetActiveWindow(WholeScreenWindow);
   //{WLI}    GoToXY (CallWindowLX, CallWindowLY - 1);
   //{WLI}    Write ('          ');
   //{WLI}    RestorePreviousWindow;
end;

procedure DisplayAutoSendCharacterCount;
var
  h                                     : HWND;
  nCmdShow                              : integer;
begin

  h := wh[mweAutoSendCount];
  if (AutoSendCharacterCount > 0) and AutoSendEnable and (ActiveMode = CW) and not SearchAndPounceMode then
  begin
    nCmdShow := SW_SHOW;
    tSetWindowLeft(h, (AutoSendCharacterCount - 1) * ws2 * 3 + ws * 15 {col4});
  end
  else
    nCmdShow := SW_HIDE;
  Windows.ShowWindow(h, nCmdShow);
end;

procedure DeleteBandMapEntry(var Entry: BandMapEntryPointer);

var
  BandMapEntryRecord, PreviousBandEntryRecord: BandMapEntryPointer;
  //CompressedDeleteCall                  : EightBytes;
  {  StartBand, StopBand, }Band         : BandType;
  {  StartMode, StopMode, }Mode         : ModeType;

begin
  if not BandMapEnable then Exit;
  tSetStartStopBandMode;

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin

      if (not WARCBandsEnabled) and
        ({(Band = Band60) or} (Band = Band30) or (Band = Band17) or (Band = Band12)) then
        Continue; {KK1L: 6.64 Keep band map within contest limits}

      PreviousBandEntryRecord := nil;
      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        if BigCompressedCallsAreEqual(Entry^.Call, BandMapEntryRecord^.Call) then
          if Abs(Entry^.Frequency - BandMapEntryRecord^.Frequency) <= BandMapGuardBand then
          begin

                  { We have found the entry to delete }

            if PreviousBandEntryRecord = nil then { This is the first entry }
            begin
              BandMapFirstEntryList[Band, Mode] := BandMapEntryRecord^.NextEntry;
              Entry := BandMapEntryRecord^.NextEntry;
              Dispose(BandMapEntryRecord);
              Exit;
            end;

                  { Not the first record }

            PreviousBandEntryRecord^.NextEntry := BandMapEntryRecord^.NextEntry;
            Entry := BandMapEntryRecord^.NextEntry;

                  { Was it the last one?  If so, make the active entry
                    the previous record }

            if Entry = nil then
              Entry := PreviousBandEntryRecord;
            Dispose(BandMapEntryRecord);
            Exit;
          end;

        PreviousBandEntryRecord := BandMapEntryRecord;
        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;
end;

procedure SetUpBandMapEntry(BandMapData: BandMapEntryPointer; Radio: RadioType); {KK1L: 6.73 Added Radio}

{KK1L: 6.64 Added sense of mode from frequency so radio would be set to mode}
{      when bandmapentry is selected}
{KK1L: 6.64 Added taking radio out of split when QSXOffset=0}
{KK1L: 6.64 Added QSXOffset scaling to make range within INTEGER}

var
  EntryBand                             : BandType;
  EntryMode                             : ModeType;
  QSXOffsetInHertz                      : LONGINT;
  TempCallsign                          : Str20;
begin
  if BandMapData = nil then Exit;
  BandMapCursorData := BandMapData;

  with BandMapData^ do
    if Frequency > 0 then
    begin
      GetBandMapBandModeFromFrequency(Frequency, EntryBand, EntryMode);

        //      ClearCallWindowAtSPMove := false;
      if QSXOffset <> 0 then
      begin
            {KK1L: 6.64 Scaling added to keep offset within INTEGER range.}
            {QSXOffsetInHertz := QSXOffset * 10;}
            {KK1L: 6.64 Not needed. Only LONGINT seems to work as QSXOffset type}
        QSXOffsetInHertz := QSXOffset;
            {KK1L: 6.64 Trying to add resonable functionality to split stuff}
        case BandMapSplitMode of
          ByCutoffFrequency:
            begin
                  {KK1L: 6.71 moved ahead of 'A' because for TS850 need to make B active to change mode}
              SetRadioFreq(Radio, {wli Frequency +} QSXOffsetInHertz, EntryMode, 'B');
              SetRadioFreq(Radio, Frequency, EntryMode, 'A');
            end;
          AlwaysPhone:
            begin
                  {KK1L: 6.71 moved ahead of 'A' because for TS850 need to make B active to change mode}
              SetRadioFreq(Radio, {wli Frequency +} QSXOffsetInHertz, Phone, 'B');
              SetRadioFreq(Radio, Frequency, Phone, 'A');
            end;
        end;
        PutRadioIntoSplit(Radio); {KK1L: 6.71 Moved here from before case for TS850 change}
      end
      else {KK1L: 6.64 Takes radio back out of split if not required for next entry}
      begin
        SetRadioFreq(Radio, Frequency, EntryMode, 'A');
        PutRadioOutOfSplit(Radio);
      end;
        {wli}
//      Escape_proc;
//      SetOpMode(SearchAndPounceOpMode);
      CallAlreadySent := False;
      ExchangeHasBeenSent := False;
      tCleareExchangeWindow;
      TempCallsign := BandMapExpandedString(Call);
      if CQLabel(TempCallsign) then
      begin
        Windows.SetWindowText(wh[mweCall], nil);
        SetOpMode(CQOpMode);
      end
      else
      begin
        SetOpMode(SearchAndPounceOpMode);
        if Copy(TempCallsign, 1, 3) <> 'NEW' then
          tSetWindowText(wh[mweCall], TempCallsign);
      end;
        //      Frm.CallWindow . SetFocus;
      tCallWindowSetFocus;
        //        SendMessage(CallWindowHandle, EM_SETSEL, 16, 16);
      PlaceCaretToTheEnd(wh[mweCall]);
      DisplayCountryName(CallWindowString);
      DisplayBeamHeading(CallWindowString, '');

        //        DispalayB4; //???????

      if Contest <> GENERALQSO then
      begin
        VisibleLog.ShowMultiplierStatus(@CallWindowString);
        VisibleLog.ShowQSOStatus(@CallWindowString);
      end;
        //      FRM.CallWindowChange(nil);
        //      CallAlreadySent := False;

    end;
end;

function NextNonDupeEntryInDisplayedBandMap(Band: BandType; Mode: ModeType): boolean;

{ Data will be in BandMapCursorData record }
{KK1L: 6.64 Added to allow stepping through the displayed bandmap rather than just in}
{      current band and mode.}

var
  BandMapEntryRecord                    : BandMapEntryPointer;
  Callsign                              : CallString;
  //  StartBand, StopBand              : BandType;
  //  StartMode, StopMode              : ModeType;
  RadioToUse                            : RadioType; {KK1L: 6.73}

begin
  NextNonDupeEntryInDisplayedBandMap := False;

  if CommandUseInactiveRadio then {KK1L: 6.73}
    RadioToUse := InactiveRadio
  else
    RadioToUse := ActiveRadio;
  tSetStartStopBandMode;
  {
    if BandMapAllBands then
      begin
        if VHFBandsEnabled then //KK1L: 6.64 Keep band map within contest limits
          begin
            StartBand := Band160;
            StopBand := Band2;
          end
        else
          begin
            StartBand := Band160;
            StopBand := Band12; //KK1L: 6.65 fixes WARC display enable
          end;
      end
    else
      begin
        StartBand := BandMapBand;
        StopBand := BandMapBand;
      end;

    if BandMapAllModes then
      begin
        StartMode := CW;
        StopMode := Phone;
      end
    else
      begin
        StartMode := BandMapMode;
        StopMode := BandMapMode;
      end;
  }
  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin

      if (not WARCBandsEnabled) and
        ({(Band = Band60) or} (Band =Band30) or (Band = Band17) or (Band = Band12)) then
        Continue; {KK1L: 6.64 Keep band map within contest limits}

      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
            {KK1L: 6.73 Use LastDisplayedFreq instead of DisplayedFrequency to support control-A}
//       if BandMapEntryRecord^.Frequency > LastDisplayedFreq[RadioToUse] then
//        if Abs(LastDisplayedFreq[RadioToUse] - BandMapEntryRecord^.Frequency) > BandMapGuardBand then
        if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
          if ((BandMapEntryRecord^.StatusByte and $40) = 0) then
          begin
            SetUpBandMapEntry(BandMapEntryRecord, RadioToUse); {KK1L: 6.73}
            NextNonDupeEntryInDisplayedBandMap := True;
            Exit;
          end;

        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;

  { Got to the end of the list without finding anything.  Start at the
    beginning and find the first non dupe entry }

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin
      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
        if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
          if ((BandMapEntryRecord^.StatusByte and $40) = 0) then
          begin
            BandMapCursorData := BandMapEntryRecord;
            NextNonDupeEntryInDisplayedBandMap := True;
            Exit;
          end;

        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;
end;

{KK1L: 6.68}

function NextMultiplierEntryInDisplayedBandMap(Band: BandType; Mode: ModeType): boolean;

{ Data will be in BandMapCursorData record }
{KK1L: 6.68 Added to allow stepping through the displayed bandmap rather than just in}
{      current band and mode.}

var
  BandMapEntryRecord                    : BandMapEntryPointer;
  Callsign                              : CallString;
  //  StartBand, StopBand              : BandType;
  //  StartMode, StopMode              : ModeType;
  RadioToUse                            : RadioType; {KK1L: 6.73}

begin
  NextMultiplierEntryInDisplayedBandMap := False;

  if CommandUseInactiveRadio then {KK1L: 6.73}
    RadioToUse := InactiveRadio
  else
    RadioToUse := ActiveRadio;
  tSetStartStopBandMode;
  {
    if BandMapAllBands then
      begin
        if VHFBandsEnabled then //KK1L: 6.64 Keep band map within contest limits
          begin
            StartBand := Band160;
            StopBand := Band2;
          end
        else
          begin
            StartBand := Band160;
            StopBand := Band12; //KK1L: 6.65 fixes WARC display enable
          end;
      end
    else
      begin
        StartBand := BandMapBand;
        StopBand := BandMapBand;
      end;

    if BandMapAllModes then
      begin
        StartMode := CW;
        StopMode := Phone;
      end
    else
      begin
        StartMode := BandMapMode;
        StopMode := BandMapMode;
      end;
  }
  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin

      if (not WARCBandsEnabled) and
        ({(Band = Band60) or }(Band = Band30) or (Band = Band17) or (Band = Band12)) then
        Continue; {KK1L: 6.64 Keep band map within contest limits}

      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
            {KK1L: 6.73 Use LastDisplayedFreq instead of DisplayedFrequency to support control-A}
//????????        if BandMapEntryRecord^.Frequency > LastDisplayedFreq[RadioToUse] then
//????????          if Abs(LastDisplayedFreq[RadioToUse] - BandMapEntryRecord^.Frequency) > BandMapGuardBand then
        if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
          if ((BandMapEntryRecord^.StatusByte and $80) <> 0) then
          begin
            SetUpBandMapEntry(BandMapEntryRecord, RadioToUse); {KK1L: 6.73}
            NextMultiplierEntryInDisplayedBandMap := True;
            Exit;
          end;

        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;

  { Got to the end of the list without finding anything.  Start at the
    beginning and find the first non dupe entry }

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin
      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
        if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
          if ((BandMapEntryRecord^.StatusByte and $80) <> 0) then
          begin
            BandMapCursorData := BandMapEntryRecord;
            NextMultiplierEntryInDisplayedBandMap := True;
            Exit;
          end;

        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;
end;

function NextNonDupeEntryInBandMap(Band: BandType; Mode: ModeType): boolean;

{ Data will be in BandMapCursorData record }
var
  BandMapEntryRecord                    : BandMapEntryPointer;
  Callsign                              : CallString;
  RadioToUse                            : RadioType; {KK1L: 6.73}

begin
  NextNonDupeEntryInBandMap := False;

  if CommandUseInactiveRadio then {KK1L: 6.73}
    RadioToUse := InactiveRadio
  else
    RadioToUse := ActiveRadio;

  if BandMapFirstEntryList[Band, Mode] = nil then
    Exit;

  BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

  { Search through the bandmap to find the next non dupe entry. }

  while BandMapEntryRecord <> nil do
  begin
    Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
      {KK1L: 6.73 Use LastDisplayedFreq instead of DisplayedFrequency to support control-A}
//????????    if BandMapEntryRecord^.Frequency > LastDisplayedFreq[RadioToUse] then
//????????      if Abs(LastDisplayedFreq[RadioToUse] - BandMapEntryRecord^.Frequency) > BandMapGuardBand then
    if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
      if ((BandMapEntryRecord^.StatusByte and $40) = 0) then
      begin
        SetUpBandMapEntry(BandMapEntryRecord, RadioToUse); {KK1L: 6.73}
        NextNonDupeEntryInBandMap := True;
        Exit;
      end;

    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;

  { Got to the end of the list without finding anything.  Start at the
    beginning and find the first non dupe entry }

  BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

  while BandMapEntryRecord <> nil do
  begin
    Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
    if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
      if ((BandMapEntryRecord^.StatusByte and $40) = 0) then
      begin
        BandMapCursorData := BandMapEntryRecord;
        NextNonDupeEntryInBandMap := True;
        Exit;
      end;

    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;
end;

{KK1L: 6.68}

function NextMultiplierEntryInBandMap(Band: BandType; Mode: ModeType): boolean;

{ Data will be in BandMapCursorData record }
var
  BandMapEntryRecord                    : BandMapEntryPointer;
  Callsign                              : CallString;
  RadioToUse                            : RadioType; {KK1L: 6.73}

begin
  NextMultiplierEntryInBandMap := False;

  if CommandUseInactiveRadio then {KK1L: 6.73}
    RadioToUse := InactiveRadio
  else
    RadioToUse := ActiveRadio;

  if BandMapFirstEntryList[Band, Mode] = nil then
    Exit;

  BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

  { Search through the bandmap to find the next non dupe entry. }

  while BandMapEntryRecord <> nil do
  begin
    Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
      {KK1L: 6.73 Use LastDisplayedFreq instead of DisplayedFrequency to support control-A}
//????????    if BandMapEntryRecord^.Frequency > LastDisplayedFreq[RadioToUse] then
//????????      if Abs(LastDisplayedFreq[RadioToUse] - BandMapEntryRecord^.Frequency) > BandMapGuardBand then
    if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
      if ((BandMapEntryRecord^.StatusByte and $80) <> 0) then
      begin
        SetUpBandMapEntry(BandMapEntryRecord, RadioToUse); {KK1L: 6.73}
        NextMultiplierEntryInBandMap := True;
        Exit;
      end;

    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;

  { Got to the end of the list without finding anything.  Start at the
    beginning and find the first non dupe entry }

  BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

  while BandMapEntryRecord <> nil do
  begin
    Callsign := BandMapExpandedString(BandMapEntryRecord^.Call);
    if CQLabel(Callsign) then {KK1L: 6.69 added to skip CQ frequency}
      if ((BandMapEntryRecord^.StatusByte and $80) <> 0) then
      begin
        BandMapCursorData := BandMapEntryRecord;
        NextMultiplierEntryInBandMap := True;
        Exit;
      end;

    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;
end;

procedure GetBandMapBandModeFromFrequency(Frequency: LONGINT;
  var Band: BandType;
  var Mode: ModeType);

{ Mode might be setup by someone else - in which case, don't mess with it }

//var
 // TempMode                              : ModeType;
  //TempStr                               : Str20;
begin
  CalculateBandMode(Frequency, Band, {Temp} Mode);
//  if not (Mode in [CW, Phone]) then
  begin
    if Band = NoBand then Exit;
    if Frequency >= BandMapModeCutoffFrequency[Band] then
      Mode := Phone
    else
      Mode := CW;
  end;
end;

procedure AddBandMapModeCutoffFrequency(Freq: LONGINT);

var
  TempBand                              : BandType;
  TempMode                              : ModeType;
begin
  CalculateBandMode(Freq, TempBand, TempMode);
  if TempBand in [Band160..Band2] then BandMapModeCutoffFrequency[TempBand] := Freq;
end;

procedure AddBandMapPlaceHolder;

{KK1L: 6.65 Created proc to add a dummy call to the BM. It is invoked by CTRL-INS.}
{           Its purpose is to put a unique ID in the BM with multiplier set when you}
{           tune across a station, catch a partial call, and don't want to wait.}

begin
  tBandMapPlaceHolder[0] := CHR(8);
  tGetSystemTime;

  Format(@tBandMapPlaceHolder[1], 'NEW %02u%02u', UTC.wMinute, UTC.wSecond);

  tCreateAndAddNewSpot(tBandMapPlaceHolder, False, ActiveRadioPtr);
  DisplayBandMap;
end;

procedure AddBandMapEntry(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: Byte;
  Source: CallString);
begin
  TempSpot.FCall := Call;
  TempSpot.FFrequency := Frequency;
  TempSpot.FQSXFrequency := QSXFrequency;
  TempSpot.FMode := Mode;
  TempSpot.FDupe := Dupe;
  TempSpot.FMult := Mult;
  TempSpot.FMinutesLeft := 0; //MinutesLeft;
  TempSpot.FSourceCall := Source;
  TempSpot.FSysTime := UTC.wMinute + UTC.wHour * 60 + UTC.wDay * 60 * 24 + UTC.wMonth * 60 * 24 * 30;
  SpotsList.AddSpot(TempSpot, True);
end;

procedure AddBandMapEntry_old(Call: CallString;
  Frequency: LONGINT;
  QSXFrequency: LONGINT;
  Mode: ModeType;
  Dupe: boolean;
  Mult: boolean;
  MinutesLeft: Byte;
  Source: CallString);

{KK1L: 6.64 Added QSXOffset scaling to make range within INTEGER}

var
  LastBandMapEntryRecord, NextBandMapEntryRecord: BandMapEntryPointer;
  TempBandMapEntryRecord, BandMapEntryRecord: BandMapEntryPointer;
  StatusByte                            : Byte;
  QSXOffset                             : LONGINT; {KK1L: 6.64 Tried INTEGER, but no joy.}
  CompressedCall                        : EightBytes;
  EntryAdded                            : boolean;
  Band                                  : BandType;

begin
  if not BandMapEnable then Exit;

  { The band map seemed to be crashing with SHF frequencies }

  if Frequency > 150000000 then Exit;
  if Frequency < 10 then Exit;

  BigCompressFormat(Call, CompressedCall);

  { Fix up status byte }

  StatusByte := MinutesLeft and $3F;
  if Dupe then StatusByte := StatusByte or $40;
  if Mult then StatusByte := StatusByte or $80;

  { Compute QSX offset value - zero means none }

  if QSXFrequency = 0 then
    QSXOffset := 0
  else
    if Abs(QSXFrequency - Frequency) < 327670 then
      {KK1L: 6.64 Scaling added to keep offset within INTEGER range.}
      {SXOffset := (QSXFrequency - Frequency) DIV 10}
      {KK1L: 6.64 Not needed. Only LONGINT seems to work as QSXOffset type}
      QSXOffset := (QSXFrequency - Frequency)
    else
      QSXOffset := 0; { Unexpected result }

  GetBandMapBandModeFromFrequency(Frequency, Band, Mode);

  if Band = NoBand then Exit;

  { See if the list of entries for this band mode is empty }

  if BandMapFirstEntryList[Band, Mode] = nil then { Nothing in bandmap yet }
  begin
    New(BandMapFirstEntryList[Band, Mode]);
    BandMapFirstEntryList[Band, Mode]^.Call := CompressedCall;
    BandMapFirstEntryList[Band, Mode]^.Frequency := Frequency;
    BandMapFirstEntryList[Band, Mode]^.QSXOffset := QSXOffset;
    BandMapFirstEntryList[Band, Mode]^.StatusByte := StatusByte;
    BandMapFirstEntryList[Band, Mode]^.bmBand := Band;
    BandMapFirstEntryList[Band, Mode]^.bmMode := Mode;
    BandMapFirstEntryList[Band, Mode]^.Source := Source;
    BandMapFirstEntryList[Band, Mode]^.NextEntry := nil;
    Exit;
  end;

  { There are some entries for this band/mode.  Get setup to look
    through the list }

  LastBandMapEntryRecord := nil;
  BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

  { Search through the bandmap to find the right place for this entry.
    We keep the frequencies in order, so we need to step through the
    linked list until we find a record with a higher frequency than
    the one being added.  We squeeze this new entry in before that one,
    but check to see if the frequency is nearly the same first. }

  EntryAdded := False;

  while BandMapEntryRecord <> nil do
  begin

      { See if the frequency is nearly the same - and if so, we will
        use this record. }

    if Abs(Frequency - BandMapEntryRecord^.Frequency) <= BandMapGuardBand then
    begin
      if EntryAdded then { Already added it - so delete this one }
      begin

              { We should not be able to be here without
                LastBandMapEntryRecord being setup to something...

                We are going to set the .NextEntry pointer of the
                previous record to point to the NextEntry as indicated
                in the .NextEntry value of the current record }

        LastBandMapEntryRecord^.NextEntry := BandMapEntryRecord^.NextEntry;
        TempBandMapEntryRecord := BandMapEntryRecord^.NextEntry;

              { Delete the current record. Runtime 204 here? }

              { Runtime 204 here when SPACE entered for frequency }

        Dispose(BandMapEntryRecord);

              { Setup current entry with this next entry.
                LastBandMapEntryRecord is fine the way it is }

        BandMapEntryRecord := LastBandMapEntryRecord^.NextEntry;
        Continue;
      end;

          { Entry not yet added - take over this record }

      BandMapEntryRecord^.Call := CompressedCall;
      BandMapEntryRecord^.Frequency := Frequency;
      BandMapEntryRecord^.QSXOffset := QSXOffset;
      BandMapEntryRecord^.StatusByte := StatusByte;
      BandMapEntryRecord^.bmBand := Band;
      BandMapEntryRecord^.bmMode := Mode;
      BandMapEntryRecord^.Source := Source;
      EntryAdded := True;

          { Setup to examine next record and then continue }

      LastBandMapEntryRecord := BandMapEntryRecord;
      BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      Continue;
    end;

    if BigCompressedCallsAreEqual(CompressedCall, BandMapEntryRecord^.Call) then
    begin
          { We have found the same call in the band map.  If the frequency
            was close enough - we would have already used it.  Therefore,
            we can probably delete this call. }

          { However, we need to check for the special case that this is the
            first entry in the list - and therefore wouldn't have been
            added yet }

      if LastBandMapEntryRecord = nil then { This is the 1st entry }
      begin

              { New for 6.50 - if there are no other entries - just use
                this one again }

        if BandMapEntryRecord^.NextEntry = nil then { no next entry }
        begin
          BandMapEntryRecord^.Call := CompressedCall;
          BandMapEntryRecord^.Frequency := Frequency;
          BandMapEntryRecord^.QSXOffset := QSXOffset;
          BandMapEntryRecord^.StatusByte := StatusByte;
          BandMapEntryRecord^.bmBand := Band;
          BandMapEntryRecord^.bmMode := Mode;
          BandMapEntryRecord^.Source := Source;
          Exit;
        end;

              { New for 6.50 - if the frequency is less than the next
                bandmap entries, we should also just use this one }

        NextBandMapEntryRecord := BandMapEntryRecord^.NextEntry;

        if Frequency < BandMapEntryRecord^.Frequency then
        begin
          BandMapEntryRecord^.Call := CompressedCall;
          BandMapEntryRecord^.Frequency := Frequency;
          BandMapEntryRecord^.QSXOffset := QSXOffset;
          BandMapEntryRecord^.StatusByte := StatusByte;
          BandMapEntryRecord^.bmBand := Band;
          BandMapEntryRecord^.bmMode := Mode;
          BandMapEntryRecord^.Source := Source;
          Exit;
        end;

              { Okay - we have found a record with the same call, but we
                can't leave it here because the frequency indicates that
                it should be furthur in the list somewhere.

                Delete the active record and do the splice so the list
                still works.  This is a unique way of deleting an entry
                as we have to worry about the BandMapFirstEntry entry. }

        BandMapFirstEntryList[Band, Mode] := BandMapEntryRecord^.NextEntry;
        TempBandMapEntryRecord := BandMapEntryRecord^.NextEntry;
        Dispose(BandMapEntryRecord);

        BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];
        Continue;
      end;

          { Found an entry with the same callsign - it isn't the first
            entry of the list.  The frequencies aren't close enough that
            we would have already used this record. }

          { New in 6.50 - See if the frequency is still less than the
            next entry - or perhaps that the next entry does not exist.
            In either case, we can still use this record. }

          { See if there are no other entries }

      if not EntryAdded then
      begin
        if BandMapEntryRecord^.NextEntry = nil then
        begin
          BandMapEntryRecord^.Call := CompressedCall;
          BandMapEntryRecord^.Frequency := Frequency;
          BandMapEntryRecord^.QSXOffset := QSXOffset;
          BandMapEntryRecord^.StatusByte := StatusByte;
          BandMapEntryRecord^.bmBand := Band;
          BandMapEntryRecord^.bmMode := Mode;
          BandMapEntryRecord^.Source := Source;
          Exit;
        end;

              { See if the frequency is less than the next entry }

        NextBandMapEntryRecord := BandMapEntryRecord^.NextEntry;

        if Frequency < BandMapEntryRecord^.Frequency then
        begin
          BandMapEntryRecord^.Call := CompressedCall;
          BandMapEntryRecord^.Frequency := Frequency;
          BandMapEntryRecord^.QSXOffset := QSXOffset;
          BandMapEntryRecord^.StatusByte := StatusByte;
          BandMapEntryRecord^.bmBand := Band;
          BandMapEntryRecord^.bmMode := Mode;
          BandMapEntryRecord^.Source := Source;
          Exit;
        end;
      end;

          { Okay - we can't use this record, so we will delete it and
            splice the pointers. }

      LastBandMapEntryRecord^.NextEntry := BandMapEntryRecord^.NextEntry;
      TempBandMapEntryRecord := BandMapEntryRecord^.NextEntry;

      Dispose(BandMapEntryRecord);
      BandMapEntryRecord := LastBandMapEntryRecord^.NextEntry;
      Continue;
    end;

      { See if the frequency is less than the next record.  If so, this
        is where we want to put it }

    if (not EntryAdded) and
      (Frequency < BandMapEntryRecord^.Frequency) then
    begin

          { New for 6.50 }

      if LastBandMapEntryRecord = nil then { This is the first entry }
      begin
        BandMapEntryRecord := New(BandMapEntryPointer);

              { Do the splice }

        BandMapEntryRecord^.NextEntry := BandMapFirstEntryList[Band, Mode];

        BandMapFirstEntryList[Band, Mode] := BandMapEntryRecord;

              { Save the data }

        BandMapEntryRecord^.Call := CompressedCall;
        BandMapEntryRecord^.Frequency := Frequency;
        BandMapEntryRecord^.QSXOffset := QSXOffset;
        BandMapEntryRecord^.StatusByte := StatusByte;
        BandMapEntryRecord^.bmBand := Band;
        BandMapEntryRecord^.bmMode := Mode;
        BandMapEntryRecord^.Source := Source;
        EntryAdded := True;

              { Setup to go through the rest of the list }

        LastBandMapEntryRecord := BandMapEntryRecord;
        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
        Continue;
      end;

          { We need to squeeze an new entry in here }

      TempBandMapEntryRecord := BandMapEntryRecord; { Remember }

      BandMapEntryRecord := New(BandMapEntryPointer);

          { Do the splice }

      LastBandMapEntryRecord^.NextEntry := BandMapEntryRecord;

      BandMapEntryRecord^.NextEntry := TempBandMapEntryRecord;

          { Fill in the data for the new record }

      BandMapEntryRecord^.Call := CompressedCall;
      BandMapEntryRecord^.Frequency := Frequency;
      BandMapEntryRecord^.QSXOffset := QSXOffset;
      BandMapEntryRecord^.StatusByte := StatusByte;
      BandMapEntryRecord^.bmBand := Band;
      BandMapEntryRecord^.bmMode := Mode;
      BandMapEntryRecord^.Source := Source;
      EntryAdded := True;

          { Setup to continue looking at the rest of the entries.  We
            need to do this in case there is an entry on this band/mode
            later on with the same callsign that needs to be deleted. }

      LastBandMapEntryRecord := BandMapEntryRecord;
      BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      Continue;
    end;

      { Point to the next entry in the list }

    LastBandMapEntryRecord := BandMapEntryRecord;
    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;

  if EntryAdded then
  begin
    Exit;
  end;

  { We got to the end of the list without finding the call or a place to
    add it.  Add to end of list. }

  BandMapEntryRecord := New(BandMapEntryPointer);

  LastBandMapEntryRecord^.NextEntry := BandMapEntryRecord;

  BandMapEntryRecord^.Call := CompressedCall;
  BandMapEntryRecord^.Frequency := Frequency;
  BandMapEntryRecord^.QSXOffset := QSXOffset;
  BandMapEntryRecord^.StatusByte := StatusByte;
  BandMapEntryRecord^.bmBand := Band;
  BandMapEntryRecord^.bmMode := Mode;
  BandMapEntryRecord^.Source := Source;
  BandMapEntryRecord^.NextEntry := nil;

end;

procedure SaveBandMap;

{ Saves the band map data to BandMapFileName }

var
  i                                     : integer;
  Spot                                  : TSpotRecord;
  h                                     : HWND;
begin
  if not tOpenFileForWrite(h, TR4W_BANDMAPBIN_FILENAME) then Exit;
  if SpotsList.Count > 0 then
  begin
    sWriteFile(h, BandMapFileVersion, SizeOf(BandMapFileVersion));
    sWriteFile(h, SpotsList.Count, SizeOf(SpotsList.Count));
    for i := 0 to SpotsList.Count - 1 do
    begin
      Spot := SpotsList.Get(i);
      sWriteFile(h, Spot, SizeOf(TSpotRecord));
    end;
  end;
  CloseHandle(h);

end;

procedure LoadBandMap;
{ Loads band map data from BandMapFileName.  Please only call when the
  program has just started and there isn't any possibility of any band
  map information already being there. }
label
  1;
var
  TempChar                              : Char;
  i                                     : integer;
  c                                     : integer;
  Spot                                  : TSpotRecord;
  h                                     : HWND;
  lpNumberOfBytesRead                   : Cardinal;
begin
  if not TF.tOpenFileForRead(h, TR4W_BANDMAPBIN_FILENAME) then Exit;
  Windows.ReadFile(h, TempChar, SizeOf(TempChar), lpNumberOfBytesRead, nil);
  if lpNumberOfBytesRead <> SizeOf(TempChar) then goto 1;
  if TempChar <> BandMapFileVersion then goto 1;
  Windows.ReadFile(h, c, SizeOf(SpotsList.Count), lpNumberOfBytesRead, nil);
  if c > 0 then
  begin
    for i := 1 to c do
    begin
      ReadFile(h, Spot, SizeOf(TSpotRecord), lpNumberOfBytesRead, nil);
      if lpNumberOfBytesRead = SizeOf(TSpotRecord) then SpotsList.AddSpot(Spot, False);
    end;
  end;
  1: CloseHandle(h);
end;

procedure GetBandMapDisplayInfo(var MaxEntriesPerPage: integer; var NumberBandMapRows: integer);

begin

  NumberBandMapRows := 1000; //(bf.ClientHeight - 5) div 15 ;
  MaxEntriesPerPage := 1000; //((bf.Width - 0) div 125) * NumberBandMapRows;
  Exit;
  {
        if BandMapWindowRY = 43 then //KK1L: 6.64 43 line screen I assume?
           begin
              if (MultiInfoMessage = '') then
                 begin
                    MaxEntriesPerPage := 85;
                    NumberBandMapRows := 17;
                 end
              else
                 begin
                    MaxEntriesPerPage := 65;
                    NumberBandMapRows := 13;
                 end
           end

        else //KK1L: 6.64 50 line screen

           begin
              if (MultiInfoMessage = '') then
                 begin

                    NumberBandMapRows := bf.Height div 19;
                    MaxEntriesPerPage := ((bf.Width - 30) div 130) * NumberBandMapRows;
                 end
              else
                 begin
                    MaxEntriesPerPage := 100;
                    NumberBandMapRows := 20;
                 end;
           end;
  }
end;

procedure UpdateBlinkingBandMapCall;

begin
  if not BandMapEnable then Exit;

  if BandMapBlinkingCallRecord <> nil then
    with BandMapBlinkingCallRecord^ do
    begin
      StatusByte := StatusByte and $C0;
      StatusByte := (BandMapDecayTime and $3F) or StatusByte;
    end;

  DisplayBandMap;
end;


procedure UpdateTenMinuteDate(Band: BandType; Mode: ModeType);   //n4af 4.40.9

begin
  if (Band <> TenMinuteTime.Band) or (Mode <> TenMinuteTime.Mode) then
  begin
    TenMinuteTime.Band := Band;
    TenMinuteTime.Mode := Mode;
    TenMinuteTime.Time := GetTickCount;
  end;
end;


procedure CalculateNumberVisibleBandMapEntries(var NumberVisibleBandMapEntries: integer;
  var CursorEntryNumber: integer;
  StartAtTop: boolean);

{ New in 6.49 }
{ Compute number of band map entries and which entry number the
  BandMapCursorData (global variable) resides at. }

var
  Band, StartBand, StopBand             : BandType;
  Mode, StartMode, StopMode             : ModeType;
  BandMapEntryRecord                    : BandMapEntryPointer;

begin
  if BandMapAllBands then
  begin
    if VHFBandsEnabled then {KK1L: 6.64 Keep band map within contest limits}
    begin
      StartBand := Band160;
      StopBand := Band2;
    end
    else
    begin
      StartBand := Band160;
      StopBand := Band12; {KK1L: 6.65 fixes WARC display enable}
    end;
  end
  else
  begin
    StartBand := BandMapBand;
    StopBand := BandMapBand;
  end;

  if BandMapAllModes then
  begin
    StartMode := CW;
    StopMode := Phone;
  end
  else
  begin
    StartMode := BandMapMode;
    StopMode := BandMapMode;
  end;

  NumberVisibleBandMapEntries := 0;
  CursorEntryNumber := 0;

  if StartAtTop then
    BandMapCursorData := BandMapFirstEntryList[StartBand, StartMode];

  FoundCursor := False;

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin
      if (not WARCBandsEnabled) and
        ((Band = Band30) or (Band = Band17) or (Band = Band12)) then
        Continue; {KK1L: 6.64 Keep band map within contest limits}

      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        if ((BandMapEntryRecord^.StatusByte and $40) <> 0) and BandMapDupeDisplay then
        begin {entry is a dupe and we are displaying dupes }

                {wli ???????? ?? nil BandMapCursorData}
          if BandMapCursorData <> nil then
            if BandMapEntryRecord^.Frequency = BandMapCursorData^.Frequency then
            begin
              BandMapCursorData := BandMapEntryRecord;
              FoundCursor := True;
            end;
          if not FoundCursor then
            inc(CursorEntryNumber);
          inc(NumberVisibleBandMapEntries);
        end

        else
          if ((BandMapEntryRecord^.StatusByte and $40) = 0) then
          begin {KK1L: 6.64 entry is not a dupe so just check it}

                  {wli ???????? ?? nil BandMapCursorData}
            if BandMapCursorData <> nil then
              if BandMapEntryRecord^.Frequency = BandMapCursorData^.Frequency then
              begin
                BandMapCursorData := BandMapEntryRecord;
                FoundCursor := True;
              end;
            if not FoundCursor then
              inc(CursorEntryNumber);
            inc(NumberVisibleBandMapEntries);
          end;
        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;

  if not FoundCursor then
    {KK1L: 6.64 covers the case of the cursor on a dupe when BandMapDupeDisplay is toggled FALSE}
    {      Really it just finds the first appropriate entry to display at entry zero}
    {      It covers cases of single band, all bands, all modes, all bands and modes}
  begin
    CursorEntryNumber := 0;
    GetRecordForBandMapCursor(BandMapCursorData, CursorEntryNumber);
  end;

end;

function GetRecordForBandMapCursor(var Entry: BandMapEntryPointer; CursorEntryNumber: integer): boolean;
{ KK1L: 6.64 Rewritten as function for possible multiple use. Code updated to work properly }
{       when displaying dupes or not.                                                  }
{ KK1L: 6.65 CursorEntryNumber did not need to be "pass by reference". Changed to "pass by value"}
label
  1, 2;
var
  EntryNumber                           : integer;
  FoundRecord                           : boolean;
  Band {, StartBand, StopBand}          : BandType;
  Mode {, StartMode, StopMode}          : ModeType;

begin

  tSetStartStopBandMode;
  {
    if BandMapAllBands then
      begin
        if VHFBandsEnabled then //KK1L: 6.64 Keep band map within contest limits
          begin
            StartBand := Band160;
            StopBand := Band2;
          end
        else
          begin
            StartBand := Band160;
            StopBand := Band12; //KK1L: 6.65 fixes WARC display enable
          end;
      end
    else
      begin
        StartBand := BandMapBand;
        StopBand := BandMapBand;
      end;

    if BandMapAllModes then
      begin
        StartMode := CW;
        StopMode := Phone;
      end
    else
      begin
        StartMode := BandMapMode;
        StopMode := BandMapMode;
      end;
  }
  EntryNumber := 0;
  GetRecordForBandMapCursor := False;
  FoundRecord := False;

  for Band := StartBand to StopBand do
  begin
    for Mode := StartMode to StopMode do
    begin

      if (not WARCBandsEnabled) and
        ((Band = Band30) or (Band = Band17) or (Band = Band12)) then
        Continue; {KK1L: 6.64 Keep band map within contest limits}

      Entry := BandMapFirstEntryList[Band, Mode];
      while Entry <> nil do
      begin

        if (EntryNumber = CursorEntryNumber) then
        begin {KK1L: 6.64 found a cursor match. Get Entry^ in synch then set BandMapCursorData}
                  //          if (not BandMapDupeDisplay) then {KK1L: 6.64 if not displaying dupes find the next non-dupe}
                  //            while ((Entry^.StatusByte and $40) <> 0)
                  //              and (Entry <> nil) do Entry := Entry^.NextEntry;

          if BandMapDupeDisplay = False then
          begin
            1: if (Entry^.StatusByte and $40) <> 0 then
            begin
              Entry := Entry^.NextEntry;
              if Entry <> nil then goto 1;
            end;
          end;

          if (Entry <> nil) then
          begin {KK1L: 6.64 Only set data if not nil}
            BandMapCursorData := Entry;
            GetRecordForBandMapCursor := True;
            FoundRecord := True;
            Exit; {KK1L: 6.64 Found a match. Let's get out of here}
          end;
          Break; {KK1L: 6.64 Ran out of entries. Jump out of WHILE Entry <> nil to next Mode/Band}
        end

        else {KK1L: 6.64 not a cursor match. Go to next keeping Entry^ and EntryNumber in synch with display}
        begin
          if BandMapDupeDisplay = False then
          begin
            2: if (Entry^.StatusByte and $40) <> 0 then
            begin
              Entry := Entry^.NextEntry;
              if Entry <> nil then goto 2;
            end;
          end;

                  //          if (not BandMapDupeDisplay) then {KK1L: 6.64 if not displaying dupes find the next non-dupe}
                  //            while ((Entry^.StatusByte and $40) <> 0) and (Entry <> nil) do
                  //              Entry := Entry^.NextEntry; {KK1L: 6.64 non-dupe of current cursor}

          if Entry <> nil then {KK1L: 6.64 Only increment if not starting a new band/mode}
          begin
            Entry := Entry^.NextEntry;
            inc(EntryNumber);
          end;
        end;

      end;
    end;
  end;
end;

procedure DecrementQTCCount(Call: CallString; Count: integer);

var
  Station                               : integer;
//  CompressedCall                   : EightBytes;

begin
//  BigCompressFormat(Call, CompressedCall);

  if (NumberQTCStations = 0) or (Count = 0) then Exit;

  for Station := 0 to NumberQTCStations - 1 do
//    if BigCompressedCallsAreEqual(QTCDataArray^[Station].Call, CompressedCall) then
    if QTCDataArray^[Station].Call = Call then
      while (QTCDataArray^[Station].NumberQTCs > 0) and (Count > 0) do
      begin
        dec(QTCDataArray^[Station].NumberQTCs);
        dec(Count);
      end;

end;


procedure OutputQSOorMultStatusString(OutputString_Milt: ShortString {Str160});

//var
 // Cursor                                : integer;

begin
  GetRidOfPostcedingSpaces(OutputString_Milt);

  //   FRM.MultiplierInformationWindow.Lines.Add(OutputString_Milt);

  //{WLI}    IF WhereX > 1 THEN WriteLn;     { Added in 6.28 }

end;


procedure DisplayUserInfo(Call: CallString);

var
  data                                  : DataBaseEntryRecord;
  TempString, InfoString, Command       : Str40;
  CustomString                          : ShortString {str40};
  Zone                                  : integer;
  FoundCall                             : boolean;
  Heading                               : integer;
  //qe                                   : pChar;
  //pstr                                 : str80;

begin
  if UserInfoShown = NoUserInfo then Exit;
  if Call = '' then Exit;
  FoundCall := CD.GetEntry(Call, data);

  Windows.ZeroMemory(@InfoString, SizeOf(InfoString));
//  InfoString := '';

  case UserInfoShown of
    NameInfo:
      if FoundCall then
        InfoString := data.mName;
    QTHInfo:
      if FoundCall then
        InfoString := data.QTH;
    CheckSectionInfo:
      if FoundCall then
        InfoString := data.Check + data.Section;
    SectionInfo:
      if FoundCall then
        InfoString := data.Section;
    OldCallInfo:
      if FoundCall then
        InfoString := data.OldCall;
    FocInfo:
      if FoundCall then
        InfoString := data.FOC;
    GridInfo:
      if FoundCall then
      begin
        InfoString := data.Grid;

        if (MyGrid <> '') and LooksLikeAGrid(data.Grid) then
        begin
              //          SaveSetAndClearActiveWindow(BeamHeadingWindow);
          Heading := round(GetBeamHeading(MyGrid, data.Grid));
              //          Write(data.Grid, ' at ', Heading, '?');
                                   //          RestorePreviousWindow;
        end;
      end;

    CQZoneInfo:
      if FoundCall and (data.CQZone <> '') then
        InfoString := data.CQZone
      else
      begin
        Zone := ctyGetCQZone(Call);
        if Zone > 0 then
          Str(Zone, InfoString);
      end;

    ITUZoneInfo:
      if FoundCall and (data.ITUZone <> '') then
        InfoString := data.ITUZone
      else
      begin
        Zone := ctyGetITUZone(Call);
        if Zone > 0 then
          Str(Zone, InfoString);
      end;

    User1Info:
      if FoundCall then
        InfoString := data.User1;
    User2Info:
      if FoundCall then
        InfoString := data.User2;
    User3Info:
      if FoundCall then
        InfoString := data.User3;
    User4Info:
      if FoundCall then
        InfoString := data.User4;
    User5Info:
      if FoundCall then
        InfoString := data.User5;

    CustomInfo:
      begin
        InfoString := '';
        CustomString := CustomUserString;

        while CustomString <> '' do
        begin
          Command := RemoveFirstString(CustomString);

          if Command = 'CQZONE' then
            if FoundCall and (data.CQZone <> '') then
              InfoString := InfoString + data.CQZone + ' '
            else
            begin
              Zone := ctyGetCQZone(Call);

              if Zone > 0 then
              begin
                Str(Zone, TempString);
                InfoString := InfoString + TempString + ' ';
              end;
            end;

          if Command = 'ITUZONE' then
            if FoundCall and (data.ITUZone <> '') then
              InfoString := InfoString + data.ITUZone + ' '
            else
            begin
              Zone := ctyGetITUZone(Call);

              if Zone > 0 then
              begin
                Str(Zone, TempString);
                InfoString := InfoString + TempString + ' ';
              end;
            end;

          if Command = 'NAME' then
            if FoundCall and (data.mName <> '') then
              InfoString := InfoString + data.mName + ' ';

          if Command = 'QTH' then
            if FoundCall and (data.QTH <> '') then
              InfoString := InfoString + data.QTH + ' ';

          if Command = 'SECTION' then
            if FoundCall and (data.Section <> '') then
              InfoString := InfoString + data.Section + ' ';

            { If they entered USER # instead of USER#, make it work - 6.75 }

          if Command = 'USER' then
          begin
            Command := RemoveFirstString(CustomString);

            if (Command >= '1') and (Command <= '5') then
            begin
              case Command[1] of
                '1':
                  if FoundCall and (data.User1 <> '') then
                    InfoString := InfoString + data.User1 + ' ';
                '2':
                  if FoundCall and (data.User2 <> '') then
                    InfoString := InfoString + data.User1 + ' ';
                '3':
                  if FoundCall and (data.User3 <> '') then
                    InfoString := InfoString + data.User1 + ' ';
                '4':
                  if FoundCall and (data.User4 <> '') then
                    InfoString := InfoString + data.User1 + ' ';
                '5':
                  if FoundCall and (data.User5 <> '') then
                    InfoString := InfoString + data.User1 + ' ';
              end;
            end
            else
              CustomString := Command + ' ' + CustomString; { put it back }
          end;

          if Command = 'USER1' then
            if FoundCall and (data.User1 <> '') then
              InfoString := InfoString + data.User1 + ' ';

          if Command = 'USER2' then
            if FoundCall and (data.User2 <> '') then
              InfoString := InfoString + data.User2 + ' ';

          if Command = 'USER3' then
            if FoundCall and (data.User3 <> '') then
              InfoString := InfoString + data.User3 + ' ';

          if Command = 'USER4' then
            if FoundCall and (data.User4 <> '') then
              InfoString := InfoString + data.User4 + ' ';

          if Command = 'USER5' then
            if FoundCall and (data.User5 <> '') then
              InfoString := InfoString + data.User5 + ' ';

          if Command = 'GRID' then
            if FoundCall and (data.Grid <> '') then
            begin
              InfoString := InfoString + data.Grid + ' ';

                  //              if (MyGrid <> '') and LooksLikeAGrid(data.Grid) then
                  //              begin
                  //                SaveSetAndClearActiveWindow(BeamHeadingWindow);
                  //                Heading := round(GetBeamHeading(MyGrid, data.Grid));
                  //                Write(data.Grid, ' at ', Heading, '?');
                  //    SetTR4WWindowText(BeamHeadingWindowHandle, data.Grid+ ' at '+ inttostr(Heading)+ '*');
                  //                RestorePreviousWindow;
                  //              end;
            end;

          if Command = 'FOC' then
            if FoundCall and (data.FOC <> '') then
         //   begin
              InfoString := InfoString + data.FOC + ' ';
        {       pStr := InfoString;
               qe := @pStr;
               QuickDisplay(qe);
               end;       }
          if Command = 'CHECK' then
            if FoundCall and (data.Check <> '') then
              InfoString := InfoString + data.Check + ' ';

          if Command = 'OLDCALL' then
            if FoundCall and (data.OldCall <> '') then
              InfoString := InfoString + data.OldCall + ' ';

          if Command = 'TENTEN' then
            if FoundCall and (data.TENTEN <> '') then
              InfoString := InfoString + data.TENTEN + ' ';
        end;
      end;

  end;

  if InfoString <> '' then
  begin
      //         while length(InfoString) < 32 do
      //            InfoString := ' ' + InfoString + ' ';

    SetMainWindowText(mweUserInfo, @InfoString[1]);

      //         Write(InfoString);
  end
  else
    SetMainWindowText(mweUserInfo, nil);

  //  RestorePreviousWindow;
end;

function RTTYInverse(InputString: string): string;

var
  Address                               : integer;

begin
  if InputString = '' then
  begin
    RTTYInverse := '';
    Exit;
  end;

  for Address := 0 to length(InputString) do
    case InputString[Address] of
      'E': InputString[Address] := '3';
      'A': InputString[Address] := '-';
      'S': InputString[Address] := ' ';
      'I': InputString[Address] := '8';
      'U': InputString[Address] := '7';
      'D': InputString[Address] := '$';
      'R': InputString[Address] := '4';
      'J': InputString[Address] := '''';
      'N': InputString[Address] := ',';
      'F': InputString[Address] := '!';
      'C': InputString[Address] := ':';
      'K': InputString[Address] := '(';
      'T': InputString[Address] := '5';
      'Z': InputString[Address] := '"';
      'L': InputString[Address] := ')';
      'W': InputString[Address] := '2';
      'H': InputString[Address] := '#';
      'Y': InputString[Address] := '6';
      'P': InputString[Address] := '0';
      'Q': InputString[Address] := '1';
      'O': InputString[Address] := '9';
      'B': InputString[Address] := '?';
      'G': InputString[Address] := '@';
      'M': InputString[Address] := '.';
      'X': InputString[Address] := '/';
      'V': InputString[Address] := ';';

      '3': InputString[Address] := 'E';
      '-': InputString[Address] := 'A';
      ' ': InputString[Address] := 'S';
      '8': InputString[Address] := 'I';
      '7': InputString[Address] := 'U';
      '$': InputString[Address] := 'D';
      '4': InputString[Address] := 'R';
      '''': InputString[Address] := 'J';
      ',': InputString[Address] := 'N';
      '!': InputString[Address] := 'F';
      ':': InputString[Address] := 'C';
      '(': InputString[Address] := 'K';
      '5': InputString[Address] := 'T';
      '"': InputString[Address] := 'Z';
      //{WLI-dup}            '(': InputString [Address] := 'L';
      '2': InputString[Address] := 'W';
      '#': InputString[Address] := 'H';
      '6': InputString[Address] := 'Y';
      '0': InputString[Address] := 'P';
      '1': InputString[Address] := 'Q';
      '9': InputString[Address] := 'O';
      '?': InputString[Address] := 'B';
      '@': InputString[Address] := 'G';
      '.': InputString[Address] := 'M';
      '/': InputString[Address] := 'X';
      ';': InputString[Address] := 'V';
    end;

  RTTYInverse := InputString;
end;

procedure UpdateK1EAStationInfo(Field: K1EAStationInfoFieldType;
  StationIDChar: Char;
  MessageString: ShortString {Str20});

var
  Freq                                  : LONGINT;
  {Index,} Result                         : integer;
  //TempString                            : Str20;
  Band                                  : BandType;
  Mode                                  : ModeType;

begin
  GetRidOfPostcedingSpaces(MessageString);
  Val(MessageString, Freq, Result);

  if Result <> 0 then
  begin
      //{WLI}        SendMorse ('ooops');
    Exit;
  end;

  Band := NoBand;

  CalculateBandMode(Freq, Band, Mode);

  if Band = NoBand then
    Exit;

  if Field = Pass then
    K1EAMultiInfo[Band].PassFreq := Freq;

  if Field = Run then
    K1EAMultiInfo[Band].RunFreq := Freq;
end;

procedure WindInit;

//var
 // Band                                  : BandType;
 // Mode                                  : ModeType;
begin
  {
  for Band := Band160 to AllBands do
    for Mode := CW to Both do
    begin
      if MultiStatus[Band, Mode] <> nil then
        Dispose(MultiStatus[Band, Mode]);
      MultiStatus[Band, Mode] := nil;
    end;
    }
  MarkTime(TenMinuteTime.Time);
end;

procedure DispalayDupe;
begin
  Format(QuickDisplayBuffer, TC_ISADUPE, @CallWindowString[1]);

//  DispalayB4(SW_HIDE);
  QuickDisplay(QuickDisplayBuffer);
  if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
//  SendMessage(wh[mweCall], EM_SETSEL, 0, -1);
//  EscapeDeletedCallEntry := CallWindowString;
  tCleareCallWindow;
end;

procedure DispalayB4(nCmdShow: integer);
begin
  if tB4IndicatorPrevState = nCmdShow then Exit;
  tB4IndicatorPrevState := nCmdShow;
  Windows.ShowWindow(wh[mweQSOB4Status], nCmdShow);
end;

procedure DispalayLogGridLines;
var
  Style                                 : integer;
begin
  if tShowGridlines then
    Style := LVS_EX_GRIDLINES or LVS_EX_FULLROWSELECT
  else
    Style := LVS_EX_FULLROWSELECT;

  ListView_SetExtendedListViewStyle(wh[mweEditableLog], Style);
  Windows.SetWindowLong(wh[mweEditableLog], GWL_STYLE, $5000A005);

  CheckEditableWindowHeight;
end;

procedure DispalayNewMult(nCmndShow: integer);
begin
  if nCmndShow = tNewMultIndicatorPrevState then Exit;
  tNewMultIndicatorPrevState := nCmndShow;
  Windows.ShowWindow(wh[mweNewMultStatus], nCmndShow);
end;

procedure DisplayLocalTime(Country: Word);
label
  1;
var
//  i                                     : integer;
  UTC, LOCAL                            : SYSTEMTIME;
  //Offset                                : LONGINT;
//  p                                     : PChar;
 // SummerTimeIncrementation              : integer;
 // r                                     : integer;
  TZ                                    : TIME_ZONE_INFORMATION;
begin


  if tLocalTimePrevState = Country then Exit;
  tLocalTimePrevState := Country;

  if Country = UNKNOWN_COUNTRY then
  begin
    wsprintfBuffer[0] := #0;
    goto 1;
  end;
  GetSystemTime(UTC);
  Windows.ZeroMemory(@tz, SizeOf(tz));
  TZ.Bias := ctyGetCountryUTCOffset(Country);
  Windows.ZeroMemory(@LOCAL, SizeOf(LOCAL));
  if not SystemTimeToTzSpecificLocalTime(@tz, UTC, LOCAL) then
  begin
//    ShowSysErrorMessage('TZ');
  end;

//  SummerTimeIncrementation := 0;
//  if (UTC.wMonth > 3) and (UTC.wMonth < 11) then SummerTimeIncrementation := 1000;
//  r := round(ctyGetCountryUTCOffset(Country));
//  i := round(ctyGetCountryUTCOffset(Country) * -1000) + SummerTimeIncrementation;
//  IncSystemTime(UTC, 1 {const} * 6 {minuts} * 6 {hours/10} * i); //1 sec = 1000
{
  asm
  movzx eax,word ptr LOCAL.wDayOfWeek
  mov   eax,[eax*4+PCharDayTags]
  push  eax

  xor  eax ,eax

  mov ax,word ptr LOCAL.wMinute
  push eax

  mov ax,word ptr LOCAL.wHour
  push eax
  end;
  wsprintf(wsprintfBuffer, '%02u:%02u %s');

  asm add esp,20
  end;
}
  Format(wsprintfBuffer, '%02u:%02u %s', integer(LOCAL.wHour), integer(LOCAL.wMinute), PCharDayTags[LOCAL.wDayOfWeek]);
  1:
  SetMainWindowText(mweLocalTime, wsprintfBuffer);
end;


procedure DisplayBandMap;
begin
  // Diagnostic: trace every entry into DisplayBandMap so we can see who
  // is calling and what state the gates are in.  Useful for tracking
  // down "bandmap clears unexpectedly" symptoms (issue: bandmap-startup-clear).
  // Booleans rendered as 0/1 via Ord() to avoid pulling SysUtils.BoolToStr
  // through this unit's tangled uses chain.
  logger.Trace('[DisplayBandMap] enter: ' +
               'BandMapEnable=%d, BandMapWindowExists=%d, ' +
               'BandMapPreventRefresh=%d, ' +
               'BandMapBand=%d, BandMapMode=%d, ' +
               'BandMapAllBands=%d, BandMapAllModes=%d, ' +
               'BandMapDupeDisplay=%d, BandMapDisplayCQ=%d, ' +
               'BandMapMultsOnly=%d, WARCBandsEnabled=%d, VHFBandsEnabled=%d, ' +
               'FCount=%d',
    [Ord(BandMapEnable),
     Ord(tWindowsExist(tw_BANDMAPWINDOW_INDEX)),
     Ord(BandMapPreventRefresh),
     Ord(BandMapBand), Ord(BandMapMode),
     Ord(BandMapAllBands),
     Ord(BandMapAllModes),
     Ord(BandMapDupeDisplay),
     Ord(BandMapDisplayCQ),
     Ord(BandMapMultsOnly),
     Ord(WARCBandsEnabled),
     Ord(VHFBandsEnabled),
     SpotsList.Count]);
  if not BandMapEnable then
    begin
    logger.Trace('[DisplayBandMap] exit: BandMapEnable=False');
    Exit;
    end;
  if not tWindowsExist(tw_BANDMAPWINDOW_INDEX) then
    begin
    logger.Trace('[DisplayBandMap] exit: bandmap window does not exist');
    Exit;
    end;
//  if  BandMapPreventRefresh then  Exit;             // GAV  4.45.6
  SpotsList.Display;
  end;

 procedure NextBandMapEntry;
var
  //BandMapEntryRecord                    : BandMapEntryPointer;
 // NumberEntriesDisplayed                : integer;
  Band                                  : BandType;
 // Mode                                  : ModeType;
  CC                                    : integer;
 // CurCursorPosData                      : integer;
 // numberbandentries                     : integer;
  //i: integer;
  j                                  : integer;
  Spot                                  : TSpotRecord;
  //d                                     : pChar;
  //str1                                   : str10;

begin
   TempSpot.FBand := NoBand;
              BMp := 0;
  //            tLB_SETCURSEL(BandMapListBox, 0);
  CC := Windows.SendMessage(BandMapListBox, LB_GETCOUNT, 0, 0);
    if CC = LB_ERR then Exit;
     if TwoRadioMode and QSYInactiveRadio then
      Band := InactiveRadioptr.BandMemory
       else
        Band := ActiveRadioptr.BandMemory;

  //k := Windows.SendMessage(BandMapListBox, LB_GETCURSEL, 0, 0);   // K contains real cursor displacement from top (0)
 //  i := GetBMSelItemData; //SendMessage(BandMapListBox, LB_GETITEMDATA, tLB_GETCURSEL(BandMapListBox), 0);
//  if k = LB_ERR then Exit;

//  Spot := SpotsList.Get(j);



if (K = -1) or (k > CC) then
k := 0;
    for j := k to CC do      // loop thru bm entries looking for match to band and mode
     begin
     CC := Windows.SendMessage(BandMapListBox, LB_GETCOUNT, 0, 0);     // Current Cursor
      Spot := SpotsList.Get(j);                                       // get current spot
   //   GetBandMapBandModeFromFrequency(TempSpot.FFrequency, TempSpot.FBand, TempSpot.FMode);
      CallWindowString := Spot.FCall;
      SetOpMode(SEARCHAndPOUNCEOpMode);
      logger.info('[NEXTBM] CALL = '+ SPOT.FCALL);
      logger.info('Freq = ' + IntToStr(Spot.ffrequency));
      if (Spot.FBand =  InactiveRadioptr.BandMemory) and (Spot.FMode = ActiveMode) and (QSYInactiveRadio) then
       begin
        logger.Info('Enter NextBandMap INACTIVE-Radio: ' + spot.fcall );
        LOGGER.INFO('Freq = ' + IntToStr(Spot.ffrequency));
        PutCallToCallWindow(OnDeckCall);
        TuneRadioToSpot(Spotslist.Get(k), InActiveRadio);
        inc(k);
        break;
       end
       else
      if (Spot.FBand = ActiveRadioptr.BandMemory) and (Spot.FMode = ActiveMode) then
      if not (QSYInactiveRadio) then
       begin
         logger.info('[NEXTBM-Active] CALL = '+ SPOT.FCALL);
         LOGGER.INFO('Freq = ' + IntToStr(Spot.ffrequency));
         PutCallToCallWindow(CallWindowString);
         TuneRadioToSpot(Spotslist.Get(j), ActiveRadio);
         inc(k);
         break;
     end ;


       if j = k then
       inc(k);

          if k > CC then
           begin
             k := 0;
             CC := Windows.SendMessage(BandMapListBox, LB_GETCOUNT, 0, 0);
           end;
       end;     // end loop
           if k > CC-1 then
           begin
             k := 0;
             CC := Windows.SendMessage(BandMapListBox, LB_GETCOUNT, 0, 0);
           end;

end;     // end procedure

procedure BMFirst;
begin
              BMp := 0;
              tLB_SETCURSEL(BandMapListBox, 0);

end;

procedure DisplayBandMap_proc;
var

  BandMapEntryRecord                    : BandMapEntryPointer;
  NumberEntriesDisplayed                : integer;
  Band                                  : BandType;
  Mode                                  : ModeType;
  CurrentCursorPos                      : integer;
  CurCursorPosData                      : integer;
  Caption                               : string;
  //  CallSignString                   : CallString;

begin

  if not BandMapEnable then Exit;
  if (not DisplayBandMapEnable) then Exit;

  //  tr4w_NeedToBlink := False;         //n4af  4.93.4


  CurCursorPosData := GetBMSelItemData;
  // Delphi 7 does not zero stack-allocated locals. Without this default,
  // CurrentCursorPos was only assigned inside the band/mode/entry loops
  // when an entry matched CurCursorPosData -- and was then passed to
  // tLB_SETCURSEL unconditionally at the bottom of the procedure. If no
  // entry matched (bandmap repopulated, prior selection expired, dupe
  // filter toggled, frequency walked off) the listbox cursor landed on
  // whatever was on the stack. -1 is the LB_SETCURSEL convention for
  // "no selection".
  CurrentCursorPos := -1;

  //  if not DoNotAddToBandMap then
  begin
    tSetWindowRedraw(BandMapListBox, False);
    SendMessage(BandMapListBox, LB_RESETCONTENT, 0, 0);
    SendMessage(BandMapListBox, LB_INITSTORAGE, 50, 0);
  end;
  BandMapBlinkingCall := '';
  tSetStartStopBandMode;

  NumberEntriesDisplayed := 0;

  Caption := 'Bandmap ' + BandStringsArray[StartBand] + ModeStringArray[StartMode] + ' - ';

  if (not WARCBandsEnabled) and (StopBand = Band12) then
    Caption := Caption + BandStringsArray[Band10] + ModeStringArray[StopMode]
  else
    Caption := Caption + BandStringsArray[StopBand] + ModeStringArray[StopMode];

  if BandMapDupeDisplay then
    Caption := Caption + ' DUPES ON '
  else
    Caption := Caption + ' DUPES OFF';

  tSetWindowText(tr4w_WindowsArray[tw_BANDMAPWINDOW_INDEX].WndHandle, Caption);

  for Band := StartBand to StopBand do
    for Mode := StartMode to StopMode do
    begin

      if ((not WARCBandsEnabled)  or (Band = Band30) or (Band = Band17) or (Band = Band12)) then Continue;

      BandMapEntryRecord := BandMapFirstEntryList[Band, Mode];

      while BandMapEntryRecord <> nil do
      begin
        with BandMapEntryRecord^ do
        begin
          if (not BandMapDupeDisplay) and ((BandMapEntryRecord^.StatusByte and $40) <> 0) then
          begin
            BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
            Continue;
          end;
                //                if not DoNotAddToBandMap then
          SendMessage(BandMapListBox, LB_ADDSTRING, 0, integer(BandMapEntryRecord));

          if (Abs(BandMapEntryRecord^.Frequency - BandMapCursorFrequency) <= BandMapGuardBand) then
          begin
            if not CQLabel(BandMapExpandedString(BandMapEntryRecord^.Call)) then
            begin
            SendMessage(BandMapListBox, LB_GETITEMRECT, wParam(NumberEntriesDisplayed), lParam(@tBlinkerRect));
      //         tr4w_NeedToBlink := False;     //n4af 4.93.4
            end;
          end;

          if BandMapEntryPointer(CurCursorPosData) = BandMapEntryRecord then
            CurrentCursorPos := NumberEntriesDisplayed;

          inc(NumberEntriesDisplayed);
        end;
        BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
      end;
    end;
  //  if (not DoNotAddToBandMap) or (tIvertedBlinker)  then
  begin
    tSetWindowRedraw(BandMapListBox, True);
    tLB_SETCURSEL(BandMapListBox, CurrentCursorPos);
    Windows.InvalidateRect(BandMapListBox, 0, False);
    tIvertedBlinker := False;
  end;
  NeedToSynchBandMap := False;
  //  DoNotAddToBandMap := False;
end;

procedure tDisplayAutoCQStatus;
var
  ID                                    : Str10;
begin
  Windows.ZeroMemory(@ID, SizeOf(ID));
  ID := KeyId(AutoCQMemory);
  Format(QuickDisplayBuffer, TC_REPEATING, @ID[1], AutoCQDelayTime);
  SetTextInQuickCommandWindow(QuickDisplayBuffer);
end;

procedure UpadateRadioStatus(rig: RadioPtr);
var
  //TempInt                               : integer;
  h                                     : HWND;
  dif                                   : integer;
begin

  with rig^ do
  begin
    h := tRadioInterfaceWndHandle;
    if h <> 0 then
    begin
          //          Windows.SetWindowText(InsertWindowHandle, inttopchar(CurrentStatus.PrevRITFreq));
          //          Windows.SetWindowText(OpModeWindowHandle, inttopchar(CurrentStatus.RITFreq));

      if CurrentStatus.PrevRITFreq <> CurrentStatus.RITFreq then
      begin
{$RANGECHECKS OFF}
       //SetDlgItemInt(h, 120, CurrentStatus.RITFreq, CurrentStatus.RITFreq < 0);
       SetDlgItemText(h, 120, RITFreqToPChar(CurrentStatus.RITFreq)); //FreqToPChar(CurrentStatus.RITFreq));
{$RANGECHECKS ON}
        CurrentStatus.PrevRITFreq := CurrentStatus.RITFreq;
      end;
      if CurrentStatus.PrevVFOStatus <> CurrentStatus.VFOStatus then
      begin
        if CurrentStatus.VFOStatus = VFOA then
        begin
          EnableWindowTrue(h, 102);
          EnableWindowFalse(h, 104);
        end;
        if CurrentStatus.VFOStatus = VFOB then
        begin
          EnableWindowTrue(h, 104);
          EnableWindowFalse(h, 102);
        end;
        if CurrentStatus.VFOStatus = vfoUnknown then
        begin
          EnableWindowTrue(h, 104);
          EnableWindowTrue(h, 102);
        end;
        CurrentStatus.PrevVFOStatus := CurrentStatus.VFOStatus;
      end;

      SetDlgItemText(h, 102, FreqToPChar(CurrentStatus.VFO[VFOA].Frequency));
      SetDlgItemText(h, 104, FreqToPChar(CurrentStatus.VFO[VFOB].Frequency));

          //              if (CurrentStatus.VFOA.Frequency = 0) or (CurrentStatus.VFOB.Frequency = 0) then SetDlgItemText(h, 120, nil)

      Windows.EnableWindow(Windows.GetDlgItem(h, 121), CurrentStatus.RIT);
      Windows.EnableWindow(Windows.GetDlgItem(h, 122), CurrentStatus.XIT);
      Windows.EnableWindow(Windows.GetDlgItem(h, 123), CurrentStatus.Split);
    end;

    Windows.SetWindowText(rig^.FreqWindowHandle, FreqToPChar(CurrentStatus.Freq));
//    rig.CurrentBand := rig.CurrentStatus.Band;
//    rig.CurrentMode := rig.CurrentStatus.Mode;

    if rig = ActiveRadioPtr then
    begin
      dif := Abs(CurrentStatus.Freq - LastDisplayedFreq);
      if LastDisplayedFreq <> 0 then
        if dif > AutoSAPEnableRate then
          if dif <= 10000 then
            if AutoSAPEnable and (OpMode = CQOpMode) then
             SetOpMode(SearchAndPounceOpMode);
               
                //      if tStatusEqualityCounter = StatusEquality then
//        if FilteredStatus.Freq <> 0 then
//          if (FilteredStatus.Band <> BandMemory[ActiveRadio {RadioOne}])
//            or (FilteredStatus.Mode <> ModeMemory[ActiveRadio {RadioOne}])
//            then
      begin
            //BandMapCursorFrequency := FilteredStatus.Freq;
        ActiveBand := FilteredStatus.Band;
        ActiveMode := FilteredStatus.Mode;

        DisplayBandMode(ActiveBand, ActiveMode, False);
        VisibleDupeSheetChanged := True;

        DisplayCodeSpeed;
        DisplayAutoSendCharacterCount;
        VisibleLog.ShowRemainingMultipliers; //wli
        ShowFMessages(0);
            //DoNotAddToBandMap := False;
      end;

    end;

    Exit;
      //      DoNotAddToBandMap := True;
    if ((ActiveRadio = RadioOne) and (rig = @Radio1)) or ((ActiveRadio = RadioTwo) and (rig = @Radio2)) then
    begin
      dif := Abs(CurrentStatus.Freq - LastDisplayedFreq);
      if LastDisplayedFreq <> 0 then
        if dif > AutoSAPEnableRate then
          if dif <= 10000 then
          begin
            if AutoSAPEnable and (OpMode = CQOpMode) then
              SetOpMode(SearchAndPounceOpMode);
          end;

//      if tStatusEqualityCounter = StatusEquality then
//        if FilteredStatus.Freq <> 0 then
//          if (FilteredStatus.Band <> BandMemory[ActiveRadio {RadioOne}])
//            or (FilteredStatus.Mode <> ModeMemory[ActiveRadio {RadioOne}])
//            then
      begin
            //BandMapCursorFrequency := FilteredStatus.Freq;
        ActiveBand := FilteredStatus.Band;
        ActiveMode := FilteredStatus.Mode;

        DisplayBandMode(ActiveBand, ActiveMode, False);
        VisibleDupeSheetChanged := True;

        DisplayCodeSpeed;
        DisplayAutoSendCharacterCount;
        VisibleLog.ShowRemainingMultipliers; //wli
        ShowFMessages(0);
            //DoNotAddToBandMap := False;
      end;

      if (({CurrentStatus}FilteredStatus.Freq <> BandMapCursorFrequency) or
        (BandMapMode <> ActiveMode)) and ({CurrentStatus}FilteredStatus.Freq <> 0) then
      begin
        BandMapCursorFrequency := {CurrentStatus} FilteredStatus.Freq;
        BandMapBand := ActiveBand;
        BandMapMode := ActiveMode;
        DisplayBandMap;
      end;

      if FrequencyMemoryEnable then
        FreqMemory[FilteredStatus.Band, FilteredStatus.Mode] := FilteredStatus.Freq;
    end;
  (*  start   REMOVECANDIDATE
//    LastDisplayedFreq[ActiveRadio] := FilteredStatus.Freq;

      {
          RadioOnTheMove[radioone] := False;
          RadioMovingInBandMode[radioone] := False;

          if FilteredStatus.Freq <> 0 then
             if (FilteredStatus.Freq <> LastDisplayedFreq[radioone]) or
                (FilteredStatus.Mode <> LastDisplayedMode) then //wli
                begin
                   if Abs(FilteredStatus.Freq - LastDisplayedFreq[radioone]) > AutoSAPEnableRate then
                      begin
                         RadioOnTheMove[radioone] := LastDisplayedFreq[radioone] <> 0;
                         //          if RadioOnTheMove[radioone] then if (AutoSAPEnable) and (OpMode = CQOpMode) then FRM.SetSAP;

                         RadioMovingInBandMode[radioone] := (FilteredStatus.Band = BandMemory[radioone]) and
                            (FilteredStatus.Mode = ModeMemory[radioone]) and (LastDisplayedFreq[radioone] <> 0);

                         //                        if RadioMovingInBandMode[radioone] then
                         //                           begin
                         //                              if (AutoSAPEnable) and (OpMode = CQOpMode) then SetOpMode(SearchAndPounceOpMode);

                         //                                          if ClearCallWindowAtSPMove then
                         //                                            if opmode = SearchAndPounceOpMode then if callwindowstring <> '' then
                         //                                              begin
                         //                                                tCleareCallWindow;
                         //                                                tCleareExchangeWindow;
                         //                                                setfocus(CallWindowHandle);
                         //                                                ExchangeHasBeenSent := False;
                         //                                                ClearCallWindowAtSPMove := true;
                         //                                              end;

                         //                           end;

                      end;

                   //         If this is the ActiveRadio, then I have some more things to do.

                   if ActiveRadio = radioone then
                      begin
                         if (FilteredStatus.Band <> BandMemory[radioone])
                            or (FilteredStatus.Mode <> ModeMemory[radioone])
                            then
                            if Radio1.TrackingEnable then
                               begin
                                  //            IF FilteredStatus.Band <> NoBand THEN
                                  ActiveBand := FilteredStatus.Band;
                                  //            IF FilteredStatus.Mode <> NoMode THEN
                                  ActiveMode := FilteredStatus.Mode;

                                  DisplayBandMode(ActiveBand, ActiveMode, False);
                                  VisibleDupeSheetChanged := True;

                                  DisplayCodeSpeed ;
                                  DisplayAutoSendCharacterCount;
                                  VisibleLog.ShowRemainingMultipliers; //wli
                                  ShowFMessages(0);
                               end;

                         //                     See what radio two might be up to

                         if TwoRadioState = TwoRadiosDisabled then // No 2nd radio
                            begin
                               if ((FilteredStatus.Freq <> BandMapCursorFrequency) or
                                  (BandMapMode <> ActiveMode)) and (FilteredStatus.Freq <> 0) then
                                  begin
                                     BandMapCursorFrequency := FilteredStatus.Freq;
                                     BandMapBand := ActiveBand;
                                     BandMapMode := ActiveMode;
                                     DisplayBandMap;
                                  end;
                            end
                         else
                            begin
                               if BandMapEnable then
                                  if ((FilteredStatus.Band = BandMapBand) and
                                     (FilteredStatus.Freq <> BandMapCursorFrequency) and
                                     (FilteredStatus.Freq <> 0)) or
                                     (RadioOnTheMove[radioone]) then //KK1L: 6.73 Consolidated logic
                                     begin
                                        BandMapCursorFrequency := FilteredStatus.Freq;
                                        BandMapBand := ActiveBand;
                                        BandMapMode := ActiveMode;
                                        DisplayBandMap;
                                     end;
                            end;
                      end
                   else
                      begin

                         //                  Okay, this isn't the active radio, but we might have
                         //                  something to do if the band map is active.  If we are
                         //                  tuning to new frequencies on this radio, then we are
                         //                  going to assume that it is appropriate for the band
                         //                  map on this band to be displayed!

                         // Guard: don't follow the inactive radio if it has not yet
                         // reported a real band/mode (NoBand/NoMode are uninitialized
                         // sentinels). Same defect as uRadioPolling.pas inactive branch.
                         if (TwoRadioState <> TwoRadiosDisabled) and BandMapEnable and
                            RadioOnTheMove[radioone] and
                            (FilteredStatus.Band <> NoBand) and
                            (FilteredStatus.Mode <> NoMode) then
                            begin
                               logger.Trace('[BMWriter LOGWIND:4935 inactive-FS] ' +
                                            'BandMapBand:=FS.Band=%d, BandMapMode:=FS.Mode=%d, FS.Freq=%d, ' +
                                            'TwoRadioState=%d, RadioOnTheMove[1]=%d',
                                            [Ord(FilteredStatus.Band), Ord(FilteredStatus.Mode),
                                             FilteredStatus.Freq, Ord(TwoRadioState),
                                             Ord(RadioOnTheMove[radioone])]);
                               BandMapBand := FilteredStatus.Band;
                               BandMapMode := FilteredStatus.Mode;
                               BandMapCursorFrequency := FilteredStatus.Freq;
                               DisplayBandMap;
                            end;
                      end;

                   //       DisplayFrequency(FilteredStatus, RadioOne);
 //                  LastDisplayedFreq[radioone] := FilteredStatus.Freq;

                   BandMemory[radioone] := FilteredStatus.Band;
                   ModeMemory[radioone] := FilteredStatus.Mode;

                   //wli -  what is 'freq'?!

                   //       IF FrequencyMemoryEnable THEN
                   //        FreqMemory[FilteredStatus.Band, FilteredStatus.Mode] := Freq;

                   //maybe?
                   if FrequencyMemoryEnable then
                      FreqMemory[FilteredStatus.Band, FilteredStatus.Mode] := FilteredStatus.Freq;

                end;
          LastDisplayedFreq[radioone] := FilteredStatus.Freq;
         }
         *)
  end;
end;

procedure tDispalyOnAirTime;
var
d              : Cardinal;
//OperatingTime                        : integer;
 // PreviousQSOTime                       : TQSOTime;
 // Switch : boolean;

 begin
  if (CallWinKeyDown) and (not Begin_QSO) then              // 4.115.3   dont start timeer until first entry
   begin
    Begin_QSO := True;
    StartCPU := Windows.GetTickCount;
   end;

if (T2 > 0)  then
 begin
   d := Windows.GetTickCount;
    if (d div 1000) mod 2 = 0 then
     SetMainWindowText(mweOnAirTimeCounter,MillisecondsToFormattedString(d - StartCPU, False)) ;     //  4.115.3
 end
   else
     SetMainWindowText(mweOnAirTimeCounter,MillisecondsToFormattedString(0, False))
//  SetMainWindowText(mweOnAirTimeCounter,MillisecondsToFormattedString(TimeSpentByBand[AllBands] * 1000, False));
end;


procedure tDispalyTimeFromLastQSO;      // n4af 4.35.5
{ Try keying on tElapsedTimeFromLastQSO.
Procedure modified by N4AF to also display total OFF TIME.
If it total elapsed drops, enter was pressed so
 save into var d2 contents of tElapsedTimeFromLastQSO on procedure exit to compare to value on entry.
set Constant T1 to length of break time
normally onairtime = elapse since firstSetMainWindowText(mweOnAirTimeCounter,MillisecondsToFormattedString(Windows.GetTickCount-StartCPU, False));  qso. But when elapsed > break, we must save the elapsed time and
subtract break time from it.
Then when elapsed next drops below break length, add saved elapsed to current elapsed.
}
var
  d                                    : Cardinal;
  k                                    : Cardinal;
  //l                                    : Cardinal;
  //TimeDifference                       : Integer;
 //n4af 4.35.5
 begin
 // 4.115.2 remove commented code below
 begin
 T2 := tElapsedTimeFromLastQSO;  // T2 = initial elapsed
 Start := True;
 end;

  d := Windows.GetTickCount - T2;
 //d := a;
 k := Windows.GetTickCount - tElapsedTimeFromLastQSO;     // time from last qso

  if (k div 1000) mod 2 = 0 then         // if 5 seconds elapsed
     SetMainWindowText(mweLastQSOTime, MillisecondsToFormattedString(k, False));     // display elapsed since last qso
     tDispalyOnAirTime;
{    if (k < T1) then
  begin
  if K < B then
  begin
  A := B;     // restore former K value

  end;
  if Gate then
  Gate := False;
  if C = 0 then
  D1 :=  D        // save previous K
    else
  D1 := b + c + e;


  if (d1 div 1000) mod 2 = 0 then         // if 2 seconds elapsed
  //       // display elapsed since last qso
      SetMainWindowText(mweOnAirTimeCounter, MillisecondsToFormattedString(TimeSpentByBand[AllBands] * 1000, False));
   b := K;  // last value of K before enter pressed

  end;

   if K > T1 then
   begin
   
   if not Gate then
   begin
   e := c;    // save old c value into var e  Snap last good K ONCE
   Gate := true;
   end;
  
 C := A;       // c points to the last K

end;
}
end;

procedure tDispalyMyComputerID;
begin
  CID_TWO_BYTES[0] := ComputerID;
  SetMainWindowText(mweComputerID, @CID_TWO_BYTES);
end;

procedure tDispalyPaddleAndFootSwitchStatus;
var
  TempBool                              : LongBool;
begin

  if not DoingPaddle then TempBool := False else TempBool := True;
 // Windows.EnableWindow(wh[mwePaddle], TempBool); //n4af 4.36.7

  if not tDoingFootSwitchEnable then TempBool := False else TempBool := True;
  Windows.EnableWindow(wh[mweFootSwitch], TempBool);
end;

procedure tDisplayCQTotal;
begin
  Format(wsprintfBuffer, TC_CQTOTAL, tRestartInfo.riCQTotalCounter);
  SetMainWindowText(mweCQTotal, wsprintfBuffer);
end;

function CQLabel(Callsign: CallString): boolean;
begin
  Result := False;
  if length(Callsign) < 3 then Exit;
  if (Callsign[1] = 'C') and (Callsign[2] = 'Q') and (Callsign[3] = '/') then Result := True;
end;

procedure old_UpadateRadioStatus(RadioPointer: RadioPtr);
//var
 // TempInt                               : integer;
  //h                                     : HWND;
begin
end;

procedure tSetStartStopBandMode;
begin
  if BandMapAllBands then
  begin
    if VHFBandsEnabled then
    begin
      StartBand := Band160;
      StopBand := Band2;
    end
    else
    begin
      StartBand := Band160;
      StopBand := Band12; // Band12 comes after Bands160-10
    end;
  end
  else
  begin
    StartBand := BandMapBand;
    StopBand := BandMapBand;
  end;

  if BandMapAllModes then
  begin
    StartMode := CW;
    StopMode := Phone;
  end
  else
  begin
    StartMode := BandMapMode;
    StopMode := BandMapMode;
  end;

end;

procedure DisplayCountryInformation(FileName: Str80; Call: CallString);

{ This procedure will go search through the file specified and if it
  finds an entry with the country ID for the callsign indicated, it
  will display the data contained after that line, until the next blank
  line if found (up to five lines).  The information will be displayed
  in the editable log window. }

//var
  //FileRead                              : Text;
  //CountryID                             : Str20;
  //FileString                            : Str80;
  //WhereY                                : integer;
begin
{  REMOVECANDIDATE
  //  if tr4w_WindowsArray[tr4w_LAST5WINDOW_INDEX].tr4w_WndHandle = 0 then Exit;
  if not OpenFileForRead(FileRead, FileName) then Exit;

  CountryID := CountryTable.GetCountryID(CountryTable.GetCountry(Call, True));

  strU(CountryID);
  WhereY := 1;
  while not Eof(FileRead) do
  begin
    ReadLn(FileRead, FileString);

    if UpperCase(FileString) = CountryID then
    begin
          //      SaveSetAndClearActiveWindow(EditableLogWindow);

      repeat
        ReadLn(FileRead, FileString);

        if FileString <> '' then
        begin
                //          if WhereX > 1 then WriteLn;
                //          Write(FileString);
                //          SendDlgItemMessage(tr4w_WindowsArray[tr4w_LAST5WINDOW_INDEX].tr4w_WndHandle, 101, LB_ADDSTRING, 0, integer(PChar(string(FileString))));
                //          SendMessage(_EditableLogWindow, LB_ADDSTRING, 0, integer(PChar(string(FileString))));
          inc(WhereY);
        end;

      until (WhereY = 5) or (FileString = '');

      Close(FileRead);
          //      RestorePreviousWindow;
      Exit;

    end;

  end;

  Close(FileRead);
}
end;

procedure FlashQickDisplay;
var
  i                                     : integer;
begin
//  Windows.AnimateWindow(wh[mweQuickCommand], 1000, AW_ACTIVATE or AW_VER_NEGATIVE);
  for i := 0 to 5 do
  begin
    Windows.EnableWindow(wh[mweQuickCommand], LongBool(i mod 2));
    Sleep(100);
  end;

  tFlashQDThreadID := 0;
end;

procedure ShowTourDuration;
var
  IntegerTime                           : integer;
begin
  if TourDuration = 0 then Exit;
  IntegerTime := UTC.wMinute mod TourDuration;
  Windows.SendMessage(TorDurationPrBarWindow, PBM_SETPOS, IntegerTime, 0);

  Format(TempBuffer2, TC_NEWTOUR, IntegerTime, TourDuration);

//  Windows.SetDlgItemText(ReminderDlgHandle, 102, TempBuffer2);
  Windows.SetWindowText(TorDurationWindow, TempBuffer2);

  if IntegerTime = 1 then
  begin
    SendMessage(TorDurationPrBarWindow, PBM_SETMARQUEE, wParam(False), 40);
    Windows.SetWindowLong(TorDurationPrBarWindow {GetDlgItem(ReminderDlgHandle, 101)}, GWL_STYLE, $50000001);
  end;

  if IntegerTime = 0 then
  begin
    if Sheet.tAutoReset then tClearDupesheet;
    if (Sheet.tAutoReset and MultReset) then tClearMultsheet; // 4.52.11
    SendMessage(TorDurationPrBarWindow, PBM_SETMARQUEE, wParam(True), 40);
    Windows.SetWindowLong(TorDurationPrBarWindow {GetDlgItem(ReminderDlgHandle, 101)}, GWL_STYLE, $50000009);
  end;
end;

procedure SetListViewColor(Window: TMainWindowElement);
//var rgb: cardinal;
begin
  if wh[Window] = 0 then Exit;
  ListView_SetTextBkColor(wh[Window], tr4wColorsArray[TWindows[Window].mweBackG]);
  ListView_SetBkColor(wh[Window], tr4wColorsArray[TWindows[Window].mweBackG]);
  ListView_SetTextColor(wh[Window], tr4wColorsArray[TWindows[Window].mweColor]);
  

//  Windows.SendMessage(wh[Window], LVM_REDRAWITEMS, 0, LinesInEditableLog - 1);
  Windows.InvalidateRect(wh[Window], nil, True);
end;

procedure UpadateMainWindow;
begin
  Windows.InvalidateRect(tr4whandle, nil, True);
end;

procedure UpadateAutoSend;
begin
  AutoSendEnable := AutoSendCharacterCount > 0;
  DisplayAutoSendCharacterCount;
end;


begin
  WindInit;
end.


