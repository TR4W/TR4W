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
unit uRadioPolling;
{$IMPORTEDDATA OFF}
interface

uses
   //FmtBcd,
   LogDupe,
   VC,
   TF,
   uSpots,
   uNet,
   Tree,
   LogRadio,
   LogEdit,
   uDupeSheet, // 4.53.7
   uFunctionKeys,
   utils_file,
   MainUnit,
   Messages,
   SysUtils,
   LogWind,
   LogStuff,
   LogK1EA,
   idUDPClient, // ny4i 4.44.9
   idGlobal, // ny4i 4.44.9
   Windows,
   StrUtils,
   Math,
   DateUtils,
   uNetRadioBase,
   uRadioElecraftK4,
   uRadioHamLibDirect;

type
   DebugFileMessagetype = (dfmTX, dfmRX, dfmError);

function ReadFromSerialPort(BytesToRead: Cardinal; rig: RadioPtr): boolean;
function ReadFromCOMPort(b: Cardinal; rig: RadioPtr): boolean;
function ReadFromCOMPortRaw(b: Cardinal; rig: RadioPtr): boolean;
procedure SetSerialRadioAlertState(rig: RadioPtr; alertOn: boolean);
procedure MarkSerialRead(rig: RadioPtr; success: boolean);
procedure pNetworkRadio(rig: RadioPtr);
procedure pKenwood2(rig: RadioPtr);
procedure pKenwoodNew(rig: RadioPtr);
procedure pFT990_FT1000(rig: RadioPtr);
procedure pFT747GX(rig: RadioPtr);
procedure pFT840_FT890_FT900(rig: RadioPtr);
procedure pFT920(rig: RadioPtr);
procedure pFT767(rig: RadioPtr);
procedure pFT736R(rig: RadioPtr);
procedure pFT817_FT847_FT857_FT897(rig: RadioPtr);
procedure pFT1000MP(rig: RadioPtr);
procedure pFT100(rig: RadioPtr);
function ArrayToString(const a: array of Char): string;

procedure pIcom(rig: RadioPtr);
procedure pIcomNew(rig: RadioPtr);
function icomCheckBuffer(rig: RadioPtr): boolean;
procedure SetVFOModeExtendedMode(rig: RadioPtr; which: Cardinal; mode: ModeType;
   em: ExtendedModeType);

procedure pFTDX9000(rig: RadioPtr);
procedure pFTDX10_FTDX101(rig: RadioPtr);
procedure pFTX1F(rig: RadioPtr);
procedure pFT891_FT991(rig: RadioPtr);
procedure pOrion(rig: RadioPtr);
procedure pOrion3(rig: RadioPtr);
//procedure pOrionNew(rig: RadioPtr);

procedure UpdateStatus(rig: RadioPtr);
procedure ClearRadioStatus(rig: RadioPtr);

procedure WriteToDebugFile(port: PortType; MessageType: DebugFileMessagetype; p:
   PChar; Count: Cardinal);
