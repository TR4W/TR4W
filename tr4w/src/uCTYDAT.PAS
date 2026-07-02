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
unit uCTYDAT;

{$IMPORTEDDATA OFF}
interface

uses

  VC,
  TF,
  uCommctrl,
  Windows,
  uCallSignRoutines,
  utils_text,
  utils_file,
  LogGrid
  ;
{
type
  DXMultiplierString = string[5];
  GridString = string[7];
  ContinentType = (UnknownContinent, NorthAmerica, SouthAmerica, Europe, Africa, Asia, Oceania);
  CallString = string[10];
}

const
  MaxCountries                          = 1000 {380};    // n4af 4.42.6
const
{(*}
  RussianGrids                          : array['A'..'Z'] of array['0'..'9'] of  FourChar =
    (
//   0       1       2       3       4       5       6       7       8       9
    ('NO66', 'KO59', ''    , 'KO85', 'LN28', ''    , 'KN95', ''    , ''    , 'MO05'), //A
    ('OQ26', 'KO59', ''    , 'KO85', 'LN28', ''    , 'KN95', ''    , ''    , 'MO05'), //B
    ('PN78', 'KO59', ''    , 'KO85', 'LO31', ''    , 'KN95', ''    , ''    , 'MO06'), //C
    ('PN68', 'KO59', ''    , 'KO85', 'LO31', ''    , 'KN95', ''    , ''    , 'MO06'), //D
    ('QO11', 'KO59', ''    , 'KO82', ''    , ''    , 'LN14', ''    , ''    , 'MO06'), //E
    ('QO11', 'KO59', ''    , 'KO85', 'LO23', ''    , 'LN05', ''    , ''    , 'LO88'), //F
    ('QO11', 'KO59', ''    , 'KO92', ''    , ''    , 'LN05', ''    , ''    , 'LP70'), //G
    ('OO29', 'KO59', ''    , 'LO05', 'LO53', ''    , 'LN05', ''    , ''    , 'NO26'), //H
    ('QO59', 'KO59', ''    , 'KO76', 'LO53', ''    , 'LN26', ''    , ''    , 'NO26'), //I
    ('PO80', 'KO59', ''    , 'KO76', ''    , ''    , 'LN23', ''    , ''    , 'MP50'), //J
    ('RP96', 'KO59', ''    , ''    , ''    , ''    , ''    , ''    , ''    , 'MP26'), //K
    ('PN53', 'KO59', ''    , 'KO64', 'LO44', ''    , 'KN97', ''    , ''    , 'MO27'), //L
    ('PN53', 'KO59', ''    , 'KO97', 'LO44', ''    , 'KN97', ''    , ''    , 'MO65'), //M
    ('PN53', 'KP71', ''    , 'LO07', 'KO74', ''    , 'KN97', ''    , ''    , 'MO65'), //N
    ('OO43', 'LP04', ''    , 'LO07', 'KO74', ''    , 'KN97', ''    , ''    , 'NO15'), //O
    ('OO43', 'LP77', ''    , 'KO84', 'LO55', ''    , 'LN23', ''    , ''    , 'NO15'), //P
    ('PP00', 'KO99', ''    , 'KO91', 'LO55', ''    , 'LN23', ''    , ''    , 'MO25'), //Q
    ('PP00', 'KO99', ''    , 'LO02', 'LO55', ''    , ''    , ''    , ''    , 'MO25'), //R
    ('OO22', 'KO99', ''    , 'KO94', 'LO46', ''    , ''    , ''    , ''    , 'LO71'), //S
    ('OO22', 'LO26', ''    , 'LO26', 'LO46', ''    , ''    , ''    , 'OO22', 'LO71'), //T
    ('OO62', 'LO26', ''    , 'LO07', 'LO24', ''    , 'LN46', ''    , ''    , 'NO35'), //U
    ('OO62', 'KO59', ''    , 'LO06', ''    , ''    , 'LN46', ''    , 'ON69', 'NO35'), //V
    ('NO53', 'KO47', ''    , 'KO81', 'LO66', ''    , 'LN33', ''    , ''    , 'LO84'), //W
    ('RO06', 'KO47', ''    , 'KO84', ''    , ''    , 'LN13', ''    , ''    , 'LP63'), //X
    ('NO83', 'KP68', ''    , 'KO73', 'LO35', ''    , 'LN05', ''    , ''    , 'NO12'), //Y
    ('RO06', 'KP68', ''    , 'KO80', 'LO35', ''    , ''    , ''    , ''    , 'NO31')  //Z
    );
{*)}
const

  GridsArraysCount                      = 18;

  GridsIndexArray                       : array[1..GridsArraysCount] of string[2] =
    ('ZS', 'K', 'CE', 'CP', 'EA', 'EU', 'HK', 'JA', 'OA', 'OH', 'PY', 'SM', 'ZP', 'YV', 'YB', 'VE', 'VK', 'XE');

