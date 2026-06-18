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
unit uProcessCommand;

{$IMPORTEDDATA OFF}

interface

uses
  uMMTTY,
utils_text,
  VC,
  TF,
  uWinKey,
  uCFG,
  uTelnet,
  LogCfg,
  uNet,
  uIO,
  LOGSUBS1,
  LOGSUBS2,
  Windows,
  Tree,
  LogWind,
  LogRadio,
  uRadioPolling,
  MainUnit,
  LogEdit,
  LogCW,
  LogK1EA,
  CFGCMD,
  LogStuff,
  SysUtils;

type
  TsCommandsArrayType = packed record
    caCommand: PChar;
    caAddress: Pointer;
  end;

  type
  TsCWCharsArrayType = packed record
    CWChars: PChar;
    CWAddress: Pointer;
  end;
  
procedure scSRS;
procedure scSRSI;
procedure scSRS1;
procedure scSRS2;

procedure scWK_SWAPTUNE;
procedure scEXCHANGERADIOS;
procedure scWK_RESET;
procedure scSENDMESSAGE;
procedure scTOGGLECW;
procedure scBANDUP;
procedure scBANDDOWN;
procedure scCWMONITORON;
procedure scCWMONITOROFF;
procedure scWINEXEC;
procedure scDISABLECW;
//procedure CheckNumber;
procedure scENABLECW;
procedure scSAPMODE;
procedure scCQMODE;
procedure scCWENABLETOGGLE;
procedure scEXECUTE;
procedure scPlayMessageActive;
procedure scPlayMessageInActive;
procedure scRADIOONELPTMASK;
procedure scCABRILLO;
procedure scFLUSHINITIALEX;
procedure scSNLOCKOUT;
procedure scSNRELEASE;
procedure scLASTSPFREQ;
procedure scLASTCQFREQ;
procedure scLOGIN;
procedure scSENDTOCLUSTER;
procedure scDUPECHECK;
procedure scBOOLSWAP;

procedure csMMTTY_GRABLASTCALL;
procedure csMMTTY_SWITCH_TO_RX_IMMEDIATELY;
procedure csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED;
procedure csMMTTY_SWITCH_TO_TX;
procedure csMMTTY_CLEAR_THE_TX_BUFFER;

