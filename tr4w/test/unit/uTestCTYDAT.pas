unit uTestCTYDAT;

{
  Tests for uCTYDAT callsign -> DXCC entity lookup (Issue #1033,
  pre-migration roadmap item 2).

  These pin the country-database lookup that ~109k lines of contest code
  rely on for country, continent and zone assignment, so it survives the
  Delphi 12 Unicode / 64-bit phases unchanged.

  Test data: the real, git-tracked cty.dat shipped in tr4w\target\.
  It is resolved relative to the test EXE (test\unit\ -> ..\..\target\)
  and loaded once via ctyLoadInCountryFile -- the same call the app makes
  at startup (tr4w.dpr) -- so the tests exercise the actual
  load -> shell-sort -> index -> binary-search pipeline, not a mock.

  Asserted values were verified directly against the country header lines
  in tr4w\target\cty.dat (name : CQ : ITU : Continent : ... : primaryPrefix):
      United States      NA  K    CQ 05  ITU 08
      England            EU  G    CQ 14  ITU 27
      Japan              AS  JA   CQ 25
      Fed. Rep. Germany  EU  DL
      Argentina          SA  LU
      Australia          OC  VK
      South Africa       AF  ZS

  Conventions (docs/tr4w-migration-strategy.md): cast enums/Bytes to
  Integer before CheckEquals; keep each method focused on one entity.

  Note: uCTYDAT was decoupled from MainUnit (own Log4D logger) as part of
  this issue so it could be linked into the dependency-light test EXE.
}

interface

uses
   uTR4WTestFramework;

type
   TCTYDATTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      FLoaded: Boolean;

      // Loads cty.dat once (idempotent). Asserts the load succeeded.
      procedure EnsureCtyLoaded;
      // Asserts a callsign resolves to the expected continent + DXCC id.
      procedure CheckEntity(const Call: string; ExpectCont: Integer;
                            const ExpectID, Ctx: string);

      procedure Test_LoadCtyDat;
      procedure Test_UnitedStates_W1AW;
      procedure Test_England_G3;
      procedure Test_Japan_JA1;
      procedure Test_Germany_DL1;
      procedure Test_Argentina_LU1;
      procedure Test_Australia_VK2;
      procedure Test_SouthAfrica_ZS6;
      procedure Test_Zones_W1_England_Japan;
      procedure Test_UnknownCountryIndex;
   end;

implementation

uses
   SysUtils, VC, uCTYDAT;

// ---------------------------------------------------------------------------
// Load helper -- loads the shipped cty.dat once, relative to the test EXE.
// ---------------------------------------------------------------------------

procedure TCTYDATTests.EnsureCtyLoaded;
var
   path: string;
begin
   if FLoaded then
      begin
      Exit;
      end;

   // test\unit\tr4w_unit_tests.exe -> ..\..\target\cty.dat
   path := ExtractFilePath(ParamStr(0)) + '..\..\target\cty.dat';
   CheckTrue(FileExists(path), 'cty.dat present at ' + path);
   if not FileExists(path) then
      begin
      Exit;
      end;

   // (CheckDupe=False, LoadRemainingMults=False) -- the country/continent/
   // zone tables come from the main parse; remaining-mults data is not
   // needed for entity lookups and avoids extra file dependencies.
   CheckTrue(ctyLoadInCountryFile(PChar(path), False, False),
             'ctyLoadInCountryFile succeeded');
   FLoaded := True;
end;

procedure TCTYDATTests.CheckEntity(const Call: string; ExpectCont: Integer;
                                   const ExpectID, Ctx: string);
begin
   CheckEquals(ExpectCont, Integer(ctyGetContinent(Call)), Ctx + ' continent');
   CheckEquals(ExpectID, Trim(ctyGetCountryID(Call)), Ctx + ' DXCC id');
end;

// ---------------------------------------------------------------------------
// Load + sanity
// ---------------------------------------------------------------------------

procedure TCTYDATTests.Test_LoadCtyDat;
begin
   BeginTest('Test_LoadCtyDat');
   EnsureCtyLoaded;
   // The shipped cty.dat lists ~340 DXCC entities; a low bound proves the
   // parse populated the country table without hard-coding the exact count.
   CheckTrue(ctyGetTotalCountries > 300, 'country table populated (> 300)');
end;

// ---------------------------------------------------------------------------
// Continent + DXCC-id spot checks, one representative call per continent
// ---------------------------------------------------------------------------

