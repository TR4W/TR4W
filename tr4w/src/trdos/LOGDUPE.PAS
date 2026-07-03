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
unit LogDupe;

{ This unit contains the objects DupeSheet and MultSheet.  It has all
  of the methods required to use them. }

{$IMPORTEDDATA OFF}
interface

uses
utils_text,
  uCallSignRoutines,
  uMults,
  uCallsigns,
  Windows,
  VC,
  TF,
  LogDom,
  Tree,
  utils_file,
  //Country9,
  ZoneCont,
  LogWind,
  LogRadio,
  LogSCP
  ;

const
  MaxGridSquaresInList                  = 40;

//  TwoLetterPartialCallListLength        = 500;
//  DomesticMultArraySize                 = 400 + 300; {RDAC}
//  DXMultArraySize                       = MaxCountries {UA4WLI};
//  PrefixMultArraySize                   = 1500;

  MaxVisDupeCallTotal                   = 40;
  MaxInitialExchanges                   = 60000; // 4.86.4
  MaxLongPartialCalls                   = 150;

  { Note that the four byte and eight byte blocks must be the same
    size due to how the initial exchange stuff works.        }

  FourByteBlockSize                     = 200; { Used for both calls and prefixes }
  EightByteBlockSize                    = 100; { Used for calls > 6 characters }
  PartialCallBlockSize                  = 200;

  MaxCallBlocks                         = 50; { Per band mode }
  MaxBigCallBlocks                      = 20; { Total in dupesheet }
  MaxPartialCallBlocks                  = 100;

type
  RestartInfo = record
    riPTTOnTotalTime: Cardinal;
    riQSOByOpMode: array[OpModeType] of Cardinal;
    riTotalRecordsInLog: integer;
    riCQTotalCounter: Cardinal;
//    riGetScoresClassArray: array[101..103] of integer;
//    riColumnsWidthArray: array[LogColumnsType] of integer;
  end;

  {
    LongPartialCallListType = array[0..MaxLongPartialCalls] of EightBytes;
    LongPartialCallListPointer = ^LongPartialCallListType;
  }
  //  InitialExchangeArray = array[1..MaxInitialExchanges] of EightBytes;
  //  InitialExchangeArrayPointer = ^InitialExchangeArray;
  {
    PartialCallType = record
      Call: FourBytes;
      InitialExchangeIndex: integer;
    end;

    PartialCallArray = array[0..PartialCallBlockSize - 1] of PartialCallType;
    PartialCallArrayPtr = ^PartialCallArray;
  }
  CallDistrictRecord = record
    List: array[0..MaxVisDupeCallTotal] of string[6];
    Total: integer;
  end;

//  VisibleDupesheet = array[1..10] of CallDistrictRecord;

  StateType = (NoStates, State48, State49, State50);

  ProvinceType = (NoProvinces, Province8, Province11, Province12, Province13);

//  DomesticMultArray = array[0..DomesticMultArraySize - 1] of FourBytes;
//  DXMultArray = array[0..DXMultArraySize - 1] of FourBytes;
//  PrefixMultArray = array[0..PrefixMultArraySize - 1] of FourBytes;
//  ZoneMultArray = array[0..ZoneMultArraySize - 1] of FourBytes;

//  DomesticMultArrayPtr = ^DomesticMultArray;
//  DXMultArrayPtr = ^DXMultArray;
//  PrefixMultArrayPtr = ^PrefixMultArray;
//  ZoneMultArrayPtr = ^ZoneMultArray;

//  FourByteBlockArray = array[0..FourByteBlockSize - 1] of FourBytes;
  EightByteBlockArray = array[0..EightByteBlockSize - 1] of EightBytes;

//  CallBlockPtr = ^FourByteBlockArray;
//  BigCallBlockPtr = ^EightByteBlockArray;
//  FourBytePtr = ^FourBytes;
{
  MultTotals = record
    NumberDomesticMults: integer;
    NumberDXMults: integer;
    NumberPrefixMults: integer;
    NumberZoneMults: integer;
  end;
}
  QSOTotalArray = array[BandType, CW..Both] of integer;
//  MultTotalArrayType = array[BandType, CW..Both] of MultTotals;
{
  MultList = record
//    Totals: MultTotalArrayType;
//    DomesticList: array[BandType, CW..Both] of DomesticMultArrayPtr;
//    DXList: array[BandType, CW..Both] of DXMultArrayPtr;
//    PrefixList: array[BandType, CW..Both] of PrefixMultArrayPtr;
//    ZoneList: array[BandType, CW..Both] of ZoneMultArrayPtr;
  end;
}
  DupeList = record
    Totals: QSOTotalArray;
    //    NumberBigCalls: integer;
    //    DupeList: array[BandType, CW..Both, 1..MaxCallBlocks] of CallBlockPtr;
    //    BigCallList: array[1..MaxBigCallBlocks] of BigCallBlockPtr;
  end;

  VDEntry = record
    Callsign: string[6];
    NextEntry: Pointer;
  end;

  VDEntryPointer = ^VDEntry;

  //  CallDistrictTotalArray = array[1..11] of integer;

  DupeAndMultSheet = object
    DupeSheetEnable: boolean;
    tAutoReset: boolean;
    //    DupeSheet: DupeList;
//    MultSheet: MultList;

    function AddBigCallAddress(BigCall: EightBytes): integer;
    procedure AddCallToVisibleDupeSheet(Callsign: CallString);
    procedure AddCompressedCallToDupeSheet(Call: FourBytes; Band: BandType; Mode: ModeType);
    procedure AddQSOToSheets(RXData: ContestExchangePtr; AddToPartials: boolean);

    //    function CallIsADupe(Call: CallString; Band: BandType; Mode: ModeType): boolean;

//    procedure CancelOutNewDomesticMultWeHaveWorked(MultString: Str20;      Band: BandType;      Mode: ModeType);

//    procedure CancelOutNewDXMultWeHaveWorked(MultString: DXMultiplierString ;      Band: BandType;      Mode: ModeType);

//    procedure CancelOutNewZoneMultWeHaveWorked(MultString: integer; Band: BandType; Mode: ModeType);
//    procedure CancelOutRemainingMultsWeHaveWorked(Band: BandType; Mode: ModeType; multtype: RemainingMultiplierType);

    //    procedure ClearDupeSheet;

        //    procedure CreateVisibleDupeSheetArrays(var Band: BandType;      Mode: ModeType);

    function TwoLetterCrunchProcess(PartialCall: {Call} string): boolean;

    procedure DisposeOfMemoryAndZeroTotals;

    function IsADomesticMult(Mult: Str10; Band: BandType; Mode: ModeType): boolean;

    procedure DupeSheetTotals(var Totals: QSOTotalArray);

    //    function EntryExists(Entry: FourBytes; Band: BandType; Mode: ModeType): boolean;
    procedure ExamineLogForQSOTotals(var QTotals: QSOTotalArray);

    //    procedure MakePartialCallList(Call: CallString;      ActiveBand: BandType;      ActiveMode: ModeType;      var PossCallList: PossibleCallRecord);

    procedure MakePossibleCallList(Call: CallString; var PossCallList: PossibleCallRecord);

//    procedure MultSheetTotals(var Totals: MultTotalArrayType);

    function ReadInBinFiles {(JustDoIt: boolean)}: boolean;

    procedure SetMultFlags(var RXData: ContestExchange);
    procedure SetUpRemainingMultiplierArrays;

    procedure SaveRestartFile;

    procedure SheetInitAndLoad;
  end;

const
  DXMultTypenameArray                   : array[DXMultType] of PChar =
    (
//    'NO COUNT', //    NoCountDXMults,
    'NONE', //    NoDXMults,
    'ARRL DXCC WITH NO USA OR CANADA', //    ARRLDXCCWithNoUSAOrCanada,
    'ARRL DXCC WITH NO ARRL SECTIONS', //    ARRLDXCCWithNoARRLSections,
    'ARRL DXCC WITH NO USA CANADA KH6 OR KL7', //    ARRLDXCCWithNoUSACanadaKH6OrKL7,
    'ARRL DXCC WITH NO I OR IS0', //    ARRLDXCCWithNoIOrIS0,
    'ARRL DXCC WITH NO JT',
    'ARRL DXCC', //    ARRLDXCC,
    'CQ DXCC', //    CQDXCC,
    'CQ DXCC WITH NO USA OR CANADA', //    CQDXCCWithNoUSAOrCanada,
    'CQ DXCC WITH NO HB9', //    CQDXCCWithNoHB9,

    'CQ DXCC WITH NO OK',
    'CQ EUROPEAN COUNTRIES', //    CQEuropeanCountries,
    'CQ UBA EUROPEAN COUNTRIES', //    CQUBAEuropeanCountries,
    'CQ NON EUROPEAN COUNTRIES', //    CQNonEuropeanCountries,
    'NORTH AMERICAN ARRL DXCC WITH NO USA CANADA OR KL7', //    NorthAmericanARRLDXCCWithNoUSACanadaOrkL7,
    'NON SOUTH AMERICAN COUNTRIES', //    NonSouthAmericanCountries,
    'PACC COUNTRIES AND PREFIXES', //    PACCCountriesAndPrefixes,
 //   'CQ NON EUROPEAN COUNTRIES AND WAE', //    CQNonEuropeanCountriesAndWAECallRegions
    'BLACK SEA COUNTRIES'
    );
var

  InitialExCallsigns                    : integer;
  InitialExDupes                        : integer;

  tAllowDupeQSOs                        : boolean = False;
  // Issue #1034: ActiveDXMult moved to VC.pas (light home) so uMults can read it
  // without depending on LogDupe. All users resolve it via VC (universally used).
  ActivePrefixMult                      : PrefixMultType {= NoPrefixMults};

  AutoDupeEnableCQ                      : boolean = False;
  AutoDupeEnableSandP                   : boolean = True;

  tConnectionAtStartup                  : boolean;

  CallsignUpdateEnable                  : boolean;
  CountDomesticCountries                : boolean;
