{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }

 unit PostUnit;

{$IMPORTEDDATA OFF}
interface

uses
  uCallSignRoutines,
  uCTYDAT,
  LogDom,
  uErmak,
  uCallsigns,
  LogK1EA,
  utils_text,
  utils_file,
  sysutils,
  StrUtils,
  Classes,
  Tree,
  Version,
  VC,
//  Help,
  uMults,
  uADIF,
  LogEdit,
  TF,
  LogWind,
  //Country9,
  LogDupe,
  LogStuff,
  LogGrid,
  ZoneCont,
  Messages,
  LogCW, // 4.53.2
  Windows,
  uCabrilloFormat,  // tCabrilloFreqString / tCabrilloModeString + per-field formatters (extracted from this unit, see uCabrilloFormat.pas)
  uCabrilloExchange, // #998 capstone: FormatCabrilloExchange (the case ActiveExchange MYEX/HISEX builder, extracted + unit-tested)
  uSuperCheckPartialFileUpload,
  Dialogs;

type
  RateSheetType = array[1..3, 0..23, BandType, CW..Both] of integer;
  RateSheetPointer = ^RateSheetType;

  ReportEntryArray = array[0..500] of Str20;
  ReportEntryArrayPointer = ^ReportEntryArray;

type
  MultCountryTotalRecordType = record
    FirstCall: CallString;
    TotalQSOs: integer;
  end;

type
  CountryMultiplierArray = array[Band160..Band10, 0..MaxCountries - 1] of MultCountryTotalRecordType;
  CountryMultiplierArrayPointer = ^CountryMultiplierArray;

type

  PLEFTONBIStateType = record
    LastBand: BandType;
    LastMode: ModeType;
    LastDateString: Str20;
    LastTimeString: Str80;
    LastHourIndex: integer;
    DoingBreak: boolean;
    BandsThisMinute: array[BandType] of boolean;
  end;

type

  HourTotalsRecord = record
    HourName: string[2];
    QSOs: array[BandType, ModeType] of integer;
    QSOPoints: array[BandType, ModeType] of integer;
    Mults: array[BandType, ModeType] of integer;
    Minutes: array[BandType, ModeType] of integer;
  end;

  LogHourTotalArray = array[0..49] of HourTotalsRecord;
  LogHourTotalArrayPointer = ^LogHourTotalArray;

type
  QTCEntryRecord = record
    Time: CallString;
    Call: CallString;
    Number: CallString;
  end;

  QTCEntryArrayType = array[0..9] of QTCEntryRecord;
  QTCEntryArrayPtr = ^QTCEntryArrayType;
  {
  type
     CabrilloStringType =
        (
        csRSTZone,
        csRSTQSONumber,
        csDummy
        );
  }
function GetMyExchangeForExport: string;
procedure ExportToEDI;
procedure ExportToEDIByBand(Band: BandType);
procedure ExportToADIF;
procedure ExportToTRLogFormat;
procedure ExportToCSV;   //n4af 04.30.3
procedure ExportTo3830Scores;
procedure PrintQSOsByCountry;
function GenerateCountryMultiplierTotals: boolean;
procedure QSOsByCountryByBand;
procedure ContinentReport;
function CheckLog: boolean;
procedure CheckTimeOnByBand(LastHour: integer);
procedure FinishOutLastHour;
procedure PrintHourTotals;
function GenerateAllTotalsPerHour: boolean;
procedure ScoreByHour;
//function DetermineNumberOfQTCs: integer;
function CalculateTotals: boolean;
procedure SummarySheet;
procedure CreateCabrilloFile;
procedure CheckForNewContestDate(Date: TQSOTime);

procedure WriteADIFField(sFieldName: string; sFieldValue: string);
function SLOperatorsSortProc(List: TStringList; Index1, Index2: Integer): Integer;
function GetOperatorsFromLog: string;
function DeleteRepeatedSpaces(const s: string): string;

procedure WriteTitleBlockToSummarySheet;

procedure WriteScoreInformationToSummarySheet;

function MakeCategoryString: string;
function tGenerateSummaryPortionOfCabrilloFile: boolean;
function tGenerateLogPortionOfCabrilloFile: boolean;
procedure tFirstCallInEachCountry;
procedure SetTransmittersIdentifiers;
procedure tFirstCallInEachZone;
procedure PrintFirstCountryMultiplierCallsigns;
function GenerateZoneMultiplierTotals: boolean;
procedure PrintFirstZoneMultiplierCallsigns;
procedure ZoneReport;
procedure BandChangeReport;
procedure MakeReportFileName(ShortFileName: PChar);
procedure MakeNotesList;
function GoodLookingQSO: boolean;
function GetStateFromSection(section: string) : string;
//function CorrectContestExchange: boolean;

var
  tShowFrequencyinLog                   : boolean = true;     // Was false but Howie confirmed it should be true de NY4I 9 AUG 2020
  Radio1IDs                             : Str10;
//  Radio2ID                              : Char = #0;
  RateSheet                             : RateSheetPointer;

  TempRXData                            : ContestExchange;

  CABRILLO_RST_SEND                     : array[0..3] of Char;
  CABRILLO_RST_RCVD                     : array[0..3] of Char;
  CABRILLO_MYEX                         : string;   // Issue #998: was array[0..63] of Char
  CABRILLO_HISEX                        : string;   // Issue #998: was array[0..63] of Char

  ADIF_FREQ_STRING                      : array[0..15] of Char;

  tReportsFilename                      : FileNameType;
  tReportFileWrite                      : HWND;
  PreviewFileNameAddress                : PChar;
  PreviewFileIsCabrillo                 : boolean;

  CountryMultTotals                     : CountryMultiplierArrayPointer;
  P                                     : pchar;
  P1                                     : pchar;
  TotalLogQSOs                          : Cardinal;
  ReportsFilename                       : ShortString;

  ReportFileWrite                       : Text;
  LOGDATFileWrite                       : ShortString;
  SStr                                   : Pchar;
  Precedence, Check, Section, Power, NameInFile, QTH: Str40;
  Overlay                               : Str20;
  NameFileDirectory                     : Str40;
  NumberDates                           : integer;
  ContestDates                          : array[0..10] of TQSOTime;

  QSOPointTotals                        : array[BandType, CW..Both] of integer;
  RawQSOTotals                          : array[BandType, CW..Both] of integer;
  PostQSOTotals                         : array[BandType, CW..Both] of integer;
{
  PrefixTotals                          : array[BandType, CW..Both] of Word;
  ZoneTotals                            : array[BandType, CW..Both] of Word;
  DomesticTotals                        : array[BandType, CW..Both] of Word;
  DXTotals                              : array[BandType, CW..Both] of Word;
}
  //  Header                                : Str80;

  LogHourTotals                         : LogHourTotalArrayPointer;

  //  NumberDates       : integer;
  NumberLogHours                        : integer;

  PhoneUsed                             : boolean;
  PLeftOnBiState                        : PLEFTONBIStateType;

  CallSignLength                        : integer;
  Contest                               : ContestType;

  NumberExchangeElementsToRecord        : integer;
  ReverseExchangeNumber                 : boolean;

  PreviousName                          : Str20; { Used for Interent Sprint }

  QTCEnable                             : boolean;

  ReceivedCallCursorPosition            : integer;
  ReceivedQSONumberLength               : integer;
  RSTIsPartOfTheExchange                : boolean;

  SentDataLength                        : integer;
  SniffForTransmitter                   : boolean;
  SentInformation                       : Str40;
  SentQSONumberLength                   : integer;

  SuppressRST                           : boolean;

  QTCList                               : QTCEntryArrayPtr;

const
  CabrilloVersion                       = '3.0';

//  NumberOperatorCategories              = 3;
//  NumberBandCategories                  = 13;
//  NumberPowerCategories                 = 3;
//  NumberModeCategories                  = 4;
  NumberOverlayCategories               = 6;
  NumberAssistedCategories              = 2;
  NumberStationCategories               = 11;
  NumberTimeCategories                  = 4;
  NumberTransmitterCategories           = 5;
  NumberCertificateCategories           = 2;
  NumberSections                        = 81;

  NumberErmakOverlayCategories          = 11;

  ErmakOverlayCategory                  : array[0..NumberErmakOverlayCategories - 1] of PChar = (
    'YL',
    'JR',
    'JR-13',
    'JR-15',
    'JR-18',
    'JR-19',
    'VETERAN',
    'SPECIAL',
    'OVER-50',
    'OVER-100',
    'POLAR'
    );

 { OperatorCategory                      : array[0..NumberOperatorCategories - 1] of PChar = (
    'SINGLE-OP',
    'MULTI-OP',
    'CHECKLOG');
 }
  TimeCategory                          : array[0..NumberTimeCategories - 1] of PChar = (
    '6-HOURS',
    '8-HOURS',
    '12-HOURS',
    '24-HOURS'
    );

  TransmitterCategory                   : array[0..NumberTransmitterCategories - 1] of PChar = (
    'ONE',
    'TWO',
    'LIMITED',
    'UNLIMITED',
    'SWL'
    );
{
  AssistedCategory                      : array[0..NumberAssistedCategories - 1] of PChar = (
    'NON-ASSISTED',
    'ASSISTED'
    );
}
  StationCategory                       : array[0..NumberStationCategories - 1] of PChar =
    (
    'DISTRIBUTED',
    'FIXED',
    'MOBILE',
    'PORTABLE',
    'ROVER',
    'ROVER-LIMITED',
    'ROVER-UNLIMITED',
    'EXPEDITION',
    'HQ',
    'SCHOOL',
    'EXPLORER'
    );
{
  BandCategory                          : array[0..NumberBandCategories - 1] of PChar = (
    'ALL',
    '160M',
    '80M',
    '40M',
    '20M',
    '15M',
    '10M',
    '6M',
    '2M',
    '222',
    '432',
    '902',
    '1.2G'
    );

  PowerCategory                         : array[0..NumberPowerCategories - 1] of PChar = (
    'HIGH',
    'LOW',
    'QRP');

  ModeCategory                          : array[0..NumberModeCategories - 1] of PChar = (
    'CW',
    'RTTY',
    'SSB',
    'MIXED');
}
  OverlayCategory                       : array[0..NumberOverlayCategories - 1] of PChar = (
    'CLASSIC',  //n4af 4.35.4
    'ROOKIE',
    'TB-WIRES',
    'YOUTH',
    'NOVICE-TECH',
    'YL');

    Certificate                 : array[0..NumberCertificateCategories - 1] of PChar = (           //N4AF 37.0.1
    'YES',
    'NO');

    // tCabrilloFreqString and tCabrilloModeString moved to uCabrilloFormat.pas
    // (see this unit's interface uses clause).  The arrays are still referenced
    // by LOGContactToUDP in LOGSUBS2.PAS, which now also `uses uCabrilloFormat`.
{
  tARRLVESections                       : array[0..NumberSections - 1] of PChar = (
    'AB',
    'AK',
    'AL',
    'AR',
    'AZ',
    'BC',
    'CO',
    'CT',
    'DE',
    'DX',
    'EB',
    'EM',
    'ENY',
    'EP',
    'EW',
    'GA',
    'IA',
    'ID',
    'IL',
    'IN',
    'KS',
    'KY',
    'LA',
    'LAX',
    'MAR',
    'MB',
    'MDC',
    'ME',
    'MI',
    'MN',
    'MO',
    'MS',
    'MT',
    'NC',
    'ND',
    'NE',
    'NFL',
    'NH',
    'NL',
    'NLI',
    'NM',
    'NNJ',
    'NNY',
    'NTX',
    'NV',
    'NWT',
    'OH',
    'OK',
    'ON',
    'OR',
    'ORG',
    'PAC',
    'PR',
    'QC',
    'RI',
    'SB',
    'SC',
    'SCV',
    'SD',
    'SDG',
    'SF',
    'SFL',
    'SJV',
    'SK',
    'SNJ',
    'STX',
    'SV',
    'TN',
    'UT',
    'VA',
    'VI',
    'VT',
    'WCF',
    'WI',
    'WMA',
    'WNY',
    'WPA',
    'WTX',
    'WV',
    'WWA',
    'WY');
}
implementation

uses
  uCbrSum,
  MainUnit,
  uCFG;
  // mo.DomList (ADIF CNTY long-name lookup) is reachable via the
  // interface-section 'uses uMults' clause above.

procedure WriteADIFField(sFieldName: string; sFieldValue: string);
var sBuffer: string;
begin
   if length(sFieldValue) > 0 then
      begin
      sBuffer := SysUtils.Format('<%s:%u>%s ', [sFieldName,length(sFieldValue),sFieldValue]);
      sWriteFileFromString(tReportFileWrite, sBuffer);
      end
   else
      begin
      DEBUGMSG('[WriteADIFField] ' + sFieldName + ' value is blank - skipping');
      end;
end;

// For state-based QSO parties, return the host state's 2-letter ADIF
// postal code; for any other contest return ''.  Used during ADIF export
// when QTHString carries a county/section code instead of a 2-letter
// state code -- in those contests we know the state by the contest itself.
function GetStateForContest(c: ContestType): string;
begin
   case c of
      CALQSOPARTY        : Result := 'CA';
      FLORIDAQSOPARTY    : Result := 'FL';
      MICHQSOPARTY       : Result := 'MI';
      MINNQSOPARTY       : Result := 'MN';
      MOQSOPARTY         : Result := 'MO';
      NCQSOPARTY         : Result := 'NC';
      OHIOQSOPARTY       : Result := 'OH';
      TEXASQSOPARTY      : Result := 'TX';
      WISCONSINQSOPARTY  : Result := 'WI';
      TENNESSEEQSOPARTY  : Result := 'TN';
      COLORADOQSOPARTY   : Result := 'CO';
      PAQSOPARTY         : Result := 'PA';
      INQSOPARTY         : Result := 'IN';
   else
      Result := '';
   end;
end;

procedure CreateCabrilloFile;
label
  1;
var
  SetTransmittersId                     : boolean;
  scp: TSCPUpload;
begin

  SetTransmittersId := False;
  Format(tReportsFilename, '%s%s.LOG', TR4W_LOG_PATH_NAME, @MyCall[1]);
  DeleteSlashes(tReportsFilename);

  Windows.ZeroMemory(@Radio1IDs, SizeOf(Radio1IDs));
  SetTransmittersId := TF.SendDlgItemMessage(CreateCabrilloWindow, $CF {124}, CB_GETCURSEL) = 1;

  if Contest = IOTA then
    if TF.SendDlgItemMessage(CreateCabrilloWindow, 120, CB_GETCURSEL) = 1 then SetTransmittersId := True;

  if SetTransmittersId then SetTransmittersIdentifiers;