{(*}
  GridsArray                            : array[1..GridsArraysCount] of array['0'..'9'] of FourChar =
    (
    ('',     'KF07', 'KF26', 'KG12', 'KG31', 'KG50', 'KG44', '',     '',     ''),
    ('EN12', 'FN48', 'FN22', 'FN10', 'EM73', 'EM01', 'DM06', 'DN21', 'EN81', 'EN52'),
    ('',     'FG58', 'FG41', 'FF47', 'FF45', 'FF32', 'FF30', 'FE22', '',     ''),
    ('',     'FH63', 'FH70', 'FH61', 'FG69', 'FH73', 'FH93', 'FG88', 'FH77', 'FH68'),
    ('',     'IN62', 'IN82', 'IN92', 'IM79', 'IM98', '',     'IM77', '',     ''),
    ('',     'KO33', 'KO33', 'KO12', 'KO13', '',     'KO55', 'KO53', 'KO52', ''),
    ('',     'FK20', 'GK80', 'FJ34', 'FJ16', 'FJ16', 'FJ23', 'FJ35', 'FJ21', 'FJ40'),
    ('',     'PM95', 'PM84', 'PM74', 'PM65', 'PM63', 'PM52', 'QM09', 'QN13', 'PM86'),
    ('',     'EI95', 'FI03', 'FI20', 'FH18', 'FH26', 'FH32', 'FH46', 'FI27', 'FI14'),
    ('',     'KP10', 'KP20', 'KP11', 'KP32', 'KP20', 'KP03', 'KP42', 'KP44', 'KP25'),
    ('',     'GG88', 'GH65', 'GG30', 'GH71', 'GG44', 'GH97', 'HI13', 'GI05', 'GH25'),
    ('',     'JO97', 'KP05', 'JP83', 'JO79', 'JO89', 'JO67', 'JO76', '',     ''),
    ('',     'GG08', 'GG06', 'GG17', 'GG16', 'GG14', 'GG14', 'GG25', 'GG13', 'GG24'),
    ('',     'FK30', 'FJ48', 'FK40', 'FJ57', 'FK60', 'FJ86', 'FK80', 'FJ99', 'FJ63'),
    ('OI33', 'OI33', 'OI52', 'OI62', 'OI27', 'OJ00', 'NJ93', 'OI68', 'PI08', 'OI07'),
    ('',     'FN75', 'FN25', 'FN04', 'EN19', 'DO72', 'DO33', 'CN99', 'DP20', 'FN65'),
    ('',     'QF56', 'QF46', 'QF22', 'QG53', 'PF85', 'OF88', 'QE37', 'PH65', ''),
    ('',     'EK09', 'DM21', 'EK48', '',     '',     '',     '',     '',     '')
    );
{*)}
{
  ZSGrids                               : array['0'..'9'] of GridString =
    ('', 'KF07', 'KF26', 'KG12', 'KG31', 'KG50', 'KG44', '', '', '');

  KGrids                                : array['0'..'9'] of GridString =
    ('EN12', 'FN48', 'FN22', 'FN10', 'EM73', 'EM01', 'DM06', 'DN21', 'EN81', 'EN52');

  CEGrids                               : array['0'..'9'] of GridString =
    ('', 'FG58', 'FG41', 'FF47', 'FF45', 'FF32', 'FF30', 'FE22', '', '');

  CPGrids                               : array['0'..'9'] of GridString =
    ('', 'FH63', 'FH70', 'FH61', 'FG69', 'FH73', 'FH93', 'FG88', 'FH77', 'FH68');

  EAGrids                               : array['0'..'9'] of GridString =
    ('', 'IN62', 'IN82', 'IN92', 'IM79', 'IM98', '', 'IM77', '', '');

  EUGrids                               : array['0'..'9'] of GridString =
    ('', 'KO33', 'KO33', 'KO12', 'KO13', '', 'KO55', 'KO53', 'KO52', '');

  HKGrids                               : array['0'..'9'] of GridString =
    ('', 'FK20', 'GK80', 'FJ34', 'FJ16', 'FJ16', 'FJ23', 'FJ35', 'FJ21', 'FJ40');

  JAGrids                               : array['0'..'9'] of GridString =
    ('', 'PM95', 'PM84', 'PM74', 'PM65', 'PM63', 'PM52', 'QM09', 'QN13', 'PM86');

  OAGrids                               : array['0'..'9'] of GridString =
    ('', 'EI95', 'FI03', 'FI20', 'FH18', 'FH26', 'FH32', 'FH46', 'FI27', 'FI14');

  OHGrids                               : array['0'..'9'] of GridString =
    ('', 'KP10', 'KP20', 'KP11', 'KP32', 'KP20', 'KP03', 'KP42', 'KP44', 'KP25');

  PYGrids                               : array['0'..'9'] of GridString =
    ('', 'GG88', 'GH65', 'GG30', 'GH71', 'GG44', 'GH97', 'HI13', 'GI05', 'GH25');

  SMGrids                               : array['0'..'9'] of GridString =
    ('', 'JO97', 'KP05', 'JP83', 'JO79', 'JO89', 'JO67', 'JO76', '', '');

  ZPGrids                               : array['0'..'9'] of GridString =
    ('', 'GG08', 'GG06', 'GG17', 'GG16', 'GG14', 'GG14', 'GG25', 'GG13', 'GG24');

  YVGrids                               : array['0'..'9'] of GridString =
    ('', 'FK30', 'FJ48', 'FK40', 'FJ57', 'FK60', 'FJ86', 'FK80', 'FJ99', 'FJ63');

  YBGrids                               : array['0'..'9'] of GridString =
    ('OI33', 'OI33', 'OI52', 'OI62', 'OI27', 'OJ00', 'NJ93', 'OI68', 'PI08', 'OI07');

  VEGrids                               : array['0'..'9'] of GridString =
    ('', 'FN75', 'FN25', 'FN04', 'EN19', 'DO72', 'DO33', 'CN99', 'DP20', 'FN65');

  VKGrids                               : array['0'..'9'] of GridString =
    ('', 'QF56', 'QF46', 'QF22', 'QG53', 'PF85', 'OF88', 'QE37', 'PH65', '');
}
  ARRLSectionCountryString              = ' K VE KC6 KG4 KL KH0 KH1 KH2 KH3 KH4 KH5 KH6 KH7 KH8 KH9 KP1 KP2 KP3 KP4 KP5 ';

  UBAEuroCountryString                  = ' 5B 9H CT CT3 CU DL EA EA6 EA8 EI ES F FG FM FR FY G GD GI GJ GM GU GW HA I IS LX LY LZ OE OH OH0 OJ0 OK OM OZ PA S5 SM SP SV SV5 SV9 SY TK YL YO ';

  ScandinavianCountries                 = ' LA JW JX OH OH0 OJ0 OX OY OZ SM TF ';

  BlackSeaCountriesString               = ' OE ZA EU LZ E7 HA DL 4L I Z3 ER SP UA YO OM S5 TA UR 9A 4O OK HB YU ';

type
  DXMultString = array[0..7] of Char;
  PrefixName = array[0..13] of Char;

//  ZoneModeType = (CQZoneMode, ITUZoneMode);
//const
//  ZoneModeTypeSA                        : array[ZoneModeType] of PChar = ('CQ Zone', 'ITU Zone');