//function WriteToSerialCATPort(data: Str80; port: HWND): Cardinal;
function GetFrequencyForYaesu3(p: PChar): Cardinal;
function GetFrequencyForYaesu4(p: PChar): Cardinal;
function GetFrequencyFromBCD(Count: Cardinal; Addr: PChar): Cardinal;
function GetFrequencyForYaesuFT747(a: PChar): Cardinal;
procedure GetVFOInfoForYaesuType3(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
procedure GetVFOInfoForYaesuType5(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
procedure GetVFOInfoForYaesuFTX1(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
procedure BeginPolling(rig: RadioPtr); stdcall;
procedure SetDCBForIcom(port: HWND);
function ReadICOM(b: Cardinal; rig: RadioPtr): boolean;

procedure DisplayCurrentStatus(rig: RadioPtr);
procedure ProcessFilteredStatus(rig: RadioPtr);
function BufferToInt(buf: PChar; StartPos, EndPos: integer): integer;
procedure GetVFOInfoForFT2000(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
procedure SetVFOA(rig: RadioPtr);
procedure SetVFOB(rig: RadioPtr);
function getIcomResponceSpeed(rig: RadioPtr): boolean;
procedure PTTStatusChanged;
procedure SendRadioInfoToUDP(rig: RadioPtr);
var
   saveVFOAFreq: integer;
   dtLastUDPRadio: TDateTime;
const
   POLLINGDEBUG = False;
   ICOM_DEBUG = False;

implementation

procedure pKenwood2(rig: RadioPtr);
//label
//   NextWait;

type
   tKenwoodCommands = (kcIF, kcFA, kcFB);
var
   PollNumber: tKenwoodCommands;
   stat: TComStat;
   Errs: DWORD;
   BytesInBuffer: integer;
   BufferNotChanged: integer;
   RadioWaitTime: integer;
   RadioTimeoutTime: integer;
   RadioWaitLoops: integer;
   NumberOfSucceffulPolls: integer;
   i: integer;
   TempCommand: tKenwoodCommands;
const
   KenwoodPollRequests: array[tKenwoodCommands] of PChar = ('IF;', 'FA;',
      'FB;');
   KenwoodPollRequestsAnswerLength: array[tKenwoodCommands] of integer = (38,
      14, 14);
begin
   if rig.RadioModel in [K3,KX3,K4] then
      begin
         SetK3ExtendedCommandMode;
      end;

    // set up the parmeaters for how long we wait for the radio
   RadioWaitTime := FreqPollRate; // How often we check for bytes Set to 10
   RadioTimeoutTime := 1000; // sets the max timeout time for radio
   RadioWaitLoops := RadioTimeoutTime Div RadioWaitTime; // how may loops to make

   repeat
      if rig^.PollingStopRequested then Exit;

      inc(rig^.tPollCount);

      NumberOfSucceffulPolls := 0;

      for PollNumber := Low(tKenwoodCommands) to High(tKenwoodCommands) do
         begin

            if PollNumber in [kcFA, kcFB] then
               begin
                  if rig^.CurrentStatus.VFOStatus = VFOA then
                     if PollNumber = kcFA then
                        Continue;
                  if rig^.CurrentStatus.VFOStatus = VFOB then
                     if PollNumber = kcFB then
                        Continue;

                  if rig^.tPollCount mod 10 <> 0 then
                     Continue;
               end;

            Sleep(FreqPollRate);

            rig.WritePollRequest(KenwoodPollRequests[PollNumber]^, 3);
            BytesInBuffer := 0;
            BufferNotChanged := 0;

            // Take in bytes from the radio until either we get the number of
            // bytes expected or until we time out.
            // Normally check for new bytes every 10 ms and timeout in 1000 ms.
            // refactored 12/11/2020 Dan-K0TI

            while BufferNotChanged < RadioWaitLoops do
              begin
                if rig^.PollingStopRequested then Exit;
                Sleep(RadioWaitTime);  // wait a little for some bytes
                ClearCommError(rig^.tCATPortHandle, Errs, @stat);
                if stat.cbInQue > BytesInBuffer then
                  begin
                    BytesInBuffer := stat.cbInQue;
                    if BytesInBuffer = KenwoodPollRequestsAnswerLength[PollNumber] then
                      begin
                         // log the time it took to get here
                         logger.trace('Max wait time (ms) -' + inttostr(BufferNotChanged * RadioWaitTime));
                         // found the correct byte count, go process
                         break;
                      end;
                  end
                else
                  begin
                    // still not enough bytes, try again
                    inc(BufferNotChanged);
                  end;
              end;
            if BufferNotChanged >= RadioWaitLoops then // we timed out, log it
              begin
                logger.warn('Radio Timeout 1000ms');
                logger.warn('Buffer Bytes -' + inttostr(BytesInBuffer));
              end;

            // Serial liveness indicator: bytes received => the radio answered;
            // none within the timeout => after the grace period, mark it lost.
            MarkSerialRead(rig, BytesInBuffer > 0);

            if BytesInBuffer > 0 then
               begin
                  inc(NumberOfSucceffulPolls);

                  ReadFromSerialPort(BytesInBuffer, rig);
                  if logger.IsTraceEnabled then
                     logger.trace('Read from Kenwood2 ' + rig.tBuf);
                  for i := 1 to BytesInBuffer - 1 + 1 do
                     if rig.tBuf[i] = ';' then
                        begin

                           for TempCommand := Low(tKenwoodCommands) to
                              High(tKenwoodCommands) do
                              if i >=
                                 KenwoodPollRequestsAnswerLength[TempCommand] then
                                 if rig.tBuf[i -
                                    KenwoodPollRequestsAnswerLength[TempCommand] +
                                    2] =
                                    KenwoodPollRequests[TempCommand][1] then
                                    //                  asm nop end;

                                    begin
                                       case TempCommand of
                                          kcFA:
                                             begin
                                                logger.trace('polling: FA %s',
                                                   [AnsiLeftStr(rig^.tBuf, 40)]);
                                                rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf[i - 13], 3, 11);
                                             end;
                                          kcFB:
                                             begin
                                                logger.trace('polling: FB %s',
                                                   [AnsiLeftStr(rig^.tBuf, 40)]);
                                                rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf[i - 13], 3, 11);
                                             end;

                                          kcIF:
                                             begin
                                                logger.trace('polling IF %s',
                                                   [AnsiLeftStr(rig^.tBuf, 40)]);
                                                rig^.CurrentStatus.Freq :=
                                                   BufferToInt(@rig^.tBuf[i - 37],
                                                   3, 11);
                                                CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);

                                                case rig^.tBuf[i - 8] of
                                                   '1':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eLSB;
                                                         rig^.CurrentStatus.Mode
                                                            := Phone;
                                                      end;
                                                   '2':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eUSB;
                                                         rig^.CurrentStatus.Mode
                                                            := Phone;
                                                      end;
                                                   '3':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eCW;
                                                         rig^.CurrentStatus.Mode
                                                            := CW;
                                                      end;
                                                   '4':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eFM;
                                                         rig^.CurrentStatus.Mode
                                                            := FM;
                                                      end;
                                                   '5':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eAM;
                                                         rig^.CurrentStatus.Mode
                                                            := Phone;
                                                      end;
                                                   '6':
                                                      begin
                                                         if rig^.RadioModel in
                                                            [K3, KX3,K4] then
                                                            begin
                                                               case rig^.tBuf[i
                                                                  - 3] of
                                                                  '0':
                                                                     rig^.CurrentStatus.ExtendedMode := eDATA; 
                                                                  '1':
                                                                     rig^.CurrentStatus.ExtendedMode := eRTTY;
                                                                  '2':
                                                                     rig^.CurrentStatus.ExtendedMode := eRTTY;
                                                                  '3':
                                                                     rig^.CurrentStatus.ExtendedMode := ePSK31;
                                                                  else
                                                                     begin
                                                                        logger.info('Unknown value from K3/K4 ExtendedMode response' + rig^.tBuf);
                                                                     end;
                                                               end;
                                                            end
                                                         else
                                                            begin
                                                               rig^.CurrentStatus.ExtendedMode := eRTTY;
                                                            end;
                                                         rig^.CurrentStatus.Mode
                                                            := Digital;
                                                      end;
                                                   '7':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eCW_R;
                                                         rig^.CurrentStatus.Mode
                                                            := CW;
                                                      end;
                                                   '8':
                                                      begin
                                                         rig^.CurrentStatus.Mode
                                                            := CW;
                                                         rig^.CurrentStatus.ExtendedMode := eCW_R;
                                                      end;
                                                   '9':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eRTTY_R;
                                                         rig^.CurrentStatus.Mode
                                                            := Digital;
                                                      end;
                                                   'A':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eDATA;
                                                         rig^.CurrentStatus.Mode
                                                            := Digital;
                                                      end;
                                                   'B':
                                                      begin
                                                         rig^.CurrentStatus.ExtendedMode := eDATA_R;
                                                         rig^.CurrentStatus.Mode
                                                            := Digital;
                                                      end;
                                                   else
                                                      begin
                                                         logger.info('Invalid mode received from KenwoodNew ' + rig^.tBuf[30]);
                                                      end;
                                                end;

                                                if rig^.tBuf[i - 7] = '0' then
                                                   begin
                                                      //            debugmsg('polling IF ' + inttostr(rig^.CurrentStatus.Freq));
                                                      rig^.CurrentStatus.VFO[VFOA].Frequency := rig^.CurrentStatus.Freq;
                                                      //        ActiveVFO_is_A := True;
                                                      rig^.CurrentStatus.VFOStatus := VFOA;
                                                   end
                                                else
                                                   begin
                                                      rig^.CurrentStatus.VFO[VFOB].Frequency := rig^.CurrentStatus.Freq;
                                                      //        ActiveVFO_is_A := False;
                                                      rig^.CurrentStatus.VFOStatus := VFOB;
                                                   end;

                                                //      rig^.CurrentStatus.Freq := rig^.CurrentStatus.Freq + rig^.FrequencyAdder;
                                                rig^.CurrentStatus.RITFreq :=
                                                   BufferToInt(@rig^.tBuf[i - 37],
                                                   19, 5);
                                                rig^.CurrentStatus.Split :=
                                                   rig^.tBuf[i - 5] <> '0';
                                                rig^.CurrentStatus.RIT :=
                                                   rig^.tBuf[i - 14] = '1';
                                                rig^.CurrentStatus.XIT :=
                                                   rig^.tBuf[i - 13] = '1';

                                                rig^.CurrentStatus.TXOn :=
                                                   rig^.tBuf[i - 9] = '1';
                                                if rig^.tBuf[i - 9] = '1' then
                                                   begin
                                                      logger.trace('K3/KX3/K4/Kenwood2 says radio is transmitting');
                                                   end
                                                else
                                                   begin
                                                      logger.trace('K3/KX3/K4/Kenwood2 says radio is RECEIVING');
                                                   end;
                                             end;
                                       end;
                                    end;

                        end;
                  Windows.ZeroMemory(@rig.tBuf, 128);

               end;
         end;

      if NumberOfSucceffulPolls = 0 then
         begin
            ClearRadioStatus(rig);
            Sleep(500);
         end;

      UpdateStatus(rig);
   until rig^.tPollCount < 0;
end;

procedure pOrion3(rig: RadioPtr);
label
   1, NextWait;
var
   //  TempMode                              : ModeType;
   PollNumber: integer;
   stat: TComStat;
   Errs: DWORD;
   BytesInBuffer: integer;
   BufferNotChanged: integer;
   NumberOfSucceffulPolls: integer;
   i: integer;
const
   PollsCount = 4;
   OrionPollRequests: array[0..PollsCount - 1] of PChar = ('?AF'#13, '?BF'#13,
      '?KV'#13, '?RMM'#13);
   OrionPollRequestsLength: array[0..PollsCount - 1] of integer = (4, 4, 4, 5);
   //  OrionPollRequestsAnswerLength         : array[0..PollsCount - 1] of integer = (12, 12, 7, 6);
begin
   repeat
      inc(rig^.tPollCount);

      if rig.tOrionFreq[0] <> #0 then
         begin
            rig.WriteBufferToCATPort(rig.tOrionFreq);
            Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
            Sleep(200);
         end;

      if rig.tOrionMode[0] <> #0 then
         begin
            rig.WriteBufferToCATPort(rig.tOrionMode);
            Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
            Sleep(200);
         end;

      NumberOfSucceffulPolls := 0;

      for PollNumber := 0 to PollsCount - 1 do
         begin
            rig.WritePollRequest(OrionPollRequests[PollNumber]^,
               OrionPollRequestsLength[PollNumber]);
            BytesInBuffer := 0;
            BufferNotChanged := 0;

            NextWait:
            Sleep(20 {n5aw} {OrionWaitTime});
            ClearCommError(rig^.tCATPortHandle, Errs, @stat);
            if stat.cbInQue > BytesInBuffer then
               begin
                  BytesInBuffer := stat.cbInQue;
                  goto NextWait;
               end
            else
               begin
                  inc(BufferNotChanged);
                  if BufferNotChanged < 3 then
                     goto NextWait;
               end;

            if BytesInBuffer > 0 then
               begin
                  inc(NumberOfSucceffulPolls);

                  ReadFromSerialPort(BytesInBuffer, rig);

                  for i := 1 to BytesInBuffer - 1 do
                     if rig.tBuf[i] = '@' then
                        begin
                           case rig.tBuf[i + 1] of
                              'A':
                                 begin
                                    if rig.tBuf[i + 11] = #13 then
                                       rig^.CurrentStatus.VFO[VFOA].Frequency :=
                                          BufferToInt(@rig^.tBuf[i], 4, 8);
                                 end;
                              'B':
                                 begin
                                    if rig.tBuf[i + 11] = #13 then
                                       rig^.CurrentStatus.VFO[VFOB].Frequency :=
                                          BufferToInt(@rig^.tBuf[i], 4, 8);
                                 end;
                              'K':
                                 if rig.tBuf[i + 6] = #13 then
                                    begin
                                       if rig.tBuf[i + 3] = 'A' then
                                          begin
                                             rig^.CurrentStatus.Freq :=
                                                rig^.CurrentStatus.VFO[VFOA].Frequency;
                                             rig^.CurrentStatus.VFOStatus :=
                                                VFOA;
                                          end
                                       else
                                          begin
                                             rig^.CurrentStatus.Freq :=
                                                rig^.CurrentStatus.VFO[VFOB].Frequency;
                                             rig^.CurrentStatus.VFOStatus :=
                                                VFOB;
                                          end;
                                    end;
                              'R':
                                 if rig.tBuf[i + 5] = #13 then
                                    begin
                                       CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);
                                       case rig.tBuf[i + 4] of
                                          '0':
                                             begin
                                                rig^.CurrentStatus.Mode :=
                                                   Phone;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eUSB;
                                             end;
                                          '1':
                                             begin
                                                rig^.CurrentStatus.Mode :=
                                                   Phone;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eLSB;
                                             end;
                                          '2':
                                             begin
                                                rig^.CurrentStatus.Mode := CW;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eCW;
                                             end;
                                          '3':
                                             begin
                                                rig^.CurrentStatus.Mode := CW;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eCW_R;
                                             end;
                                          '4':
                                             begin
                                                rig^.CurrentStatus.Mode :=
                                                   Phone;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eAM;
                                             end;
                                          '5':
                                             begin
                                                rig^.CurrentStatus.Mode := FM;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eFM;
                                             end;
                                          '6':
                                             begin
                                                rig^.CurrentStatus.Mode :=
                                                   Digital;
                                                rig^.CurrentStatus.ExtendedMode
                                                   := eRTTY;
                                             end;
                                          else
                                             begin
                                                logger.Warn('Invalid mode character from Orion3 = ' + rig.tBuf[i + 4]);
                                             end;
                                       end;

                                    end;
                           end;
                        end;
                  Windows.ZeroMemory(@rig.tBuf, 64);

               end;
         end;

      if NumberOfSucceffulPolls = 0 then
         begin
            ClearRadioStatus(rig);
            Sleep(500);
         end;

      1:
      UpdateStatus(rig);
   until rig^.tPollCount < 0;
end;

procedure pOrion(rig: RadioPtr);
label
   1;
var
   TempMode: ModeType;
begin
   repeat
      inc(rig^.tPollCount);

      if rig.tOrionFreq[0] <> #0 then
         begin
            rig.WriteBufferToCATPort(rig.tOrionFreq);
            Windows.ZeroMemory(@rig.tOrionFreq, SizeOf(rig.tOrionFreq));
            Sleep(200);
         end;

      if rig.tOrionMode[0] <> #0 then
         begin
            rig.WriteBufferToCATPort(rig.tOrionMode);
            Windows.ZeroMemory(@rig.tOrionMode, SizeOf(rig.tOrionMode));
            Sleep(200);
         end;

      rig.WritePollRequest('?AF'#13, 4);
      if not ReadFromCOMPort(12, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      {?}
      if rig.tBuf[2] <> 'A' then
         begin
            Sleep(500);
            PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
            ClearRadioStatus(rig);
            goto 1;
         end;

      //    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@AF03526900');
      rig^.CurrentStatus.VFO[VFOA].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

      rig.WritePollRequest('?BF'#13, 4);
      if not ReadFromCOMPort(12, rig) or (rig.tBuf[2] <> 'B') then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      //    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@BF14173490');
      rig^.CurrentStatus.VFO[VFOB].Frequency := BufferToInt(@rig^.tBuf, 4, 8);

      rig.WritePollRequest('?KV'#13, 4);
      if not ReadFromCOMPort(7, rig) or (rig.tBuf[2] <> 'K') then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      //    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@KVAAA');

      if rig.tBuf[4] = 'A' then
         begin
            rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOA].Frequency;
            rig^.CurrentStatus.VFOStatus := VFOA;
         end
      else
         begin
            rig^.CurrentStatus.Freq := rig^.CurrentStatus.VFO[VFOB].Frequency;
            rig^.CurrentStatus.VFOStatus := VFOB;
         end;
      CalculateBandMode(rig^.CurrentStatus.Freq, rig^.CurrentStatus.Band,
         TempMode);

      rig.WritePollRequest('?RMM'#13, 5);
      if not ReadFromCOMPort(6, rig) or (rig.tBuf[2] <> 'R') then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      //    Windows.ZeroMemory(@rig^.tBuf, 512); Windows.lstrcat(@rig^.tBuf, '@RMM2');
      case rig.tBuf[5] of
         '0':
            begin
               rig^.CurrentStatus.Mode := Phone;
               rig^.CurrentStatus.ExtendedMode := eUSB;
            end;
         '1':
            begin
               rig^.CurrentStatus.Mode := Phone;
               rig^.CurrentStatus.ExtendedMode := eLSB;
            end;
         '2':
            begin
               rig^.CurrentStatus.Mode := CW;
               rig^.CurrentStatus.ExtendedMode := eCW;
            end;
         '3':
            begin
               rig^.CurrentStatus.Mode := CW;
               rig^.CurrentStatus.ExtendedMode := eCW_R;
            end;
         '4':
            begin
               rig^.CurrentStatus.Mode := Phone;
               rig^.CurrentStatus.ExtendedMode := eAM;
            end;
         '5':
            begin
               rig^.CurrentStatus.Mode := FM;
               rig^.CurrentStatus.ExtendedMode := eFM;
            end;
         '6':
            begin
               rig^.CurrentStatus.Mode := Digital;
               rig^.CurrentStatus.ExtendedMode := eRTTY;
            end;
         else
            begin
               logger.Warn('Invalid mode character from Orion = ' +
                  rig.tBuf[5]);
            end;
      end;

      1:
      UpdateStatus(rig);
   until rig^.tPollCount < 0;
end;

procedure pNetworkRadio(rig: RadioPtr); // Network classes (K4 network, Flex 6000 series network, etc)
var
   ro: TNetRadioBase;
   wasConnected: Boolean;
   loggedNoConnInfo: Boolean;   // Issue #968 -- log the "no IP/port" skip once, not every cycle
   reconnectDelay: Integer;
   sleepRemaining: Integer;
   lastPollTick: LongWord;
   lastHeartbeatTick: LongWord;
   lastRITXITTick: LongWord;
   authErrBuf: array[0..127] of Char;
   handshakeStuckSinceTick: LongWord;  // GetTickCount when we first noticed IsConnected but not IsOperational; 0 = not tracking
   actVFO: TVFO;                       // active (RX) VFO for the aggregate main-window status (ro.GetActiveVFO)
const
   RECONNECT_INITIAL_DELAY = 1000;    // 1 second initial delay
   RECONNECT_MAX_DELAY = 30000;       // 30 seconds max delay
   HANDSHAKE_STUCK_MS = 8000;         // Force a Disconnect+Connect cycle if the transport has been mid-handshake (IsConnected but not IsOperational) for this long.  Covers the "radio was off when Connect() fired, the initial AYH packet was lost, no further AYH retries are sent" failure mode -- without this the polling thread spins forever in the connected branch sending CI-V commands that fail with "stream not open".

   // SetRadioAlertState � set or clear RadioDisconnected flag and repaint freq/name
   // windows only on a state transition (guarded by current flag value).
   procedure SetRadioAlertState(alertOn: boolean);
   begin
      if alertOn = rig^.RadioDisconnected then
         Exit;   // No change � do not call InvalidateRect unnecessarily
      rig^.RadioDisconnected := alertOn;
      if alertOn then
         logger.Info('[pNetworkRadio] %s � alert color ON', [rig^.RadioName])
      else
         logger.Info('[pNetworkRadio] %s � alert color OFF', [rig^.RadioName]);
      if rig^.FreqWindowHandle <> 0 then
         Windows.InvalidateRect(rig^.FreqWindowHandle, nil, False);
      if rig^.RadioNameWndHandle <> 0 then
         Windows.InvalidateRect(rig^.RadioNameWndHandle, nil, False);
   end;

begin

   { Unlike the other polling procedures, all we have to do here is grab the
     radio parameters we need from network classes. We do not need to send any
     commands as the network class keeps up to date when anything on the radio
     changes. This is at least the way the K4 works. If other future network
     interfaces do not work that way, then the network class should poll on a
     timer so the net effect it appears that the network class just "has" the info.
     NY4I 27-Nov-2021
   }
   logger.Trace('[pNetworkRadio] Entering polling procedure');
   ro := rig^.tNetObject;
   wasConnected := False;
   lastPollTick := 0;
   lastHeartbeatTick := 0;
   lastRITXITTick := 0;
   reconnectDelay := RECONNECT_INITIAL_DELAY;
   handshakeStuckSinceTick := 0;
   loggedNoConnInfo := False;

   // Keep polling thread alive until stop is requested (e.g. on Reset Radio Ports)
   while not rig^.PollingStopRequested do
      begin
      try
         if ro.IsConnected then
         begin
         // Stuck-handshake detector: IsConnected is the loose "transport is doing
         // something" check that stays True throughout the multi-step Icom
         // handshake (WaitingForHere/WaitingForReady/WaitingForLogin/etc.).
         // If we sit in that limbo too long -- e.g. the radio was off when our
         // initial AYH packet was sent, and the transport doesn't auto-retry --
         // force a Disconnect so the else-branch fires Connect() again with
         // a fresh handshake.  Without this, the polling thread spins forever
         // in the connected branch sending CI-V commands that fail with
         // "stream not open" until the operator manually intervenes.
         //
         // Gated on CanRecycleOnStuckHandshake so we only force-recycle for
         // radios where it actually fixes things.  Flex returns False because
         // its IsOperational drops when SmartSDR closes (TCP is fine, slice
         // is gone) -- recycling TCP wouldn't help and would just churn.
         if (not ro.IsOperational) and ro.CanRecycleOnStuckHandshake then
            begin
            if handshakeStuckSinceTick = 0 then
               handshakeStuckSinceTick := GetTickCount
            else if (GetTickCount - handshakeStuckSinceTick) > HANDSHAKE_STUCK_MS then
               begin
               logger.Warn('[pNetworkRadio] %s handshake stuck (IsConnected but not IsOperational) for >%d ms; forcing Disconnect for retry',
                  [rig^.RadioName, HANDSHAKE_STUCK_MS]);
               handshakeStuckSinceTick := 0;
               try
                  ro.Disconnect;
               except
                  on E: Exception do
                     logger.Debug('[pNetworkRadio] Forced Disconnect raised: %s - %s', [E.ClassName, E.Message]);
               end;
               // Brief sleep so the next iteration sees the new state cleanly,
               // then loop -- the else-branch will reset wasConnected and
               // schedule the reconnect via the existing backoff path.
               Sleep(100);
               Continue;
               end;
            end
         else
            handshakeStuckSinceTick := 0;  // operational, or this radio doesn't recycle on stuck

         // Radio is connected - poll status
         if not wasConnected then
            begin
            logger.trace('[pNetworkRadio] Radio connected � querying initial freq/mode/state');
            wasConnected := True;
            reconnectDelay := RECONNECT_INITIAL_DELAY;  // Reset backoff on successful connection
            // Don't unconditionally clear the alert here -- IsConnected is
            // the loose "transport is doing something" check that stays True
            // throughout the multi-step Icom handshake (WaitingForHere etc.).
            // The IsOperational query below (and the per-iteration check at
            // line ~944) is the strict "fully connected" gate that drives
            // the alert color; clearing here would briefly turn the alert
            // off during reconnect even when the radio is unreachable.
            SetRadioAlertState(not ro.IsOperational);

            // For serial radios that require active polling, honour the user-configurable
            // FREQUENCY POLL RATE setting (FreqPollRate, default 10ms, range 10-1000ms).
            // This keeps serial K4 poll latency consistent with legacy K3 behaviour.
            if ro.requiresPolling and (ro.serialPort <> NoPort) then
               begin
               ro.pollingInterval := FreqPollRate;
               logger.Debug('[pNetworkRadio] Serial polling interval set to %dms (FREQUENCY POLL RATE)',
                            [ro.pollingInterval]);
               end;

            // Query freq and mode directly from the polling thread.
            // The OnInitialPollSeeding timer window is created on this thread, which has
            // no Win32 message pump (it only calls Sleep), so WM_TIMER is never dispatched
            // and the timer callback never fires. Querying here guarantees the display
            // updates on every connect/reconnect without the user needing to touch the VFO.
            if Assigned(ro) then
               begin
               logger.Debug('[pNetworkRadio] Querying initial freq/mode');
               ro.QueryActiveVFO;      // $07 $D2 � must be first so FActiveVFO is set before mode routing
               ro.QueryVFOAFrequency;
               ro.QueryVFOBFrequency;
               ro.QueryMode;           // $04 � active VFO mode ? routed to FActiveVFO slot
               ro.QueryVFOAMode;       // $26 $00 � inactive VFO A mode (when VFO B is active)
               ro.QueryVFOBMode;       // $26 $01 � VFO B mode + data mode
               end;

            // Poll the remaining states that transceive does not push
            if Assigned(ro) and ro.requiresPolling then
               begin
               logger.Debug('[pNetworkRadio] Querying initial RIT/XIT/split/TX');
               ro.PollRadioState;
               end;

            // CW speed on initial connection:
            // - CWSpeedSync OFF: program is master � push CodeSpeed to radio so they agree.
            // - CWSpeedSync ON:  radio is master � do NOT push; leave the radio's speed alone.
            //   The $14 $0C query sent during connect will return ro.CWSpeed, and the
            //   polling loop below (ro.CWSpeed -> CodeSpeed sync) will apply it on the
            //   first cycle that sees a valid response.
            if not rig^.CWSpeedSync and (CodeSpeed >= 6) and Assigned(ro) then
               begin
               logger.Debug('[pNetworkRadio] CWSpeedSync off � pushing program speed %d WPM to radio', [CodeSpeed]);
               ro.SetCWSpeed(CodeSpeed);
               end;

            // StartupCommand: configured per-radio in the .cfg file.  Sent
            // once, after the first successful connect (not on every reconnect)
            // to match the legacy semantic from when SetUpRadioInterface sent
            // it synchronously.  Reset Radio Ports frees and rebuilds the radio
            // object, which sets StartupCommandSent back to False so the
            // command fires again on the next first connect.  Issue #436.
            if (not rig^.StartupCommandSent) and (Length(rig^.StartupCommand) > 0) and Assigned(ro) then
               begin
               logger.Info('[pNetworkRadio] Sending StartupCommand for %s: %s',
                           [rig^.RadioName, rig^.StartupCommand]);
               ro.SendToRadio(rig^.StartupCommand);
               rig^.StartupCommandSent := True;
               end;
            end;

         // HamLib Direct: short sleep so FNeedsPoll is checked promptly when
         // an async callback fires. Legacy serial radios use FreqPollRate.
         if Assigned(ro) and (ro is THamLibDirect) then
            Sleep(50)
         else
            Sleep(FreqPollRate);

         // Auth failure may happen asynchronously during handshake.
         // IsConnected can still be True if Disconnect couldn't complete
         // (Indy self-deadlock), so check AuthFailed explicitly.
         if Assigned(ro) and ro.AuthFailed then
            begin
            logger.Warn('[pNetworkRadio] Auth failed for %s - stopping', [rig^.RadioName]);
            StrPCopy(authErrBuf, rig^.RadioName + ': Auth failed - check credentials');
            QuickDisplayError(authErrBuf);
            if rig^.tRadioInterfaceWndHandle <> 0 then
               begin
               SetDlgItemText(rig^.tRadioInterfaceWndHandle, 130, 'AUTH FAILED');
               end;
            Break;
            end;

         // HamLib Direct: drain user commands first on every cycle (max 50ms latency),
         // then poll when an async callback fired or the heartbeat interval elapsed.
         // Set HAMLIB ASYNC ONLY = TRUE in cfg to disable the heartbeat and only
         // poll on async callbacks � useful for testing whether transceive is working.
         if Assigned(ro) and (ro is THamLibDirect) then
            begin
            THamLibDirect(ro).DrainUrgentQueue;

            if InterlockedExchange(THamLibDirect(ro).FNeedsPoll, 0) <> 0 then
               begin
               if TR4W_HAMLIB_DEBUG then
                  logger.Info('[pNetworkRadio] HamLib poll triggered by ASYNC callback');
               THamLibDirect(ro).SendPollRequests;
               lastHeartbeatTick := GetTickCount;
               end
            else if not TR4W_HAMLIB_ASYNC_ONLY and
                    (GetTickCount - lastHeartbeatTick >= LongWord(ro.pollingInterval)) then
               begin
               if TR4W_HAMLIB_DEBUG then
                  logger.Info('[pNetworkRadio] HamLib poll triggered by HEARTBEAT (%dms)',
                              [ro.pollingInterval]);
               THamLibDirect(ro).SendPollRequests;
               lastHeartbeatTick := GetTickCount;
               end;

            // RIT/XIT slow poll � every 5000ms independently of the main heartbeat.
            // rig_get_rit/xit trigger $07 D0 side-effects in HamLib's Icom driver
            // which dismiss front-panel menus; polling infrequently keeps them usable.
            if GetTickCount - lastRITXITTick >= 5000 then
               begin
               THamLibDirect(ro).SendRITXITPoll;
               lastRITXITTick := GetTickCount;
               end;
            end
         // For radios that require active polling (Icom, etc.), call PollRadioState
         // Throttled by pollingInterval (e.g. 500ms for network Icom)
         else if Assigned(ro) and ro.requiresPolling then
            begin
            if (GetTickCount - lastPollTick >= LongWord(ro.pollingInterval)) then
               begin
               ro.PollRadioState;
               lastPollTick := GetTickCount;
               end;
            end;

         // Aggregate "main window" status follows the active (RX/operating) VFO.
         // Swap-model radios (K4) return nrVFOA from GetActiveVFO -- unchanged
         // from before. Selectable-model radios (Kenwood FR, Flex) return the
         // receiving VFO, so the main window tracks A/B selection on the radio.
         actVFO := ro.GetActiveVFO;
         rig^.CurrentStatus.Freq := ro.frequency[actVFO];
         rig^.CurrentStatus.Band := GetTR4WBandFromNetworkBand(ro.band[actVFO]);
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[actVFO],rig^.CurrentStatus.Mode,rig^.CurrentStatus.ExtendedMode);
         rig^.CurrentStatus.RITFreq :=  ro.RITOffset[actVFO];
         rig^.CurrentStatus.Split := ro.IsSplitEnabled;
         rig^.CurrentStatus.RIT := ro.IsRITOn[actVFO];
         rig^.CurrentStatus.XIT := ro.IsXITOn[actVFO];
         rig^.CurrentStatus.TXOn := ro.IsTransmitting;
         if actVFO = nrVFOB then
            rig^.CurrentStatus.VFOStatus := VFOB
         else
            rig^.CurrentStatus.VFOStatus := VFOA;

         // VFO A
         rig.CurrentStatus.VFO[VFOA].Frequency := ro.frequency[nrVFOA];
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[nrVFOA],rig.CurrentStatus.VFO[VFOA].Mode,rig.CurrentStatus.VFO[VFOA].ExtendedMode);
         rig.CurrentStatus.VFO[VFOA].RIT := ro.IsRITOn[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].XIT := ro.IsXITOn[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].RITFreq := ro.RITOffset[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].Band := GetTR4WBandFromNetworkBand(ro.band[nrVFOA]);
         rig.CurrentStatus.Band := GetTR4WBandFromNetworkBand(ro.band[actVFO]);  // aggregate band follows active VFO

         // VFO B
         rig.CurrentStatus.VFO[VFOB].Frequency := ro.frequency[nrVFOB];
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[nrVFOB],rig.CurrentStatus.VFO[VFOB].Mode,rig.CurrentStatus.VFO[VFOB].ExtendedMode);
         rig.CurrentStatus.VFO[VFOB].RIT := ro.IsRITOn[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].XIT := ro.IsXITOn[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].RITFreq := ro.RITOffset[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].Band := GetTR4WBandFromNetworkBand(ro.band[nrVFOB]);

         // Sync CW speed from radio ? program (active radio only, when CWSpeedSync enabled)
         // Only the active radio should update CodeSpeed � in SO2R, the inactive radio
         // may have a different speed and would otherwise fight the active radio.
         if rig^.CWSpeedSync and (ro.CWSpeed > 0) and (ro.CWSpeed <> CodeSpeed)
            and (rig = ActiveRadioPtr) then
            begin
            logger.Info('[pNetworkRadio] CWSpeedSync: radio speed %d WPM -> CodeSpeed', [ro.CWSpeed]);
            CodeSpeed := ro.CWSpeed;
            DisplayCodeSpeed;  // Refreshes display and persists to SpeedMemory
            end;

         // HamLib Direct skips this � SendPollRequests already logs individual values.
         if TR4W_HAMLIB_DEBUG and not (ro is THamLibDirect) then
            logger.Info('[pNetworkRadio:%s] pre-UpdateStatus: VFOA=%d VFOB=%d split=%s VFOStatus=%d',
               [rig^.RadioName,
                rig.CurrentStatus.VFO[VFOA].Frequency,
                rig.CurrentStatus.VFO[VFOB].Frequency,
                BoolToStr(rig.CurrentStatus.Split, True),
                Ord(rig.CurrentStatus.VFOStatus)]);

         // Check operational state (e.g. Flex slice 0 validity).
         // TCP may be up while slices are gone (SmartSDR closed); alert in that case too.
         SetRadioAlertState(not ro.IsOperational);

         UpdateStatus(rig);
         end
      else
         begin
         // Radio disconnected - attempt reconnection
         SetRadioAlertState(True);  // TCP disconnected
         if wasConnected then
            begin
            logger.Info('[pNetworkRadio] Radio disconnected, will attempt reconnection');
            wasConnected := False;
            // Zero freq in both Current and Previous status.
            // Current: so the display shows blank, not a stale reading.
            // Previous: so UpdateStatus detects a real change when reconnect brings the
            //           actual frequency back (if only Current were zeroed, a reconnect
            //           at the same frequency would produce no StatusChanged event).
            rig.CurrentStatus.Freq := 0;
            rig.CurrentStatus.VFO[VFOA].Frequency := 0;
            rig.CurrentStatus.VFO[VFOB].Frequency := 0;
            rig.PreviousStatus.Freq := 0;
            rig.PreviousStatus.VFO[VFOA].Frequency := 0;
            rig.PreviousStatus.VFO[VFOB].Frequency := 0;
            // Blank the frequency display immediately. FreqToPChar(0) shows "0.000"
            // which is as misleading as the stale value, so write '' directly.
            if rig^.FreqWindowHandle <> 0 then
               Windows.SetWindowText(rig^.FreqWindowHandle, '');
            if rig^.tRadioInterfaceWndHandle <> 0 then
               begin
               SetDlgItemText(rig^.tRadioInterfaceWndHandle, 102, '');
               SetDlgItemText(rig^.tRadioInterfaceWndHandle, 104, '');
               end;
            reconnectDelay := RECONNECT_INITIAL_DELAY;  // Reset backoff on new disconnect
            end;

         // If auth failed, show error and stop reconnecting
         if Assigned(ro) and ro.AuthFailed then
            begin
            logger.Warn('[pNetworkRadio] Authentication failed for %s - not retrying', [rig^.RadioName]);
            StrPCopy(authErrBuf, rig^.RadioName + ': Auth failed - check credentials');
            QuickDisplayError(authErrBuf);
            if rig^.tRadioInterfaceWndHandle <> 0 then
               begin
               SetDlgItemText(rig^.tRadioInterfaceWndHandle, 130, 'AUTH FAILED');
               end;
            Break;
            end;

         // Attempt to reconnect with exponential backoff.
         // Sleep in short intervals so PollingStopRequested is checked promptly
         // during shutdown (otherwise a 30s sleep blocks ExitProgram).
         sleepRemaining := reconnectDelay;
         while (sleepRemaining > 0) and (not rig^.PollingStopRequested) do
            begin
            if sleepRemaining > 250 then
               begin
               Sleep(250);
               end
            else
               begin
               Sleep(sleepRemaining);
               end;
            Dec(sleepRemaining, 250);
            end;
         if rig^.PollingStopRequested then
            begin
            Break;
            end;

         // Issue #968 -- a network radio with no IP address or a 0 TCP port has
         // nothing to connect to.  ro.Connect would just return -1 every cycle
         // (the port=0 / address=0 guards in TNetRadioBase.Connect) and flood the
         // log once per second.  Idle quietly until the operator supplies the
         // connection info; log the reason once so it is still discoverable.
         if (rig^.RadioTCPPort = 0) or (Length(rig^.IPAddress) = 0) then
            begin
            if not loggedNoConnInfo then
               begin
               logger.Warn('[pNetworkRadio] %s has no IP address/TCP port configured -- not attempting to connect until set',
                  [rig^.RadioName]);
               loggedNoConnInfo := True;
               end;
            Continue;
            end;
         loggedNoConnInfo := False;

         try
            logger.Info('[pNetworkRadio] Reconnection attempt (delay: %dms)', [reconnectDelay]);
            ro.Connect;

            // Connect only initiates the handshake (sends AYH for Icom, opens TCP for K4).
            // IsConnected will be True on the next loop iteration once the handshake completes.
            // The connected branch (above) handles initial polling and CW speed sync at that point.
         except
            on E: Exception do
               begin
               logger.Debug('[pNetworkRadio] Reconnection failed: %s - %s', [E.ClassName, E.Message]);
               // Exponential backoff: double the delay, cap at max
               reconnectDelay := reconnectDelay * 2;
               if reconnectDelay > RECONNECT_MAX_DELAY then
                  reconnectDelay := RECONNECT_MAX_DELAY;
               end;
         end;
         end;
      except
         on E: EAbstractError do
            begin
            logger.Error('[pNetworkRadio] ABSTRACT ERROR: %s at address %p', [E.Message, ExceptAddr]);
            logger.Error('[pNetworkRadio] This indicates a missing method implementation in the radio class');
            raise;  // Re-raise so user sees the dialog
            end;
         on E: Exception do
            begin
            logger.Error('[pNetworkRadio] Exception in polling loop: %s - %s', [E.ClassName, E.Message]);
            Sleep(1000);  // Avoid tight loop on repeated errors
            end;
      end;  // end of try-except
      end;  // end of while True loop iteration

end;

procedure pHamLib(rig: RadioPtr);
var
   ro: TNetRadioBase;
   wasConnected: Boolean;
begin

{ To do a full poll, we need to request the following:

   Active VFO
   Frequency
   Mode
   RIT Offset
   XIT Offset
   Split status
   RIT On/Off status
   XIT On/Off status
   Transmit status

   Since these are calls to hamlib, we just send the reuiests here.
   The TCP socket receive event will process the result when it comes back

   }

   logger.Trace('[pHamLib] Entering polling procedure');
   ro := rig^.tNetObject;
   wasConnected := False;

   // Keep polling thread alive until stop is requested (e.g. on Reset Radio Ports)
   while not rig^.PollingStopRequested do
      begin
      if ro.IsConnected then
         begin
         // Radio is connected - poll status
         if not wasConnected then
            begin
            logger.Info('[pHamLib] Radio connected, resuming polling');
            wasConnected := True;
            end;

         // rig^.tNetObject.SendPollRequests; // Removed - rigctld no longer supported
         Sleep(FreqPollRate);
         rig^.CurrentStatus.Freq := ro.frequency[nrVFOA];
         rig^.CurrentStatus.Band := GetTR4WBandFromNetworkBand(ro.band[nrVFOA]);
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[nrVFOA],rig^.CurrentStatus.Mode,rig^.CurrentStatus.ExtendedMode);
         rig^.CurrentStatus.RITFreq :=  ro.RITOffset[nrVFOA];
         rig^.CurrentStatus.Split := ro.IsSplitEnabled;
         rig^.CurrentStatus.RIT := ro.IsRITOn[nrVFOA];
         rig^.CurrentStatus.XIT := ro.IsXITOn[nrVFOA];
         rig^.CurrentStatus.TXOn := ro.IsTransmitting;

         // VFO A
         rig.CurrentStatus.VFO[VFOA].Frequency := ro.frequency[nrVFOA];
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[nrVFOA],rig.CurrentStatus.VFO[VFOA].Mode,rig.CurrentStatus.VFO[VFOA].ExtendedMode);
         rig.CurrentStatus.VFO[VFOA].RIT := ro.IsRITOn[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].XIT := ro.IsXITOn[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].RITFreq := ro.RITOffset[nrVFOA];
         rig.CurrentStatus.VFO[VFOA].Band := GetTR4WBandFromNetworkBand(ro.band[nrVFOA]);

         // VFO B
         rig.CurrentStatus.VFO[VFOB].Frequency := ro.frequency[nrVFOB];
         GetTRModeAndExtendedModeFromNetworkMode(ro.mode[nrVFOB],rig.CurrentStatus.VFO[VFOB].Mode,rig.CurrentStatus.VFO[VFOB].ExtendedMode);
         rig.CurrentStatus.VFO[VFOB].RIT := ro.IsRITOn[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].XIT := ro.IsXITOn[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].RITFreq := ro.RITOffset[nrVFOB];
         rig.CurrentStatus.VFO[VFOB].Band := GetTR4WBandFromNetworkBand(ro.band[nrVFOB]);

         UpdateStatus(rig);
         end
      else
         begin
         // Radio disconnected - attempt reconnection
         if wasConnected then
            begin
            logger.Info('[pHamLib] Radio disconnected, attempting reconnection');
            wasConnected := False;
            rig.CurrentStatus.VFO[VFOA].Frequency := 0;
            rig.CurrentStatus.VFO[VFOB].Frequency := 0;
            end;

         // Attempt to reconnect
         Sleep(2000);  // Wait 2 seconds before reconnection attempt
         try
            logger.Info('[pHamLib] Calling Connect to reconnect radio');
            ro.Connect;
         except
            on E: Exception do
               begin
               logger.Debug('[pHamLib] Reconnection attempt failed: %s - %s', [E.ClassName, E.Message]);
               end;
         end;
         end;
      end;

