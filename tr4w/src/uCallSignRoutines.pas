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
unit uCallSignRoutines;
{$IMPORTEDDATA OFF}
interface
uses
  uStrSearch,   // Issue #1033: was TF (needed only for StrU, which #997 moved to the light uStrSearch) -- drops TF -> MainUnit -> LogStuff coupling
  uRussiaOblasts,
  // Tree,
  utils_text,
  VC,
  Windows;
const
  ARRLSectionCountryString              = ' K VE KC6 KG4 KL KH0 KH1 KH2 KH3 KH4 KH5 KH6 KH7 KH8 KH9 KP1 KP2 KP3 KP4 KP5 ';
  BlackSeaCountriesString               = ' OE ZA EU LZ E7 HA DL 4L I Z3 ER SP UA YO OM S5 TA UR 9A 4O OK HB YU ';
  CISCountries                          = ' UA UA2 UA9 UR EU 4J EK UN EX ER EY EZ UK 4L ';
  UBAEuroCountryString                  = ' 5B 9A 9H CT CT3 CU DL EA EA6 EA8 EI ES F FG FM FR FY  HA I IS LX LY LZ OE OH OH0 OJ0 OK OM OZ PA S5 SM SP SV SV/A SV5 SV9 SY TK YL YO ';   // 4.106.5
  ScandinavianCountries                 = ' LA JW JX OH OH0 OJ0 OX OY OZ SM TF ';
  IndonesianCountries                   = ' YB YC YD YE YF ';           // 4.64.1
function ARRLSectionCountry(CountryID: Str20): boolean;
function BlackSeaRegionCountry(CountryID: Str20): boolean;
function CISCountry(CountryID: Str20): boolean;
function UBACountry(CountryID: Str20): boolean;
function ScandinavianCountry(CountryID: Str20): boolean;
function IndonesianCountry(CountryID: Str20): boolean;
function GetNumber(Call: CallString): Char;
function GetFirstSuffixLetter(Call: CallString): Char;
function RussianID(ID: ShortString): boolean;
function FrenchID(ID: ShortString): boolean;
function SpanishStation(ID: ShortString): boolean;
function OKOMStation(ID: ShortString): boolean;
function UKEIStation(ID: ShortString): boolean;
function GetPrefix(Call: CallString): PrefixString;
function GetOblast(Call: CallString): Str2;
function MobileCall(Call: CallString): boolean;  //n4af 4.41.8
//function IsUA1AStation(Call: CallString): boolean;
function StandardCallFormat(Call: CallString; Complete: boolean): CallString;
function GetRussiaOblastID(Call: CallString): Str2; //
function CaliforniaCall(Call: CallString): boolean;
function RootCall(Call: CallString): CallString;
function RoverCall(Call: CallString): boolean;
function SimilarCall(Call1: CallString; Call2: CallString): boolean;
function GoodCallSyntax(Call: CallString): boolean;
function ValidCallCharacter(CallChar: Char): boolean;
implementation
uses uCTYDAT;
function ARRLSectionCountry(CountryID: Str20): boolean;
begin
  Result := False;
  if pos(' ' + CountryID + ' ', ARRLSectionCountryString) <> 0 then Result := True;
end;
function BlackSeaRegionCountry(CountryID: Str20): boolean;
begin
  Result := False;
  if pos(' ' + CountryID + ' ', BlackSeaCountriesString) <> 0 then Result := True;
end;
function CISCountry(CountryID: Str20): boolean;
begin
  Result := False;
  if pos(' ' + CountryID + ' ', CISCountries) <> 0 then Result := True;
end;
function UBACountry(CountryID: Str20): boolean;
begin
  Result := pos(' ' + CountryID + ' ', UBAEuroCountryString) <> 0;
end;
function ScandinavianCountry(CountryID: Str20): boolean;
begin
  Result := False;
  if pos(' ' + CountryID + ' ', ScandinavianCountries) <> 0 then Result := True;
end;
function IndonesianCountry(CountryID: Str20): boolean;         // 4.64.1
begin
  Result := False;
  if pos(' ' + CountryID + ' ', IndonesianCountries) <> 0 then Result := True;
end;
function GetNumber(Call: CallString): Char;
{ This function will look at the callsign passed to it and return the
  single number that is in it.  If the call is portable, the number from
  the portable designator will be given if there is one.  If the call
  or prefix has two numbers in it, the last one will be given.         }
var
  CharPtr                               : integer;
begin
  if StringHas(Call, '/') then Call := PrecedingString(Call, '/');
  for CharPtr := length(Call) downto 1 do
    if Call[CharPtr] in ['0'..'9'] then
    begin
      GetNumber := Call[CharPtr];
      Exit;
    end ;
  GetNumber := CHR(0);
