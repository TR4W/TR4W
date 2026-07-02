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
unit LogK1EA;

{$F+}
{$IMPORTEDDATA OFF}
interface

uses {Dos, Crt, SlowTree,} Tree,
  uWinKey,
  TF,
  VC,
  BeepUnit,
//  DLPortIO,
  uIO,
  MMSystem,
  Messages,
  Windows;
//procedure TimerInterrupt(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall;
const

  ElementLengthConstant                 = 1200;
  CWBufferSize                          = 1024 * 2 - 1;
  CommandBufferSize                     = 256; { Buffer size for data sent to serial ports }

  { Parallel port bit assignments:  (Bits are shown 0 to 7.  0 = LSB)

    Pin     Port    Bit    Description
    ---     ----    ---    -----------
     1     Base+2    0     Input/Output - Output to emitters of transistors.
     2     Base+0    0     Output - Band bit 0 or DVK Clear
     3     Base+0    1     Output - DVK #1
     4     Base+0    2     Output - DVK #2
     5     Base+0    3     Output - DVK #3 or WX0B SO2R Stereo/Mono KK1L: 6.71
     6     Base+0    4     Output - DVK #4
     7     Base+0    5     Output - Band bit 1 or DVK #5 KK1L: 6.71
     8     Base+0    6     Output - Band bit 2 or DVK #6 KK1L: 6.71
     9     Base+0    7     Output - Band bit 3 or WX0B SO2R Stereo/Mono KK1L: 6.71
    10
    11
    12     Base+1    5     Input - Dit paddle
    13     Base+1    4     Input - Dah paddle
    14     Base+2    1     Input/Output - Used for paddle pullup or relay.
    15     Base+1    3     Input - Foot switch input.
    16     Base+2    2     Input/Output - Output PTT
    17     Base+2    3     Input/Output - Output CW

    18-25                  Grounds

    None   Base+2    5     W9XT card record bit (set to 1, pulse memory, then
                           clear this bit to stop recording).

    BIT Patterns for Band bits:

    BAND   9   8   7   2      Value written to I/O port
    ----  --- --- --- ---     -------------------------
    160   lo  lo  lo  hi      $01   $00 is written if not one of these bands.
     80   lo  lo  hi  lo      $20
     40   lo  lo  hi  hi      $21
     30   lo  hi  lo  lo      $40
     20   lo  hi  lo  hi      $41
     17   lo  hi  hi  lo      $60
     15   lo  hi  hi  hi      $61
     12   hi  lo  lo  lo      $80
     10   hi  lo  lo  hi      $81
      6   hi  lo  hi  lo      $A0
      2   hi  lo  hi  hi      $A1
    222   hi  hi  lo  lo      $C0
    432   hi  hi  lo  hi      $C1
    902   hi  hi  hi  lo      $E0
    1296  hi  hi  hi  hi      $E1

  And if anyone is ever wondering about the Mem [$40:$17] bits

         1 = Right Shift
         2 = Left Shift
         4 = Control Key
         8 = Alt key pressed
        10 = Scroll Lock Active
        20 = Num lock on
        40 = Caps lock on
        80 = Insert mode on

  }

type

  FootSwitchModeType = (
    FootSwitchDisabled,
    CWGrant,
    FootSwitchF1,
    FootSwitchLastCQFreq,
    FootSwitchNextBandMap,
    FootSwitchNextDisplayedBandMap, {KK1L: 6.64}
    FootSwitchNextMultBandMap, {KK1L: 6.68}
    FootSwitchNextMultDisplayedBandMap, {KK1L: 6.68}
    FootSwitchUpdateBandMapBlinkingCall,
    FootSwitchDupecheck,
    Normal,
    QSONormal,
    QSOQuick,
    FootSwitchControlEnter,
    StartSending,
    SwapRadio
    );

  BeepType = (Beepsingle, BeepCongrats, ThreeHarmonics, PromptBeep, Warning, WakeUp, Congrats);

  CWElementRecord = record
    length: integer;
    Key: boolean;
  end;

  K1EAKeyer = object
    tDebugFile: array[Serial1..Serial20] of HWND {Text};

    tr4w_PortDebug: array[Serial1..Serial20] of boolean;
    NumberInterruptConstant: integer;

//    CurtisModeA: boolean;
    CodeSpeed: integer;

    KeyerInitialized: boolean;

    OldInt0BVector, OldInt0CVector: Pointer;

    //wli      SerialPortConfigured: array[Serial1..Serial9] of boolean;
    SerialPortConfigured_Handle: array[Serial1..Serial20] of HWND;
    SerialPortDebug: boolean;

    //    SerialPortOutputBuffer: array[Serial1..Serial9] of CharacterBuffer;
    //    SerialPortInputBuffer: array[Serial1..Serial9] of CharacterBuffer;

    //ua4wli    SerialPortDefaultDelay: array[Serial1..Serial9] of integer;
    //ua4wli    SerialPortDelay: array[Serial1..Serial9] of integer;

    //    SlowInterrupts: boolean;

    //    UseIRQs: boolean;

    //    procedure AddSerialPortCharacter(port: PortType; Character: Char);
//    procedure AddSerialPortString(port: PortType; data: Str80);

    procedure AddCharacterToCWBuffer(Character: Char);
    procedure AddStringToCWBuffer(Msg: Str160; Tone: integer);
    function BufferEmpty: boolean;
//    procedure CheckPTT;
    //    procedure CheckSerialPortReceiveData(SerialPort: PortType);
    //    procedure CheckSerialPortSendData(SerialPort: PortType);
    procedure ClearSerialPortInputBuffer(port: PortType);

    function CWStillBeingSent: boolean;
    procedure Dah;
    procedure Dat;
    function DeleteLastCharacter: boolean;
    procedure Dit;

    procedure FlushCWBuffer;
    procedure IncrementBufferEnd;
    procedure InitializeKeyer;

//    procedure PTTForceOn;
//    procedure PTTUnForce;
    procedure SetSpeed(Speed: integer {byte});

    {PROCEDURE}function SetUpSerialPort(port: PortType;
      BaudRate: Word;
      Bits: integer;
      Parity: ParityType;
      StopBits: SHORTINT;
      DefaultDelay: SHORTINT): HWND;

    procedure UnInitializeKeyer;
  end;

  RealTimeCWElementRecords = record
    CWSendStatus: boolean;
    ClockCount: Word;
  end;

  RealTimeMessageType = array[0..1024] of RealTimeCWElementRecords;

  RealTimeMessagePointer = ^RealTimeMessageType;

const
  FootSwitchModeTypeStringArray         : array[FootSwitchModeType] of PChar =
    (
    'DISABLED',
    'CW GRANT',
    'F1',
    'LAST CQ FREQ',
    'NEXT BANDMAP',
    'NEXT DISP BANDMAP',
    'NEXT MULT BANDMAP',
    'NEXT MULT DISP BANDMAP',
    'UPDATE BAND MAP BLINKING CALL',
    'DUPE CHECK',
    'NORMAL',
    'QSO NORMAL',
    'QSO QUICK',
    'CONTROL ENTER',
    'START SENDING',
    'SWAP RADIOS'
    );

var

{$IF CWDEBUG}
  cwDebugArray                          : array[0..1000] of integer;
{$IFEND}

  //   ii:integer;

//  tHighCWPerformance                    : boolean ;
//  TimerResolutionIsSet                  : boolean ;

  tPaddlePortBaseAddress                : HWND = INVALID_HANDLE_VALUE;
  tFootSwitchPortBaseAddress            : HWND = INVALID_HANDLE_VALUE;
  tRelayControlPortBaseAddress          : HWND = INVALID_HANDLE_VALUE;
  tActiveStereoPortBaseAddress          : HWND = INVALID_HANDLE_VALUE;

  tUseControlPort                       : boolean;

  TR4W_BeepThread                       : HWND;
  tPaddleFootSwitchThread               : HWND = INVALID_HANDLE_VALUE;

  tExitFromPaddleFootSwitchThread       : boolean;
  tPTTOnCounter                         : Cardinal;
  PaddlePTTOn                           : boolean;
  TR4W_BeepThreadID                     : Cardinal;
  tPaddleThreadID                       : Cardinal;
  tFlashQDThreadID                      : Cardinal;

  tCW_Event                             : Cardinal;
  tCWPaddle_Event                       : Cardinal;
  tDVP_Event                            : Cardinal;
//  tWaitForNextCharEvent                 : Cardinal;

  tDVPTimerEventID                      : Cardinal;
  tExitFromDVPThread                    : boolean;
  //   tNetEvent                       : Cardinal;

  ActiveDVKPort                         : PortType; //���� ������
  ActiveFootSwitchPort                  : PortType {= NoPort};
//  ActiveKeyerPort                       : PortType {= NoPort};
//  tActiveKeyerHandle                    : HWND = INVALID_HANDLE_VALUE;

  ActivePaddlePort                      : PortType {= NoPort};
  ActiveRadio                           : RadioType = RadioOne;

  InactiveRadio                         : RadioType = RadioTwo; {KK1L: 6.73}
  ActiveStereoPort                      : PortType {= NoPort}; {KK1L: 6.71}

  BeepEnable                            : boolean = False; //N4AF performance change
  BeepFreq                              : integer = 1200;

//  CountsSinceLastCW                     : LONGINT = 0;
  CPUKeyer                              : K1EAKeyer =
    (
//    CurtisModeA: False;
    CodeSpeed: 35;
    KeyerInitialized: False;
    SerialPortConfigured_Handle: (INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE)
    );

  CQRITEnabled                          : boolean = True;

  DVKDelay                              : integer;
  DVKPortAddress                        : Word;
  DVPOn                                 : boolean;
  DVKClearAllBits                       : Byte = $80;
  DVKClearMessageBits                   : Byte = $81;
  ElementLength                         : integer;

  EnableSixDVKMessages                  : boolean = True;

  FarnsworthEnable                      : boolean;
  FarnsworthSpeed                       : integer = 25;
  FootSwitchDebug                       : boolean;
  FootSwitchMode                        : FootSwitchModeType {= FootSwitchDisabled};
  tFootSwitchPressed                    : boolean;

  MonitorTone                           : integer = 700;

  NoPollDuringPTT                       : boolean;

  PaddleActive                          : boolean;
  PaddleBug                             : boolean;
  PaddleBugDahBeingSent                 : boolean;
  PaddlePTTOffTimerCount                : integer;
  PaddlePTTHoldCount                    : integer = 13;
  PaddlePTTOffTimer                     : integer;
  PaddleMonitorTone                     : integer = 700;
  PaddleSpeed                           : integer;
  tPaddleElementLength                  : Cardinal;

  PortBeingUsed                         : PortType {= NoPort};
  PTTEnable                             : boolean = True;
  PTTLockout                            : boolean;
  PTTTurnOnDelay                        : integer = 15;
  tPTTViaCommand                        : boolean;
  tr4w_PTTStartTime                     : DWORD;
  tElapsedTimeFromLastQSO               : DWORD;