end;


procedure pKenwoodNew(rig: RadioPtr); // K3 is here
label
   NextPoll;
var
   Step: integer;
   TempVFO: ActiveVFOStatusType;
const
   KenwoodVFORequests: array[ActiveVFOStatusType] of PChar = (nil, 'FA;', 'FB;',
      'FB;');
   KenwoodPollCount = 10;
begin
   Step := KenwoodPollCount;
   NextPoll:
   Sleep(FreqPollRate);

   if rig^.PollingStopRequested then Exit;

   if rig.CommandsBufferPointer <> 0 then
      begin
         rig.WritePollRequest(rig.CommandsBuffer[0], rig.CommandsBufferPointer);
         Windows.ZeroMemory(@rig.CommandsBuffer[0],
            SizeOf(rig.CommandsBuffer[0]));
         rig.CommandsBufferPointer := 0;
         Sleep(80);
      end;

   //  if step = KenwoodPollCount then
   if rig.WritePollRequest('IF;', 3) then
      begin
         if not ReadFromCOMPort {OnEvent}(38, rig) then
            ClearRadioStatus(rig)
         else
            begin
               //      Windows.SetWindowText(tr4whandle, @rig^.tBuf);
               rig.CurrentStatus.VFOStatus :=
                  ActiveVFOStatusType(Ord(rig^.tBuf[31]) - Ord('0') + 1);

               rig.CurrentStatus.Freq := BufferToInt(@rig^.tBuf, 3, 11);
               if rig.CurrentStatus.Freq = rig.PreviousStatus.Freq then
                  Sleep(200);

               CalculateBandMode(rig^.CurrentStatus.Freq,
                  rig^.CurrentStatus.Band, rig^.CurrentStatus.Mode);

               // Set the extendedMode based on the actual mode ny4i
               case rig^.tBuf[30] of
                  '1':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eLSB;
                        rig^.CurrentStatus.Mode := Phone;
                     end;
                  '2':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eUSB;
                        rig^.CurrentStatus.Mode := Phone;
                     end;
                  '3':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eCW;
                        rig^.CurrentStatus.Mode := CW;
                     end;
                  '4':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eFM;
                        rig^.CurrentStatus.Mode := FM;
                     end;
                  '5':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eAM;
                        rig^.CurrentStatus.Mode := Phone;
                     end;
                  '6':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eRTTY;
                        rig^.CurrentStatus.Mode := Digital;
                     end;
                  '7':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eCW_R;
                        rig^.CurrentStatus.Mode := CW;
                     end;
                  '8':
                     begin
                        rig^.CurrentStatus.Mode := CW;
                        rig^.CurrentStatus.ExtendedMode := eCW_R;
                     end;
                  '9':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eRTTY_R;
                        rig^.CurrentStatus.Mode := Digital;
                     end;
                  'A':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eDATA;
                        rig^.CurrentStatus.Mode := Digital;
                     end;
                  'B':
                     begin
                        rig^.CurrentStatus.ExtendedMode := eDATA_R;
                        rig^.CurrentStatus.Mode := Digital;
                     end;
                  else
                     DEBUGMSG('Invalid mode received from KenwoodNew ' +
                        rig^.tBuf[30]);
               end;

               rig^.CurrentStatus.RITFreq := BufferToInt(@rig^.tBuf, 19, 5);

               rig^.CurrentStatus.Split := rig^.tBuf[33] <> '0';
               rig^.CurrentStatus.RIT := rig^.tBuf[24] = '1';
               rig^.CurrentStatus.XIT := rig^.tBuf[25] = '1';

               rig.CurrentStatus.VFO[rig.CurrentStatus.VFOStatus].Frequency :=
                  rig.CurrentStatus.Freq;
               rig.CurrentStatus.VFO[rig.CurrentStatus.VFOStatus].Mode :=
                  rig.CurrentStatus.Mode;
               rig.CurrentStatus.VFO[rig.CurrentStatus.VFOStatus].ExtendedMode
                  := rig.CurrentStatus.ExtendedMode;
               dec(Step);
            end;
      end;

   if step = 0 then
      begin
         if rig.CurrentStatus.VFOStatus = VFOA then
            TempVFO := VFOB
         else
            TempVFO := VFOA;
         if rig.WritePollRequest(KenwoodVFORequests[TempVFO]^, 3) then
            if ReadFromCOMPort(14, rig) then // on event
               begin
                  rig^.CurrentStatus.VFO[TempVFO].Frequency :=
                     BufferToInt(@rig^.tBuf, 3, 11);
               end;
      end;

   if Step = 0 then
      step := KenwoodPollCount;

   UpdateStatus(rig);
   goto NextPoll;
end;

procedure pFT990_FT1000(rig: RadioPtr);
label
   1;
var
   F1, TempFreq: LONGINT;
   TempBand: BandType;
   TempMode: ModeType;
