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
unit LOGSUBS1;
{$IMPORTEDDATA OFF}
interface

uses
  uNet,
  uWinKey,
  uYCCCSO2R,
  uMixW,
  uMMTTY,
  VC,
  uCallSignRoutines,
  utils_text,
  uTelnet,
  BeepUnit,
  Windows,
  //Country9,
  FCONTEST,
  CFGCMD,
  uTotal,
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
  LOGWAE,
  LogWind,
  {Printer,}
  {Crt,
  SlowTree,}
  Tree,
  ZoneCont
  ;

procedure RememberFrequency;
procedure PutUpExchangeMenu;
procedure SendFunctionKeyMessage(Key: Char; OpMode: OpModeType);
procedure CheckTwoRadioState(Action: TwoRadioAction);
function SendCrypticMessage(Message: Str160): boolean;
procedure SendCorrectCallIfNeeded;
function Send73Message: boolean;
procedure AddOnCQExchange;
procedure SwapRadios;

implementation

uses
  uRadioPolling,
  LOGSUBS2,
  MainUnit;

procedure PutUpExchangeMenu;

{ This routine will put up the exchange menu.  This menu is displayed
  during the time the exchange is being entered and edited.  The exchange
  window is normally underneath this menu.                               }

begin
  // IF ExchangeFunctionKeyMenu = '' THEN
  //  RemoveWindow (FunctionKeyWindow)
  // ELSE
  begin
    //        SaveSetAndClearActiveWindow (FunctionKeyWindow);
    //        Write (ExchangeFunctionKeyMenu);
    //        RestorePreviousWindow;
  end;
end;

procedure CheckForRemovedDupeSheetWindow;

begin
  if VisibleDupeSheetRemoved then
  begin
    //    RemoveWindow(BigWindow);
//    VisibleLog.SetUpEditableLog;
    UpdateTotals2;
    VisibleLog.ShowRemainingMultipliers;
    VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);

    //         if VisibleDupesheetEnable then
//      CallsignsList.Display(ActiveBand, ActiveMode);
  end;

  VisibleDupeSheetRemoved := False;
end;

function SendCrypticMessage(Message: Str160): boolean;

var

  TempChar: Char;
label
  DontCheckPTT;