type

  PrefixRec = record
    {14}Prefix: PrefixName;
    {01}PrefLength: Byte;
    {01}FullCallsigns: boolean;

    {02}Country: Word;
    {01}CQZone: Byte;
    {01}ITUZone: Byte;
  end;

  PrefixRecPtr = ^PrefixRec;

  CountryInfoRecord = record
    {06}ID: DXMultiplierString;
    {01}dummy: Byte;
    {01}DefaultContinent: ContinentType;

    {08}DefaultGrid: GridString;

    {32}Name: array[0..31] of Char;
    {01}DefaultITUZone: Byte;
    {02}UTCOffset: Smallint;
    {01}DefaultCQZone: Byte;
    {01}VisibleInRM: Byte;
  end;

  CountryInfoArrayType = array[0..MaxCountries - 1] of CountryInfoRecord;

  CTYInterface = record
    ctyVersion: array[0..15] of Char;
    ctyTable: CountryInfoArrayType;
    ctyNumberCountries: longint;   // 4.42.6
    ctyPrefixesTable: HDSA;
    ctyPrefixesTableRecords: longword;
    ctyZoneMode: ZoneModeType;
    ctyTempQTHRecord: QTHRecord;
    ctyCountryMode: CountryModeType;
//    ctyLastCountryCall: CallString;
    ctyNumberRemainingCountries: longint; // 4.42.6
    ctyCustomRemainingCountryListFound: boolean;
    ctyIndexArray: array[Char] of Smallint;
    ctyMaxLengthIndexArray: array[Char] of Byte;
    ctyLastLocatedCall: CallString;
    ctyLastLocatedRecord: QTHRecord;
    ctyLastIndex: integer;
    ctyrfOblMode: boolean;    // n4af 4.42.6
    ctyR150SMode: boolean;
//    ctyUA3Country: Word;
//    ctyUA9Country: Word;
  end;

//  RemainingDXMultTemplateType = array[0..MaxCountries - 1] of DXMultString; //FourBytes;
//  RemainingDXMultTemplatePointer = ^RemainingDXMultTemplateType;

function ctyLocateCall(Call: CallString; var QTH: QTHRecord): boolean;
//function ctyInit(ctyFilename: PChar): boolean;
function ctyLoadInCountryFile(ctyFilename: PChar; CheckDupe: boolean; LoadRemainingMults: boolean): boolean;
function ctyFindCallsign(const s: PChar; var Index: integer): boolean;
function ctyGetGrid(Call: CallString; var ID: DXMultiplierString): GridString;
function ctyGetContinent(Call: CallString): ContinentType;
function ctyGetCountry(Call: CallString): Word;
function ctyGetCountryUTCOffset(Country: Word): Smallint;
function ctyGetZone(Call: CallString): Byte;
function ctyGetITUZone(Call: CallString): Byte;
function ctyGetCQZone(Call: CallString): Byte;

function ctyGetDefaultITUZone(Country: Word): Byte;
function ctyGetDefaultCQZone(Country: Word): Byte;
function ctyGetDefaultGrid(Country: Word): GridString;
function ctyGetCountryIdByIndex(Country: Word): DXMultiplierString;
function ctyGetContinentByIndex(Country: Word): ContinentType;
function ctyGetTotalCountries: integer;
function ctyGetVersion: PChar;
function ctyIsActiveMultiplier(Index: Word): boolean;
procedure ctySetCountryMode(CountryMode: CountryModeType);

function ctyGetCountryNamePchar(Index: Word): PChar;
function ctyGetCountryIdPchar(Index: Word): PChar;
function ctyGetCountryName(Index: Word): ShortString;
function ctyGetCountryID(Call: CallString): DXMultiplierString;

procedure ctyShellSort;
procedure ctyAddNewPrefixRecord(pr: PrefixRecPtr; CheckDupe: boolean);
procedure ctyMakeDefaultRemainingCountryList;
procedure ctyLoadInRFOblList;   // n4af 4.42.6
procedure ctyLoadInRemainingMults(p: PChar);
procedure ctyLoadInR150SList;

var
  CTY                                   : CTYInterface;

implementation

Uses MainUnit;

procedure ctyAddNewPrefixRecord(pr: PrefixRecPtr; CheckDupe: boolean);
var
  TempIndex                             : integer;
begin

  if not pr.FullCallsigns then
  begin
    if pr.Prefix[0] = 'R' then
//      if pr.Prefix[1] in ['B'..'Z'] then
      if pr.Prefix[1] in ['B'..'H', 'J'..'Z'] then
        if pr.Prefix[2] <> '2' then
          Exit;

    if pr.Prefix[0] = 'U' then
      if pr.Prefix[1] in ['B'..'E', 'G'..'I'] then Exit;

  end;
   if CheckDupe then
  begin

    for TempIndex := 0 to CTY.CTYPrefixesTableRecords - 1 do
      if StrComp(PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, TempIndex))^.Prefix, pr.Prefix) = 0 then
      begin
        DSA_SetItem(CTY.CTYPrefixesTable, TempIndex, pr);
        Exit;
      end;
  end;

  DSA_InsertItem(CTY.CTYPrefixesTable, CTY.CTYPrefixesTableRecords, pr);
  inc(CTY.CTYPrefixesTableRecords);
end;

procedure ReplaceCountry(r: CountryInfoRecord);
var

  i, Index1, Index2                     : Word;
  c                                     : Cardinal;
begin
  Index1 := MAXWORD;
  Index2 := MAXWORD;
  for i := 0 to CTY.CTYNumberCountries do
  begin
    if CTY.CTYTable[i].ID = r.ID then
    begin
      Index1 := i;
    end;

    if utils_text.StrComp(@CTY.CTYTable[i].ID[1], @r.Name[1]) = 0 then
    begin
      Index2 := i;
    end;
//    tf.StrComp()
  end;
  if Index1 = MAXWORD then Exit;
  if Index2 = MAXWORD then Exit;

  CTY.ctyTable[Index1].VisibleInRM := 1;
  for c := 0 to CTY.CTYPrefixesTableRecords - 1 do
  begin
    if PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, c))^.Country = Index1 then
      PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, c))^.Country := Index2;
  end;

end;

function ctyLoadInCountryFile(ctyFilename: PChar; CheckDupe: boolean; LoadRemainingMults: boolean): boolean;

// (#) Override CQ Zone
// [#] Override ITU Zone
// ? <#/#> Override latitude/longitude
// ? {aa} Override Continent
type
  ctyColumns = (cpCountryName, cpCQZone, cpITUZone, cpContinent, cpLatitude, cpLongitude, cpTimeOffset, cpPrimaryPrefix, cpUnDef);

