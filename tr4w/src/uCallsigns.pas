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
unit uCallsigns;
{$IMPORTEDDATA OFF}
interface

uses
//  SysUtils,
  VC,
  TF,
  Windows,
  Messages,
  Tree,
  LogRadio,
  LogSCP;

const
  MAXCALLSIGNSINLIST                    = 100000;           // 4.115.6

type
  PCallsignItem = ^TCallsignItem;

  TPossibleCalls = record
    FCall: CallString;
    FDupe: boolean;
  end;

  TCallsignItem = record
    {16}FDupesArray: TDupesArray;

    {14}FCall: CallString;
    {01}FQSOs: Byte;
    {01}res1: Byte;

    {14}FInExchange: String[14];
    {01}res2: Byte;
//    {01}res3: Byte;
  end;

  TCallsignItemList = array[0..MAXCALLSIGNSINLIST - 1] of TCallsignItem;
  PCallsignItemList = ^TCallsignItemList;

  TCallsignsList = object {class}
  private
    FList: PCallsignItemList;
    FCount: integer;
    FCapacity: integer;
    //    FPartialList: array[0..9] of TPossibleCalls;
    procedure Grow;
  protected
    function GetCapacity: integer;
    procedure SetCapacity(NewCapacity: integer);
    function CompareStrings(const s1, s2: CallString): integer;
    procedure InsertCallsign(Index: integer; const s: CallString); virtual;
  public
//  destructor Destroy; override;
    constructor Init;
    function Get(Index: integer): CallString;
    function GetQSOs(Index: integer): Byte;
    function GetDupesArray(Index: integer; var da: TDupesArray): boolean;

    function GetTotalWorkedStations: integer;
    function AddCallsign(const s: CallString; Mode: ModeType; Band: BandType; JustAddToList: boolean): integer;
    function AddIniitialExchange(const Call:CallString; InitialExchangeString: Str14): boolean;
    function GetIniitialExchange(const Call: CallString): Str14;
    function GetIniitialExchangeByIndex(Index: integer): CallString;
    function CallsignIsDupe(const s: CallString; Band: BandType; Mode: ModeType; var IndexInList: integer): boolean;
//    procedure Clear;
//    procedure Delete(Index: integer);
    procedure ClearDupes;
    procedure DisplayDupeSheet(Radio: RadioPtr {dBand: BandType; dMode: ModeType});
    function CreatePartialsList(Call: CallString): integer;
    function FindCallsign(const s: CallString; var Index: integer): boolean; virtual;
    function FindNumber(s: CallString): boolean; virtual;  // n4af 4.42.2

    property Count: integer read FCount;
  end;

const
  MaxCallsignsInPossibleCallsList       = 9;
var
  CallsignsList                         : TCallsignsList;
//  PossibleCallsList                     : array[0..MaxCallsignsInPossibleCallsList - 1] of TPossibleCalls;

implementation
uses
  SysUtils,            // Issue #997 - SysUtils.Format / StrPCopy
  LogStuff,
  LogDupe,
  LogWind;

{ TStringList }

constructor TCallsignsList.Init;
begin
  Grow;
end;
{
destructor TCallsignsList.Destroy;
begin
  inherited Destroy;
  if FCount <> 0 then Finalize(FList^[0], FCount);
  FCount := 0;
  SetCapacity(0);
end;
}

function TCallsignsList.GetIniitialExchangeByIndex(Index: integer): CallString;
begin
  Result := FList^[Index].FInExchange
end;

function TCallsignsList.GetIniitialExchange(const Call: CallString): Str14;
var
  Index                                 : integer;
begin
  if FindCallsign(Call, Index) then
    Result := FList^[Index].FInExchange
     else
      Result := '';
end;

function TCallsignsList.AddIniitialExchange(const Call:CallString; InitialExchangeString: Str14): boolean;
label
  Add;
var
  Index                                 : integer;
begin
  if FindCallsign(Call, Index) then
  begin
    Result := False;
    goto Add;
  end;
  if Count = MAXCALLSIGNSINLIST then Exit;
  InsertCallsign(Index, Call);
  Result := True;
  Add:
  FList^[Index].FInExchange := InitialExchangeString;
end;

function TCallsignsList.GetTotalWorkedStations: integer;
var
  i                                     : integer;
begin
  Result := 0;
  for i := 0 to Count - 1 do
    if FList^[i].FQSOs > 0 then inc(Result);
end;