begin // 1
  Result := False;
  if FoundCommand(Message) and (Message = '') then
    Exit;
  if (ActiveMode in [Phone, FM]) and (DVKEnable = False) then
    goto DontCheckPTT;
  if (ActiveMode = CW) and (CWEnable = False) then
    goto DontCheckPTT;

  if CheckPTTLockout then
    Exit;

  DontCheckPTT:

  Result := True;
  InactiveRigCallingCQ := False;
  tWaitForNextChar := True;

  if (Copy(Message,1,3) = 'E E') then
   TryLogContact;

  if not (Copy(Message, 1, 1) = ControlA) then
  begin // I think we want to make sure we swap radios once. I tried caling SwapRadios here but it got called again.
      SetUpToSendOnActiveRadio;
  end;

  // n4af 4.41.3

  while (Copy(Message, 1, 1) = ControlA) or (Copy(Message, 1, 1) = ControlB) or
    (Copy(Message, 1, 1) = ControlE) do
  begin // 2
    TempChar := Message[1];

    if TempChar = ControlA then
      if TwoRadioMode then
      begin // 3
        if ActiveRadio = RadioOne then
        begin // 4
          if not SendingOnRadioTwo then
            ActiveMode := Radio2.ModeMemory;
        end // 3
        else {// Radio Two} if not SendingOnRadioOne then
            ActiveMode := Radio1.ModeMemory;

        SetUpToSendOnInactiveRadio;

        //    Sleep(5); // Added to get rid of relay flicking on old radio
      end; // 2

    if TempChar = ControlB then
      if TwoRadioMode then      
      begin
       SetUpToSendOnInactiveRadio;
       if autosendenable then
          CallWindowKeyUpProc; // n4af 4.44.2
        InactiveRigCallingCQ := True;
        InactiveSwapRadio := True;
        if ExchangeWindowString = '' then // 4.52.1
          Switch := True;
          SwitchNext := True; // 4.52.3
      end;

          Delete(Message, 1, 1);
  end; // 1
  //ny4i to fix issue #9

  if pos('>', Message) > 0 then
  begin // 2
    if ActiveMode <> Digital then
    begin // 3
      RITClear;
      Delete(Message, pos('>', Message), 1);
    end // 2
    else
      SendMessageToMixW(Message);

  end; // 1

  case ActiveMode of
    FM, Phone:
      begin
        if DVKEnable then
          SendCrypticDVPString(Message)
        else
          //               if ActiveDVKPort <> NoPort then
  //               SendDVKMessage(Message);
      end;

    CW:
      begin
        // 'ctrl-=' repeat-last-CW-message: bracket the send so AddStringToBuffer
        // records the actual expanded characters as LastCWMessage.
        BeginCWCapture;
        SendCrypticCWstring(Message);
        EndCWCapture;
      end;
{$IF MMTTYMODE}
    Digital:
      begin
        SendCrypticCWString(Message);
        //        ProcessMMTTYMessage(TXM_CHAR, 10);

      end;
{$IFEND}

    //wli    Digital: SendCrypticDigitalString(message);
  end;
  tWaitForNextChar := False;
end;

procedure SendFunctionKeyMessage(Key: Char; OpMode: OpModeType);

var

  QSONumberString: Str20;
  MessageKey: Char;
  Message: Str160;
  IncrementCounter: boolean;

  TempMode: ModeType;
begin


  begin
    SwitchNext := False;
    Switch := False;
    MessageKey := Key;

    //wli      if (ActiveMode = Phone) and (DVPEnable or (ActiveDVKPort <> NoPort)) then
    //wli         if (Key >= ControlF1) and (Key <= ControlF10) then MessageKey := CHR(Ord(Key) - 35);

    TempMode := ActiveMode;
    if ActiveMode = FM then
      TempMode := Phone;
    Switch := False; // n4af 4.44.7
    if OpMode = CQOpMode then
      Message := GetCQMemoryString(TempMode, MessageKey) {KK1L: 6.73 Added mode}
    else
      Message := GetEXMemoryString(TempMode, MessageKey); {KK1L: 6.73 Added mode}

    //{WLI}           FoundCommand (Message);

    if Message = '' then
      Exit; { Nothing left }
    {
        if (ActiveMode = Phone) and DVPEnable and DVPMessagePlaying then
        begin
          TimeOut := 0;

            //      DVPStopPlayback;

            //      repeat
            //        Wait(5);
            //        inc(TimeOut);
            //      until (not DVPMessagePlaying) or (TimeOut > 30);
        end;
    }
    InactiveRigCallingCQ := False;
    //    SetUpToSendOnActiveRadio;

    if ActiveMode = CW then
    begin
      //  Esc_Counter := 0; // 4.53.7 reset if function key pressed
      DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};

      if AllCWMessagesChainable then
      begin
        if CWStillBeingSent then
          AddStringToBuffer(' ', CWTone);
      end
      else if pos(ControlD, Message) = 0 then
      begin
        //          wkWaitForChainablemessage := True;
        if not (IsCWByCATActive and
          (ActiveRadioPtr^.RadioModel in ICOMRadios)) then
        begin
          FlushCWBuffer; // ny4i Issue 145 - Don;t dothis for Icom radios. It messes up the times of CW Messages
        end;
      end;
    end;

    IncrementCounter := SendCrypticMessage(Message);

    if (OpMode = CQOpMode) and (Key >= F1) and (Key <= F4) then
    begin

      if IncrementCounter then
        if Key = F1 then
        begin
          inc(tRestartInfo.riCQTotalCounter);
          tDisplayCQTotal;
        end;

      //     if BandMapEnable and BandMapDisplayCQ then  //n4af 4.46.3
      begin
        if ActiveRadioPtr^.LastDisplayedFreq <> 0 then
        begin
          Str(NextSerialToSend, QSONumberString);  // Issue #954
          //   BandMapCursorFrequency := ActiveRadioPtr^.LastDisplayedFreq;      // GAV Removed, not required
          tCreateAndAddNewSpot('CQ/ ' + QSONumberString, False, ActiveRadioPtr);
          LastCQFrequency := ActiveRadioPtr^.LastDisplayedFreq;
          LastCQMode := ActiveMode;
        end;

        {
        if ActiveRadio = RadioOne then
        begin
          if Radio1.LastDisplayedFreq <> 0 then
          begin
            Str(TotalContacts + 1, QSONumberString);
            BandMapCursorFrequency := Radio1.LastDisplayedFreq;
            tCreateAndAddNewSpot('CQ/ ' + QSONumberString, False, @Radio1);
            LastCQFrequency := Radio1.LastDisplayedFreq;
            LastCQMode := ActiveMode;
          end;
        end

        else // Radio two
          if Radio2.LastDisplayedFreq <> 0 then
          begin
            Str(TotalContacts + 1, QSONumberString);
            BandMapCursorFrequency := Frequency;
            tCreateAndAddNewSpot('CQ/ ' + QSONumberString, False, @Radio2);
            LastCQFrequency := Radio2.LastDisplayedFreq
              LastCQMode := ActiveMode;
          end;
           }
      end;

      //        if (ActiveMultiPort <> NoPort) and          ((MultiInfoMessage <> '') or K1EANetworkEnable) then          CreateAndSendCQMultiInfoMessage;
    end;
  end;