label
  1, 2;
var
  MapFin                                : Cardinal;
  MapBase                               : Pointer;
  p                                     : PChar;
  h                                     : HWND;
  i                                     : Cardinal;
  s                                     : Cardinal;
  b                                     : array[0..31] of Char;
  //rmbuffer                              : array[0..4096 - 1] of Char;
  c                                     : ctyColumns;
  //x                                     : Cardinal;
  l                                     : Cardinal;
  Lat, Lon                              : REAL;
  code                                  : integer;
  r                                     : CountryInfoRecord;
  pr                                    : PrefixRec;
  e                                     : Cardinal;
  z                                     : Cardinal;
  oITU                                  : Byte;
  oCQ                                   : Byte;
  Size                                  : Cardinal;
 // Minutes                               : integer;
 // pppp                                  : integer;
//  NumberCountriesIndex             : integer;
const
  rm                                    = 'REMAINING MULTS';

begin
//3.900.000 ticks
//  Start := GetCPU;
  Result := False;
  z := 0; // 4.79.3
  h := CreateFile(ctyFilename, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_FLAG_SEQUENTIAL_SCAN, 0);
  if h = INVALID_HANDLE_VALUE then Exit;

  MapFin := Windows.CreateFileMapping(h, nil, PAGE_READONLY, 0, 0, nil);
  if MapFin = 0 then goto 1;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_READ, 0, 0, 0);
  if MapBase = nil then goto 2;

  if CTY.CTYPrefixesTable = 0 then
    CTY.CTYPrefixesTable := DSA_Create(SizeOf(PrefixRec), 100);

  p := MapBase;
  c := cpCountryName;
  s := 0;
  e := 0;
  oITU := 0;
  oCQ := 0;

//  Windows.ZeroMemory(@CTY.CTYTable, SizeOf(CountryInfoArrayType));

    Size := Windows.GetFileSize(h, nil);

  for i := 0 to Size - 1 do
  begin
           case p[i] of
      ':':
        begin
          l := i - s;
          case c of

            cpCountryName:
              begin
                Windows.ZeroMemory(@r, SizeOf(r));
                Windows.CopyMemory(@r.Name, @p[s], l);
              end;

            cpCQZone:
              begin
                if r.Name[0] = '!' then
                begin
                  // Issue #997: removed asm nop (no-op).
                  Windows.CopyMemory(@r.ID[1], @p[i - l], l);
                  r.ID[0] := CHR(l);
                  ReplaceCountry(r);
                  c := cpCountryName;
                  Continue;
                end;
                r.DefaultCQZone := Ord(p[i - 1]) - Ord('0');
                if l = 2 then r.DefaultCQZone := r.DefaultCQZone + (Ord(p[i - 2]) - Ord('0')) * 10;
              end;

            cpITUZone:
              begin
                r.DefaultITUZone := Ord(p[i - 1]) - Ord('0');
                if l = 2 then r.DefaultITUZone := r.DefaultITUZone + (Ord(p[i - 2]) - Ord('0')) * 10;
              end;

            cpContinent:
              begin
                if p[i - 2] = 'E' then r.DefaultContinent := Europe;
                if p[i - 2] = 'O' then r.DefaultContinent := Oceania;
                if p[i - 2] = 'N' then r.DefaultContinent := NorthAmerica;
                if p[i - 2] = 'S' then r.DefaultContinent := SouthAmerica;
                if p[i - 1] = 'S' then r.DefaultContinent := Asia;
                if p[i - 1] = 'F' then r.DefaultContinent := Africa;
              end;

            cpLatitude:
              begin
                Windows.ZeroMemory(@b, SizeOf(b));
                Windows.CopyMemory(@b, @p[s], l);
                Lat := ValExt(b, code);
                //Val(b, Lat, code);
                //Lat := ValExt(b, code);
              end;
            cpLongitude:
              begin

                Windows.ZeroMemory(@b, SizeOf(b));
                Windows.CopyMemory(@b, @p[s], l);
//                Val(b, Lon, code);
                Lon := ValExt(b, code);
                if code = 0 then r.DefaultGrid := ConvertLatLonToGrid(Lat, Lon);
              end;

            cpTimeOffset:
              begin
                Windows.ZeroMemory(@b, SizeOf(b));
                Windows.CopyMemory(@b, @p[s], l);
                r.UTCOffset := PCharToInt(@b) * 60;
{
                for Minutes := 1 to 3 do
                  if b[Minutes] = '.' then
                  begin
                    if b[Minutes + 1] <> '0' then
                      r.UTCOffset := r.UTCOffset + (PCharToInt(@b[Minutes + 1]) div 25) * 15;
                  end;
}
                //tPos(
//                Lon := ValExt(b, code);
//                if code = 0 then r.UTCOffset := round(Lon * 100);
              end;
            cpPrimaryPrefix:
              begin
                Windows.CopyMemory(@r.ID[1], @p[s], l);
                r.ID[0] := CHR(l);