//  if FileExists(tReportsFilename) then if not OkayToDeleteExistingFile(tReportsFilename) then Exit;
  if not tGenerateSummaryPortionOfCabrilloFile then Exit;
  if not tGenerateLogPortionOfCabrilloFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;
  CloseHandle(tReportFileWrite);
  PreviewFileNameAddress := tReportsFilename;
  PreviewFileIsCabrillo := True;
  FilePreview;
  // Ask if user wants to upload the Cabrillo file to SCP
  If YesOrNo(0,'Do you want to upload your Cabrillo file to SuperChecklPartial?' {TC_WANTTOCONVERTLOG}) = IDYES then
     begin
     scp := TSCPUpload.Create(true,logger);
     try
        if scp.SendFile(tReportsFileName) then
           begin
           logger.Info('%s file uploaded to SCP',[tReportsFileName]);
           //ShowMessage('Log file successfully uploaded to SuperCheckPartial');
           MessageBox(tr4whandle, 'Log file successfully uploaded to SuperCheckPartial', nil, MB_OK or MB_ICONINFORMATION {or MB_RTLREADING } or MB_TASKMODAL);
           end
        else
           begin
           logger.Error('Error sending %s to SCP',[tReportsFileName]);
           logger.Error(scp.errorResult);
           //ShowMessage(PChar('Error uploading log file to SuperCheckPartial' + #13#10 + scp.errorResult));
           MessageBox(tr4whandle, PChar('Error uploading log file to SuperCheckPartial' + #13#10 + scp.errorResult), nil, MB_OK or MB_ICONINFORMATION {or MB_RTLREADING } or MB_TASKMODAL);
           end;
     finally
        scp.Free;
     end;
  end;

end;

function CheckLog: boolean;
begin
  Result := False;
  //  if not CheckForTempFile then exit;

  if not CalculateTotals then Exit;
  //  if not CheckLogForContacts then exit;

  Result := True;
end;

procedure SummarySheet;
begin
  if not CheckLog then Exit;
  MakeReportFileName('Summary.txt');
  if not tOpenFileForWrite(tReportFileWrite, @ReportsFilename[1]) then Exit;
  WriteTitleBlockToSummarySheet;
  WriteScoreInformationToSummarySheet;
  CloseHandle(tReportFileWrite);
  FilePreview;
end;

procedure ExportTo3830Scores;
// 3830Scores.com quick-submission report.  Layout adapts to contest rules:
//   - Mode columns (CW Qs / Ph Qs / Dig Qs) appear only for modes that have
//     at least one logged QSO.  Ph = USB+LSB+FM per spec.
//   - Per-band Mults column appears iff MultByBand = TRUE (CQ-WW, etc).
//   - Bottom Mults summary: per-mode breakdown if MultByMode = TRUE (FQP,
//     NAQP); single 'Mults: N' otherwise.
//   - All 8 standard 3830-form bands always rendered (160-2), even when
//     zero.  Extra VHF/UHF rows appended only if they have QSOs.
const
   STD_BANDS        : array[0..7] of BandType =
      (Band160, Band80, Band40, Band20, Band15, Band10, Band6, Band2);
   STD_BAND_LABELS  : array[0..7] of string =
      ('160', ' 80', ' 40', ' 20', ' 15', ' 10', '  6', '  2');
var
   buf                                   : string;
   band                                  : BandType;
   i                                     : integer;
   m                                     : RemainingMultiplierType;
   showCW, showPh, showDig               : boolean;
   bandQsCW, bandQsPh, bandQsDig         : integer;
   bandMults                             : integer;
   sumCW, sumPh, sumDig, sumBandMults    : integer;
   cwMults, phMults, digMults, totalMults: integer;
   iniBuf                                : array[0..255] of Char;
   operatorsStr, classStr, powerStr      : string;

   function CalcBandMults(b: BandType): integer;
   var
      mm: RemainingMultiplierType;
   begin
      Result := 0;
      // Note: FM QSOs are folded into Phone by LoadTotalCount (PostUnit ~986)
      // before RawQSOTotals/MTotals are populated, so RawQSOTotals/MTotals
      // are indexed by the CW..Both subrange of ModeType.  Don't reference
      // FM here (compile error: 'Constant expression violates subrange bounds').
      for mm := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
         if MultByMode then
            Result := Result +
                      mo.MTotals[b, CW, mm] +
                      mo.MTotals[b, Phone, mm] +
                      mo.MTotals[b, Digital, mm]
         else
            Result := Result + mo.MTotals[b, Both, mm];
   end;

begin
   if not CheckLog then Exit;
   MakeReportFileName('3830Score.txt');
   if not tOpenFileForWrite(tReportFileWrite, @ReportsFilename[1]) then Exit;

   // RawQSOTotals[band, Phone] already includes FM (folded in by LoadTotalCount).
   showCW  := RawQSOTotals[AllBands, CW] > 0;
   showPh  := RawQSOTotals[AllBands, Phone] > 0;
   showDig := RawQSOTotals[AllBands, Digital] > 0;

   buf := SysUtils.Format('SOFTWARE: %s http://www.tr4w.net'#13#10#13#10,
                          [TR4W_CURRENTVERSION]);
   buf := buf + '3830Scores summary'#13#10#13#10;

   // Metadata from the Cabrillo Summary fields the operator saved (read
   // silently from tr4w.ini [REPORT] - no dialog popup).  Empty values
   // emit blank lines so the operator types them directly on 3830's form.
   if GetPrivateProfileString('REPORT', '_OPERATORS',
         nil, iniBuf, SizeOf(iniBuf), TR4W_INI_FILENAME) > 0
   then operatorsStr := string(iniBuf) else operatorsStr := '';
   if GetPrivateProfileString('REPORT', '_CATEGORY-OPERATOR',
         nil, iniBuf, SizeOf(iniBuf), TR4W_INI_FILENAME) > 0
   then classStr := string(iniBuf) else classStr := '';
   if GetPrivateProfileString('REPORT', '_CATEGORY-POWER',
         nil, iniBuf, SizeOf(iniBuf), TR4W_INI_FILENAME) > 0
   then powerStr := string(iniBuf) else powerStr := '';

   buf := buf + SysUtils.Format('Call Used: %s'#13#10,        [string(MyCall)]);
   buf := buf + SysUtils.Format('Operators: %s'#13#10,        [operatorsStr]);
   buf := buf + SysUtils.Format('Class:     %s'#13#10,        [classStr]);
   buf := buf + SysUtils.Format('Power:     %s'#13#10#13#10,  [powerStr]);

   // Header row
   buf := buf + '     ';
   if showCW       then buf := buf + '    CW Qs';
   if showPh       then buf := buf + '    Ph Qs';
   if showDig      then buf := buf + '   Dig Qs';
   if MultByBand   then buf := buf + '    Mults';
   buf := buf + #13#10;

   sumCW := 0; sumPh := 0; sumDig := 0; sumBandMults := 0;

   // Standard 8 HF/Low-band rows (always shown, even when zero)
   for i := Low(STD_BANDS) to High(STD_BANDS) do
   begin
      band      := STD_BANDS[i];
      bandQsCW  := RawQSOTotals[band, CW];
      bandQsPh  := RawQSOTotals[band, Phone];
      bandQsDig := RawQSOTotals[band, Digital];

      buf := buf + SysUtils.Format('%4s ', [STD_BAND_LABELS[i]]);
      if showCW  then buf := buf + SysUtils.Format('%9d', [bandQsCW]);
      if showPh  then buf := buf + SysUtils.Format('%9d', [bandQsPh]);
      if showDig then buf := buf + SysUtils.Format('%9d', [bandQsDig]);
      if MultByBand then
         begin
         bandMults := CalcBandMults(band);
         buf := buf + SysUtils.Format('%9d', [bandMults]);
         sumBandMults := sumBandMults + bandMults;
         end;
      buf := buf + #13#10#13#10;   // blank line between rows for readability

      sumCW  := sumCW  + bandQsCW;
      sumPh  := sumPh  + bandQsPh;
      sumDig := sumDig + bandQsDig;
   end;

   // Extra VHF/UHF rows beyond 2m, only if they have QSOs
   for band := Band222 to Band24G do
      begin
      bandQsCW  := RawQSOTotals[band, CW];
      bandQsPh  := RawQSOTotals[band, Phone];
      bandQsDig := RawQSOTotals[band, Digital];
      if (bandQsCW + bandQsPh + bandQsDig) = 0 then Continue;

      buf := buf + SysUtils.Format('%4s ', [BandStringsArray[band]]);
      if showCW  then buf := buf + SysUtils.Format('%9d', [bandQsCW]);
      if showPh  then buf := buf + SysUtils.Format('%9d', [bandQsPh]);
      if showDig then buf := buf + SysUtils.Format('%9d', [bandQsDig]);
      if MultByBand then
         begin
         bandMults := CalcBandMults(band);
         buf := buf + SysUtils.Format('%9d', [bandMults]);
         sumBandMults := sumBandMults + bandMults;
         end;
      buf := buf + #13#10#13#10;   // blank line between rows for readability

      sumCW  := sumCW  + bandQsCW;
      sumPh  := sumPh  + bandQsPh;
      sumDig := sumDig + bandQsDig;
      end;

   // Total row
   buf := buf + 'Total';
   if showCW     then buf := buf + SysUtils.Format('%9d', [sumCW]);
   if showPh     then buf := buf + SysUtils.Format('%9d', [sumPh]);
   if showDig    then buf := buf + SysUtils.Format('%9d', [sumDig]);
   if MultByBand then buf := buf + SysUtils.Format('%9d', [sumBandMults]);
   buf := buf + #13#10#13#10;

   // Mults summary
   if MultByMode then
      begin
      cwMults := 0; phMults := 0; digMults := 0;
      for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
         begin
         cwMults  := cwMults  + mo.MTotals[AllBands, CW, m];
         phMults  := phMults  + mo.MTotals[AllBands, Phone, m];
         digMults := digMults + mo.MTotals[AllBands, Digital, m];
         end;
      if showCW  then buf := buf + SysUtils.Format('CW Mults: %d'#13#10,  [cwMults]);
      if showPh  then buf := buf + SysUtils.Format('Ph Mults: %d'#13#10,  [phMults]);
      if showDig then buf := buf + SysUtils.Format('Dig Mults: %d'#13#10, [digMults]);
      totalMults := cwMults + phMults + digMults;
      buf := buf + SysUtils.Format('Total Mults: %d'#13#10, [totalMults]);
      end
   else
      begin
      totalMults := 0;
      for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
         totalMults := totalMults + mo.MTotals[AllBands, Both, m];
      buf := buf + SysUtils.Format('Mults: %d'#13#10, [totalMults]);
      end;

   buf := buf + SysUtils.Format('Total Score: %d'#13#10, [TotalScore]);

   sWriteFileFromString(tReportFileWrite, buf);
   CloseHandle(tReportFileWrite);
   FilePreview;
end;

function ContestFriendlyParens: string;
// Returns ' (<FriendlyName>)' for the current contest, or '' when the contest
// has no FriendlyName defined.  Shared by the human-readable summary-sheet and
// score-report headers so the friendly-name formatting lives in one place.
var
  sFriendly                             : string;
begin
  sFriendly := string(ContestsArray[Contest].FriendlyName);
  if sFriendly <> '' then
     begin
     Result := ' (' + sFriendly + ')';
     end
  else
     begin
     Result := '';
     end;
end;

procedure WriteTitleBlockToSummarySheet;
var
  nNumberOfBytesToWrite                 : integer;
  TempTag                               : CabrilloTags;
begin
  // Title block built as a plain string -- replaces the prior inline-asm
  // wsprintf argument pushing.  The contest's friendly name is shown in
  // parentheses after the contest name when one is defined (ContestFriendlyParens).
  sWriteFileFromString(tReportFileWrite,
    #13#10 +
    SysUtils.Format('%21s SUMMARY SHEET', [string(ContestName)]) + #13#10#13#10 +
    '               CONTEST: ' + string(ContestName) + ContestFriendlyParens + #13#10 +
    '            START DATE: ' + string(tGetDateFormat(ContestDates[0])) + #13#10 +
    '         CALLSIGN USED: ' + string(MyCall) + #13#10 +
    '               LOCATOR: ' + string(MyGrid) + #13#10#13#10);

//  for i := 147 to 167 - 2 + 2 do
  for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
  begin
    if ErmakSpecification then if TempTag = ctOperators then Continue;

    Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer2, SizeOf(TempBuffer2));
    if TempBuffer2[0] = #0 then Continue;

    nNumberOfBytesToWrite := Format(wsprintfBuffer, '%22s: %s'#13#10, @CabrilloTagsArray[TempTag].ctrTag[1], TempBuffer2);


    sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
  end;

  // Footer built as a plain string -- replaces the prior inline-asm wsprintf
  // arg pushing.  The run/search counts had been read from raw byte offsets
  // [tRestartInfo+$4]/[+$8], which are riQSOByOpMode[CQOpMode] (run) and
  // riQSOByOpMode[SearchAndPounceOpMode] (search); see RestartInfo in LOGDUPE.
  sWriteFileFromString(tReportFileWrite,
    #13#10'        OPERATING TIME: ' + string(MillisecondsToFormattedString(TimeSpentByBand[AllBands] * 1000, False)) +
    #13#10'            CQ COUNTER: ' + IntToStr(tRestartInfo.riCQTotalCounter) +
    #13#10'            RUN/SEARCH: ' + IntToStr(tRestartInfo.riQSOByOpMode[CQOpMode]) + '/' +
                                       IntToStr(tRestartInfo.riQSOByOpMode[SearchAndPounceOpMode]) + ' Qs' +
    #13#10'      UNIQUE CALLSIGNS: ' + IntToStr(CallsignsList.GetTotalWorkedStations) + #13#10 +
    #13#10'            SOFTWARE: ' + TR4W_CURRENTVERSION + ' http://www.tr4w.net'#13#10);


end;

procedure WriteScoreInformationToSummarySheet;
var
  Band                                  : BandType;
  Mode                                  : ModeType;
  TempMode                              : ModeType;
  BString                               : PChar;
  MString                               : PChar;
  SumInteger                            : integer;
  m                                     : RemainingMultiplierType;
  TotalLine                             : boolean;
  totalMults                            : integer;
const
  h                                     = #13#10'  BAND   Raw QSOs   Valid QSOs   Points';
  mn                                    :array[RemainingMultiplierType] of PChar = ('','Mults', 'Countries', 'Zones', 'Prefixes');
  breakline                             = #13#10' __________________________________________________________________';
begin
  TotalLine := False;
  totalMults := -1;  // To accomodate the totals line that will add one too many
  sWriteFile(tReportFileWrite, h, length(h));    // QSO part of header

  for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
  begin
    if mo.MTotals[AllBands, Both, m] = 0 then
       begin
       Continue;
       end;
    sWriteFileFromString(tReportFileWrite, SysUtils.Format('%10s', [string(mn[m])]));
  end;

  sWriteFile(tReportFileWrite, breakline, length(breakline));

  for Band := Band160 to AllBands do
    for Mode := CW to Phone do
      if RawQSOTotals[Band, Mode] > 0 then
      begin

        BString := BandStringsArray[Band];
        MString := ModeStringArray[Mode];

        TempMode := Mode;
        if Band = AllBands then
        begin
          if TotalLine then Continue;
          sWriteFile(tReportFileWrite, breakline, length(breakline));
          sWriteFile(tReportFileWrite, #13#10, 2);
          TempMode := Both;
          TotalLine := True;
          BString := 'Total';   // 4.97.8
          MString := nil;
        end;

        SumInteger := QSOPointTotals[Band, TempMode];
      // Issue #998: asm-push wsprintf -> SysUtils.Format + sWriteFileFromString
      // (removes the asm, the custom Format function, and the PChar buffer in one).
      // Arg order matches the original right-to-left pushes: %5s=BString,
      // %4s=MString, %8d=RawQSOTotals, %12d=PostQSOTotals, %8d=QSOPointTotals.
        sWriteFileFromString(tReportFileWrite,
          SysUtils.Format(#13#10' %5s%4s %8d  %12d %8d',
            [string(BString), string(MString),
             RawQSOTotals[Band, TempMode],
             PostQSOTotals[Band, TempMode],
             SumInteger]));
        if contest = WINTERFIELDDAY then
           begin
           inc(totalMults);
           end;

        for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
        begin
          if mo.MTotals[AllBands, Both, m] = 0 then
             begin
             Continue;
             end;
          if contest = WINTERFIELDDAY then     // or any contest where it is one mults if QSOs on this band/mode
             begin
             if totalLine then
                begin
                sWriteFileFromString(tReportFileWrite, SysUtils.Format('%10d', [totalMults]));
                end
             else
                begin
                sWriteFileFromString(tReportFileWrite, SysUtils.Format('%10d', [1]));
                end;
             end
          else
             begin
             sWriteFileFromString(tReportFileWrite, SysUtils.Format('%10d', [mo.MTotals[Band, TempMode, m]]));
             end;
        end;
      end;
//  sWriteFile(tReportFileWrite, breakline, length(breakline));
  if QTCEnable then
  begin
    sWriteFileFromString(tReportFileWrite, SysUtils.Format(#13#10#13#10'    There were %d QTC points.', [TotalNumberQTCsProcessed]));
  end;
  if Contest <> ARRLFIELDDAY then
     sWriteFileFromString(tReportFileWrite, SysUtils.Format(#13#10#13#10'    Claimed Score = %d points.', [TotalScore]))      // 4.108.9
  else
     sWriteFileFromString(tReportFileWrite, SysUtils.Format(#13#10#13#10'     Claimed Score = %d points.', [SumInteger]));     // 4.108.9
end;

function CalculateTotals: boolean;

{ Returns TRUE if successful }
label
  1;
var
  Band                                  : BandType;
  PreviousBand                          : BandType;
  Mode                                  : ModeType;
  FirstRecord                           : boolean;
  TempMode                              : ModeType;
  TimeDifference                        : integer;
  PreviousQSOTime                       : TQSOTime;
  Min                                   : Integer;
begin

if pos('CQ-WW', ContestName ) <> 0 then       //n4af 4.35.3
Min := 60
else
Min := 30;
  NumberDates := 0;
//  OperatingTime := 0;
  CalculateTotals := False;
  ZeroMemory(@TimeSpentByBand, SizeOf(TimeSpentByBand));
  for Band := Band160 to AllBands do
    for Mode := CW to Both do
    begin
      PostQSOTotals[Band, Mode] := 0;
      RawQSOTotals[Band, Mode] := 0;
      QSOPointTotals[Band, Mode] := 0;
    end;

  if not OpenLogFile then Exit;
  FirstRecord := True;
  PreviousBand := NoBand;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if TempRXData.ceQSO_Deleted = True then goto 1;
    if TempRXData.ceQSO_Skiped then goto 1;
    if TempRXData.ceRecordKind <> rkQSO then goto 1;

    TempMode := TempRXData.Mode;
    if TempMode = FM then TempMode := Phone;

    inc(RawQSOTotals[TempRXData.Band, TempMode]);
    inc(RawQSOTotals[TempRXData.Band, Both]);
    inc(RawQSOTotals[AllBands, TempMode]);
    inc(RawQSOTotals[AllBands, Both]);

    if GoodLookingQSO then if TempRXData.ceDupe = False then
      begin

        if not FirstRecord then
        begin
          TimeDifference := QSOTimeToSeconds(TempRXData.tSysTime) - QSOTimeToSeconds(PreviousQSOTime);
          if TimeDifference <= Min {min} * 60 then      //n4af 4.35.3
//            OperatingTime := OperatingTime + TimeDifference;
          begin
            if PreviousBand = TempRXData.Band then
              inc(TimeSpentByBand[TempRXData.Band], TimeDifference);
            inc(TimeSpentByBand[AllBands], TimeDifference);
          end;
          PreviousBand := TempRXData.Band;
        end;

        PreviousQSOTime := TempRXData.tSysTime;

        FirstRecord := False;
        CheckForNewContestDate(TempRXData.tSysTime);

        inc(PostQSOTotals[TempRXData.Band, TempMode]);
        inc(PostQSOTotals[TempRXData.Band, Both]);
        inc(PostQSOTotals[AllBands, TempMode]);
        inc(PostQSOTotals[AllBands, Both]);

        QSOPointTotals[TempRXData.Band, TempMode] := QSOPointTotals[TempRXData.Band, TempMode] + TempRXData.QSOPoints;
        QSOPointTotals[TempRXData.Band, Both] := QSOPointTotals[TempRXData.Band, Both] + TempRXData.QSOPoints;
        QSOPointTotals[AllBands, TempMode] := QSOPointTotals[AllBands, TempMode] + TempRXData.QSOPoints;
        QSOPointTotals[AllBands, Both] := QSOPointTotals[AllBands, Both] + TempRXData.QSOPoints;
      end;
    goto 1;
  end;
  CloseLogFile;
//  OperatingTime := OperatingTime div 60;
  CalculateTotals := True;
end;

procedure CheckForNewContestDate(Date: TQSOTime);

var
  Index                                 : integer;

begin
  if NumberDates = 0 then
  begin
    ContestDates[0] := Date;
    inc(NumberDates);
    Exit;
  end;

  for Index := 0 to NumberDates - 1 do
    if ContestDates[Index].qtDay = Date.qtDay then Exit;

  ContestDates[NumberDates] := Date;
  inc(NumberDates);

  if (NumberDates > 10) and (Contest <> GENERALQSO) then     // 4.72.1
  begin
    showwarning(TC_TOOMANYCONTESTDATES);
      //    halt;
  end;

end;

function MakeCategoryString: string;
begin
  Result :=
    GetDialogItemText(CreateCabrilloWindow, 121) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 122) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 123) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 124);

end;
{
function DetermineNumberOfQTCs: integer;

// This procedure will look at the QTC.DAT file and determine how many QTCs
//  were sent or received.

var
  FileRead                         : Text;
  //  FileString                            : Str80;
  QTCsThisStation, NumberQTCs      : integer;

begin
  NumberQTCs := 0;

  if OpenFileForRead(FileRead, 'QTCLIST.DAT') then
  begin
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead);

      if not Eof(FileRead) then
      begin
        ReadLn(FileRead, QTCsThisStation);
        NumberQTCs := NumberQTCs + QTCsThisStation;
      end;
    end;

    Close(FileRead);
  end;

  DetermineNumberOfQTCs := NumberQTCs;
end;
}

procedure ScoreByHour;
begin

  if not CheckLog then Exit;
  MakeReportFileName('HourTotals.txt');
  New(LogHourTotals);
  if GenerateAllTotalsPerHour then PrintHourTotals;
  Dispose(LogHourTotals);

end;

function GenerateAllTotalsPerHour: boolean;

{ This routine will fill up the global variable LogHourTotals with data. }
label
  1;
var
  LineNumber, CurrentHourIndex          : integer;
  TotalLogQSOs                          : LONGINT;
  LastHourProcessed                     : Word;
  TempMults                             : integer;
begin
  Result := False;
  Windows.ZeroMemory(LogHourTotals, SizeOf(LogHourTotalArray));

  { Initialize the time on band status }

  with PLeftOnBiState do
  begin
    LastBand := NoBand;
    LastMode := NoMode;
    LastDateString := '';
    LastTimeString := '';
    LastHourIndex := -1;
    DoingBreak := False;
  end;
  Windows.ZeroMemory(@PLeftOnBiState.BandsThisMinute, SizeOf(PLeftOnBiState.BandsThisMinute));

  if not OpenLogFile then Exit;

  { Initialize variables }

  CurrentHourIndex := 0;
  LastHourProcessed := UNKNOWN_COUNTRY;
  NumberLogHours := 0;
  TotalLogQSOs := 0;
  LineNumber := 0;

  ReadVersionBlock;
  1:

  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      if LastHourProcessed <> TempRXData.tSysTime.qtHour then
      begin
        if CurrentHourIndex = 49 then
        begin
          ShowMessage(TC_MORETHAN50DIFFERENTHOURSINTHISLOG);
          Exit;
        end;

        if LastHourProcessed <> UNKNOWN_COUNTRY then inc(CurrentHourIndex);

        LogHourTotals^[CurrentHourIndex].HourName := IntToStr(TempRXData.tSysTime.qtHour);
        LastHourProcessed := TempRXData.tSysTime.qtHour;
      end;

      inc(TotalLogQSOs);

      inc(LogHourTotals^[CurrentHourIndex].QSOs[TempRXData.Band, TempRXData.Mode]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[AllBands, TempRXData.Mode]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[TempRXData.Band, Both]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[AllBands, Both]);

      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[TempRXData.Band, TempRXData.Mode], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[AllBands, TempRXData.Mode], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[TempRXData.Band, Both], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[AllBands, Both], TempRXData.QSOPoints);

      TempMults := 0;
      if TempRXData.DXMult then inc(TempMults);
      if TempRXData.DomesticMult then inc(TempMults);
      if TempRXData.ZoneMult then inc(TempMults);
      if TempRXData.PrefixMult then inc(TempMults);

      if TempMults <> 0 then
//      if (TempRXData.DXMult or TempRXData.DomesticMult or TempRXData.ZoneMult or TempRXData.PrefixMult) then
      begin
        inc(LogHourTotals^[CurrentHourIndex].Mults[TempRXData.Band, TempRXData.Mode], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[AllBands, TempRXData.Mode], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[TempRXData.Band, Both], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[AllBands, Both], TempMults);
      end;

    end;
    goto 1;
  end;

  FinishOutLastHour;
  CheckTimeOnByBand(CurrentHourIndex);

  CloseLogFile;
  GenerateAllTotalsPerHour := True;
end;

procedure PrintHourTotals;

var
  //  Destination                           : Char;
  FileWrite                             : Text;
  Band                                  : BandType;
  //  TempString, FileName                  : Str80;
  TotalMults, LastHourPrinted, HourIndex, ThisHour, Result: integer;
  TotalQSOPoints, TotalContacts         : LONGINT;
  Score                                 : REAL;
  Day1QSOTotals, Day1MultTotals, Day2QSOTotals, Day2MultTotals: array[Band160..Band10] of LONGINT;
  DoingDay1                             : boolean;
  TotalDay1QSOs, TotalDay1Mults, TotalDay2QSOs, TotalDay2Mults: LONGINT;
  TempBand                              : BandType;
  ShowScore                             : boolean;
begin
  ShowScore := not (Contest in [CUPRFCW, CUPRFSSB, RU3AXMEMORIAL, CUPURAL, UKRAINECHAMPIONSHIP, {RADIOYOC,} RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB]);
  OpenFileForWrite(FileWrite, ReportsFilename);

  //  if Header = '' then
  //  Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, ContestName + ContestFriendlyParens + ' ' + MyCall);
  WriteLn(FileWrite);

  Write(FileWrite, 'HR     160       80       40       20       15       10   HR TOT CUM TOTAL');
  if ShowScore then WriteLn(FileWrite, '  SCORE') else WriteLn(FileWrite, '');

  Write(FileWrite, '--   -------  -------  -------  -------  -------  ------- ------ ---------');
  if ShowScore then WriteLn(FileWrite, '  -----') else WriteLn(FileWrite, '');

  HourIndex := 0;

  TotalMults := 0;
  TotalContacts := 0;
  TotalQSOPoints := 0;

  DoingDay1 := True;

  for Band := Band160 to Band10 do
  begin
    Day1QSOTotals[Band] := 0;
    Day1MultTotals[Band] := 0;
    Day2QSOTotals[Band] := 0;
    Day2MultTotals[Band] := 0;
  end;

  while LogHourTotals^[HourIndex].HourName <> '' do
  begin
    inc(LastHourPrinted);

    if (HourIndex > 0) and (LastHourPrinted > 23) then
    begin
      DoingDay1 := False;
      LastHourPrinted := 0;
    end;

    Val(LogHourTotals^[HourIndex].HourName, ThisHour, Result);

    if HourIndex = 0 then LastHourPrinted := ThisHour;

    while ThisHour <> LastHourPrinted do
    begin
      Write(FileWrite, LastHourPrinted: 2);
      for Band := Band160 to Band10 do Write(FileWrite, '     --- ');
      Write(FileWrite, '    --- ');
      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');

      if ShowScore then
      begin
        Score := TotalQSOPoints * TotalMults / 1000000;
        WriteLn(FileWrite, Score: 6: 3, ' M');
      end
      else
        WriteLn(FileWrite);

      inc(LastHourPrinted);
      if LastHourPrinted > 23 then LastHourPrinted := 0;
    end;

    TotalContacts := TotalContacts + LogHourTotals^[HourIndex].QSOs[AllBands, Both];
    TotalMults := TotalMults + LogHourTotals^[HourIndex].Mults[AllBands, Both];
    TotalQSOPoints := TotalQSOPoints + LogHourTotals^[HourIndex].QSOPoints[AllBands, Both];

    if DoingDay1 then
    begin

      for TempBand := Band160 to Band10 do
      begin
        Day1QSOTotals[TempBand] := Day1QSOTotals[TempBand] + LogHourTotals^[HourIndex].QSOs[TempBand, Both];
        Day1MultTotals[TempBand] := Day1MultTotals[TempBand] + LogHourTotals^[HourIndex].Mults[TempBand, Both];
      end;
    end
    else
    begin
      for TempBand := Band160 to Band10 do
      begin
        Day2QSOTotals[TempBand] := Day2QSOTotals[TempBand] + LogHourTotals^[HourIndex].QSOs[TempBand, Both];
        Day2MultTotals[TempBand] := Day2MultTotals[TempBand] + LogHourTotals^[HourIndex].Mults[TempBand, Both];
      end;
    end;

    with LogHourTotals^[HourIndex] do
    begin
      Write(FileWrite, ThisHour: 2);

      for Band := Band160 to Band10 do
      begin
        if QSOs[Band, Both] > 0 then
        begin
          Write(FileWrite, QSOs[Band, Both]: 6, '/', Mults[Band, Both]);
          if Mults[Band, Both] < 10 then Write(FileWrite, ' ');
        end
        else
          Write(FileWrite, '     --- ');
      end;

      Write(FileWrite, QSOs[AllBands, Both]: 5, '/', Mults[AllBands, Both]);

      if Mults[AllBands, Both] < 10 then Write(FileWrite, ' ');

      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');
      if ShowScore then
      begin
        Score := TotalQSOPoints * TotalMults / 1000000;
        WriteLn(FileWrite, Score: 6: 3, ' M');
      end
      else
        WriteLn(FileWrite);
    end;

    Val(LogHourTotals^[HourIndex].HourName, LastHourPrinted, Result);
    inc(HourIndex);
  end;

  TotalDay1QSOs := Day1QSOTotals[Band160] + Day1QSOTotals[Band80] +
    Day1QSOTotals[Band40] + Day1QSOTotals[Band20] +
    Day1QSOTotals[Band15] + Day1QSOTotals[Band10];

  TotalDay1Mults := Day1MultTotals[Band160] + Day1MultTotals[Band80] +
    Day1MultTotals[Band40] + Day1MultTotals[Band20] +
    Day1MultTotals[Band15] + Day1MultTotals[Band10];

  TotalDay2QSOs := Day2QSOTotals[Band160] + Day2QSOTotals[Band80] +
    Day2QSOTotals[Band40] + Day2QSOTotals[Band20] +
    Day2QSOTotals[Band15] + Day2QSOTotals[Band10];

  TotalDay2Mults := Day2MultTotals[Band160] + Day2MultTotals[Band80] +
    Day2MultTotals[Band40] + Day2MultTotals[Band20] +
    Day2MultTotals[Band15] + Day2MultTotals[Band10];

  Write(FileWrite, 'D1');

  for Band := Band160 to Band10 do
  begin
    Write(FileWrite, Day1QSOTotals[Band]: 5, '/', Day1MultTotals[Band]);
    if Day1MultTotals[Band] < 10 then Write(FileWrite, ' ');
    if Day1MultTotals[Band] < 100 then Write(FileWrite, ' ');
  end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs: 6, '/', TotalDay1Mults);

  if not DoingDay1 then
  begin
    Write(FileWrite, 'D2');

    for Band := Band160 to Band10 do
    begin
      Write(FileWrite, Day2QSOTotals[Band]: 5, '/', Day2MultTotals[Band]);
      if Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end;

    WriteLn(FileWrite, '        ', TotalDay2QSOs: 6, '/', TotalDay2Mults);
  end;

  Write(FileWrite, 'TO');

  for Band := Band160 to Band10 do
    //    if Band >= Band40 then
  begin
    Write(FileWrite, (Day1QSOTotals[Band] + Day2QSOTotals[Band]): 5, '/',
      Day1MultTotals[Band] + Day2MultTotals[Band]);

    if Day1MultTotals[Band] + Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
    if Day1MultTotals[Band] + Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
  end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs + TotalDay2QSOs: 6, '/', TotalDay1Mults + TotalDay2Mults);

  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;
end;

procedure FinishOutLastHour;

{ This routine will look at the last QSO processed by the PLeftOnBiState
  machine to see if we should fill in the last few minutes of the contest
  with the band of the last QSO.  This is done if the interval is less
  than 10 minutes. }

var
  LastMinuteString                      : Str20;
  Minute, LastMinute, Result            : integer;

begin
  with PLeftOnBiState do
  begin

    LastMinuteString := PostcedingString(LastTimeString, ':');

    Val(LastMinuteString, LastMinute, Result);

    if (LastMinute >= 50) and (LastMinute < 59) then
      for Minute := LastMinute + 1 to 59 do
      begin
        inc(LogHourTotals^[LastHourIndex].Minutes[LastBand, Both]);
        inc(LogHourTotals^[LastHourIndex].Minutes[AllBands, Both]);
      end;

  end;
end;

procedure CheckTimeOnByBand(LastHour: integer);

{ This procedure will look through the LogHourTotals to make sure that the
  individual band on times add up to the hourly on time (as indicated in
  the All, Both cell).  If the total of the band times exceeds that of
  the All, Both number, the band will the longest on time during the
  hour will have its time adjusted to make the total come out correctly. }

var
  Correction, HourTotal, BiggestBandTotal, HourIndex: integer;
  Band, BiggestBand                     : BandType;

begin
  for HourIndex := 0 to LastHour do
  begin
    HourTotal := 0;
    BiggestBand := NoBand;
    BiggestBandTotal := 0;

    for Band := Band160 to BandLight do
    begin
      HourTotal := HourTotal + LogHourTotals^[HourIndex].Minutes[Band, Both];

      if LogHourTotals^[HourIndex].Minutes[Band, Both] > BiggestBandTotal then
      begin
        BiggestBandTotal := LogHourTotals^[HourIndex].Minutes[Band, Both];
        BiggestBand := Band;
      end;
    end;

    Correction := LogHourTotals^[HourIndex].Minutes[AllBands, Both] - HourTotal;

    if Correction <> 0 then
      LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] :=
        LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] + Correction;

  end;
end;

procedure ContinentReport;
label
  1;
type
  ContListType = (USA, Canada, na, SA, eu, { UA,} af, ASI, Japan, OC, UK);
const
  ContListNames                         : array[ContListType] of string[7] =
    ('    USA', ' Canada', '     NA', '     SA', '   Euro' {, '     UA'}, 'African', '  Asian', '  Japan', '  Ocean', 'Unknown');
const
  MaxUnknownCalls                       = 10;

var
  Band                                  : BandType;
  ID, Call                              : CallString;
  CallAddress, AllBandTotal             : integer;
  ContTotals                            : array[BandType, ContListType] of integer;
  Cont, ListContinent                   : ContListType;
  TempQSOTotals                         : array[BandType] of integer;
  UnknownCalls                          : array[BandType, 0..MaxUnknownCalls - 1] of CallString;
  FileWrite                             : Text;
begin
  MakeReportFileName('Continent List.txt');
  Windows.ZeroMemory(@TempQSOTotals, SizeOf(TempQSOTotals));
  Windows.ZeroMemory(@ContTotals, SizeOf(ContTotals));
  if not OpenFileForWrite(FileWrite, ReportsFilename) then Exit;

  if not OpenLogFile then Exit;

  TotalLogQSOs := 0;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
//    if CorrectContestExchange then
    if GoodLookingQSO then
    begin
      inc(TempQSOTotals[TempRXData.Band]);

      Call := StandardCallFormat(TempRXData.Callsign, True);

      ID := TempRXData.QTH.CountryID;
//      if ID = 'UA' then
//        ListContinent := UA
//      else
      if ID = 'K' then
        ListContinent := USA
      else
        if ID = 'VE' then
          ListContinent := Canada
        else
          if ID = 'JA' then
            ListContinent := Japan
          else
            case TempRXData.QTH.Continent of
              NorthAmerica: ListContinent := na;
              SouthAmerica: ListContinent := SA;
              Europe: ListContinent := eu;
              Africa: ListContinent := af;
              Asia: ListContinent := ASI;
              Oceania: ListContinent := OC;
            else ListContinent := UK;
            end;

      inc(ContTotals[TempRXData.Band, ListContinent]);

      if ListContinent = UK then
        if ContTotals[TempRXData.Band, UK] <= MaxUnknownCalls then
          UnknownCalls[TempRXData.Band, ContTotals[TempRXData.Band, UK] - 1] := Call;

    end;
    goto 1;
  end;
  CloseLogFile;

 
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, ContestTitle);
  //  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, 'Continent List');
  WriteLn(FileWrite);

  //  if not DoingDupingFile then
  begin
    WriteLn(FileWrite,
      '                    160    80    40    20    15    10    30    17    12    ALL'#13#10 +
      '                    ---   ---   ---   ---   ---   ---   ---   ---   ---    ---');
  end;

  for Cont := USA to UK do
  begin
    Write(FileWrite, '  ' + ContListNames[Cont] + ' calls =');

      //    if not DoingDupingFile then
    begin
      AllBandTotal := 0;

      for Band := Band160 to Band10 do
      begin
        Write(FileWrite, ContTotals[Band, Cont]: 6);
        AllBandTotal := ContTotals[Band, Cont] + AllBandTotal;
      end;

      WriteLn(FileWrite, AllBandTotal: 7);
    end;
      //    else
      //      WriteLn(FileWrite, ContTotals[Band160, Cont]: 6);
    if Cont = OC then WriteLn(FileWrite, '');
  end;

  WriteLn(FileWrite, '');

  Write(FileWrite, '    Total calls =');

  //  if not DoingDupingFile then
  begin
    AllBandTotal := 0;
    for Band := Band160 to Band12 do
    begin
      Write(FileWrite, TempQSOTotals[Band]: 6);
      AllBandTotal := TempQSOTotals[Band] + AllBandTotal;
    end;
    WriteLn(FileWrite, AllBandTotal: 7);
  end;
  //  else
  //    WriteLn(FileWrite, TempQSOTotals[Band160]: 6);

  WriteLn(FileWrite);

  for Band := Band160 to Band10 do
    if ContTotals[Band, UK] > 0 then
    begin
        //      TempString := BandString[Band];
        //      GetRidOfPrecedingSpaces(TempString);
        //      if not DoingDupingFile then
      Write(FileWrite, 'Unknowns on ', BandStringsArray[Band], ' = ');
        //      else
        //        Write(FileWrite, 'Unknowns = ');

      for CallAddress := 0 to ContTotals[Band, UK] - 1 do
        if CallAddress < MaxUnknownCalls then
          Write(FileWrite, UnknownCalls[Band, CallAddress], ' ');

      WriteLn(FileWrite);
    end;

  Close(FileWrite);
  FilePreview;
end;

procedure QSOsByCountryByBand;
begin

  //        WriteLnCenter('SHOW TOTAL QSOs BY COUNTRY BY BAND');
  //        WriteLn('This report will show the number of QSOs made in each country by band');

  New(CountryMultTotals);
  //  GenerateCountryMultiplierTotals;
  //  if not CheckLog then exit;
  if GenerateCountryMultiplierTotals then PrintQSOsByCountry;
  Dispose(CountryMultTotals);
  //  windows.FreeResource()

end;

function GenerateCountryMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each country - and record the callsign of the first QSO
  for each country.  The results are saved in the structure
  CountryMultTotals. }
label
  1;
begin
  GenerateCountryMultiplierTotals := False;
  Windows.ZeroMemory(CountryMultTotals, SizeOf(CountryMultiplierArray));
  if not OpenLogFile then Exit;
  ReadVersionBlock;
  TotalLogQSOs := 0;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      inc(TotalLogQSOs);
      if TempRXData.QTH.Country <= MaxCountries - 1 then
        if TempRXData.QTH.Country > 0 then
        begin
          if CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].TotalQSOs = 0 then
            CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].FirstCall := TempRXData.Callsign;

          if TempRXData.QTH.Country <> MAXWORD {>= 0} then
          begin
            inc(CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].TotalQSOs);
          end;
        end;
    end;
    goto 1;
  end;
  CloseLogFile;
  GenerateCountryMultiplierTotals := True;
end;

procedure PrintQSOsByCountry;

var
  Count, CountryIndex                   : integer;
  FileWrite                             : Text;

  tCountryName                          : PChar;
  tCountryID                            : PChar;
  TotalCountryQSOs                      : LONGINT;
  TempBand                              : BandType;
begin

  MakeReportFileName('qsosbycountry.txt');
  OpenFileForWrite(FileWrite, ReportsFilename);

  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, ContestTitle);
  WriteLnVarCenter(FileWrite, 'QSOs MADE IN EACH COUNTRY');
  WriteLn(FileWrite);
  WriteLn(FileWrite);
  WriteLn(FileWrite, '     Country               Prefix   160   80   40   20   15   10  Total  Percent');
  WriteLn(FileWrite, '     -------               ------  ---- ---- ---- ---- ---- ----  -----  -------');

  Count := 0;
  CountryIndex := 0;

//  while ctyGetCountryID(CountryIndex) <> '' do
  while CountryIndex < CTY.ctyNumberCountries do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin
      inc(Count);
      TotalCountryQSOs := 0;
      tCountryName := ctyGetCountryNamePchar(CountryIndex);
      tCountryID := @CTY.ctyTable[CountryIndex].ID[1];
      // Issue #998: asm-push wsprintf -> SysUtils.Format, written straight to the
      // text file. %4u=Count, %-23s=country name, %-5s=country ID.
      Write(FileWrite, SysUtils.Format('%4u %-23s %-5s',
        [Count, string(tCountryName), string(tCountryID)]));

      for TempBand := Band160 to Band10 do
      begin
        if CountryMultTotals^[TempBand, CountryIndex].TotalQSOs > 0 then
          Write(FileWrite, CountryMultTotals^[TempBand, CountryIndex].TotalQSOs: 5)
        else
          Write(FileWrite, '    -');
        TotalCountryQSOs := TotalCountryQSOs + CountryMultTotals^[TempBand, CountryIndex].TotalQSOs;
      end;

      Write(FileWrite, TotalCountryQSOs: 7);
      WriteLn(FileWrite, ((TotalCountryQSOs * 100) / TotalLogQSOs): 8: 2);

    end;
    inc(CountryIndex);
  end;

  //  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;

end;

procedure ExportToEDI;
var
  Band                                  : BandType;
begin
  for Band := Band160 to BandLight do
    ExportToEDIByBand(Band);
end;

procedure ExportToEDIByBand(Band: BandType);
label
  1;
var
  TempTag                               : CabrilloTags;
const
  EDI_ModeCodes                         : array[ModeType] of integer = (2, 7, 1, 0, 0, 6);
  EDI_NewArray                          : array[boolean] of PChar = (nil, 'N');
  EDI_DupeArray                         : array[boolean] of PChar = (nil, 'D');
begin
  if QSOTotals[Band, Both] = 0 then Exit;

  Format(tReportsFilename, '%s%s_%s.EDI', TR4W_LOG_PATH_NAME, @MyCall[1], BandStringsArrayWithOutSpaces[Band]);

  DeleteSlashes(tReportsFilename);
  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

  if not OpenLogFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;

  Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
  for TempTag := ctAddress to ctAddressCountry do
  begin
    if Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer1, SizeOf(TempBuffer1)) = 0 then Continue;
    Windows.lstrcat(wsprintfBuffer, TempBuffer1);
    Windows.lstrcat(wsprintfBuffer, ' ');
  end;

  Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctName) + 200, @TempBuffer1, SizeOf(TempBuffer1));
  Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctCategoryOperator) + 200, @TempBuffer2, SizeOf(TempBuffer2));

  // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
  // ContestName, MyCall, MyGrid, BandString, Name, Address, Section, QSOcount.
  sWriteFileFromString(tReportFileWrite, SysUtils.Format(
    '[REG1TEST;1]'#13#10 +
    'TName=%s'#13#10 +
    'PCall=%s'#13#10 +
    'PWWLo=%s'#13#10 +
    'PBand=%s'#13#10 +
    'RName=%s'#13#10 +
    'PAdr1=%s'#13#10 +
    'PSect=%s'#13#10 +
    '[QSORecords;%u]'#13#10,
    [string(PChar(@ContestName[1])),
     string(PChar(@MyCall[1])),
     string(PChar(@MyGrid[1])),
     string(EDIFBANDSTRINGSARRAY[Band]),
     string(PChar(@TempBuffer1)),
     string(PChar(@wsprintfBuffer)),
     string(PChar(@TempBuffer2)),
     QSOTotals[Band, Both]]));

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      if TempRXData.Band <> Band then goto 1;
      // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
      // date (Year/Month/Day), time (Hour/Minute), callsign, mode code,
      // rst-sent, sent-qso#, rst-rcvd, rcvd-qso#, rcvd-WWL, qso-points,
      // new-WWL, new-DXCC, dupe.  %02d -> %.2d (always non-negative here).
      // The new/dupe flag arrays are nil when false -> string(nil) = '' (EDI
      // blank field).
      //
      // The two QSO-number fields were C '%03d' = zero-pad to WIDTH 3 with the
      // sign counted in the width (-1 -> "-01").  Delphi '%.3d' pads DIGITS
      // (-1 -> "-001"), which differs for negatives (the "no serial" sentinel
      // is -1).  We reproduce C semantics with '%.*d' and precision = 3 minus
      // the sign character, supplied as an argument before each value.
      sWriteFileFromString(tReportFileWrite, SysUtils.Format(
        '%.2d%.2d%.2d;' + {date}
        '%.2d%.2d;' + {time}
        '%s;' + {callsign}
        '%d;' + {mode code}
        '%d;' + {rst sent}
        '%.*d;' + {sent qso number (C %03d)}
        '%d;' + {rst received}
        '%.*d;' + {received qso number (C %03d)}
        ';' + {Received Exchange}
        '%s;' + {Received WWL}
        '%d;' + {QSO points}
        ';' + {New-Exchange}
        '%s;' + {New-WWL}
        '%s;' + {New-DXCC}
        '%s' + {Duplicate-QSO}
        #13#10,
        [TempRXData.tSysTime.qtYear,
         TempRXData.tSysTime.qtMonth,
         TempRXData.tSysTime.qtDay,
         TempRXData.tSysTime.qtHour,
         TempRXData.tSysTime.qtMinute,
         string(PChar(@TempRXData.Callsign[1])),
         EDI_ModeCodes[TempRXData.Mode],
         TempRXData.RSTSent,
         3 - Ord(TempRXData.NumberSent < 0), TempRXData.NumberSent,
         TempRXData.RSTReceived,
         3 - Ord(TempRXData.NumberReceived < 0), TempRXData.NumberReceived,
         string(PChar(@TempRXData.QTHString[1])),
         TempRXData.QSOPoints,
         string(EDI_NewArray[TempRXData.DomesticMult]),
         string(EDI_NewArray[TempRXData.DXMult]),
         string(EDI_DupeArray[TempRXData.ceDupe])]));

    end;
    goto 1;
  end;
  CloseHandle(tReportFileWrite);
  CloseLogFile;

  PreviewFileNameAddress := tReportsFilename;
  FilePreview;
end;

// ---------------------------------------------------------------------------
// Tail emitter callback for uADIF.ExportADIFToString.
// Emits the contest-specific fields that uADIF.EmitADIFRecord skips because
// they need access to MainUnit/trdos globals (MyCall, MyFDClass, MySection,
// MyPark, mo.DomList, ActiveZoneMult, etc.) or are gated on contest-specific
// reinterpretation of QTHString.  Called once per record.
// ---------------------------------------------------------------------------
function EmitContestSpecificTailForExport(const rec: ContestExchange): string;
var
   stxString  : string;
   cntyIdx    : Integer;
   stateCode  : string;
   qthForGrid : ShortString;
   exchForGrid : ShortString;
begin
   Result := '';

   // The legacy MY-exchange builder (GetMyExchangeForExport) and its
   // GoodLookingQSO guard read the global TempRXData, NOT `rec`.  ExportToADIF
   // reads every QSO into the `records` array first, which leaves TempRXData
   // pointing at the LAST record read (typically a deleted QSO at end of log).
   // Without re-syncing it here, GoodLookingQSO saw ceQSO_Deleted = True for
   // every record and STX_STRING came out as "Error generating my exchange"
   // (and serial-based exchanges would reuse the last QSO's serial).  Restore
   // the "TempRXData is the current record" invariant the legacy helpers rely
   // on before invoking them.
   TempRXData := rec;

   // APP_TR4W_CLAIMEDQSO (Issue #750) is emitted by uADIF.EmitADIFRecord
   // -- it's a ContestExchange-sourced field, not contest-specific, and
   // round-trip tests rely on it being present without a tail emitter.

   // ----- STX_STRING (always, from MY side) -----
   stxString := GetMyExchangeForExport;
   Result := Result + EmitADIFField('STX_STRING',
                                    Trim(DeleteRepeatedSpaces(stxString)));

   // ----- SRX_STRING (Issue #898) -----
   // uADIF.EmitADIFRecord deliberately does NOT emit SRX_STRING because
   // its shape is contest-specific:
   //   POTA          -> park-ref shape (handled below in the POTA branch)
   //   RST-implied   -> "RST + ExchString"  (ResolveSRXString normalizes)
   //   no RST        -> ExchString as-is    (FD, SS, Winter FD, etc.)
   // The "is RST part of this contest's exchange?" knowledge lives in
   // ExchangeInformation.RST (trdos/LOGDUPE.PAS), which uADIF cannot
   // see without taking a trdos dependency.  POTA's own SRX_STRING is
   // emitted further down -- this branch handles every other contest.
   if rec.ceContest <> POTA then
      begin
      if ExchangeInformation.RST then
         Result := Result + EmitADIFField('SRX_STRING',
                                          ResolveSRXString(rec))
      else
         Result := Result + EmitADIFField('SRX_STRING',
                                          string(rec.ExchString));
      end;

   // ----- POTA-specific (uADIF skips SRX_STRING for POTA) -----
   if rec.ceContest = POTA then
      begin
      Result := Result + EmitADIFField('MY_SIG', 'POTA');
      Result := Result + EmitADIFField('MY_SIG_INFO', string(MyPark));
      Result := Result + EmitADIFField('MY_POTA_REF', string(MyPark));
      if LooksLikeAPOTAPark(string(rec.QTHString)) then
         Result := Result + EmitADIFField('SRX_STRING', string(rec.QTHString))
      else
         begin
         Result := Result + EmitADIFField('SRX_STRING', string(rec.ExchString));
         if LooksLikeAState(string(rec.ExchString)) then
            Result := Result + EmitADIFField('STATE', string(rec.ExchString))
         else
            begin
            exchForGrid := rec.ExchString;
            if LooksLikeAGrid(exchForGrid) then
               Result := Result + EmitADIFField('GRIDSQUARE',
                                                string(rec.ExchString));
            end;
         end;
      end;

   // ----- CNTY (state QP with FAltName loaded from <state>_cty.dom) -----
   stateCode := GetStateForContest(rec.ceContest);
   if (stateCode <> '') and (rec.QTHString <> '') and
      (Length(rec.QTHString) <> 2) then
      begin
      if mo.DomList.FindMult(rec.QTHString, cntyIdx) and
         (mo.DomList.FList[cntyIdx].FAltName <> '') then
         Result := Result + EmitADIFField('CNTY',
                              stateCode + ',' +
                              mo.DomList.FList[cntyIdx].FAltName);
      end;

   // ----- Contest-specific primary-location field -----
   //
   // uADIF.EmitADIFRecord already emitted <QTH> when QTHString is non-empty.
   // Most contests have a more specific tag (GRIDSQUARE / IOTA / ARRL_SECT /
   // DOK / APP_TR4W_HQ / POTA_REF) -- emit it here too so the file matches
   // the original ExportToADIF output.  A few contests deliberately suppress
   // any location field (CQ160, NA-SPRINT, NAQSO).
   if rec.QTHString <> '' then
      begin
      qthForGrid := rec.DomesticQTH;
      if LooksLikeAGrid(qthForGrid) and (ActiveDomesticMult <> RDADistrict) then
         Result := Result + EmitADIFField('GRIDSQUARE',
                                          string(rec.DomesticQTH))
      else
         case rec.ceContest of
            WAG:
               Result := Result + EmitADIFField('DOK',
                                                string(rec.QTHString));
            ARRL160:
               if (rec.QTH.CountryID = 'K') or (rec.QTH.CountryID = 'VE') then
                  Result := Result + EmitADIFField('ARRL_SECT',
                                                   string(rec.QTHString));
            ARRLFIELDDAY, WINTERFIELDDAY:
               begin
               if rec.QTHString <> 'DX' then
                  begin
                  Result := Result + EmitADIFField('ARRL_SECT',
                                                   string(rec.QTHString));
                  Result := Result + EmitADIFField('CLASS',
                                                   string(rec.ceClass));
                  end;
               // Legacy behaviour: emit an additional STX_STRING with
               // MyFDClass + MySection.  The record then has two
               // STX_STRING tags; the second one wins on parse.
               Result := Result + EmitADIFField('STX_STRING',
                                                string(MyFDClass) + ' ' +
                                                string(MySection));
               end;
            ARRLSSCW, ARRLSSSSB:
               if rec.QTHString <> 'DX' then
                  Result := Result + EmitADIFField('ARRL_SECT',
                                                   string(rec.QTHString));
            CQ160CW, CQ160SSB, NASPRINTCW, SPRINTSSB, NASPRINTRTTY,
            NAQSOCW, NAQSOSSB, NAQSORTTY:
               ;  // legacy: no extra location field
            POTA:
               if LooksLikeAPOTAPark(string(rec.QTHString)) then
                  begin
                  Result := Result + EmitADIFField('SIG', 'POTA');
                  Result := Result + EmitADIFField('SIG_INFO',
                                                   string(rec.QTHString));
                  Result := Result + EmitADIFField('POTA_REF',
                                                   string(rec.QTHString));
                  end;
            IOTA:
               Result := Result + EmitADIFField('IOTA',
                                                string(rec.DomesticQTH));
            IARU:
               Result := Result + EmitADIFField('APP_TR4W_HQ',
                                                string(rec.QTHString));
            ARRLDIGI, WWDIGI, BATAVIA_FT8:
               Result := Result + EmitADIFField('GRIDSQUARE',
                                                string(rec.QTHString));
         else
            // Default: uADIF already emitted <QTH:...>.  Nothing more.
            ;
         end;
      end;

   // ----- CQZ / ITUZ (zone) -----
   if rec.Zone <> DUMMYZONE then
      begin
      if ActiveZoneMult = CQZones then
         Result := Result + EmitADIFField('CQZ',
                                          SysUtils.Format('%.2d', [rec.Zone]))
      else if ActiveZoneMult = ITUZones then
         Result := Result + EmitADIFField('ITUZ',
                                          SysUtils.Format('%.2d', [rec.Zone]))
      else if (ActiveZoneMult = NoZoneMults) and ExchangeInformation.Zone then
         begin
         if CTY.ctyZoneMode = CQZoneMode then
            Result := Result + EmitADIFField('CQZ',
                                  SysUtils.Format('%.2d', [rec.Zone]))
         else
            Result := Result + EmitADIFField('ITUZ',
                                  SysUtils.Format('%.2d', [rec.Zone]));
         end;
      end;

   // ----- STATION_CALLSIGN (when operator differs from MyCall) -----
   if (rec.ceOperator <> '') and
      (string(rec.ceOperator) <> string(MyCall)) then
      Result := Result + EmitADIFField('STATION_CALLSIGN', string(MyCall));
end;

procedure ExportToADIF;
var
   records      : TContestExchangeArray;
   dtReportTime : TDateTime;
   adifStr      : string;
begin
   dtReportTime := Now;
   lstrcpy(tReportsFilename, TR4W_LOG_FILENAME);
   tReportsFilename[Windows.lstrlen(tReportsFilename) - 3] := #0;
   lstrcat(tReportsFilename, 'ADI');
   if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

   if not OpenLogFile then
      begin
      CloseHandle(tReportFileWrite);
      Exit;
      end;

   // Banner lines (pre-header, kept for compatibility with older ADIF
   // consumers that expect the "Created by TR4W..." comment).
   sWriteFileFromString(tReportFileWrite, 'ADIF File'#13#10);
   sWriteFileFromString(tReportFileWrite,
      'Created by TR4W version ' + TR4W_CURRENTVERSION +
      ' on ' + FormatDateTime('mmm-dd-yyyy hh:mm:ss', dtReportTime) +
      #13#10);

   // Read all "good" QSOs from the log into an in-memory array.
   SetLength(records, 0);
   ReadVersionBlock;
   while ReadLogFile do
      begin
      if GoodLookingQSO then
         begin
         SetLength(records, Length(records) + 1);
         records[High(records)] := TempRXData;
         end;
      end;

   // Build the whole ADIF document (header + records + tail extras) and
   // write it as one block.  The per-record body lives in
   // uADIF.EmitADIFRecord; the contest-specific extras come from the
   // EmitContestSpecificTailForExport callback above.
   adifStr := uADIF.ExportADIFToString(records,
                                       string(TR4W_CURRENTVERSION),
                                       @EmitContestSpecificTailForExport);
   sWriteFileFromString(tReportFileWrite, adifStr);

   CloseHandle(tReportFileWrite);
   CloseLogFile;
   PreviewFileNameAddress := tReportsFilename;
   FilePreview;
end;



procedure ExportToCSV;              //n4af 04/18/14 new procedure added
label
  1;

begin

  lstrcpy(tReportsFilename, TR4W_LOG_FILENAME);
  tReportsFilename[Windows.lstrlen(tReportsFilename) - 3] := #0;
  lstrcat(tReportsFilename, 'CSV');
  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

  if not OpenLogFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;


  //nNumberOfBytesToWrite := Format(wsprintfBuffer, TR4W_CURRENTVERSION + #13#10#13#10#13#10, @ContestTitle[1]);
  //NumberOfBytesToWrite := Format(wsprintfBuffer, TR4W_CURRENTVERSION + #13#10#13#10#13#10, @ContestTitle[1]);

  //sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);

  ReadVersionBlock;
  1:

  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      // Issue #998: asm-push wsprintf -> SysUtils.Format, written INSIDE the
      // GoodLookingQSO guard.  The old write sat outside the guard and re-emitted
      // the stale buffer for skipped/deleted/non-QSO records; now only good QSOs
      // are written.  cdecl arg order: callsign, band, mode, year, month, day,
      // hour, minute, second, rst-sent, rst-rcvd, contest name.  %02d -> %.2d.
      sWriteFileFromString(tReportFileWrite, SysUtils.Format(
        '%s,%s,%s,%u%.2d%.2d,%.2d%.2d%.2d,%u,%u,%s'#13#10,
        [string(PChar(@TempRXData.Callsign[1])),
         string(ADIFBANDSTRINGSARRAY[TempRXData.Band]),
         string(ADIFModeString[TempRXData.Mode]),
         TempRXData.tSysTime.qtYear + 2000,
         TempRXData.tSysTime.qtMonth,
         TempRXData.tSysTime.qtDay,
         TempRXData.tSysTime.qtHour,
         TempRXData.tSysTime.qtMinute,
         TempRXData.tSysTime.qtSecond,
         TempRXData.RSTSent,
         TempRXData.RSTReceived,
         string(ContestTypeSA[Contest])]));
      end;
    goto 1;
   end;
  
  CloseHandle(tReportFileWrite);
  CloseLogFile;
  PreviewFileNameAddress := tReportsFilename;
  FilePreview;
end;


procedure ExportToTRLogFormat;
label
  1;

begin

end;

function tGenerateSummaryPortionOfCabrilloFile: boolean;
var
  T2                                    : PChar;
  T3                                    : String;
  TempTag                               : CabrilloTags;
  TempPchar                             : PChar;
  Operator                              : integer;
  ControlID                             : integer;
  TempErmakField                        : TErmakFields;
  TempInteger                           : integer;
const
  op                                    = 'OPERATORS: ';
begin
  Result := False;

  if (Contest = ARRL10) or (Contest = WINTERFIELDDAY) then
    if Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctLocation) + 200, @TempBuffer2, SizeOf(TempBuffer2)) = 0 then
    begin
      showwarning('LOCATION field is empty.');
      Exit;
    end;

  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;
  T2 := @MyCall[1];
  if length(ContestsArray[Contest].CABName) = 0 then
         begin
         T3 := ContestTypeSA[Contest]
         end
      else
         begin
         T3 := ContestsArray[Contest].CABName;     // NY4I
         end;

  //T3 := ContestTypeSA[contest];        // 4.78.2
   if Contest = GENERALQSO then       // 4.78.3        // ALLOW CUSTOM CONFIG Contest Title or Contest Name
      if length(ContestTitle) <> 0  then
         T3 := ContestTitle
      else if length(ContestName) <> 0  then      // 4.78.3
         T3 := ContestName;

  // Issue #998: asm-push wsprintf -> SysUtils.Format + sWriteFileFromString.
  // %s=CALLSIGN(T2), %s=CONTEST(T3), %d=CLAIMED-SCORE(TotalScore).
  sWriteFileFromString(tReportFileWrite, SysUtils.Format(
    'START-OF-LOG: 3.0'#13#10'CREATED-BY: ' + TR4W_CURRENTVERSION + #13#10'CALLSIGN: %s'#13#10'CONTEST: %s'#13#10'CLAIMED-SCORE: %d'#13#10,
    [string(T2), T3, TotalScore]));

  for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
  begin
    if ErmakSpecification then if TempTag = ctOperators then Continue;

    Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer2, SizeOf(TempBuffer2));
    //if TempBuffer2[0] = #0 then Continue;
    if TempTag = ctOperators then
       begin
       ;
       end
    else if TempBuffer2[0] =#0 then
      begin
      Continue;
      end;

    if Contest = WINTERFIELDDAY then
       begin
       if TempTag = ctLocation then
          begin
          sWriteFileFromString(tReportFileWrite,'ARRL-SECTION: ' + TempBuffer2 + #13#10);
          sWriteFileFromString(tReportFileWrite,'X-EXCHANGE: ' + MyFDClass + #13#10);
          end;
       end;
    TempPchar := @CabrilloTagsArray[TempTag].ctrTag[1];
    if TempTag = ctOperators then
       begin
       StrPCopy(TempBuffer2, GetOperatorsFromLog);   // Issue #998 (was custom Format '%s')
       end;
    // Issue #998: %s=tag(TempPchar), %s=value(TempBuffer2).
    sWriteFileFromString(tReportFileWrite, SysUtils.Format('%s: %s'#13#10,
      [string(TempPchar), string(PChar(@TempBuffer2))]));
  end;

  if MyGrid <> '' then
     begin
     sWriteFileFromString(tReportFileWrite,'GRID-LOCATOR: ' + MyGrid + #13#10);
     end;

  if ErmakSpecification then
    for Operator := 1 to 10 do
      for TempErmakField := Low(TErmakFields) to High(TErmakFields) do
      begin
        ControlID := integer(TempErmakField) + (Operator) * 100;
        // Issue #998: builds the INI key into TempBuffer2 (not file output).
        // OPERATORINFO is C '_OP_INFO_%03u' (zero-pad); Delphi Format uses '%.3u'.
        StrPCopy(TempBuffer2, SysUtils.Format('_OP_INFO_%.3u', [ControlID]));
        TempInteger := GetPrivateProfileString(ERMAKSECTION, TempBuffer2, '?', TempBuffer1, SizeOf(TempBuffer1), TR4W_INI_FILENAME);
        TempPchar := @TempBuffer1[0];
        if TempErmakField = efOp then
        begin
          if TempBuffer1[0] <> '1' then Break;
          sWriteFile(tReportFileWrite, op, length(op));
          Continue;
        end;

        if TempErmakField = efLevel then
          if TempBuffer1[0] in ['0'..'7'] then
          begin
            TempPchar := ZVANIYA[Ord(TempBuffer1[0]) - Ord('0')];
            TempInteger := Windows.lstrlen(TempPchar);
          end;

        if TempErmakField = efTrainer then
        begin
          if TempBuffer1[0] = '1' then
          begin
            TempPchar := '??????';
            TempInteger := 6;
          end
          else
          begin
            TempPchar := nil;
            TempInteger := 0;
          end;

        end;

        sWriteFile(tReportFileWrite, TempPchar^, TempInteger);
        if TempErmakField <> High(TErmakFields) then
          sWriteFile(tReportFileWrite, ', ', 2)
        else
          sWriteFile(tReportFileWrite, #13#10, 2);
      end;

  Result := True;
end;

// Issue #998 capstone: the per-exchange SetMyEx/SetHisEx + the whole
// `case ActiveExchange of` were extracted into uCabrilloExchange.pas
// (FormatCabrilloExchange) so the exchange formatting is unit-testable.

function tGenerateLogPortionOfCabrilloFile: boolean;
label
  1;
var
  HisCallsign                           : PChar;
  RSTSent                               : PChar;
  RSTReceived                           : PChar;
  Freq                                  : PChar;
  ModeString                            : PChar;
  csQTHString                           : PChar;
  nrReceived                            : integer;
  nrSent                                : integer;
  tempcategoryoperator                  : tcategoryoperator;

  T4                                    : PChar;      // 4.73.6
  sFirstPart                            : string;     // Issue #998: replaces CABRILLO_FIRST_PART
  sPrefix                               : string;     // Issue #998: QSO:/X-QSO: line prefix
  sFmt                                  : string;     // Issue #998: assembly format string
  sCall1                                : string;     // Issue #998: QTC from-call (QTCR/QTCS swap)
  sCall2                                : string;     // Issue #998: QTC to-call (QTCR/QTCS swap)
  myStationEx                           : TMyStationExchange;  // #998 capstone: My-station fields for FormatCabrilloExchange
  cRandomCharsReceived                  : PChar;
  cKids                                 : PChar;
  previousqsonr                         : integer;
  TransmitterIDPos                      : integer;
  contacts                              : integer;
  PreviousQTHString                     : Str10;
  pnr                                   : integer;
  slOperators                           : TStringList;


begin
  TransmitterIDPos := 83;
  pnr := 0;
  if (Contest = NAQSOCW) or (Contest = NAQSOSSB) or (Contest = NAQSORTTY) then TransmitterIDPos := 92;        // 4.67.7
  //if Contest =  NAQPCW  then TransmitterIDPos := 92;
  contacts := 0;
  Result := False;

  logger.Info('In tGenerateLogPortionOfCabrilloFile');

  if not OpenLogFile then Exit;

  ReadVersionBlock;

   try
      try
      slOperators := TStringList.Create;
      slOperators.Duplicates := dupIgnore;
      // Issue #998 capstone: the My-station / his-zone / his-name locals that fed
      // the exchange `case` were removed here -- FormatCabrilloExchange now derives
      // them from the rx/my it is passed (PostUnit builds myStationEx at the call).

  previousqsonr := 0;
  1:
  if ReadLogFile then
  begin
    inc(contacts);
    //slOperators.Add(TempRXData.ceOperator);


    HisCallsign := @TempRXData.Callsign[1];

    if TempRXData.RSTSent < 25 then
       begin
       if WSJTXEnabled then
          begin
          RSTSent := PChar(SysUtils.Format('%d', [wsjtx.ConvertSNRToRST(TempRXData.RSTSent)]));
          end
       else
          begin
          RSTSent := PChar(SysUtils.Format('%d',[599]));
          logger.info('RSTSent was less than 25 but WSJTXEnabled is FALSE');
          end;
       end
    else
       begin
       RSTSent := PChar(SysUtils.Format('%d', [TempRXData.RSTSent]));
       end;

    if (TempRXData.ExtMode in [eFT8, eMFSK, eJT65]) and
       (TempRXData.RSTReceived < 25)                then
       begin
       if WSJTXEnabled then
          begin
          RSTReceived := PChar(SysUtils.Format('%d', [wsjtx.ConvertSNRToRST(TempRXData.RSTReceived)]));
          end
       else
          begin
          RSTReceived := '599';
          end;
       end
    else
       begin
       RSTReceived := PChar(SysUtils.Format('%d', [TempRXData.RSTReceived]));
       end;
    
    nrReceived := TempRXData.NumberReceived;
    nrSent := TempRXData.NumberSent;
    if tShowFrequencyInLog then
       begin
       if (TempRXData.Frequency = 0) then                                // Get base frequency from band
          begin
          Freq := tCabrilloFreqString[TempRXData.Band];                     // https://wwrof.org/cabrillo/cabrillo-qso-data/
          end
       else
          begin
          if (TempRXData.Frequency > 0) and (TempRXData.Frequency < 30000000) then
             begin
             Freq := inttopchar(TempRXData.Frequency div 1000);
             end
          else
             begin                                                             // Per the Cabrillo spec, if above 30 Mhz, do not use actual frequency
             Freq := tCabrilloFreqString[TempRXData.Band];                     // https://wwrof.org/cabrillo/cabrillo-qso-data/
             end;
          end;
       end
    else
       begin
       Freq := tCabrilloFreqString[TempRXData.Band];
       end; 


    // This was just assuming any digital contact was RY which is obviously not true.
    if TempRXData.Mode = Digital then
       begin
       case TempRXData.ExtMode of
          eNoMode, eRTTY:
             begin
             ModeString := 'RY';
             end;
          else
             begin
             ModeString := 'DG';
             end;
          end; // case
       end
    else if TempRXData.Mode = FM then
       begin
       if Contest = WINTERFIELDDAY then
          begin
          ModeString := 'PH';
          end
       else
          begin
          ModeString := tCabrilloModeString[TempRXData.Mode];
          end;
       end
    else
       begin
       ModeString := tCabrilloModeString[TempRXData.Mode];
       end;

    if DoingDomesticMults then
    begin
      if LiteralDomesticQTH then
        csQTHString := @TempRXData.QTHString[1]
       else
       if ContestName = 'WWDIGI' then
        csQTHString := @TempRXData.QTHString[1]
      else
       if contestname  = 'LABRE' then
        csQTHString := @temprxdata.qthstring[1]
      else
        csQTHString := @TempRXData.DomesticQTH[1] {DomMultQTH};
    end
    else
      csQTHString := @TempRXData.QTHString[1];

    if Contest in [CUPRFCW, CUPRFSSB] then
      csQTHString := @TempRXData.QTHString[1];

   if ContestNAME = 'EURASIA' then
      csQTHString := @(TempRXData.QTHString[1]);


 if Contest in [CALQSOPARTY]  then
  begin


     csQTHString := @TempRXData.QTHString[1] ;
   // else
   //    csQTHString := @TempRXData.DomMultQTH[1];
if TempRXData.DomMultQTH = '' then
  begin
  TempRXData.DomMultQTH := 'DX';
  csQTHString := 'DX';
  end;
  end;

    if GoodLookingQSO then
    begin

          {Make First part}
      // Issue #998: asm-push wsprintf -> SysUtils.Format; the CABRILLO_FIRST_PART
      // PChar buffer is replaced by the local sFirstPart string.  cdecl arg
      // order: freq, mode, year, month, day, hour, minute, mycall.  %02d -> %.2d
      // (date/time fields are always non-negative).
      // Issue #750: X-QSO records use the 'X-QSO:' prefix instead of 'QSO:';
      // only the literal prefix differs (the 2-char-wider prefix shifts later
      // columns by 2 -- Cabrillo parsers tolerate X-QSO column alignment).
      if TempRXData.ceXQSO then
         sPrefix := 'X-QSO: '
      else
         sPrefix := 'QSO: ';
      sFirstPart := SysUtils.Format(sPrefix + '%5s %s %d-%.2d-%.2d %.2d%.2d %-7s ',
        [string(Freq),
         string(ModeString),
         TempRXData.tSysTime.qtYear + 2000,
         TempRXData.tSysTime.qtMonth,
         TempRXData.tSysTime.qtDay,
         TempRXData.tSysTime.qtHour,
         TempRXData.tSysTime.qtMinute,
         string(PChar(@MyCall[1]))]);
{
      ActiveExchange := RSTQSONumberExchange;
      nrReceived := StrToInt(TempRXData.ceClass);
      Windows.ZeroMemory(@CABRILLO_RST_RCVD, SizeOf(CABRILLO_RST_RCVD));
      Windows.lstrcat(CABRILLO_RST_RCVD, '599');
}
          {Make Exchanges Strings}
      // Issue #998 capstone: the per-exchange MYEX/HISEX builder was extracted
      // into uCabrilloExchange.FormatCabrilloExchange (dependency-light + unit-
      // tested).  Build the My-station record and pass the per-QSO derived
      // strings; it fills CABRILLO_MYEX / CABRILLO_HISEX (and carries pnr).
      myStationEx.MyState      := string(MyState);
      myStationEx.MyGrid       := string(MyGrid);
      myStationEx.MyName       := string(MyName);
      myStationEx.MyZone       := string(MyZone);
      myStationEx.MyFDClass    := string(MyFDClass);
      myStationEx.MySection    := string(MySection);
      myStationEx.MyCheck      := string(MyCheck);
      myStationEx.MyPrec       := string(MyPrec);
      myStationEx.MyFOCNumber  := string(MyFOCNumber);
      myStationEx.MyPostalCode := string(MyPostalCode);
      FormatCabrilloExchange(ActiveExchange, Contest, ContestTitle, ContestName,
        TempRXData, myStationEx,
        string(RSTSent), string(RSTReceived), string(csQTHString),
        string(PChar(@PreviousQTHString[1])),
        contacts, pnr, CABRILLO_MYEX, CABRILLO_HISEX);
//----------------------------

      // Issue #998: StrUpper (ASCII a-z only) on the old PChar buffer -> UpperCase
      // on the string (also ASCII a-z; Cabrillo exchanges are ASCII so identical).
      CABRILLO_HISEX := UpperCase(CABRILLO_HISEX);

  if CategoryOperator = coMULTIOP then
      if temprxdata.cecomputerid = ComputerID then        // 4.73.6

      T4 := '1'
       else
        T4 := '0';
 if CategoryOperator <> coMULTIOP then
 T4 := '';
      // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
      // first-part, my-exchange, his-callsign, his-exchange, multi-op flag.
      // ARKTIKA_SPRING uses a narrower layout that consumes only the first 4
      // args (the multi-op flag is omitted); Delphi Format ignores the extra
      // trailing argument, so a single arg list serves both formats.
      if Contest = ARKTIKA_SPRING then
         sFmt := '%s%-12s%-10s%-10s'#13#10           // 4.100.3
      else
         sFmt := '%s%s%-15s%-10s %-5s'#13#10;        // 4.100.3
      sWriteFileFromString(tReportFileWrite, SysUtils.Format(sFmt,
        [sFirstPart,
         CABRILLO_MYEX,
         string(HisCallsign),
         CABRILLO_HISEX,
         string(T4)]));

      previousqsonr := nrReceived mod 1000;
    end;


    Windows.ZeroMemory(@PreviousQTHString, SizeOf(PreviousQTHString));
    PreviousQTHString := TempRXData.QTHString;

    if TempRXData.ceRecordKind in [rkQTCR, rkQTCS] then
    begin

      cKids := @TempRXData.Kids[1];
      cRandomCharsReceived := @TempRXData.RandomCharsReceived[1];
      // Issue #998: asm-push wsprintf -> SysUtils.Format + sWriteFileFromString
      // (last asm block in this unit).  QTC: freq mode date time <call1>
      // <randomchars> <call2> <sentNr> <kids> <rcvdNr>.  For rkQTCR the
      // from/to calls are MyCall/HisCallsign; for rkQTCS they swap.
      // %02d -> %.2d (date/time), %04u -> %.4u (sent number).
      if TempRXData.ceRecordKind = rkQTCR then
         begin
         sCall1 := string(PChar(@MyCall[1]));
         sCall2 := string(HisCallsign);
         end
      else
         begin
         sCall1 := string(HisCallsign);
         sCall2 := string(PChar(@MyCall[1]));
         end;
      sWriteFileFromString(tReportFileWrite, SysUtils.Format(
        'QTC: %5s %s %d-%.2d-%.2d %.2d%.2d %-14s%-11s%-14s%.4u %-14s%u'#13#10,
        [string(Freq),
         string(ModeString),
         TempRXData.tSysTime.qtYear + 2000,
         TempRXData.tSysTime.qtMonth,
         TempRXData.tSysTime.qtDay,
         TempRXData.tSysTime.qtHour,
         TempRXData.tSysTime.qtMinute,
         sCall1,
         string(cRandomCharsReceived),
         sCall2,
         nrSent,
         string(cKids),
         nrReceived]));
    end;
    goto 1;
  end;
  sWriteFile(tReportFileWrite, 'END-OF-LOG: ', 12);

  CloseLogFile;
  Result := True;
   except
      on E: Exception do
         DebugMsg(E.ClassName + ' error raised with message ' + E.Message);
   end;
   finally
      FreeANdNil(slOperators);
   end;
end;

procedure SetTransmittersIdentifiers;
begin
  Radio1IDs := QuickEditResponse('transmiter 1 computers IDs', 10);
{
  TempString := QuickEditResponse('transmiter 1 ID', 1);
  if TempString <> '' then Radio1ID := TempString[1];
  if not (Radio1ID in ['A'..'Z']) then Radio1ID := #0;
}
//  TempString := QuickEditResponse('radio 2 ID', 1);
//  if TempString <> '' then Radio2ID := TempString[1];
end;

procedure tFirstCallInEachCountry;
begin
  New(CountryMultTotals);
  if GenerateCountryMultiplierTotals then PrintFirstCountryMultiplierCallsigns;
  Dispose(CountryMultTotals);
end;

procedure PrintFirstCountryMultiplierCallsigns;

var
  Lines, CountryIndex                   : integer;
  Prefix                                : string;
  FileWrite                             : Text;
begin

  MakeReportFileName('firstcallineachcountry.txt');
  OpenFileForWrite(FileWrite, ReportsFilename);

  Lines := 0;

  CountryIndex := 0;

  while CountryIndex < CTY.ctyNumberCountries do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin

      if ((Lines >= 55) or (Lines = 0)) then
      begin
        Write(FileWrite, ' ');

        WriteLnVarCenter(FileWrite, 'COUNTRIES WORKED - WITH CALL OF FIRST STATION WORKED');
        WriteLn(FileWrite);
        WriteLnVarCenter(FileWrite, ContestTitle);
        WriteLn(FileWrite);
        WriteLn(FileWrite, 'Prefix   160         80          40          20          15          10');
        WriteLn(FileWrite, '------ --------    --------    --------    --------    --------    --------');
        Lines := 5;
      end;

      Prefix := CTY.ctyTable[CountryIndex].ID;
      // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
      // %-6s=Prefix, then the FirstCall for bands 160/80/40/20/15/10.
      WriteLn(FileWrite, SysUtils.Format('%-6s %-11s %-11s %-11s %-11s %-11s %-11s',
        [Prefix,
         string(PChar(@CountryMultTotals^[Band160, CountryIndex].FirstCall[1])),
         string(PChar(@CountryMultTotals^[Band80,  CountryIndex].FirstCall[1])),
         string(PChar(@CountryMultTotals^[Band40,  CountryIndex].FirstCall[1])),
         string(PChar(@CountryMultTotals^[Band20,  CountryIndex].FirstCall[1])),
         string(PChar(@CountryMultTotals^[Band15,  CountryIndex].FirstCall[1])),
         string(PChar(@CountryMultTotals^[Band10,  CountryIndex].FirstCall[1]))]));
      inc(Lines);
    end;

    inc(CountryIndex);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;

end;

procedure tFirstCallInEachZone;
begin
  New(CountryMultTotals);
  MakeReportFileName('FirstCallInEachZone.txt');
  if GenerateZoneMultiplierTotals then
    PrintFirstZoneMultiplierCallsigns;

  Dispose(CountryMultTotals);

end;

function GenerateZoneMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each zone - and record the callsign of the first QSO
  for each zone.  The results are saved in the structure
  CountryMultTotals. }

label
  1;
begin
  GenerateZoneMultiplierTotals := False;
  Windows.ZeroMemory(CountryMultTotals, SizeOf(CountryMultiplierArray));
  if not OpenLogFile then Exit;
  //   TotalLogQSOs := 0;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
          //               inc(TotalLogQSOs);
      if (TempRXData.Zone > 0) and (TempRXData.Zone <= 100) then
      begin
        if TempRXData.ZoneMult then
          if CountryMultTotals^[TempRXData.Band, TempRXData.Zone].TotalQSOs = 0 then
            CountryMultTotals^[TempRXData.Band, TempRXData.Zone].FirstCall := TempRXData.Callsign;

              //                     if TempRXData.QTH.Country >= 0 then
        inc(CountryMultTotals^[TempRXData.Band, TempRXData.Zone].TotalQSOs);
      end;
    end;
    goto 1;
  end;
  CloseLogFile;
  GenerateZoneMultiplierTotals := True;
end;

procedure PrintFirstZoneMultiplierCallsigns;

var
  Lines, MaxNumberOfZones, ZoneIndex    : integer;
  TempString                            : Str80;
  FileWrite                             : Text;
  Band                                  : BandType;
begin

  OpenFileForWrite(FileWrite, ReportsFilename);

  Lines := 0;
  {
     WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
     WriteLn(FileWrite);
     WriteLnVarCenter(FileWrite, ContestTitle);
     WriteLn(FileWrite);
     WriteLn(FileWrite, 'Zone   160        80          40          20          15          10');
     WriteLn(FileWrite, '---- --------   --------    --------    --------    --------    --------');

  Lines := 5;
  }
  MaxNumberOfZones := 40;

  for Band := Band160 to Band10 do
    for ZoneIndex := 41 to 100 do
      if CountryMultTotals^[Band, ZoneIndex].TotalQSOs > 0 then
        MaxNumberOfZones := ZoneIndex;

  if (MaxNumberOfZones > 40) then
    if MaxNumberOfZones <= 75 then
      MaxNumberOfZones := 75
    else
      MaxNumberOfZones := 100;

  for ZoneIndex := 1 to MaxNumberOfZones do
  begin
    if ((Lines >= 55) or (Lines = 0)) then
    begin
      Write(FileWrite, ' ');

      WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
      WriteLn(FileWrite);
      WriteLnVarCenter(FileWrite, ContestTitle);
      WriteLn(FileWrite);
      WriteLn(FileWrite, 'Zone   160         80          40          20          15          10');
      WriteLn(FileWrite, '---- --------    --------    --------    --------    --------    --------');
      Lines := 5;
    end;
    // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
    // %-4u=ZoneIndex, then the FirstCall for bands 160/80/40/20/15/10.
    TempString := SysUtils.Format('%-4u %-11s %-11s %-11s %-11s %-11s %-11s',
      [ZoneIndex,
       string(PChar(@CountryMultTotals^[Band160, ZoneIndex].FirstCall[1])),
       string(PChar(@CountryMultTotals^[Band80,  ZoneIndex].FirstCall[1])),
       string(PChar(@CountryMultTotals^[Band40,  ZoneIndex].FirstCall[1])),
       string(PChar(@CountryMultTotals^[Band20,  ZoneIndex].FirstCall[1])),
       string(PChar(@CountryMultTotals^[Band15,  ZoneIndex].FirstCall[1])),
       string(PChar(@CountryMultTotals^[Band10,  ZoneIndex].FirstCall[1]))]);
      {
               Str(ZoneIndex: 3, TempString);

               TempString := TempString + '  ';

               if CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band160, ZoneIndex].FirstCall;

               while length(TempString) < 16 do TempString := TempString + ' ';

               if CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band80, ZoneIndex].FirstCall;

               while length(TempString) < 28 do TempString := TempString + ' ';

               if CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band40, ZoneIndex].FirstCall;

               while length(TempString) < 40 do TempString := TempString + ' ';

               if CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band20, ZoneIndex].FirstCall;

               while length(TempString) < 52 do TempString := TempString + ' ';

               if CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band15, ZoneIndex].FirstCall;

               while length(TempString) < 64 do TempString := TempString + ' ';

               if CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band10, ZoneIndex].FirstCall;
      }
    WriteLn(FileWrite, TempString);
    inc(Lines);
  end;

  //   Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;
