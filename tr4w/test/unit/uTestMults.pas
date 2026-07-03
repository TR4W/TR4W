unit uTestMults;

{
  Tests for uMults multiplier add / check / count (Issue #1034,
  pre-migration roadmap item 3).

  Scope: the zone-multiplier path of MultsObject, which is fully
  self-contained (fixed-size arrays inside the object, no cty.dat and no
  file backing). DX mults are deliberately NOT covered here because
  SetDXMult gates on CTY.ctyNumberCountries, i.e. it needs a loaded
  country database -- that belongs with the uCTYDAT lookup tests (#1033).

  IMPORTANT semantics (verified against uMults.pas): IsZnMult returns
  TRUE while the zone is still a NEEDED multiplier (its per-band bit is
  clear) and FALSE once SetZnMult has marked it worked. Bits are tracked
  per band and per mode, so working a zone on one band/mode leaves it
  still needed on the others.

  Counting: SetZnMult calls IncrementTotals, which bumps
  MTotals[Band,Mode,rmZone] plus the Both-mode and AllBands roll-ups.
  Tests read MTotals directly (a public field of the object).

  Conventions (docs/tr4w-migration-strategy.md): cast Word/enum to
  Integer before CheckEquals.

  Note: uMults + uSSL were decoupled from MainUnit/TF as part of this
  issue so the multiplier logic links into the dependency-light test EXE.
  This suite also depends on the uCTYDAT/uCallSignRoutines decouple (#1033).
}

interface

uses
   uTR4WTestFramework;

type
   TMultsTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure FreshMults;   // init once + ClearAllMults for a clean slate

      procedure Test_FreshZoneIsNeeded;
      procedure Test_SetMarksZoneWorked;
      procedure Test_WorkedZoneStillNeededOnOtherBand;
      procedure Test_WorkedZoneStillNeededOnOtherMode;
      procedure Test_OtherZoneStillNeeded;
      procedure Test_OutOfRangeZone;
      procedure Test_ZoneCount;
   end;

implementation

uses
   VC, uMults;

// Module-level instance: MultsObject embeds large fixed arrays, so keep it
// off the test stack. Its TSSL sub-lists are Init'd once; ClearAllMults gives
// each test a clean slate (and is itself under test).
var
   mo: MultsObject;
   moInited: boolean;

procedure TMultsTests.FreshMults;
begin
   if not moInited then
      begin
      mo.PrfList.Init;
      mo.DomList.Init;
      moInited := True;
      end;
   mo.ClearAllMults;
end;

// ---------------------------------------------------------------------------
// A freshly-cleared zone reads as a NEEDED multiplier (True).
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_FreshZoneIsNeeded;
begin
   BeginTest('Test_FreshZoneIsNeeded');
   FreshMults;
   CheckTrue(mo.IsZnMult(5, Band20, CW), 'zone 5 needed on 20m CW after clear');
end;

// ---------------------------------------------------------------------------
// SetZnMult marks the zone worked on that band/mode -> IsZnMult now False.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_SetMarksZoneWorked;
begin
   BeginTest('Test_SetMarksZoneWorked');
   FreshMults;
   mo.SetZnMult(5, Band20, CW);
   CheckFalse(mo.IsZnMult(5, Band20, CW), 'zone 5 no longer needed on 20m CW after SetZnMult');
end;

// ---------------------------------------------------------------------------
// Per-band tracking: working a zone on 20m leaves it needed on 40m.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_WorkedZoneStillNeededOnOtherBand;
begin
   BeginTest('Test_WorkedZoneStillNeededOnOtherBand');
   FreshMults;
   mo.SetZnMult(5, Band20, CW);
   CheckTrue(mo.IsZnMult(5, Band40, CW), 'zone 5 still needed on 40m CW');
end;

// ---------------------------------------------------------------------------
// Per-mode tracking: working a zone on CW leaves it needed on Phone.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_WorkedZoneStillNeededOnOtherMode;
begin
   BeginTest('Test_WorkedZoneStillNeededOnOtherMode');
   FreshMults;
   mo.SetZnMult(5, Band20, CW);
   CheckTrue(mo.IsZnMult(5, Band20, Phone), 'zone 5 still needed on 20m Phone');
end;

// ---------------------------------------------------------------------------
// A different zone is unaffected by working zone 5.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_OtherZoneStillNeeded;
begin
   BeginTest('Test_OtherZoneStillNeeded');
   FreshMults;
   mo.SetZnMult(5, Band20, CW);
   CheckTrue(mo.IsZnMult(6, Band20, CW), 'zone 6 still needed on 20m CW');
end;

// ---------------------------------------------------------------------------
// Out-of-range zone (> ZoneMultArraySize): IsZnMult False, SetZnMult a no-op.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_OutOfRangeZone;
begin
   BeginTest('Test_OutOfRangeZone');
   FreshMults;
   CheckFalse(mo.IsZnMult(9999, Band20, CW), 'out-of-range zone is not a mult');
   mo.SetZnMult(9999, Band20, CW);   // must not touch state / raise
   CheckTrue(mo.IsZnMult(5, Band20, CW), 'in-range zone unaffected by out-of-range set');
end;

// ---------------------------------------------------------------------------
// Count: three distinct zones worked on 20m CW -> MTotals reflects 3, with
// the Both-mode and AllBands roll-ups also at 3.
// ---------------------------------------------------------------------------
procedure TMultsTests.Test_ZoneCount;
begin
   BeginTest('Test_ZoneCount');
   FreshMults;
   mo.SetZnMult(3, Band20, CW);
   mo.SetZnMult(5, Band20, CW);
   mo.SetZnMult(7, Band20, CW);
   CheckEquals(3, Integer(mo.MTotals[Band20, CW, rmZone]),   '20m CW zone count');
   CheckEquals(3, Integer(mo.MTotals[Band20, Both, rmZone]), '20m Both-mode roll-up');
   CheckEquals(3, Integer(mo.MTotals[AllBands, CW, rmZone]), 'AllBands CW roll-up');
end;

// ---------------------------------------------------------------------------
// Suite entry point
// ---------------------------------------------------------------------------
procedure TMultsTests.RunAllTests;
begin
   Test_FreshZoneIsNeeded;
   Test_SetMarksZoneWorked;
   Test_WorkedZoneStillNeededOnOtherBand;
   Test_WorkedZoneStillNeededOnOtherMode;
   Test_OtherZoneStillNeeded;
   Test_OutOfRangeZone;
   Test_ZoneCount;
end;

end.