//  tPTTStatus                            : PTTStatusType = PTT_OFF;
  {
    tr4w_lpt1_address                     : word = $378;
    tr4w_lpt2_address                     : word = $278;
    tr4w_lpt3_address                     : word = $3BC;
  }


  Radio1SerialInvert                    : boolean;
  Radio2SerialInvert                    : boolean;
//  RadioDebugWrite                       : file;

  RealTimeCWMessageArrayType            : array[0..9] of RealTimeMessagePointer;
  RealTimeCWMessagePlaying              : boolean;
  RealTimeCWMessageRecording            : boolean;
  REalTimeCWMessageActive               : integer; { 0 through 9 }
  RealTimeCWMessageAddress              : integer; { 0 through 1024 }

  RelayControlPort                      : PortType {= NoPort};
  RememberCodeSpeed                     : integer;
  RITEnable                             : boolean = True;

  SerialInvert                          : boolean;
  ShiftKeyEnable                        : boolean = True;
  StereoControlPin                      : integer = 9;
  StereoPinState                        : boolean;
  SwapPaddles                           : boolean;
  SwapRadioRelaySense                   : boolean;

  TalkDebugWrite                        : file;
  TuningWithDits                        : boolean;
  //  Trace                                 : boolean;
  Tuning                                : boolean;
  TuneWithDits                          : boolean;

  Weight                                : REAL = 1.0;

  ActiveBeep                            : BeepType;
  CWMessageToNetwork                    : string[CWMessageToNetworkLength];

procedure DoABeep(TypeOfBeep: BeepType);

procedure DVKEnableWrite;
procedure DVKDisableWrite;
function DVKMessagePlaying: boolean;
procedure OutputBandInfo(BaseAddress: HWND {ParallelPort: PortType}; Band: BandType; Mode: ModeType);
procedure SetDVKDelay(Delay: integer);
procedure SetRelayForActiveRadio(Radio: RadioType);
procedure SetStereoPin(PinNumber: integer; PinSet: boolean); {KK1L: 6.71}
procedure StartDVK(MemorySwitch: integer);

procedure SendCWBufferStart;
procedure CWThreadProc;
procedure tDoABeep;
procedure tAutoCQTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall;
procedure tCWSleep(millsec, myEvent: Cardinal);
procedure tPaddleFootSwitchThreadProc;

procedure tSetPaddleElementLength;
function DisplayByte(b: Byte): string;
procedure tFootSwitchProcedure;
function tGetPortType(port: PortType): PortInterface;
//procedure testF(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall;
procedure BackToInactiveRadioAfterQSO;
procedure tSetPriorityClass(dwPriorityClass: DWORD);

procedure TurnOnActivePort;
procedure tStartAutoCQ;
function tStartAutoCallTerminate(idAttach: DWORD): boolean;

var
  DoingPaddle                           : boolean;
  tDoingFootSwitchEnable                : boolean;

  CWBufferStart                         : integer;
  CWBufferEnd                           : integer;
  tWaitForNextChar                      : boolean;
//  tAllowIncrementCWBufferStart          : boolean = True;
  tDitDahRatio                          : integer = 3;
implementation

uses
  uProcessCommand,
  uTelnet,
  LOGSUBS2,
  uRadioPolling,
  LogCW,
  MainUnit,
  LogWind,
  LogStuff,
  LOGSUBS1,
  LogRadio;

const
  ParallelOutputPullupOffset            = 5;
  ParallelOutputAddressOffset           = 2;
  ParallelInputAddressOffset            = 1;

type
  SendStatusType = (NothingBeingSent, DitBeingSent, DahBeingSent);

  CWBufferType = array[0..CWBufferSize] of CWElementRecord;
  CWBufferPtr = ^CWBufferType;

var

  CWBuffer                              : CWBufferPtr;
  CWBufferAvailable                     : boolean;

  CWElementLength                       : integer;

  CWLPT1Image                           : Byte = $08;
  CWLPT2Image                           : Byte = $08;
  CWLPT3Image                           : Byte = $08;

  DahMemory                             : boolean;
  DitMemory                             : boolean;
  DelayCount                            : LONGINT; { Used for Wait procedure }
  DoingDVK                              : boolean;

  DVKTimeOut                            : integer;

  FootSwitchState                       : boolean;
  FootSwitchCount                       : integer = 5;

  FrameEscapeFound                      : boolean;

  LPT1Image                             : Byte;
  LPT2Image                             : Byte;
  LPT3Image                             : Byte;

  LastFootSwitchStatus                  : boolean;

  ModemCharacterSentDelayCount          : integer;
  ModemDelayCount                       : integer;
  ModemReceiveMessage                   : Str80;
  ModemPortAddress                      : Word;
//  ModemTestAddress                      : Word;

//  NumberInterruptsConstant              : integer;
//  NumberInterrupts                      : integer;
  OldInt08Vector                        : Pointer;

  PTTDelayCount                         : integer; { When non zero, indicates that
  PTT turn on delay is in progress }

//  PTTAsserted                           : boolean; { Indicates that the PTT signal is asserted.  Comes on PTTTurnOnDelay before CW starts.  }

  PTTFootSwitch                         : boolean; { Indicates that the footswitch wants the PTT
  to be on. }

//  PTTForcedOn                           : boolean = False; { Indicates that someone wants the PTT to stay  on until they turn it off. }

 //    Regs:                 Registers;
  RememberRIT                           : boolean;

  SendStatus                            : SendStatusType;
  SendingADah                           : boolean;
  SerialPort                            : PortType;

function DisplayByte(b: Byte): string;

const
  HexChars                              : array[0..$F] of Char = '0123456789ABCDEF';
begin
  Result := HexChars[b shr 4] + HexChars[b and $F];
end;

procedure DisplayWord(w: Word);

const
  HexChars                              : array[0..$F] of Char = '0123456789ABCDEF';
begin
  Write(HexChars[Hi(w) shr 4],
    HexChars[Hi(w) and $F],
    HexChars[Lo(w) shr 4],
    HexChars[Lo(w) and $F]);
end;

{
procedure K1EAKeyer.AddSerialPortCharacter(port: PortType; Character: Char);

var
  DebugString                           : string;

begin

   // Check to see if the buffer is full - if so, we wait here

  if SerialPortOutputBuffer[port].FreeSpace = 0 then
  begin
    if SerialPortOutputBuffer[port].Debug then
    begin
      DebugString := ' **BUFFER FULL** ';
//wli      BlockWrite(SerialPortOutputBuffer[port].DebugFile, DebugString, length(DebugString) + 1);
    end;

    while SerialPortOutputBuffer[port].FreeSpace = 0 do ;
  end;

  SerialPortOutputBuffer[port].AddEntry(ord(Character));
end;
}
{
procedure K1EAKeyer.AddSerialPortString(port: PortType; data: Str80);
var
  PortHWND                              : HWND;
begin
  if Radio1.tCATPortType = port then PortHWND := Radio1.tCATPortHandle;
  if Radio2.tCATPortType = port then PortHWND := Radio2.tCATPortHandle;
  WriteToSerialCATPort(data, PortHWND);
end;
}

procedure StartDVK(MemorySwitch: integer);

var
  Image                                 : Byte;