end;
function GetFirstSuffixLetter(Call: CallString): Char;
{ This function will get the first letter after the last number in the
  callsign or portable designator.  If the call does not have a letter
  after the last number, or if the portable designator does not have
  it, a null character will be returned.                             }
var
  CharPtr                               : integer;
  TempString                            : Str80;
begin
  if StringHas(Call, '/') then
  begin
    TempString := PostcedingString(Call, '/');
    GetFirstSuffixLetter := GetFirstSuffixLetter(TempString);
  end
  else
  begin
    for CharPtr := length(Call) - 1 downto 1 do
      if Call[CharPtr] in ['0'..'9'] then
      begin
        GetFirstSuffixLetter := Call[CharPtr + 1];
        Exit;
      end;
  GetFirstSuffixLetter := CHR(0);
  end;
end;
function OKOMStation(ID: ShortString): boolean;
begin
  Result := False;
  if length(ID) > 1 then
    if ID[1] = 'O' then if
      ID[2] in ['K', 'M'] then Result := True;
end;
function UKEIStation(ID: ShortString): boolean;  // 4.58.2
begin
  Result := False;
//  if length(ID) > 1 then
    if ((ID[1] = 'G') or (ID[1] = 'M') or ((ID[1] = 'E') and (ID[2] = 'I')) or (ID[1] = '2')) then
     Result := True;
end;
function SpanishStation(ID: ShortString): boolean;
begin
  Result := False;
  if length(ID) > 1 then
    if ID[1] = 'E' then if
      ID[2] = 'A' then Result := True;
end;
function FrenchID(ID: ShortString): boolean;
begin
  Result := (ID[1] = 'F') or (ID = 'TM') or (ID = 'TK');
end;
function RussianID(ID: ShortString): boolean;
begin
  Result := False;
  if length(ID) > 1 then
  begin
    if ID[1] = 'R' then Result := True;
    if ID[1] = 'U' then if ID[2] = 'A' then Result := True;
  end;
end;
{
function getRussianRegion(Callsign: CallString): RussianRegionType;
begin
  result := rtUnknownRegion;
  Result := False;
  if length(ID) > 1 then
  begin
    if ID[1] = 'R' then Result := True;
    if ID[1] = 'U' then if ID[2] = 'A' then Result := True;
  end;
end;
}
function StandardCallFormat(Call: CallString; Complete: boolean): CallString;
{ This fucntion will take the call passed to it and put it into a
  standard format with the country indicator as the first part of
  the call.  It is intended to convert calls as they would be sent
  on the air to N6TR duping service perferred format.  This means
  that a callsign as normally sent on the air would be converted to
  a callsign that can be passed to GetCountry, GetContinent, GetZone
  and so on with probable success.
  A change made on 4 November adds the complete flag.  If the flag is
  TRUE, the routine works the way it always has.  If the flag is false,
  the call is unchanged if the call has a single integer after the / sign.
  This is intended to eliminate problems with KC8UNP/6 showing up as
  KC6/KC8UNP which gets reported as the Carolines. }
label
  1;
var

  FirstPart, SecondPart                 : Str80;
  TempPrefixString                      : PrefixString;
  l                                     : integer;
begin
  if not StringHas(Call, '/') then
  begin
    StandardCallFormat := Call;
    Exit;
  end;
  l := length(Call);
  {/P /M /N /T}
  if l > 2 then if Call[l - 1] = '/' then if Call[l] in ['P', 'M', 'N', 'T'] then
      begin
        SetLength(Call, l - 2);
        goto 1;
      end;
  {/AG /AA /AE}
  if l > 3 then if PWORD(@Call[l - 2])^ = $412F then if Call[l] in ['A', 'G', 'E'] then
      begin
        SetLength(Call, l - 3);
        goto 1;
      end;
  {/QRP}
  if l > 4 then if PInteger(@Call[l - 3])^ = $5052512F then
    begin
      SetLength(Call, l - 4);
      goto 1;
    end;
  1:
  if not StringHas(Call, '/') then
  begin
    StandardCallFormat := Call;
    Exit;
  end;
  FirstPart := PrecedingString(Call, '/');
  SecondPart := PostcedingString(Call, '/');
  if SecondPart = 'MOBILE' then {KK1L: 6.71 Added per Tree request}
  begin
    StandardCallFormat := FirstPart;
    Exit;
  end;
  if SecondPart = 'MM' then
  begin
    StandardCallFormat := 'MM/' + FirstPart;
    Exit;
  end;
  if SecondPart = 'R' then
  begin
    StandardCallFormat := FirstPart + '/' + SecondPart;
    Exit;
  end;

  if length(Call) = 11 then if (Call[1] = 'V') and (Call[2] = 'U') and (Call[7] = '/') then if Call[8] in ['0', '9'] then
      begin
        StandardCallFormat := Call;
        Exit;
      end;
  if length(SecondPart) = 1 then
    if SecondPart[1] in ['0'..'9'] then
    begin
      if Complete then
      begin
        TempPrefixString := GetPrefix(FirstPart);
        Delete(TempPrefixString, length(TempPrefixString), 1);
        SecondPart := TempPrefixString + SecondPart;
        StandardCallFormat := SecondPart + '/' + FirstPart;
      end
      else
        StandardCallFormat := Call;
      Exit;
    end
    else
    begin
      if SecondPart[1] in ['F', 'G', 'I', 'K', 'N', 'W'] then StandardCallFormat := SecondPart[1] + '/' + FirstPart
      else
        StandardCallFormat := FirstPart;
      Exit;
    end;
  if length(FirstPart) > length(SecondPart) then
  begin
    StandardCallFormat := SecondPart + '/' + FirstPart;
    Exit;
  end;
  if length(FirstPart) <= length(SecondPart) then
  begin
    StandardCallFormat := Call;
    Exit;
  end;