//  CQP                                   : boolean;

  DoingDomesticMults                    : boolean;
  DoingDXMults                          : boolean;
  DoingPrefixMults                      : boolean;
  DoingZoneMults                        : boolean;

  DomQTHDataFileName                    : FileNameType;

  ExchangeInformation                   : ExchangeInformationRecord;
  ExchangeMemoryEnable                  : boolean = True;

  FirstVDEntry                          : VDEntryPointer;

  GridSquareList                        : array[0..MaxGridSquaresInList - 1] of string[4];

  HFBandEnable                          : boolean = True;

  //  InitialExchangeList              : InitialExchangeArrayPointer = nil;

  LastPartialCall                       : CallString;
  LastPartialCallBlock                  : integer;
  LastTwoLetterCrunchedAddress          : integer;
  LastTwoLettersCrunchedOn              : Str20 {= ''};
  //  LoadingInLogFile                      : boolean;
  //  LongPartialCallList              : LongPartialCallListPointer = nil;

  MultByBand                            : boolean;
  MultByMode                            : boolean;
  MultReset                             : boolean = False;
  MultiplierAlarm                       : boolean;

  NumberDifferentMults                  : Byte {= 0};
  NumberGridSquaresInList               : Byte;
  NumberInitialExchanges                : integer;
  NumberLongPartialCalls                : integer;
  NumberPartialCalls                    : integer;
  NumberTwoLetterPartialCalls           : integer;
  NumberVDCalls                         : integer;

  OffTimeStart                          : TimeRecord;

  PartialCallEnable                     : boolean = True;
  //  PartialCallList                  : array[1..MaxPartialCallBlocks] of PartialCallArrayPtr;
  PartialCallLoadLogEnable              : boolean = {false} True;

  QSOByBand                             : boolean;
  QSOByMode                             : boolean;
  QSOTotals                             : QSOTotalArray; { This may not also be exactly the same as
  DupeList.Totals because of dupes read in }

  // Issue #954: highest serial (NumberSent) actually sent, tracked per band
  // (the AllBands index is the whole-station high-water mark).  The next serial
  // to send is this value + 1 -- see NextSerialToSend in LOGEDIT.  It is kept in
  // lockstep with QSOTotals (zeroed in the dupe-sheet reset, updated in LoadinLog
  // and in the live add), but UNLIKE QSOTotals it INCLUDES X-QSO records (they
  // consumed a number) and EXCLUDES deleted ones.  That is what stops marking a
  // QSO X-QSO -- or deleting a mid-log QSO -- from rolling the serial backward
  // and re-issuing a number already sent on the air.
  MaxSerialSent                         : array[BandType] of integer;

  RemainingMultDisplay                  : RemainingMultiplierType = rmNoRemMultDisplay;

//  RemMultMatrix                         : array[Band160..All, CW..Both, RemainingMultiplierType] of RemainingMultListPointer;

  RestartVersionNumber                  : Str10 = '4.7';
  SingleBand                            : BandType = AllBands;
  StartHour, StartMinute, StartSecond, StartSec100: Word;

  TakingABreak                          : boolean;
  TotalOffTime                          : integer;

  TimeElasped                           : array[1..20] of LONGINT;

  TotalNamesSent                        : integer;
  TotalQSOPoints                        : LONGINT {= 0};
  MOQSOPartyW0MAWorked                  : Boolean;   // W0MA worked at least once (+100 flat bonus)
  MOQSOPartyK0GQWorked                  : Boolean;   // K0GQ worked at least once (+100 flat bonus)
  MOQSOPartyPeakHourCount               : Integer;   // 40/80m QSOs in 1400-2000 UTC window (max 250)
//  TwoLetterCrunchPartialCallList        : array[0..TwoLetterPartialCallListLength] of integer;

  WildCardPartials                      : boolean = True;
  //  tTotalRecordsInLog               : integer;
  tRestartInfo                          : RestartInfo;

  //  DTR, RTS                              : boolean;

//procedure AddCallToPartialList(Call: CallString; InitialExchange: CallString);

procedure CheckMOQSOPartyBonusStation(const Callsign: CallString);
function BigEntryAddress(Entry: FourBytes): integer;

function CallNotInPossibleCallList(Call: CallString; PossCallList: PossibleCallRecord): boolean;

procedure ClearContestExchange(var Exchange: ContestExchange);
procedure ConvertBigEntryAddressToFourBytes(EntryPointer: integer; var BigEntry: FourBytes);
procedure CreateGridSquareList(Call: CallString; Band: BandType);

procedure DupeInit;
//function FindProperPartialCallAddress(Call: CallString): integer;
function FoundDomesticQTH(var RXData: ContestExchange): boolean;

procedure GetDXQTH(var RXData: ContestExchange);
//function GetInitialExchange(Call: CallString): CallString;
function GetInitialExchangeStringFromContestExchange(RData: ContestExchange): Str14;
procedure GetMultsFromLogEntry(LogEntry: Str80; var RXData: ContestExchange);
//function GetPartialCall(CallAddress: integer): CallString;

procedure LoadInitialExchangeFile;
procedure EnumInitialEx(FileString: PShortString);

function ParseExchangeIntoContestExchange(LogEntry: string;
  var RXData: ContestExchange): boolean;

function PointsToBigCall(Entry: FourBytes): boolean;

procedure PutPartialCallInList(Call: CallString;
  InitialExchange: CallString;
  CallAddress: integer);

procedure SetUpExchangeInformation(ActiveExchange: ExchangeType;
  var ExchangeInformation: ExchangeInformationRecord
  );

{procedure TransferLogEntryInfoToContestExchange(LogEntry: Str80; var RXData: ContestExchange); }
{
procedure SetDupeBit(var b: Byte);
procedure ResetDupeBit(var b: Byte);
function GetDupeBit(b: Byte): boolean;

function GetDeletedBit(b: Byte): boolean;
procedure SetDeletedBit(var b: Byte);
procedure ResetDeletedBit(var b: Byte);

function GetSPBit(b: Byte): boolean;
procedure SetSPBit(var b: Byte);
procedure ResetSPBit(var b: Byte);

function GetSendBit(b: Byte): boolean;
procedure SetSendBit(var b: Byte);
procedure ResetSendBit(var b: Byte);
}
//procedure SetStatusBit(var StatusByte: Byte; Bit: CEBits);
//procedure ResetStatusBit(var StatusByte: Byte; Bit: CEBits);
//function GetStatusBit(StatusByte: Byte; Bit: CEBits): boolean;

implementation

//{WLI}{$I RemMults}
uses
  //  OZCHR,
  uNet,
  uGetScores,
  PostUnit,
//  uStack,
  MainUnit;

procedure CreateGridSquareList(Call: CallString; Band: BandType);

//var
  //FileRead                              : Text;
 // TempString                            : string; //{WLI}
  //FileString                            : Str80;

begin
  {
    NumberGridSquaresInList := 0;

    if OpenFileForRead(FileRead, LogFileName) then
    begin
      while not Eof(FileRead) do
      begin
        ReadLn(FileRead, FileString);

        if Band = GetLogEntryBand(FileString) then
          if UpperCase(GetLogEntryCall(FileString)) = Call then
          begin
            TempString := GetLogEntryExchangeString(FileString);

            RemoveFirstString(TempString);
            RemoveFirstString(TempString);

            GridSquareList[NumberGridSquaresInList] := RemoveFirstString(TempString);
            inc(NumberGridSquaresInList);

            if NumberGridSquaresInList = MaxGridSquaresInList then
            begin
              Close(FileRead);
              Exit;
            end;
          end;
      end;

      Close(FileRead);
    end;

    if OpenFileForRead(FileRead, 'LOG.TMP') then
    begin
      while not Eof(FileRead) do
      begin
        ReadLn(FileRead, FileString);

        if Band = GetLogEntryBand(FileString) then
          if UpperCase(GetLogEntryCall(FileString)) = Call then
          begin
            TempString := GetLogEntryExchangeString(FileString);

            RemoveFirstString(TempString);
            RemoveFirstString(TempString);

            GridSquareList[NumberGridSquaresInList] := RemoveFirstString(TempString);
            inc(NumberGridSquaresInList);
          end;

        if NumberGridSquaresInList = MaxGridSquaresInList then
        begin
          Close(FileRead);
          Exit;
        end;
      end;

      Close(FileRead);
    end;
  }
end;

function FoundDomesticQTH(var RXData: ContestExchange): boolean;

{ This function will look at the domestic QTH in the contest exchange and
  see if it can figure out what it is.  If so, it will be converted to
  the standard name for the QTH and a TRUE response generated.  Otherwise
  it will be cleared out and a FALSE response generated.  It looks at
  ActiveDomesticMultiplier to see what type of domestic mult it is.  }

var
  QTHString                             : ShortString {Str40}; //{WLI}
 // CharacterPointer                      : integer;

begin
  FoundDomesticQTH := False;

   if RXData.QTHString = '' then
      begin
      logger.error('[FoundDomesticQTH] RXData.QTHString is blank');
      Exit;
      end;

  QTHString := UpperCase(RXData.QTHString);

  if StringHas(QTHString, '/') then QTHString := PrecedingString(QTHString, '/');

  GetRidOfPrecedingSpaces(QTHString);
  GetRidOfPostcedingSpaces(QTHString);
  if QTHString = 'XXX' then
   begin
    FoundDomesticQTH := True;
    exit;
   end;
  FoundDomesticQTH := DomQTHTable.GetDomQTH(QTHString, RXData.DomMultQTH, RXData.DomesticQTH);


 end;

function GetInitialExchangeIndex(InitialExchange: CallString): integer;

{ This routine will return the appropriate InitialExchangeIndex for the
  initial exchange passed to it.  This is the address that the initial
  exchange can be found in the InitialExchangeList.  If the initial
  exchange can't be found in the list - it will be added to the end
  of the list (if there is room) and that address returned.

  If the initial exchange can't be added to the list (because it is
  full) it will return with zero.

  The initial exchange list starts at 1.

}

var
  TempBytes                             : EightBytes;
  //Address                               : integer;