end;

procedure AddOnCQExchange;

var
  Name: Str20;
  StationSpeed: integer;

begin
  if K5KA.ModeEnabled then
    K5KA.State := KAMessageStarted;

  if ActiveMode in [Phone, FM] then
  begin
    if (CQPhoneExchangeNameKnown <> '') and SayHiEnable then
    begin
      Name := UpperCase(CD.GetName(RootCall(CallsignICameBackTo)));

      if (Name = '') or (Name = 'CLUB') then
        //        SendCrypticMessage(CQPhoneExchangeNameKnown)
        SendCrypticMessage(CQPhoneExchange)
      else
        //        SendCrypticMessage(CQPhoneExchange);
        SendCrypticMessage(CQPhoneExchangeNameKnown);
    end
    else
      SendCrypticMessage(CQPhoneExchange);
  end
  else
  begin
    if CWSpeedFromDataBase then
    begin
      StationSpeed := CD.GetCodeSpeed(RootCall(CallsignICameBackTo));

      if StationSpeed > 0 then
      begin
        RememberCWSpeed := CodeSpeed;
        SetSpeed(StationSpeed);
        DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
      end;
    end;

    if (CQExchangeNameKnown <> '') and SayHiEnable then
    begin
      Name := UpperCase(CD.GetName(RootCall(CallsignICameBackTo)));
      if (Name = '') or (Name = 'CLUB') then
        SendCrypticMessage(CQExchange)
          //Additional_CW_Message.ADD_Message:=CQExchange
      else
        SendCrypticMessage(CQExchangeNameKnown);
      //Additional_CW_Message.ADD_Message:=CQExchangeNameKnown;
    end
    else
    begin
      SendCrypticMessage(CQExchange);
      //Additional_CW_Message.ADD_Message:=CQExchange;
    end;

    //   ClearPTTForceOn;
  end;

  tExchangeWindowSetFocus;
  ExchangeHasBeenSent := True;
  if ActiveMode = Digital then
    SendMessageToMixW('<RXANDCLEAR>');

  SendSerialNumberChange(sntReserved);
end;

function Send73Message: boolean;
var
  s: string[20];
begin
  Result := True;
  s := '';
  if ReceivedData.Callsign <> CallsignICameBackTo then
  begin

    if ActiveMode in [Phone, FM] then
      s := CorrectedCallPhoneMessage + ' '
    else
      s := CorrectedCallMessage;
    //    CallsignICameBackTo := ReceivedData.Callsign;
  end;

  if SeventyThreeMessageSent or not MessageEnable then
    Exit;
  if BeSilent then
    Exit;

  //    if ActiveMode = Digital then SendMessageToMixW('<TX>');
  if AutoQSLCount > 0 then
  begin
    dec(AutoQSLCount);
    if AutoQSLCount = 0 then
    begin
      if ActiveMode in [Phone, FM] then
        Result := SendCrypticMessage(s + QSLPhoneMessage)
      else
        Result := SendCrypticMessage(s + QSLMessage);
      AutoQSLCount := AutoQSLInterval;
    end
    else
    begin
      if ActiveMode in [Phone, FM] then
        Result := SendCrypticMessage(s + QuickQSLPhoneMessage)
      else
        Result := SendCrypticMessage(s + QuickQSLMessage1);

    end
  end
  else

  begin
    if ActiveMode in [Phone, FM] then
      Result := SendCrypticMessage(s + QSLPhoneMessage)
    else
      if OnDeckCall <> '' then
       Result := SendCrypticMessage(s + QuickQSLMessage1)
        else
         Result := SendCrypticMessage(s + QSLMessage);
  end;

  //    if ActiveMode = Digital then SendMessageToMixW('<RXANDCLEAR>');

  SeventyThreeMessageSent := Result;