//                if r.ID = 'UA9' then
//                  asm nop end;
{
                for NumberCountriesIndex := 0 to MaxCountries - 1 do
                begin
                  if CountryInfoTable^[NumberCountriesIndex].ID = r.ID then Break;
                  if CountryInfoTable^[NumberCountriesIndex].ID = '' then Break;
                end;
}
                CTY.CTYTable[CTY.CTYNumberCountries] := r;
                inc(CTY.CTYNumberCountries);

              end;
          end;
          inc(c);
        end;
      ' ', #9: if c <> cpCountryName then s := i + 1;
      #13, #10: s := i + 1;
   
      '[', '(': begin z := i + 1;
          if e = 0 then e := i + 1;
        end;
      ')':
        begin
          oCQ := Ord(p[i - 1]) - Ord('0');

          if i - z = 2 then oCQ := oCQ + (Ord(p[i - 2]) - Ord('0')) * 10;
        end;
      ']':
        begin
          oITU := Ord(p[i - 1]) - Ord('0');
          if i - z = 2 then oITU := oITU + (Ord(p[i - 2]) - Ord('0')) * 10;
        end;

      ',', ';':
        begin
          Windows.ZeroMemory(@pr, SizeOf(pr));
          if p[s] = '=' then
          begin
            inc(s);
            pr.FullCallsigns := True;
          end;
               l := i - s;
          if e <> 0 then
          if (s <= e)  then   //n4af 4.35.2
          l := (e - s - 1);
          Windows.CopyMemory(@pr.Prefix, @p[s], l);
          pr.PrefLength := l;

          pr.Country := CTY.CTYNumberCountries - 1;
          if oCQ <> 0 then begin pr.CQZone := oCQ;
            oCQ := 0;
          end { else pr.CQZone := r.DefaultCQZone};
          if oITU <> 0 then begin pr.ITUZone := oITU;
            oITU := 0;
          end {else pr.ITUZone := r.DefaultITUZone};
          ctyAddNewPrefixRecord(@pr, CheckDupe);
          if pr.Prefix[0] = 'V' then
            if pr.Prefix[1] = 'E' then
              if pr.Prefix[2] = 'R' then
                if pr.Prefix[3] = '2' then
                  if pr.Prefix[4] = '0' then
                    Windows.lstrcat(CTY.CtyVersion, pr.Prefix);

          s := i + 1;
          e := 0;
          if p[i] = ';' then c := cpCountryName;
        end;
    end;

  end;

  if LoadRemainingMults then
  begin
    p := Strpos(MapBase, rm);
    if p <> nil then ctyLoadInRemainingMults(p);
  end;

  1: Windows.UnmapViewOfFile(MapBase);
  2: CloseHandle(MapFin);
  CloseHandle(h);

  Result := True;
  ctyShellSort;
//  Stop := GetCPU;
//  showint(Stop - Start);
end;

procedure ctyShellSort;
var
  iI, iJ, iK, iSize                     : integer;
  wTemp1                                : PrefixRec;
  wTemp2                                : PrefixRec;
 // h                                     : HWND;
  TempChar                              : Char;
  TempPtr                               : PrefixRecPtr;
begin
  iSize := CTY.ctyPrefixesTableRecords - 1;
  iK := iSize shr 1;
  while iK > 0 do
  begin
    for iI := 0 to iSize - iK do
    begin
      iJ := iI;
      while (iJ >= 0) and (
      //aSort[iJ] > aSort[iJ + iK]
        StrComp(
        PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, iJ))^.Prefix,
        PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, iJ + iK))^.Prefix
        ) > 0
        ) do
      begin
        DSA_GetItem(CTY.CTYPrefixesTable, iJ, @wTemp1);
        //wTemp := aSort[iJ];

        DSA_GetItem(CTY.CTYPrefixesTable, iJ + iK, @wTemp2);

        DSA_SetItem(CTY.CTYPrefixesTable, iJ, @wTemp2);
//        aSort[iJ] := aSort[iJ + iK];
        DSA_SetItem(CTY.CTYPrefixesTable, iJ + iK, @wTemp1);
//        aSort[iJ + iK] := wTemp;

        if iJ > iK then
          dec(iJ, iK)
        else
          iJ := 0
      end;
    end;
    iK := iK shr 1;
  end;

  FillChar(CTY.ctyIndexArray, SizeOf(CTY.ctyIndexArray), -1);
  Windows.ZeroMemory(@CTY.ctyMaxLengthIndexArray, SizeOf(CTY.ctyMaxLengthIndexArray));

{$IF tDebugMode}
  MessageBox(0, 'debug mode created prefixes.txt', 'debug mode', MB_OK or MB_ICONINFORMATION {or MB_RTLREADING } or MB_TASKMODAL);
  utils_file.tOpenFileForWrite(h, 'prefixes.txt');
{$IFEND}

  for iI := CTY.ctyPrefixesTableRecords - 1 downto 0 do
  begin
    TempPtr := PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, iI));
{$IF tDebugMode}
    sWriteFile(h, wsprintfBuffer, Format(wsprintfBuffer, '%04u %-15s %u'#13#10, iI, @TempPtr^.Prefix, TempPtr.Country));
{$IFEND}
    CTY.ctyIndexArray[TempPtr^.Prefix[0]] := iI;

    if not TempPtr^.FullCallsigns then
      if TempPtr^.PrefLength > CTY.ctyMaxLengthIndexArray[TempPtr^.Prefix[0]] then
        CTY.ctyMaxLengthIndexArray[TempPtr^.Prefix[0]] := TempPtr^.PrefLength;
  end;

{$IF tDebugMode}
  CloseHandle(h);
{$IFEND}

  CTY.ctyIndexArray[CHR(Ord('Z') + 1)] := CTY.ctyPrefixesTableRecords - 1;

  for TempChar := 'Z' downto '0' do
  begin
    if CTY.ctyIndexArray[TempChar] = -1 then
      CTY.ctyIndexArray[TempChar] := CTY.ctyIndexArray[CHR(Ord(TempChar) + 1)];
  end;

//  CTY.ctyIndexArray[CHR(Ord('9') + 1)] := CTY.ctyIndexArray['A'];

end;

function ctyFindCallsign(const s: PChar; var Index: integer): boolean;
var
  l, h, i, c                            : integer;

begin
  Result := False;

//  l := 0;
//  h := CTY.ctyPrefixesTableRecords - 1;
   if s = '-' then
      begin
      logger.Debug('Exiting ctyFindCallsign early because s = -');
      Exit;
      end;


  l := CTY.ctyIndexArray[s[0]];
  h := CTY.ctyIndexArray[CHR(Ord(s[0]) + 1)];

  try
  while l <= h do
  begin
    i := (l + h) shr 1;

    c := StrComp(PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, i))^.Prefix, s);
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
  except
     logger.error('Exception in ctyFindCallsign s = %s',[s]);
  end;
  Index := l;
end;
{
function ctyInit(ctyFilename: PChar): boolean;
begin
  Result := False;
  if ctyLoadInCountryFile(ctyFilename) then
  begin

    Result := True;
  end;
end;
}

function ctyLocateCall(Call: CallString; var QTH: QTHRecord): boolean;
label
  FillRecord;
var
  TempIndex                             : integer;
  TempPrefixRec                         : PrefixRecPtr;
  TempLength                            : integer;
  TempPrefix                            : PrefixName;
  TempPointer                           : integer;
  //StandardCall                          : CallString;
  GuantanamoBayCallsign                 : boolean;
