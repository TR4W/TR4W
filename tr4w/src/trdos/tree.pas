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
unit Tree;

{ This unit contains all the neat little library routines that are used
    in most of the N6TR programs.  They are not specfic to any program
    which is a requirement for adding new routines. }

{$IMPORTEDDATA OFF}

interface

uses

  VC,
  uCallSignRoutines,
  SysUtils,
  utils_text,
  utils_file,
  TF,
  Messages,
  Windows,
  uBandLookup;  // CalculateBandMode now lives here so it can be unit-tested without tree.pas's dependency cone

var
  tempshowcty                           : Cardinal;
const
  FMSecsPerDay                          : single = MSecsPerDay;
  IMSecsPerDay                          : integer = MSecsPerDay;

const
  dcb_Binary                            = $00000001;
  dcb_ParityCheck                       = $00000002;
  dcb_OutxCtsFlow                       = $00000004;
  dcb_OutxDsrFlow                       = $00000008;
  dcb_DtrControlMask                    = $00000030;
  dcb_DtrControlDisable                 = $00000000;
  dcb_DtrControlEnable                  = $00000010;
  dcb_DtrControlHandshake               = $00000020;
  dcb_DsrSensivity                      = $00000040;
  dcb_TXContinueOnXoff                  = $00000080;
  dcb_OutX                              = $00000100;
  dcb_InX                               = $00000200;
  dcb_ErrorChar                         = $00000400;
  dcb_NullStrip                         = $00000800;
  dcb_RtsControlMask                    = $00003000;
  dcb_RtsControlDisable                 = $00000000;
  dcb_RtsControlEnable                  = $00001000;
  dcb_RtsControlHandshake               = $00002000;
  dcb_RtsControlToggle                  = $00003000;
  dcb_AbortOnError                      = $00004000;
  dcb_Reserveds                         = $FFFF8000;

type
  PDayTable = ^TDayTable;
  TDayTable = array[1..12] of Word;

type
  PBoolean = ^boolean;

type

  //  MouseTypeType = (NoMouse, OneButton, TwoButton, ThreeButton);

  ParityType = (tNoParity, EvenParity, OddParity);

  // TwoBytes/FourBytes/EightBytes moved to VC.pas (pre-migration extraction of
  // callsign compression); tree.pas now gets them from VC (used in interface).
  FourBytesPtr = ^FourBytes;

{
  ParallelPortType = (ppNoPort, ppParallel1, ppParallel2, ppParallel3);
  ParallelPortTypeSA                    : array[ParallelPortType] of PChar = ('NONE', '1', '2', '3');
}
const
  PortTypeSA                            : array[PortType] of PChar =

  (
    'NONE',
    'SERIAL 1',
    'SERIAL 2',
    'SERIAL 3',
    'SERIAL 4',
    'SERIAL 5',
    'SERIAL 6',
    'SERIAL 7',
    'SERIAL 8',
    'SERIAL 9',
    'SERIAL 10',
    'SERIAL 11',
    'SERIAL 12',
    'SERIAL 13',
    'SERIAL 14',
    'SERIAL 15',
    'SERIAL 16',
    'SERIAL 17',
    'SERIAL 18',
    'SERIAL 19',
    'SERIAL 20',
    'TCP/IP',
    'PARALLEL 1',
    'PARALLEL 2',
    'PARALLEL 3'
    );
type
  PPortType = ^PortType;

  PortInterface =
    (NoInterface,
    SerialInterface,
    ParallelInterface);

  MultiBandAddressArrayType = array[BandType] of Byte;

const
  RussianOblastsArrayConst111           = 282;
  RussianOblastsArray111                : array[1..RussianOblastsArrayConst111] of array[0..1] of Char {Str2} = (
    '0A', 'KK'
    , '0B', 'TM'
    , '0C', 'HK'
    , '0D', 'EA'
    , '0E', 'SL'
    , '0F', 'SL'
    , '0H', 'EV'
    , '0I', 'MG'
    , '0J', 'AM'
    , '0K', 'CK'
    , '0L', 'PK'
    , '0M', 'PK'
    , '0N', 'PK'
    , '0O', 'BU'
    , '0Q', 'YA'
    , '0S', 'IR'
    , '0T', 'IR'
    , '0U', 'CT'
    , '0W', 'HA'
    , '0X', 'KY'
    , '0Y', 'TU'
    , '0Z', 'KT'
    , '1A', 'SP'
    , '1B', 'SP'
    , '1C', 'LO'
    , '1D', 'SP'
    , '1F', 'SP'
    , '1G', 'SP'
    , '1H', 'LO'
    , '1J', 'SP'
    , '1L', 'SP'
    , '1M', 'SP'
    , '1N', 'KL'
    , '1O', 'AR'
    , '1P', 'NO'
    , '1Q', 'VO'
    , '1R', 'VO'
    , '1S', 'VO'
    , '1T', 'NV'
    , '1W', 'PS'
    , '1Z', 'MU'
    , '2A', 'KA'
    , '2B', 'KA'
    , '2C', 'KA'
    , '2D', 'KA'
    , '2E', 'KA'
    , '2F', 'KA'
    , '3A', 'MA'
    , '3B', 'MA'
    , '3C', 'MA'
    , '3D', 'MO'
    , '3E', 'OR'
    , '3F', 'MO'
    , '3G', 'LP'
    , '3H', 'MO'
    , '3I', 'TV'
    , '3K', 'VR'
    , '3L', 'SM'
    , '3M', 'YR'
    , '3N', 'KS'
    , '3O', 'VR'
    , '3P', 'TL'
    , '3Q', 'VR'
    , '3R', 'TB'
    , '3S', 'RA'
    , '3T', 'NN'
    , '3U', 'IV'
    , '3V', 'VL'
    , '3W', 'KU'
    , '3X', 'KG'
    , '3Y', 'BR'
    , '3Z', 'BO'
    , '4A', 'VG'
    , '4B', 'VG'
    , '4C', 'SA'
    , '4D', 'SA'
    , '4F', 'PE'
    , '4H', 'SR'
    , '4I', 'SR'
    , '4L', 'UL'
    , '4M', 'UL'
    , '4N', 'KI'
    , '4O', 'KI'
    , '4P', 'TA'
    , '4Q', 'TA'
    , '4R', 'TA'
    , '4S', 'MR'
    , '4T', 'MR'
    , '4U', 'MD'
    , '4W', 'UD'
    , '4Y', 'CU'
    , '4Z', 'CU'
    , '6A', 'KR'
    , '6B', 'KR'
    , '6C', 'KR'
    , '6D', 'KR'
    , '6E', 'KC'
    , '6F', 'ST'
    , '6G', 'ST'
    , '6H', 'ST'
    , '6I', 'KM'
    , '6J', 'SO'
    , '6L', 'RO'
    , '6M', 'RO'
    , '6N', 'RO'
    , '6O', 'RO'
    , '6P', 'CN'
    , '6Q', 'IN'
    , '6U', 'AO'
    , '6V', 'AO'
    , '6W', 'DA'
    , '6X', 'KB'
    , '6Y', 'AD'
    , '8T', 'UO'
    , '8V', 'AB'
    , '9A', 'CB'
    , '9B', 'CB'
    , '9C', 'SV'
    , '9D', 'SV'
    , '9E', 'SV'
    , '9F', 'PM'
    , '9G', 'KP'
    , '9H', 'TO'
    , '9I', 'TO'
    , '9J', 'HM'
    , '9K', 'YN'
    , '9L', 'TN'
    , '9M', 'OM'
    , '9N', 'OM'
    , '9O', 'NS'
    , '9P', 'NS'
    , '9Q', 'KN'
    , '9R', 'KN'
    , '9S', 'OB'
    , '9T', 'OB'
    , '9U', 'KE'
    , '9V', 'KE'
    , '9W', 'BA'
    , '9X', 'KO'
    , '9Y', 'AL'
    , '9Z', 'GA'

{
    '1A', 'SP'
    , '1B', 'SP'
    , '1D', 'SP'
    , '1F', 'SP'
    , '1G', 'SP'
    , '1J', 'SP'
    , '1L', 'SP'
    , '1M', 'SP'
    , '1C', 'LO'
    , '1H', 'LO'
    , '1N', 'KL'
    , '1O', 'AR'
    , '1P', 'NO'
    , '1Q', 'VO'
    , '1R', 'VO'
    , '1S', 'VO'
    , '1T', 'NV'
    , '1W', 'PS'
    , '1Z', 'MU'
    , '2A', 'KA'
    , '2B', 'KA'
    , '2C', 'KA'
    , '2D', 'KA'
    , '2E', 'KA'
    , '2F', 'KA'
    , '3A', 'MA'
    , '3B', 'MA'
    , '3C', 'MA'
    , '3D', 'MO'
    , '3F', 'MO'
    , '3H', 'MO'
    , '3E', 'OR'
    , '3G', 'LP'
    , '3I', 'TV'
    , '3L', 'SM'
    , '3M', 'YR'
    , '3N', 'KS'
    , '3P', 'TL'
    , '3K', 'VR'
    , '3Q', 'VR'
    , '3O', 'VR'
    , '3R', 'TB'
    , '3S', 'RA'
    , '3T', 'NN'
    , '3U', 'IV'
    , '3V', 'VL'
    , '3W', 'KU'
    , '3X', 'KG'
    , '3Y', 'BR'
    , '3Z', 'BO'
    , '4A', 'VG'
    , '4B', 'VG'
    , '4C', 'SA'
    , '4D', 'SA'
    , '4F', 'PE'
    , '4H', 'SR'
    , '4I', 'SR'
    , '4L', 'UL'
    , '4M', 'UL'
    , '4N', 'KI'
    , '4O', 'KI'
    , '4P', 'TA'
    , '4Q', 'TA'
    , '4R', 'TA'
    , '4S', 'MR'
    , '4T', 'MR'
    , '4U', 'MD'
    , '4W', 'UD'
    , '4Y', 'CU'
    , '4Z', 'CU'
    , '6A', 'KR'
    , '6B', 'KR'
    , '6C', 'KR'
    , '6D', 'KR'
    , '6E', 'KC'
    , '6H', 'ST'
    , '6F', 'ST'
    , '6I', 'KM'
    , '6J', 'SO'
    , '6L', 'RO'
    , '6M', 'RO'
    , '6N', 'RO'
    , '6O', 'RO'
    , '6P', 'CN'
    , '6Q', 'IN'
    , '6U', 'AO'
    , '6V', 'AO'
    , '6W', 'DA'
    , '6X', 'KB'
    , '6Y', 'AD'
    , '8T', 'UO'
    , '8V', 'AB'
    , '9A', 'CB'
    , '9B', 'CB'
    , '9C', 'SV'
    , '9D', 'SV'
    , '9E', 'SV'
    , '9F', 'PM'
    , '9G', 'KP'
    , '9H', 'TO'
    , '9I', 'TO'
    , '9J', 'HM'
    , '9K', 'YN'
    , '9L', 'TN'
    , '9M', 'OM'
    , '9N', 'OM'
    , '9O', 'NS'
    , '9P', 'NS'
    , '9Q', 'KN'
    , '9R', 'KN'
    , '9S', 'OB'
    , '9T', 'OB'
    , '9U', 'KE'
    , '9V', 'KE'
    , '9W', 'BA'
    , '9X', 'KO'
    , '9Y', 'AL'
    , '9Z', 'GA'
    , '0A', 'KK'
    , '0B', 'TM'
    , '0C', 'HK'
    , '0D', 'EA'
    , '0F', 'SL'
    , '0E', 'SL'
    , '0H', 'EV'
    , '0I', 'MG'
    , '0J', 'AM'
    , '0K', 'CK'
    , '0L', 'PK'
    , '0M', 'PK'
    , '0N', 'PK'
    , '0O', 'BU'
    , '0Q', 'YA'
    , '0S', 'IR'
    , '0T', 'IR'
    , '0U', 'CT'
    , '0W', 'HA'
    , '0X', 'KY'
    , '0Y', 'TU'
    , '0Z', 'KT'
}
    );

  HexChars                              : array[0..$F] of Char = '0123456789ABCDEF';

  OpModeString                          : array[OpModeType] of PChar {string[3]} = ('CQ', 'SP');

  PTTStatusString                       : array[PTTStatusType] of PChar {string[7]} = ('OFF', 'ON ');

  BufferLength                          = 2048;

  MultiBandAddressArray                 : MultiBandAddressArrayType =
    ($E0, $E1, $E2, $E3, $E4, $E5, {160/80/40/20/15/10}
    $E6, $E7, $E8, $E9, $EA, $EB, $EC, {30/17/12/6/2/222/432}
    $ED, $EE, $EF, $F0, $F1, $F2, $F3, $F4, {902/1GH/2GH/3GH/5GH/10G/24G/LGT}
    $FF, $FF); {All/Non}

type

  FileComparisonType = (Before, Same, After);

  TimeRecord = record
    Hour: Word;
    Minute: Word;
    Second: Word;
    Sec100: Word;
  end;

const
  FrameEnd                              = $C0;
  FrameEscape                           = $DB;
  TransposedFrameEnd                    = $DC;
  TransposedFrameEscape                 = $DD;

  FrameEndChr                           = CHR($C0);
  FrameEscapeChr                        = CHR($DB);
  TransposedFrameEndChr                 = CHR($DC);
  TransposedFrameEscapeChr              = CHR($DD);

  MaximumFileNames                      = 300;

  DegreeSymbol                          = '�';

  ModemStatusAddressOffset              = 6;
  ModemControlAddressOffset             = 4;
  ModemLineControlAddressOffset         = 3;
  PortStatusAddressOffset               = 5;
  PortInterruptEnableOffset             = 1;
  ReceiveDataAddressOffset              = 0;
  TransmitDataAddressOffset             = 0;

  { Key code definitions }

  NullCharacter                         = CHR(0);
  NullKey                               = CHR(0);
  Beep                                  = CHR(7);
  BackSpace                             = CHR(8);
  TabKey                                = CHR(9);
  CarriageReturn                        = CHR($D);
  LineFeed                              = CHR($A);
  EscapeKey                             = CHR($1B);
  SpaceBar                              = ' ';
  ShiftTab                              = CHR(15); { After null char }

  F1                                    = CHR(112); // Function key codes
  F2                                    = CHR(113);
  F3                                    = CHR(114);
  F4                                    = CHR(115);
  F5                                    = CHR(116);
  F6                                    = CHR(117);
  F7                                    = CHR(118);
  F8                                    = CHR(119);
  F9                                    = CHR(120);
  F10                                   = CHR(121);
  F11                                   = CHR(122);
  F12                                   = CHR(123);
  //ShiftF+12
  {  ShiftF1 = CHR(124);
    ShiftF2 =  CHR(125);
    ShiftF3 =  CHR(126);
    ShiftF4 =  CHR(127);
    ShiftF5 =  CHR(128);
    ShiftF6 =  CHR(129);
    ShiftF7 =  CHR(130);
    ShiftF8 =  CHR(131);
    ShiftF9 =  CHR(132);
    ShiftF10 = CHR(133);
    ShiftF11 = CHR(134);
    ShiftF12 = CHR(135);
  }
    //ControlF+12
  ControlF1                             = CHR(124);
  ControlF2                             = CHR(125);
  ControlF3                             = CHR(126);
  ControlF4                             = CHR(127);
  ControlF5                             = CHR(128);
  ControlF6                             = CHR(129);
  ControlF7                             = CHR(130);
  ControlF8                             = CHR(131);
  ControlF9                             = CHR(132);
  ControlF10                            = CHR(133);
  ControlF11                            = CHR(134);
  ControlF12                            = CHR(135);

  ControlBackSpace                      = CHR($7F);
  //AltF+24
  AltF1                                 = CHR(136);
  AltF2                                 = CHR(137);
  AltF3                                 = CHR(138);
  AltF4                                 = CHR(139);
  AltF5                                 = CHR(140);
  AltF6                                 = CHR(141);
  AltF7                                 = CHR(142);
  AltF8                                 = CHR(143);
  AltF9                                 = CHR(144);
  AltF10                                = CHR(145);
  AltF11                                = CHR(146);
  AltF12                                = CHR(147);

  {
    F1 = CHR(59); // Function key codes
    F2 = CHR(60);
    F3 = CHR(61);
    F4 = CHR(62);
    F5 = CHR(63);
    F6 = CHR(64);
    F7 = CHR(65);
    F8 = CHR(66);
    F9 = CHR(67);
    F10 = CHR(68);
    F11 = CHR($85);
    F12 = CHR($86);

    ShiftF1 = CHR(84);
    ShiftF2 = CHR(85);
    ShiftF3 = CHR(86);
    ShiftF4 = CHR(87);
    ShiftF5 = CHR(88);
    ShiftF6 = CHR(89);
    ShiftF7 = CHR(90);
    ShiftF8 = CHR(91);
    ShiftF9 = CHR(92);
    ShiftF10 = CHR(93);
    ShiftF11 = CHR($87);
    ShiftF12 = CHR($88);

    ControlF1 = CHR(94);
    ControlF2 = CHR(95);
    ControlF3 = CHR(96);
    ControlF4 = CHR(97);
    ControlF5 = CHR(98);
    ControlF6 = CHR(99);
    ControlF7 = CHR(100);
    ControlF8 = CHR(101);
    ControlF9 = CHR(102);
    ControlF10 = CHR(103);
    ControlF11 = CHR($89);
    ControlF12 = CHR($8A);

    AltF1 = CHR(104);
    AltF2 = CHR(105);
    AltF3 = CHR(106);
    AltF4 = CHR(107);
    AltF5 = CHR(108);
    AltF6 = CHR(109);
    AltF7 = CHR(110);
    AltF8 = CHR(111);
    AltF9 = CHR(112);
    AltF10 = CHR(113);
    AltF11 = CHR($8B);
    AltF12 = CHR($8C);
  }
  //  AltQ = CHR(16);
  AltW                                  = CHR(17);
  //  AltE = CHR(18);
  AltR                                  = CHR(19);
  //  AltT = CHR(20);
  //  AltY = CHR(21);
  ////  AltU = CHR(22);
  //  AltI = CHR(23);
  //  AltO = CHR(24);
  //  AltP = CHR(25);
  //  AltA = CHR(30);
  //  AltS = CHR(31);
  //  AltD = CHR(32);
  //  AltF = CHR(33);
  //  AltG = CHR(34);
  //  AltH = CHR(35);
  //  AltJ = CHR(36);
  //  AltK = CHR(37);
  //  AltL = CHR(38);
  //  AltZ = CHR(44);
  //  AltX = CHR(45);
  //  AltC = CHR(46);
  //  AltV = CHR(47);
  //  AltB = CHR(48);
  //  AltN = CHR(49);
  //  AltM = CHR(50);

  {  Alt1 = CHR(120);
    Alt2 = CHR(121);
    Alt3 = CHR(122);
    Alt4 = CHR(123);
    Alt5 = CHR(124);
    Alt6 = CHR(125);
    Alt7 = CHR(126);
    Alt8 = CHR(127);
    Alt9 = CHR(128);
    Alt0 = CHR(129);
    AltEqual = CHR(131);
    AltDash = CHR(130);
  }
   { These are extended }

  HomeKey                               = CHR(71);
  UpArrow                               = CHR(72);
  PageUpKey                             = CHR(73);
  LeftArrow                             = CHR(75);
  RightArrow                            = CHR(77);
  EndKey                                = CHR(79);
  DownArrow                             = CHR(80);
  PageDownKey                           = CHR(81);
  InsertKey                             = CHR(82);
  DeleteKey                             = CHR(83);

  {KK1L: 6.65 Added following eight definitions}
 //  AltInsert = CHR(162);
 //  AltDelete = CHR(163);
 //  ControlInsert = CHR(146);
 //  ControlDelete = CHR(147);
 //  AltDownArrow = CHR(160);
 //  AltUpArrow = CHR(152);
 //  ControlDownArrow = CHR(145);
 //  ControlUpArrow = CHR(141);

  {KK1L: 6.72 Added following set constant for Scandinavian letters}
  AccentedChars                         : set of Char = [CHR(132), CHR(142), {A umlaut  }
    CHR(134), CHR(143), {A dot     }
    CHR(148), CHR(153)]; {O umlaut  }