end;

procedure ZoneReport;
label
  1;
var
  FileWrite                             : Text;
  Location                              : QTHRecord;
  QSONumber, NumberBadZones             : integer;
begin
  {
    WriteLn('This procedure will list any contacts where the received zone differs from');
    WriteLn('the default zone for the indicated callsign.  You should be aware that some');
    WriteLn('of the more active stations have "special" default zones.  For example, the');
    WriteLn('program knows that N4AR is in zone 4, not zone 5.');
    WriteLn;
  }

  NumberBadZones := 0;
  MakeReportFileName('PossibleBadZone.txt');
  if not OpenLogFile then Exit;

  if not OpenFileForWrite(FileWrite, ReportsFilename) then
  begin
    CloseLogFile;
    Exit;
  end;

  QSONumber := 0;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if GoodLookingQSO then

    begin
      inc(QSONumber);
      ctyLocateCall(TempRXData.Callsign, Location);
      if TempRXData.Zone <> Location.Zone then
      begin
        WriteLn(FileWrite, TempRXData.Callsign: 10);
        inc(NumberBadZones);
      end;

    end;

    goto 1;
  end;
  CloseLogFile;
  WriteLn(FileWrite, 'There were ', NumberBadZones, ' questionable zones found.');
  WriteLn(FileWrite);
  Close(FileWrite);
  FilePreview;