begin
  TempIndex := 0;
  if Call = CTY.ctyLastLocatedCall then
  begin
    QTH := cty.ctyLastLocatedRecord;
    Result := True;
    Exit;
  end;

  Result := False;

  if Call[1] = '/' then Exit;

  Windows.ZeroMemory(@QTH, SizeOf(QTHRecord));
  if length(Call) = 0 then Exit;

  Windows.CopyMemory(@TempPrefix, @Call[1], length(Call));
  TempPrefix[length(Call)] := #0;

  QTH.StandardCall := StandardCallFormat(Call, True);

  GuantanamoBayCallsign := False;

  if QTH.StandardCall[1] = 'K' then
    if QTH.StandardCall[2] = 'G' then
      if QTH.StandardCall[3] = '4' then
        if length(QTH.StandardCall) <> 5 then
//        if (PInteger(@QTH.StandardCall)^ = $34474B04) or (PInteger(@QTH.StandardCall)^ = $34474B06) then
        begin
          TempPrefix[1] := 'A';
          GuantanamoBayCallsign := True;
        end;

//  MainUnit.showint(PInteger(@QTH.StandardCall)^);

  if ctyFindCallsign(@TempPrefix, TempIndex) then
  begin
//    asm nop end;

    if CTY.ctyCountryMode = ARRLCountryMode then
    begin
      if CTY.ctyTable[PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, TempIndex))^.Country].ID[1] <> '*' then goto FillRecord;
    end else
      goto FillRecord;
  end;

  if length(QTH.StandardCall) > 3 then
    if QTH.StandardCall[1] = 'M' then
      if QTH.StandardCall[2] = 'M' then
        if QTH.StandardCall[3] = '/' then Exit;

  if length(Call) = 1 then Exit;

  Windows.CopyMemory(@TempPrefix, @QTH.StandardCall[1], length(QTH.StandardCall));
  TempPrefix[length(QTH.StandardCall)] := #0;

  if GuantanamoBayCallsign then
    TempPrefix[1] := 'A';

  if TempPrefix[0] = 'R' then
//    if TempPrefix[1] in ['B'..'H','J'..'Z'] then
    if TempPrefix[1] in ['B'..'Z'] then
      if TempPrefix[2] <> '2' then
        TempPrefix[1] := 'A';

  if TempPrefix[0] = 'U' then
    if TempPrefix[1] in ['B'..'E', 'G'..'I'] then TempPrefix[1] := 'A';

  TempLength := length(QTH.StandardCall);

  if CTY.ctyMaxLengthIndexArray[TempPrefix[0]] < TempLength then TempLength := CTY.ctyMaxLengthIndexArray[TempPrefix[0]];

  for TempPointer := TempLength downto 1 do
  begin
    TempPrefix[TempPointer] := #0;
    if ctyFindCallsign(@TempPrefix, TempIndex) then
    begin

      if CTY.ctyCountryMode = ARRLCountryMode then
      begin
        if CTY.ctyTable[PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, TempIndex))^.Country].ID[1] = '*' then Continue;
      end;

      if not PrefixRecPtr(DSA_GetItemPtr(CTY.CTYPrefixesTable, TempIndex))^.FullCallsigns then
        goto FillRecord;

    end;
  end;
  Exit;

  FillRecord:

  CTY.ctyLastIndex := TempIndex;

  TempPrefixRec := DSA_GetItemPtr(CTY.CTYPrefixesTable, TempIndex);
  QTH.Continent := CTY.ctyTable[TempPrefixRec^.Country].DefaultContinent;

  QTH.CountryID := CTY.ctyTable[TempPrefixRec.Country].ID;
  QTH.Country := TempPrefixRec.Country;

  case CTY.ctyZoneMode of
    ITUZoneMode: QTH.Zone := TempPrefixRec.ITUZone;
    CQZoneMode: QTH.Zone := TempPrefixRec.CQZone;
  end;

  if QTH.Zone = 0 then
    case CTY.ctyZoneMode of
      ITUZoneMode: QTH.Zone := CTY.ctyTable[QTH.Country].DefaultITUZone;
      CQZoneMode: QTH.Zone := CTY.ctyTable[QTH.Country].DefaultCQZone;
    end;

//  QTH.Zone := TempPrefixRec.CQZone;

  QTH.Prefix := GetPrefix(QTH.StandardCall);
{
  if CTY.ctyR150SMode then
    if QTH.Country = CTY.ctyUA9Country then
    begin
      QTH.Country := CTY.ctyUA3Country;
      QTH.CountryID := 'UA';
    end;
}
  Result := True;
  CTY.ctyLastLocatedCall := Call;
  CTY.ctyLastLocatedRecord := QTH;
end;

function ctyGetGrid(Call: CallString; var ID: DXMultiplierString): GridString;
var
  TempInteger                           : integer;
  TempChar                              : Char;
 // TempFourChar                          : FourChar;
  Oblast                                : Str2;
begin
  if ctyLocateCall(Call, CTY.ctyTempQTHRecord) then
  begin
    ID := CTY.ctyTempQTHRecord.CountryID;

    for TempInteger := 1 to GridsArraysCount do
      if ID = GridsIndexArray[TempInteger] then
      begin
        TempChar := GetNumber(Call);
        if TempChar in ['0'..'9'] then
        begin
          Result := GridsArray[TempInteger][TempChar];
          if Result <> '' then Exit;
        end;
      end;

    if Copy(ID, 1, 2) = 'UA' then
    begin
      Oblast := GetOblast(Call);
      if length(Oblast) = 2 then
      begin
        if (Oblast[2] in ['A'..'Z']) {and (Oblast[1] <> '2')} then
        begin
          Result := RussianGrids[Oblast[2]][Oblast[1]];
          if Result <> '' then Exit;
        end;
      end;
    end;

    Result := CTY.ctyTable[CTY.ctyTempQTHRecord.Country].DefaultGrid;
  end
  else
    Result := '';
end;

function ctyGetContinent(Call: CallString): ContinentType;
begin
  if ctyLocateCall(Call, CTY.ctyTempQTHRecord) then
    Result := CTY.ctyTable[CTY.ctyTempQTHRecord.Country].DefaultContinent
  else
    Result := UnknownContinent;
