<#
.SYNOPSIS
   Lints Object Pascal source for if/for/while/with bodies that are missing the
   required begin/end block (per the project's coding standard).

.DESCRIPTION
   Flags the high-confidence, unambiguous case: a line that ends with the body
   introducer `then` or `do`, whose next code line is a single statement NOT
   wrapped in `begin`.

   Deliberately conservative to avoid false positives:
     * Only end-of-line `then`/`do` are checked -- single-line forms like
       `if X then Exit;` and `else if Y then DoY` are not flagged (this also
       sidesteps the `if X then Exit;` and dispatch-chain carve-outs).
     * `else` bodies are not checked (can't distinguish if-else from case-else
       line-by-line without a real parser).
     * Bodies that are `begin`, `Exit`, `Continue`, or `Break` are allowed.

   Trailing // and { } / (* *) comments are stripped before the check.

.PARAMETER Path
   One or more Pascal files to lint.

.OUTPUTS
   One line per violation:  <file>:<line>: <message>
   Exit code 0 = clean, 1 = at least one violation (handy for CI).
#>
[CmdletBinding()]
param(
   [Parameter(ValueFromRemainingArguments = $true)]
   [string[]] $Path
)

function Test-IsSkippableBody {
   param([string] $Body)
   # A body that legitimately needs no begin/end on its own line.
   if ($Body -match '^begin\b')                  { return $true }
   if ($Body -match '^(Exit|Continue|Break)\b')  { return $true }
   return $false
}

$violations = 0

foreach ($file in $Path) {
   if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { continue }

   $lines = Get-Content -LiteralPath $file
   for ($i = 0; $i -lt $lines.Count; $i++) {

      # Strip trailing comments, then trim.
      $code = $lines[$i]
      $code = $code -replace '//.*$', ''
      $code = $code -replace '\{[^}]*\}\s*$', ''
      $code = $code -replace '\(\*.*?\*\)\s*$', ''
      $code = $code.TrimEnd()

      # Rule #2: `begin` inline after then/do -- it must be on its own line.
      if ($code -match '\b(then|do)\s+begin\b') {
         Write-Output ("{0}:{1}: 'begin' must be on its own line, not inline after then/do (line: {2})" -f $file, ($i + 1), $code.Trim())
         $violations++
      }

      # Rule #1: body introducer at end of line?
      if ($code -notmatch '(^|\s)(then|do)$') { continue }

      # Find the next non-blank, non-comment line (the body).
      $j = $i + 1
      while ($j -lt $lines.Count) {
         $t = $lines[$j].Trim()
         if ($t -eq '' -or $t.StartsWith('//') -or $t.StartsWith('{') -or $t.StartsWith('(*')) {
            $j++
            continue
         }
         break
      }
      if ($j -ge $lines.Count) { continue }

      $body = $lines[$j].Trim()
      if (-not (Test-IsSkippableBody $body)) {
         Write-Output ("{0}:{1}: if/for/while body not wrapped in begin/end (next line: '{2}')" -f $file, ($i + 1), $body)
         $violations++
      }
   }
}

if ($violations -gt 0) { exit 1 } else { exit 0 }