procedure TCTYDATTests.Test_UnitedStates_W1AW;
begin
   BeginTest('Test_UnitedStates_W1AW');
   EnsureCtyLoaded;
   CheckEntity('W1AW', Integer(NorthAmerica), 'K', 'W1AW (USA)');
end;

procedure TCTYDATTests.Test_England_G3;
begin
   BeginTest('Test_England_G3');
   EnsureCtyLoaded;
   CheckEntity('G3ABC', Integer(Europe), 'G', 'G3ABC (England)');
end;

procedure TCTYDATTests.Test_Japan_JA1;
begin
   BeginTest('Test_Japan_JA1');
   EnsureCtyLoaded;
   CheckEntity('JA1ABC', Integer(Asia), 'JA', 'JA1ABC (Japan)');
end;

procedure TCTYDATTests.Test_Germany_DL1;
begin
   BeginTest('Test_Germany_DL1');
   EnsureCtyLoaded;
   CheckEntity('DL1ABC', Integer(Europe), 'DL', 'DL1ABC (Germany)');
end;

procedure TCTYDATTests.Test_Argentina_LU1;
begin
   BeginTest('Test_Argentina_LU1');
   EnsureCtyLoaded;
   CheckEntity('LU1ABC', Integer(SouthAmerica), 'LU', 'LU1ABC (Argentina)');
end;

procedure TCTYDATTests.Test_Australia_VK2;
begin
   BeginTest('Test_Australia_VK2');
   EnsureCtyLoaded;
   CheckEntity('VK2ABC', Integer(Oceania), 'VK', 'VK2ABC (Australia)');
end;

procedure TCTYDATTests.Test_SouthAfrica_ZS6;
begin
   BeginTest('Test_SouthAfrica_ZS6');
   EnsureCtyLoaded;
   CheckEntity('ZS6ABC', Integer(Africa), 'ZS', 'ZS6ABC (South Africa)');
end;

// ---------------------------------------------------------------------------
// CQ / ITU zone spot checks (uniform-zone entities only, to avoid
// dependence on per-prefix zone overrides).
// ---------------------------------------------------------------------------

procedure TCTYDATTests.Test_Zones_W1_England_Japan;
begin
   BeginTest('Test_Zones_W1_England_Japan');
   EnsureCtyLoaded;

   // New England (W1): CQ 5 / ITU 8
   CheckEquals(5, Integer(ctyGetCQZone('W1AW')),  'W1AW CQ zone');
   CheckEquals(8, Integer(ctyGetITUZone('W1AW')), 'W1AW ITU zone');

   // England: CQ 14 / ITU 27
   CheckEquals(14, Integer(ctyGetCQZone('G3ABC')),  'G3ABC CQ zone');
   CheckEquals(27, Integer(ctyGetITUZone('G3ABC')), 'G3ABC ITU zone');

   // Japan CQ 25 (ITU zone varies across the country, so not asserted)
   CheckEquals(25, Integer(ctyGetCQZone('JA1ABC')), 'JA1ABC CQ zone');
end;

// ---------------------------------------------------------------------------
// Negative / edge: the UNKNOWN_COUNTRY sentinel maps to nothing.
// Pure index getters -- deterministic, no lookup needed.
// ---------------------------------------------------------------------------

procedure TCTYDATTests.Test_UnknownCountryIndex;
begin
   BeginTest('Test_UnknownCountryIndex');
   EnsureCtyLoaded;
   CheckEquals(Integer(UnknownContinent),
               Integer(ctyGetContinentByIndex(UNKNOWN_COUNTRY)),
               'UNKNOWN_COUNTRY -> UnknownContinent');
   CheckEquals('', Trim(ctyGetCountryIdByIndex(UNKNOWN_COUNTRY)),
               'UNKNOWN_COUNTRY -> empty DXCC id');
end;

// ---------------------------------------------------------------------------
// Suite entry point
// ---------------------------------------------------------------------------

procedure TCTYDATTests.RunAllTests;
begin
   Test_LoadCtyDat;
   Test_UnitedStates_W1AW;
   Test_England_G3;
   Test_Japan_JA1;
   Test_Germany_DL1;
   Test_Argentina_LU1;
   Test_Australia_VK2;
   Test_SouthAfrica_ZS6;
   Test_Zones_W1_England_Japan;
   Test_UnknownCountryIndex;
end;

end.