end;

procedure SendCorrectCallIfNeeded;

begin
  if (ReceivedData.Callsign <> CallsignICameBackTo) and not BeSilent then
  begin
    if MessageEnable then
      SendCrypticMessage(CorrectedCallMessage);

    CallsignICameBackTo := ReceivedData.Callsign;
  end;

  { Does this really ever work? }
{
  if StringHas(CallWindowString, ',') then
    begin
      TailEndCallString := PostcedingString(CallWindowString, ',');
      TailEnding := True;
      AddStringToBuffer(TailEndMessage + ' ' + TailEndCallString, CWTone);
    end;
}
end;

procedure SwapRadios;

begin
  DebugMsg('>>>>Entering SWAPRADIOS');
  if not TwoRadioMode then
  begin
    QuickDisplay(TC_ALTRCOMMANDDISABLED);
    //      Wait(3000); {KK1L: 6.71}
    Exit;
  end;

  TryKillAutoCQ;
  if ActiveMode = CW then
    FlushCWBufferAndClearPTT;

  //  LastDisplayedFreq[RadioOne] := 0; {KK1L: 6.73 Forces new display for highlight}
  //  LastDisplayedFreq[RadioTwo] := 0; {KK1L: 6.73 Forces new display for highlight}
  if IsCWByCATActive(InActiveRadioptr) then
    // ny4i Issue 145 - Noticed this so I fixed it. IsCWByCATActive checks if radioObject CWBYCAT is set plus if the radio model is capable of CWByCAT.
  begin
    ActiveRadioPtr^.StopSendingCW; // n4af 4.45.9
  end;
  // if InActiveRadioptr^.CWByCAT then ActiveRadioPtr^.StopSendingCW;
  InactiveRigCallingCQ := False;

  if ActiveRadio = RadioOne then
  begin
    Windows.EnableWindow(wh[mweRadioOne], False);
    Windows.EnableWindow(Radio1.FreqWindowHandle, False);
    Windows.EnableWindow(wh[mweRadioTwo], True);
    Windows.EnableWindow(Radio2.FreqWindowHandle, True);
    ActiveRadioPtr := @Radio2;
    InActiveRadioPtr := @Radio1;
    ActiveBand := Radio2.BandMemory {BandMemory[RadioTwo]};
    ActiveMode := Radio2.ModeMemory {ModeMemory[RadioTwo]};
    //   ActiveKeyerPort := Radio2.tKeyerPort;
    //   tActiveKeyerHandle := Radio2.tKeyerPortHandle;
    SerialInvert := Radio2SerialInvert;
    ActiveRadio := RadioTwo;
    InactiveRadio := RadioOne;
    CodeSpeed := Radio2.SpeedMemory;
    //SetSpeed(CodeSpeed); // ny4i Issue 153 This is done in SetUpToSendOnActiveRadio so no need to do it here.
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end
  else
  begin
    Windows.EnableWindow(wh[mweRadioOne], True);
    Windows.EnableWindow(Radio1.FreqWindowHandle, True);
    Windows.EnableWindow(wh[mweRadioTwo], False);
    Windows.EnableWindow(Radio2.FreqWindowHandle, False);
    ActiveRadioPtr := @Radio1;
    InActiveRadioPtr := @Radio2;
    ActiveBand := Radio1.BandMemory {BandMemory[RadioOne]};
    ActiveMode := Radio1.ModeMemory {ModeMemory[RadioOne]};
    SerialInvert := Radio1SerialInvert;
    ActiveRadio := RadioOne;
    InactiveRadio := RadioTwo; {KK1L: 6.73}
    CodeSpeed := Radio1.SpeedMemory; {KK1L: 6.73}
    DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
  end;

