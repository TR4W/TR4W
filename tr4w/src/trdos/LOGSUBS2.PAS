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
unit LOGSUBS2;
{$IMPORTEDDATA OFF}
{ $ O + }
interface
uses
  uMMTTY,
  uCallSignRoutines,
//  uSCP,
  uIO,
  MMSystem,
  utils_net,
  utils_text,
  utils_file,
//  uTrayBalloon,
  uMP3Recorder,
  uWinKey,
  uAltD,
  uCTYDAT,
  uDupeSheet,  // 4.53.7
//  uStack,
  uStations,
  uCallsigns,
  uCommctrl,
  //  uMMTTY,
  //uEditQSO,  // Issue 165 NY4I Removed this from here as there was a circular reference. It did not appear to be needed.
  uTelnet,
  TF,
  Version,
  VC,
  //TR,
  uSpots,
  Windows,
  Messages,
  idUDPClient,
  idGlobal,
  WinSock2,
  PostUnit,
  uCabrilloFormat,  // tCabrilloFreqString moved here from PostUnit (extracted for unit testing)
  uTotal,
  uNet,
  BeepUnit,
  LOGSUBS1,
  //Country9,
  FCONTEST,
  Math,  // ny4i 4.44.9
  {JCtrl1,}
  {JCtrl2,}
  CFGCMD,
  LogCfg,
  LogCW,
  LogDom,
  LogDupe,
  //LOGDDX,
  LOGDVP,
  LogEdit,
  LogGrid,
//  Help,
//  LOGHP,
  LogK1EA,
//  LOGMENU,
  LogNet,
  LogPack,
//  LOGPROM,
  LogRadio, { Currently not an overlay }
  LOGSend,
  LogSCP,
  LogStuff,
  uMults,
  LOGWAE,
  LogWind,
  {Printer,}
  {Crt,
  SlowTree,}
  SysUtils,
  DateUtils,
  Tree,
  ZoneCont
  ;
  var TimeLastScoreBroadcast : TDateTime;
  const BandTypeToUDPContactBand  : array[Band160..BandLight] of PChar =
    (
    '1.8',
    '3.5',
    '7',
    '14',
    '21',
    '28',
   
    '10',
    '18',
    '24',
    '50',
    '144',
    '222',
    '420',
    '902',
    '1.2G',
    '2.3G',
    '3.4G',
    '5.7G',
    '10G',
    '24G',
    'LIGHT'
    );
procedure SendScoreToUDP;
procedure LogContactToUDP(RXData: ContestExchange); // ny4i
procedure SendFullLogToHamScore;  // Issue #783 -- enqueue every QSO for RTC resync
procedure LogEditedContactToUDP(RXData: ContestExchange); // ny4i
procedure LookupInfoToUDP(RXData: ContestExchange); // Issue 612 ny4i
function BuildUDPContact(RXData: ContestExchange; whichUDP: UDPType): string; // Issue 612 ny4i
procedure SendFullLogToUDP;
procedure SendDeletedContactToUDP(RXData: ContestExchange);
procedure ToggleModes;
procedure ToggleStereoPin; {KK1L: 6.71}
procedure OTRSPCommand;
procedure LogContact(var RXData: ContestExchange; MyComputer: boolean);
procedure SwapMultDisplay;
procedure PushLogStringIntoEditableLogAndLogPopedQSO(LogString: ShortString {Str80}; MyQSO: boolean);
procedure DeleteLastContact;
//procedure MoveEditableLogIntoLogFile;
procedure DoAltZ({var WindowString: string { VAR KeyChar: CHAR});
function WindowDupeCheck: boolean;
function SearchAndPounce: boolean;
function FoundCommand(var SendString: Str160): boolean;
procedure ShowPartialCallMults(WindowString: CallPtr {CallString});
procedure DupeCheckOnInactiveRadio(Tune: boolean);
function GotExchange: boolean;
procedure ProcessExchangeFunctionKey(ExtendedKey: Char);
procedure ExitProgram(Ask: boolean);
procedure GoToNextMultBandMapFrequency;
procedure GoToNextDisplayedBandMapFrequency;
procedure GoToNextMultDisplayedBandMapFrequency;
function tAddQSOToLog(RXData: ContestExchange): boolean;
function ConvertBandTypeToUDPContactBand(band: BandType): string;
implementation
uses
  uProcessCommand,
  MainUnit,
  uRadioPolling,
  uYCCCSO2R,
  uHamScore,        // Issue #783 -- HamScoreOnLog hook
  uExchangeBuilder; // Canonical SentExchange builder for UDP broadcast
procedure CreateAndSendPacketSpot(PacketSpotCall: CallString; PacketSpotFreq: LONGINT);

begin

end;
procedure PutContactIntoLogFile(LogString: string {Str80});

begin

end;
procedure PushLogStringIntoEditableLogAndLogPopedQSO(LogString: ShortString {Str80};
  MyQSO: boolean);
var
  RData                                 : ContestExchange;

begin

  //  LogString := VisibleLog.PushLogEntry(LogString);
     { LogString is now what popped off the top of the editable window }
  GetRidOfPostcedingSpaces(LogString);
  if LogString <> '' then
  begin
    PutContactIntoLogFile(LogString);
    if ParseExchangeIntoContestExchange(LogString, RData) then
    begin
      ProcessPartialCallAndInitialExchange(RData);
           end;
  end;
end;
procedure ProcessCallWindowCommand(Command: Str80);
{ This procedure gets called if a command in the call window was typed in
  starting with a \ character. }

begin
  Delete(Command, 1, 1); // Get rid of the \ character
  {
    if (Command = 'PASSFREQ') and K1EANetworkEnable then
    begin
      Freq := QuickEditFreq('Enter pass freq in kHz : ', 10);
      Str(Freq, TempString);
           // Make sure my display is updated
      UpdateK1EAStationInfo(Pass, K1EAStationID, TempString);
           // Send to K1EA network
      SendMultiMessage('G' + K1EAStationID + ' ' + TempString);
    end;
  }
  if Command = 'RADIO' then TestRadioInterface;
  {   Disabled in 6.46
      IF TakingABreak AND ((Command = 'TIMEON') OR (Command = 'ON')) THEN
          BEGIN
          ThisBreak := ElaspedMinutes (OffTimeStart);
          TotalOffTime := TotalOffTime + ThisBreak;
          TakingABreak := False;
          SaveSetAndClearActiveWindow (QuickCommandWindow);
          Write ('Total off time is now = ', MinutesToTimeString (TotalOffTime), ' minutes');
          ReminderPostedCount := 60;
          RestorePreviousWindow;
          TempString := '; Break finished at ' + GetFullTimeString +
                        '  This break = ' + MinutesToTimeString (ThisBreak) +
                        '  Total off time = ' + MinutesToTimeString (TotalOffTime);
          PushLogStringIntoEditableLogAndLogPopedQSO (TempString, True);
          END;
      IF (NOT TakingABreak) AND ((Command = 'TIMEOFF') OR (Command = 'OFF')) THEN
          BEGIN
          MarkTime (OffTimeStart);
          TakingABreak := True;
          LastDisplayedBreakTime := -1;
          TempString := '; Break started at ' + GetFullTimeString;
          PushLogStringIntoEditableLogAndLogPopedQSO (TempString, True);
          END;
 }
end;

function WindowDupeCheck: boolean;
{ Returns TRUE if the call window has a dupe in it. }
var
  RememberTime                          : Cardinal {TimeRecord};
  Dupe                                  : boolean;
begin
  WindowDupeCheck := False;
  if length(CallWindowString) < 2 then Exit;
  WindowDupeCheckCall := CallWindowString;
  BandMapBand := ActiveBand;
  BandMapMode := ActiveMode; {KK1L: 6.69 should be here too for no radio connected.}
  Dupe := VisibleLog.CallIsADupe(CallWindowString, ActiveBand, ActiveMode);
  {if not Dupe then }tCreateAndAddNewSpot(CallWindowString, Dupe, ActiveRadioPtr);
  if Dupe then
  begin
//    if AutoDupeEnableSandP then //wli
    begin
      tCallWindowSetFocus;
      WindowDupeCheck := True;
      DispalayDupe;
{
      asm
      lea eax,[CallWindowString+1]
      push eax
      end;
      wsprintf(QuickDisplayBuffer, TC_WASADUPE);
      asm add esp,12
      end;
      QuickDisplay(QuickDisplayBuffer);
}
//      DispalayB4(SW_HIDE);
//      Windows.ShowWindow(B4StatusWindowHandle, SW_HIDE);
//      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
      MarkTime(RememberTime);
      if KeyRecentlyPressed(F1, 200) then FlushCWBufferAndClearPTT; { Withing two seconds }
      ShowStationInformation(@CallWindowString);
      DisplayGridSquareStatus(CallWindowString);

      VisibleLog.DoPossibleCalls(CallWindowString);
      tCleareExchangeWindow;

                   //    RemoveWindow(NameSentWindow);
                   //    RemoveWindow(CountryNameWindow);
    //    DisplayInsertMode(InsertMode);
//      if not QTCsEnabled then
//      begin
//        EscapeDeletedCallEntry := CallWindowString;
              //      CallWindowString := '';
//      end;
//      tCleareCallWindow;
          //{WLI}        ClrScr;
          //{WLI}        Write (CallWindowString);
    end;
  end
  else
  begin
    StationInformationCall := '';
    ShowStationInformation(@CallWindowString);
    DisplayGridSquareStatus(CallWindowString);
      
    if DupeCheckSound = DupeCheckGratsIfMult then
    begin
      if VisibleLog.DetermineIfNewMult(CallWindowString, ActiveBand, ActiveMode)
      {if TempInteger <> 0 }then DoABeep(BeepCongrats);
    end;
  end;
end;
function GoodCallPutUp: boolean;
{ This function will move the call with the cursors around it from the
  possible call window to the call window.  It will be checked to see if
  it is a dupe.  If it is, a FALSE return will be generated.  Otherwise,
  a TRUE response is generated and if any initial exchange exists, it is
  put in the exchange window.  The exchange window will always be left
  active, with the cursor at 1, 1  }
var
  InitialExchange                       : Str80;
begin
  GoodCallPutUp := False;
  with PossibleCallList do
    if NumberPossibleCalls > 0 then
    begin
      CallWindowString := List[CursorPosition].Call;
        //      ClearWindow(ExchangeWindow);
//      if ActiveWindow = ExchangeWindow then
           //        RestorePreviousWindow;
               //{WLI}            ClrScr;
               //{WLI}            Write (CallWindowString);
      if WindowDupeCheck then Exit;
        //      ActivateExchangeWindow;
      InitialExchange := InitialExchangeEntry(CallWindowString);
      if InitialExchange <> '' then
      begin
            //{WLI}                ClrScr;
        ExchangeWindowString := InitialExchange;
            //{WLI}                Write (ExchangeWindowString);
                            {TR6.74 - need to do this since IntialExchangeEntry does not }
        if InitialExchangeOverwrite then
          InitialExchangePutUp := ExchangeWindowString <> '';
        if InitialExchangeCursorPos = AtEnd then
               //                    GoToXY (Length (InitialExchange) + 1, 1)
    //    else
              //{WLI}                    GoToXY (1, 1);
      end
      else
          //{WLI}                Write (ExchangeWindowString);
 //         GoToXY (1,1);
        ShowStationInformation(@CallWindowString);
      DisplayGridSquareStatus(CallWindowString);
      GoodCallPutUp := True;
    end;
end;
procedure ToggleStereoPin; {KK1L: 6.71}
begin
  TF.InvertBoolean(StereoPinState);
  SetStereoPin(StereoControlPin, StereoPinState);
  if ycccActive then
     YCCCSetStereo(StereoPinState);
end;

{ Handles OTRSP=RX1, OTRSP=RX2, OTRSP=RXA, OTRSP=RXI, OTRSP=STEREO function key commands }
procedure OTRSPCommand;
var
   cmd: string;
begin
   if not ycccActive then
      begin
      Exit;
      end;
   cmd := UpperCase(scFileName);
   if cmd = 'RX1' then
      begin
      YCCCSetRxMode(False, False);
      end
   else if cmd = 'RX2' then
      begin
      YCCCSetRxMode(True, False);
      end
   else if cmd = 'STEREO' then
      begin
      YCCCSetRxMode(False, True);
      end
   else if cmd = 'RXA' then
      begin
      { Follow active (TX) radio }
      YCCCSetRxMode(ActiveRadio = RadioTwo, False);
      end
   else if cmd = 'RXI' then
      begin
      { Follow inactive radio - opposite of TX }
      YCCCSetRxMode(ActiveRadio = RadioOne, False);
      end;
end;

procedure ToggleModes;
begin
  if (MultipleModesEnabled) or (TotalContacts = 0) then
  begin
    case ActiveMode of
      CW: if DigitalModeEnable then ActiveMode := Digital else ActiveMode := Phone;
      Phone: if ActiveBand >= Band6 then ActiveMode := FM else ActiveMode := CW;
      Digital: ActiveMode := Phone;
    else ActiveMode := CW;
    end;

    EditingCallsignSent := False;
    DisplayBandMode(
      ActiveBand,
      ActiveMode,
        True
      );
    DisplayCodeSpeed;
      {KK1L: 6.73 This gets done in UpdateTimeAndRateDisplay. Only do if no radio connected.}
     if ((ActiveRadio = RadioOne)  and ((Radio1.tCATPortType <> NoPort)) or (not Radio1.PollingEnable))  then
      Radio1.ModeMemory {ModeMemory[RadioOne]} := ActiveMode
    else
      if (ActiveRadio = RadioTwo) and ((Radio2.tCATPortType = NoPort) or (not Radio2.PollingEnable)) then
        Radio2.ModeMemory {ModeMemory[RadioTwo]} := ActiveMode;
    UpdateTotals2;
    CallsignsList.DisplayDupeSheet(ActiveRadioPtr);
    if QSOByMode then VisibleDupeSheetChanged := True;
    if MultByMode then
    begin
      VisibleLog.ShowRemainingMultipliers;
      VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
    end;
    BandMapBand := ActiveBand;
    BandMapMode := ActiveMode; {KK1L: 6.68 BM now tracks mode with no radio connected on mode change}
    DisplayBandMap;
  end;
end;
procedure DupeCheckOnInactiveRadio(Tune: boolean);
{ This will perform a dupe check on the inactive radio }
var

  isDupe                                : boolean;

begin
  if not TwoRadioMode then
  begin
    QuickDisplay(TC_ALTDCOMMANDDISABLED);
    Exit;
  end;
   RITEnable := False;
  { VER6.73 - Make up a string of the inactive CW Speed for display }
  Str(InActiveRadioPtr.SpeedMemory, SpeedString);
  BandMapBand := InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]};
  BandMapMode := InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]};
 // DisplayBandMap; { Do we always want to do this?  What if already up? }    // 4.102.5
  
  if K5KA.AltDString <> '' then
  begin
    tClearDupeInfoCall;
    DupeInfoCall := K5KA.AltDString;
  end
  else
  begin
   if not Tune then
//    tDialogBox(54, @AltDDlgProc);
      CreateModalDialog(140, 50, tr4whandle, @AltDDlgProc, 0);
  end;    
  { Put the band map on the band/mode of the inactive radio }
  if (DupeInfoCall = MyCall) then exit;    // issue 158
  if (DupeInfoCall <> '') {and (DupeInfoCall <> EscapeKey)} then