end;

function ctyGetCountry(Call: CallString): Word;
begin
  if ctyLocateCall(Call, CTY.ctyTempQTHRecord) then
  begin

    Result := CTY.ctyTempQTHRecord.Country;

  end
  else
    Result := UNKNOWN_COUNTRY;
end;

function ctyGetCountryIdByIndex(Country: Word): DXMultiplierString;
begin
  Windows.ZeroMemory(@Result, SizeOf(Result));
  if Country = UNKNOWN_COUNTRY then Exit;
  Result := CTY.ctyTable[Country].ID;
end;

function ctyGetContinentByIndex(Country: Word): ContinentType;
begin
  if Country = UNKNOWN_COUNTRY then
    Result := UnknownContinent
  else
    Result := CTY.ctyTable[Country].DefaultContinent;
end;

function ctyGetDefaultGrid(Country: Word): GridString;
begin
  Windows.ZeroMemory(@Result, SizeOf(Result));
  if Country = UNKNOWN_COUNTRY then Exit;
  Result := CTY.ctyTable[Country].DefaultGrid;
end;

function ctyGetDefaultITUZone(Country: Word): Byte;
begin
  Result := 0;
  if Country = UNKNOWN_COUNTRY then Exit;
  Result := CTY.ctyTable[Country].DefaultITUZone;
end;

function ctyGetDefaultCQZone(Country: Word): Byte;
begin
  Result := 0;
  if Country = UNKNOWN_COUNTRY then Exit;
  Result := CTY.ctyTable[Country].DefaultCQZone;
end;

function ctyGetCountryUTCOffset(Country: Word): Smallint;
begin
  Result := 0;
  if Country = UNKNOWN_COUNTRY then Exit;
  Result := CTY.ctyTable[Country].UTCOffset;
end;

function ctyGetZone(Call: CallString): Byte;
var
  TempPrefixRec                         : PrefixRecPtr;
begin
  if ctyLocateCall(Call, CTY.ctyTempQTHRecord) then
  begin
    TempPrefixRec := DSA_GetItemPtr(CTY.CTYPrefixesTable, CTY.ctyLastIndex);

    Result := 0;
//     Result := CTY.ctyTempQTHRecord.Zone;
//    if Result <> 0 then Exit;

    case CTY.ctyZoneMode of
      ITUZoneMode:
        begin
          if TempPrefixRec^.ITUZone <> 0 then
          begin
            Result := TempPrefixRec^.ITUZone;
            Exit;
          end;

          if CTY.ctyTempQTHRecord.CountryID = 'K' then
            case GetNumber(Call) of
              '5', '0': Result := 7;
              '6', '7': Result := 6;
            else Result := 8;
            end;

            { In China }

          if CTY.ctyTempQTHRecord.CountryID = 'BY' then
            case GetNumber(Call) of
              '8', '9': Result := 43;
              '0': Result := 42;
            else Result := 44;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'CE' then
            case GetNumber(Call) of
              '1', '2', '3', '4', '5': Result := 14;
              '6', '7', '8': Result := 16;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'CP' then
            case GetNumber(Call) of
              '1', '8', '9': Result := 12;
            else Result := 14;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'LU' then
            case GetFirstSuffixLetter(Call) of
              'V', 'W', 'X': Result := 16;
            else Result := 14;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'PY' then
            case GetNumber(Call) of
              '6', '7', '8': Result := 13;
            else Result := 15;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'UN' then
            case GetFirstSuffixLetter(Call) of
              'J', 'D', 'V', 'G': Result := 31;
            else Result := 30;
            end;

       if (CTY.ctyTempQTHRecord.CountryID = 'UA') or (CTY.ctyTempQTHRecord.CountryID = 'UA9') then
            case GetNumber(Call) of
              '1': case GetFirstSuffixLetter(Call) of
                  'N', 'Z', 'O': Result := 19;
                else Result := 29;
                end;

              '3', '6': Result := 29;

              '4': case GetFirstSuffixLetter(Call) of
                  'A', 'C', 'F', 'L', 'N', 'Q', 'S', 'U', 'Y': Result := 29;   // n4af 4.41.4
                  'H', 'P', 'W': Result := 30;
                end;
{
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'UA9' then
            case GetNumber(Call) of
}
              '8': case GetFirstSuffixLetter(Call) of
                  'T': Result := 32;
                  'V': Result := 33;
                end;

              '9':
                case GetFirstSuffixLetter(Call) of
                  'A', 'C', 'F', 'G', 'L',
                    'M', 'Q', 'S', 'T', 'W': Result := 30;
                  'H', 'O', 'U', 'Y', 'Z': Result := 31;
                  'J', 'K': Result := 21;
                  'X': Result := 20;
                end;

              '0': case GetFirstSuffixLetter(Call) of
                  'B', 'H': Result := 22;
                  'Q': Result := 23;
                  'I': Result := 24;
                  'X': Result := 25;
                  'K': Result := 26;
                  'A', 'O', 'R', 'S', 'W', 'Y': Result := 32; // n4af 4.54.3 issue 213
                  'D', 'J', 'U': Result := 33;
                  'C', 'F', 'L': Result := 34;
                  'Z': Result := 35;
                end;

            end;

          if CTY.ctyTempQTHRecord.CountryID = 'VE' then
            case GetNumber(Call) of
              '1', '9': Result := 9;
              '2', '3': Result := 4;
              '4', '5': Result := 3;
              '6', '7': Result := 2;
            else Result := 0;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'VK' then
            case GetNumber(Call) of
              '4', '8': Result := 55;
              '6': Result := 58;
            else Result := 59;
            end;
           if Result = 0 then  Result := CTY.ctyTable[CTY.ctyTempQTHRecord.Country].DefaultITUZone;    // 4.54.4
        end;

      CQZoneMode:
        begin

         if TempPrefixRec^.CQZone <> 0 then
          begin
            Result := TempPrefixRec^.CQZone;
            Exit;
          end;        

          if CTY.ctyTempQTHRecord.CountryID = 'K' then
            case GetNumber(Call) of
              '1', '2', '3', '4': Result := 5;
              '5', '8', '9', '0': Result := 4;
              '6', '7': Result := 3;
            end;

            { We have to check for call areas for UA9 }

          if CTY.ctyTempQTHRecord.CountryID = 'VE' then
            case GetNumber(Call) of
              '1', '2', '9', '0': Result := 5;
              '3', '4', '5', '6': Result := 4;
              '7': Result := 3;
              '8': Result := 2;
            end;

          if CTY.ctyTempQTHRecord.CountryID = 'UA9' then
            case GetNumber(Call) of
              '8': Result := 18;

              '9': case GetFirstSuffixLetter(Call) of
                  'A', 'C', 'D', 'F', 'G', 'J', 'K', 'L', 'M', 'N', 'Q', 'R', 'S', 'T', 'W', 'X': Result := 17;
                  'H', 'O', 'U', 'Y', 'Z': Result := 18;
                end;

              '0': case GetFirstSuffixLetter(Call) of
                  'A', 'B', 'H', 'O', 'R', 'S', 'U', 'W': Result := 18;  // 4.54.3 issue 213
                  'C', 'D', 'E', 'F', 'I', 'J', 'K', 'L': Result := 19;
                  'Q', 'X', 'Z': Result := 19;
                  'Y': Result := 23;
                else Result := 19;
                end;
            end;

            { And China }

          if CTY.ctyTempQTHRecord.CountryID = 'BY' then
            case GetNumber(Call) of
              '1', '2': Result := 24;

              '3': case GetFirstSuffixLetter(Call) of
                  'G', 'H', 'I', 'J', 'K', 'L': Result := 23;
                else Result := 24;
                end;

              '4', '5', '6', '7', '8': Result := 24;

              '9': case GetFirstSuffixLetter(Call) of
                  'M', 'N', 'P', 'Q', 'R', 'S': Result := 24;
                else Result := 23;
                end;

              '0': Result := 23;
            end;

            { And Austrailia }

          if CTY.ctyTempQTHRecord.CountryID = 'VK' then
            case GetNumber(Call) of
              '6', '8': Result := 29;
            else Result := 30;
            end;
        
          if Result = 0 then Result := CTY.ctyTable[CTY.ctyTempQTHRecord.Country].DefaultCQZone;
        end;
    end;

  end
  else
    Result := DUMMYZONE;
