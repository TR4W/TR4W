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
unit uMults;

{$IMPORTEDDATA OFF}

interface

uses

  VC,
  uSSL,
  uCallSignRoutines,
  uCTYDAT,
  //Country9,
  Windows,
  Log4D;   // Issue #1034: dropped uCallsigns (unused here)


const
  ZoneMultArraySize                     = 100;

type
  DXMultsArray = record
    dxmaArray: TDupesArray;
    dxmaVisible: boolean;
  end;

  MultsObject = object
    DXMultsArray: array[0..MaxCountries - 1] of TDupesArray;
    ZoneMultsArray: array[0..ZoneMultArraySize] of TDupesArray;
    PrfList: TSSL;
    DomList: TSSL;

    MTotals: array[BandType, CW..Both, RemainingMultiplierType] of Word;

    procedure IncrementTotals(Band: BandType; Mode: ModeType; m: RemainingMultiplierType);
    procedure ClearAllMults;
    procedure FillRemMultsBytes(rm: RemainingMultiplierType);

    procedure SetZnMult(Zone: Word; Band: BandType; Mode: ModeType);
    procedure SetDXMult(Cntr: Word; Band: BandType; Mode: ModeType);
    procedure SetPxMult(Prfx: CallString; Band: BandType; Mode: ModeType);
    procedure SetDmMult(Dom: CallString; Band: BandType; Mode: ModeType);

    function IsZnMult(Zone: Word; Band: BandType; Mode: ModeType): boolean;
    function IsDXMult(Country: Word; Band: BandType; Mode: ModeType): boolean;
    function IsPxMult(Prfx: CallString; Band: BandType; Mode: ModeType): boolean;
    function IsDmMult(Dom: CallString; Band: BandType; Mode: ModeType; DomMultType: DomesticMultType): boolean;
    procedure FillVisibleBytes;
  end;

var
  mo                                    : MultsObject;
  
implementation

// Issue #1034: own Log4D logger (initialized below), replacing the former
// MainUnit.logger borrow. MainUnit + LogDupe were otherwise unused here, so
// dropping them removes uMults's direct MainUnit -> LogStuff coupling and lets
// the multiplier logic be linked into the dependency-light unit-test EXE.
var
  logger: TLogLogger;

procedure MultsObject.IncrementTotals(Band: BandType; Mode: ModeType; m: RemainingMultiplierType);
begin
  inc(MTotals[Band, Mode, m]);

  if Mode <> Both then
    inc(MTotals[Band, Both, m]);

  if Band <> AllBands then
    inc(MTotals[AllBands, Mode, m]);

   if ((Mode <> Both) and (Band <> AllBands)) then
     inc(MTotals[AllBands, Both, m]);
end;

procedure MultsObject.ClearAllMults;
begin
  Windows.ZeroMemory(@ZoneMultsArray, SizeOf(ZoneMultsArray));
  Windows.ZeroMemory(@DXMultsArray, SizeOf(DXMultsArray));
  Windows.ZeroMemory(@MTotals, SizeOf(MTotals));
  PrfList.ClearDupes;
  DomList.ClearDupes;
end;

procedure MultsObject.SetZnMult(Zone: Word; Band: BandType; Mode: ModeType);
begin
  if not (Zone in [0..ZoneMultArraySize]) then Exit;
  ZoneMultsArray[Zone][Mode] := ZoneMultsArray[Zone][Mode] or (1 shl Ord(Band));
  ZoneMultsArray[Zone][Both] := ZoneMultsArray[Zone][Both] or (1 shl Ord(Band));
  ZoneMultsArray[Zone][Mode] := ZoneMultsArray[Zone][Mode] or (1 shl Ord(AllBands));
  ZoneMultsArray[Zone][Both] := ZoneMultsArray[Zone][Both] or (1 shl Ord(AllBands));
  IncrementTotals(Band, Mode, rmZone);
end;

procedure MultsObject.SetDXMult(Cntr: Word; Band: BandType; Mode: ModeType);
begin
  if Cntr >= CTY.ctyNumberCountries then Exit;

  DXMultsArray[Cntr][Mode] := DXMultsArray[Cntr][Mode] or (1 shl Ord(Band));
  DXMultsArray[Cntr][Both] := DXMultsArray[Cntr][Both] or (1 shl Ord(Band));
  DXMultsArray[Cntr][Mode] := DXMultsArray[Cntr][Mode] or (1 shl Ord(AllBands));
  DXMultsArray[Cntr][Both] := DXMultsArray[Cntr][Both] or (1 shl Ord(AllBands));
  IncrementTotals(Band, Mode, rmDX);
end;