//  ClearRadioStatus(ActiveRadioPtr); //n4af 4.71.3
  ShowInformation; // n4af 04.40.02

  SetUpToSendOnActiveRadio; // 4.62.1  issue 278 remove 4.54.2 comment on this line
  DisplayRadio(ActiveRadio);
  DisplayBandMode(ActiveBand, ActiveMode, False);
  UpdateTotals2;
  if Radio1.tRadioInterfaceWndHandle <> 0 then
    InvalidateRect(Radio1.tRadioInterfaceWndHandle, nil, True);
  if Radio2.tRadioInterfaceWndHandle <> 0 then
    InvalidateRect(Radio2.tRadioInterfaceWndHandle, nil, True);

  wkSetKeyerOutput(ActiveRadioPtr);
  if ycccActive then
     YCCCSetActiveRadio(Integer(ActiveRadio)); { RadioOne=1, RadioTwo=2 }

  if QSONumberByBand then
    DisplayNextQSONumber;

  if MultByBand then
  begin
    VisibleLog.ShowRemainingMultipliers;
    VisibleLog.DisplayGridMap(ActiveBand, ActiveMode);
  end;

  BandMapBand := ActiveBand;
  BandMapMode := ActiveMode;
  VisibleDupeSheetChanged := True;
  ShowInformation; // n4af 4.40.2
  ActiveRadioPtr.active := true;
  InactiveRadioPtr.active := false;
  DebugMsg('<<<<Exiting  SWAPRADIOS');
end;

procedure ExchangeRadios; {KK1L: 6.71}
{KK1L: 6.71 This proc exchanges the band/mode/freq of the radios keeping the same one active }
{ The original purpose was to make it easy to find a new run freq on the second radio }
{ (presumably not on the best antenna system) and swap it to the primary antenna setup.}

begin

  { Needs to be put back }
end;



procedure RememberFrequency;

var
  Band: BandType;
  Mode: ModeType;
begin
  CalculateBandMode(ActiveRadioPtr.FilteredStatus.Freq, Band, Mode);
  Mode := ActiveMode;
  if (Band = ActiveBand) and (Mode in [CW..Phone]) then
    FreqMemory[ActiveBand, ActiveMode] := ActiveRadioPtr.FilteredStatus.Freq;

end;

procedure CheckTwoRadioState(Action: TwoRadioAction);

var
//  Key: Char;
  TimeOut: Byte;

begin
  if not TwoRadioMode then
  begin
    TwoRadioState := TwoRadiosDisabled;
    Exit;
  end;

  case TwoRadioState of

    Idle:
      if Action = CallPutUp then
      begin
        TwoRadioState := CallReady;
        ExchangeHasBeenSent := False;
      end;

    // There is a callsign displayed and if someone presses the space
    // bar, we want to call that station NOW!

    CallReady:
      case Action of
        SpaceBarPressed:
          begin
            {kk1l                   IF (ActiveMode = CW) AND CWStillBeingSent THEN
                                    FlushCWBufferAndClearPTT;
            }

            if (OpMode = CQOpMode) then //KK1L: 6.73
              CalledFromCQMode := True
            else
              CalledFromCQMode := False;
                // KK1L: 6.73 NOTE TRUE disables special called from SAPMode

            SwapRadios; // Changes active band/mode and display

            //InactiveRigCallingCQ := False;

            if ActiveMode = CW then
            begin
              if DEEnable then
                SendStringAndStop(DEPlusMyCall)
              else
                SendStringAndStop(MyCall);
            end
            else if ActiveMode = Digital then
              SendStringAndStop(CallWindowString + ' DE ' + MyCall + ' KK ')
            else if DVKEnable then
            begin
              SendCrypticMessage('MYCALL.WAV');
            end
            else if ActiveDVKPort <> NoPort then
              SendDVKMessage(GetEXMemoryString(ActiveMode, F1));
                //KK1L: 6.73 Added mode to GetEXMemoryString

            TwoRadioState := StationCalled;

            //                     If during the time we are calling an ESCAPE key
            //                      is pressed, we will abort sending MyCall on the
            //                      inactive radio and go back to CQing on the Active
            //                      Radio

            //KK1L: 6.71 Added DoingDVK so DVKDelay is used too!
            if DVKEnable or (ActiveMode = CW) or (ActiveDVKPort <> NoPort) then
            begin

                //Now launch a CQ on the "inactive" rig (which was
                //the one we were CQing on.

                //KK1L: 6.73 Added CalledFromCQMode
                //KK1L: 6.73 Added mode to GetCQMemoryString
              if (GetCQMemoryString(InActiveRadioPtr.ModeMemory, AltF3) <> '')
                and (CalledFromCQMode) then
              begin
                {KK1L: 6.73 Added mode to GetCQMemoryString}
                SendCrypticMessage(ControlA +
                  GetCQMemoryString(InActiveRadioPtr.ModeMemory, AltF3));

                //                            IF DVPEnable AND (ActiveMode = Phone) AND DVPActive THEN
                //                            KK1L: 6.73 Need to check mode of the inactive radio!!
                if DVKEnable and (InActiveRadioPtr.ModeMemory = Phone) and
                  DVPActive then
                begin
  //                TimeOut := 0;

                end;
              end;

            end;

            Exit;
          end;
      end;

    //We have called a station on the second rig.  We were sending a CQ
    //on the inactive radio using the ControlA feature which means that
    //InactiveRigSendingCW is TRUE.

    StationCalled:
      case Action of
        SpaceBarPressed, // Need to call the station again
        F1Pressed:
          begin
            InactiveRigCallingCQ := False;

            if ActiveMode = CW then
            begin

              if (ActiveMode = CW) and DEEnable then
                SendStringAndStop(DEPlusMyCall)
              else
                SendStringAndStop(MyCall);
            end
            else
            begin
              if DVKEnable and DVPMessagePlaying then
              begin
                TimeOut := 0;

                DVPStopPlayback;

                repeat
                  Sleep(5);
                  inc(TimeOut);
                until (not DVPMessagePlaying) or (TimeOut > 50);
              end;

              if DVKEnable then
              begin
                SendCrypticMessage('MYCALL.WAV');