function TCallsignsList.AddCallsign(const s: CallString; Mode: ModeType; Band: BandType; JustAddToList: boolean): integer;
label
  Add;
var
  Value                                 : integer;

begin

  if FindCallsign(s, Result) then goto Add;
  if Count = MAXCALLSIGNSINLIST then Exit;
  InsertCallsign(Result, s);
  Add:
 if   FList^[Result].FQSOs < 255 then  //n4af 4.35.8
  inc(FList^[Result].FQSOs);

  if JustAddToList then Exit;

  Value := FList^[Result].FDupesArray[Mode];
  FList^[Result].FDupesArray[Mode] := Value or (1 shl Ord(Band));

  Value := FList^[Result].FDupesArray[Both];
  FList^[Result].FDupesArray[Both] := Value or (1 shl Ord(Band));

  Value := FList^[Result].FDupesArray[Mode];
  FList^[Result].FDupesArray[Mode] := Value or (1 shl Ord(AllBands));

  Value := FList^[Result].FDupesArray[Both];
  FList^[Result].FDupesArray[Both] := Value or (1 shl Ord(AllBands));

end;

function TCallsignsList.CallsignIsDupe(const s: CallString; Band: BandType; Mode: ModeType; var IndexInList: integer): boolean;
var
  Index                                 : integer;
  TempMode                              : ModeType;
  TempBand                              : BandType;
begin
  Result := False;
  if FindCallsign(s, Index) then
  begin
//    TempMode := Mode;
    if QSOByMode then TempMode := Mode else TempMode := Both;
    if QSOByBand then TempBand := Band else TempBand := AllBands;

    if TempMode = FM then TempMode := Phone;

    Result := (FList^[Index].FDupesArray[TempMode {Mode}] and (1 shl Ord(TempBand))) <> 0;
    IndexInList := Index;
  end
  else
    IndexInList := -1;
end;
{
procedure TCallsignsList.Clear;
begin
  if FCount <> 0 then
  begin
    Finalize(FList^[0], FCount);
    FCount := 0;
    SetCapacity(0);
  end;
end;

procedure TCallsignsList.Delete(Index: integer);
begin
  if (Index < 0) or (Index >= FCount) then Exit; //Error(@SListIndexError, Index);
  Finalize(FList^[Index]);
  dec(FCount);
  if Index < FCount then System.Move(FList^[Index + 1], FList^[Index], (FCount - Index) * SizeOf(TCallsignItem));
end;
}
{
procedure TCallsignsList.ExchangeItems(Index1, Index2: integer);
var
  temp                             : integer;
  Item1, Item2                     : PStringItem;
  DI                               : TDupesArray;
begin
  Item1 := @FList^[Index1];
  Item2 := @FList^[Index2];
  temp := integer(Item1^.FCall);
  integer(Item1^.FCall) := integer(Item2^.FCall);
  integer(Item2^.FCall) := temp;
  //  temp := integer(Item1^.FObject);
  //  integer(Item1^.FObject) := integer(Item2^.FObject);
  //  integer(Item2^.FObject) := temp;

  DI := Item1^.FDupesArray;
  Item1^.FDupesArray := Item2^.FDupesArray;
  Item2^.FDupesArray := DI;
end;
}

function TCallsignsList.FindCallsign(const s: CallString; var Index: integer): boolean;
var
  l, h, i, c                            : integer;

  begin
  Result := False;
  l := 0;
  h := FCount - 1;
  while l <= h do
  begin
    i := (l + h) shr 1;
    c := CompareStrings(FList^[i].FCall, s);
    if c < 0 then
     l := i + 1
     else
    begin
      h := i - 1;
      if c = 0 then
      begin
        Result := True;
        l := i;
      end;
    end;
  end;
  Index := l;
end;


function TCallsignsList.FindNumber( s: CallString): boolean;         // n4af 4.42.2 reverse lookup member #
var
 i, {l,} h, c                             : integer;
 lstr                                    : string;
begin
  Result := False;
  i := -1; //4.67.3
  h := FCount - 1;
  while i <= h do
  begin
    i := (i + 1);
  lstr := laststring(Flist[i].Finexchange);
   c := CompareStrings(lstr, s);
    if c = 0 then
    begin
    Result := True;
    CallWindowString :=  flist^[i].FCall;
    
    exit; 
      end;
    end;
  end;


function TCallsignsList.Get(Index: integer): CallString;
begin
  //  if (Index < 0) or (Index >= FCount) then Exit; //ERROR(@SListIndexError, Index);
  Result := FList^[Index].FCall;