end;
{
function CorrectContestExchange: boolean;
begin

  RESULT := False;

  if (
    (TempRXData.ceQSO_Skiped = False) and
    (TempRXData.Band <> NoBand) and
    (TempRXData.Mode <> NoMode) and
    (TempRXData.ceQSO_Dupe = False) and
    (TempRXData.ceQSO_Deleted = False)
    ) then RESULT := True;
end;
}

procedure BandChangeReport;
label
  1;
var
  LastBand                              : BandType;
  LastMode                              : ModeType;
  FirstQSO                              : boolean;
  QSONumber, NumberBandChanges, NumberTwoXmtrQSOs, LastBandChangeQSO: integer;
  FileWrite                             : HWND;
  sr                                    : PChar;
begin
  if not OpenLogFile then Exit;
  MakeReportFileName('BandChange.txt');
  if not tOpenFileForWrite(FileWrite, @ReportsFilename[1]) then
  begin
    CloseLogFile;
    Exit;
  end;
  QSONumber := 0;
  NumberBandChanges := 0;
  LastBandChangeQSO := -100;
  NumberTwoXmtrQSOs := 0;

  //  Write(QSONumber);
  FirstQSO := True;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if GoodLookingQSO then

    begin
      if FirstQSO then
      begin
        LastBand := TempRXData.Band;
        LastMode := TempRXData.Mode;
        FirstQSO := False;
      end;
      inc(QSONumber);

      if (LastBand <> TempRXData.Band) or (LastMode <> TempRXData.Mode) then
      begin
        inc(NumberBandChanges);
              {
                      Write(FileWrite, NumberBandChanges: 4, '. ',
                        TempRXData.NumberSent: 5,
                        '  Band change from ',
                        BandString[LastBand], ModeString[LastMode], ' to ',
                        BandString[TempRXData.Band], ModeString[TempRXData.Mode], ' at ',
                        TempRXData.tSysTime.wHour: 2, ':', TempRXData.tSysTime.wMinute: 02,
                        '.');
              }
        sr := '';
        if LastBandChangeQSO + 1 = QSONumber then
        begin
          sr := '  *';
          inc(NumberTwoXmtrQSOs);
        end;

        // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
        // NumberBandChanges, fromBand, fromMode, toBand, toMode, Hour, Minute, sr
        // (%02d -> %.2d zero-pad).
        sWriteFileFromString(FileWrite,
          SysUtils.Format('%4d.  Band change from %s%s to %s%s at %.2d:%.2d.%s'#13#10,
            [NumberBandChanges,
             string(BandStringsArray[LastBand]),
             string(ModeStringArray[LastMode]),
             string(BandStringsArray[TempRXData.Band]),
             string(ModeStringArray[TempRXData.Mode]),
             TempRXData.tSysTime.qtHour,
             TempRXData.tSysTime.qtMinute,
             string(sr)]));

              //        WriteLn(FileWrite);
        LastBandChangeQSO := QSONumber;
      end;
      LastBand := TempRXData.Band;
      LastMode := TempRXData.Mode;
    end;
    goto 1;
  end;
  if NumberTwoXmtrQSOs > 0 then
  begin

    sWriteFileFromString(FileWrite,
      SysUtils.Format(#13#10'There were %d second radio QSOs made.', [NumberTwoXmtrQSOs]));
  end;

  CloseLogFile;
  CloseHandle(FileWrite);
  FilePreview;
end;

function GoodLookingQSO: boolean;
begin
  Result := False;

  if TempRXData.ceRecordKind <> rkQSO then Exit;
  if TempRXData.ceQSO_Skiped = True then Exit;
  if TempRXData.Band = NoBand then Exit;
  if TempRXData.Mode = NoMode then Exit;
  if TempRXData.ceQSO_Deleted = True then Exit;

  Result := True;
end;

procedure MakeReportFileName(ShortFileName: PChar);
var
  p                                     : PChar;
begin
  p := @ReportsFilename[1];
  Windows.ZeroMemory(@ReportsFilename, SizeOf(ReportsFilename));
  lstrcpy(p, TR4W_LOG_PATH_NAME);
  lstrcat(p, ShortFileName);
  ReportsFilename[0] := CHR(Windows.lstrlen(p));
  PreviewFileNameAddress := p;
end;

procedure MakeNotesList;
label
  1;
var
  Note                                  : PChar;
  Minutes, Hour                         : integer;
begin
  MakeReportFileName('Notes.txt');
  if not OpenLogFile then Exit;

  if not tOpenFileForWrite(tReportFileWrite, @ReportsFilename[1]) then
  begin
    CloseLogFile;
    Exit;
  end;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if TempRXData.ceRecordKind = rkNote then
    begin
      Minutes := TempRXData.tSysTime.qtMinute;
      Hour := TempRXData.tSysTime.qtHour;
      Note := @TempRXData.Prefix;
      // Issue #998: asm-push wsprintf -> SysUtils.Format. cdecl arg order is
      // %s=date, %02u=Hour, %02u=Minutes, %s=Note (%02u -> %.2u zero-pad).
      sWriteFileFromString(tReportFileWrite,
        SysUtils.Format('%s %.2u:%.2u: %s'#13#10,
          [string(tGetDateFormat(TempRXData.tSysTime)), Hour, Minutes, string(Note)]));
    end;

    goto 1;
  end;
  CloseLogFile;
  CloseHandle(tReportFileWrite);
  FilePreview;
end;

(*----------------------------------------------------------------------------*)

function GetMyExchangeForExport: string;
var
  //HisCallsign                           : PChar;
  cMyZone                               : integer;
  cMyState                              : string;
  cMyPark                               : string;
  cMyName                               : PChar;
  //csName                                : PChar;
  cMyFOCNumber                          : PChar;
  cMyCheck                              : PChar;
  //csCheck                               : integer {PChar};
  crFOCNr                               : PChar;
  cMyGrid                               : PChar;
  csPower                               : PChar;
  //hisAge                                : Integer;
  csQTHString                           : PChar;
  //str1                                  : widestring;
  //nrReceived                            : integer;
  nrSent                                : integer;
  //tempcategoryoperator                  : tcategoryoperator;

  //T1                                    : PChar;
  //T2                                    : PChar;
  //T3                                    : PChar;
  //T4                                    : PChar;      // 4.73.6
  //cKids                                 : PChar;
  TempGrid                              : Str20;
  previousqsonr                         : integer;
  contacts                              : integer;
  PreviousQTHString                     : Str10;
  pnr                                   : integer;




begin
   Result := 'Error generating my exchange';
   try
   TempGrid := MyGrid;
   // Issue #902 -- null-terminate after the actual grid length.
   // Old code wrote #0 at byte 5 unconditionally; that silently truncated
   // 6-char grids (e.g. EL88AA -> EL88) in the exported exchange field.
   TempGrid[Length(MyGrid) + 1] := #0;
   cMyGrid := @TempGrid[1];

   cMyName := @MyName[1];

   cMyZone := StrToInt(MyZone);
   cMyState := MyState;
   cMyPark := MyPark;

   previousqsonr := 0;
   nrSent := TempRXData.NumberSent;


   // Exchanges yet to be added...
   {
    CheckAndChapterOrQTHExchange:
    KidsDayExchange:
    NameQTHAndPossibleTenTenNumber:
    NameAndPossibleGridSquareExchange:
    NZFieldDayExchange:
    RSTAndGrid3Exchange:
    QSONumberNameChapterAndQTHExchange:
    RSTALLJAPrefectureAndPrecedenceExchange:
    RSTAndDOMESTICQTH:       //n4af
    RSTAndFOCNumberExchange: //n4af
    RSTAndGridExchange:
    RSTAndSerialNumberAndGridandPossibleMemberNumber:
    RSTNameAndPossibleFOCNumber:
    RSTPossibleDomesticQTHAndPower:
    RSTQSONumberAndRandomCharactersExchange:
    RSTQSONumberOrDomesticQTHExchange:
    RSTQTHNameAndFistsNumberOrPowerExchange:
    RSTQTHExchange:
    RSTLongJAPrefectureExchange:
    RSTAndGridSquareOrRDAExchange:
   }

   if GoodLookingQSO then
      begin

      {Make Exchanges Strings}
      case ActiveExchange of
         GridExchange, Grid2Exchange:
            begin
           Result := cMyGrid;
        //  Format(CABRILLO_MYEX, '%-11s', cMyGrid);
            end;

         RSTNameAndQTHExchange:
            begin
            Result := SysUtils.Format('%-3d %-5s %-7s', [TempRXData.RSTSent, cMyName, cMyState]);
            end;

         QSONumberAndNameExchange:
            begin
            Result := SysUtils.Format('%-3d %-7s', [nrSent, cMyName]);
            end;

         RSTAndPostalCodeExchange:
            begin
            if contacts = 1 then
               begin
               Result := SysUtils.Format('%-3d %-10s', [TempRXData.RSTSent, MyPostalCode]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-10s', [TempRXData.RSTSent, PreviousQTHString]);
               end;
            end;

         RSTQSONumberAndGridSquareExchange:
            begin
            Result := SysUtils.Format('%-3d %-4d %-7s', [TempRXData.RSTSent, nrSent, cMyGrid]);
            end;

         RSTQSONumberOrDomesticQTHExchange:      //n4af 4.40.6
            begin
            if cMystate[1] <> '' then
               begin
               Result := SysUtils.Format('%-3d  %-5s', [TempRXData.RSTSent, cMyState]);
               end
            else if cMystate[1] = '' then
               begin
               Result := SysUtils.Format('%-3d  %-6d', [TempRXData.RSTSent, nrSent]);
               end;
            end;

         RSTPrefectureExchange:
            Result := SysUtils.Format('%-3d %-7d', [TempRXData.RSTSent, cMyZone]);

         NameAndDomesticOrDXQTHExchange:
            Result := SysUtils.Format('  %-10s %-4s', [cMyName, cMyState]);


         QSONumberPrecedenceCheckDomesticQTHExchange:
            begin
            CID_TWO_BYTES[0] := TempRXData.Precedence;
            //csName := CID_TWO_BYTES;

            cMyName := @MyPrec[1] ;
            //csCheck := {inttopchar}(TempRXData.Check);
            cMyCheck := @MyCheck[1];
            //cMyState := @MySection[1];

            Result := SysUtils.Format('%-4d %s %s %-3s ', [nrSent, cMyName, cMyCheck, MySection]);
            end;

         QSONumberNameDomesticOrDXQTHExchange:
            begin
            //csName := @TempRXData.Name[1];
            cMyName := @MyName[1];
            if MyState = '' then cMyState := 'DX';
            if TempRXData.QTHString = '' then csQTHString := 'DX';
            Result := SysUtils.Format('%-4d %-7s %-8s', [nrSent, cMyNAme, cMyState]);
            end;
         QSONumberAndAgeExchange:
            begin
            Result := SysUtils.Format('%-4d %-8s', [nrSent, cMyState]);
            end;

         RSTAgeAndPossibleSK:
            Result := SysUtils.Format('%-3d %-16s', [TempRXData.RSTSent, cMyState]);

         RSTAgeExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         AgeAndQSONumberExchange:      // 4.55.4
            Result := SysUtils.Format('%-3d %-2s %03d      ', [cMyState, nrSent]);

         RSTAndPOTAPark:
            Result := cMyPark;

         RSTPowerExchange:
            begin
            csPower := @TempRXData.Power[1];
            if contest = FOCMARATHON then
               begin
               cMyFOCNumber :=  @MyFOCNumber[1];
               crFOCNr := @TempRXData.Power[1];
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyFOCNumber]);
               end
            else if Contest <> FOCMARATHON then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);
               end;
            end;
         RSTAndOrGridExchange:
            begin
            Result := SysUtils.Format('%-3d %-7s',[TempRXData.RSTSent, cMyGrid]);
            end;

         QSONumberAndGridSquare:
            Result := SysUtils.Format('%-3s %-7s',[nrSent, cMyState]);

         QSONumberDomesticOrDXQTHExchange, QSONumberDomesticQTHExchange:
            Result := SysUtils.Format('%-4s %-6d', [cMyState, nrSent]);

         QSONumberAndPossibleDomesticQTHExchange, RSTQSONumberAndDomesticQTHExchange, RSTQSONumberAndPossibleDomesticQTHExchange:
            if cMyState = 'TRC' then
               begin
               Result := SysUtils.Format('%-3d %d%-6s',[TempRXData.RSTSent, nrSent, cMyState]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-4d %-6s ',[TempRXData.RSTSent, nrSent, cMyState]);
               end;

         RSTZoneAndPossibleDomesticQTHExchange:
            begin
            if MyState = '' then
               begin
               cMyState := 'DX';
               end;
            Result := SysUtils.Format('%-3d %02u %-4s', [TempRXData.RSTSent, MyZone, cMyState]);
            end;
         RSTZoneOrDomesticQTH, RSTZoneOrSocietyExchange:
            if MyState <> '' then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-7d', [TempRXData.RSTSent, cMyZone]);
               end;

         QSONumberAndCoordinatesSum: {RFASCHAMPIONSHIP}
            Result := SysUtils.Format('%-3s %03d    ', [cMyState, nrSent]);
         QSONumberAndGeoCoordinates:
            Result := cMyState;

         ClassDomesticOrDXQTHExchange:
            Result := SysUtils.Format('%-3s %-7s ', [ MyFDClass, MySection]);

         RSTQSONumberExchange:
            Result := SysUtils.Format('%-3d %03d ', [TempRXData.RSTSent, nrSent]);      // issue 177


         RSTAndContinentExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         RSTDomesticQTHExchange:
            if Contest in [CQVHF {, MMAA}] then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyGrid]);
               end
            else
               begin
               if MyState = '' then
                  begin
                  cMyState := 'DX';
                  end;
               if Contest in [SPDX, PACC] then
                  begin
                  MyState := inttopchar(nrSent);
                  end;
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, MyState]);   // 4.97.5
               end;

         RSTDomesticOrDXQTHExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         QSONumberAndZone:
            Result := SysUtils.Format('  %s    %03d ', [cMyState, nrSent]);

         RSTZoneExchange:
            Result := SysUtils.Format('%-3d %-7.2d', [TempRXData.RSTSent, cMyZone]);

         QSONumberAndPreviousQSONumber:
            begin
            //hisnr := (nrreceived div 1000);    // 4.53.2
            //rxnr := (nrreceived mod 1000);    // 4.53.2
            Result := SysUtils.Format('%-.3u%-7.3d', [pnr, nrSent]);
            end;

         RSTAndQSONumberOrFrenchDepartmentExchange,
         RSTAndQSONumberOrDomesticQTHExchange,
         RSTDomesticQTHOrQSONumberExchange:
            begin
            if (MyState <> '') and (Contest <> PCC) then      // 4.83.2
               begin
               Result := SysUtils.Format('%-3d %-7s',[TempRXData.RSTSent, cMyState]);
               end
            else if StringIsAllNumbers(MyState) then
               begin
               Result := SysUtils.Format('%-4d %03u/M   ', [TempRXData.RSTSent, nrSent]);
               end
            else
               begin
               Result := SysUtils.Format('%-4d %03u   ', [TempRXData.RSTSent, nrSent]);
               end;
            end;
         // Exchanges not yet implemented
         CheckAndChapterOrQTHExchange,
         KidsDayExchange,
         NameQTHAndPossibleTenTenNumber,
         NameAndPossibleGridSquareExchange,
         NZFieldDayExchange,
         RSTAndGrid3Exchange,
         QSONumberNameChapterAndQTHExchange,
         RSTALLJAPrefectureAndPrecedenceExchange,
         RSTAndDOMESTICQTH,       //n4af
         RSTAndFOCNumberExchange, //n4af
         RSTAndGridExchange,
         RSTAndSerialNumberAndGridandPossibleMemberNumber,
         RSTNameAndPossibleFOCNumber,
         RSTPossibleDomesticQTHAndPower,
         RSTQSONumberAndRandomCharactersExchange,
         //RSTQSONumberOrDomesticQTHExchange,
         RSTQTHNameAndFistsNumberOrPowerExchange,
         RSTQTHExchange,
         RSTLongJAPrefectureExchange,
         RSTAndGridSquareOrRDAExchange:
            begin
            Result := 'None';
            logger.error('[] MyExchange ADIF not yet implemented for exchange %s',[ActiveExchangeArray[ActiveExchange]]);
            end;

         end; // of case ActiveExchange
      end;
   except
   end;
   end;