begin
    DisplayGridSquareStatus(CallWindowString);
    ShowStationInformation(@DupeInfoCall);                                          //gav 4.44.8
    isDupe := VisibleLog.CallIsADupe(DupeInfoCall, InActiveRadioPtr.BandMemory, InActiveRadioPtr.ModeMemory);
    if not Tune then tCreateAndAddNewSpot(DupeInfoCall, isDupe, InActiveRadioPtr);
    if isDupe and (DupeInfoCall <> MyCall) then   // n4af issue158
    begin
      DupeInfoCallWindowState := diDupe;
      Format(wsprintfBuffer, '%s DUPE!! on %s%s', @DupeInfoCall[1], BandStringsArray[InActiveRadioPtr.BandMemory], ModeStringArray[InActiveRadioPtr.ModeMemory]);
      SetMainWindowText(mweDupeInfoCall, wsprintfBuffer {DupeInfoCall + ' DUPE!! on ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory]});
      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
 //      tClearDupeInfoCall;
  //      clearaltd; // 4.53.11  // 4.126.1
     end
    else
    begin
      DupeInfoCallWindowState := diNotDupe;
      if VisibleLog.DetermineIfNewMult(DupeInfoCall, InActiveRadioPtr.BandMemory, InActiveRadioPtr.ModeMemory)
      {if TempString <> 0 }then
      begin
        if DupeCheckSound = DupeCheckGratsIfMult then DoABeep(BeepCongrats);
        DupeInfoCallWindowState := diNotDupeMult;
      end;
      Format(wsprintfBuffer, '%s OK!!'#13#10'Space bar for %s%s', @DupeInfoCall[1], BandStringsArray[InActiveRadioPtr.BandMemory], ModeStringArray[InActiveRadioPtr.ModeMemory]);
      SetMainWindowText(mweDupeInfoCall, wsprintfBuffer {DupeInfoCall + ' DUPE!! on ' + BandStringsArray[InActiveRadioPtr.BandMemory] + ModeString[InActiveRadioPtr.ModeMemory]});
      if TwoRadioState <> TwoRadiosDisabled then TwoRadioState := CallReady;
    end;
  end;
 
  RITEnable := True;
end;
procedure SwapMultDisplay;
label
  Next;
//var  no                                    : integer;
begin
  if NumberDifferentMults < 2 then Exit;
//  no := 0;
  Next:
//  inc(no);
//  if no > 10 then Exit;
  if RemainingMultDisplay = rmPrefix then
    RemainingMultDisplay := rmDomestic
  else
    RemainingMultDisplay := RemainingMultiplierType(Ord(RemainingMultDisplay) + 1);
  case RemainingMultDisplay of
    rmDomestic: if not DoingDomesticMults then goto Next;
    rmDX: if not DoingDXMults then goto Next;
    rmZone: if not DoingZoneMults then goto Next;
    rmPrefix: if not DoingPrefixMults then goto Next;
  end;

  SetRemMultsColumnWidth;
  VisibleLog.ShowRemainingMultipliers;
end;
procedure DeleteLastContact;
var
  TempRXData                            : ContestExchange;
  lpNumberOfBytesRead                   : Cardinal;
  p                                     : PChar;

begin
  if not OpenLogFile then Exit;
  tSetFilePointer(-1 * SizeOf(ContestExchange), FILE_END);
  Windows.ReadFile(LogHandle, TempRXData, SizeOf(ContestExchange), lpNumberOfBytesRead, nil);
  if
    (lpNumberOfBytesRead <> SizeOf(ContestExchange)) or
    (TempRXData.ceRecordKind <> rkQSO) or
    (TempRXData.ceQSO_Skiped <> tLastLogEntryIsDeleted)
    then
  begin
    CloseLogFile;
    Exit;
  end;
  if tLastLogEntryIsDeleted then
  begin

    TempRXData.ceQSO_Skiped := False;
    p := TC_YOUHAVERESTOREDTHELASTDELETED;
    LogContactToUDP(TempRXData);
    if Assigned(externalLogger) then
       begin
       externalLogger.LogQSO(TempRXData);
       end;
    // Issue #920 -- mirror restoration to HamScore as a (re-)contactinfo
    // so the server sees the QSO come back with the same ID.
    HamScoreOnLog(TempRXData);
  end
  else
  begin
    TempRXData.ceQSO_Skiped := True;
    p := TC_YOUHAVEDELETEDTHELASTLOGENTRY;
    SendDeletedContactToUDP(TempRXData);
    if Assigned(externalLogger) then
       begin
       externalLogger.DeleteQSO(TempRXData);
       end;
    // Issue #920 -- mirror the deletion to HamScore via <contactdelete>.
    // Previously only LogContact had a HamScore hook; ALT-Y deletes
    // dropped silently from the server's view.
    HamScoreOnDelete(TempRXData);
  end;
  InvertBoolean(tLastLogEntryIsDeleted);
  tSetFilePointer(-1 * SizeOf(ContestExchange), FILE_END);
  sWriteFile(LogHandle, TempRXData, SizeOf(ContestExchange));
  SendRecordToServer(NET_EDITEDQSO_ID, TempRXData);
  CloseLogFile;
  LoadinLog;
  ShowMessage(p);
  //  QuickDisplay(p);
end;
procedure LogBackCopy(Seconds: integer);
var
  SecString, TempString                 : Str80;
begin
  Str(Seconds, SecString);
  Str(NextSerialToSend, TempString);  // Issue #954
  TempString := '; Backcopy made for QSO #' + TempString + ' at ' +
    GetTimeString + ' for ' + SecString + ' seconds.';
  PushLogStringIntoEditableLogAndLogPopedQSO(TempString, True);
end;
procedure PlayLastSeconds(Seconds: integer);

begin

end;

// Wait for a thread handle to signal, pumping Windows messages so that
// cross-thread SendMessage calls (e.g. SetDlgItemText from the polling
// thread) don't deadlock the main thread.
procedure WaitForPollingThreadWithMessages(H: THandle; TimeoutMs: DWORD);
var
   Deadline: DWORD;
   Remaining: DWORD;
   WaitResult: DWORD;
   Msg: TMsg;
begin
   if H = 0 then
      begin
      Exit;
      end;
   Deadline := GetTickCount + TimeoutMs;
   repeat
      Remaining := Deadline - GetTickCount;
      if Remaining > TimeoutMs then
         begin
         Break;  // wrapped past deadline
         end;
      WaitResult := MsgWaitForMultipleObjects(1, H, False, Remaining, QS_SENDMESSAGE);
      if WaitResult = WAIT_OBJECT_0 then
         begin
         logger.Info('[WaitForPollingThread] Thread exited cleanly');
         Break;  // thread exited
         end;
      if WaitResult = WAIT_TIMEOUT then
         begin
         logger.Info('[WaitForPollingThread] TIMED OUT after %dms', [TimeoutMs]);
         Break;  // timed out
         end;
      // WAIT_OBJECT_0 + 1 = message available — pump it so SendMessage unblocks
      PeekMessage(Msg, 0, 0, 0, PM_NOREMOVE);
   until False;
end;

procedure ExitProgram(Ask: boolean);
begin
{$IF not tDebugMode }
  if Ask then
    if YesOrNo(tr4whandle, TC_DOYOUREALLYWANTTOEXITTHEPROGRAM) = IDno then Exit;
  logger.Info('Starting ExitProgram');
{$IFEND}
//  GetLogColumnsWidth;
//  timeEndPeriod(1);
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_EXIT, 0);
{$IFEND}
{$IF  LANG = 'RUS'}
//  if (OCXHandle <> 0) then FreeLibrary(OCXHandle);
{$IFEND}
  logger.Info('[ExitProgram] Step 1: SaveTelnetWindowSpots');
  logger.debug('Calling SaveTelnetWindowSpots');
  SaveTelnetWindowSpots;
  logger.debug('Back from SaveTelnetWindowSpots');

  // Stop polling threads FIRST so they don't recreate transports or call
  // SendMessage (SetDlgItemText) while we're tearing down on the main thread.
  // Use MsgWaitForMultipleObjects to pump messages while waiting — polling
  // threads call SetDlgItemText which uses SendMessage to the main thread.
  // Plain WaitForSingleObject deadlocks because SendMessage blocks until
  // the owning thread processes the message.
  logger.Info('[ExitProgram] Step 2: Stopping polling threads');
  Radio1.PollingStopRequested := True;
  Radio2.PollingStopRequested := True;
  logger.Info('[ExitProgram] Step 2a: Waiting for Radio1 (handle=%d)', [Radio1.tRadioInterfaceThreadHandle]);
  WaitForPollingThreadWithMessages(Radio1.tRadioInterfaceThreadHandle, 3000);
  logger.Info('[ExitProgram] Step 2b: Waiting for Radio2 (handle=%d)', [Radio2.tRadioInterfaceThreadHandle]);
  WaitForPollingThreadWithMessages(Radio2.tRadioInterfaceThreadHandle, 3000);
  logger.Info('[ExitProgram] Step 2c: Polling threads done');

  // Disconnect network radios BEFORE WSACleanup kills the sockets.
  // Without this, the radio never receives disconnect packets and keeps
  // the session alive, blocking reconnection on next program start.
  logger.Info('[ExitProgram] Step 3: Disconnecting Radio1');
  if Radio1.tNetObject <> nil then
     begin
     Radio1.tNetObject.Disconnect;
     end;
  logger.Info('[ExitProgram] Step 4: Disconnecting Radio2');
  if Radio2.tNetObject <> nil then
     begin
     Radio2.tNetObject.Disconnect;
     end;
  logger.Info('[ExitProgram] Step 5: WSACleanup');

  if WindowsSocketsInitialised then
     begin
     WSACleanup;
     end;

  ntBeepClose;

  logger.Info('[ExitProgram] SaveTR4WPOSFILE');
  SaveTR4WPOSFILE;

  if BackCopyEnable then
     begin
     StopBackCopy;
     end;

  if NetDebug then
     begin
     Close(NetDebugBinaryOutput);
     Close(NetDebugBinaryInput);
     end;
  if UDPBroadcastScore then
     begin
     SendScoreToUDP;
     end;
  if DVKEnable then
     begin
     DVPUnInit;
     end;

  {if BandMapEnable then }SaveBandMap;
  wkClose;
  DriverDestroy;

  logger.Info('[ExitProgram] Step SaveRestartFile');
  Sheet.SaveRestartFile;

  UnInitializeKeyer;
  NoSound;
  CD.SCPDisableAndDeAllocateFileBuffer;
//  SaveMissedWAVCallsigns;
//  CallsignsList.Destroy;
//  SpotsList.Destroy;
  if LuconSZLoadded then RemoveFontResource(TR4W_LC_FILENAME);
{$IF SCPDEBUG}
  if scpLoaded then
     begin
     scpClose;
     end;
{$IFEND}
//  if TrayBallonDisplayed then Balloon_DeleteTrayIcon;
  FreeAndNil(udp); // ny4i 4.44.9 Destroy the udp object
  FreeAndNil(slElements);
  // Restore StickyKeys settings // ny4i Issue 126
  SystemParametersInfo( SPI_SETSTICKYKEYS, SizeOf(StickyKeysAtStartup), @StickyKeysAtStartup, 0 );
 logger.Info('[ExitProgram] Calling tr4w_Shutdown');
 tr4w_ShutDown;
 logger.Info('[ExitProgram] Exiting');
end;

procedure TalkToRTTYPort;


begin

end;
procedure PacketWindow;
var
  Key                                   : Char;
 // TempString                            : string;
  CommandLine                           : Str80;
//  RememberDoingZ80Op                    : boolean;
//  RadioFrequency                        : REAL;
//  Band                                  : BandType;
//  Mode                                  : ModeType;
//  StringLength, Result                  : integer;
//  PacketByte                            : Byte;
  TimeMark                              : Cardinal {TimeRecord};
begin
  PacketWindowUp := True;
  RITEnable := False;
  QuickDisplay(TC_YOUARENOWTALKINGTOYOURPACKETPORT);
  //  SaveSetAndClearActiveWindow(DupeSheetWindow);
   //{WLI}    ClrScr;
  Packet.DisplayPacketDisplayBuffer;
  { Show chars from incomplete line that isn't in the PacketDisplayBuffer }
//  Write(Packet.PacketDisplayLine);
  CommandLine := '';
  MarkTime(TimeMark);
  repeat
    UpdateTimeAndRateDisplays(True, True);
    if NewKeyPressed then
    begin
      MarkTime(TimeMark);
      Key := NewReadKey;
      if Key = ControlB then
      begin
        if PacketAutoCR and (CommandLine <> '') then
          if Packet.PacketSerialPort <> NoPort then
            SendChar(Packet.PacketSerialPort, Key)
          else
            if {ActiveMultiPort } NoPort <> NoPort then
            begin
              if 1 = 1 {K1EANetworkEnable} then
              begin
                        //                SendMultiMessage('A' + K1EAStationID + CommandLine);
              end
              else
                SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
                  MultiPacketMessageToSend, CommandLine);
            end;
            //        RestorePreviousWindow;
            //        RemoveWindow(BigWindow);
//        VisibleLog.SetUpEditableLog;
        UpdateTotals2;
        VisibleLog.ShowRemainingMultipliers;
        VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
            {                  if VisibleDupesheetEnable then
                                 begin
                                    VisibleDupeSheetChanged := true;
                                    VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
                                 end;
            }
                              //        RemoveWindow(QuickCommandWindow);
        PacketWindowUp := False;
        RITEnable := True;
        Exit;
      end;
      if Key = NullKey then
      begin
        Key := NewReadKey;
            //        case Key of
            //          AltA:
            //            if (CallWindowString = '') and (LastSCPCall = '') then
            //              SetAlarm
            //            else
            //              VisibleLog.SuperCheckPartial(CallWindowString, False, ActiveRadio);
                                 {KK1L: 6.73 Added ActiveRadio}
            //          AltB:
            //            begin
                                       //{WLI}                        RememberFrequency;
            //              BandUp;
                                       {KK1L: 6.73 NOTE the following statement is redundant. It is in BandUp and BandDown.}
            //              if QSONumberByBand then
            //                DisplayNextQSONumber(TotalContacts + 1);
            //            end;
            //          AltD:
            //            if K1EANetworkEnable then
            //              PassStationToCTNetwork
            //            else
            //              DupeCheckOnInactiveRadio;
            //          AltK: ToggleCW(true);
            //          AltM:
            //            begin
                                       //{WLI}                        RememberFrequency;
            //              ToggleModes;
            //            end;
            //          AltR:
            //            begin
                                       //{WLI}                        SwapRadios;
            //              InactiveRigCallingCQ := False;
            //              Str(SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Used to use a variable CheckSpeed}
            //            end;
            //          AltS: SetNewCodeSpeed;
            //          AltT: TimeAndDateSet;
            //          AltV:
            //            begin
                                       //{WLI}                        RememberFrequency;
            //              BandDown;
            //            end;
            //          AltX: ExitProgram;
            //          AltY:
            //            begin
            //              DeleteLastContact;
            //              LastTwoLettersCrunchedOn := '';
            //            end;
            //          PageUpKey: SpeedUp;
            //          PageDownKey: SlowDown;
            //        else
                                    //{WLI}                      SendFunctionKeyMessage (Key, OpMode);
                                                          {KK1L: note: this is where to add switch to SAPMode if NextBandMap command}
            //        end;
      end
      else
      begin
        if Packet.PacketSerialPort <> NoPort then
          SendChar(Packet.PacketSerialPort, Key)
        else
          if Key <> BackSpace then
          begin
            if Key <> CarriageReturn then
              Write(Key)
            else
              WriteLn(Key);
          end
          else
                {                        IF WhereX > 1 THEN
                                            BEGIN
                                            GoToXY (WhereX - 1, WhereY);
                                            Write (' ');
                                            GoToXY (WhereX - 1, WhereY);
                                            END;
                 }
            if Key <> BackSpace then
              CommandLine := CommandLine + Key
            else
              Delete(CommandLine, length(CommandLine), 1);
      end;
      if Key = CarriageReturn then
      begin
            //                  if (Packet.PacketSerialPort = NoPort) and (ActiveMultiPort <> NoPort) then
        begin
              {
              if K1EANetworkEnable then
              begin
                Delete(CommandLine, length(CommandLine), 1);
                SendMultiMessage('A' + K1EAStationID + CommandLine);
              end
              else
                SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
                  MultiPacketMessageToSend, CommandLine);
                  }
        end;
        CommandLine := '';
      end;
    end;
 //   Packet.CheckPacketBuffer(True);
//    Packet.CheckPacketMessage;
    Sleep(4);
  until ({ActiveMultiPort}NoPort <> NoPort) and (ElaspedSec100(TimeMark) > 2000);
  if PacketAutoCR and (CommandLine <> '') then
    if Packet.PacketSerialPort <> NoPort then
      SendChar(Packet.PacketSerialPort, Key)
    else
      //         if ActiveMultiPort <> NoPort then
    begin
        {
         if K1EANetworkEnable then
         begin
           Delete(CommandLine, length(CommandLine), 1);
           SendMultiMessage('A' + K1EAStationID + CommandLine);
         end
         else
           SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
             MultiPacketMessageToSend, CommandLine);
         }
    end;
  //  RestorePreviousWindow;
  //  RemoveWindow(BigWindow);