//                TimeOut := 0;

              end;

              if ActiveDVKPort <> NoPort then
                //SendDVKMessage (GetEXMemoryString (F2)); //KK1L: 6.71 removed
//KK1L: 6.73 Added mode to GetEXMemoryString
                SendDVKMessage(GetEXMemoryString(ActiveMode, F1));
                  //KK1L: 6.71 added to be consistent!

            end;

            //KK1L: 6.71 Added DoingDVK so DVKDelay is used too!
            if (ActiveMode = CW) or DVKEnable or (ActiveDVKPort <> NoPort) then
            begin

              if (GetCQMemoryString(InActiveRadioPtr.ModeMemory, AltF3) <> '')
                and (CalledFromCQMode) then
              begin

                SendCrypticMessage(ControlA +
                  GetCQMemoryString(InActiveRadioPtr.ModeMemory, AltF3));

                if (ActiveMode = Phone) and DVPActive then
                begin
                  TimeOut := 0;

                  repeat
                    Sleep(5);
                    inc(TimeOut)
                  until DVPMessagePlaying or (TimeOut > 30);
                end;
              end;
            end;

            Exit;
          end;

        F2Pressed:
          begin
            if ActiveMode = CW then
              if ExchangeHasBeenSent and (RepeatSearchAndPounceExchange <> '')
                then
                SendCrypticMessage(RepeatSearchAndPounceExchange)
              else
                SendCrypticMessage(SearchAndPounceExchange)
            else if ExchangeHasBeenSent and (RepeatSearchAndPouncePhoneExchange
              <> '') then
              SendCrypticMessage(RepeatSearchAndPouncePhoneExchange)
            else
              SendCrypticMessage(SearchAndPouncePhoneExchange);

            ExchangeHasBeenSent := True;
            TwoRadioState := SendingExchange;
          end;

        ReturnPressed:
          begin
            if not (ExchangeHasBeenSent or BeSilent) then
            begin
              SetUpToSendOnInactiveRadio;

              if ActiveMode = CW then
                SendCrypticMessage(SearchAndPounceExchange)
              else
                SendCrypticMessage(SearchAndPouncePhoneExchange);
            end;

            ExchangeHasBeenSent := True;
            TwoRadioState := SendingExchange;
          end;

        EscapePressed:
          begin
            SwapRadios;

            TwoRadioState := CallReady;
          end;

        FootSwitchWasPressed:
          SetUpToSendOnActiveRadio;
      end;

    SendingExchange:
      if Action = ContactDone then
      begin
        K5KA.AltDString := '';

        if ActiveMode = Phone then
          Sleep(50);

        SwapRadios;
        SetOpMode(CQOpMode);
        if (ControlBMemory = '') and (OnDeckCall = '') and (CalledFromCQMode)
          then
          SendCrypticMessage(GetCQMemoryString(ActiveMode, F1));

        if DVKEnable and (ActiveMode = Phone) and DVPActive then
        begin
//          TimeOut := 0;

        end;

        TwoRadioState := Idle;
      end;
  end;

end;

procedure SetupPacketSpot(Address: integer; Radio: RadioType);

{ This procedure will look in the packet memory at the indicated address
  and set the CallWindowString to the proper callsign, set the active
  radio to the proper radio with the proper band and mode, and show
  the QSO and multiplier status for the station, and display the beam
  heading.  It is up to whoever calls this to make sure the state
  of the program is ready to accept this data.    }

