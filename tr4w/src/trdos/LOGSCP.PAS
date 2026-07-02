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
unit LogSCP;

{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  utils_text,
  utils_file,
  Windows,
  Messages,
  Classes,
  uCallSignRoutines,
  uCTYDAT,
  //Country9,
  Tree {, Crt, DOS};

const
  ua4wliscpconst                        = 4;

  ASCIIFileName                         = 'TRMASTER.ASC'; { ASCII file used for making changes }
  //n6tr  BufferArraySize                       = 65000; { Largest cell that can be read in }

    {ua4wli}
  BufferArraySize                       = 65000 * ua4wliscpconst; { Largest cell that can be read in }

  TempFileName                          = 'TEMPDTA.TMP';
  AVeryBigNumber                        = 1000000000;
  MaxBlocks                             = 10;
  MaximumPossibleCalls                  = 50;
  MemoryBlockSize                       = 65000 * ua4wliscpconst;
  MaximumCallsAlreadSaved               = 3000;

type
  EntryArrayType = array[0..300] of Char;
  EntryArrayPtr = ^EntryArrayType;

  CallsAlreadySavedArray = array[0..MaximumCallsAlreadSaved - 1] of CallString;
  CallsAlreadySavedArrayPtr = ^CallsAlreadySavedArray;

  PossibleCallActionType = (AnyCall, OnlyCallsWithNames, LogOnly); {KK1L: 6.69 added LogOnly}

  PossibleCallEntry = record
    Call: CallString;
    Dupe: boolean;
  end;

  PossibleCallRecord = record
    NumberPossibleCalls: integer;
    List: array[0..MaximumPossibleCalls - 1] of PossibleCallEntry;
    CursorPosition: integer;
  end;

  DataListEntryPointer = ^DataListEntryRecord;

  DataListEntryRecord = record
    data: DataBaseEntryRecord;
    NextEntry: DataListEntryPointer;
  end;

  MemoryBlock = array[0..MemoryBlockSize - 1] of Byte;
  MemoryBlockPtr = ^MemoryBlock;

  BufferArray = array[0..BufferArraySize - 1] of Char;
  BufferPtr = ^BufferArray;

  CellBufferObject = object
    MaximumMemoryToUse: LONGINT; { TR should set this to a low # }
    ReadAddress: LONGINT;
    MemoryAllocated: LONGINT;
    Key: Str20;

    NumberBufferEntries: LONGINT;

    Buffer1Bytes: LONGINT;
    Buffer2Bytes: LONGINT;
    Buffer3Bytes: LONGINT;

    Buffer1: BufferPtr;
    Buffer2: BufferPtr;
    Buffer3: BufferPtr;

    Buffer1Used: boolean;
    Buffer2Used: boolean;
    Buffer3Used: boolean;

    procedure FigureOutBufferSizes(NumberBytes: LONGINT);
    function GetNextEntry(var EntryString: ShortString {string}): boolean;
    function GetNextEntryAddress(var EntryAddress: Pointer): boolean;
    procedure Initialize(var NumberBytes: LONGINT);
    procedure GoAway;
    procedure LoadCellIntoBuffer(KeyString: CallString; {var } FileRead: HWND {file}; NumberBytes: LONGINT);
  end;

  PartialCallListEntryPtr = ^PartialCallListEntryType;

  PartialCallListEntryType = record
    Call: CallString;
    NextEntry: PartialCallListEntryPtr;
  end;

  BytesWrittenArrayPtr = ^SCPIndexArrayType;

  CallDatabase = object
    ActiveASCIIFileName: Str80; { For ASCII file }
    ActiveFilename: FileNameType {str80}; { Database filename }

    ASCIIFileCrunchCallToRemove: CallString;
    ASCIIFileCrunchRead: Text;
    ASCIIFileCrunchWrite: Text;
    ASCIIFileIsCurrent: boolean; { Handy if successive AddEntries }

    CellBuffer: CellBufferObject; { The big and great File Buffer }
    CountryString: Str80;

    DTAFileSize: LONGINT;

    DeleteCallList: array[0..19] of CallString;
    MasterFileExists: boolean;
    NumberDeleteCalls: integer;

    { Used by TransferMergeDataToASCIIFile to delete some calls }

    EntryPointerList: EntryPointerListPtr;

    FirstMergeDataListEntry: DataListEntryPointer;

    IndexArrayAllocated: boolean;

    InitialPartialCall: CallString;
    InitialPartialList: PartialCallListEntryPtr;

    LastCallRecord: DataBaseEntryRecord;
    LastPartialCall: CallString;
    LastPartialList: PartialCallListEntryPtr;

    MemoryBlocks: array[0..MaxBlocks - 1] of MemoryBlockPtr;
    NumberEntries: LONGINT;

    SectionOverwrite: boolean;
    CQZoneOverwrite: boolean;
    FOCOverwrite: boolean;
    GridOverwrite: boolean;
    HitsOverwrite: boolean;
    ITUZoneOverwrite: boolean;
    CheckOverwrite: boolean;
    NameOverwrite: boolean;
    OldCallOverwrite: boolean;
    QTHOverwrite: boolean;
    SpeedOverwrite: boolean;
    TenTenOverwrite: boolean;
    User1Overwrite: boolean;
    User2Overwrite: boolean;
    User3Overwrite: boolean;
    User4Overwrite: boolean;
    User5Overwrite: boolean;

    PossibleCallAction: PossibleCallActionType;

    SCPDisabledByApplication: boolean; { If TRUE - memory deallocated }

    SCPIndexArray: SCPIndexArrayPtr; { Table of cell addresses }
    SCPEndOfFile: LONGINT; { Address for end of last entry }
    WorkingDirectory: Str40;

    TRMasterFileRead: HWND {file};
    TRMasterFileOpen: boolean;

    procedure AddInBytes(NumberBytes, X, Y: integer);
    procedure AddRecordToMergeList(data: DataBaseEntryRecord);
    procedure ASCIIFileEditor;
    function BestTwoLetters(Partial: CallString): Str20;
    procedure BlowAwayFirstLettersList;
    procedure CheckDTAFile;
    procedure ClearDataEntry(var data: DataBaseEntryRecord);
    procedure ClearField;
    procedure DeleteLowHitCalls;

    function FirstCellForThisCall(Call: CallString; X, Y: integer): boolean;

    procedure GeneratePossibleCallList(Call: CallString);

    procedure GetBestOffsets(Call: CallString;
      var StartingOffset, EndingOffset: LONGINT;
      var X, Y: integer);

    function GetEntry(Call: CallString; var data: DataBaseEntryRecord): boolean;
    function GetCodeSpeed(Call: CallString): integer;
    procedure GetDataFromASCIIEntry(FileString: ShortString; var data: DataBaseEntryRecord; Ignore: Char);
    function GetFOCNumber(Call: CallString): CallString;
    function GetName(Call: CallString): CallString;
//    function GetNextPartialCall: CallString;
    procedure GetNextPartialCall(var Call: CallString);
    function GetRandomCall: CallString; { Use this one }

    function GoodCountry(Call: CallString): boolean;
    function RandomCall: CallString; { Might get FOC number calls }

    function LoadInIndexArray: boolean;

    procedure MergeArrays(var FirstArray: EntryArrayPtr;
      var SecondArray: EntryArrayPtr;
      var OutputArray: EntryArrayPtr);

    procedure MovePossibleCallsFromBufferIntoCallList(Call: CallString);
    procedure NewTwoLetters(PartialCall: CallString {Str20});
    function NumberOfBytesAtThisAddress(TwoLetters: Str20): LONGINT;
    function OverwriteFlagStatus: boolean;
    procedure ParseEntryToDataRecord(EntryString: ShortString {string}; var DataRecord: DataBaseEntryRecord);

    procedure PushChar(InChar: Char; var BlockNumber: Word; var BlockAddress: Word);

    function PartialCallSetup(PartialCall: CallString): boolean;

    procedure SaveCallsAndNamesToFile(FileName: string);
    procedure SaveDataToASCIIFile(var FileWrite: Text; NewData: DataBaseEntryRecord);
    procedure SaveToASCIIFile;

    procedure SCPDisableAndDeAllocateFileBuffer;

    procedure ShowStatistics;
    procedure TransferNewData(OldData: DataBaseEntryRecord; var NewData: DataBaseEntryRecord);

    { Iterates every entry in TRMASTER.DTA and collects non-empty operator
      names (uppercased) into Names.  Uses a private file handle so it does
      not disturb the shared TRMasterFileRead state used by SCP lookups. }
    procedure BuildOperatorNameSet(Names: TStringList);
  end;

const
  PossibleCallActionTypeStringArray     : array[PossibleCallActionType] of PChar =
    (
    'ALL',
    'NAMES',
    'LOG ONLY'
    );

var
  CD                                    : CallDatabase {=


 };
  CallsAlreadySaved                     : CallsAlreadySavedArrayPtr;
  NumberCallsAlreadySaved               : integer;
  PossibleCallList                      : PossibleCallRecord {= (NumberPossibleCalls: 0)};

  { Sorted list of unique operator names (uppercased) built from TRMASTER.DTA.
    Nil until InitOperatorNameSet is called.  Supports fast binary-search
    lookups via NameInOperatorSet. }
  OperatorNameSet                       : TStringList;

procedure InitOperatorNameSet;
function NameInOperatorSet(const AName: string): Boolean;

function GetRandomLetter: Char;
function GetRandomNumber: Char;

implementation
uses LogWind,
  uMaster,
  MainUnit,
  SysUtils;

function DoubleIndexCall(Call: CallString): boolean;

begin
  while length(Call) >= 3 do
  begin
    if pos(Copy(Call, 1, 2), Copy(Call, 2, length(Call) - 1)) > 0 then
    begin
      DoubleIndexCall := True;
      Exit;
    end;

    Delete(Call, 1, 1);
  end;

  DoubleIndexCall := False;
end;

procedure CellBufferObject.Initialize(var NumberBytes: LONGINT);
begin
  if MaximumMemoryToUse = 3 * BufferArraySize then { POST mode }
  begin
    if MemoryAllocated = 0 then
    begin
          //{WLI}            IF MaxAvail > BufferArraySize THEN
      begin
        Buffer1Used := True;
        New(Buffer1);
      end;

          //{WLI}            IF MaxAvail > BufferArraySize THEN
      begin
        Buffer2Used := True;
        New(Buffer2);
      end;

          //{WLI}            IF MaxAvail > BufferArraySize THEN
      begin
        Buffer3Used := True;
        New(Buffer3);
      end;
    end;

    MemoryAllocated := 3 * BufferArraySize;
  end

  else { TR has set the max memory to something else }
  begin
    if MemoryAllocated > 0 then
      FreeMem(Buffer1, MemoryAllocated);
      {wli ������ 216 �� FreeMem}
    if (NumberBytes > MaximumMemoryToUse) or
      (NumberBytes < 0) then
      NumberBytes := MaximumMemoryToUse;

      { Runtime error 201 here with K5KG - 0D73:0139 }

   //{WLI}        IF NumberBytes < MaxAvail THEN
    begin
      GetMem(Buffer1, NumberBytes);
      MemoryAllocated := NumberBytes;
    end
      //{WLI}        ELSE
      //{WLI}            MemoryAllocated := 0;
  end;

  Key := '';
  NumberBufferEntries := 0;
  Buffer1Bytes := 0;
  Buffer2Bytes := 0;
  Buffer3Bytes := 0;
end;

procedure CellBufferObject.GoAway;

begin
  if MaximumMemoryToUse = 3 * BufferArraySize then { Post mode }
  begin
    if MemoryAllocated > 0 then
    begin
      if Buffer1Used then Dispose(Buffer1);
      if Buffer2Used then Dispose(Buffer2);
      if Buffer3Used then Dispose(Buffer3);

      Buffer1Used := False;
      Buffer2Used := False;
      Buffer3Used := False;
    end;
  end
  else
    if MemoryAllocated > 0 then
    begin
      FreeMem(Buffer1, MemoryAllocated);
    end;

  MemoryAllocated := 0;
  Key := '';
  NumberBufferEntries := 0;
  Buffer1Bytes := 0;
  Buffer2Bytes := 0;
  Buffer3Bytes := 0;
end;

procedure CellBufferObject.FigureOutBufferSizes(NumberBytes: LONGINT);

begin
  Buffer2Bytes := 0;
  Buffer3Bytes := 0;

  if NumberBytes > BufferArraySize then
  begin
    Buffer1Bytes := BufferArraySize;

    NumberBytes := NumberBytes - BufferArraySize;

    if NumberBytes > BufferArraySize then
    begin
      Buffer2Bytes := BufferArraySize;
      NumberBytes := NumberBytes - BufferArraySize;

      if NumberBytes > BufferArraySize then
      begin
              //{WLI}                ReportError ('This cell is too big!');
        logger.Fatal('In FigureOutBufferSizes, the cell is too big');
        halt;
      end
      else
        Buffer3Bytes := NumberBytes;

    end
    else
      Buffer2Bytes := NumberBytes;
  end
  else
    Buffer1Bytes := NumberBytes;

end;

procedure CellBufferObject.LoadCellIntoBuffer(KeyString: CallString;
  {var }FileRead: HWND {file};
  NumberBytes: LONGINT);

var
  BytesRead                             : integer {WORD} {WLI};

begin
  Initialize(NumberBytes);

  if MaximumMemoryToUse <= BufferArraySize then { TR mode }
  begin
    sReadFile(FileRead, Buffer1^, NumberBytes);
//    BlockRead(FileRead, Buffer1^, NumberBytes, BytesRead);
    Key := KeyString;
    NumberBufferEntries := NumberBytes;
    ReadAddress := 0;
    Exit;
  end;

  FigureOutBufferSizes(NumberBytes);

  if (Buffer1Bytes > 0) and Buffer1Used then
  begin
    sReadFile(FileRead, Buffer1^, Buffer1Bytes);

    if BytesRead < Buffer1Bytes then
    begin
          //{WLI}            ReportError ('File read error!!  Line #721 in LOGSCP.PAS.');
      halt;
    end;
  end;

  if (Buffer2Bytes > 0) and Buffer2Used then
  begin
    sReadFile(FileRead, Buffer2^, Buffer2Bytes);

    if BytesRead < Buffer2Bytes then
    begin
          //                 ReportError ('File read error!!  Line #721 in LOGSCP.PAS.');
      halt;
    end;
  end;

  if (Buffer3Bytes > 0) and Buffer3Used then
  begin
    sReadFile(FileRead, Buffer3^, Buffer3Bytes);

    if BytesRead < Buffer3Bytes then
    begin
          //{WLI}            ReportError ('File read error!!  Line #721 in LOGSCP.PAS.');
      halt;
    end;
  end;

  Key := KeyString;
  NumberBufferEntries := NumberBytes;
  ReadAddress := 0;
end;

function CellBufferObject.GetNextEntry(var EntryString: ShortString {string}): boolean;

{ Returns FALSE when no more entries left in the cell buffer }

var
  CellChar                              : Char;

begin
  EntryString := '';

  while ReadAddress <= NumberBufferEntries - 1 do
  begin
    if ReadAddress < BufferArraySize then
      CellChar := Buffer1^[ReadAddress]
    else
      if ReadAddress < BufferArraySize * 2 then
        CellChar := Buffer2^[ReadAddress - BufferArraySize]
      else
        CellChar := Buffer3^[ReadAddress - (2 * BufferArraySize)];

    inc(ReadAddress);

    if CellChar = CHR(0) then
    begin
      GetNextEntry := True;
      Exit;
    end;

    EntryString := EntryString + CellChar;
  end;

  { We didn't find a null character at the end - return a null string }

  EntryString := '';
  GetNextEntry := False;
end;

function CellBufferObject.GetNextEntryAddress(var EntryAddress: Pointer): boolean;

{ Returns FALSE when no more entries left in the cell buffer }

var
  CellChar                              : Char;

begin
  { Find address of first byte in the record to be read }

  if ReadAddress < BufferArraySize then
    EntryAddress := Addr(Buffer1^[ReadAddress])
  else
    if ReadAddress < BufferArraySize * 2 then
    begin
      if not Buffer2Used then
      begin
        GetNextEntryAddress := False;
        Exit;
      end;

      EntryAddress := Addr(Buffer2^[ReadAddress - BufferArraySize])
    end
    else
    begin
      if not Buffer3Used then
      begin
        GetNextEntryAddress := False;
        Exit;
      end;

      EntryAddress := Addr(Buffer3^[ReadAddress - (2 * BufferArraySize)]);
    end;

  while ReadAddress <= NumberBufferEntries - 1 do
  begin
    if ReadAddress < BufferArraySize then
      CellChar := Buffer1^[ReadAddress]
    else
      if ReadAddress < BufferArraySize * 2 then
        CellChar := Buffer2^[ReadAddress - BufferArraySize]
      else
        CellChar := Buffer3^[ReadAddress - (2 * BufferArraySize)];

    inc(ReadAddress);

    if CellChar = CHR(0) then
    begin
      GetNextEntryAddress := True;
      Exit;
    end;
  end;

  { We didn't find a null character at the end - return a null string }

  GetNextEntryAddress := False;
end;

function GetRandomLetter: Char;

begin
  GetRandomLetter := CHR(Ord('A') + Random(26));
end;

function GetRandomNumber: Char;

begin
  GetRandomNumber := CHR(Ord('0') + Random(10));
end;

procedure CallDatabase.PushChar(InChar: Char; var BlockNumber: Word; var BlockAddress: Word);

begin
  MemoryBlocks[BlockNumber]^[BlockAddress] := Ord(InChar);

  inc(BlockAddress);

  if BlockAddress = SizeOf(MemoryBlock) then
  begin
    BlockAddress := 0;
    inc(BlockNumber);
  end;
end;

function KeyInRange(X, Y, FirstKeyX, FirstKeyY, LastKeyX, LastKeyY: integer): boolean;

{ Returns TRUE if the key is >= FirstKey and < LastKey }

begin
  KeyInRange := False;

  if (X < 0) or (X > 36) or (Y < 0) or (Y > 36) then Exit;

  if (X < FirstKeyX) or (X > LastKeyX) then Exit;

  if (X = FirstKeyX) and (Y < FirstKeyY) then Exit;

  if (X = LastKeyX) and (Y >= LastKeyY) then Exit;

  KeyInRange := True;
end;

function NumberOfDataBytes(data: DataBaseEntryRecord): integer;

var
  NumberBytes                           : integer;

begin
  with data do
  begin
    NumberBytes := length(Call);

    if Section <> '' then NumberBytes := NumberBytes + length(Section) + 1;
    if CQZone <> '' then NumberBytes := NumberBytes + length(CQZone) + 1;
    if FOC <> '' then NumberBytes := NumberBytes + length(FOC) + 1;
    if Hits > 0 then NumberBytes := NumberBytes + 2;
    if Grid <> '' then NumberBytes := NumberBytes + length(Grid) + 1;
    if ITUZone <> '' then NumberBytes := NumberBytes + length(ITUZone) + 1;
    if Check <> '' then NumberBytes := NumberBytes + length(Check) + 1;
    if mName <> '' then NumberBytes := NumberBytes + length(mName) + 1;
    if OldCall <> '' then NumberBytes := NumberBytes + length(OldCall) + 1;
    if QTH <> '' then NumberBytes := NumberBytes + length(QTH) + 1;
    if Speed > 0 then NumberBytes := NumberBytes + 2;
    if TENTEN <> '' then NumberBytes := NumberBytes + length(TENTEN) + 1;
    if User1 <> '' then NumberBytes := NumberBytes + length(User1) + 1;
    if User2 <> '' then NumberBytes := NumberBytes + length(User2) + 1;
    if User3 <> '' then NumberBytes := NumberBytes + length(User3) + 1;
    if User4 <> '' then NumberBytes := NumberBytes + length(User4) + 1;
    if User5 <> '' then NumberBytes := NumberBytes + length(User5) + 1;
  end;

  NumberBytes := NumberBytes + 1; { for the null character at the end }
  NumberOfDataBytes := NumberBytes;
end;

function GetSize(EntryArray: EntryArrayPtr): integer;

var
  EntrySize                             : integer;

begin
  EntrySize := 0;

  while (EntryArray^[EntrySize] <> CHR(0)) do
    inc(EntrySize);

  inc(EntrySize); { Give me the null character too }

  GetSize := EntrySize;
end;

function GetCall(EntryArray: EntryArrayPtr): CallString;

var
  TempCall                              : Str20;
  CharPointer                           : integer;

begin
  TempCall := '';

  CharPointer := 0;

  while EntryArray^[CharPointer] > ControlZ do
  begin
    TempCall := TempCall + EntryArray^[CharPointer];
    inc(CharPointer);
  end;

  GetCall := TempCall;
end;

function GetArrayString(var InputArray: EntryArrayPtr): string;

var
  TempString                            : string;
  Address                               : integer;

begin
  TempString := '';
  Address := 0;

  while InputArray^[Address] <> CHR(0) do
  begin
    TempString := TempString + InputArray^[Address];
    inc(Address);
  end;

  GetArrayString := TempString;
end;

procedure ConvertDatbaseEntryRecordToEntryArray(InputRecord: DataBaseEntryRecord;
  var OutputArray: EntryArrayPtr);

var
  InputAddress, OutputAddress           : integer;

begin
  OutputAddress := 0;

  with InputRecord do
  begin
    for InputAddress := 1 to length(Call) do
    begin
      OutputArray^[OutputAddress] := Call[InputAddress];
      inc(OutputAddress);
    end;

    if Section <> '' then
    begin
      OutputArray^[OutputAddress] := ControlA;
      inc(OutputAddress);

      for InputAddress := 1 to length(Section) do
      begin
        OutputArray^[OutputAddress] := Section[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if CQZone <> '' then
    begin
      OutputArray^[OutputAddress] := ControlC;
      inc(OutputAddress);

      for InputAddress := 1 to length(CQZone) do
      begin
        OutputArray^[OutputAddress] := CQZone[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if FOC <> '' then
    begin
      OutputArray^[OutputAddress] := ControlF;
      inc(OutputAddress);

      for InputAddress := 1 to length(FOC) do
      begin
        OutputArray^[OutputAddress] := FOC[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if Hits > 0 then
    begin
      OutputArray^[OutputAddress] := ControlH;
      inc(OutputAddress);
      OutputArray^[OutputAddress] := CHR(Hits);
      inc(OutputAddress);
    end;

    if Grid <> '' then
    begin
      OutputArray^[OutputAddress] := ControlG;
      inc(OutputAddress);

      for InputAddress := 1 to length(Grid) do
      begin
        OutputArray^[OutputAddress] := Grid[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if ITUZone <> '' then
    begin
      OutputArray^[OutputAddress] := ControlI;
      inc(OutputAddress);

      for InputAddress := 1 to length(ITUZone) do
      begin
        OutputArray^[OutputAddress] := ITUZone[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if Check <> '' then
    begin
      OutputArray^[OutputAddress] := ControlK;
      inc(OutputAddress);

      for InputAddress := 1 to length(Check) do
      begin
        OutputArray^[OutputAddress] := Check[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if mName <> '' then
    begin
      OutputArray^[OutputAddress] := ControlN;
      inc(OutputAddress);

      for InputAddress := 1 to length(mName) do
      begin
        OutputArray^[OutputAddress] := mName[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if OldCall <> '' then
    begin
      OutputArray^[OutputAddress] := ControlO;
      inc(OutputAddress);

      for InputAddress := 1 to length(OldCall) do
      begin
        OutputArray^[OutputAddress] := OldCall[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if QTH <> '' then
    begin
      OutputArray^[OutputAddress] := ControlQ;
      inc(OutputAddress);

      for InputAddress := 1 to length(QTH) do
      begin
        OutputArray^[OutputAddress] := QTH[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if Speed <> 0 then
    begin
      OutputArray^[OutputAddress] := ControlS;
      inc(OutputAddress);
      OutputArray^[OutputAddress] := CHR(Speed);
      inc(OutputAddress);
    end;

    if TENTEN <> '' then
    begin
      OutputArray^[OutputAddress] := ControlT;
      inc(OutputAddress);

      for InputAddress := 1 to length(TENTEN) do
      begin
        OutputArray^[OutputAddress] := TENTEN[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if User1 <> '' then
    begin
      OutputArray^[OutputAddress] := ControlU;
      inc(OutputAddress);

      for InputAddress := 1 to length(User1) do
      begin
        OutputArray^[OutputAddress] := User1[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if User2 <> '' then
    begin
      OutputArray^[OutputAddress] := ControlV;
      inc(OutputAddress);

      for InputAddress := 1 to length(User2) do
      begin
        OutputArray^[OutputAddress] := User2[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if User3 <> '' then
    begin
      OutputArray^[OutputAddress] := ControlW;
      inc(OutputAddress);

      for InputAddress := 1 to length(User3) do
      begin
        OutputArray^[OutputAddress] := User3[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if User4 <> '' then
    begin
      OutputArray^[OutputAddress] := ControlX;
      inc(OutputAddress);

      for InputAddress := 1 to length(User4) do
      begin
        OutputArray^[OutputAddress] := User4[InputAddress];
        inc(OutputAddress);
      end;
    end;

    if User5 <> '' then
    begin
      OutputArray^[OutputAddress] := ControlY;
      inc(OutputAddress);

      for InputAddress := 1 to length(User5) do
      begin
        OutputArray^[OutputAddress] := User5[InputAddress];
        inc(OutputAddress);
      end;
    end;
  end;

  OutputArray^[OutputAddress] := NullCharacter;
  inc(OutputAddress);
end;

procedure CallDatabase.MergeArrays(var FirstArray: EntryArrayPtr;
  var SecondArray: EntryArrayPtr;
  var OutputArray: EntryArrayPtr);

{ This will move any data from the first array into the second one. }

var
  FirstDataRecord, SecondDataRecord, OutputDataRecord: DataBaseEntryRecord;

begin
  ParseEntryToDataRecord(GetArrayString(FirstArray), FirstDataRecord);
  ParseEntryToDataRecord(GetArrayString(SecondArray), SecondDataRecord);

  ClearDataEntry(OutputDataRecord);

  { Start with the contents of the first record }

  OutputDataRecord := FirstDataRecord;

  { We add the hits together }

  if FirstDataRecord.Hits + SecondDataRecord.Hits > 255 then
    OutputDataRecord.Hits := 255
  else
    OutputDataRecord.Hits := FirstDataRecord.Hits + SecondDataRecord.Hits;

  { If the second record has any data - put it into the output record }

  if SecondDataRecord.Section <> '' then OutputDataRecord.Section := SecondDataRecord.Section;
  if SecondDataRecord.CQZone <> '' then OutputDataRecord.CQZone := SecondDataRecord.CQZone;
  if SecondDataRecord.FOC <> '' then OutputDataRecord.FOC := SecondDataRecord.FOC;
  if SecondDataRecord.Grid <> '' then OutputDataRecord.Grid := SecondDataRecord.Grid;
  if SecondDataRecord.ITUZone <> '' then OutputDataRecord.ITUZone := SecondDataRecord.ITUZone;
  if SecondDataRecord.Check <> '' then OutputDataRecord.Check := SecondDataRecord.Check;
  if SecondDataRecord.mName <> '' then OutputDataRecord.mName := SecondDataRecord.mName;
  if SecondDataRecord.OldCall <> '' then OutputDataRecord.OldCall := SecondDataRecord.OldCall;
  if SecondDataRecord.QTH <> '' then OutputDataRecord.QTH := SecondDataRecord.QTH;
  if SecondDataRecord.Speed <> 0 then OutputDataRecord.Speed := SecondDataRecord.Speed;
  if SecondDataRecord.TENTEN <> '' then OutputDataRecord.TENTEN := SecondDataRecord.TENTEN;
  if SecondDataRecord.User1 <> '' then OutputDataRecord.User1 := SecondDataRecord.User1;
  if SecondDataRecord.User2 <> '' then OutputDataRecord.User2 := SecondDataRecord.User2;
  if SecondDataRecord.User3 <> '' then OutputDataRecord.User3 := SecondDataRecord.User3;
  if SecondDataRecord.User4 <> '' then OutputDataRecord.User4 := SecondDataRecord.User4;
  if SecondDataRecord.User5 <> '' then OutputDataRecord.User5 := SecondDataRecord.User5;

  { Convert the output record back into a packed array in the format used
    in the TRMASTER.DTA file }

  ConvertDatbaseEntryRecordToEntryArray(OutputDataRecord, OutputArray);
end;

function AlreadySaved(Call: CallString): boolean;

var
  Address                               : integer;

begin
  if NumberCallsAlreadySaved > 0 then
    for Address := 0 to NumberCallsAlreadySaved - 1 do
      if Call = CallsAlreadySaved^[Address] then
      begin
        AlreadySaved := True;
        Exit;
      end;

  AlreadySaved := False;

  if NumberCallsAlreadySaved < MaximumCallsAlreadSaved then
  begin
    CallsAlreadySaved^[NumberCallsAlreadySaved] := Call;
    inc(NumberCallsAlreadySaved);
  end;
end;

procedure CallDatabase.SaveCallsAndNamesToFile(FileName: string);

var
  CellSize                              : LONGINT;
  FileRead                              : file;
  FileWrite                             : Text;
  //BytesRead                             : Word;
  X, Y, NextX, NextY, StartingOffset, EndingOffset: LONGINT;
  KeyString, TempString                 : Str40;
  EntryString                           : ShortString {string};
  DataRecord                            : DataBaseEntryRecord;

begin
  if not LoadInIndexArray then Exit;
  if FileName = '' then Exit;

  OpenFileForWrite(FileWrite, FileName);

  //{WLI}    GoToXY (1, WhereY);
  //{WLI}    Write ('Saving .DTA file to ASCII file.  Processing cell   ');

  CellBuffer.Initialize(CellSize); { Only works in POST mode }

  New(CallsAlreadySaved);

  for X := 0 to 36 do
    for Y := 0 to 36 do
    begin
      NumberCallsAlreadySaved := 0; { Set to zero for each cell }

        //{WLI}            GoToXY (WhereX - 2, WhereY);

      KeyString := GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y);

        //      Write(KeyString);

      StartingOffset := SCPIndexArray^[X, Y];

      NextY := Y + 1;
      NextX := X;

      if NextY > 36 then
      begin
        if X < 36 then
        begin
          NextX := X + 1;
          NextY := 0;
          EndingOffset := SCPIndexArray^[NextX, NextY];
        end
        else
          EndingOffset := SCPEndOfFile;
      end
      else
        EndingOffset := SCPIndexArray^[NextX, NextY];

      if (X <> 0) or (Y <> 0) then
      begin
        if FilePos(FileRead) <> StartingOffset then
        begin
          Close(FileRead);
          Assign(FileRead, ActiveFilename);
          Reset(FileRead, 1);
          Seek(FileRead, StartingOffset);
        end;
      end
      else
      begin
        Assign(FileRead, ActiveFilename);
        Reset(FileRead, 1);
        Seek(FileRead, StartingOffset);
      end;

      if StartingOffset < EndingOffset then
      begin
        CellSize := EndingOffset - StartingOffset;

        if CellSize > 3 * BufferArraySize then
        begin
          WriteLn;
                //{WLI}                    ReportError (GetSCPCharFromInteger (X) + GetSCPCharFromInteger (Y) + ' cell is too large!!!');
          halt;
        end;

//        CellBuffer.LoadCellIntoBuffer(KeyString, FileRead, CellSize);

        while CellBuffer.GetNextEntry(EntryString) do
        begin
          ParseEntryToDataRecord(EntryString, DataRecord);

          if DataRecord.mName <> '' then
            if FirstCellForThisCall(DataRecord.Call, X, Y) then
              if DoubleIndexCall(DataRecord.Call) then
              begin
                if not AlreadySaved(DataRecord.Call) then
                begin
                  TempString := DataRecord.Call;
                  while length(TempString) < 15 do TempString := TempString + ' ';
                  TempString := TempString + DataRecord.mName;
                  WriteLn(FileWrite, TempString);
                end;
              end
              else
              begin
                TempString := DataRecord.Call;
                while length(TempString) < 15 do TempString := TempString + ' ';
                TempString := TempString + DataRecord.mName;
                WriteLn(FileWrite, TempString);
              end;
        end;

      end;
    end;

  CellBuffer.GoAway;
  Dispose(CallsAlreadySaved);

  Close(FileWrite);
  ASCIIFileIsCurrent := True;
  //{WLI}    GoToXY (1, WhereY);
  //{WLI}    ClrEol;
  //{WLI}    TextColor (Cyan);
  //{WLI}    WriteLn ('Data successfully saved to ASCII file.');
end;

procedure CallDatabase.AddInBytes(NumberBytes, X, Y: integer);

{ Will increment the totals in the SCPIndexArray starting for the cell
  indicated }

var
  XAddress, YAddress                    : integer;

begin
  { We start at the end of the specified cell }

  inc(Y);

  if Y > 36 then
  begin
    inc(X);
    Y := 0;
  end;

  if X <= 36 then
    for XAddress := X to 36 do
      for YAddress := Y to 36 do
        SCPIndexArray^[XAddress, YAddress] := SCPIndexArray^[XAddress, YAddress] + NumberBytes;

  SCPEndOfFile := SCPEndOfFile + NumberBytes;
end;

procedure CallDatabase.GetBestOffsets(Call: CallString;
  var StartingOffset, EndingOffset: LONGINT;
  var X, Y: integer);

var
  BestTwoLetterString                   : Str20;
  NextX, NextY                          : integer;

begin
  BestTwoLetterString := BestTwoLetters(Call);

  if BestTwoLetterString = '' then { No calls found in array }
  begin
    StartingOffset := 0;
    EndingOffset := 0;
    Exit;
  end;

  X := GetSCPIntegerFromChar(BestTwoLetterString[1]);
  Y := GetSCPIntegerFromChar(BestTwoLetterString[2]);

  if (X <> -1) and (Y <> -1) then
  begin
    StartingOffset := SCPIndexArray^[X, Y];

    NextY := Y + 1;
    NextX := X;

    if NextY > 36 then
    begin
      if X < 36 then
      begin
        NextX := X + 1;
        NextY := 0;
        EndingOffset := SCPIndexArray^[NextX, NextY];
      end
      else
        EndingOffset := SCPEndOfFile;
    end
    else
      EndingOffset := SCPIndexArray^[NextX, NextY];
  end;

end;

function CallDatabase.BestTwoLetters(Partial: CallString): Str20;

{ This routine will return the best two letters to be used when looking
  for the specified callsign/partial. }

var
  CharPos                               : integer;
  MinimumBytes                          : LONGINT;
  NumberBytes                           : array[1..11] of LONGINT;

begin
  BestTwoLetters := ''; { Default if we fall out }

  if not LoadInIndexArray then Exit;

  if length(Partial) < 2 then Exit; { Can't deal with this }

  MinimumBytes := AVeryBigNumber;

  for CharPos := 1 to length(Partial) - 1 do
  begin
    if Copy(Partial, CharPos, 2) = 'JA' then Continue;

    NumberBytes[CharPos] := NumberOfBytesAtThisAddress(Copy(Partial, CharPos, 2));

      { We get zero if we had an illegal character - like a question mark }

    if NumberBytes[CharPos] > 0 then
      if NumberBytes[CharPos] < MinimumBytes then
        MinimumBytes := NumberBytes[CharPos];
  end;

  { Now, which pair had the minimum cell size? }

  for CharPos := 1 to length(Partial) - 1 do
    if NumberBytes[CharPos] = MinimumBytes then
    begin
      BestTwoLetters := Copy(Partial, CharPos, 2);
      Exit;
    end;

  { We fall through leaving a null string if we couldn't process the
    data.  This might occure if someone called us with a string that
    didn't have two non wildcard entries in a row (like N?6). }

end;

procedure CallDatabase.BlowAwayFirstLettersList;

{ This procedure will clear out the InitialPartialList }

var
  NextRecord, ActiveRecord              : PartialCallListEntryPtr;

begin
  ActiveRecord := InitialPartialList;

  while ActiveRecord <> nil do
  begin
    NextRecord := ActiveRecord^.NextEntry;
    Dispose(ActiveRecord);
    ActiveRecord := NextRecord;
  end;

  InitialPartialCall := '';
  InitialPartialList := nil;
end;

procedure CallDatabase.ClearField;

//var  Key: Char;

begin
  {

       WriteLn ('This procedure will allow you to clear out one of the data fields in the ');
       WriteLn ('database.  For string values, they will be set to null string.  Numberic');
       WriteLn ('values will be set to zero.');
       WriteLn;

       WriteLn ('A - Section    K - Check        U - User 1');
       WriteLn ('C - CQ Zone    N - Name         V - User 2');
       WriteLn ('F - FOC        O - Old Call     W - User 3');
       WriteLn ('G - Grid       Q - QTH          X - User 4');
       WriteLn ('H - Hits       S - Speed        Y - User 5');
       WriteLn ('I - ITU Zone   T - Ten ten #');
       WriteLn;

       REPEAT
           Key := UpCase (GetKey ('Enter field to clear (escape to abort) : '));
           IF Key = EscapeKey THEN Exit;
       UNTIL (Key = 'A') OR (Key = 'C') OR (Key = 'F') OR (Key = 'G') OR
             (Key = 'H') OR (Key = 'I') OR (Key = 'K') OR (Key = 'N') OR
             (Key = 'O') OR (Key = 'Q') OR (Key = 'S') OR (Key = 'T') OR
             (Key = 'U') OR (Key = 'V') OR (Key = 'W') OR (Key = 'X') OR
             (Key = 'Y');

       IF NOT ASCIIFileIsCurrent THEN SaveToASCIIFile;

       BuildNewDatabaseFromASCIIFile (Key);

       WriteLn ('COMPLETE.  If for some reason, you want to undo this operation, simply run');
       WriteLn ('the Build command from the main menu.');
  }
end;

procedure CallDatabase.ClearDataEntry(var data: DataBaseEntryRecord);

begin

  Windows.ZeroMemory(@data, SizeOf(DataBaseEntryRecord));
  {
    with data do
    begin
      Call := '';
      Section := '';
      CQZone := '';
      FOC := '';
      Grid := '';
      Hits := 0;
      ITUZone := '';
      Check := '';
      mName := '';
      OldCall := '';
      QTH := '';
      Speed := 0;
      TENTEN := '';
      User1 := '';
      User2 := '';
      User3 := '';
      User4 := '';
      User5 := '';
    end;
   }
end;

function CallDatabase.FirstCellForThisCall(Call: CallString; X, Y: integer): boolean;

{ This function will return TRUE if X Y values passed to it point to the
  first cell this call would be found in when using a typical FOR X FOR Y
  loop to go through the database. }

var
  LeastX, LeastY, TestX, TestY, CharPointer: integer;

begin
  if length(Call) < 2 then
  begin
    FirstCellForThisCall := False;
    Exit;
  end;

  LeastX := 37;
  LeastY := 37;

  for CharPointer := 1 to length(Call) - 1 do
  begin
    TestX := GetSCPIntegerFromChar(Call[CharPointer]);
    TestY := GetSCPIntegerFromChar(Call[CharPointer + 1]);

    if (TestX < LeastX) or ((TestX = LeastX) and (TestY < LeastY)) then
    begin
      LeastX := TestX;
      LeastY := TestY;
    end;
  end;

  FirstCellForThisCall := (X = LeastX) and (Y = LeastY);
end;

function CallDatabase.GetCodeSpeed(Call: CallString): integer;

var
  data                                  : DataBaseEntryRecord;

begin
  if GetEntry(Call, data) then
    GetCodeSpeed := data.Speed
  else
    GetCodeSpeed := 0;
end;

function CallDatabase.GetName(Call: CallString): CallString;

var
  data                                  : DataBaseEntryRecord;
  tName                                 : CallString;

begin
  {  Name := '';

    if Name <> '' then
    begin
      GetName := Name;
      Exit;
    end;
  }

  if GetEntry(Call, data) then
  begin
      //    GetName := data.mName;
    tName := LowerCase(data.mName);
    tName[1] := UpCase(data.mName[1]);
    GetName := tName;
  end
  else
    GetName := '';
end;

function CallDatabase.GetFOCNumber(Call: CallString): CallString;

var
  data                                  : DataBaseEntryRecord;

begin
  if GetEntry(RootCall(Call), data) then
    GetFOCNumber := data.FOC
  else
    GetFOCNumber := '';
end;

function CallDatabase.GetEntry(Call: CallString; var data: DataBaseEntryRecord): boolean;

{ This function will fetch all the data for the callsign indicated.  It
  returns TRUE if the callsign was found. }

var
  EntryString                           : ShortString {string};

begin
  if Call = LastCallRecord.Call then
  begin
    data := LastCallRecord;
    GetEntry := True;
    Exit;
  end;

  GetEntry := False;

  ClearDataEntry(data);

  if not LoadInIndexArray then Exit;

  if not PartialCallSetup(Call) then Exit;

  while CellBuffer.GetNextEntry(EntryString) do
  begin
    ParseEntryToDataRecord(EntryString, data);

    if data.Call = Call then
    begin
      GetEntry := True;
      LastCallRecord := data;
      Exit;
    end;
  end;

  { Didn't find anything }

  ClearDataEntry(data);
end;

procedure CallDatabase.GetDataFromASCIIEntry(FileString: ShortString; var data: DataBaseEntryRecord; Ignore: Char);

{ This function will decode the ASCII string and put the proper data into
  the Data variable }

var
  TestName, Command                     : Str40;
  ID                                    : Char;
  Result                                : integer;

begin
  ClearDataEntry(data);

  data.Call := UpperCase(RemoveFirstString(FileString));

  while (FileString <> '') and (FileString[1] = '=') do
  begin
    ID := FileString[2];

    Delete(FileString, 1, 2);

    if StringHas(FileString, '=') then { Another command in waiting }
    begin
      Command := PrecedingString(FileString, ' =');

      FileString := Copy(FileString,
        pos('=', FileString),
        (length(FileString) - pos('=', FileString)) + 1);

    end
    else
    begin
      Command := FileString;
      FileString := '';
    end;

    with data do
      case ID of
        'A':
          if Ignore <> 'A' then Section := Command;
        'C':
          if Ignore <> 'C' then CQZone := Command;
        'F':
          if Ignore <> 'F' then FOC := Command;
        'G':
          if Ignore <> 'G' then Grid := Command;

        'H':
          if Ignore <> 'H' then Val(Command, Hits, Result);

        'I':
          if Ignore <> 'I' then ITUZone := Command;
        'K':
          if Ignore <> 'K' then Check := Command;

        'N':
          if Ignore <> 'N' then
          begin
            if length(Command) = 1 then
              Continue;

            if length(Command) = 2 then
            begin
              TestName := UpperCase(Command);

              if (TestName <> 'AL') and (TestName <> 'ED') and
                (TestName <> 'OZ') and (TestName <> 'BO') and
                (TestName <> 'TY') and (TestName <> 'JO') and
                (TestName <> 'GO') and (TestName <> 'OX') and
                (TestName <> 'CY') and (TestName <> 'JP') and
                (TestName <> 'MO') and (TestName <> 'HI') and
                (TestName <> 'OJ') then
                Continue;
            end;

            mName := Command;
          end;

        'O':
          if Ignore <> 'O' then OldCall := Command;
        'Q':
          if Ignore <> 'Q' then QTH := Command;

        'S':
          if Ignore <> 'S' then Val(Command, Speed, Result);

        'T':
          if Ignore <> 'T' then TENTEN := Command;
        'U':
          if Ignore <> 'U' then User1 := Command;
        'V':
          if Ignore <> 'V' then User2 := Command;
        'W':
          if Ignore <> 'W' then User3 := Command;
        'X':
          if Ignore <> 'X' then User4 := Command;
        'Y':
          if Ignore <> 'Y' then User5 := Command;
      end;
  end;

end;

function CountryStringPresent(CountryID: Str20; CountryString: ShortString {Str80} {WLI}): boolean;

var
  CString                               : Str20;
  CommaPosition                         : integer;

begin
  while pos(',', CountryString) > 0 do
  begin
    CommaPosition := pos(',', CountryString);

    if CommaPosition > 1 then
    begin
      CString := Copy(CountryString, 1, CommaPosition - 1);

      if CString = CountryID then
      begin
        CountryStringPresent := True;
        Exit;
      end;

      Delete(CountryString, 1, CommaPosition);
      GetRidOfPrecedingSpaces(CountryString);
    end;
  end;

  if CountryString <> '' then
    CountryStringPresent := CountryID = CountryString
  else
    CountryStringPresent := False;
end;

function CallDatabase.GoodCountry(Call: CallString): boolean;

var
  CountryID                             : DXMultiplierString {Str20};
  TempString                            : Str80;
  QTH                                   : QTHRecord;
begin
  GoodCountry := True;
  if CountryString = '' then Exit;

  TempString := CountryString;

  ctyLocateCall(Call, QTH);
  CountryID := QTH.CountryID;

  if (Copy(CountryString, 1, 1) = '!') or
    (Copy(CountryString, 1, 1) = '-') then { Exclude countries }
  begin
    Delete(TempString, 1, 1); { Get rid of ! or - }

    if CountryStringPresent(CountryID, TempString) then
      GoodCountry := False;

    Exit;
  end
  else

    { Include countries}

    GoodCountry := CountryStringPresent(CountryID, TempString);
end;

//function CallDatabase.GetNextPartialCall: CallString;

procedure CallDatabase.GetNextPartialCall(var Call: CallString);

{ Returns the next possible call and puts it in the InitialPartialCallList }

var
  EntryString                           : ShortString {string};
  data                                  : DataBaseEntryRecord;

begin
//  GetNextPartialCall := '';
  Call := '';

  if SCPDisabledByApplication then Exit;
  if CellBuffer.Key = '' then Exit;

  while CellBuffer.GetNextEntry(EntryString) do
  begin
    ParseEntryToDataRecord(EntryString, data);

    if (length(InitialPartialCall) = 2) or (PartialCall(InitialPartialCall, data.Call)) then
      if CountryString <> '' then
      begin
        if GoodCountry(data.Call) then
        begin
          {GetNextPartial}Call := data.Call;
          Exit;
        end;
      end
      else
      begin
        {GetNextPartial}Call := data.Call;
        Exit;
      end;
  end;
end;

function CallDatabase.LoadInIndexArray: boolean;

{ This procedure will go read in the index array for the active file.
  It is saved in SCPIndexArray. Returns TRUE if it thinks it worked. }

//var
  //Directory                             : Str40;
  //Result1                               : integer {WORD} {WLI};

begin
  WorkingDirectory := '';
  LoadInIndexArray := False;
  if (SCPDisabledByApplication) or (PossibleCallAction = LogOnly) then Exit;

  {KK1L 6.69 added LogOnly check}

  if TRMasterFileOpen then
  begin
    LoadInIndexArray := True;
    Exit;
  end;

  //{WLI}    IF SizeOf (SCPIndexArray^) + 5000 >= MaxAvail THEN Exit;

//  if ActiveFilename <> '' then
  if ActiveFilename[0] <> #0 then
  begin

      { If the file does not appear in the active directory, we need
        to search around for it and come up with a complete path for
        it. }
    if not MasterFileExists then Exit;


      //{WLI}
         {DosError := 0;}
           { Seems to be necessary in some cases as the
                                value will be 18 - indicating "no more files"
                                which might be because of the FindFirst that
                                was executed.  Doesn't seem to get reset by
                                the next two statements...  weird. }

    if tOpenFileForRead(TRMasterFileRead, ActiveFilename) then

//      Assign(TRMasterFileRead, ActiveFilename);
//    Reset(TRMasterFileRead, 1);
//    if IORESULT {DosError} {WLI} = 0 then
    begin
      DTAFileSize := Windows.GetFileSize(TRMasterFileRead, nil) {FileSize(TRMasterFileRead)};

      New(SCPIndexArray);
      sReadFile(TRMasterFileRead, SCPIndexArray^, SizeOf(SCPIndexArray^));
      sReadFile(TRMasterFileRead, SCPEndOfFile, SizeOf(SCPEndOfFile));
//      BlockRead(TRMasterFileRead, SCPIndexArray^, SizeOf(SCPIndexArray^), Result1);
//      BlockRead(TRMasterFileRead, SCPEndOfFile, SizeOf(SCPEndOfFile), Result1);
      LoadInIndexArray := True;
      TRMasterFileOpen := True;
      IndexArrayAllocated := True;
    end;

  end;

end;

procedure CallDatabase.NewTwoLetters(PartialCall: CallString {Str20});

{ This procedure will setup the GetNextPartialCall function for a
  new two letter key.  }

var
  StartingOffset, EndingOffset, NumberBytes: LONGINT;
  X, Y                                  : integer;
  KeyString                             : CallString;

begin
  BlowAwayFirstLettersList;

  { Get rid of old file buffer }

  GetBestOffsets(PartialCall, StartingOffset, EndingOffset, X, Y);

  KeyString := GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y);

  if StartingOffset = EndingOffset then { No calls found }
  begin
    CellBuffer.GoAway;
    Exit;
  end;

  CellBuffer.Key := GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y);

  if EndingOffset - StartingOffset > BufferArraySize then
    EndingOffset := StartingOffset + BufferArraySize;

  //{WLI}    IF EndingOffset - StartingOffset >= MaxAvail THEN
  //{WLI}        EndingOffset := StartingOffset + (MaxAvail - 5000);

  NumberBytes := EndingOffset - StartingOffset;

//  Seek(TRMasterFileRead, StartingOffset);
  Windows.SetFilePointer(TRMasterFileRead, StartingOffset, nil, FILE_BEGIN);

  CellBuffer.LoadCellIntoBuffer(KeyString, TRMasterFileRead, NumberBytes);
  InitialPartialCall := PartialCall;
end;

function CallDatabase.NumberOfBytesAtThisAddress(TwoLetters: Str20): LONGINT;

var
  X, Y                                  : integer;
  Difference, StartingOffset, EndingOffset: LONGINT;

begin
  if TwoLetters = '//' then
  begin
    NumberOfBytesAtThisAddress := 0;
    Exit;
  end;

  if not LoadInIndexArray then Exit;

  X := GetSCPIntegerFromChar(TwoLetters[1]);
  Y := GetSCPIntegerFromChar(TwoLetters[2]);

  if (X = -1) or (Y = -1) then
  begin
    NumberOfBytesAtThisAddress := 0;
    Exit;
  end;

  StartingOffset := SCPIndexArray^[X, Y];

  inc(Y);

  if Y > 36 then
  begin
    Y := 0;
    inc(X);
  end;

  EndingOffset := SCPIndexArray^[X, Y];
  Difference := EndingOffset - StartingOffset;
  NumberOfBytesAtThisAddress := Difference;
end;

procedure CallDatabase.ParseEntryToDataRecord(EntryString: ShortString {string}; var DataRecord: DataBaseEntryRecord);

{ This procedure will take a null terminated entry from the .DTA file
  and parse the data into the data record. }

var
  CharAddress                           : integer;

begin
  ClearDataEntry(DataRecord);

  with DataRecord do
  begin
    CharAddress := 1;

    repeat
      while EntryString[CharAddress] > ControlZ do
      begin
        Call := Call + EntryString[CharAddress];
        inc(CharAddress);
        if CharAddress > length(EntryString) then Exit;
      end;

      case EntryString[CharAddress] of

        ControlA:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              Section := Section + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlC:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              CQZone := CQZone + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlF:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              FOC := FOC + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlG:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              Grid := Grid + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlH:
          begin
            inc(CharAddress);
            Hits := Ord(EntryString[CharAddress]);
            inc(CharAddress);
          end;

        ControlI:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              ITUZone := ITUZone + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlK:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              Check := Check + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlN:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              mName := mName + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlO:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              OldCall := OldCall + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlQ:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              QTH := QTH + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlS:
          begin
            inc(CharAddress);
            Speed := Ord(EntryString[CharAddress]);
            inc(CharAddress);
          end;

        ControlT:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              TENTEN := TENTEN + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlU:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              User1 := User1 + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlV:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              User2 := User2 + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlW:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              User3 := User3 + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlX:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              User4 := User4 + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

        ControlY:
          begin
            inc(CharAddress);

            while EntryString[CharAddress] > ControlZ do
            begin
              User5 := User5 + EntryString[CharAddress];
              inc(CharAddress);
              if CharAddress > length(EntryString) then Exit;
            end;
          end;

      else Exit; { This should not happen! }
      end;

    until CharAddress >= length(EntryString);
  end;
end;

procedure CallDatabase.SaveDataToASCIIFile(var FileWrite: Text;
  NewData: DataBaseEntryRecord);

{ Saves the data in NewData to the file opened in FileWrite.  }

begin
  Write(FileWrite, NewData.Call);

  with NewData do
  begin
    if Section <> '' then Write(FileWrite, ' =A', Section);
    if CQZone <> '' then Write(FileWrite, ' =C', CQZone);
    if FOC <> '' then Write(FileWrite, ' =F', FOC);
    if Grid <> '' then Write(FileWrite, ' =G', Grid);
    if Hits > 0 then Write(FileWrite, ' =H', Hits);
    if ITUZone <> '' then Write(FileWrite, ' =I', ITUZone);
    if Check <> '' then Write(FileWrite, ' =K', Check);
    if mName <> '' then Write(FileWrite, ' =N', mName);
    if OldCall <> '' then Write(FileWrite, ' =O', OldCall);
    if QTH <> '' then Write(FileWrite, ' =Q', QTH);
    if Speed > 0 then Write(FileWrite, ' =S', Speed);
    if TENTEN <> '' then Write(FileWrite, ' =T', TENTEN);
    if User1 <> '' then Write(FileWrite, ' =U', User1);
    if User2 <> '' then Write(FileWrite, ' =V', User2);
    if User3 <> '' then Write(FileWrite, ' =W', User3);
    if User4 <> '' then Write(FileWrite, ' =X', User4);
    if User5 <> '' then Write(FileWrite, ' =Y', User5);
  end;

  WriteLn(FileWrite);

end;

procedure CallDatabase.SaveToASCIIFile;

{ This procedure will save the active file to the file ASCIIFileName.
  It will set the variable ASCIIFileIsCurrent to TRUE }

var
  CellSize         : LONGINT;
  FileRead                              : file;
  FileWrite                             : Text;
  X, Y, NextX, NextY, StartingOffset, EndingOffset: LONGINT;
  EntryString                           : ShortString {string};
  KeyString                             : CallString;
  DataRecord                            : DataBaseEntryRecord;

begin
  if not LoadInIndexArray then
  begin
    ShowMessage('Unable to save .DTA to ASCII file.');
    Exit;
  end;

  OpenFileForWrite(FileWrite, { WorkingDirectory + } ActiveASCIIFileName);

  //{WLI}    GoToXY (1, WhereY);
  ShowMessage('Saving .DTA file to ASCII file.  Processing cell   ');

  New(CallsAlreadySaved);

  for X := 0 to 36 do
    for Y := 0 to 36 do
    begin
      NumberCallsAlreadySaved := 0;

        //{WLI}            GoToXY (WhereX - 2, WhereY);
      KeyString := GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y);
        //      Write(KeyString);

      StartingOffset := SCPIndexArray^[X, Y];

      NextY := Y + 1;
      NextX := X;

      if NextY > 36 then
      begin
        if X < 36 then
        begin
          NextX := X + 1;
          NextY := 0;
          EndingOffset := SCPIndexArray^[NextX, NextY];
        end
        else
          EndingOffset := SCPEndOfFile;
      end
      else
        EndingOffset := SCPIndexArray^[NextX, NextY];

      if (X <> 0) or (Y <> 0) then
      begin
        if FilePos(FileRead) <> StartingOffset then
        begin
          Close(FileRead);
          Assign(FileRead, ActiveFilename);
          Reset(FileRead, 1);
          Seek(FileRead, StartingOffset);
        end;
      end
      else
      begin
        Assign(FileRead, ActiveFilename);
        Reset(FileRead, 1);
        Seek(FileRead, StartingOffset);
      end;

      if StartingOffset < EndingOffset then
      begin
        CellSize := EndingOffset - StartingOffset;

        if CellSize > BufferArraySize * 3 then
        begin

          ShowMessage(PChar(string(GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y) + ' cell is too large - 3!!')));
          halt;
        end;

//        CellBuffer.LoadCellIntoBuffer(KeyString, FileRead, CellSize);

        while CellBuffer.GetNextEntry(EntryString) do
        begin
          ParseEntryToDataRecord(EntryString, DataRecord);

          if FirstCellForThisCall(DataRecord.Call, X, Y) then
            if DoubleIndexCall(DataRecord.Call) then
            begin
              if not AlreadySaved(DataRecord.Call) then
                SaveDataToASCIIFile(FileWrite, DataRecord);

            end
            else
              SaveDataToASCIIFile(FileWrite, DataRecord);
        end;
      end;
    end;

  Dispose(CallsAlreadySaved);
  CellBuffer.GoAway;

  Closefile(FileWrite);
  Closefile(FileRead);

  ASCIIFileIsCurrent := True;
  ShowMessage('Data successfully saved to ASCII file.');

end;

procedure CallDatabase.TransferNewData(OldData: DataBaseEntryRecord; var NewData: DataBaseEntryRecord);

{ Moves any data found in OldData into the NewData variable if not found
  in the NewData entry }

begin
  if HitsOverwrite and (OldData.Hits < 255) then
    NewData.Hits := OldData.Hits + 1
  else
    NewData.Hits := OldData.Hits;

  with NewData do
  begin
    if (not SectionOverwrite) and (OldData.Section <> '') or (NewData.Section = '') then Section := OldData.Section;
    if (not CQZoneOverwrite) and (OldData.CQZone <> '') or (NewData.CQZone = '') then CQZone := OldData.CQZone;
    if (not FOCOverwrite) and (OldData.FOC <> '') or (NewData.FOC = '') then FOC := OldData.FOC;
    if (not GridOverwrite) and (OldData.Grid <> '') or (NewData.Grid = '') then Grid := OldData.Grid;
    if (not ITUZoneOverwrite) and (OldData.ITUZone <> '') or (NewData.ITUZone = '') then ITUZone := OldData.ITUZone;
    if (not CheckOverwrite) and (OldData.Check <> '') or (NewData.Check = '') then Check := OldData.Check;
    if (not NameOverwrite) and (OldData.mName <> '') or (NewData.mName = '') then mName := OldData.mName;
    if (not OldCallOverwrite) and (OldData.OldCall <> '') or (NewData.OldCall = '') then OldCall := OldData.OldCall;
    if (not QTHOverwrite) and (OldData.QTH <> '') or (NewData.QTH = '') then QTH := OldData.QTH;
    if (not SpeedOverwrite) and (OldData.Speed > 0) or (NewData.Speed = 0) then Speed := OldData.Speed;
    if (not TenTenOverwrite) and (OldData.TENTEN <> '') or (NewData.TENTEN = '') then TENTEN := OldData.TENTEN;
    if (not User1Overwrite) and (OldData.User1 <> '') or (NewData.User1 = '') then User1 := OldData.User1;
    if (not User2Overwrite) and (OldData.User2 <> '') or (NewData.User2 = '') then User2 := OldData.User2;
    if (not User3Overwrite) and (OldData.User3 <> '') or (NewData.User3 = '') then User3 := OldData.User3;
    if (not User4Overwrite) and (OldData.User4 <> '') or (NewData.User4 = '') then User4 := OldData.User4;
    if (not User5Overwrite) and (OldData.User5 <> '') or (NewData.User5 = '') then User5 := OldData.User5;
  end;
end;

function CallDatabase.PartialCallSetup(PartialCall: CallString): boolean;

{ Just call this routine, then call GetNextPartialCall until it returns
  nothing }

var
  CharPos                               : integer;

begin
  if not LoadInIndexArray then
  begin
    PartialCallSetup := False;
    Exit;
  end;

  PartialCallSetup := True;

  for CharPos := 1 to length(PartialCall) do
    if Copy(PartialCall, CharPos, 2) = CellBuffer.Key then
    begin { We have already read in a cell with this call }
      CellBuffer.ReadAddress := 0; { Rewind list }
      InitialPartialCall := PartialCall;
      Exit;
    end;

  NewTwoLetters(PartialCall);
end;

procedure CallDatabase.ASCIIFileEditor;
{
var
  ChangesMade, NeedToSaveLastRecord: boolean;
  data: DatabaseEntryRecord;
  Key: Char;
  Call: CallString;
  FileWrite: Text;
}
begin

  {    ChangesMade := False;
      NeedToSaveLastRecord := False;

      ClearScreenAndTitle ('TRMASTER EDITOR');

      WriteLn ('This editor will allow you to look at the data for any call in the TRMASTER');
      WriteLn ('database.  This editor will convert your .DTA file to an ASCII .ASC file');
      WriteLn ('which it will perform edits to.  When you are done, you will be asked if you');
      WriteLn ('want to save your changes by converting the edited .ASC file to the .DTA file.');
      WriteLn;
      WriteLn ('New calls may be added as well.');
      WriteLn;
      WriteLn ('Note that you will need to save the data back to the .DTA file before you can');
      WriteLn ('see the changes that you have made.  You will be prompted to do this when you');
      WriteLn ('have finished.');
      WriteLn;

      REPEAT
          Key := UpCase (GetKey ('Okay to proceed? (Y/N) : '));
          IF (Key = EscapeKey) OR (Key = 'N') THEN Exit;
      UNTIL Key = 'Y';
      WriteLn;

      IF NOT ASCIIFileIsCurrent THEN SaveToASCIIFile;

      WriteLn;

      REPEAT

  ///         This screen of code is basically doing the GetResponse function,
  //          with the added benefit of doing the ASCIIFileCrunch from the
  //          last entry if neceseary.

          TextColor (Cyan);
          Write ('Enter call to edit (none to quit): ');
          TextColor (Yellow);

          Call := '';

          REPEAT
              REPEAT
                  IF NOT ASCIIFileCrunch THEN
                      IF NeedToSaveLastRecord THEN
                          BEGIN
                          OpenFileForAppend (FileWrite, WorkingDirectory + ActiveASCIIFileName);
                          SaveDataToASCIIFile (FileWrite, Data);
                          Close (FileWrite);
                          CellBuffer.Key := '';
                          NeedToSaveLastRecord := False;
                          END;

              UNTIL KeyPressed;

              Key := UpCase (ReadKey);

              IF Key = CarriageReturn THEN
                  BEGIN
                  WriteLn;

                  IF ASCIIFileCrunch THEN
                      BEGIN
                      TextColor (Yellow);
                      Write ('Please give me a second to finish the last update...');

                      REPEAT UNTIL NOT ASCIIFileCrunch;
                      TextColor (Cyan);
                      GoToXY (1, WhereY);
                      ClrEol;
                      END;

                  IF NeedToSaveLastRecord THEN
                      BEGIN
                      OpenFileForAppend (FileWrite, WorkingDirectory + ActiveASCIIFileName);
                      SaveDataToASCIIFile (FileWrite, Data);
                      Close (FileWrite);
                      CellBuffer.Key := '';
                      NeedToSaveLastRecord := False;
                      END;

                  Break;
                  END;

               IF Key = BackSpace THEN
                  BEGIN
                  IF Call <> '' THEN
                      BEGIN
                      GoToXY (WhereX - 1, WhereY);
                      Write (' ');
                      GoToXY (WhereX - 1, WhereY);
                      Delete (Call, Length (Call), 1);
                      END;
                  END
              ELSE
                  BEGIN
                  Write (Key);
                  Call := Call + Key;
                  END;

          UNTIL Length (Call) >= 12;

          IF NeedToSaveLastRecord THEN
              BEGIN
              OpenFileForAppend (FileWrite, WorkingDirectory + ActiveASCIIFileName);
              SaveDataToASCIIFile (FileWrite, Data);
              Close (FileWrite);
              CellBuffer.Key := '';
              END;

          IF Call = '' THEN
              BEGIN
              IF ChangesMade THEN
                  BEGIN
                  GoTOXY (1, WhereY);
                  ClrEol;

                  REPEAT
                      Key := UpCase (GetKey ('Do you want to save your changes to TRMASTER.DTA? (Y/N) : '));
                  UNTIL (Key = 'Y') OR (Key = 'N');
                  WriteLn;
                  IF Key = 'Y' THEN BuildNewDatabaseFromASCIIFile (Chr (0));
                  END;

              Exit;
              END;

          GetEntry (Call, Data);

          IF Data.Call = '' THEN
              Data.Call := Call
          ELSE
              BEGIN    //Set up ASCII crunch process
              ASCIIFileCrunchCallToRemove := Call;
              OpenFileForRead  (ASCIIFileCrunchRead,  WorkingDirectory + ActiveASCIIFileName);
              OpenFileForWrite (ASCIIFileCrunchWrite, WorkingDirectory + TempFileName);
              END;

          REPEAT
              WITH Data DO
                  BEGIN
                  ClrScr;

                  TextColor (Yellow);
                  Write ('(C)');
                  TextColor (Cyan);
                  WriteLn ('all = ', Call);

                  TextColor (Yellow);
                  Write ('(A)');
                  TextColor (Cyan);
                  WriteLn ('RRL Section = ', Section);

                  Write ('CQ');
                  TextColor (Yellow);
                  Write ('(Z)');
                  TextColor (Cyan);
                  WriteLn ('one = ',  CQZone);

                  TextColor (Yellow);
                  Write ('(F)');
                  TextColor (Cyan);
                  WriteLn ('OC = ', FOC);

                  TextColor (Yellow);
                  Write ('(G)');
                  TextColor (Cyan);
                  WriteLn ('rid = ', Grid);

                  TextColor (Yellow);
                  Write ('(H)');
                  TextColor (Cyan);
                  WriteLn ('its = ', Hits);

                  TextColor (Yellow);
                  Write ('(I)');
                  TextColor (Cyan);
                  WriteLn ('TUZone = ', ITUZone);

                  Write ('Chec');
                  TextColor (Yellow);
                  Write ('(k)');
                  TextColor (Cyan);
                  WriteLn (' = ', Check);

                  TextColor (Yellow);
                  Write ('(N)');
                  TextColor (Cyan);
                  WriteLn ('ame = ', Name);

                  TextColor (Yellow);
                  Write ('(O)');
                  TextColor (Cyan);
                  WriteLn ('ldCall = ', OldCall);

                  TextColor (Yellow);
                  Write ('(Q)');
                  TextColor (Cyan);
                  WriteLn ('TH = ', QTH);

                  TextColor (Yellow);
                  Write ('(S)');
                  TextColor (Cyan);
                  WriteLn ('peed = ', Speed, '   Zero disables the speed function.');

                  TextColor (Yellow);
                  Write ('(T)');
                  TextColor (Cyan);
                  WriteLn ('enTen = ', TenTen);

                  TextColor (Cyan);
                  Write ('User');
                  TextColor (Yellow);
                  Write ('(1)');
                  TextColor (Cyan);
                  WriteLn (' = ', User1);

                  TextColor (Cyan);
                  Write ('User');
                  TextColor (Yellow);
                  Write ('(2)');
                  TextColor (Cyan);
                  WriteLn (' = ', User2);

                  TextColor (Cyan);
                  Write ('User');
                  TextColor (Yellow);
                  Write ('(3)');
                  TextColor (Cyan);
                  WriteLn (' = ', User3);

                  TextColor (Cyan);
                  Write ('User');
                  TextColor (Yellow);
                  Write ('(4)');
                  TextColor (Cyan);
                  WriteLn (' = ', User4);

                  TextColor (Cyan);
                  Write ('User');
                  TextColor (Yellow);
                  Write ('(5)');
                  TextColor (Cyan);
                  WriteLn (' = ', User5);

                  WriteLn;

                  REPEAT
                      GoToXY (1, WhereY);
                      ClrEol;
                      TextColor (Cyan);
                      Write ('Enter field ID to edit or ESCAPE if done with this call : ');

                      REPEAT
                          ASCIIFileCrunch
                      UNTIL KeyPressed;

                      Key := UpCase (ReadKey);
                      TextColor (Yellow);
                      IF Key >= ' ' THEN Write (Key);
                  UNTIL (Key = 'C') OR (Key = 'A') OR (Key = 'Z') OR (Key = 'F') OR
                        (Key = 'G') OR (Key = 'H') OR (Key = 'I') OR (Key = 'K') OR
                        (Key = 'N') OR (Key = 'O') OR (Key = 'Q') OR (Key = 'S') OR
                        (Key = 'T') OR (Key = '1') OR (Key = '2') OR (Key = '3') OR
                        (Key = '4') OR (Key = '5') OR (Key = EscapeKey);

                  IF Key <> EscapeKey THEN ChangesMade := True;

                  GoToXY (1, WhereY);
                  ClrEol;

                  CASE Key OF
                      'C': Call    := UpperCase (GetResponse ('Enter new call : '));
                      'A': Section := GetResponse ('Enter new ARRL section : ');
                      'Z': CQZone  := GetResponse ('Enter new CQ zone : ');
                      'F': FOC     := GetResponse ('Enter new FOC number : ');
                      'G': Grid    := GetResponse ('Enter new Grid : ');
                      'H': Hits    := GetValue    ('Enter new hit value (0-255) : ');
                      'I': ITUZone := GetResponse ('Enter new ITU zone : ');
                      'K': Check   := GetResponse ('Enter new check : ');
                      'N': Name    := GetResponse ('Enter new name : ');
                      'O': OldCall := GetResponse ('Enter new old call : ');
                      'Q': QTH     := GetResponse ('Enter new QTH : ');
                      'S': Speed   := GetValue    ('Enter code speed for this station : ');
                      'T': TenTen  := GetResponse ('Enter new TenTen number : ');
                      '1': User1   := GetResponse ('Enter new user 1 value : ');
                      '2': User2   := GetResponse ('Enter new user 2 value : ');
                      '3': User3   := GetResponse ('Enter new user 3 value : ');
                      '4': User4   := GetResponse ('Enter new user 4 value : ');
                      '5': User5   := GetResponse ('Enter new user 5 value : ');

                      EscapeKey:
                          BEGIN
                          IF ASCIIFileCrunch THEN
                              NeedToSaveLastRecord := True
                          ELSE
                              BEGIN
                              OpenFileForAppend (FileWrite, WorkingDirectory + ActiveASCIIFileName);
                              SaveDataToASCIIFile (FileWrite, Data);
                              Close (FileWrite);
                              CellBuffer.Key := '';
                              END;

                          Break;
                          END;
                      END;
                  END;
              UNTIL False;
      UNTIL False;
     }
end;

procedure CallDatabase.AddRecordToMergeList(data: DataBaseEntryRecord);

var
  ActiveRecord                          : DataListEntryPointer;

begin
  if FirstMergeDataListEntry = nil then
  begin
    FirstMergeDataListEntry := New(DataListEntryPointer);
    FirstMergeDataListEntry^.NextEntry := nil;
    FirstMergeDataListEntry^.data := data;
    Exit;
  end;

  { We have some entries already - make sure it isn't a dupe }

  ActiveRecord := FirstMergeDataListEntry;

  repeat
    if ActiveRecord^.data.Call = data.Call then Exit; { dupe - ignore it }
    if ActiveRecord^.NextEntry = nil then Break;
    ActiveRecord := ActiveRecord^.NextEntry;
  until False;

  { Okay, this call does not appear in the merge list, so add it }

  ActiveRecord^.NextEntry := New(DataListEntryPointer);
  ActiveRecord := ActiveRecord^.NextEntry;
  ActiveRecord^.NextEntry := nil;
  ActiveRecord^.data := data;
end;

function CallDatabase.OverwriteFlagStatus: boolean;
begin

end;

procedure CallDatabase.DeleteLowHitCalls;
begin

end;

procedure CallDatabase.MovePossibleCallsFromBufferIntoCallList(Call: CallString);

label
  CallFound;

var
  EntryString                           : ShortString {string};
  Address                               : integer;
  data                                  : DataBaseEntryRecord;

begin
  if CellBuffer.NumberBufferEntries = 0 then Exit; { No calls to move }

  CellBuffer.ReadAddress := 0; { Rewind list }

  while CellBuffer.GetNextEntry(EntryString) do
  begin
    ParseEntryToDataRecord(EntryString, data);

    if SimilarCall(Call, data.Call) then
      if (PossibleCallAction <> OnlyCallsWithNames) or (data.mName <> '') then
        if PossibleCallList.NumberPossibleCalls < MaximumPossibleCalls then
        begin
          if PossibleCallList.NumberPossibleCalls > 0 then
            for Address := 0 to PossibleCallList.NumberPossibleCalls - 1 do
              if PossibleCallList.List[Address].Call = data.Call then
                goto CallFound;

              { Call not in list and there is room for it }

          with PossibleCallList do
          begin
            List[NumberPossibleCalls].Call := data.Call;
            List[NumberPossibleCalls].Dupe := False;
            inc(NumberPossibleCalls);
          end;
        end;

    CallFound:
  end;
end;

procedure CallDatabase.GeneratePossibleCallList(Call: CallString);

{ This procedure will generate a list of possible callsigns for the one
  entered.  The list will be stored in the PossibleCalls list with
  NumberPossibleCalls indicating the number of callsigns found. }

var
  FirstKeyPos, SecondKeyPos, CharPos    : integer;
  LowestCell, SecondLowestCell, ThirdLowestCell, BytesAtThisPos: LONGINT;
  LowestKeyPos, SecondLowestKeyPos, ThirdLowestKeyPos: integer;
  TempDupe, Change                      : boolean;
  Range, CallAddress              : integer;
  TempString                            : CallString;

begin
  PossibleCallList.NumberPossibleCalls := 0;

  if not LoadInIndexArray then Exit;

  FirstKeyPos := 0;
  LowestKeyPos := 0;
  SecondLowestKeyPos := 0;
  ThirdLowestKeyPos := 0;

  LowestCell := AVeryBigNumber;
  SecondLowestCell := AVeryBigNumber;
  ThirdLowestCell := AVeryBigNumber;

  for CharPos := 1 to length(Call) - 1 do
  begin
    BytesAtThisPos := NumberOfBytesAtThisAddress(Copy(Call, CharPos, 2));

    if BytesAtThisPos < LowestCell then
    begin
      ThirdLowestCell := SecondLowestCell;
      ThirdLowestKeyPos := SecondLowestKeyPos;

      SecondLowestCell := LowestCell;
      SecondLowestKeyPos := LowestKeyPos;

      LowestCell := BytesAtThisPos;
      LowestKeyPos := CharPos;
    end
    else
      if BytesAtThisPos < SecondLowestCell then
      begin
        ThirdLowestCell := SecondLowestCell;
        ThirdLowestKeyPos := SecondLowestKeyPos;

        SecondLowestCell := BytesAtThisPos;
        SecondLowestKeyPos := CharPos;
      end
      else
        if BytesAtThisPos < ThirdLowestCell then
        begin
          ThirdLowestCell := BytesAtThisPos;
          ThirdLowestKeyPos := CharPos;
        end;
  end;

  for CharPos := 1 to length(Call) - 1 do
    if Copy(Call, CharPos, 2) = CellBuffer.Key then
    begin { We have already read in a cell for this call }
      MovePossibleCallsFromBufferIntoCallList(Call);
      FirstKeyPos := CharPos;
      Break;
    end;

  if FirstKeyPos = 0 then { Current buffer was no help }
  begin
    if Abs(LowestKeyPos - SecondLowestKeyPos) >= 2 then
    begin
      FirstKeyPos := LowestKeyPos;
      SecondKeyPos := SecondLowestKeyPos;
    end
    else
      if Abs(LowestKeyPos - ThirdLowestKeyPos) >= 2 then
      begin
        FirstKeyPos := LowestKeyPos;
        SecondKeyPos := ThirdLowestKeyPos;
      end
      else
      begin
        FirstKeyPos := SecondLowestKeyPos;
        SecondKeyPos := ThirdLowestKeyPos;
      end;

    NewTwoLetters(Copy(Call, FirstKeyPos, 2));
    MovePossibleCallsFromBufferIntoCallList(Call);
  end
  else
    if Abs(FirstKeyPos - LowestKeyPos) >= 2 then
      SecondKeyPos := LowestKeyPos
    else
      if Abs(FirstKeyPos - SecondLowestKeyPos) >= 2 then
        SecondKeyPos := SecondLowestKeyPos
      else
        SecondKeyPos := ThirdLowestKeyPos;

  NewTwoLetters(Copy(Call, SecondKeyPos, 2));
  MovePossibleCallsFromBufferIntoCallList(Call);

  { Sort the calls into alphabetical order }

  if PossibleCallList.NumberPossibleCalls < 2 then Exit; { No sorting needed }

  Range := PossibleCallList.NumberPossibleCalls - 2;

  repeat
    with PossibleCallList do
    begin
      Change := False;

      for CallAddress := 0 to Range do
        if List[CallAddress].Call > List[CallAddress + 1].Call then
        begin
          TempString := List[CallAddress].Call;
          List[CallAddress].Call := List[CallAddress + 1].Call;
          List[CallAddress + 1].Call := TempString;

          TempDupe := List[CallAddress].Dupe;
          List[CallAddress].Dupe := List[CallAddress + 1].Dupe;
          List[CallAddress].Dupe := TempDupe;

          Change := True;
        end;
    end;

    dec(Range);
  until (not Change) or (Range < 0);
end;


function CallDatabase.GetRandomCall: CallString;

var
  Call                                  : CallString;

begin
  repeat
    Call := RandomCall;
  until not StringIsAllNumbers(Call);

  GetRandomCall := Call;
end;

function CallDatabase.RandomCall: CallString;

var
  NextX, NextY, X, Y                    : Word;
  StartingOffset, Address, EndingOffset, Range: LONGINT;
  MiniBuffer                            : array[0..63] of Char;
  Call                                  : CallString;

begin
  if not LoadInIndexArray then
  begin
    case Random(4) of
      0: RandomCall := GetRandomLetter +
        GetRandomNumber +
          GetRandomLetter +
          GetRandomLetter;

      1: RandomCall := GetRandomLetter +
        GetRandomNumber +
          GetRandomLetter +
          GetRandomLetter +
          GetRandomLetter;

      2: RandomCall := GetRandomLetter +
        GetRandomLetter +
          GetRandomNumber +
          GetRandomLetter +
          GetRandomLetter +
          GetRandomLetter;

      3: RandomCall := GetRandomLetter +
        GetRandomLetter +
          GetRandomNumber +
          GetRandomLetter;

    end;

    Exit;
  end;

  X := Random(37);
  Y := Random(36);

  StartingOffset := SCPIndexArray^[X, Y];

  NextY := Y + 1;
  NextX := X;

  if NextY > 36 then
  begin
    if X < 36 then
    begin
      NextX := X + 1;
      NextY := 0;
      EndingOffset := SCPIndexArray^[NextX, NextY];
    end
    else
      EndingOffset := SCPEndOfFile;
  end
  else
    EndingOffset := SCPIndexArray^[NextX, NextY];

  Range := EndingOffset - StartingOffset;

  while Range > 65000 do Range := Range - 32000;

  Address := Random(Range) + StartingOffset;

  if Address + SizeOf(MiniBuffer) >=
//  FileSize(TRMasterFileRead)
  Windows.GetFileSize(TRMasterFileRead, nil)
    then
    Address := (Windows.GetFileSize(TRMasterFileRead, nil) {FileSize(TRMasterFileRead)} - SizeOf(MiniBuffer)) - 5;

//  Seek(TRMasterFileRead, Address);
  Windows.SetFilePointer(TRMasterFileRead, Address, nil, FILE_BEGIN);

  sReadFile(TRMasterFileRead, MiniBuffer, SizeOf(MiniBuffer));

  Address := 0;

  while MiniBuffer[Address] <> NullCharacter do
  begin
    inc(Address);

    if Address = 64 then
    begin
      RandomCall := 'N6TR';
      Exit;
    end;

  end;

  inc(Address);

  Call := '';

  while MiniBuffer[Address] > ControlZ do
  begin
    Call := Call + MiniBuffer[Address];
    inc(Address);

    if Address = 64 then
    begin
      while length(Call) < 4 do
        Call := Call + 'A';

      RandomCall := Call;
      Exit;
    end;
  end;

  RandomCall := Call;
end;

procedure CallDatabase.SCPDisableAndDeAllocateFileBuffer;

begin
  {   IF FileBuffer    <> nil THEN Dispose (FileBuffer);    6.43 }

  if TRMasterFileOpen then
  begin
    CloseHandle(TRMasterFileRead);
    Dispose(SCPIndexArray);
    TRMasterFileOpen := False;
    IndexArrayAllocated := False;
  end;

  SCPDisabledByApplication := True;
end;

procedure CallDatabase.ShowStatistics;

var
  Address, FileOffset                   : LONGINT;
  FileRead                              : file;
  BytesRead                             : Word;
  X, Y, Entry, NextX, NextY, StartingOffset, EndingOffset: LONGINT;
  EntryString                           : ShortString {string};
  DataRecord                            : DataBaseEntryRecord;

  TotalNames, TotalGrids, TotalSections, TotalCQZones, TotalFocs: LONGINT;
  TotalITUZones, TotalCalls, TotalChecks, TotalQTHs, TotalTenTens: LONGINT;
  NumberBytes, TotalOldCalls, TotalSpeeds: LONGINT;
  TotalUser1s, TotalUser2s, TotalUser3s, TotalUser4s, TotalUser5s: LONGINT;
  HitList                               : array[0..51] of LONGINT;
  KeyString, TempString                 : Str20;

begin
  //  ShowMessage('TRMASTER DATABASE STATISTICS');

  //  Write('Computing totals for cell AA');

  if SCPIndexArray = nil then { Make sure index array is loaded }
    if not LoadInIndexArray then
    begin
        //{WLI}            GoToXY (1, WhereY);
        //{WLI}            ClrEol;
      ShowMessage('No TRMASTER.DTA file found.');
        //{WLI}            WaitForKeyPressed;
      Exit;
    end;

  { Initialize counts }

  TotalCalls := 0;
  TotalNames := 0;
  TotalGrids := 0;
  TotalSections := 0;
  TotalCQZones := 0;
  TotalFocs := 0;
  TotalITUZones := 0;
  TotalChecks := 0;
  TotalOldCalls := 0;
  TotalQTHs := 0;
  TotalTenTens := 0;
  TotalSpeeds := 0;
  TotalUser1s := 0;
  TotalUser2s := 0;
  TotalUser3s := 0;
  TotalUser4s := 0;
  TotalUser5s := 0;

  for Entry := 0 to 51 do HitList[Entry] := 0;

  for X := 0 to 36 do
    for Y := 0 to 36 do
    begin
        //{WLI}            GoToXY (WhereX - 2, WhereY);
      KeyString := GetSCPCharFromInteger(X) + GetSCPCharFromInteger(Y);
        //{WLI}            Write (KeyString);

      StartingOffset := SCPIndexArray^[X, Y];

      NextY := Y + 1;
      NextX := X;

      if NextY > 36 then
      begin
        if X < 36 then
        begin
          NextX := X + 1;
          NextY := 0;
          EndingOffset := SCPIndexArray^[NextX, NextY];
        end
        else
          EndingOffset := SCPEndOfFile;
      end
      else
        EndingOffset := SCPIndexArray^[NextX, NextY];

      if (X <> 0) or (Y <> 0) then
      begin
        if FilePos(FileRead) <> StartingOffset then
        begin
          Close(FileRead);
          Assign(FileRead, ActiveFilename);
          Reset(FileRead, 1);
          Seek(FileRead, StartingOffset);
        end;
      end
      else
      begin
        Assign(FileRead, ActiveFilename);
        Reset(FileRead, 1);
        Seek(FileRead, StartingOffset);
      end;

      if StartingOffset < EndingOffset then
      begin
        NumberBytes := EndingOffset - StartingOffset;

        if NumberBytes > BufferArraySize * 3 then
        begin
                //        WriteLn;
//          showmessage(GetSCPCharFromInteger(x) + GetSCPCharFromInteger(y) + ' cell is too large - 5!!');
          halt;
        end;

//        CellBuffer.LoadCellIntoBuffer(KeyString, FileRead, NumberBytes);

        while CellBuffer.GetNextEntry(EntryString) do
        begin
          ParseEntryToDataRecord(EntryString, DataRecord);

          if FirstCellForThisCall(DataRecord.Call, X, Y) then
          begin
            inc(TotalCalls);

            with DataRecord do
            begin
              if mName <> '' then inc(TotalNames);
              if Grid <> '' then inc(TotalGrids);
              if Section <> '' then inc(TotalSections);
              if CQZone <> '' then inc(TotalCQZones);
              if FOC <> '' then inc(TotalFocs);
              if ITUZone <> '' then inc(TotalITUZones);
              if Check <> '' then inc(TotalChecks);
              if QTH <> '' then inc(TotalQTHs);
              if OldCall <> '' then inc(TotalOldCalls);
              if Speed > 0 then inc(TotalSpeeds);
              if TENTEN <> '' then inc(TotalTenTens);
              if User1 <> '' then inc(TotalUser1s);
              if User2 <> '' then inc(TotalUser2s);
              if User3 <> '' then inc(TotalUser3s);
              if User4 <> '' then inc(TotalUser4s);
              if User5 <> '' then inc(TotalUser5s);

              if Hits <= 50 then
                inc(HitList[Hits])
              else
                inc(HitList[51]);
            end;
          end;
        end;
      end;
    end;

  //{WLI}    GoToXY (1, WhereY);
  //{WLI}    ClrEol;
  {
      Write   ('Total calls = ', TotalCalls);
      GoToXY (40, WhereY);
      WriteLn ('Total QTHs = ', TotalQTHs);

      Write   ('Total Names = ', TotalNames);
      GoToXY (40, WhereY);
      WriteLn ('Total Grids = ', TotalGrids);

      Write   ('Total CQ Zones = ', TotalCQZones);
      GoToXY (40, WhereY);
      WriteLn ('Total ITU Zones = ', TotalITUZones);

      Write   ('Total Checks = ', TotalChecks);
      GoToXY (40, WhereY);
      WriteLn ('Total Sections = ', TotalSections);

      Write   ('Total TenTens = ', TotalTenTens);
      GoToXY (40, WhereY);
      WriteLn ('Total FOCs = ', TotalFOCs);

      Write   ('Total User1s = ', TotalUser1s);
      GoToXY (40, WhereY);
      WriteLn ('Total User2s = ', TotalUser2s);

      Write   ('Total User3s = ', TotalUser3s);
      GoToXY (40, WhereY);
      WriteLn ('Total User4s = ', TotalUser4s);

      Write   ('Total User5s = ', TotalUser5s);
      GoToXY (40, WhereY);
      WriteLn ('Total CW Speeds = ', TotalSpeeds);

      WriteLn ('Total OldCalls = ', TotalOldCalls);

      WriteLn;
  }
  ShowMessage('Hit count histogram for 0 to 50+ : ');
  {
      FOR Entry := 0 TO 51 DO
          BEGIN
          IF WhereX > 68 THEN WriteLn;

          IF Entry < 51 THEN
              Write (Entry:3, ': ', HitList [Entry])
          ELSE
              Write ('More than 50 = ', HitList [51]);

          WHILE ((WhereX MOD 12) <> 0) AND (WhereX < 77) DO Write (' ');
          END;
  }
  //{WLI}    WriteLn;
  //{WLI}    WaitForKeyPressed;
end;

procedure ShowNameEditorCommands;

begin
  {    ClearScreenAndTitle ('TRMASTER NAME EDITOR PROGRAM');

      WriteLn ('This editor allows you to quickly edit the names in your TRMASTER database.');
      WriteLn;
      WriteLn ('Since the TRMASTER.DTA file can''t be edited quickly, this procedure will');
      WriteLn ('stop occasionally to update the files.  Because of this, the changes you');
      WriteLn ('had just typed in will not take effect until this process occurs.');
      WriteLn;
      WriteLn ('Changes are first made to the TRMASTER.ASC file.  They are not saved in');
      WriteLn ('the TRMASTER.DTA file until the end of this procedure.');
      WriteLn;
      WriteLn ('Single letter commands: C - Toggle CW sending of names.');
      WriteLn ('                        D - Delete a call from the database.');
      WriteLn ('                        F - Make ASCII file with calls and names.');
      WriteLn ('                        X - Quit editing and save changes.');
      WriteLn;
     }
end;

function CallHasNoNumber(Call: CallString): boolean;

var
  CharPointer                           : integer;

begin
  if Call = '' then
  begin
    CallHasNoNumber := True;
    Exit;
  end;

  CallHasNoNumber := False;

  for CharPointer := 1 to length(Call) do
    if ((Call[CharPointer] >= '0') and (Call[CharPointer] <= '9')) then
      Exit;

  CallHasNoNumber := True;
end;

procedure CallDatabase.CheckDTAFile;

{ This procedure will do the following:

    1. Load in the index file of the TRMASTER.DTA file.

    2. Check to see if the JA cell has stuff in it - if so, the .DTA
       file will be rewritten with no calls in the JA cell.

    3. Check to make sure no remaining cell is over BufferArraySize
       bytes and if so - truncate it.

  The result is a new .DTA file.  The .ASC file is not changed. }

begin

end;

{ --------------------------------------------------------------------------
  Operator name set — built once from TRMASTER.DTA, searched by callers
  that need to recognise a token as an operator name.
  -------------------------------------------------------------------------- }

procedure CallDatabase.BuildOperatorNameSet(Names: TStringList);
{ Opens a private read handle to TRMASTER.DTA, walks every 37×37 cell,
  and adds each non-empty operator name (uppercased) to Names.
  The shared TRMasterFileRead handle and CellBuffer state are untouched. }
var
   FileHandle  : HWND;
   LocalBuf    : CellBufferObject;
   X           : Integer;
   Y           : Integer;
   StartOffset : LONGINT;
   EndOffset   : LONGINT;
   NumBytes    : LONGINT;
   EntryStr    : ShortString;
   Rec         : DataBaseEntryRecord;
begin
   if not LoadInIndexArray then
      Exit;
   if not tOpenFileForRead(FileHandle, ActiveFilename) then
      Exit;
   FillChar(LocalBuf, SizeOf(LocalBuf), 0);
   LocalBuf.MaximumMemoryToUse := BufferArraySize;
   try
      for X := 0 to 36 do
         begin
         for Y := 0 to 36 do
            begin
            StartOffset := SCPIndexArray^[X, Y];
            { End offset = start of the next cell; the very last cell uses SCPEndOfFile }
            if Y < 36 then
               EndOffset := SCPIndexArray^[X, Y + 1]
            else if X < 36 then
               EndOffset := SCPIndexArray^[X + 1, 0]
            else
               EndOffset := SCPEndOfFile;
            NumBytes := EndOffset - StartOffset;
            if NumBytes <= 0 then
               Continue;
            if NumBytes > BufferArraySize then
               NumBytes := BufferArraySize;
            Windows.SetFilePointer(FileHandle, StartOffset, nil, FILE_BEGIN);
            LocalBuf.LoadCellIntoBuffer('', FileHandle, NumBytes);
            while LocalBuf.GetNextEntry(EntryStr) do
               begin
               ParseEntryToDataRecord(EntryStr, Rec);
               if Rec.mName <> '' then
                  Names.Add(UpperCase(Rec.mName));
               end;
            end;
         end;
   finally
      LocalBuf.GoAway;
      CloseHandle(FileHandle);
      end;
end;

procedure InitOperatorNameSet;
{ Builds OperatorNameSet from TRMASTER.DTA on first call (idempotent).
  MasterFileExists is set at startup before ActiveFilename is populated,
  so we do a live check here now that the contest has set the filename. }
begin
   if OperatorNameSet <> nil then
      Exit;
   CD.MasterFileExists := (CD.ActiveFilename[0] <> #0) and
      FileExists(CD.ActiveFilename);
   if not CD.MasterFileExists then
      begin
      logger.Debug('InitOperatorNameSet: TRMASTER.DTA not found — name lookup disabled');
      Exit;
      end;
   OperatorNameSet            := TStringList.Create;
   OperatorNameSet.Sorted     := True;
   OperatorNameSet.Duplicates := dupIgnore;
   CD.BuildOperatorNameSet(OperatorNameSet);
   logger.Debug('OperatorNameSet: ' + IntToStr(OperatorNameSet.Count) +
      ' names loaded from TRMASTER.DTA');
end;

function NameInOperatorSet(const AName: string): Boolean;
begin
   Result := (OperatorNameSet <> nil) and
      (OperatorNameSet.IndexOf(UpperCase(AName)) >= 0);
end;

begin

//  CD.CellBuffer.Buffer1Used := False;
//  CD.CellBuffer.Buffer2Used := False;
//  CD.CellBuffer.Buffer3Used := False;

  CD.CellBuffer.MaximumMemoryToUse := 3 * BufferArraySize;

//  CD.CellBuffer.MemoryAllocated := 0;

//  CD.SCPDisabledByApplication := False;

//  CD.ASCIIFileCrunchCallToRemove := '';
//  CD.ASCIIFileIsCurrent := False;
  CD.ActiveASCIIFileName := ASCIIFileName;
//  CD.CountryString := '';

//  CD.CellBuffer.Key := '';
//  CD.PossibleCallAction := OnlyCallsWithNames;
//  CD.FirstMergeDataListEntry := nil;
//  CD.InitialPartialList := nil;
//  CD.SCPIndexArray := nil;
//  CD.SectionOverwrite := False;
//  CD.CQZoneOverwrite := False;
//  CD.FOCOverwrite := False;
//  CD.GridOverwrite := False;
  CD.HitsOverwrite := True;
//  CD.TRMasterFileOpen := False;
//  CD.IndexArrayAllocated := False;
//  CD.ITUZoneOverwrite := False;
//  CD.CheckOverwrite := False;
//  CD.NameOverwrite := False;
//  CD.NumberDeleteCalls := 0;
//  CD.OldCallOverwrite := False;
//  CD.QTHOverwrite := False;
//  CD.SpeedOverwrite := False;
//  CD.TenTenOverwrite := False;
//  CD.User1Overwrite := False;
//  CD.User2Overwrite := False;
//  CD.User3Overwrite := False;
//  CD.User4Overwrite := False;
//  CD.User5Overwrite := False;

end.

