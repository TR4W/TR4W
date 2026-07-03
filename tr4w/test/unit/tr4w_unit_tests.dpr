program tr4w_unit_tests;

{
  TR4W Automated Unit Test Runner
  Delphi 7 — console application, no VCL.

  Usage:
    tr4w_unit_tests.exe
    Exit code 0 = all tests passed.
    Exit code 1 = one or more failures.

  DUnitX migration (Delphi 12 Phase 4):
    Replace the main block with:
      var Runner := TDUnitX.CreateRunner;
      Runner.Run;
    Add [TestFixture]/[Test] attributes to each suite class.
    Remove RegisterSuite calls and RunAllSuites.
}

{$APPTYPE CONSOLE}

uses
   SysUtils,
   uTR4WTestFramework   in 'uTR4WTestFramework.pas',
   uIcomCIV             in '..\..\src\uIcomCIV.pas',
   uTestIcomCIV         in 'uTestIcomCIV.pas',
   uRadioBand           in '..\..\src\uRadioBand.pas',
   uTestRadioBand       in 'uTestRadioBand.pas',
   uFlexRadioUtils      in '..\..\src\uFlexRadioUtils.pas',
   uTestFlexRadioUtils  in 'uTestFlexRadioUtils.pas',
   VC                   in '..\..\src\VC.pas',
   utils_text           in '..\..\src\utils\utils_text.pas',
   uTestUtilsText       in 'uTestUtilsText.pas',
   uADIF                in '..\..\src\uADIF.pas',
   uTestADIF            in 'uTestADIF.pas',
   uTestADIFFixtures    in 'uTestADIFFixtures.pas',
   uBandLookup          in '..\..\src\uBandLookup.pas',
   uTestBandLookup      in 'uTestBandLookup.pas',
   uCabrilloFormat      in '..\..\src\uCabrilloFormat.pas',
   uTestCabrilloFormat  in 'uTestCabrilloFormat.pas',
   uCabrilloExchange    in '..\..\src\uCabrilloExchange.pas',
   uTestCabrilloExchange in 'uTestCabrilloExchange.pas',
   uCRC32               in '..\..\src\uCRC32.pas',
   uTestCRC32           in 'uTestCRC32.pas',
   utils_math           in '..\..\src\utils\utils_math.pas',
   uTestUtilsMath       in 'uTestUtilsMath.pas',
   uGridDistance        in '..\..\src\uGridDistance.pas',
   uTestGridDistance    in 'uTestGridDistance.pas',
   utils_file           in '..\..\src\utils\utils_file.pas',
   uTestUtilsFile       in 'uTestUtilsFile.pas',
   uTestADIFRegression  in 'uTestADIFRegression.pas',
   uFreqTimeFormat      in '..\..\src\uFreqTimeFormat.pas',
   uTestFreqTimeFormat  in 'uTestFreqTimeFormat.pas',
   uStrSearch           in '..\..\src\uStrSearch.pas',
   uTestStrSearch       in 'uTestStrSearch.pas',
   uCallCompress        in '..\..\src\uCallCompress.pas',
   uTestCallCompress    in 'uTestCallCompress.pas';

begin
   IsMultiThread := True;  // Match main application setting

   WriteLn('=== TR4W Unit Tests ===');
   WriteLn('');

   RegisterSuite(TIcomCIVTests.Create('IcomCIV'));
   RegisterSuite(TRadioBandTests.Create('RadioBand'));
   RegisterSuite(TFlexRadioUtilsTests.Create('FlexRadioUtils'));
   RegisterSuite(TUtilsTextTests.Create('UtilsText'));
   RegisterSuite(TADIFLexerTests.Create('ADIFLexer'));
   RegisterSuite(TADIFHelperTests.Create('ADIFHelpers'));
   RegisterSuite(TADIFMappingTests.Create('ADIFMapping'));
   RegisterSuite(TADIFFixtureTests.Create('ADIFFixtures'));
   RegisterSuite(TBandLookupTests.Create('BandLookup'));
   RegisterSuite(TCabrilloFormatTests.Create('CabrilloFormat'));
   RegisterSuite(TCabrilloExchangeTests.Create('CabrilloExchange'));
   RegisterSuite(TCRC32Tests.Create('CRC32'));
   RegisterSuite(TUtilsMathTests.Create('UtilsMath'));
   RegisterSuite(TGridDistanceTests.Create('GridDistance'));
   RegisterSuite(TUtilsFileTests.Create('UtilsFile'));
   RegisterSuite(TADIFRegressionTests.Create('ADIFRegression'));
   RegisterSuite(TFreqTimeFormatTests.Create('FreqTimeFormat'));
   RegisterSuite(TStrSearchTests.Create('StrSearch'));
   RegisterSuite(TCallCompressTests.Create('CallCompress'));

   if RunAllSuites then
      begin
      WriteLn('');
      WriteLn('All tests passed.');
      ExitCode := 0;
      end
   else
      begin
      WriteLn('');
      WriteLn('FAILURES detected — see above.');
      ExitCode := 1;
      end;
end.