end;
function GetPrefix(Call: CallString): PrefixString;
{ This function will return the prefix for the call passed to it. This is
    a new and improved version that will handle calls as they are usaully
    sent on the air.                                                          }
var
    FirstPart, SecondPart, TempString     : Str80;
    CallPointer, Count                    : Integer;
begin
  for CallPointer := 1 to length(Call) do
    if Call[CallPointer] = '/' then
    begin
      FirstPart := Call;
        //{WLI}            FirstPart [0] := Chr (CallPointer - 1);
      FirstPart := Copy(FirstPart, 1, CallPointer - 1);
      SecondPart := '';
      for Count := CallPointer + 1 to length(Call) do
        SecondPart := SecondPart + Call[Count];
      if length(SecondPart) = 1 then
        if (SecondPart >= '0') and (SecondPart <= '9') then
        begin
          TempString := GetPrefix(FirstPart);
              //{WLI}                    TempString [0] := Chr (Length (TempString) - 1);
          TempString := Copy(TempString, 1, length(TempString) - 1);
          GetPrefix := TempString + SecondPart;
          Exit;
        end
        else
        begin
 //         GetPrefix := GetPrefix(FirstPart);
          Exit;
        end;
        {KK1L: 6.68 Added AM check to allow /AM as aeronautical mobile rather than Spain}
      if (Copy(SecondPart, 1, 2) = 'MM') or (Copy(SecondPart, 1, 2) = 'AM') then
      begin
        GetPrefix := GetPrefix(FirstPart);
        Exit;
      end;
      if length(FirstPart) > length(SecondPart) then
      begin
        GetPrefix := GetPrefix(SecondPart);
        Exit;
      end;
      if length(FirstPart) <= length(SecondPart) then
      begin
        GetPrefix := GetPrefix(FirstPart);
        Exit;
      end;
    end;
  { Call does not have portable sign.  Find natural prefix. }
  if not StringHasNumber(Call) then
  begin
    GetPrefix := Call + '0';
    Exit;
  end;
  for CallPointer := length(Call) downto 2 do
    if Call[CallPointer] <= '9' then
    begin
      GetPrefix := Call;
        //{WLI}            GetPrefix [0] := CHR (CallPointer);
      Result := Copy(Call, 1, CallPointer);
      Exit;
    end;
  if (Call[1] <= '9') and (length(Call) = 2) then
  begin
    GetPrefix := Call + '0';
    Exit;
  end;
  GetPrefix := ''; { We have no idea what the prefix is }
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
function GetRussiaOblastID(Call: CallString): Str2; //
var

  Oblast                                : Str2;
  r                                     : PChar;
  reg                                   : RussianRegionType;
begin
  Result := '';
  if tPos(Call, '/') <> 0 then Exit;
  Oblast := GetOblast(Call);
  if length(Oblast) < 2 then Exit;
  reg := GetRussiaOblastByTwoChars(Oblast[1], Oblast[2]);
  if reg = rtUnknownRegion then Exit;
  r := RussianRegionsTypeIdArray[GetRussiaOblastByTwoChars(Oblast[1], Oblast[2])];
  Result[0] := #2;
  Result[1] := r[0];
  Result[2] := r[1];
end;
function CaliforniaCall(Call: CallString): boolean;
begin
  CaliforniaCall := False;
  if not StringHas(Call, '6') then Exit;
  Call := StandardCallFormat(Call, True);
  if StringHas(Call, '/') then if not StringHas(Call, '6/') then Exit;
  if (Call[1] <> 'A') and (Call[1] <> 'K') and (Call[1] <> 'N') and (Call[1] <> 'W') then Exit;
  if Call[2] = 'H' then Exit;
  CaliforniaCall := True;