begin
   repeat
      inc(rig^.tPollCount);
      rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
      //    WriteToSerialCATPort(FT1000MPPoll1String, rig^.tCATPortHandle);
      if rig^.RadioModel = FT1000 then
         F1 := 16
      else
         F1 := 32;
      if not ReadFromCOMPort(F1, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      with rig^.CurrentStatus do
         begin
            rig^.CurrentStatus.RITFreq := 10 * (SHORTINT(rig^.tBuf[6]) * 255 +
               Ord(rig^.tBuf[7]));
            rig^.CurrentStatus.RIT := (Ord(rig^.tBuf[5]) and (1 shl 1)) <> 0;
            rig^.CurrentStatus.XIT := (Ord(rig^.tBuf[5]) and (1 shl 0)) <> 0;

            Freq := GetFrequencyForYaesu3(@rig^.tBuf[2]);
            Freq := Freq + rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case Ord(rig^.tBuf[8]) of
               0, 1, 3: Mode := Phone;
               2: Mode := CW;
               4: Mode := FM;
               5, 6: Mode := Digital;
            end;
         end;

      {2}
      rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
      //    WriteToSerialCATPort(FT1000MPPoll2String, rig^.tCATPortHandle);
      if ReadFromCOMPort(32, rig) then
         with rig^.CurrentStatus do
            begin
               TempFreq := GetFrequencyForYaesu3(@rig^.tBuf[2]);
               CalculateBandMode(TempFreq, TempBand, TempMode);

               case Ord(rig^.tBuf[8]) of
                  0, 1, 3: TempMode := Phone;
                  2: TempMode := CW;
                  4: TempMode := FM;
                  5, 6: TempMode := Digital;
               end;

               VFO[VFOA].Frequency := TempFreq;
               VFO[VFOA].Band := TempBand;
               VFO[VFOA].Mode := TempMode;

               TempFreq := GetFrequencyForYaesu3(@rig^.tBuf[17 + 1]);
               CalculateBandMode(TempFreq, TempBand, TempMode);

               case Ord(rig^.tBuf[24]) of
                  0, 1, 3: TempMode := Phone;
                  2: TempMode := CW;
                  4: TempMode := FM;
                  5, 6: TempMode := Digital;
               end;

               VFO[VFOB].Frequency := TempFreq;
               VFO[VFOB].Band := TempBand;
               VFO[VFOB].Mode := TempMode;
            end;

      rig.WritePollRequest(FT1000MPPoll3String, length(FT1000MPPoll3String));
      //    WriteToSerialCATPort(FT1000MPPoll3String, rig.tCATPortHandle);
          //?????? 3 ????? - ???????? ??????????, ????????? ??? - Model ID
      if ReadFromCOMPort(5, rig) then

         with rig.CurrentStatus do
            begin
               Split := (Ord(rig.tBuf[1]) and $01) > 0;
               if (Ord(rig.tBuf[1]) and (1 shl 1)) <> 0 then
                  rig^.CurrentStatus.VFOStatus := VFOB
               else
                  rig^.CurrentStatus.VFOStatus := VFOA;
            end;
      1:
      UpdateStatus(rig);
   until rig^.tPollCount < 0;
end;

procedure pFT747GX(rig: RadioPtr);
label
   1;
var
   ActiveVFO_is_B: boolean;
   //  c                                     : integer;
   //  b                                     : Byte;
begin
   repeat
      inc(rig.tPollCount);
      rig.WritePollRequest(FT747GXPollString, length(FT747GXPollString));
      //    WriteToSerialCATPort(FT747GXPollString, rig.tCATPortHandle);

      if not ReadFromCOMPort(344, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      {
          rig.tBuf[01] := CHR($00); //Split

          rig.tBuf[02] := CHR($00); //Frequency
          rig.tBuf[03] := CHR($14); //Frequency
          rig.tBuf[04] := CHR($16); //Frequency
          rig.tBuf[05] := CHR($80); //Frequency
          rig.tBuf[06] := CHR(Random(255)); //Frequency

          rig.tBuf[07] := CHR($00); //Cur band
          rig.tBuf[08] := CHR($02); //vfo a status flag

          rig.tBuf[09] := CHR($00); //Frequency
          rig.tBuf[10] := CHR($14); //Frequency
          rig.tBuf[11] := CHR($16); //Frequency
          rig.tBuf[12] := CHR($80); //Frequency
          rig.tBuf[13] := CHR($25); //Frequency

          rig.tBuf[14] := CHR($14); //?
          rig.tBuf[15] := CHR($16); //?
          rig.tBuf[16] := CHR($80); //?

          rig.tBuf[17] := CHR($00); //Frequency
          rig.tBuf[18] := CHR($03); //Frequency
          rig.tBuf[19] := CHR($68); //Frequency
          rig.tBuf[20] := CHR($00); //Frequency
          rig.tBuf[21] := CHR(Random(255)); //Frequency

          Sleep(400);
      }
      with rig.CurrentStatus do
         begin
{(*}
      Split          := (Ord(rig.tBuf[1]) and (1 shl 1)) <> 0;
      RIT            := (Ord(rig.tBuf[1]) and (1 shl 2)) <> 0;
      ActiveVFO_is_B := (Ord(rig.tBuf[1]) and (1 shl 3)) <> 0;
      if ActiveVFO_is_B then VFOStatus:= vfoB else VFOStatus:= vfoA;
{*)}

            Freq := GetFrequencyForYaesuFT747(@rig.tBuf[2]);

            CalculateBandMode(Freq, Band, Mode);

            case Ord(rig^.tBuf[22] {?!}) of
               1: Mode := FM;
               2, 8, 16: Mode := Phone;
               4: Mode := CW;
            end;

         end;

      with rig.CurrentStatus.VFO[VFOA] do
         begin
            Frequency := GetFrequencyForYaesuFT747(@rig.tBuf[9]);
            CalculateBandMode(Frequency, Band, Mode);
         end;

      with rig.CurrentStatus.VFO[VFOB] do
         begin
            Frequency := GetFrequencyForYaesuFT747(@rig.tBuf[17]);
            CalculateBandMode(Frequency, Band, Mode);
         end;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT840_FT890_FT900(rig: RadioPtr);
label
   1;
var
   RITFreqPtr: ^Smallint;
begin
   repeat
      inc(rig.tPollCount);
      rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
      //    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);

      if not ReadFromCOMPort(19, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            if Ord(rig.tBuf[1]) and $40 > 0 then
               Split := True
            else
               Split := False;
            Freq := GetFrequencyForYaesu3(@rig.tBuf[3]) + rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case Ord(rig^.tBuf[8]) of
               0, 1, 3: Mode := Phone;
               2: Mode := CW;
               4: Mode := FM;
               5, 6: Mode := Digital;
            end;

            RITFreqPtr := @rig.tBuf[6];
            RITFreq := RITFreqPtr^;
         end;
      rig.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;
      rig.CurrentStatus.VFO[VFOA].Mode := rig.CurrentStatus.Mode;
      rig.CurrentStatus.VFO[VFOA].ExtendedMode :=
         rig.CurrentStatus.ExtendedMode;
      rig.CurrentStatus.VFO[VFOA].Band := rig.CurrentStatus.Band;

      with rig.CurrentStatus.VFO[VFOB] do
         begin
            Frequency := GetFrequencyForYaesu3(@rig.tBuf[12]);
            CalculateBandMode(Frequency, Band, Mode);

            case Ord(rig^.tBuf[17]) of
               0, 1, 3: Mode := Phone;
               2: Mode := CW;
               4: Mode := FM;
               5, 6: Mode := Digital;
            end;

         end;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT817_FT847_FT857_FT897(rig: RadioPtr);
label
   1;
var
   F1: integer;
begin
   if rig^.RadioModel in [{FT817, }FT847] then
      rig.WritePollRequest(TurnOn847CATString, length(TurnOn847CATString));

   repeat
      inc(rig.tPollCount);
      rig.WritePollRequest(FT847PollString, length(FT847PollString));

      if not ReadFromCOMPort(5, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            F1 := (Ord(rig.tBuf[1]) and $F0) shr 4; { 100s of mhz }
            F1 := F1 * 10;
            F1 := F1 + (Ord(rig.tBuf[1]) and $0F); { 10s of mhz}
            F1 := F1 * 10;

            F1 := F1 + ((Ord(rig.tBuf[2]) and $F0) shr 4); { MHz }
            F1 := F1 * 10;
            F1 := F1 + (Ord(rig.tBuf[2]) and $0F); { 100 kHz }
            F1 := F1 * 10;

            F1 := F1 + ((Ord(rig.tBuf[3]) and $F0) shr 4); { 10 kHz }
            F1 := F1 * 10;
            F1 := F1 + (Ord(rig.tBuf[3]) and $0F); { kHz }
            F1 := F1 * 10;

            F1 := F1 + ((Ord(rig.tBuf[4]) and $F0) shr 4); { 100 hz }
            F1 := F1 * 10;

            F1 := F1 + (Ord(rig.tBuf[4]) and $0F); { 10 hz }
            F1 := F1 * 10;
            Freq := F1 + rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case Ord(rig.tBuf[5]) of
               $00, $01, $04, $84: Mode := Phone;
               $02, $03, $82, $83: Mode := CW;
               $0A, $0C: Mode := Digital;
               $06, $08, $88: Mode := FM;
            end;

         end;

      rig^.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;

      if rig^.RadioModel in [FT857, FT897] then
         begin
            if rig.tYaesuSendFreq then
               begin
                  rig.WritePollRequest(rig.tYaesuFreq5Bytes, 5);
                  rig.tYaesuSendFreq := False;
                  Sleep(100);
                  PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR);
               end;

            if rig.tYaesuSendMode then
               begin
                  rig.WritePollRequest(rig.tYaesuMode5Bytes, 5);
                  rig.tYaesuSendMode := False;
                  Sleep(100);
                  PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR);
               end;
         end;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

function icomCheckBuffer(rig: RadioPtr): boolean;
label
   NextLongCheck, NextShortCheck, NewCheck;
var
   stat: TComStat;
   Errs: DWORD;
   counter: integer;
   BytesInFuffer: integer;
   i: integer;
   FDPos: integer;
   DummyMode: ModeType;
   freq: Cardinal;
   //  p                                     : pchar;
const
   FD_NOT_FOUND = 12;
   ICOM_MAX_IN_BUFFER = 256;
begin

   Result := False;

   NewCheck:
   counter := 0;

   NextLongCheck:
   Sleep(100);
   ClearCommError(rig^.tCATPortHandle, Errs, @stat);
   if stat.cbInQue = 0 then
      begin
         inc(counter);
         if counter < 3 then
            goto NextLongCheck
         else
            Exit;
      end;

   BytesInFuffer := stat.cbInQue;
   counter := 0;

   NextShortCheck:
   Sleep({newIcomResponseTimeout}newIcomResponseTimeoutAuto);
   ClearCommError(rig^.tCATPortHandle, Errs, @stat);

   if BytesInFuffer < stat.cbInQue then
      begin
         BytesInFuffer := stat.cbInQue;
         counter := 0;
         goto NextShortCheck;
      end
   else
      begin
         inc(counter);
         if counter < 2 then
            if stat.cbInQue < ICOM_MAX_IN_BUFFER then
               goto NextShortCheck;
      end;

   if Errs = 0 then
      begin
         ReadFromSerialPort(stat.cbInQue, rig);
         Result := True;

         for i := 1 to stat.cbInQue do
            if rig.tBuf[i] = ICOM_PREAMBLE_CODE then
               if rig.tBuf[i + 1] = ICOM_PREAMBLE_CODE then
                  if rig.tBuf[i + 2] in [ICOM_CONTROLLER_ADDRESS,
                     ICOM_OTHER_RADIOS_ADDRESS] then
                     begin

                        for FDPos := 6 to FD_NOT_FOUND do
                           if rig.tBuf[i + FDPos] = #$FD then
                              Break;
                        if FDPos = FD_NOT_FOUND then
                           Continue;

                        case rig.tBuf[i + 4] of

                           ICOM_TRANSFER_FREQ, ICOM_GET_FREQ:
                              if FDPos in [9, 10] then
                                 begin
                                    //------------------00.01.02.03.04.05.06.07.08.09.10
                                    //FE.FE.ra.E0.03.FD.FE.FE.E0.ra.03.00.00.00.00.00.FD - ic765 and others
                                    //FE.FE.ra.E0.03.FD.FE.FE.E0.ra.03.00.00.00.00.FD    - ic735
                                    rig.CurrentStatus.Freq :=
                                       GetFrequencyFromBCD(FDPos - 5 {5},
                                       @rig.tBuf[i + 5 {12}]) +
                                       rig^.FrequencyAdder;
                                    rig.CurrentStatus.VFO[VFOA].Frequency :=
                                       rig.CurrentStatus.Freq;
                                    with rig.CurrentStatus do
                                       CalculateBandMode(Freq, Band, DummyMode);
                                    UpdateStatus(rig);
                                 end;
                           ICOM_GET_EXTENDEDVFO:
                              if Ord(rig.tBuf[i + 4 + 1]) = 0 then
                                 begin // VFO A
                                    rig.CurrentStatus.Freq :=
                                       GetFrequencyFromBCD(5, @rig.tBuf[i + 6]) +
                                       rig^.FrequencyAdder;
                                    rig.CurrentStatus.VFO[VFOA].Frequency :=
                                       rig.CurrentStatus.Freq;
                                    with rig.CurrentStatus do
                                       CalculateBandMode(Freq, Band, DummyMode);
                                    UpdateStatus(rig);
                                 end
                              else if Ord(rig.tBuf[i + 4 + 1]) = 1 then
                                 begin // VFO B
                                    freq := GetFrequencyFromBCD(5, @rig.tBuf[i +
                                       6]) + rig^.FrequencyAdder;
                                    rig.CurrentStatus.VFO[VFOB].Frequency :=
                                       freq;

                                    //rig.CurrentStatus.VFO[VFOB].Mode :=
                                    //with rig.CurrentStatus do CalculateBandMode(Freq, Band, DummyMode);
                                    //UpdateStatus(rig);
                                 end;
                           ICOM_GET_EXTENDEDMODE:
                              begin
                                 case Ord(rig.tBuf[i + 6]) of
                                    0:
                                       begin // LSB
                                          if Ord(rig.tBuf[i + 7]) = 0 then
                                             begin
                                                SetVFOModeExtendedMode(rig,
                                                   Ord(rig.tBuf[i + 5]), Phone,
                                                   eLSB);
                                             end
                                          else
                                             begin
                                                SetVFOModeExtendedMode(rig,
                                                   Ord(rig.tBuf[i + 5]), Digital,
                                                   eDATA_R);
                                             end;
                                       end;
                                    1:
                                       begin
                                          if Ord(rig.tBuf[i + 7]) = 0 then
                                             begin
                                                SetVFOModeExtendedMode(rig,
                                                   Ord(rig.tBuf[i + 5]), Phone,
                                                   eUSB);
                                             end
                                          else
                                             begin
                                                SetVFOModeExtendedMode(rig,
                                                   Ord(rig.tBuf[i + 5]), Digital,
                                                   eDATA);
                                             end;
                                       end;
                                    2: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), Phone, eAM);
                                    3: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), CW, eCW);
                                    4: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), Digital, eRTTY);
                                    5: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), FM, eFM);
                                    7: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), CW, eCW_R);
                                    8: SetVFOModeExtendedMode(rig, Ord(rig.tBuf[i
                                       + 5]), Digital, eRTTY_R);
                                    else
                                       DEBUGMSG('Unknown Mode command from Icom '
                                          + IntToStr(Ord(rig.tBuf[i + 6])));
                                 end;
                                 if Ord(rig.tBuf[i + 8]) > 0 then
                                    begin
                                       Icom_Filter_Width := Ord(rig.tBuf[i +
                                          8]);
                                    end;
                                 UpdateStatus(rig);
                              end;
                           ICOM_TRANSFER_MODE, ICOM_GET_MODE:
                              if FDPos in [6, 7] then
                                 begin
                                    //------------------00.01.02.03.04.05.06.07
                                    //FE.FE.ra.E0.04.FD.FE.FE.E0.ra.04.00.00.FD + IF passband width data (06)
                                    //FE.FE.ra.E0.04.FD.FE.FE.E0.ra.04.00.FD
                                    rig.saveMode := Ord(rig.tBuf[i + 5]);
                                    //rig.ProcessIcomMode(Ord(rig.tBuf[i + 5]));


                                    if (Ord(rig.tBuf[i + 6]) > 0) then
                                       // n4af 4.43.4
                                       Icom_Filter_Width := Ord(rig.tBuf[i + 6]);
                                          // 4.43.4
                                    UpdateStatus(rig);
                                 end;
                           ICOM_STATE:
                              if rig.tBuf[i + 5] = ICOM_STATE_DATA_MODE then
                                 begin
                                 if Ord(rig.tBuf[i + 6]) = 1 then  // Only set Digital if it is on as we would not know what mode is when data mode is reported off. ny4i
                                    begin
                                    if rig.currentStatus.Mode <> Digital then
                                       begin
                                       rig.CurrentStatus.Mode := Digital;
                                       Icom_Filter_Width := Ord(rig.tBuf[i+7]);
                                       logger.Trace('Setting Icom mode to DATA based on 1A06 command');
                                       UpdateStatus(rig);
                                       end;
                                    end
                                 else
                                    begin
                                    if rig.saveMode > 0 then
                                       begin
                                       rig.ProcessIcomMode(rig.saveMode);
                                       UpdateStatus(rig);
                                       end;
                                    end;
                                 end;
                           ICOM_XMIT_SETTINGS:
                              if Ord(rig.tBuf[i + 4 + 1]) = 0 then
                                 begin
                                    rig.CurrentStatus.TXOn :=
                                       Boolean(Ord(rig.tBuf[i + 4 + 2]));
                                       //ny4i  // 4.44.5
                                    UpdateStatus(rig);
                                 end;
                           ICOM_SPLIT_MODE:
                              if Ord(rig.tBuf[i + 4 + 1]) = 1 then
                                 begin
                                    rig.CurrentStatus.Split := True;
                                    UpdateStatus(rig);
                                 end
                              else
                                 begin
                                    rig.CurrentStatus.Split := false;
                                    UpdateStatus(rig);
                                 end;

                           ICOM_GET_RIT_FREQ:
                              if (Ord(rig.tBuf[i + 4 + 1])) = 1 then
                                 // RIT Status Response (On/Off)
                                 begin
                                    if (Ord(rig.tBuf[i + 4 + 2])) = 1 then
                                       begin
                                          rig.CurrentStatus.RIT := true;
                                       end
                                    else if (Ord(rig.tBuf[i + 4 + 2])) = 0 then
                                       begin
                                          rig.CurrentStatus.RIT := false;
                                       end;
                                    UpdateStatus(rig);
                                 end
                              else if (Ord(rig.tBuf[i + 4 + 1])) = 0 then
                                 // RIT Frequency Response
                                 begin
                                    rig.CurrentStatus.RITFreq :=
                                       (GetFrequencyFromBCD(2, @rig.tBuf[i + 6]));
                                    if (Ord(rig.tBuf[i + 8])) = 1 then
                                       // 1 if negative RIT
                                       begin
                                          rig.CurrentStatus.RITFreq :=
                                             rig.CurrentStatus.RITFreq * -1;
                                       end;
                                    UpdateStatus(rig);
                                 end;
                        end;
                     end;
         Windows.ZeroMemory(@rig.tBuf, stat.cbInQue);
         if stat.cbInQue >= ICOM_MAX_IN_BUFFER then
            goto NewCheck;
      end;
end;

procedure pIcomNew(rig: RadioPtr); // This is now called for all ICOM radios
label
   NextPoll;
var
   i: integer;
begin
   if rig.RadioBaudRate >= 1200 then
      newIcomResponseTimeoutAuto := 60;
   if rig.RadioBaudRate >= 2400 then
      newIcomResponseTimeoutAuto := 40;
   if rig.RadioBaudRate >= 4800 then
      newIcomResponseTimeoutAuto := 30;
   if rig.RadioBaudRate >= 9600 then
      newIcomResponseTimeoutAuto := 20 - 10;
   if rig.RadioBaudRate >= 19200 then
      newIcomResponseTimeoutAuto := 10;
   //  1200, 2400, 4800, 9600, 19200,
   //if newIcomResponseTimeoutAuto

   NextPoll:
   for i := 0 to 7 do
      if rig.CommandsBuffer[i][0] <> #0 then
         begin
            rig.WritePollRequest(rig.CommandsBuffer[i][1],
               Ord(rig.CommandsBuffer[i][0]) - 1);
            rig.CommandsBuffer[i][0] := #0;
            icomCheckBuffer(ActiveRadioPtr);
         end;

   //  sleep(200);
   Sleep(FreqPollRate);

   if rig^.RadioModel in IcomRadiosThatSupportVFOB then
      begin

         rig.SendIcomExtendedVFO(false);
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;

            end;

         rig.SendIcomExtendedMode(false);
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;

            end;

         rig.SendIcomExtendedVFO(true);
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;

            end;

         rig.SendIcomExtendedMode(true);
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;

            end;

      end
   else      // else if for radios that do not support VFOB command
      begin
         rig.SendIcomCommand(Ord(ICOM_GET_MODE));
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;
            end;

         rig.SendIcomCommand(Ord(ICOM_GET_FREQ));
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;
            end;

         // Add the 1A06 command
         rig.GetIcomDataStateCommand;
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;
            end;
      end;
   rig.SendIcomCommand(Ord(ICOM_SPLIT_MODE));
   if not icomCheckBuffer(rig) then
      begin
         ClearRadioStatus(rig);
         UpdateStatus(rig);
         Sleep(1000);
         goto NextPoll;
      end;
   if rig^.RadioModel in IcomRadiosThatSupportRIT then
      begin
         rig.SendRITStatusCommand;
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;
            end;

         rig.SendRITFreqCommand;
         if not icomCheckBuffer(rig) then
            begin
               ClearRadioStatus(rig);
               UpdateStatus(rig);
               Sleep(1000);
               goto NextPoll;
            end;
      end;
   rig.SendXMITStatusCommand;
   if not icomCheckBuffer(rig) then
      begin
         ClearRadioStatus(rig);
         UpdateStatus(rig);
         Sleep(1000);
         goto NextPoll;
            // Argh....a damn GoTo...what the hell?!? // ny4i // 4.44.5
      end;

   goto NextPoll;
end;

procedure pIcom(rig: RadioPtr);
label
   1, 2, 3, 4, 5, NextPoll, ModeReceived;
var
   c: Cardinal;
   failures: integer;
   stat: TComStat;
   Errs: DWORD;
   ModePollCount: integer;
   ModeBytes: integer;
begin
   //  SetDCBForIcom(rig.tr4w_CATPortHandle);
   //  rig.ICOM_OVERLAPPED.hEvent := CreateEvent(nil, FALSE, FALSE, nil);
   if cmdIcomResponseTimeout = -1 then
      IcomResponseTimeout := 48000 div rig.RadioBaudRate
   else
      IcomResponseTimeout := cmdIcomResponseTimeout;

   if IcomResponseTimeout < 10 then
      IcomResponseTimeout := 10;

   5:
   //  if getIcomResponceSpeed(rig) = False then goto 5;

   failures := 0;
   3:

   repeat

      inc(rig.tPollCount);

{$IF ICOM_DEBUG}
      rig.tBuf[01] := CHR($FE);
      rig.tBuf[02] := CHR($FE);
      rig.tBuf[03] := CHR($5E);
      rig.tBuf[04] := CHR($E0);
      rig.tBuf[05] := CHR($03);
      rig.tBuf[06] := CHR($FD);
      rig.tBuf[07] := CHR($FE);
      rig.tBuf[08] := CHR($FE);
      rig.tBuf[09] := CHR($E0);
      rig.tBuf[10] := CHR($5E);
      rig.tBuf[11] := CHR($03);
      rig.tBuf[12] := CHR($00);
      rig.tBuf[13] := CHR($00);
      rig.tBuf[14] := CHR($05);
      rig.tBuf[15] := CHR($07);
      rig.tBuf[16] := CHR($00);
{$ELSE}
      rig.SendIcomCommand(Ord(ICOM_GET_FREQ));
      if rig.RadioModel = IC735 then
         c := 16
      else
         c := 17;
      if not ReadICOM(c, rig) then
         begin
            4:
            inc(failures);
            if failures > 5 then
               begin
                  ClearRadioStatus(rig);
                  goto 2;
               end
            else
               goto 3;
         end;
{$IFEND}
      if rig.RadioModel = IC735 then
         c := 4
      else
         c := 5;

      rig.CurrentStatus.Freq := GetFrequencyFromBCD(c, @rig.tBuf[12]) +
         rig^.FrequencyAdder;
      rig.CurrentStatus.VFO[VFOA].Frequency := rig.CurrentStatus.Freq;

      with rig.CurrentStatus do
         CalculateBandMode(Freq, Band, Mode);