var
  QSXFrequency, PacketFrequency: LONGINT;

begin
  PacketFrequency := Packet.PacketMemory[Address].Frequency;
  QSXFrequency := Packet.PacketMemory[Address].QSXFrequency;

  CalculateBandMode(PacketFrequency, ActiveBand, ActiveMode);


  if Radio <> ActiveRadio then
    SwapRadios
  else
  begin
    DisplayBandMode(ActiveBand, ActiveMode, False);
    UpdateTotals2;
  end;

  if QSXFrequency <> 0 then
  begin
    {KK1L: 6.71 moved ahead of PutRadioIntoSplit because for TS850 need to make B active to change mode}
    SetRadioFreq(ActiveRadio, QSXFrequency, ActiveMode, 'B');
    PutRadioIntoSplit(ActiveRadio);
  end
  else {KK1L: 6.64 Takes radio out of split if not needed for spot}
  begin
    PutRadioOutOfSplit(ActiveRadio);
  end;

  SetRadioFreq(Radio, PacketFrequency, ActiveMode, 'A');
    {KK1L: 6.71 Moved here from before IF for TS850 change}

  CallWindowString := Packet.PacketMemory[Address].Call;

  VisibleLog.ShowQSOStatus(@CallWindowString);
  VisibleLog.ShowMultiplierStatus(@CallWindowString);
  DisplayBeamHeading(CallWindowString, '');
end;

procedure DisplayPacketSpots(HighLightedSpot: integer);

var
  PacketAddress, Spot: integer;

begin
  //{WLI}    TextColor (ActiveColor);
  //{WLI}    TextBackground (ActiveBackground);

  //{WLI}    ClrScr;

  for Spot := 1 to 10 do
  begin

    PacketAddress := Packet.PacketMemoryStart + Spot - 1;

    if PacketAddress > 10 then
      PacketAddress := PacketAddress - 11;

    if PacketAddress = Packet.PacketMemoryEnd then
      Exit;

    //{WLI}        GoToXY (((Spot - 1) DIV 5) * 40 + 1, (Spot - 1) MOD 5 + 1);

    if Spot = HighLightedSpot then
    begin
      //{WLI}            TextColor (ActiveBackground);
      //{WLI}            TextBackground (ActiveColor);
    end
    else
    begin
      //{WLI}            TextColor (ActiveColor);
      //{WLI}            TextBackground (ActiveBackground);
    end;

    Write(Packet.PacketMemory[PacketAddress].Time, '  ',
      Packet.PacketMemory[PacketAddress].Frequency / 1000: 7: 1, '  ',
      Packet.PacketMemory[PacketAddress].Call);

    if Packet.PacketMemory[PacketAddress].QSXFrequency <> 0 then
      Write(' QSX ', Packet.PacketMemory[PacketAddress].QSXFrequency / 1000: 7:
        1);

    //    NoCursor;
  end;

  QuickDisplay('Select spot.  RETURN, left or right arrow to select.  ESCAPE to exit.');
end;

procedure SetUpRadioFromPacketSpot(Radio: RadioType;
  PacketAddress: integer;
  Spot: integer);

begin
  //  RestorePreviousWindow;
//  VisibleLog.SetUpEditableLog;
  //  RemoveWindow(QuickCommandWindow);
  //  BigCursor;

  PacketAddress := Packet.PacketMemoryStart + Spot - 1;

  if PacketAddress > 10 then
    PacketAddress := PacketAddress - 11;

  if Packet.PacketMemoryEnd > Packet.PacketMemoryStart then
  begin
    if (PacketAddress >= Packet.PacketMemoryStart) and
      (PacketAddress < Packet.PacketMemoryEnd) then
      SetupPacketSpot(PacketAddress, Radio)
  end
  else if (PacketAddress >= Packet.PacketMemoryStart) or
    (PacketAddress < Packet.PacketMemoryEnd) then
    SetupPacketSpot(PacketAddress, Radio);
end;

function PacketMemoryRequest: boolean;

{ Gets called when a Control-U is done.  Returns TRUE if spot selected.
  Spot address number is put into Global variable PacketAddress.     }

var
  Key: Char;
  PacketAddress, NumberSpots: integer;
  Spot: integer;
//  Frequency: REAL;

