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
unit uSSL;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  // Issue #1034: dropped 'TF' (unused here) -- it pulled TF -> MainUnit -> LogStuff,
  // which blocked uSSL (and its uMults consumer) from linking into the test EXE.
  //Country9,
  Windows,
  Messages;

type

  PStringItem = ^TStringItem;

  TStringItem = record
    FMult: Str10;
    FArray: TDupesArray;
    FAltName: Str30;
  end;

  PStringItemList = ^TStringItemList;
  TStringItemList = array[0..10000] of TStringItem;

  TSSL = object {class}
  private
    FCount: integer;
    FCapacity: integer;
//    FTotalMults: array[ModeType] of integer;
    procedure Grow;
  protected
    function GetCapacity: integer;
    procedure SetCapacity(NewCapacity: integer);
    function CompareStrings(const s1, s2: Str10): integer;
    procedure InsertMult(Index: integer; const s: Str10; Band: BandType; Mode: ModeType); virtual;
  public
    FList: PStringItemList;
    TotalMults: integer;
//    destructor Destroy; override;
    constructor Init;
    function StringIsDupeByIndex(IndexInList: integer; Band: BandType; Mode: ModeType): boolean;
    function StringIsDupe(const s: CallString; Band: BandType; Mode: ModeType; var IndexInList: integer): boolean;
    function Get(Index: integer): Str10;
    function AddString(const s: Str10; Band: BandType; Mode: ModeType; JustAdd: boolean): integer;
    procedure Clear;
    procedure Delete(Index: integer);
    procedure ClearDupes;
    function FindMult(const s: Str10; var Index: integer): boolean; virtual;
    property Count: integer read FCount;
//    property TotalMults: integer read FTotalMults;

  end;

implementation

constructor TSSL.Init;
begin
  Grow;
end;

{
destructor TSSL.Destroy;
begin
  inherited Destroy;
  if FCount <> 0 then Finalize(FList^[0], FCount);
  FCount := 0;
  SetCapacity(0);
end;
}

function TSSL.AddString(const s: Str10; Band: BandType; Mode: ModeType; JustAdd: boolean): integer;
label
  Add;
begin
  if FindMult(s, Result) then goto Add;
  InsertMult(Result, s, Band, Mode);
  Add:
  if JustAdd then Exit;
  FList^[Result].FArray[Mode] := FList^[Result].FArray[Mode] or (1 shl Ord(Band));
  FList^[Result].FArray[Both] := FList^[Result].FArray[Both] or (1 shl Ord(Band));
  FList^[Result].FArray[Mode] := FList^[Result].FArray[Mode] or (1 shl Ord(AllBands));
  FList^[Result].FArray[Both] := FList^[Result].FArray[Both] or (1 shl Ord(AllBands));
end;

procedure TSSL.Clear;
begin
  if FCount <> 0 then
  begin

    FCount := 0;
    Windows.ZeroMemory(@TotalMults, SizeOf(TotalMults));
//    FTotalMults := 0;
    SetCapacity(0);
  end;
end;

procedure TSSL.Delete(Index: integer);
begin
  if (Index < 0) or (Index >= FCount) then Exit; //Error(@SListIndexError, Index);
 
  dec(FCount);
  if Index < FCount then System.Move(FList^[Index + 1], FList^[Index], (FCount - Index) * SizeOf(TStringItem));
end;

function TSSL.StringIsDupeByIndex(IndexInList: integer; Band: BandType; Mode: ModeType): boolean;
begin
  Result := (FList^[IndexInList].FArray[Mode] and (1 shl Ord(Band))) <> 0;
end;

function TSSL.StringIsDupe(const s: CallString; Band: BandType; Mode: ModeType; var IndexInList: integer): boolean;
var
  Index                                 : integer;
  TempMode                              : ModeType;
begin
  Result := False;
  if FindMult(s, Index) then
  begin
    TempMode := Mode;
    if TempMode = FM then TempMode := Phone;
    Result := (FList^[Index].FArray[TempMode] and (1 shl Ord(Band))) <> 0;
    IndexInList := Index;
  end
  else
    IndexInList := -1;
end;

function TSSL.FindMult(const s: Str10; var Index: integer): boolean;
var
  l, h, i, c                            : integer;
begin
  Result := False;
  l := 0;
  h := FCount - 1;
  while l <= h do
  begin
    i := (l + h) shr 1;
    c := CompareStrings(FList^[i].FMult, s);
    if c < 0 then l := i + 1 else
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

function TSSL.Get(Index: integer): Str10;
begin
  Result := FList^[Index].FMult;
end;

function TSSL.GetCapacity: integer;
begin
  Result := FCapacity;
end;

procedure TSSL.Grow;
var
  delta                                 : integer;
begin
  if FCapacity > 64 then delta := FCapacity div 4 else
    if FCapacity > 8 then delta := 16 else
      delta := 4;
  SetCapacity(FCapacity + delta);
end;

procedure TSSL.InsertMult(Index: integer; const s: Str10; Band: BandType; Mode: ModeType);
begin
  if FCount = FCapacity then Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(TStringItem));

  Windows.ZeroMemory(@FList^[Index], SizeOf(FList^[Index]));
  FList^[Index].FMult := s;
  inc(FCount);
end;

procedure TSSL.SetCapacity(NewCapacity: integer);
begin
  ReallocMem(FList, NewCapacity * SizeOf(TStringItem));
  FCapacity := NewCapacity;
end;

function TSSL.CompareStrings(const s1, s2: Str10): integer;
begin
  Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @s1[1], length(s1), @s2[1], length(s2)) - 2;
//  RESULT := StrComp(@s1[1], @s2[1]);
end;

procedure TSSL.ClearDupes;
var
  Index                                 : integer;
begin
  for Index := 0 to FCount - 1 do Windows.ZeroMemory(@FList^[Index].FArray, SizeOf(TDupesArray));
end;

end.