(*----------------------------------------------------------------------------*)
function GetOperatorsFromLog: string;
var
  slOperators                           : TStringList;
  Index: integer;
begin
  Result := '';
  if not OpenLogFile then Exit;

  ReadVersionBlock;

   try
      try
         slOperators := TStringList.Create;
         slOperators.Duplicates := dupIgnore;
	      slOperators.Sorted := false;

         while ReadLogFile do
            begin
            //slOperators.Add(TempRXData.ceOperator);
            slOperators.Values[TempRXData.ceOperator] := IntToStr(StrToInt(slOperators.Values[TempRXData.ceOperator]) + 1);
            end;
         CloseLogFile;
         logger.debug('Before operators sort');
         for Index := 0 to slOperators.Count-1 do
            begin
            logger.debug('   %s',[slOperators.Names[Index]]);
            end;
         slOperators.CustomSort(SLOperatorsSortProc);
         //Result := slOperators.DelimitedText;
         logger.debug('After operators sort');
         for Index := 0 to slOperators.Count-1 do
            begin
            logger.debug('[%d]   %s',[Index,slOperators.Names[Index]]);
            Result := Result + slOperators.Names[Index];
            if Index < (slOperators.Count-1) then
               begin
               Result := Result + ', ';
               end;
            end;
      except
      on E: Exception do
         logger.error('Exception in GetOperatorsFromLog ',E);
      end;
   finally
      FreeAndNil(slOperators);
   end;