end;
function RootCall(Call: CallString): CallString;
var
  TempCall                              : CallString;
begin
  TempCall := StandardCallFormat(Call, True);
  if StringHas(TempCall, '/') then
    TempCall := PostcedingString(TempCall, '/');
  if length(TempCall) <= 2 then
  begin
    TempCall := PrecedingString(StandardCallFormat(Call, True), '/');
    if length(TempCall) >= 3 then
    begin
      RootCall := TempCall;
      Exit;
    end;
  end;
  if StringHas(TempCall, '/') then
    TempCall := PrecedingString(TempCall, '/');
  {   IF Length (TempCall) > 6 THEN TempCall [0] := Chr (6); }
  RootCall := TempCall;
end;
function RoverCall(Call: CallString): boolean;
begin
  RoverCall := UpperCase(Copy(Call, length(Call) - 1, 2)) = '/R';
end;
function MobileCall(Call: CallString): boolean;      //n4af 4.41.8
begin
  MobileCall := UpperCase(Copy(Call, length(Call) - 1, 2)) = '/M';
end;
function SimilarCall(Call1: CallString; Call2: CallString): boolean;
{ This function will return true if the two calls only differ in one
    character position.         }
var
  NumberDifferentChars, NumberTestChars, TestChar: integer;
  c1, c2                                : string[1];
begin
  if pos('/', Call1) > 0 then Call1 := RootCall(Call1);
  if pos('/', Call2) > 0 then Call2 := RootCall(Call2);
  SimilarCall := False;
  if Abs(length(Call1) - length(Call2)) > 1 then Exit;
  NumberTestChars := length(Call1);
  if (length(Call2) > NumberTestChars) then inc(NumberTestChars);
  { NumberTestChars is equal to length of longest call. }
  NumberDifferentChars := 0;
  for TestChar := NumberTestChars downto 1 do
  begin
    c1 := Copy(Call1, TestChar, 1);
    c2 := Copy(Call2, TestChar, 1);
    if (c1 <> c2) and (c1 <> '?') and (c2 <> '?') then
    begin
      inc(NumberDifferentChars);
      if (NumberDifferentChars) = 2 then Break;
    end;
  end;
  if NumberDifferentChars <= 1 then
  begin
    SimilarCall := True;
    Exit;
  end;
  { Let's see if either call shows up in the other - finds I4COM PI4COM }
  if (pos(Call1, Call2) = 0) and (pos(Call2, Call1) = 0) then Exit;
  SimilarCall := True;
end;
function GoodCallSyntax(Call: CallString): boolean;
{ This function will look at the callsign passed to it and see if it
    looks like a real callsign.                                           }
var
  CharacterPointer                      : integer;
begin
  GoodCallSyntax := False;
  if length(Call) < 3 then Exit;
  uStrSearch.StrU(Call);
  if not StringHasLetters(Call) then Exit;
  case length(Call) of
    8:
      if ((Call[2] = '/') or (Call[2] = '-')) and
        ((Call[6] = '/') or (Call[6] = '-')) then
        Exit;
    9:
      if ((Call[3] = '/') or (Call[3] = '-')) and
        ((Call[7] = '/') or (Call[7] = '-')) then
        Exit;
  end;
  if Call = 'RAEM' then
  begin
    GoodCallSyntax := True;
    Exit;
  end;
  for CharacterPointer := 1 to length(Call) do
    if not ValidCallCharacter(Call[CharacterPointer]) then Exit;
  for CharacterPointer := 1 to length(Call) do
    if Call[CharacterPointer] = '/' then
    begin
      if CharacterPointer = 1 then Exit;
      if CharacterPointer = length(Call) then Exit;
      GoodCallSyntax := True;
      Exit;
    end;
  if (Call[1] <= '9') and (Call[2] <= '9') then Exit;
  if length(Call) = 3 then
  begin
    if
      ((Call[2] < '0') or (Call[2] > '9')) and
      ((Call[3] < '0') or (Call[3] > '9')) then
      Exit;
  end ;
  { //n4af 4.38.3
  else
    if
      ((Call[2] < '0') or (Call[2] > '9')) and
      ((Call[3] < '0') or (Call[3] > '9')) and
      ((Call[4] < '0') or (Call[4] > '9')) then
      Exit;
  if Call[length(Call)] in ['0'..'9'] then
  begin
//    if (Call <> 'BP100') and (Call <> 'BV100')and (Call <> 'BM100') then Exit;
    if ((length(Call) <> 5) and (Call[1] = 'B')) then Exit;
  end;
  }
  GoodCallSyntax := True;
end;
function ValidCallCharacter(CallChar: Char): boolean;
begin
  Result := CallChar in ['/', '0'..'9', 'A'..'Z'];
end;
end.
