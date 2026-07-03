unit uCallCompress;

{
  Callsign compression -- extracted VERBATIM from tree.pas (Issue: pre-migration
  test net for the byte-packing primitives, which are the most Unicode-fragile
  code in the codebase: they assume 1 byte per character).

  A callsign is packed into fixed bytes via a base-37 alphabet:
    WordValueFromCharacter : Char  -> 0..36  (A-Z/a-z -> 11..36, 0-9 -> 1..10,
                                              space '/' '?' #0 -> 0)
    CompressThreeCharacters: <=3 chars -> 2 bytes (Hi/Lo of sum value*37^n)
    CompressFormat         : 6-char call -> FourBytes (two 3-char halves)
    BigCompressFormat      : 12-char call -> EightBytes (two CompressFormat)

  Behavior is unchanged from tree.pas. tree.pas forwards its public
  CompressFormat / BigCompressFormat here, so the ~13 existing callers (dupe
  checking, binary log format, ...) run this code unchanged.

  Bodies moved verbatim, with two deliberate, behavior-preserving edits:
    * strU(Call) -> uStrSearch.StrU(Call): tree's strU was TF.strU, which #997
      relocated to the light uStrSearch. Same routine; this drops the TF
      (-> MainUnit) dependency so this unit stays link-light.
    * The one extended-char branch in WordValueFromCharacter is written as the
      explicit byte sequence #$EF#$BF#$BD instead of a source literal -- see the
      comment there. That keeps it byte-identical without an encoding-fragile
      character in this file.
}

interface

uses
   VC;

function WordValueFromCharacter(Character: Char): Word;
procedure CompressThreeCharacters(Input: Str80; var Output: TwoBytes);
procedure CompressFormat(Call: CallString; var Output: FourBytes);
procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);

implementation

uses
   uStrSearch;

function WordValueFromCharacter(Character: Char): Word;
begin
  if (Character = CHR(0)) or (Character = ' ') or
    (Character = '/') or (Character = '?') then
  begin
    WordValueFromCharacter := 0;
    Exit;
  end;

  if Character in ['A'..'Z'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('A') + 11;
    Exit;
  end;

  if Character in ['a'..'z'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('a') + 11;
    Exit;
  end;

  if Character in ['0'..'9'] then
  begin
    WordValueFromCharacter := Ord(Character) - Ord('0') + 1;
    Exit;
  end;

  // Verbatim from tree.pas: originally a single extended char that a past UTF-8
  // conversion mangled into U+FFFD (bytes EF BF BD). Delphi 7 reads that as a
  // 3-byte string literal, so as a `Char = <3-byte string>` comparison it never
  // matches today. Represented as explicit bytes to preserve that behavior
  // exactly without an encoding-fragile literal in this file. (Flagged for D12.)
  if Character = #$EF#$BF#$BD then
  begin
    WordValueFromCharacter := 1;
    Exit;
  end;

  WordValueFromCharacter := 0;
end;

procedure CompressThreeCharacters(Input: Str80; var Output: TwoBytes);

{ This procedure will compress a string of up to 3 characters to 2 bytes. }

var
  Multiplier, Value, Sum                : Word;
  LoopCount, CharPosition               : integer;

begin
  if ((Input = '') or (length(Input) > 3)) then
  begin
    Output[1] := 0;
    Output[2] := 0;
    Exit;
  end;

  Multiplier := 1;
  Sum := 0;
  LoopCount := 0;

  for CharPosition := length(Input) downto 1 do
  begin
    Value := WordValueFromCharacter(Input[CharPosition]);
    Sum := Sum + Value * Multiplier;
    inc(LoopCount);
    if LoopCount >= 3 then Break;
    Multiplier := Multiplier * 37;
  end;

  Output[2] := Lo(Sum);
  Output[1] := Hi(Sum);
end;

procedure CompressFormat(Call: CallString; var Output: FourBytes);

{ This function will give the compressed representation for the string
    passed to it.  The string must be no longer than 6 characters.  }

var
  TempBytes                             : TwoBytes;

begin
  if Call = '' then
  begin
    Output[1] := 0;
    Output[2] := 0;
    Output[3] := 0;
    Output[4] := 0;
    Exit;
  end;

  uStrSearch.StrU(Call);   // was TF.strU (relocated to uStrSearch in #997)

  while length(Call) < 6 do Call := ' ' + Call;

  CompressThreeCharacters(Copy(Call, 1, 3), TempBytes);
  Output[1] := TempBytes[1];
  Output[2] := TempBytes[2];
  CompressThreeCharacters(Copy(Call, 4, 3), TempBytes);
  Output[3] := TempBytes[1];
  Output[4] := TempBytes[2];
end;

procedure BigCompressFormat(Call: CallString; var CompressedBigCall: EightBytes);

var
  CompressedCall                        : FourBytes;
  Byte                                  : integer;
  ShortCall                             : Str20;

begin
  while length(Call) < 12 do
     begin
     Call := ' ' + Call;
     end;

  ShortCall := Copy(Call, 1, 6);
  CompressFormat(ShortCall, CompressedCall);

  for Byte := 1 to 4 do
     begin
     CompressedBigCall[Byte] := CompressedCall[Byte];
     end;
  Delete(Call, 1, 6);

  CompressFormat(Call, CompressedCall);
  for Byte := 1 to 4 do
     begin
     CompressedBigCall[Byte + 4] := CompressedCall[Byte];
     end;
end;

end.
