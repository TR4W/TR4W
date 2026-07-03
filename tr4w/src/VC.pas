
{
 Copyright Dmitriy Gulyaev UA4WLI 2015.
 This file is part of TR4W  (SRC)
 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.
 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT.
If not, ref:
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit VC;
interface

{$IMPORTEDDATA OFF}

uses

  Windows,
  Messages,
  Log4D,
  Version;

{$INCLUDE w.pas}



const
  tDebugMode                            = False;
  NEWER_DEBUG                           = False; // ny4i added this as tDebugMode changes too much.
  MMTTYMODE                             = True;


type

  EntryPointerListType = array[0..15000] of Pointer;
  EntryPointerListPtr = ^EntryPointerListType;

  PortType =
    (NoPort,
    Serial1,
    Serial2,
    Serial3,
    Serial4,
    Serial5,
    Serial6,
    Serial7,
    Serial8,
    Serial9,
    Serial10,
    Serial11,
    Serial12,
    Serial13,
    Serial14,
    Serial15,
    Serial16,
    Serial17,
    Serial18,
    Serial19,
    Serial20,
    Network,
    Parallel1,
    Parallel2,
    Parallel3
    );

  CountryModeType =
    (
    CQCountryMode, //DXCC+WAE
    ARRLCountryMode //DXCC ONLY
    );

  UDPType = (udpContactInfo, udpContactReplace, udpContactDelete, udpLookupInfo);
  LastEntryType = (letCallsign, letQTHString);

  TR4WDLGTEMPLATE = {packed } record
    Style: DWORD;
    dwExtendedStyle: DWORD;
    cdit: Word;
    X: SHORT;
    Y: SHORT;
    cx: SHORT;
    cy: SHORT;
    B1: Byte;
    B2: Byte;
    b3: Byte;
//    b4: Byte;
//    B5: Byte;
  end;

  TRichEditObject = record
    reLibModule: HMODULE;
    reUsers: Cardinal;
  end;

 ExchangeInformationRecord = record
    Age: boolean;
    Chapter: boolean;
    Check: boolean;
    ClassEI: boolean;
    FOCNumber: boolean;
    Kids: boolean;
    Name: boolean;
//    PostalCode: boolean;
    Power: boolean;
    Precedence: boolean;
    QSONumber: boolean;
    QTH: boolean;
    RandomChars: boolean;
    RST: boolean;
    TenTenNum: boolean;
    Zone: boolean;
    ZoneOrSociety: boolean;
  end;
  SCPIndexArrayType = array[0..36, 0..36] of longword {LONGINT n6tr} {LongWord {ua4wli};
  SCPIndexArrayPtr = ^SCPIndexArrayType;

  FourChar = array[0..3] of Char;
  TAdditionalMultByBand = (dmbbDefauld, dmbbAllBand);
  Yaesu5Bytes = array[0..4] of Byte;
  FileNameType = array[0..MAX_PATH - 1] of Char;
  OperatorType = array[0..10] of Char;
  ZoneModeType = (CQZoneMode, ITUZoneMode);

const

  MAINTR4WDLGTEMPLATE                   : TR4WDLGTEMPLATE =
    (Style: DS_MODALFRAME or DS_3DLOOK or WS_POPUP or WS_CAPTION or WS_SYSMENU or WS_THICKFRAME; dwExtendedStyle: WS_EX_DLGMODALFRAME or WS_EX_TOOLWINDOW);

  ZoneModeTypeSA                        : array[ZoneModeType] of PChar = ('CQ Zone', 'ITU Zone');

const
  tr4w_ClassName                        : array[0..4] of Char = ('T', 'R', '4', 'W', #0);
  CQPChar                               : array[0..2] of Char = ('C', 'Q', #0);
  MASKEVENT                             = False;
  OGLVERSION                            = False;
  K6VVA_WK_DEBUG                        = False;
  MORSERUNNER                           = False;
  ICOM_LONG_MODECOMMAND                 = True ;

// LANG is selected by passing -DLANG_xxx to DCC32 (e.g. -DLANG_RUS).
// Default is ENG when no LANG_xxx is defined, so local builds work unchanged.
{$IFDEF LANG_ENG}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_RUS}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_SER}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_ESP}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_MNG}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_POL}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_CZE}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_ROM}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_CHN}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_GER}{$DEFINE _LANG_SET}{$ENDIF}
{$IFDEF LANG_UKR}{$DEFINE _LANG_SET}{$ENDIF}
{$IFNDEF _LANG_SET}{$DEFINE LANG_ENG}{$ENDIF}

const
{$IFDEF LANG_ENG}  LANG = 'ENG';{$ENDIF}
{$IFDEF LANG_RUS}  LANG = 'RUS';{$ENDIF}
{$IFDEF LANG_SER}  LANG = 'SER';{$ENDIF}
{$IFDEF LANG_ESP}  LANG = 'ESP';{$ENDIF}
{$IFDEF LANG_MNG}  LANG = 'MNG';{$ENDIF}
{$IFDEF LANG_POL}  LANG = 'POL';{$ENDIF}
{$IFDEF LANG_CZE}  LANG = 'CZE';{$ENDIF}
{$IFDEF LANG_ROM}  LANG = 'ROM';{$ENDIF}
{$IFDEF LANG_CHN}  LANG = 'CHN';{$ENDIF}
{$IFDEF LANG_GER}  LANG = 'GER';{$ENDIF}
{$IFDEF LANG_UKR}  LANG = 'UKR';{$ENDIF}
{$IF LANG = 'ENG'}{$INCLUDE lang\tr4w_consts_eng.pas}{$IFEND}
{$IF LANG = 'RUS'}{$INCLUDE lang\tr4w_consts_rus.pas} {$IFEND}
{$IF LANG = 'SER'}{$INCLUDE lang\tr4w_consts_ser.pas}{$IFEND}
{$IF LANG = 'ESP'}{$INCLUDE lang\tr4w_consts_esp.pas}{$IFEND}
{$IF LANG = 'MNG'}{$INCLUDE lang\tr4w_consts_mng.pas}{$IFEND}
{$IF LANG = 'POL'}{$INCLUDE lang\tr4w_consts_pol.pas}{$IFEND}
{$IF LANG = 'CZE'}{$INCLUDE lang\tr4w_consts_cze.pas}{$IFEND}
{$IF LANG = 'ROM'}{$INCLUDE lang\tr4w_consts_rom.pas}{$IFEND}
{$IF LANG = 'CHN'}{$INCLUDE lang\tr4w_consts_chn.pas}{$IFEND}
{$IF LANG = 'GER'}{$INCLUDE lang\tr4w_consts_ger.pas}{$IFEND}
{$IF LANG = 'UKR'}{$INCLUDE lang\tr4w_consts_ukr.pas}{$IFEND}

{$IF tDebugMode}

const
  WINKEYDEBUG                           = False;
  tKeyerDebug                           = False;

  CWDEBUG                               = False;
  SCPDEBUG                              = False;
  MAKE_DEFAULT_VALUES                   = True;
{$IFEND}

  OZCR2008                              = False;
  LOGVERSION                            = 'v1.7'; // This is broken out below for comparison later on. Again, needlessly complex. de NY4I
  LOGVERSION1                           = 'v';
  LOGVERSION2                           = '1';
  LOGVERSION3                           = '.';
  LOGVERSION4                           = '7';     // ny4i Added QSO GUID (id field) to ContestExchange
  CURRENTVERSIONASINTEGER               = Ord(LOGVERSION1) + Ord(LOGVERSION2) * 256 + Ord(LOGVERSION3) * $10000 + Ord(LOGVERSION4) * $1000000;
  TR4W_DOWNLOAD_LINK                    : PChar = 'http://www.tr4w.net/download/?' + TR4W_CURRENTVERSION_NUMBER;

  LATEST_CONFIG_FILE                    : PChar = 'LATEST CONFIG FILE';
  MAIN_CALLSIGN                         : PChar = 'MAIN CALLSIGN';

 // ' TR4W_DOWNLOAD_LINK_WITH_VER           = 'http://tr4w.net/4.42/tr4w_setup_4_42.1.exe';

  { ====== LISTVIEW CONTROL ====================== }

const
  WC_LISTVIEW                           = 'SysListView32';

const

  { The following addresses are used as the bible for finding things in log
      entries from the logging program.         }

  LogEntryBandAddress                   = 1;
  LogEntryBandWidth                     = 3;
  LogEntryModeAddress                   = 4;
  LogEntryModeWidth                     = 3;
  LogEntryDayAddress                    = 8;
  LogEntryDayWidth                      = 2;
  LogEntryMonthAddress                  = 11;
  LogEntryMonthWidth                    = 3;
  LogEntryYearAddress                   = 15;
  LogEntryYearWidth                     = 4;
  LogEntryHourAddress                   = 18;
  LogEntryHourWidth                     = 2;
  LogEntryMinuteAddress                 = 21;
  LogEntryMinuteWidth                   = 2;
  LogEntryQSONumberAddress              = 24;
  LogEntryQSONumberWidth                = 4;
  LogEntryComputerIDAddress             = 28;
  LogEntryComputerIDWidth               = 1;
  LogEntryCallAddress                   = 30;
  LogEntryCallWidth                     = 12;
  LogEntryNameSentAddress               = 42;
  LogEntryNameSentWidth                 = 1;
  LogEntryExchangeAddress               = 44;
  LogEntryExchangeWidth                 = 24;
  LogEntryMultAddress                   = 69;
  LogEntryMultWidth                     = 8;
  LogEntryPointsAddress                 = 77;
  LogEntryPointsWidth                   = 2;
  LogEntryRcvdRSTAddress                = 49;

  { List View Styles }
  LVS_ICON                              = $0000;
  LVS_REPORT                            = $0001;
  LVS_SMALLICON                         = $0002;
  LVS_LIST                              = $0003;
  LVS_TYPEMASK                          = $0003;
  LVS_SINGLESEL                         = $0004;
  LVS_SHOWSELALWAYS                     = $0008;
  LVS_SORTASCENDING                     = $0010;
  LVS_SORTDESCENDING                    = $0020;
  LVS_SHAREIMAGELISTS                   = $0040;
  LVS_NOLABELWRAP                       = $0080;
  LVS_AUTOARRANGE                       = $0100;
  LVS_EDITLABELS                        = $0200;
  LVS_OWNERDATA                         = $1000;
  LVS_NOSCROLL                          = $2000;

  LVS_TYPESTYLEMASK                     = $FC00;

  LVS_ALIGNTOP                          = $0000;
  LVS_ALIGNLEFT                         = $0800;
  LVS_ALIGNMASK                         = $0C00;

  LVS_OWNERDRAWFIXED                    = $0400;
  LVS_NOCOLUMNHEADER                    = $4000;
  LVS_NOSORTHEADER                      = $8000;

  { List View Extended Styles }
{$EXTERNALSYM LVS_EX_GRIDLINES}
  LVS_EX_GRIDLINES                      = $00000001;
{$EXTERNALSYM LVS_EX_SUBITEMIMAGES}
  LVS_EX_SUBITEMIMAGES                  = $00000002;
{$EXTERNALSYM LVS_EX_CHECKBOXES}
  LVS_EX_CHECKBOXES                     = $00000004;
{$EXTERNALSYM LVS_EX_TRACKSELECT}
  LVS_EX_TRACKSELECT                    = $00000008;
{$EXTERNALSYM LVS_EX_HEADERDRAGDROP}
  LVS_EX_HEADERDRAGDROP                 = $00000010;
{$EXTERNALSYM LVS_EX_FULLROWSELECT}
  LVS_EX_FULLROWSELECT                  = $00000020; // applies to report mode only
{$EXTERNALSYM LVS_EX_ONECLICKACTIVATE}
  LVS_EX_ONECLICKACTIVATE               = $00000040;
{$EXTERNALSYM LVS_EX_TWOCLICKACTIVATE}
  LVS_EX_TWOCLICKACTIVATE               = $00000080;
{$EXTERNALSYM LVS_EX_FLATSB}
  LVS_EX_FLATSB                         = $00000100;
{$EXTERNALSYM LVS_EX_REGIONAL}
  LVS_EX_REGIONAL                       = $00000200;
{$EXTERNALSYM LVS_EX_INFOTIP}
  LVS_EX_INFOTIP                        = $00000400; // listview does InfoTips for you
{$EXTERNALSYM LVS_EX_UNDERLINEHOT}
  LVS_EX_UNDERLINEHOT                   = $00000800;
{$EXTERNALSYM LVS_EX_UNDERLINECOLD}
  LVS_EX_UNDERLINECOLD                  = $00001000;
{$EXTERNALSYM LVS_EX_MULTIWORKAREAS}
  LVS_EX_MULTIWORKAREAS                 = $00002000;

const
  LVM_GETBKCOLOR                        = LVM_FIRST + 0;

const

//  col1                                  = 0;
//  defStyle                         = WS_CHILD or SS_NOTIFY or SS_CENTER or {$IF tDebugMode = FALSE}SS_SUNKEN or {$IFEND}WS_VISIBLE or SS_NOPREFIX;
  UNKNOWN_COUNTRY                       = MAXWORD;
  MainStyle                             = WS_CHILD or SS_NOTIFY or SS_NOPREFIX;
  defStyle                              = MainStyle or SS_center or SS_SUNKEN or WS_VISIBLE;
  DefStyleBorder                        = defStyle or WS_BORDER;
  DefStyleDis                           = defStyle or WS_DISABLED;
  DefStyleNoSun                         = WS_CHILD or SS_NOTIFY or SS_center or SS_NOPREFIX or WS_VISIBLE;
  uVisStyle                             = WS_CHILD or SS_NOTIFY or SS_center or SS_NOPREFIX or SS_SUNKEN;
  uVisStyleNoSun                        = WS_CHILD or SS_NOTIFY or SS_center or SS_NOPREFIX;
  LeftStyle                             = WS_CHILD or SS_NOTIFY or SS_LEFT or SS_NOPREFIX or SS_SUNKEN or WS_VISIBLE;
  RightStyle                            = WS_CHILD or SS_NOTIFY or SS_RIGHT or SS_NOPREFIX or SS_SUNKEN or WS_VISIBLE;
  LeftVisNoSunStyle                     = WS_CHILD or SS_NOTIFY or SS_LEFT or SS_NOPREFIX or WS_VISIBLE;

  NET_MESSAGESTATE_ID                   = 1000;
  NET_LOGCOMPARE_ID                     = 1010;
  NET_INTERCOMMESSAGE_ID                = 1020;
  NET_NETWORKDXSPOT_ID                  = 1030;

  NET_QSOINFO_ID                        = 1040;
  NET_EDITEDQSO_ID                      = 1050;
  NET_OFFLINEQSO_ID                     = 1055;
  NET_THIS_QTC_WAS__SEND_ID             = 1056;

  NET_TAKESERVERQSO_ID                  = 1060;
  NET_TIMESYN_ID                        = 1070;
  NET_PARAMETER_ID                      = 1080;
  NET_STATIONSTATUS_ID                  = 1090;
//  NET_MULTSFREQUENCIES_ID               = 1100;
  NET_CLIENTSTATUS_ID                   = 1110;
  NET_SPOTVIANETWORK_ID                 = 1120;
  NET_COMPUTERID_ID                     = 1130;
  NET_SERVERMESSAGE_ID                  = 1140;

  SM_CLEARALLLOGS_MESSAGE               = 8230;
//  SM_CLEARSERVERLOG_MESSAGE        = 8231;

//  SM_SORTLOG_MESSAGE               = 8240;
  SM_SERVERLOG_CHANGED_MESSAGE          = 8250;
  SM_DISCONECT_CLIENT_MESSAGE           = 8260;
  SM_GETSTATUS_MESSAGE                  = 8270;
  SM_CLEAR_DUPESHEET_MESSAGE            = 8280;
  SM_CLEAR_MULTSHEET_MESSAGE            = 8290;
  SM_RECEIVED_UPDATED_QSO_MESSAGE       = 8300;
  SM_SERIAL_NUMBER_CHANGED              = 8310;

const

  TWO_STRINGS                           : PChar = '%s%s';
  BA                                    : array[boolean] of PChar = ('FALSE', 'TRUE');
  BAl                                   : array[boolean] of PChar = ('false', 'true');
  BAHTML                                : array[boolean] of PChar = ('FALSE', 'TRUE');
  BAR                                   : array[boolean] of PChar = ('No', 'Yes');
  BAMARK                                : array[boolean] of PChar = (nil, '+');

  MIXWMODE                              = False;

  CALLSIGNWINDOWID                      = 73;
  EXCHANGEWINDOWID                      = 88;
  MULTSARRAYWINDOW                      = 89;
  DUMMYZONE                             = MAXBYTE;

const
  CWMessageToNetworkLength              = 58;

{$IF tDebugMode}
var

  cw_tick_array                         : array[0..500] of Cardinal;
  cw_tick                               : integer;
{$IFEND}

//  ddd                                   : array[0..256] of Char = '';

//  col2                                  : integer;
//  col3                                  : integer;
//  col4                                  : integer;

//  col5                                  : integer;
//  col6                                  : integer;
//  col7                                  : integer;
//  col8                                  : integer;
//  col9                                  : integer;
//  col10                                 : integer;
//  col11                                 : integer;

type

  WavHeader = record
    Marker1: array[0..3] of Char;
    BytesFollowing: LONGINT;
    Marker2: array[0..3] of Char;
    Marker3: array[0..3] of Char;
    Fixed1: LONGINT;
    FormatTag: Word;
    Channels: Word;
    SampleRate: LONGINT;
    BytesPerSecond: LONGINT;
    BytesPerSample: Word;
    BitsPerSample: Word;
    Marker4: array[0..3] of Char;
    DataBytes: LONGINT;
  end;

  ActiveWindowType = (awCallWindow, awExchangeWindow, awEditableLog, awUnknown);

  TMessageState = packed record
    {2}msID: Word;
    {2}msCWElements: Word;
    {1}msComputerId: Char;
    {59}msCWMessage: array[0..CWMessageToNetworkLength] of Char;
  end;

  TMessageStatePtr = ^TMessageState;

type
  TSerialNumberType = (sntFree, sntReserved, sntUnknown);

type
  tr4wColors = (
    trLightBlue,
    trBlack,
    trBlue,
    trRed,

    trBrown,
    trGreen,
    trCyan,
    trMagenta,

    trLightGray,
    trDarkGray,
    trLightGreen,
    trLightCyan,

    trLightRed,
    trLightMagenta,
    trYellow,
    trWhite,

    trBtnFace,
    trAlert
    );
  Ptr4wColors = ^tr4wColors;
//http://code.google.com/p/doctype/wiki/CSSColors
//http://www.w3.org/TR/CSS2/syndata.html#value-def-color
//http://www.w3schools.com/CSS/css_colorsfull.asp
const
  BASECOLUMNWIDTH                       = 49;     // 4.90.4
  PREFIXCOLUMNWIDTH                     = 104;    // 4.90.4

  tr4wColorsSA                          : array[tr4wColors] of PChar = (
    'LIGHT BLUE',
    'BLACK',
    'BLUE',
    'RED',

    'BROWN',
    'GREEN',
    'CYAN',
    'MAGENTA',

    'LIGHT GRAY',
    'DARK GRAY',
    'LIGHT GREEN',
    'LIGHT CYAN',

    'LIGHT RED',
    'LIGHT MAGENTA',
    'YELLOW',
    'WHITE',

    'BTNFACE',
    'ALERT'
    );

var



  tr4wColorsArray                       : array[tr4wColors] of tcolor = (
//   b g r
    $FFFF00,
    $000000,
    $FF0000, //BLUE
    $0000FF, //RED

    $2A2AA5, //BROWN
    $00FF00,
    $FFFF00, //CYAN
    $FF00FF, //MAGENTA

    $D3D3D3,
    $A9A9A9,
    $90EE90,
    $FFFFE0, //LIGHT CYAN

    $8080FF, //LIGHT RED
    $800080, //LIGHT MAGENTA
    $00FFFF,
    $FFFFFF,

    clbtnface,
    $0000FF  //ALERT (RED)
    );
type
  TMainWindowElementInfo = record
{(*}
    mweName   : Pchar;
    mweiStyle : Cardinal;
    mweText   : PChar;

    mweColor  : tr4wColors;
    mweBackG  : tr4wColors;
    mweE      : Boolean;//isEmpty
    mweI      : Byte;//is Info window

    mweB      : Byte;
    mweiX     : Byte;
    mweiY     : Byte;
    mweiWidth : Byte;

    mweiHeight: Byte;
{*)}
  end;

type
  DummyByte = Byte;

  ContinentType = (

    UnknownContinent,
    NorthAmerica,
    SouthAmerica,
    Europe,
    Africa,
    Asia,
    Oceania,
    Antartica
    );

const
  tContinentArray                       : array[ContinentType] of PChar =
    (
    TC_C9_UNKNOWN,
    TC_C9_NORTHAMERICA,
    TC_C9_SOUTHAMERICA,
    TC_C9_EUROPE,
    TC_C9_AFRICA,
    TC_C9_ASIA,
    TC_C9_OCEANIA,
    TC_C9_ANTARTICA
    );

type

  CabrilloExtantionType = (ceCBR, ceLOG);

  RemainingMultiplierType = (rmNoRemMultDisplay, rmDomestic, rmDX, rmZone, rmPrefix);

  InitialExchangeType = (
    NoInitialExchange,
    NameInitialExchange,
    NameQTHInitialExchange,
    CheckSectionInitialExchange,
    SectionInitialExchange,
    QTHInitialExchange,
    FOCInitialExchange,
    GridInitialExchange,
    ZoneInitialExchange,
    User1InitialExchange,
    User2InitialExchange,
    User3InitialExchange,
    User4InitialExchange,
    User5InitialExchange,
    CustomInitialExchange
    );

  TMainWindowElement = (
    mweAutoSendCount,
    mweBandMode,
    mweBeamHeading,
    mweCall,
    mweClock,
    mweCodeSpeed,
    mweComputerID,
    mweCountryName,
    mweCQQSOCounter,
    mweCQTotal,
    mweCurrentOperator,
    mweDate,
    mweDupeInfoCall,
    mweEditableLog,
    mweExchange,
    mweFootSwitch,
    mweFullTime,
    mweLocator,
    mweHourRate,
    mweInsert,
    mweLastQSOTime,
    mweLocalTime,

    mweMasterStatus,
    mweNewMultStatus,
    mweMultNeedsHeader,
    mweName,
    mweNetwork,
    mweOnAirTimeCounter,
    mweOpMode,
    mwePaddle,
    mwePossibleCall,
    mweQSOsWithThisStation,
    mwePTTStatus,
    mweQSOB4Status,
    mweQSONeedsHeader,
    mweQSONumber,

    mweQuickCommand,
    mweRadioOneFreq,
    mweRadioOne,
    mweRadioTwoFreq,
    mweRadioTwo,

    mweRate,
    mweSPQSOCounter,
    mweStations,
    mweTenMinuts,
    mweTotalScore,
    mweUserInfo,
    mweWholeScreen,
    mweWinKey,
    mweWSJTX

    );

var

//  tR150SMode                            : boolean;
//  OrionWaitTime                         : integer = 50;
   ReverseInitialex                     : boolean = False;
   FontSize                             : integer = 2;
   BandMapSize                          : integer = 3;
//   BandMapItemWidth                     : integer = 120;
//   BandMapItemHeight                    : integer = 14;
  QZBRandomOffsetEnable                 : boolean;
//  QZBFixedOffset                        : real;
  // Issue #930 -- operator's actual ITU zone for HamScore/COS <iaruzone>.
  // Needed as an explicit CFG because large countries (US, Russia, Canada)
  // span multiple ITU zones, so the CTY.DAT default-by-prefix can be wrong.
  // Falls back to ctyGetITUZone(MyCall) when 0.
  MyITUZone                             : Byte;

  RichEditObject                        : TRichEditObject;
  RemMultsDXToolTip                     : HWND;
//  ti                                    : TOOLINFO;

  DomesticMultByBand                    : TAdditionalMultByBand;
  DXCCMultByBand                        : TAdditionalMultByBand;