end;

function TCallsignsList.GetQSOs(Index: integer): Byte;
begin
  Result := 0;
  if Index = -1 then Exit;

  Result := FList^[Index].FQSOs;
end;

function TCallsignsList.GetDupesArray(Index: integer; var da: TDupesArray): boolean;
begin
  Result := False;
  if Index = -1 then Exit;
  da := FList^[Index].FDupesArray;
  Result := True;
end;

function TCallsignsList.GetCapacity: integer;
begin
  Result := FCapacity;
end;

procedure TCallsignsList.Grow;
var
  delta                                 : integer;
begin
  if FCapacity > 64 then delta := FCapacity div 4 else
    if FCapacity > 8 then delta := 16 else
      delta := 4;
  SetCapacity(FCapacity + delta);
end;

procedure TCallsignsList.InsertCallsign(Index: integer; const s: CallString);
begin

  if FCount = FCapacity then Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(TCallsignItem));

  Windows.ZeroMemory(@FList^[Index], SizeOf(FList^[Index]));
  FList^[Index].FCall := s;
//  with FList^[Index] do
//  begin
//    Windows.ZeroMemory(@FDupesArray, SizeOf(TDupesArray));
//    FQSOs := 0;
//    FCall := s;
//    FInExchange := '';
//  end;
  inc(FCount);

end;

procedure TCallsignsList.SetCapacity(NewCapacity: integer);
begin
  ReallocMem(FList, NewCapacity * SizeOf(TCallsignItem));
  FCapacity := NewCapacity;
end;

function TCallsignsList.CompareStrings(const s1 {edx}, s2 {ecx}: CallString): integer {eax};
begin
  Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @s1[1], length(s1), @s2[1], length(s2)) - 2;

{
  Result := 0;
  if s1 <> s2 then
  begin
    asm
    JBE @@L
    JNE @@G
@@L:MOV RESULT,-1
    JMP @@E
@@G:MOV RESULT, 1
@@E:
    end;
  end;
}
{
  if s1 = s2 then result := 0
  else
    if s1 < s2 then result := -1
    else
      result := 1;
}

//  if s1[0] > s2[0] then l := length(s2) else l := length(s1);
{
  asm
  push ebx
  push ecx
  push edi
  push esi

  xor ebx, ebx
  mov bl,byte ptr [edx]
  sub bl,byte ptr [ecx]//>0 length(s1)>length(s2)

  xor eax, eax
  mov al,byte ptr [edx]
  cmp al,byte ptr [ecx]
  jbe  @@1
  mov al,byte ptr [ecx]

@@1:

  MOV ESI,ecx
  MOV EDI,edx
  add esi,1
  add edi,1

  mov ecx,eax//3

  REPE CMPSB
  JZ   @@EQUAL
  JB   @@LESS

@@GREAT:
  MOV EDX,-1
  JMP @@EXIT

@@EQUAL:
//  CMP EBX ,0
//  JL  @@LESS
//  JNZ  @@GREAT
  MOV EDX,EBX
  JMP @@EXIT

@@LESS:
  MOV EDX,1
  JMP @@EXIT

  @@EXIT:

  pop esi
  pop edi
  pop ecx
  pop ebx
  end;
}

//  RESULT := StrComp(@s1[1], @s2[1]);
//  RESULT := Windows.lstrcmp(@s1[1], @s2[1]);

end;

function TCallsignsList.CreatePartialsList(Call: CallString): integer;
label
  1;
var
  Index                                 : integer;
  TempIndex                             : integer;
//  TempMode                              : ModeType;
begin
  if not PossibleCallEnable then Exit;
  tLB_RESETCONTENT(wh[mwePossibleCall]);
  if length(Call) < 2 then Exit;
  Result := 0;
  for Index := 0 to FCount - 1 do
  begin
    if pos(Call, FList^[Index].FCall) > 0 then
    begin
//      if QSOByMode then TempMode := ActiveMode else TempMode := Both;
//      if TempMode = FM then TempMode := Phone;
      PossibleCallList.List[Result].Call := FList^[Index].FCall;
      PossibleCallList.List[Result].Dupe :=
        CallsignIsDupe(FList^[Index].FCall, ActiveBand, ActiveMode, TempIndex);
//      (FList^[Index].FDupesArray[TempMode] and (1 shl Ord(ActiveBand))) <> 0;
      SendMessage(wh[mwePossibleCall], LB_ADDSTRING, 0, Result);
      inc(Result);
      if Result = MaxCallsignsInPossibleCallsList then goto 1;
    end;
  end;
  1:
  if Result > 0 then SendMessage(wh[mwePossibleCall], LB_SETCURSEL, 0, 0);