end;

function SLOperatorsSortProc(List: TStringList; Index1, Index2: Integer): Integer;
var
  i1, i2: Integer;
begin
  i1 := StrToInt(List.ValueFromIndex[Index1]);
  i2 := StrToInt(List.ValueFromIndex[Index2]);
  Result := i2 - i1;    // This sorts in ascending count order
  /////Result := i1 - i2;    // This sorts in descendiong count order
end;

(*----------------------------------------------------------------------------*)
function GetStateFromSection(section: string) : string;
begin
   logger.debug ('Entering GetStateFromSection with ' + section);
   Case AnsiIndexText(AnsiUpperCase(section), ['EMA', 'WMA',                     // 0..1
                                               'ENY', 'NLI', 'NNY', 'WNY',       // 2..5
                                               'NNJ', 'SNJ',                     // 6..7
                                               'EPA', 'WPA',                     // 8..9
                                               'NFL', 'SFL', 'WCF',              // 10..12
                                               'NTX', 'WTX', 'STX',
                                               'EB',  'LAX', 'ORG', 'SB', 'SCV', 'SDG', 'SF', 'SJV', 'SV',
                                               'PAC',
                                               'EWA', 'WWA',
                                               'GTA', 'ONE', 'ONN', 'ONS',
                                               'MAR'
                                              ]) of

   0..1: Result := 'MA';
   2..5: Result := 'NY';
   6..7: Result := 'NJ';
   8..9: Result := 'PA';
   10..12: Result := 'FL';
   13..15: Result := 'TX';
   16..24: Result := 'CA';
   25: Result := 'HI';
   26..27: Result := 'WA';
   28..31: Result := 'ON';
   32: Result := 'NS';
   else
      Result := Tree.GetStateFromSection(section); // This is to not return VE providences that do map directly from sections.
   end;

   logger.debug('Leaving GetSectionFromState with ' + Result);
end;

function DeleteRepeatedSpaces(const s: string): string;
  var
    i, j, State: Integer;
  begin
    SetLength(Result, Length(s));
    j := 0;
    State := 0;

    for i := 1 to Length(s) do begin

      if s[i] = ' ' then
        Inc(State)
      else
        State := 0;

      if State < 2 then
        Result[i - j] := s[i]
      else
        Inc(j);

    end;

    if j > 0 then
        SetLength(Result, Length(s) - j);
  end;

end.