type

  BufferArrayType = array[0..BufferLength] of Byte;

  //  CharacterBuffer = object
  //    Tail: integer; { Oldest entry address }
  //    Head: integer; { Place where new entry goes }
  //    List: ^BufferArrayType;

        { Set Debug = TRUE to have all activity logged.  This isn't
          actually done in this unit, since we really don't know
          what serial port we are dealing with and if we are coming
          or going.  But it seemed like putting the variables here
          made it easier to think about. }

  //    Debug: boolean; { Set TRUE to enable debug activity }
  //    DebugFile: Text {wli  file}; { Is setup as a read file if this is an input      buffer, write file if an output buffer }

  //    procedure InitializeBuffer;
  //    procedure AddEntry(Entry: Byte);
  //    procedure AddString(Entry: string);
  //    procedure ClearBuffer;
  //    function FreeSpace: integer;
  //    function GetNextByte(var Entry: Byte): boolean;
  //    function GetSlippedString(var Entry: string): boolean;
  //    function GetNextLine(var Entry: string): boolean;
  //    procedure GoAway;
  //    function IsEmpty: boolean;
  //  end;

  FileNameRecord = record
    NumberFiles: integer;
    List: array[0..MaximumFileNames - 1] of string[12];
  end;

  BufferType = array[0..$FF] of Char;
  BufferTypePtr = ^BufferType;

const
  InitialCodeSpeed                      = 35;
var

  CodeSpeed                             : integer = InitialCodeSpeed;
  //  FMMode                           : boolean;
    //  HourOffset                            : integer;
  QuestionMarkChar                      : Char = '?';
  SlashMarkChar                         : Char = '/';
  //  UseBIOSCOMIO                     : boolean;
    //   UseBIOSKeyCalls                 : boolean;

//  Com1PortBaseAddress              : Word;
//  Com2PortBaseAddress              : Word;
//  Com3PortBaseAddress              : Word;
//  Com4PortBaseAddress              : Word;
//  Com5PortBaseAddress              : Word;
//  Com6PortBaseAddress              : Word;

  //  tr4w_SerialPortDebug        : boolean;
function CheckPTTLockout: boolean;
function GetRealPath(Path, FileName, AddFolder: PChar): PChar;

function AddBand(Band: BandType): Char;
function AddMode(Mode: ModeType): Char;

function AlphaPartOfString(InputString: Str160): Str80;

//function ArcCos(X: REAL): REAL;
//function ATan2(Y, X: REAL): REAL;

function BigCompressedCallsAreEqual(Call1, Call2: EightBytes): boolean;
procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);
//procedure BigCursor;
function BigExpandedString(Input: EightBytes): Str80;
function BracketedString(LongString: Str160; StartString: Str80; StopString: Str80): Str80;
//{WLI}    FUNCTION  BYTADDR  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): INTEGER;
//{WLI}    FUNCTION  BYTDUPE  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): BOOLEAN;
//{WLI}    FUNCTION  BYTSTOCR (List: Pointer; Start: INTEGER): INTEGER;

procedure CalculateBandMode(Freq: Cardinal; var Band: BandType; var Mode: ModeType);
function KeyboardCallsignChar(var Key: integer; ExChWin: boolean): boolean;

function CallFitsFormat(Format: Str20; Call: Str20): boolean;
function CallSortValue(Call: CallString): LONGINT;
function CharReady(SerialPort: PortType): boolean;

function CheckSum(InputString: string): Byte;
function CheckSumWord(InputString: string): Word;

procedure CompressFormat(Call: CallString; var Output: FourBytes);

//function ControlKeyPressed: boolean;
function CopyWord(LongString: string; Index: integer): Str80;

procedure DecrementASCIIInteger(var ASCIIString: Str80);
procedure DelayOrKeyPressed(DelayTime: integer);
function DeleteMult(var LogString: Str80; MultString: Str20): boolean;

function ElaspedTimeString(StartTime: Cardinal {TimeRecord}): PChar {Str20};
function ElaspedSec100(StartTime: Cardinal {TimeRecord}): LONGINT;

function ExpandedString(Input: FourBytes): Str80;
procedure ExpandTabs(var InputString: string);
function ExpandTwoBytes(Input: TwoBytes): Str80;
//wli

function FirstLetter(InputString: Str80): Char;
procedure FormFeed;

function GetChecksum8(Call: FourBytes): integer;
function GetColorInteger(ColorString: Str80): tr4wColors;
function GetDateString: PChar;
function GetDayString: Str80;
//procedure GetFileNames(Path: Str80; Mask: Str80; var FileNames: FileNameRecord);

function GetFirstString(LongString: string): Str80;
function GetFullTimeString(WithMilliseconds: boolean): PChar {str80};
function GetIntegerTime: integer;

function GetLastString(LongString: ShortString): Str80;

function GetLogEntryBand(LogEntry: Str160): BandType;
function GetLogEntryCall(LogEntry: Str160): {Call} string {Str160};
function GetLogEntryComputerID(LogEntry: Str160): Char;
function GetLogEntryDateString(LogEntry: Str160): Str160;
function GetLogEntryExchangeString(LogEntry: Str160): Str160;
function GetLogEntryHour(LogEntry: Str160): integer;
function GetLogEntryIntegerTime(LogEntry: Str160): integer;
function GetLogEntryMode(LogEntry: string {160}): ModeType;
function GetLogEntryMultString(LogEntry: Str160): Str160;
function GetLogEntryQSONumber(LogEntry: Str160): integer;
function GetLogEntryQSOPoints(LogEntry: Str160): integer;
function GetLogEntryRSTString(LogEntry: Str160): string;
function tGetLogEntryRcvdRSTString(LogEntry: Str160): string;
function GoodLookingRDA(RDA: Str20): boolean;
function GetOblast(Call: CallString): Str2;
function GetLogEntryTimeString(LogEntry: Str160): Str160;

function GetKey(Prompt: Str80): Char;
function GetKeyResponse(Prompt: string): Char;

function GetReal(Prompt: PChar): REAL;
function GetResponse(Prompt: PChar {string}): ShortString;
procedure GetRidOfCarriageReturnLineFeeds(var s: string);
procedure GetRidOfPostcedingSpaces(var s: ShortString);
procedure GetRidOfPrecedingSpaces(var s: ShortString);
function GetSCPCharFromInteger(Index: integer): Char;
function GetSCPIntegerFromChar(InputChar: Char): integer;
function GetStateFromSection(Section: Str20): Str20;
function GetSuffix(Call: CallString): CallString;
function GetTimeString: PChar {str80};
function GetTimeString4Digit: PChar;
function GetTomorrowString: Str80;

function GetYearString: PChar {Str20};

function GoodLookingGrid(Grid: Str20): boolean;
function GoodLookingGrid2(Grid: Str20): boolean;
function GoodLookingGrid3(Grid: Str20): boolean;
procedure HexToInteger(InputString: Str80; var OutputInteger: integer; var Result: integer);
procedure HexToLongInteger(InputString: Str80; var OutputInteger: LONGINT; var Result: integer);
procedure HexToWord(InputString: Str80; var OutputWord: Word; var Result: integer);

procedure IncrementASCIIInteger(var ASCIIString: Str80);
procedure IncrementMinute(var DateString: Str20; var TimeString: Str80);
function WordValueFromCharacter(Character: Char): Word;

//procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: word);
//function DecodeDateFully(const DateTime: TDateTime; var Year, Month, Day, DOW: word): boolean;
//function DateTimeToTimeStamp(DateTime: TDateTime): ttimestamp;
//procedure DivMod(Dividend: integer; Divisor: word; var RESULT, Remainder: word);
//procedure DecodeTime(const DateTime: TDateTime; var Hour, Min, Sec, msec: word);
//function EncodeDate(Year, Month, Day: word): TDateTime;
//function TryEncodeDate(Year, Month, Day: word; out Date: TDateTime): boolean;
//function TryEncodeTime(Hour, Min, Sec, msec: word; out Time: TDateTime): boolean;
//function IsLeapYear(Year: word): boolean;
//procedure ReplaceTime(var DateTime: TDateTime; const NewTime: TDateTime);

//function tr4w_HourWithHourOffset(Hour: Smallint): Smallint;
function tGetBandFromString(BandStr: ShortString): BandType;

procedure IncSystemTime(var St: SYSTEMTIME; Offset: int64);
procedure tGetQSOSystemTime(var Time: TQSOTime);
function QSOTimeToSeconds(t: TQSOTime): integer;
//procedure Congrats;

{PROCEDURE}
function InitializeSerialPort(
  SerialPort: PortType;
  BaudRate: Cardinal;
  Bits: Byte;
  Parity: ParityType;
  StopBits: Byte;
  dwFlagsAndAttributes: DWORD;
  EvtChar: Char): HWND;

function KeyId(Key: Char): Str10;

function LastLetter(InputString: Str160): Char;
function LastString(InputString: ShortString {Str160} {WLI}): Str160;
function LineInput(Prompt: Str160;
  InitialString: Str160;
  OverwriteEnable: boolean;
  ExitOnAltKey: boolean): Str160;

function LowerCase(const s: string): string;
function LooksLikeAGrid(var GridString: ShortString): boolean;
function LooksLikeAGridIgnoreAE(var GridString: ShortString): boolean;
function LooksLikeAPOTAPark(park: string): boolean;
function LooksLikeAState(state: string): boolean; // NY4I
function LooksLikeASection(section: string): boolean;
function Lpt1BaseAddress: Word;
function Lpt2BaseAddress: Word;
function Lpt3BaseAddress: Word;

function MakeDupeFilename(Band: BandType; Mode: ModeType): Str80;
function MakeTitle(Band: BandType; Mode: ModeType; Contest: Str80; CallUsed: Str80): Str80;
procedure MarkTime(var StartTime: Cardinal {TimeRecord});
function MicroTimeElapsed(StartTime: Cardinal {TimeRecord}): LONGINT;
function MinutesToTimeString(Minutes: integer): Str20;
function MultiMessageSourceBand(Source: Byte): BandType;

function NewKeyPressed: boolean;
function NewReadKey: Char;

//procedure NoCursor;
//{WLI}    FUNCTION  NUMBYTES (Call1: Pointer; Call2: Pointer): INTEGER;
function NumberPartOfString(InputString: Str160): Str80;

function OkayToDeleteExistingFile(FileName: PChar): boolean;
function OkayToProceed: boolean;
function OpenDupeFileForRead(var FileHandle: Text; FileName: Str80): boolean;
function OpenFileForAppend(var FileHandle: Text; FileName: string): boolean;
function OpenFileForRead_old(var FileHandle: Text; FileName: string {Str80}): boolean;

function OperatorEscape: boolean;

function PacketCharReady(SerialPort: PortType; var CIn: Char): boolean;
procedure PacketSendChar(SerialPort: PortType; CharToSend: Char);
function PartialCall(Pattern: CallString; Call: CallString): boolean;
function PortableStation(Call: CallString): boolean;

function ReadChar(SerialPort: PortType): Char;

procedure RenameFile(OldName: string; NewName: string);

function RemoveBand(var LongString: ShortString): BandType;
function RemoveFirstChar(var LongString: string): Char;
function RemoveFirstLongInteger(var LongString: ShortString): LONGINT;
function RemoveFirstReal(var LongString: ShortString): REAL;
function RemoveFirstString(var LongString: ShortString): Str80;
function RemoveLastString(var LongString: ShortString): Str80;
function RemoveMode(var LongString: ShortString): ModeType;

procedure SendByte(SerialPort: PortType; ByteToSend: Byte);
procedure SendChar(SerialPort: PortType; CharToSend: Char);

function SlipMessage(Message: string): string;

function UpperCase_old(const s: string): string;

//function UpperCase(const s: string): string;

function ValidRST(var Ex: ShortString {Str80} {WLI}; var RST: smallInt {Word} {RSTString}; Mode: ModeType): boolean;

function WhiteSpaceCharacter(InputChar: Char): boolean;

//procedure WriteColor(Prompt: Str80; FColor: INTEGER; BColor: INTEGER);

procedure SixteenthNote(Pitch: integer);
procedure EigthNote(Pitch: integer);

//function Get_Tstrings_from_string(s: string; ts: tstringLIST): boolean;
procedure QuickBeep;
function TryToOpenCOMPort(portnr: Cardinal {Byte}; dwFlagsAndAttributes: DWORD): HWND;
const
  NoteVeryLoA                           = 220;
  NoteVeryLoASharp                      = 235;
  NoteVeryLoBFlat                       = 235;
  NoteVeryLoB                           = 250;
  NoteVeryLoBSharp                      = 265;
  NoteLoC                               = 265;
  NoteLoCSharp                          = 280;
  NoteLoDFlat                           = 280;
  NoteLoD                               = 295;
  NoteLoDSharp                          = 312;
  NoteLoEFlat                           = 312;
  NoteLoE                               = 330;
  NoteLoESharp                          = 350;
  NoteLoFFlat                           = 330;
  NoteLoF                               = 350;
  NoteLoFSharp                          = 372;
  NoteLoGFlat                           = 372;
  NoteLoG                               = 395;
  NoteLoGSharp                          = 417;
  NoteLoAFlat                           = 417;
  NoteLoA                               = 440;
  NoteLoASharp                          = 470;
  NoteLoBFlat                           = 470;
  NoteLoB                               = 500;
  NoteLoBSharp                          = 530;
  NoteCFlat                             = 500;
  NoteC                                 = 530;
  NoteCSharp                            = 560;
  NoteDFlat                             = 560;
  NoteD                                 = 590;
  NoteDSharp                            = 625;
  NoteEFlat                             = 625;
  NoteE                                 = 660;
  NoteESharp                            = 700;
  NoteFFlat                             = 660;
  NoteF                                 = 700;
  NoteFSharp                            = 745;
  NoteGFlat                             = 745;
  NoteG                                 = 790;
  NoteGSharp                            = 835;
  NoteAFlat                             = 835;
  NoteA                                 = 880;
  NoteASharp                            = 940;
  NoteBFlat                             = 940;
  NoteB                                 = 1000;
  NoteBSharp                            = 1060;
  NoteHiCFlat                           = 1000;
  NoteHiC                               = 1060;
  NoteHiCSharp                          = 1120;
  NoteHiDFlat                           = 1120;
  NoteHiD                               = 1180;
  NoteHiDSharp                          = 1250;
  NoteHiEFlat                           = 1250;
  NoteHiE                               = 1320;
  NoteHiESharp                          = 1400;
  NoteHiFFlat                           = 1320;
  NoteHiF                               = 1400;
  NoteHiFSharp                          = 1490;
  NoteHiGFlat                           = 1490;
  NoteHiG                               = 1580;
  NoteHiGSharp                          = 1670;
  NoteHiAFlat                           = 1670;
  NoteHiA                               = 1760;
  NoteHiASharp                          = 1880;
  NoteHiBFlat                           = 1880;
  NoteHiB                               = 2000;
  NoteVeryHiE                           = 2640;
  NoNote                                = 50;

procedure WriteLnCenter(Prompt: Str80);
procedure WriteLnVarCenter(var FileWrite: Text; Prompt: Str80);
procedure WriteLnLstCenter(Prompt: Str80);
function FoundDirectory(FileName: string; Path: string; var Directory: string): boolean;
function FindDirectory(FileName: Str80): Str80;
function String2Hex(const Buffer: Ansistring): string;

var
  Beat                                  : integer = 500;
implementation

uses
  uCallCompress,   // pre-migration: extracted callsign-compression primitives (golden-tested)
  LogStuff,
  uNet,
  LogDupe,
  BeepUnit,
  MainUnit,
  LogWind
  ,
  LogK1EA
  ,
  uFreqTimeFormat   // Issue #997: golden-tested time formatter
  ;

//{WLI}FUNCTION  BYTADDR  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): INTEGER; EXTERNAL;
//{WLI}FUNCTION  BYTDUPE  (Call: Pointer; NumberCalls: INTEGER; A: Pointer): BOOLEAN; EXTERNAL;
//{WLI}FUNCTION  NUMBYTES (Call1: Pointer; Call2: Pointer): INTEGER; EXTERNAL;
//{WLI}FUNCTION  BYTSTOCR (List: Pointer; Start: INTEGER): INTEGER; EXTERNAL;

var
//  ActivityCounter                       : integer;
//  CharacterSpace                        : integer;
  CWPitch                               : integer;
  DahLength                             : integer;
  DitLength                             : integer;
//  ExtendedKey                           : Byte;
  //  MouseType                             : MouseTypeType;
//  ReadKeyAltState                       : boolean;
//  WordSpace                             : integer;

  //{WLI}{$L dupe}

  { The first set of routines are local to TREE }

function CharacterFromIntegerValue(IntegerValue: integer): Char;

{ This table is used for compressing data. }