begin
  if not DVPOn then Exit;

  case MemorySwitch of
    0:
      begin
        {           IF (Radio1BandOutputPort <> ActiveDVKPort) AND
                      (Radio2BandOutputPort <> ActiveDVKPort) THEN
                         }Image := $1 { Abort message }
        {              ELSE
                          Exit;
                  }
      end;

    1: Image := $2; { Memory one   }
    2: Image := $4; { Memory two   }
    3: Image := $8; { Memory three }
    4: Image := $10; { Memory four  }
    {5: IF EnableSixDVKMessages THEN Image := $20 ELSE Exit; {KK1L: 6.71}{KK1L: 6.72 added IF}{KK1L: 6.73}
    {6: IF EnableSixDVKMessages THEN Image := $40 ELSE Exit; {KK1L: 6.71}{KK1L: 6.72 added IF}{KK1L: 6.73}
    5: Image := $20; { Memory five  } {KK1L: 6.73}
    6: Image := $40; { Memory six   } {KK1L: 6.73}
  else Exit;
  end;

  {WLI}
  {    CASE ActiveDVKPort OF

          Parallel1: BEGIN
                     LPT1Image := (LPT1Image AND DVKClearMessageBits) OR Image;  //KK1L: 6.71 Was $E1 KK1L: 6.72 ClearBits
                     Port [LPT1BaseAddress] := LPT1Image;
                     END;

          Parallel2: BEGIN
                     LPT2Image := (LPT2Image AND DVKClearMessageBits) OR Image;  //KK1L: 6.71 Was $E1  KK1L: 6.72 ClearBits
                     Port [LPT2BaseAddress] := LPT2Image;
                     END;

          Parallel3: BEGIN
                     LPT3Image := (LPT3Image AND DVKClearMessageBits) OR Image;  //KK1L: 6.71 Was $E1  //KK1L: 6.72 ClearBits
                     Port [LPT3BaseAddress] := LPT3Image;
                     END;

          ELSE       Exit;
          END;}

  DVKTimeOut := 40;
end;

{KK1L: 6.71 Started coding for the stereo pin stuff}

procedure SetStereoPin(PinNumber: integer; PinSet: boolean);

var
  //  BaseAddress                      : Word;
  TempByte                              : Byte;
  Mask                                  : TBitSet;
begin
  if tActiveStereoPortBaseAddress = INVALID_HANDLE_VALUE then Exit;

  case PinNumber of
    5: Mask := bsBIT3; { Pin five, bit 3 }
    9: Mask := bsBIT7; { Pin nine, bit 7 }
  else Exit;
  end;

  TempByte := GetPortByte(tActiveStereoPortBaseAddress, otData);

//  if PinSet then
//    TempByte := TempByte or Mask
//  else
//    TempByte := TempByte and (not Mask);

  DriverBitOperation(TempByte, Mask, TBitOperation(PinSet));

  SetPortByte(tActiveStereoPortBaseAddress, otData, TempByte);

  //  case PinNumber of
  //    5: Image := $08; { Pin five, bit 3 }
  //    9: Image := $80; { Pin nine, bit 7 }
  //    else Exit;
  //  end;
    {    CASE ActiveStereoPort OF

            Parallel1: BEGIN
                       IF PinSet THEN
                           LPT1Image := (LPT1Image AND (not Image)) OR Image
                       ELSE
                           LPT1Image := (LPT1Image AND (not Image));
                       Port [LPT1BaseAddress] := LPT1Image;
                       END;

            Parallel2: BEGIN
                       IF PinSet THEN
                           LPT2Image := (LPT2Image AND (not Image)) OR Image
                       ELSE
                           LPT2Image := (LPT2Image AND (not Image));
                       Port [LPT2BaseAddress] := LPT2Image;
                       END;

            Parallel3: BEGIN
                       IF PinSet THEN
                           LPT3Image := (LPT3Image AND (not Image)) OR Image
                       ELSE
                           LPT3Image := (LPT3Image AND (not Image));
                       Port [LPT3BaseAddress] := LPT3Image;
                       END;

            ELSE       Exit;
            END;
    }
end;

procedure TurnOffActivePort;

var
  SerialOff                             : Cardinal;
  hand                                  : HWND;
  TempByte                              : Byte;
begin
  if ActiveRadioPtr.tKeyerPortHandle = INVALID_HANDLE_VALUE then Exit;
//  ActivePortOn := (PTTAsserted or PTTForcedOn or PTTFootSwitch) and PTTEnable;

   if ActiveRadioPtr.tKeyerPort in [Serial1..Serial20] then
  begin
    SerialOff := 0;
    if ActiveRadioPtr.tr4w_keyer_DTR_state = RtsDtr_CW then SerialOff := CLRDTR;
    if ActiveRadioPtr.tr4w_keyer_rts_state = RtsDtr_CW then SerialOff := CLRRTS;
    if SerialOff = 0 then Exit;
    if SerialInvert then dec(SerialOff);
    hand := ActiveRadioPtr.tKeyerPortHandle; //ActiveRadioPtr.tKeyerPortHandle;
    if hand <> INVALID_HANDLE_VALUE then TREscapeCommFunction(hand, SerialOff);
  end
  else

    if ActiveRadioPtr.tKeyerPort in [Parallel1..Parallel3] then
    begin
      if ActiveRadioPtr.tKeyerPortHandle = INVALID_HANDLE_VALUE then Exit;
      TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
      DriverBitOperation(TempByte, CW_SIGNAL, boSet1);
        {17PIN}
//      LPTTempByte := LPTTempByte or BIT3;
        {1PIN}
//      LPTTempByte := LPTTempByte xor BIT0;
      SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);
    end;
end;

procedure DVKEnableWrite;

{ This procedure will turn on the fifth bit of the third LPT port which
  will set the DVK up to be written into. }

begin
  //{wli}
  {    CASE ActiveDVKPort OF

          Parallel1:
              BEGIN
              CWLPT1Image := CWLPT1Image OR  $20;
              Port [LPT1BaseAddress + ParallelOutputAddressOffset] := CWLPT1Image;
              END;

          Parallel2:
              BEGIN
              CWLPT2Image := CWLPT2Image OR  $20;
              Port [LPT2BaseAddress + ParallelOutputAddressOffset] := CWLPT2Image;
              END;

          Parallel3:
              BEGIN
              CWLPT3Image := CWLPT3Image OR  $20;
              Port [LPT3BaseAddress + ParallelOutputAddressOffset] := CWLPT3Image;
              END;

          END;
     }
end;

procedure DVKDisableWrite;

{ This procedure will stop the recording process on the DVK. }

begin
  {    CASE ActiveDVKPort OF

          Parallel1:
              BEGIN
              CWLPT1Image := CWLPT1Image AND $DF;
              Port [LPT1BaseAddress + ParallelOutputAddressOffset] := CWLPT1Image;
              END;

          Parallel2:
              BEGIN
              CWLPT2Image := CWLPT2Image AND $DF;
              Port [LPT2BaseAddress + ParallelOutputAddressOffset] := CWLPT2Image;
              END;

          Parallel3:
              BEGIN
              CWLPT3Image := CWLPT3Image AND $DF;
              Port [LPT3BaseAddress + ParallelOutputAddressOffset] := CWLPT3Image;
              END;

          END;
     }
end;

procedure TurnOnActivePort;

var
  SerialOn                              : Cardinal;
  { PTT will always be on if PTTEnable. }

  hand                                  : HWND;
  TempByte                              : Byte;
begin
  if ActiveRadioPtr.tKeyerPortHandle = INVALID_HANDLE_VALUE then
     begin
     logger.debug('[TurnOnActivePort] Exiting early due to ActiveRadioPtr.tKeyerPortHandle = INVALID_HANDLE_VALUE');
     Exit;
     end;
//  ActivePortOn := True;
//  CountsSinceLastCW := 0;

  if ActiveRadioPtr.tKeyerPort in [Serial1..Serial20] then
  begin
    SerialOn := 0;
    if ActiveRadioPtr.tr4w_keyer_DTR_state = RtsDtr_CW then SerialOn := SETDTR;
    if ActiveRadioPtr.tr4w_keyer_rts_state = RtsDtr_CW then SerialOn := SETRTS;
    if SerialOn = 0 then Exit;
    if SerialInvert then inc(SerialOn);
    hand := ActiveRadioPtr.tKeyerPortHandle; //ActiveRadioPtr.tKeyerPortHandle;
    if hand <> INVALID_HANDLE_VALUE then TREscapeCommFunction(hand, SerialOn);
//    SetMainWindowText(mweInsert, inttopchar(hand));
  end
  else
  begin
    if ActiveRadioPtr.tKeyerPort in [Parallel1..Parallel3] then
    begin
      if ActiveRadioPtr.tKeyerPortHandle = INVALID_HANDLE_VALUE then Exit;
      TempByte := GetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl);
      DriverBitOperation(TempByte, CW_SIGNAL, boSet0);
          {17PIN}
//      LPTTempByte := LPTTempByte and (not BIT3);
          {1PIN}
//      LPTTempByte := LPTTempByte xor BIT0;
      SetPortByte(ActiveRadioPtr.tKeyerPortHandle, otControl, TempByte);
    end;
  end;

end;

procedure SetRelayForActiveRadio(Radio: RadioType);
var
  TempByte                              : Byte;
  TempRadio                             : RadioType;
  Operation                             : TBitOperation;
begin
  {
    if (ActiveKeyerPort >= Parallel1) and (ActiveKeyerPort <= Parallel3) then
      if tPTTStatus = ptt_ON then
        LPTTempByte := 197
      else
        LPTTempByte := 193;
    if ActiveRadioPtr.tr4w_KeyerPortHandle = INVALID_HANDLE_VALUE then Exit;
    SetPortByte(ActiveRadioPtr.tr4w_KeyerPortHandle + 2, LPTTempByte);
  }
  if tRelayControlPortBaseAddress = INVALID_HANDLE_VALUE then Exit;

  TempRadio := Radio;

  if SwapRadioRelaySense then
    if Radio = RadioOne then
      TempRadio := RadioTwo
    else
      TempRadio := RadioOne;

  if TempRadio = RadioOne then Operation := boSet0;
  if TempRadio = RadioTwo then Operation := boSet1;

  TempByte := GetPortByte(tRelayControlPortBaseAddress, otControl);

  DriverBitOperation(TempByte, RELAY_SIGNAL, Operation);

  SetPortByte(tRelayControlPortBaseAddress, otControl, TempByte);
  {    IF SwapRadioRelaySense THEN
          IF Radio = RadioOne THEN
              Radio := RadioTwo
          ELSE
              Radio := RadioOne;

      CASE Radio OF
          RadioOne:
              CASE RelayControlPort OF
                  Parallel1:
                      BEGIN
                      CWLPT1Image := CWLPT1Image AND $FD;
                      Port [LPT1BaseAddress + ParallelOutputAddressOffset] := CWLPT1Image;
                      END;

                  Parallel2:
                      BEGIN
                      CWLPT2Image := CWLPT2Image AND $FD;
                      Port [LPT2BaseAddress + ParallelOutputAddressOffset] := CWLPT2Image;
                      END;

                  Parallel3:
                      BEGIN
                      CWLPT3Image := CWLPT3Image AND $FD;
                      Port [LPT3BaseAddress + ParallelOutputAddressOffset] := CWLPT3Image;
                      END;

                  END;

          RadioTwo:
              CASE RelayControlPort OF
                  Parallel1:
                      BEGIN
                      CWLPT1Image := CWLPT1Image OR $02;
                      Port [LPT1BaseAddress + ParallelOutputAddressOffset] := CWLPT1Image;
                      END;

                  Parallel2:
                      BEGIN
                      CWLPT2Image := CWLPT2Image OR $02;
                      Port [LPT2BaseAddress + ParallelOutputAddressOffset] := CWLPT2Image;
                      END;

                  Parallel3:
                      BEGIN
                      CWLPT3Image := CWLPT3Image OR $02;
                      Port [LPT3BaseAddress + ParallelOutputAddressOffset] := CWLPT3Image;
                      END;

                  END;
          END;

      Wait (2);
   }
end;
{
procedure K1EAKeyer.PTTForceOn;

begin
//  PTTForcedOn := True;
  TurnOffActivePort;
  //   Frm.PTT . Color := clnavy;
end;
}
{
procedure K1EAKeyer.PTTUnForce;

begin
//  PTTForcedOn := False;
  //   Frm.PTT . Color := clbtnface;
end;
}

procedure K1EAKeyer.IncrementBufferEnd;

begin
  CWBufferEnd := (CWBufferEnd + 1) mod CWBufferSize;
//  tAllowIncrementCWBufferStart := True;
end;
{
procedure K1EAKeyer.CheckPTT;

begin
  if not PTTAsserted then
  begin
    PTTAsserted := True;
    if not PTTForcedOn then PTTDelayCount := PTTTurnOnDelay;
    TurnOffActivePort;
  end;
end;
}

