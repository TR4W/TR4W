unit uTestCallCompress;

{
  Golden tests for uCallCompress (pre-migration test net).

  Callsign compression packs characters into fixed bytes assuming 1 byte per
  character -- the single most Unicode-fragile primitive in the codebase, and
  foundational to dupe checking and the binary log format. These tests lock the
  exact byte output so the Phase 2 (Unicode) / Phase 3 (64-bit) changes cannot
  silently alter it.

  Two kinds of assertion:
    * exact golden bytes for known inputs (base-37 pack, verified by hand and
      pinned by the build), and
    * structural invariants that need no hand computation (empty -> zeros,
      case-insensitivity via StrU, and the Big/Compress relationship).

  Conventions (docs/tr4w-migration-strategy.md): cast Byte to Integer before
  CheckEquals.
}

interface

uses
   uTR4WTestFramework;

type
   TCallCompressTests = class(TTestCase)
   public
      procedure RunAllTests; override;

   private
      procedure CheckFour(const Call: string; e1, e2, e3, e4: Integer; const Ctx: string);

      procedure Test_WordValueFromCharacter;
      procedure Test_EmptyCall;
      procedure Test_SingleLetter;
      procedure Test_KnownCall_W1AW;
      procedure Test_CaseInsensitive;
      procedure Test_BigCompressStructure;
   end;

implementation

uses
   VC, uCallCompress;

procedure TCallCompressTests.CheckFour(const Call: string; e1, e2, e3, e4: Integer; const Ctx: string);
var
   f : FourBytes;
begin
   CompressFormat(Call, f);
   CheckEquals(e1, Integer(f[1]), Ctx + ' [1]');
   CheckEquals(e2, Integer(f[2]), Ctx + ' [2]');
   CheckEquals(e3, Integer(f[3]), Ctx + ' [3]');
   CheckEquals(e4, Integer(f[4]), Ctx + ' [4]');
end;

// ---------------------------------------------------------------------------
// The base-37 alphabet: A-Z/a-z -> 11..36, 0-9 -> 1..10, space '/' '?' #0 -> 0.
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_WordValueFromCharacter;
begin
   BeginTest('Test_WordValueFromCharacter');
   CheckEquals(0,  Integer(WordValueFromCharacter(CHR(0))), 'NUL -> 0');
   CheckEquals(0,  Integer(WordValueFromCharacter(' ')),    'space -> 0');
   CheckEquals(0,  Integer(WordValueFromCharacter('/')),    'slash -> 0');
   CheckEquals(0,  Integer(WordValueFromCharacter('?')),    'question -> 0');
   CheckEquals(11, Integer(WordValueFromCharacter('A')),    'A -> 11');
   CheckEquals(36, Integer(WordValueFromCharacter('Z')),    'Z -> 36');
   CheckEquals(11, Integer(WordValueFromCharacter('a')),    'a folds to A -> 11');
   CheckEquals(36, Integer(WordValueFromCharacter('z')),    'z -> 36');
   CheckEquals(1,  Integer(WordValueFromCharacter('0')),    '0 -> 1');
   CheckEquals(10, Integer(WordValueFromCharacter('9')),    '9 -> 10');
end;

// ---------------------------------------------------------------------------
// Empty call -> all zero bytes (explicit guard).
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_EmptyCall;
begin
   BeginTest('Test_EmptyCall');
   CheckFour('', 0, 0, 0, 0, 'empty call');
end;

// ---------------------------------------------------------------------------
// 'A' pads to '     A'; first 3 chars are spaces (0,0), last 3 are '  A'
// -> value 11 in the low byte.
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_SingleLetter;
begin
   BeginTest('Test_SingleLetter');
   CheckFour('A', 0, 0, 0, 11, 'single letter A');
end;

// ---------------------------------------------------------------------------
// 'W1AW' pads to '  W1AW'.
//   '  W' -> sum = 33            -> bytes (Hi,Lo) = (0, 33)
//   '1AW' -> sum = 2*37^2 + 11*37 + 33 = 2738 + 407 + 33 = 3178 -> (12, 106)
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_KnownCall_W1AW;
begin
   BeginTest('Test_KnownCall_W1AW');
   CheckFour('W1AW', 0, 33, 12, 106, 'W1AW golden');
end;

// ---------------------------------------------------------------------------
// StrU uppercases before packing, so lower- and upper-case pack identically.
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_CaseInsensitive;
var
   fLo, fUp : FourBytes;
begin
   BeginTest('Test_CaseInsensitive');
   CompressFormat('w1aw', fLo);
   CompressFormat('W1AW', fUp);
   CheckEquals(Integer(fUp[1]), Integer(fLo[1]), 'lower==upper [1]');
   CheckEquals(Integer(fUp[2]), Integer(fLo[2]), 'lower==upper [2]');
   CheckEquals(Integer(fUp[3]), Integer(fLo[3]), 'lower==upper [3]');
   CheckEquals(Integer(fUp[4]), Integer(fLo[4]), 'lower==upper [4]');
end;

// ---------------------------------------------------------------------------
// BigCompressFormat pads to 12 and packs two 6-char halves. For a short call
// the leading half is all spaces (-> zeros), and the trailing half is the same
// 6-char '  W1AW' that CompressFormat('W1AW') packs -- so big[5..8] == four[1..4].
// ---------------------------------------------------------------------------
procedure TCallCompressTests.Test_BigCompressStructure;
var
   big  : EightBytes;
   four : FourBytes;
begin
   BeginTest('Test_BigCompressStructure');
   BigCompressFormat('W1AW', big);
   CompressFormat('W1AW', four);

   CheckEquals(0, Integer(big[1]), 'big[1] leading-space half');
   CheckEquals(0, Integer(big[2]), 'big[2]');
   CheckEquals(0, Integer(big[3]), 'big[3]');
   CheckEquals(0, Integer(big[4]), 'big[4]');

   CheckEquals(Integer(four[1]), Integer(big[5]), 'big[5] == four[1]');
   CheckEquals(Integer(four[2]), Integer(big[6]), 'big[6] == four[2]');
   CheckEquals(Integer(four[3]), Integer(big[7]), 'big[7] == four[3]');
   CheckEquals(Integer(four[4]), Integer(big[8]), 'big[8] == four[4]');
end;

// ---------------------------------------------------------------------------
// Suite entry point
// ---------------------------------------------------------------------------
procedure TCallCompressTests.RunAllTests;
begin
   Test_WordValueFromCharacter;
   Test_EmptyCall;
   Test_SingleLetter;
   Test_KnownCall_W1AW;
   Test_CaseInsensitive;
   Test_BigCompressStructure;
end;

end.