//  DomesticMultIsRussianOblast           : boolean;

  CreateCabrilloWindow                  : HWND;
  AlertColor                            : tr4wColors = trAlert;
  wh                                    : array[TMainWindowElement] of HWND;

  TWindows                              : array[TMainWindowElement] of TMainWindowElementInfo =
    (
{(*}

{mweAutoSendCount}        (mweName: 'ARROW';                   mweiStyle: DefStyleNoSun;     mweText:#175#0      ; mweColor: trRed;   mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 16; mweiY: 07; mweiWidth: 01; mweiHeight: 1 ),
{mweBandMode}             (mweName: 'BAND MODE';               mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 00; mweiY: 07; mweiWidth: 04; mweiHeight: 1 ),
{mweBeamHeading}          (mweName: 'BEAM HEADING';            mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 0; mweiX: 32; mweiY: 06; mweiWidth: 14; mweiHeight: 1 ),
{mweCall}                 (mweName: 'CALL';                    mweiStyle: 0;                 mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 1; mweiX: 08; mweiY: 07; mweiWidth: 03; mweiHeight: 1 ),
{mweClock}                (mweName: 'CLOCK';                   mweiStyle: defStyle;          mweText:'nil'         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 08; mweiY: 07; mweiWidth: 03; mweiHeight: 1 ),
{mweCodeSpeed}            (mweName: 'CODE SPEED';              mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 00; mweiY: 10; mweiWidth: 04; mweiHeight: 1 ),
{mweComputerID}           (mweName: 'COMPUTER ID';             mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 08; mweiY: 08; mweiWidth: 03; mweiHeight: 1 ),
{mweCountryName}          (mweName: 'COUNTRY NAME';            mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 28; mweiY: 07; mweiWidth: 10; mweiHeight: 1 ),
{mweCQQSOCounter}         (mweName: 'CQ COUNTER';              mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 38; mweiY: 08; mweiWidth: 04; mweiHeight: 1 ),
{mweCQTotal}              (mweName: 'CQ TOTAL';                mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 38; mweiY: 09; mweiWidth: 08; mweiHeight: 1 ),
{mweCurrentOperator}      (mweName: 'OPERATOR';                mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 42; mweiY: 11; mweiWidth: 04; mweiHeight: 1 ),
{mweDate}                 (mweName: 'DATE';                    mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 04; mweiY: 07; mweiWidth: 04; mweiHeight: 1 ),
{mweDupeInfoCall}         (mweName: 'DUPE INFO CALL';          mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 0; mweiX: 23; mweiY: 01; mweiWidth: 09; mweiHeight: 2 ),
{mweEditableLog}          (mweName: 'EDITABLE LOG';            mweiStyle: 1;                 mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 0; mweiX: 23; mweiY: 01; mweiWidth: 09; mweiHeight: 2 ),
{mweExchange}             (mweName: 'EXCHANGE';                mweiStyle: 0;                 mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 1; mweiX: 08; mweiY: 07; mweiWidth: 03; mweiHeight: 1 ),
{mweFootSwitch}           (mweName: 'FOOT SWITCH';             mweiStyle: DefStyleDis;       mweText:TC_FOOTSW   ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 42; mweiY: 10; mweiWidth: 04; mweiHeight: 1 ),
{mweFullTime}             (mweName: 'FULL TIME';               mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 0; mweiX: 00; mweiY: 00; mweiWidth: 05; mweiHeight: 1 ),

{mweLocator}              (mweName: 'GRID LOCATOR';            mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 33; mweiY: 11; mweiWidth: 05; mweiHeight: 1 ),

{mweHourRate}             (mweName: 'HOUR RATE';               mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 28; mweiY: 09; mweiWidth: 05; mweiHeight: 1 ),
{mweInsert}               (mweName: 'INSERT';                  mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 42; mweiY: 07; mweiWidth: 04; mweiHeight: 1 ),
{mweLastQSOTime}          (mweName: 'LAST QSO TIME';           mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 33; mweiY: 08; mweiWidth: 05; mweiHeight: 1 ),
{mweLocalTime}            (mweName: 'LOCAL TIME';              mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 38; mweiY: 07; mweiWidth: 04; mweiHeight: 1 ),

{mweMasterStatus}         (mweName: 'MASTER';                  mweiStyle: uVisStyle;         mweText:'MASTER'    ; mweColor: trWhite; mweBackG: trBlue;    mweI:0; mweB: 1; mweiX: 11; mweiY: 10; mweiWidth: 04; mweiHeight: 1 ),
{mweNewMultStatus}        (mweName: 'MULT';                    mweiStyle: uVisStyle;         mweText:'MULT'      ; mweColor: trBlack; mweBackG: trYellow;  mweI:0; mweB: 1; mweiX: 11; mweiY: 11; mweiWidth: 04; mweiHeight: 1 ),
{mweMultNeedsHeader}      (mweName: 'MULTIPLIER INFORMATION';  mweiStyle: LeftVisNoSunStyle; mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 0; mweiX: 32; mweiY: 03; mweiWidth: 14; mweiHeight: 1 ),
{mweName}                 (mweName: 'NAME';                    mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 25; mweiY: 07; mweiWidth: 03; mweiHeight: 1 ),

{mweNetwork}              (mweName: 'NETWORK';                 mweiStyle: 1;                 mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:1; mweB: 1; mweiX: 25; mweiY: 07; mweiWidth: 03; mweiHeight: 1 ),

{mweOnAirTimeCounter}     (mweName: 'ON AIR TIME';             mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 28; mweiY: 08; mweiWidth: 05; mweiHeight: 1 ),
{mweOpMode}               (mweName: 'OP MODE';                 mweiStyle: defStyle;          mweText:CQPChar     ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 28; mweiY: 11; mweiWidth: 05; mweiHeight: 1 ),
{mwePaddle}               (mweName: 'PADDLE';                  mweiStyle: DefStyleDis;       mweText:TC_PADDLE   ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 38; mweiY: 10; mweiWidth: 04; mweiHeight: 1 ),
{mwePossibleCall}         (mweName: 'POSSIBLE CALL';           mweiStyle: 0;                 mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 23; mweiY: 07; mweiWidth: 02; mweiHeight: 1 ),
{mweQSOsWithThisStation}  (mweName: 'PREVIOUS QSOS';           mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 23; mweiY: 07; mweiWidth: 02; mweiHeight: 1 ),
{mwePTTStatus}            (mweName: 'PTT';                     mweiStyle: defStyle;          mweText:'OFF'       ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 25; mweiY: 11; mweiWidth: 03; mweiHeight: 1 ),
{mweQSOB4Status}          (mweName: 'QSO B4';                  mweiStyle: uVisStyle;         mweText:'QSOB4'     ; mweColor: trWhite; mweBackG: trRed;     mweI:0; mweB: 1; mweiX: 11; mweiY: 09; mweiWidth: 04; mweiHeight: 1 ),
{mweQSONeedsHeader}       (mweName: 'QSO INFORMATION';         mweiStyle: LeftVisNoSunStyle; mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 0; mweiX: 32; mweiY: 00; mweiWidth: 14; mweiHeight: 1 ),
{mweQSONumber}            (mweName: 'QSO NUMBER';              mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 1; mweiX: 11; mweiY: 07; mweiWidth: 04; mweiHeight: 2 ),
{mweQuickCommand}         (mweName: 'QUICK COMMAND';           mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 00; mweiY: 12; mweiWidth: 46; mweiHeight: 1 ),
{mweRadioOneFreq}         (mweName: 'RADIO ONE FREQ';          mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 00; mweiY: 08; mweiWidth: 04; mweiHeight: 1 ),
{mweRadioOne}             (mweName: 'RADIO ONE NAME';          mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 00; mweiY: 09; mweiWidth: 04; mweiHeight: 1 ),
{mweRadioTwoFreq}         (mweName: 'RADIO TWO FREQ';          mweiStyle: DefStyleDis;       mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 04; mweiY: 08; mweiWidth: 04; mweiHeight: 1 ),
{mweRadioTwo}             (mweName: 'RADIO TWO NAME';          mweiStyle: DefStyleDis;       mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 04; mweiY: 09; mweiWidth: 04; mweiHeight: 1 ),
{mweRate}                 (mweName: 'RATE';                    mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 33; mweiY: 09; mweiWidth: 05; mweiHeight: 1 ),
{mweSPQSOCounter}         (mweName: 'S&P COUNTER';             mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 42; mweiY: 08; mweiWidth: 04; mweiHeight: 1 ),
{mweStations}             (mweName: 'STATIONS';                mweiStyle: 1;                 mweText:nil         ; mweColor: trBlack; mweBackG: trWhite;   mweI:0; mweB: 0; mweiX: 23; mweiY: 01; mweiWidth: 09; mweiHeight: 2 ),

{mweTenMinuts}            (mweName: 'TEN MINUTES';             mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 0; mweiX: 00; mweiY: 01; mweiWidth: 05; mweiHeight: 1 ),
{mweTotalScore}           (mweName: 'TOTAL SCORE';             mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 0; mweiX: 23; mweiY: 00; mweiWidth: 09; mweiHeight: 1 ),
{mweUserInfo}             (mweName: 'USER INFO';               mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:1; mweB: 1; mweiX: 15; mweiY: 11; mweiWidth: 10; mweiHeight: 1 ),
{mweWholeScreen}          (mweName: 'WHOLE SCREEN';            mweiStyle: 0;                 mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 15; mweiY: 11; mweiWidth: 10; mweiHeight: 1 ),
{mweWinKey}               (mweName: 'WINKEYER';                mweiStyle: DefStyleDis;       mweText:'WK'        ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 38; mweiY: 11; mweiWidth: 04; mweiHeight: 1 ),
{mweWSJTX   }             (mweName: 'WSJTX';                   mweiStyle: defStyle;          mweText:nil         ; mweColor: trBlack; mweBackG: trBtnFace; mweI:0; mweB: 1; mweiX: 08; mweiY: 09; mweiWidth: 03; mweiHeight: 1 )


{*)}
    );

const
  CabrilloExtantionSA                   : array[CabrilloExtantionType] of PChar = ('%s%s.CBR', '%s%s.LOG');

  ContinentTypeSA                       : array[ContinentType] of PChar =
    ('NONE', 'NA', 'SA', 'EU', 'AF', 'AS', 'OC', 'AN');

type
  RadioType = (NoRadio, RadioOne, RadioTwo);
  LogRecordKind = (rkQSO, rkQTCR, rkQTCS, rkNote);
  SpotModeType = (NormalSpot, SHDXSpot);
  MesWindowType = (CQMsgWin, ExMsgWin, OtherMsgWin);
  tLogLevels = (llNone, llFatal, llError, llWarn, llInfo, llDebug, llTrace);
  tCategoryAssisted = (caNONASSISTED, caASSISTED);
  tCategoryBand = (cbALL, cb160M, cb80M, cb40M, cb20M, cb15M, cb10M, cb6M, cb2M, cb222, cb432, cb902, cb12G);
  tCategoryMode = (cmCW, cmDIGITAL, cmRTTY, cmSSB, cmMIXED, cmFM); // Issue #976: FM added (appended; existing cmDIGITAL/cmRTTY string swap left as a separate follow-up)
  tCertificate = (Yes, No);
  tCategoryOperator = (coSINGLEOP, coMULTIOP, coCHECKLOG);
  tCategoryPower = (cpHIGH, cpLOW, cpQRP);
  tCategoryTransmitter = (ctONE, ctTWO, ctLIMITED, ctUNLIMITED, ctSWL);

const
                                            // Use uppercase
  tLogLevelsSA                          : array[tLogLevels] of PChar = ('NONE' ,'FATAL', 'ERROR', 'WARN', 'INFO', 'DEBUG', 'TRACE');
  tCategoryAssistedSA                   : array[tCategoryAssisted] of PChar = ('NON-ASSISTED', 'ASSISTED');
  tCategoryBandSA                       : array[tCategoryBand] of PChar = ('ALL', '160M', '80M', '40M', '20M', '15M', '10M', '6M', '2M', '222', '432', '902', '1.2G');
  tCategoryModeSA                       : array[tCategoryMode] of PChar = ('CW', 'RTTY', 'DIGI', 'SSB', 'MIXED', 'FM');    // 4.90.14; FM added Issue #976
  tCertificateSA                        : array[tCertificate] of PChar = ('Yes', 'No');
  tCategoryOperatorSA                   : array[tCategoryOperator] of PChar = ('SINGLE-OP', 'MULTI-OP', 'CHECKLOG');
  tCategoryPowerSA                      : array[tCategoryPower] of PChar = ('HIGH', 'LOW', 'QRP');
  tCategoryTransmitterSA                : array[tCategoryTransmitter] of PChar = ('ONE', 'TWO', 'LIMITED', 'UNLIMITED', 'SWL');

var
  CategoryAssisted                      : tCategoryAssisted;
  CategoryBand                          : tCategoryBand;
  CategoryMode                          : tCategoryMode;
  Certificate                           : tCertificate;
  CategoryOperator                      : tCategoryOperator;
  CategoryPower                         : tCategoryPower;
  CategoryTransmitter                   : tCategoryTransmitter;
  logLevels                             : tLogLevels;
type

  CFGKind = (ckNormal, ckArray, ckList);

  CFGFunc = (cfAll, {cfR1, cfR2, cfHard, cfBM, } cfCol, cfAppearance, cfWK, cfRadio1, cfRadio2);

  CFGStatus = (csNew, csOld, csRem);

  CFGType = (ctFreqList, ctDirectory, ctFileName, ctMessage, ctMultiplier, ctBoolean, ctReal, ctByte, ctInteger, ctWord, ctString, ctURL, ctCaseSensitive, ctPassword, ctOperation, ctOther, ctChar, ctAlphaChar, {ctPort, } ctPortLPT, ctBand);

  ContestType =
    (
    DUMMYCONTEST,
    SEVENQP,
    ALLASIANCW,
    ALLASIANSSB,
    ALLJA,
    APSPRINT,
    ARCI,
    ARI_DX,
    ARRL10,
    ARRLDIGI,
    ARRL160,
    ARRLDXCW,
    ARRLDXSSB,
    ARRLSSCW,
    ARRLSSSSB,
    ARRLVHFJAN,
    ARRLVHFJUN,
    ARRLVHFSEP,
    ArizonaQsoParty,
    BALTIC,
    BWQP,
    CIS,
    CALQSOPARTY,
    COUNTYHUNTER,
    CQ160CW,
    CQ160SSB,
    CQM,
    CQVHF,
    CQWPXCW,
    CQWPXSSB,
    CQWPXRTTY,
    CQWWCW,
    CQWWSSB,
    CROATIAN,
    CUPRFCW,
    CUPRFSSB,
    CUPRFDIG,
    CUPURAL,
    EUSPRINT_SPRING_CW,
    EUROPEANHFC,
    EUROPEANVHF,
    TESLA,
    ARRLFIELDDAY,
    FISTS,
    FOCMARATHON,     //n4af
    FLORIDAQSOPARTY,
    GACWWWSACW,
    GAGARINCUP,
    GENERALQSO,
    GRIDLOC,
    HADX,
    YUDX, //4.57.5
    UKEI, // 4.58.2
    HELVETIA,
    IARU,
    INTERNETSPRINT,
    IOTA,
    JIDXCW,
    JIDXSSB,
    JALONGPREFECT,
    JTDX,
    KCJ,
    KIDSDAY,
    KVP,
    LABRE,
    LZDX,
    MARCONIMEMORIAL,     //n4af
    MINITEST,
    MINI80,
    MINI40,
    MICHQSOPARTY,
    MINNQSOPARTY,
    MOQSOPARTY,
    NAQSOCW,
    NAQSOSSB,
    NAQSORTTY,
    NASPRINTCW,
    SPRINTSSB,
    NASPRINTRTTY,
    NCCCSPRINT,
    NEWENGLANDQSO,
    NCQSOPARTY,
    NRAUBALTICCW,
    NRAUBALTICSSB,
    NZFIELDDAY,
    OCEANIADXCW,
    OCEANIADXSSB,
    OHIOQSOPARTY,
    OKDX,
    OLDNEWYEAR,
    OZCR_O,
    OZCR_Z,
    PACC,
    POTA,
    QCWA,
    QCWAGOLDEN,
    CANADA_WINTER,
    RADIOVHFFD,
    RAEM,
    RDA,
    REGION1FIELDDAY,
    REGION1FIELDDAY_RCC_CW,
    REGION1FIELDDAY_RCC_SSB,
    RFCHAMPIONSHIPCW,
    RFCHAMPIONSHIPSSB,
    RFASCHAMPIONSHIPCW,
    RSGB_ROPOCO_CW,
    RSGB_ROPOCO_SSB,
    RSGB18,
    RUSSIANDX,
    SACCW,
    YBDX,            // 4.64.1
    SACSSB,
    SALMONRUN,
    SOUTHAMERICANWW,
    SPDX,
    STEWPERRY,
    TENTEN,
    TEXASQSOPARTY,
    TOEC,
    UA4WCHAMPIONSHIP,
    UBACW,
    UBASSB,
    UCG,
    UKRAINECHAMPIONSHIP,
    UKRAINIAN,
    DARCWAEDCCW,
    DARCWAEDCSSB,
    DARCXMAS,
    WAG,
    WISCONSINQSOPARTY,
    WWL,
    WWPMC,
    XMAS,
    YODX,
    YOUTHCHAMPIONSHIPRF,
    RU3AXMEMORIAL,
    LQP,
    ARKTIKA_SPRING,
    UNDX,
    NYQP,
    KINGOFSPAINCW,
    KINGOFSPAINSSB,
    WRTC,
    TENNESSEEQSOPARTY,
    COLORADOQSOPARTY,
    R9W_UW9WK_MEMORIAL,
    PCC,         // 4.83.8 *ALL* ref to TAC changed to PCC
    RADIOMEMORY,
    DARC10M,
    REFCW,
    REFSSB,
    BSCI,
    CQMM,
    SASPRINT,
    CWOPS,
    OZHCRVHF,
    CANADA_DAY,
    CQWWRTTY,
    CWOPEN,
    MAKROTHEN,
    EUSPRINT_SPRING_SSB,
    EUSPRINT_AUTUMN_CW,
    EUSPRINT_AUTUMN_SSB,
    ARRL_RTTY_ROUNDUP,
    CQIR,
    WWIH,
    ALRS_UA1DZ_CUP,
    WINTERFIELDDAY,
    RADIOYOC,
    PAQSOPARTY,  // 4.74.3
    INQSOPARTY,  // 4.88.2
    OKOMSSB,    // 4.80.1
    BATAVIA_FT8, // 4.90.11
    WWDIGI,
    MWC,           // 4.92.8
    IRTS ,      // 4.93.1
    EUDX,        // 4.95.6
    BCQP,       // 4.97.7
    VAQP,
    YOTA,
    IN7QPNE,
    MST ,        // 4.110.5
    SST,
    RTC          // Real-Time Contest (COS) -- exchange: RST + serial + 4-char grid; distance-based scoring
    );

    { NOTE: pls ensure VC INTERFACEDRADIOTYPE and LOGRADIO INTEFACEDRADIOTYPE ARE IN THE SAME ORDER }
type
    InterfacedRadioType = (
    NoInterfacedRadio,
    K2,
    K3,
    KX3,
    K4,
    FLEX,       // 4.87.2
    TS140,
    TS440,
    TS450,
    TS480,
    TS570,
    TS590,
    TS690,
    TS850,
    TS870,
    TS890,    // Issue #436 -- alphabetical placement among Kenwoods
    TS940,
    TS950,
    TS990,
    TS2000,
    FT100,
    FTDX10,
    FTDX101,
    FTX1F,     // Yaesu FTX-1F/FTX-1R — rtYaesu4, 30-byte IF response (Issue #817)
    FT450,
    FT710,
    FT736R,
    FT747GX,
    FT767,
    FT817, { Behaves like FT847 }
    FT818,
    FT840,
    FT847,
    FT857, {UA3DPX}
    FT890, {RD4WA}
    FT891, // ny4i Issue218
    FT897, { Behaves like FT847 }
    FT900, { Behaves like FT890 }
    FT920,
    FT950,
    FT990,
    FT991,
    FT1000, {& 1000D}
    FT1000MP, { Also for the Mark V }
    FT1200,
    FT2000,
    FTDX3000,
    FTDX5000,
    FTDX9000,
    IC78,
    IC705,
    IC706,
    IC706II,
    IC706IIG,
    IC707,
    IC718,
    IC725,
    IC726,
    IC728,
    IC729,
    IC735,
    IC736,
    IC737,
    IC738,
    IC746,
    IC746PRO,
    IC756,
    IC756PRO,
    IC756PROII,
    IC756PROIII,
    IC761,
    IC765,
    IC775,
    IC781,
    IC905,    // Alphabetical placement among Icoms (between IC781 and IC910)
    IC910,
    IC970D,
    IC7000,
    IC7100,
    IC7200,
    IC7300,
    IC7300MK2,  // Alphabetical placement among Icoms (right after IC7300)
    IC7410,
    IC7600,
    IC7610,     // 4.65.7 issue 282
    IC7700,
    IC7760,
    IC7800,
    IC7850,
    IC7851,
    IC9100,
    IC9700,
    OMNI6,
    ORION,
    FLRIG,
    TRXMANAGER,
    FT757GXII,
    EXPERTTCI,
    ACLOG,
    HAMLIBANY);


    
  ICOMRadioTypes = set of InterfacedRadioType;
  KenwoodRadioTypes = set of InterfacedRadioType;
  YaesuRadioTypes = set of InterfacedRadioType;
  InterfacedRadioTypeSet = set of InterfacedRadioType;
  HamLib_ONLY_RadioTypes = set of InterfacedRadioType;
    
  BandType = (
    Band160,
    Band80,
    Band40,
    Band20,
    Band15,
    Band10,
//    Band60,
    Band30,
    Band17,
    Band12,
    Band6,
    Band2,
    Band222,
    Band432,
    Band902,
    Band1296,
    Band2304,
    Band3456,
    Band5760,
    Band10G,
    Band24G,
    BandLight,
    AllBands,
    NoBand
    );
  PBandType = ^BandType;
  (* ****** If you add any new non-Data extended modes, please update MainUnit.GetModeFromExtendedMode *)
  ExtendedModeType = (eNoMode, eCW, eRTTY, eFT8, eFT4, eJT65, ePSK31, ePSK63, eSSB, eFM, eAM,
                      eMFSK, eJS8, eUSB, eLSB, eData, eCW_R, eData_R, eRTTY_R, eFM_N, eAM_N,eData_FM, eC4FM, eDStar, ePSK_R, eWFM);

  ModeType = (CW, Digital, Phone, Both, NoMode, FM); { Use for TR }
           //AM, CW, CW-R, DATA-L, DATA-U, FM, LSB, USB, RTTY, RTTY-R, WBFM
  ExtendedRadioModeType = (rNoMode, rCW, rLSB, rUSB, rAM, rFM, rRTTY, rRTTY_R, rAFSK, rDATA_U, rDATA_L, rDIGITAL, rCW_R);
  {    ModeType = (CW, Phone, Both, NoMode, FM, Digital);   { Use for calltest }
  OpModeType = (CQOpMode, SearchAndPounceOpMode);

   ModeAndExtendedModeType = record
      msmMode: ModeType;
      msmExtendedMode: ExtendedModeType;
   end;

  PTTStatusType = (PTT_OFF, PTT_ON);

type
  BandChangeType = record
    bcBand: BandType;
    bcWARC: boolean;
    bcVHF: boolean;
  end;
type
  DupeBits = Cardinal;
type
  TDupesArray = array[CW..NoMode {Both}] of DupeBits;
type
  TIntegerSet = set of 0..SizeOf(integer) * 8 - 1;

type
  FreqRecord = record
    frMin: integer;
    frMax: integer;
    frBand: BandType;
    frMode: ModeType;
  end;
const
  FreqModeArraySize                     = 25;
  FreqModeArray                         : array[1..FreqModeArraySize] of FreqRecord =
{(*}
    (
    (frMin: 1790000;    frMax: 2000000;    frBand:Band160;  frMode: NoMode),

    (frMin: 3490000;    frMax: 3600000;    frBand:Band80;   frMode: CW),
//    (frMin: 3530000;    frMax: 3600000;    frBand:Band80;   frMode: NoMode),
    (frMin: 3600000;    frMax: 4000000;    frBand:Band80;   frMode: Phone),
//    (frMin: 5350000;    frMax: 5405000;    frBand:Band60;   frMode: NoMode),
    (frMin: 6990000;    frMax: 7040000;    frBand:Band40;   frMode: CW),
    (frMin: 7040000;    frMax: 7100000;    frBand:Band40;   frMode: NoMode),
    (frMin: 7100000;    frMax: 7300000;    frBand:Band40;   frMode: Phone),

    (frMin: 10099000;   frMax: 10150000;   frBand:Band30;   frMode: CW),

    (frMin: 13990000;   frMax: 14100000;   frBand:Band20;   frMode: CW),
    (frMin: 14100000;   frMax: 14350000;   frBand:Band20;   frMode: Phone),

    (frMin: 18068000;   frMax: 18110000;   frBand:Band17;   frMode: CW),
    (frMin: 18110000;   frMax: 18168000;   frBand:Band17;   frMode: Phone),

    (frMin: 20990000;   frMax: 21150000;   frBand:Band15;   frMode: CW),
//  (frMin: 21000000;   frMax: 21150000;   frBand:Band15;   frMode: NoMode),
    (frMin: 21150000;   frMax: 21450000;   frBand:Band15;   frMode: Phone),

    (frMin: 24890000;   frMax: 24930000;   frBand:Band12;   frMode: CW),
    (frMin: 24930000;   frMax: 24990000;   frBand:Band12;   frMode: Phone),

    (frMin: 28000000;   frMax: 28300000;   frBand:Band10;   frMode: CW),
    (frMin: 28300000;   frMax: 29700000;   frBand:Band10;   frMode: Phone),

    (frMin: 50000000;   frMax: 50100000;   frBand:Band6;    frMode: CW),
    (frMin: 50100000;   frMax: 54000000;   frBand:Band6;    frMode: Phone),

    (frMin: 144000000;  frMax: 144100000;  frBand:Band2;    frMode: CW),
    (frMin: 144100000;  frMax: 148000000;  frBand:Band2;    frMode: Phone),

    (frMin: 218000000;  frMax: 250000000;  frBand:Band222;  frMode: Phone),
    (frMin: 400000000;  frMax: 500000000;  frBand:Band432;  frMode: Phone),

    (frMin: 900000000;  frMax: 1000000000; frBand:Band902;  frMode: Phone),
    (frMin: 1000000000; frMax: 1500000000; frBand:Band1296; frMode: Phone)
//    (frMin: 2300000000; frMax: 2400000000; frBand:Band2304; frMode: Phone)
    );
{*)}

const

  { These are all extended keys }

  ControlLeftArrow                      = CHR(115);
  ControlRightArrow                     = CHR(116);
  ControlEnd                            = CHR(117);
  ControlPageDown                       = CHR(118);
  ControlHome                           = CHR(119);
  ControlPageUp                         = CHR(132);

  { Not extended }

  ControlA                              = CHR(1);
  ControlB                              = CHR(2);
  ControlC                              = CHR(3);
  ControlD                              = CHR(4);
  ControlE                              = CHR(5);
  ControlF                              = CHR(6);
  ControlG                              = CHR(7);
  ControlH                              = CHR(8);
  ControlI                              = CHR(9);
  ControlJ                              = CHR(10);
  ControlK                              = CHR(11);
  ControlL                              = CHR(12);
  ControlM                              = CHR(13);
  ControlN                              = CHR(14);
  ControlO                              = CHR(15);
  ControlP                              = CHR(16);
  ControlQ                              = CHR(17);
  ControlR                              = CHR(18);

  ControlS                              = CHR(19);
  ControlT                              = CHR(20);
  ControlU                              = CHR(21);
  ControlV                              = CHR(22);
  ControlW                              = CHR(23);
  ControlX                              = CHR(24);
  ControlY                              = CHR(25);
  ControlZ                              = CHR(26);

  ControlLeftBracket                    = CHR(27);
  ControlBackSlash                      = CHR(28);
  ControlRightBracket                   = CHR(29);
  ControlDash                           = CHR(31);

  MonthTags                             : array[1..12] of PChar = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

  CallstringLength                      = 13;

  ADIFModeString                        : array[ModeType] of PChar = ('CW', 'DIGITAL',  'SSB', 'BTH', 'NON', 'FM');
  ModeStringArray                       : array[ModeType] of PChar = ('CW', 'DIGI',  'SSB', 'BTH', 'NON', 'FM');


  ExtendedModeStringArray               : array[ExtendedModeType] of string =
                                              ('NoMode', 'CW', 'RTTY', 'FT8', 'FT4', 'JT65', 'PSK31', 'PSK63', 'SSB', 'FM', 'AM',
                                               'MFSK', 'JS8', 'USB', 'LSB', 'DATA', 'CW-R', 'DATA-R', 'RTTY-R', 'FM-N', 'AM-N',
                                               'DATA-FM', 'C4FM', 'D-STAR', 'PSK-R', 'WFM');

  BandStringsArray                      : array[BandType] of PChar {string} =
    (
    '160',
    ' 80',
    ' 40',
    ' 20',
    ' 15',
    ' 10',
 //   ' 60',
    ' 30',
    ' 17',
    ' 12',
    '  6',
    '  2',
    '222',
    '432',
    '902',
    '1GH',
    '2GH',
    '3GH',
    '5GH',
    '10G',
    '24G',
    'LGT',
    'All',
    'NON'
    );

  BandStringsArrayWithOutSpaces         : array[BandType] of PChar {string} =
    (
    '160',
    '80',
    '40',
    '20',
    '15',
    '10',
 //   '60',
    '30',
    '17',
    '12',
    '6',
    '2',
    '222',
    '432',
    '902',
    '1GH',
    '2GH',
    '3GH',
    '5GH',
    '10G',
    '24G',
    'LGT',
    'All',
    'NON'
    );

  ADIFBANDSTRINGSARRAY                  : array[BandType] of PChar =
    (
    '160m',
    '80m',
    '40m',
    '20m',
    '15m',
    '10m',
 //   '60m',
    '30m',
    '17m',
    '12m',
    '6m',
    '2m',
    '1.25m',       // Issue 406 ny4i         // 4.60.6
    '70cm',        // Issue 406 ny4i         // 4.60.6
    '33cm',         // Issue 406 ny4i         // 4.60.6
    '23cm',         // Issue 406 ny4i         // 4.60.6
    '13cm',         // Issue 406 ny4i         // 460.6
    '9cm',          // Issue 406 ny4i
    '6cm',          // Issue 406 ny4i
    '3cm',          // Issue 406 ny4i
    '1.25cm',       // Issue 406 ny4i
    '1mm',          // Issue 406 ny4i Our LGT
    nil,
    nil
    );

  EDIFBANDSTRINGSARRAY                  : array[BandType] of PChar =
    (
    '160',
    '80',
    '40',
    '20',
    '15',
    '10',
 //   '60',
    '30',
    '17',
    '12',
    '50 MHz', {edi}
    '145 MHz', {edi}
    '222 MHz',
    '432 Mhz', {edi}
    '902 MHz',
    '1296 Mhz', {edi}
    '2,3 GHz', {edi}
    '3,4 GHz', {edi}
    '5,7 GHz', {edi}
    '10 GHz', {edi}
    '24 GHz', {edi}
    nil,
    nil,
    nil
    );

type
  StationStatusType = (sstComputerNameAndID, sstBandModeFreq, sstPTT, sstOpMode, sstQSOs, sstCallsign, sstOperator);

  TStationState = packed record

    {02}ssID: Word;
    {02}ssQSOTotals: Word;

    {01}ssComputerID: Char;
    {01}ssCurrentBand: BandType;
    {01}ssCurrentMode: ModeType;
    {01}ssStatusByte: Byte;

    {04}ssFreq: integer;

    {13}ssCallsign: array[0..CallstringLength - 1] of Char;

    {09}ssName: array[0..8] of Char;

    {01}ssType: StationStatusType;

    {11}ssOperator: OperatorType;
  end;

type
  TClientStatus = packed record
    {2}csID: Word;
    {1}csTelnet: boolean;
  end;
  TClientStatusPtr = ^TClientStatus;

type
  DupeInfoState = (diNone, diDupe, diNotDupe, diNotDupeMult);
  UpadateAction = (actSetClearDupesheetBit, actResetClearDupesheetBit, actRescore, actGetCRC32, actClearMults);

  GridRec = array[1..6] of Char;

  Str2 = string[2];
  Str10 = string[10];
  Str14 = string[14];
  Str20 = string[20];
  Str25 = string[25];
  Str30 = string[30];
  Str31 = string[30];
  Str40 = string[40];
  Str50 = string[50];
  Str80 = string[80];
  Str160 = string[160];
  Str255 = string[255];
  GridString = string[7];
  CallString = string[CallstringLength];

  CallPtr = ^CallString;

  DomesticMultiplierString = Str10;

  DXMultiplierString = string[5];
  PrefixString = string[5];

  PrefixMultiplierString = string[6];
  PostalCodeString = string[6];
  ZoneMultiplierString = string[6];

  DataBaseEntryRecord = record
    Call: CallString; { Always first }
    Section: string[5]; { Control-A }
    CQZone: string[2]; { Control-C }
    FOC: string[5]; { Control-F }
    Grid: string[6]; { Control-G }
    Hits: Byte; { Control-H }
    ITUZone: string[5]; { Control-I }
    Check: string[2]; { Control-K }
    mName: CallString; { Control-N }
    OldCall: CallString; { Control-O }
    QTH: string[10]; { Control-Q }
    Speed: Byte; { Control-S }
    TENTEN: string[6]; { Control-T }
    User1: CallString; { Control-U }
    User2: CallString; { Control-V }
    User3: CallString; { Control-W }
    User4: CallString; { Control-X }
    User5: CallString; { Control-Y }
  end;

  DataBaseEntryRecordPtr = ^DataBaseEntryRecord;

  TQSOTime = packed record
    {1}qtYear: Byte;
    {1}qtMonth: Byte;
    {1}qtDay: Byte;
    {1}qtHour: Byte;
    {1}qtMinute: Byte;
    {1}qtSecond: Byte;
  end;
type
{Don`t touch!}
  QTHRecord = record
   {06}CountryID: DXMultiplierString;
   {01}Zone: Byte;
   {01}reserved: Byte;

   {07}Prefix: PrefixMultiplierString;
   {01}Continent: ContinentType;

   {14}StandardCall: CallString; 
   {02}Country: Word;

  end;
  MultsFrequencies = array[CW..Phone, Band160..Band10] of integer;
type
  NetMultsFrequencies = packed record
    mfID: Word;
    mfQSOTotals: MultsFrequencies;
  end;

type
  TSendSpotViaNetwork = packed record
    vnID: Word;
    vnMessage: array[0..45] of Char;
  end;

  TSendSpotViaNetworkPtr = ^TSendSpotViaNetwork;

type
  TComputerNetID = packed record
    ciID: Word;
    ciComputerID: Char;
    ciReserved: Byte;
  end;

  TComputerNetIDPtr = ^TComputerNetID;

type
  TLogFileInformation = packed record
    liID: Word;
    liSeverCRC32: Cardinal;
    liLocalCRC32: Cardinal;
    liServerLogSize: Cardinal;
    liLocalLogSize: Cardinal;
    liContest: ContestType;
  end;

type
  PLogFileInformation = ^TLogFileInformation;

  {(*}

(* The TLogHeader type had a dependency on the size of the ContestExchange
   to build the dummy area of its type definition. This meant that to add something
   to ContestExchange, you had to go to find TLogRecord to change the number of
   bytes in ther dummy array. I changed this (at bottom of VC.pas) so the size
   is derived on the sizes so no change elsewhere required.
   I found this because I added a field to CE and the program complained as the
   TRN file was not the right size. This should eliminate that maintenance
   step. de NY4I
*)

type
  ContestExchange = record
{COMMON START}

{06}  tSysTime:            TQSOTime;
{01}  Band:                BandType;
{01}  Mode:                ModeType;

{04}  ceQSOID1:            Cardinal;
{04}  ceQSOID2:            Cardinal;
{04}  Frequency:           LONGINT;

{01}  ceQSO_Deleted:       boolean;
{01}  ceComputerID:        Char;
{01}  ceOperatorID:        Byte;
{01}  ceRecordKind:        LogRecordKind;

{01}  ceQSO_Skiped:        boolean;
{01}  ceSendToServer:      boolean;
{01}  ceNeedSendToServerAE:    boolean;
{01}  ceDupe:              boolean;

{07}  PostalCode_old:          PostalCodeString;
{01}  ZERO_01:             DummyByte;

{COMMON END}

{07}  Prefix:              PrefixMultiplierString;
{01}  ZERO_02:             DummyByte;

{14}  Callsign:            CallString;
{01}  Age:                 byte;
{01}  ceWasSendInQTC:      Boolean;

{01}  DomesticMult:        boolean;
{01}  DXMult:              boolean;
{01}  PrefixMult:          boolean;
{01}  ZoneMult:            boolean;
      ExtMode:             ExtendedModeType;
      ExchString:          Str40;  // What is entered as SRX exchange
{04}  ceClass:             string[3]{10}; { Field day class }

{01}  ZERO_04:             DummyByte;
{01}  Precedence:          Char;
{01}  ceRadio:             RadioType;
{01}  Check:               Byte;           {The CHECK is two numbers (year)}

{32}  QTH:                 QTHRecord;

{06}  DXQTH:               DXMultiplierString;
{01}  ZERO_05:             DummyByte;
{01}  Radio:               InterfacedRadioType;

{11}  DomMultQTH:          DomesticMultiplierString; //String for dom mult count
{01}  ZERO_06:             DummyByte;

{11}  DomesticQTH:         Str10;//Corrected QTH - if it is need  - i.e. AF1 -> AF-001 in IOTA contest.
{01}  ZERO_07:             DummyByte;

{11}  Name:                Str10;
{01}  ZERO_08:             DummyByte;

{07}  Power:               string[6];
{01}  ZERO_09:             DummyByte;

{04}  NumberReceived:      integer;
{04}  NumberSent:          integer;

{02}  RSTSent:             smallInt; {Word;}
{02}  RSTReceived:         smallInt; {Word;}  // if this was an int, I could put ft8 reports here.

{11}  QTHString:           Str10;//QTH received by user (literal)
{01}  ZERO_10:             DummyByte;

{06} RandomCharsSent:      string[5];
{02} TenTenNum:            word;

{05}  Chapter:             string[4];
{01}  ZERO_11:             DummyByte;
{01}  ceClearDupeSheet:    boolean;
{01}  ceSearchAndPounce:   boolean;

{01}  Prefecture:          Byte;
{01}  InhibitMults:        boolean;
{01}  Zone:                Byte;
{01}  NameSent:            boolean;

{21}  Kids:                Str20; { Used for whole ex string }
{01}  ceContest:           ContestType;
{02}  QSOPoints:           word{Smallint};

{08}  RandomCharsReceived: string[7];

{01}  ZERO_13:             DummyByte;
{01}  ceClearMultSheet:    Boolean;
{01}  MP3Record:           Boolean;
{01}  //res3:                Byte;

{******************************}
{07}  ceOperator:          OperatorType;

{32}  id:                   string[32];
{01}  //res15:               Byte;

{01}  //res16:               Byte;
{01} // res17:               Byte;
{01} // res18:               Byte;
{01} // res19:               Byte;

{01} // res20:               Byte;
{01} // res21:               Byte;
{01} // res22:               Byte;
{01}  //res23:               Byte;

//{01}  res25:               Byte;
// ceXQSO: True when the operator has marked this contact as a Cabrillo
// X-QSO -- the contact happened and is kept in the log for NIL
// protection of the other station, but is not claimed for credit
// (excluded from QSO count, multipliers, points, and dupe checking).
// Stored in the slot freed by shrinking sReserved from string[50] to
// string[49]; the on-disk byte at this offset in older logs was the
// length byte of unused sReserved (always zero), so existing logs read
// with ceXQSO = False after the layout change.  Issue #750.
{01}  ceXQSO:              Boolean;
{49} sReserved:               string[49]
   end;
{*)}

const
  SizeOfContestExchange                 = SizeOf(ContestExchange);
type
  ContestExchangePtr = ^ContestExchange;

type

  ContestExchangev1_6 = record
{COMMON START}

{06}  tSysTime:            TQSOTime;
{01}  Band:                BandType;
{01}  Mode:                ModeType;

{04}  ceQSOID1:            Cardinal;
{04}  ceQSOID2:            Cardinal;
{04}  Frequency:           LONGINT;

{01}  ceQSO_Deleted:       boolean;
{01}  ceComputerID:        Char;
{01}  ceOperatorID:        Byte;
{01}  ceRecordKind:        LogRecordKind;

{01}  ceQSO_Skiped:        boolean;
{01}  ceSendToServer:      boolean;
{01}  ceNeedSendToServerAE:    boolean;
{01}  ceDupe:              boolean;

{07}  PostalCode_old:          PostalCodeString;
{01}  ZERO_01:             DummyByte;

{COMMON END}

{07}  Prefix:              PrefixMultiplierString;
{01}  ZERO_02:             DummyByte;

{14}  Callsign:            CallString;
{01}  Age:                 byte;
{01}  ceWasSendInQTC:      Boolean;

{01}  DomesticMult:        boolean;
{01}  DXMult:              boolean;
{01}  PrefixMult:          boolean;
{01}  ZoneMult:            boolean;
      ExtMode:             ExtendedModeType;
      ExchString:          Str40;  // What is entered as SRX exchange
{04}  ceClass:             string[3]{10}; { Field day class }

{01}  ZERO_04:             DummyByte;
{01}  Precedence:          Char;
{01}  ceRadio:             RadioType;
{01}  Check:               Byte;           {The CHECK is two numbers (year)}

{32}  QTH:                 QTHRecord;

{06}  DXQTH:               DXMultiplierString;
{01}  ZERO_05:             DummyByte;
{01}  Radio:               InterfacedRadioType;

{11}  DomMultQTH:          DomesticMultiplierString; //String for dom mult count
{01}  ZERO_06:             DummyByte;

{11}  DomesticQTH:         Str10;//Corrected QTH - if it is need  - i.e. AF1 -> AF-001 in IOTA contest.
{01}  ZERO_07:             DummyByte;

{11}  Name:                Str10;
{01}  ZERO_08:             DummyByte;

{07}  Power:               string[6];
{01}  ZERO_09:             DummyByte;

{04}  NumberReceived:      integer;
{04}  NumberSent:          integer;

{02}  RSTSent:             smallInt; {Word;}
{02}  RSTReceived:         smallInt; {Word;}  // if this was an int, I could put ft8 reports here.

{11}  QTHString:           Str10;//QTH received by user (literal)
{01}  ZERO_10:             DummyByte;

{06} RandomCharsSent:      string[5];
{02} TenTenNum:            word;

{05}  Chapter:             string[4];
{01}  ZERO_11:             DummyByte;
{01}  ceClearDupeSheet:    boolean;
{01}  ceSearchAndPounce:   boolean;

{01}  Prefecture:          Byte;
{01}  InhibitMults:        boolean;
{01}  Zone:                Byte;
{01}  NameSent:            boolean;

{21}  Kids:                Str20; { Used for whole ex string }
{01}  ceContest:           ContestType;
{02}  QSOPoints:           word{Smallint};

{08}  RandomCharsReceived: string[7];

{01}  ZERO_13:             DummyByte;
{01}  ceClearMultSheet:    Boolean;
{01}  MP3Record:           Boolean;
{01}  res3:                Byte;

{******************************}
{07}  ceOperator:          OperatorType;

{01}//  res4:                Byte;
{01}//  res5:                Byte;
{01}//  res6:                Byte;
{01}//  res7:                Byte;

{01}//  res8:                Byte;
{01}//  res9:                Byte;
{01}//  res10:               Byte;
{******************************}

{01}//  res11:               Byte;

{01}//  res12:               Byte;
{01}//  res13:               Byte;
{01}//  res14:               Byte;
{01}  res15:               Byte;

{01}  res16:               Byte;
{01}  res17:               Byte;
{01}  res18:               Byte;
{01}  res19:               Byte;

{01}  res20:               Byte;
{01}  res21:               Byte;
{01}  res22:               Byte;
{01}  res23:               Byte;

//{01}  res25:               Byte;
   end;
{*)}

const
  SizeOfContestExchangev1_6                 = SizeOf(ContestExchangev1_6);
type
  ContestExchangePtrv1_6 = ^ContestExchangev1_6;

// This is another declaration of ContestExchange for version 1.5. This is used to convert

  ContestExchangev1_5 = record
{COMMON START}

{06}  tSysTime:            TQSOTime;
{01}  Band:                BandType;
{01}  Mode:                ModeType;

{04}  ceQSOID1:            Cardinal;
{04}  ceQSOID2:            Cardinal;
{04}  Frequency:           LONGINT;

{01}  ceQSO_Deleted:       boolean;
{01}  ceComputerID:        Char;
{01}  ceOperatorID:        Byte;
{01}  ceRecordKind:        LogRecordKind;

{01}  ceQSO_Skiped:        boolean;
{01}  ceSendToServer:      boolean;
{01}  ceNeedSendToServerAE:    boolean;
{01}  ceDupe:              boolean;

{07}  PostalCode_old:          PostalCodeString;
{01}  ZERO_01:             DummyByte;

{COMMON END}

{07}  Prefix:              PrefixMultiplierString;
{01}  ZERO_02:             DummyByte;

{14}  Callsign:            CallString;
{01}  Age:                 byte;
{01}  ceWasSendInQTC:      Boolean;

{01}  DomesticMult:        boolean;
{01}  DXMult:              boolean;
{01}  PrefixMult:          boolean;
{01}  ZoneMult:            boolean;
{04}  ceClass:             string[3]{10}; { Field day class }

{01}  ZERO_04:             DummyByte;
{01}  Precedence:          Char;
{01}  ceRadio:             RadioType;
{01}  Check:               Byte;           {The CHECK is two numbers (year)}

{32}  QTH:                 QTHRecord;

{06}  DXQTH:               DXMultiplierString;
{01}  ZERO_05:             DummyByte;
{01}  Radio:               InterfacedRadioType;

{11}  DomMultQTH:          DomesticMultiplierString; //String for dom mult count
{01}  ZERO_06:             DummyByte;

{11}  DomesticQTH:         Str10;//Corrected QTH - if it is need  - i.e. AF1 -> AF-001 in IOTA contest.
{01}  ZERO_07:             DummyByte;

{11}  Name:                Str10;
{01}  ZERO_08:             DummyByte;

{07}  Power:               string[6];
{01}  ZERO_09:             DummyByte;

{04}  NumberReceived:      integer;
{04}  NumberSent:          integer;

{02}  RSTSent:             smallInt; {Word;}
{02}  RSTReceived:         smallInt; {Word;}  // if this was an int, I could put ft8 reports here.

{11}  QTHString:           Str10;//QTH received by user (literal)
{01}  ZERO_10:             DummyByte;

{06} RandomCharsSent:      string[5];
{02} TenTenNum:            word;

{05}  Chapter:             string[4];
{01}  ZERO_11:             DummyByte;
{01}  ceClearDupeSheet:    boolean;
{01}  ceSearchAndPounce:   boolean;

{01}  Prefecture:          Byte;
{01}  InhibitMults:        boolean;
{01}  Zone:                Byte;
{01}  NameSent:            boolean;

{21}  Kids:                Str20; { Used for whole ex string }
{01}  ceContest:           ContestType;
{02}  QSOPoints:           word{Smallint};

{08}  RandomCharsReceived: string[7];

{01}  ZERO_13:             DummyByte;
{01}  ceClearMultSheet:    Boolean;
{01}  MP3Record:           Boolean;
{01}  res3:                Byte;

{******************************}
{07}  ceOperator:          OperatorType;

{01}//  res4:                Byte;
{01}//  res5:                Byte;
{01}//  res6:                Byte;
{01}//  res7:                Byte;

{01}//  res8:                Byte;
{01}//  res9:                Byte;
{01}//  res10:               Byte;
{******************************}

{01}//  res11:               Byte;

{01}//  res12:               Byte;
{01}//  res13:               Byte;
{01}//  res14:               Byte;
{01}  res15:               Byte;

{01}  res16:               Byte;
{01}  res17:               Byte;
{01}  res18:               Byte;
{01}  res19:               Byte;

{01}  res20:               Byte;
{01}  res21:               Byte;
{01}  res22:               Byte;
{01}  res23:               Byte;

//{01}  res25:               Byte;
   end;

   const
  SizeOfContestExchangev1_5                 = SizeOf(ContestExchangev1_5);
type
  ContestExchangePtrv1_5 = ^ContestExchangev1_5;
//----------------------------------------------------------------------------------------
type
  TNetSynQSOInformation = packed record
    qsID: Word;
    qsInformation: ContestExchange;
    qsRes1: Byte;
    qsRes2: Byte;
    qsRes3: Byte;
    qsRes4: Byte;
  end;

type
  TNetQSOInformation = packed record
    qiID: Word;
    qiInformation: ContestExchange;
    qiComputerID: Cardinal;
    qiReservedByte1: Byte;
    qiReservedByte2: Byte;
  end;

type

  TSpotRecord = record
    {04}FFrequency: LONGINT; { LONGINT of spotted frequency }
    {04}FSysTime: Cardinal {SYSTEMTIME};
    {04}FQSXFrequency: LONGINT; { Any QSX frequency }

    {14}FCall: CallString;
    {01}FBand: BandType; { The band of the spot }
    {01}FMode: ModeType; { The mode of the spot }

    {32}FNotes: array[0..31] of Char; { Any notes }

    {14}FSourceCall: CallString; { Callsign of station making the post }
    {01}FSpotMode: SpotModeType; { NormalSpot or SHDXSpot }
    {01}FMult: boolean;

    {12}FFreqString: array[0..11] of Char; //Str10;

    {04}FMinutesLeft: integer;

    {01}FDupe: boolean;
//    {01}FLoudSignal: boolean;
    {01}FCQ: boolean;
    {01}FWARCBand: boolean;

    //    FInMaster: boolean;
    //    FDistanceFromDXToSource: integer;
    //    FDistanceToDX: Word;
    //    FDistanceToSource: Word;
    //    FWorkBefore: boolean;
    //FTimeString: string[5]; { Time shown in packet spot - includes the Z }
  end;

type
  TNetDXSpot = packed record
    dsID: Word;
    dsSpot: TSpotRecord;
  end;

type
  TNetDXSpotPtr = ^TNetDXSpot;

//type  ContestExchangePtr = ^ContestExchange;
type
  TStationStatePtr = ^TStationState;

type
  NetQSOInformationPtr = ^TNetQSOInformation;

type
  TNetSynQSOInformationPtr = ^TNetSynQSOInformation;

type
  TNetTimeSync = packed record
    tsID: Word;
    tsTime: SYSTEMTIME;
    tsReserved1: Byte;
    tsReserved2: Byte;
  end;

type
  TNetTimeSyncPtr = ^TNetTimeSync;

type
  TParameterToNetwork = packed record
    pnID: Word;
    pnCommand: ShortString;
    pnValue: ShortString;
  end;

type
  TIntercomMessage = packed record
    imID: Word;
    imSender: Char;
    imMessage: Str80;
  end;

type
  TServerMessage = packed record
    smID: Word;
    smMessage: Word;
    smParam: integer;
  end;
type
  TServerMessagePtr = ^TServerMessage;

const

  _RESTARTBIN                           : PChar = 'RESTART.BIN';
  _LOGFILE                              : PChar = 'LOG file';

  _COMMANDS                             : PChar = 'COMMANDS';


  OPERATORINFO                          : PChar = '_OP_INFO_%03u';

  ERMAK_                                : PChar = 'ERMAK';
  ERMAKSECTION                          : PChar = 'ERMAKREPORT';
  CABRILLOSECTION                       : PChar = 'REPORT';

//  TRAINER                          = 'TRAINER';

const

  WM_SOCK                               = $5F4; //WM_APP + 115;
  WM_SOCK_SYNC_TIME                     = WM_SOCK + 1;
  WM_SOCK_NET                           = WM_SOCK + 2;
  WM_TRAYBALLON                         = WM_SOCK + 3;

  StatusEquality                        = 1;
  tr4w_MAX_RATE                         = 200;

  tCQAsInteger                          = $202F5143;
  tNEWAsInteger                         = $2057454E;

const
  CallsignExchangeWinStyle              = WS_CHILD or WS_VISIBLE or ES_UPPERCASE or WS_TABSTOP or ES_AUTOHSCROLL {or ES_OEMCONVERT  } or ES_NOHIDESEL;

  QSOMULTSWINDOWSTYLE                   = uVisStyleNoSun;
  QSOMULTSMODEWINDOWSTYLE               = WS_CHILD or SS_NOTIFY or SS_RIGHT or SS_NOPREFIX or WS_VISIBLE;
type
  TWndEntry = packed record
    WndRect: TRect;
    WndVisible: boolean;
    WndHandle: HWND;
    WndProcAdr: Pointer;
  end;

type
  TColorsFontsEntry = packed record
    cfFont: tagLOGFONTA;
    cfFontColor: Cardinal;
    cfBkGrColor: HBRUSH;
    cfWindowHandle: HWND;
  end;

type
  QTCActionType = (NoQTCAction, AbortThisQTC, SaveThisQTC);

type
  SocketStateType = (ssActive, ssIdle);

type
  TSelection = record
    StartPos, EndPos: integer;
  end;

type

  WindowsType =
    (
   {00}tw_MAINWINDOW_INDEX,
   {01}tw_BANDMAPWINDOW_INDEX,
   {02}tw_DUPESHEETWINDOW1_INDEX,
   {03}tw_FUNCTIONKEYSWINDOW_INDEX,
   {04}tw_MASTERWINDOW_INDEX,
   {05}tw_REMMULTSWINDOW_INDEX,
   {06}tw_RADIOINTERFACEWINDOW1_INDEX,
   {07}tw_RADIOINTERFACEWINDOW2_INDEX,
   {08}tw_TELNETWINDOW_INDEX,
   {09}tw_NETWINDOW_INDEX,
   {10}tw_MMTTYWINDOW_INDEX,
   {11}tw_INTERCOMWINDOW_INDEX,
   {12}tw_POSTSCORESWINDOW_INDEX,
   {13}tw_STATIONS_INDEX,
   {14}tw_STATIONS_RM_DX,
   {15}tw_STATIONS_RM_DOM,
   {16}tw_STATIONS_RM_ZONE,
   {17}tw_MP3RECORDER,
   {18}tw_STATIONS_RM_PREFIX,
   {19}tw_DUPESHEETWINDOW2_INDEX,
   {20}tw_HAMSCOREWINDOW_INDEX,
   {21}tw_Dummy11
    );

  LogColumnsType =
    (
    logColBand,
    logColDate,
    logColTime,
    logColNumberSent,

    logColCallsign,
    logColQTC,
    logColNumberReceive,
    logColDXMult,
    logColZoneMult,
    logColPrefixMult,
    logColPrecedence,
    logColCheck,
    logColName,
    logColClass,
    logColQTH,
    logColAge,
    logColChapter,
    logColPower,
    logColFOC,
    logColKids,
//    logColPostCode,

    logColPoints,
    logColTotalMults,

    logColComputerID,
    logColSearchAndPounce,

    logColDupe,
    logColFreq,
    logColOperator
    );

type
  TLogColumnsInfo = record
    Text: PChar;
    Width: Byte;
    Align: Byte;
    Enable: boolean;
    pos: Byte;
  end;
const
  SizeOfTLogColumnsInfo                 = SizeOf(TLogColumnsInfo);
//  ActiveMainWindowProc                  : array[ActiveWindowType] = ();
var
//  RemMultsColumnWidthArray         : array[RemainingMultiplierType] of integer;

  ActiveMainWindow                      : ActiveWindowType = awUnknown;

  CurrentOperator                       : OperatorType;

  ColumnsArray                          : array[LogColumnsType] of TLogColumnsInfo =
    (
{(*}
    ( Text:RC_BAND ;      Width: 4; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: RC_DATE;      Width: 4; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: 'UTC';        Width: 3; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: 'QsS';        Width: 4; Align: LVCFMT_RIGHT;  Enable: True;  Pos: 0),
    ( Text: RC_CALLSIGN;  Width: 8; Align: LVCFMT_LEFT;   Enable: True;  Pos: 0),
    ( Text: 'QTC';        Width: 7; Align: LVCFMT_LEFT;   Enable: False; Pos: 0),
    ( Text: 'QsR';        Width: 3; Align: LVCFMT_RIGHT;  Enable: False; Pos: 0),
    ( Text: 'DX';         Width: 3; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Zn';         Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Px';         Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Pre';        Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Ck';         Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Name';       Width: 3; Align: LVCFMT_CENTER; Enable: False; Pos: 0),

    ( Text: 'Cl.';        Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),

    ( Text: 'QTH';        Width: 4; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Age';        Width: 3; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Ch.';        Width: 2; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'PWR';        Width: 3; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'FOC#';       Width: 4; Align: LVCFMT_CENTER; Enable: False; Pos: 0),
    ( Text: 'Kids';       Width: 7; Align: LVCFMT_CENTER; Enable: False; Pos: 0),

//    ( Text: 'PC';         Width: 4; Align: LVCFMT_CENTER; Enable: False; Pos: 0),

    ( Text: TC_POINTS;    Width: 2; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: 'M';          Width: 2; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),

    ( Text: 'Id';         Width: 2; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: '$';          Width: 2; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),

    ( Text: 'D';          Width: 2; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: TC_FREQ;      Width: 4; Align: LVCFMT_CENTER; Enable: True;  Pos: 0),
    ( Text: TC_OP;        Width: 4; Align: LVCFMT_LEFT;   Enable: True;  Pos: 0)
{*)}
    );

  // Language-neutral column names used to persist COLUMN WIDTH ... settings
  // in CFG files. Must stay in sync with ColumnsArray above (same order, same
  // count). These match the uppercased English Text values that older English
  // builds historically wrote, so existing CFG files continue to parse.
  // Without this, CFGs are language-locked: a CFG saved by an English build
  // fails to load in a Spanish/Russian/etc. build because ColumnsArray[].Text
  // is translated at compile time.
  ColumnCanonicalName: array[LogColumnsType] of PChar = (
    'BAND',     'DATE',     'UTC',      'QSS',      'CALLSIGN', 'QTC',
    'QSR',      'DX',       'ZN',       'PX',       'PRE',      'CK',
    'NAME',     'CL.',      'QTH',      'AGE',      'CH.',      'PWR',
    'FOC#',     'KIDS',     'PTS',      'M',        'ID',       '$',
    'D',        'FREQ',     'OP'
    );

  {Windows ID`s}
const
  tr4w_MAINWINDOW_INDEX                 = 0;
  tr4w_BANDMAPWINDOW_INDEX              = 1;
  tr4w_DUPESHEETWINDOW_INDEX            = 2;
  tr4w_FUNCTIONKEYSWINDOW_INDEX         = 3;
  tr4w_MASTERWINDOW_INDEX               = 4;
  tr4w_REMMULTSSWINDOW_INDEX            = 5;
  tr4w_RADIOINTERFACEWINDOW1_INDEX      = 6;
  tr4w_RADIOINTERFACEWINDOW2_INDEX      = 7;

  tr4w_TELNETWINDOW_INDEX               = 8;
  tr4w_NETWINDOW_INDEX                  = 9;
  tr4w_MMTTYWINDOW_INDEX                = 10;
  tr4w_TR4W_WINDOWS_TOTAL               = 10;

  {Main Window ListBoxes}
  MainWindowPCLID                       = 77;
  //   MainWindowELLID                 = 2;

     { Units of time }
  HoursPerDay                           = 24;
  MinsPerDay                            = HoursPerDay * 60;
  SecsPerDay                            = MinsPerDay * 60;
  MSecsPerDay                           = SecsPerDay * 1000;

  {timers}
  ONE_SECOND_TIMER_HANDLE               = 1;
  QUICK_REPORT_TIMER_HANDLE             = 2;
  BEACONS_ONE_SECOND_TIMER_HANDLE       = 3;
  // BANDMAP_BLINK_TIMER_HANDLE            = 4;
  REMINDER_ONE_SECOND_TIMER_HANDLE      = 5;
  WAV_PTT_TIMER_HANDLE                  = 6;
  AUTOCQ_TIMER_HANDLE                   = 7;
  NETSTATUS_TIMER_HANDLE                = 8;
  ALARM_WAKEUP_TIMER_HANDLE             = 9;
  CLOSE_ALARM_WAKEUP_HANDLE             = 10;
  UPDATE_NET_CW_MESSAGE                 = 11;
  BANDMAP_REFRESH_TIMER_HANDLE          = 12;

  {menu items & accelerators}

  menu_syncpctime                       = 10550;
  menu_beaconsmonitor                   = 10551;
  item_calculator                       = 10555;
{
  menu_COAX_Length_Calculator           = 10552;
  menu_Distance                         = 10553;
  menu_Grid                             = 10554;
  menu_lc                               = 10556;
}
  menu_windowsmanager                   = 10557;
  menu_volume_control                   = 10558;
  menu_settimezone                      = 10559;
  menu_qrzru_calendar                   = 10560;
  menu_recording_control                = 10561;
//  menu_soundrecorder                    = 10562;
  menu_pingserver                       = 10563;
  menu_runserver                        = 10564;
  menu_WA7BNM_calendar                   = 10565;
  menu_run_devicemanager                = 10566;
  menu_get_offset                       = 10567;
//  menu_wa7bnm_calendar                  = 10568;
  menu_3830_scores_posting              = 10569;     //4.51.8
  menu_arrl_submit                      = 10570;     //4.53.3
  menu_reset_radio_ports                = 10571;     // NY4I Issue #533
  //  menu_addonlinerdxcresults         = 10564;

  menu_escape                           = 10502;

  menu_new_contest                      = 10000;
  menu_log_file_properties              = 10001;
  menu_exit                             = 10002;
  menu_cabrillo                         = 10003;
  menu_summary                          = 10004;
  menu_scorebyhour                      = 10005;
  menu_continentlist                    = 10006;
  menu_qsobycountry                     = 10007;
  menu_adif                             = 10008;
  menu_first_call_work_ineachcountry    = 10009;
  menu_first_call_work_InEachZone       = 10010;
  menu_POSSIBLEBADZONE                  = 10011;
  menu_band_changes                     = 10012;
//  menu_trlog                            = 10013;
  menu_initial_ex_list                  = 10014;
  menu_allcallsigns_list                = 10015;
  menu_clear_log                        = 10016;
  menu_export_notes                     = 10017;
  menu_import_adif                      = 10018;
  menu_export_edi                       = 10019;
  menu_csv                              = 10020;
  menu_3830scores                       = 10021;
  menu_edit_cabrillo_summary            = 10022;  // Issue #914
  menu_options                          = 10100;
  menu_messages                         = 10101;
  menu_other_messages                   = 10102;
  menu_cat_radio_one                    = 10103;
  menu_lpt                              = 10104;
  menu_net_set                          = 10105;
  menu_cat_radio_two                    = 10106;
  menu_winkeyer2                        = 10107;
  menu_colors                           = 10108;
  menu_appearance                       = 10109;
  menu_trlog                            = 10110;

  menu_windows_bandmap                  = 10200;
  menu_windows_dupesheet1               = 10201;
  menu_windows_funckeys                 = 10202;
  menu_windows_trmasterdta              = 10203;
  menu_windows_remmults                 = 10204;
  menu_windows_radiointerface1          = 10205;
  menu_windows_radiointerface2          = 10206;

  menu_windows_telnet                   = 10207;
  menu_windows_network                  = 10208;
  menu_windows_mmtty                    = 10209;
  menu_windows_intercom                 = 10210;
  menu_windows_getscores                = 10211;
  menu_windows_stations                 = 10212;

  menu_rm_dx                            = 10213;
  menu_rm_domestic                      = 10214;
  menu_rm_zone                          = 10215;
  menu_rm_prefix                        = 10217;

//  menu_windows_stack                    = 10216;
//  menu_windows_mf                       = 10217;
  menu_windows_mp3recorder              = 10216;
  menu_windows_dupesheet2               = 10218;

  menu_alt_wkmode                       = 10300;
  menu_alt_autocqresume                 = 10301;
  menu_alt_dupecheck                    = 10302;
  menu_alt_SO2R_edit                         = 10303;
  menu_alt_savetofloppy                   = 10304;
  menu_alt_swapmults                    = 10305;
  menu_alt_incnumber                    = 10306;
  menu_alt_multbell                     = 10307;
  menu_alt_killcw                       = 10308;      // This is relaly a toggle CW command - ny4i 2026JUN10
  menu_alt_searchlog                    = 10309;
  menu_alt_transfreq                    = 10310;     //  4.47.3 restore menuid
  menu_alt_reminder                     = 10311;
  menu_alt_autocq                       = 10312;
  menu_alt_tooglerigs                   = 10313;
  menu_alt_cwspeed                      = 10314;
  menu_alt_settime                      = 10315;
  menu_alt_flushlogtodisk               = 10316;
  menu_alt_p                            = 10317;
  menu_alt_initialexhange               = 10318;
  menu_alt_tooglesidetone               = 10319;
  menu_alt_toogleautosend               = 10320;
  menu_alt_bandup                       = 10321;
  menu_alt_banddown                     = 10322;
  menu_alt_ssbcwmode                    = 10323;
  menu_alt_deleteqso                    = 10324;
  menu_alt_init_qso                     = 10325;
  menu_alt_setnettime                   = 10326;

  menu_alt_increment_time_1             = 10327;
  menu_alt_increment_time_2             = 10328;
  menu_alt_increment_time_3             = 10329;
  menu_alt_increment_time_4             = 10330;
  menu_alt_increment_time_5             = 10331;
  menu_alt_increment_time_6             = 10332;
  menu_alt_increment_time_7             = 10333;
  menu_alt_increment_time_8             = 10334;
  menu_alt_increment_time_9             = 10335;
  menu_alt_increment_time_0             = 10336;
  menu_alt_x                            = 10337;
  menu_ctrl_j                           = 10338;

  menu_ctrl_sendkeyboardinput           = 10400;
  menu_ctrl_trpath                      = 10605;
  menu_ctrl_commtopacket                = 10401;
  menu_ctrl_cleardupesheet              = 10402;
  menu_ctrl_viewlogdat                  = 10403;
  menu_ctrl_note                        = 10404;
  menu_ctrl_missmultsreport             = 10405;
  menu_ctrl_ptt                         = 10427;    // 4.53.9
  menu_ctrl_qtcfunctions                = 10407;
  menu_ctrl_recalllastentry             = 10408;
  menu_ctrl_viewpacketspots             = 10409;
  menu_ctrl_refreshbandmap              = 10410;
  menu_ctrl_SplitOff                    = 10411;
  menu_ctrl_lookup                     = 10412;
  menu_ctrl_cursorinbandmap             = 10413;
  menu_ctrl_logqsowithoutcw             = 10414;
  menu_ctrl_PlaceHolder                 = 10415;
  menu_ctrl_ct1bohscreen                = 10416;
  menu_ctrl_cursorintelnet              = 10417;

  menu_ctrl_incAQSLinterval             = 10418;
  menu_ctrl_decAQSLinterval             = 10419;

  menu_ctrl_showCallsign                = 10420;
  menu_ctrl_showSpeed                   = 10421;
  menu_ctrl_showBand                    = 10422;
  menu_ctrl_showQSONumber               = 10423;
  menu_ctrl_clearmultsheet              = 10424;
  menu_ctrl_shdxcallsign                = 10425;
  menu_ctrl_execute_config              = 10426;
  menu_ctrl_redoposscalls               = 10406; // 4.53.9
  menu_alt_ctrl_redoposscalls           = 10428; // Issue #20 -- long-path rotor turn

  menu_mainwindow_setfocus              = 10500;
  menu_insertmode                       = 10501;
  menu_cwspeedup                        = 10503;
  menu_cwspeeddown                      = 10504;
  menu_cqmode                           = 10505;
  menu_spmode_ortab                     = 10506;
  menu_ctrl_sendspot                    = 10507;
  menu_rescore                          = 10508;
  menu_send_message                     = 10509;
  menu_getserverlog                     = 10510;
  menu_clearserverlog                   = 10511;
  menu_compare_logs                     = 10512;
  menu_login                            = 10517;

  menu_clear_dupesheet_in_network       = 10515;
  menu_clear_multsheet_in_network       = 10516;

  menu_inactiveradio_cwspeedup          = 10513;
  menu_inactiveradio_cwspeeddown        = 10514;

 // menu_alt_transfreq                    = 10311;   // 4.47.3 remove
  menu_download_pota_parks              = 10607;  // issue #864
  menu_repeat_pota_parks               = 10608;  // repeat last logged parks for second operator
  menu_hamscore_resync                 = 10609;  // Issue #783 -- HamScore RTC: wipe server log + re-send all QSOs
  // menu_windows_hamscore is intentionally placed in the 10200-10219 auto-mapped
  // range as 10199 + Ord(tw_HAMSCOREWINDOW_INDEX) = 10199 + 20.  This lets the
  // existing CheckMenuItem in OpenTR4WWindow auto-toggle the menu checkmark and
  // lets the windows-menu dispatch in MainUnit auto-route open/close.
  menu_windows_hamscore                = 10219;  // Issue #783 Phase 4 -- HamScore status window toggle
  menu_home_page                        = 10606;
//  menu_send_bug                         = 10605;
  menu_wiki_rus                         = 10604;
  menu_download_latest_cty_dat             = 10603;  // 4.75.3
  menu_contents                         = 10602;
  menu_about                            = 10601;
  menu_historytxt                       = 10600;

  {accelerators id`s}
//  tr4w_accelerator_vktab                = 10650;
  tr4w_accelerator_vkreturn             = 10651;
  //  tr4w_accelerator_vkup                 = 10652;
  //  tr4w_accelerator_vkdown               = 10653;

  waveheader                            =
    #$52#$49#$46#$46#$24#$00#$00#$00 + #$57#$41#$56#$45#$66#$6D#$74#$20 +
    #$10#$00#$00#$00#$01#$00#$01#$00 + #$22#$56#$00#$00#$44#$AC#$00#$00 +
    #$02#$00#$10#$00#$64#$61#$74#$61 + #$00#$00#$00#$00;

var
  LogBadQSOString                       : Str80;
  LoadedPlugins                         : integer;
  PluginsArray                          : array[1..16] of array[0..31] of Char;
  MultBand                              : BandType;
  MultMode                              : ModeType;
//  tNTPServer                            : ShortString = 'pool.ntp.org';
{$IF MORSERUNNER}
  MorseRunnerWindow                     : HWND;
  MorseRunnerWindowsCounter             : integer;
  MorseRunner_MyCallsign                : HWND;
  MorseRunner_Callsign                  : HWND;
  MorseRunner_RST                       : HWND;
  MorseRunner_Number                    : HWND;
{$IFEND}

  tKeyerDebugWindowHandle               : HWND;
  tShowDomesticMultiplierName           : boolean;
  tRemMultsColumnWidth                  : integer;
  tInputDialogWarning                   : boolean;
  tInputDialogInteger                   : boolean;
  tInputDialogLowerCase                 : boolean;
  tInputDialogPassword                  : boolean;       // Issue #783 -- mask input as '*' bullets
  tInputDialogPreviousValue             : ShortString;
//  CMDLowerCase                          : ShortString;
  ClearQuickDisplayTimer                : Cardinal;
  DifferentContests                     : boolean;

  TotWinHandles                         : array[0..7, 0..3] of HWND;
  TotWinHandlesFilled                   : array[0..7, 0..3] of boolean;

  TotWinheadHandles                     : array[1..7] of HWND;
  tr4whandle                            : HWND;
  TR4WApplication                       : HWND;
  tr4w_WinClass                         : TWndClass = (Style: CS_DBLCLKS; hbrBackground: COLOR_BTNFACE + 1; {lpszMenuName: 'T'; } lpszClassName: tr4w_ClassName; );
  tr4w_main_menu                        : HMENU;
  tr4w_accelerators                     : hAccel;

  DupeInfoCallWindowCleared             : boolean = True;

  //   tr4w_CurrentThreadId            : DWORD;

     {Main window windows handles}
  NCWP                                  : Pointer;

//  CallWindowHandle                      : HWND;
//  ExchangeWindowHandle             : HWND;
//  RateWindowHandle                      : HWND;

//  RadioOneWindowHandle                  : HWND;
//  RadioTwoWindowHandle                  : HWND;

//  BandModeWindowHandle                  : HWND;
//  HourRateWindowHandle                  : HWND;
//  CodeSpeedWindowHandle                 : HWND;
//  DateWindowHandle                      : HWND;
//  NameSentWindowHandle                  : HWND;
//  LastQSOWindowHandle                   : HWND;
//  OpModeWindowHandle                    : HWND;
//  ClockWindowHandle                     : HWND;
//  UserInfoWindowHandle                  : HWND;
//  FullTimeWindowHandle                  : HWND;
//  QSONumberWindowHandle                 : HWND;
//  InsertWindowHandle                    : HWND;
//  TotalScoreWindowHandle                : HWND;
//  PTTStatusWindowHandle                 : HWND;
//  CountryNameWindowHandle               : HWND;
//  LocatorWindowHandle                   : HWND;
//  BeamHeadingWindowHandle               : HWND;
//  LocalTimeWindowHandle                 : HWND;
//  QIHeaderWindowHandle                  : HWND;
//  QsoInformationWindowHandle  : HWND;
//  MIHeaderWindowHandle                  : HWND;
//  MultiplierInformationWindowHandle: HWND;
//  QuickCommandWindowHandle              : HWND;

//  FreqOneWindowHandle         : HWND;
//  FreqTwoWindowHandle         : HWND;

//  AutoSendCountWindowHandle             : HWND;
//  B4StatusWindowHandle                  : HWND;
//  MasterStatusWindowHandle              : HWND;
//  NewMultIndicatorWindowHandle          : HWND;
  CPUButtonHandle                       : HWND = INVALID_HANDLE_VALUE;

//  _PossibleCallWindow                   : HWND;
  //  _EditableLogWindow                    : HWND;

//  _NewELogWindow                        : HWND;

//  TenMinutsWindow                       : HWND;
//  _PTTCounterWindow                     : HWND;

  RateProgressBar                       : HWND;
  LastProgressBar                       : HWND;

//  PaddleWindowHandle                    : HWND;
//  FootSwWindowHandle                    : HWND;
//  WinKey2WindowHandle                   : HWND;
//  CurrentOperatorWindowHandle           : HWND;

//  CQQSOCounterWindowHandle              : HWND;
//  SPQSOCounterWindowHandle              : HWND;

//  MyComputerIDWindowHandle              : HWND;
  FunctionKeysWindowHandles             : array[112..123] of HWND;

  MultsWindowsHandles1                  : array[Band160..Band10] of HWND;
  MultsWindowsHandles2                  : array[Band160..Band10] of HWND;
  MultWindowHandle1                     : HWND;
  MultWindowHandle2                     : HWND;

  QSONeedWindowsHandles1                : array[Band160..Band10] of HWND;
  QSONeedWindowsHandles2                : array[Band160..Band10] of HWND;
  QSONeedWindowHandle1                  : HWND;
  QSONeedWindowHandle2                  : HWND;
  DupeInfoCallWindowState               : DupeInfoState;
//  CQTotalWindowHandle                   : HWND;
//  QSOsWithThisStationWindowHandle       : HWND;
  IntitialExLoaded                      : boolean;
  DupeInfoCallWindowHandle              : HWND;

  TorDurationWindow                     : HWND;
  TorDurationPrBarWindow                : HWND;

var
  LogFrequencyEnable                    : boolean;
  NameFlagEnable                        : boolean = True;
  BoldFont                              : boolean = True;
//  DateFormat                            : Str10 = 'dd-MM-yy';
  ImportFromADIFThreadID                : Cardinal;
  tMutex                                : Cardinal;

  MainWindowEditHeight                  : integer;

  ws                                    : integer = 5;
  ws2                                   : integer;

  WindowSize                            : integer = 5;

  ColumnAutoSize                        : boolean = True;
  ColumnWidthOverride                   : array[LogColumnsType] of Integer;

  LinesInEditableLog                    : integer = 5;

//  StaticWindowHeight                    : integer;
  //EditableLogWindowHeight               : integer;
  MainWindowWidth                       : integer;
//  MainWindowHeight                      : integer;
  MainWindowCaptionAndHeader            : integer;
  MainWindowChildsWidth                 : integer;
  EditableLogHeight                     : integer;

  RightTopWidth                         : integer;

//  line1                                 : integer;
//  Line2                                 : integer;
//  Line3                                 : integer;
//  Line4                                 : integer;
//  Line5                                 : integer;
//  line6                                 : integer;
//  Line7                                 : integer;
//  line8                                 : integer;
  NoBorder                              : boolean;
  NoCaption                             : boolean;
  NoColumnHeader                        : boolean;
  FKButtonWidth                         : integer;

  tCRC32                                : longword = 0;
  VideoGameLength                       : integer;

  MesWindow                             : MesWindowType;
  ConfirmEditChanges                    : boolean = True;
  tEightBitsPerPixel                    : boolean;
  EditabledLogFocused                   : boolean = False;

  UTC                                   : SYSTEMTIME;
  CompleteCallsignMask                  : CallString;
  StationsCallsignsMask                 : CallString;
//  tLV_ITEM                              : TLVItem;
  LogHandle                             : HWND;
  CID_TWO_BYTES                         : array[0..1] of Char = (#73, #0);

//  NET_CLEARLOG_MESSAGE                  : DWORD = 3030001000;
  NET_LOGINFO_MESSAGE                   : DWORD = 3030002000;
  _COM                                  : PChar = '\\.\COM%u';

  ErmakSpecification                    : boolean;
//  sDISMESSAGE                           : array[0..4] of Char = ('D', 'I', 'S', 'C', #0);

//  tr4w_saddr                            : sockaddr_in = (sin_family: AF_INET);
  {Fonts}
  LuconSZLoadded                        : boolean;
  MainFontName                          : Str31 = 'Arial';
  MainCallsign                          : CallString;
  MainFont                              : HFONT;
  MainFixedFont                         : HFONT;

  MainWindowEditFont                    : HFONT;

  CATWindowFont                         : HFONT;

  MSSansSerifFont                       : HFONT;
  LucidaConsoleFont                     : HFONT;

  TerminalFont                          : HFONT;
  SymbolFont                            : HFONT;
  Fontstructure                         : tagLOGFONT;

  WAV_STOP_PTT_TIMER_IDENTIFIER         : integer;

  tLogIndex                             : integer;
  tShowGridlines                        : boolean;
  tWorkingAreaRect                      : TRect;

//  tr4w_CallWindowActive                 : boolean;
//  tr4w_ExchangeWindowActive             : boolean;

  tContestNameInComment                 : boolean;
  tr4w_TempRect                         : TRect;

  CWThreadCounter                       : Cardinal;
  CWThreadID                            : Cardinal;
  CWThreadHandle                        : HWND;
  BnadmapThread                         : HWND;
  BnadmapThreadID                       : Cardinal;

  {AutoCQ variables}
  tAutoCQMode                           : boolean;
  tAutoCQTimerID                        : Cardinal;
  tAutoSendMode                         : boolean;

  TR4W_PATH_NAME                        : FileNameType;
  TR4W_LOG_PATH_NAME                    : FileNameType;
  TR4W_LOG_FILENAME                     : FileNameType;
  TR4W_DOM_FILENAME                     : FileNameType;   // 4.100.2
  TR4W_CFG_FILENAME                     : FileNameType;
  TR4W_RST_FILENAME                     : FileNameType;
  TR4W_SYN_FILENAME                     : FileNameType;

  TR4W_DEFMESSAGES_FILENAME             : FileNameType;

  TR4W_INTERCOM_FILENAME                : FileNameType;
  TR4W_REMAININGMULTS_FILENAME          : FileNameType;
  TR4W_CTY_DAT_FILENAME                 : FileNameType;     // 4.75.3
  TR4W_INI_FILENAME                     : FileNameType;
  TR4W_CTY_FILENAME                     : FileNameType;
  TR4W_RFOBL_FILENAME                  : FileNameTYpe; // n4af 04.42.6
  TR4W_R150S_FILENAME                   : FileNameType;
  TR4W_INPUT_CFG_FILENAME               : FileNameType;

  TR4W_POS_FILENAME                     : FileNameType;
//  TR4W_WINKEYINI_FILENAME               : FileNameType;
  TR4W_BANDMAPBIN_FILENAME              : FileNameType;

  TR4W_TEMP_MP3_FILENAME                : FileNameType;
  TR4W_COMM_HELP_FILENAME               : FileNameType;
  TR4W_GET_MP3_FILENAME                 : FileNameType;

  TR4W_EXECONFIGFILE_FILENAME           : FileNameType;
  TR4W_MP3_PLAYER_FILENAME              : FileNameType;
  TR4W_ADIF_FILENAME                    : FileNameType;
  TR4W_DVP_RECORDER_FILENAME            : FileNameType;
//  TR4W_IODRIVER_FILENAME                : FileNameType;

  TR4W_FLOPPY_FILENAME                  : FileNameType {= 'C:\TR4W\LOGBACK.TRW'};
  TR4W_INITIALEX_FILENAME               : FileNameType {= 'INITIAL.EX'};
  TR4W_LATESTCFG_FILENAME               : FileNameType;

  TR4W_MP3PATH                          : FileNameType {= 'MP3'};
  TR4W_DVKPATH                          : FileNameType {= 'DVP'};

  TR4W_MMTTYPATH                        : FileNameType;

  TR4W_HAMLIB_DEBUG                     : boolean;
  TR4W_HAMLIB_ASYNC_ONLY                : boolean;  // Disable heartbeat — async callbacks only (testing)
  TR4W_HAMLIB_TRACE                     : boolean;  // Enable HamLib internal trace → target/hamlib_trace.log
  TR4W_TELNET_DEBUG                     : boolean;  // Issue #23 — log all DX cluster I/O + telnet-window writes (INFO, gated)

  TR4W_LC_FILENAME                      : PChar = 'LUCONSZ.TTF';

  CPUstart, CPUstop                     : int64;
  WindowsOSversion                      : Cardinal;

  tr4w_WindowsArray                     : array[WindowsType] of TWndEntry;
  tFontsColorsArray                     : array[0..1] of TColorsFontsEntry;

  tr4w_osverinfo                        : OSVERSIONINFO {= (dwOSVersionInfoSize: SizeOf(OSVERSIONINFO))};
  StickyKeysAtStartup                   : STICKYKEYS; // ny4i Issue 126
  Msg                                   : TMsg;
  EditingCallsignSent                   : boolean; //???????????? ??? autosend, ????? ?????????? backspace
  ControlAMode                          : boolean; //????? Ctrl+A
  StartCPU                              : DWORD;
  StopCPU                               : DWORD;

  IndexOfItemInLogForEdit               : integer;

  CursorBitmap                          : HBITMAP;
  tr4w_CustomCaret                      : boolean = True;

//  trWSAData                             : TWSAData;
  ConnectionCommand                     : Str20;
//  RICHED32DLLHANDLE                     : Cardinal;

type

  DXMultType =
    (
//    NoCountDXMults,
    NoDXMults,

    {DXCC ONLY}
    ARRLDXCCWithNoUSAOrCanada,
    ARRLDXCCWithNoARRLSections,
    ARRLDXCCWithNoUSACanadaKH6OrKL7,
    ARRLDXCCWithNoIOrIS0,
    ARRLDXCCWithNoJT,
    ARRLDXCC,

    {DXCC+WAE}
    CQDXCC,
    CQDXCCWithNoUSAOrCanada,
    CQDXCCWithNoHB9,
    CQDXCCWithNoOK,
    CQEuropeanCountries,
    CQUBAEuropeanCountries,
    CQNonEuropeanCountries,

    NorthAmericanARRLDXCCWithNoUSACanadaOrkL7,
    NonSouthAmericanCountries,
    PACCCountriesAndPrefixes,
//    CQNonEuropeanCountriesAndWAECallRegions,
    BlackSeaCountries
    );

  PrefixMultType =          // NOTE: ORDER MUST MATCH PREFIXMULTSTRING ARRAY BELOW 4.67.9
    (
    NoPrefixMults,
    AsianPrefixes,
    BelgiumPrefixes,
    CallSignPrefix,
    IndonesianDistricts,       // 4.64.1
    MongolianCallSignPrefix,
    NonSouthAmericanPrefixes,
    NorthAmericanPrefixes,
    Prefix,
    SACDistricts,
    SouthAmericanPrefixes,
    SouthAndNorthAmericanPrefixes,
    GCStation,
    CQNonEuropeanCountriesAndWAECallRegions,
    RussianPrefixes

    );

  ZoneMultType =
    (
    NoZoneMults,
    CQZones,
    ITUZones,
    JAPrefectures,
    BranchZones,
    EUHFCYear,
    RFChampionchipZones
    );
   // 4.67.9 NOTE: ORDER MUST MATCH PREFIXMULTTYPE (ABOVE)
const
  PrefixMultStringArray                 : array[PrefixMultType] of PChar =
    (
    'NONE',
    'ASIAN PREFIXES',
    'BELGIUM PREFIXES',
    'CALLSIGN',
    'Indonesian Districts',     // 4.64.1
    'MONGOLIAN CALLSIGN PREFIX',
    'NON SOUTH AMERICAN PREFIXES',
    'NORTH AMERICAN PREFIXES',
    'PREFIX',
    'SAC DISTRICTS',
    'SOUTH AMERICAN PREFIXES',
    'SOUTH AND NORTH AMERICAN PREFIXES',
    'GC STATION',
    'CQ NON EUROPEAN COUNTRIES AND WAE',
    'RUSSIAN PREFIXES'
       );
type
  DomesticMultType =
    (
    NoDomesticMults,
    WYSIWYGDomestic,
    IOTADomestic,
    GridSquares,
    GridFields,
    DOKCodes,
    DomesticFile,
    RDADistrict,
    NumericID
    );

  QSOPointMethodType =
    (
     NoQSOPointMethod, //{ Score = 0 }
    AllAsianQSOPointMethod,
    ARCIQSOPointMethod,
    ARIQSOPointMethod,
    ARRLFieldDayQSOPointMethod,
    ARRLDIGIQSOPointMethod,
    ARRL160QSOPointMethod,
    ARRL10QSOPointMethod,
    ARRLDXQSOPointMethod,
    ARRLVHFJUNPointMethod,
    ARRLVHFSSPointMethod,
    BalticQSOPointMethod,
    BWQPQSOPointMethod,
    CISQSOPointMethod,
    CQ160QSOPointMethod,
    CQMQSOPointMethod,
    CQVHFQSOPointMethod,
    CQWWQSOPointMethod,
    CQWWRTTYQSOPointMethod,
    CQWPXQSOPointMethod,
    CQWPXRTTYQSOPointMethod,
    CroatianQSOPointMethod,
    EuropeanFieldDayQSOPointMethod,
    EuropeanSprintQSOPointMethod,
    EuropeanVHFQSOPointMethod,
    TeslaQSOPointMethod,
    FistsQSOPointMethod,
    FOCMarathonQSOPointMethod,
    HADXQSOPointMethod,
    ONY,
    YUDXQSOPointMethod,     // 4.57.5
    UKEIQSOPointMethod,    // 4.58.2
    HelvetiaQSOPointMethod,
    IARUQSOPointMethod,
    InternetSixQSOPointMethod,
    IOTAQSOPointMethod,
    JapanInternationalDXQSOPointMethod,
    KCJQSOPointMethod,
    LABREQSOPointMethod,
    LQPQSOPointMethod,
    MMCQSOPOINTMETHOD,
    NZFieldDayQSOPointMethod,
    OKDXQSOPointMethod,
    RAEMQSOPointMethod,
    RACQSOPointMethod,
    ThreePhoneFiveCWFourRTTY,   // 4.57.1 issue  242
    RSGBQSOPointMethod,
    RSGB160Method,
    RussianDXQSOPointMethod,
    RDAQSOPointMethod,
    SalmonRunQSOPointMethod,
    ScandinavianQSOPointMethod,
    IndonesianQSOPointMethod,
    SouthAmericanQSOPointMethod,
    SouthAmericanWWQSOPointMethod,
    SLFivePointQSOMethod,
    StewPerryQSOPointMethod,
    TenTenQSOPointMethod,
    TOECQSOPointMethod,
    UBAQSOPointMethod,
    UkrainianQSOPointMethod,
    VKZLQSOPointMethod,
    WAEQSOPointMethod,
    WAGQSOPointMethod,
    WWLQSOPointMethod,
    YL_ARCK_YL,
    YODXQSOPointMethod,
    AlwaysOnePointPerQSO, //{ Ignores dupes }
    OnePointPerQSO,
    TwoPointsPerQSO,
    ThreePointsPerQSO,
    TwoPhoneFourCW,
    OnePhoneTwoCW,
    ThreePhoneFiveCW,
    TwoPhoneThreeCW,
    TenPointsPerQSO,
    OneEuropeTwoOther,
    CupRFMethod,
    UA4WMethod,
    ChampionshipRFMethod,
    ChampionshipUkrMethod,
    RadioVHFFDQSOPointMethod,
    LZDXQSOPointMethod,
    OldNewYearQSOPointMethod,
    ChampionshipRFASMethod,
    YouthChampionshipRFMethod,
    RegionOneFieldDayRCCQSOPointMethod,
    GACWWWSACWQSOPointMethod,
    WWPMCQSOPointMethod,
    JTDXQSOPointMethod,
    Radio160QSOPointMethod,
    ArktikaSpringQSOPointMethod,
    GagarinCupQSOPointMethod,
    UNDXQSOPointMethod,
    KingOfSpainQSOPointMethod,
    WRTCQSOPointMethod,
    R9WUW9WKMemorialQSOPointMethod,
    PCCQSOPointMethod,
    REFQSOPointMethod,
    RadioMemoryQSOPointMethod,
    BSCIQSOPointMethod,
    CQMMQSOPointMethod,
    OZHCRVHFQSOPointMethod,
    MakrothenQSOPointMethod,
    NCQSOPointMethod,
    ALRSUA1DZCupQSOPointMethod,
    HolyLand,               // 4.69.1
    OQPQSOPointMethod,                     // 4.70.
    PortugalDay,    // 4.70.4
    RPX ,        // 4.72.2
    DLRTTY ,      // 4.72.5
    JAKARTARTTY,     // 4.74.2
    TRCDIGITAL,       // 4.75.2
    PAQSOPOINTMETHOD, // 4.74.3
    INQsoPoinrMethod,  // 4.88.2
    XERTTY,           // 4.77.5
    OKOMSSBQSOPointMethod, // 4.80.1
    uQRQCPM,      // 4.82.3
    OKOMRTTY,     // 4.83.4
    SRRQSOPOINTMETHOD, // 4.90.4
    YBFT8QP,              // 4.90.7
    WWDIGIQP,               // 4.90.8
    IRTSQSOPointMethod,     // 4.93.1
    EUDXQSOPointMethod,     // 4.95.6
    BCQPQSOPointMethod,      // 4.97.6
    MWCQP,
    VAQSOPointMethod,
    YOTAQSOPointMethod,
    HAMSPIRIT ,
 //   RSGBDXMethod,
    NYQPQP,
    RCCVHFQP,
    CFOQP,
    RTCQSOPointMethod  // Haversine grid-center distance, tier 1/2/3/4 @ 2000/4000/8000 km
    );

const

  DomesticMultStringArray               : array[DomesticMultType] of PChar =
    (
    'NONE',
    'WYSIWYG',
    'IOTA',
    'GRID SQUARES',
    'GRID FIELDS',
    'DOK CODES',
    'DOMESTIC FILE',
    'RDA DISTRICT',
    'NUMERIC ID'
    );

  QSOPointMethodArray                   : array[QSOPointMethodType] of PChar =
    (
    'NONE', //    NoQSOPointMethod, { Score = 0 }
    'ALL ASIAN', //    AllAsianQSOPointMethod,
    'ARCI', //    ARCIQSOPointMethod,
    'ARI DX', //    ARIQSOPointMethod,
    'ARRL FD', //    ARRLFieldDayQSOPointMethod,
    'ARRL DIGI', // ARRLDIGIQSOPointMethod
    'ARRL 160', //    ARRL160QSOPointMethod,
    'ARRL 10', //    ARRL10QSOPointMethod,
    'ARRL DX', //    ARRLDXQSOPointMethod,
    'ARRL VHF JUN', //    ARRLVHFQSOPointMethod,
    'ARRL VHF SS', //    ARRLVHFSSPointMethod,
    'BALTIC', //    BalticQSOPointMethod,
    'BWQP', // BWQPQSOPointMethod,
    'CIS', //    CISQSOPointMethod,
    'CQ 160', //    CQ160QSOPointMethod,
    'CQ M', //    CQMQSOPointMethod,
    'CQ VHF', //    CQVHFQSOPointMethod,
    'CQ WW', //    CQWWQSOPointMethod,
    'CQ WW RTTY', //    CQWWRTTYQSOPointMethod,
    'CQ WPX', //    CQWPXQSOPointMethod,
    'CQ WPX RTTY', //    CQWPXRTTYQSOPointMethod,
    'CROATIAN', //    CroatianQSOPointMethod,
    'EUROPEAN FIELD DAY', //    EuropeanFieldDayQSOPointMethod,
    'EUROPEAN SPRINT', //    EuropeanSprintQSOPointMethod,
    'EUROPEAN VHF', //    EuropeanVHFQSOPointMethod,
    'HF-TESLA', //    TeslaQSOPointMethod,
    'FISTS', //    FistsQSOPointMethod,
    'FOC MARATHON' , // FOCMarathonPointMethod,
    'HA DX', //    HADXQSOPointMethod,
    'ONY',
    'YUDX', //     YUDXQSOPointMethod,        // 4.57.5
    'UKEI', //    UK-EIQSOPointMethod,       // 4.58.2
    'HELVETIA', //    HelvetiaQSOPointMethod,
    'IARU', //    IARUQSOPointMethod,
//    'IN',
    'INTERNET SIX', //    InternetSixQSOPointMethod,
    'IOTA', //    IOTAQSOPointMethod,
    'JA INTERNATIONAL DX', //    JapanInternationalDXQSOPointMethod,
    'KCJ', //    KCJQSOPointMethod,
    'LQP',//    'MQP', //    MQPQSOPointMethod,
    'MARCONI MEMORIAL', // MMCQsoPointMethod,      //n4af
    'NZ FIELD DAY', //    NZFieldDayQSOPointMethod,
    'OK DX', //    OKDXQSOPointMethod,
    'RAEM', //    RAEMQSOPointMethod,
    'CANADA WINTER', //    RACQSOPointMethod,
    'YOK', // Youth of Kazakstan
    'RSGB', //    RSGBQSOPointMethod,
    'RSGB 160', // rsgb160method,
    'RUSSIAN DX', //    RussianDXQSOPointMethod,
    'RDA', //    RDAQSOPointMethod,
    'SALMON RUN', //    SalmonRunQSOPointMethod,
    'SCANDINAVIAN', //    ScandinavianQSOPointMethod,
    'INDONESIAN', // IndonesianQSOPointMethod,        // 4.64.1
    'SOUTH AMERICAN', //    SouthAmericanQSOPointMethod,
    'SOUTH AMERICAN WW', //    SouthAmericanWWQSOPointMethod,
    'SL FIVE POINT', //    SLFivePointQSOMethod,
    'STEW PERRY', //    StewPerryQSOPointMethod,
    'TEN TEN', //    TenTenQSOPointMethod,
    'TOEC', //    TOECQSOPointMethod,
    'UBA', //    UBAQSOPointMethod,
    'UKRAINIAN', //    UkrainianQSOPointMethod,
    'VK ZL', //    VKZLQSOPointMethod,
    'WAE', //    WAEQSOPointMethod,
    'WAG', //    WAGQSOPointMethod,
    'WWL', //    WWLQSOPointMethod,
    'YL_ARCK_YL',
    'YO DX', //    YODXQSOPointMethod,
    'ALWAYS ONE', //    AlwaysOnePointPerQSO, { Ignores dupes }
    'ONE POINT PER QSO', //    OnePointPerQSO,
    'TWO POINTS PER QSO', //    TwoPointsPerQSO,
    'THREE POINTS PER QSO', //    ThreePointsPerQSO,
    'TWO PHONE FOUR CW', //    TwoPhoneFourCW,
    'ONE PHONE TWO CW', //    OnePhoneTwoCW,
    'THREE PHONE FIVE CW', //    ThreePhoneFiveCW,
    'TWO PHONE THREE CW', //    TwoPhoneThreeCW,
    'TEN POINTS PER QSO', //    TenPointsPerQSO,
    'ONE EUROPE TWO OTHER', //    OneEuropeTwoOther,
    'RF CUP', //    CupRFMethod,
    'R4W', //    UA4WMethod,
    'RF CHAMP', //    ChampionshipRFMethod,
    'UKR CHAMP', //    ChampionshipUkrMethod,
    'RADIO VHF FD', //    RadioVHFFDQSOPointMethod,
    'LABRE', //labreqsopointmethod,
    'LZ', //    LZDXQSOPointMethod,
    'ONY', //    OldNewYearQSOPointMethod,
    'RF AS CHAMP', //    ChampionshipRFASMethod,
    'SRR JR', //    YouthChampionshipRFMethod,
    'REG 1 RCC', //    RegionOneFieldDayRCCQSOPointMethod,
    'GACWWWSA', //    GACWWWSACWQSOPointMethod,
    'WW PMC', //    WWPMCQSOPointMethod,
    'JT', //    JTDXQSOPointMethod
    'RADIO 160',
    'ARKTIKA-SPRING',
    'GAGARIN-CUP',
    'UN DX',
    'KING OF SPAIN',
    'WRTC',
    'R9W-UW9WK-MEMORIAL',
    'PCC',
    'REF',
    'RADIO-MEMORY',
    'BSCI',
    'CQMM',
   // 'SASPRINT',
    'OZHCR-VHF',
    'MAKROTHEN',
    'NC QSO Party',
    'ALRS-UA1DZ-CUP',
     'HOLYLAND',       // 4.69.1
     'OQPQSOPOINTMETHOD',             // 4.70.4
     'PORTUGALDAY',     // 4.71.4
     'RPX' ,            // 4.72.2
     'DL-RTTY',         // 4.72.5
     'JAKARTA-RTTY',     // 4.74.2
     'TRC-DIGITAL',      // 4.75.2
     'PA QSO PARTY',      // 4.74.3
     'IN QSO PARTY',      // 4.88.2
     'XE RTTY',           // 4.77.5
     'OKOM SSB',          // 4.80.1
     'UQRQCPM',           // 4.82.3
     'OKOMRTTY',           // 4.83.4
     'SRRQSOPOINTMETHOD',  // 4.90.4
     'YBFT8QP',               // 4.90.7
     'WWDIGIQP',              // 4.90.8
     'IRTS',   //  IRTSQSOPointMethod    // 4.93.1
     'EUDX',    // 4.95.6
     'MWCQP',
     'BC QSO PARTY',      // 4.97.6
     'VA QSO PARTY',
     'YOTA',
     'HAMSPIRIT', // 4.115.5
      'NYQPQP',
      'RCCVHFQP',
      'CFOQP',
      'RTC'                // Issue #902
    );

{ When adding a new ExchangeType, please add a handler in the case statement in GetMyExchangeForExport
  in PostUnit for the ADIF export as well as in tGenerateLogPortionOfCabrilloFile in PostUnit for the Cabrillo file.
  ny4i }
type
  ExchangeType = (
  UnknownExchange,
    NoExchangeReceived,
    AgeAndQSONumberExchange, //WLI
    QSONumberAndAgeExchange,   // 4.119.1
    CheckAndChapterOrQTHExchange,
    ClassDomesticOrDXQTHExchange,
    KidsDayExchange,
    NameAndDomesticOrDXQTHExchange,
    NameQTHAndPossibleTenTenNumber,
    NameAndPossibleGridSquareExchange,
    NZFieldDayExchange,
    GridExchange,
    Grid2Exchange,
    RSTAndGrid3Exchange,
    QSONumberAndPreviousQSONumber, //WLI
    QSONumberAndGeoCoordinates, //WLI
    QSONumberAndCoordinatesSum, //WLI
    QSONumberAndZone,
    QSONumberAndNameExchange,
    QSONumberAndGridSquare, //WLI
    QSONumberAndPossibleDomesticQTHExchange, {KK1L: 6.73 For MIQP originally}
    QSONumberDomesticOrDXQTHExchange,
    QSONumberDomesticQTHExchange,
    QSONumberNameChapterAndQTHExchange,
    QSONumberNameDomesticOrDXQTHExchange,
    QSONumberPrecedenceCheckDomesticQTHExchange,
    RSTAgeExchange,
    RSTALLJAPrefectureAndPrecedenceExchange,
    RSTAndContinentExchange,
    RSTAndDOMESTICQTH,       //n4af
    RSTAndFOCNumberExchange, //n4af
    RSTAndGridExchange,
    RSTAndOrGridExchange,
    RSTAndPOTAPark,
    RSTAndQSONumberOrDomesticQTHExchange,
    RSTAndSerialNumberAndGridandPossibleMemberNumber,  // 4.88.3
    RSTAndPostalCodeExchange,
    RSTDomesticOrDXQTHExchange,
    RSTDomesticQTHExchange,
    RSTDomesticQTHOrQSONumberExchange,
    RSTNameAndQTHExchange,
    RSTNameAndPossibleFOCNumber,
    RSTPossibleDomesticQTHAndPower,
    RSTPowerExchange,
    RSTPrefectureExchange,
    RSTQSONUMBEREXCHANGE,
    RSTQSONumberAndDomesticQTHExchange,
    RSTQSONumberAndGridSquareExchange,
    RSTQSONumberAndPossibleDomesticQTHExchange,
    RSTQSONumberAndRandomCharactersExchange,
    RSTQSONumberOrDomesticQTHExchange,  //n4af 4.36
    RSTQTHNameAndFistsNumberOrPowerExchange,
    RSTQTHExchange,
    RSTZoneAndPossibleDomesticQTHExchange,
    RSTZoneExchange,
    RSTZoneOrSocietyExchange,
    RSTLongJAPrefectureExchange, {KK1L: 6.72 JA}
    RSTAgeAndPossibleSK, //WLI
    RSTZoneOrDomesticQTH, //WLI
    RSTAndQSONumberOrFrenchDepartmentExchange,
    RSTAndGridSquareOrRDAExchange

    ); //WLI

const
  ActiveExchangeArray                   : array[ExchangeType] of PChar =
    (
     'UNKNOWN',
    'NONE',
  	'AGE AND QSO NUMBER',
    'QSO NUMBER AND AGE', // 4.119.1
    'CHECK AND CHAPTER OR QTH EXCHANGE',
    'CLASS DOMESTIC OR DX QTH',
    'KIDS DAY EXCHANGE',
    'NAME DOMESTIC OR DX QTH',
    'NAME QTH AND POSSIBLE TEN TEN NUMBER',
    'NAME AND POSSIBLE GRID SQUARE',
    'NZ FIELD DAY',
    'GRID',
    'GRID2',
    'RST AND GRID3',
    'QSO NUMBER AND PREVIOUS QSO NUMBER',
    'QSO NUMBER AND GEO COORDINATES',
    'QSO NUMBER AND COORDINATES SUM',
    'QSO NUMBER AND ZONE',
    'QSO NUMBER AND NAME',
    'QSO NUMBER AND GRID',
    'QSO NUMBER AND POSSIBLE DOMESTIC QTH',
    'QSO NUMBER DOMESTIC OR DX QTH',
    'QSO NUMBER DOMESTIC QTH',
    'QSO NUMBER NAME CHAPTER AND QTH',
    'QSO NUMBER NAME DOMESTIC OR DX QTH',
    'QSO NUMBER PRECEDENCE CHECK SECTION',
    'RST AGE',
    'RST ALL JA PREFECTURE AND PRECEDENCE',
    'RST AND CONTINENT',
    'RST AND DOMESTIC QTH',       //n4af
  	'RST AND FOC NUMBER',
    'RST AND GRID',
    'RST AND OR GRID',
    'RST AND POTA PARK',
    'RST AND QSO NUMBER OR DOMESTIC QTH',
    'RST QSO NUMBER AND GRID AND POSSIBLE NUMBER', // 4.88.3
    'RST AND POSTAL CODE',
    'RST DOMESTIC OR DX QTH',
    'RST DOMESTIC QTH',
    'RST DOMESTIC QTH OR QSO NUMBER',
    'RST NAME AND QTH',
    'RST NAME AND POSSIBLE FOC NUMBER',
    'RST POSSIBLE DOMESTIC QTH AND POWER',
    'RST POWER',
    'RST PREFECTURE',
    'RST QSO NUMBER',
    'RST QSO NUMBER AND DOMESTIC QTH',
    'RST QSO NUMBER AND GRID SQUARE',
    'RST QSO NUMBER AND POSSIBLE DOMESTIC QTH',
    'RST QSO NUMBER AND RANDOM CHARACTERS',
    'RST QSO NUMBER OR DOMESTIC QTH',
    'RST QTH NAME AND FISTS NUMBER OR POWER',
    'RST QTH',
    'RST ZONE AND POSSIBLE DOMESTIC QTH',
    'RST ZONE',
    'RST ZONE OR SOCIETY',
    'RST LONG JA PREFECTURE',
    'RST AGE AND POSSIBLE SK',
    'RST ZONE OR DOMESTIC QTH',
    'RST AND QSO NUMBER OR FRENCH DEPARTMENT',
    'RST AND GRID SQUARE OR RDA'
    )
    ;
type
  TUSQSOPartyRecord = record
{(*}
    InsideStateDOMFile  : PChar;
//    OutsideStateDOMFile : PChar;
    StateName           : Pchar;
  end;

const
QSOPartiesCount = 20;

  QSOParties                         : array[1..QSOPartiesCount] of TUSQSOPartyRecord =
  (

  (InsideStateDOMFile:'minnesota';  {OutsideStateDOMFile:'MINNESOTA';  }StateName:'MN'),
  (InsideStateDOMFile:'michigan';   {OutsideStateDOMFile:'MICHIGAN';   }StateName:'MI'),
  (InsideStateDOMFile:'newyork';    {OutsideStateDOMFile:'NEWYORK';    }StateName:'NY'),
  (InsideStateDOMFile:'texas';      {OutsideStateDOMFile:'TEXAS';      }StateName:'TX'),
  (InsideStateDOMFile:'ohio';       {OutsideStateDOMFile:'OHIO';       }StateName:'OH'),
  (InsideStateDOMFile:'california'; {OutsideStateDOMFile:'CALIFORNIA'; }StateName:'CA'),
  (InsideStateDOMFile:'wisconsin';  {OutsideStateDOMFile:'WISCONSIN';  }StateName:'WI'),
  (InsideStateDOMFile:'tennessee';  {OutsideStateDOMFile:'TENNESSEE';  }StateName:'TN'),
  (InsideStateDOMFile:'washington'; {OutsideStateDOMFile:'WASHINGTON'; }StateName:'WA'),  //n4af 4.41.1
  (InsideStateDOMFile:'seven';      {OutsideStateDOMFile:'SEVEN';      }StateName:'7th area'),
  (InsideStateDOMFile:'florida';    {OutsideStateDOMFile:'FLORIDA';    }StateName:'FL'),
  (InsideStateDOMFile:'colorado';   {OutsideStateDOMFile:'COLORADO';   }StateName:'CO'),
  (InsideStateDOMFile:'nc';         {OutsideStateDOMFile:'NC';         }StateName:'NC'),
  (InsideStateDOMFile:'pa';         {OutsideStateDOMFile:'PA';         }StateName:'PA'),    // 4.74.3
  (InsideStateDOMFile:'in';         {OutsideStateDOMFile:'IN';         }StateName:'IN'),
  (InsideStateDOMFile:'ve7';        {OutsideStateDOMFile:'VE7';        }StateName: 'VE7'),
  (InsideStateDOMFile:'va';         {OutsideStateDOMFile:'VA';         }StateName:'VA'),
  (InsideStateDOMFile:'in7qpne';    {OutsideStateDOMFile:'IN7QPNE';    }StateName:'IN7QPNE'),
  (InsideStateDOMFile:'arizona';    {OutsideStateDOMFile:'ARIZONA';    }StateName:'AZ'),
  (InsideStateDOMFile:'missouri';   {OutsideStateDOMFile:'MISSOURI';   }StateName:'MO')
  );
{*)}

  type
    TContestInfo = record
{(*}
    {01}Name    : Pchar;
    {04}Email   : PChar;
    {04}DF      : PChar;
    {02}WA7BNM  : WORD;
//    {04}SK3BG   : PChar;

    {02}QRZRUID : Word;
    {01}PxM     : PrefixMultType;
    {01}ZnM     : ZoneMultType;
    {01}AIE     : InitialExchangeType;{ActiveInitialExchange}
    {01}DM      : DomesticMultType;

    {01}P       : Byte;//US QSO Party
    {01}AE      : ExchangeType;
    {01}XM      : DXMultType;
    {01}QP      : QSOPointMethodType;
    {??}ADIFName: PChar;  // If blank, use the name.
    {??}CABName : PChar;  // If blank, use the name.
    // True when this contest permits the same station to legitimately
    // submit multiple QSOs on the same band+mode with different QTH
    // (mobile, rover, county-line).  Used by ImportFromADIF to suppress
    // post-import dupe-flagging for follow-up records.  Default False;
    // set True only for the single-state QSO parties (multi-state QPs
    // such as 7QP/NEQP are out of scope until per-state handling lands).
    {01}CountyLineAllowed : Boolean;

    // Human-friendly contest name for reports (sourced from WA7BNM cabnames).
    // If blank, use ContestTypeSA[ct].
    {??}FriendlyName : PChar;
{*)}
    end;
{
    TContestMults = record
      DomM: DomesticMultType;
      DXM: DXMultType;
      ZnM: ZoneMultType;
      PxM: PrefixMultType;
    end;
}

// NOTE This array below and ContestTypeSA have to be in the same order
// This really should be setup so the name of the contest is the first parameter sothere is only one array rather
// than a parallel array. NY4I Issue 222
{ Note - # entries FOUR ARRAYS must match:
 Contest Type ~  Line #768
 QSO Point Method ` 3637
 ContestTypeSA  ` 3110
 Contests Boolean array ~ 3321
 }
  const
    ContestsArray                       : array[ContestType] of TContestInfo =
      (

 (Name: 'DUMMY CONTEST';               Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: UnknownExchange;                             XM:NoDXMults; QP:NoQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 (Name: '7QP';                         Email: nil;                      DF: 'seven_cty';         WA7BNM:  404; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 10;AE: RSTDomesticOrDXQTHExchange;                  XM:NoDXMults; QP:TwoPhoneThreeCW; ADIFName:'7QP';   CABName:''; FriendlyName: '7th Call Area QSO Party'),
 (Name: 'ALL ASIAN CW';                Email: nil;                      DF: nil;                 WA7BNM:   47; {SK3BG: 'allasia';    } QRZRUID: 146 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAgeExchange;                              XM:NoDXMults; QP:AllAsianQSOPointMethod; ADIFName:'ALL-ASIAN-DX-CW';   CABName:''; FriendlyName: 'All Asian DX Contest, CW'),
 (Name: 'ALL ASIAN SSB';               Email: nil;                      DF: nil;                 WA7BNM:  102; {SK3BG: 'allasia';    } QRZRUID: 146 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAgeExchange;                              XM:NoDXMults; QP:AllAsianQSOPointMethod; ADIFName:'AL-ASIAN-DX-PHONE';   CABName:''; FriendlyName: 'All Asian DX Contest, Phone'),
 ({Name: 'ALL JA';                     }Email: nil;                      DF: 'allja';             WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTALLJAPrefectureAndPrecedenceExchange;     XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'AP-SPRINT';                  }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: 'asiapacs';   } QRZRUID: 77  ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                               XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'ARCI';                       }Email: nil;                      DF: 's50p12';            WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTPossibleDomesticQTHAndPower;              XM:ARRLDXCCWithNoUSACanadaKH6OrKL7; QP:ARCIQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'ARI-DX';                     }Email: nil;                      DF: 'ari';               WA7BNM:    9; {SK3BG: nil;          } QRZRUID: 85  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:ARRLDXCCWithNoIOrIS0; QP:ARIQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARI International DX Contest'),
 ({Name: 'ARRL-10';                    }Email: '10meter@arrl.org';       DF: 'arrl10';            WA7BNM:  199; {SK3BG: 'arrl10';     } QRZRUID: 14  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCCWithNoUSACanadaKH6OrKL7; QP:ARRL10QSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARRL 10-Meter Contest'),
 ({Name: 'ARRL DIGI';                  }Email: 'contests@arrl.org';      DF: nil;                 WA7BNM:  716;                         QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: GridInitialExchange; DM: NoDomesticMults {GridFields};    P: 0; AE: Grid2Exchange;                               XM:NoDXMults; QP:ARRLDIGIQSOPointMethod; ADIFName:'';   CABName:'ARRL-DIGI'; FriendlyName: 'ARRL Inter. Digital Contest'),    // Issue 577
 ({Name: 'ARRL-160';                   }Email: '160meter@arrl.org';      DF: 'arrlsect';          WA7BNM:  194; {SK3BG: 'arrl160';    } QRZRUID: 22  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticOrDXQTHExchange;                  XM:NoDXMults; QP:ARRL160QSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARRL 160-Meter Contest'),
 ({Name: 'ARRL-DX-CW';                 }Email: 'DXCW@arrl.org';          DF: nil;                 WA7BNM:  256; {SK3BG: 'arrlidx';    } QRZRUID: 335 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTPowerExchange;                            XM:NoDXMults; QP:ARRLDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARRL Inter. DX Contest, CW'),
 ({Name: 'ARRL-DX-SSB';                }Email: 'DXPhone@arrl.org';       DF: nil;                 WA7BNM:  289; {SK3BG: 'arrlidx';    } QRZRUID: 334 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTPowerExchange;                            XM:NoDXMults; QP:ARRLDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARRL Inter. DX Contest, SSB'),
 ({Name: 'ARRL-SS-CW';                 }Email: 'SSCW@arrl.org';          DF: 'arrlsect';          WA7BNM:  177; {SK3BG: 'arrlnoss';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: CheckSectionInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberPrecedenceCheckDomesticQTHExchange; XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'ARRL Sweepstakes Contest, CW'),
 ({Name: 'ARRL-SS-SSB';                }Email: 'SSPhone@arrl.org';       DF: 'arrlsect';          WA7BNM:  178; {SK3BG: 'arrlnoss';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: CheckSectionInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberPrecedenceCheckDomesticQTHExchange; XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'ARRL Sweepstakes Contest, SSB'),
 ({Name: 'ARRL VHF JAN';              }Email: nil;                      DF: nil;                 WA7BNM:  231; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridSquares;     P: 0; AE:RSTandorGridExchange;                      XM:NoDXMults; QP:ARRLVHFJUNPointMethod; ADIFName:'ARRL-VHF-JAN';   CABName:''; FriendlyName: 'ARRL January VHF Contest'),
 ({Name: 'ARRL VHF JUN';               }Email: nil;                      DF: nil;                 WA7BNM:   43; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridSquares;     P: 0; AE:RSTandorGridExchange;                      XM:NoDXMults; QP:ARRLVHFJUNPointMethod; ADIFName:'ARRL-VHF-JUN';   CABName:''; FriendlyName: 'ARRL June VHF Contest'),
 ({Name: 'ARRL VHF SEP';                }Email: nil;                      DF: nil;                 WA7BNM:  113; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridSquares;     P: 0; AE: RSTandorGridExchange;                      XM:NoDXMults; QP:ARRLVHFJUNPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'ARRL September VHF Contest'),
 ({Name: 'ARIZONA QSO PARTY';          }Email: 'info@azqp.org';          DF: 'arizona_cty';            WA7BNM:  482; {SK3BG: nil;       } QRZRUID: 0    ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 19; AE: RSTDomesticOrDXQTHExchange;                  XM:ARRLDXCCWithNoUSAOrCanada;  QP:OnePhoneTwoCW; ADIFName:'AZ-QSO-PARTY';   CABName:'AZ-QSO-PARTY'; FriendlyName: 'Arizona QSO Party'),        
 ({Name: 'BALTIC';                     }Email: nil;                      DF: nil;                 WA7BNM:   28; {SK3BG: nil;          } QRZRUID: 161 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:BalticQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Baltic Contest'),
 ({Name: 'BWQP';                       }Email: nil;                      DF: nil;                 WA7BNM: 0000;      {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults;    P: 0; AE: RSTNameAndQTHExchange;              XM:NoDXMults; QP:BWQPQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'CIS';                        }Email: nil;                      DF: 'cis';               WA7BNM:  197; {SK3BG: nil;          } QRZRUID: 500 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC; QP:CISQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CIS DX Contest, CW'),
 ({Name: 'CQP';                        }Email: nil;                      DF: 'california_cty';    WA7BNM:  140; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;   P: 6 ;AE: QSONumberDomesticOrDXQTHExchange;                    XM:NoDXMults; QP:TwoPhoneThreeCW; ADIFName:'';   CABName:''; CountyLineAllowed: True; FriendlyName: 'California QSO Party'),           //n4af
 ({Name: 'COUNTY HUNTER';              }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQTHExchange;                              XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'General County Hunting Log'),
 ({Name: 'CQ-160-CW';                  }Email: '160CW@kkn.net';          DF: 's48p14dc';          WA7BNM:  232; {SK3BG: 'cqww160';    } QRZRUID: 311 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE:RSTZoneOrDomesticQTH;                          XM:CQDXCCWithNoUSAOrCanada; QP:CQ160QSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ 160-Meter Contest, CW'),     // 4.77.6
 ({Name: 'CQ-160-SSB';                 }Email: '160SSB@kkn.net';         DF: 's48p14dc';          WA7BNM:  259; {SK3BG: 'cqww160';    } QRZRUID: 312 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZoneOrDomesticQTH;                         XM:CQDXCCWithNoUSAOrCanada; QP:CQ160QSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ 160-Meter Contest, SSB'),           // 4.77.6
  ({Name: 'CQ-M';                       }Email: nil;                      DF: nil;                 WA7BNM:   14; {SK3BG: 'cqmidxc';    } QRZRUID: 126 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:CQDXCC{ARRLDXCC};  QP:CQMQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ-M International DX Contest'),
 ({Name: 'CQ-VHF';                     }Email: nil;                      DF: nil;                 WA7BNM:   73; {SK3BG: 'cqwwvhf';    } QRZRUID: 363 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM:  GridSquares;     P: 0; AE: RSTandorGridExchange;                      XM:NoDXMults; QP:CQVHFQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ Worldwide VHF SSB/CW Contest'),
// ({Name: 'WWDIGI';                     }Email: 'director@ww-digi.com';   DF: nil;                 WA7BNM:  650;                         QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: GridInitialExchange; DM: GridSquares; P: 0; AE: Grid2Exchange;
 ({Name: 'CQ-WPX-CW';                  }Email: 'cw@cqwpx.com';           DF: nil;                 WA7BNM:   29; {SK3BG: nil;          } QRZRUID: 18  ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:CQWPXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ WW WPX Contest, CW'),
 ({Name: 'CQ-WPX-SSB';                 }Email: 'ssb@cqwpx.com';          DF: nil;                 WA7BNM:  291; {SK3BG: nil;          } QRZRUID: 6   ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:CQWPXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ WW WPX Contest, SSB'),
 ({Name: 'CQ-WPX-RTTY';                }Email: 'rtty@cqwpx.com';         DF: nil;                 WA7BNM:  245; {SK3BG: nil;          } QRZRUID: 6   ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:CQWPXRTTYQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ WW RTTY WPX Contest'),
 ({Name: 'CQ-WW-CW';                   }Email: 'cw@cqww.com';            DF: nil;                 WA7BNM:  192; {SK3BG: 'cqwwdxc';    } QRZRUID: 5   ; Pxm: NoPrefixMults; ZnM: CQZones; AIE: CustomInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:CQDXCC; QP:CQWWQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ Worldwide DX Contest, CW'), // 4.105.17
 ({Name: 'CQ-WW-SSB';                  }Email: 'ssb@cqww.com';           DF: nil;                 WA7BNM:  172; {SK3BG: 'cqwwdxc';    } QRZRUID: 4   ; Pxm: NoPrefixMults; ZnM: CQZones; AIE: ZoneInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:CQDXCC; QP:CQWWQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ Worldwide DX Contest, SSB'),
 ({Name: 'CROATIAN';                  }Email: nil;                       DF: 'croat';            WA7BNM:  206; {SK3BG: '9acwc';      } QRZRUID: 91  ; Pxm: NoPrefixMults; ZnM:ITUZones; AIE: ZoneInitialExchange; DM: DomesticFile; P: 0; AE: RSTZONEORDOMESTICQTH;   XM:NODXMULTS; QP:CroatianQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Croatian DX Contest'),
 ({Name: 'RF-CUP-CW';                  }Email: nil;                      {DF: 'grids';}           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 27  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridFields;    P: 0; AE: QSONumberAndGridSquare;                      XM:NoDXMults; QP:CupRFMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RF-CUP-SSB';                 }Email: nil;                      {DF: 'grids';}           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 24  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridFields;    P: 0; AE: QSONumberAndGridSquare;                      XM:NoDXMults; QP:CupRFMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RF-CUP-DIG';                 }Email: nil;                      DF: 'grids';             WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 86  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberAndGridSquare;                      XM:NoDXMults; QP:CupRFMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'URAL-CUP';                   }Email: nil;                      DF: 'grids';             WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 112 ; Pxm: CallSignPrefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberDomesticQTHExchange;                XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'EU-SPRINT-SPRING-CW';        }Email: nil;                      DF: nil;                 WA7BNM:  317;                         QRZRUID: 216 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndNameExchange;                    XM:NoDXMults; QP:EuropeanSprintQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'EUROPEAN HFC';               }Email: nil;                      DF: nil;                 WA7BNM:   82; {SK3BG: 'euhfcs';     } QRZRUID: 31  ; Pxm: NoPrefixMults; ZnM: EUHFCYear; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'European HF Championship'),
 ({Name: 'EUROPEAN VHF';               }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberAndGridSquareExchange;           XM:NoDXMults; QP:EuropeanVHFQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'HF-TESLA    ';               }Email: nil;                      DF: nil;                 WA7BNM: 566; {SK3BG: nil;           } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberAndGridSquareExchange;           XM:NoDXMults; QP:TeslaQSOPointMethod; ADIFName:'';   CABName:'HF-TESLA'; FriendlyName: 'TESLA Memorial HF CW Contest'),
 ({Name: 'ARRL FIELD DAY';             }Email: 'fieldday@arrl.org';      DF: 'arrlsect';          WA7BNM:   57; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; {DM: NoDomesticMults;}    P: 0; AE: ClassDomesticOrDXQTHExchange;                XM:ARRLDXCC; QP:ARRLFieldDayQSOPointMethod; ADIFName:'ARRL-FIELD-DAY';   CABName:'ARRL-FD'; FriendlyName: 'ARRL Field Day'),   //ny4i Issue 222
 ({Name: 'FISTS';                      }Email: nil;                      DF: 's49p8';             WA7BNM:  251; {SK3BG: 'fistsspr';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQTHNameAndFistsNumberOrPowerExchange;     XM:NoDXMults; QP:FistsQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'FISTS Winter Unlimited Sprint'),
 ({Name: 'FOC MARATHON';               }Email: nil;                      DF: nil;                 WA7BNM:  0000; {SK3BG: nil;         } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTPowerExchange;                  XM:CQDXCC; QP:FOCMarathonQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),            //n4af
 ({Name: 'FLORIDA QSO PARTY';          }Email: nil;                      DF: 'florida_cty';       WA7BNM:  325; {SK3BG: 'flqp';       } QRZRUID: 0    ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 11; AE: RSTDomesticOrDXQTHExchange;                  XM:ARRLDXCCWithNoUSAOrCanada;  QP:OnePhoneTwoCW; ADIFName:'FL-QSO-PARTY';   CABName:'FCG-FQP'; CountyLineAllowed: True; FriendlyName: 'Florida QSO Party'),        //N4AF 4.38.10
 ({Name: 'GACW-WWSA-CW';               }Email: nil;                      DF: nil;                 WA7BNM:   45; {SK3BG: 'gacwdxc';    } QRZRUID: 321 ; Pxm: NoPrefixMults; ZnM: CQZones; AIE: ZoneInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:CQDXCC; QP:GACWWWSACWQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'GACW WWSA CW DX Contest'),
 ({Name: 'GAGARIN-CUP';                }Email: nil;                      DF: 'GC';                 WA7BNM:  367; {SK3BG: 'ygintc';     } QRZRUID: 82  ; Pxm: GCStation; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTZoneorDomesticQTH;                             XM:NoDXMults; QP:GagarinCupQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Yuri Gagarin International DX Contest'),
 ({Name: 'GENERAL QSO';                }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTNameAndQTHExchange;                       XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'General QSO/DX Logging'),
 ({Name: 'GRID LOC';                   }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: NameAndPossibleGridSquareExchange;           XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'HA DX';                      }Email: nil;                      DF: 'hungary';           WA7BNM:  228; {SK3BG: '`c';      } QRZRUID: 116 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:CQDXCC; QP:HADXQSOPointMethod; ADIFName:'HA-DX';   CABName:''; FriendlyName: 'Hungarian DX Contest'),     // 4.84.2
 ({Name: 'YUDX ';                      }Email: nil;                      DF: 'yu';                WA7BNM:  000; {SK3BG:  nil;         } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:CQDXCC; QP:YUDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),     // 4.57.5
 ({Name: 'UKEI ';                      }Email: nil;                      DF: 'uk-ei';             WA7BNM:  000; {SK3BG:  nil;         } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONUMBERAndPossibleDomesticQTHExchange;           XM:CQDXCC; QP:UKEIQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),     // 4.58.2
 ({Name: 'HELVETIA';                   }Email: nil;                      DF: 'swiss';             WA7BNM:  326; {SK3BG: 'helvc';      } QRZRUID: 157 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;  XM:NoDXMults; QP:HelvetiaQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Helvetia Contest'),          // 4.54.6 issue 214
 ({Name: 'IARU-HF';                    }Email: 'iaruhf@iaru.org';        DF: 'iaruhq';            WA7BNM:   67; {SK3BG: 'iaruhfc';    } QRZRUID: 33  ; Pxm: NoPrefixMults; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTZoneOrSocietyExchange;                    XM:NoDXMults; QP:IARUQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'IARU HF World Championship'),
 ({Name: 'INTERNET SPRINT';            }Email: nil;                      DF: 's49p13';            WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberNameDomesticOrDXQTHExchange;        XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:AlwaysOnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RSGB-IOTA';                  }Email: nil;                      DF: nil;                 WA7BNM:   75; {SK3BG: nil;          } QRZRUID: 29  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: IOTADomestic;    P: 0; AE: RSTQSONumberAndPossibleDomesticQTHExchange;  XM:NoDXMults; QP:IOTAQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'RSGB IOTA Contest'),
 ({Name: 'JIDX-CW';                    }Email: nil;                      DF: 'jidx';              WA7BNM:  314; {SK3BG: 'jaintdx';    } QRZRUID: 57  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:NoDXMults; QP:JapanInternationalDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'JIDX CW Contest'),
 ({Name: 'JIDX-SSB';                   }Email: nil;                      DF: 'jidx';              WA7BNM:  184; {SK3BG: 'jaintdx';    } QRZRUID: 57  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:NoDXMults; QP:JapanInternationalDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'JIDX Phone Contest'),
 ({Name: 'JA LONG PREFECT';            }Email: nil;                      DF: 'jacg3';             WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTLongJAPrefectureExchange;                 XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'JT DX';                      }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: MongolianCallSignPrefix; ZnM: NoZoneMults; AIE: ZoneInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:ARRLDXCCWithNoJT;    QP:JTDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'KCJ';                        }Email: nil;                      DF: 'japref';            WA7BNM:   89; {SK3BG: 'kcjc';       } QRZRUID: 169 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZONEORDOMESTICQTH;                      XM:NoDXMults; QP:KCJQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Keymans Club of Japan Contest'),
 ({Name: 'KIDS DAY';                   }Email: nil;                      DF: nil;                 WA7BNM:  224; {SK3BG: 'kidsday';    } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: KidsDayExchange;                             XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'ARRL Kids Day'),
 ({Name: 'KVP';                        }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: EUHFCYear;   AIE: noInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;                             XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'LABRE';                      }Email: 'logs@labre.org.br' ;     DF: 'brazil';            WA7BNM:  761; {SK3BG: 'nil';      } QRZRUID: 0  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticOrDXQTHExchange;                        XM:ARRLDXCC; QP:LABREQSOPointMethod; ADIFName:'';   CABName:'LABRE-DX'; FriendlyName: 'LABRE DX Contest'),
 ({Name: 'LZ DX';                      }Email: nil;                      DF: 'lz';                WA7BNM:  187; {SK3BG: 'lzdxc';      } QRZRUID: 53  ; Pxm: NoPrefixMults; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZoneOrDomesticQTH;                        XM:NoDXMults; QP:LZDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'LZ DX Contest'),
 ({Name: 'Marconi Memorial';     }Email: 'contest.marconi@arifano.it';   DF: nil;              WA7BNM:   56; {SK3BG: nil;        }   QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                       XM:CQDXCC; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'Marconi Memorial HF Contest'),        //n4af    4.68.1
 ({Name: 'MINITEST';                   }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: CallSignPrefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'MINI80';                   }Email: nil;                      DF: nil;                 WA7BNM: 712; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: CallSignPrefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'MINITEST-80 ';   CABName:'MINITEST-80 '; FriendlyName: 'Mini-Test 80'),
 ({Name: 'MINI40';                   }Email: nil;                      DF: nil;                 WA7BNM: 711; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: CallSignPrefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'MINITEST-40 ';   CABName:'MINITEST-40 '; FriendlyName: 'Mini-Test 40'),
 ({Name: 'MICH QSO PARTY';             }Email: nil;                      DF: 'michigan_cty';                 WA7BNM:  323; {SK3BG: 'miqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 2; AE: RSTDomesticQTHExchange;                XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'MI-QSO-PARTY';   CABName:'MI-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Michigan QSO Party'),
 ({Name: 'MINN QSO PARTY';             }Email: nil;                      DF: 'minnesota_cty';                 WA7BNM:  238; {SK3BG: 'mnqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 1; AE: NameAndDomesticOrDXQTHExchange;              XM:NoDXMults; QP:TwoPointsPerQSO{MQPQSOPointMethod}; ADIFName:'MN-QSO-PARTY';   CABName:'MN-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Minnesota QSO Party'),
 ({Name: 'MO QSO PARTY';              }Email: 'moqsoparty@w0ma.org' ;    DF: 'missouri_cty';      WA7BNM:  327; {SK3BG: 'moqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 20; AE: RSTDomesticQTHExchange;               XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'MO-QSO-PARTY';   CABName:'MO-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Missouri QSO Party'),
 ({Name: 'NAQP-CW';                    }Email: 'cwnaqpmgr@ncjweb.com';   DF: 'naqp';              WA7BNM:  218; {SK3BG: 'naqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: DomesticFile;    P: 0; AE: NameAndDomesticOrDXQTHExchange;              XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'North American QSO Party, CW'),
 ({Name: 'NAQP-SSB';                   }Email: 'ssbnaqpmgr@ncjweb.com';  DF: 'naqp';              WA7BNM:  229; {SK3BG: 'naqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: DomesticFile;    P: 0; AE: NameAndDomesticOrDXQTHExchange;              XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'North American QSO Party, SSB'),
 ({Name: 'NAQP-RTTY';                  }Email: 'rttynaqpmgr@ncjweb.com'; DF: 'naqp';              WA7BNM:  263; {SK3BG: 'naqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: DomesticFile;    P: 0; AE: NameAndDomesticOrDXQTHExchange;              XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'North American QSO Party, RTTY'),
 ({Name: 'NA-SPRINT-CW';               }Email: 'cwsprint@ncjweb.com';    DF: 'naqp';             WA7BNM:  253; {SK3BG: 'nasprint';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberNameDomesticOrDXQTHExchange;        XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'North American Sprint, CW'),
 ({Name: 'SSB-SPRINT';                 }Email: '';                       DF: 'naqp';         WA7BNM:  242; {SK3BG: '';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberNameDomesticOrDXQTHExchange;        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'NA-SPRINT-SSB';   CABName:'NA-SPRINT-SSB'; FriendlyName: 'North American Sprint, SSB'),         // 4.55.10
 ({Name: 'NA-SPRINT-RTTY';             }Email: 'rttysprint@ncjweb.com';  DF: 's49p8';             WA7BNM:  155; {SK3BG: 'nasprint';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberNameDomesticOrDXQTHExchange;        XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'North American Sprint, RTTY'),
 ({Name: 'NCCC-SPRINT';                }Email: nil;                      DF: 'naqp';              WA7BNM:   44; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberNameDomesticOrDXQTHExchange;        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'NCCC Sprint'),
 ({Name: 'NEQP';                       }Email: nil;                      DF: nil;                 WA7BNM:   10; {SK3BG: 'newengqp';   } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticOrDXQTHExchange;                  XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:''; FriendlyName: 'New England QSO Party'),
 ({Name: 'NC QSO PARTY';               }Email: nil;                      DF: 'nc_cty';            WA7BNM:  265; {SK3BG:  nil ;       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 13; AE: RSTDomesticQTHExchange;                XM:NoDXMults; QP:NCQSOPointMethod; ADIFName:'North Carolina QSO Party';   CABName:'NC-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'North Carolina QSO Party'),
 ({Name: 'NRAU-BALTIC-CW';             }Email: nil;                      DF: 'nrau';              WA7BNM: 0000; {SK3BG: 'nrau';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONumberAndDomesticQTHExchange;          XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'NRAU-BALTIC-SSB';            }Email: nil;                      DF: 'nrau';              WA7BNM:  220; {SK3BG: 'nrau';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONumberAndDomesticQTHExchange;          XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'NRAU-Baltic Contest, CW'),
 ({Name: 'NZ FIELD DAY';               }Email: nil;                      DF: nil;                 WA7BNM:  222; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: BranchZones; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: NZFieldDayExchange;                          XM:NoDXMults; QP:NZFieldDayQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'NRAU-Baltic Contest, SSB'),
 ({Name: 'OCEANIA-DX-CW';              }Email: nil;                      DF: nil;                 WA7BNM:  151; {SK3BG: 'ocdxc';      } QRZRUID: 72  ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:VKZLQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Oceania DX Contest, CW'),
 ({Name: 'OCEANIA-DX-SSB';             }Email: nil;                      DF: nil;                 WA7BNM:  142; {SK3BG: 'ocdxc';      } QRZRUID: 73  ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:VKZLQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Oceania DX Contest, Phone'),
 ({Name: 'OHIO QSO PARTY';             }Email: nil;                      DF: 'ohio_cty';          WA7BNM:  100; {SK3BG: 'ohqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 5; AE: RSTQSONumberAndDomesticQTHExchange;          XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:'MRRC-OHQP'; CountyLineAllowed: True; FriendlyName: 'Ohio QSO Party'),
 ({Name: 'OK-OM DX';                   }Email: nil;                      DF: 'okom';              WA7BNM:  185; {SK3BG: 'okomdxc';    } QRZRUID: 12  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:CQDXCC; QP:OKDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'OK/OM DX Contest, CW'),
 ({Name: 'RADIO-ONY';                  }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 12  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTPowerExchange;                              XM:NoDXMults; QP:OldNewYearQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'OZCR-O';                     }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 182 ; Pxm: NoPrefixMults; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTZoneOrSocietyExchange;                    XM:CQDXCC{ARRLDXCC}; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'OZCR-Z';                     }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 182 ; Pxm: NoPrefixMults; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTZoneOrSocietyExchange;                    XM:NoDXMults; QP:IARUQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'PACC';                       }Email: nil;                      DF: 'pacc';              WA7BNM:  249; {SK3BG: 'pacc';       } QRZRUID: 66  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'Dutch PACC Contest'),
 ({Name: 'POTA';                       }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndPOTAPark;                         XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'Parks on the Air(r) Logging'),
 ({Name: 'QCWA';                       }Email: nil;                      DF: nil;                 WA7BNM:  332; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberNameChapterAndQTHExchange;          XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:''; FriendlyName: 'QCWA QSO Party'),
 ({Name: 'QCWA GOLDEN';                }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberNameChapterAndQTHExchange;          XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'CANADA_WINTER';          }Email: nil;                      DF: 'p13';               WA7BNM:  205; {SK3BG: 'canday';     } QRZRUID: 101 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:RACQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'RAC Winter Contest'),
 ({Name: 'RF-VHF-FD   ';               }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 180 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberAndGridSquareExchange;           XM:NoDXMults; QP:RadioVHFFDQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RAEM';                       }Email: nil;                      DF: nil;                 WA7BNM:  209; {SK3BG: 'raem';       } QRZRUID: 88  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndGeoCoordinates;                  XM:NoDXMults; QP:RAEMQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'RAEM Contest'),
 ({Name: 'RDAC';                       }Email: nil;                      DF: nil;                 WA7BNM:   94; {SK3BG: 'rdac';       } QRZRUID: 386 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: RDADistrict;     P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC; QP:RDAQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Russian District Award Contest'),
 ({Name: 'REGION 1 FIELD DAY';         }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:CQDXCC; QP:EuropeanFieldDayQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'REGION 1 FIELD DAY-RCC-CW';  }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 358 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:CQDXCC; QP:RegionOneFieldDayRCCQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'REGION 1 FIELD DAY-RCC-SSB'; }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 358 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:CQDXCC; QP:RegionOneFieldDayRCCQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RF-CHAMP-CW';                }Email: 'champ@srr.ru';           DF: 'russian';           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 30  ; Pxm: NoPrefixMults; ZnM: RFChampionchipZones; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberAndZone;                            XM:NoDXMults; QP:ChampionshipRFMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RF-CHAMP-SSB';               }Email: 'champ@srr.ru';           DF: 'russian';           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 28  ; Pxm: NoPrefixMults; ZnM: RFChampionchipZones; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberAndZone;                            XM:NoDXMults; QP:ChampionshipRFMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'AS-CHAMP-CW';                }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 64  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndCoordinatesSum;                  XM:NoDXMults; QP:ChampionshipRFASMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RSGB-ROPOCO-CW';             }Email: nil;                      DF: nil;                 WA7BNM:   77; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndPostalCodeExchange;                    XM:NoDXMults; QP:TenPointsPerQSO; ADIFName:'RSGB-ROLO';   CABName:'RSGB-ROLO'; FriendlyName: 'RSGB RoLo CW'),
 ({Name: 'RSGB-ROPOCO-SSB';            }Email: nil;                      DF: nil;                 WA7BNM:  361; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndPostalCodeExchange;                    XM:NoDXMults; QP:TenPointsPerQSO; ADIFName:'RSGB-ROLO';   CABName:'RSGB-ROLO'; FriendlyName: 'RSGB RoLo SSB'),
 ({Name: 'RSGB 1.8';                   }Email: nil;                      DF: 'rsgb';              WA7BNM: 0000; {SK3BG: 'rsgb1-8';    } QRZRUID: 44  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONumberAndPossibleDomesticQTHExchange;  XM:CQDXCC; QP:RSGB160Method; ADIFName:'';   CABName:''; FriendlyName: ''),               // issue 296
 ({Name: 'RDXC';                       }Email: 'logs@rdxc.org';          DF: 'russian';           WA7BNM:  310; {SK3BG: 'russdxc';    } QRZRUID: 7   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC; QP:RussianDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Russian DX Contest'),
 ({Name: 'SAC-CW';                     }Email: nil;                      DF: nil;                 WA7BNM:  121; {SK3BG: 'sacnsc';     } QRZRUID: 175 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:ScandinavianQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Scandinavian Activity Contest, CW'),
 ({Name: 'YBDX';                       }Email: nil;                      DF: nil;                 WA7BNM:  772; {SK3BG: 'sacnsc';     } QRZRUID: 175 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:IndonesianQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'YB ORARI DX Contest'),          // 4.64.1
 ({Name: 'SAC-SSB';                    }Email: nil;                      DF: nil;                 WA7BNM:  131; {SK3BG: 'sacnsc';     } QRZRUID: 175 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:ScandinavianQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Scandinavian Activity Contest, SSB'),
 ({Name: 'SALMON RUN';                 }Email: nil;                      DF: 'washington_cty';                 WA7BNM:  126; {SK3BG: 'washsr';     } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 9; AE: RSTDomesticOrDXQTHExchange;                  XM:NoDXMults; QP:SalmonRunQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Washington State Salmon Run'),    // n4af 4.41.1
 ({Name: 'SOUTH AMERICAN WW';          }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndContinentExchange;                     XM:NoDXMults; QP:SouthAmericanWWQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'SP DX';                      }Email: nil;                      DF: 'spdx';              WA7BNM:  312; {SK3BG: nil;          } QRZRUID: 127 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:NoDXMults; QP:ThreePointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'SP DX Contest'),
 ({Name: 'STEW-PERRY';                 }Email: nil;                      DF: nil;                 WA7BNM:  207; {SK3BG: 'stpetbdc';   } QRZRUID: 46  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndOrGridExchange;                        XM:NoDXMults; QP:StewPerryQSOPointMethod; ADIFName:'STEW-PERRY';   CABName:''; FriendlyName: 'Stew Perry Topband Challenge'),
 ({Name: 'TEN TEN';                    }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: NameQTHAndPossibleTenTenNumber;              XM:NoDXMults; QP:TenTenQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Ten-Ten On Air Activities'),
 ({Name: 'TEXAS QSO PARTY';            }Email: nil;                      DF: 'texas_cty';                 WA7BNM:  133; {SK3BG: 'txqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 4; AE: RSTDomesticOrDXQTHExchange;                  XM:NoDXMults; QP:TwoPhoneThreeCW; ADIFName:'TX-QSO-PARTY';   CABName:''; CountyLineAllowed: True; FriendlyName: 'Texas QSO Party'),       //n4af 4.33.6
 ({Name: 'TOEC';                       }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: 'toecwwgc';   } QRZRUID: 163 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridFields;      P: 0; AE: RSTDomesticQTHExchange;                      XM:NoDXMults; QP:TOECQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'UA4WCHAMPIONSHIP';           }Email: 'r4w@narod.ru';           DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 132 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTAndGridSquareOrRDAExchange;                XM:NoDXMults; QP:UA4WMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'UBA-CW';                     }Email: nil;                      DF: 'uba';               WA7BNM:  261; {SK3BG: 'ubac';       } QRZRUID: 59  ; Pxm: BelgiumPrefixes; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONumberAndPossibleDomesticQTHExchange;  XM:CQUBAEuropeanCountries; QP:UBAQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'UBA DX Contest, CW'),
 ({Name: 'UBA-SSB';                    }Email: nil;                      DF: 'uba';               WA7BNM:  235; {SK3BG: 'ubac';       } QRZRUID: 58  ; Pxm: BelgiumPrefixes; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTQSONumberAndPossibleDomesticQTHExchange;  XM:CQUBAEuropeanCountries; QP:UBAQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'UBA DX Contest, SSB'),
 ({Name: 'UCG';                        }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 160 ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:CQWPXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'UKRAINE CHAMPIONSHIP';       }Email: nil;                      DF: 'ukraine';           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: QSONumberDomesticQTHExchange;                XM:NoDXMults; QP:ChampionshipUkrMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'UKRAINIAN';                  }Email: nil;                      DF: 'ukraine';           WA7BNM:  176; {SK3BG: 'ukrdxc';     } QRZRUID: 8   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:CQDXCC; QP:UkrainianQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Ukrainian DX Contest'),
 ({Name: 'DARC-WAEDC-CW';              }Email: nil;                      DF: nil;                 WA7BNM:   85; {SK3BG: 'waedxc';     } QRZRUID: 15  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:WAEQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'WAE DX Contest, CW'),
 ({Name: 'DARC-WAEDC-SSB';             }Email: nil;                      DF: nil;                 WA7BNM:  111; {SK3BG: 'waedxc';     } QRZRUID: 16  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                        XM:NoDXMults; QP:WAEQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'WAE DX Contest, SSB'),
 ({Name: 'DARC-XMAS';                  }Email: nil;                      DF: nil;                 WA7BNM:  210; {SK3BG: 'darcxmas';   } QRZRUID: 100 ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'DARC Christmas Contest'),
 ({Name: 'WAG';                        }Email: nil;                      DF: nil;                 WA7BNM:  163; {SK3BG: 'wadlc';      } QRZRUID: 74  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:WAGQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Worked All Germany Contest'),
 ({Name: 'WISCONSIN QSO PARTY';        }Email: nil;                      DF: 'wisconsin_cty';     WA7BNM:  330; {SK3BG: 'wisqp';      } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 7; AE: RSTDomesticQTHExchange;                      XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'WI-QSO-PARTY';   CABName:'WIQP'; CountyLineAllowed: True; FriendlyName: 'Wisconsin QSO Party'),
 ({Name: 'WWL';                        }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridFields;      P: 0; AE: RSTAndGridExchange;                          XM:NoDXMults; QP:WWLQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'WW PMC';                     }Email: nil;                      DF: 'pmc';               WA7BNM:  471; {SK3BG: nil;          } QRZRUID: 229 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZoneOrSocietyExchange;                    XM:NoDXMults; QP:WWPMCQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'WW PMC Contest'),
 ({Name: 'XMAS';                       }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 100 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTQSONumberAndRandomCharactersExchange;     XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'YO-DX-HF';                      }Email: nil;                      DF: 'romania';           WA7BNM:   98; {SK3BG: 'yodxc';      } QRZRUID: 328 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:ARRLDXCC;  QP:YODXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'YO DX HF Contest'),
 ({Name: 'SRR-JR';                     }Email: nil;                      DF: 'russian';           WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 331 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: AgeAndQSONumberExchange;                           XM:ARRLDXCC; QP:AlwaysOnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),      // n4af 04.42.6
 ({Name: 'RU3AX MEMORIAL';                  }Email: nil;                    DF: 'russian';           WA7BNM:  202; {SK3BG: 'russ160';    } QRZRUID: 90  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC;  QP:RussianDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Russian 160-Meter DX Contest'),      // 4.65.4
 ({Name: 'LOCUST QP';                  }Email: nil;                      DF: 'naqp';              WA7BNM:  446; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: NameAndDomesticOrDXQTHExchange{QSONumberNameDomesticOrDXQTHExchange};        XM:NoDXMults; QP:LQPQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Locust QSO Party'),
 ({Name: 'ARKTIKA-SPRING';             }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 351 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:ArktikaSpringQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'UN DX';                      }Email: nil;                      DF: 'kda';               WA7BNM:  480; {SK3BG: nil;          } QRZRUID: 13  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC;    QP:UNDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'UN DX Contest'),
 ({Name: 'NYQP';                       }Email: nil;                      DF: 'newyork_cty';                 WA7BNM:  473; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 3; AE: RSTDomesticQTHExchange;                      XM:NoDXMults; QP:OnePhoneTwoCW; ADIFName:'';   CABName:''; FriendlyName: 'New York QSO Party'),
 ({Name: 'KING-OF-SPAIN-CW';           }Email: nil;                      DF: 'ea';                WA7BNM:   23; {SK3BG: 'kingofsp';   } QRZRUID: 308 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:CQDXCC;    QP:KingOfSpainQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'His Maj. King of Spain Contest, CW'),
 ({Name: 'KING-OF-SPAIN-SSB';          }Email: nil;                      DF: 'ea';                WA7BNM:   59; {SK3BG: 'kingofsp';   } QRZRUID: 308 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:CQDXCC;    QP:KingOfSpainQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'His Maj. King of Spain Contest, SSB'),
 ({Name: 'WRTC';                       }Email: nil;                      DF: 'iaruhq';            WA7BNM:   67; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: ZoneInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTZoneOrSocietyExchange;                  XM:ARRLDXCC;  QP:WRTCQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'IARU HF World Championship'),  //n4af 4.31.2
 ({Name: 'TENNESSEE QSO PARTY';        }Email: nil;                      DF: 'tennessee_cty';                 WA7BNM:  115; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 8;AE: RSTDomesticQTHExchange;                      XM:NoDXMults; QP:TwoPhoneThreeCW; ADIFName:'TN-QSO-PARTY';   CABName:'TN-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Tennessee QSO Party'),         // n4af 4.51.4
 ({Name: 'COLORADO QSO PARTY';         }Email: 'colorado_cty';                      DF: nil;                 WA7BNM:  431; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 12;AE: NameAndDomesticOrDXQTHExchange;              XM:NoDXMults; QP:TwoPointsPerQSO; ADIFName:'CO-QSO-PARTY';   CABName:'COQP'; CountyLineAllowed: True; FriendlyName: 'Colorado QSO Party'),
 ({Name: 'R9W-UW9WK-MEMORIAL';         }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 41  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P:  0;AE: QSONumberAndZone;                            XM:NoDXMults; QP:R9WUW9WKMemorialQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'PCC';                        }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 35  ; Pxm: Prefix; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;  XM:NoDXMults; QP:PCCQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'RADIO-MEMORY';               }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 83  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: RSTAgeAndPossibleSK;                         XM:NoDXMults; QP:RadioMemoryQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'DARC-10M';                   }Email: nil;                      DF: nil;                 WA7BNM:  223; {SK3BG: 'darcxmas';   } QRZRUID: 184 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTQSONumberAndPossibleDomesticQTHExchange{RSTAndQSONumberOrDomesticQTHExchange};        XM:CQDXCC; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: 'DARC 10-Meter Contest'),
 ({Name: 'REF-CW';                     }Email: nil;                      DF: 'ref';               WA7BNM:  233; {SK3BG: 'refc';       } QRZRUID: 67  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrFrenchDepartmentExchange;   XM:NoDXMults; QP:REFQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'REF Contest, CW'),
 ({Name: 'REF-SSB';                    }Email: nil;                      DF: 'ref';               WA7BNM:  260; {SK3BG: 'refc';       } QRZRUID: 67  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrFrenchDepartmentExchange;   XM:NoDXMults; QP:REFQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'REF Contest, SSB'),
 ({Name: 'BSCI';                       }Email: nil;                      DF: nil;                 WA7BNM:  470; {SK3BG: nil;          } QRZRUID: 232 ; Pxm: NoPrefixMults; ZnM: ITUZones; AIE: ZoneInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTZoneOrSocietyExchange;                    XM:BlackSeaCountries; QP:BSCIQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Black Sea Cup International'),
 ({Name: 'CQMM';                       }Email: nil;                      DF: nil;                 WA7BNM:   21; {SK3BG: nil;          } QRZRUID: 34  ; Pxm: SouthAmericanPrefixes; ZnM: NoZoneMults; AIE: NoInitialExchange;      DM: NoDomesticMults; P: 0; AE: RSTAndContinentExchange;                    XM:CQDXCC; QP:CQMMQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQMM DX Contest'),
 ({Name: 'SA-SPRINT';                  }Email: 'sa-sprint.com/enviar-log/';  DF: nil;             WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: SouthAmericanPrefixes; ZnM: NoZoneMults; AIE: NoInitialExchange;      DM: NoDomesticMults; P: 0; AE: RSTQSONumberExchange;                    XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''), // 4.50.5 issue 177
 ({Name: 'CWOPS';                      }Email: nil;                      DF: nil;                 WA7BNM:  498; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: CallSignPrefix;        ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: NoDomesticMults; P: 0; AE: NameAndDomesticOrDXQTHExchange;             XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'CWOPS-CWT';   CABName:''; FriendlyName: 'CWops Test (CWT)'),
 ({Name: 'OZHCR-VHF';                  }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 203 ; Pxm: NoPrefixMults;         ZnM: NoZoneMults; AIE: NoInitialExchange; DM: GridSquares; P: 0; AE: RSTQSONumberAndGridSquareExchange;             XM:NoDXMults; QP:OZHCRVHFQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'CANADA_DAY';             }Email: nil;                      DF: 'p13';               WA7BNM:   60; {SK3BG: 'canday';     } QRZRUID: 101 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:NoDXMults; QP:RACQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'RAC Canada Day Contest'),
 ({Name: 'CQ-WW-RTTY';                 }Email: 'rtty@cqww.com';          DF: 's48p14dc';          WA7BNM:  130; {SK3BG: nil;          } QRZRUID: 191 ; Pxm: NoPrefixMults; ZnM: CQZones; AIE: ZoneInitialExchange; DM: DomesticFile; P: 0; AE: RSTZoneAndPossibleDomesticQTHExchange;  XM:CQDXCC; QP:CQWWRTTYQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'CQ Worldwide DX Contest, RTTY'),
 ({Name: 'CW-OPEN';                     }Email: 'cwo@cwops.org';          DF: nil;                 WA7BNM:  532; {SK3BG: nil;          } QRZRUID:   0 ; Pxm: CallSignPrefix; ZnM: CQZones; AIE: NameInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndNameExchange;  XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'CWOPS-CW-OPEN';   CABName:'CW-OPEN'; FriendlyName: 'CWOps CW Open'),
 ({Name: 'Makrothen';                  }Email: nil;                      DF: nil;                 WA7BNM:  159; {SK3BG: nil;          } QRZRUID: 515 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: GridInitialExchange; DM: NoDomesticMults; P: 0; AE: GridExchange;  XM:NoDXMults; QP:MakrothenQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Makrothen RTTY Contest'),
 ({Name: 'EU-SPRINT-SPRING-SSB';       }Email: nil;                      DF: nil;                 WA7BNM:  316;                         QRZRUID: 216 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndNameExchange;                    XM:NoDXMults; QP:EuropeanSprintQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'RSGB International Sprint Contest, SSB'),
 ({Name: 'EU-SPRINT-AUTUMN-CW';        }Email: nil;                      DF: nil;                 WA7BNM:  152;                         QRZRUID: 216 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndNameExchange;                    XM:NoDXMults; QP:EuropeanSprintQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'EU Autumn Sprint, CW'),
 ({Name: 'EU-SPRINT-AUTUMN-SSB';       }Email: nil;                      DF: nil;                 WA7BNM:  143;                         QRZRUID: 216 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndNameExchange;                    XM:NoDXMults; QP:EuropeanSprintQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'Eu Autumn Sprint, SSB'),
 ({Name: 'ARRL RTTY ROUNDUP';       }   Email: 'rttyru@arrl.org';        DF: 's48p14dc';          WA7BNM:  217;                         QRZRUID:  56 ; Pxm: NoPrefixMults; ZnM: NoZoneMults;  DM: DomesticFile; P: 0; AE: RSTDomesticQTHOrQSONumberExchange;           XM:ARRLDXCC; QP:OnePointPerQSO; ADIFName:'ARRL-RTTY';   CABName:''; FriendlyName: 'ARRL RTTY Roundup'),
 ({Name: 'CQIR';                    }   Email: nil;                      DF: 'ireland';           WA7BNM:  434;                         QRZRUID:   0 ; Pxm: NoPrefixMults; ZnM: NoZoneMults;  DM: DomesticFile; P: 0; AE: QSONumberAndPossibleDomesticQTHExchange;           XM:NoDXMults; QP:TwoPhoneThreeCW; ADIFName:'';   CABName:''; FriendlyName: 'CQIR - Ireland Calling'),
 ({Name: 'WWIH';                    }   Email: nil;                      DF: nil;                 WA7BNM:  552;                         QRZRUID:   0 ; Pxm: NoPrefixMults; ZnM: CQZones;  AIE:ZoneInitialExchange;DM: NoDomesticMults; P: 0; AE: RSTZoneExchange;           XM:CQDXCC; QP:CQWWRTTYQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'World Wide Iron Ham Contest'),
 ({Name: 'ALRS_UA1DZ_CUP';          }   Email: nil;                      DF: 'russian';           WA7BNM: 0000;                         QRZRUID: 543 ; Pxm: NoPrefixMults; ZnM: NoZoneMults;  AIE:NoInitialExchange; DM: WYSIWYGDomestic; P: 0; AE: RSTDomesticQTHExchange;           XM:CQDXCC; QP:ALRSUA1DZCupQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'WINTER FIELD DAY';        }   Email: 'wfda@winterfieldday.com';DF: 'arrlsect';          WA7BNM:   421; {SK3BG: nil;         } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: ClassDomesticOrDXQTHExchange;                XM:ARRLDXCC; QP:ARRLFieldDayQSOPointMethod; ADIFName:'WFD';   CABName:'WFD'; FriendlyName: 'Winter Field Day'),
 ({Name: 'RADIO-YOC';                  }Email: nil;                      DF: nil;                 WA7BNM: 0000; {SK3BG: nil;          } QRZRUID: 119 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: NoDomesticMults; P: 0; AE: QSONumberAndPreviousQSONumber;               XM:ARRLDXCC;  QP:ThreePointsPerQSO; ADIFName:'';   CABName:''; FriendlyName: ''),
 ({Name: 'PA QSO PARTY';               }Email: nil;                      DF: 'pa_cty';            WA7BNM: 153; {SK3BG:  nil ;        } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 14; AE: QSONumberDomesticQTHExchange;                XM:NoDXMults; QP:PAQSOPointMethod; ADIFName:'PA-QSO-PARTY';   CABName:'PA-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Pennsylvania QSO Party'),     // 4.74.3
 ({Name: 'IN QSO PARTY';               }Email: nil;                      DF: 'in_cty';            WA7BNM:    8; {SK3BG:  nil ;        } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 15; AE: RSTDomesticQTHExchange;                XM:NoDXMults; QP:TWOPOINTSPERQSO; ADIFName:'IN-QSO-PARTY';   CABName:'IN-QSO-PARTY'; CountyLineAllowed: True; FriendlyName: 'Indiana QSO Party'),     // 4.144.3
 ({Name: 'OK-OM SSB';                  }Email: nil;                      DF: 'okom';              WA7BNM:  567; {SK3BG: 'okomdxc';    } QRZRUID: 12  ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile; P: 0; AE: RSTAndQSONumberOrDomesticQTHExchange;        XM:CQDXCC; QP:OKOMSSBQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'OK/OM DX Contest, SSB'),     // 4.80.1
 ({Name: 'BATAVIA-FT8';                }Email: nil;                      DF: nil;                 WA7BNM:  677;                       QRZRUID: 0   ; Pxm: Prefix;        ZnM: NoZoneMults; AIE: GridInitialExchange; DM: NoDomesticMults; P: 0; AE: GridExchange;                           XM:CQDXCC; QP:YBFT8QP; ADIFName:'';   CABName:'BATAVIA'; FriendlyName: 'Batavia FT8 Contest'),    // 4.90.11
 ({Name: 'WWDIGI';                     }Email: 'director@ww-digi.com';   DF: nil;                 WA7BNM:  650;                         QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: GridInitialExchange; DM: GridFields; P: 0; AE: Grid2Exchange;                           XM:NoDXMults; QP:WWDIGIQP; ADIFName:'';   CABName:'WW-DIGI'; FriendlyName: 'World Wide Digi DX Contest'),    // 4.90.11
 ({Name: 'MWC';                        }Email: 'memorial-ok1wc.cz/index.php?page=logs';                      DF: 'mwc';                 WA7BNM:  0;  QRZRUID: 0 ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile; P: 0; AE: RSTQSONumberExchange;          XM:NoDXMults; QP:MWCQP; ADIFName:'';   CABName:''; FriendlyName: ''),     // 4.98.1
 ({Name: 'IRTS ';                      }Email: 'IRTS.contests@gmail.com';             DF: 'ireland';             WA7BNM:  000; {SK3BG:  nil;         } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: ZoneInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZoneOrDomesticQTH;           XM:NoDXMults; QP:EUDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: ''),     // 4.95.6
 ({Name: 'EUDX';                       }Email: 'log.eudxc@gmail.com';    DF: 'EUDX';           WA7BNM:  000; {SK3BG: nil;    } QRZRUID: 0   ;         Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 0; AE: RSTZoneOrDomesticQTH;           XM:CQDXCC; QP:EUDXQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: '') ,
 ({Name: 'BCQP';                       }Email: nil;                      DF: 've7_cty';                 WA7BNM:  269; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 16; AE: RSTDomesticQTHExchange;                      XM:NoDXMults; QP:BCQPQSOPointMethod; ADIFName:'';   CABName:''; FriendlyName: 'British Columbia QSO Party'),      // 4.97.6
 ({Name: 'VA QSO Party';               }Email: nil;                      DF: 'va_cty';            WA7BNM:  302; {SK3BG:  nil ;        } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 17; AE: QSONumberDomesticOrDXQTHExchange;                XM:NoDXMults; QP:VAQSOPointMethod; ADIFName:'VA-QSO-PARTY';   CABName:'VA-QSO-PARTY'; FriendlyName: 'Virginia QSO Party'),      // 4.88.2
 ({Name: 'YOTA';                       }Email: nil;                      DF: 'YOTA';                 WA7BNM:   696; {SK3BG: nil;    } QRZRUID: 0; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile; P: 0; AE: RSTAgeExchange;                              XM:NoDXMults; QP:YOTAQSOPointMethod; ADIFName:'YOTA';   CABName:'YOTA-CONTEST'; FriendlyName: 'YOTA Contest') ,
 ({Name: 'IN7QPNE';                    }Email: nil;                      DF: 'in7qpne_cty';            WA7BNM: 0000; {SK3BG:  nil ;        } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NoInitialExchange; DM: DomesticFile;    P: 18; AE: RSTDomesticQTHExchange;                XM:NoDXMults; QP:PAQSOPointMethod; ADIFName:'IN7QPNE-QSO-PARTY';   CABName:'IN7QPNE-QSO-PARTY'; FriendlyName: 'Combined Indiana, 7th Call Area, New England and Delaware QSO Party'),     // 4.88.2
 ({Name: 'MST';                        }Email: nil;                      DF: nil;                 WA7BNM:  720; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: CallSignPrefix;        ZnM: NoZoneMults; AIE:NoInitialExchange ; DM: NoDomesticMults; P: 0; AE: QSONumberandNameExchange;             XM:NoDXMults; QP:OnePointPerQSO; ADIFName:'MST';   CABName:''; FriendlyName: 'ICWC Medium Speed Test'),          // 4.110.5
 ({Name: 'SST';                        }Email: 'k1usn.radioclub.sst@gmail.com';   DF: 'naqp';              WA7BNM:  681; {SK3BG: 'naqp';       } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: NameQTHInitialExchange; DM: DomesticFile;    P: 0; AE: NameAndDomesticOrDXQTHExchange;              XM:NorthAmericanARRLDXCCWithNoUSACanadaOrkL7; QP:OnePointPerQSO; ADIFName:'K1USN-SST';   CABName:'K1USNSST'; FriendlyName: 'K1USN Slow Speed Test'),
 ({Name: 'RTC';                        }Email: nil;                      DF: nil;                 WA7BNM:  782; {SK3BG: nil;          } QRZRUID: 0   ; Pxm: NoPrefixMults; ZnM: NoZoneMults; AIE: GridInitialExchange; DM: GridSquares;     P: 0; AE: RSTQSONumberAndGridSquareExchange;          XM:NoDXMults; QP:RTCQSOPointMethod; ADIFName:'RTC';   CABName:'RTC'; FriendlyName: 'Real Time Contest')   // Issue #902 Real-Time Contest (COS)
 );




  // Warning - Do not change names here without careful consideration. If you do, it will break old config files. Better to use the ADIFName or CABName fields if needed. In a perfect world, these would all be the ADIFNAME.
    ContestTypeSA                       : array[ContestType] of PChar =

    (
      'DUMMY CONTEST',
      '7QP',
      'ALL-ASIAN-DX-CW',
      'ALL-ASIAN-DX-SSB',
      'ALL JA',
      'AP-SPRINT',
      'ARCI',
      'ARI-DX',
      'ARRL-10',
      'ARRL-DIGI',
      'ARRL-160',
      'ARRL-DX-CW',
      'ARRL-DX-SSB',
      'ARRL-SS-CW',
      'ARRL-SS-SSB',
      'ARRL-VHF-JAN',
      'ARRL-VHF-JUN',
      'ARRL-VHF-SEP',
      'ARIZONA QSO PARTY',
      'BALTIC',
      'BWQP',
      'CIS',
      'CALIFORNIA QSO PARTY',
      'COUNTY HUNTER',
      'CQ-160-CW',
      'CQ-160-SSB',
      'CQ-M',
      'CQ-VHF',
      'CQ-WPX-CW',
      'CQ-WPX-SSB',
      'CQ-WPX-RTTY',
      'CQ-WW-CW',
      'CQ-WW-SSB',
      'CROATIAN',
      'RF-CUP-CW',
      'RF-CUP-SSB',
      'RF-CUP-DIG',
      'URAL-CUP',
      'EU-SPRINT-SPRING-CW',
      'EUROPEAN HFC',
      'EUROPEAN VHF',
      'HF-TESLA',
      'ARRL-FD',    // The internal name is ARRL-FD. If we change it here, it breaks old files so leave as ARRL-FD. I use the ADIFNAME fiels in the ContestSA array for the right value// 4.89.6
      'FISTS',
      'FOC MARATHON',  //n4af
      'FLORIDA QSO PARTY',
      'GACW-WWSA-CW',
      'GAGARIN-CUP',
      'GENERAL QSO',
      'GRID LOC',
      'HA DX',
      'YUDX',    // 4.57.5
      'UKEI',   // 4.58.2
      'HELVETIA',
      'IARU-HF',
      'INTERNET SPRINT',
      'RSGB-IOTA',
      'JIDX-CW',
      'JIDX-SSB',
      'JA LONG PREFECT',
      'MONGOLIAN DX',
      'KCJ',
      'KIDS DAY',
      'KVP',
      'LABRE',
      'LZ DX',
      'MARCONI MEMORIAL',       //n4af
      'MINITEST',
      'MINI80',
      'MINI40',
      'MICHIGAN QSO PARTY',
      'MINNESOTA QSO PARTY',
      'MISSOURI QSO PARTY',
      'NAQP-CW',
      'NAQP-SSB',
      'NAQP-RTTY',
      'NA-SPRINT-CW',
      'SSB-SPRINT',
      'NA-SPRINT-RTTY',
      'NCCC-SPRINT',
      'NEQP',
      'NC QSO PARTY',
      'NRAU-BALTIC-CW',
      'NRAU-BALTIC-SSB',
      'NZ FIELD DAY',
      'OCEANIA-DX-CW',
      'OCEANIA-DX-SSB',
      'OHIO QSO PARTY',
      'OK-OM DX CW',
      'RADIO-ONY',
      'OZCHR-TEAMS',
      'OZCHR',
      'PACC',
      'POTA',
      'QCWA',
      'QCWA GOLDEN',
      'CANADA WINTER',
      'RF-VHF-FD',
      'RAEM',
      'RDAC',
      'REGION 1 FIELD DAY',
      'REGION 1 FIELD DAY-RCC-CW',
      'REGION 1 FIELD DAY-RCC-SSB',
      'RF-CHAMP-CW',
      'RF-CHAMP-SSB',
      'AS-CHAMP',
      'RSGB-ROPOCO-CW',
      'RSGB-ROPOCO-SSB',
      'RSGB-160',
      'RDXC',
      'SAC-CW',
      'YBDX',      // 4.64.1
      'SAC-SSB',
      'SALMON RUN',
      'SOUTH AMERICAN WW',
      'SP DX',
      'STEW-PERRY',
      'TEN TEN',
      'TEXAS QSO PARTY',
      'TOEC',
      'R4W-CHAMP',
      'UBA-DX-CW',
      'UBA-DX-SSB',
      'UCG',
      'UKRAINE CHAMPIONSHIP',
      'UKRAINIAN',
      'DARC-WAEDC-CW',
      'DARC-WAEDC-SSB',
      'DARC-XMAS',
      'WAG',
      'WISCONSIN QSO PARTY',
      'WWL',
      'WW PMC',
      'XMAS',
      'YO-DX-HF',
      'SRR-JR',
      'RU3AX MEMORIAL',      // 4.65.4
      'LOCUST QSO PARTY',
      'ARKTIKA-SPRING',
      'UN DX',
      'NY-QSO-PARTY',
      'KING-OF-SPAIN-CW',
      'KING-OF-SPAIN-SSB',
      'WRTC',
      'TENNESSEE QSO PARTY',
      'COLORADO QSO PARTY',
      'R9W-UW9WK-MEMORIAL',
      'PCC',
      'RADIO-MEMORY',
      'DARC-10M',
      'REF-CW',
      'REF-SSB',
      'BLACK SEA CUP',
      'CQMM',
      'SA-SPRINT',
      'CWOPS',
      'OZHCR-VHF',
      'CANADA DAY',
      'CQ-WW-RTTY',
      'CWOPEN',
      'MAKROTHEN-RTTY',
      'EU-SPRINT-SPRING-SSB',
      'EU-SPRINT-AUTUMN-CW',
      'EU-SPRINT-AUTUMN-SSB',
      'ARRL-RTTY',
      'CQIR',
      'WWIH',
      'ALRS-UA1DZ-CUP',
      'WINTER FIELD DAY' ,
      'RADIO-YOC',
      'PA QSO PARTY',  // 4.74.3
      'IN QSO PARTY', // 4.88.2
      'OK-OM DX SSB',       // 4.80.1
      'BATAVIA-FT8',    // 4.90.11
      'WWDIGI',
      'MWC',               // 4.92.8
      'IRTS',        // 4.93.1
      'EUDX',         // 4.95.6
      'BCQP',          // 4.97.6
      'VAQP',
      'YOTA',
      'IN7QPNE',
      'MST',           // 4.110.5
      'SST',
      'RTC'            // Issue #902
     );

  const
    {QSO BY BAND BIT 0}
    ciQB0                               = 0;
    ciQB1                               = 1;
    QSO_BY_BAND_BIT                     = 0;

    {QSO BY MODE BIT 1}
    ciQM0                               = 0;
    ciQM1                               = 2;
    QSO_BY_MODE_BIT                     = 1;

    {MULT BY BAND BIT 2}
    ciMB0                               = 0;
    ciMB1                               = 4;
    MULT_BY_BAND_BIT                    = 2;

    {MULT BY MODE BIT 3}
    ciMM0                               = 0;
    ciMM1                               = 8;
    MULT_BY_MODE_BIT                    = 3;

    {ERMAK SPEC BIT 4}
    ciErmak0                            = 0;
    ciErmak1                            = 16;
    ERMAK_BIT                           = 4;

    {VHF BAND ENABLE BIT 5}
    ciVHFEnabled0                       = 0;
    ciVHFEnabled1                       = 32;
    VHF_BAND_ENABLE_BIT                 = 5;

    {CQ ZONE MODE BIT 6}
    ciCQZoneMode0                       = 0; {ITU ZONE MODE}
    ciCQZoneMode1                       = 64; {CQ ZONE MODE}
    CQ_ZONE_MODE_BIT                    = 6;

    {COUNT DOMESTIC COUNTRIES BIT 7}
    ciCDC0                              = 0;
    ciCDC1                              = 128;
    CDC_BIT                             = 7;

    {RTC (REAL-TIME CONTEST) CAPABLE BIT 8 -- HamScore real-time contact upload support, issue #931}
    ciRTC0                              = 0;
    ciRTC1                              = 256;
    RTC_CAPABLE_BIT                     = 8;

    ContestsBooleanArray                : array[ContestType] of Word =
      (
      ({Name: 'DUMMY CONTEST';              }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: '7QP';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'ALL ASIAN CW';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ALL ASIAN SSB';              }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ALL JA';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'AP-SPRINT';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARCI';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARI-DX';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'ARRL-10';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'ARRL-DIGI';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARRL-160';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARRL-DX-CW';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARRL-DX-SSB';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARRL-SS-CW';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARRL-SS-SSB';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARRL VHF JAN';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARRL VHF JUN';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARRL VHF SEP';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'ARIZONA QSO PARTY';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'BALTIC';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'BWQP';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),        //n4af
      ({Name: 'CIS';                        }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'CQP';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),     //n4af 4.34.5
      ({Name: 'COUNTY HUNTER';              }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-160-CW';                  }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-160-SSB';                 }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-M';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'CQ-VHF';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'CQ-WPX-CW';                  }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-WPX-SSB';                 }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-WPX-RTTY';                }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQ-WW-CW';                   }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'CQ-WW-SSB';                  }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'CROATIAN';                   }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'RF-CUP-CW';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RF-CUP-SSB';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RF-CUP-DIG';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'URAL-CUP';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'EU-SPRINT-SPRING-CW';        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'EUROPEAN HFC';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'EUROPEAN VHF';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'HF-TESLA    ';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),      // 4.57.4
      ({Name: 'ARRL-FIELD DAY';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'FISTS';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'FOC MARATHON';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),    //n4af
      ({Name: 'FLORIDA QSO PARTY';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'GACW-WWSA-CW';               }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'GAGARIN-CUP';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'GENERAL QSO';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'GRID LOC';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'HA DX';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'YUDX';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),    // 4.57.5    // 4.58.1
      ({Name: 'UKEI';                       }ciCDC0+ ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),    // 4.58.2
      ({Name: 'HELVETIA';                   }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0 + ciRTC1),    // 4.54.6 issue 214    // 4.56.8
      ({Name: 'IARU-HF';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'INTERNET SPRINT';            }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RSGB-IOTA';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'JIDX-CW';                    }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'JIDX-SSB';                   }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'JA LONG PREFECT';            }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'JT DX';                      }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'KCJ';                        }ciCDC1 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'KIDS DAY';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM1),
      ({Name: 'KVP';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'LABRE';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'LZ DX';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name; 'Marconi Memorial';           }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),    //n4af
      ({Name: 'MINITEST';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'MINI80';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'MINI40';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'MICH QSO PARTY';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'MINN QSO PARTY';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0 + ciRTC1),
      ({Name: 'MO QSO PARTY';              }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'NAQP-CW';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0 + ciRTC1),
      ({Name: 'NAQP-SSB';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0 + ciRTC1),
      ({Name: 'NAQP-RTTY';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0 + ciRTC1),
      ({Name: 'NA-SPRINT-CW';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0 + ciRTC1),
      ({Name: 'SSB SPRINT';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'NA-SPRINT-RTTY';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0 + ciRTC1),
      ({Name: 'NCCC-SPRINT';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'NEQP';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'NC QSO PARTY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),      // issue 292 4.66.1
      ({Name: 'NRAU-BALTIC-CW';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'NRAU-BALTIC-SSB';            }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'NZ FIELD DAY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'OCEANIA-DX-CW';              }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'OCEANIA-DX-SSB';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'OHIO QSO PARTY';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'OK-OM DX';                   }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RADIO-ONY';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'OZCR-O';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'OZCR-Z';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'PACC';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'POTA';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'QCWA';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'QCWA GOLDEN';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CANADA WINTER';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'RF-VHF-FD';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RAEM';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RDAC';                       }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'REGION 1 FIELD DAY';         }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'REGION 1 FIELD DAY-RCC-CW';  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'REGION 1 FIELD DAY-RCC-SSB'; }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RF-CHAMP-CW';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RF-CHAMP-SSB';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'AS-CHAMP-CW';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'RSGB-ROPOCO-CW';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RSGB-ROPOCO-SSB';            }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RSGB 1.8';                   }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),        // issue 296
      ({Name: 'RDXC';                       }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'SAC-CW';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'YBDX';                       }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),       // 4.64.1   // add issue 291
      ({Name: 'SAC-SSB';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'SALMON RUN';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'SOUTH AMERICAN WW';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'SP DX';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'STEW-PERRY';                 }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'TEN TEN';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'TEXAS QSO PARTY';            }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'TOEC';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'R4W-CHAMP';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'UBA-CW';                     }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'UBA-SSB';                    }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'UCG';                        }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'UKRAINE CHAMPIONSHIP';       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'UKRAINIAN';                  }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'DARC-WAEDC-CW';              }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'DARC-WAEDC-SSB';             }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'DARC-XMAS';                  }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'WAG';                        }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'WISCONSIN QSO PARTY';        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'WWL';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'WW PMC';                     }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'XMAS';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'YO DX';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'SRR-JR';                     }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'RU3AX MEMORIAL';             }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB0 + ciQM1 + ciMB0 + ciMM1),      // 4.65.    // 4.76.5
      ({Name: 'LQP';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARKTIKA-SPRING';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'UN DX';                      }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'NYQP';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'KING-OF-SPAIN-CW';           }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'KING-OF-SPAIN-SSB';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'WRTC';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'TENNESSEE QSO PARTY';        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'COLORADO QSO PARTY';         }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'R9W-UW9WK-MEMORIAL';         }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'PCC';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'RADIO-MEMORY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'DARC-10M';                   }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB0 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'REF-CW';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'REF-SSB';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'BSCI';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'CQMM';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'SA-SPRINT';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),   // 4.50.5 issue 177
      ({Name: 'CWOPS';                      }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0 + ciRTC1),
      ({Name: 'OZHCR-VHF';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CANADA WINTER';          }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'CQ-WW-CW';                   }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'CWOPEN';                     }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0 + ciRTC1),
      ({Name: 'MAKROTHEN';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'EU-SPRINT-SPRING-SSB';       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'EU-SPRINT-AUTUMN-CW';        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'EU-SPRINT-AUTUMN-SSB';       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'ARRL RTTY ROUNDUP';          }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'CQIR';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),
      ({Name: 'WWIH';                       }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM1),
      ({Name: 'ALRS-UA1DZ-CUP';             }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'WINTER-FIELD DAY';           }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled1 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),        // 4.56.9 ny4i
      ({Name: 'RADIO-YOC';                  }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak1 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'PA QSO PARTY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),       // 4.74.3
      ({Name: 'IN QSO PARTY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),     // 4.88.2
      ({Name: 'OK-OM SSB';                  }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'BATAVIA-FT8';                }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0),
      ({Name: 'WW-DIGI';                    }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0),
      ({Name: 'MWC';                        }ciCDC0 + ciCQZoneMode1 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),       // 4.92.8
      ({Name: 'IRTS';                       }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0) ,     // 4.93.1
      ({Name: 'EUDX';                       }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),     // 4.95.6
      ({Name: 'BC QSO Party';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM1),      // 4.97.6
      ({Name: 'VA QSO PARTY';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),
      ({Name: 'YOTA';                       }ciCDC1 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB1 + ciMM0),
      ({Name: 'IN7QPNE     ';               }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM1 + ciMB0 + ciMM0),     // 4.99.7
      ({Name: 'MST';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB0 + ciMM0 + ciRTC1),        // 4.110.5
      ({Name: 'SST';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0 + ciRTC1),
      ({Name: 'RTC';                        }ciCDC0 + ciCQZoneMode0 + ciVHFEnabled0 + ciErmak0 + ciQB1 + ciQM0 + ciMB1 + ciMM0 + ciRTC1)        // Issue #902

        );

  type
    tWindowColorRecord = record
      wcWindow: PDWORD;
      wcColor: ptr4wColors;
      wcbackground: ptr4wColors;
    end;

  // Well this is bizzare. In order for the file size check to match, TLogHeader needs to be the same size as the ContestExchange record.
  // So it looks like lhDummy is used to pad this out.
  // But rather than keep this in the same place like when you change contestexchange, you have to figure that out.
  // The better way to do this is to take SIZEOFCONTEXTEXCHANGE - the used bytes in log header as the size of the lhDummy char array de NY4I
  const SizeOfLHVersionString = 8;
  const SizeOfLHFileDesc = 16;
  const SizeOfLHWarningString = 36;
  const SizeOfLHValid = (SizeOfLHVersionString + SizeOfLHFileDesc + SizeOfLHWarningString);

  type TLogHeader = record
      lhVersionString: array[0..(SizeOfLHVersionString-1)] of Char;
      lhFileDesc: array[0..(SizeOfLHFileDesc-1)] of Char;
      lhWarningString: array[0..(SizeOfLHWarningString-1)] of Char;
      lhDummy: array[0..(SizeOfContestExchange-SizeOfLHValid-1)] of Char;  // three fields above are 60 bytes
   //   lhDummy: array[0..(SizeOfContestExchange-SizeOfTLogHeader-1)] of Char;  // three fields above are 60 bytes

    end;
  (*
  TLogHeader = record
      lhVersionString: array[0..7] of Char;
      lhFileDesc: array[0..15] of Char;
      lhWarningString: array[0..35] of Char;
   //   lhDummy: array[0..(SIZEOFCONTEXTEXCHANGE-60-1)] of Char;  // three fields above are 60 bytes
   //   lhDummy: array[0..(SizeOfContestExchange-SizeOfTLogHeader-1)] of Char;  // three fields above are 60 bytes
    end;
  *)

  const
    LogHeader                           : TLogHeader =
      (
      lhVersionString: (LOGVERSION1, LOGVERSION2, LOGVERSION3, LOGVERSION4, #0, #$20, #13, #10);
      lhFileDesc: ('T', 'R', '4', 'W', ' ', 'L', 'O', 'G', ' ', 'F', 'I', 'L', 'E', ' ', #13, #10);
      lhWarningString: ('W', 'A', 'R', 'N', 'I', 'N', 'G', ':', ' ', 'D', 'O', ' ', 'N', 'O', 'T', ' ', 'E', 'D', 'I', 'T', ' ', 'T', 'H', 'I', 'S', ' ', 'F', 'I', 'L', 'E', '!', #13, #10, #13, #10, #0);
      );

  const
    SizeOfTLogHeader                    = SizeOf(TLogHeader);



  var
    tr4wBrushArray                      : array[tr4wColors] of HBRUSH;
    // Issue #1034: relocated here from LogDupe so light units (uMults and the
    // pre-migration test EXE) can read the active DX-multiplier mode without
    // pulling LogDupe's monolith cone. DXMultType is defined above in this unit;
    // zero-initialized to NoDXMults (its first value), matching the old default.
    ActiveDXMult                        : DXMultType;

implementation
//rd4wa -
begin
  tr4wColorsArray[trBtnFace] := GetSysColor(COLOR_BTNFACE);
//  Windows.CopyMemory(@TR4W_FLOPPY_FILENAME, PChar('LOGBACK.TRW'), 11);
//  tr4wColorsArray[trSelected] := GetSysColor(COLOR_ACTIVECAPTION);
end.