begin
  Result := '?';

  if IntegerValue = 0 then CharacterFromIntegerValue := ' ';

  if IntegerValue >= 1 then
    if IntegerValue <= 10 then
      Result := CHR(IntegerValue + 47);

  if IntegerValue >= 11 then
    if IntegerValue <= 36 then
      Result := CHR(IntegerValue + 54);

  {
    case IntegerValue of
      0: CharacterFromIntegerValue := ' ';
      1: CharacterFromIntegerValue := '0';
      2: CharacterFromIntegerValue := '1';
      3: CharacterFromIntegerValue := '2';
      4: CharacterFromIntegerValue := '3';
      5: CharacterFromIntegerValue := '4';
      6: CharacterFromIntegerValue := '5';
      7: CharacterFromIntegerValue := '6';
      8: CharacterFromIntegerValue := '7';
      9: CharacterFromIntegerValue := '8';

      10: CharacterFromIntegerValue := '9';
      11: CharacterFromIntegerValue := 'A';
      12: CharacterFromIntegerValue := 'B';
      13: CharacterFromIntegerValue := 'C';
      14: CharacterFromIntegerValue := 'D';
      15: CharacterFromIntegerValue := 'E';
      16: CharacterFromIntegerValue := 'F';
      17: CharacterFromIntegerValue := 'G';
      18: CharacterFromIntegerValue := 'H';
      19: CharacterFromIntegerValue := 'I';
      20: CharacterFromIntegerValue := 'J';
      21: CharacterFromIntegerValue := 'K';
      22: CharacterFromIntegerValue := 'L';
      23: CharacterFromIntegerValue := 'M';
      24: CharacterFromIntegerValue := 'N';
      25: CharacterFromIntegerValue := 'O';
      26: CharacterFromIntegerValue := 'P';
      27: CharacterFromIntegerValue := 'Q';
      28: CharacterFromIntegerValue := 'R';
      29: CharacterFromIntegerValue := 'S';
      30: CharacterFromIntegerValue := 'T';
      31: CharacterFromIntegerValue := 'U';
      32: CharacterFromIntegerValue := 'V';
      33: CharacterFromIntegerValue := 'W';
      34: CharacterFromIntegerValue := 'X';
      35: CharacterFromIntegerValue := 'Y';
      36: CharacterFromIntegerValue := 'Z';
    else CharacterFromIntegerValue := '?';
    end;
  }
end;

function WordValueFromCharacter(Character: Char): Word;

//var   TempInteger                     : Word;

   { This table is used for compressing data. }