const



 // sCommands                             =  67  {$IF MMTYMODE} + 5  {$IFEND};
  sCommands                             =  72 + 2 + 1 + 5;  // Issue 61 Added OTRSP command + 5 display entries

  sCommandsArray                        : array[0..sCommands - 1] of TsCommandsArrayType =
    (

//{$IF MMTTYMODE}    //5
      (caCommand: 'MM_CLEAR_THE_TX_BUFFER'; caAddress: @csMMTTY_CLEAR_THE_TX_BUFFER),
      (caCommand: 'MM_SWITCH_TO_TX'; caAddress: @csMMTTY_SWITCH_TO_TX),
      (caCommand: 'MM_SWITCH_TO_RX_IMMEDIATELY'; caAddress: @csMMTTY_SWITCH_TO_RX_IMMEDIATELY),
      (caCommand: 'MM_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED'; caAddress: @csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED),
      (caCommand: 'MM_GRABLASTCALL'; caAddress: @csMMTTY_GRABLASTCALL),
//{$IFEND}

   //24
(caCommand: ' <01>   =  Send on other radio- focus d/n change';caaddress:@scexchangeradios),      // n4af 4.42.11
(caCommand: ' <02>   =  Send on other radio,switch radio if called';caaddress:@scexchangeradios), // n4af 4.42.11
(caCommand: ' <05>   =  Same as <02> but subsequent enter triggers cq on other radio';caaddress:@scexchangeradios), // n4af 4.42.11
(caCommand: '  # = QSO Number '; caAddress: @scEXCHANGERADIOS),     //n4af 04.33.2    DUMMY @ entries
(caCommand: '  @ = HisCall '; caAddress: @scEXCHANGERADIOS),          // really done by LOGSEND.PAS
(caCommand: '  $ = Salutation/Name '; caAddress: @scEXCHANGERADIOS),
(caCommand: '  % = Name from Names DB'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' : = Send from K.B.'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' ~ = Salutation - no name'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  \ = My Call'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' | = Name from Exch Window'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' [ = Wait for # (RST)'; caAddress: @scEXCHANGERADIOS),
(caCommand: ' ] = Repeat last RST from ['; caAddress: @scEXCHANGERADIOS),
(caCommand: '  ^ = Half space'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  CTRL-P CTRL-F = Faster'; caAddress: @scEXCHANGERADIOS),
(caCommand: '  CTRL-P CTRL-S = Slower'; caAddress: @scWK_SWAPTUNE),
(caCommand: ' + = Previous #'; caAddress: @scWK_RESET),       //4.53.2  // 4.71.5
(caCommand: '  > = Reset RIT'; caAddress: @scSENDMESSAGE),
(caCommand: ' < = SK'; caAddress: @scBOOLSWAP),
(caCommand: ' = = BT'; caAddress: @tClearDupesheet),
(caCommand: ' ! = SN'; caAddress: @tClearMultSheet),
(caCommand: ' & = AS'; caAddress: @scDUPECHECK),
// (caCommand: ' ) = Last QSOs Call'; caAddress: @scDUPECHECK),
(caCommand: ' , = Send GMT time'; caAddress: @scDUPECHECK),       // 4.56.5
(caCommand: ' .  = Repeat previous GMT time'; caAddress: @scDUPECHECK),       // 4.56.6
(caCommand: ' ALT-D = Dupe Check R2'; caAddress:  @CheckNumber),
(caCommand: ' CN = Check Entered Number'; caAddress:  @CheckNumber),    // n4af 4.42.2
  // (caCommand: 'CN' ; caAddress:  @CheckNumber),                      // n4af 4.42.2
    (caCommand: 'ALT-D'; caAddress: @scDupeCheck),
    (caCommand: 'WK_SWAPTUNE'; caAddress: @scWK_SWAPTUNE),
    (caCommand: 'WK_RESET'; caAddress: @scWK_RESET),
    (caCommand: 'NEXTBANDMAP'; caAddress: @NEXTBANDMAPENTRY),
 //   (caCommand: 'BMFIRST'; caAddress: @BMFIRST),
    (caCommand: 'SENDTOCLUSTER'; caAddress: @scSENDTOCLUSTER),
    (caCommand: 'LASTCQFREQ'; caAddress: @scLASTCQFREQ),
    (caCommand: 'LASTSPFREQ'; caAddress: @scLASTSPFREQ),
    (caCommand: 'LOGIN'; caAddress: @scLOGIN),     //ny4i 04.39.4
    (caCommand: 'ENTER'; caAddress: @ProcessReturn),
    (caCommand: 'ESCAPE'; caAddress: @Escape_proc),
    (caCommand: 'COMPLETECALL'; caAddress: @CompleteCallsign),
    (caCommand: 'SWAPRADIOS'; caAddress: @SwapRadios),
    (caCommand: 'TOGGLEMODES'; caAddress: @ToggleModes),
    (caCommand: 'TOGGLESTEREOPIN'; caAddress: @ToggleStereoPin),
    (caCommand: 'OTRSP'; caAddress: @OTRSPCommand),  // Issue 61 - OTRSP RX focus
    (caCommand: ' OTRSP=RX1    = Listen to Radio 1'; caAddress: @OTRSPCommand),
    (caCommand: ' OTRSP=RX2    = Listen to Radio 2'; caAddress: @OTRSPCommand),
    (caCommand: ' OTRSP=RXA    = Listen to active (TX) radio'; caAddress: @OTRSPCommand),
    (caCommand: ' OTRSP=RXI    = Listen to inactive radio'; caAddress: @OTRSPCommand),
    (caCommand: ' OTRSP=STEREO = Stereo (hear both radios)'; caAddress: @OTRSPCommand),
    (caCommand: 'TOGGLECW'; caAddress: @scTOGGLECW),
    (caCommand: 'BANDUP'; caAddress: @scBANDUP),
    (caCommand: 'BANDDOWN'; caAddress: @scBANDDOWN),
    (caCommand: 'CWMONITORON'; caAddress: @scCWMONITORON),
    (caCommand: 'CWMONITOROFF'; caAddress: @scCWMONITOROFF),
    (caCommand: 'WINEXEC'; caAddress: @scWINEXEC),
    (caCommand: 'DISABLECW'; caAddress: @scDISABLECW),
    (caCommand: 'ENABLECW'; caAddress: @scENABLECW),
    (caCommand: 'EXCHANGERADIOS'; caAddress: @scEXCHANGERADIOS),
    (caCommand: 'SAPMODE'; caAddress: @scSAPMODE),
    (caCommand: 'CQMODE'; caAddress: @scCQMODE),
    (caCommand: 'CONTROLENTER'; caAddress: @tr4w_log_qso_without_cw),
    (caCommand: 'CWENABLETOGGLE'; caAddress: @scCWENABLETOGGLE),
    (caCommand: 'EXECUTE'; caAddress: @scEXECUTE),
    (caCommand: 'CABRILLO'; caAddress: @scCABRILLO),
    (caCommand: 'INITIALIZEQSO'; caAddress: @InitializeQSO),
    (caCommand: 'AUTOCQ'; caAddress: @RunAutoCQ),
    (caCommand: 'SPACEBAR'; caAddress: @SpaceBarProc2),
    (caCommand: 'PLAYMESSAGE_ACTIVE'; caAddress: @scPlayMessageActive),
    (caCommand: 'PLAYMESSAGE_INACTIVE'; caAddress: @scPlayMessageInActive),
    (caCommand: 'SRS'; caAddress: @scSRS),
    (caCommand: 'SRSI'; caAddress: @scSRSI),
    (caCommand: 'SRS1'; caAddress: @scSRS1),
    (caCommand: 'SRS2'; caAddress: @scSRS2),
    (caCommand: 'RADIOONELPTMASK'; caAddress: @scRADIOONELPTMASK),
    (caCommand: 'FLUSHINITIALEX'; caAddress: @scFLUSHINITIALEX),
    (caCommand: 'SNLOCKOUT'; caAddress: @scSNLOCKOUT),
    (caCommand: 'CLEARDUPESHEET'; caAddress: @tClearDupeSheet)  ,
    (caCommand: 'CLEARMULTSHEET'; caAddress: @tClearMultSheet)
    )
    ;

function FoundCommand(var SendString: Str160): boolean;

var
  scFileName                            : ShortString;
implementation

function FoundCommand(var SendString: Str160): boolean;

var
  CommandString                         : ShortString;
  TempInt, Result1                      : integer;
  i                                     : integer;
  p                                     : Pointer;
  cmdProc                               : procedure;   // Issue #997: typed call of a Pointer command handler
begin
  FoundCommand := False;

  CommandUseInactiveRadio := False;

  while StringHas(SendString, ControlC) do
  begin
    if not StringHas(SendString, ControlD) then Exit;

    FoundCommand := StringHas(SendString, ControlD);

    CommandString := {UpperCase}(BracketedString(SendString, ControlC, ControlD));
    Delete(SendString, pos(ControlC, SendString), pos(ControlD, SendString) - pos(ControlC, SendString) + 1);

    if Copy(CommandString, 1, 1) = ControlA then {KK1L: 6.73 Vector commands to inactive radio with CTRL-A}
    begin
      CommandUseInactiveRadio := True;
      Delete(CommandString, 1, 1);
    end;

    if StringHas(CommandString, '=') then
    begin
      scFileName := PostcedingString(CommandString, '=');
      CommandString := PrecedingString(CommandString, '=');
    end;

    CommandString[Ord(CommandString[0]) + 1] := #0;
    scFileName[length(scFileName) + 1] := #0;
   
    for i := 0 to sCommands - 1 do
    begin
      if StrComp(sCommandsArray[i].caCommand, @CommandString[1]) = 0 then
      begin
        // Issue #997: asm `call p` (untyped Pointer command handler,
        // parameterless) -> typed call, guarded against a nil entry in the
        // command-table (sCommandsArray) definition.
        @cmdProc := sCommandsArray[i].caAddress;
        if Assigned(cmdProc) then
           cmdProc;

        // Issue #997: asm wsprintf-push -> TF.Format.
        Format(QuickDisplayBuffer, '"%s" command is executed.', PChar(sCommandsArray[i].caCommand));
        QuickDisplay(QuickDisplayBuffer);

        Break;

      end;
    end;

      if ClearDupeSheetCommandGiven then
      begin
         tClearDupesheet;
      
              //        MoveEditableLogIntoLogFile;
              //        UpdateTotals2;
              //        Sheet.ClearDupeSheet;
      end;

    if CommandString = 'QSY' then CWMessageCommand := CWCommandQSY;

    if Copy(CommandString, 1, 5) = 'SPEED' then
    begin
      Delete(CommandString, 1, 5);

      if StringIsAllNumbers(CommandString) then
      begin
        Val(CommandString, TempInt, Result1);
        SetSpeed(TempInt);
        DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
      end
      else
      begin
        while Copy(CommandString, 1, 1) = '+' do
        begin
          Delete(CommandString, 1, 1);

          if CodeSpeed < 99 then
          begin
            SetSpeed(CodeSpeed + 1);
            DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
          end;
        end;

        while Copy(CommandString, 1, 1) = '-' do
        begin
          Delete(CommandString, 1, 1);

          if CodeSpeed > 1 then
          begin
            SetSpeed(CodeSpeed - 1);
            DisplayCodeSpeed {(CodeSpeed, CWEnabled, DVPOn, ActiveMode)};
          end;
        end;
      end;
    end;
  end;

  CommandUseInactiveRadio := False; {KK1L: 6.73 Put back to normal so other calls default to active radio}
end;

procedure scTOGGLECW;
begin
  ToggleCW(False);
end;

procedure scBANDUP;
begin
  ProcessMenu(menu_alt_bandup);
end;

procedure scBANDDOWN;
begin
  ProcessMenu(menu_alt_banddown);
end;

procedure scCWMONITORON;
begin
  if OldCWTone = 0 then OldCWTone := 700;
  CWTone := OldCWTone;
  AddStringToBuffer('', CWTone);
end;

procedure scCWMONITOROFF;
begin
  if CWTone <> 0 then
  begin
    OldCWTone := CWTone;
    CWTone := 0;
    AddStringToBuffer('', CWTone);
  end;
end;

procedure scWINEXEC;
begin
   logger.Info('[scWINEXEC] Calling WinExec with %s',[scFileName]);
   if Windows.WinExec(@scFileName[1], SW_SHOWMINIMIZED) < 31 then
      begin
      ShowSysErrorMessage('WINEXEC');
      end;
end;

procedure scDISABLECW;
begin
   SetCWState(False, False); // both flags + flush/PTT + display, no Alt-K prompt (command, not key)
end;

procedure scENABLECW;
begin
   SetCWState(True, False); // both flags + display, no Alt-K prompt (command, not key)
end;

procedure scSAPMODE;
begin
  SetOpMode(SearchAndPounceOpMode);
end;

procedure scCQMODE;
begin
  SetOpMode(CQOpMode);
end;

procedure scCWENABLETOGGLE;
begin
  //CWEnable := not CWEnable;  // Going to try and call ToggleCW
  ToggleCW(false); // no display as this was a command.
end;

procedure scEXECUTE;

begin
  ExecuteConfigurationFile(scFileName);
{
  RunningConfigFile := True;
  ClearDupeSheetCommandGiven := False;
  FirstCommand := False;
  if FileExists(@scFileName[1]) then
    LoadInSeparateConfigFile(scFileName, FirstCommand, MyCall);
  if ClearDupeSheetCommandGiven then tClearDupesheet;
  RunningConfigFile := False;
  }
end;

procedure scSRS;
begin
   if ActiveRadioPtr.tNetObject <> nil then
      begin
      ActiveRadioPtr.tNetObject.SendToRadio(scFileName);
      end
   else if ActiveRadioPtr.RadioModel in [IC78..IC9700, OMNI6] then
      begin
//    ActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName;
//    ActiveRadioPtr.CommandsTempBuffer
      Windows.CopyMemory(@ActiveRadioPtr.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
      ActiveRadioPtr.CommandsTempBuffer[0] := CHR(length(scFileName));
      ActiveRadioPtr.AddCommandToBuffer;
      end
   else
//    WriteToSerialCATPort(scFileName, ActiveRadioPtr.tCATPortHandle);
      ActiveRadioPtr.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRSI;
begin
  if InActiveRadioPtr.tNetObject <> nil then
    begin
    InActiveRadioPtr.tNetObject.SendToRadio(scFileName);
    end
  else if InActiveRadioPtr.RadioModel in [IC78..IC9700, OMNI6] then
    begin
    Windows.CopyMemory(@InActiveRadioPtr.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    InActiveRadioPtr.CommandsTempBuffer[0] := CHR(length(scFileName));
    InActiveRadioPtr.AddCommandToBuffer;
    end
//    InActiveRadioPtr.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, InActiveRadioPtr.tCATPortHandle);
    InActiveRadioPtr.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRS1;
begin
  if Radio1.tNetObject <> nil then
    begin
    Radio1.tNetObject.SendToRadio(scFileName);
    end
  else if Radio1.RadioModel in [IC78..IC9700, OMNI6] then
  begin
    Windows.CopyMemory(@Radio1.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    Radio1.CommandsTempBuffer[0] := CHR(length(scFileName));
    Radio1.AddCommandToBuffer;
  end
//    Radio1.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, Radio1.tCATPortHandle);
    Radio1.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scSRS2;
begin
  if Radio2.tNetObject <> nil then
    begin
    Radio2.tNetObject.SendToRadio(scFileName);
    end
  else if Radio2.RadioModel in [IC78..IC9700, OMNI6] then
  begin
    Windows.CopyMemory(@Radio2.CommandsTempBuffer[1], @scFileName[1], length(scFileName));
    Radio2.CommandsTempBuffer[0] := CHR(length(scFileName));
    Radio2.AddCommandToBuffer;
  end
//    Radio2.ICOM_COMMAND_CUSTOM := scFileName
  else
//    WriteToSerialCATPort(scFileName, Radio2.tCATPortHandle);
    Radio2.WriteToCATPort(scFileName[1], length(scFileName));
end;

procedure scPlayMessageActive;
var bError: boolean;
   // nMemoryNum: integer;
begin
   if ActiveRadioPtr.tNetObject <> nil then
      begin
      if StrToIntDef(scFileName,-1) <> -1 then
         begin
         bError := ActiveRadioPtr.tNetObject.MemoryKeyer(StrToInt(scFileName));
         end
      else
         begin
         bError := true;
         logger.Error('Command to PlayMessageActive must be a memory number (%s)',[scFileName]);
         end;
      if bError then
         begin
         QuickDisplay('Error playing voice memory');
         end;
      end
   else
      begin
      if StrToIntDef(scFileName,-1) <> -1 then
         begin
         bError := ActiveRadioPtr.MemoryKeyer(StrToInt(scFileName));
         end
      else
         begin
         logger.Error('Command to PlayMessageActive must be a memory number (%s)',[scFileName]);
         bError := true;
         end;

      if bError then
         begin
         QuickDisplay('Error playing voice memory');
         end;
      end;
end;

procedure scPlayMessageInActive;
var bError: boolean;
   // nMemoryNum: integer;
begin
   if InActiveRadioPtr.tNetObject <> nil then
      begin
      if StrToIntDef(scFileName,-1) <> -1 then
         begin
         bError := InActiveRadioPtr.tNetObject.MemoryKeyer(StrToInt(scFileName));
         end
      else
         begin
         bError := true;
         logger.Error('Command to PlayMessageInActive must be a memory number (%s)',[scFileName]);
         end;
      if bError then
         begin
         QuickDisplay('Error playing voice memory');
         end;
      end
   else
      begin
      if StrToIntDef(scFileName,-1) <> -1 then
         begin
         bError := InActiveRadioPtr.MemoryKeyer(StrToInt(scFileName));
         end
      else
         begin
         logger.Error('Command to PlayMessageInActive must be a memory number (%s)',[scFileName]);
         bError := true;
         end;

      if bError then
         begin
         QuickDisplay('Error playing voice memory');
         end;
      end;
end;


procedure scRADIOONELPTMASK;
var
  TempByte                              : Byte;
  r                                     : integer;
begin
  if Radio1.tPTTStatus = PTT_ON then Exit;
  if not DriverIsLoaded() then Exit;
  if not (Radio1.tKeyerPort in [Parallel1, Parallel2, Parallel3]) then Exit;
  Val(scFileName, TempByte, r);
  if r <> 0 then Exit;
  SetPortByte(Radio1.tKeyerPortHandle, otData, TempByte);
end;

procedure scCABRILLO;
begin
  ProcessMenu(menu_cabrillo);
end;

procedure scFLUSHINITIALEX;
begin
  GenerateCallsignsList(TR4W_INITIALEX_FILENAME);
  QuickDisplay('FLUSHINITIALEX command is executed.');
end;

procedure scSNLOCKOUT;
begin
  SendSerialNumberChange(sntReserved);
end;

procedure scSNRELEASE;
begin
  SendSerialNumberChange(sntFree);
end;

procedure scLASTSPFREQ;
begin
  if LastSPFrequency = 0 then Exit;
  SetRadioFreq(ActiveRadio, LastSPFrequency, LastSPMode, 'A');
  SetOpMode(SearchAndPounceOpMode);
end;

procedure scLASTCQFREQ;
begin
  if LastCQFrequency = 0 then Exit;
  SetRadioFreq(ActiveRadio, LastCQFrequency, LastCQMode, 'A');
  tCleareCallWindow;
  SetOpMode(CQOpMode);
end;

procedure scLOGIN;
begin
  ProcessMenu(menu_login);
end;

procedure scSENDTOCLUSTER;
begin
  uTelnet.SendViaTelnetSocket(@scFileName[1]);
end;
{
procedure CheckNumber;
begin
if StringIsAllNumbers(CallWindowString) then
          if  CallsignsList.FindNumber(CallWindowString) then
      PutCallToCallWindow(CallWindowString);

   end;
 }
procedure scDUPECHECK;
begin
  DupeCheckOnInactiveRadio(False);
end;

procedure scBOOLSWAP;
var
  i                                     : integer;
  p                                     : Pointer;
  cmdProc                               : procedure;   // Issue #997: typed call of a Pointer change-handler
begin
  for i := 1 to CommandsArraySize do
    if StrComp(@scFileName[1], CFGCA[i].crCommand) = 0 then
      if CFGCA[i].crType = ctBoolean then
      begin
        PBoolean(CFGCA[i].crAddress)^ := not PBoolean(CFGCA[i].crAddress)^;
        if CFGCA[i].crP <> 0 then
        begin
          // Issue #997: asm `call P` (untyped Pointer change-handler) -> typed
          // call, guarded against a nil entry in the CommandsProcArray definition.
          @cmdProc := CommandsProcArray[CFGCA[i].crP];
          if Assigned(cmdProc) then
             cmdProc;
          Format(QuickDisplayBuffer, '%s=%s', @scFileName[1], BA[PBoolean(CFGCA[i].crAddress)^]);
          QuickDisplay(QuickDisplayBuffer);
        end;
        Break;
      end;
end;

procedure scWK_RESET;
begin
  wkSendAdminCommand(wkRESET);
end;

procedure scSENDMESSAGE;
begin
  if scFileName <> '' then
  begin
    NetIntercomMessage.imSender := ComputerID;
    Windows.ZeroMemory(@NetIntercomMessage.imMessage, SizeOf(NetIntercomMessage.imMessage));
    NetIntercomMessage.imMessage := scFileName;
    SendToNet(NetIntercomMessage, SizeOf(NetIntercomMessage));
    Exit;
  end;
  ProcessMenu(menu_send_message);
end;

procedure scWK_SWAPTUNE;
begin
  if wkSendTwoBytes($0B, Byte(not wkTune)) = 2 then
    TF.InvertBoolean(wkTune);
end;

procedure scEXCHANGERADIOS;

var
//  R1VFO                                 : VFOStatusType;
//  R2VFO                                 : VFOStatusType;

  R1REC                                 : RadioStatusRecord;
  R2REC                                 : RadioStatusRecord;
const

  VFPLETTERARRAY                        : array[ActiveVFOStatusType] of Char = ('A', 'A', 'B', 'A');
begin
{
  if Radio1.FilteredStatus.VFO[VFOA].Frequency = 0 then Exit;
  if Radio2.FilteredStatus.VFO[VFOA].Frequency = 0 then Exit;

  Windows.CopyMemory(@R2VFO, @Radio1.FilteredStatus.VFO[VFOA], SizeOf(VFOStatusType));
  Windows.CopyMemory(@R1VFO, @Radio2.FilteredStatus.VFO[VFOA], SizeOf(VFOStatusType));

  Radio1.SetRadioFreq(R1VFO.Frequency, R1VFO.Mode, 'A');
  Radio2.SetRadioFreq(R2VFO.Frequency, R2VFO.Mode, 'A');
}
  logger.Debug('Entering scExchangeRadios');
  if Radio1.FilteredStatus.Freq = 0 then Exit;
  if Radio2.FilteredStatus.Freq = 0 then Exit;

  Windows.CopyMemory(@R2REC, @Radio1.FilteredStatus, SizeOf(RadioStatusRecord));
  Windows.CopyMemory(@R1REC, @Radio2.FilteredStatus, SizeOf(RadioStatusRecord));

  Radio1.SetRadioFreq(R1REC.Freq, R1REC.Mode, 'A'{VFPLETTERARRAY[Radio1.FilteredStatus.VFOStatus]});
  Radio2.SetRadioFreq(R2REC.Freq, R2REC.Mode, 'A'{VFPLETTERARRAY[Radio2.FilteredStatus.VFOStatus]});

  logger.Debug('Exiting scExchangeRadios');
end;

procedure csMMTTY_GRABLASTCALL;
begin
{$IF MMTTYMODE}
  PutCallToCallWindow(MMTTY.mmttyLastCallsign);
  if tAutoCQMode and (length(MMTTY.mmttyLastCallsign) > 0) then      // wli issue 84 4.70.6
    if TryKillAutoCQ then Escape_proc;
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_RX_IMMEDIATELY;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_IMMEDIATELY);
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_RX_AFTER_THE_TRANSMISSION_IS_COMPLETED);
{$IFEND}
end;

procedure csMMTTY_SWITCH_TO_TX;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_SWITCH_TO_TX);
{$IFEND}
end;

procedure csMMTTY_CLEAR_THE_TX_BUFFER;
begin
{$IF MMTTYMODE}
  PostMmttyMessage(RXM_PTT, RXM_PTT_CLEAR_THE_TX_BUFFER);
{$IFEND}
end;

end.