procedure K1EAKeyer.Dit;

begin

  //   SpeakerBeep(CWTone, 90);
  //   Sleep(30);
  if not CWBufferAvailable then
  begin
    New(CWBuffer);
    CWBufferAvailable := True;
  end;

//  CheckPTT;

  CWBuffer^[CWBufferEnd].length := 10;
  CWBuffer^[CWBufferEnd].Key := True;
  IncrementBufferEnd;

  CWBuffer^[CWBufferEnd].length := 10;
  CWBuffer^[CWBufferEnd].Key := False;
  IncrementBufferEnd;

//  CheckPTT;

end;

procedure K1EAKeyer.Dat;

begin
  if not CWBufferAvailable then
  begin
    New(CWBuffer);
    CWBufferAvailable := True;
  end;
{
  if not PTTAsserted then
  begin
    PTTAsserted := True;
    PTTDelayCount := PTTTurnOnDelay;
    TurnOffActivePort;
  end;
}
  CWBuffer^[CWBufferEnd].length := 45;
  CWBuffer^[CWBufferEnd].Key := True;

  IncrementBufferEnd;

  CWBuffer^[CWBufferEnd].length := 10;
  CWBuffer^[CWBufferEnd].Key := False;
  IncrementBufferEnd;
{
  if not PTTAsserted then
  begin
    PTTAsserted := True;
    PTTDelayCount := PTTTurnOnDelay;
    TurnOffActivePort;
  end;
}
end;

procedure K1EAKeyer.Dah;

begin

  //   SpeakerBeep(CWTone, 270);
  //   Sleep(30);

  if not CWBufferAvailable then
  begin
    New(CWBuffer);
    CWBufferAvailable := True;
  end;
{
  if not PTTAsserted then
  begin
    PTTAsserted := True;
    PTTDelayCount := PTTTurnOnDelay;
    TurnOffActivePort;
  end;
}

  CWBuffer^[CWBufferEnd].length := tDitDahRatio * 10;
  CWBuffer^[CWBufferEnd].Key := True;

  IncrementBufferEnd;

  CWBuffer^[CWBufferEnd].length := 10;
  CWBuffer^[CWBufferEnd].Key := False;
  IncrementBufferEnd;
{
  if not PTTAsserted then
  begin
    PTTAsserted := True;
    PTTDelayCount := PTTTurnOnDelay;
    TurnOffActivePort;
  end;
}
end;

function K1EAKeyer.DeleteLastCharacter: boolean;

{ This routine will remove the last character off the keying buffer.  If
  it fouund a letter to remove, it will return TRUE. }

var
  BufferPointer                         : integer;

begin
  if CWBufferEnd <> CWBufferStart then
    BufferPointer := CWBufferEnd - 1
  else
  begin
    DeleteLastCharacter := False;
    Exit;
  end;

  while BufferPointer <> CWBufferStart do
  begin
    dec(BufferPointer);

    if BufferPointer < 0 then
      BufferPointer := BufferPointer + CWBufferSize;

    if (CWBuffer^[BufferPointer].length = 20) and (CWBuffer^[BufferPointer].Key = False) then
    begin
      CWBufferEnd := (BufferPointer + 1) mod CWBufferSize;
      DeleteLastCharacter := True;
      Exit;
    end;
  end;

  DeleteLastCharacter := False;
end;
{
function FootSwitch: boolean;

var
  Pressed                               : boolean;

begin
  FootSwitch := False;

  Pressed := FootSwitchPressed;

  if FootSwitchMode = CWGrant then
  begin
    FootSwitch := Pressed;
    Exit;
  end;

  if Pressed then // Footswitch is pressed
  begin

         // Has been pressed for awhile now

    if FootSwitchState then
    begin
      FootSwitchCount := 5;
      Exit;
    end

               // has not been pressed very long

    else
      if FootSwitchCount = 0 then // Count has expired - make it so
      begin
        FootSwitchState := True;
        FootSwitchCount := 5;
        FootSwitch := True;
        Exit;
      end;
  end

         // Not pressed

  else
  begin

         // Has been open for awhile now

    if not FootSwitchState then
    begin
      FootSwitchCount := 5;
      Exit;
    end

               // has not been open very long

    else
      if FootSwitchCount = 0 then
      begin
        FootSwitchState := False;
        FootSwitchCount := 5;
        Exit;
      end;
  end;
end;
}

procedure K1EAKeyer.ClearSerialPortInputBuffer(port: PortType);

begin
  //  SerialPortInputBuffer[Port].ClearBuffer;
end;

function K1EAKeyer.SetUpSerialPort(port: PortType;
  BaudRate: Word;
  Bits: integer;
  Parity: ParityType;
  StopBits: SHORTINT;
  DefaultDelay: SHORTINT): HWND;

{ Sets up up the serial port hardware and initializes both the send and
  receive buffers }