begin
  if (Character = CHR(0)) or (Character = ' ') or
    (Character = '/') or (Character = '?') then
  begin
    WordValueFromCharacter := 0;
    Exit;
  end;

  if Character in ['A'..'Z'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('A') + 11;
    Exit;
  end;

  if Character in ['a'..'z'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('a') + 11;
    Exit;
  end;

  if Character in ['0'..'9'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('0') + 1;
    Exit;
  end;

  if Character = '�' then
  begin
    WordValueFromCharacter := 1;
    Exit;
  end;

  WordValueFromCharacter := 0;
end;

procedure CompressThreeCharacters(Input: Str80; var Output: TwoBytes);

{ This procedure will compress a string of up to 3 characters to 2 bytes. }

var
  Multiplier, Value, Sum                : Word;
  LoopCount, CharPosition               : integer;

begin
  if ((Input = '') or (length(Input) > 3)) then
  begin
    Output[1] := 0;
    Output[2] := 0;
    Exit;
  end;

  Multiplier := 1;
  Sum := 0;
  LoopCount := 0;
  {
     if length(Input) > 3 then
        begin
           Output[1] := 0;
           Output[2] := 0;
           Exit;
        end;
  }
  for CharPosition := length(Input) downto 1 do
  begin
    Value := WordValueFromCharacter(Input[CharPosition]);
    Sum := Sum + Value * Multiplier;
    inc(LoopCount);
    if LoopCount >= 3 then Break;
    Multiplier := Multiplier * 37;
  end;

  Output[2] := Lo(Sum);
  Output[1] := Hi(Sum);
end;

function ExpandTwoBytes(Input: TwoBytes): Str80;

var
  Sum                                   : LONGINT;
  TempString                            : Str80;
  TempInt1, TempInt2                    : LONGINT;

begin
  TempInt1 := Input[1];
  if TempInt1 < 0 then TempInt1 := TempInt1 + 256;
  TempInt2 := Input[2];
  if TempInt2 < 0 then TempInt2 := TempInt2 + 256;
  Sum := TempInt1 * 256 + TempInt2;

  if Sum = 0 then
  begin
    ExpandTwoBytes := '';
    Exit;
  end;

  TempString := CharacterFromIntegerValue(Sum div 1369);
  if TempString[1] = CHR(0) then TempString := '';
  Sum := Sum mod 1369;
  TempString := TempString + CharacterFromIntegerValue(Sum div 37);
  if TempString[1] = CHR(0) then TempString := '';
  Sum := Sum mod 37;
  TempString := TempString + CharacterFromIntegerValue(Sum);
  if TempString[1] = CHR(0) then TempString := '';
  ExpandTwoBytes := TempString;
end;

procedure SixteenthNote(Pitch: integer);

begin
  if Pitch > 0 then
    SpeakerBeep(Pitch, Beat div 4);
  //  begin
  //    Sound(Pitch);
  //  end;
  //  Sleep(Beat div 4);
  //  NoSound;
end;

procedure EigthNote(Pitch: integer);

begin
  if Pitch > 0 then
    SpeakerBeep(Pitch, Beat div 2);
  //  begin
  //    Sound(Pitch);
  //  end;
  //  Sleep(Beat div 2);
  //  NoSound;
end;

procedure QuarterNote(Pitch: integer);

begin
  if Pitch > 0 then
    SpeakerBeep(Pitch, Beat);
  //  begin
  //    Sound(Pitch);
  //  end;
  //  Sleep(Beat);
  //  NoSound;
end;

procedure Dit;

begin
  Sound(CWPitch);
  Sleep(DitLength);
  NoSound;
  Sleep(DitLength);
end;

procedure Dah;

begin
  Sound(CWPitch);
  Sleep(DahLength);
  NoSound;
  Sleep(DitLength);
end;

{ Now for the external routines in alphabetical order. }

function AddBand(Band: BandType): Char;

var
  TempChar                              : Char;

begin
  Move(Band, TempChar, 1);
  AddBand := TempChar;
end;

function AddMode(Mode: ModeType): Char;

var
  TempChar                              : Char;

begin
  Move(Mode, TempChar, 1);
  AddMode := TempChar;
end;

function AlphaPartOfString(InputString: Str160): Str80;

var
  TempString                            : Str80;
  CharPointer                           : integer;

begin
  if InputString = '' then
  begin
    AlphaPartOfString := '';
    Exit;
  end;

  TempString := '';

  for CharPointer := 1 to length(InputString) do
    if (InputString[CharPointer] >= 'A') and (InputString[CharPointer] <= 'Z') then
      TempString := TempString + InputString[CharPointer];

  AlphaPartOfString := TempString;
end;

function BigCompressedCallsAreEqual(Call1, Call2: EightBytes): boolean;
begin
  Result := int64(Call1) = int64(Call2);
end;

procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);

{ Extracted to uCallCompress.pas (pre-migration test net). Behavior unchanged. }

begin
  uCallCompress.BigCompressFormat(Call, CompressedBigCall);
end;

function BigExpandedString(Input: EightBytes): Str80;

var
  TempBytes                             : TwoBytes;
  TempString                            : Str80;

begin
  TempBytes[1] := Input[1];
  TempBytes[2] := Input[2];
  TempString := ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[3];
  TempBytes[2] := Input[4];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[5];
  TempBytes[2] := Input[6];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[7];
  TempBytes[2] := Input[8];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  while (TempString[1] = ' ') and (length(TempString) > 1) do
    Delete(TempString, 1, 1);
  BigExpandedString := TempString;
end;

function BracketedString(LongString: Str160; StartString: Str80; StopString: Str80): Str80;

{ This function will return any string sits between the StartString and the
  StopString.  The shortest possible string to meet this criteria is
  returned.  If the start string is null, then the returned string will
  be the preceding string to the StopString.  If the StopString is null, the
  returned string will be the postceding string to the StartString.         }

var
  StartLocation, StopLocation           : integer;

begin
  BracketedString := '';

  if StartString <> '' then
  begin
    StartLocation := pos(StartString, LongString);
    if StartLocation = 0 then Exit;
  end
  else
    StartLocation := 0;

  if StartLocation > 0 then
    Delete(LongString, 1, StartLocation + length(StartString) - 1);

  if StopString = '' then
  begin
    BracketedString := LongString;
    Exit;
  end
  else
  begin
    StopLocation := pos(StopString, LongString);
    if StopLocation = 0 then Exit;
  end;

  BracketedString := Copy(LongString, 1, StopLocation - 1);
end;

procedure CalculateBandMode(Freq: Cardinal; var Band: BandType; var Mode: ModeType);
begin
  // ---------------------------------------------------------------------------
  // This is a forwarding stub.  The actual implementation lives in
  // src/uBandLookup.pas.
  //
  // WHY:
  //   Tree.pas is 5,292 lines and `uses` the world (TF, Win32 Windows/Messages,
  //   uCallSignRoutines, etc.).  Pulling tree.pas into the unit-test EXE
  //   drags that entire dependency cone in -- which kills the test runner's
  //   isolation and blows up build/link times.
  //
  //   To unit-test CalculateBandMode, the function body was lifted -- verbatim
  //   -- into src/uBandLookup.pas, which `uses VC` only.  See
  //   docs/tr4w-migration-strategy.md, section "Tier 1 Extraction Pattern".
  //
  // CALLER COMPATIBILITY:
  //   The 10 existing call sites in LOGPACK / LOGSUBS1 / LOGWIND all
  //   `uses Tree;` and reach this declaration.  Keeping the stub here means
  //   none of those files had to change.  Callers see identical behavior
  //   because the implementation in uBandLookup is the same code that used
  //   to live here.
  //
  // QUALIFIED CALL BELOW:
  //   `uBandLookup.CalculateBandMode(...)` is qualified deliberately.  Tree's
  //   own interface still declares CalculateBandMode, so the bare name would
  //   resolve to this very procedure and infinite-recurse.  The unit prefix
  //   selects the implementation in uBandLookup.
  //
  // DO NOT add logic here.  If band-lookup behavior needs to change, edit
  // uBandLookup.pas so the unit tests can prove the change.
  // ---------------------------------------------------------------------------
  uBandLookup.CalculateBandMode(Freq, Band, Mode);
end;

function CallFitsFormat(Format: Str20; Call: Str20): boolean;

{ Format includes ? and * characters }

var
  LengthFormat, LengthCall, CallAddress, FormatAddress: integer;

begin
  LengthFormat := length(Format);
  LengthCall := length(Call);

  FormatAddress := 1;
  CallAddress := 1;

  repeat

    { See if the charaters are the same }

    if Format[FormatAddress] = Call[CallAddress] then
    begin
      if FormatAddress <= LengthFormat then inc(FormatAddress);
      if CallAddress <= LengthCall then inc(CallAddress);
      Continue;
    end;

    { We have a mismatch.  If ? in format - count it like a match }

    if Format[FormatAddress] = '?' then
    begin
      if FormatAddress <= LengthFormat then inc(FormatAddress);

      if CallAddress <= LengthCall then
        inc(CallAddress)
      else
      begin { We didn't have a character to match up with ? }
        CallFitsFormat := False;
        Exit;
      end;

      Continue;
    end;

    { Now for the hard one - we are going to assume that only one
      * can be contained in the format statement }

    if Format[FormatAddress] = '*' then
    begin
      if FormatAddress = LengthFormat then { We are done }
      begin
        CallFitsFormat := True;
        Exit;
      end;

        { * found - not at end.  See if stuff after * matches }

      Format := Copy(Format,
        FormatAddress + 1,
        LengthFormat - FormatAddress);

      Call := Copy(Call, length(Call) - length(Format) + 1, length(Format));

      if Call = Format then
      begin
        CallFitsFormat := True;
        Exit;
      end;

      CallFitsFormat := CallFitsFormat(Format, Call);
      Exit;
    end;

    { We have a real mismatch - so return a FALSE value }

    CallFitsFormat := False;
    Exit;

  until (FormatAddress = LengthFormat + 1) and (CallAddress = LengthCall + 1);

  CallFitsFormat := True;
end;

function PacketCharReady(SerialPort: PortType; var CIn: Char): boolean;

{ This funtion will see if a char is waiting in the packet port. }

{VAR PortAddress: WORD;
    Regs: Registers;
    Ready: BOOLEAN;
    }
begin
  {    PortAddress := 0;

      CASE SerialPort OF
          Serial1: PortAddress := Com1PortBaseAddress;
          Serial2: PortAddress := Com2PortBaseAddress;
          Serial3: PortAddress := Com3PortBaseAddress;
          Serial4: PortAddress := Com4PortBaseAddress;
          Serial5: PortAddress := Com5PortBaseAddress;
          Serial6: PortAddress := Com6PortBaseAddress;

          DRSI: BEGIN
                Regs.AX := 0;
                Intr ($FF, Regs);
                CIn := Chr (Regs.AL);
                PacketCharReady := Regs.AH <> 0;
                Exit;
                END;
          END;

      IF PortAddress <> 0 THEN
          BEGIN
          Ready := (Port [PortAddress + 5] AND 1) = 1;

          IF Ready THEN Cin := Chr (Port [PortAddress]);

          PacketCharReady := Ready;
          END
      ELSE
          PacketCharReady := False;

 }
end;

function CharReady(SerialPort: PortType): boolean;
//{WLI}
{ This funtion will see if a char is waiting in the UART }

{VAR PortAddress: WORD;
    Regs: REGISTERS;
}
begin
  {    IF UseBIOSCOMIO THEN
          BEGIN
          Regs.AH := 3;

          CASE SerialPort OF
              Serial1: Regs.DX := 0;
              Serial2: Regs.DX := 1;
              Serial3: Regs.DX := 2;
              Serial4: Regs.DX := 3;

              ELSE
                  BEGIN
                  CharReady := True;   // a safer value than false
                  Exit;
                  END;
              END;

          Intr ($14, Regs);

          CharReady := (Regs.AH AND 1) = 1;
          END

      ELSE

          BEGIN
          PortAddress := 0;

          CASE SerialPort OF
              Serial1: PortAddress := Com1PortBaseAddress;
              Serial2: PortAddress := Com2PortBaseAddress;
              Serial3: PortAddress := Com3PortBaseAddress;
              Serial4: PortAddress := Com4PortBaseAddress;
              Serial5: PortAddress := Com5PortBaseAddress;
              Serial6: PortAddress := Com6PortBaseAddress;
              END;

          IF PortAddress <> 0 THEN
              BEGIN
              PortAddress := PortAddress + 5;
              CharReady := (Port [PortAddress] AND 1) = 1;
              END
          ELSE
              CharReady := False;
          END;

 }
end;

function CheckSum(InputString: string): Byte;

var
  Index, Sum                            : Word;

begin
  Sum := 0;

  if length(InputString) > 0 then
    for Index := 1 to length(InputString) do
      Sum := Sum + Ord(InputString[Index]);

  CheckSum := Lo(Sum);
end;

function CheckSumWord(InputString: string): Word;

var
  Index, Sum                            : Word;

begin
  Sum := 0;

  if length(InputString) > 0 then
    for Index := 1 to length(InputString) do
      Sum := Sum + Ord(InputString[Index]);

  CheckSumWord := Sum;
end;

procedure CompressFormat(Call: CallString; var Output: FourBytes);

{ Extracted to uCallCompress.pas (pre-migration test net). Forwards so the ~13
  callers run the now unit-tested implementation. Behavior unchanged. }

begin
  uCallCompress.CompressFormat(Call, Output);
end;

function CopyWord(LongString: string; Index: integer): Str80;

begin
  CopyWord := '';

  if Index = 0 then Exit;

  Delete(LongString, 1, Index - 1);

  CopyWord := GetFirstString(LongString);
end;

procedure DecrementASCIIInteger(var ASCIIString: Str80);

var
  TempValue, Result                     : integer;

begin
  Val(ASCIIString, TempValue, Result);
  if Result <> 0 then
  begin
    ASCIIString := '';
    Exit;
  end;
  dec(TempValue);
  Str(TempValue, ASCIIString);
end;

procedure DelayOrKeyPressed(DelayTime: integer);

begin
  //{WLI}    WHILE DelayTime > 0 DO
  //{WLI}        BEGIN
  //{WLI}        IF KeyPressed THEN Exit;
  //{WLI}        Delay (1);
  //{WLI}        Dec (DelayTime);
  //{WLI}        END;
end;

function DeleteMult(var LogString: Str80; MultString: Str20): boolean;

var
  CharPointer, Position                 : integer;
  TempString                            : Str20;

begin
  DeleteMult := False;
  TempString := Copy(LogString, LogEntryMultAddress, LogEntryMultWidth);

  Position := pos(MultString, TempString);

  if (Position >= 1) and
    (Position < LogEntryMultWidth) then
  begin
    Position := Position + LogEntryMultAddress - 1;

    for CharPointer := Position to Position + length(MultString) - 1 do
      LogString[CharPointer] := ' ';

    DeleteMult := True;
    Exit;
  end;
end;

procedure MarkTime(var StartTime: Cardinal {TimeRecord});
begin
  StartTime := GetTickCount;
end;

function ElaspedTimeString(StartTime: Cardinal {TimeRecord}): PChar {Str20};

{ Returns a string in the format HH:MM:SS with how long it has been }

//var
//  Hours, Mins, Secs, TotalSeconds       : LONGINT;
//  HourString, MinsString, SecsString    : Str20;
begin
  Result := MillisecondsToFormattedString(GetTickCount - StartTime, False);
  {
    TotalSeconds := ElaspedSec100(StartTime) div 100;
     //   ElaspedTimeString := IntToStr(TotalSeconds);
     //   Exit;

    Hours := TotalSeconds div 3600;

    TotalSeconds := TotalSeconds - (Hours * 60);

    Mins := TotalSeconds div 60;

    TotalSeconds := TotalSeconds - (Mins * 60);

    Str(Hours, HourString);
    Str(Mins, MinsString);
    Str(TotalSeconds, SecsString);

    if length(SecsString) < 2 then SecsString := '0' + SecsString;
    if length(MinsString) < 2 then MinsString := '0' + MinsString;

    ElaspedTimeString := HourString + ':' + MinsString + ':' + SecsString;
  }
end;

function ElaspedSec100(StartTime: Cardinal {TimeRecord}): LONGINT;

//var
//  Hour, Minute, Second, Sec100          : word;
//  TempMinute, TempSecond, TempSec100    : LONGINT;

begin
  Result := (GetTickCount - StartTime) mod 1000;
end;

function ExpandedString(Input: FourBytes): Str80;

{ Returns the expanded string for the compressed integer passed to it. }

var
  TempBytes                             : TwoBytes;
  TempString                            : Str80;

begin
  TempBytes[1] := Input[1];
  TempBytes[2] := Input[2];
  TempString := ExpandTwoBytes(TempBytes);
  TempBytes[1] := Input[3];
  TempBytes[2] := Input[4];
  TempString := TempString + ExpandTwoBytes(TempBytes);
  while (TempString[1] = ' ') and (length(TempString) > 1) do Delete(TempString, 1, 1);
  ExpandedString := TempString;
end;

procedure ExpandTabs(var InputString: string);

var
  TabPos                                : integer;

begin
  TabPos := pos(TabKey, InputString);

  while TabPos > 0 do
  begin
    Delete(InputString, TabPos, 1);
    Insert(' ', InputString, TabPos);
    inc(TabPos);

    while TabPos mod 8 <> 0 do
    begin
      Insert(' ', InputString, TabPos);
      inc(TabPos);
    end;

    TabPos := pos(TabKey, InputString);
  end;
end;

//procedure BigCursor;

//{WLI} VAR Regs: REGISTERS;

//begin
 {    Regs.AH := $1;
     Regs.CH := $0;
     Regs.CL := $D;
     Intr ($10, Regs);
}
//end;

function SlipMessage(Message: string): string;

var
  CharPointer                           : integer;
  TempString                            : string;

begin
  TempString := '';

  if Message = '' then
  begin
    SlipMessage := '';
    Exit;
  end;

  for CharPointer := 1 to length(Message) do
  begin
    if Message[CharPointer] = CHR(FrameEnd) then
      TempString := Concat(TempString, CHR(FrameEscape), CHR(TransposedFrameEnd))
    else
      if Message[CharPointer] = CHR(FrameEscape) then
        TempString := Concat(TempString, CHR(FrameEscape), CHR(TransposedFrameEscape))
      else
        TempString := TempString + Message[CharPointer];
  end;

  SlipMessage := CHR(FrameEnd) + TempString + CHR(FrameEnd);
end;

function FirstLetter(InputString: Str80): Char;

var
  TempString                            : Str20;

begin
  TempString := Copy(InputString, 1, 1);

  if length(TempString) > 0 then
    FirstLetter := TempString[1]
  else
    FirstLetter := CHR(0);
end;

function LastLetter(InputString: Str160): Char;

var
  TempString                            : Str20;

begin
  TempString := Copy(InputString, length(InputString), 1);
  if length(TempString) > 0 then
    LastLetter := TempString[1]
  else
    LastLetter := CHR(0);
end;

procedure FormFeed;

begin
  //{WLI}     Write (Lst, Chr (12));
end;

function GetChecksum8(Call: FourBytes): integer;

var
  Sum                                   : integer;

begin
  Sum := Call[1] + Call[2] + Call[3] + Call[4];
  Sum := Sum and 7;
end;

function GetColorInteger(ColorString: Str80): tr4wColors;

begin
  ColorString := UpperCase(ColorString);
  if ColorString = 'BLACK' then GetColorInteger := trBlack;
  if ColorString = 'BLUE' then GetColorInteger := trBlue;
  if ColorString = 'GREEN' then GetColorInteger := trGreen;
  if ColorString = 'CYAN' then GetColorInteger := trCyan;
  if ColorString = 'RED' then GetColorInteger := trRed;
  if ColorString = 'MAGENTA' then GetColorInteger := trMagenta;
  if ColorString = 'BROWN' then GetColorInteger := trBrown;
  if ColorString = 'LIGHT GRAY' then GetColorInteger := trLightGray;
  if ColorString = 'DARK GRAY' then GetColorInteger := trDarkGray;
  if ColorString = 'LIGHT BLUE' then GetColorInteger := trLightBlue;
  if ColorString = 'LIGHT GREEN' then GetColorInteger := trLightGreen;
  if ColorString = 'LIGHT CYAN' then GetColorInteger := trLightCyan;
  if ColorString = 'LIGHT RED' then GetColorInteger := trLightRed;
  if ColorString = 'LIGHT MAGENTA' then GetColorInteger := trLightMagenta;
  if ColorString = 'YELLOW' then GetColorInteger := trYellow;
  if ColorString = 'WHITE' then GetColorInteger := trWhite;
  if ColorString = 'BTNFACE' then GetColorInteger := trBtnFace;
end;

function GetDateString: PChar;

{ This function goes off and reads the DOS clock and generates a nice
  looking ASCII string using the format 25-DEC-90.  It takes the Time
  Offset variable into account.

  If the HOUR OFFSET variable is non zero, the hours will get 24 added
  to it and then the HOUR OFFSET added.  This is done to keep the
  HOURS word variable from wrapping around to 65536 since there are no
  negative numbers for a WORD variable.  Thus a value greater than 47
  after adding the HOUR OFFSET indicates that a day must be added.  If
  the value is less than 24, then a day must be subtracted.
   }
var
//  TempString                            : PChar;
  Time                                  : TQSOTime;
begin

  tGetQSOSystemTime(Time);
  Result := tGetDateFormat(Time);
{
  tGetSystemTime;

  TempString := MonthTags[UTC.wMonth];

  UTC.wYear := UTC.wYear mod 100;
  asm
   mov ax,word ptr UTC.wYear
   movzx eax,ax
   push eax

   push TempString

   mov ax,word ptr UTC.wDay
   movzx eax,ax
   push eax
  end;
  wsprintf(GetDateStringBuffer, '%02u-%s-%02u');
  asm add esp,20
  end;

  RESULT := GetDateStringBuffer;
}
end;

function GetDayString: Str80;

{ This function will look at the DOS clock and generate a nice looking
    ASCII string showing the name of the day of the week (ie: Monday).  }

const
  DayTags                               : array[0..6] of string[9] = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');
begin
  tGetSystemTime;
  GetDayString := DayTags[UTC.wDayOfWeek];
end;
{
procedure GetFileNames(Path: Str80;
  Mask: Str80;
  var FileNames: FileNameRecord);

// This function will get files names for you until all of them have been
//  returned.  When this happens, you will get a null string as a result.

var
  DirInfo                     : TSearchRec;

begin
  FileNames.NumberFiles := 0;

  if (Path <> '') and (Path[length(Path)] <> '\') then
    Path := Path + '\';

  FindFirst(Path + Mask, faArchive, DirInfo);

  while (IORESULT  = 0) and (FileNames.NumberFiles < MaximumFileNames) do
  begin
    FileNames.List[FileNames.NumberFiles] := DirInfo.Name;
    inc(FileNames.NumberFiles);
    FindNext(DirInfo);
  end;
end;
}

function GetIntegerTime: integer;
{ This function will return the present time in N6TR integer format. }

begin
  tGetSystemTime;
  GetIntegerTime := UTC.wHour * 100 + UTC.wMinute;
end;

function GetLogEntryBand(LogEntry: Str160): BandType;

//var  TempString                            : string[3] {str80};

begin
  if length(LogEntry) < 4 then
  begin
    GetLogEntryBand := NoBand;
    Exit;
  end;

  //  TempString := Copy(LogEntry, 1, 3);
  Result := tGetBandFromString(Copy(LogEntry, 1, 3));
  {  if TempString = 'LGT' then
    begin
      GetLogEntryBand := BandLight;
      Exit;
    end;

    if TempString = '24G' then
    begin
      GetLogEntryBand := Band24G;
      Exit;
    end;
    if TempString = '10G' then
    begin
      GetLogEntryBand := Band10G;
      Exit;
    end;
    if TempString = '5GH' then
    begin
      GetLogEntryBand := Band5760;
      Exit;
    end;
    if TempString = '3GH' then
    begin
      GetLogEntryBand := Band3456;
      Exit;
    end;
    if TempString = '2GH' then
    begin
      GetLogEntryBand := Band2304;
      Exit;
    end;
    if TempString = '1GH' then
    begin
      GetLogEntryBand := Band1296;
      Exit;
    end;
    if TempString = '902' then
    begin
      GetLogEntryBand := Band902;
      Exit;
    end;
    if TempString = '432' then
    begin
      GetLogEntryBand := Band432;
      Exit;
    end;
    if TempString = '222' then
    begin
      GetLogEntryBand := Band222;
      Exit;
    end;

    if TempString = '  2' then
    begin
      GetLogEntryBand := Band2;
      Exit;
    end;
    if TempString = '  6' then
    begin
      GetLogEntryBand := Band6;
      Exit;
    end;
    if TempString = ' 10' then
    begin
      GetLogEntryBand := Band10;
      Exit;
    end;
    if TempString = ' 12' then
    begin
      GetLogEntryBand := Band12;
      Exit;
    end;
    if TempString = ' 15' then
    begin
      GetLogEntryBand := Band15;
      Exit;
    end;
    if TempString = ' 17' then
    begin
      GetLogEntryBand := Band17;
      Exit;
    end;
    if TempString = ' 20' then
    begin
      GetLogEntryBand := Band20;
      Exit;
    end;
    if TempString = ' 30' then
    begin
      GetLogEntryBand := Band30;
      Exit;
    end;
    if TempString = ' 40' then
    begin
      GetLogEntryBand := Band40;
      Exit;
    end;
    if TempString = ' 75' then
    begin
      GetLogEntryBand := Band80;
      Exit;
    end;
    if TempString = ' 80' then
    begin
      GetLogEntryBand := Band80;
      Exit;
    end;
    if TempString = '160' then
    begin
      GetLogEntryBand := Band160;
      Exit;
    end;
    GetLogEntryBand := NoBand;
  }
end;

function GetLogEntryCall(LogEntry: Str160): string;

var
  TempString                            : ShortString {Str80} {WLI};

begin
  TempString := Copy(LogEntry, LogEntryCallAddress, LogEntryCallWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetLogEntryCall := TempString;
end;

function GetLogEntryComputerID(LogEntry: Str160): Char;

var
  TempString                            : ShortString {Str20} {WLI};

begin
  TempString := Copy(LogEntry, LogEntryComputerIDAddress { + 1 wli}, LogEntryComputerIDWidth);

  GetRidOfPrecedingSpaces(TempString);

  if TempString = '' then
    TempString := Copy(LogEntry, LogEntryComputerIDAddress, LogEntryComputerIDWidth);

  if TempString = '' then
    GetLogEntryComputerID := CHR(0)
  else
    GetLogEntryComputerID := TempString[1];
end;

function GetLogEntryDateString(LogEntry: Str160): Str160;

begin
  GetLogEntryDateString := Copy(LogEntry, LogEntryDayAddress, 9);
end;

function GetLogEntryExchangeString(LogEntry: Str160): Str160;

var
  TempString                            : ShortString {Str80} {WLI};

begin
  TempString := Copy(LogEntry, LogEntryExchangeAddress, LogEntryExchangeWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetLogEntryExchangeString := TempString;
end;

function GetLogEntryHour(LogEntry: Str160): integer;

var
  HourString                            : Str80;
  Hour, Result1                         : integer;

begin
  HourString := Copy(LogEntry, LogEntryHourAddress, LogEntryHourWidth);
  Val(HourString, Hour, Result1);
  if Result1 = 0 then GetLogEntryHour := Hour else GetLogEntryHour := -1;
end;

function GetLogEntryMode(LogEntry: string {160}): ModeType;

var
  TempString                            : Str80;

begin
  TempString := Copy(LogEntry, LogEntryModeAddress, LogEntryModeWidth);

  if TempString = 'CW ' then
    GetLogEntryMode := CW
  else
    if TempString = 'DIG' then
      GetLogEntryMode := Digital
    else
      if (TempString = 'SSB') or (TempString = 'FM ') then
        GetLogEntryMode := Phone
      else
        GetLogEntryMode := NoMode;
end;

function GetLogEntryMultString(LogEntry: Str160): Str160;

var
  TempString                            : ShortString {Str80} {WLI};

begin
  TempString := Copy(LogEntry, LogEntryMultAddress, LogEntryMultWidth);
  GetRidOfPostcedingSpaces(TempString);
  GetRidOfPrecedingSpaces(TempString);
  GetLogEntryMultString := TempString;
end;

function GetLogEntryQSONumber(LogEntry: Str160): integer;

var
  TempString                            : ShortString {Str20} {WLI};
  QSONumber, Result1                    : integer;

begin
  TempString := Copy(LogEntry, LogEntryQSONumberAddress, LogEntryQSONumberWidth + 1);
  GetRidOfPrecedingSpaces(TempString);
  GetRidOfPrecedingSpaces(TempString);

  TempString := NumberPartOfString(TempString);

  Val(TempString, QSONumber, Result1);
  if Result1 = 0 then
    GetLogEntryQSONumber := QSONumber
  else
    GetLogEntryQSONumber := -1;
end;

function GetLogEntryQSOPoints(LogEntry: Str160): integer;

var
  TempString                            : ShortString {Str20} {WLI};
  Address, QSOPoints, Result1           : integer;

begin
  TempString := Copy(LogEntry, LogEntryPointsAddress, LogEntryPointsWidth);

  Address := LogEntryPointsAddress + LogEntryPointsWidth;

  while (Copy(LogEntry, Address, 1) >= '0') and (Copy(LogEntry, Address, 1) <= '9') do
  begin
    TempString := TempString + LogEntry[Address];
    inc(Address);
  end;

  GetRidOfPrecedingSpaces(TempString);

  if not StringIsAllNumbers(TempString) then
    GetLogEntryQSOPoints := 0
  else
  begin
    Val(TempString, QSOPoints, Result1);
    GetLogEntryQSOPoints := QSOPoints;
  end;
end;

function GetLogEntryRSTString(LogEntry: Str160): string;

var
  TempString                            : Str80;

begin
  TempString := Copy(LogEntry, LogEntryExchangeAddress, 4);
  GetLogEntryRSTString := NumberPartOfString(TempString);
end;

function tGetLogEntryRcvdRSTString(LogEntry: Str160): string;
var
  TempString                            : Str80;
begin
  TempString := Copy(LogEntry, LogEntryRcvdRSTAddress, 4);
  Result := NumberPartOfString(TempString);
end;

function GetLogEntryIntegerTime(LogEntry: Str160): integer;

var
  TempString                            : Str20;
  Time, Result1                         : integer;

begin
  TempString := Copy(LogEntry, LogEntryHourAddress, 5);
  Delete(TempString, 3, 1);

  Val(TempString, Time, Result1);

  if Result1 = 0 then
    GetLogEntryIntegerTime := Time
  else
    GetLogEntryIntegerTime := -1;
end;

function GetLogEntryTimeString(LogEntry: Str160): Str160;

begin
  GetLogEntryTimeString := Copy(LogEntry, LogEntryHourAddress, 5);
end;

function GetKey(Prompt: Str80): Char;
{WLI}
//VAR Key: CHAR;

begin
  {    GoToXY (1, WhereY);
      ClrEol;
      TextColor (Cyan);
      TextBackground (Black);
      Write (Prompt);
      REPEAT UNTIL KeyPressed;
      Key := ReadKey;
      TextColor (Yellow);
      IF Key >= ' ' THEN Write (Key);
      GetKey := Key;
 }
end;

function GetKeyResponse(Prompt: string): Char;

{ Looks for prompt to be in the form: prompt (A, B, Q, U, S, M) : and will
  accept only those keys listed. }

var
  Key                                   : Char;
  ListString                            : Str40;

begin
  ListString := UpperCase(BracketedString(Prompt, '(', ')')) + ',';

  repeat
    Key := UpCase(GetKey(Prompt));

    if (Key = EscapeKey) or StringHas(ListString, Key + ',') then
    begin
      GetKeyResponse := Key;
      WriteLn;
      Exit;
    end;
  until False;
end;

function GetResponse(Prompt: PChar {string}): ShortString;

//var
//  InputString                 : string;
//  Key                         : Char;
  {WLI}
begin
  //��������  inputquery('TR4W', Prompt, InputString);
  Result := QuickEditResponse(Prompt, 10);

  //   Result := InputString;
     {    TextColor (Cyan);
         TextBackground (Black);

         Write (Prompt);
         TextColor (Yellow);

         InputString := '';

         REPEAT
             REPEAT UNTIL KeyPressed;

             Key := ReadKey;

             IF Key = CarriageReturn THEN
                 BEGIN
                 GetResponse := InputString;
                 WriteLn;
                 Exit;
                 END;

             IF Key = BackSpace THEN
                 BEGIN
                 IF InputString <> '' THEN
                     BEGIN
                     GoToXY (WhereX - 1, WhereY);
                     Write (' ');
                     GoToXY (WhereX - 1, WhereY);
                     Delete (InputString, Length (InputString), 1);
                     END;
                 END
             ELSE
                 BEGIN
                 Write (Key);
                 InputString := InputString + Key;
                 END;

         UNTIL Length (InputString) > 250;
    }
end;

procedure GetRidOfCarriageReturnLineFeeds(var s: string);

begin
  while pos(CarriageReturn, s) > 0 do
    s[pos(CarriageReturn, s)] := ' ';

  while pos(LineFeed, s) > 0 do
    Delete(s, pos(LineFeed, s), 1);
end;

procedure GetRidOfPostcedingSpaces(var s: ShortString);

begin
  while length(s) > 0 do
    if (s[length(s)] = ' ') or (s[length(s)] = TabKey) then
      Delete(s, length(s), 1)
    else
      Exit;
end;

procedure GetRidOfPrecedingSpaces(var s: ShortString);

begin
  if s = '' then Exit;
  {wli ���� >0}
  while ((s[1] = ' ') or (s[1] = TabKey)) and (length(s) >= 2) do
    Delete(s, 1, 1);
end;

function GetSuffix(Call: CallString): CallString;

var
  TempString                            : Str20;
  CharPointer                           : integer;

begin
  CharPointer := length(Call);
  TempString := '';

  while (Call[CharPointer] >= 'A') and (CharPointer > 0) do
  begin
    TempString := Call[CharPointer] + TempString;
    dec(CharPointer);
  end;

  GetSuffix := TempString;
end;

function GetFullTimeString(WithMilliseconds: boolean): PChar;

{ This function will look at the DOS clock and generate a nice looking
  ASCII string showing the time using the format 23:42:32.  It will take
  the HourOffset variable into account. }

begin
  tGetSystemTime;
  // Issue #997: asm wsprintf -> uFreqTimeFormat.FormatFullTime (golden-tested,
  // proven byte-identical to the asm). Same UTC fields, same HH:MM:SS[:mmm].
  Result := uFreqTimeFormat.FormatFullTime(UTC.wHour, UTC.wMinute, UTC.wSecond,
              UTC.wMilliseconds, WithMilliseconds);
end;

function GetTimeString: PChar;
begin
  tGetSystemTime;
  Format(GetTimeStringBuffer, '%.2hu:%.2hu', UTC.wHour, UTC.wMinute);
  Result := GetTimeStringBuffer;
end;

function GetTimeString4Digit: PChar;
begin
  tGetSystemTime;
  Format(GetTimeStringBuffer, '%.2hu%.2hu', UTC.wHour, UTC.wMinute);
  Result := GetTimeStringBuffer;
end;

function GetTomorrowString: Str80;
{ This function will look at the DOS clock and generate a nice looking
  ASCII string showing the name of tomorrow (ie: Monday).  }
//const  DayTags                               : array[0..6] of string[9] = ('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday');

begin

end;

function GetReal(Prompt: PChar): REAL;

var
  TempValue                             : REAL;
  Result1                               : integer;
  TempString                            : Str80;

begin
  TempString := GetResponse(Prompt);
  Val(TempString, TempValue, Result1);

  if Result1 = 0 then
    GetReal := TempValue
  else
    GetReal := 0;
end;

function GetYearString: PChar;
begin
  tGetSystemTime;
{
  asm
  mov ax,word ptr UTC.wYear
  movzx eax,ax
  push eax
  end;
}
  Format(GetYearStringBuffer, '%u', UTC.wYear);

//  wsprintf(GetYearStringBuffer, '%u');
//  asm add esp,12  end;
  Result := GetYearStringBuffer;
end;

procedure HexToInteger(InputString: Str80; var OutputInteger: integer; var Result: integer);

var
  Multiplier                            : integer;

begin
  Result := 1;
  Multiplier := 1;
  OutputInteger := 0;
  if InputString = '' then Exit;

  Result := 0;

  while length(InputString) > 0 do
  begin
    case UpCase(InputString[length(InputString)]) of
      '0': OutputInteger := OutputInteger + Multiplier * 0;
      '1': OutputInteger := OutputInteger + Multiplier * 1;
      '2': OutputInteger := OutputInteger + Multiplier * 2;
      '3': OutputInteger := OutputInteger + Multiplier * 3;
      '4': OutputInteger := OutputInteger + Multiplier * 4;
      '5': OutputInteger := OutputInteger + Multiplier * 5;
      '6': OutputInteger := OutputInteger + Multiplier * 6;
      '7': OutputInteger := OutputInteger + Multiplier * 7;
      '8': OutputInteger := OutputInteger + Multiplier * 8;
      '9': OutputInteger := OutputInteger + Multiplier * 9;
      'A': OutputInteger := OutputInteger + Multiplier * 10;
      'B': OutputInteger := OutputInteger + Multiplier * 11;
      'C': OutputInteger := OutputInteger + Multiplier * 12;
      'D': OutputInteger := OutputInteger + Multiplier * 13;
      'E': OutputInteger := OutputInteger + Multiplier * 14;
      'F': OutputInteger := OutputInteger + Multiplier * 15;

    else
      begin
        Result := 1;
        Exit;
      end;
    end;

    Delete(InputString, length(InputString), 1);
    Multiplier := Multiplier * 16;
  end;

  Result := 0;
end;

procedure HexToWord(InputString: Str80; var OutputWord: Word; var Result: integer);

var
  Multiplier                            : Word;

begin
  Result := 1;
  Multiplier := 1;
  OutputWord := 0;
  if InputString = '' then Exit;

  Result := 0;

  while length(InputString) > 0 do
  begin
    case UpCase(InputString[length(InputString)]) of
      '0': OutputWord := OutputWord + Multiplier * 0;
      '1': OutputWord := OutputWord + Multiplier * 1;
      '2': OutputWord := OutputWord + Multiplier * 2;
      '3': OutputWord := OutputWord + Multiplier * 3;
      '4': OutputWord := OutputWord + Multiplier * 4;
      '5': OutputWord := OutputWord + Multiplier * 5;
      '6': OutputWord := OutputWord + Multiplier * 6;
      '7': OutputWord := OutputWord + Multiplier * 7;
      '8': OutputWord := OutputWord + Multiplier * 8;
      '9': OutputWord := OutputWord + Multiplier * 9;
      'A': OutputWord := OutputWord + Multiplier * 10;
      'B': OutputWord := OutputWord + Multiplier * 11;
      'C': OutputWord := OutputWord + Multiplier * 12;
      'D': OutputWord := OutputWord + Multiplier * 13;
      'E': OutputWord := OutputWord + Multiplier * 14;
      'F': OutputWord := OutputWord + Multiplier * 15;

    else
      begin
        Result := 1;
        Exit;
      end;
    end;

    Delete(InputString, length(InputString), 1);
    Multiplier := Multiplier * 16;
  end;

  Result := 0;
end;

procedure HexToLongInteger(InputString: Str80; var OutputInteger: LONGINT; var Result: integer);

var
  Multiplier                            : LONGINT;

begin
  Result := 1;
  Multiplier := 1;
  OutputInteger := 0;
  if InputString = '' then Exit;

  Result := 0;

  while length(InputString) > 0 do
  begin
    case UpCase(InputString[length(InputString)]) of
      '0': OutputInteger := OutputInteger + Multiplier * 0;
      '1': OutputInteger := OutputInteger + Multiplier * 1;
      '2': OutputInteger := OutputInteger + Multiplier * 2;
      '3': OutputInteger := OutputInteger + Multiplier * 3;
      '4': OutputInteger := OutputInteger + Multiplier * 4;
      '5': OutputInteger := OutputInteger + Multiplier * 5;
      '6': OutputInteger := OutputInteger + Multiplier * 6;
      '7': OutputInteger := OutputInteger + Multiplier * 7;
      '8': OutputInteger := OutputInteger + Multiplier * 8;
      '9': OutputInteger := OutputInteger + Multiplier * 9;
      'A': OutputInteger := OutputInteger + Multiplier * 10;
      'B': OutputInteger := OutputInteger + Multiplier * 11;
      'C': OutputInteger := OutputInteger + Multiplier * 12;
      'D': OutputInteger := OutputInteger + Multiplier * 13;
      'E': OutputInteger := OutputInteger + Multiplier * 14;
      'F': OutputInteger := OutputInteger + Multiplier * 15;

    else
      begin
        Result := 1;
        Exit;
      end;
    end;

    Delete(InputString, length(InputString), 1);
    Multiplier := Multiplier * 16;
  end;

  Result := 0;
end;

procedure IncrementASCIIInteger(var ASCIIString: Str80);

var
  TempValue, Result                     : integer;

begin
  Val(ASCIIString, TempValue, Result);
  if Result <> 0 then
  begin
    ASCIIString := '';
    Exit;
  end;
  inc(TempValue);
  Str(TempValue, ASCIIString);
end;

function KeyId(Key: Char): Str10;

begin
  case Key of
    {
        F1: KeyId := 'F1';
        F2: KeyId := 'F2';
        F3: KeyId := 'F3';
        F4: KeyId := 'F4';
        F5: KeyId := 'F5';
        F6: KeyId := 'F6';
        F7: KeyId := 'F7';
        F8: KeyId := 'F8';
        F9: KeyId := 'F9';
        F10: KeyId := 'F10';
        F11: KeyId := 'F11';
        F12: KeyId := 'F12';
    }
    F1..F12: KeyId := 'F' + IntToStr(Ord(Key) - 111);

    {
        AltF1: KeyId := 'AltF1';
        AltF2: KeyId := 'AltF2';
        AltF3: KeyId := 'AltF3';
        AltF4: KeyId := 'AltF4';
        AltF5: KeyId := 'AltF5';
        AltF6: KeyId := 'AltF6';
        AltF7: KeyId := 'AltF7';
        AltF8: KeyId := 'AltF8';
        AltF9: KeyId := 'AltF9';
        AltF10: KeyId := 'AltF10';
        AltF11: KeyId := 'AltF11';
        AltF12: KeyId := 'AltF12';
    }
    AltF1..AltF12: KeyId := 'AltF' + IntToStr(Ord(Key) - 135);
    {
        ControlF1: KeyId := 'ControlF1';
        ControlF2: KeyId := 'ControlF2';
        ControlF3: KeyId := 'ControlF3';
        ControlF4: KeyId := 'ControlF4';
        ControlF5: KeyId := 'ControlF5';
        ControlF6: KeyId := 'ControlF6';
        ControlF7: KeyId := 'ControlF7';
        ControlF8: KeyId := 'ControlF8';
        ControlF9: KeyId := 'ControlF9';
        ControlF10: KeyId := 'ControlF10';
        ControlF11: KeyId := 'ControlF11';
        ControlF12: KeyId := 'ControlF12';
    }

    ControlF1..ControlF12: KeyId := 'ControlF' + IntToStr(Ord(Key) - 123);

  else KeyId := '';
  end;

end;

procedure DisplayLineInputString(Str: Str160; Cursor: integer; EndOfPrompt: integer);


begin
  //{WLI}

end;
{
function ControlKeyPressed: boolean;

begin
      ControlKeyPressed := (Mem [$40:$17] AND 4) <> 0;
end;
}

function LastString(InputString: ShortString {Str160} {WLI}): Str160;

var
  CharPointer                           : integer;

begin
  LastString := '';
  if InputString = '' then Exit;

  GetRidOfPostcedingSpaces(InputString);

  for CharPointer := length(InputString) downto 1 do
    if (InputString[CharPointer] = ' ') or
      (InputString[CharPointer] = ControlI) then
    begin
      LastString := Copy(InputString, CharPointer + 1, length(InputString) - CharPointer);
      Exit;
    end;

  LastString := InputString;
end;


{PROCEDURE}

function InitializeSerialPort(
  SerialPort: PortType;
  BaudRate: Cardinal;
  Bits: Byte;
  Parity: ParityType;
  StopBits: Byte;
  dwFlagsAndAttributes: DWORD;
  EvtChar: Char): HWND;
var
  DCB                                   : TDCB;
  CommTimeouts                          : TCommTimeouts;
  com_port_name                         : Byte;
  Parity_byte                           : Byte;
  WinAPIstopBits                        : Byte;
begin
  Result := INVALID_HANDLE_VALUE;
  if tGetPortType(SerialPort) = SerialInterface then
    com_port_name := Ord(SerialPort)
  else
    Exit;
  Result := TryToOpenCOMPort(com_port_name, dwFlagsAndAttributes);
  if Result = INVALID_HANDLE_VALUE then
  begin
    Format(wsprintfBuffer, 'COM%d:'#13'%s', com_port_name, SysErrorMessage(GetLastError));
    showwarning(wsprintfBuffer);
    Exit;
  end;

  if not SetupComm(Result, 512, 512) then
  begin
    //showwarning('SetupComm');
    Exit;
  end;

  {-------DCB--------}
  if not GetCommState(Result, DCB) then
  begin
    Result := INVALID_HANDLE_VALUE;
    Exit;

  end;
  if Parity = tNoParity then Parity_byte := 0;
  if Parity = EvenParity then Parity_byte := 1;
  if Parity = OddParity then Parity_byte := 2;

  DCB.Parity := Parity_byte;
  DCB.BaudRate := BaudRate;
  DCB.ByteSize := Bits;
  DCB.EvtChar := EvtChar;

  WinAPIstopBits := ONESTOPBIT;
  if StopBits = 2 then WinAPIstopBits := TWOSTOPBITS;

  DCB.StopBits := WinAPIstopBits;
  DCB.Flags := dcb_Binary or dcb_DtrControlEnable or dcb_RtsControlEnable;

  if not SetCommState(Result, DCB) then
  begin
    Result := INVALID_HANDLE_VALUE;
    Exit;

  end;
  {-------DCB--------}

  TREscapeCommFunction(Result, CLRDTR); //CW
  TREscapeCommFunction(Result, CLRRTS); //PTT

  Windows.ZeroMemory(@CommTimeouts, SizeOf(CommTimeouts));

  if not SetCommTimeouts(Result, CommTimeouts) then Exit;
  CPUKeyer.SerialPortConfigured_Handle[SerialPort] := Result;

end;

function LineInput(Prompt: Str160;
  InitialString: Str160;
  OverwriteEnable: boolean;
  ExitOnAltKey: boolean): Str160;

{ This function will display the prompt and allow the operator to input
  a response to the prompt.  If an InitialString is passed along, it will
  be displayed as the initial entry value.  It can be edited, or written
  over as desired.  An escape with no entry will give a result of escape
  key.  If the input or initial entry goes beyond the right of the window,
  it will be handled nicely I hope. }

begin
  //{WLI}
  {    ClrScr;
      Write (Prompt);
      EndOfPrompt := WhereX;
      CursorPosition := Length (InitialString) + 1;

      DisplayLineInputString (InitialString, CursorPosition, EndOfPrompt);

      InputString := InitialString;
      InsertMode := True;
      VirginEntry := OverWriteEnable;

      REPEAT
          REPEAT UNTIL KeyPressed;
          Key := ReadKey;

          CASE Key OF
              EscapeKey:
                  BEGIN
                  IF InputString = '' THEN
                      BEGIN
                      LineInput := EscapeKey;
                      Exit;
                      END;

                  InputString := '';
                  CursorPosition := 1;
                  VirginEntry := False;
                  END;

              BackSpace:
                  BEGIN
                  IF CursorPosition > 1 THEN
                      BEGIN
                      Delete (InputString, CursorPosition - 1, 1);
                      Dec (CursorPosition);
                      END;
                  VirginEntry := False;
                  END;

              ControlA:
                  IF CursorPosition > 1 THEN
                      BEGIN
                      REPEAT
                          Dec (CursorPosition);
                      UNTIL (CursorPosition = 1) OR
                            ((InputString [CursorPosition - 1] = ' ') AND
                             (InputString [CursorPosition] <> ' '));
                      VirginEntry := False;
                      END;

              ControlS:
                  IF CursorPosition > 1 THEN
                      BEGIN
                      Dec (CursorPosition);
                      VirginEntry := False;
                      END;

              ControlD:
                  IF CursorPosition < (Length (InputString) + 1) THEN
                      BEGIN
                      Inc (CursorPosition);
                      VirginEntry := False;
                      END;

              ControlF:
                  IF CursorPosition < (Length (InputString) + 1) THEN
                      BEGIN
                      REPEAT
                          Inc (CursorPosition);
                      UNTIL (CursorPosition = Length (InputString) + 1) OR
                            ((InputString [CursorPosition - 1] = ' ') AND
                             (InputString [CursorPosition] <> ' '));
                      VirginEntry := False;
                      END;

              ControlG:
                  IF CursorPosition < Length (InputString) + 1 THEN
                      BEGIN
                      Delete (InputString, CursorPosition, 1);
                      VirginEntry := False;
                      END;

  

              ControlP:
                  BEGIN
                  REPEAT UNTIL KeyPressed;
                  Key := ReadKey;

                  IF VirginEntry THEN
                      BEGIN
                      InputString := Key;
                      VirginEntry := False;
                      CursorPosition := 2;
                      END
                  ELSE
                      BEGIN
                      IF InsertMode THEN
                          Insert (Key, InputString, CursorPosition)
                      ELSE
                          InputString [CursorPosition] := Key;
                      Inc (CursorPosition);
                      END;
                  END;

              ControlT:
                  BEGIN
                  TempString := Copy (InputString, CursorPosition, 200);
                  Delete (InputString, CursorPosition, 200);
                  TempString := StringWithFirstWordDeleted (TempString);
                  InputString := InputString + TempString;
                  VirginEntry := False;
                  END;

              ControlY:
                  BEGIN
                  InputString := '';
                  VirginEntry := False;
                  END;

              NullKey:
                  BEGIN
                  VirginEntry := False;
                  Key := ReadKey;

                  CASE Key OF
                      HomeKey: CursorPosition := 1;

                      LeftArrow:
                          IF CursorPosition > 1 THEN
                              Dec (CursorPosition);

                      RightArrow:
                          IF CursorPosition < Length (InputString) + 1 THEN
                              Inc (CursorPosition);

                      EndKey:
                          CursorPosition := Length (InputString) + 1;

                      InsertKey: InsertMode := NOT InsertMode;

                      DeleteKey:
                          IF CursorPosition <= Length (InputString) THEN
                              Delete (InputString, CursorPosition, 1);

                      ELSE
                          IF ExitOnAltKey THEN
                              BEGIN
                              LineInput := NullKey + Key;
                              Exit;
                              END;
                      END;

                  END

  

              ELSE
                  IF Key >= ' ' THEN
                      BEGIN
                      IF VirginEntry THEN
                          BEGIN
                          InputString := Key;
                          VirginEntry := False;
                          CursorPosition := 2;
                          END
                      ELSE
                          BEGIN
                          IF InsertMode THEN
                              Insert (Key, InputString, CursorPosition)
                          ELSE
                              InputString [CursorPosition] := Key;
                          Inc (CursorPosition);
                          END;
                      END
                  ELSE
                      IF Key = CarriageReturn THEN
                          BEGIN
                          LineInput := InputString;
                          Exit;
                          END;

              END;

      DisplayLineInputString (InputString, CursorPosition, EndOfPrompt);
      UNTIL False;
 }
end;


function LooksLikeAPOTAPark(park: string): boolean;
begin
   Result := IsValidPOTAPark(park);
end;

function LooksLikeAGrid(var GridString: ShortString): boolean;

{ If it does look like a grid, it will make the first two letters lower
  case so it looks like a domestic QTH. }

var
  TestString                            : Str20;
  i                                     : integer;
 // p                                  : pchar;
begin

  LooksLikeAGrid := False;

  TestString := UpperCase(GridString);
  if ((ActiveExchange = RSTAndOrGridExchange) or        // 4.118.1
      (ActiveExchange = Grid2Exchange) or
      (ActiveExchange = RSTAndGrid3Exchange) or
      (ActiveExchange = GridExchange) or
      (ActiveExchange = RSTQSONumberAndGridSquareExchange) or
      (ActiveExchange = GridExchange)  or
      (ActiveExchange = RSTNameAndQTHExchange) or // ny4i - Added for GeneralQSo to check if there is a grid in the exchange
      (ActiveExchange = RSTAndPOTAPark) or        // ny4i Added so free-form POTA exchange can find a grid.
      (ActiveExchange = RSTAndGridExchange)) then

     begin
     if (length(TestString) <> 4) and (length(TestString) <> 6) then
        begin
        Exit;
        end;
  //   if (TestString[1] < 'A') or (TestString[1] > 'R') then Exit;
  //   if (TestString[2] < 'A') or (TestString[2] > 'R') then Exit;
     for i := 1 to 2 do
        begin
        if (TestString[i] < 'A') or (TestString[i] > 'R') then
           begin
           Exit;
           end;
        end;
  //if (TestString[3] < '0') or (TestString[3] > '9') then Exit;
  //if (TestString[4] < '0') or (TestString[4] > '9') then Exit;
     for i := 3 to 4 do
        begin
        if (TestString[i] < '0') or (TestString[i] > '9') then
           begin
           Exit;
           end;
        end;
  //   if GridString[1] > 'Z' then GridString[1] := CHR(Ord(GridString[1]) - Ord('a') + Ord('A'));
  //   if GridString[2] > 'Z' then GridString[2] := CHR(Ord(GridString[2]) - Ord('a') + Ord('A'));
     for i := 1 to 2 do
        begin
        if GridString[i] > 'Z' then
           begin
           GridString[i] := CHR(Ord(GridString[i]) - Ord('a') + Ord('A'));
           end;
        end;
     LooksLikeAGrid := True;
     end
  else
     begin
     logger.debug('Exiting LooksLikeAGrid because ActiveExchange not related to a grid');
     end;
end;


function LooksLikeAGridIgnoreAE(var GridString: ShortString): boolean;

{ If it does look like a grid, it will make the first two letters lower
  case so it looks like a domestic QTH. }

var
  TestString                            : Str20;
  i                                     : integer;
  //p                                  : pchar;
begin

  LooksLikeAGridIgnoreAE := False;

  TestString := UpperCase(GridString);
  if (length(TestString) <> 4) and (length(TestString) <> 6) then
     begin
     Exit;
     end;

  for i := 1 to 2 do
     begin
     if (TestString[i] < 'A') or (TestString[i] > 'R') then
        begin
        Exit;
        end;
     end;

  for i := 3 to 4 do
     begin
     if (TestString[i] < '0') or (TestString[i] > '9') then
        begin
        Exit;
        end;
     end;

  for i := 1 to 2 do
     begin
     if GridString[i] > 'Z' then
        begin
        GridString[i] := CHR(Ord(GridString[i]) - Ord('a') + Ord('A'));
        end;
     end;

  LooksLikeAGridIgnoreAE := True;

end;


function LowerCase(const s: string): string;
var
  ch                                    : Char;
  l                                     : integer;
  Source, Dest                          : PChar;
begin
  l := length(s);
  SetLength(Result, l);
  Source := Pointer(s);
  Dest := Pointer(Result);
  while l <> 0 do
  begin
    ch := Source^;
    if ch in ['A'..'Z'] then inc(ch, 32);
    Dest^ := ch;
    inc(Source);
    inc(Dest);
    dec(l);
  end;

end;

function Lpt1BaseAddress: Word;

begin
  //{WLI}
  {    Address := MemW [ $40:8 ];

      IF Address = 0 THEN
          Lpt1BaseAddress := $3BC
      ELSE
          Lpt1BaseAddress := Address;
 }
end;

function Lpt2BaseAddress: Word;



begin
  {    Address := MemW [ $40:$A ];

      IF Address = 0 THEN
          Lpt2BaseAddress := $278
      ELSE
          Lpt2BaseAddress := Address;
 }
end;

function Lpt3BaseAddress: Word;


begin
  {    Address := MemW [ $40:$C ];

      IF Address = 0 THEN
          Lpt3BaseAddress := $378
      ELSE
          Lpt3BaseAddress := Address;
 }
end;

function MakeDupeFilename(Band: BandType; Mode: ModeType): Str80;

{ This procedure will generate the duping filename for the band and mode
    specified.                                                                }

begin
  MakeDupeFilename := 'L' + ModeStringArray[Mode] + BandStringsArray[Band];
end;

function MakeTitle(Band: BandType; Mode: ModeType; Contest: Str80; CallUsed: Str80): Str80;

begin
  MakeTitle := Contest + '   ' + CallUsed + '   ' + BandStringsArray[Band] + ' ' + ModeStringArray[Mode];
end;

function MicroTimeElapsed(StartTime: Cardinal {TimeRecord}): LONGINT;
{ Gives answer in Sec100s }
begin
  Result := GetTickCount - StartTime;
end;

function MinutesToTimeString(Minutes: integer): Str20;
var
  Hours                                 : integer;
  HourString, MinuteString              : Str20;
begin
  Hours := Minutes div 60;
  Minutes := Minutes mod 60;
  Str(Hours, HourString);
  Str(Minutes, MinuteString);
  while length(MinuteString) < 2 do MinuteString := '0' + MinuteString;
  MinutesToTimeString := HourString + ':' + MinuteString;
end;

function MultiMessageSourceBand(Source: Byte): BandType;

begin
  case Source of
    $E0: MultiMessageSourceBand := Band160;
    $E1: MultiMessageSourceBand := Band80;
    $E2: MultiMessageSourceBand := Band40;
    $E3: MultiMessageSourceBand := Band20;
    $E4: MultiMessageSourceBand := Band15;
    $E5: MultiMessageSourceBand := Band10;

    $E6: MultiMessageSourceBand := Band30;
    $E7: MultiMessageSourceBand := Band17;
    $E8: MultiMessageSourceBand := Band12;
    $E9: MultiMessageSourceBand := Band6;
    $EA: MultiMessageSourceBand := Band2;
    $EB: MultiMessageSourceBand := Band222;
    $EC: MultiMessageSourceBand := Band432;

    $ED: MultiMessageSourceBand := Band902;
    $EE: MultiMessageSourceBand := Band1296;
    $EF: MultiMessageSourceBand := Band2304;
    $F0: MultiMessageSourceBand := Band3456;
    $F1: MultiMessageSourceBand := Band5760;
    $F2: MultiMessageSourceBand := Band10G;
    $F3: MultiMessageSourceBand := Band24G;
    $F4: MultiMessageSourceBand := BandLight;

  else
    MultiMessageSourceBand := NoBand;
  end;
end;

//procedure NoCursor;

//{WLI}VAR Regs: REGISTERS;

//begin
 {    Regs.AH := $1;
     Regs.CH := $10;
     Regs.CL := $00;
     Intr ($10, Regs);
}
//end;

function NumberPartOfString(InputString: Str160): Str80;

var
  TempString                            : Str80;
  CharPointer                           : integer;

begin
  if InputString = '' then
  begin
    NumberPartOfString := '';
    Exit;
  end;
  TempString := '';
  for CharPointer := 1 to length(InputString) do
    if (InputString[CharPointer] >= '0') and (InputString[CharPointer] <= '9') then
      TempString := TempString + InputString[CharPointer];
  NumberPartOfString := TempString;
end;

function OkayToDeleteExistingFile(FileName: PChar): boolean;
begin
  Format(wsprintfBuffer, TC_ALREADYEXISTSOKAYTODELETE, FileName);
  Result := MessageBox(0, wsprintfBuffer, tr4w_ClassName, MB_YESNO or MB_ICONWARNING) = IDYES;
end;

function OkayToProceed: boolean;



begin
  {    OkayToProceed := False;

      REPEAT
          Key := UpCase (GetKey ('Okay to proceed? (Y/N): '));
      UNTIL (Key = 'N') OR (Key = EscapeKey) OR (Key = 'Y');

      GoToXY (1, WhereY);
      ClrEol;

      OkayToProceed := Key = 'Y';
      TextColor (Cyan);
 }
end;

function OpenDupeFileForRead(var FileHandle: Text; FileName: Str80): boolean;

{ This function will open a duping file and make it ready to read in.  If
    the file does not exist or does not appear to be a duping file, it will
    return FALSE.  If it does exist, the next line to be read will be the
    title.                                                                  }



begin
//  OpenDupeFileForRead := False;
//  if not OpenFileForRead(FileHandle, FileName) then Exit;
//  ReadLn(FileHandle, TempString);
//  OpenDupeFileForRead := TempString = 'DUPE';
end;

function OpenFileForAppend(var FileHandle: Text; FileName: string): boolean;

{ This function will open the filename indicated for append.  If the file
    does not exist, it is opened for write.  At this time, the function
    always returns TRUE (must of been lazy the day I wrote it).                 }

//var  find_data                             : WIN32_FIND_DATA;
begin
  OpenFileForAppend := True;

  //  if FindFirst(FileName, faArchive, DirInfo) = 0 then
//  if Windows.FindFirstFile(PChar(FileName), find_data) <> INVALID_HANDLE_VALUE then
     //    IF IORESULT{DosError}{WLI} = 0 THEN { FileExists }
  if FileExists(@FileName[1]) then
  begin

    Assign(FileHandle, FileName);
    Append(FileHandle);
  end
  else
  begin
    Assign(FileHandle, FileName);
    ReWrite(FileHandle);
  end;
end;

function OpenFileForRead_old(var FileHandle: Text; FileName: string {Str80}): boolean;
begin
  Assign(FileHandle, FileName);
{$I-}
  Reset(FileHandle);
{$I+}
  Result := IORESULT = 0;
end;

function OperatorEscape: boolean;

begin
  {    OperatorEscape := False;

      IF KeyPressed THEN
          BEGIN
          Key := ReadKey;
          IF Key = EscapeKey THEN
              BEGIN
              OperatorEscape := True;
              Exit;
              END
          ELSE
              IF Key = NullKey THEN
                  Key := ReadKey;
          END;
 }
end;

function PortableStation(Call: CallString): boolean;

{ This function will return TRUE if the callsign passed to it is a portable
  station. }

var
  TempString                            : Str20;
  TempChar                              : Char;

begin
  PortableStation := False;
  TempString := PostcedingString(Call, '/');

  if StringHas(TempString, '/') then
    TempString := PostcedingString(TempString, '/');

  if length(TempString) = 1 then
  begin
    TempChar := TempString[1];
    if ((TempChar >= '0') and (TempChar <= '9')) or (TempChar = 'P') or (TempChar = 'M') then
      PortableStation := True;
  end;
end;

function ReadChar(SerialPort: PortType): Char;

{ This funtion will get the char that is waiting in the UART }


  //{WLI}    Regs: REGISTERS;

begin
  {    REPEAT UNTIL CharReady (SerialPort);

      IF UseBIOSCOMIO THEN
          BEGIN
          Regs.AH := 2;       // Read character

          CASE SerialPort OF
              Serial1: Regs.DX := 0;
              Serial2: Regs.DX := 1;
              Serial3: Regs.DX := 2;
              Serial4: Regs.DX := 3;
              ELSE
                  BEGIN
                  ReadChar := Chr (0);
                  Exit;
                  END;
              END;

          Intr ($14, Regs);

          ReadChar := Chr (Regs.AL);
          END

      ELSE
          BEGIN
          PortAddress := 0;

          CASE SerialPort OF
              Serial1: PortAddress := Com1PortBaseAddress;
              Serial2: PortAddress := Com2PortBaseAddress;
              Serial3: PortAddress := Com3PortBaseAddress;
              Serial4: PortAddress := Com4PortBaseAddress;
              Serial5: PortAddress := Com5PortBaseAddress;
              Serial6: PortAddress := Com6PortBaseAddress;
              END;

          IF PortAddress <> 0 THEN
              ReadChar := Chr (Port [PortAddress])
          ELSE
              ReadChar := Chr (0);
          END;
 }
end;

function RemoveBand(var LongString: ShortString): BandType;

var
  TempByte                              : Byte;
  Band                                  : BandType;

begin
  TempByte := Ord(LongString[1]);
  Move(TempByte, Band, 1);
  RemoveBand := Band;
  Delete(LongString, 1, 1);
end;

function RemoveMode(var LongString: ShortString): ModeType;

var
  TempByte                              : Byte;
  Mode                                  : ModeType;

begin
  TempByte := Ord(LongString[1]);
  Move(TempByte, Mode, 1);
  RemoveMode := Mode;
  Delete(LongString, 1, 1);
end;

function RemoveFirstChar(var LongString: string): Char;


begin
  while (LongString <> '') and ((Copy(LongString, 1, 1) = ' ') or (Copy(LongString, 1, 1) = TabKey)) do
    Delete(LongString, 1, 1);

  if LongString = '' then
  begin
    RemoveFirstChar := NullCharacter;
    Exit;
  end;

  RemoveFirstChar := LongString[1];
  Delete(LongString, 1, 1);

  while (LongString <> '') and ((Copy(LongString, 1, 1) = ' ') or (Copy(LongString, 1, 1) = TabKey)) do
    Delete(LongString, 1, 1);
end;

function RemoveFirstLongInteger(var LongString: ShortString): LONGINT;

var
  IntegerString                         : Str80;
  Number                                : LONGINT;
  Result1                               : integer;

begin
  IntegerString := RemoveFirstString(LongString);
  Val(IntegerString, Number, Result1);
  if Result1 = 0 then
    RemoveFirstLongInteger := Number
  else
    RemoveFirstLongInteger := 0;
end;

function RemoveFirstReal(var LongString: ShortString): REAL;

var
  Result1                               : integer;
  TempString                            : Str80;
  TempReal                              : REAL;

begin
  TempString := RemoveFirstString(LongString);

  Val(TempString, TempReal, Result1);

  if Result1 = 0 then
    RemoveFirstReal := TempReal
  else
    RemoveFirstReal := 0;
end;

function GetFirstString(LongString: string): Str80;

var
  CharCount                             : integer;
  FirstWordFound                        : boolean;
  FirstWordCursor                       : integer;

begin
  if LongString = '' then
  begin
    GetFirstString := '';
    Exit;
  end;

  FirstWordFound := False;

  for CharCount := 1 to length(LongString) do
    if FirstWordFound then
    begin
      if (LongString[CharCount] = ' ') or (LongString[CharCount] = TabKey) then
      begin
        GetFirstString := Copy(LongString, FirstWordCursor, CharCount - FirstWordCursor);
        Exit;
      end;
    end
    else
      if (LongString[CharCount] <> ' ') and (LongString[CharCount] <> TabKey) then
      begin
        FirstWordFound := True;
        FirstWordCursor := CharCount;
      end;

  if FirstWordFound then
    GetFirstString := Copy(LongString, FirstWordCursor, length(LongString) - FirstWordCursor + 1)
  else
    GetFirstString := '';
end;

function RemoveFirstString(var LongString: ShortString): Str80;

var
  CharCount                             : integer;
  FirstWordFound                        : boolean;
  FirstWordCursor                       : integer;

begin

  if LongString = '' then
  begin
    RemoveFirstString := '';
    Exit;
  end;

  for CharCount := 1 to length(LongString) do
    if (LongString[CharCount] = CarriageReturn) or
      (LongString[CharCount] = LineFeed) then
      LongString[CharCount] := ' ';

  FirstWordFound := False;

  for CharCount := 1 to length(LongString) do
    if FirstWordFound then
    begin
      if (LongString[CharCount] = ' ') or (LongString[CharCount] = TabKey) then
      begin
        RemoveFirstString := Copy(LongString, FirstWordCursor, CharCount - FirstWordCursor);
        Delete(LongString, 1, CharCount);
        Exit;
      end;
    end
    else
      if (LongString[CharCount] <> ' ') and (LongString[CharCount] <> TabKey) then
      begin
        FirstWordFound := True;
        FirstWordCursor := CharCount;
      end;

  if FirstWordFound then
    RemoveFirstString := Copy(LongString, FirstWordCursor, length(LongString) - FirstWordCursor + 1)
  else
    RemoveFirstString := '';

  LongString := '';
end;

function RemoveLastString(var LongString: ShortString): Str80;
var
  CharPos                               : integer;
begin
  if length(LongString) > 0 then
  begin
    GetRidOfPostcedingSpaces(LongString);
    for CharPos := length(LongString) downto 1 do
      if (LongString[CharPos] = ' ') or (LongString[CharPos] = TabKey) then
      begin
        RemoveLastString := Copy(LongString, CharPos + 1, length(LongString) - CharPos);
        Delete(LongString, CharPos, length(LongString) - CharPos + 1);
        Exit;
      end;

    RemoveLastString := LongString;
    LongString := '';
  end
  else
    RemoveLastString := '';
end;

function GetLastString(LongString: ShortString): Str80;

var
  CharPos                               : integer;

begin
  if length(LongString) > 0 then
  begin
    GetRidOfPostcedingSpaces(LongString);
    for CharPos := length(LongString) downto 1 do
      if (LongString[CharPos] = ' ') or (LongString[CharPos] = TabKey) then
      begin
        GetLastString := Copy(LongString, CharPos + 1, length(LongString) - CharPos);
        Exit;
      end;

    GetLastString := LongString;
  end
  else
    GetLastString := '';
end;

procedure SendByte(SerialPort: PortType; ByteToSend: Byte);

{ This procedure will send a byte to the serial port. }

begin
  SendChar(SerialPort, CHR(ByteToSend));
end;

procedure PacketSendChar(SerialPort: PortType; CharToSend: Char);


  //{WLI}    Regs: REGISTERS;

begin
  {    PortAddress := 0;

      CASE SerialPort OF
          Serial1: PortAddress := Com1PortBaseAddress;
          Serial2: PortAddress := Com2PortBaseAddress;
          Serial3: PortAddress := Com3PortBaseAddress;
          Serial4: PortAddress := Com4PortBaseAddress;
          Serial5: PortAddress := Com5PortBaseAddress;
          Serial6: PortAddress := Com6PortBaseAddress;

          DRSI: BEGIN
                Regs.AH := 1;
                Regs.AL := Ord (CharToSend);
                Intr ($FF, Regs);
                Exit;
                END;
          END;

      IF PortAddress = 0 THEN Exit;

  //    REPEAT UNTIL (Port [PortAddress + 5] AND $20) = $20;

      Port [PortAddress] := Ord (CharToSend);
 }
end;

procedure SendChar(SerialPort: PortType; CharToSend: Char);


  //{WLI}    Regs: REGISTERS;

begin
  {    IF UseBIOSCOMIO THEN
          BEGIN
          Regs.AH := 1;           // Function 01h
          Regs.AL := Ord (CharToSend);  // Data to send

          CASE SerialPort OF
              Serial1: Regs.DX := 0;
              Serial2: Regs.DX := 1;
              Serial3: Regs.DX := 2;
              Serial4: Regs.DX := 3;
              ELSE Exit;
              END;

          Intr ($14, Regs);
          END

      ELSE
          BEGIN
          PortAddress := 0;

          CASE SerialPort OF
              Serial1: PortAddress := Com1PortBaseAddress;
              Serial2: PortAddress := Com2PortBaseAddress;
              Serial3: PortAddress := Com3PortBaseAddress;
              Serial4: PortAddress := Com4PortBaseAddress;
              Serial5: PortAddress := Com5PortBaseAddress;
              Serial6: PortAddress := Com6PortBaseAddress;
              END;

          IF PortAddress = 0 THEN Exit;

          REPEAT UNTIL (Port [PortAddress + 5] AND $20) = $20;

          Port [PortAddress] := Ord (CharToSend);
          END;
 }
end;

function UpperCase_old(const s: string): string;
{
From FastcodeUpperCaseUnit
�������� � 2 ���� �������.
}
asm {Size = 134 Bytes}
  push    ebx
  push    edi
  push    esi
  test    eax, eax               {Test for S = NIL}
  mov     esi, eax               {@S}
  mov     edi, edx               {@Result}
  mov     eax, edx               {@Result}
  jz      @@Null                 {S = NIL}
  mov     edx, [esi-4]           {Length(S)}
  test    edx, edx
  je      @@Null                 {Length(S) = 0}
  mov     ebx, edx
  call    system.@LStrSetLength  {Create Result String}
  mov     edi, [edi]             {@Result}
  mov     eax, [esi+ebx-4]       {Convert the Last 4 Characters of String}
  mov     ecx, eax               {4 Original Bytes}
  or      eax, $80808080         {Set High Bit of each Byte}
  mov     edx, eax               {Comments Below apply to each Byte...}
  sub     eax, $7B7B7B7B         {Set High Bit if Original <= Ord('z')}
  xor     edx, ecx               {80h if Original < 128 else 00h}
  or      eax, $80808080         {Set High Bit}
  sub     eax, $66666666         {Set High Bit if Original >= Ord('a')}
  and     eax, edx               {80h if Orig in 'a'..'z' else 00h}
  shr     eax, 2                 {80h > 20h ('a'-'A')}
  sub     ecx, eax               {Clear Bit 5 if Original in 'a'..'z'}
  mov     [edi+ebx-4], ecx
  sub     ebx, 1
  and     ebx, -4
  jmp     @@CheckDone
@@Null:
  pop     esi
  pop     edi
  pop     ebx
  jmp     System.@LStrClr
@@Loop:                          {Loop converting 4 Character per Loop}
  mov     eax, [esi+ebx]
  mov     ecx, eax               {4 Original Bytes}
  or      eax, $80808080         {Set High Bit of each Byte}
  mov     edx, eax               {Comments Below apply to each Byte...}
  sub     eax, $7B7B7B7B         {Set High Bit if Original <= Ord('z')}
  xor     edx, ecx               {80h if Original < 128 else 00h}
  or      eax, $80808080         {Set High Bit}
  sub     eax, $66666666         {Set High Bit if Original >= Ord('a')}
  and     eax, edx               {80h if Orig in 'a'..'z' else 00h}
  shr     eax, 2                 {80h > 20h ('a'-'A')}
  sub     ecx, eax               {Clear Bit 5 if Original in 'a'..'z'}
  mov     [edi+ebx], ecx
@@CheckDone:
  sub     ebx, 4
  jnc     @@Loop
  pop     esi
  pop     edi
  pop     ebx
end;

//function UpperCase(const s: string): string;

{        ASM

    CLD
    LEA     SI, Input
    LES     DI, @Result
    SEGSS   LODSB
    STOSB
    XOR     AH, AH
    XCHG    AX, CX
    JCXZ    @3
    @1:
    SEGSS   LODSB
    CMP     AL, 'a'
    JB      @2
    CMP     AL, 'z'
    JA      @2
    SUB     AL, 20H
    @2:
    STOSB
    LOOP    @1
    @3:
    END;
}

function ValidRST(var Ex: ShortString; var RST: smallInt {Word}; Mode: ModeType): boolean;

var

  DefaultRST                            : Word;
  Number                                : integer;
begin
  ValidRST := False;

  if (Mode = CW) or (Mode = Digital) then
    DefaultRST := 599
  else
    DefaultRST := 59;

  if length(Ex) = 0 then
  begin
    RST := DefaultRST;
    ValidRST := True;
    Exit;
  end;

  Number := GetNumberFromCharBuffer(@Ex[1]);

  RemoveFirstString(Ex);
  //GetRidOfPrecedingSpaces(Ex);
  //showmessage(pchar(string(ex)));
  if Number in [1..9] then
  begin
    Number := 50 + Number;
    if Mode = CW then Number := Number * 10 + 9;
    RST := Number;
    Result := True;
    Exit;
  end;

  if Number in [10..59] then
  begin
    if Mode = Phone then RST := Number;
    Result := True;
    Exit;
  end;

  if (Number >= 100) and (Number <= 599) then
    if (Mode = CW) or (Mode = Digital) then
    begin
      RST := Number;
      Result := True;
      Exit;
    end;

  //showint(number);
{
  RSTString := '';
  //  if Tree.StringIsAllNumbers(Ex) then //wli
  while (Copy(Ex, 1, 1) >= '0') and (Copy(Ex, 1, 1) <= '9') do
  //while Copy(Ex, 1, 1) in ['0'..'9'] do
  begin
    RSTString := RSTString + Copy(Ex, 1, 1);
    Delete(Ex, 1, 1);
  end;

  case length(RSTString) of
    0:
      begin
        RST := DefaultRST;
        ValidRST := True;
      end;

    1:
      begin
        Delete(DefaultRST, 2, 1);
        Insert(RSTString, DefaultRST, 2);
        RST := DefaultRST;
        ValidRST := True;
      end;

    2:
      if Mode = Phone then
      begin
        RST := RSTString;
        ValidRST := (RST[1] >= '1') and (RST[1] <= '5');
      end;

    3:
      if (Mode = CW) or (Mode = Digital) then
      begin
        RST := RSTString;
        ValidRST := (RST[1] >= '1') and (RST[1] <= '5');
      end;
  end;
}
end;

//procedure WriteColor(Prompt: Str80; FColor: INTEGER; BColor: INTEGER);

//begin
 //{WLI}
 {    TextColor (FColor);
     TextBackground (BColor);
     Write (Prompt);
}
//end;

function WhiteSpaceCharacter(InputChar: Char): boolean;

begin
  WhiteSpaceCharacter := (InputChar = ' ') or (InputChar = TabKey);
end;
{
procedure CharacterBuffer.InitializeBuffer;

begin
   //  Tail := 0;
   //  Head := 0;
   //  New(List);
    // DebugFlag := False;
end;

procedure CharacterBuffer.ClearBuffer;

begin
  Tail := 0;
  Head := 0;

end;

function CharacterBuffer.FreeSpace: integer;

begin
  if Head < Tail then
    FreeSpace := Tail - Head - 1
  else
    FreeSpace := BufferLength - (Head - Tail) - 1;
end;

procedure CharacterBuffer.GoAway;

begin
  if List <> nil then
    Dispose(List);

  List := nil;
end;

function CharacterBuffer.IsEmpty;

begin
  IsEmpty := (Head = Tail) or (List = nil);
end;

procedure CharacterBuffer.AddEntry(Entry: Byte);

begin
   //  List^[Head] := Entry;
   //  Head := (Head + 1) mod BufferLength;

   //  if Tail = Head then
   //    Tail := (Tail + 1) mod BufferLength;
end;

procedure CharacterBuffer.AddString(Entry: string);

var
  Index                                 : integer;

begin
  if Length(Entry) > 0 then
     begin
       for Index := 1 to Length(Entry) do
       begin
         List^[Head] := Ord(Entry[Index]);
         Head := (Head + 1) mod BufferLength;
       end;

       if Tail = Head then
         Tail := (Tail + 1) mod BufferLength;
     end;

end;
}

{
function CharacterBuffer.GetNextByte(var Entry: Byte): boolean;

// Returns TRUE if a byte was there to get

begin
  if Tail <> Head then
  begin
    Entry := List^[Tail];
    Tail := (Tail + 1) mod BufferLength;
    GetNextByte := True;
  end
  else
    GetNextByte := False;
end;

function CharacterBuffer.GetNextLine(var Entry: string): boolean;
// The Head is where new data would go (there isn't any there yet), and  the Tail is the oldest byte in the buffer.

var
  TestTail                              : integer;

begin
   {    GetNextLine := False;

       IF Tail = Head THEN Exit;     // Nothing to look at

       TestTail := Tail;

   //     We move through the data, looking for a CarriageReturn

       WHILE (List^ [TestTail] <> Ord (CarriageReturn)) AND
             (List^ [TestTail] <> Ord (LineFeed)) DO
                 BEGIN
                 TestTail := (TestTail + 1) MOD BufferLength;

                 IF TestTail = Head THEN Exit;  // No CarriageReturn was found
                 END;

   //     We have found a carriage return or line feed at TestTail.  We aren't
   //      going to copy the carriage return, so back up one count.

       Dec (TestTail);

   // See if we went below zero

       IF TestTail < 0 THEN TestTail := BufferLength - 1;

   //Copy the string

       Entry := '';

       IF TestTail > Tail THEN   //Can use monotonic addressing
           BEGIN
           IF (TestTail - Tail) + 1 <= 255 THEN
               BEGIN
              Entry [0] := Chr ((TestTail - Tail) + 1);  // String Length
               Move (List^ [Tail], Entry [1], (TestTail - Tail) + 1);
               END;
           END
       ELSE
           IF (BufferLength - Tail) + TestTail + 1 < 255 THEN
               BEGIN
               Entry [0] := Chr ((BufferLength - Tail) + TestTail + 1);
               Move (List^ [Tail], Entry [1], BufferLength - Tail);
               Move (List^ [0],    Entry [BufferLength - Tail + 1], Length (Entry) - BufferLength + Tail);
               END;

   //Tell the guy calling me that we have something for him to look at

       GetNextLine := True;

       Tail := TestTail;  //Point to the last piece of the data

   //Added 12-Oct-2003 because this wasn't working a second time

       Tail := (Tail + 1) MOD BufferLength;  //Point to the CR

   //     This will take care of jumping over CarriageReturn and any line feeds
   //      that might follow it.

       WHILE ((List^ [Tail] = Ord (CarriageReturn)) OR (List^ [Tail] = Ord (LineFeed))) DO
           BEGIN
           Tail := (Tail + 1) MOD BufferLength;
           IF Tail = Head THEN Exit;
           END;

end;
 }

procedure IncrementMonth(var DateString: Str20);

{ This procedure will increment the month of the date string to the next
  month and set the day to 1.  If it is in December, the year will also
  be incremented. }

var
  MonthString, YearString               : Str20;
  Year, Result                          : integer;

begin
  MonthString := UpperCase(BracketedString(DateString, '-', '-'));

  YearString := Copy(DateString, length(DateString) - 1, 2);
  Val(YearString, Year, Result);

  if MonthString = 'JAN' then
    DateString := '1-FEB-' + YearString;

  if MonthString = 'FEB' then
    DateString := '1-MAR-' + YearString;

  if MonthString = 'MAR' then
    DateString := '1-APR-' + YearString;

  if MonthString = 'APR' then
    DateString := '1-MAY-' + YearString;

  if MonthString = 'MAY' then
    DateString := '1-JUN-' + YearString;

  if MonthString = 'JUN' then
    DateString := '1-JUL-' + YearString;

  if MonthString = 'JUL' then
    DateString := '1-AUG-' + YearString;

  if MonthString = 'AUG' then
    DateString := '1-SEP-' + YearString;

  if MonthString = 'SEP' then
    DateString := '1-OCT-' + YearString;

  if MonthString = 'OCT' then
    DateString := '1-NOV-' + YearString;

  if MonthString = 'NOV' then
    DateString := '1-DEC-' + YearString;

  if MonthString = 'DEC' then
  begin
    inc(Year);
    if Year > 99 then Year := 0;

    Str(Year, YearString);

    while length(YearString) < 2 do
      YearString := '0' + YearString;

    DateString := '1-JAN-' + YearString;
  end;
end;

procedure IncrementMinute(var DateString: Str20; var TimeString: Str80);

{ This procedure will add a day to the DateString passed to it.  The
  string is in the format dd-mon-yr.  It will handle month ends and
  increment the year correctly (including leap years). }

var
  Day, Hour, Minute, Year, Result       : integer;
  MinuteString, HourString, DayString, MonthString, YearString: Str20;

begin
  Val(PostcedingString(TimeString, ':'), Minute, Result);
  Val(PrecedingString(TimeString, ':'), Hour, Result);

  inc(Minute);

  if Minute > 59 then
  begin
    Minute := 0;
    inc(Hour);

    if Hour > 23 then
    begin
      Hour := 0;

      Val(PrecedingString(DateString, '-'), Day, Result);
      inc(Day);
      Str(Day, DayString);

      while length(DayString) < 2 do
        DayString := '0' + DayString;

      Delete(DateString, 1, pos('-', DateString) - 1);
      Insert(DayString, DateString, 1);

          { Now check for new month }

      if Day > 28 then { All months have at least 28 days }
      begin
        MonthString := UpperCase(BracketedString(DateString, '-', '-'));

        if (MonthString = 'JAN') or (MonthString = 'MAR') or
          (MonthString = 'MAY') or (MonthString = 'JUL') or
          (MonthString = 'AUG') or (MonthString = 'OCT') or
          (MonthString = 'DEC') then
          if Day > 31 then IncrementMonth(DateString);

        if MonthString = 'FEB' then
        begin
          YearString := Copy(DateString, length(DateString) - 1, 2);
          Val(YearString, Year, Result);

          if (Year mod 4 = 0) and (Year <> 0) then { Leap year }
          begin
            if Day > 29 then IncrementMonth(DateString);
          end
          else
            if Day > 28 then IncrementMonth(DateString);

        end;

        if (MonthString = 'APR') or (MonthString = 'JUN') or
          (MonthString = 'SEP') or (MonthString = 'NOV') then
          if Day > 30 then IncrementMonth(DateString);

      end;
    end;

  end;

  Str(Minute, MinuteString);

  while length(MinuteString) < 2 do
    MinuteString := '0' + MinuteString;

  Str(Hour, HourString);

  while length(HourString) < 2 do
    HourString := '0' + HourString;

  TimeString := HourString + ':' + MinuteString;
end;

function NewKeyPressed: boolean;

begin
  {    IF UseBIOSKeyCalls THEN
          BEGIN
          NewKeyPressed := KeyPressed;
          Exit;
          END;

      NewKeyPressed := Mem [$40:$1A] <> Mem [$40:$1C];
 }
end;

function NewReadKey: Char;



begin
  {    IF UseBIOSKeyCalls THEN
          BEGIN
          Key := ReadKey;

          IF ReadKeyAltState THEN
              BEGIN
              NewReadKey := Key;
              ReadKeyAltState := False;
              Exit;
              END;

          IF Key = NullKey THEN
              BEGIN
              NewReadKey := Key;
              ReadKeyAltState := True;
              Exit;
              END;

          IF Key = QuestionMarkChar THEN
              NewReadKey := '?'
          ELSE
              IF Key = SlashMarkChar THEN
                  NewReadKey := '/'
              ELSE
                  NewReadKey := Key;

          Exit;
          END;

      Address := Mem [$40:$1A];

      IF ExtendedKey <> 0 THEN
          BEGIN
          NewReadKey := Chr (ExtendedKey);
          Address := Address + 2;
          IF Address > $3C THEN Address := $1E;
          Mem [$40:$1A] := Address;
          ExtendedKey := 0;
          Exit;
          END;

      REPEAT UNTIL NewKeyPressed;

      MemByte := Mem [$40:Address];

      IF (MemByte = 0) OR (MemByte = $E0) THEN
          BEGIN
          NewReadKey := Chr (0);
          ExtendedKey := Mem [$40:Address + 1];
          Exit;
          END
      ELSE
          BEGIN
          IF Chr (MemByte) = QuestionMarkChar THEN
              NewReadKey := '?'
          ELSE
              IF Chr (MemByte) = SlashMarkChar THEN
                  NewReadKey := '/'
              ELSE
                  NewReadKey := Chr (MemByte);

          Address := Address + 2;
          IF Address > $3C THEN Address := $1E;
          Mem [$40:$1A] := Address;
          END;
 }
end;

function GoodLookingGrid(Grid: Str20): boolean;

{ Verifies that the grid square is legitimate }

var
  CharPosition                          : integer;

begin
  GoodLookingGrid := False;

  if not ((length(Grid) = 4) or (length(Grid) = 6)) then Exit;

  strU(Grid);

  for CharPosition := 1 to length(Grid) do
    case CharPosition of
      1, 2:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'R') then
          Exit;

      3, 4:
        if (Grid[CharPosition] < '0') or (Grid[CharPosition] > '9') then
          Exit;

      5, 6:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'Z') then
          Exit;

    end;

  GoodLookingGrid := True;
end;

function GoodLookingGrid2(Grid: Str20): boolean;

{ Verifies that the grid  is legitimate }

var
  CharPosition                          : integer;
//   buf: array[0..4] of char;

begin
  GoodLookingGrid2 := False;

  if not ((length(Grid) = 2) or (length(Grid) = 4)) then Exit;

  strU(Grid);

  for CharPosition := 1 to length(Grid) do
    case CharPosition of
      1, 2:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'R') then
          Exit;

      3, 4:
        if (Grid[CharPosition] < '0') or (Grid[CharPosition] > '9') then
          Exit;

      5, 6:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'Z') then
          Exit;

    end;

  GoodLookingGrid2 := True;
end;

function GoodLookingGrid3(Grid: Str20): boolean;

{ Verifies that the grid  is legitimate }

var
  CharPosition                          : integer;
//   buf: array[0..4] of char;

begin
  GoodLookingGrid3 := False;

  if not (length(Grid) = 6)  then Exit;

  strU(Grid);

  for CharPosition := 1 to length(Grid) do
    case CharPosition of
      1, 2:
      if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'R') then
        exit;
        {   if (Grid[CharPosition] > 'R') then

         Exit; }

      3, 4:
        if (Grid[CharPosition] < '0') or (Grid[CharPosition] > '9') then
          Exit;

      5, 6:
        if (Grid[CharPosition] < 'A') or (Grid[CharPosition] > 'Z') then
          Exit;

    end;

  GoodLookingGrid3 := True;
end;


function GetSCPIntegerFromChar(InputChar: Char): integer;

begin
  GetSCPIntegerFromChar := -1;

  if InputChar in ['A'..'Z'] then
  begin
    GetSCPIntegerFromChar := Ord(InputChar) - Ord('A');
    Exit;
  end;

  if InputChar in ['0'..'9'] then
  begin
    GetSCPIntegerFromChar := Ord(InputChar) - Ord('0') + 26;
    Exit;
  end;

  if InputChar = '/' then GetSCPIntegerFromChar := 36;
end;

function GetSCPCharFromInteger(Index: integer): Char;

begin
  if Index <= 25 then
    GetSCPCharFromInteger := CHR(Ord('A') + Index)
  else
    if Index <= 35 then
      GetSCPCharFromInteger := CHR(Ord('0') + (Index - 26))
    else
      if Index = 36 then
        GetSCPCharFromInteger := '/'
      else
        GetSCPCharFromInteger := CHR(0);
end;

function PartialCall(Pattern: CallString; Call: CallString): boolean;

label
  NotAPartialCallHere;

var
  CharPos, ComparePos                   : integer;

begin
  if pos(Pattern, Call) > 0 then
  begin
    PartialCall := True;
    Exit;
  end;

  if pos('?', Pattern) = 0 then
  begin
    PartialCall := False;
    Exit;
  end;

  for CharPos := 1 to length(Call) - length(Pattern) + 1 do
  begin
    if (Call[CharPos] = Pattern[1]) or (Pattern[1] = '?') then
    begin
      for ComparePos := 2 to length(Pattern) do
        if (Call[CharPos + ComparePos - 1] <> Pattern[ComparePos]) and (Pattern[ComparePos] <> '?') then
          goto NotAPartialCallHere;

          { We have a match! }

      PartialCall := True;
      Exit;
    end;

    NotAPartialCallHere:

  end;

  PartialCall := False;
end;

function CSV(Letter: CallString): integer;

{ Computers character sort value for CallSortValue routine }

begin
  if Letter = '' then
  begin
    CSV := 0;
    Exit;
  end;

  if Letter = '/' then
  begin
    CSV := 1;
    Exit;
  end;

  if (Letter >= '0') and (Letter <= '9') then
  begin
    CSV := Ord(Letter[1]) - Ord('0') + 1;
    Exit;
  end;

  if (Letter >= 'A') and (Letter <= 'Z') then
  begin
    CSV := Ord(Letter[1]) - Ord('A') + 11;
    Exit;
  end;
end;

function CallSortValue(Call: CallString): LONGINT;

{ Processes /, 0-9 and A-Z for the first 6 letters }

var
  CharPos                               : integer;
  Total                                 : REAL;

begin
  Total := 0;

  if Call = '' then
  begin
    CallSortValue := 0;
    Exit;
  end;

  for CharPos := 1 to 6 do
    Total := CSV(Copy(Call, CharPos, 1)) + (Total * 37);

  CallSortValue := round(Total - 2147483648.0);
end;

function GetStateFromSection(Section: Str20): Str20;

begin
  Section := UpperCase(Section);

  if (Section = 'AK') or (Section = 'AL') or (Section = 'AR') or
    (Section = 'AZ') or (Section = 'CO') or (Section = 'CT') or
    (Section = 'DE') or (Section = 'GA') or (Section = 'IA') or
    (Section = 'ID') or (Section = 'IN') or (Section = 'IL') or
    (Section = 'KS') or (Section = 'KY') or (Section = 'LA') or
    (Section = 'ME') or (Section = 'MI') or (Section = 'MN') or
    (Section = 'MO') or (Section = 'MS') or (Section = 'MT') or
    (Section = 'NC') or (Section = 'ND') or (Section = 'NE') or
    (Section = 'NH') or (Section = 'NM') or (Section = 'NV') or
    (Section = 'OH') or (Section = 'OK') or (Section = 'OR') or

  (Section = 'RI') or (Section = 'SD') or (Section = 'TN') or
    (Section = 'UT') or (Section = 'VA') or (Section = 'VT') or
    (Section = 'WI') or (Section = 'WV') or (Section = 'WY') or
    (Section = 'SC') then
  begin
    GetStateFromSection := Section;
    Exit;
  end;

  if (Section = 'EB') or (Section = 'LAX') or (Section = 'ORG') or
    (Section = 'SB') or (Section = 'SCV') or (Section = 'SDG') or
    (Section = 'SF') or (Section = 'SJV') or (Section = 'SV') then
  begin
    GetStateFromSection := 'CA';
    Exit;
  end;

  if (Section = 'EM') or (Section = 'WM') then
  begin
    GetStateFromSection := 'MA';
    Exit;
  end;

  if (Section = 'EN') or (Section = 'WNY') or (Section = 'NNY') or
    (Section = 'ENY') or (Section = 'NLI') then
  begin
    GetStateFromSection := 'NY';
    Exit;
  end;

  if (Section = 'EP') or (Section = 'WP') then
  begin
    GetStateFromSection := 'PA';
    Exit;
  end;

  if (Section = 'EW') or (Section = 'WWA') or (Section = 'EWA') then
  begin
    GetStateFromSection := 'WA';
    Exit;
  end;

  if (Section = 'NF') or (Section = 'SF') or (Section = 'WCF') then // ny4i 4.44.9...unrelated but I happened to notice this
  begin
    GetStateFromSection := 'FL';
    Exit;
  end;

  if (Section = 'NNJ') or (Section = 'SNJ') then
  begin
    GetStateFromSection := 'NJ';
    Exit;
  end;

  if (Section = 'NTX') or (Section = 'STX') or (Section = 'WTX') then
  begin
    GetStateFromSection := 'TX';
    Exit;
  end;

  GetStateFromSection := '';
end;

function LooksLikeAState(state: string): boolean;

begin
  Result := false;
  if (state = 'CA') or (state = 'TX') or (state = 'NY') or (state = 'FL') or
     (state = 'TX') or (state = 'PA') or (state = 'MA') or (state = 'NJ') or
     (state = 'WA') or (state = 'MD') or (state = 'DC') or
     (state = 'AK') or (state = 'AL') or (state = 'AR') or
     (state = 'AZ') or (state = 'CO') or (state = 'CT') or
     (state = 'DE') or (state = 'GA') or (state = 'IA') or
     (state = 'ID') or (state = 'IN') or (state = 'IL') or
     (state = 'KS') or (state = 'KY') or (state = 'LA') or
     (state = 'ME') or (state = 'MI') or (state = 'MN') or
     (state = 'MO') or (state = 'MS') or (state = 'MT') or
     (state = 'NC') or (state = 'ND') or (state = 'NE') or
     (state = 'NH') or (state = 'NM') or (state = 'NV') or
     (state = 'OH') or (state = 'OK') or (state = 'OR') or
     (state = 'RI') or (state = 'SD') or (state = 'TN') or
     (state = 'UT') or (state = 'VA') or (state = 'VT') or
     (state = 'WI') or (state = 'WV') or (state = 'WY') or
     (state = 'SC') or (state = 'HI') or
     (state = 'NS') or (state = 'QC') or (state = 'ON') or (state = 'MB') or
     (state = 'SK') or (state = 'AB') or (state = 'BC') or (state = 'NT') or
     (state = 'NB') or (state = 'NL') or (state = 'YT') or (state = 'PE') or (state = 'NU') then
     begin
     Result := true;
     end;


end;

function LooksLikeASection(section: string): boolean;

begin
   Result := false;
   if (Section = 'AK') or (Section = 'AL') or (Section = 'AR') or
      (Section = 'AZ') or (Section = 'CO') or (Section = 'CT') or
      (Section = 'DE') or (Section = 'GA') or (Section = 'IA') or
      (Section = 'ID') or (Section = 'IN') or (Section = 'IL') or
      (Section = 'KS') or (Section = 'KY') or (Section = 'LA') or
      (Section = 'ME') or (Section = 'MI') or (Section = 'MN') or
      (Section = 'MO') or (Section = 'MS') or (Section = 'MT') or
      (Section = 'NC') or (Section = 'ND') or (Section = 'NE') or
      (Section = 'NH') or (Section = 'NM') or (Section = 'NV') or
      (Section = 'OH') or (Section = 'OK') or (Section = 'OR') or
      (Section = 'RI') or (Section = 'SD') or (Section = 'TN') or
      (Section = 'UT') or (Section = 'VA') or (Section = 'VT') or
      (Section = 'WI') or (Section = 'WV') or (Section = 'WY') or
      (Section = 'SC') then
      begin
      Result := true;
      end
   else if (Section = 'EB') or (Section = 'LAX') or (Section = 'ORG') or
           (Section = 'SB') or (Section = 'SCV') or (Section = 'SDG') or
           (Section = 'SF') or (Section = 'SJV') or (Section = 'SV') then
      begin
      Result := true;
      end
   else if (Section = 'EM') or (Section = 'EMA') or
           (Section = 'WM') or (Section = 'WMA') then
      begin
      Result := true;
      end
   else if (Section = 'EN') or (Section = 'WNY') or (Section = 'NNY') or
           (Section = 'ENY') or (Section = 'NLI') then
      begin
      Result := true;
      end
   else if (Section = 'EP') or (Section = 'EPA') or
           (Section = 'WP') or (Section = 'WPA') then
      begin
      Result := true;
      end
   else if (Section = 'EW') or (Section = 'EWA') or
           (Section = 'WWA') or (Section = 'WW') then
      begin
      result := true;
      end
   else if (Section = 'NF') or (Section = 'SF') or (Section = 'WCF') then
      begin
      Result := true;
      end
   else if (Section = 'NNJ') or (Section = 'SNJ') then
      begin
      Result := true;
      end
   else if (Section = 'NTX') or (Section = 'STX') or (Section = 'WTX') then
      begin
      Result := true;
      end
   else
      begin
      Result := false;
      end;

end;
{
function ReadFromSerialPort(port: HWND; BytesToRead: Cardinal; WriteDebug: boolean): boolean ;
var
   //  d                                     : array[1..250] of Char;
   BytesRead                       : Cardinal;
   //  i                                     : Byte;
   //  Temstring                             : string;
begin
   Result := False;
   if ReadFile(port, Radio1.tBuf, BytesToRead, BytesRead, nil) then
      if BytesToRead = BytesRead then Result := True;

   if CPUKeyer.SerialPortDebug then
      if port = Radio1.tr4w_CATPortHandle then
         WriteToDebugFile(Radio1.tr4w_CATPort, True, @Radio1.tBuf, BytesToRead);
   //    begin
   //      SetLength(Temstring, BytesRead);
   //      for i := 1 to BytesRead do Temstring[i] := d[i];
   //      RESULT := Temstring;
   //    end;

   //  if WriteDebug then
   //    if CPUKeyer.SerialPortDebug then
   //      if Port = Radio1.tr4w_CATPortHandle then
   //        WriteLn(CPUKeyer.tr4w_InputDebugFile[Radio1.tr4w_CATPort], GetFullTimeString(True) + ': ' + Result);
end;
}

procedure WriteLnCenter(Prompt: Str80);


begin
  {    ScreenWidth := Lo (WindMax);

      CenterSpaces := (ScreenWidth DIV 2) - (Length (Prompt) DIV 2);
      IF CenterSpaces > 0 THEN GoToXY (CenterSpaces, WhereY);
      WriteLn (Prompt);
     }
end;

procedure WriteLnVarCenter(var FileWrite: Text; Prompt: Str80);

var
  Space, CenterSpaces                   : integer;

begin
  CenterSpaces := 40 - (length(Prompt) div 2);

  if CenterSpaces > 0 then for Space := 1 to CenterSpaces do
      Prompt := ' ' + Prompt;

  WriteLn(FileWrite, Prompt);
end;

procedure WriteLnLstCenter(Prompt: Str80);


begin
  {    CenterSpaces := 40 - (Length (Prompt) DIV 2);
      IF CenterSpaces > 0 THEN FOR Space := 1 TO CenterSpaces DO Write (Lst, ' ');
      WriteLn (Lst, Prompt);
     }
end;

function FoundDirectory(FileName: string; Path: string; var Directory: string): boolean;

var
  TempString                            : Str80;
  //{WLI}
  s                                     : string;
//  CharPos                               : integer;
  find_data                             : WIN32_FIND_DATA;
begin
  FoundDirectory := False;

  //wli
  //    S := FSearch (FileName, Path);
  if Windows.FindFirstFile(PChar(FileName), find_data) <> INVALID_HANDLE_VALUE then

    if s = '' then
      Exit
    else
    begin
        //wli         TempString := FExpand (S);

      while TempString[length(TempString)] <> '\' do
        Delete(TempString, length(TempString), 1);

      Delete(TempString, length(TempString), 1);

      Directory := TempString;
      FoundDirectory := True;
    end;

end;

function FindDirectory(FileName: Str80): Str80;

{ This procedure will attempt to find the directory for the filename
  passed to it.  It will first check the current working directory, the
  directory above the working one, then check the environment variable
  TRLOG.

  If still no luck, it will check to see it can be found in the command
  string used to execute the program that is running.

  Then it will check the PATH environment string directories.

  Finally, it will check the old \log\name directory.  If it isn't found,
  it will return a null string.

  If a directory was found, it will end without \. }

var
  TempString, Directory                 : string;

begin
  FindDirectory := '';

  if FoundDirectory(FileName, '.', Directory) then
  begin
    FindDirectory := Directory;
    Exit;
  end;

  if FoundDirectory(FileName, '..', Directory) then
  begin
    FindDirectory := Directory;
    Exit;
  end;

  //wli     IF FoundDirectory (FileName, GetEnv ('TRLOG'), Directory) THEN
  begin
    FindDirectory := Directory;
    Exit;
  end;

  { All this will check to see what command was typed in to run the
    active program and see if a path was specified. }

  TempString := ParamStr(0);

  if StringHas(TempString, '\') then
  begin
    while TempString[length(TempString)] <> '\' do
      Delete(TempString, length(TempString), 1);

    Delete(TempString, length(TempString), 1);

    if FoundDirectory(FileName, TempString, Directory) then
    begin
      FindDirectory := Directory;
      Exit;
    end;
  end;

  //wli     IF FoundDirectory (FileName, GetEnv ('PATH'), Directory) THEN
  begin
    FindDirectory := Directory;
    Exit;
  end;

  if FoundDirectory(FileName, '\log\name', Directory) then
  begin
    FindDirectory := Directory;
    Exit;
  end;

end;

procedure RenameFile(OldName: string; NewName: string);

{ This procedure will rename the filename specified to the new name
    indicated.  If a file existed with the newname, it is deleted first. }

var
  f                                     : Text;

begin

  Windows.DeleteFile(PChar(NewName));
  //wli DeleteFile(NewName);

  Assign(f, OldName);
  Rename(f, NewName);
end;

procedure QuickBeep;

begin
  SpeakerBeep(1000, 300);
end;

function TryToOpenCOMPort(portnr: Cardinal {Byte}; dwFlagsAndAttributes: DWORD): HWND;
begin
  Format(wsprintfBuffer, _COM, portnr);

  Result :=
    CreateFile(
    wsprintfBuffer,
    GENERIC_READ or GENERIC_WRITE,
    0,
    nil,
    OPEN_EXISTING,
    dwFlagsAndAttributes,
    0);
end;

function tGetBandFromString(BandStr: ShortString): BandType;
var
  TempBandType                          : BandType;
  Band                                  : string[3];
begin
  Result := NoBand;
  if BandStr = '' then Exit;
  Band := Copy(BandStr, 1, 3);
  if length(Band) = 2 then Band := ' ' + Band;
  if length(Band) = 1 then Band := '  ' + Band;
  for TempBandType := Band160 to NoBand do
    if BandStringsArray[TempBandType] = Band then
    begin
      Result := TempBandType;
      Break;
    end;
end;

procedure IncSystemTime(var St: SYSTEMTIME; Offset: int64);
var
  TEMPFILETIME                          : FILETIME;
begin
  Windows.SystemTimeToFileTime(St, TEMPFILETIME);
  TEMPFILETIME := FILETIME(int64(TEMPFILETIME) + Offset * 10000);
  Windows.FileTimeToSystemTime(TEMPFILETIME, St);
end;

procedure tGetQSOSystemTime(var Time: TQSOTime);
begin
  tGetSystemTime;
  if UTC.wYear < 2000 then Time.qtYear := 0
  else
    Time.qtYear := UTC.wYear - 2000;
  Time.qtMonth := UTC.wMonth;
  Time.qtDay := UTC.wDay;
  Time.qtHour := UTC.wHour;
  Time.qtMinute := UTC.wMinute;
  Time.qtSecond := UTC.wSecond;
end;

function QSOTimeToSeconds(t: TQSOTime): integer;
begin
  Result :=
    t.qtSecond +
    t.qtMinute * 60 +
    t.qtHour * 60 * 60 +
    t.qtDay * 60 * 60 * 24 +
    t.qtMonth * 60 * 60 * 24 * 30;
end;

function CheckPTTLockout: boolean;
var
  c                                     : integer;
begin
  Result := False;
  if PTTLockout then
    if NetSocket <> 0 then
      for c := 1 to 26 do
        if ((StatusArray[c].ssStatusByte and (1 shl 0)) <> 0) //PTT
          and ((StatusArray[c].ssStatusByte and (1 shl 3)) <> 0) //PTT LOCKOUT
          then
          if Ord(ComputerID) - 64 <> c then
          begin
            QuickDisplay('PTT LOCKOUT=TRUE');
            Result := True;
          end;
end;

function GetRealPath(Path, FileName, AddFolder: PChar): PChar;
begin
  Windows.ZeroMemory(@GETREALPATHBUFFER, SizeOf(GETREALPATHBUFFER));
  if pPos('\', TR4W_DVKPATH) = -1 then
  begin
    Format(GETREALPATHBUFFER, '%s%s\', TR4W_PATH_NAME, Path);
  end
  else
  begin
    Format(GETREALPATHBUFFER, '%s\', Path);
  end;

  if AddFolder <> nil then
  begin
    Windows.lstrcat(GETREALPATHBUFFER, AddFolder);
    Windows.lstrcat(GETREALPATHBUFFER, '\');
  end;

  Windows.lstrcat(GETREALPATHBUFFER, FileName);

  Result := GETREALPATHBUFFER;
end;

function KeyboardCallsignChar(var Key: integer; ExChWin: boolean): boolean;
begin
  Result := False;

  if Key in [Ord('0')..Ord('9'), Ord('a')..Ord('z'), Ord('A')..Ord('Z'), 191, Ord('/'), Ord('?'), VK_BACK, Ord('-')] then Result := True;

  if ExChWin then
  begin
    if Key = Ord(' ') then Result := True;
//    if Key in [134, 143, 132, 142, 148, 153] then RESULT := True;
    if Key in [228, 196, 229, 197, 246, 214] then Result := True;
  end;

//  Key := 148;
  if Key = Ord(QuestionMarkChar) then
  begin
    Key := Ord('?');
    Result := True;
  end;

  if Key = Ord(SlashMarkChar) then
  begin
    Key := Ord('/');
    Result := True;
  end;

end;

function GetOblast(Call: CallString): Str2;
var
  i                                     : integer;
  c1                                    : Char;
  c2                                    : Char;
begin
  Call := StandardCallFormat(Call, False);

  if StringHas(Call, '/') then Call := PrecedingString(Call, '/');

  c1 := #0;
  c2 := #0;
  for i := 2 to length(Call) do
  begin
    if c1 <> #0 then
    begin
      if Call[i] in ['A'..'Z'] then
      begin
        c2 := Call[i];
        Break;
      end;
      Continue;
    end;

    if Call[i] in ['0'..'9'] then
      c1 := Call[i];
  end;

  if (c1 = #0) or (c2 = #0) then
    Result := ''
  else
  begin
    Result[0] := #2;
    Result[1] := c1;
    Result[2] := c2;
//    Result := c1 + c2;
  end;
{
  while Copy(Call, 1, 1) >= 'A' do
  begin
    Delete(Call, 1, 1);

    if Call = '' then
    begin
      GetOblast := '';
      Exit;
    end;
  end;

  GetOblast := Copy(Call, 1, 2);
}
end;

function GoodLookingRDA(rda: Str20): boolean;

{ Verifies that the grid square is legitimate }

var
  CharPosition                          : integer;

begin
  result := False;

  if not ((length(rda) = 4) ) then Exit;

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

function IsWin64: Boolean;
var
  IsWow64Process : function(hProcess : THandle; var Wow64Process : BOOL): BOOL; stdcall;
  Wow64Process : BOOL;
begin
  Result := False;
  IsWow64Process := GetProcAddress(GetModuleHandle(Kernel32), 'IsWow64Process');
  if Assigned(IsWow64Process) then begin
    if IsWow64Process(GetCurrentProcess, Wow64Process) then begin
      Result := Wow64Process;
    end;
  end;
end;

{
procedure Congrats;
var
  OldBeat                               : integer;
begin
  OldBeat := Beat;
  Beat := 400;
  SixteenthNote(NoteC);
  SixteenthNote(NoteE);
  SixteenthNote(NoteG);
  EigthNote(NoteHiC);
  SixteenthNote(NoteG);
  EigthNote(NoteHiC);
  Beat := OldBeat;
end;
}

function String2Hex(const Buffer: Ansistring): string;
   var
     n: Integer;
   begin
     Result := '';
     for n := 1 to Length(Buffer) do
       Result := UpperCase(Result + IntToHex(Ord(Buffer[n]), 2)) + ' ';
   end;

end.