{$IF NOT ICOM_DEBUG}
      rig.SendIcomCommand(Ord(ICOM_GET_MODE));

      ModePollCount := 0;
      ModeBytes := 0;

      NextPoll:

      Sleep(IcomResponseTimeout);
      ClearCommError(rig^.tCATPortHandle, Errs, @stat);
      if stat.cbInQue > ModeBytes then
         begin
            ModeBytes := stat.cbInQue;
            goto NextPoll;
         end
      else
         begin
            inc(ModePollCount);
            if ModePollCount < 8 then
               goto NextPoll;
         end;

      if ModeBytes > 0 then
         begin
            ReadFromSerialPort(ModeBytes, rig);
            if ModeBytes in [13, 14] then
               goto ModeReceived
            else
               begin
                  PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or
                     PURGE_RXABORT);
                  goto 1;
               end;
         end
      else
         goto 1;

      ModeReceived:

      //    if rig.RadioModel = IC735 then c := 13 else c := 14;
      //    if not ReadICOM(c, rig) then goto 1;

{$IFEND}

{$IF ICOM_DEBUG}
      rig.tBuf[01] := CHR($FE);
      rig.tBuf[02] := CHR($FE);
      rig.tBuf[03] := CHR($5E);
      rig.tBuf[04] := CHR($E0);
      rig.tBuf[05] := CHR($04);
      rig.tBuf[06] := CHR($FD);
      rig.tBuf[07] := CHR($FE);
      rig.tBuf[08] := CHR($FE);
      rig.tBuf[09] := CHR($E0);
      rig.tBuf[10] := CHR($5E);
      rig.tBuf[11] := CHR($04);
      rig.tBuf[12] := CHR($03);
      rig.tBuf[13] := CHR($01);
      rig.tBuf[14] := CHR($FD);
{$IFEND}
      if rig.tBuf[ModeBytes] = #$FD then
         case Ord(rig.tBuf[12]) of
            0:
               begin
                  rig.CurrentStatus.Mode := Phone;
                  rig.CurrentStatus.ExtendedMode := eLSB;
               end;
            1:
               begin
                  rig.CurrentStatus.Mode := Phone;
                  rig.CurrentStatus.ExtendedMode := eUSB;
               end;
            2:
               begin
                  rig.CurrentStatus.Mode := Phone;
                  rig.CurrentStatus.ExtendedMode := eAM;
               end;
            5, 6:
               begin
                  rig.CurrentStatus.Mode := FM;
                  rig.CurrentStatus.ExtendedMode := eFM;
               end;
            3:
               begin
                  rig.CurrentStatus.Mode := CW;
                  rig.CurrentStatus.ExtendedMode := eCW;
               end;
            7:
               begin
                  rig.CurrentStatus.Mode := CW;
                  rig.CurrentStatus.ExtendedMode := eCW_R;
               end;
            4:
               begin
                  rig.CurrentStatus.Mode := Digital;
                  rig.CurrentStatus.ExtendedMode := eRTTY;
               end;
            8:
               begin
                  rig.CurrentStatus.Mode := Digital;
                  rig.CurrentStatus.ExtendedMode := eRTTY;
               end;
            12:
               begin
                  rig.CurrentStatus.Mode := Digital;
                  rig.CurrentStatus.ExtendedMode := eDATA;
               end;
            13:
               begin
                  rig.CurrentStatus.Mode := Digital;
                  rig.CurrentStatus.ExtendedMode := eDATA_R;
               end;
            else
               begin
                  logger.Error('Unknown mode value in pIcom - ' + rig.tBuf[12]);
               end;
         end;

      1:

      2:
      failures := 0;
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT100(rig: RadioPtr);
label
   1;

begin
   repeat
      inc(rig.tPollCount);
      rig.WritePollRequest(FT100StatusUpdate, length(FT100StatusUpdate));
      if not ReadFromCOMPort(32, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            Freq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 1.25) +
               rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case (Ord(rig.tBuf[6]) and $07) of
               0, 1, 4: Mode := Phone;
               2, 3: Mode := CW;
               5: Mode := Digital;
               6, 7: Mode := FM;
            end;
            RITFreq := round(1.25 * (SHORTINT(rig^.tBuf[11]) * 255 +
               Ord(rig^.tBuf[12])));
         end;

      //    WriteToSerialCATPort(FT100ReadStatusFlags, rig.tCATPortHandle);
      rig.WritePollRequest(FT100ReadStatusFlags, length(FT100ReadStatusFlags));
      if ReadFromCOMPort(8, rig) then
         begin
            rig^.CurrentStatus.Split := (Ord(rig.tBuf[1]) and (1 shl 0)) <> 0;
            rig^.CurrentStatus.VFOStatus := ActiveVFOStatusType((Ord(rig.tBuf[2])
               and (1 shl 2)) + 1);
         end;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT1000MP(rig: RadioPtr);
label
   1;
var
   TempFreq: integer;
   TempBand: BandType;
   TempMode: ModeType;
begin
   repeat
      inc(rig.tPollCount);
      rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
      //    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);
      if not ReadFromCOMPort(16, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            Freq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 0.625) +
               rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case (Ord(rig.tBuf[8]) and $07) of
               0:
                  begin
                     Mode := Phone;
                     ExtendedMode := eLSB;
                  end;
               1:
                  begin
                     Mode := Phone;
                     ExtendedMode := eUSB;
                  end;
               2:
                  begin
                     Mode := CW;
                     ExtendedMode := eCW;
                  end;
               3:
                  begin
                     Mode := Phone;
                     ExtendedMode := eAM;
                  end;
               4:
                  begin
                     Mode := FM;
                     ExtendedMode := eFM;
                  end;
               5:
                  begin
                     Mode := Digital;
                     ExtendedMode := eRTTY;
                  end;
               6:
                  begin
                     Mode := Digital;
                     ExtendedMode := eData;
                  end;
            end;
         end;

      rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
      //    WriteToSerialCATPort(FT1000MPPoll2String, rig.tCATPortHandle);
      if ReadFromCOMPort(32, rig) then
         with rig.CurrentStatus do
            begin
               TempFreq := round(GetFrequencyForYaesu4(@rig.tBuf[2]) * 0.625);
               CalculateBandMode(TempFreq, TempBand, TempMode);

               case (Ord(rig.tBuf[8]) and $07) of
                  2, 5, 6: TempMode := CW;
                  else
                     TempMode := Phone;
               end;

               VFO[VFOA].Frequency := TempFreq;
               VFO[VFOA].Band := TempBand;
               VFO[VFOA].Mode := TempMode;

               if rig.tBuf[2 + 16] = #$20 then
                  rig.tBuf[2 + 16] := #0;
               TempFreq := round(GetFrequencyForYaesu4(@rig.tBuf[18]) * 0.625);
               CalculateBandMode(TempFreq, TempBand, TempMode);

               { Look at band/mode information from radio }

               case (Ord(rig.tBuf[8 + 16]) and $07) of
                  2, 5, 6: TempMode := CW;
                  else
                     TempMode := Phone;
               end;

               VFO[VFOB].Frequency := TempFreq;
               VFO[VFOB].Band := TempBand;
               VFO[VFOB].Mode := TempMode;
            end;
      rig.WritePollRequest(FT1000MPPoll3String, length(FT1000MPPoll3String));
      //    WriteToSerialCATPort(FT1000MPPoll3String, rig.tCATPortHandle);
      if ReadFromCOMPort(6, rig) then
         begin
            //      rig.CurrentStatus.Split := ((Ord(rig.tBuf[1]) and $01) > 0);
            rig^.CurrentStatus.Split := (Ord(rig.tBuf[1]) and (1 shl 0)) <> 0;
            rig^.CurrentStatus.VFOStatus := ActiveVFOStatusType((Ord(rig.tBuf[2])
               and (1 shl 2)) + 1);
         end;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT920(rig: RadioPtr);
label
   1;
var
   TempFreq: integer;
   TempBand: BandType;
   TempMode: ModeType;