procedure MultsObject.SetPxMult(Prfx: CallString; Band: BandType; Mode: ModeType);
begin
  Prfx[Ord(Prfx[0]) + 1] := #0;
  PrfList.AddString(Prfx, Band, Mode, False);
  IncrementTotals(Band, Mode, rmPrefix);
end;

procedure MultsObject.SetDmMult(Dom: CallString; Band: BandType; Mode: ModeType);
begin
  Dom[Ord(Dom[0]) + 1] := #0;
  DomList.AddString(Dom, Band, Mode, False);
  IncrementTotals(Band, Mode, rmDomestic);
end;

function MultsObject.IsZnMult(Zone: Word; Band: BandType; Mode: ModeType): boolean;
begin
  if Zone in [0..ZoneMultArraySize] then
    Result := (ZoneMultsArray[Zone][Mode] and (1 shl Ord(Band))) = 0
  else
    Result := False;
end;

function MultsObject.IsDXMult(Country: Word; Band: BandType; Mode: ModeType): boolean;
begin
  if Country < MaxCountries then
     Result := (DXMultsArray[Country][Mode] and (1 shl Ord(Band))) = 0
    else
       Result := False;
end;

function MultsObject.IsPxMult(Prfx: CallString; Band: BandType; Mode: ModeType): boolean;
var
  Index                                 : integer;
begin
  Prfx[Ord(Prfx[0]) + 1] := #0;
  Result := not PrfList.StringIsDupe(Prfx, Band, Mode, Index);
  if Index = -1 then
     begin
     logger.debug('In MultsObject.IsPxMult, for Prfx of ' + Prfx + ', Result = true');
     Result := True;
     end;
end;

function MultsObject.IsDmMult(Dom: CallString; Band: BandType; Mode: ModeType; DomMultType: DomesticMultType): boolean;
var
  Index                                 : integer;
  InsertPos                             : integer;
  StoredKey                             : Str10;
  FieldKey                              : Str10;
begin
  Dom[Ord(Dom[0]) + 1] := #0;

  // For GridFields the mult unit is the 2-char field ("FN"), not the full
  // 4-char grid square ("FN20" or "FN25"). Truncate the query to 2 chars so
  // that any FN-prefixed grid in the store matches, regardless of whether the
  // stored key is the field ("FN", new format) or the full grid ("FN20", old
  // log records). GridSquares uses the full 4-char key and is unaffected.
  if DomMultType = GridFields then
     begin
     FieldKey := Copy(Dom, 1, 2);
     Result := not DomList.StringIsDupe(FieldKey, Band, Mode, Index);
     if Index = -1 then
        begin
        // Exact 2-char field not found — store may have full-grid keys.
        // FindMult returns the insertion point, which lands at the first
        // stored entry whose prefix matches FieldKey (e.g. "FN20").
        DomList.FindMult(FieldKey, InsertPos);
        if InsertPos < DomList.Count then
           begin
           StoredKey := DomList.Get(InsertPos);
           if Copy(StoredKey, 1, 2) = FieldKey then
              begin
              Result := not DomList.StringIsDupeByIndex(InsertPos, Band, Mode);
              Exit;
              end;
           end;
        Result := True;
        end;
     Exit;
     end;

  Result := not DomList.StringIsDupe(Dom, Band, Mode, Index);
  if Index = -1 then
     Result := True;

end;

procedure MultsObject.FillRemMultsBytes(rm: RemainingMultiplierType);
begin

end;

procedure MultsObject.FillVisibleBytes;
label
  1;
var
  i                                     : integer;
begin
  for i := 0 to MaxCountries - 1 do
  begin
    if CTY.ctyCountryMode = ARRLCountryMode then
      if CTY.ctyTable[i].ID[1] = '*' then
      begin
        1:
        CTY.ctyTable[i].VisibleInRM := 0;
        Continue;
      end;

    if ActiveDXMult = NoDXMults then goto 1;

    if ActiveDXMult = CQNonEuropeanCountries then
      if CTY.ctyTable[i].DefaultContinent = Europe then Continue;

    if ActiveDXMult = CQEuropeanCountries then
      if CTY.ctyTable[i].DefaultContinent <> Europe then Continue;

    if ActiveDXMult = CQUBAEuropeanCountries then
      if not UBACountry(CTY.ctyTable[i].ID) then Continue;

    if CTY.ctyCustomRemainingCountryListFound then Continue;

    if CTY.ctyTable[i].VisibleInRM <> 1 then
      CTY.ctyTable[i].VisibleInRM := 2;

  end;
end;

begin
  logger := TLogLogger.GetLogger('uMults');   // Issue #1034: own logger (was MainUnit.logger)
  mo.PrfList.Init;
  mo.DomList.Init;
//  mo.PrfList := TSSL.Create;
//  mo.DomList := TSSL.Create;
end.