begin
  { Setup the hardware }

  Result := InitializeSerialPort(port, BaudRate, Bits, Parity, StopBits, FILE_ATTRIBUTE_NORMAL, #0);
  if Result = INVALID_HANDLE_VALUE then Exit; //wli
  CPUKeyer.SerialPortConfigured_Handle[port] := Result;
  { Initialize output buffer }

//ua4wli  SerialPortOutputBuffer[port].InitializeBuffer;
//ua4wli  SerialPortInputBuffer[port].InitializeBuffer;

  { Set up send delays }

//ua4wli SerialPortDefaultDelay[port] := DefaultDelay;
//ua4wli  SerialPortDelay[port] := 0;

  { Enable TimerInterrupt to check this port }

  { See if we need to setup a debug file for this port }

//  if tr4w_SerialPortDebug {SerialPortDebug} then
{
 if SerialPortDebug then
 begin
   SerialPortOutputBuffer[Port].Debug := True;
   SerialPortInputBuffer[Port].Debug := True;

   case Port of
     Serial1:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM1OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM1IN.BIN');
       end;

     Serial2:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM2OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM2IN.BIN');
       end;

     Serial3:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM3OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM3IN.BIN');
       end;

     Serial4:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM4OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM4IN.BIN');
       end;

     Serial5:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM5OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM5IN.BIN');
       end;

     Serial6:
       begin
         Assign(SerialPortOutputBuffer[Port].DebugFile, 'COM6OUT.BIN');
         Assign(SerialPortInputBuffer[Port].DebugFile, 'COM6IN.BIN');
       end;

   else
     begin
       ShowWarning('Unexpected error - trying to assign debug file to bad serial port.');
       halt;
     end;

   end;

   ReWrite(SerialPortOutputBuffer[Port].DebugFile );
   ReWrite(SerialPortInputBuffer[Port].DebugFile );
 end;
}
end;
{
procedure K1EAKeyer.CheckSerialPortSendData(SerialPort: PortType);

// Checks to see if the buffer for the port specified has anything to send

var
  NextByte                              : Byte;

begin
       WITH SerialPortOutputBuffer [SerialPort] DO
           BEGIN
           IF IsEmpty THEN        // Buffer is empty - clear status
               BEGIN
               SerialPortDelay [SerialPort] := 0;
               Exit;
               END;

   //         See if we need to wait awhile before sending this data

           IF SerialPortDelay [SerialPort] > 0 THEN
               BEGIN
               Dec (SerialPortDelay [SerialPort]);
               Exit;
               END;

         //We have data to send - check the port to make sure it isn't busy

           CASE SerialPort OF
               Serial1: IF NOT (Port [Com1PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;

               Serial2: IF NOT (Port [Com2PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;

               Serial3: IF NOT (Port [Com3PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;

               Serial4: IF NOT (Port [Com4PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;

               Serial5: IF NOT (Port [Com5PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;

               Serial6: IF NOT (Port [Com6PortBaseAddress + PortStatusAddressOffset] AND 1) = 1 THEN
                            Exit;
               END;

           GetNextByte (NextByte);

           CASE SerialPort OF
               Serial1: Port [Com1PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               Serial2: Port [Com2PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               Serial3: Port [Com3PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               Serial4: Port [Com4PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               Serial5: Port [Com5PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               Serial6: Port [Com6PortBaseAddress + TransmitDataAddressOffset] := NextByte;
               END;

         //If DebugFlag is active - add the character to the output file

           IF SerialPortOutputBuffer [SerialPort].Debug THEN
               BlockWrite (SerialPortOutputBuffer [SerialPort].DebugFile, NextByte, 1);

           SerialPortDelay [SerialPort] := SerialPortDefaultDelay [SerialPort];
           END;

end;
}

{
procedure K1EAKeyer.CheckSerialPortReceiveData(SerialPort: PortType);

// Checks to see if a character is ready for the specified port.  If so,
//  it will read it in, and put it in the buffer for the port. I had to
//  move all of the ReadChar stuff in here, as I was getting hangs at
//  power up otherwise (seemed to be some kind of uninitialized variable
//  that I could never track down

var
  PortData                              : Byte;
  PortAddress                           : word;
   //    Regs: Registers;

begin
    PortAddress := 0;

       CASE SerialPort OF
           Serial1: PortAddress := Com1PortBaseAddress;
           Serial2: PortAddress := Com2PortBaseAddress;
           Serial3: PortAddress := Com3PortBaseAddress;
           Serial4: PortAddress := Com4PortBaseAddress;
           Serial5: PortAddress := Com5PortBaseAddress;
           Serial6: PortAddress := Com6PortBaseAddress;
           ELSE Exit;
           END;

       IF (Port [PortAddress + 5] AND 1) = 0 THEN Exit; // No character ready

   //    Character ready - go read it

       PortData := Port [PortAddress];

       SerialPortInputBuffer [SerialPort].AddEntry (PortData);

       IF SerialPortInputBuffer [SerialPort].Debug THEN
           BlockWrite (SerialPortInputBuffer [SerialPort].DebugFile, PortData, 1);

end;
   }

procedure K1EAKeyer.AddCharacterToCWBuffer(Character: Char);

begin
{
  if wkActive then
  begin
    wkAddCWMessageToInternalBuffer(UpCase(Character));
    exit;
  end;
}
  logger.debug('[CWThreadProc] AddCharacterToCWBuffer %s',[Character]);

  case UpCase(Character) of
    'A':
      begin
        Dit;
        Dah;
      end;
    'B':
      begin
        Dah;
        Dit;
        Dit;
        Dit;
      end;
    'C':
      begin
        Dah;
        Dit;
        Dah;
        Dit;
      end;
    'D':
      begin
        Dah;
        Dit;
        Dit;
      end;
    'E':
      begin
        Dit;
      end;
    'F':
      begin
        Dit;
        Dit;
        Dah;
        Dit;
      end;
    'G':
      begin
        Dah;
        Dah;
        Dit;
      end;
    'H':
      begin
        Dit;
        Dit;
        Dit;
        Dit;
      end;
    'I':
      begin
        Dit;
        Dit;
      end;
    'J':
      begin
        Dit;
        Dah;
        Dah;
        Dah;
      end;
    'K':
      begin
        Dah;
        Dit;
        Dah;
      end;
    'L':
      begin
        Dit;
        Dah;
        Dit;
        Dit;
      end;
    'M':
      begin
        Dah;
        Dah;
      end;
    'N':
      begin
        Dah;
        Dit;
      end;
    'O':
      begin
        Dah;
        Dah;
        Dah;
      end;
    'P':
      begin
        Dit;
        Dah;
        Dah;
        Dit;
      end;
    'Q':
      begin
        Dah;
        Dah;
        Dit;
        Dah;
      end;
    'R':
      begin
        Dit;
        Dah;
        Dit;
      end;
    'S':
      begin
        Dit;
        Dit;
        Dit;
      end;
    'T':
      begin
        Dah;
      end;
    'U':
      begin
        Dit;
        Dit;
        Dah;
      end;
    'V':
      begin
        Dit;
        Dit;
        Dit;
        Dah;
      end;
    'W':
      begin
        Dit;
        Dah;
        Dah;
      end;
    'X':
      begin
        Dah;
        Dit;
        Dit;
        Dah;
      end;
    'Y':
      begin
        Dah;
        Dit;
        Dah;
        Dah;
      end;
    'Z':
      begin
        Dah;
        Dah;
        Dit;
        Dit;
      end;
    '0':
      begin
        Dah;
        Dah;
        Dah;
        Dah;
        Dah;
      end;
    '1':
      begin
        Dit;
        Dah;
        Dah;
        Dah;
        Dah;
      end;
    '2':
      begin
        Dit;
        Dit;
        Dah;
        Dah;
        Dah;
      end;
    '3':
      begin
        Dit;
        Dit;
        Dit;
        Dah;
        Dah;
      end;
    '4':
      begin
        Dit;
        Dit;
        Dit;
        Dit;
        Dah;
      end;
    '5':
      begin
        Dit;
        Dit;
        Dit;
        Dit;
        Dit;
      end;
    '6':
      begin
        Dah;
        Dit;
        Dit;
        Dit;
        Dit;
      end;
    '7':
      begin
        Dah;
        Dah;
        Dit;
        Dit;
        Dit;
      end;
    '8':
      begin
        Dah;
        Dah;
        Dah;
        Dit;
        Dit;
      end;
    '9':
      begin
        Dah;
        Dah;
        Dah;
        Dah;
        Dit;
      end;
    '.':
      begin
        Dit;
        Dah;
        Dit;
        Dah;
        Dit;
        Dah;
      end;
    ',':
      begin
        Dah;
        Dah;
        Dit;
        Dit;
        Dah;
        Dah;
      end;
    '?':
      begin
        Dit;
        Dit;
        Dah;
        Dah;
        Dit;
        Dit;
      end;
    '/':
      begin
        Dah;
        Dit;
        Dit;
        Dah;
        Dit;
      end;
    '+':
      begin
        Dit;
        Dah;
        Dit;
        Dah;
        Dit;
      end;
    '<':
      begin
        Dit;
        Dit;
        Dit;
        Dah;
        Dit;
        Dah;
      end;
    '=':
      begin
        Dah;
        Dit;
        Dit;
        Dit;
        Dah;
      end;
    '!':
      begin
        Dit;
        Dit;
        Dit;
        Dah;
        Dit;
      end;

    '&':
      begin
        Exit;
        {
                Dit;
                Dah;
                Dit;
                Dit;
                Dit;
        }
      end;

    '-': Dat;

    CHR(197), CHR(229), //wli
      CHR(134), CHR(143):
      begin
        Dit;
        Dah;
        Dah;
        Dit;
        Dah;
      end; {KK1L: NOTE This is A-ring!!}
    CHR(196), CHR(228), //wli
      CHR(132), CHR(142):
      begin
        Dit;
        Dah;
        Dit;
        Dah;
      end; {KK1L: NOTE This is A-umlaut!}
    CHR(214), CHR(246), //wli
      CHR(148), CHR(153):
      begin
        Dah;
        Dah;
        Dah;
        Dit;
      end; {KK1L: NOTE This is O-umlaut!}

    ControlE:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 22;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlDash:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 26;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlK:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 30;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlN:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 34;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlO:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 38;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlP:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 6;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlQ:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 8;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlBackSlash:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlV:
      begin
        CWBuffer^[CWBufferEnd].length := 12;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlL:
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 14;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
        CWBuffer^[CWBufferEnd].length := 10;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlF: { Speed up command }
      begin
        CWBuffer^[CWBufferEnd].length := 0;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
      end;

    ControlS: { Slow down command }
      begin
        CWBuffer^[CWBufferEnd].length := 0;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlX: { Decrease weight command }
      begin
        CWBuffer^[CWBufferEnd].length := -1;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    ControlY: { Increase weight command }
      begin
        CWBuffer^[CWBufferEnd].length := -1;
        CWBuffer^[CWBufferEnd].Key := True;
        IncrementBufferEnd;
      end;

    ' ':
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 30;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

    '^':
      begin
//        CheckPTT;
        CWBuffer^[CWBufferEnd].length := 15;
        CWBuffer^[CWBufferEnd].Key := False;
        IncrementBufferEnd;
      end;

  end;

  if (Character > ' ') and
    (Character <> ' ') and
    (Character <> StartSendingNowKey) and
    (Character <> '^') then
  begin
    CWBuffer^[CWBufferEnd].length := 20;
    CWBuffer^[CWBufferEnd].Key := False;
    IncrementBufferEnd;
  end;
end;

procedure K1EAKeyer.AddStringToCWBuffer(Msg: Str160; Tone: integer);

var
  Character                             : integer;
  CommandState                          : boolean;

begin

  { Next two lines to fix bug where somtimes paddle speed gets ignored }

 //    form1.SendCW(tone,msg);
 //    exit;

//  PaddlePTTOffTimer := 0;
//  PaddleActive := False;

  if not CWBufferAvailable then
  begin
    New(CWBuffer);
    CWBufferAvailable := True;
  end;

  MonitorTone := Tone;
{
  if ActiveKeyerPort <> PortBeingUsed then
  begin
    FlushCWBuffer;
    PortBeingUsed := ActiveKeyerPort;
  end;
}
  CommandState := False;

  if length(Msg) > 0 then
  begin
    for Character := 1 to length(Msg) do
    begin
      if CommandState then
      begin
        CWBuffer^[CWBufferEnd].length := Ord('0') - Ord(Msg[Character]);
        IncrementBufferEnd;
        CommandState := False;
        Continue;
      end;

      case UpCase(Msg[Character]) of
        ControlLeftBracket: CommandState := True;

      else
        AddCharacterToCWBuffer(UpCase(Msg[Character]));
      end;

    end;
  end;

end;

function K1EAKeyer.BufferEmpty: boolean;

begin
  BufferEmpty := CWBufferStart = CWBufferEnd - 0 {������� -1};
end;

function K1EAKeyer.CWStillBeingSent: boolean;
begin
  Result := CWThreadID <> 0;
  // CWStillBeingSent := PTTAsserted;
end;

procedure K1EAKeyer.FlushCWBuffer;
begin
//  GetExitCodeThread(CWThreadHandle, lpExitCode);
//  Windows.TerminateThread(CATWTR^.tRadioInterfaceThreadHandle, lpExitCode);

  //  CWBufferStart := CWBufferEnd; ������ ������ ���-�� �� �������� ������ ���� � �����
{
  I := 0;
  if CWBufferEnd > 0
    then I := 1;
  CWBufferStart := CWBufferEnd - I;
}
//  ExitFromCWThread := True;
  CWBufferStart := CWBufferEnd;
  if CWThreadID <> 0 then
  begin
    dec(CWBufferStart);
    if CWBufferStart = -1 then CWBufferStart := CWBufferSize;
  end;
  logger.debug('[CWThreadProc] CWBufferStart := CWBuferEnd');
  {$IF tDebugMode}
  AddStringToTelnetConsole('CWBufferStart := CWBufferEnd', tstReceived);
{$IFEND}
//  tAllowIncrementCWBufferStart := False;

//  CWBufferStart := 0;
//  CWBufferEnd := 0;
//if CWThreadID <> 0 then  tCWBufferCleared := True;

  if (MonitorTone <> 0) {and (BeepCount = 0)} then NoSound;

  PTTDelayCount := 0;
//  PTTAsserted := False;

  TurnOffActivePort;
  PortBeingUsed := NoPort;
  wkClearBuffer;
end;

procedure K1EAKeyer.SetSpeed(Speed: integer {byte});

begin
  if Speed > 0 then
  begin
    CodeSpeed := Speed;
    ElementLength := round(ElementLengthConstant / Speed);
//    PaddlePTTOffTimerCount := ElementLength * PaddlePTTHoldCount;
  end;
end;

procedure DoABeep(TypeOfBeep: BeepType);

begin
  if not BeepEnable then Exit;
  ActiveBeep := TypeOfBeep;
  logger.Info('Calling tCreateThread from DoABeep');
  TR4W_BeepThread := tCreateThread(@tDoABeep, TR4W_BeepThreadID);
  logger.Info('Created Beep thread with threadid of %d',[TR4W_BeepThreadID] );
  // Issue #997: asm SetThreadPriority -> Pascal call. The old `push eax` pushed a
  // stale handle (clobbered by the preceding logger.Info), so this never applied;
  // now set it on the real handle. BEHAVIOR CHANGE: beep thread now runs IDLE.
  SetThreadPriority(TR4W_BeepThread, THREAD_PRIORITY_IDLE);

  {   Exit;
     if not BeepEnable then
        begin
           //        NoSound;
           Exit;
        end;

     case ActiveBeep of
        ThreeHarmonics:
           begin

              SpeakerBeep(300, 60);
              SpeakerBeep(450, 150);
              SpeakerBeep(550, 60);
              SpeakerBeep(350, 150);

           end;

        Warning:
           begin
              SpeakerBeep(1500, 150);
           end;

        single:
           begin
              SpeakerBeep(2000, 75);
           end;

        PromptBeep:
           begin
              SpeakerBeep(2000, 100);
           end;

        BeepCongrats:
           begin
              SpeakerBeep(500, 80);
              SpeakerBeep(400, 80);
              SpeakerBeep(300, 80);
              SpeakerBeep(600, 80);
              SpeakerBeep(800, 80);
           end;
     end;
  }
end;

function DVKMessagePlaying: boolean;

begin
  DVKMessagePlaying := DVKDelay > 0;
end;

procedure SetDVKDelay(Delay: integer);

begin
  //  if CPUKeyer.SlowInterrupts then
  //    DVKDelay := round(Delay / 3.36)
  //  else
  DVKDelay := round(Delay / 1.68);

end;

(*
procedure TimerInterrupt(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall; //(Flags, CS, IP, ax, BX, cx, DX, SI, DI, DS, ES, BP: Word);
label
  back;
  { Welcome to the heart beat of the TR Logging Program.  This interrupt
    will occur every 1.68 milliseconds (every 3.36 milliseconds if running
    in TR SLOW mode).

    The following things happen during this interrupt:

        - Decrement delay count for Wait Routine (if > 0).
        - Check beeper count and state.
        - Check Paddle port inputs.
        - Check CW Demod port (input only);
        - DVK pulse time out.
        - Tuning keys (left control and left shift).
        - RIT keys (left and right shift keys).
        - PTT timeout and CW Status.

    This procedure also performs the jump to the old interrupt 08 handler
    when appropriate to keep the system clock ticking correctly.  (ie: every
    32 times (or 16 if TR SLOW)) }

  //{wli} INTERRUPT;

var
  TempChar                              : Char;
  TempByte                              : Byte;
  TempString                            : Str80;
  SerialPort                            : PortType;

begin
  back:



  if PTTDelayCount > 0 then
  begin
    if PTTDelayCount = PTTTurnOnDelay then TurnOffActivePort;

    if FootSwitchMode = CWGrant then
    begin

    end
    else
      dec(PTTDelayCount);
  end
  else
  begin
    if (CWElementLength > 0) and not (Tuning {or PaddleBugDahBeingSent}) then
      dec(CWElementLength);

    if CWElementLength = 0 then
    begin
      if CWBufferStart <> CWBufferEnd then
      begin
        if CWBuffer^[CWBufferStart].length = 0 then // Bump speed command
        begin
          if CWBuffer^[CWBufferStart].Key then
          begin
            if CPUKeyer.CodeSpeed < 98 then inc(CPUKeyer.CodeSpeed);
            if (CPUKeyer.CodeSpeed > 25) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
            if (CPUKeyer.CodeSpeed > 35) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
            if (CPUKeyer.CodeSpeed > 45) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
          end
          else
          begin
            if CPUKeyer.CodeSpeed > 49 then dec(CPUKeyer.CodeSpeed);
            if CPUKeyer.CodeSpeed > 38 then dec(CPUKeyer.CodeSpeed);
            if CPUKeyer.CodeSpeed > 27 then dec(CPUKeyer.CodeSpeed);
            if CPUKeyer.CodeSpeed > 2 then dec(CPUKeyer.CodeSpeed);
          end;

          ElementLength := round(ElementLengthConstant / CPUKeyer.CodeSpeed);
        end
        else
          if CWBuffer^[CWBufferStart].length < 0 then // Command mode
          begin
            case CWBuffer^[CWBufferStart].length of
              -1:
                if CWBuffer^[CWBufferStart].Key then
                  Weight := Weight + 0.03
                else
                  Weight := Weight - 0.03;

              -2: FarnsworthEnable := not FarnsworthEnable;
              -3: FarnsworthSpeed := 25;
              -4: FarnsworthSpeed := 35;
              -5: FarnsworthSpeed := 45;
              -6: FarnsworthSpeed := 55;
              -7: FarnsworthSpeed := 75;
              -8: FarnsworthSpeed := 95;
            end;
          end
          else
          begin
            if CWBuffer^[CWBufferStart].Key then
            begin

              TurnOnActivePort;
              CWElementLength := round(Weight * (CWBuffer^[CWBufferStart].length * ElementLength) / 10.0);
                        //                                    if (BeepCount = 0) and (MonitorTone <> 0) then SpeakerBeep(MonitorTone, CWElementLength * 13); //Sound(MonitorTone);

            end
            else
            begin
              SendingADah := False;
              TurnOffActivePort;
                        //                                    if (MonitorTone <> 0) and (BeepCount = 0) then NoSound;

              if FarnsworthEnable and
                (CWBuffer^[CWBufferStart].length >= 15) and
                (CodeSpeed < FarnsworthSpeed) then
              begin
                if CWBuffer^[CWBufferStart].length = 15 then
                  CWBuffer^[CWBufferStart].length := CWBuffer^[CWBufferStart].length
                    + (FarnsworthSpeed - CodeSpeed)
                else
                  CWBuffer^[CWBufferStart].length := CWBuffer^[CWBufferStart].length
                    + ((FarnsworthSpeed - CodeSpeed) * 2);
              end;

              CWElementLength := round(((CWBuffer^[CWBufferStart].length * ElementLength) / 10.0) -
                ((Weight - 1.0) * 2 * ElementLength));

            end;
          end;

        inc(CWBufferStart);
        CWBufferStart := CWBufferStart mod CWBufferSize;
      end
      else
      begin
        SendStatus := NothingBeingSent;
{
        if PaddleActive then
        begin
          if PaddlePTTOffTimer > 0 then dec(PaddlePTTOffTimer);
          if PaddlePTTOffTimer = 0 then PaddleActive := False;
        end
        else
        begin
          PTTAsserted := False;
          PaddlePTTOffTimer := 0;
        end;
}
//        if CountsSinceLastCW = 0 then CountsSinceLastCW := 1;

//        if ActivePortOn then TurnOffActivePort;
      end;
    end;
  end;

  // Check the active serial ports to see if we have any data to collect.
{
  if not CPUKeyer.UseIRQs then
     for SerialPort := Serial1 to Serial4 do
        if CPUKeyer.SerialPortConfigured[SerialPort] then
           CPUKeyer.CheckSerialPortReceiveData(SerialPort);

  for SerialPort := Serial5 to Serial6 do
     if CPUKeyer.SerialPortConfigured[SerialPort] then
        CPUKeyer.CheckSerialPortReceiveData(SerialPort);

  //Check the serial send buffers

  for SerialPort := Serial1 to Serial6 do
     if CPUKeyer.SerialPortConfigured[SerialPort] then
        CPUKeyer.CheckSerialPortSendData(SerialPort);

  //     Now - call the standard timer interrupt if the time has come so
  //      that the time/date are still kept up to date

  inc(NumberInterrupts);

  if NumberInterrupts >= NumberInterruptsConstant then
     begin
        NumberInterrupts := 0;
        asm
          INT ($F1);
        end;
     end
  else
     begin
        asm
          MOV AL, $20
          OUT $20, AL
        end;
     end;
  }
  Sleep(2);
  goto back;
end;
*)
procedure K1EAKeyer.InitializeKeyer;

var
  //SerialPort                            : PortType;
  hand                                  : Cardinal;
begin

  DoingDVK := ActiveDVKPort <> NoPort;

  DoingPaddle := ActivePaddlePort <> NoPort;

//  PaddlePTTOffTimerCount := ElementLength * PaddlePTTHoldCount;

//  if BeepCount = 0 then NoSound;

  TurnOffActivePort;

//  NumberInterrupts := 0;
  CWElementLength := 0;
  CWBufferStart := 0;
  CWBufferEnd := 0;
//  PTTAsserted := False;
  PTTDelayCount := 0;
//  TurnOffActivePort;

  if Radio1.tKeyerPort in [Serial1..Serial20] then
  begin
    hand := CPUKeyer.SerialPortConfigured_Handle[Radio1.tKeyerPort {ActiveKeyerPort}];
    if hand = INVALID_HANDLE_VALUE then
       begin
       if logger.IsErrorEnabled then
          begin
          if (radio1.RadioModel in YaesuRadios) and (radio1.RadioKeyerStopBits <> 0) then
             begin
             logger.Error('***** Keyer stop bits not set to 0 for a Yaesu radio');
             end;
          end;
       hand := InitializeSerialPort(Radio1.tKeyerPort, Radio1.RadioBaudRate, 8, Tree.tNoParity, Radio1.RadioKeyerStopBits, FILE_ATTRIBUTE_NORMAL, #0);
       end;
    if hand <> INVALID_HANDLE_VALUE then
    begin
      if hand <> INVALID_HANDLE_VALUE then
      begin
        Radio1.tKeyerPortHandle := hand;
        if Radio1.tr4w_keyer_DTR_state = RtsDtr_ON then TREscapeCommFunction(hand, SETDTR);
        if Radio1.tr4w_keyer_DTR_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRDTR);
        if Radio1.tr4w_keyer_rts_state = RtsDtr_ON then TREscapeCommFunction(hand, SETRTS);
        if Radio1.tr4w_keyer_rts_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRRTS);
        KeyerInitialized := True;
      end;
    end;
  end;

  if Radio1.tKeyerPort in [Parallel1..Parallel3] then
  begin
    OpenLPT(Radio1.tKeyerPortHandle, Radio1.tKeyerPort);
//    PTTOff;
    KeyerInitialized := True;
  end;

  if (Radio2.tKeyerPort >= Serial1) and (Radio2.tKeyerPort <= Serial20) then
  begin
    hand := CPUKeyer.SerialPortConfigured_Handle[Radio2.tKeyerPort {Radio2.tr4w_KeyerPort}];
    if hand = INVALID_HANDLE_VALUE then
       begin
       if logger.IsErrorEnabled then
          begin
          if (radio2.RadioModel in YaesuRadios) and (radio2.RadioKeyerStopBits <> 0) then
             begin
             logger.Error('***** Keyer stop bits not set to 0 for a Yaesu radio');
             end;
          end;
       hand := InitializeSerialPort(Radio2.tKeyerPort, Radio2.RadioBaudRate, 8, Tree.tNoParity, Radio2.RadioKeyerStopBits, FILE_ATTRIBUTE_NORMAL, #0);
       end;
    if hand <> INVALID_HANDLE_VALUE then
    begin
      if hand <> INVALID_HANDLE_VALUE then
      begin
        Radio2.tKeyerPortHandle := hand;
        if Radio2.tr4w_keyer_DTR_state = RtsDtr_ON then TREscapeCommFunction(hand, SETDTR);
        if Radio2.tr4w_keyer_DTR_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRDTR);
        if Radio2.tr4w_keyer_rts_state = RtsDtr_ON then TREscapeCommFunction(hand, SETRTS);
        if Radio2.tr4w_keyer_rts_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRRTS);
        KeyerInitialized := True;
      end;
    end;
  end;

  if (Radio2.tKeyerPort >= Parallel1) and (Radio2.tKeyerPort <= Parallel3) then
  begin
    OpenLPT(Radio2.tKeyerPortHandle, Radio2.tKeyerPort);
//    PTTOff;
    KeyerInitialized := True;
  end;

  ElementLength := round(ElementLengthConstant / CodeSpeed);

end;

procedure K1EAKeyer.UnInitializeKeyer;

var
  SerialPort                            : PortType;

begin
  for SerialPort := Serial1 to Serial20 do
    if CPUKeyer.SerialPortConfigured_Handle[SerialPort] <> INVALID_HANDLE_VALUE then
    begin
{
      if SerialPortDebug then
      begin
            //        Close(tr4w_InputDebugFile[SerialPort]);
            //        Close(tr4w_OutputDebugFile[SerialPort]);
            //        CloseHandle(tDebugFile[SerialPort]);
        CloseCATDebugFile(SerialPort);
      end;
}
      CPUKeyer.SerialPortConfigured_Handle[SerialPort] := INVALID_HANDLE_VALUE;
      CloseHandle(CPUKeyer.SerialPortConfigured_Handle[SerialPort]);

    end;

//  DestroyDlPortio;

end;

procedure OutputBandInfo(BaseAddress: HWND; Band: BandType; Mode: ModeType);

{ Outputs the appropriate bits to the parallel port }

var
  Image                                 : Byte;

const
   BandInfoArray                         : array[BandType] of Byte = ($01, $20, $21, $41, $61, $81, $40, $60, $80, $A0, $A1, $C0, $C1, $E0, $E1, $00, $00, $00, $00, $00, $00, $00, $00);
begin
  if BaseAddress = INVALID_HANDLE_VALUE then Exit;
  Image := BandInfoArray[Band];
  if Mode = Phone then
    Image := Image or (1 shl 1);
  SetPortByte(BaseAddress, otData, Image);
end;

procedure SendCWBufferStart;
begin
  CallWinKeyDown := False;  //4.52.4
  if CWBuffer^[CWBufferStart].length = 0 then // Bump speed command
  begin
    if CWBuffer^[CWBufferStart].Key then
    begin
      if CPUKeyer.CodeSpeed < 98 then inc(CPUKeyer.CodeSpeed);
      if (CPUKeyer.CodeSpeed > 25) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
      if (CPUKeyer.CodeSpeed > 35) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
      if (CPUKeyer.CodeSpeed > 45) and (CPUKeyer.CodeSpeed < 98) then inc(CPUKeyer.CodeSpeed);
    end
    else
    begin
      if CPUKeyer.CodeSpeed > 49 then dec(CPUKeyer.CodeSpeed);
      if CPUKeyer.CodeSpeed > 38 then dec(CPUKeyer.CodeSpeed);
      if CPUKeyer.CodeSpeed > 27 then dec(CPUKeyer.CodeSpeed);
      if CPUKeyer.CodeSpeed > 2 then dec(CPUKeyer.CodeSpeed);
    end;
    ElementLength := round(ElementLengthConstant / CPUKeyer.CodeSpeed);
  end

  else
    if CWBuffer^[CWBufferStart].length < 0 then // Command mode
    begin
      case CWBuffer^[CWBufferStart].length of
        -1:
          if CWBuffer^[CWBufferStart].Key then
            Weight := Weight + 0.03
          else
            Weight := Weight - 0.03;

        -2: InvertBoolean(FarnsworthEnable);
        -3: FarnsworthSpeed := 25;
        -4: FarnsworthSpeed := 35;
        -5: FarnsworthSpeed := 45;
        -6: FarnsworthSpeed := 55;
        -7: FarnsworthSpeed := 75;
        -8: FarnsworthSpeed := 95;
      end;
    end
    else
    begin
      if CWBuffer^[CWBufferStart].Key then
      begin
        TurnOnActivePort;
        CWElementLength := round(Weight * (CWBuffer^[CWBufferStart].length * ElementLength) / 10.0);

        if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then
          Sound(CWTone)
        else
          ntBeep(CWTone, CWElementLength);
        tCWSleep(CWElementLength, tCW_Event);
        if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then NoSound;
      end
      else
      begin
        SendingADah := False;
        TurnOffActivePort;
        if FarnsworthEnable and (CWBuffer^[CWBufferStart].length >= 15) and (CodeSpeed < FarnsworthSpeed) then
        begin
          if CWBuffer^[CWBufferStart].length = 15 then
            CWBuffer^[CWBufferStart].length := CWBuffer^[CWBufferStart].length + (FarnsworthSpeed - CodeSpeed)
          else
            CWBuffer^[CWBufferStart].length := CWBuffer^[CWBufferStart].length + ((FarnsworthSpeed - CodeSpeed) * 2);
        end;
        CWElementLength := round(((CWBuffer^[CWBufferStart].length * ElementLength) / 10.0) - ((Weight - 1.0) * 2 * ElementLength));
        tCWSleep(CWElementLength, tCW_Event);
      end;
    end;
{$IF tDebugMode}
//  Windows.SetWindowText(InsertWindowHandle, inttopchar({CWBufferEnd - }CWBufferStart));
{$IFEND}
end;

procedure CWThreadProc;
label
  SendNext, ExitAndPTTof;
var
  b                                     : boolean;
begin
//tCWSleep(15, tCW_Event);

  timeBeginPeriod(1);
  Sleep(20);

//  tSetPriorityClass(REALTIME_PRIORITY_CLASS);

  b := False;
//  Sleep(5);

//  tCWSleep(1, tCW_Event);
  SendNext:
  if CWBufferStart <> CWBufferEnd then
  begin
    SendCWBufferStart;
    if CWBufferStart <> CWBufferEnd then
    begin
      CWBufferStart := (CWBufferStart + 1) mod CWBufferSize;
      goto SendNext;
    end;

  end;

  if b = False then
    if tStartAutoCallTerminate(CWThreadID) then
    begin
      b := True;
      goto SendNext;
    end;
//  if tAutoSendMode then goto SendNext;

  if tAutoSendMode or tWaitForNextChar then
  begin
    Sleep(10);
    goto SendNext;
  end;

  ExitAndPTTof:
  logger.debug('[CWThreadProc] ExitAndPTTof');
{$IF tDebugMode}
  AddStringToTelnetConsole('ExitAndPTTof', tstReceived);
{$IFEND}
  CWBufferStart := CWBufferEnd;
  if not PaddlePTTOn then PTTOff;

//  ExitFromCWThread := False;
   SetSpeed(DisplayedCodeSpeed);   // 4.50.1
  tStartAutoCQ;  // It appears we go here everytime we finish a CW buffer no matter if we just CQ'ed or not ny4i  4.44.5
{$IF OZCR2008}
  CWMessageToNetwork := '';
{$IFEND}

//  if TwoRadioState = SendingExchange then CheckTwoRadioState(ContactDone);

//  tSetPriorityClass(NORMAL_PRIORITY_CLASS);
  timeEndPeriod(1);

  if not CloseHandle(CWThreadHandle) then
    ShowSysErrorMessage('CW');

  CWThreadID := 0;

  BackToInactiveRadioAfterQSO;

end;

function tStartAutoCallTerminate(idAttach: DWORD): boolean;
begin
  Result := False;
  if AutoCallTerminate = True then
    if ExchangeHasBeenSent = False then
      if tAutoSendMode then
        if ControlAMode = False then
        begin
          AttachThreadInput(idAttach, MainThreadID, True);
          ReturnInCQOpMode;
          Result := True;
        end;
end;

procedure tStartAutoCQ;
begin
   logger.trace('[CWThreadProc] In tStartAutoCQ');
{$IF tDebugMode}
  AddStringToTelnetConsole('In tStartAutoCQ', tstReceived);
{$IFEND}
  if tAutoCQMode = True then
    tAutoCQTimerID := SetTimer(tr4whandle, AUTOCQ_TIMER_HANDLE, AutoCQDelayTime, @tAutoCQTimerProc);

end;

procedure tDoABeep;
var
  OldBeat                               : integer;
begin

  case ActiveBeep of
    ThreeHarmonics:
      begin

        SpeakerBeep(300, 60);
        SpeakerBeep(450, 150);
        SpeakerBeep(550, 60);
        SpeakerBeep(350, 150);

      end;

    Warning:
      begin
        SpeakerBeep(1500, 150);
      end;

    Beepsingle:
      begin
        SpeakerBeep(2000, 75);
      end;

    PromptBeep:
      begin
        SpeakerBeep(2000, 100);
        SpeakerBeep(2000, 40);
        SpeakerBeep(2000, 120);
      end;

    BeepCongrats:
      begin
        SpeakerBeep(500, 80);
        SpeakerBeep(400, 80);
        SpeakerBeep(300, 80);
        SpeakerBeep(600, 80);
        SpeakerBeep(800, 80);
      end;

    WakeUp:
      begin

        SixteenthNote(NoteC);
        SixteenthNote(NoteC);
        SixteenthNote(NoteF);
        SixteenthNote(NoteC);
        SixteenthNote(NoteF);
        SixteenthNote(NoteA);
        SixteenthNote(NoteF);
        SixteenthNote(NoNote);
        SixteenthNote(NoteF);
        SixteenthNote(NoteF);
        SixteenthNote(NoteA);
        SixteenthNote(NoteF);
        SixteenthNote(NoteA);
        SixteenthNote(NoteHiC);
        SixteenthNote(NoteA);
        SixteenthNote(NoNote);
        SixteenthNote(NoteF);
        SixteenthNote(NoteA);
        EigthNote(NoteHiC);
        SixteenthNote(NoteA);
        SixteenthNote(NoteF);
        EigthNote(NoteC);
        SixteenthNote(NoteC);
        SixteenthNote(NoteC);
        EigthNote(NoteF);
        SixteenthNote(NoteF);
        SixteenthNote(NoteF);
        Sleep(10);
        EigthNote(NoteF);
      end;

    Congrats:
      begin
        OldBeat := Beat;
        Beat := 400;
        SixteenthNote(NoteC);
        SixteenthNote(NoteE);
        SixteenthNote(NoteG);
        EigthNote(NoteHiC);
        SixteenthNote(NoteG);
        EigthNote(NoteHiC);
        Beat := OldBeat;
      end;

  end;

end;

procedure tAutoCQTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall;
var
  TempChar                              : Char;
begin
  Windows.KillTimer(tr4whandle, AUTOCQ_TIMER_HANDLE);
  if OpMode = SearchAndPounceOpMode then
  begin
    TryKillAutoCQ;
    Exit;
  end;
  TempChar := AutoCQMemory;
  if (AutoCQMemory = F1) and RandomCQMode then TempChar := Char(Random(4) + 112);
  if GetCQMemoryString(ActiveMode, TempChar) = '' then TempChar := AutoCQMemory;
  //   Windows.SetWindowText(VC.InsertWindowHandle, inttopchar(ord(TempChar)));
  tDisplayAutoCQStatus;
  SendFunctionKeyMessage(TempChar, OpMode);
end;

procedure tCWSleep(millsec, myEvent: Cardinal);
var
  t                                     : Cardinal;
begin
  if millsec = 0 then Exit;
{$IF tDebugMode}
  Start := GetCPU;
{$IFEND}

  t := timeSetEvent(millsec, 1, TFNTimeCallBack(myEvent), 0, TIME_ONESHOT + TIME_CALLBACK_EVENT_SET);
  if t <> 0 then
  begin
    WaitForSingleObject(myEvent, INFINITE);
  end
  else
  begin
    Sleep(millsec);
  end;

{$IF tDebugMode}
//  cw_tick_array[cw_tick] := (GetCPU - Start) {div 17000000};
//  inc(cw_tick);
{$IFEND}

end;

procedure tPaddleFootSwitchThreadProc;
label
  Start;
var
  TempByte                              : Byte;
  TempCardinal                          : Cardinal;
  DitContact                            : boolean;
  DahContact                            : boolean;
  CWElementLength                       : Cardinal;
begin
  tDispalyPaddleAndFootSwitchStatus;

  tPTTOnCounter := 0;
  PaddlePTTOn := False;

  Start:
  CWElementLength := tPaddleElementLength;
//  sleep(100);

  if PaddlePTTOn = False then
    Sleep(CWElementLength)
  else
    tCWSleep(CWElementLength, tCWPaddle_Event);

  if tDoingFootSwitchEnable then
    if FootSwitchMode <> FootSwitchDisabled then
    begin
      if not tUseControlPort then
      begin
            {LPT}
        TempByte := GetPortByte(tFootSwitchPortBaseAddress, otState);
//        Windows.SetWindowText(wh[mweUserInfo], inttopchar(TempByte));
        if TempByte and 8 = 8 then
        begin
          if tFootSwitchPressed = True then
            if FootSwitchMode = Normal then PTTOff;
          tFootSwitchPressed := False;
        end;
        if TempByte and 8 = 0 then
          if tFootSwitchPressed = False then
          begin
            tFootSwitchPressed := True;
            tFootSwitchProcedure;
          end;

      end
      else
      begin
            {COM}
        GetCommModemStatus(Radio1.tCATPortHandle, TempCardinal);

        if TempCardinal and MS_RLSD_ON = 0 then
        begin
          if tFootSwitchPressed = True then
            if FootSwitchMode = Normal then PTTOff;
          tFootSwitchPressed := False;
        end;
        if TempCardinal and MS_RLSD_ON = MS_RLSD_ON then
          if tFootSwitchPressed = False then
          begin
            tFootSwitchPressed := True;
            tFootSwitchProcedure;
          end;
      end;
    end;

  if DoingPaddle then
    if ActiveMode = CW then
    begin

      DitContact := False;
      DahContact := False;
      if not tUseControlPort then
      begin
        if tPaddlePortBaseAddress <> INVALID_HANDLE_VALUE then
        begin
          TempByte := GetPortByte(tPaddlePortBaseAddress, otState);
//          Windows.SetWindowText(wh[mweUserInfo], inttopchar(TempByte));
          if TempByte and 32 = 0 then DitContact := True;
          if TempByte and 16 = 0 then DahContact := True;
        end;
      end
      else
      begin
            //1.DCD - 128 6.DSR - 32 Dah 8.CTS - 16 Dit  9.RI  - 64
        GetCommModemStatus(Radio1.tCATPortHandle, TempCardinal);
        if TempCardinal and MS_CTS_ON = MS_CTS_ON then DitContact := True;
        if TempCardinal and MS_DSR_ON = MS_DSR_ON then DahContact := True;
      end;
      if (DitContact or DahContact) then
      begin
        tPTTOnCounter := 0;
        CWBufferStart := CWBufferEnd;
        if PaddlePTTOn = False then
        begin
          PaddlePTTOn := True;
          if not CheckPTTLockout then PTTOn;
        end;
        TurnOnActivePort;

        if DahContact then CWElementLength := tPaddleElementLength * 3;
        if SwapPaddles then
        begin
          if DahContact then CWElementLength := tPaddleElementLength;
          if DitContact then CWElementLength := tPaddleElementLength * 3;
        end;

        if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then
          Sound(PaddleMonitorTone)
        else
          ntBeep(PaddleMonitorTone, CWElementLength);

            //        Sleep(CWElementLength);
        tCWSleep(CWElementLength, tCWPaddle_Event);

        TurnOffActivePort;
        if WindowsOSversion = VER_PLATFORM_WIN32_WINDOWS then NoSound;
      end
      else
      begin
        if PaddlePTTOn then inc(tPTTOnCounter);
      end;
      if PaddlePTTOn then if tPTTOnCounter = PaddlePTTHoldCount then
        begin
          PaddlePTTOn := False;
          if CWBufferStart = CWBufferEnd then PTTOff;
        end;
    end;

  if tExitFromPaddleFootSwitchThread = False then goto Start;

end;

procedure tSetPaddleElementLength;
var
  TempSpeed                             : Cardinal;
begin

  TempSpeed := PaddleSpeed;
  if TempSpeed = 0 then TempSpeed := CodeSpeed;
  tPaddleElementLength := round(ElementLengthConstant / TempSpeed);
end;

procedure tFootSwitchProcedure;
begin
  {
  FootSwitchModeType = (
      CWGrant,
  -    FootSwitchDisabled,
  -    FootSwitchF1,
      FootSwitchLastCQFreq,
  -    FootSwitchNextBandMap,
  -    FootSwitchNextDisplayedBandMap,
  -    FootSwitchNextMultBandMap,
  -    FootSwitchNextMultDisplayedBandMap,
  -    FootSwitchUpdateBandMapBlinkingCall,
      FootSwitchDupecheck,
  -    Normal,
  -    QSONormal,
      QSOQuick,
  -    FootSwitchControlEnter,
  -    StartSending,
      SwapRadio);
  }
  case FootSwitchMode of

    FootSwitchF1:
      begin
        if OpMode = CQOpMode then
          SendFunctionKeyMessage(F1, CQOpMode)
        else
          ProcessExchangeFunctionKey(F1);
      end;

    //    FootSwitchDisabled:      FootSwitchPressed := False;

    FootSwitchLastCQFreq:
      begin
        scLASTCQFREQ;
      end;

    FootSwitchUpdateBandMapBlinkingCall: UpdateBlinkingBandMapCall;

    FootSwitchDupecheck: DupeCheckOnInactiveRadio(False);

    StartSending:
      if ActiveMode = CW then
        PostMessage(wh[mweCall], WM_CHAR, integer(StartSendingNowKey), 0);

    SwapRadio:
      begin
        SwapRadios;
        //        Str(SpeedMemory[InactiveRadio], SpeedString); {KK1L: 6.73 Used to use a variable CheckSpeed}
      end;

    Normal:
      begin
        if not CheckPTTLockout then PTTOn;
        //        if TwoRadioState <> TwoRadiosDisabled then          CheckTwoRadioState(FootswitchWasPressed);

        //        FootSwitchPressed := False;
      end;
    QSONormal, FootSwitchControlEnter:
      begin
        AttachThreadInput(tPaddleThreadID, MainThreadID, True);
        if FootSwitchMode = QSONormal then
          ProcessReturn
        else
          ProcessMenu(menu_ctrl_logqsowithoutcw);
      end;

  end;

end;

function tGetPortType(port: PortType): PortInterface;
begin
  Result := NoInterface;
  if port in [Serial1..Serial20] then Result := SerialInterface
  else
    if port in [Parallel1..Parallel3] then Result := ParallelInterface;
end;

procedure BackToInactiveRadioAfterQSO;
begin
  if (ActiveRadioPtr^.tTwoRadioMode = TR3) then // ny4i Issue 149 This activeradioptr.cwbycat would cause the rigs to swap all the time for CWBC or (activeradioptr.cwbycat) then
  begin
    tClearDupeInfoCall;
    ActiveRadioPtr^.tTwoRadioMode := TR0;
    InActiveRadioPtr^.tTwoRadioMode := TR0;
    SwapRadios;
    SetOpMode(CQOpMode);
     if AltDCQEnable then  // 4.89.3
     if OnDeckCall = '' then
      SendCrypticMessage(GetCQMemoryString(ActiveMode, F1))
     else
     begin
      PutCallToCallWindow(OnDeckCall);
     end;
  end;

//  if ActiveRadioPtr^.tTwoRadioMode = TR2 then
//   if (GetCQMemoryString(InActiveRadioPtr^.ModeMemory, AltF3) <> '') {and (CalledFromCQMode) } then
//      SendCrypticMessage(ControlA + GetCQMemoryString(InActiveRadioPtr^.ModeMemory, AltF3));

end;

procedure tSetPriorityClass(dwPriorityClass: DWORD);
begin
//  if tHighCWPerformance then
//    Windows.SetPriorityClass(GetCurrentProcess, dwPriorityClass);
end;

end.