begin

   //  WriteToSerialCATPort(TurnOn847CATString, rig.Port_Handle);
   repeat

      inc(rig.tPollCount);
      rig.WritePollRequest(FT1000MPPoll1String, length(FT1000MPPoll1String));
      //    WriteToSerialCATPort(FT1000MPPoll1String, rig.tCATPortHandle);
      if not ReadFromCOMPort(28, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            Freq := GetFrequencyForYaesu4(@rig.tBuf[2]) + rig^.FrequencyAdder;
            CalculateBandMode(Freq, Band, Mode);

            case (Ord(rig.tBuf[8]) and $07) of
               1: Mode := CW;
               3: Mode := FM;
               4, 5, 6: Mode := Digital;
               else
                  Mode := Phone;
            end;
            XIT := LongBool(Ord(rig.tBuf[9]) and (1 shl 0));
            RIT := LongBool(Ord(rig.tBuf[9]) and (1 shl 1));
         end;
      rig.WritePollRequest(FT1000MPPoll2String, length(FT1000MPPoll2String));
      //    WriteToSerialCATPort(FT1000MPPoll2String, rig.tCATPortHandle);
      if not ReadFromCOMPort(28, rig) then
         begin
            //      ClearRadioStatus(rig);
            goto 1;
         end;

      with rig.CurrentStatus do
         begin
            TempFreq := GetFrequencyForYaesu4(@rig.tBuf[2]);
            CalculateBandMode(TempFreq, TempBand, TempMode);
            case (Ord(rig.tBuf[8]) and $07) of
               1: TempMode := CW;
               3: TempMode := FM;
               4, 5, 6: TempMode := Digital;
               else
                  TempMode := Phone;
            end;

            VFO[VFOA].Frequency := TempFreq;
            VFO[VFOA].Band := TempBand;
            VFO[VFOA].Mode := TempMode;

            TempFreq := GetFrequencyForYaesu4(@rig.tBuf[16]);
            CalculateBandMode(TempFreq, TempBand, TempMode);
            case (Ord(rig.tBuf[22]) and $07) of
               1: TempMode := CW;
               3: TempMode := FM;
               4, 5, 6: TempMode := Digital;
               else
                  TempMode := Phone;
            end;

            VFO[VFOB].Frequency := TempFreq;
            VFO[VFOB].Band := TempBand;
            VFO[VFOB].Mode := TempMode;
         end;

      //3

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFT736R(rig: RadioPtr);
begin
   //  WriteToSerialCATPort(FT767CATEnablePollingString, rig.tCATPortHandle)
   rig.WritePollRequest(FT767CATEnablePollingString,
      length(FT767CATEnablePollingString));
end;

procedure pFT767(rig: RadioPtr);
label
   1;
var
   TempMode: ModeType;
begin
   repeat

      if rig.tPollCount mod 2 <> 0 then
         //      WriteToSerialCATPort(FT767CATEnablePollingString, rig.tCATPortHandle)
         rig.WritePollRequest(FT767CATEnablePollingString,
            length(FT767CATEnablePollingString))
      else
         //      WriteToSerialCATPort(FT767PollString, rig.tCATPortHandle);
         rig.WritePollRequest(FT767PollString, length(FT767PollString));

      if not ReadFromCOMPort(5, rig) then
         goto 1;
      //    WriteToSerialCATPort(FT767ACKString, rig.tCATPortHandle);
      rig.WritePollRequest(FT767ACKString, length(FT767ACKString));

      inc(rig.tPollCount);
      if not ReadFromCOMPort(86, rig) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      rig.CurrentStatus.Freq := GetFrequencyFromBCD(4, @rig.tBuf[82]) * 10 +
         rig^.FrequencyAdder;
      rig.CurrentStatus.VFO[VFOA].Frequency := GetFrequencyFromBCD(4,
         @rig.tBuf[82 - 7]) * 10;
      rig.CurrentStatus.VFO[VFOB].Frequency := GetFrequencyFromBCD(4,
         @rig.tBuf[82 - 19]) * 10;
      CalculateBandMode(rig.CurrentStatus.Freq, rig.CurrentStatus.Band,
         rig.CurrentStatus.Mode);

      TempMode := NoMode;
      case Ord(rig.tBuf[86]) mod 8 of
         0: TempMode := Phone;
         1: TempMode := Phone;
         2: TempMode := CW;
         3: TempMode := Phone;
         4: TempMode := FM;
         5: TempMode := Digital;
      end;
      rig.CurrentStatus.Mode := TempMode;

      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure pFTDX9000(rig: RadioPtr);
label
   1;
var
   TempVFO: VFOStatusType;
begin
   repeat
      inc(rig.tPollCount);

      //    WriteToSerialCATPort('IF;', rig.tCATPortHandle); {information}
      rig.WritePollRequest('IF;', 3);
{$IF NOT POLLINGDEBUG}
      if ((not ReadFromCOMPort(27, rig)) or (PWORD(@rig.tBuf)^ <> $4649)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
{$IFEND}

{$IF POLLINGDEBUG}
      SetVFOA(rig);
{$IFEND}
      GetVFOInfoForFT2000(@rig.tBuf, rig.CurrentStatus.VFO[VFOA],
         rig.FrequencyAdder);

      {opposite band information}
      //WriteToSerialCATPort('OI;', rig.tCATPortHandle);
      rig.WritePollRequest('OI;', 3);

{$IF NOT POLLINGDEBUG}
      if ((not ReadFromCOMPort(27, rig)) or (PWORD(@rig.tBuf)^ <> $494F)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
{$IFEND}

{$IF POLLINGDEBUG}
      SetVFOB(rig);
{$IFEND}
      GetVFOInfoForFT2000(@rig.tBuf, rig.CurrentStatus.VFO[VFOB],
         rig.FrequencyAdder);
      {
      FR
      FT450  - NO
      FT950  - FUNCTION RX
      FT2000 - FUNCTION RX
      FT9000 - RECEIVER STATUS
      }
      TempVFO := rig.CurrentStatus.VFO[VFOA];
      rig^.CurrentStatus.VFOStatus := VFOA;

      if rig.RadioModel in [FT950, FT2000, FTDX9000] then
         begin
            {function rx}
      //      WriteToSerialCATPort('FR;', rig.tCATPortHandle);
            rig.WritePollRequest('FR;', 3);
{$IF NOT POLLINGDEBUG}
            if ((not ReadFromCOMPort(4, rig)) or (PWORD(@rig.tBuf)^ <> $5246))
               then
               begin
                  ClearRadioStatus(rig);
                  goto 1;
               end;
{$IFEND}

{$IF POLLINGDEBUG}
            rig.tBuf[3] := '1';
{$IFEND}
            if rig.tBuf[3] = '4' then
               begin
                  TempVFO := rig.CurrentStatus.VFO[VFOB];
                  rig^.CurrentStatus.VFOStatus := VFOB;
               end
            else
               begin
                  //        TempVFO := rig.CurrentStatus.VFOA;
                  //        rig^.CurrentStatus.VFOStatus := vfoA;
               end;
         end;

      rig.CurrentStatus.Freq := TempVFO.Frequency;
      rig.CurrentStatus.Band := TempVFO.Band;
      rig.CurrentStatus.Mode := TempVFO.Mode;
      //    Windows.SetWindowText(tr4whandle, inttopchar(integer(rig.CurrentStatus.Mode)));
      rig.CurrentStatus.RITFreq := TempVFO.RITFreq;
      rig.CurrentStatus.RIT := TempVFO.RIT;
      rig.CurrentStatus.XIT := TempVFO.XIT;
      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;
//-----

procedure pFT891_FT991(rig: RadioPtr);

label
   1;
var
   TempVFO: VFOStatusType;
begin
   repeat
      inc(rig.tPollCount);

      rig.WritePollRequest('IF;', 3);
         // This retreives VFO A (Primary). Get other VFO with OI; command.
      if ((not ReadFromCOMPort(28, rig)) or
         (PWORD(@rig.tBuf)^ <> $4649)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      GetVFOInfoForYaesuType3(@rig.tBuf, rig.CurrentStatus.VFO[VFOA],
         rig.FrequencyAdder);

      rig.WritePollRequest('OI;', 3); //opposite band information

      if ((not ReadFromCOMPort(28, rig)) or
         (PWORD(@rig.tBuf)^ <> $494F)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      GetVFOInfoForYaesuType3(@rig.tBuf, rig.CurrentStatus.VFO[VFOB],
         rig.FrequencyAdder);

      TempVFO := rig.CurrentStatus.VFO[VFOA];
      rig^.CurrentStatus.VFOStatus := VFOA;

      if rig.RadioModel in [FT991] then
         begin
         rig.WritePollRequest('FT;', 3);         // This retreives which VFO is different, then we are in split.
         if ((not ReadFromCOMPort(4, rig)) {or (PWORD(@rig.tBuf)^ <> $494F) }) then
            begin
            ClearRadioStatus(rig);
            goto 1;
            end;
         if rig.tBuf[3] = '1' then // VFO is the TX
            begin
            rig^.CurrentStatus.Split := true;
            end
         else if rig.tBuf[3] = '0' then
            begin
            rig^.CurrentStatus.Split := false;
            end
         else
            begin
            Logger.Error('Yaesu tBuf after FT; command unexpected result (Split set to false)- ' + rig.tBuf);
            rig^.CurrentStatus.Split := false;
            end;
         end
      else if rig.RadioModel = FT891 then // 891 does not have an FT command. Use ST instead
         begin
         rig.WritePollRequest('ST;', 3);         // This retreives which VFO is different, then we are in split.
         if ((not ReadFromCOMPort(4, rig)) {or (PWORD(@rig.tBuf)^ <> $494F) }) then
            begin
            ClearRadioStatus(rig);
            goto 1;
            end;
         if rig.tBuf[3] = '1' then // VFO is the TX
            begin
            rig^.CurrentStatus.Split := true;
            end
         else if rig.tBuf[3] = '0' then
            begin
            rig^.CurrentStatus.Split := false;
            end
         else
            begin
            Logger.Error('Yaesu FT891 tBuf after ST; command unexpected result (Split set to false)- ' + rig.tBuf);
            rig^.CurrentStatus.Split := false;
            end;
         end;
      //----------------
      rig.WritePollRequest('TX;', 3);
      if ((not ReadFromCOMPort(4, rig)) {or (PWORD(@rig.tBuf)^ <> $4649)}) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      if rig.tBuf[3] in ['1', '2'] then // VFO is the TX
         begin
            rig^.CurrentStatus.TXOn := true;
         end
      else if rig.tBuf[3] = '0' then
         begin
            rig^.CurrentStatus.TXOn := false;
         end
      else
         begin
            Logger.Error('Yaesu tBuf after TX; command unexpected result (TXOn set to false)- ' + rig.tBuf);
            rig^.CurrentStatus.TxOn := false;
         end;

      rig.CurrentStatus.Freq := TempVFO.Frequency;
      rig.CurrentStatus.Band := TempVFO.Band;
      rig.CurrentStatus.Mode := TempVFO.Mode;
      rig.CurrentStatus.ExtendedMode := TempVFO.ExtendedMode;
      //    Windows.SetWindowText(tr4whandle, inttopchar(integer(rig.CurrentStatus.Mode)));
      rig.CurrentStatus.RITFreq := TempVFO.RITFreq;
      rig.CurrentStatus.RIT := TempVFO.RIT;
      rig.CurrentStatus.XIT := TempVFO.XIT;
      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;
//------------------------------------------------------------------------------
procedure pFTDX10_FTDX101(rig: RadioPtr);
     // Even though this was a poor choice of names for a procedure, this procedure
     // does handle other radios--typically newer than the DX10 and DX101 like the FT710
label
   1;
var
   TempVFO: VFOStatusType;
begin
   repeat
      inc(rig.tPollCount);

      rig.WritePollRequest('IF;', 3);
         // This retreives VFO A (Primary). Get other VFO with OI; command.
      if ((not ReadFromCOMPort(28, rig)) or
         (PWORD(@rig.tBuf)^ <> $4649)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      GetVFOInfoForYaesuType5(@rig.tBuf, rig.CurrentStatus.VFO[VFOA],
         rig.FrequencyAdder);

      rig.WritePollRequest('OI;', 3); //opposite band information

      if ((not ReadFromCOMPort(28, rig)) or
         (PWORD(@rig.tBuf)^ <> $494F)) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;

      GetVFOInfoForYaesuType5(@rig.tBuf, rig.CurrentStatus.VFO[VFOB],
         rig.FrequencyAdder);

      TempVFO := rig.CurrentStatus.VFO[VFOA];
      rig^.CurrentStatus.VFOStatus := VFOA;

      rig.WritePollRequest('FT;', 3);         // This retreives which VFO is different, then we are in split.
      if ((not ReadFromCOMPort(4, rig)) {or (PWORD(@rig.tBuf)^ <> $494F) }) then
         begin
         ClearRadioStatus(rig);
         goto 1;
         end;
      if rig.tBuf[3] = '1' then // VFO is the TX
         begin
         rig^.CurrentStatus.Split := true;
         end
      else if rig.tBuf[3] = '0' then
         begin
         rig^.CurrentStatus.Split := false;
         end
      else
         begin
         Logger.Error('Yaesu tBuf after FT; command unexpected result (Split set to false)- ' + rig.tBuf);
         rig^.CurrentStatus.Split := false;
         end;
     

      //----------------
      rig.WritePollRequest('TX;', 3);
      if ((not ReadFromCOMPort(4, rig)) {or (PWORD(@rig.tBuf)^ <> $4649)}) then
         begin
            ClearRadioStatus(rig);
            goto 1;
         end;
      if rig.tBuf[3] in ['1', '2'] then // VFO is the TX
         begin
            rig^.CurrentStatus.TXOn := true;
         end
      else if rig.tBuf[3] = '0' then
         begin
            rig^.CurrentStatus.TXOn := false;
         end
      else
         begin
            Logger.Error('Yaesu tBuf after TX; command unexpected result (TXOn set to false)- ' + rig.tBuf);
            rig^.CurrentStatus.TxOn := false;
         end;

      rig.CurrentStatus.Freq := TempVFO.Frequency;
      rig.CurrentStatus.Band := TempVFO.Band;
      rig.CurrentStatus.Mode := TempVFO.Mode;
      rig.CurrentStatus.ExtendedMode := TempVFO.ExtendedMode;
      //    Windows.SetWindowText(tr4whandle, inttopchar(integer(rig.CurrentStatus.Mode)));
      rig.CurrentStatus.RITFreq := TempVFO.RITFreq;
      rig.CurrentStatus.RIT := TempVFO.RIT;
      rig.CurrentStatus.XIT := TempVFO.XIT;
      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

//-----

function ReadFromSerialPort(BytesToRead: Cardinal; rig: RadioPtr): boolean;
var
   BytesRead: Cardinal;
  // s: string;
begin
   Result := False;
   if BytesToRead > SizeOf(rig^.tBuf) then
      Exit;

   if Windows.ReadFile(rig.tCATPortHandle, rig^.tBuf, BytesToRead, BytesRead, nil
      {rig^.pOver}) then
      if BytesToRead = BytesRead then
         Result := True;
   if logger.IsTraceEnabled then
      begin
      logger.trace('[ReadFromSerialPort] Read %s from serial port',[String2Hex(AnsiLeftStr(ArrayToString(rig^.tBuf),BytesRead))]);
      end;

end;

procedure ClearRadioStatus(rig: RadioPtr);
begin
   logger.debug('Entered ClearRadioStatus');
   {
     if rig.FilteredStatus.TXOn then
     begin
       tPTTStatus := PTT_OFF;
       PTTStatusChanged;
     end;
   }
   Windows.ZeroMemory(@rig^.CurrentStatus, SizeOf(rig^.CurrentStatus));
   Windows.ZeroMemory(@rig^.FilteredStatus, SizeOf(rig^.FilteredStatus));
   rig.CurrentStatus.Mode := NoMode;
   rig.FilteredStatus.Mode := NoMode;
   rig.LastDisplayedFreq := 0;
end;

procedure WriteToDebugFile(port: PortType; MessageType: DebugFileMessagetype; p:
   PChar; Count: Cardinal);
var
   DirectionChar: PChar;
   i, lpNumberOfBytesWritten: Cardinal;
   P1: PChar;
   tChar: Char;
   bgColor: PChar;
   h: HWND;

const
   InOutArray: array[DebugFileMessagetype] of PChar = ('PC >', 'PC <', 'Error');
begin
   if MessageType = dfmRX then
      bgColor := ' BGCOLOR=#00FF00';
   if MessageType = dfmTX then
      bgColor := nil;
   if MessageType = dfmError then
      bgColor := ' BGCOLOR=#FFFF00';

   DirectionChar := InOutArray[MessageType];

   P1 := GetFullTimeString(True);
   // Issue #997: asm wsprintf -> Format
   lpNumberOfBytesWritten := StrLen(StrPCopy(TempBuffer1,
      SysUtils.Format('<TR%s><TD>%s</TD><TD>%s</TD><TD>%s</TD><TD>%d</TD><TD>',
      [string(bgColor), string(P1), string(DirectionChar), string(p), count])));
   h := CPUKeyer.tDebugFile[port];
   sWriteFile(h, TempBuffer1, lpNumberOfBytesWritten);
   if Count > 0 then
      begin
         for i := 0 to Count - 1 do
            begin
               tChar := p[i]; //rig.tBuf[I];
               // Issue #997: asm wsprintf -> Format (%#x = alt-form hex with 0x prefix; no direct Delphi spec)
               lpNumberOfBytesWritten := StrLen(StrPCopy(TempBuffer1,
                  '[0x' + SysUtils.Format('%x', [Ord(tChar)]) + ']'));
               sWriteFile(h, TempBuffer1, lpNumberOfBytesWritten);
            end;
      end;
   sWriteFile(h, '</TD></TR>'#13#10, 12);
end;

function GetFrequencyForYaesu3(p: PChar): Cardinal;
{p ????????? ?? ?????? ???????? ????}
begin
   Result := (Ord(p[0]) * 65536 + Ord(p[1]) * 256 + Ord(p[2])) * 10;
end;

function GetFrequencyForYaesu4(p: PChar): Cardinal;
{p ????????? ?? ?????? ???????? ????}
begin

   Result :=
      Ord(p[0]) * 256 * 256 * 256 +
      Ord(p[1]) * 256 * 256 +
      Ord(p[2]) * 256 +
      Ord(p[3]);

end;

function GetFrequencyFromBCD(Count: Cardinal; Addr: PChar): Cardinal;

var
   F1: Cardinal;
const
   c = 1;
begin
   if Count = 5 then
      begin
         F1 := (Ord(Addr[5 - c]) and $F0) shr 4; { 1000s of mhz }
         F1 := F1 * 10;
         F1 := F1 + (Ord(Addr[5 - c]) and $0F); { 100s of mhz}
         F1 := F1 * 10;
      end
   else
      F1 := 0;

   if Count <> 2 then
      begin
         F1 := F1 + ((Ord(Addr[4 - c]) and $F0) shr 4); { 10s of mhz }
         F1 := F1 * 10;
         F1 := F1 + (Ord(Addr[4 - c]) and $0F); { 1s of mhz}
         F1 := F1 * 10;

         F1 := F1 + ((Ord(Addr[3 - c]) and $F0) shr 4);
         F1 := F1 * 10;
         F1 := F1 + (Ord(Addr[3 - c]) and $0F);
         F1 := F1 * 10;
      end;
   F1 := F1 + ((Ord(Addr[2 - c]) and $F0) shr 4);
   F1 := F1 * 10;
   F1 := F1 + (Ord(Addr[2 - c]) and $0F);

   if F1 > $CCCCCCC then {MAXLONG/10}
      begin
         Result := 0;
         Exit;
      end;

   F1 := F1 * 10;

   F1 := F1 + ((Ord(Addr[1 - c]) and $F0) shr 4);

   if F1 > $CCCCCCC - 256 then {MAXLONG/10-256}
      begin
         Result := 0;
         Exit;
      end;

   F1 := F1 * 10;

   F1 := F1 + (Ord(Addr[1 - c]) and $0F);

   Result := F1;
end;

procedure UpdateStatus(rig: RadioPtr);
var
   StatusChanged: boolean;
   TempInteger: integer;
begin
  //  logger.Trace('UpdateStatus called for %s', [rig.RadioName]);
   StatusChanged := False;
   //  CompareString(LOCALE_SYSTEM_DEFAULT, 0, @rig.CurrentStatus, SizeOf(RadioStatusRecord), @rig.PreviousStatus, SizeOf(RadioStatusRecord)) <> 2;
   for TempInteger := 0 to SizeOf(RadioStatusRecord) - 1 do
      begin
         if PChar(@rig.CurrentStatus)[TempInteger] <>
            PChar(@rig.PreviousStatus)[TempInteger] then
            begin
               StatusChanged := True;
               Break;
            end;
      end;

   //if StatusChanged = True then
   if (StatusChanged) or
      ((UDPBroadcastRadio) and (SecondsBetween(Now, dtLastUDPRadio) > 10) ) then
      begin
         DisplayCurrentStatus(rig); // Update the Radio Window only
         rig.FilteredStatusChanged := True;
      end
   else
      begin
         if rig.FilteredStatusChanged then
            begin
               rig.FilteredStatus := rig.CurrentStatus;
               ProcessFilteredStatus(rig);
               rig.FilteredStatusChanged := False;
            end;
      end;
   rig.PreviousStatus := rig.CurrentStatus;
end;

procedure ProcessFilteredStatus(rig: RadioPtr);
var
   dif: integer;
begin
   if rig.CurrentStatus.Mode = CW then
      if IsCWByCATActive(rig) then
         begin
            if not rig.FilteredStatus.TXOn then
               begin
               if rig.CWByCAT_Sending then
                  // ny4i Moved under this If to only perform when we are sending
                  begin
                  logger.trace('rig.CWByCAT_Sending set to FALSE - %s (%s)',
                           [rig.RadioName, InterfacedRadioTypeSA[rig.RadioModel]]);
                        rig.tmrCWByCAT.Enabled := false;
                           // ny4i Issue 153 Disable timer so we do not fire if we get the this event here
                        //BackToInactiveRadioAfterQSO; // Moved to Timer event // ny4i Issue 153 We have to try here as WK and Serial do it in their threads when not busy
                        rig.CWByCAT_Sending := false;
                        if rig.CheckAutoCallTerminate then
                           begin
                              DebugMsg('rig.CheckAutoCallTerminate is true - Enter ReturnInCQMode');
                              ReturnInCQOpMode;
                           end;
                     end;
               end;
         end;
   // move location of variable dif assignment so it is used for both active and inactive radios K0TI 12/19/2020
   dif := Abs(rig.FilteredStatus.Freq - rig.LastDisplayedFreq);
   if rig = ActiveRadioPtr then
      begin
         if rig.LastDisplayedFreq <> 0 then
            if dif > AutoSAPEnableRate then
               if dif <= 10000 then
                  if AutoSAPEnable and
                     // Issue #795 vs bandmap: #795 made a MANUAL dial QSY clear
                     // the call/exchange in S&P.  But a COMMANDED QSY (bandmap
                     // double-click, spot click, typed freq) also moves the VFO
                     // and may have just placed a call -- don't clobber it.
                     // SetRadioFreq records the commanded VFO-A freq; treat this
                     // as a manual tune (and clear) only if we landed FAR from
                     // the last commanded freq.
                     (Abs(rig.FilteredStatus.Freq - rig.tCommandedQSYFreq) > AutoSAPEnableRate) then // n4af 4.44.10
                    // if OpMode = CQOpMode then    // 4.139.3
                        begin
                           SetOpMode(SearchAndPounceOpMode);
                           tClearDupeInfoCall;
                           ClearAltD; // 4.53.7
                           initializeQSO; // 4.53.5
                           Second := False;
                              // n4af 4.46.7  first esc d/n clear call
                           switchnext := False; // n4af issue  230
                           tCallWindowSetFocus;  // 4.139.1
                        end;
         if rig.CurrentStatus.TxOn then
            begin
               rig.tPTTStatus := PTT_ON;
            end
         else
            begin
               rig.tPTTStatus := PTT_OFF;
            end;
         pTTStatusChanged;
         if rig.FilteredStatus.Freq = 0 then
            Exit;
         if rig.FilteredStatus.Band = NoBand then
            begin
            logger.debug('ProcessFilteredStatus:Radio %s] rig.FilteredStatus.Band = NoBand', [rig.RadioName]);
            logger.debug('ProcessFilteredStatus:Radio %s] rig.FilteredStatus.freq = %d', [rig.RadioName,rig.FilteredStatus.Freq]);
            end;
         logger.Trace('[ProcessFilteredStatus] rig=%s, ' +
                      'BandMemory=%d, FS.Band=%d, ' +
                      'ModeMemory=%d, FS.Mode=%d, ' +
                      'FS.Freq=%d, ActiveBand(before)=%d, ActiveMode(before)=%d',
                      [rig.RadioName, Ord(rig.BandMemory), Ord(rig.FilteredStatus.Band),
                       Ord(rig.ModeMemory), Ord(rig.FilteredStatus.Mode),
                       rig.FilteredStatus.Freq, Ord(ActiveBand), Ord(ActiveMode)]);
         // Guard: NoBand/NoMode are sentinels meaning "not yet reported by radio".
         // Never propagate them into ActiveBand/ActiveMode; they would corrupt the
         // bandmap, dupe sheet, and multiplier displays until the next valid poll.
         if (rig.FilteredStatus.Band <> NoBand) and
            (rig.FilteredStatus.Mode <> NoMode) and
            ((rig.BandMemory <> rig.FilteredStatus.Band) or
             (rig.ModeMemory <> rig.FilteredStatus.Mode)) then
            begin
               ActiveBand := rig.FilteredStatus.Band;
               ActiveMode := rig.FilteredStatus.Mode;
               DisplayBandMode(ActiveBand, ActiveMode, False);
               VisibleDupeSheetChanged := True;

               DisplayCodeSpeed;
               DisplayAutoSendCharacterCount;
               VisibleLog.ShowRemainingMultipliers; //wli

               if QSONumberByBand then
                  DisplayNextQSONumber;

               ShowFMessages(0);
            end;

         if ((dif > 0) and ((rig.FilteredStatus.Freq <> BandMapCursorFrequency)
            or (BandMapMode <> ActiveMode)) and (rig.FilteredStatus.Freq <> 0)) then
            // Gav 4.47.4 #015
            begin
               SpotsList.DisplayCallsignOnThisFreq(rig.FilteredStatus.Freq);
               BandMapCursorFrequency := rig.FilteredStatus.Freq;
               BandMapBand := ActiveBand;
               BandMapMode := ActiveMode;
               BandMapNeedsRefresh := True; // coalesced via 250ms timer � avoids flash on every VFO poll
            end;
      end
   else
      begin // Inactive Radio Processing

         if TuneDupeCheckEnable then
            begin
               SpotsList.TuneDupeCheck(rig.FilteredStatus.Freq);
            end;

         if (rig.BandMemory <> rig.FilteredStatus.Band) or (rig.ModeMemory <>
            rig.FilteredStatus.Mode) then
            begin
               InActiveRadioPtr.UpdateBandOutputInfo(rig.FilteredStatus.Band,
                  rig.FilteredStatus.Mode);
            end;

         //GAV added this section. Changes BandmapBand & Bandmap Mode to follow inactive radio when inactive radio is tuned

         // Issue #908: gate the "follow inactive radio" feature on TwoRadioMode.
         // The legacy LOGWIND.PAS path checked TwoRadioState <> TwoRadiosDisabled;
         // this Gav-added polling path forgot the SO2R gate, so an inactive radio
         // could mutate the bandmap even with TWO RADIO MODE=FALSE.
         //
         // Guard: also skip if the inactive radio has not yet reported real
         // band/mode (NoBand/NoMode are uninitialized sentinels), which would
         // otherwise blank the active radio's bandmap on first poll.
         if TwoRadioMode and
            (rig.FilteredStatus.Band <> NoBand) and
            (rig.FilteredStatus.Mode <> NoMode) and
            (dif > 0) and
            ((rig.FilteredStatus.Freq <> BandMapCursorFrequency) or
             (BandMapMode <> ActiveMode)) and
            (rig.FilteredStatus.Freq <> 0) then
            // Gav 4.47.4 #015
            begin
               BandmapBand := rig.FilteredStatus.Band;
               BandMapMode := rig.FilteredStatus.Mode;
               VisibleDupeSheetChanged := True;
               BandMapCursorFrequency := rig.FilteredStatus.Freq;
               BandMapNeedsRefresh := True; // coalesced via 250ms timer � avoids flash on every VFO poll
            end;

         //GAV End of added

      end;
{$IF tDebugMode}
   {
     if boolean(tPTTStatus) <> rig.FilteredStatus.TXOn then
     begin
       tPTTStatus := PTTStatusType(rig.FilteredStatus.TXOn);
       PTTStatusChanged;
     end;
   }
{$IFEND}
   rig.BandMemory := rig.FilteredStatus.Band;
   rig.ModeMemory := rig.FilteredStatus.Mode;
   rig.LastDisplayedFreq := rig.FilteredStatus.Freq;

end;

procedure DisplayCurrentStatus(rig: RadioPtr);
var
   h: HWND;
   //fa: integer;
begin
   //logger.Debug('Entering DisplayCurrentStatus');
   if rig = ActiveRadioPtr then
      SendStationStatus(sstBandModeFreq);
   if UDPBroadcastRadio then
      begin
      SendRadioInfoToUDP(rig); // ny4i 4.44.9 // Broadcast Radio Info if set
      end;
   //Windows.SetWindowText(rig^.FreqWindowHandle, FreqToPChar(rig.CurrentStatus.Freq));
   h := rig.tRadioInterfaceWndHandle;
   //if h = 0 then Exit;
   //tSetWindowRedraw(h,false);
   if rig.CurrentStatus.VFO[VFOA].Frequency <>
      rig.CurrentStatus.previousVFO[VFOA].Frequency then
      begin
         if TR4W_HAMLIB_DEBUG then
            logger.Info('[DisplayCurrentStatus:%s] VFOA display update: %d ? %d',
               [rig^.RadioName,
                rig.CurrentStatus.previousVFO[VFOA].Frequency,
                rig.CurrentStatus.VFO[VFOA].Frequency]);
         if h <> 0 then
            begin
               SetDlgItemText(h, 102,
                  FreqToPChar(rig.CurrentStatus.VFO[VFOA].Frequency));
            end;
         Windows.SetWindowText(rig^.FreqWindowHandle,
            FreqToPChar(rig.CurrentStatus.Freq));
      end
   else
      begin
         rig.CurrentStatus.previousVFO[VFOA].Frequency :=
            rig.CurrentStatus.VFO[VFOA].Frequency;
      end;
   (*fa := rig.CurrentStatus.VFO[VFOA].Frequency;    // This is so pointless updates do not flicker.
   if fa <> saveVFOAFreq then                      // We need a changed flag so we can check them all.
      begin
      if h <> 0 then
         begin
         SetDlgItemText(h, 102, FreqToPChar(fa));
         end;
      Windows.SetWindowText(rig^.FreqWindowHandle, FreqToPChar(rig.CurrentStatus.Freq));
      end
   else
      begin
      saveVFOAFreq := fa;
      end;
      *)
   if rig.CurrentStatus.VFO[VFOB].Frequency <>
      rig.CurrentStatus.previousVFO[VFOB].Frequency then
      begin
         if TR4W_HAMLIB_DEBUG then
            logger.Info('[DisplayCurrentStatus:%s] VFOB display update: %d ? %d',
               [rig^.RadioName,
                rig.CurrentStatus.previousVFO[VFOB].Frequency,
                rig.CurrentStatus.VFO[VFOB].Frequency]);
         if h <> 0 then
            begin
               SetDlgItemText(h, 104,
                  FreqToPChar(rig.CurrentStatus.VFO[VFOB].Frequency));
            end;
         //Windows.SetWindowText(rig^.FreqWindowHandle, FreqToPChar(rig.CurrentStatus.Freq));
      end
   else
      begin
         rig.CurrentStatus.previousVFO[VFOB].Frequency :=
            rig.CurrentStatus.VFO[VFOB].Frequency;
      end;
   //tSetWindowRedraw(h,true);
   //UpdateWindow(h);
  // ActiveRadioPtr.tPTTStatus :=
   if rig.CurrentStatus.TXOn then
      begin
         ActiveRadioPtr.tPTTStatus := PTT_ON;
      end
   else
      begin
         ActiveRadioPtr.tPTTStatus := PTT_OFF;
      end;

   if rig.CurrentStatus.PrevRITFreq <> rig.CurrentStatus.RITFreq then
      begin
         { $ R A NGECHECKS OFF}
             //SetDlgItemInt(h, 120, Cardinal(rig.CurrentStatus.RITFreq), rig.CurrentStatus.RITFreq < 0);
         SetDlgItemText(h, 120, RITFreqToPchar(rig.CurrentStatus.RITFreq));
         { $ R A NGECHECKS ON}
         rig.CurrentStatus.PrevRITFreq := rig.CurrentStatus.RITFreq;
      end;

   if rig.CurrentStatus.PrevVFOStatus <> rig.CurrentStatus.VFOStatus then
      begin
         if TR4W_HAMLIB_DEBUG then
            logger.Info('[DisplayCurrentStatus:%s] VFOStatus change: %d ? %d',
               [rig^.RadioName,
                Ord(rig.CurrentStatus.PrevVFOStatus),
                Ord(rig.CurrentStatus.VFOStatus)]);
         if rig.CurrentStatus.VFOStatus = VFOA then
            begin
               EnableWindowTrue(h, 102);
               EnableWindowFalse(h, 104);
            end;
         if rig.CurrentStatus.VFOStatus = VFOB then
            begin
               EnableWindowTrue(h, 104);
               EnableWindowFalse(h, 102);
            end;
         if rig.CurrentStatus.VFOStatus = vfoUnknown then
            begin
               EnableWindowTrue(h, 104);
               EnableWindowTrue(h, 102);
            end;
         rig.CurrentStatus.PrevVFOStatus := rig.CurrentStatus.VFOStatus;
      end;

   Windows.EnableWindow(rig.RITWndHandle, rig.CurrentStatus.RIT);
   Windows.EnableWindow(rig.XITWndHandle, rig.CurrentStatus.XIT);
   Windows.EnableWindow(rig.SplitWndHandle, rig.CurrentStatus.Split);

   // Drive the split warning from confirmed radio state, not from CallWindowChange.
   // CallWindowChange fires before CurrentStatus.Split is updated, causing the
   // warning to flicker or appear/disappear at the wrong time in both directions.
   if (rig = ActiveRadioPtr) and
      (rig.PreviousStatus.Split <> rig.CurrentStatus.Split) then
      begin
      if rig.CurrentStatus.Split then
         QuickDisplay(TC_SPLIT_WARN)
      else
         QuickDisplay(nil);
      end;

   // Update VFO A mode label when mode changes (Issue #566)
   if (rig.ModeVFOAWndHandle <> 0) and
      (rig.CurrentStatus.VFO[VFOA].ExtendedMode <>
       rig.CurrentStatus.previousVFO[VFOA].ExtendedMode) then
      begin
      Windows.SetWindowText(rig.ModeVFOAWndHandle,
         PChar(ExtendedModeStringArray[rig.CurrentStatus.VFO[VFOA].ExtendedMode]));
      rig.CurrentStatus.previousVFO[VFOA].ExtendedMode :=
         rig.CurrentStatus.VFO[VFOA].ExtendedMode;
      end;

   // Update VFO B mode label when mode changes (Issue #566)
   if (rig.ModeVFOBWndHandle <> 0) and
      (rig.CurrentStatus.VFO[VFOB].ExtendedMode <>
       rig.CurrentStatus.previousVFO[VFOB].ExtendedMode) then
      begin
      Windows.SetWindowText(rig.ModeVFOBWndHandle,
         PChar(ExtendedModeStringArray[rig.CurrentStatus.VFO[VFOB].ExtendedMode]));
      rig.CurrentStatus.previousVFO[VFOB].ExtendedMode :=
         rig.CurrentStatus.VFO[VFOB].ExtendedMode;
      end;

end;

// Serial liveness indicator: set/clear RadioDisconnected for a serial radio and
// repaint the freq/name windows, only on a state transition.  Deliberately
// mirrors the network-side SetRadioAlertState nested in pNetworkRadio -- kept
// separate so this change does not touch the (battle-tested) network polling
// path; unifying the two is a post-Field-Day cleanup.
procedure SetSerialRadioAlertState(rig: RadioPtr; alertOn: boolean);
begin
   if alertOn = rig^.RadioDisconnected then Exit;   // no change -> do not repaint unnecessarily
   rig^.RadioDisconnected := alertOn;
   if alertOn then
      begin
      logger.Info('[SerialLiveness] %s -> alert color ON', [rig^.RadioName]);
      end
   else
      begin
      logger.Info('[SerialLiveness] %s -> alert color OFF', [rig^.RadioName]);
      end;
   if rig^.FreqWindowHandle <> 0 then
      begin
      Windows.InvalidateRect(rig^.FreqWindowHandle, nil, False);
      end;
   if rig^.RadioNameWndHandle <> 0 then
      begin
      Windows.InvalidateRect(rig^.RadioNameWndHandle, nil, False);
      end;
end;

// Update the serial liveness indicator from one read attempt.  Shared by the
// ReadFromCOMPort wrapper and pKenwood2's inline read loop so the logic lives
// in one place.  A good read re-stamps the last-good time and clears the alert;
// a sustained silence (no good read within the timeout) raises it.
procedure MarkSerialRead(rig: RadioPtr; success: boolean);
const
   SERIAL_LIVENESS_TIMEOUT_MS = 3000;   // declare the serial radio "lost" after this much silence
begin
   if success then
      begin
      rig^.tLastValidResponse := GetTickCount;
      SetSerialRadioAlertState(rig, False);
      end
   else if (GetTickCount - rig^.tLastValidResponse) > SERIAL_LIVENESS_TIMEOUT_MS then
      begin
      SetSerialRadioAlertState(rig, True);
      end;
end;

function ReadFromCOMPortRaw(b: Cardinal; rig: RadioPtr): boolean;
label
   1;
var
   stat: TComStat;
   Errs: DWORD;
   c: Cardinal;
   SleepMs: Cardinal;
begin
{$IF MASKEVENT}
   if rig^.RadioModel in KenwoodRadios then
      begin
         Result := ReadFromCOMPortOnEvent(b, rig);
         Exit;
      end;
{$IFEND}

   //  if NoPollDuringPTT then while rig.tPTTStatus = PTT_ON do Sleep(100);
   Result := False;
   c := 0;
   stat.cbInQue := 0;

   if rig^.RadioModel in [IC78..IC9700, OMNI6] then
      SleepMs := IcomResponseTimeout
   else
      begin
         if b < 5 then
            SleepMs := 100
         else
            SleepMs := 50 {+50};
         if rig^.RadioModel = Orion then
            SleepMs := 100;
      end;

   while stat.cbInQue < {<>}b do
      begin
         Sleep(SleepMs);
         if rig^.tPollCount < 0 then
            Exit;
         if not ClearCommError(rig^.tCATPortHandle, Errs, @stat) then

            ShowSysErrorMessage('READ');

         inc(c);
         if c >= b then
            begin
               1:

               {To view data in Portmon}
               if Errs = 0 then
                  begin
                     if stat.cbInQue <> 0 then
                        ReadFromSerialPort(stat.cbInQue, rig);
                  end
               else
                  begin
                     logger.Error('In ReadFromCOMPort, Errs <> 0 %d', [Errs]);
                     Sleep(100);
                  end;

               PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
               ClearCommError(rig^.tCATPortHandle, Errs, @stat);
               Result := False;
               Exit;
            end;
      end;
   rig.tBuf[b + 1] := #0;
   Result := ReadFromSerialPort(b, rig);

   if rig^.RadioModel in [Orion] then
      begin
         if rig.tBuf[1] <> '@' then
            goto 1;
         if rig.tBuf[b] <> #$0D then
            goto 1;
      end;

   if rig^.RadioModel in KenwoodRadios then
      if rig.tBuf[b] <> ';' then
         goto 1;

   if rig^.RadioModel in [IC706..OMNI6] then
      begin
         if (PWORD(@rig.tBuf[1])^ <> $FEFE) then
            goto 1;

         if rig.tBuf[3] = #0 then
            if not rig.tDisableCIVTransceive then
               begin
                  rig.tDisableCIVTransceive := True;
                  showwarning(TC_DISBALE_CIV);
               end;

         if (rig.tBuf[b] <> ICOM_END_OF_MESSAGE_CODE) or
            (rig.tBuf[4] <> ICOM_CONTROLLER_ADDRESS) then
            goto 1;
      end;

end;

function ReadFromCOMPort(b: Cardinal; rig: RadioPtr): boolean;
begin
   Result := ReadFromCOMPortRaw(b, rig);
   // Serial liveness decorator (shared with pKenwood2's inline loop via
   // MarkSerialRead): a good read keeps the indicator green; sustained silence
   // turns it red.  Decorator only -- reconnect is handled elsewhere.
   MarkSerialRead(rig, Result);
end;

procedure BeginPolling(rig: RadioPtr); stdcall;
begin
   logger.debug('Entered BeginPolling');
   ClearRadioStatus(rig);
   rig^.tLastValidResponse := GetTickCount;   // baseline so the liveness timer can't fire before the first poll
   Sleep(100);  // The polling thread did not start after reset?

   { If the radio is a network interface, we do not care what type of radio as
     the same class gets all the information from the derived radio class type.
     This BeginPolling procedure is fired up as a thread so it may cause some
     strange issues since we have a thread in the network class. TBD
   }
   if rig.tNetObject <> nil then
      begin
      pNetworkRadio(rig);
      Exit;   // Nothing else is done here so exit
      end;

   // The rest is for direct (non-hamlib) serial radio interfaces

   PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);

   Windows.ZeroMemory(@rig.tBuf, SizeOf(rig.tBuf));


   case rig^.RadioModel of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
         TS950, TS990,
         TS2000, FLEX, K2, K3, KX3, K4:
         begin
{$IF MASKEVENT}
            pKenwoodNew(rig);
{$ELSE}
            pKenwood2(rig);
{$IFEND}

         end;
      FT767:
         pFT767(rig);
      FT736R:
         pFT736R(rig);
      FT747GX:
         pFT747GX(rig);
      FT817, FT818, FT847, FT857, FT897:
         pFT817_FT847_FT857_FT897(rig);
      FT840, FT890, FT900:
         pFT840_FT890_FT900(rig);
      FT920:
         pFT920(rig);
      FT990, FT1000:
         pFT990_FT1000(rig);
      FT1000MP:
         pFT1000MP(rig);
      FT100:
         pFT100(rig);
      FT450, FT950, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         pFTDX9000(rig);
      FT891, FT991:
         pFT891_FT991(rig); // ny4i Issue218 9 byte frequency
      FTDX10, FTDX101, FT710:
         pFTDX10_FTDX101(rig);
      FTX1F:
         pFTX1F(rig);
      IC78..IC9700, OMNI6:
         pIcomNew(rig);
      //    pIcom(rig);

{$IF MASKEVENT}
      //    Orion: pOrionNew(rig);
{$ELSE}
      //    Orion: pOrion(rig);
      Orion: pOrion3(rig);
{$IFEND}

   end;
end;

procedure SetDCBForIcom(port: HWND);
var
   TDCB: _DCB;
begin
   GetCommState(port, TDCB);
   SetCommState(port, TDCB);
   SetCommMask(port, EV_RXCHAR);
end;

function ReadICOM(b: Cardinal; rig: RadioPtr): boolean;

begin
   Result := ReadFromCOMPort(b, rig);
end;

function BufferToInt(buf: PChar; StartPos, EndPos: integer): integer;
var
   i: integer;
   negative: boolean;
begin
   negative := False;
   Result := 0;
   for i := StartPos - 1 to StartPos + EndPos - 2 do
      begin
         if not (buf[i] in ['0'..'9', '+', '-']) then
            begin
               Result := 0;
               Exit;
            end;
         if buf[i] in ['0'..'9'] then
            Result := Result * 10 + (Ord(buf[i]) - 48);
         if buf[i] = '-' then
            negative := True;
      end;
   if negative then
      Result := Result * -1;
end;

procedure GetVFOInfoForFT2000(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
var
   TempMode: ModeType;
begin
   TempMode := NoMode; // Issue 116
   VFO.Frequency := BufferToInt(buf, 6, 8) + FrequencyAdder;
   CalculateBandMode(VFO.Frequency, VFO.Band, VFO.Mode);
   VFO.RITFreq := BufferToInt(buf, 14, 5);
   VFO.RIT := buf[19 - 1] = '1';
   VFO.XIT := buf[20 - 1] = '1';
   case buf[21 - 1] of
      '1': TempMode := Phone;
      '2': TempMode := Phone;
      '3': TempMode := CW;
      '4': TempMode := FM;
      '5': TempMode := Phone;

      '6': TempMode := Digital;
      '7': TempMode := CW;
      '8': TempMode := Digital;
      '9': TempMode := Digital;

   end;
   VFO.Mode := TempMode;

end;
//-----
// Issue 218 added this procedure NY4I

procedure GetVFOInfoForYaesuType3(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
var
   TempMode: ModeType;
   TempExtendedMode: ExtendedModeType;
begin
   TempMode := NoMode;
   VFO.Frequency := BufferToInt(buf, 6, 9) + FrequencyAdder;
      // 9 bytes on this radio
   CalculateBandMode(VFO.Frequency, VFO.Band, VFO.Mode);
   VFO.RITFreq := BufferToInt(buf, 15, 5);
   VFO.RIT := buf[20 - 1] = '1';
   VFO.XIT := buf[21 - 1] = '1';
   case buf[22 - 1] of
      '1':
         begin
            TempMode := Phone;
            tempExtendedMode := eLSB;
         end;
      '2':
         begin
            TempMode := Phone;
            tempExtendedMode := eUSB;
         end;
      '3':
         begin
            TempMode := CW;
            tempExtendedMode := eCW;
         end;
      '4':
         begin
            TempMode := FM;
            tempExtendedMode := eFM;
         end;
      '5':
         begin
            TempMode := Phone;
            tempExtendedMode := eAM;
         end;
      '6':
         begin
            TempMode := Digital;
            tempExtendedMode := eRTTY_R;
         end;
      '7':
         begin
            TempMode := CW;
            tempExtendedMode := eCW_R;
         end;
      '8':
         begin
            TempMode := Digital;
            tempExtendedMode := eDATA_R;
         end;
      '9':
         begin
            TempMode := Digital;
            tempExtendedMode := eRTTY;
         end;
      'A':
         begin
            TempMode := Digital;
            tempExtendedMode := eDATA_FM;
         end;
      'B':
         begin
            TempMode := FM;
            tempExtendedMode := eFM_N;
         end;
      'C':
         begin
            TempMode := Digital;
            tempExtendedMode := eData;
         end;
      'D':
         begin
            TempMode := Phone;
            tempExtendedMode := eAM_N;
         end;
      'E':
         begin
            TempMode := FM;
            tempExtendedMode := eC4FM;
         end;
      else
         begin
            logger.Error('Unknown mode value for FT891/991 ' + buf[22 - 1]);
            tempExtendedMode := eNoMode;
         end;

   end;
   VFO.Mode := TempMode;
   VFO.ExtendedMode := tempExtendedMode;

end;
//------
procedure GetVFOInfoForYaesuType5(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);               // FTDX10 because YAESU USES THE SAME MODE CHARACTER FOR c4fm AND psk ON DIFFERENT RADIOS./ dumb!!!!
var
   TempMode: ModeType;
   TempExtendedMode: ExtendedModeType;
begin
   TempMode := NoMode;
   VFO.Frequency := BufferToInt(buf, 6, 9) + FrequencyAdder;
      // 9 bytes on this radio
   CalculateBandMode(VFO.Frequency, VFO.Band, VFO.Mode);
   VFO.RITFreq := BufferToInt(buf, 15, 5);
   VFO.RIT := buf[20 - 1] = '1';
   VFO.XIT := buf[21 - 1] = '1';
   case buf[22 - 1] of
      '1':
         begin
            TempMode := Phone;
            tempExtendedMode := eLSB;
         end;
      '2':
         begin
            TempMode := Phone;
            tempExtendedMode := eUSB;
         end;
      '3':
         begin
            TempMode := CW;
            tempExtendedMode := eCW;
         end;
      '4':
         begin
            TempMode := FM;
            tempExtendedMode := eFM;
         end;
      '5':
         begin
            TempMode := Phone;
            tempExtendedMode := eAM;
         end;
      '6':
         begin
            TempMode := Digital;
            tempExtendedMode := eRTTY_R;
         end;
      '7':
         begin
            TempMode := CW;
            tempExtendedMode := eCW_R;
         end;
      '8':
         begin
            TempMode := Digital;
            tempExtendedMode := eDATA_R;
         end;
      '9':
         begin
            TempMode := Digital;
            tempExtendedMode := eRTTY;
         end;
      'A':
         begin
            TempMode := Digital;
            tempExtendedMode := eDATA_FM;
         end;
      'B':
         begin
            TempMode := FM;
            tempExtendedMode := eFM_N;
         end;
      'C':
         begin
            TempMode := Digital;
            tempExtendedMode := eData;
         end;
      'D':
         begin
            TempMode := Phone;
            tempExtendedMode := eAM_N;
         end;
      'E':
         begin
            TempMode := Digital;
            tempExtendedMode := ePSK31;
         end;
      'F':
         begin
            TempMode := Digital;
            tempExtendedMode := eData_FM;
         end;
      else
         begin
            logger.Error('Unknown mode value for FT891/991 ' + buf[22 - 1]);
            tempExtendedMode := eNoMode;
         end;

   end;
   VFO.Mode := TempMode;
   VFO.ExtendedMode := tempExtendedMode;

end;
//------------------------------------------------------------------------------
procedure GetVFOInfoForYaesuFTX1(buf: PChar; var VFO: VFOStatusType;
   FrequencyAdder: integer);
   // FTX-1F/FTX-1R IF response layout (30 bytes total, Issue #817):
   //   Pos 1-2:   "IF"
   //   Pos 3-7:   P1  VFO/memory channel (5 bytes � 2 longer than FTDX10's 3-byte P1)
   //   Pos 8-16:  P2  VFO frequency Hz (9 bytes)
   //   Pos 17:    P3  Clarifier direction (+/-)
   //   Pos 18-21: P3  Clarifier offset 0000-9990 Hz (4 bytes)
   //   Pos 22:    P4  RX CLAR on/off
   //   Pos 23:    P5  TX CLAR on/off
   //   Pos 24:    P6  Mode
   //   Pos 25:    P7  VFO type
   //   Pos 26:    P8  CTCSS
   //   Pos 27-28: P9  Fixed "00"
   //   Pos 29:    P10 Simplex/shift
   //   Pos 30:    ";"
var
   TempMode         : ModeType;
   TempExtendedMode : ExtendedModeType;
begin
   TempMode := NoMode;
   VFO.Frequency := BufferToInt(buf, 8, 9) + FrequencyAdder;
   CalculateBandMode(VFO.Frequency, VFO.Band, VFO.Mode);
   VFO.RITFreq := BufferToInt(buf, 17, 5);  // direction byte + 4-digit offset
   VFO.RIT     := buf[22 - 1] = '1';        // P4 RX CLAR
   VFO.XIT     := buf[23 - 1] = '1';        // P5 TX CLAR
   case buf[24 - 1] of                       // P6 MODE
      '1':
         begin
         TempMode         := Phone;
         TempExtendedMode := eLSB;
         end;
      '2':
         begin
         TempMode         := Phone;
         TempExtendedMode := eUSB;
         end;
      '3':
         begin
         TempMode         := CW;
         TempExtendedMode := eCW;
         end;
      '4':
         begin
         TempMode         := FM;
         TempExtendedMode := eFM;
         end;
      '5':
         begin
         TempMode         := Phone;
         TempExtendedMode := eAM;
         end;
      '6':
         begin
         TempMode         := Digital;
         TempExtendedMode := eRTTY_R;
         end;
      '7':
         begin
         TempMode         := CW;
         TempExtendedMode := eCW_R;
         end;
      '8':
         begin
         TempMode         := Digital;
         TempExtendedMode := eData_R;
         end;
      '9':
         begin
         TempMode         := Digital;
         TempExtendedMode := eRTTY;
         end;
      'A':
         begin
         TempMode         := Digital;
         TempExtendedMode := eData_FM;
         end;
      'B':
         begin
         TempMode         := FM;
         TempExtendedMode := eFM_N;
         end;
      'C':
         begin
         TempMode         := Digital;
         TempExtendedMode := eData;
         end;
      'D':
         begin
         TempMode         := Phone;
         TempExtendedMode := eAM_N;
         end;
      'E':
         begin
         TempMode         := Digital;
         TempExtendedMode := ePSK31;
         end;
      'F':
         begin
         TempMode         := Digital;
         TempExtendedMode := eData_FM;
         end;
      'H':
         begin
         // C4FM-DN (digital narrow) Yaesu System Fusion digital voice
         TempMode         := Phone;
         TempExtendedMode := eC4FM;
         end;
      'I':
         begin
         // C4FM-VW (digital voice wide) Yaesu System Fusion digital voice
         TempMode         := Phone;
         TempExtendedMode := eC4FM;
         end;
      '0', 'G', 'J':
         begin
         // Unused/reserved mode values in FTX-1 CAT manual
         TempMode         := NoMode;
         TempExtendedMode := eNoMode;
         end;
      else
         begin
         logger.Error('Unknown mode value for FTX-1F: ' + buf[24 - 1]);
         TempMode         := NoMode;
         TempExtendedMode := eNoMode;
         end;
   end;
   VFO.Mode         := TempMode;
   VFO.ExtendedMode := TempExtendedMode;
end;
//------------------------------------------------------------------------------
procedure pFTX1F(rig: RadioPtr);
   // FTX-1F/FTX-1R polling procedure (Issue #817).
   // IF; and OI; responses are 30 bytes (vs 28 for FTDX10) because the
   // VFO/memory-channel field (P1) is 5 bytes instead of 3.
label
   1;
var
   TempVFO: VFOStatusType;
begin
   repeat
      inc(rig.tPollCount);

      rig.WritePollRequest('IF;', 3);
         // Retrieves VFO A (Primary). Get other VFO with OI; command.
      if ((not ReadFromCOMPort(30, rig)) or
         (PWORD(@rig.tBuf)^ <> $4649)) then
         begin
         ClearRadioStatus(rig);
         goto 1;
         end;

      GetVFOInfoForYaesuFTX1(@rig.tBuf, rig.CurrentStatus.VFO[VFOA],
         rig.FrequencyAdder);

      rig.WritePollRequest('OI;', 3);  // Opposite VFO information
      if ((not ReadFromCOMPort(30, rig)) or
         (PWORD(@rig.tBuf)^ <> $494F)) then
         begin
         ClearRadioStatus(rig);
         goto 1;
         end;

      GetVFOInfoForYaesuFTX1(@rig.tBuf, rig.CurrentStatus.VFO[VFOB],
         rig.FrequencyAdder);

      TempVFO := rig.CurrentStatus.VFO[VFOA];
      rig^.CurrentStatus.VFOStatus := VFOA;

      rig.WritePollRequest('FT;', 3);
      if not ReadFromCOMPort(4, rig) then
         begin
         ClearRadioStatus(rig);
         goto 1;
         end;
      if rig.tBuf[3] = '1' then
         rig^.CurrentStatus.Split := true
      else if rig.tBuf[3] = '0' then
         rig^.CurrentStatus.Split := false
      else
         begin
         logger.Error('FTX-1F: unexpected FT; response (Split set to false): ' + rig.tBuf);
         rig^.CurrentStatus.Split := false;
         end;

      rig.WritePollRequest('TX;', 3);
      if not ReadFromCOMPort(4, rig) then
         begin
         ClearRadioStatus(rig);
         goto 1;
         end;
      if rig.tBuf[3] in ['1', '2'] then
         rig^.CurrentStatus.TXOn := true
      else if rig.tBuf[3] = '0' then
         rig^.CurrentStatus.TXOn := false
      else
         begin
         logger.Error('FTX-1F: unexpected TX; response (TXOn set to false): ' + rig.tBuf);
         rig^.CurrentStatus.TXOn := false;
         end;

      rig.CurrentStatus.ExtendedMode := TempVFO.ExtendedMode;
      rig.CurrentStatus.RITFreq     := TempVFO.RITFreq;
      rig.CurrentStatus.RIT         := TempVFO.RIT;
      rig.CurrentStatus.XIT         := TempVFO.XIT;
      1:
      UpdateStatus(rig);
   until rig.tPollCount < 0;
end;

procedure SetVFOA(rig: RadioPtr);
begin
{$IF POLLINGDEBUG}
   Sleep(500);

   rig.tBuf[6] := '0';
   rig.tBuf[7] := '3';
   rig.tBuf[8] := '6';
   rig.tBuf[9] := CHR(Random(8) + Ord('0'));
   rig.tBuf[10] := '0';
   rig.tBuf[11] := '0';
   rig.tBuf[12] := '0';
   rig.tBuf[13] := '0';

   rig.tBuf[14] := '+';
   rig.tBuf[15] := '1';
   rig.tBuf[16] := '2';
   rig.tBuf[17] := '3';
   rig.tBuf[18] := '4';

   rig.tBuf[21] := '2';
{$IFEND}
end;

procedure SetVFOB(rig: RadioPtr);
begin
{$IF POLLINGDEBUG}
   Sleep(500);
   rig.tBuf[6] := '2';
   rig.tBuf[7] := '1';
   rig.tBuf[8] := '2';
   rig.tBuf[9] := CHR(Random(8) + Ord('0'));
   rig.tBuf[10] := '0';
   rig.tBuf[11] := '0';
   rig.tBuf[12] := '0';
   rig.tBuf[13] := '0';

   rig.tBuf[14] := '+';
   rig.tBuf[15] := '1';
   rig.tBuf[16] := '2';
   rig.tBuf[17] := '3';
   rig.tBuf[18] := '4';

   rig.tBuf[21] := '1';
{$IFEND}
end;

function getIcomResponceSpeed(rig: RadioPtr): boolean;
label
   1;
var
   c: Cardinal;
   stat: TComStat;
   Errs: DWORD;
   counter: integer;
begin
   Result := False;
   counter := 0;
   rig.SendIcomCommand(3);
   if rig.RadioModel = IC735 then
      c := 16
   else
      c := 17;
   ClearCommError(rig^.tCATPortHandle, Errs, @stat);
   1:
   if stat.cbInQue <> c then
      begin
         inc(counter);
         Sleep(10);
         if counter < 100 then
            goto 1;
      end
   else
      begin
         Result := True;
         IcomResponseTimeout := (counter * 10) div c;
      end;
   PurgeComm(rig^.tCATPortHandle, PURGE_RXCLEAR or PURGE_RXABORT);
end;

procedure PTTStatusChanged;
begin
   if ActiveRadioPtr.tPTTStatus = PTT_ON then
      begin
         tr4w_PTTStartTime := GetTickCount
      end
   else //n4af 04.30.3
      begin
         if ActiveRadioPtr.CurrentStatus.Mode = CW then
            if IsCWByCATActive then
               begin
                  ActiveRadioPtr.CWByCAT_Sending := false;
                     // If we were sending but the PTT goes off, now reset this.
                  BackToInactiveRadioAfterQSO; // ny4i Issue 153 We have to try here as WK and Serial do it in their threads when not busy
                  logger.trace('[Active] CWByCAT_Sending set to FALSE - %s (%s)',
                     [ActiveRadioPtr.RadioName, InterfacedRadioTypeSA[ActiveRadioPtr.RadioModel]]);
                  tStartAutoCQ; // this is totally bizzare but the way autocqresume works is you call this and it checks.
               end;
         if tr4w_PTTStartTime <> 0 then
            begin
               tRestartInfo.riPTTOnTotalTime := tRestartInfo.riPTTOnTotalTime +
                  GetTickCount - tr4w_PTTStartTime;
            end;
      end;

   tDispalyOnAirTime;
   SetMainWindowText(mwePTTStatus, PTTStatusString[ActiveRadioPtr.tPTTStatus]);
   SendStationStatus(sstPTT);
end;

function GetFrequencyForYaesuFT747(a: PChar): Cardinal;
var
   c: integer;
begin
   Result := 0;
   for c := 0 to 4 do
      begin
         Result := Ord(a[c]) div 16 + (Result * 10);
         Result := Ord(a[c]) mod 16 + (Result * 10);
      end;
end;

procedure SendRadioInfoToUDP(rig: RadioPtr);
var
   sBuf: AnsiString;
   sMode: AnsiString;
   // msg   : TIdBytes;
   freq: integer;
   txFreq: integer;
begin

   { Example of message from N1MM
   <RadioInfo>
           <RadioNr>1</RadioNr>
           <Freq>1809738</Freq>
           <TXFreq>1809738</TXFreq>
           <Mode>USB</Mode>
           <OpCall>NY4I</OpCall>
           <IsRunning>False</IsRunning>
           <FocusEntry>1389988</FocusEntry>
           <Antenna>-1</Antenna>
           <Rotors>-1</Rotors>
           <FocusRadioNr>1</FocusRadioNr>
   </RadioInfo>
   }
   if rig.CurrentStatus.Split then
      begin
         txFreq := rig.CurrentStatus.VFO[VFOB].Frequency;
         freq := rig.CurrentStatus.Freq;
      end
   else
      begin
         txFreq := rig.CurrentStatus.Freq;
         freq := rig.CurrentStatus.Freq;
      end;

   case rig.CurrentStatus.Mode of
      CW: sMode := 'CW';
      Phone:
         if freq < 10000000 then
            // It seems like this should be in the radio object instead of us guessing // ny4i
            begin
               sMode := 'LSB';
               if (freq > 5300000) and (freq < 5400000) then
                  begin
                     sMode := 'USB';
                  end;
            end
         else
            begin
               sMode := 'USB';
            end;
      Digital: sMode := 'RTTY';
      else
         sMode := ' ';
   end; // of case
   sMode := ExtendedModeStringArray[rig.currentStatus.ExtendedMode];
   sBuf := '<?xml version="1.0" encoding="utf-8"?>' + sLineBreak +
      '<RadioInfo>' + sLineBreak +
      #9 + '<app>TR4W</app>' + sLineBreak +
      #9 + '<StationName>' +  GetLocalComputerName + '</StationName>' + sLineBreak +
      // Per N1MM RadioInfo spec: RadioNr identifies the packet's subject
      // radio (1 or 2), not whichever radio is currently active.  In SO2R,
      // each radio emits its own packet with its own number.
      #9 + '<RadioNr>' + Format('%d',[Math.IfThen(rig = @Radio1,1,2)]) + '</RadioNr>' + sLineBreak +
      #9 + '<Freq>' + Format('%d', [freq div 10]) + '</Freq>' + sLineBreak +
      #9 + '<TXFreq>' + Format('%d', [txFreq div 10]) + '</TXFreq>' + sLineBreak +
      #9 + '<Mode>' + sMode + '</Mode>' +  sLineBreak +
      #9 + '<OpCall>' + CurrentOperator + '</OpCall>' +  sLineBreak +
      #9 + '<IsRunning>' + StrUtils.IfThen(OpMode = SearchAndPounceOpMode,'False','True') + '</IsRunning>' + sLineBreak +
      #9 + '<FocusEntry>0</FocusEntry>' + sLineBreak +
      #9 + '<EntryWindowHwnd>' + '0' + '</EntryWindowHwnd>' + sLineBreak +
      #9 + '<Antenna>-1</Antenna>' + sLineBreak +
      #9 + '<Rotors>-1</Rotors>' + sLineBreak +
      // FocusRadioNr / ActiveRadioNr: which radio has operator focus right now.
      // TR4W tracks this as the global ActiveRadio; both fields reflect it.
      #9 + '<FocusRadioNr>' + Format('%d',[Math.IfThen(ActiveRadio = RadioOne,1,2)]) + '</FocusRadioNr>' + sLineBreak +
      #9 + '<IsStereo>' + 'False' + '</IsStereo>' + sLineBreak +
      #9 + '<IsSplit>' + StrUtils.IfThen(rig.CurrentStatus.Split,'True','False') + '</IsSplit>' + sLineBreak +
      #9 + '<ActiveRadioNr>' + Format('%d',[Math.IfThen(ActiveRadio = RadioOne,1,2)]) + '</ActiveRadioNr>' + sLineBreak +
      #9 + '<IsTransmitting>' + StrUtils.IfThen(rig.CurrentStatus.TXOn,'True','False') + '</IsTransmitting>' + sLineBreak +
      #9 + '<FunctionKeyCaption>' + '' + '</FunctionKeyCaption>' + sLineBreak +
      #9 + '<RadioName>' + rig.RadioName + '</RadioName>' + sLineBreak +
      // N1MM RadioInfo IsConnected (Issue #917).  Source: rig.RadioDisconnected,
      // which is maintained by pNetworkRadio's SetRadioAlertState for network
      // radios (Icom CI-V/IP, K4 TCP, FlexRadio, HamLib Direct, TS-890 LAN).
      // The legacy serial polling threads (pYaesu/pIcom/pKenwood/pK3/etc.)
      // do not currently update RadioDisconnected, so this reports True for
      // serial-attached radios whenever one is configured -- real serial
      // CAT-port liveness detection is a separate follow-up.
      #9 + '<IsConnected>' + StrUtils.IfThen(rig.RadioDisconnected,'False','True') + '</IsConnected>' + sLineBreak +
      '</RadioInfo>';

   //SetLength(msg,Length(sBuf));
   //msg := RawToBytes(sBuf[1], Length(sBuf));
   try
      udp.BroadcastEnabled := true;
      udp.Send(UDPBroadcastAddress, UDPBroadcastPortRadio, sBuf); // ny4i 4.44.9
      logger.trace('[SendRadioInfoToUDP] %s', [sBuf]);
      dtLastUDPRadio := Now;
   except
      on E: Exception do
         // ShowMessage(PChar('Exception in SendRadioInfoToUDP. Message = '));
   end;
end; // SendRadioInfoToUDP;

procedure SetVFOModeExtendedMode(rig: RadioPtr; which: Cardinal; mode: ModeType;
   em: ExtendedModeType);
begin
   if which = 0 then
      begin
         rig.CurrentStatus.VFO[VFOA].Mode := mode;
         rig.CurrentStatus.VFO[VFOA].ExtendedMode := em;  // was VFOB � copy-paste bug
         rig.CurrentStatus.Mode := mode;
         rig.CurrentStatus.ExtendedMode := em;
      end
   else if which = 1 then
      begin
         rig.CurrentStatus.VFO[VFOB].Mode := mode;
         rig.CurrentStatus.VFO[VFOB].ExtendedMode := em;
      end
   else
      begin
         DEBUGMSG('In SetVFOModeExtendedMode, which is not valid ' +
            IntToStr(which));
      end;
end;

function ArrayToString(const a: array of Char): string;
begin
  if Length(a)>0 then
    SetString(Result, PChar(@a[0]), Length(a))
  else
    Result := '';
end;

end.