begin
  PacketMemoryRequest := False;

  //   if (Packet.PacketSerialPort = NoPort) and (ActiveMultiPort = NoPort) then      Exit;

  if Packet.PacketMemoryStart = Packet.PacketMemoryEnd then
    Exit;

  //  SaveSetAndClearActiveWindow(EditableLogWindow);
   //{WLI}    ClrScr;

  Spot := 1;

  if Packet.PacketMemoryEnd < Packet.PacketMemoryStart then
    NumberSpots := (Packet.PacketMemoryEnd + 11) - Packet.PacketMemoryStart
  else
    NumberSpots := Packet.PacketMemoryEnd - Packet.PacketMemoryStart;

  repeat
    DisplayPacketSpots(Spot);

    //{WLI}        REPEAT UNTIL KeyPressed;
    //{WLI}        Key := ReadKey;

    case Key of
      TabKey:
        if (Spot > 5) then
          Spot := Spot - 5
        else
          Spot := Spot + 5;

      EscapeKey:
        begin
          //          RestorePreviousWindow;
//          VisibleLog.SetUpEditableLog;
          //          RemoveWindow(QuickCommandWindow);
          //          BigCursor;
          Exit;
        end;

      CarriageReturn:
        begin
          PacketMemoryRequest := True;
          //          RestorePreviousWindow;
//          VisibleLog.SetUpEditableLog;
          //          RemoveWindow(QuickCommandWindow);
          //          BigCursor;

          PacketAddress := Packet.PacketMemoryStart + Spot - 1;

          if PacketAddress > 10 then
            PacketAddress := PacketAddress - 11;

          if Packet.PacketMemoryEnd > Packet.PacketMemoryStart then
          begin
            if (PacketAddress >= Packet.PacketMemoryStart) and
              (PacketAddress < Packet.PacketMemoryEnd) then
              SetupPacketSpot(PacketAddress, ActiveRadio)
          end
          else if (PacketAddress >= Packet.PacketMemoryStart) or
            (PacketAddress < Packet.PacketMemoryEnd) then
            SetupPacketSpot(PacketAddress, ActiveRadio);

          Exit;
        end;

      NullKey:
        begin
          //{WLI}                Key := ReadKey;

          case Key of
            UpArrow:
              if (Spot <> 1) and (Spot <> 6) then
                dec(Spot);

            DownArrow:
              if (Spot <> 5) and (Spot <> 10) then
                if Spot < NumberSpots then
                  inc(Spot);

            LeftArrow:
              begin
                if SwapPacketSpotRadios then
                begin
                  if Radio1.tCATPortType <> NoPort then
                  begin
                    SetUpRadioFromPacketSpot(RadioOne, PacketAddress, Spot);
                    PacketMemoryRequest := True;
                    Exit;
                  end;
                end
                else if Radio2.tCATPortType <> NoPort then
                begin
                  PacketMemoryRequest := True;
                  SetUpRadioFromPacketSpot(RadioTwo, PacketAddress, Spot);
                  Exit;
                end;

                if Spot > 5 then
                  Spot := Spot - 5;
              end;

            RightArrow:
              begin
                if SwapPacketSpotRadios then
                begin
                  if Radio2.tCATPortType <> NoPort then
                  begin
                    SetUpRadioFromPacketSpot(RadioTwo, PacketAddress, Spot);
                    PacketMemoryRequest := True;
                    Exit;
                  end;
                end
                else if Radio1.tCATPortType <> NoPort then
                begin
                  PacketMemoryRequest := True;
                  SetUpRadioFromPacketSpot(RadioOne, PacketAddress, Spot);
                  Exit;
                end;

                if Spot <= NumberSpots - 5 then
                  if (Spot < 6) then
                    Spot := Spot + 5;
              end;
          end;
        end;
    end;
  until False;
end;

procedure DualingCQs;

begin
  if not TwoRadioMode then
    Exit;

  {KK1L: 6.73 Added mode to GetCQMemoryString}
  if GetCQMemoryString(ActiveMode, AltF1) = '' then
  begin
    QuickDisplay(TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1);
    Exit;
  end;

  SwapRadios;

  repeat
    SendFunctionKeyMessage(AltF1, CQOpMode);

    //{WLI}        REPEAT
    //{WLI}            UpdateTimeAndRateDisplays (True, True);
    //{WLI}            Packet.CheckPacket;
    //{WLI}        UNTIL (KeyPressed) OR NOT CWStillBeingSent;


    SwapRadios;
  until False;
end;

end.