//  VisibleLog.SetUpEditableLog;
  UpdateTotals2;
  VisibleLog.ShowRemainingMultipliers;
  VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
  {   if VisibleDupesheetEnable then
        begin
           VisibleDupeSheetChanged := true;
           VisibleLog.DisplayVisibleDupeSheet(ActiveBand, ActiveMode);
        end;
  }
     //  RemoveWindow(QuickCommandWindow);
  PacketWindowUp := False;
  RITEnable := True;
end;
function AutoCQLoopKeyCheck: Char;

begin
   Result := #0; // ny4i Issue 116 to ensure an initialized value of returned.

end;
procedure AutoCQResume(SkipFirstMessage: boolean);
var
  CQMemory, SendChar      : Char;
  CharacterCount                        : integer;
  FileName, TempString                  : ShortString;
  QSONumberString                       : Str20;
  LastDisplayedTimeElasped, Count, TimeElasped: integer;
  StartOfLastPhoneMessage               : Cardinal {TimeRecord};
  TimeOut                               : Byte;
begin
  LastDisplayedTimeElasped := 0;
  SetUpToSendOnActiveRadio;
  KeyPressedMemory := CHR(0);
  CWEnabled := True;
  if not (((AutoCQMemory >= F1) and (AutoCQMemory <= AltF10)) or
    ((AutoCQMemory >= F11) and (AutoCQMemory <= AltF12))) then
    Exit;
  if AutoCQDelayTime > 0 then
  begin
           SetSpeed(DisplayedCodeSpeed);   // 4.49.3
    Write('Repeating ', KeyId(AutoCQMemory), '  Listen time = ',
      (AutoCQDelayTime / 2): 2: 1, ' - PgUp/Dn to adjust or ESCAPE     ');
    FlushCWBuffer;   //n4af 4.36.13
    CQMemory := AutoCQMemory;
    repeat
      if FrequencyDisplayed then
      begin
        LastCQFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
        LastCQMode := ActiveMode;
      end
      else
        LastCQFrequency := 0;
      if (AutoCQMemory = F1) and RandomCQMode then
      begin
        Count := 0;
        repeat
          inc(Count);
          case Random(4) of
            0: CQMemory := F1;
            1: CQMemory := F2;
            2: CQMemory := F3;
            3: CQMemory := F4;
          end;
        until (GetCQMemoryString(ActiveMode, CQMemory) <> '') or (Count > 1000); {KK1L: 6.73 Added mode}
      end;
      if ActiveMode <> Phone then
      begin
        TempString := GetCQMemoryString(ActiveMode, CQMemory); {KK1L: 6.73 Added mode}
        if not SkipFirstMessage then
          for CharacterCount := 1 to length(TempString) do
          begin
            SendChar := TempString[CharacterCount];
            case SendChar of
              '\': AddStringToBuffer(MyCall, CWTone);
              '>': RITClear;
            else AddStringToBuffer(SendChar, CWTone);
            end;
          end;
      end
      else { Phone mode }
      begin
        TempString := GetCQMemoryString(ActiveMode, CQMemory); {KK1L: 6.73 Added mode}
            {KK1L: 6.72 Pulled out the DVK code from the REPEAT...UNTIL. Can't tell end of DVK message}
            {REPEAT {KK1L: 6.71}
            {    IF DVPEnable THEN
            {        BEGIN
            {        WHILE TempString <> '' DO
            {            BEGIN
            {            FileName := RemoveFirstString (TempString);
            {            GetRidOfPrecedingSpaces (FileName);
            {            IF NOT SkipFirstMessage THEN DVPPlayMessage (FileName);
            {            END;
            {        END
            {    ELSE
            {        IF (NOT SkipFirstMessage) AND (ActiveDVKPort <> NoPort) THEN {KK1L: 6.71 added DVK check}
            {            SendDVKMessage (TempString);
            {
            {    IF AutoCQLoopKeyCheck = EscapeKey THEN Exit; {KK1L: 6.71a Check if key fell out of loop or escape}
            {
            {    Wait (20); {KK1L: 6.71}
            {UNTIL NOT (DVPMessagePlaying OR DVKMessagePlaying); {KK1L: 6.71 should start timer at END of message}
            {KK1L: 6.72 Replaced above with this}
        if DVKEnable then
          repeat
            while TempString <> '' do
            begin
              FileName := RemoveFirstString(TempString);
              GetRidOfPrecedingSpaces(FileName);
//              if not SkipFirstMessage then DVPPlayMessage(FileName);
            end;
            if AutoCQLoopKeyCheck = EscapeKey then
            begin
              if DVKEnable and DVPMessagePlaying then {KK1L: 6.71b Kill DVP}
              begin
                TimeOut := 0;
                DVPStopPlayback;
                repeat
                  Sleep(5);
                  inc(TimeOut);
                until (not DVPMessagePlaying) or (TimeOut > 30);
              end;
              Exit;
            end;
            Sleep(20);
          until not DVPMessagePlaying
        else
        begin
                //wli                        if (not SkipFirstMessage) and (ActiveDVKPort <> NoPort) then SendDVKMessage(TempString);
          if AutoCQLoopKeyCheck = EscapeKey then
          begin
                    //wli                              if (ActiveDVKPort <> NoPort) then StartDVK(0); {KK1L: 6.71b Kill DVK}
            Exit;
          end;
        end;
        MarkTime(StartOfLastPhoneMessage); {KK1L: 6.72 Or End in the case of DVP}
      end;
      SkipFirstMessage := False;
        {KK1L: 6.68 From here to REPEAT added to put autoCQ in band map and send multi info message.}
      if BandMapEnable and (Radio1.LastDisplayedFreq {LastDisplayedFreq[RadioOne]} <> 0) and (OpMode = CQOpMode) and BandMapDisplayCQ then
      begin
        Str(NextSerialToSend, QSONumberString);  // Issue #954
        BandMapCursorFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
            //            NewBandMapEntry('CQ/ ' + QSONumberString, LastDisplayedFreq[ActiveRadio], 0, ActiveMode, False, False, BandMapDecayTime, True, MyCall);
        tCreateAndAddNewSpot('CQ/ ' + QSONumberString, False, ActiveRadioPtr {?});
        LastCQFrequency := ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]};
        LastCQMode := ActiveMode;
      end;
        //            if ActiveMultiPort <> NoPort then CreateAndSendCQMultiInfoMessage;
      repeat
          {        if ActiveMode <> Phone then
                  begin
                    if CPUKeyer.SlowInterrupts then
                      TimeElasped := CountsSinceLastCW div 149
                    else
                      TimeElasped := CountsSinceLastCW div 298;
                  end
                  else
                   }TimeElasped := MicroTimeElapsed(StartOfLastPhoneMessage) div 50;
        if LastDisplayedTimeElasped <> TimeElasped then
        begin
              //{WLI}                     GoToXY (WhereX - 4, WhereY);
          if TimeElasped < 20 then Write(' ');
          Write((TimeElasped / 2): 2: 1);
          LastDisplayedTimeElasped := TimeElasped;
        end;
          { Allow for many commands to get processed - also see if an
            escape key was pressed. }
        if AutoCQLoopKeyCheck = EscapeKey then Exit;
          {KK1L: 6.72 NOTE Timing delays can occur if there are radio communcations problems due to    }
          {                various timeouts, etc in the polling called from UpdateTimeAndRateDisplays. }
        UpdateTimeAndRateDisplays(True, True);
      Packet.CheckPacket;
        Sleep(4);
      until TimeElasped >= AutoCQDelayTime;
    until False;
  end;
end;
procedure AutoCQ;
var
  Time, Result                          : integer;
   key : Char;
    TempString                            : Str80;
begin
  SetUpToSendOnActiveRadio;
  //  SaveSetAndClearActiveWindow(QuickCommandWindow);
  Write('Press the memory key you want to repeat');
  repeat until NewKeyPressed;
  Key := UpCase(NewReadKey);
  if Key <> NullKey then
  begin
      //    RemoveAndRestorePreviousWindow;
    Exit;
  end;
  Key := NewReadKey;
  if not (((Key >= F1) and (Key <= AltF10)) or ((Key >= F11) and (Key <= AltF12))) then
  begin
      //    RemoveAndRestorePreviousWindow;
    Exit;
  end;
  AutoCQMemory := Key;
  repeat
    //{WLI}         ClrScr;
    if ActiveMode = Phone then
      if DVKEnable then {KK1L: 6.72 Now need to differentiate DVP and DVK}
        {Write ('Number of seconds between start of transmissions : ')}{KK1L: 6.71 fixed this in AutoCQResume}
        Write('Number of seconds of listening time : ') {KK1L: 6.71 fixed this in AutoCQResume}
      else
        Write('Number of seconds between start of transmissions : ') {KK1L: 6.72}
    else
      Write('Number of seconds of listening time : ');
    TempString := '';
    repeat
      repeat until NewKeyPressed;
      Key := UpCase(NewReadKey);
      if Key = EscapeKey then
      begin
          //        RemoveAndRestorePreviousWindow;
        Exit;
      end;
      if Key = BackSpace then
        if length(TempString) > 0 then
        begin
          TempString[0] := CHR(length(TempString) - 1);
            //{WLI}                     GoToXY (WhereX - 1, WhereY);
            //{WLI}                     ClrEol;
        end;
      if (Key >= '0') and (Key <= '9') then
      begin
        TempString := TempString + Key;
        Write(Key);
      end;
    until (length(TempString) = 2) or (Key = CarriageReturn);
    Val(TempString, Time, Result);
    Time := Time * 2;
  until (Time >= 1) and (Time <= 99);
  AutoCQDelayTime := Time;
  //  RemoveAndRestorePreviousWindow;
  AutoCQResume(False);
end;
procedure ShowPartialCallMults(WindowString: CallPtr {CallString});
var
  TestString                            : ShortString;
  //  TestString1                           : string;
  TempString                            : ShortString;
  TempExchange                          : ContestExchange;

begin
//  if not PartialCallMultsEnable then Exit;
  if ActiveMainWindow <> awCallWindow then if ActiveDomesticMult <> GridSquares then Exit;          
  if length(WindowString^) < 2 then Exit;
  if length(WindowString^) < 3 then DispalayNewMult(SW_HIDE);
  if DoingDomesticMults then
   begin                                           // Gav 4.44.8      Uncommented this section
    TempString := WindowString^;
    while TempString <> '' do
    begin
      TestString := RemoveFirstString(TempString);
      TempExchange.QTHString := RemoveFirstString(TestString);
      if not (StringIsAllNumbersOrSpaces(TempExchange.QTHString)) then
        if FoundDomesticQTH(TempExchange) then
        begin
          VisibleLog.ShowDomesticMultiplierStatus(TempExchange.DomesticQTH);
          Exit;
        end;
    end;
  end
 else VisibleLog.ShowMultiplierStatus(WindowString);
end;

{KK1L: 6.68}
procedure GoToNextMultBandMapFrequency;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextMultiplierEntryInBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]}, InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextMultiplierEntryInBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}
      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;
procedure GoToNextDisplayedBandMapFrequency;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextNonDupeEntryInDisplayedBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]},
    InActiveRadioPtr.ModeMemory { ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextNonDupeEntryInDisplayedBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}
      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;
{KK1L: 6.68}
procedure GoToNextMultDisplayedBandMapFrequency;

begin
  if (CommandUseInactiveRadio) and {KK1L: 6.73}
    (NextMultiplierEntryInDisplayedBandMap(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]},
    InActiveRadioPtr.ModeMemory {ModeMemory[InactiveRadio]})) then
    SetUpBandMapEntry(BandMapCursorData, InactiveRadio)
  else
    if NextMultiplierEntryInDisplayedBandMap(ActiveBand, ActiveMode) then
    begin
      SetUpBandMapEntry(BandMapCursorData, ActiveRadio); {KK1L: Added ActiveRadio}
      if ActiveWindow = ExchangeWindow then
      begin
            //{WLI}                 ClrScr;
        ExchangeWindowString := '';
            //        RestorePreviousWindow;
      end;
    end;
end;
function FoundCommand(var SendString: Str160): boolean;

begin
  Result := uProcessCommand.FoundCommand(SendString);
end;
procedure DoAltZ({var WindowString: string {; VAR KeyChar: CHAR});
begin
  tSetExchWindInitExchangeEntry;
  CheckAndSetInitialExchangeCursorPos;
  ShowStationInformation(@CallWindowString);

end;
procedure WindowEditor(var WindowString: string;
  var KeyChar: Char;
  var ExtendedKeyChar: Char);
{ This procedure is inteded to do all the editing functions for the
  given window string.  It is assumed that the window is set up already
  for the string.  If there is some inital value for the string, pass it
  in WindowString, otherwise make it a null string.  If a return, a vertical
  cursor move, escape with no input, or a function key is entered, the
  procedure will halt and return the character that was received.  If the
  key is a function key, only the null character is read.
  A new change is to not do anymore dupechecks in this procedure.  If a
  dupe check is attempted, the procedure will exit with the KeyChar =
  SpaceBar.  Dupe checks are attempted in one of two ways:  If the
  space bar is pressed and the active window is the call window or if the
  space bar is pressed and the active window is the exchange window and
  there is no data entered yet.                                          }

begin

end;
procedure ProcessExchangeFunctionKey(ExtendedKey: Char);
{ This procedure is used when a function key has been pressed when the
  exchange menu is up (either CQ or pounce).  A function key will send
  the memory that is assigned to that key in the CQ exchange mode. }
begin

  case ExtendedKey of
    F1:
      begin
        if (TwoRadioState = StationCalled) then
          CheckTwoRadioState(F1Pressed)
        else
        begin
            
          begin
            if ActiveMode = CW then
            begin
              if not AllCWMessagesChainable then FlushCWBuffer;
              if (KeyRecentlyPressed(F1, 600)) or (not DEEnable) then
                SendCrypticMessage(MyCall)
              else
              begin
                FlushCWBuffer;
                SendCrypticMessage(DEPlusMyCall);
              end;
              KeyStamp(F1);
            end
            else
              if ActiveMode = Digital then
              begin
              if DEEnable then     // wli issue 277
                SendCrypticMessage(CallWindowString + ' DE ' + MyCall + ' ' + MyCall)
              else
                SendCrypticMessage(CallWindowString + ' ' + MyCall + ' ' + MyCall);
              end
              else
                SendFunctionKeyMessage(F1, SearchAndPounceOpMode);
            InactiveRigCallingCQ := False;
          end;
        end;
        if length(CallWindowString) > 2 then tExchangeWindowSetFocus;
        if ExchangeWindowString = '' then
        begin
          tSetExchWindInitExchangeEntry;
          CheckAndSetInitialExchangeCursorPos;
        end;
        ExchangeHasBeenSent := False;
      end;
    F2:
      begin
        if TwoRadioState = StationCalled then
          CheckTwoRadioState(F2Pressed)
        else
        begin
          if ActiveMode in [CW, Digital] then
          begin
            if ActiveMode = CW then
              if not AllCWMessagesChainable then FlushCWBuffer;
            if ExchangeHasBeenSent and (RepeatSearchAndPounceExchange <> '') then
              SendCrypticMessage(RepeatSearchAndPounceExchange)
            else
            begin
              if (ActiveWindow = CallWindow) and
                (CallWindowString = '') and (ExchangeWindowString = '') then
              begin
                if RepeatSearchAndPounceExchange <> '' then
                  SendCrypticMessage(RepeatSearchAndPounceExchange)
                else
                  SendCrypticMessage(SearchAndPounceExchange);
                KeyStamp(ExtendedKey);
                Exit;
              end
              else
                SendCrypticMessage(SearchAndPounceExchange);
            end;
          end
          else
//            SendFunctionKeyMessage(F2, SearchAndPounceOpMode);
            SendCrypticMessage(SearchAndPouncePhoneExchange);
          ExchangeHasBeenSent := True;
        end;
//        if K5KA.ModeEnabled then K5KA.State := KAMessageStarted;
      end;
  else
    begin
      SendFunctionKeyMessage(ExtendedKey, SearchAndPounceOpMode);
      if ExtendedKey = AltF10 then
      begin
        CallsignICameBackTo := CallWindowString;
        ShowStationInformation(@CallWindowString);
      end;
    end;
  end;
  KeyStamp(ExtendedKey);
end;
procedure LogContact(var RXData: ContestExchange; MyComputer: boolean);
{ This procedure will log the contact just completed.  It will be
  pushed onto the editable log and the log entry popped off the editable
  log will be examined and written to the LOG.DAT file.                 }
label
  1;
var

  Address                               : integer;

  TempMode                              : ModeType;
  perfTimeStart, perfTimeStop: TDateTime;
begin
  logger.trace('>>>Entering LogContact');
 // StationInformationCall := '';    // This might be cleared out too soon - Moved to end of TryLogContact ny4i
  ShowQSOStatusCall := '';
  VisibleDupeSheetChanged := True;
  //if Packet.PacketSerialPort <> NoPort then Packet.DeletePacketEntry(RXData.Callsign, RXData.Band, RXData.Mode);
//  OldTotalScore := TotalScore;
  LastTwoLettersCrunchedOn := '';
  if AutoTimeIncrementQSOs > 0 then
  begin
    inc(AutoTimeQSOCount);
    if AutoTimeQSOCount >= AutoTimeIncrementQSOs then IncrementTime(1);
  end;
//   if LastDeletedLogEntry <> '' then
//      begin
//         LastDeletedLogEntry := '';
//         //    RemoveWindow(QuickCommandWindow);
//      end;
  tLastLogEntryIsDeleted := False;
  WindowDupeCheckCall := RXData.Callsign;
  //  LastQSOLogged := RXData;
  if TenMinuteRule <> NoTenMinuteRule then
     UpdateTenMinuteDate(rxData.band,rxData.Mode);
  //  if not DDX(VerifyContact) then RXData.QSOPoints := 0;
     //  if not TailEnding then RemoveWindow(PossibleCallWindow);
  //  if Trace then Write('@');
  if MobileCall(RXData.Callsign) and (ActiveDomesticMult = DomesticFile) and (RXData.DomesticQTH <> '')then    // n4af 4.41.8 Add Q.P. Rover  // 4.98.6
     RXData.Callsign := PrecedingString(RXData.Callsign,'/')  + '/' + RXData.DomesticQTH;  // n4af 4.41.7

  // ceClearDupeSheet bypass: county-line / Nfer follow-up records carry
  // this flag so the dupe check below (and the matching one in
  // tUpdateLog(actRescore)) does NOT flag them as dupes.  See
  // MainUnit.DrainPendingMultiQSORefs for where the flag is set.
  if (not RXData.ceClearDupeSheet) and
    (VisibleLog.CallIsADupe(RXData.Callsign, RXData.Band, RXData.Mode) or
    ((ActiveDomesticMult = GridSquares) and RoverCall(RXData.Callsign) and (NumberGridSquaresInList > 0))) then
    if not (ActiveQSOPointMethod = AlwaysOnePointPerQSO) then
    begin
        //      if Trace then Write('#');
      RXData.ceDupe := True;
        //            RXData.tDupe := True;
      if (ActiveDomesticMult = GridSquares) and RoverCall(RXData.Callsign) then
      begin
        if NumberGridSquaresInList > 0 then
          for Address := 0 to NumberGridSquaresInList - 1 do
            if RXData.DomesticQTH = GridSquareList[Address] then
            begin
              RXData.QSOPoints := 0;
                    //                              if ReminderPostedCount = 0 then
              begin
                Format(QuickDisplayBuffer, TC_YOUALREADYWORKEDIN, @RXData.Callsign[1], @RXData.DomMultQTH[1]);
                QuickDisplay(QuickDisplayBuffer);
                if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
                      //                                    ReminderPostedCount := 60;
              end;
              Break;
            end;
      end
      else
      begin
            //                  if ReminderPostedCount = 0 then
        begin
          Format(QuickDisplayBuffer, TC_ISADUPEANDWILLBELOGGEDWITHZERO, @RXData.Callsign[1]);
          QuickDisplay(QuickDisplayBuffer);
          if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
        end;
        RXData.QSOPoints := 0;
      end;
    end;
  VisibleLog.ProcessMultipliers(RXData);
  if MyComputer then
    begin
    RXData.Radio := ActiveRadioPtr^.RadioModel;
    RXData.ceRadio := ActiveRadio;
    tGetQSOSystemTime(RXData.tSysTime);
    RXData.ceQSOID1 := STARTTIMEOFTHETR4W;
    RXData.ceQSOID2 := Windows.GetTickCount;
    RXData.ceOperator := CurrentOperator;
    if RecorderDuration = rdEachQSO then
      if SaveLastQSOToMP3File(@RXData) then
        RXData.MP3Record := True;
    if not SendRecordToServer(NET_QSOINFO_ID, RXData) then inc(tUSQ);
    perfTimeStart := Now;
    if UDPBroadcastContact then
       begin
       LogContactToUDP(RXData);
       end;
    if ExternalLoggerEnabled then
       begin
       if Assigned(externalLogger) then
          begin
          externalLogger.LogQSO(RXData);
          end;
       end;
    // Issue #783 -- HamScore RTC realtime upload (cheap no-op when disabled).
    HamScoreOnLog(RXData);
    perfTimeStop := Now;
    logger.Debug('Milliseconds to send UDP and TCP to external logger = %d',[DateUtils.MilliSecondsBetween(perfTimeStop, perfTimeStart)]);
    end
  else
    begin     // ny4i issue 82 - If the option is set, broadcast contacts received from the Network
    if UDPBroadcastAllQSOs then
       begin
       LogContactToUDP(RXData);
       end;
    // Issue #783 -- network-received QSOs also feed RTC if multi-op uplink is enabled.
    HamScoreOnLog(RXData);
    end;
  if not tAddQSOToLog(RXData) then Exit;
  //if RXData.Band in [Band160..Band10] then
  inc(ContinentQSOCount[RXData.Band, RXData.QTH.Continent]);
  TempMode := RXData.Mode;
  if TempMode = FM then TempMode := Phone;
  if ((RXData.Mode <> NoMode) and (RXData.Band <> NoBand) and (RXData.ceRecordKind = rkQSO)) then
  begin
    UpdateMaxSerialSent(RXData.Band, RXData.NumberSent);  // Issue #954: track highest sent serial
    inc(QSOTotals[RXData.Band, TempMode]);
    inc(QSOTotals[RXData.Band, Both]);
    inc(QSOTotals[AllBands, TempMode]);
    inc(QSOTotals[AllBands, Both]);
    Sheet.SetMultFlags(RXData);
    Sheet.AddQSOToSheets(@RXData, True);
    CallsignsList.AddCallsign(RXData.Callsign, TempMode, RXData.Band, False);
    CallsignsList.AddIniitialExchange(RXData.Callsign, GetInitialExchangeStringFromContestExchange(RXData));
    SendStationStatus(sstQSOs);
  end;
  if SingleBand <> AllBands then
     begin
     if RXData.Band = SingleBand then TotalQSOPoints := TotalQSOPoints + RXData.QSOPoints;
     end
  else
     TotalQSOPoints := TotalQSOPoints + RXData.QSOPoints;

  if Contest = MOQSOPARTY then
     begin
     CheckMOQSOPartyBonusStation(RXData.Callsign);
     if (RXData.Band in [Band80, Band40]) and
        (RXData.tSysTime.qtHour >= 14) and
        (RXData.tSysTime.qtHour < 20) and
        (MOQSOPartyPeakHourCount < 250) then
        inc(MOQSOPartyPeakHourCount);
     end;
  //  ProcessPartialCallAndInitialExchange(RXData);
    //  PushLogStringIntoEditableLogAndLogPopedQSO(LogString, True);
    //  if Trace then Write('&');
  if MyComputer then
    if not TailEnding then
    begin
//      ShowStationInformation(@RXData.Callsign);
      UpdateStationStatus(RXData.Callsign, -1);
    end;
  if DoingDomesticMults and                                         // Gav 4.44.8   uncommented section
    (MultByBand or MultByMode) and
    (RXData.DomesticQTH <> '') then
    VisibleLog.ShowDomesticMultiplierStatus(RXData.DomMultQTH);
  {Increment rate data}
  inc(NumberContactsThisMinute);
  NumberQSOPointsThisMinute := NumberQSOPointsThisMinute + RXData.QSOPoints;
  if RXData.Band in [Band160..Band10] then
    if RXData.ceRecordKind = rkQSO then
    begin
      inc(NumberBandQSOsThisMinute[RXData.Band]);
      if HourDisplay = BandChangesThisComputer then if not MyComputer then goto 1;
      if tThisHourPreviousBand <> RXData.Band then
      begin
        if tThisHourPreviousBand <> NoBand then inc(tThisHourBandChanges);
        tThisHourPreviousBand := RXData.Band;
        DisplayHour;
      end;
    end;
  1:
  //    DisplayTotalScore (TotalScore);
  DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
  //  CheckAvailableMemory;
  if BeepEvery10QSOs and (TotalContacts mod 10 = 0) then QuickBeep;
  if FloppyFileSaveFrequency > 0 then
    if QSOTotals[AllBands, Both] > 0 then
      if QSOTotals[AllBands, Both] mod FloppyFileSaveFrequency = 0 then
        SaveLogFileToFloppy;
  if UpdateRestartFileEnable then Sheet.SaveRestartFile;
  BeSilent := False;
  NameCallsignPutUp := '';
  if CheckLogFileSize then
    if not LogFileLooksOkay then
    begin
      DoABeep(Warning);
      showwarning(TC_LOGFILESIZECHECKFAILED);
        //            ReminderPostedCount := 60;
    end;
  if CWSpeedFromDataBase and (RememberCWSpeed <> 0) then
  begin
    SetSpeed(RememberCWSpeed);
    RememberCWSpeed := 0;
    DisplayCodeSpeed;
  end;
  //  if (DDXState <> Off) and Debug and (CWTone = 0) then if Random(100) = 0 then BandUp;
  if BandMapEnable then
  begin
      //UpdateBandMapMultiplierStatus;
    SpotsList.UpdateSpotsMultiplierStatus;
      //        KK1L: 6.64 Need to change dupe status for this contact as well
//      UpdateBandMapDupeStatus(RXData.Callsign, RXData.Band, RXData.Mode, True);
    SpotsList.UpdateSpotsDupeStatus(RXData.Callsign, RXData.Band, TempMode {RXData.Mode});
  end;
  if UDPBroadcastScore then
     begin
     if SecondsBetween(TimeLastScoreBroadcast,Now) > 250 then
        begin
        TimeLastScoreBroadcast := Now;
        SendScoreToUDP;
        end;
     end;
  //**************************
  ///StationInformationCall := ''; // ny4i - Moved this to be cleared here.
end;
procedure loglastcall;

begin

end;

function SearchAndPounce: boolean;
label
  ControlEnterCommand1, ControlEnterCommand2;
  { Returns FALSE when we don't want to search and pounce anymore. }

begin
  OpMode := SearchAndPounceOpMode;
  BandMapBand := ActiveBand;
  DisplayBandMap;
  //   if ActiveMultiPort <> NoPort then CreateAndSendSAPMultiInfoMessage;
//wli  LogBadQSOString := '';
  CQRITEnabled := False;
  ClearAutoSendDisplay;
  //????????   FRM.ExchangeWindow.Color := clyellow;
     //  FRM.CallWindow . SetFocus;
  tCallWindowSetFocus;
  //{WLI}    PutUpExchangeWindow;
  PutUpExchangeMenu;
  //   if ReminderPostedCount = 0 then      FRM.QUICKCOMMANDWINDOW . Caption := SAP;
     //        QuickDisplay ('You are in the Search And Pounce mode.  Press Shift-Tab to exit.');
  tCleareExchangeWindow;
  //{WLI}    ExchangeWindowString := '';
  if DupeInfoCall <> '' then {KK1L: 6.73 Keeps SO2R message in line with reality}
  begin
      //    SaveAndSetActiveWindow(DupeInfoWindow);
    WriteLn(DupeInfoCall + ' OK!!          ');
    if (TwoRadioState = StationCalled) and (OpMode = CQOpMode) then
      Write('Enter to complete QSO    '); {KK1L: 6.73 The stuff normally following this should remain.}
      //    RestorePreviousWindow;
  end;
  {   Removed in 6.19 - I decided that it would be better to leave the
      cursor in the call window so you can call the guy with a RETURN.
      Whoops - we need this for two radio stuff.  Put back in if
      TwoRadioState = StationCalled. }
  if TwoRadioState = StationCalled then
  begin
      //{WLI}        ActivateExchangeWindow;
    tSetExchWindInitExchangeEntry;
      //{WLI}        ExchangeWindowString := InitialExchangeEntry (CallWindowString);
      //{WLI}//        ClrScr;
      //{WLI}        Write (ExchangeWindowString);
              {TR6.74 - because InitialExchangeEntry no longer does this }
      //{WLI}        IF InitialExchangeOverwrite THEN
      //{WLI}            InitialExchangePutUp := ExchangeWindowString <> '';
      //{WLI}        IF InitialExchangeCursorPos = AtStart THEN
      //{WLI}            GoToXY (1, 1)
      //{WLI}        ELSE
      //{WLI}            GoToXY (1, Length (ExchangeWindowString) + 1);
      //{WLI}        ExchangeWindowCursorPosition := WhereY;
  end;
  //    IF KeyRecentlyPressed (F1, 100) THEN DDX (MaybeRespondToMyCall);
  //{WLI}    SearchAndPounce := False;
  { Presumed exit value unless a QSO is finished
                                  and we aren't using the SprintQSYRule. }
  SearchAndPounce := True;
end;
procedure GetInitialCall;
var
  Key, TempKey   : Char;
  SearchAndPounceStatus, SpecialRadioSwap {, StationCalled}: boolean;
//  MTotals                               : MultTotalArrayType;
  EditingCallsignSent                   : boolean;
  TimeOut                               : Byte;
begin
  OpMode := CQOpMode;
  EditingCallsignSent := False;
  SpecialRadioSwap := False;
  CallAlreadySent := False;
  //  RemoveWindow(ExchangeWindow);
//  ResetSavedWindowListAndPutUpCallWindow;
  EscapeDeletedCallEntry := CallWindowString;
  CallWindowString := '';
  ExchangeWindowString := '';
  CleanUpDisplay;
//  if DDXState = SAndPExchangeSent then    DDX(NormalContactComplete);
  repeat
    //      PutUpCQMenu;
    //      if ReminderPostedCount = 0 then
    QuickDisplay('ENTER a callsign.  SPACE for dupecheck.  Alt-H for help.');
//    DDX(MaybeSendANewCall);
{
    if DebugFlag and (DDXState = CallSentInResponseToACQ) then
    begin
      CallWindowString := DDXCall1;
      Write(CallWindowString);
    end;
}
    if KeyPressedMemory = ' ' then
    begin
      Key := ' ';
      KeyPressedMemory := CHR(0);
    end
    else
      if ActiveWindow = CallWindow then
        begin
        // Issue #997: was asm nop (no-op then-branch)
        end
//        WindowEditor(CallWindowString, Key, ExtendedKey)
      else
        //wli                WindowEditor(ExchangeWindowString, Key, ExtendedKey);
        if (Key = StartSendingNowKey) and (ActiveWindow = CallWindow) and (length(CallWindowString) >= 1) then
        begin
            //                  if ReminderPostedCount = 0 then
          if AutoCallTerminate then
            QuickDisplay('Continue entering characters.  Auto terminate active!!')
          else
            QuickDisplay('Continue entering characters and press RETURN when done.');
          if length(CallWindowString) > 0 then
          begin
            if MessageEnable then
            begin
              AddStringToBuffer(CallWindowString, CWTone);
              if IsCWByCATActive then
                 begin
                 AddStringToBuffer(CWByCATBufferTerminator,CWTone);
                 end;
//              PTTForceOn;
            end;
            if (SCPMinimumLetters > 0) and (not NewKeyPressed) then {KK1L: 6.73 Added ActiveRadio}
              VisibleLog.SuperCheckPartial(CallWindowString, True, ActiveRadioPtr);
            repeat
              repeat
                if (ActiveMode = CW) and CWEnabled {and (not ReadInLog)} and
                  AutoCallTerminate and not CWStillBeingSent then
                begin
                  CallAlreadySent := True;
                  CallsignICameBackTo := CallWindowString;
                  Exit;
                end;
              until NewKeyPressed {or ReadInLog};
              if 1 > 1 {ReadInLog} then
              begin
                if (length(ReadInCallsign) = length(CallWindowString)) and
                  (length(ReadInCallsign) > 0) then
                  TempKey := CarriageReturn
                else
                begin
                  TempKey := ReadInCallsign[length(CallWindowString) + 1];
                  Sleep(Random(400));
                end;
              end
              else TempKey := UpCase(NewReadKey);
              case TempKey of
                BackSpace:
                  if EditingCallsignSent then
                  begin
                    if length(CallWindowString) > 0 then
                    begin
                      Delete(CallWindowString, length(CallWindowString), 1);
                    end
                  end
                  else
                    if (CWEnabled and DeleteLastCharacter) or not CWEnabled then
                    begin
                      Delete(CallWindowString, length(CallWindowString), 1);
                    end
                    else
                    begin
                      AddStringToBuffer('!', CWTone);
                      Delete(CallWindowString, length(CallWindowString), 1);
                      EditingCallsignSent := True;
                    end;
                NullKey:
                  begin
                    CallAlreadySent := True;
                    CallsignICameBackTo := CallWindowString;
                  end;
                CarriageReturn:
                  begin
                    CallAlreadySent := True;
                    CallsignICameBackTo := CallWindowString;
                    Exit;
                  end;
                EscapeKey:
                  begin
                    if ((ActiveMode = CW) and CWStillBeingSent) or
                      ((ActiveMode = Phone) and (DVPMessagePlaying or DVKMessagePlaying)) then
                    begin
                      if ActiveMode = CW then
                        FlushCWBufferAndClearPTT
                      else
                        if DVPActive then
                        begin
                          DVPStopPlayback;
                          TimeOut := 0;
                          repeat
                            Sleep(5);
                            inc(TimeOut);
                          until (not DVPMessagePlaying) or (TimeOut > 60);
                        end;
                    end
                    else
                    begin
                      FlushCWBufferAndClearPTT;
                      EscapeDeletedCallEntry := CallWindowString;
                      CallWindowString := '';
                            //wli                                ClrScr;
              //                      RemoveWindow(ExchangeWindow);
//                                          if not VisibleDupesheetEnable then
                      begin
                              //                        RemoveWindow(QSOInformationWindow);
                              //                        RemoveWindow(MultiplierInformationWindow);
                      end;
                      NameCallsignPutUp := '';
                            //                      RemoveWindow(QuickCommandWindow);
                      CleanUpDisplay;
                    end;
                  end;
              else
                if (ValidCallCharacter(TempKey)) or (TempKey = '?') then
                begin
                  EditingCallsignSent := False;
                  CallWindowString := CallWindowString + TempKey;
                  AddStringToBuffer(TempKey, CWTone);
                  Write(TempKey);
                  if PartialCallEnable then
                    if Sheet.TwoLetterCrunchProcess(CallWindowString) then
                    begin
                                {
                                  VisibleLog.GeneratePartialCallList(CallWindowString,
                                    ActiveBand,
                                    ActiveMode,
                                    PossibleCallList);
                                  DisplayPossibleCalls(PossibleCallList);
                                  }
                    end;
                  if (SCPMinimumLetters > 0) and (not NewKeyPressed) then {KK1L: 6.73 Added ActiveRadio}
                    VisibleLog.SuperCheckPartial(CallWindowString, True, ActiveRadioPtr);
                end;
              end; { of case }
            until TempKey = EscapeKey;
          end;
        end
        else
          case Key of
            EscapeKey:
              begin
                if ((ActiveMode = CW) and CWStillBeingSent) or
                  ((ActiveMode = Phone) and (DVPMessagePlaying or DVKMessagePlaying)) then
                begin
                  if ActiveMode = CW then
                    FlushCWBufferAndClearPTT
                  else
                    if DVPActive then
                    begin
                      DVPStopPlayback;
                      TimeOut := 0;
                      repeat
                        Sleep(5);
                        inc(TimeOut);
                      until (not DVPMessagePlaying) or (TimeOut > 60);
                    end;
                end
                else
                  if ActiveWindow = ExchangeWindow then
                  begin
                    if ExchangeWindowString <> '' then
                    begin
                      ExchangeWindowString := '';
                          //wli                               ClrScr;
                    end
                    else
                        //                      RemoveAndRestorePreviousWindow;
                  end
                  else
                  begin
                    EscapeDeletedCallEntry := CallWindowString;
                    CallWindowString := '';
                      //wli                           ClrScr;
                    ExchangeWindowString := '';
                      //                    RemoveWindow(ExchangeWindow);
                      //                    RemoveWindow(QSOInformationWindow);
                      //                    RemoveWindow(MultiplierInformationWindow);
                      //                    RemoveWindow(QuickCommandWindow);
                      //                    RemoveWindow(DupeInfoWindow);
                    NameCallsignPutUp := '';
                    tClearDupeInfoCall;
                     clearaltd; // 4.53.11
                      { This is new for 5.88 }
                    if TwoRadioState = CallReady then
                      TwoRadioState := Idle;
                    CleanUpDisplay;
                      //                    DisplayEditableLog(VisibleLog.LogEntries);
                  end;
              end;
            SpaceBar:
              if (DupeInfoCall <> '') and (CallWindowString = '') then
              begin
                FlushCWBufferAndClearPTT;
                if (TwoRadioState = CallReady) then
                    //wli                        CheckTwoRadioState (SpaceBarPressed) {KK1L: 6.73 Should modify to handle Alt-D from SAP mode}
                else
                begin
                      //wli                        SwapRadios;  { Changes band/mode and display }
                  SpecialRadioSwap := True;
                end;
                if TwoRadioState <> CallReady then
                begin
                  CallWindowString := DupeInfoCall; {KK1L: 6.73 NOTE Why are these three lines here?. I know}
                      //                  ResetSavedWindowListAndPutUpCallWindow; {                it puts a call in the window. Does it  }
                  Write(CallWindowString); {                cover the on deck call case???         }
                  ShowStationInformation(@CallWindowString);
                  DisplayGridSquareStatus(CallWindowString);
                  VisibleLog.DoPossibleCalls(CallWindowString);
                  if (length(CallWindowString) >= 3) and (ExchangeWindowString = '') then
                  begin
                          //                    ActivateExchangeWindow;
                    ExchangeWindowString := InitialExchangeEntry(CallWindowString);
                          //wli                            ClrScr;
                          //wli                            Write (ExchangeWindowString);
                                                      {TR6.74 - need to do this since IntialExchangeEntry does not }
                    if InitialExchangeOverwrite then
                      InitialExchangePutUp := ExchangeWindowString <> '';
                          //wli                            IF InitialExchangeCursorPos = AtStart THEN GoToXY (1, 1);
                          //wli                            ExchangeWindowCursorPosition := WhereY;
             //                    RestorePreviousWindow;
                  end;
                  repeat
                        //                                    PutUpExchangeWindow;
                    DisplayNextQSONumber;
                    ClearContestExchange(ReceivedData);
                    ExchangeHasBeenSent := False;
                    SearchAndPounceStatus := SearchAndPounce;
                  until (not SearchAndPounceStatus) or (TwoRadioState = SendingExchange);
                  ClearContestExchange(ReceivedData); { To try and fix a problem
                      with Two Radio mode and DX
                      mults showing up in next QSO }
                  if ActiveRadio = RadioOne then
                  begin
                    CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
                  end
                  else
                    CQRITEnabled := Radio2.RadioModel in KenwoodRadios;
                  if (TwoRadioState = SendingExchange) then
                        //wli                            CheckTwoRadioState (ContactDone)
                  else
                    if SpecialRadioSwap then
                    begin
                            //wli                                SwapRadios;
                      SpecialRadioSwap := False;
                    end;
                  DisplayAutoSendCharacterCount;
                  if SearchAndPounceStatus then
                  begin
                    DupeInfoCall := '';
                          //                    RemoveWindow(DupeInfoWindow);
                    EscapeDeletedCallEntry := CallWindowString;
                    CallWindowString := '';
                          //                    RemoveWindow(ExchangeWindow);
//                    ResetSavedWindowListAndPutUpCallWindow;
                  end;
                end;
              end
                  { Still a SpaceBar, but not doing DupeInfoCall }
              else
                if (CallWindowString = '') or not SpaceBarDupeCheckEnable then
                begin
                  if CWStillBeingSent then FlushCWBufferAndClearPTT; { Clear CW sent on Inactive Radio}
                  SetUpToSendOnActiveRadio;
                  InactiveRigCallingCQ := False;
                  if MessageEnable then
                  begin
                    if ActiveMode = CW then
                    begin
                      if DEEnable then
                        SendStringAndStop(DEPlusMyCall)
                      else
                        SendStringAndStop(MyCall);
                    end
                    else
                      if ActiveMode = Digital then
                        SendStringAndStop(CallWindowString + ' DE ' + MyCall + ' KK')
                      else
                            //wli            SendFunctionKeyMessage (F1, SearchAndPounceOpMode);
                  end;
                  KeyStamp(F1);
                  repeat
                      //                                 PutUpExchangeWindow;
                    DisplayNextQSONumber;
                    ClearContestExchange(ReceivedData);
                    ExchangeHasBeenSent := False;
                  until not SearchAndPounce;
                  ClearContestExchange(ReceivedData);
                  if ActiveRadio = RadioOne then
                  begin
                    CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
                  end
                  else
                    CQRITEnabled := Radio2.RadioModel in KenwoodRadios;
                    //                  RemoveWindow(ExchangeWindow);
                  DisplayAutoSendCharacterCount;
                  EscapeDeletedCallEntry := CallWindowString;
                    //                  if CallWindowString = '' then                    ResetSavedWindowListAndPutUpCallWindow;
                end
                else
                begin
                    //                  if WindowDupeCheck then RemoveWindow(ExchangeWindow);
                    //                  RestorePreviousWindow;
                end;
            TabKey, ControlU:
              begin
                repeat
                  //                           PutUpExchangeWindow;
                  DisplayNextQSONumber;
                  ClearContestExchange(ReceivedData);
                  ExchangeHasBeenSent := False;
                until not SearchAndPounce;
                ClearContestExchange(ReceivedData);
                if ActiveRadio = RadioOne then
                begin
                  CQRITEnabled := Radio1.RadioModel in KenwoodRadios;
                end
                else
                  CQRITEnabled := Radio2.RadioModel in KenwoodRadios;
                DisplayAutoSendCharacterCount;
                {
                if CallWindowString = '' then
                begin
                  RemoveWindow(ExchangeWindow);
                  ResetSavedWindowListAndPutUpCallWindow;
                end;
                }
              end;
            { NullKey:
               begin
                 if (((ExtendedKey >= F1) and (ExtendedKey <= F10)) or
                   ((ExtendedKey >= F11) and (ExtendedKey <= F12)) or
                   ((ExtendedKey >= ControlF1) and (ExtendedKey <= ControlF10)) or
                   ((ExtendedKey >= ControlF11) and (ExtendedKey <= ControlF12)) or
                   ((ExtendedKey >= AltF1) and (ExtendedKey <= AltF10)) or
                   ((ExtendedKey >= AltF11) and (ExtendedKey <= AltF12)) or
                   ((ExtendedKey >= ShiftF1) and (ExtendedKey <= ShiftF10)) or
                   ((ExtendedKey >= ShiftF11) and (ExtendedKey <= ShiftF12))) then
                 begin
                   KeyStamp(ExtendedKey);
                               //wli                        SendFunctionKeyMessage (ExtendedKey, CQOpMode);
                   if (ExtendedKey = F1) or (ExtendedKey = F2) then
                     if FrequencyDisplayed then
                     begin
                       LastCQFrequency := LastDisplayedFreq[ActiveRadio];
                       LastCQMode := ActiveMode;
                     end
                     else
                       LastCQFrequency := 0;
                   if CWMessageCommand = CWCommandSAPMode then
                   begin
                     CWMessageCommand := NoCWCommand;
                     if DupeInfoCall <> '' then
                     begin
                                           //                      SaveAndSetActiveWindow(DupeInfoWindow);
                       WriteLn(DupeInfoCall + ' OK!!          ');
                       Write('CQ mode for   ');
                                           //                      RestorePreviousWindow;
                     end;
                     repeat
                       PutUpExchangeWindow;
                       DisplayNextQSONumber;  // Issue #954: value computed inside (NextSerialToSend)
                       ClearContestExchange(ReceivedData);
                       ExchangeHasBeenSent := False;
                     until not SearchAndPounce;
                     ClearContestExchange(ReceivedData);
                     if ActiveRadio = radioone then
                     begin
                       CQRITEnabled := Radio1.RadioModel = TS850;
                     end
                     else
                       CQRITEnabled := Radio2.RadioModel = TS850;
                     DisplayAutoSendCharacterCount;
                     if CallWindowString = '' then
                     begin
                                           //                      RemoveWindow(ExchangeWindow);
                       ResetSavedWindowListAndPutUpCallWindow;
                     end;
                   end;
                   if (CWMessageCommand = CWCommandControlEnter) then
                   begin
                     BeSilent := true;
                     CWMessageCommand := NoCWCommand;
                     if length(CallWindowString) > 1 then
                     begin
                       CallsignICameBackTo := CallWindowString;
                       Exit;
                     end;
                   end;
                   if ((ExtendedKey = F1) or (ExtendedKey = F2)) then
                     if DDXState <> Off then
                     begin
                       DDXState := WaitingForCQ;
                       DDX(MaybeSendANewCall);
                     end;
                   if ExtendedKey = F9 then DDX(RepeatCallsign);
                 end
                 else
                   case ExtendedKey of
                     DownArrow:
                       if ActiveWindow <> ExchangeWindow then
                         if ExchangeWindowString = '' then
                         begin
                             //                          SaveSetAndClearActiveWindow(ExchangeWindow);
                         end
                         else
                         begin
                           ActivateExchangeWindow;
                         end;
                       // Issue #997: removed a no-op `else asm nop end`.
                     AltC:
                       if (ActiveMode = cw) or (ActiveDVKPort <> NoPort) or DVPEnable then
                       begin
                         AutoCQResume(False);
                         if ValidCallCharacter(UpCase(KeyPressedMemory)) then
                         begin
                           CallWindowString := UpCase(KeyPressedMemory);
                           Write(CallWindowString);
                         end;
                       end;
                     AltQ:
                       if (ActiveMode = cw) or (ActiveDVKPort <> NoPort) or (DVPEnable) then
                       begin
                         EscapeDeletedCallEntry := CallWindowString;
                         CallWindowString := '';
                                        //                        RemoveWindow(PossibleCallWindow);
                                        //                        ClearWindow(CallWindow);
                         ;
                         if ValidCallCharacter(UpCase(KeyPressedMemory)) then
                         begin
                           CallWindowString := UpCase(KeyPressedMemory);
                           Write(CallWindowString);
                         end;
                       end;
                   end;
               end;
        }        
            CarriageReturn:
              if length(CallWindowString) > 1 then
              begin
                CallsignICameBackTo := CallWindowString;
                Exit;
              end
              else
                if length(CallWindowString) = 0 then
                  //wli                           if (ActiveMode = CW) or DVPEnable or (ActiveDVKPort <> NoPort) then
                begin
                  InactiveRigCallingCQ := False;
                  SetUpToSendOnActiveRadio;
                  if MessageEnable and not ((CWTone = 0) and DebugFlag) then
                      //wli                                SendFunctionKeyMessage (F1, CQOpMode);
                                                  { This is where the initial CQ gets sent if you
                                                    are in debug mode! }
{
                    if DDXState <> Off then
                    begin
                      DDXState := WaitingForCQ;
                      DDX(MaybeSendANewCall);
                    end
}
                end;
          end; { of case }
  until False;
end;
function GotExchange: boolean;
{ This function takes care of putting up the exchange menu and operator
  I/O until an exchange is entered or an escape to quit.  A true response
  means that a good exchange has been found.  If the big + key is used to
  enter the exchange instead of a return, the flag QuickQSL is set true. }
label
  ControlEnterCommand1, ControlEnterCommand2;

begin
  //    OpMode := CQOpMode;
  GotExchange := False;
  QuickQSL := NoQuickQSLKey;
  //    TailEnding  := False;
  LookingForCQExchange := True;
  //   if ReminderPostedCount = 0 then
  QuickDisplay('Enter exchange.  Press ENTER to log, ESCAPE to abort QSO.');
  if ActiveMode = CW then PutUpExchangeMenu;
  //  if K1EANetworkEnable then DisplayMultiMessages;
     //    SaveSetAndClearActiveWindow (ExchangeWindow);
  if ExchangeWindowString = '' then
  begin
{
    if ReadInLog then
      ExchangeWindowString := ReadInLogExchange
    else
    begin
      tSetExchWindInitExchangeEntry;
    end;
}
  end;
  {KK1L: 6.73 I want to add a space in front of the InitialExchange for K9PG. I do this in InitialExchangeEntry.}
  {GetRidOfPrecedingSpaces (ExchangeWindowString);}
//  DDX(SendExchange);
  if DualingCQState = WaitingForCallsignInput then
    DualingCQState := DualSendingExchange;
  //{WLI}    IF LogWithSingleEnter THEN
  begin
    if ParametersOkay(CallWindowString,
      ExchangeWindowString,
      ActiveBand,
      ActiveMode,
      ActiveRadioPtr.LastDisplayedFreq {LastDisplayedFreq[ActiveRadio]},
      ReceivedData) then
    begin
      GotExchange := True;
        //            RemoveWindow (ExchangeWindow);
      LookingForCQExchange := False;
      Exit;
    end;
  end;
  { We are now ready to accept input.  The CQ EXCHANGE is being sent,
    all of the windows are setup and we are ready to go }
  if (ActiveMode = CW) and AlwaysCallBlindCQ then
    SendExchangeKeyWhenCWHasStopped := F7;
  {    REPEAT
          IF ActiveWindow = CallWindow THEN
              BEGIN
              WindowString := CallWindowString;
              IF Length (WindowString) > 0 THEN
                  FOR CharPtr := 1 TO Length (WindowString) DO
                      IF WindowString [CharPtr] = '?' THEN
                          IF InsertMode THEN                   Version 6.22
                              GoToXY (CharPtr + 1, WhereY)
                          ELSE}
  {                           GoToXY (CharPtr, WhereY);
              WindowEditor (WindowString, Key, ExtendedKey);
              CallWindowString := WindowString;
              CASE Key OF
                  EscapeKey:
                      BEGIN
                      RemoveWindow (ExchangeWindow);
                      GotExchange := False;
                      LookingForCQExchange := False;
                      Exit;
                      END;
                  SpaceBar: IF SpaceBarDupeCheckEnable THEN
                                IF WindowDupeCheck THEN
                                    BEGIN
                                    RemoveWindow (ExchangeWindow);
                                    GotExchange := False;
                                    LookingForCQExchange := False;
                                    Exit;
                                    END;
                  NullKey:
                      CASE ExtendedKey OF
                          UpArrow, DownArrow:
                              BEGIN      {KK1L testing}
  {                            ActivateExchangeWindow;
                              {QuickDisplay2('ActivateExchangeWindow2');}
  {                            END;
                          ELSE
                              BEGIN
                              ProcessExchangeFunctionKey (ExtendedKey);
                              IF CWMessageCommand = CWCommandControlEnter THEN
                                  BEGIN
                                  BeSilent := True;
                                  CWMessageCommand := NoCWCommand;
                                  GoTo ControlEnterCommand1;
                                  END;
                              END;
                          END;
                  CarriageReturn:
                      BEGIN
  ControlEnterCommand1:
                      IF ParametersOkay (CallWindowString,
                                         ExchangeWindowString,
                                         ActiveBand,
                                         ActiveMode,
                                         LastDisplayedFreq [ActiveRadio],
                                         ReceivedData) THEN
                          BEGIN
                          GotExchange := True;
                          RemoveWindow (ExchangeWindow);
                          LookingForCQExchange := False;
                          Exit;
                          END
                      ELSE
                          BEGIN
                          IF ParameterOkayMode = QSLButDoNotLog THEN
                              BEGIN
  //wli                            SendCorrectCallIfNeeded;
  //wli                            Send73Message;
                              QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                              END;
                          ActivateExchangeWindow;
                          END;
                     END
                  ELSE
                      BEGIN
                      IF (Key = QuickQSLKey1) OR
                         (Key = QuickQSLKey2) THEN
                          BEGIN
                          IF ParametersOkay (CallWindowString,
                                             ExchangeWindowString,
                                             ActiveBand,
                                             ActiveMode,
                                             LastDisplayedFreq [ActiveRadio],
                                             ReceivedData) THEN
                                 BEGIN
                                 GotExchange := True;
                                 RemoveWindow (ExchangeWindow);
                                 IF Key = QuickQSLKey1 THEN
                                     QuickQSL := QuickKey1
                                 ELSE
                                     QuickQSL := QuickKey2;
                                 LookingForCQExchange := False;
                                 Exit;
                                 END
                             ELSE
                                 BEGIN
                                 IF ParameterOkayMode = QSLButDoNotLog THEN
                                     BEGIN
  //wli                                   SendCorrectCallIfNeeded;
  //wli                                   Send73Message;
                                     QuickDisplay ('PLEASE FIX EXCHANGE!!');
                                     END;
                                 ActivateExchangeWindow;
                                 END;
                          END
                      ELSE
                          IF Key = TailEndKey THEN
                              BEGIN
                              IF ParametersOkay (CallWindowString,
                                                 ExchangeWindowString,
                                                 ActiveBand,
                                                 ActiveMode,
                                                 LastDisplayedFreq [ActiveRadio],
                                                  ReceivedData) THEN
                                  BEGIN
                                  GotExchange := True;
                                  RemoveWindow (ExchangeWindow);
                                  TailEnding := True;
                                  LookingForCQExchange := False;
                                  Exit;
                                  END
                              ELSE
                                  BEGIN
                                  IF ParameterOkayMode = QSLButDoNotLog THEN
                                      BEGIN
  //wli                                    SendCorrectCallIfNeeded;
  //wli                                    Send73Message;
                                      QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                      END;
                                  ActivateExchangeWindow;
                                  END;
                              END
                          ELSE
                              ActivateExchangeWindow;
                      END;
                  END; { of case}
  {            END;  { of call window active }
  {        IF ActiveWindow = ExchangeWindow THEN
              BEGIN
  //wli            WindowEditor (ExchangeWindowString, Key, ExtendedKey);
              CASE Key OF
                  EscapeKey: BEGIN
                             RemoveWindow (ExchangeWindow);
                             GotExchange := False;
                             LookingForCQExchange := False;
                             Exit;
                             END;
                  SpaceBar: IF SpaceBarDupeCheckEnable THEN
                                IF WindowDupeCheck THEN
                                    BEGIN
                                    RemoveWindow (ExchangeWindow);
                                    GotExchange := False;
                                    LookingForCQExchange := False;
                                    Exit;
                                    END;
                  NullKey:
                      CASE ExtendedKey OF
                          UpArrow, DownArrow:
                              BEGIN      {KK1L testing}
  {                            RestorePreviousWindow;
                              {QuickDisplay2('RestorePreviousWindow2');}
  {                            END;
                          ELSE
                              BEGIN
                              ProcessExchangeFunctionKey (ExtendedKey);
                              IF CWMessageCommand = CWCommandControlEnter THEN
                                  BEGIN
                                  BeSilent := True;
                                  CWMessageCommand := NoCWCommand;
                                  GoTo ControlEnterCommand2;
                                  END;
                              END;
                          END;
                  CarriageReturn:
                      BEGIN
  ControlEnterCommand2:
                      IF ParametersOkay (CallWindowString,
                                         ExchangeWindowString,
                                         ActiveBand,
                                         ActiveMode,
                                         LastDisplayedFreq [ActiveRadio],
                                         ReceivedData) THEN
                          BEGIN
                          GotExchange := True;
                          RemoveWindow (ExchangeWindow);
                          LookingForCQExchange := False;
                          Exit;
                          END
                      ELSE
                          IF ParameterOkayMode = QSLButDoNotLog THEN
                              BEGIN
  //wli                            SendCorrectCallIfNeeded;
  //wli                            Send73Message;
                              QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                              END;
                      END;
                  ELSE
                      BEGIN
                      IF Key = TailEndKey THEN
                          BEGIN
                          IF ParametersOkay (CallWindowString,
                                             ExchangeWindowString,
                                             ActiveBand,
                                             ActiveMode,
                                             LastDisplayedFreq [ActiveRadio],
                                             ReceivedData) THEN
                              BEGIN
                              GotExchange := True;
                              RemoveWindow (ExchangeWindow);
                              TailEnding := True;
                              LookingForCQExchange := False;
                              Exit;
                              END
                          ELSE
                              IF ParameterOkayMode = QSLButDoNotLog THEN
                                  BEGIN
  //wli                                SendCorrectCallIfNeeded;
  //wli                                Send73Message;
                                  QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                  END;
                          END
                      ELSE
                          IF (Key = QuickQSLKey1) OR
                             (Key = QuickQSLKey2) THEN
                              BEGIN
                              IF ParametersOkay (CallWindowString,
                                                 ExchangeWindowString,
                                                 ActiveBand,
                                                 ActiveMode,
                                                 LastDisplayedFreq [ActiveRadio],
                                                 ReceivedData) THEN
                                  BEGIN
                                  GotExchange := True;
                                  RemoveWindow (ExchangeWindow);
                                  IF Key = QuickQSLKey1 THEN
                                      QuickQSL := QuickKey1
                                  ELSE
                                      QuickQSL := QuickKey2;
                                  LookingForCQExchange := False;
                                  Exit;
                                  END
                              ELSE
                                  IF ParameterOkayMode = QSLButDoNotLog THEN
                                      BEGIN
  //wli                                    SendCorrectCallIfNeeded;
  //wli                                    Send73Message;
                                      QuickDisplay ('PLEASE FIX EXCHANGE for ' + CallsignICameBackTo + '!!');
                                      END;
                              END
                          ELSE
                              RestorePreviousWindow;
                      END;
                  END; { of case}
  {            END;  { of exchange window active }
  {
      UNTIL FALSE;
     }
end;
procedure OperateContest;
var
//MTotals                               : MultTotalArrayType;
  TempKey                               : Char;
  RememberInactiveCQ                    : boolean;
  RememberTime                          : Cardinal {TimeRecord};
  begin
//  ReadInConfigFile('');
  if SayHiEnable then
    DisplayNamePercentage({TotalNamesSent + VisibleLog.NumberNamesSentInEditableLog, TotalContacts});
  SetStereoPin(StereoControlPin, StereoPinState); {KK1L: 6.71}
  DisplayRadio(ActiveRadio);
  DisplayTotalScore {(TotalScore)};
  ClearContestExchange(ReceivedData);
  SetUpToSendOnActiveRadio;
  repeat
    SeventyThreeMessageSent := False;
    ExchangeHasBeenSent := False;
//wli    LogBadQSOString := '';
    if TailEnding then
    begin
      PreviousQSOReceivedData := ReceivedData;
      CallsignICameBackTo := TailEndCallString;
      CallWindowString := TailEndCallString;
        //wli            ClrScr;
      Write(CallWindowString);
      ClearContestExchange(ReceivedData);
      ExchangeWindowString := '';
    end
    else
    begin
//      Sheet.MultSheetTotals(MTotals);
      UpdateTotals2;
      if ReceivedData.DomesticMult or ReceivedData.DXMult or ReceivedData.ZoneMult then
        VisibleLog.ShowRemainingMultipliers;
      if ReceivedData.DomesticMult then VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
      ClearContestExchange(ReceivedData);
      GetInitialCall;
      WindowDupeCheckCall := CallsignICameBackTo;
    end;
    if (ActiveMode = CW) and (not TailEnding) and (not CallAlreadySent) then
    begin
      if MessageEnable and not BeSilent then
        if not (DebugFlag and (CWTone = 0)) then
          AddStringToBuffer(CallsignICameBackTo, CWTone);
      CallAlreadySent := True;
    end;
//    if (ActiveMode = Digital) and (not CallAlreadySent) then
//      StartRTTYTransmission(CallsignICameBackTo + ' ');
    if DualingCQState = DualSendingCQ then
    begin
        //wli            SwapRadios;
      DualingCQState := DualSendingExchange;
    end;
    {??????? ??????  ??????????? ? returnCQopMode}
    if AutoDupeEnableCQ and
      VisibleLog.CallIsADupe(CallsignICameBackTo, ActiveBand, ActiveMode) then
    begin
        //            if ReminderPostedCount = 0 then
//      QuickDisplay(CallsignICameBackTo + ' is a dupe!!');
      if DupeCheckSound <> DupeCheckNoSound then DoABeep(ThreeHarmonics);
      ShowName(CallsignICameBackTo);
      DisplayCountryName(CallsignICameBackTo);
      DisplayUserInfo(CallsignICameBackTo);
      if ActiveMode = CW then
      begin
        if QTCsEnabled then
        begin
          DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)));
          if NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)) < 10 then
          begin
            if QTCsEnabled and (MyContinent = Europe) then
            begin
              AddStringToBuffer(' B4 ', CWTone);
                        //wli                            WAEQTC (CallWindowString);
            end
            else
              if MessageEnable and not BeSilent then
                        //wli                                SendCrypticMessage (QSOBeforeMessage);
          end
          else
            if MessageEnable and not BeSilent then
                    //wli                            SendCrypticMessage (QSOBeforeMessage);
        end
        else
          if MessageEnable and not BeSilent then
                //wli                        SendCrypticMessage (QSOBeforeMessage);
            if DualingCQState <> NoDualingCQs then
              DualingCQState := SendingDupeMessage;
      end;
      if ActiveMode = Digital then
        FinishRTTYTransmission(QSOBeforeMessage);
      if ActiveMode = Phone then
      begin
            //wli                SendCrypticMessage (QSOBeforePhoneMessage);
        Write(' DUPE!!');
        EscapeDeletedCallEntry := CallWindowString;
        CallWindowString := '';
        if QTCsEnabled then
          DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(CallWindowString, False)))
        else
        begin
          MarkTime(RememberTime);
          repeat
            UpdateTimeAndRateDisplays(True, True);
            Packet.CheckPacket;
          until ElaspedSec100(RememberTime) >= 30;
                //wli                    ClrScr;
        end;
      end;
      if AutoDisplayDupeQSO then
      begin
        ShowPreviousDupeQSOs(CallsignICameBackTo, ActiveBand, ActiveMode);
//        EditableLogDisplayed := True;
      end;
      if TailEnding then
      begin
            //        ReceivedData.ceSearchAndPounce := False;
        LogContact(PreviousQSOReceivedData, True);
        TailEnding := False;
      end;
      if Contest <> GENERALQSO then
      begin
        VisibleLog.ShowMultiplierStatus(@CallsignICameBackTo);
        VisibleLog.ShowQSOStatus(@CallsignICameBackTo);
      end;
      DisplayUserInfo(CallsignICameBackTo);
      DisplayBeamHeading(CallsignICameBackTo, '');
    end
    else { not a dupe or not AutoDupeEnable }
    begin
      if MessageEnable and not BeSilent then
        if not (DebugFlag and (CWTone = 0)) then
            //wli                    AddOnCQExchange;
          ShowName(CallsignICameBackTo);
      DisplayGridSquareStatus(CallsignICameBackTo);
      DisplayUserInfo(CallsignICameBackTo);
      DisplayBeamHeading(CallsignICameBackTo, '');
      DisplayCountryName(CallsignICameBackTo);
      if QTCsEnabled then
        DisplayQTCNumber(NumberQTCsThisStation(CallWindowString));
      if Contest <> GENERALQSO then
      begin
        VisibleLog.ShowMultiplierStatus(@CallWindowString);
        VisibleLog.ShowQSOStatus(@CallWindowString);
      end;
      VisibleLog.DoPossibleCalls(CallWindowString);
      if TailEnding then
      begin
            //        ReceivedData.ceSearchAndPounce := False;
        LogContact(PreviousQSOReceivedData, True);
        TailEnding := False;
      end;
//      if K5KA.ModeEnabled then DupeCheckOnInactiveRadio(False);
      if GotExchange then
      begin
        if TailEnding then
        begin
          TailEndCallString := '';
                //wli                    SendCorrectCallIfNeeded;
      //    if MessageEnable then AddStringToBuffer(TailEndMessage + ' ', CWTone);
          repeat
            repeat until NewKeyPressed;
            TempKey := UpCase(NewReadKey);
            if TempKey <> CarriageReturn then
              if ValidCallCharacter(TempKey) or (TempKey = '?') then
              begin
                if MessageEnable then
                  AddStringToBuffer(TempKey, CWTone);
                TailEndCallString := TailEndCallString + TempKey;
              end;
          until TempKey = CarriageReturn;
          if TailEndCallString = '' then
          begin
            TailEnding := False;
                    //            ReceivedData.ceSearchAndPounce := False;
            LogContact(ReceivedData, True);
          end;
        end
        else
        begin
          if ActiveMode = CW then
          begin
            RememberInactiveCQ := InactiveRigCallingCQ;
                    //wli                        SendCorrectCallIfNeeded;
            if not (DebugFlag and (CWTone = 0)) then
            begin
              if MessageEnable and not (BeSilent or TailEnding) then
                if QuickQSL <> NoQuickQSLKey then
                begin
                  if QuickQSL = QuickKey1 then
                                //wli                                        SendCrypticMessage (QuickQSLMessage1)
                  else
                                //wli                                        SendCrypticMessage (QuickQSLMessage2);
                end
                else
                  if ExchangeInformation.Age then
                  begin
                    if ReceivedData.Age = {'00'} 0 then
                      Send88Message
                    else
                                  //wli                                            Send73Message;
                  end
                  else
                              //wli                                        Send73Message;
                    InactiveRigCallingCQ := RememberInactiveCQ;
            end;
          end
          else
            if MessageEnable and not BeSilent then
            begin
              if QuickQSL <> NoQuickQSLKey then
                        //wli                                SendCrypticMessage (QuickQSLPhoneMessage)
              else
                        //                                Send73Message;
            end;
          if DualingCQState = DualGettingExchange then
            DualingCQState := DualSendingQSL;
          BeSilent := False;
          if not TailEnding then
          begin
                    //            ReceivedData.ceSearchAndPounce := False;
            LogContact(ReceivedData, True);
          end;
        end;
      end
      else
        if CWSpeedFromDataBase and (RememberCWSpeed > 0) then
        begin
          SetSpeed(RememberCWSpeed);
          RememberCWSpeed := 0;
        end;
    end;
  until False;
end;
function tAddQSOToLog(RXData: ContestExchange): boolean;
var
  lpNumberOfBytesWritten                : Cardinal;
begin
  Result := False;
  if tPreviousDupeQSOsShowed then ShowPreviousDupeQSOsWnd(False); //DestroyPreviousDupeQSOsWnd;
  LogHandle := CreateFile(TR4W_LOG_FILENAME, GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_FLAG_WRITE_THROUGH, 0);
  if LogHandle = INVALID_HANDLE_VALUE then
  begin
//    showwarning(SysErrorMessage(GetLastError));
    ShowSysErrorMessage('SAVE_LOG');
    Exit;
  end;
//  if not OpenLogFile then Exit;
  tSetFilePointer(0, FILE_END);
  if tWriteFile(LogHandle, RXData, SizeOf(ContestExchange), lpNumberOfBytesWritten) then
    if lpNumberOfBytesWritten = SizeOf(ContestExchange) then
      inc(tRestartInfo.riTotalRecordsInLog);
  CloseLogFile;
  tSetWindowRedraw(wh[mweEditableLog], False);
  if tLogIndex = LinesInEditableLog then
  begin
    ListView_DeleteItem(wh[mweEditableLog], 0);
    tLogIndex := LinesInEditableLog - 1;
  end;
  tAddContestExchangeToLog(RXData, wh[mweEditableLog], tLogIndex);
  EnsureListViewColumnVisible(wh[mweEditableLog]);
  tSetWindowRedraw(wh[mweEditableLog], True);
  Result := True;
//  SendStationStatus;
end;
procedure SendScoreToUDP;
var
    sBuf: AnsiString;

    TempBand                              : BandType;
    TempMode                              : ModeType;
    m                                     : RemainingMultiplierType;
    BandPchar                             : PChar;
    nQSOs                                 : integer;
    nTotal                                : integer;
    sContestName                          : string;
const
  GetScoresMults                        : array[RemainingMultiplierType] of PChar = (nil, 'state', 'country', 'zone', 'prefix');
  GetScoresMultsIARU                   : array[RemainingMultiplierType] of PChar = (nil, 'HQ', 'country', 'zone', 'prefix');
  GetScoresMultsWRTC                   : array[RemainingMultiplierType] of PChar = (nil, 'HQ', 'country', 'zone', 'prefix');
  GetScoresModesArray                   : array[ModeType] of PChar = ('CW', 'DIG', 'PH', 'ALL', nil, nil);
begin
// Score formatted for WRTC Score Computer
{
<?xml version="1.0"?>
<dynamicresults>
	<soft>TR4W</soft>
	<version>4.68</version>
	<contest>IARU-HF</contest>
	<call>NY4I</call>
	<club>Florida Contest Club</club>
	<class ops="SINGLE-OP" mode="MIXED" power="HIGH" bands="ALL"  transmitter="ONE"  assisted = "ASSISTED"></class>
	<breakdown>
		<qso band="80" mode="PH">2</qso>
		<mult band="80" mode="PH" type="CTY">1</mult>
		<mult band="80" mode="PH" type="HQ">0</mult>
		<point band="80" mode="PH">4</point>
		<qso band="total" mode="ALL">2</qso>
		<mult band="total" mode="ALL" type="CTY">1</mult>
		<mult band="total" mode="ALL" type="HQ">0</mult>
		<point band="total" mode="ALL">4</point>
	</breakdown>
	<score>4</score>
	<timestamp>2018-01-19 17:23:51</timestamp>
</dynamicresults>

**** NOTE ****
You cannot use QSOTotals[TempBand, TempMode] for an accurate score for the total QSOs. QSOTotals[TempBand, TempMode] is not decremented for ALL as that is the log's total QSO count including deleted contacts.
QSOTotals[TempBand, TempMode] is accurate for the individual bands so just sum those values to calculate the total
}
   nTotal := 0;
   if UDPBroadcastScore then                // Issue 304 NY4I
     begin
     CalculateTotals;    // This reads the log so be careful how often it is done.
     if length(ContestsArray[Contest].ADIFName) = 0 then
         begin
         sContestName := ContestTypeSA[Contest]
         end
     else
        begin
        sContestName := ContestsArray[Contest].ADIFName;
        end;
     sBuf := '<?xml version="1.0"?>' + sLineBreak +
            '<dynamicresults>' +  sLineBreak +
            #9 + '<soft>TR4W</soft>' + sLineBreak +
            #9 + '<version>' + TR4W_CURRENTVERSION_NUMBER + '</version>' + sLineBreak +
            #9 + '<contest>' + sContestName + '</contest>' +   sLineBreak +
            #9 + '<call>' + MyCall + '</call>' + sLineBreak +
            #9 + '<club>' + ' ' + '</club>' + sLineBreak +
            #9 + '<class ops="' + tCategoryOperatorSA[CategoryOperator] + '" mode="' + tCategoryModeSA[CategoryMode] +
                 '" power="' + tCategoryPowerSA[CategoryPower] + '" bands="' + tCategoryBandSA[CategoryBand] +
                 '" transmitter="' + tCategoryTransmitterSA[CategoryTransmitter] +
                 '" assisted="' + tCategoryAssistedSA[CategoryAssisted] + '"></class>' + sLineBreak +
            #9 + '<breakdown>' + sLineBreak;
  for TempBand := Band160 to AllBands do
     begin
     for TempMode := CW to Phone do {Both do} // Was Phone for a test do
        begin
        if QSOTotals[TempBand, TempMode] = 0 then Continue;
        BandPchar := BandStringsArrayWithOutSpaces[TempBand];
        if TempBand = AllBands then
           begin
           BandPchar := 'total';
           nQSOs := nTotal;
           end
        else
           begin
           nQSOs := QSOTotals[TempBand, TempMode];
           end;
        nTotal := nTotal + QSOTotals[TempBand, TempMode];
        if GetScoresModesArray[TempMode] <> 'ALL' then
           begin
           sBuf := sBuf + #9#9 + '<qso band="' + BandPChar +
                              '" mode="' + GetScoresModesArray[TempMode] +
                              '">' + IntToStr(nQSOs) + '</qso>' + sLineBreak;
           end;
        if Contest <> WRTC then
           begin
           for m := Succ(Low(RemainingMultiplierType)) to High(RemainingMultiplierType) do
              begin
              sBuf := sBuf + #9#9 + '<mult band="' + BandPChar + '" mode="' + GetScoresModesArray[TempMode] +
                                        '" type="' +  GetScoresMults[m] + '">' + IntToStr(mo.MTotals[TempBand, TempMode, m]) +
                                        '</mult>' + sLineBreak;
              end;
           end
        else
           begin // WRTC
           if GetScoresModesArray[TempMode] = 'ALL' then
              begin
              for m := Succ(Low(RemainingMultiplierType)) to Succ(Succ(Low(RemainingMultiplierType))) do  // odd bit of code to select rmDomestic and rmDX
                 begin
                 sBuf := sBuf + #9#9 + '<mult band="' + BandPChar + '" mode="' + GetScoresModesArray[TempMode] +
                                           '" type="' + GetScoresMultsWRTC[m] + '">' +
                                            IntToStr(mo.MTotals[TempBand, TempMode, m]) + '</mult>' + sLineBreak;
                 end;
              end;
           end;
        if GetScoresModesArray[TempMode] = 'ALL' then
           begin
           sBuf := sBuf + #9#9 + '<point band="' + BandPChar + '" mode="' + GetScoresModesArray[TempMode] + '">' +
                        IntToStr(QSOPointTotals[TempBand, TempMode]) + '</point>' + sLineBreak;
           sBuf := sBuf + sLineBreak;
           end;
        end;
        // After mode loop...
     end;
  sBuf := sBuf + #9 + '</breakdown>' + sLineBreak +
                 #9 + '<score>' + IntToStr(TotalScore) + '</score>' + sLineBreak +
                 #9 + '<timestamp>' + SystemTimeToString(UTC) + '</timestamp>' + sLineBreak +
                 '</dynamicresults>' + sLineBreak;
  udp.BroadcastEnabled := true;
  logger.debug('[SendScoreToUDP] \n %s',[sBuf]);
  udp.Send(UDPBroadcastAddress,UDPBroadcastPortScore,sBuf);
  end;
end;
procedure SendDeletedContactToUDP(RXData: ContestExchange);
var
    sBuf: AnsiString;
begin
   if UDPBroadcastContact then                // Issue 165 NY4I
     begin
     sBuf := '<?xml version="1.0"?>' + sLineBreak +
            '<contactdelete>' +  sLineBreak +
            #9 + '<app>TR4W</app>' + sLineBreak +
            #9 + '<timestamp>' +                      // 2008-01-01 07:04:00
               SysUtils.format('20%0.2d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d',[
                      RxData.tSysTime.qtYear,
                      RxData.tSysTime.qtMonth,
                      RxData.tSysTime.qtDay,
                      RxData.tSysTime.qtHour,
                      RxData.tSysTime.qtMinute,
                      RxData.tSysTime.qtSecond]) +
            '</timestamp>' + sLineBreak +
            #9 + '<call>' + RXData.Callsign + '</call>' + sLineBreak +
            #9 + '<contestnr>' + IntToStr(Ord(RxData.ceContest)) + '</contestnr>' + sLineBreak +
            #9 + '<StationName>' +  ComputerName + '</StationName>' + sLineBreak + // Issue 263 NY4I
            #9 + '<ID>' + RxData.id + '</ID>' + sLineBreak +
      '</contactdelete>'+ sLineBreak ;
      udp.BroadcastEnabled := true;
      udp.Send(UDPBroadcastAddress,UDPBroadcastPortContact,sBuf);
      end;
end;

function BuildUDPContact(RXData: ContestExchange; whichUDP: UDPType): string;
var
  // msg: TIdBytes;
  // sBuf: AnsiString;
   sMode : AnsiString;
   nNumberReceived : integer;
   sComputerID : AnsiString;
   freq : integer;
   txFreq : integer;
   nMultCount: integer;
   sContestName: AnsiString;
   sOperator : AnsiString;
   sRecType: AnsiString;
   sExchange: AnsiString;
   sMultiplierFields: AnsiString;
   sTimestamp: AnsiString;
begin
   // if operator is blank, use mycall
   // Add CR to output
   // Band is in Mhz, not meters.
   // ny4i Issue 82 - Added code to check if there is a radio interfaced and if not,
   // generate the base frequency from the band. This uses an array that was used for Cabrillo files.

   case whichUDP of
      
      udpContactInfo: sRecType := 'contactinfo';
      udpContactReplace: sRecType := 'contactreplace';
      udpLookupInfo: sRecType := 'lookupinfo';
      else
         sRecType := 'contactinfo';
      end;

   
   // This is actually wrong. We should send the info from the Contact not the actual radio. NY4I 2021 July 1
   freq := RXData.Frequency;
   txFreq := RXData.Frequency;

   if ActiveRadioPtr.RadioModel <> NoInterfacedRadio then
      begin
      if ActiveRadioPtr.CurrentStatus.Split then
         begin
         freq := ActiveRadioPtr.CurrentStatus.Freq;
         txFreq := ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency;
         end
      else
         begin
         freq := ActiveRadioPtr.CurrentStatus.Freq;
         txFreq := freq;
         end;
      end
   else
      begin // ny4i Issue 82 The Cabrillo reference is just because this array was declared in Cabrillo.
      freq := StrToInt(tCabrilloFreqString[RxData.Band]) * 1000; //14000 in array but needs to be 14000000
      txFreq := freq;
      end;
   if RXData.ExtMode <> eNoMode then
      begin
      sMode := ExtendedModeStringArray[RXData.extMode];
      end
   else
      begin
         case RXData.Mode of
            CW: sMode := 'CW';
            Phone:
               begin
               if IntegerBetween(freq,5300000,5500000) then
                  begin
                  sMode := 'USB'; // 60m band is USB
                  end
               else if freq < 8000000 then
                  begin
                  sMode := 'LSB';
                  end
               else
                  begin
                  sMode := 'USB';
                  end;
               end;
            Digital: sMode := 'RTTY';
            FM: sMode := 'FM';
            else sMode := 'CW';
          end; // of case
      end;
    if RxData.ceComputerID = #0 then
       begin
       sComputerID := ' ';
       end
    else
       begin
       sComputerID := RxData.ceComputerID;
       end;

       if CurrentOperator[0] = #0 then
       begin
       sOperator := MyCall;
       end
   else
      begin
      sOperator := CurrentOperator;
      end;


   if RxData.DXMult then
      begin
      Inc(nMultCount);
      end;
   if RxData.DomesticMult then
      begin
      Inc(nMultCount);
      end;
   if RxData.PrefixMult then
      begin
      Inc(nMultCount);
      end;
   if RxData.ZoneMult then
      begin
      Inc(nMultCount);
      end;
   case nMultCount of
      0:
         begin
         sMultiplierFields := #9 + '<ismultiplier1>0</ismultiplier1>' + sLineBreak +
                              #9 + '<ismultiplier2>0</ismultiplier2>' + sLineBreak +
                              #9 + '<ismultiplier3>0</ismultiplier3>' + sLineBreak;
         end;
      1:
        begin
         sMultiplierFields := #9 + '<ismultiplier1>1</ismultiplier1>' + sLineBreak +
                              #9 + '<ismultiplier2>0</ismultiplier2>' + sLineBreak +
                              #9 + '<ismultiplier3>0</ismultiplier3>' + sLineBreak;
         end;
      2:
        begin
         sMultiplierFields := #9 + '<ismultiplier1>1</ismultiplier1>' + sLineBreak +
                              #9 + '<ismultiplier2>1</ismultiplier2>' + sLineBreak +
                              #9 + '<ismultiplier3>0</ismultiplier3>' + sLineBreak;
         end;
      else
         begin
         sMultiplierFields := #9 + '<ismultiplier1>1</ismultiplier1>' + sLineBreak +
                              #9 + '<ismultiplier2>1</ismultiplier2>' + sLineBreak +
                              #9 + '<ismultiplier3>1</ismultiplier3>' + sLineBreak;
         end;
      end; // case nMultCount

   if length(ContestsArray[Contest].CABName) = 0 then
      begin
      sContestName := ContestTypeSA[RxData.ceContest]
      end
   else
      begin
      sContestName := ContestsArray[Contest].CABName;
      end;

   nNumberReceived := IfThen(RxData.NumberReceived > 0,RxData.NumberReceived,0);
   sTimestamp := SysUtils.format('20%0.2d-%0.2d-%0.2d %0.2d:%0.2d:%0.2d',[
                             RxData.tSysTime.qtYear,
                             RxData.tSysTime.qtMonth,
                             RxData.tSysTime.qtDay,
                             RxData.tSysTime.qtHour,
                             RxData.tSysTime.qtMinute,
                             RxData.tSysTime.qtSecond]);
   Result := '<?xml version="1.0"?>' + sLineBreak +
             '<' + sRecType + '>' + sLineBreak +
             #9 + '<app>TR4W</app>' + sLineBreak +
             #9 + '<contestname>' + sContestName + '</contestname>' + sLineBreak +
             {#9 + '<contestname>' + ContestTypeSA[RxData.ceContest] + '</contestname>' + sLineBreak + }
             #9 + '<contestnr>' + IntToStr(Ord(RxData.ceContest)) + '</contestnr>' + sLineBreak +
             #9 + '<timestamp>' + sTimestamp + '</timestamp>' + sLineBreak +
             #9 + '<mycall>' + MyCall + '</mycall>' + sLineBreak +
             #9 + '<band>' + ConvertBandTypeToUDPContactBand(RXData.Band) + '</band>' + sLineBreak +
            #9 + '<rxfreq>' + Format('%d',[freq div 10]) + '</rxfreq>' + sLineBreak + // 1420100
            #9 + '<txfreq>' + Format('%d',[txFreq div 10]) + '</txfreq>' + sLineBreak +
            #9 + '<operator>' + RXData.ceOperator + '</operator>' + sLineBreak +
            #9 + '<mode>' + sMode + '</mode>' + sLineBreak +
            #9 + '<call>' + RXData.Callsign + '</call>' + sLineBreak +
            #9 + '<countryprefix>' + RxData.QTH.CountryID + '</countryprefix>' + sLineBreak +
            #9 + '<wpxprefix>' + RxData.QTH.Prefix + '</wpxprefix>' + sLineBreak +
            #9 + '<stationprefix>' + RXData.QTH.Prefix + '</stationprefix>' + sLineBreak +
            #9 + '<continent>' + GetContinentName(RXData.QTH.Continent) + '</continent>' + sLineBreak  +
            #9 + '<snt>' + Format('%d',[RxData.RSTSent]) + '</snt>' + sLineBreak +
            #9 + '<sntnr>' + Format('%d',[RxData.NumberSent]) + '</sntnr>' + sLineBreak +
            #9 + '<rcv>' + Format('%d',[RxData.RSTReceived]) + '</rcv>' + sLineBreak +

            #9 + '<rcvnr>' + Format('%d',[nNumberReceived]) + '</rcvnr>' + sLineBreak +
            #9 + '<gridsquare></gridsquare>' + sLineBreak;
   {case Contest of         // This should perhaps case off of the exchange instead of contest.
      ARRLFIELDDAY, WINTERFIELDDAY:
         sExchange := RXData.ceClass;
      NAQSOCW, NAQSOSSB, NAQSORTTY:
         sExchange := RXData.Name;
      else
         sExchange := RXData.ExchString;
      end;}
   // Canonical received exchange, per contest, rebuilt from typed fields
   // so the operator-typed order doesn't leak into consumers. The prior
   // ActiveExchange dispatch only handled 2 cases and fell back to the
   // raw operator string; the shared builder covers more contests
   // (WPX/WAE, CQ WW/IARU, CQ 160, ARRL DX, All Asian, CWT, CWOpen, RTC,
   // Field Day, Winter FD) with the same logic the RTC POST uses.
   sExchange := BuildRxExchangeText(RxData);

   Result := Result + #9 + '<exchange1>' + sExchange + '</exchange1>' + sLineBreak;
   Result := Result +
            #9 + '<section>' + RxData.QTHString + '</section>' + sLineBreak +    // Issue 262
            #9 + '<comment></comment>' + sLineBreak +
            #9 + '<qth>' + RxData.QTHString + '</qth>' + sLineBreak +
            #9 + '<name>' + RxData.Name + '</name>' + sLineBreak +
            #9 + '<power>' + RxData.Power + '</power>' + sLineBreak +
            #9 + '<misctext></misctext>' + sLineBreak +
            #9 + '<zone>' + Format('%d',[RxData.Zone]) + '</zone>' + sLineBreak +
            #9 + '<prec>' + {sPrecedence +} '</prec>' + sLineBreak +
            #9 + '<ck>' + Format('%d',[RxData.Check]) + '</ck>' + sLineBreak +                // TODO
                 sMultiplierFields +
            #9 + '<points>' + Format('%d',[RXData.QSOPoints]) + '</points>' + sLineBreak +
            #9 + '<radionr>' + Format('%d',[Ord(RxData.ceRadio)]) + '</radionr>' + sLineBreak +
            #9 + '<RoverLocation></RoverLocation>' + sLineBreak +
            #9 + '<RadioInterfaced>' + Format('%d',[IfThen(ActiveRadioPtr.RadioModel <> NoInterfacedRadio,1,0)]) + '</RadioInterfaced>' + sLineBreak +  // ny4i Issue 82
            #9 + '<NetworkedCompNr>0</NetworkedCompNr>' + sLineBreak + // TODO
            #9 + '<IsOriginal>True</IsOriginal>' + sLineBreak +
            #9 + '<NetBiosName>' + GetLocalComputerName + '</NetBiosName>' + sLineBreak +
            #9 + '<IsRunQSO>' + Format('%d',[IfThen(RxData.ceSearchAndPounce,0,1)]) + '</IsRunQSO>' + sLineBreak +
            #9 + '<StationName>' +  ComputerName + '</StationName>' + sLineBreak + // Issue 263 NY4I
            #9 + '<ID>' + RxData.id + '</ID>' + sLineBreak +
            // Issue #750: X-QSO records (kept in the log for NIL
            // protection but not claimed for credit) also report
            // IsClaimedQso=0 -- same wire-format meaning as a skipped
            // QSO from the consumer's perspective.  N1MM uses the
            // same convention.
            #9 + '<IsClaimedQso>' + Format('%d',[IfThen(RxData.ceQSO_Skiped or RxData.ceXQSO,0,1)]) + '</IsClaimedQso>' + sLineBreak +
            #9 + '<oldtimestamp>' + sTimestamp + '</oldtimestamp>' + sLineBreak +
            #9 + '<oldcall>' + RXData.Callsign + '</oldcall>' + sLineBreak +
            // SentExchange built from CQExchange template, not the
            // received string. Pre-fix this echoed RxData.ExchString,
            // which is wrong for any contest. See uExchangeBuilder.
            #9 + '<SentExchange>' + BuildSentExchangeText(RxData) + '</SentExchange>' + sLineBreak +

      '</' + sRecType + '>'+ sLineBreak ;

      // Note for above oldcall and oldtimestamp. See message  https://groups.io/g/N1MMLoggerPlus/message/70623 why these fields
      // existed. This was for old consumers of UDP data that could not handle the GUID field. It has been 3 years since this was done.
      // As sending the old call and old timestamp is non-trivial, this program will not send th eidfference. It assumes the consumer of the UDP
      // records has updated their software to handle the ID field.
      // I left the fields here in case there is software that marked them reequired in the XML.
      // Tom NY4I 4 May 2025
end;


procedure LogContactToUDP(RXData: ContestExchange);
var
   sBuf: AnsiString;
begin

   udp.BroadcastEnabled := true;
   sBuf := BuildUDPContact(RXData, udpContactInfo);
   logger.Trace('Sending UDP Broadcast data: ' + sBuf);
   udp.Send(UDPBroadcastAddress,UDPBroadcastPortContact,sBuf);
end;

procedure LogEditedContactToUDP(RXData: ContestExchange);
var
   sBuf: AnsiString;
begin

   udp.BroadcastEnabled := true;
   sBuf := BuildUDPContact(RXData, udpContactReplace);
   logger.Trace('Sending UDP Broadcast data: ' + sBuf);
   udp.Send(UDPBroadcastAddress,UDPBroadcastPortContact,sBuf);
end;

procedure LookupInfoToUDP(RXData: ContestExchange);
var
   sBuf: AnsiString;
begin

   udp.BroadcastEnabled := true;
   sBuf := BuildUDPContact(RXData, udpLookupInfo);
   logger.Trace('Sending UDP Broadcast data: ' + sBuf);
   udp.Send(UDPBroadcastAddress,UDPBroadcastPortLookup,sBuf);
end;


// Issue #783 -- HamScore RTC: walk the binary log file and enqueue every
// good QSO via HamScoreOnLog so the server can rebuild its view from
// scratch.  Pairs with HamScoreResyncFromScratch which enqueues the
// <deletelog> separator first.  Mirrors SendFullLogToUDP's iteration
// pattern (same OpenLogFile / ReadLogFile / GoodLookingQSO trio).
procedure SendFullLogToHamScore;
var
  nCount: Integer;
begin
  nCount := 0;
  if not OpenLogFile then
    begin
    logger.Error('[SendFullLogToHamScore] Could not open log file');
    CloseHandle(tReportFileWrite);
    Exit;
    end;
  try
    ReadVersionBlock;
    while ReadLogFile do  // fills global TempRXData
      begin
      if GoodLookingQSO then
        begin
        Inc(nCount);
        HamScoreOnLog(TempRXData);
        end;
      end;
    CloseLogFile;
    Logger.Info('[SendFullLogToHamScore] Enqueued %d QSO(s) for RTC resync', [nCount]);
  except
    on E: Exception do
      Logger.Error('[SendFullLogToHamScore] %s', [E.Message]);
  end;
end;

procedure SendFullLogToUDP;
var nCount: integer;
   saveDecimalSeparator: char;
begin
   nCount := 0;
   if not OpenLogFile then
      begin
      logger.error('[SendFullLogToUDP] Could not open log file');
      CloseHandle(tReportFileWrite);
      Exit;
      end;

   saveDecimalSeparator := DecimalSeparator;
   try
      //DecimalSeparator := '.'; // Set this so we use . as reqired by ADIF and not localized separator ny4i

      ReadVersionBlock;
      while ReadLogFile do  // This reads the log into TempRXData global (bad design)
         begin
         if GoodLookingQSO then
            begin
            inc(nCount);
            logger.Debug('[SendFullLogToUDP] (%d) Read contact for callsign %s',[nCount,TempRXData.Callsign]);
            //SendDeletedContactToUDP(TempRXData);
            LogEditedContactToUDP(TempRXData);
            end
         else
            begin
            if TempRXData.ceQSO_Deleted  then
               begin
               logger.trace('[SendFullLogToUDP] Contact for %s not sent to UDP as it was DELETED',[TempRXData.Callsign]);
               end
            else
               begin
               logger.error('[SendFullLogToUDP] Was not valid GoodLookingQSO %s',[TempRXData.Callsign]);
               end;
            end;
         end;
      CloseLogFile;
      Logger.Info('%d records sent to UDP',[nCount]);
      Format(QuickDisplayBuffer, '%d log records sent to UDP', nCount);
      QuickDisplay(QuickDisplayBuffer);
   finally
      DecimalSeparator := SaveDecimalSeparator;
   end;
end;

function ConvertBandTypeToUDPContactBand(band: BandType): string;
begin
   if DecimalSeparator <> '.' then
      begin
      // Convert the . in BandTypeToUDPContactBand to the DecimalSeperator
      result := StringReplace(BandTypeToUDPContactBand[band],'.',DecimalSeparator,[rfReplaceAll]);
      end
   else
      begin
      result := BandTypeToUDPContactBand[band];
      end;

end;


end.