end;

function ctyGetITUZone(Call: CallString): Byte;
var
  TempZoneModeType                      : ZoneModeType;
begin
  TempZoneModeType := CTY.ctyZoneMode;
  CTY.ctyZoneMode := ITUZoneMode;
  Result := ctyGetZone(Call);
  CTY.ctyZoneMode := TempZoneModeType;
end;

function ctyGetCQZone(Call: CallString): Byte;
var
  TempZoneModeType                      : ZoneModeType;
begin
  TempZoneModeType := CTY.ctyZoneMode;
  CTY.ctyZoneMode := CQZoneMode;
  Result := ctyGetZone(Call);
  CTY.ctyZoneMode := TempZoneModeType;
end;

function ctyGetCountryNamePchar(Index: Word): PChar;
begin
  if (Index >= 0) and (Index < CTY.ctyNumberCountries) then
    Result := @CTY.ctyTable[Index].Name
  else
    Result := nil;
end;

function ctyGetCountryIdPchar(Index: Word): PChar;
begin
  if (Index >= 0) and (Index < CTY.ctyNumberCountries) then
    Result := @CTY.ctyTable[Index].ID[1]
  else
    Result := nil;
end;

function ctyGetCountryName(Index: Word): ShortString;
begin
  Windows.ZeroMemory(@Result, SizeOf(Result));
  if (Index >= 0) and (Index < CTY.ctyNumberCountries) then
    Result := CTY.ctyTable[Index].Name;
end;

function ctyGetCountryID(Call: CallString): DXMultiplierString;
begin
  if ctyLocateCall(Call, CTY.ctyTempQTHRecord) then
    Result := CTY.ctyTempQTHRecord.CountryID
  else
    Result := '';
end;

procedure ctyMakeDefaultRemainingCountryList;
begin

end;

procedure ctyLoadInRemainingMults(p: PChar);
var
  i                                     : Cardinal;
  s                                     : Cardinal;
  b                                     : PrefixName;
  e                                     : Cardinal;
begin
  s := 0;
  for i := 0 to 4096 - 1 do
  begin
    if p[i] in ['*', 'A'..'Z', 'a'..'z', '1'..'9'] then if s = 0 then s := i;

    if p[i] in [' ', #13, #10, ',', ';', #0] then if s <> 0 then
      begin
        Windows.ZeroMemory(@b, SizeOf(b));
        Windows.CopyMemory(@b, @p[s], i - s);
        StrUpper(@b);
        for e := 0 to MaxCountries - 1 do
        begin

          if StrComp(@CTY.ctyTable[e].ID[1], b) = 0 then
          begin
            CTY.ctyTable[e].VisibleInRM := 2;
            CTY.ctyCustomRemainingCountryListFound := True;
            Break;
          end;
        end;
        s := 0;
      end;
    if p[i] = #0 then Break;
  end;
end;

function ctyGetTotalCountries(): integer;
begin
  Result := CTY.ctyNumberCountries;
end;

function ctyGetVersion: PChar;
begin
  Result := cty.ctyVersion;
end;

function ctyIsActiveMultiplier(Index: Word): boolean;
begin
  Result := CTY.ctyTable[Index].VisibleInRM <> 1;
end;

procedure ctySetCountryMode(CountryMode: CountryModeType);
begin
  CTY.ctyCountryMode := CountryMode;
end;

procedure ctyLoadInR150SList;
//var
  //TempIndex                             : integer;
 // TempRec                               : PrefixRecPtr;
begin

  cty.ctyR150SMode := True;

  Format(TR4W_R150S_FILENAME, '%sr150s.dat', TR4W_PATH_NAME);
  ctyLoadInCountryFile(TR4W_R150S_FILENAME, True, False);

end;

procedure ctyLoadInRFOblList;
//var
  //TempIndex                             : integer;
  //TempRec                               : PrefixRecPtr;
begin

  cty.ctyRFOblMode := True;

  Format(TR4W_rfobl_FILENAME, '%srfobl.dat', TR4W_PATH_NAME);
  ctyLoadInCountryFile(TR4W_rfobl_FILENAME, True, False);

end;

end.