end;

procedure TCallsignsList.DisplayDupeSheet(Radio: RadioPtr {dBand: BandType; dMode: ModeType});
var
  TempDSHandle                          : HWND;
  VDListBox                             : HWND;
  i, Index                              : integer;

  Band                                  : BandType;
  Mode                                  : ModeType;
  TempChar                              : Char;
  Item                                  : integer;
  p1                                    : pchar;
  p2                                    : pchar;
begin
//  if not Sheet.DupeSheetEnable then Exit;
  TempDSHandle := Radio.tDupeSheetWnd;// tr4w_WindowsArray[tw_DUPESHEETWINDOW1_INDEX].WndHandle;
  if TempDSHandle = 0 then Exit;

  VDListBox := Windows.GetDlgItem(TempDSHandle, 101);

  Band := Radio.BandMemory;
  Mode := Radio.ModeMemory;

  if not ColumnDupeSheetEnable then      //n4af 04.33.7 reactive columndupesheetenable
  SendMessage(VDListBox, LB_RESETCONTENT, 0, 0) 
  else
    for Index := 48 to 57 do SendDlgItemMessage(TempDSHandle, Index, LB_RESETCONTENT, 0, 0);

   SendMessage(VDListBox, WM_SETREDRAW, wParam(False), 0);

  for TempChar := '0' to '9' do
  begin
    for Index := 0 to FCount - 1 do
    begin
      if (FList^[Index].FDupesArray[Mode] and (1 shl Ord(Band))) <> 0 then
      begin
      {$RangeChecks OFF}
        for i := 0 to length(FList^[Index].FCall) do        // 4.79.3
          if FList^[Index].FCall[i - 1] in ['A'..'Z'] then
            if FList^[Index].FCall[i] in ['0'..'9'] then
            begin
              if FList^[Index].FCall[i] = TempChar then
              begin
            if ColumnDupeSheetEnable then
             SendDlgItemMessage(TempDSHandle, Ord(FList^[Index].FCall[i]), LB_ADDSTRING, 0, integer(@FList^[Index].FCall[1]))
           else
                Item := SendMessage(VDListBox, LB_ADDSTRING, 0, integer(@FList^[Index].FCall[1]));
                SendMessage(VDListBox, LB_SETITEMDATA, Item, Ord(TempChar));
              end;
              Break;
            end;
      end;
      
    end;
 //   if not ColumnDupeSheetEnable then
    begin
 //   Item := SendDlgItemMessage(TempDSHandle, 101, LB_ADDSTRING, 0, integer(pchar('*********')));

 //   Item := SendMessage(VDListBox, LB_ADDSTRING, 0, integer(PChar('---------')));
 //   SendMessage(VDListBox, LB_SETITEMDATA, Item, Ord(TempChar));
    end;
  end;

  SendDlgItemMessage(TempDSHandle, 101, WM_SETREDRAW, wParam(True), 0);

  P1 := BandStringsArray[Band];
  P2 := ModeStringarray[Mode];
  // Issue #997: removed orphaned `asm push p2/push p1` -- leftover from the
  // earlier conversion below; the SysUtils.Format call replaced the wsprintf
  // that consumed these pushes, and the matching `add esp,16` was already
  // commented out, so the pushes fed nothing (absorbed by the stack frame).

  // Issue #997 - wsprintf-push formatting converted to SysUtils.Format
  StrPCopy(wsprintfBuffer, SysUtils.Format(TC_DUPESHEET+' - %s',
    [string(BandStringsArray[Band]), string(ModeStringArray[Mode]), string(PChar(@Radio.RadioName[1]))]));
//  asm add esp,16  end;
  Windows.SetWindowText(Radio.tDupeSheetWnd, wsprintfBuffer);
end;

procedure TCallsignsList.ClearDupes;
var
  Index                                 : integer;
begin
  for Index := 0 to FCount - 1 do
  begin
    Windows.ZeroMemory(@FList^[Index].FDupesArray, SizeOf(TDupesArray));
    FList^[Index].FQSOs := 0;
      {
            for Band := Band160 to AllBands do
              for Mode := CW to Both do
                FList^[Index].FDupesArray[Mode, Band] := 0;
      }
  end;
end;

begin
//  CallsignsList := TCallsignsList.Create;
  CallsignsList.Init;
end.