begin
  GetInitialExchangeIndex := 0; { Default in case we can't do it }

  if InitialExchange = '' then Exit; { Nothing to do with this }

  BigCompressFormat(InitialExchange, TempBytes);

  { See if there is a list to look at.  If not, create the list and
    make this the first entry. }

  if NumberInitialExchanges = 0 then { First one - allocate memory }
  begin
      {WLI}
      //{WLI}        IF MaxAvail > SizeOf (InitialExchangeArray) THEN
    begin
        //        if InitialExchangeList = nil then New(InitialExchangeList);
        //        inc(NumberInitialExchanges);
        //        InitialExchangeList^[NumberInitialExchanges] := TempBytes;
        //        GetInitialExchangeIndex := NumberInitialExchanges;
    end;
      {        ELSE
                  BEGIN
                  DoABeep (Single);
                  QuickDisplay ('Not enough memory for initial exchange array!!');
                  ReminderPostedCount := 30;
                  END;

              Exit;
             }
  end;

  { Search the list for this entry }

  if NumberInitialExchanges > MaxInitialExchanges then Exit; //wli
  {
    for Address := 1 to NumberInitialExchanges do
      if (TempBytes[1] = InitialExchangeList^[Address][1]) and
        (TempBytes[2] = InitialExchangeList^[Address][2]) and
        (TempBytes[3] = InitialExchangeList^[Address][3]) and
        (TempBytes[4] = InitialExchangeList^[Address][4]) and
        (TempBytes[5] = InitialExchangeList^[Address][5]) and
        (TempBytes[6] = InitialExchangeList^[Address][6]) and
        (TempBytes[7] = InitialExchangeList^[Address][7]) and
        (TempBytes[8] = InitialExchangeList^[Address][8]) then
        begin
          GetInitialExchangeIndex := Address; // Found it!!
          Exit;
        end;
  }
    { Not found in the list.  Add it to end if there is room. }

  if NumberInitialExchanges < MaxInitialExchanges then
  begin
      //      inc(NumberInitialExchanges);
      //      InitialExchangeList^[NumberInitialExchanges] := TempBytes;
      //      GetInitialExchangeIndex := NumberInitialExchanges;
  end;
end;

procedure AddCallToPartialList(Call: CallString; InitialExchange: CallString);

//var
  //ProperAddress                         : integer;
 // Index, BlockNumber, BlockAddress      : integer;

begin
 {
    ProperAddress := FindProperPartialCallAddress(Call);

    if GetPartialCall(ProperAddress) = Call then
      begin
        BlockNumber := ProperAddress div FourByteBlockSize + 1;
        BlockAddress := ProperAddress mod FourByteBlockSize;

        Index := GetInitialExchangeIndex(InitialExchange);

        PartialCallList[BlockNumber]^[BlockAddress].InitialExchangeIndex := Index;
        Exit;
      end;

    SqueezeInPartialCall(Call, InitialExchange, ProperAddress);
   }
end;
{
function GetInitialExchange(Call: CallString): CallString;
// This procedure will return the initial exchange for the callsign passed  to it.  If there is no initial exchange, a null string will be returned.
var
  CallIndex                        : integer;
begin

  if FindStringInInitCallsignListBox(Call, CallIndex) then
    begin
      CallIndex := SendMessage(IntitialExCallsignsList, LB_GETITEMDATA, CallIndex, 0);
      SetLength(Result, 12);
      CallIndex := SendMessage(IntitialExExchangesList, LB_GETTEXT, CallIndex, integer(@Result[1]));
      if CallIndex = LB_ERR then
        SetLength(Result, CallIndex);
    end
  else
    Result := '';
end;
}

function CallNotInPossibleCallList(Call: CallString;
  PossCallList: PossibleCallRecord): boolean;

var
  Entry                                 : integer;

begin
  CallNotInPossibleCallList := True;

  if PossCallList.NumberPossibleCalls = 0 then Exit;

  for Entry := 0 to PossCallList.NumberPossibleCalls - 1 do
    if Call = PossCallList.List[Entry].Call then
    begin
      CallNotInPossibleCallList := False;
      Exit;
    end;
end;
{
procedure DupeAndMultSheet.MakePartialCallList(Call: CallString;
  ActiveBand: BandType;
  ActiveMode: ModeType;
  var PossCallList: PossibleCallRecord);

var
  Address                          : integer;
  TempCall                         : CallString;

begin
  PossCallList.NumberPossibleCalls := 0;
  PossCallList.CursorPosition := 0;

  if not PartialCallEnable then Exit;
  if length(Call) < 2 then Exit;

  if NumberTwoLetterPartialCalls > 0 then
    for Address := 0 to NumberTwoLetterPartialCalls - 1 do
      begin
        TempCall := GetPartialCall(TwoLetterCrunchPartialCallList[Address]);

        if pos(Call, TempCall) <> 0 then
          if CallNotInPossibleCallList(TempCall, PossCallList) then
            begin
              PossCallList.List[PossCallList.NumberPossibleCalls].Call := TempCall;
              PossCallList.List[PossCallList.NumberPossibleCalls].Dupe :=
                CallIsADupe(TempCall, ActiveBand, ActiveMode);

              inc(PossCallList.NumberPossibleCalls);
              if PossCallList.NumberPossibleCalls > 12 then Exit;
            end;
      end;
end;
}

function PointsToBigCall(Entry: FourBytes): boolean;

begin
  PointsToBigCall := (Entry[1] = 255) and (Entry[4] = 255);
end;

procedure ConvertBigEntryAddressToFourBytes(EntryPointer: integer; var BigEntry: FourBytes);

begin
  BigEntry[1] := 255;
  BigEntry[2] := EntryPointer mod 256;
  BigEntry[3] := EntryPointer div 256;
  BigEntry[4] := 255;
end;

function BigEntryAddress(Entry: FourBytes): integer;

{ Converts big entry string found in the entry list to an address where
  the entry can be found in the BigEntryList.  Starts at zero.  If there
  is an error, it will return with -1.                                   }

begin
  BigEntryAddress := (Entry[3] * 256) + Entry[2];
end;

procedure ClearContestExchange(var Exchange: ContestExchange);

begin
  logger.Trace('>>> Entering ClearContestExchange');
  Windows.ZeroMemory(@Exchange, SizeOf(ContestExchange));
  Exchange.Band := NoBand;
  Exchange.Mode := NoMode;
  Exchange.ExtMode := eNoMode;
  Exchange.NumberReceived := -1;
  Exchange.NumberSent := -1;
  Exchange.Prefecture := MAXBYTE;
  Exchange.QTH.Zone := DUMMYZONE;
  Exchange.Zone := DUMMYZONE;
//  Exchange.PrefixMult := False;
  Exchange.QTH.Continent := UnknownContinent;
  Exchange.QTH.Country := UNKNOWN_COUNTRY;
  Exchange.TenTenNum := MAXWORD;
  Exchange.ceContest := Contest;
end;

function GetNumber(Call: CallString): Char;

var
  TempString, NumberString              : CallString;

begin
  GetNumber := '0';

  if (Call = '') or not StringHasNumber(Call) then Exit;

  TempString := GetPrefix(Call);

  NumberString := '';

  while (TempString <> '') and
    (Copy(TempString, length(TempString), 1) >= '0') and
    (Copy(TempString, length(TempString), 1) <= '9') do
  begin
    NumberString := Copy(TempString, length(TempString), 1) + NumberString;
    Delete(TempString, length(TempString), 1);
  end;

  GetNumber := NumberString[1];
end;

procedure GetDXQTH(var RXData: ContestExchange);

//var
  //ID                                    : string[6];
  //NumberChar                            : Char; {KK1L: 6.70}

begin
  if not CountDomesticCountries then
  begin
    if ActiveDomesticMult = WYSIWYGDomestic then
      if RXData.DomesticQTH <> '' then Exit;

    if DomesticCountryCall(RXData.Callsign) then Exit;
  end;

//R3DSS/E9
  case ActiveDXMult of

//    NoCountDXMults:      RXData.DXQTH := RXData.QTH.CountryID; { 6.60 }

    NoDXMults:
      {RXData.DXQTH := RXData.QTH.CountryID}; { 6.30 }

    ARRLDXCCWithNoUSAOrCanada, CQDXCCWithNoUSAOrCanada:
      if (RXData.QTH.CountryID <> 'K') and (RXData.QTH.CountryID <> 'VE') then
        RXData.DXQTH := RXData.QTH.CountryID;

    ARRLDXCCWithNoARRLSections:
      if pos(' ' + RXData.QTH.CountryID + ' ', ARRLSectionCountryString) = 0 then
        RXData.DXQTH := RXData.QTH.CountryID;

    ARRLDXCCWithNoUSACanadaKH6OrKL7:
      if (RXData.QTH.CountryID <> 'K') and (RXData.QTH.CountryID <> 'VE') and
        (RXData.QTH.CountryID <> 'KH6') and (RXData.QTH.CountryID <> 'KL') then
        RXData.DXQTH := RXData.QTH.CountryID;

    ARRLDXCCWithNoIOrIS0:
//      if (RXData.QTH.CountryID <> 'I') and (RXData.QTH.CountryID <> 'IS') and (RXData.QTH.CountryID <> 'IT9') then
      if RXData.QTH.CountryID[1] <> 'I' then
        RXData.DXQTH := RXData.QTH.CountryID;

    CQDXCCWithNoHB9: if RXData.QTH.CountryID <> 'HB' then RXData.DXQTH := RXData.QTH.CountryID;
    CQDXCCWithNoOK: if RXData.QTH.CountryID <> 'OK' then RXData.DXQTH := RXData.QTH.CountryID;
    ARRLDXCCWithNoJT: if RXData.QTH.CountryID <> 'JT' then RXData.DXQTH := RXData.QTH.CountryID;

    NorthAmericanARRLDXCCWithNoUSACanadaOrkL7:
      if (RXData.QTH.Continent = NorthAmerica) then
        if (RXData.QTH.CountryID <> 'K') and
          (RXData.QTH.CountryID <> 'VE') and
          (RXData.QTH.CountryID <> 'KL') then
          RXData.DXQTH := RXData.QTH.CountryID;

    CQEuropeanCountries:
      if (RXData.QTH.Continent = Europe) then
        RXData.DXQTH := RXData.QTH.CountryID;

    CQUBAEuropeanCountries:
      if UBACountry(RXData.QTH.CountryID) then
        RXData.DXQTH := RXData.QTH.CountryID;

    CQNonEuropeanCountries:
      if (RXData.QTH.Continent <> Europe) then
        RXData.DXQTH := RXData.QTH.CountryID;

    NonSouthAmericanCountries:
      if RXData.QTH.Continent <> SouthAmerica then
        RXData.DXQTH := RXData.QTH.CountryID;

    BlackSeaCountries:
      begin
        if BlackSeaRegionCountry(RXData.QTH.CountryID) then
          RXData.DXQTH := RXData.QTH.CountryID;
      end;

    PACCCountriesAndPrefixes:
      begin
        if RXData.QTH.CountryID = 'UA9' then
        begin
          if StringHas(RXData.Callsign, '9') then
            RXData.DXQTH := 'UA9'
          else
            RXData.DXQTH := 'UA0';

          Exit;
        end;

        if (RXData.QTH.CountryID = 'CE') or
          (RXData.QTH.CountryID = 'JA') or (RXData.QTH.CountryID = 'LU') or
          (RXData.QTH.CountryID = 'PY') or (RXData.QTH.CountryID = 'VE') or
          (RXData.QTH.CountryID = 'K') or (RXData.QTH.CountryID = 'VK') or
          (RXData.QTH.CountryID = 'ZS') or (RXData.QTH.CountryID = 'ZL') then
        begin
          RXData.DXQTH := RXData.QTH.CountryID + GetNumber(RXData.Callsign);
          Exit;
        end;

        RXData.DXQTH := RXData.QTH.CountryID;
      end;

  else
    RXData.DXQTH := RXData.QTH.CountryID;
  end;
end;

procedure GetMultsFromLogEntry(LogEntry: Str80; var RXData: ContestExchange);

{ This procedure will look at the log entry string passed to it and
  based upon the active mutliplier flags determine what, if any multipliers
  are contained in the mult string.  Any multipliers found will be returned
  in it's proper variable.  All other variables will be set to the null
  string.                                                                }

//var
  //MultString                            : Str20;
  //Mult, NumberMults                     : integer;
  //MultArray                             : array[1..2] of Str20;

begin

end;

(*procedure TransferLogEntryInfoToContestExchange(LogEntry: Str80; var RXData: ContestExchange);

begin
  ClearContestExchange(RXData);
  RXData.Band := GetLogEntryBand(LogEntry);
  RXData.Mode := GetLogEntryMode(LogEntry);
  RXData.Callsign := GetLogEntryCall(LogEntry);
  GetMultsFromLogEntry(LogEntry, RXData);
  RXData.QTH.Prefix := RXData.Prefix;
end;
*)
function DupeAndMultSheet.AddBigCallAddress(BigCall: EightBytes): integer;

{ This function will return the proper big call array address for the
  big call entered.  If the call already exists in the big call array,
  then its address is returned.  If it does not exist, it is added to
  the end of the array and that address is returned.  This is done to
  eliminate double entries of big calls in this list, saving memory and
  making it easier to determine if a big call is a dupe on any given
  band or mode.                                                      }

//var
 // NumberCalls, NumberDupeBlocks, NumberEntriesInLastBlock, Block, EndAddress{, Address}: integer;
  //MaxAvail                              : integer;

begin

end;

procedure DupeAndMultSheet.AddCompressedCallToDupeSheet(Call: FourBytes; Band: BandType; Mode: ModeType);

{var
  NumberCalls, DupeBlock, BlockAddress  : integer;
  DupeBand                              : BandType;
  DupeMode                              : ModeType;
}
begin
  
end;

procedure DupeAndMultSheet.AddQSOToSheets(RXData: ContestExchangePtr; AddToPartials: boolean);

{ This procedure will take the information from the contest exchange passed
  to it and add the contact to the DupeAndMultSheet.  This is normally done
  with information after it has gone through the EditableWindow or when
  reading in the LOG.DAT file at the start.                               }

//var
//  {MultBand, }TempDOMBand               : BandType;
//  MultMode                              : ModeType;
begin

  if RXData.ceSearchAndPounce then
    inc(tRestartInfo.riQSOByOpMode[SearchAndPounceOpMode])
  else
    inc(tRestartInfo.riQSOByOpMode[CQOpMode]);

  if not RXData.ceClearMultSheet then
//    if RXData.DomesticMult or RXData.DXMult or RXData.PrefixMult or RXData.ZoneMult then
  begin

    if RXData.DomesticMult then
    begin
//        TempDOMBand := RXData.Band;
//        if Contest in [RDA, RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB] then TempDOMBand := All;
//        mo.SetDmMult(RXData.DomMultQTH, TempDOMBand, RXData.Mode);
      mo.SetDmMult(RXData.DomMultQTH, RXData.Band, RXData.Mode);
    end;

    if RXData.DXMult then
    begin
      mo.SetDXMult(RXData.QTH.Country, RXData.Band, RXData.Mode);
    end;

    if RXData.PrefixMult then
    begin
      mo.SetPxMult(RXData.Prefix, RXData.Band, RXData.Mode);
    end;

    if RXData.ZoneMult then
    begin
      mo.SetZnMult(RXData.Zone, RXData.Band, RXData.Mode);
    end;
  end;
end;

function DupeAndMultSheet.TwoLetterCrunchProcess(PartialCall: {Call} string): boolean;

{ This process will work on generating the TwoLetterPartialList based upon
  the input provided.  It will return TRUE if there is a change to the list
  which means there might be changes in the partial call list. }

var
  Address, FirstAddress, LastAddress, NumberCallsToCrunch: integer;
  {GotPartialCall,} TempString            : Str20;
  FileWrite                             : Text;

begin
  TwoLetterCrunchProcess := False; { Assume no changes }

  if length(PartialCall) < 2 then Exit; { We don't do anything yet }
  if NumberPartialCalls = 0 then Exit; { No partial calls to look at }

  { Look to see if we have different first two letters than the last time
    this function was called.  If so, set up a brand new process with an
    empty list of callsigns. }

  if LastTwoLettersCrunchedOn <> Copy(PartialCall, 1, 2) then
  begin
    LastTwoLettersCrunchedOn := Copy(PartialCall, 1, 2);
    LastTwoLetterCrunchedAddress := -1;
    NumberTwoLetterPartialCalls := 0;
    TwoLetterCrunchProcess := True;
    LastPartialCall := PartialCall;
  end;

  { Look to see if we have process the whole list.  If so, then, there isn't
    anything for us to do.  However, if the callsign has changed, we will
    report TRUE so that the partial call list can be recalculated based upon
    the new callsign.  }

  if LastTwoLetterCrunchedAddress >= NumberPartialCalls - 1 then
  begin
    TwoLetterCrunchProcess := PartialCall <> LastPartialCall;
    LastPartialCall := PartialCall;
    Exit;
  end;

  { Now we only care about the first two letters. }

  if length(PartialCall) > 2 then PartialCall := Copy(PartialCall, 1, 2);

  { Wildcard partials means the two letters can show up anywhere in the
    callsign. }

  if WildCardPartials then
  begin
    NumberCallsToCrunch := NumberPartialCalls - LastTwoLetterCrunchedAddress - 1;

      { We will only crunch up to 200 callsigns per call to this process.  Note
        that we might not get to all of them if the operator presses a key. }

//wli ???? ???????????? initial.ex ? ????? ????????    if NumberCallsToCrunch > 200 then NumberCallsToCrunch := 200;

      { Now look through the partial call list, looking for any calls that have
        the partial string in it. }

    for Address := LastTwoLetterCrunchedAddress + 1 to LastTwoLetterCrunchedAddress + NumberCallsToCrunch do
    begin
          {
            if pos(PartialCall, GetPartialCall(Address)) > 0 then
              begin
                if NumberTwoLetterPartialCalls < TwoLetterPartialCallListLength then
                  begin
                    TwoLetterCrunchPartialCallList[NumberTwoLetterPartialCalls] := Address;
                    inc(NumberTwoLetterPartialCalls);
                    TwoLetterCrunchProcess := True; // We have changed the list
                  end;
              end;

            inc(LastTwoLetterCrunchedAddress);
          }
            //            IF NewKeyPressed THEN Exit;  { Went to NewKeyPressed in 6.27 }
    end;
  end

  else
  begin

      { Remember that the partial call list is in alphabetical order.  If we
        find the first and last address that partial calls will be found, our
        job is done.  First, we compute the first address for this partial call. }

//      FirstAddress := FindProperPartialCallAddress(PartialCall);

      { Since we back up one more, if the address is more than zero, decrement
        it by one. }

    if FirstAddress > 0 then dec(FirstAddress);

      { Now we find the last address for any partial calls.  We do this by finding
        the proper address for a call with the last character incremented by one. }
      { Generate a string that has the second character incremented }

    TempString := PartialCall;

    if TempString[2] = 'Z' then
    begin
      TempString[2] := '0';
      TempString[1] := CHR(Ord(TempString[1]) + 1);
          {
                    if TempString[1] > 'Z' then
                      LastAddress := NumberPartialCalls
                    else
                      LastAddress := FindProperPartialCallAddress(TempString);
          }
    end
    else
    begin
      TempString[2] := CHR(Ord(TempString[2]) + 1);
          //          LastAddress := FindProperPartialCallAddress(TempString);
    end;

    for Address := FirstAddress to LastAddress do
    begin
          {
            GotPartialCall := GetPartialCall(Address);

            if pos(PartialCall, GotPartialCall) = 1 then
              begin
                if NumberTwoLetterPartialCalls < TwoLetterPartialCallListLength then
                  begin
                    TwoLetterCrunchPartialCallList[NumberTwoLetterPartialCalls] := Address;
                    inc(NumberTwoLetterPartialCalls);
                    TwoLetterCrunchProcess := True;
                  end;
              end;

            inc(LastTwoLetterCrunchedAddress);
            }
    end;
    LastTwoLetterCrunchedAddress := NumberPartialCalls - 1;
  end;
end;

procedure DupeAndMultSheet.AddCallToVisibleDupeSheet(Callsign: CallString);

var
  SuffixString, NumberString            : CallString;
  NumberChar, Character                 : Char;
  NextRecord, {Remember,} ActiveVDEntry : VDEntryPointer;
  Count                                 : integer;

begin
  //{WLI}    IF MaxAvail <= SizeOf (VDEntry) THEN Exit;

  {    StandardCall := StandardCallFormat (Callsign, True);

      IF StringHas (StandardCall, '/') THEN
          StandardCall := PostcedingString (StandardCall, '/');
  }
  Callsign := RootCall(Callsign);

  NumberString := NumberPartOfString(Callsign);
  NumberChar := NumberString[1];

  if FirstVDEntry = nil then { Set up entries with 1 to 10 }
  begin
    FirstVDEntry := New(VDEntryPointer);
    ActiveVDEntry := FirstVDEntry;

    ActiveVDEntry^.Callsign := '1';
    ActiveVDEntry^.NextEntry := New(VDEntryPointer);

    for Count := 2 to 10 do
    begin
      if Count < 10 then
        Character := CHR(Ord('0') + Count)
      else
        Character := '0';

      ActiveVDEntry := ActiveVDEntry^.NextEntry;

      ActiveVDEntry^.Callsign := Character;

      if Character <> '0' then
        ActiveVDEntry^.NextEntry := New(VDEntryPointer)
      else
        ActiveVDEntry^.NextEntry := nil;
    end;

    NumberVDCalls := 10;
  end;

  ActiveVDEntry := FirstVDEntry;

  while ActiveVDEntry^.Callsign <> NumberChar do
    if ActiveVDEntry^.NextEntry = nil then
    begin
      ActiveVDEntry^.NextEntry := New(VDEntryPointer);
      ActiveVDEntry := ActiveVDEntry^.NextEntry;

      ActiveVDEntry^.Callsign := Callsign;
      ActiveVDEntry^.NextEntry := nil;
      inc(NumberVDCalls);
      Exit;
    end
    else
      ActiveVDEntry := ActiveVDEntry^.NextEntry;

  { We have found the Number Entry that matches the call we are adding. }

  if ActiveVDEntry^.NextEntry = nil then { Adding the 1st 0 call? }
  begin
    if ActiveVDEntry^.Callsign <> '0' then
    begin
          //      SetWindow(WholeScreenWindow);
               //{WLI}            ClrScr;
      ShowMessage('Not finding zero at end visible dupesheet list!!');
      logger.Fatal('Not finding zero at end visible dupesheet list!!');
      halt;
    end;

    ActiveVDEntry^.NextEntry := New(VDEntryPointer);
    ActiveVDEntry := ActiveVDEntry^.NextEntry;

    ActiveVDEntry^.Callsign := Callsign;
    ActiveVDEntry^.NextEntry := nil;
    inc(NumberVDCalls);
    Exit; { All done - 1st 0 call added }
  end;

  { See if it is the first for this number }

  NextRecord := ActiveVDEntry^.NextEntry;

  if (length(NextRecord^.Callsign) = 1) and StringIsAllNumbers(ActiveVDEntry^.Callsign) then
  begin
    ActiveVDEntry^.NextEntry := New(VDEntryPointer);

    ActiveVDEntry := ActiveVDEntry^.NextEntry;
    ActiveVDEntry^.Callsign := Callsign;
    ActiveVDEntry^.NextEntry := NextRecord;
    inc(NumberVDCalls);
    Exit;
  end;

  { We have to find the right place to squeeze it }

  SuffixString := GetSuffix(Callsign);

  while (SuffixString > GetSuffix(NextRecord^.Callsign)) and
    (length(NextRecord^.Callsign) > 1) and
    (ActiveVDEntry^.NextEntry <> nil) do
  begin
    ActiveVDEntry := NextRecord;
    NextRecord := ActiveVDEntry^.NextEntry;
    if NextRecord = nil then Break; {added by wli}
  end;

  if NextRecord <> nil then {added by wli}
  begin {added by wli}
    if (ActiveVDEntry^.NextEntry = nil) and (SuffixString > GetSuffix(NextRecord^.Callsign)) then
    begin
      ActiveVDEntry := NextRecord;

      ActiveVDEntry^.NextEntry := New(VDEntryPointer);
      ActiveVDEntry := ActiveVDEntry^.NextEntry;
      ActiveVDEntry^.Callsign := Callsign;
      ActiveVDEntry^.NextEntry := nil;
      Exit;
    end;
  end; {added by wli}

  ActiveVDEntry^.NextEntry := New(VDEntryPointer);

  ActiveVDEntry := ActiveVDEntry^.NextEntry;
  ActiveVDEntry^.Callsign := Callsign;
  ActiveVDEntry^.NextEntry := NextRecord;
  inc(NumberVDCalls);
end;
{
procedure DupeAndMultSheet.CreateVisibleDupeSheetArrays(var Band: BandType;
  Mode: ModeType);

var
  Block, NumberBlocks, NumberEntriesInLastBlock, TargetAddress: integer;
  CallAddress                      : integer;
  Callsign                         : string; //Str80; //WLI
  CompressedCall                   : FourBytes;
  BigCompressedCall                : EightBytes;
  NextEntry, ActiveVDEntry         : VDEntryPointer;
  TempInt                          : integer;
  tempEightByteBlockArray          : EightByteBlockArray;
begin
  NumberVDCalls := 0;

  ActiveVDEntry := FirstVDEntry;

  while ActiveVDEntry <> nil do
    begin
      NextEntry := ActiveVDEntry^.NextEntry;
      Dispose(ActiveVDEntry);
      ActiveVDEntry := NextEntry;
    end;

  FirstVDEntry := nil;

  if (Mode = NoMode) or (DupeSheet.Totals[Band, Mode] = 0) then Exit;

  NumberBlocks := (DupeSheet.Totals[Band, Mode] - 1) div FourByteBlockSize + 1;
  NumberEntriesInLastBlock := DupeSheet.Totals[Band, Mode] mod FourByteBlockSize;

  for Block := 1 to NumberBlocks do
    begin
      if Block = NumberBlocks then
        TargetAddress := NumberEntriesInLastBlock
      else
        TargetAddress := FourByteBlockSize;

      for CallAddress := 0 to TargetAddress - 1 do
        begin
          CompressedCall := DupeSheet.DupeList[Band, Mode, Block]^[CallAddress];

          if not PointsToBigCall(CompressedCall) then
            Callsign := ExpandedString(CompressedCall)
          else
            begin
              TempInt := BigEntryAddress(CompressedCall);
              if TempInt > EightByteBlockSize - 1 then Exit;
              //        tempEightByteBlockArray:=          DupeSheet.BigCallList[1]^;
              BigCompressedCall := DupeSheet.BigCallList[1]^[TempInt];
              Callsign := BigExpandedString(BigCompressedCall);
              Callsign := PostcedingString(Callsign, ' ');
              GetRidOfPostcedingSpaces(Callsign);
            end;

          AddCallToVisibleDupeSheet(Callsign);
        end;

    end;
end;
}

procedure DupeAndMultSheet.DisposeOfMemoryAndZeroTotals;

//var
  //Band                                  : BandType;
  //Mode                                  : ModeType;
 // NumberBlocks, Block                   : integer;
  //TempRemainingMultiplierType           : RemainingMultiplierType;
begin

  CallsignsList.ClearDupes;

  mo.ClearAllMults;
{
  for Band := Band160 to AllBands do
    for Mode := CW to Both do
    begin

      if MultSheet.DomesticList[Band, Mode] <> nil then Dispose(MultSheet.DomesticList[Band, Mode]);
      if MultSheet.DXList[Band, Mode] <> nil then Dispose(MultSheet.DXList[Band, Mode]);
      if MultSheet.PrefixList[Band, Mode] <> nil then Dispose(MultSheet.PrefixList[Band, Mode]);
      if MultSheet.ZoneList[Band, Mode] <> nil then Dispose(MultSheet.ZoneList[Band, Mode]);

      for TempRemainingMultiplierType := rmDomestic to rmZone do
        if RemMultMatrix[Band, Mode, TempRemainingMultiplierType] <> nil then
        begin
//          showint(integer(RemMultMatrix[Band, Mode, TempRemainingMultiplierType]));
//          ShowMessage(BandStringsArrayWithOutSpaces[Band]);
//          ShowMessage(ModeString[Mode]);
//          showint(integer(TempRemainingMultiplierType));
          Dispose(RemMultMatrix[Band, Mode, TempRemainingMultiplierType]);
        end;

    end;

  Windows.ZeroMemory(@RemMultMatrix, SizeOf(RemMultMatrix));
}
  Windows.ZeroMemory(@QSOTotals, SizeOf(QSOTotals));
  Windows.ZeroMemory(@MaxSerialSent, SizeOf(MaxSerialSent));  // Issue #954: rebuilt by LoadinLog
  Windows.ZeroMemory(@ContinentQSOCount, SizeOf(ContinentQSOCount));

//  Windows.ZeroMemory(@MultSheet, SizeOf(MultSheet));

  if QTCsEnabled then
  begin
    if QTCDataArray <> nil then Windows.ZeroMemory(QTCDataArray, SizeOf(QTCDataArrayType));
    NumberQTCBooksSent := 0;
    NumberQTCStations := 0;
    TotalNumberQTCsProcessed := 0;
  end;

  TotalQSOPoints := 0;
  MOQSOPartyW0MAWorked := False;
  MOQSOPartyK0GQWorked := False;
  MOQSOPartyPeakHourCount := 0;
  TotalNamesSent := 0;
  tRestartInfo.riTotalRecordsInLog := 0;
  tUSQ := 0;
  tUSQE := 0;
  Windows.ZeroMemory(@tRestartInfo.riQSOByOpMode, SizeOf(tRestartInfo.riQSOByOpMode));
  tThisHourPreviousBand := NoBand;
end;

procedure CheckMOQSOPartyBonusStation(const Callsign: CallString);
begin
   if Callsign = 'W0MA' then
      MOQSOPartyW0MAWorked := True;
   if Callsign = 'K0GQ' then
      MOQSOPartyK0GQWorked := True;
end;

procedure DupeAndMultSheet.DupeSheetTotals(var Totals: QSOTotalArray);

begin
  //  Totals := DupeSheet.Totals;
end;

procedure DupeAndMultSheet.ExamineLogForQSOTotals(var QTotals: QSOTotalArray);

//var
  //FileRead                              : Text;
 // TempString                            : string {Str80}; {WLI}
//  Band                                  : BandType;
 // Mode                                  : ModeType;

begin

end;

procedure EnumInitialEx(FileString: PShortString);

var
  InitialExchangeString                 : ShortString;
  Call                                  : Str80;
begin
  if FileString^[1] = ';' then Exit;

  Call := RemoveFirstString(FileString^);
  if FileString^ <> '' then
  begin
    InitialExchangeString := '';
    while FileString^ <> '' do
      InitialExchangeString := InitialExchangeString + RemoveFirstString(FileString^) + ' ';

    GetRidOfPostcedingSpaces(InitialExchangeString);
    if not CallsignsList.AddIniitialExchange(Call, InitialExchangeString) then inc(InitialExDupes);
    inc(InitialExCallsigns);
  end;
end;

procedure LoadInitialExchangeFile;
var
  TempInteger                           : integer;
begin

  if not EnumerateLinesInFile(TR4W_INITIALEX_FILENAME, EnumInitialEx, True) then Exit;
  TempInteger := Format(wsprintfBuffer, '%s:'#13#10 + TC_THEREWERECALLS, TR4W_INITIALEX_FILENAME, InitialExCallsigns, InitialExDupes);
{$IF LANG = 'ENG'}
  if InitialExDupes = 0 then wsprintfBuffer[TempInteger - 11] := #0;
{$IFEND}
  ShowMessage(wsprintfBuffer);
end;

procedure DupeAndMultSheet.MakePossibleCallList(Call: CallString; var PossCallList: PossibleCallRecord);

label
  CallAlreadyInList;

//var
 // Band, StartBand, EndBand              : BandType;
 // Mode, StartMode, EndMode              : ModeType;
 // CallBytes                             : FourBytes;
 // NumberCalls, CallAddress, NumberDupeBlocks, EndAddress, Entry: integer;
  //NumberEntriesInLastBlock, Block       : integer;
  //TempCall                              : Str80;

begin
  {
    if Call = '' then Exit;
    Call := StandardCallFormat(Call, True);

    CompressFormat(Call, CallBytes);

    if QSOByBand then
      begin
        StartBand := Band160;
        EndBand := BandLight;
      end
    else
      begin
        StartBand := All;
        EndBand := All;
      end;

    if QSOByMode then
      begin
        StartMode := CW;
        EndMode := Phone;
      end
    else
      begin
        StartMode := Both;
        EndMode := Both;
      end;

    for Band := StartBand to EndBand do
      for Mode := StartMode to EndMode do
        begin
          NumberCalls := DupeSheet.Totals[Band, Mode];
          if NumberCalls > 0 then
            begin
              NumberDupeBlocks := (NumberCalls - 1) div FourByteBlockSize + 1;
              NumberEntriesInLastBlock := (NumberCalls - 1) mod FourByteBlockSize + 1;

              Block := 1;

              repeat
                if Block = NumberDupeBlocks then
                  EndAddress := NumberEntriesInLastBlock
                else
                  EndAddress := FourByteBlockSize;

                for CallAddress := 0 to EndAddress - 1 do
                  begin
                    if NUMBYTES
                      (Addr(CallBytes), Addr(DupeSheet.DupeList[Band, Mode, Block]^[CallAddress])) >= 2 then
                      begin

                        TempCall := ExpandedString(DupeSheet.DupeList[Band, Mode, Block]^[CallAddress]);
                        if SimilarCall(TempCall, Call) then
                          if PossCallList.NumberPossibleCalls < 12 then
                            begin
                              if PossCallList.NumberPossibleCalls > 0 then
                                for Entry := 0 to PossCallList.NumberPossibleCalls - 1 do
                                  if PossCallList.List[Entry].Call = TempCall then
                                    goto CallAlreadyInList;
                              PossCallList.List[PossCallList.NumberPossibleCalls].Call := TempCall;
                              PossCallList.List[PossCallList.NumberPossibleCalls].Dupe := False;

                              inc(PossCallList.NumberPossibleCalls);
                            end
                          else
                            Exit;
                      end;
                    CallAlreadyInList:
                  end;
                inc(Block);
              until Block > NumberDupeBlocks;
            end;
        end;
  }
end;
{
procedure DupeAndMultSheet.MultSheetTotals(var Totals: MultTotalArrayType);

begin
  Totals := MultSheet.Totals;
end;
}

procedure PutPartialCallInList(Call: CallString;
  InitialExchange: CallString;
  CallAddress: integer);

var
  BlockNumber, BlockAddress             : integer;
  CompressedCall                        : FourBytes;
  Index                                 : Byte;

begin
  BlockNumber := CallAddress div FourByteBlockSize + 1;
  BlockAddress := CallAddress mod FourByteBlockSize;

  if BlockNumber > LastPartialCallBlock then
  begin
      {WLI}
      {        IF MaxAvail < SizeOf (FourByteBlockArray) THEN
                  BEGIN
                  DoABeep (Single);
                  QuickDisplay ('Not enough memory for FourByteBlockArray!!');
                  ReminderPostedCount := 30;
                  Exit;
                  END;
      }
//      if PartialCallList[BlockNumber] = nil then        New(PartialCallList[BlockNumber]);

    LastPartialCallBlock := BlockNumber;
  end;

  CompressFormat(Call, CompressedCall);
  //  PartialCallList[BlockNumber]^[BlockAddress].Call := CompressedCall;

  if ExchangeMemoryEnable then
  begin
    Index := GetInitialExchangeIndex(InitialExchange);
    //         PartialCallList[BlockNumber]^[BlockAddress].InitialExchangeIndex := Index;
  end
  else
    //    PartialCallList[BlockNumber]^[BlockAddress].InitialExchangeIndex := 0;
end;

function DupeAndMultSheet.IsADomesticMult(Mult: Str10; Band: BandType; Mode: ModeType): boolean;

//var
  //NumberMults                           : integer;
  //CompressedMult                        : FourBytes;
 // DomQTH                                : Str20;

begin
  {    IsADomesticMult := False;

      IF Mult = '' THEN Exit;

      IF NOT MultByBand THEN Band := All;
      IF NOT MultByMode THEN Mode := Both;

      IF DoingDomesticMults THEN
          BEGIN
          NumberMults := MultSheet.Totals [Band, Mode].NumberDomesticMults;

          IF NumberMults = 0 THEN
              IsADomesticMult := True
          ELSE
              BEGIN
              CompressFormat (Mult, CompressedMult);

              IF NOT BytDupe (Addr (CompressedMult), NumberMults, MultSheet.DomesticList [Band, Mode]) THEN
                  IsADomesticMult := True;
              END;
          END;
     }
end;

procedure DupeAndMultSheet.SetMultFlags(var RXData: ContestExchange);
label
  SkipDomesticMult;
{ This procedure will look at the contest exchange passed to it and see
  if any multiplier flags should be set.  No updating of multiplier arrays
  of totals is done.        }

var
  //Mult, NumberMults                     : integer;
 // TempBand                              : BandType;
  MultBand                              : BandType;
  MultMode                              : ModeType;
  //CompressedMult                        : FourBytes;
  //DomQTH                                : Str20;
 // c                                     : integer;

begin
   logger.Trace('>>> Entering DupeAndMultSheet.SetMultFlags');
   if logger.IsDebugEnabled then
      begin
      logger.debug('DoingDomesticMults = ' + BooleanToStr(DoingDomesticMults));
      logger.debug('DoingDXMults       = ' + BooleanToStr(DoingDXMults));
      logger.debug('DoingPrefixMults   = ' + BooleanToStr(DoingPrefixMults));
      logger.debug('DoingZoneMults     = ' + BooleanToStr(DoingZoneMults));
      end;

  if RXData.ceClearMultSheet then Exit;
  RXData.DomesticMult := False;
  RXData.DXMult := False;
  RXData.PrefixMult := False;
  RXData.ZoneMult := False;

  if MultByBand then MultBand := RXData.Band else MultBand := AllBands;
  if MultByMode then MultMode := RXData.Mode else MultMode := Both;

  if (RXData.DomMultQTH = '') and (RXData.DomesticQTH <> '') then
    RXData.DomMultQTH := RXData.DomesticQTH;

  SkipDomesticMult:
  if (Contest = BCQP) and (RXData.DomMultQTH = 'dx') then         // 4.98.2
    exit;   // no mults for dx
  if (Contest = NYQP) and (RXData.DomMultQTH = 'DX') then         // 4.116.5
    exit;
   if (Contest = INQSOPARTY) and (RXData.DomMultQTH = 'DX') then         // 4.116.5
     exit;
  if (RXData.DomMultQTH <> '') and DoingDomesticMults then
    RXData.DomesticMult := mo.IsDmMult(RXData.DomMultQTH, GetAddMultBand(DomesticMultByBand, MultBand), MultMode, ActiveDomesticMult);

  if (RXData.DXQTH <> '') and DoingDXMults {and (ActiveDXMult <> NoCountDXMults)} then
 // if (activeqsopointmethod = DLRTTY then
    RXData.DXMult := mo.IsDXMult(RXData.QTH.Country, GetAddMultBand(DXCCMultByBand, MultBand), MultMode);

   if (RXData.Prefix <> '') and DoingPrefixMults then
      begin        // 4.83.6
      if (contest = PCC) and
         (RXData.QTH.CountryID = MyCountry) then
         begin
         RXData.PrefixMult := False
         end
      else
         begin
         RXData.PrefixMult := mo.IsPxMult(RXData.Prefix, MultBand, MultMode);
         end;
      end;
    if (Contest = NZFIELDDAY) then
    if (RXData.Zone = StrToInt(MyZone)) or (RXData.Zone = 00) then   exit;  //n4af 4.41.6


  if (RXData.Zone <> DUMMYZONE) and DoingZoneMults then              // n4af 4.42.1
     RXData.ZoneMult := mo.IsZnMult(RXData.Zone, MultBand, MultMode);
end;

procedure DupeAndMultSheet.SaveRestartFile;

var
 // Band                                  : BandType;
 // Mode                                  : ModeType;
  FileWrite                             : HWND;
 // Block, Result{, NumberBlocks}           : integer;

begin

  if not tOpenFileForWrite(FileWrite, TR4W_RST_FILENAME) then Exit;

//TF.sWriteFile()

//  Assign(FileWrite, TR4W_RST_FILENAME);
//  ReWrite(FileWrite, 1);

  sWriteFile(FileWrite, RestartVersionNumber, SizeOf(RestartVersionNumber));
  sWriteFile(FileWrite, ContestName, SizeOf(ContestName));

  sWriteFile(FileWrite, Radio1.BandMemory, SizeOf(BandType));
  sWriteFile(FileWrite, Radio2.BandMemory, SizeOf(BandType));
  sWriteFile(FileWrite, Radio1.ModeMemory, SizeOf(ModeType));
  sWriteFile(FileWrite, Radio2.ModeMemory, SizeOf(ModeType));
  sWriteFile(FileWrite, Radio1.SpeedMemory, SizeOf(integer)); {KK1L: 6.73}
  sWriteFile(FileWrite, Radio2.SpeedMemory, SizeOf(integer)); {KK1L: 6.73}

//  BlockWrite(FileWrite, QSOTotals, SizeOf(QSOTotals), Result);
//  BlockWrite(FileWrite, TotalNamesSent, SizeOf(TotalNamesSent), Result);
//  BlockWrite(FileWrite, TotalQSOPoints, SizeOf(TotalQSOPoints), Result);
//  BlockWrite(FileWrite, MultByBand, SizeOf(MultByBand), Result);
//  BlockWrite(FileWrite, MultByMode, SizeOf(MultByMode), Result);
//  BlockWrite(FileWrite, TakingABreak, SizeOf(TakingABreak), Result);
//  BlockWrite(FileWrite, TotalOffTime, SizeOf(TotalOffTime), Result);
//  BlockWrite(FileWrite, OffTimeStart, SizeOf(OffTimeStart), Result);

//  BlockWrite(FileWrite, ContinentQSOCount, SizeOf(ContinentQSOCount), Result);
//  BlockWrite(FileWrite, TimeSpentByBand, SizeOf(TimeSpentByBand), Result);

  sWriteFile(FileWrite, LastCQFrequency, SizeOf(LastCQFrequency)); {KK1L: 6.68}
  sWriteFile(FileWrite, LastCQMode, SizeOf(LastCQMode)); {KK1L: 6.68}

  sWriteFile(FileWrite, RemainingMultDisplay, SizeOf(RemainingMultDisplay));
{
  with MultSheet do
  begin
    BlockWrite(FileWrite, Totals, SizeOf(Totals), RESULT);

    for Band := Band160 to All do
      for Mode := CW to Both do
        if (((MultByBand) and (Band <> All)) or
          ((not MultByBand) and (Band = All))) and
          (((MultByMode) and (Mode <> Both)) or
          ((not MultByMode) and (Mode = Both))) then
        begin
          if Totals[Band, Mode].NumberDomesticMults > 0 then BlockWrite(FileWrite, DomesticList[Band, Mode]^, SizeOf(DomesticList[Band, Mode]^), RESULT);
          if Totals[Band, Mode].NumberDXMults > 0 then BlockWrite(FileWrite, DXList[Band, Mode]^, SizeOf(DXList[Band, Mode]^), RESULT);
          if Totals[Band, Mode].NumberPrefixMults > 0 then BlockWrite(FileWrite, PrefixList[Band, Mode]^, SizeOf(PrefixList[Band, Mode]^), RESULT);
          if Totals[Band, Mode].NumberZoneMults > 0 then BlockWrite(FileWrite, ZoneList[Band, Mode]^, SizeOf(ZoneList[Band, Mode]^), RESULT);
        end;
  end;
}
//  for Band := Band160 to Band2 do    for Mode := CW to Phone do      BlockWrite(FileWrite, FreqMemory[Band, Mode], SizeOf(FreqMemory[Band, Mode]), RESULT);
  sWriteFile(FileWrite, FreqMemory, SizeOf(FreqMemory));
  sWriteFile(FileWrite, tRestartInfo, SizeOf(RestartInfo));
  sWriteFile(FileWrite, CurrentOperator, SizeOf(CurrentOperator));
//  BlockWrite(FileWrite, StackArray, SizeOf(StackArray), RESULT);
//  BlockWrite(FileWrite, StackPointer, SizeOf(StackPointer), RESULT);

  CloseHandle(FileWrite);
end;

function DupeAndMultSheet.ReadInBinFiles {(JustDoIt: boolean)}: boolean;

var
//  FileRead                              : file;
 // Result1, Block, NumberBlocks          : integer;
 // Band                                  : BandType;
 // Mode                                  : ModeType;
  RestartVersion                        : Str10;
  NameOfContest                         : Str80;
  h                                     : HWND;
begin
  DisposeOfMemoryAndZeroTotals;

  ReadInBinFiles := False;
{
  if not JustDoIt then
  begin

  end;
}
  //    Showmessage ('Reading in restart file...');

{$IF MAKE_DEFAULT_VALUES = TRUE}
  Exit;
{$IFEND}

  if not tOpenFileForRead(h, TR4W_RST_FILENAME) then Exit;

  sReadFile(h, RestartVersion, SizeOf(RestartVersion));

  if RestartVersion <> RestartVersionNumber then
  begin
    CloseHandle(h);

    Format(wsprintfBuffer, TC_DIFVERSION, _RESTARTBIN, @RestartVersionNumber[1], @RestartVersion[1]);

    ShowMessage(wsprintfBuffer);
    Exit;
  end;

  sReadFile(h, NameOfContest, SizeOf(ContestName));

  if ContestName = '' then ContestName := NameOfContest;

  if NameOfContest <> ContestName then
  begin
    CloseHandle(h);
    ShowMessage(TC_RESTARTBINISFORADIFFERENTCONTEST);
    Exit;
  end;

  sReadFile(h, Radio1.BandMemory, SizeOf(BandType));
  sReadFile(h, Radio2.BandMemory, SizeOf(BandType));
  sReadFile(h, Radio1.ModeMemory, SizeOf(ModeType));
  sReadFile(h, Radio2.ModeMemory, SizeOf(ModeType));
  sReadFile(h, Radio1.SpeedMemory, SizeOf(integer)); {KK1L: 6.73}
  sReadFile(h, Radio2.SpeedMemory, SizeOf(integer)); {KK1L: 6.73}

//  BlockRead(FileRead, QSOTotals, SizeOf(QSOTotals), Result1);
//  BlockRead(FileRead, TotalNamesSent, SizeOf(TotalNamesSent), Result1);
//  BlockRead(FileRead, TotalQSOPoints, SizeOf(TotalQSOPoints), Result1);

//  BlockRead(FileRead, MultByBand, SizeOf(MultByBand), Result1);
//  BlockRead(FileRead, MultByMode, SizeOf(MultByMode), Result1);
//  BlockRead(FileRead, TakingABreak, SizeOf(TakingABreak), Result1);
//  BlockRead(FileRead, TotalOffTime, SizeOf(TotalOffTime), Result1);
//  BlockRead(FileRead, OffTimeStart, SizeOf(OffTimeStart), Result1);

//  BlockRead(FileRead, ContinentQSOCount, SizeOf(ContinentQSOCount), Result1);
//  BlockRead(FileRead, TimeSpentByBand, SizeOf(TimeSpentByBand), Result1);

  sReadFile(h, LastCQFrequency, SizeOf(LastCQFrequency)); {KK1L: 6.68}
  sReadFile(h, LastCQMode, SizeOf(LastCQMode)); {KK1L: 6.68}

//  if BandMemory[RadioOne] >= All then BandMemory[RadioOne] := Band160;
//  if BandMemory[RadioTwo] >= All then BandMemory[RadioTwo] := Band160;

//  if ModeMemory[RadioOne] >= Both then ModeMemory[RadioOne] := CW;
//  if ModeMemory[RadioTwo] >= Both then ModeMemory[RadioTwo] := CW;

  ActiveBand := Radio1.BandMemory {BandMemory[RadioOne]};
  ActiveMode := Radio1.ModeMemory {ModeMemory[RadioOne]};
  BandMapBand := ActiveBand; {KK1L: 6.68 gets BM in sync when no radio connected}
  BandMapMode := ActiveMode; {KK1L: 6.68 gets BM in sync when no radio connected}

  sReadFile(h, RemainingMultDisplay, SizeOf(RemainingMultDisplay));

//  for Band := Band160 to Band2 do    for Mode := CW to Phone do      BlockRead(FileRead, FreqMemory[Band, Mode], SizeOf(FreqMemory[Band, Mode]), Result1);
  sReadFile(h, FreqMemory, SizeOf(FreqMemory));

  sReadFile(h, tRestartInfo, SizeOf(RestartInfo));
  sReadFile(h, CurrentOperator, SizeOf(CurrentOperator));

//  BlockRead(FileRead, StackArray, SizeOf(StackArray), Result1);
//  BlockRead(FileRead, StackPointer, SizeOf(StackPointer), Result1);

//  SetLogColumnsWidth;

  CloseHandle(h);

  ReadInBinFiles := True;
  {CodeSpeed := RadioOneSpeed;}
  CodeSpeed := Radio1.SpeedMemory; {KK1L: 6.73}
end;

procedure DupeAndMultSheet.SheetInitAndLoad;

{ This procedure will load in the LOG.DAT file and fill up all the sheets
  with the right stuff.  Make sure that QSOByBand, QSOByMode and the
  active multiplier globals are setup before executing this.         }

begin
  ReadInBinFiles;
  {?? ??????}
//  SetUpRemainingMultiplierArrays;
  LoadInitialExchangeFile;
  LoadinLog;
end;

procedure SetUpExchangeInformation(ActiveExchange: ExchangeType; var ExchangeInformation: ExchangeInformationRecord);

begin
  //windows.ZeroMemory(@ExchangeInformation,sizeof(ExchangeInformation));

  with ExchangeInformation do
  begin
    Age := False;
    Chapter := False;
    Check := False;
    ClassEI := False;
//    FOCNumber := False;
    Name := False;
//    PostalCode := False;
    Power := False;
    Precedence := False;
    QSONumber := False;
    QTH := False;
    RandomChars := False;
    RST := False;
    Zone := False;
    ZoneOrSociety := False;
  end;

  case ActiveExchange of
    CheckAndChapterOrQTHExchange:
      begin
        ExchangeInformation.Chapter := True;
        ExchangeInformation.Check := True;
        ExchangeInformation.QTH := True;
      end;

    ClassDomesticOrDXQTHExchange:
      begin
        ExchangeInformation.ClassEI := True;
        ExchangeInformation.QTH := True;
      end;

    KidsDayExchange:
      begin
        ExchangeInformation.Kids := True;
      end;

    RSTAndContinentExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
      end;

    NameQTHAndPossibleTenTenNumber:
      begin
        ExchangeInformation.Name := True;
        ExchangeInformation.QTH := True;
        ExchangeInformation.TenTenNum := True;
      end;

    NameAndDomesticOrDXQTHExchange:
      begin
        ExchangeInformation.Name := True;
        ExchangeInformation.QTH := True;
      end;

    NameAndPossibleGridSquareExchange:
      begin
        ExchangeInformation.Name := True;
        ExchangeInformation.QTH := True;
      end;

    NZFieldDayExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Zone := True;
      end;
  
    QSONumberAndCoordinatesSum, QSONumberAndGeoCoordinates:
      begin
        ExchangeInformation.QTH := True;
        ExchangeInformation.QSONumber := True;
      end;

    QSONumberAndPreviousQSONumber:
      begin
//        ExchangeInformation.RandomChars := True;
        ExchangeInformation.QSONumber := True;
      end;

    QSONumberAndZone:
      begin
        ExchangeInformation.Zone := True;
        ExchangeInformation.QSONumber := True;
      end;

    QSONumberAndNameExchange:
      begin
        ExchangeInformation.Name := True;
        ExchangeInformation.QSONumber := True;
      end;
    QSONumberAndGridSquare,
      QSONumberDomesticQTHExchange,
      QSONumberDomesticOrDXQTHExchange:
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.QTH := True;
      end;

    QSONumberNameChapterAndQTHExchange:
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Name := True;
        ExchangeInformation.Chapter := True;
        ExchangeInformation.QTH := True;
      end;

    QSONumberNameDomesticOrDXQTHExchange:
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Name := True;
        ExchangeInformation.QTH := True;
      end;

    QSONumberPrecedenceCheckDomesticQTHExchange:
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Precedence := True;
        ExchangeInformation.Check := True;
        ExchangeInformation.QTH := True;
      end;

    AgeAndQSONumberExchange:
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Age := True;
      end;

    QSONumberAndAgeExchange:             // 4.119.1
      begin
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.Age := True;
      end;
    RSTAndPOTAPark:
       begin
       ExchangeInformation.RST := true;
       ExchangeInformation.QTH := true;
       end;
       
    RSTAgeAndPossibleSK:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Age := True;
        ExchangeInformation.QTH := True;
      end;

    RSTAgeExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Age := True;
      end;

    RSTALLJAPrefectureAndPrecedenceExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Precedence := True;
        ExchangeInformation.QTH := True;
      end;

    RSTPossibleDomesticQTHAndPower:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
        ExchangeInformation.Power := True;
      end;

    Grid2Exchange:
      begin
        ExchangeInformation.QTH := True;
      end;

      RSTAndGrid3Exchange:      // 4.96.3
      begin
        ExchangeInformation.QTH := True;
      end;

       GridExchange:
      begin
        ExchangeInformation.QTH := True;
      end;

    RSTAndOrGridExchange, RSTAndGridExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
      end;

    RSTAndPostalCodeExchange:
      begin
        ExchangeInformation.RST := True;
//        ExchangeInformation.PostalCode := True;
        ExchangeInformation.QTH := True;
      end;

    RSTQTHExchange,
      RSTDomesticOrDXQTHExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
      end;

    RSTDomesticQTHExchange,
      RSTPrefectureExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
        ExchangeInformation.QSONumber := True;  // 4.97.5
      end;

    QSONumberAndPossibleDomesticQTHExchange, RSTDomesticQTHOrQSONumberExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.QTH := True;
      end;

    RSTNameAndQTHExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Name := True;
        ExchangeInformation.QTH := True;
      end;
  RSTAndFOCNumberExchange:
  begin
  ExchangeInformation.RST := True;
  ExchangeInformation.Power := True;
  end;

    RSTPowerExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Power := True;
      end;
    {WLI-DUBLICATE}
    {        NZFieldDayExchange:
                BEGIN
                ExchangeInformation.RST := True;
                ExchangeInformation.QSONumber := True;
                ExchangeInformation.Zone := True;
                END;
    }
    RSTQSONumberExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QSONumber := True;
      end;

    RSTAndQSONumberOrFrenchDepartmentExchange,
    RSTQSONumberOrDomesticQTHExchange, //n4af 04.40.5
      RSTQSONumberAndPossibleDomesticQTHExchange,
      RSTQSONumberAndDomesticQTHExchange,
      RSTQSONumberAndGridSquareExchange,
      RSTAndQSONumberOrDomesticQTHExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QSONumber := True;
        ExchangeInformation.QTH := True;
      end;

    RSTQTHNameAndFistsNumberOrPowerExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
        ExchangeInformation.Name := True;
        ExchangeInformation.Power := True;
        ExchangeInformation.QSONumber := True;
      end;

    RSTQSONumberAndRandomCharactersExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.RandomChars := True;
        ExchangeInformation.QSONumber := True;
      end;

    RSTZoneAndPossibleDomesticQTHExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Zone := True;
        ExchangeInformation.QTH := True;
      end;

    RSTZoneExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Zone := True;
      end;

    RSTZoneOrSocietyExchange:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
        ExchangeInformation.Zone := True;
      end;

    RSTLongJAPrefectureExchange: {KK1L: 6.72}
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.QTH := True;
      end;
      RSTZoneOrDomesticQTH:
      begin
        ExchangeInformation.RST := True;
        ExchangeInformation.Zone := True;
        ExchangeInformation.QTH := True;
      end;
  end;

end;

function ParseExchangeIntoContestExchange(LogEntry: string;
  var RXData: ContestExchange): boolean;

{ Returns TRUE if it looks like a good QSO }

var
  ExchangeString                        : ShortString {Str80}; {WLI}

begin
  ParseExchangeIntoContestExchange := False;
  logger.debug('Entering ParseEchangeIntoCOntestExchange with LogEntry = (%s)',[LogEntry]);

  ClearContestExchange(RXData);

  { See if it is a note }

  if Copy(LogEntry, 1, 1) = ';' then Exit;

  RXData.Callsign := GetLogEntryCall(LogEntry);
  RXData.Band := GetLogEntryBand(LogEntry);
  RXData.Mode := GetLogEntryMode(LogEntry);
  SetExtendedModeFromMode(RXData);
  RXData.QSOPoints := GetLogEntryQSOPoints(LogEntry);
  //  RXData.Date := GetLogEntryDateString(LogEntry);
  //  RXData.Time := GetLogEntryIntegerTime(LogEntry);

  if (RXData.Band = NoBand) or (RXData.Mode = NoMode) then Exit;

  ExchangeString := GetLogEntryExchangeString(LogEntry);

  if ExchangeInformation.RST then
  begin
    RXData.RSTSent := StrToInt(RemoveFirstString(ExchangeString));

      { Sometimes the received RST is optional, so I only pull it
        off if it appears to be all there (numbers only). }

    if StringIsAllNumbers(GetFirstString(ExchangeString)) then
      RXData.RSTReceived := StrToInt(RemoveFirstString(ExchangeString));
  end;


  if (ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange) then {KK1L: 6.70 for FISTS funny exchange}
  begin

    RXData.QTHString := RemoveFirstString(ExchangeString);
    RXData.Name := RemoveFirstString(ExchangeString);
      {KK1L: 6.70 The power/number is right where the mults usually go}
    RXData.Power := GetLogEntryMultString(LogEntry); {KK1L: 6.70 I use power string for either number or power}
  end

  else {KK1L: 6.70 What follows is what was always here!}
  begin
    if ExchangeInformation.ClassEI then
      RXData.ceClass := RemoveFirstString(ExchangeString);

      { Sometimes the QSO number is optional - so only pull it off the
        exchange if it looks like it is there. }

    if ExchangeInformation.QSONumber and StringIsAllNumbers(GetFirstString(ExchangeString)) then
      RXData.NumberReceived := RemoveFirstLongInteger(ExchangeString);

    if ExchangeInformation.RandomChars then
    begin
      RXData.RandomCharsSent := RemoveFirstString(ExchangeString); { added in 6.27 }
      RXData.RandomCharsReceived := RemoveFirstString(ExchangeString);
    end;
{
    if ExchangeInformation.PostalCode then
    begin
      RXData.PostalCode := RemoveFirstString(ExchangeString) + ' ' + RemoveFirstString(ExchangeString);
    end;
}
    if ExchangeInformation.Power then
      RXData.Power := RemoveFirstString(ExchangeString);

    if ExchangeInformation.Age then
      RXData.Age := StrToInt(RemoveFirstString(ExchangeString));

    if ExchangeInformation.Name then
      RXData.Name := RemoveFirstString(ExchangeString);

    if ExchangeInformation.Chapter then
      RXData.Chapter := RemoveFirstString(ExchangeString);

    if ExchangeInformation.Precedence then
      RXData.Precedence := RemoveFirstString(ExchangeString)[1];

    if ExchangeInformation.Check then
      RXData.Check := StrToInt(RemoveFirstString(ExchangeString));

    if ExchangeInformation.Zone and StringIsAllNumbersOrSpaces(ExchangeString) then
      RXData.Zone := StrToInt(RemoveFirstString(ExchangeString));

    if ExchangeInformation.QTH then
    begin
      GetRidOfPrecedingSpaces(ExchangeString);
      GetRidOfPostcedingSpaces(ExchangeString);
      RXData.QTHString := ExchangeString;
    end;
  end;

  ParseExchangeIntoContestExchange := True;
end;

procedure DupeInit;

var
  //Block                                 : integer;
  NextEntry, ActiveVDEntry              : VDEntryPointer;
  //Band                                  : BandType;
  //Mode                                  : ModeType;

begin
  //  for Block := 1 to MaxPartialCallBlocks do PartialCallList[Block] := nil;
  ActiveVDEntry := FirstVDEntry;
  while ActiveVDEntry <> nil do
  begin
    NextEntry := ActiveVDEntry^.NextEntry;
    Dispose(ActiveVDEntry);
    ActiveVDEntry := NextEntry;
  end;
end;

function GetInitialExchangeStringFromContestExchange(RData: ContestExchange): Str14;

var
  QString                               : ShortString; {STR40} {WLI}
  TString, TempString                   : string[14];

begin
  GetInitialExchangeStringFromContestExchange := '';
  TempString := '';

  with RData do
  begin

    if ActiveExchange = RSTALLJAPrefectureAndPrecedenceExchange then
    begin
      GetInitialExchangeStringFromContestExchange := Precedence + ' ' + QTHString;
      Exit;
    end;

    if ActiveExchange = RSTDomesticQTHOrQSONumberExchange then
    begin
      QString := QTHString;

      while QString <> '' do
      begin
        TString := RemoveFirstString(QString);

              //wli              if StringHasLowerCase(TString) then
        begin
          GetInitialExchangeStringFromContestExchange := TString;
          Exit;
        end;
      end;
      Exit;
    end;

    if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then
    begin
      GetInitialExchangeStringFromContestExchange := QTHString + ' ' + Name + ' ' + Power;
      Exit;
    end;

    if ActiveExchange = RSTZoneOrSocietyExchange then
    begin
      if QTHString <> '' then
      begin
        GetInitialExchangeStringFromContestExchange := QTHString;
        Exit;
      end;
    end;

     if ActiveExchange = RSTZoneOrDomesticQTH then           // 4.95.6
      begin
       if QTHString <> '' then
        begin
         GetInitialExchangeStringFromContestExchange := QTHString;
        Exit;
       end;
    end;

    if ExchangeInformation.Zone then

      TempString := IntToStr(Zone);

    if ExchangeInformation.Name then TempString := Name;
    if ExchangeInformation.ClassEI then TempString := ceClass;
    if ExchangeInformation.Age then TempString := IntToStr(Age);
    if ExchangeInformation.Check then TempString := IntToStr(Check);

    if ExchangeInformation.Chapter then TempString := TempString + ' ' + Chapter;

    if ExchangeInformation.QTH then
    begin
      QString := QTHString;
{//?
      if ((ActiveExchange = QSONumberNameChapterAndQTHExchange) or
        (ActiveDomesticMult <> NoDomesticMults) or
        (ActiveExchange = QSONumberAndGeoCoordinates) or
        (ActiveExchange = QSONumberAndCoordinatesSum) or
        (ActiveExchange = QSONumberDomesticQTHExchange) or
        (ActiveExchange = RSTAndQSONumberOrDomesticQTHExchange) or
        (ActiveExchange = RSTAndOrGridExchange)) then
}
      if (TempString = '') or (StrToInt(TempString) = 255) then   // 4.85.6
        TempString := QString
      else
        TempString := TempString + ' ' + QString;
    end;

    if ExchangeInformation.Power then
      if TempString = '' then
        TempString := Power
      else
        TempString := TempString + ' ' + Power;

      //         if Contest = OLDNEWYEAR then if TempString = '' then TempString := IntToStr(RData.NumberReceived);
  end;

  GetInitialExchangeStringFromContestExchange := TempString;
end;
{
procedure DupeAndMultSheet.CancelOutNewDomesticMultWeHaveWorked(MultString: Str20;
  Band: BandType;
  Mode: ModeType);
var
  Address                               : integer;

begin
  if DomQTHTable.NumberRemainingMults = 0 then Exit;
  Address := DomQTHTable.GetDomMultInteger(MultString);
  if Address <> -1 then
    RemMultMatrix[Band, Mode, rmDomestic]^[Address] := False;
end;
}

{
procedure DupeAndMultSheet.CancelOutNewDXMultWeHaveWorked(MultString: DXMultiplierString;
  Band: BandType;
  Mode: ModeType);
var
  Address                               : integer;

begin
  if CountryTable.NumberRemainingCountries = 0 then Exit;
  Address := CountryTable.GetDXMultInteger(MultString);
  if Address <> -1 then
    RemMultMatrix[Band, Mode, rmDX]^[Address] := False;
end;
}
{
procedure DupeAndMultSheet.CancelOutNewZoneMultWeHaveWorked(MultString: integer ;
  Band: BandType;
  Mode: ModeType);
var
  Address, RESULT                       : integer;

begin
  //  Address := MultString;
  if RemMultMatrix[Band, Mode, rmZone] = nil then Exit;

//    Val(MultString, Address, Result);
//    if Result <> 0 then Exit;

  if ActiveZoneMult <> EUHFCYear then dec(MultString);

  RemMultMatrix[Band, Mode, rmZone]^[MultString] := False;
end;
}
{
procedure DupeAndMultSheet.CancelOutRemainingMultsWeHaveWorked(Band: BandType;
  Mode: ModeType;
  multtype: RemainingMultiplierType);

var
  RESULT, NumberMults, Mult, Address    : integer;

begin

  if multtype = rmDomestic then
  begin
    NumberMults := MultSheet.Totals[Band, Mode].NumberDomesticMults;

    if (NumberMults = 0) or (RemMultMatrix[Band, Mode, rmDomestic] = nil) then Exit;

    for Mult := 0 to NumberMults - 1 do
    begin
      Address := DomQTHTable.GetDomMultInteger(ExpandedString(MultSheet.DomesticList[Band, Mode]^[Mult]));

      if Address <> -1 then
        RemMultMatrix[Band, Mode, rmDomestic]^[Address] := False;
    end;
  end;

  if multtype = rmDX then
  begin

    NumberMults := MultSheet.Totals[Band, Mode].NumberDXMults;

    if (NumberMults = 0) or (RemMultMatrix[Band, Mode, rmDX] = nil) then Exit;

    for Mult := 0 to CountryTable.NumberCountries - 1 do
    begin
//      Address := CountryTable.GetDXMultInteger(ExpandedString(MultSheet.DXList[Band, Mode]^[Mult]));
      Address := CountryTable.GetDXMultInteger(CountryTable.CountryInfoTable^[Mult].ID);

      if Address <> -1 then
        RemMultMatrix[Band, Mode, rmDX]^[Address] := False;
    end;

  end;

  if multtype = Zone then
  begin
    NumberMults := MultSheet.Totals[Band, Mode].NumberZoneMults;

    if (NumberMults = 0) or (RemMultMatrix[Band, Mode, Zone] = nil) then Exit;

    for Mult := 0 to NumberMults - 1 do
    begin
      Val(ExpandedString(MultSheet.ZoneList[Band, Mode]^[Mult]), Address, RESULT);

      if ActiveZoneMult <> EUHFCYear then dec(Address); // Zone 1 is address 0

      if (Address >= 0) and (Address < 100) and (RESULT = 0) then
        RemMultMatrix[Band, Mode, Zone]^[Address] := False;
    end;
  end;

end;
}

procedure DupeAndMultSheet.SetUpRemainingMultiplierArrays;

var
  StartBand, FinishBand{, Band}           : BandType;
  StartMode, FinishMode{, Mode}           : ModeType;
  //TempString                            : Str20;
 // Address                               : integer;

begin
  if MultByBand then
  begin
    StartBand := Band160;
    FinishBand := Band2304;
  end
  else
  begin
    StartBand := AllBands;
    FinishBand := AllBands;
  end;

  if MultByMode then
  begin
    StartMode := CW;
    FinishMode := Phone;
  end
  else
  begin
    StartMode := Both;
    FinishMode := Both;
  end;
{
  if (DoingDXMults) then
  begin
    if CountryTable.NumberRemainingCountries > 0 then
      for Band := StartBand to FinishBand do
        for Mode := StartMode to FinishMode do
        begin
          if RemMultMatrix[Band, Mode, rmDX] = nil then
                //                        IF MaxAvail > SizeOf (RemainingMultList) THEN
          begin
            New(RemMultMatrix[Band, Mode, rmDX]);

            for Address := 0 to CountryTable.NumberRemainingCountries - 1 do
              RemMultMatrix[Band, Mode, rmDX]^[Address] := True;
          end;

          CancelOutRemainingMultsWeHaveWorked(Band, Mode, rmDX);
        end;
  end;
}
  if DoingZoneMults then
  begin
    case ActiveZoneMult of
      CQZones: MaxNumberOfZones := 40;
      EUHFCYear: MaxNumberOfZones := 100;
      ITUZones: MaxNumberOfZones := 75;
      JAPrefectures: MaxNumberOfZones := 50;
      BranchZones: MaxNumberOfZones := 99;
      RFChampionchipZones: MaxNumberOfZones := 7;
    else MaxNumberOfZones := 0;
    end;

  end;


end;

begin
  //{WLI}    HeapError := @HeapFunc;
  DupeInit;
end.


