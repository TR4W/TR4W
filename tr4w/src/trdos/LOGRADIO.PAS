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
unit LogRadio;

{$IMPORTEDDATA OFF}

{ This unit has the RadioObject in it, which is used to do everything
  associated with radio interface.  It relies on LogK1EA for sent and
  received data buffer support, but nothing else.  LogWind pulls data
  out of this unit without using any other interface to the radio (I
  hope. }

interface

uses
   Classes,
   Math,
   SysUtils,
   TF,
   Tree,
   VC,
   Windows,
   utils_text,
   ExtCtrls,
   uNetRadioBase,
   uRadioElecraftK4,
   uRadioFactory;

var
   Icom_Filter_Width: integer;     // n4af 4.43.4
   TimeoutBuffer:     PCOMMTIMEOUTS;

const

   ICOM_TRANSFER_FREQ = #$00;
   ICOM_TRANSFER_MODE = #$01;

   ICOM_GET_FREQ      = #$03;
   ICOM_GET_MODE      = #$04;
   ICOM_XMIT_SETTINGS = #$1C;

   ICOM_SET_FREQ        = #$05;
   ICOM_SET_MODE        = #$06;
   ICOM_SET_VFO_COMMAND = #$07;

   ICOM_SPLIT_MODE     = #$0F;
   ICOM_SET_SPLIT_MODE = #$0F;

   ICOM_SET_SLIDERS  = #$14;
   // Things like CW speed, and rotating knobs
   ICOM_SET_CW_SPEED = #$0C;

   ICOM_SEND_CW        = #$17;
   ICOM_SET_XMIT_STATE = #$18;  // + 00 for XMIT off, 01 for XMIT on.

   ICOM_GET_RIT_FREQ   = #$21;
   ICOM_GET_EXTENDEDVFO = #$25;
   ICOM_GET_EXTENDEDMODE = #$26;
   ICOM_SET_DVK = #$28;     // Command 28 plays voice memories
   //ICOM_SET_RIT_FREQ   =
   ICOM_STATE            = #$1A;
   ICOM_STATE_DATA_MODE  = #$06;

   ICOM_SET_VFO_A_COMMAND = #$00;
   ICOM_SET_VFO_B_COMMAND = #$01;

   ICOM_END_OF_MESSAGE_CODE = #$FD;
   ICOM_PREAMBLE_CODE       = #$FE;

   ICOM_CONTROLLER_ADDRESS   = #$E0;
   ICOM_OTHER_RADIOS_ADDRESS = #$00;

type
   tr4w_RTSDTRType = (RtsDtr_Nothing, RtsDtr_OFF, RtsDtr_ON, RtsDtr_CW, RtsDtr_PTT);
   TEventHandlers = class
      procedure OnTimerTick(Sender : TObject);
   end;

// var EventHandlers : TEventHandlers;
const

   tr4w_RTSDTRTypeSA: array[tr4w_RTSDTRType] of PChar =
      (
      'NONE',
      'OFF',
      'ON',
      'CW',
      'PTT'
      );

type
   ActiveVFOStatusType = (vfoUnknown, VFOA, VFOB, vfoMem);
   TXRXType = (VFODisabled, RXOnly, TXOnly, Transceive, UnknownTXRX);

   //  SplitType = (NoSplit, SplitOn);
   //  RITType = (NoRIT, RITOn);

   { PollingStatusType is used for the basic state machine states }
   TRMode = (
      TR0,
      TR1, //spacebar TwoRadioMode = false
      TR2, //spacebar TwoRadioMode = true
      TR3
      );

   PollingStatusType = (NoPollStatus,
      PollStatus1,
      PollStatus2,
      PollStatus3,
      PollStatus4,
      PollStatus5);

   VFOStatusType = record
      {04}Frequency: longint;
      {04}RITFreq:   integer;
      {01}Band:      BandType;
      {01}Mode:      ModeType;
      {01}Split:     boolean;
      {01}RIT:       boolean;
      {01}XIT:       boolean;
       ExtendedMode: ExtendedModeType;
   end;

   RadioStatusRecord = record
      //    {24}VFOA: VFOStatusType;
      //    {24}VFOB: VFOStatusType;
      VFO:           array[ActiveVFOStatusType] of VFOStatusType;
      previousVFO:   array[ActiveVFOStatusType] of VFOStatusType;
      {04}Freq:      longint; // This is the active frequency for the radio
      {04}Split:     longbool;
      {04}RIT:       longbool;
      {04}XIT:       longbool;
      {04}RITFreq:   integer;
      {04}PrevRITFreq: integer;
      {01}Band:      BandType;
      {01}Mode:      ModeType;
      ExtendedMode:  ExtendedModeType;
      {01}VFOStatus: ActiveVFOStatusType;
      {01}PrevVFOStatus: ActiveVFOStatusType;
      {01}TXOn:      boolean;
        //  ModeActual:ExtendedRadioModeType; // tom
   end;

   RadioObject = object
      tDupeSheetWnd:     HWND;
      tDisableCIVTransceive: boolean;
      tPTTStatus:        PTTStatusType;
      tTwoRadioMode:     TRMode;
      RadioOnTheMove:    boolean;
      LastDisplayedFreq: integer;
      tCommandedQSYFreq: integer;  // Issue #795 vs bandmap: last app-commanded VFO-A freq; auto-S&P treats a QSY landing here as commanded (don't clear the entry), not a manual dial tune
      SpeedMemory:       integer;
      BandMemory:        BandType;
      ModeMemory:        ModeType;
      tNetObject:          TNetRadioBase;  // Factory creates K4 or HamLibDirect
      FreqWindowHandle:    HWND;
      RadioNameWndHandle:  HWND;
      RadioDisconnected:   Boolean;
      tLastValidResponse:  Cardinal;   // GetTickCount of last good serial read; drives the serial liveness indicator
      RadioName:        Str20;
      StartupCommand  : Str50;
      StartupCommandSent: Boolean;  // One-shot guard: set True after pNetworkRadio sends StartupCommand on first connect (Issue #436)
      HamLibID:          integer;
      //    lpOverlapped: TOverlapped;
      //    pOver: POverlapped;

      CommandsBuffer:        array[0..7] of array[0..{19}40] of char;
      CommandsBufferPointer: cardinal;
      CommandsTempBuffer:    array[0..{19}40] of char; // ny4i extended for icom cw  // 4.44.5

      //    ICOM_COMMAND_B1: Str80;
      //    ICOM_COMMAND_SET_MODE: string[8];
      //    ICOM_COMMAND_SET_FREQ: string[11];
      //    ICOM_COMMAND_B2: Str80;
      //    ICOM_COMMAND_CUSTOM: Str80;

      //    ICOM_COMMAND_PTT: Char;
      //    ICOM_SET_PTT: array[0..7] of Char;
      //    ICOM_SET_SPLIT: array[0..7] of Char;

      FT857_COMMAND_SET_MODE: string[5];
      FT857_COMMAND_SET_FREQ: string[5];

      tRadioInterfaceThreadID: cardinal;
      tRadioInterfaceThreadHandle: HWND;
      PollingStopRequested: Boolean;
      tPollCount: integer;
      tStatusEqualityCounter: cardinal;
      tRadioInterfaceWndHandle: HWND;
      RITWndHandle:     HWND;
      XITWndHandle:     HWND;
      SplitWndHandle:   HWND;
      ModeVFOAWndHandle: HWND;  // Issue #566: mode label beside VFO A freq
      ModeVFOBWndHandle: HWND;  // Issue #566: mode label beside VFO B freq
      tRadioOnTheMove: boolean;
      tBuf: array[1..512] of char;
      active : boolean;
      CurrentStatus:   RadioStatusRecord; { Last reading taken }
      PreviousStatus:  RadioStatusRecord; { Reading before Last }
      FilteredStatus:  RadioStatusRecord; { Updated if Current = Previous }
      FilteredStatusChanged: boolean;
      BandOutputPort:  PortType;
      tBandOutputPortBaseAddress: HWND;
      CommandPauseTimeStamp: TimeRecord;
      FrequencyAdder:  longint;
      FT1000MPCWReverse: boolean;
      CWByCAT:         boolean;                    // ny4i 4.44.5
      CWSpeedSync:     boolean;
      CWByCAT_Sending: boolean;                    // ny4i Issue 129
      CATSerialLock:   TRTLCriticalSection;        // serialize a poll cycle vs a CW-by-CAT write on this radio's serial port
      UseHamLib:       boolean;
      WideCWFilter:    boolean;
      IcomFilterByte:  byte;
      IDCharacter:     char;
      IPAddress:       str50;
      NetworkUsername: str50;  // Network radio username (Icom CI-V/IP, Kenwood TS-890, etc.) -- Issue #904
      NetworkPassword: str50;  // Network radio password -- Issue #904
      IcomDataModeID: Byte;        // Icom data sub-mode: 1=D1 (default), 2=D2, 3=D3
      CWByCATBuffer:   string;                  // ny4i 4.44.5
      //    PartialRadioResponse: string;
      PollingEnable:   boolean;
      PollDelay:       integer;
      PollStatus:      PollingStatusType;
      PollTime:        cardinal {TimeRecord};
      RadioModel:      InterfacedRadioType;
      RadioBaudRate:   cardinal;
      RadioNumberBits: integer;
      RadioStopBits:   integer;
      RadioKeyerStopBits: integer;
      RadioParity:     ParityType;
      RadioTCPPort:    integer;
      RadioTimeout:    integer;
      ReceiverAddress: integer; { Used for Icom interfaces }
      WaitingForCommandPause: boolean;

      tCATPortType:   PortType;
      tCATPortHandle: HWND;

      tKeyerPort:       PortType;
      tKeyerPortHandle: HWND;

      tr4w_keyer_rts_state: tr4w_RTSDTRType; //keyer RTS
      tr4w_keyer_DTR_state: tr4w_RTSDTRType; //keyer DTR
      tr4w_cat_rts_state:   tr4w_RTSDTRType; //CAT RTS
      tr4w_cat_dtr_state:   tr4w_RTSDTRType; //CAT DTR

      tYaesuFreq5Bytes: array[0..4] of byte;
      tYaesuMode5Bytes: array[0..4] of byte;

      tYaesuSendFreq: boolean;
      tYaesuSendMode: boolean;

      tIcom6Bytes: array[0..5] of byte;
      tIcom7Bytes: array[0..6] of byte; //ny4i  // 4.44.5
      tIcom11Bytes: array[0..10] of byte; //ny4i
      tIcomFilterWidth: integer;

      tKenwood14Bytes: array[0..14] of char;

      tOrionFreq:   array[0..15] of char;
      tOrionMode:   array[0..07] of char;
      CommandPause: integer;
      saveMode : integer;
      nextExtendedMode : ExtendedModeType;
      tmrCWByCAT: TTimer;
      EventHandlers : TEventHandlers;
      procedure AddCommandToBuffer;
      function  CheckAutoCallTerminate: boolean;
      function DeleteLastCWCharacter: boolean;
      procedure FlushCWByCATBuffer;
      procedure PutRadioIntoSplit;
      procedure PutRadioOutOfSplit;
      procedure SendIcomCommand(Command: byte);
      procedure SendIcomTwoByteCommand(Command: byte; opCode: byte);
      procedure SendXMITStatusCommand;
      procedure SendIcomExtendedVFO(bVFO: boolean);
      procedure SendIcomExtendedMode(bVFO: boolean);
      procedure SendRITStatusCommand;
      procedure SendRITFreqCommand;
      procedure GetIcomDataStateCommand;
      procedure SetICOMRITFrequency(hz: integer);
      function MemoryKeyer(mem: integer): boolean;
      procedure ProcessIcomMode(mode: integer);
      procedure SendIcomClearRITCommand;
      function CalculateIcomFilterWidth: integer;
      procedure SetRadioCWSpeed(speed: longint);
      procedure SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char); overload;
      procedure SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char; extendedMode: ExtendedModeType); overload;
      procedure SendCW(Msg: Str160);
      procedure SetUpRadioInterface;
      function DetermineNetworkRadioModel: TRadioModel;
      function MapRadioModelToFactory: TRadioModel;
      procedure StopSendingCW;
      //    procedure StartNextPoll;
      //    function TimeToGiveUp: boolean;
      procedure UpdateBandOutputInfo(Band: BandType; Mode: ModeType);
      procedure UpdateRadioStatus;
      function ConvertBCDStringToFreq(BCDString: Str20): longint;

      procedure FreqToBCD(Freq: longint; Swap: boolean; OpCode: byte);
      procedure CheckAndInitializePorts_ForThisRadio;
      function WriteToCATPort(const Buffer; nNumberOfBytesToWrite: DWORD): longbool;
      function WritePollRequest(const Buffer; nNumberOfBytesToWrite: DWORD): longbool;
      function AddToOutputBuffer(Buffer: PChar; nNumberOfBytesToWrite: DWORD): longbool;
      procedure WriteBufferToCATPort(const Buffer);
      procedure OnCWByCATTimeEvent(Sender :TObject);
      procedure EnableCWBYCATTimer(ms: integer);
      procedure AddTimeToCWByCATTimer(ms: integer);

      //    property fddd;
   end;
   RadioPtr = ^RadioObject;

var
   IcomResponseTimeout:    integer;
   cmdIcomResponseTimeout: integer = -1;
   newIcomResponseTimeout: integer = 60;

   newIcomResponseTimeoutAuto: integer;
   icomCIVTransceiveEnable:    boolean;
   InBandLock:     boolean = True;      // 4.92.1
   TwoRadioMode: boolean;

   Radio1:           RadioObject {=
    (
    SpeedMemory: InitialCodeSpeed;
    BandMemory: Band160;
    ModeMemory: CW;
    RadioName: 'Rig 1';
    ICOM_COMMAND_PTT: #255;
    tRadioInterfaceWndHandle: 0;
    FT1000MPCWReverse: False;
    IDCharacter: CHR(0);
    //    PollTimeout: 500;
    PollingEnable: True;
    PollStatus: NoPollStatus;
    RadioModel: NoInterfacedRadio;

    RadioBaudRate: 4800;

    RadioNumberBits: 8;

    RadioStopBits: 2;

    RadioParity: tNoParity;

    ReceiverAddress: 4;
    WaitingForCommandPause: False;
    //    TrackingEnable: True;
    //    UpdateSeconds: 0;

    tCATPortType: NoPort;
    tCATPortHandle: INVALID_HANDLE_VALUE;

    tKeyerPortHandle: INVALID_HANDLE_VALUE;
    tr4w_keyer_rts_state: RtsDtr_PTT;
    tr4w_keyer_DTR_state: RtsDtr_CW;
    tr4w_cat_rts_state: RtsDtr_OFF; //CAT RTS
    tr4w_cat_dtr_state: RtsDtr_OFF; //CAT DTR
    );
};
   Radio2:           RadioObject {=
    (
    SpeedMemory: InitialCodeSpeed;
    BandMemory: Band160;
    ModeMemory: CW;
    RadioName: 'Rig 2';
    ICOM_COMMAND_PTT: #255;
    tRadioInterfaceWndHandle: 0;
    FT1000MPCWReverse: False;
    IDCharacter: CHR(0);
    //    PollTimeout: 500;
    PollingEnable: True;
    PollStatus: NoPollStatus;
    RadioModel: NoInterfacedRadio;
    RadioBaudRate: 4800;
    RadioNumberBits: 8;
    RadioStopBits: 2;
    RadioParity: tNoParity;
    ReceiverAddress: 4;
    WaitingForCommandPause: False;
    //    TrackingEnable: True;
    //    UpdateSeconds: 0;
    tCATPortType: NoPort;
    tCATPortHandle: INVALID_HANDLE_VALUE;

    tKeyerPortHandle: INVALID_HANDLE_VALUE;
    tr4w_keyer_rts_state: RtsDtr_PTT;
    tr4w_keyer_DTR_state: RtsDtr_CW;
    tr4w_cat_rts_state: RtsDtr_OFF; //CAT RTS
    tr4w_cat_dtr_state: RtsDtr_OFF; //CAT DTR
    );
};
   //  RITCommandTimeStamp              : Cardinal {TimeRecord};
   ActiveRadioPtr:   RadioPtr = @Radio1;
   InActiveRadioPtr: RadioPtr = @Radio2;
   RadioSupportsCWByCAT: InterfacedRadioTypeSet;
   RadioSupportsCWSpeedSync: InterfacedRadioTypeSet;
   RadioSupportsPlayDVK: InterfacedRadioTypeSet;
   IcomRadiosThatSupportRIT: InterfacedRadioTypeSet;
   IcomRadiosThatSupportVFOB: InterfacedRadioTypeSet;
   IcomRadiosThatSupportPSKMode: InterfacedRadioTypeSet;  // For data, radio uses PSK mode instead of USB-D.
   ICOMRadios:       ICOMRadioTypes;
   KenwoodRadios:    KenwoodRadioTypes;
   YaesuRadios:      YaesuRadioTypes;
   HAMLIbONLYRadios: HamLib_ONLY_RadioTypes;

const
   RTS_DTR_Values_Array: array[1..4] of PChar =
      ('OFF', 'ON', 'CW', 'PTT');

type
   RigType = (rtUnknown, rtICOM, rtKenwood, rtYaesu1, rtYaesu2, rtYaesu3, rtYaesu4, rtJST, rtOrion, rtHamlib);

   BaudRateType = (BR1200, BR2400, BR4800, BR9600, BR19200, BR38400, BR57600, BR115200);
{
const
  Baud_Rate_Array                       : array[BaudRateType] of integer =
    (
    1200, 2400, 4800, 9600, 19200, 38400, 57600 , 115200
    );
}
type
   TRadioParameters = record
      //    Name: PChar;
      br:   BaudRateType; //Baud Rate
      p:    byte; //Polling
      c:    byte; //ShiftInCQMode
      s:    byte; //ShiftInSPMode
      t:    byte; //PTTViaCommand
      RA:   byte; //ReceiverAddress
      SW:   byte; //Swap
      SFOC: byte; //SetFreqOpCode
      SMOC: byte; //SetModeOpCode
      SPOC: byte; //SetPTTOpCode
      RX:   byte; //RXOpCode
      TX:   byte; //TXOpCode
      mb:   byte; //PositionOfModeByte

      CW:   byte; //CWLOpCode
      //    CWU: Byte; //CWLOpCode
      LSB:  byte; //LSBOpCode
      USB:  byte; //USBOpCode
      FM:   byte; //FMOpCode
      AM:   byte; //AMOpCode
      DIGL: byte; //DigLOpCode
      DIGU: byte; //DigUOpCode

      hamlibID: integer;
      rt: RigType;
   end;

//const
//  YaesuReplyRigs                        : array[0..1] of InterfacedRadioType = (FT857, FT897);
{
 When adding an item here, you have to
    1. Add a type to the InterfacedRadioType around line 1060 in VC.pas
    2. Each new radio requires the type in InterfacedRadioType, the entry
       below in the RadioParametersArray array and the literal name of the
       radio in InterfacedRadioTypeSA below.  // Issue 120
    3. Also update the Sets in InitRadio wherever applicable for the new radio. ** Important for CWBYCAT ad RIT functions
 - ny4i
       PLS NOTE VC INTERFACEDRADIOTYPE ARRAY AND THE BELOW ARRAY ARE IN THE SAME ORDER OF ENTRY !
 -- n4af
}
const
   RadioParametersArray: array[InterfacedRadioType] of
      TRadioParameters =
      (
{(*}
    ({Name: 'NONE';       } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00),
    ({Name: 'K2';         } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2021; rt: rtKenwood),
    ({Name: 'K3';         } BR:BR38400; P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2029; rt: rtKenwood),
    ({Name: 'KX3';        } BR:BR38400; P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2045; rt: rtKenwood),
    ({Name: 'K4';         } BR:BR38400; P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2047; rt: rtKenwood),
    ({Name: 'FLEX';       } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2048; rt: rtKenwood),     // 4.87.2
    ({Name: 'TS140';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2025; rt: rtKenwood),
    ({Name: 'TS440';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2002; rt: rtKenwood),
    ({Name: 'TS450';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2003; rt: rtKenwood),
    ({Name: 'TS480';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2028; rt: rtKenwood),
    ({Name: 'TS570';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2016; rt: rtKenwood),
    ({Name: 'TS590';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2004; rt: rtKenwood),
    ({Name: 'TS690';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2005; rt: rtKenwood),
    ({Name: 'TS850';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2009; rt: rtKenwood),
    ({Name: 'TS870';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2010; rt: rtKenwood),
    ({Name: 'TS890';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2041; rt: rtKenwood),  // Issue #436 -- native Kenwood serial; default 4800 baud (radio menu can raise to 115200)
    ({Name: 'TS940';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2011; rt: rtKenwood),
    ({Name: 'TS950';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2012; rt: rtKenwood),
    ({Name: 'TS990';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2039; rt: rtKenwood),
    ({Name: 'TS2000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 2041; rt: rtKenwood),
    ({Name: 'FT100';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02;  LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $05; DIGU: $05; hamlibID: 1021; rt: rtYaesu1),
    ({Name: 'FTDX10';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1042; rt: rtYaesu4),
    ({Name: 'FTDX101';    } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1040; rt: rtYaesu4),
    ({Name: 'FTX1F';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1051; rt: rtYaesu4),  // FTX-1F/FTX-1R — Issue #817
    ({Name: 'FT450';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1027; rt: rtYaesu2),
    ({Name: 'FT710';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu4),   // Issue 640 ny4i
    ({Name: 'FT736R';     } BR:BR4800;  P: 0; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02;  LSB: $00; USB: $01; FM: $08; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1010; rt: rtYaesu1),
    ({Name: 'FT747GX';    } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03;  LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $00; DIGU: $00; hamlibID: 1005; rt: rtYaesu1),
    ({Name: 'FT767';      } BR:BR4800;  P: 1; C: 1; S: 1; T:0; RA: $00; SW: 1; SFOC: $08; SMOC: $0A; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $12;  LSB: $10; USB: $11; FM: $14; AM: $13; DIGL: $15; DIGU: $15; hamlibID: 1009; rt: rtYaesu1),
    ({Name: 'FT817';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $88; TX: $08; MB: 0; CW: $02;  LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $0C; DIGU: $0A; hamlibID: 1020; rt: rtYaesu1),
    ({Name: 'FT818';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $88; TX: $08; MB: 0; CW: $02;  LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $0C; DIGU: $0A; hamlibID: 1041; rt: rtYaesu1),
    ({Name: 'FT840';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03;  LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $FF; DIGU: $FF; hamlibID: 1011; rt: rtYaesu1),
    ({Name: 'FT847';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $FF; hamlibID: 1001; rt: rtYaesu1),
    ({Name: 'FT857';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $0A; hamlibID: 1022; rt: rtYaesu1),
    ({Name: 'FT890';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $FF; DIGU: $FF; hamlibID: 1015; rt: rtYaesu1),
    ({Name: 'FT891';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1036; rt: rtYaesu3),
    ({Name: 'FT897';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $0A; hamlibID: 1023; rt: rtYaesu1),
    ({Name: 'FT900';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $FF; DIGU: $FF; hamlibID: 1013; rt: rtYaesu1),
    ({Name: 'FT920';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $0A; hamlibID: 1014; rt: rtYaesu1),
    ({Name: 'FT950';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1028; rt: rtYaesu2),
    ({Name: 'FT990';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $08; DIGU: $09; hamlibID: 1016; rt: rtYaesu1),
    ({Name: 'FT991';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1035; rt: rtYaesu3),
    ({Name: 'FT1000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; hamlibID: 1003; rt: rtYaesu1),
    ({Name: 'FT1000MP';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; hamlibID: 1024; rt: rtYaesu1),
    ({Name: 'FT1200';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1034; rt: rtYaesu2),
    ({Name: 'FT2000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1029; rt: rtYaesu2),
    ({Name: 'FTDX3000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1037; rt: rtYaesu2),
    ({Name: 'FTDX5000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1032; rt: rtYaesu2),
    ({Name: 'FTDX9000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1030; rt: rtYaesu2),
    ({Name: 'IC78';       } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $62; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3045; rt: rtIcom),
    ({Name: 'IC705';      } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $A4; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3085; rt: rtIcom),
    ({Name: 'IC706';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $48; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3009; rt: rtIcom),
    ({Name: 'IC706II';    } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $4E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3010; rt: rtIcom),
    ({Name: 'IC706IIG';   } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $58; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3011; rt: rtIcom),
    ({Name: 'IC707';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3012; rt: rtIcom),
    ({Name: 'IC718';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $5E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3013; rt: rtIcom),
    ({Name: 'IC725';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $28; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3014; rt: rtIcom),
    ({Name: 'IC726';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $30; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3015; rt: rtIcom),
    ({Name: 'IC728';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $38; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3016; rt: rtIcom),
    ({Name: 'IC729';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3017; rt: rtIcom),
    ({Name: 'IC735';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $04; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3019; rt: rtIcom),
    ({Name: 'IC736';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $40; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3020; rt: rtIcom),
    ({Name: 'IC737';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3021; rt: rtIcom),
    ({Name: 'IC738';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $44; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3022; rt: rtIcom),
    ({Name: 'IC746';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $56; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3023; rt: rtIcom),
    ({Name: 'IC746PRO';   } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $66; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3046; rt: rtIcom),
    ({Name: 'IC756';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $50; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3026; rt: rtIcom),
    ({Name: 'IC756PRO';   } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $5C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3027; rt: rtIcom),
    ({Name: 'IC756PROII'; } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $64; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3047; rt: rtIcom),
    ({Name: 'IC756PROIII';} BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $6E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3057; rt: rtIcom),
    ({Name: 'IC761';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $1E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3028; rt: rtIcom),
    ({Name: 'IC765';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $2C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3029; rt: rtIcom),
    ({Name: 'IC775';      } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $46; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3030; rt: rtIcom),
    ({Name: 'IC781';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $26; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3031; rt: rtIcom),
    ({Name: 'IC905';      } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $AC; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 0; rt: rtIcom),
    ({Name: 'IC910';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $60; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3044; rt: rtIcom),
    ({Name: 'IC970D';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $2E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3035; rt: rtIcom),
    ({Name: 'IC7000';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $70; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3060; rt: rtIcom),
    ({Name: 'IC7100';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $88; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3070; rt: rtIcom),
    ({Name: 'IC7200';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $76; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3061; rt: rtIcom),
    ({Name: 'IC7300';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $94; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3073; rt: rtIcom),
    ({Name: 'IC7300MK2';  } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $B6; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 0; rt: rtIcom),
    ({Name: 'IC7410';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $80; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3067; rt: rtIcom),
    ({Name: 'IC7600';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $7A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3063; rt: rtIcom),
    ({Name: 'IC7610';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $98; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3078; rt: rtIcom), // 4.65.7 issue #282 #282   // 4.68.12
    ({Name: 'IC7700';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $74; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3062; rt: rtIcom),
    ({Name: 'IC7760';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $B2; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3092; rt: rtIcom),
    ({Name: 'IC7800';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $6A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3056; rt: rtIcom),
    ({Name: 'IC7850';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $8E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3075; rt: rtIcom),
    ({Name: 'IC7851';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $8E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3075; rt: rtIcom),
    ({Name: 'IC9100';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $7C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3068; rt: rtIcom),
    ({Name: 'IC9700';     } BR:BR38400; P: 1; C: 0; S: 0; T:0; RA: $A2; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3081; rt: rtIcom),
    ({Name: 'OMNI6';      } BR:BR9600;  P: 1; C: 1; S: 1; T:0; RA: $04; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 3051; rt: rtIcom),
    ({Name: 'ORION';      } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 16008; rt:rtOrion),
    ({Name: 'FLRIG';      } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 4; rt:rtHamlib),
    ({Name: 'TRXMANAGER';} BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 5; rt:rtHamlib),
    ({Name: 'FT757GXII';  } BR:BR4800;  P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1007; rt:rtHamlib),
    ({Name: 'EXPERTTCI'; } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 7; rt:rtHamlib),
    ({Name: 'ACLOG';      } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 8; rt:rtHamlib),
    ({Name: 'HAMLIBANY';  } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; hamlibID: 1; rt:rtHamLib)
);
{*)}
const
   InterfacedRadioTypeSA: array[InterfacedRadioType] of PChar = (

      'NONE',
      'K2',
      'K3',
      'KX3',
      'K4',
      'FLEX',
      'TS440',
      'TS450',
      'TS480',
      'TS530',
      'TS570',
      'TS590',
      'TS690',
      'TS850',
      'TS870',
      'TS890',
      'TS940',
      'TS950',
      'TS990',
      'TS2000',
      'FT100',
      'FTDX10',
      'FTDX101',
      'FTX-1',
      'FT450',
      'FT710',
      'FT736R',
      'FT747GX',
      'FT767',
      'FT817',
      'FT818',
      'FT840',
      'FT847',
      'FT857',
      'FT890',
      'FT891',
      'FT897',
      'FT900',
      'FT920',
      'FT950',
      'FT990',
      'FT991',
      'FT1000',
      'FT1000MP',
      'FT1200',
      'FT2000',
      'FTDX3000',
      'FTDX5000',
      'FTDX9000',
      'IC78',
      'IC705',
      'IC706',
      'IC706II',
      'IC706IIG',
      'IC707',
      'IC718',
      'IC725',
      'IC726',
      'IC728',
      'IC729',
      'IC735',
      'IC736',
      'IC737',
      'IC738',
      'IC746',
      'IC746PRO',
      'IC756',
      'IC756PRO',
      'IC756PROII',
      'IC756PROIII',
      'IC761',
      'IC765',
      'IC775',
      'IC781',
      'IC905',
      'IC910H',
      'IC970D',
      'IC7000',
      'IC7100',
      'IC7200',
      'IC7300',
      'IC7300MK2',
      'IC7410',
      'IC7600',
      'IC7610',
      'IC7700',
      'IC7760',
      'IC7800',
      'IC7850',
      'IC7851',
      'IC9100',
      'IC9700',
      'OMNI6',
      'ORION',
      'FLRIG',          // HamLib Only
      'TRX-MANAGER',    // HamLib Only
      'FT757GXII',      // HamLib Only
      'EXPERTTCI',     // HamLib Only
      'ACLOG',          // HamLib Only
      'HAMLIB-ANY'      // HamLib Only
      );

 {
    const
    Radio_Type_Array: array[InterfacedRadioType] of PChar = (
    'NONE',
    'K2',
    'TS850',
    'FT100',
    'FT450',
    'FT736R',
    'FT767',
    'FT817',
    'FT818',
    'FT840',
    'FT847',
    'FT857',
    'FT890',
    'FT897',
    'FT900',
    'FT920',
    'FT950',
    'FT990',
    'FT1000',
    'FT1000MP',
    'FT2000',
    'FTDX9000',
    'IC706',
    'IC706II',
    'IC706IIG',
    'IC707',
    'IC718',
    'IC725',
    'IC726',
    'IC728',
    'IC729',
    'IC735',
    'IC736',
    'IC737',
    'IC738',
    'IC746',
    'IC746PRO',
    'IC756',
    'IC756PRO',
    'IC756PROII',
    'IC756PROIII',
    'IC761',
    'IC765',
    'IC775',
    'IC781',
    'IC7000',
    'IC7800',
    'OMNI6',
    'JST245',
    'ORION');
}


function IntegerToBCD(Value: DWORD): integer; // ny4i  // 4.44.5
function Integer4ToBCD(Value: DWORD): integer; // ny4i  // 4.44.5
function ModeTypeToNetMode(mode: ModeType): TRadioMode;
procedure InitRadios;
function OpenCATDebugFile(port: PortType): boolean;
//procedure CloseCATDebugFile(port: PortType);

function tPTTVIACAT(PTTOn: boolean): boolean;
//function GetRadioFromString(RadioName: ShortString): InterfacedRadioType;
procedure TestRadioInterface;


{ Old style function calls supported here }

{ Works on the radio specified  (Radio1 or Radio2) }

function GetRadioParameters(Radio: RadioType; RadioInfoString: string;
   var Freq: longint; var Band: BandType; var Mode: ModeType;
   Polling: boolean; Debug: boolean): boolean;
//wli
function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;
procedure PutRadioIntoSplit(Radio: RadioType);
procedure PutRadioOutOfSplit(Radio: RadioType);
procedure SetRadioFreq(Radio: RadioType; Freq: longint; Mode: ModeType; VFO: char);


{ These work on the ActiveRadio }

//procedure CheckRITKeys;

procedure RITClear;
procedure RITBumpDown;
procedure RITBumpUp;

procedure VFOBumpDown;
procedure VFOBumpUp;

procedure SetK3ExtendedCommandMode;




const

   //FT767PollString = NullKey + NullKey + NullKey + CHR($01) + NullKey;
   FT767PollString: Yaesu5Bytes = (0, 0, 0, 1, 0);
   FT767CATEnablePollingString = NullKey + NullKey + NullKey + NullKey + NullKey;
   FT767ACKString = NullKey + NullKey + NullKey + NullKey + CHR($0B);

   FT847PollString = NullKey + NullKey + NullKey + NullKey + CHR($03);
   FT747GXPollString = NullKey + NullKey + NullKey + NullKey + CHR($10);

   FT1000MPPoll1String = CHR($00) + CHR($00) + CHR($00) + CHR($02) + CHR($10); //16 answer
   FT1000MPPoll2String = CHR($00) + CHR($00) + CHR($00) + CHR($03) + CHR($10); //32b answer
   FT1000MPPoll3String = CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($FA);

   FT100StatusUpdate = CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($10);
   FT100ReadStatusFlags = CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($FA);

   TurnOn847CATString = NullKey + NullKey + NullKey + NullKey + CHR($00);
   TurnOff847CATString = NullKey + NullKey + NullKey + NullKey + CHR($80);

implementation

uses
   LogK1EA,
   LogWind,
   MainUnit, uRadioPolling,
   uTelnet,
   LogStuff,
   LogSUBS2,
   LogCW,
   uRadioHamLibDirect,
   uRadioIcomBase,
   uRadioKenwoodTS890;  // Issue #436



procedure TEventHandlers.OnTimerTick(Sender : TObject);
var callInactive: boolean;
begin
  DebugMsg('TimerTick event fired');
  TTimer(Sender).Enabled := false;
  if IsCWByCATActive(ActiveRadioPtr) then
     begin
     if ActiveRadioPtr.CWByCAT_Sending then
        begin
        ActiveRadioPtr.CWByCAT_Sending := false;
        callInactive := true;
        end;
     end;

  if IsCWByCATActive(InActiveRadioPtr) then
  begin
  if InActiveRadioPtr.CWByCAT_Sending then
     begin
     InActiveRadioPtr.CWByCAT_Sending := false;
     callInactive := true;
     end;
  end;

  if callInactive then
     begin
     BackToInactiveRadioAfterQSO;
     end;
end;

function IntegerToBCD(Value: DWORD): integer;
const
   Dividers: array[1..8] of integer = (1, 10, 100, 1000, 10000, 100000, 1000000, 10000000);
var
   j: integer;
begin
   Result := 0;
   for j := 8 downto 1 do //8 digits
      begin
      Result := (Result shl 4) or ((Value div Dividers[j]) mod 10);
      end;
end;//IntegerToBCD

function Integer4ToBCD(Value: DWORD): integer;
const
   Dividers: array[1..8] of integer = (1, 10, 100, 1000, 10000, 100000, 1000000, 10000000);
var
   j: integer;
begin
   Result := 0;
   for j := 2 downto 1 do //4 digits
      begin
      Result := (Result shl 4) or ((Value div Dividers[j]) mod 10);
      end;
end;//Integer4ToBCD

function ModeTypeToNetMode(mode: ModeType): TRadioMode; // TRadioMode is the Network mode type
begin
{Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
                   }
   case mode of
      CW: Result := rmCW;
      Digital: Result := rmData;
      Phone: Result := rmUSB;
      FM: Result := rmFM;
   else
      // Both / NoMode have no specific radio mode. Without this else the
      // function Result was left UNINITIALIZED -> garbage TRadioMode (often
      // rmData), which made a band change shove the radio into DATA. Return the
      // "none" mode so the caller sends no mode command and the radio keeps its
      // mode. (Use Low(TRadioMode), which is rmNone; the bare identifier rmNone
      // is ambiguous in LOGRADIO -- it also exists in TRadioModel, which wins.)
      Result := Low(TRadioMode);
   end;
 //  ModeType = (CW, Digital, Phone, Both, NoMode, FM); { Use for TR }
           //AM, CW, CW-R, DATA-L, DATA-U, FM, LSB, USB, RTTY, RTTY-R, WBFM
  //ExtendedRadioModeType = (rNoMode, rCW, rLSB, rUSB, rAM, rFM, rRTTY, rRTTY_R, rAFSK, rDATA_U, rDATA_L, rDIGITAL, rCW_R);


end;


function BufToStr(var buf; bufSize: integer): string;
begin
   SetLength(Result, bufSize);
   Move(buf, pointer(Result)^, bufSize);
end;
//------------------------------------------------------------------------------
procedure LinkToActiveRadio(IntRadioType: InterfacedRadioType;
   SerialPort: PortType);
begin
   if ActiveRadio = RadioOne then
      begin
//      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
//      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;
end;


procedure SetK3ExtendedCommandMode;
begin
   ActiveRadioPtr.WriteBufferToCATPort('K31;');
end;


procedure RITClear;

var
   IntRadioType: InterfacedRadioType;
//   SerialPort: PortType;

begin

   if ActiveRadio = RadioOne then
      begin
      if Radio1.tNetObject <> nil then
         begin
         Radio1.tNetObject.RITClear(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      if Radio2.tNetObject <> nil then
         begin
         Radio2.tNetObject.RITClear(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;

   case IntRadioType of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940,
      TS950, TS990, TS2000, FLEX, K2, K3, K4, FTDX10, FTDX101, FTX1F, FT450, FT891, FT950, FT991, FT1200, FT2000, FTDX3000,
      FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RC;');
         end;
      FT710:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('CF001+0000;'); // Set frequency to +0
         end;
      FT747GX, FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR($FF) + CHR($09), 5);
         end;

      IC78..IC9700:
         begin
         if IntRadioType in IcomRadiosThatSupportRIT then
            begin
            ActiveRadioPtr.SendIcomClearRITCommand;
            end;
         end;
      OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         // Check what radios support this and send command to clear 21 00 00 00 00 on 9700
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR0' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure RITBumpUp;

var
   IntRadioType: InterfacedRadioType;
   ActiveNetObj: TNetRadioBase;
//   SerialPort: PortType;

begin
   if ActiveRadio = RadioOne then
      ActiveNetObj := Radio1.tNetObject
   else
      ActiveNetObj := Radio2.tNetObject;

   if ActiveNetObj <> nil then
      begin
      ActiveNetObj.RITBumpUp;
      Exit;
      end;
   if ActiveRadio = RadioOne then
      begin
      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;

   case IntRadioType of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940,
      TS950, TS990, TS2000, K2, K3, K4 {, FTDX9000}:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RU;');
         end;

      FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         Exit;
         end;

      IC78..IC9700, OMNI6: {KK1L: 6.73 Added OMNI6}    // This does not work for all Icom radios.
         begin
         if IntRadioType in IcomRadiosThatSupportRIT then
            begin
         // Have to know what RIT is set to now and then increase it by a bit. RIT should be in radio poll so we always know
         // Not implemented yet due to issues converting the hz to BCD
         //ActiveRadioPtr.SetICOMRITFrequency(ActiveRadioPtr.CurrentStatus.RITFreq + 10);
            end;
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR200' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure RITBumpDown;

var
   IntRadioType: InterfacedRadioType;
   ActiveNetObj: TNetRadioBase;
//   SerialPort: PortType;

begin
   if ActiveRadio = RadioOne then
      ActiveNetObj := Radio1.tNetObject
   else
      ActiveNetObj := Radio2.tNetObject;

   if ActiveNetObj <> nil then
      begin
      ActiveNetObj.RITBumpDown;
      Exit;
      end;

   if ActiveRadio = RadioOne then
      begin
      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;

   case IntRadioType of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940,
      TS950, TS990, TS2000, K2, K3, K4 {, FTDX9000}:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RD;');
         end;

      FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         Exit;
         end;

      IC78..IC9700, OMNI6: {KK1L: 6.73 Added OMNI6} // Add code somewhere tohandle radios that do not support 21 code.
         begin
         if IntRadioType in IcomRadiosThatSupportRIT then
            begin
            // Not implemented yet due to issues converting the hz to BCD
            //ActiveRadioPtr.SetICOMRITFrequency(ActiveRadioPtr.CurrentStatus.RITFreq - 10);
            end;
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR-200' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure VFOBumpUp;

var
   IntRadioType: InterfacedRadioType;
//   SerialPort: PortType;

begin

   if ActiveRadio = RadioOne then
      begin
      if Radio1.tNetObject <> nil then
         begin
         Radio1.tNetObject.VFOBumpUp(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      if Radio2.tNetObject <> nil then
         begin
         Radio2.tNetObject.VFOBumpUp(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;

   case IntRadioType of

      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940,
      TS950, TS990, TS2000:
         begin
         ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('UP;', 3);
         end;

      FTDX10, FT450, FT891, FT991, FT950, FT2000, FTDX9000, K2, K3, K4:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('UP;');
         end;

      FT890, {FT920,} FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR($8E) + CHR(0) + CHR(0) + CHR(0) + CHR(0));
         end;

      FT767:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR($02));
         end;

      IC78..IC9700, OMNI6, FLEX:
         begin
         if ActiveRadioPtr.CurrentStatus.Freq = 0 then
            begin
            Exit;
            end;
         ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq + 20,
            ActiveRadioPtr.CurrentStatus.Mode, 'A');
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*AS+1' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure VFOBumpDown;

var
   IntRadioType: InterfacedRadioType;
//   SerialPort: PortType;

begin
   if ActiveRadio = RadioOne then
      begin
      if Radio1.tNetObject <> nil then
         begin
         Radio1.tNetObject.VFOBumpDown(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio1.RadioModel;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      if Radio2.tNetObject <> nil then
         begin
         Radio2.tNetObject.VFOBumpDown(nrVFOA);
         Exit;
         end;
      IntRadioType := Radio2.RadioModel;
//      SerialPort := Radio2.tCATPortType;
      end;

   case IntRadioType of

      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940,
      TS950, TS990, TS2000:
         begin
         ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('DN;', 3);
         end;

      FT450, FT891, FT991, FT950, FT2000, FTDX9000, K2, K3, K4:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('DN;');
         end;

      FT890, {FT920,} FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR($8E) + CHR(1) + CHR(0) + CHR(0) + CHR(0));
         end;

      FT767:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR($03));
         end;

      IC78..IC9700, OMNI6, FLEX:
         begin
         if ActiveRadioPtr.CurrentStatus.Freq = 0 then
            begin
            Exit;
            end;
         ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq - 20,
            ActiveRadioPtr.CurrentStatus.Mode, 'A');
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*AS-1' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;



 {
procedure CheckRITKeys;

var
  TestByte                         : Byte;

begin
  if not ShiftKeyEnable then Exit;

  //WLI    TestByte := Mem [$40:$17];

  TestByte := TestByte and $0F; // Mask off the lock keys

  case TestByte of
    1:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITBumpUp;
        MarkTime(RITCommandTimeStamp);
      end;

    2:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITBumpDown;
        MarkTime(RITCommandTimeStamp);
      end;

    3:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITClear;
        MarkTime(RITCommandTimeStamp);
      end;

  end;

end;
} 

function GetRadioParameters(Radio: RadioType; RadioInfoString: string;
   var Freq: longint; var Band: BandType; var Mode: ModeType;
   Polling: boolean; Debug: boolean): boolean;

begin
   //  GetRadioParameters := true;

   case Radio of
      RadioOne:
         begin
         with Radio1 do
            begin
            Freq := FilteredStatus.Freq;
            Band := FilteredStatus.Band;
            Mode := FilteredStatus.Mode;
            GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
            end;
         end;

      RadioTwo:
         begin
         with Radio2 do
            begin
            Freq := FilteredStatus.Freq;
            Band := FilteredStatus.Band;
            Mode := FilteredStatus.Mode;
            GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
            end;
         end;
      end;
end;

procedure PutRadioIntoSplit(Radio: RadioType);

begin
   case Radio of
      RadioOne:
         begin
         Radio1.PutRadioIntoSplit;
         end;
      RadioTwo:
         begin
         Radio2.PutRadioIntoSplit;
         end;
      end;
end;

procedure PutRadioOutOfSplit(Radio: RadioType);

begin
   case Radio of
      RadioOne:
         begin
         Radio1.PutRadioOutOfSplit;
         end;
      RadioTwo:
         begin
         Radio2.PutRadioOutOfSplit;
         end;
      end;
end;

procedure SetRadioFreq(Radio: RadioType; Freq: longint; Mode: ModeType; VFO: char);

{ Backwards compatable routine to the pre TR680 days }

begin
   case Radio of
      RadioOne:
         begin
         Radio1.SetRadioFreq(Freq, Mode, VFO);
         end;
      RadioTwo:
         begin
         Radio2.SetRadioFreq(Freq, Mode, VFO);
         end;
      end;
end;

procedure RadioObject.WriteBufferToCATPort(const Buffer);
begin
   WriteToCATPort(Buffer, lstrlen(@Buffer));
end;

function RadioObject.WritePollRequest(const Buffer;
   nNumberOfBytesToWrite: DWORD): longbool;
begin
 { if NoPollDuringPTT then
  if tPTTStatus = PTT_ON then
  Sleep(500);   }
 //     try
     begin
      Result := WriteToCATPort(Buffer, nNumberOfBytesToWrite);
  //    except //on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In WritePollRequest, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
   if not Result then
      begin
      Sleep(200);
      end;
end;


function RadioObject.AddToOutputBuffer(Buffer: PChar;
   nNumberOfBytesToWrite: DWORD): longbool;
begin
   //  TLogger.GetInstance.Debug('In AddToOutputBuffer');
   //  sleep(100);
   //  Windows.lstrcat(CommandsBuffer[0], Buffer);
{$IF MASKEVENT}
   Windows.CopyMemory(@CommandsBuffer[0][CommandsBufferPointer], Buffer,
      nNumberOfBytesToWrite);
   Inc(CommandsBufferPointer, nNumberOfBytesToWrite);
{$ELSE}
  if Self.tNetObject <> nil then
     begin
     logger.Trace('[AddToOutputBuffer-Network] %s',[Buffer]);
     Self.tNetObject.SendToRadio(Buffer);
     end
  else
     begin
     logger.Trace('[AddToOutputBuffer-Serial] %s',[Buffer]);
     // Take this radio's serial lock so the write cannot be interleaved with a
     // poll cycle's read on the same port (closes the race where a short KY
     // message lands inside a pKenwood2 IF; cycle and never keys) -- but ONLY
     // when CW-by-CAT is in use on this radio.  For any other radio this is the
     // same bare WriteToCATPort as master (and AddToOutputBuffer is only called
     // on the main thread, so Self.CWByCAT cannot flip between Enter and Leave).
     if Self.CWByCAT then
        begin
        EnterCriticalSection(Self.CATSerialLock);
        end;
     try
        WriteToCATPort(Buffer^, nNumberOfBytesToWrite);
     finally
        if Self.CWByCAT then
           begin
           LeaveCriticalSection(Self.CATSerialLock);
           end;
     end;
     end;
{$IFEND}
   //TLogger.GetInstance.Debug('Exiting AddToOutputBuffer');
end;

function RadioObject.WriteToCATPort(const Buffer;
   nNumberOfBytesToWrite: DWORD): longbool;
var
   lpNumberOfBytesWritten: DWORD;

   i: integer;
   s: string;
   Buf: array[0..100 * 2] of Char;
   nLen: integer;

begin
{
  if not DVKEnable then
    if RadioModel = TS850 then
      if nNumberOfBytesToWrite = 4 then
        if PChar(Buffer)[0] = 'P' then
          if PChar(Buffer)[1] = 'B' then
            if PChar(Buffer)[2] in ['1'..'3'] then
              if PChar(Buffer)[3] = ';' then
              begin
//                Result := 0;
                Exit;
              end;
}
      try
      if logger.IsTraceEnabled then
         begin
         if true then //not (nNumberOfBytesToWrite in [3,6,7]) then
            begin
            logger.trace('>>>>Enter WriteToCATPort');
            SetString(debugStr,PChar(@Buffer),nNumberOfBytesToWrite);
            nLen := nNumberOfBytesToWrite; //Ord(Buffer[0]);
            if Self.RadioModel in IcomRadios then
               begin
               BinToHex(@Buffer,Buf,nLen);
               Buf[(nLen*2) - 2] := #0;
               logger.trace(Format('[%s] Calling WriteFile to write %u bytes <%s>',[RadioName,nNumberOfBytesToWrite,Buf]));
               end
            else
               begin
               // Hex alongside the text so non-printable control bytes are visible
               // -- e.g. the K3 keyer-abort 'KY <04>;RX;' (Chr(4)) shows as plain
               // 'KY ;RX;' in a text-only trace, hiding the control byte entirely.
               BinToHex(@Buffer,Buf,nLen);
               Buf[nLen * 2] := #0;
               logger.trace(Format('[%s] Calling WriteFile to write %u bytes <%s> hex[%s]',[RadioName,nNumberOfBytesToWrite,debugStr,Buf]));
               end;
            end;
         end;

      Windows.WriteFile(tCATPortHandle, Buffer, nNumberOfBytesToWrite,
         lpNumberOfBytesWritten, nil);
      except // on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In WriteToCATPort..WriteFile, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
{
  if not Windows.WriteFile(tCATPortHandle, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, pOver) then
    if pOver <> nil then
      if GetLastError = ERROR_IO_PENDING then
      begin
        Result := True;
        Exit;
      end;
}
   Result := nNumberOfBytesToWrite = lpNumberOfBytesWritten;
{$IF NEWER_DEBUG}
   if not (nNumberOfBytesToWrite in [3,6,7]) then
      begin
      DebugMsg('<<<<Exit WriteToCATPort');
      end;
{$IFEND}
end;

{ The initializtion of BeginPolling is in this procedure so if we are not using serial ports, it has to be setup somewhere else.}
procedure RadioObject.CheckAndInitializePorts_ForThisRadio;
begin
   if RadioModel = NoInterfacedRadio then
      begin
      Exit;
      end;
   if RadioModel in [IC78..IC9700, FT100, Orion] then
      begin
      RadioStopBits := 1;
      end
   else
      begin
      RadioStopBits := 2;
      end;
   SetUpRadioInterface;

   if (tCATPortHandle <> INVALID_HANDLE_VALUE) or
      (Self.tNetObject <> nil)                 then
      begin
      if PollingEnable then
         begin
         tPollCount := -1;
         tRadioInterfaceThreadHandle :=
            CreateThread(nil, 0, @BeginPolling, @Self, 0, tRadioInterfaceThreadID);
         logger.Info('Created Radio %s thread with threadid of %d',[Self.RadioName, tRadioInterfaceThreadID] );
         end;
      end;

end;

procedure RadioObject.FreqToBCD(Freq: longint; Swap: boolean; OpCode: byte);
var
   TempByte, sb1, sb2: byte;
   c: cardinal;
   TempFreq: longint;
begin
   ZeroMemory(@tYaesuFreq5Bytes, SizeOf (tYaesuFreq5Bytes));
   tYaesuFreq5Bytes[4] := OpCode;
   TempFreq := Freq div 10;
   for c := 3 downto 0 do
      begin
      TempByte := TempFreq mod 100;
      TempFreq := TempFreq div 100;
      sb1 := TempByte div 10;
      sb2 := TempByte mod 10;
      if c = 0 then
         begin
         if Freq > 1000000000 then
            begin
            sb1 := sb1 + 10;
            end;
         end;
      TempByte := sb1 * 16 + sb2;
      tYaesuFreq5Bytes[c] := TempByte;
      end;

   if Swap then
      begin
      c := PDWORD(@tYaesuFreq5Bytes)^;
      // Issue #997: BSWAP EAX -> reverse the four bytes (c is Cardinal).
      c := ((c and $000000FF) shl 24) or
           ((c and $0000FF00) shl 8)  or
           ((c and $00FF0000) shr 8)  or
           ((c and $FF000000) shr 24);
      PDWORD(@tYaesuFreq5Bytes)^ := c;
      end;
end;

function RadioObject.ConvertBCDStringToFreq(BCDString: Str20): longint;

var
   F1: longint;

begin
   if length(BCDString) = 5 then
      begin
      F1 := (Ord(BCDString[5]) and $F0) shr 4; { 1000s of mhz }
      F1 := F1 * 10;
      F1 := F1 + (Ord(BCDString[5]) and $0F); { 100s of mhz}
      F1 := F1 * 10;
      end
   else
      begin
      F1 := 0;
      end;

   F1 := F1 + ((Ord(BCDString[4]) and $F0) shr 4); { 10s of mhz }
   F1 := F1 * 10;
   F1 := F1 + (Ord(BCDString[4]) and $0F); { 1s of mhz}
   F1 := F1 * 10;

   F1 := F1 + ((Ord(BCDString[3]) and $F0) shr 4);
   F1 := F1 * 10;
   F1 := F1 + (Ord(BCDString[3]) and $0F);
   F1 := F1 * 10;

   F1 := F1 + ((Ord(BCDString[2]) and $F0) shr 4);
   F1 := F1 * 10;
   F1 := F1 + (Ord(BCDString[2]) and $0F);
   F1 := F1 * 10;

   F1 := F1 + ((Ord(BCDString[1]) and $F0) shr 4);
   F1 := F1 * 10;

   F1 := F1 + (Ord(BCDString[1]) and $0F);

   ConvertBCDStringToFreq := F1;
end;

function FrequencyFromFourBytes(FreqStr: string): longint;

var
   F1, F2, F3: longint;

begin
   F1 := Ord(FreqStr[1]);
   F1 := F1 * 256 * 256 * 256;
   F2 := Ord(FreqStr[2]);
   F2 := F2 * 256 * 256;
   F3 := Ord(FreqStr[3]);
   F3 := F3 * 256;
   FrequencyFromFourBytes := F1 + F2 + F3 + Ord(FreqStr[4]);
end;

procedure RadioObject.SendIcomTwoByteCommand(Command: byte; opCode: byte);

begin

   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Command;
   tIcom7Bytes[5] := Ord(Chr(opCode));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom6Bytes, 7);
end;
procedure RadioObject.SendIcomCommand(Command: byte);

begin

   tIcom6Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom6Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom6Bytes[2] := ReceiverAddress;
   tIcom6Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom6Bytes[4] := Command;
   tIcom6Bytes[5] := Ord(ICOM_END_OF_MESSAGE_CODE);

   //TLogger.GetInstance.Debug(Format('In SendIcomCommand, Sending command %s',[Chr(Command)]));
   WriteToCATPort(tIcom6Bytes, 6);
end;
//------------------------------------------------------------------------------
procedure RadioObject.SendXMITStatusCommand;
begin
   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Ord(ICOM_XMIT_SETTINGS);
   tIcom7Bytes[5] := (Ord(Chr(0)));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom7Bytes, 7);
end; // SendXMITStatusCommand;
 //------------------------------------------------------------------------------
 procedure RadioObject.GetIcomDataStateCommand;
begin
   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Ord(ICOM_STATE);
   tIcom7Bytes[5] := (Ord(ICOM_STATE_DATA_MODE));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom7Bytes, 7);
end; // GetDatyaStateCommand;
//---------------------------------------------------------------------------
 procedure RadioObject.SendRITStatusCommand;
begin
   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Ord(ICOM_GET_RIT_FREQ);
   tIcom7Bytes[5] := (Ord(Chr(1)));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom7Bytes, 7);
end; // SendRITStatusCommand;

procedure RadioObject.SendRITFreqCommand;
begin
   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Ord(ICOM_GET_RIT_FREQ);
   tIcom7Bytes[5] := (Ord(Chr(0)));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom7Bytes, 7);
end; // SendRITFreqCommand;


procedure RadioObject.SetICOMRITFrequency(hz: integer);

begin
   {CommandsTempBuffer[0] := Chr(11);
   CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
   CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
   CommandsTempBuffer[3] := Chr(ReceiverAddress);
   CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
   CommandsTempBuffer[5] := ICOM_GET_RIT_FREQ;
   CommandsTempBuffer[6] := Chr(0);
   {absHz := abs(hz);
   foo := Integer4ToBCD(absHz);
   newFreq := ((absHz mod 100) * 100) + absHz div 100;

   CommandsTempBuffer[7] := Chr(absHz mod 100);// Put frequency here
   CommandsTempBuffer[8] := Chr(absHz div 100);
   CommandsTempBuffer[7] := Chr(absHz div 1000 mod 10);
   CommandsTempBuffer[8] := Chr(absHz div 100 mod 10);
   CommandsTempBuffer[7] := Chr(foo div 100);
   CommandsTempBuffer[8] := Chr(foo mod 100);



    if hz < 0 then
      begin
      CommandsTempBuffer[9] := Chr(1);
      end
   else
      begin
      CommandsTempBuffer[9] := Chr(0);
      end;
   CommandsTempBuffer[10] := ICOM_END_OF_MESSAGE_CODE;
   AddCommandToBuffer;
   }
end;

function RadioObject.MemoryKeyer(mem: integer): boolean;
var localMsg:string;
    hiMem: integer;
begin
   if Self.tNetObject <> nil then
      begin
      Result := Self.tNetObject.MemoryKeyer(mem);
      Exit;
      end;

   if not (RadioModel in RadioSupportsPlayDVK) then
      begin
      logger.Warn('Radio does not support playing a voice keyer memory');
      Result := true;
      Exit;
      end;

   case RadioModel of
      K3:
         begin
         if IntegerBetween(mem,0,4) then
            begin
            if logger.IsDebugEnabled then
               begin
               if mem = 0 then
                  begin
                  logger.debug('[K3-MemoryKeyer] Stopping playback of DVK message');
                  end
               else
                  begin
                  logger.debug('[K3-MemoryKeyer] Playing memory %d',[mem]);
                  end;
               end;
            case mem of
            0: localMsg := 'SWT37;'; // RECD button to cancel playback
            1: localMsg := 'SWT21;';
            2: localMsg := 'SWT31;';
            3: localMsg := 'SWT35;';
            4: localMsg := 'SWT39;';
            end;
            AddToOutputBuffer(addr(localMsg[1]),length(localMsg));
            Result := false;
            end
         else
            begin
            logger.error('Memory value (%d) out of range for a K3 in MemoryKeyer',[mem]);
            Result := true;
            end;
         end;
      K4:
         begin
         if mem = 0 then
            begin
            logger.debug('[K4-Serial-MemoryKeyer] Stopping DVK');
            localMsg := 'DA0;';  // DA0; Stops all DVK activity
            AddToOutputBuffer(addr(localMsg[1]),length(localMsg));
            Result := false;
            end
         else if IntegerBetween(mem,1,8) then
            begin
            logger.debug('[K4-MemoryKeyer] Playing memory %d',[mem]);
            localMsg := Format('DAMP%d00000;',[mem]);  // DAMPmnnnnn; where m is mem number and nnnnn is repeat in ms (set to 00000)
            AddToOutputBuffer(addr(localMsg[1]),length(localMsg));
            Result := false;
            end
         else
            begin
            logger.error('Memory value (%d) out of range for a K4 in MemoryKeyer',[mem]);
            Result := true;
            end;
         end;

      IC705, IC7100, IC7300, IC7610, IC7760, IC7850, IC7851, IC9100, IC9700, IC905, IC7300MK2:
         begin
         if IntegerBetween(mem,0,8) then
            begin
            logger.debug('[Icom-MemoryKeyer] Playing memory %d',[mem]);
            CommandsTempBuffer[0] := CHR(9);
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SET_DVK;
            CommandsTempBuffer[6] := CHR(0);  // sub command
            CommandsTempBuffer[7] := Chr(mem);
            CommandsTempBuffer[8] := ICOM_END_OF_MESSAGE_CODE;
            AddCommandToBuffer;
            Result := false;
            end
         else
            begin
            logger.error('Memory value (%d) out of range for an Icom in MemoryKeyer',[mem]);
            Result := true;
            end;
         end;
      TS480, TS570, TS590, TS850, TS890, TS950, TS990, TS2000:
         begin
         case RadioModel of
            TS590: hiMem := 3;
            TS890: hiMem := 6;  // Issue #436 -- TS-890 PB memories 1..6
            TS990: hiMem := 6;
            else hiMem := 3;
         end;
         if IntegerBetween(mem,0,hiMem) then
            begin
            logger.debug('[Kenwood-MemoryKeyer] Playing memory %d',[mem]);
            localMsg := Format('PB%d;',[mem]);

            ActiveRadioPtr.WriteToCATPort(localMsg[1],length(localMsg));
            Result := false;
            end
         else
            begin
            logger.error('Memory value (%d) out of range for a Kenwood in MemoryKeyer',[mem]);
            Result := true;
            end;
         end;
      FT710, FT991, FTDX10, FTDX101, FT1200, FTDX3000, FTDX5000, FTDX9000: 
         begin
         if IntegerBetween(mem,0,5) then
            begin
            logger.debug('[Yaesu-MemoryKeyer] Playing memory %d',[mem]);
            localMsg := Format('PB0%d;',[mem]);

            ActiveRadioPtr.WriteToCATPort(localMsg[1],length(localMsg));
            Result := false;
            end
         else
            begin
            logger.error('Memory value (%d) out of range for a Yaesu in MemoryKeyer',[mem]);
            Result := true;
            end;
         end;
      else
         begin
         logger.Warn('[MemoryKeyer] Memory playbacdk not yet implemented for this radio');
         Result := true;
         end;
      end;
   //TLogger.GetInstance.Debug(Format('      Leaving PutRadioOutOfSplit: %s',[RadioName]));
end;


procedure RadioObject.ProcessIcomMode(mode: integer);
begin
   case mode of
   0:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eLSB;
      end;
   1:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eUSB;
      end;
   2:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eAM;
      end;
   3:
      begin
      Self.CurrentStatus.Mode := CW;
      Self.CurrentStatus.ExtendedMode := eCW;
      end;
   4:
      begin
      Self.CurrentStatus.Mode := Digital;
      Self.CurrentStatus.ExtendedMode := eRTTY;
      end;
   5:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eFM;
      end;
   6:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eWFM;
      end;
   7:
      begin
      Self.CurrentStatus.Mode := CW;
      Self.CurrentStatus.ExtendedMode := eCW_R;
      end;
   8:
      begin
      Self.CurrentStatus.Mode := Digital;
      Self.CurrentStatus.ExtendedMode := eRTTY_R;
      end;
   12:
      begin
      Self.CurrentStatus.Mode := Digital;
      Self.CurrentStatus.ExtendedMode := ePSK31;
      end;
   13:
      begin
      Self.CurrentStatus.Mode := Digital;
      Self.CurrentStatus.ExtendedMode := ePSK_R;
      end;
   17:
      begin
      Self.CurrentStatus.Mode := Phone;
      Self.CurrentStatus.ExtendedMode := eDSTAR;
      end;
   else
      DEBUGMSG('Unknown Mode command from Icom ' + IntToStr(mode));
   end;
end;


procedure RadioObject.SendIcomClearRITCommand;
begin
   tIcom11Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[2] := ReceiverAddress;
   tIcom11Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom11Bytes[4] := Ord(ICOM_GET_RIT_FREQ);
   tIcom11Bytes[5] := (Ord(Chr(0)));
   tIcom11Bytes[6] := (Ord(Chr(0)));
   tIcom11Bytes[7] := (Ord(Chr(0)));
   tIcom11Bytes[8] := (Ord(Chr(0)));
   tIcom11Bytes[9] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom11Bytes, 10);
end; // SendRITFreqCommand;


procedure RadioObject.SendIcomExtendedVFO(bVFO: boolean);
begin
   tIcom11Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[2] := ReceiverAddress;
   tIcom11Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom11Bytes[4] := Ord(ICOM_GET_EXTENDEDVFO);
   tIcom11Bytes[5] := ifthen(bVFO,Ord(Chr(1)),Ord(Chr(0)));
   tIcom11Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom11Bytes, 7);
end; // SendIcomExtendedVFO

procedure RadioObject.SendIcomExtendedMode(bVFO: boolean);
begin
   tIcom11Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom11Bytes[2] := ReceiverAddress;
   tIcom11Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom11Bytes[4] := Ord(ICOM_GET_EXTENDEDMODE);
   tIcom11Bytes[5] := ifthen(bVFO,Ord(Chr(1)),Ord(Chr(0)));
   tIcom11Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom11Bytes, 7);
end; // SendIcomExtendedMode

procedure RadioObject.PutRadioIntoSplit;

begin
   //TLogger.GetInstance.Debug(Format('      In PutRadioIntoSplit: %s',[RadioName]));
   if Self.tNetObject <> nil then
      begin
      Self.tNetObject.Split(true);
      Exit;
      end;

   case RadioModel of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3, K4:
         begin
         AddToOutputBuffer('FR0;FT1;', 8);

         {KK1L: 6.71 For some reason needed this to get the FT1; }
         {           command to take. Started when I added setting }
         {           mode of B VFO to set freq.                    }

         //        ActiveRadioPtr.WriteBufferToCATPort('FA;');
         //        ActiveRadioPtr.WriteBufferToCATPort('FT1;');//vfo b = tx
         end;

      IC78..IC9700, OMNI6: { KK1L: 6.73 Added OMNI6 }
         begin

         CommandsTempBuffer[0] := CHR(8);
         CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[3] := CHR(ReceiverAddress);
         CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
         CommandsTempBuffer[5] := ICOM_SET_SPLIT_MODE;
         CommandsTempBuffer[6] := CHR(1);
         CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
         AddCommandToBuffer;

         end;

      FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(1) + CHR(1), 5);
         end;

      FT450, FT950, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteToCATPort('FR0;FT3;', 8);  // ny4i Was 'FR0;FT1;. Changed for Issue166
         end;
      FT891:
         begin
         ActiveRadioPtr.WriteToCATPort('ST1;', 4);
         end;
      FTDX10, FTDX101, FTX1F, FT991:
         begin
         ActiveRadioPtr.WriteToCATPort('FT3;', 4);
         end;
      FT710:
         begin
         ActiveRadioPtr.WriteToCATPort('FT1;', 4);
         end;
      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*KVABB' + CarriageReturn);
         end;

      end;
   // TLogger.GetInstance.Debug(Format('      Leaving PutRadioIntoSplit: %s',[RadioName]));
end;

procedure RadioObject.PutRadioOutOfSplit;

begin
   //TLogger.GetInstance.Debug(Format('      In PutRadioOutOfSplit: %s',[RadioName]));
   if Self.tNetObject <> nil then
      begin
      Self.tNetObject.Split(false);
      Exit;
      end;

   case RadioModel of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3, K4:
         begin
         //ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('FR0;FT0;', 8);
         AddToOutputBuffer('FR0;FT0;', 8);

         //        ActiveRadioPtr.WriteBufferToCATPort('FT0;');
         end;

      IC78..IC9700, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         // TLogger.GetInstance.Debug('Sending commands to take Icom out of Split');
         CommandsTempBuffer[0] := CHR(8);
         CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[3] := CHR(ReceiverAddress);
         CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
         CommandsTempBuffer[5] := ICOM_SET_SPLIT_MODE;
         CommandsTempBuffer[6] := CHR(0);
         CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
         AddCommandToBuffer;
         end;

      FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP: { QSL }
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(1), 5);
         end;

      FT450, FT950, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteToCATPort('FR0;FT2;', 8);       // ny4i Issue 166 Was FR0;FT0;
         end;
      FT891:
         begin
          ActiveRadioPtr.WriteToCATPort('ST0;', 4);
         end;
      FTDX10, FTDX101, FTX1F, FT991:
         begin
         ActiveRadioPtr.WriteToCATPort('FT2;', 4);
         end;
      FT710:
         begin
         ActiveRadioPtr.WriteToCATPort('FT0;', 4);
         end;
      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*KVABA' + CarriageReturn);
         end;

      end;
   //TLogger.GetInstance.Debug(Format('      Leaving PutRadioOutOfSplit: %s',[RadioName]));
end;

procedure RadioObject.UpdateRadioStatus;

{ Updates the filtered radio status } // This is not called anymore

begin
   if CurrentStatus.Freq = PreviousStatus.Freq then
      begin
      FilteredStatus.Freq := CurrentStatus.Freq;
      end;

   if CurrentStatus.Mode = PreviousStatus.Mode then
      begin
      FilteredStatus.Mode := CurrentStatus.Mode;
      end;

      if CurrentStatus.ExtendedMode = PreviousStatus.ExtendedMode then
      begin
      FilteredStatus.ExtendedMode := CurrentStatus.ExtendedMode;
      end;

   if CurrentStatus.Band = PreviousStatus.Band then
      begin
      FilteredStatus.Band := CurrentStatus.Band;
      end;

   if CurrentStatus.Split = PreviousStatus.Split then
      begin
      FilteredStatus.Split := CurrentStatus.Split;
      end;

   if CurrentStatus.VFO[VFOA].Frequency = PreviousStatus.VFO[VFOA].Frequency then
      begin
      FilteredStatus.VFO[VFOA].Frequency := CurrentStatus.VFO[VFOA].Frequency;
      end;

   if CurrentStatus.VFO[VFOA].Band = PreviousStatus.VFO[VFOA].Band then
      begin
      FilteredStatus.VFO[VFOA].Band := CurrentStatus.VFO[VFOA].Band;
      end;

   if CurrentStatus.VFO[VFOA].Mode = PreviousStatus.VFO[VFOA].Mode then
      begin
      FilteredStatus.VFO[VFOA].Mode := CurrentStatus.VFO[VFOA].Mode;
      end;

   if CurrentStatus.VFO[VFOA].ExtendedMode = PreviousStatus.VFO[VFOA].ExtendedMode then
      begin
      FilteredStatus.VFO[VFOA].ExtendedMode := CurrentStatus.VFO[VFOA].ExtendedMode;
      end;

   //   if CurrentStatus.VFOA.TXRX = PreviousStatus.VFOA.TXRX then
   //      FilteredStatus.VFOA.TXRX := CurrentStatus.VFOA.TXRX;

   if CurrentStatus.VFO[VFOB].Frequency = PreviousStatus.VFO[VFOB].Frequency then
      begin
      FilteredStatus.VFO[VFOB].Frequency := CurrentStatus.VFO[VFOB].Frequency;
      end;

   if CurrentStatus.VFO[VFOB].Band = PreviousStatus.VFO[VFOB].Band then
      begin
      FilteredStatus.VFO[VFOB].Band := CurrentStatus.VFO[VFOB].Band;
      end;

   if CurrentStatus.VFO[VFOB].Mode = PreviousStatus.VFO[VFOB].Mode then
      begin
      FilteredStatus.VFO[VFOB].Mode := CurrentStatus.VFO[VFOB].Mode;
      end;

   if CurrentStatus.VFO[VFOB].ExtendedMode = PreviousStatus.VFO[VFOB].ExtendedMode then
      begin
      FilteredStatus.VFO[VFOB].ExtendedMode := CurrentStatus.VFO[VFOB].ExtendedMode;
      end;

   //   if CurrentStatus.VFOB.TXRX = PreviousStatus.VFOB.TXRX then
   //      FilteredStatus.VFOB.TXRX := CurrentStatus.VFOB.TXRX;

   if CurrentStatus.TXOn = PreviousStatus.TXOn then        // ny4i  // 4.44.5
      begin
      FilteredStatus.TXOn := CurrentStatus.TXOn;
      end;

   PreviousStatus := CurrentStatus;
end;

procedure RadioObject.OnCWByCATTimeEvent(Sender :TObject);
begin
   if Self.CWByCAT and (Self.RadioModel in RadioSupportsCWByCAT) then
      begin
      if Self.CWBYCAT_Sending then
         begin
         QuickDisplay('CW Timer fired');
         Self.tmrCWByCat.enabled := false;
         end;
      end;
end;

procedure RadioObject.EnableCWBYCATTimer(ms: integer);
begin
{ Updating the time in a timer does not work properly. Need to come up up with a better way for that. NY4I
   if Self.tmrCWBYCAT.enabled then
      begin
      // Add the time
      DebugMsg('Adding ' + IntToStr(ms) + ' mS to tmrCWByCAT timer - Interval now = to ' + IntToStr(Self.tmrCWByCAT.interval) + ' mS.');
      Self.tmrCWByCAT.interval := Self.tmrCWByCAT.interval + ms;
      end
   else }
      begin
      logger.trace('Setting tmrCWByCAT timer to %d ms',[ms]);
      Self.tmrCWByCAT.interval := ms;
      Self.tmrCWByCat.enabled := true;
      end;
end;
{-------------------------------------------------------------------------------}
procedure RadioObject.AddTimeToCWByCATTimer(ms: integer);    // ny4i Issue 159 - Added procedure
begin
   if Self.tmrCWBYCAT.enabled then
      begin
      Self.tmrCWByCAT.interval := Self.tmrCWByCAT.interval + ms;
      end
   else
      begin
      DebugMsg('[AddTimerToCWByCATTimer] Trying to add ' + IntToStr(ms) + ' ms but timer is disabled');
      end;
end;
{------------------------------------------------------------------------------}
procedure RadioObject.AddCommandToBuffer;
begin
   // TLogger.GetInstance.Debug('Entering AddCommandToBuffer');
   if not PollingEnable then
      begin
      WriteToCATPort(PChar(@CommandsTempBuffer[1])^, Ord(CommandsTempBuffer[0]) - 1);
      // TLogger.GetInstance.Debug('Entering sleep(250)');
      Sleep(250);
      // TLogger.GetInstance.Debug('Returning from sleep(250)');
      // TLogger.GetInstance.Debug('Leaving AddCommandToBuffer via Exit');
      Exit;
      end;

   if CommandsBufferPointer = 8 then
      begin
      CommandsBufferPointer := 0;
      end;
   DebugRadioTempBuffer('AddCommandToBuffer',CommandsTempBuffer); // ny4i Issue 145 - Decorator string, pointer, length
   Windows.CopyMemory(@CommandsBuffer[CommandsBufferPointer],
      @CommandsTempBuffer, Ord(CommandsTempBuffer[0]));
   Inc(CommandsBufferPointer);
   //TLogger.GetInstance.Debug('Leaving AddCommandToBuffer');
end;


//------------------------------------------------------------------------------
function RadioObject.DeleteLastCWCharacter: boolean;  // ny4i Procedure added Issue149
begin
   Result := false;
   if length(Self.CWByCATBuffer) > 1 then
      begin
      SetLength(Self.CWByCATBuffer,length(Self.CWByCATBuffer)-1); // Remove one byte from end of string
      Result := true;
      end
   else if length(Self.CWByCATBuffer) = 1 then
      begin
      if Copy(Self.CWByCATBuffer,1,1) <> CWByCATBufferTerminator then
         begin
         SetLength(Self.CWByCATBuffer,length(Self.CWByCATBuffer)-1); // Remove one byte from end of string
         Result := true;
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.FlushCWByCATBuffer;      // ny4i 4.44.5
begin
   SetLength(Self.CWByCATBuffer,0);    // ny4i Issue 149 Added (general cleanup)
end;
//------------------------------------------------------------------------------
procedure RadioObject.SendCW(Msg: Str160);
var
   localMsg: string;
   i: integer;
   msgLen: integer;
   len: integer;
   maxLen: integer;
   pad: boolean;
   tempLen: integer;
   sLen: integer;
   sMsg: string;
   sendNow : boolean;
   formatStr: string;
//   debugStr: string;
   charProcessed: boolean;
   elements: integer;
begin
   if not ( Self.CWByCAT and (Self.RadioModel in RadioSupportsCWByCAT) ) then
      begin
      exit;   // No need to be here if radio does not support CWBYCAT and not active
      end;
   // Delphi 7 does NOT initialize stack-allocated locals. Without these two
   // explicit defaults, `charProcessed` and `sendNow` carried whatever bytes
   // happened to be on the stack from prior calls. If `charProcessed`
   // was non-zero on entry, the `if not charProcessed` guard near the bottom
   // of the rtKenwood block would short-circuit and the letter would never
   // be appended to CWByCATBuffer -- so by the time the terminator arrived
   // the buffer was empty, the assembly path ran on a zero-length string,
   // and no KY command was emitted. Per-char debug output ("Adding (N)...")
   // appeared because that log happens BEFORE the buffer append.
   charProcessed := False;
   sendNow       := False;

   //scWK_Reset;    // n4af 4.46.3  // ny4i This would not be necessary as this code is in the radio object. It is ONLY used by CWByCAT.
   localMsg := Msg;

   (* Removed network code as AddToOutputBuffer will send to net radio // ny4i  This is a bad kludge. We should call a new procedure to handle CW for networked radios
   if Self.tNetObject <> nil then
      begin
      Self.tNetObject.SendCW(msg);
      Exit;
      end;
   *)
   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // This whould really be changed to a queue where we send the CW speed command, send the KY coommand and then send the KS command as consecutive commands for the Kenwood.
         // It also illustrates that we should have a branch in this case just for ELecraft and not lump it into Kenwood. The K3 and K4 handle this but now Kenwood.     NY4I 2026 June 1
         if Msg = ControlF then// increase speed
            begin
            CodeSpeed := CodeSpeed + Round(CodeSpeed * 0.06); // increase 6 %
            //SetRadioCWSpeed(CodeSpeed);
            sendNow := true;
            charProcessed := true;
            end
         else if Msg = ControlS then
            begin       // Speed down by 6 %
            CodeSpeed := CodeSpeed - Round(CodeSpeed * 0.06); // increase 6 %
            //SetRadioCWSpeed(CodeSpeed);
            sendNow := true;
            charProcessed := true;
            end
         else if Msg = '^' then
            begin // There is no half space in Kenwood/Elecraft CW strings
            Self.CWByCATBuffer := Self.CWByCATBuffer + ' '; // Use a whole space
            charProcessed := true;
            end
         else if Msg = '!' then   // SN
            begin
            if not (RadioModel in [K2, K3, K4]) then   // No SN on Elecraft
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '%';
               end;
            charProcessed := true;
            end
         {else if Msg = '&' then // AS      // & is really MYSTATE but documented as AS
            begin
            if RadioModel in [K2, K3, K4] then
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '%'; //Elecraft AS
               end
            else
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '<'; //Kenwood AS
               end;
            charProcessed := true;
            end}
         else if Msg = '+' then // AR
            begin
            if RadioModel in [K2, K3, K4] then
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '+'; //Elecraft AR
               end
            else
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '_'; //Kenwood AR
               end;
            charProcessed := true;
            end
         else if Msg = '<' then // SK
            begin
            if RadioModel in [K2, K3, K4] then
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '*'; //Elecraft SK
               end
            else
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '>'; //Kenwood SK
               end;
            charProcessed := true;
            end
         else if Msg = '=' then // BT
            begin
            if RadioModel in [K2, K3, K4] then
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '='; //Elecraft BT
               end
            else
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + '['; //Kenwood BT
               end;
            charProcessed := true;
            end;
         // Now process the string is not already processed   
         if (Msg = CWByCATBufferTerminator) or sendNow then // Do nothing
            begin
            DebugMsg('Assembling CW message to send');
            Msg := CWByCATBuffer;               // ny4i 4.44.5
//            msgLen := length(Msg);              //length(Msg);
            //len := Min(msgLen, 24);             // 24 max for Kenwood
            case RadioModel of
               TS890:
                  begin
                  // TS-890 accepts the space-prefixed KY form with a variable-length
                  // P2 (KY <space><text>;), so no 24-byte padding -- and never KY2
                  // (P1='2' would key the fill spaces as dead air). The other Kenwoods
                  // reject a short P2 under P1=space, so they keep the fixed-24 fill.
                  maxLen := 24;
                  pad := false;
                  end;
               TS480, TS570, TS590, TS950, TS990, TS2000:
                  begin
                  maxLen := 24;
                  pad := true;
                  end;
               FLEX:
                  begin
                  // cwx send has no length limit and no padding requirement.
                  // Flex serial (KY path) uses 24/pad like Kenwood — handled below.
                  maxLen := 24;
                  pad := (Self.tCATPortType <> Network);
                  end;
               K2:
                  begin
                  maxLen := 22; //28;
                  pad := false;
                  end;
               K3, KX3, K4:
                  begin
                  maxLen := 22; //28;
                  // A short KY fails on the K3/KX3/K4 ONLY when it follows the
                  // keyer-abort TR4W sends before every message ('KY <04>;RX;',
                  // from StopSendingCW): the abort/RX transition swallows a short
                  // following message, while >=8 chars survives it.  (tr4w.log
                  // 2026-06-18: 'KY AGN4567;' silent, 'KY AGN45678;' keys; a
                  // standalone 'KY ?;' from the K3 utility keys fine -- so this is
                  // the abort window, not a radio length floor.)  Padding to maxLen
                  // gives every message enough runway to survive the abort; under
                  // P1=space the radio trims the trailing fill instead of keying it.
                  pad := true;
                  end;
               end; // case
            Msg := CWByCATBuffer;
            tempLen := length(Msg);
            while tempLen > 0 do
               begin  // Loop around to to process the message in maxLen chunks;
               sLen := min(tempLen,maxLen);
               sMsg := Copy(msg,1,sLen); // Move sLen chars into sMsg;
               Delete(Msg,1,sLen); // Delete sLen characters from start of Msg
               // Count elements on the REAL text, BEFORE any padding is appended.
               // The trailing pad spaces are trimmed by the radio and never keyed,
               // so counting them inflates tmrCWByCAT (a 1-char '?' padded to 22
               // counted as 165 elements -> a bogus ~8 s CWByCAT_Sending window).
               elements := CalculateElements(sMsg);  // ny4i Issue 153
               if pad then
                  begin
                  while length(sMsg) < maxLen do
                     begin
                     sMsg := sMsg + ' ';
                     end;
                  end;
               if Self.active then
                  begin
                  DebugMsg('Sending on ACTIVE radio ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                  if InactiveRadioPtr.CWByCAT_Sending then
                     begin
                     DebugMsg('Stopping sending CW on INACTIVE ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                     InactiveRadioPtr.StopSendingCW;
                     sleep(500); // Give command chance to complete
                     end;
                  end
               else // Inactive
                  begin
                  DebugMsg('Sending on INACTIVE radio ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                  if ActiveRadioPtr.CWByCAT_Sending then
                     begin
                     DebugMsg('Stopping sending CW on ACTIVE ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                     ActiveRadioPtr.StopSendingCW;
                     end;
                  end;
               if sendNow then
                  begin
                  formatStr := 'KYW%s;'
                  end
               else
                  begin
                  formatStr := 'KY %s;';
                  end;
               logger.trace('Total CW Elements (unpadded) = %d',[elements]);
               Self.EnableCWBYCATTimer( Round(1200 / DisplayedCodeSpeed) * elements); //ny4i Issue153 When timer fires, reset CWBYCAT_Sending
               // Set CWByCAT_Sending BEFORE the KY command is written, so the poll
               // thread (pKenwood2) pauses before the command goes on the wire.  Set
               // after the write, a short message could be stepped on by an IF; poll
               // fired in the gap and never key.
               Self.CWByCAT_Sending := true;
               logger.trace('Self.CWByCAT_Sending set to TRUE - Elecraft/Kenwood/Flex');
               // Flex over TCP: delegate to the factory object's cwx API.
               // Flex over serial falls through to the legacy KY path below.
               if (RadioModel = FLEX) and (Self.tNetObject <> nil) and (Self.tCATPortType = Network) then
                  begin
                  Self.tNetObject.BufferCW(sMsg);
                  Self.tNetObject.SendCW;
                  end
               else
                  begin
                  localMsg := Format(formatStr, [sMsg]);
                  if Self.tNetObject <> nil then
                     Self.tNetObject.SendToRadio(localMsg)
                  else
                     AddToOutputBuffer(addr(localMsg[1]), length(localMsg));
                  end;
               logger.trace('Adding K/E/F radio CW string to buffer');
               tempLen := length(Msg);
               end;
            CWByCATBuffer := ''; // Clear the buffer
            if sendNow then
               begin
//               sendNow := false;
               SetRadioCWSpeed(CodeSpeed);
               end;
            end
         else
            begin
            if not charProcessed then    // ny4i Do not add if we handled this above
               begin
               Self.CWByCATBuffer := Self.CWByCATBuffer + Msg; // Just add Msg to the buffer - Issue 131 ny4i
               end;
            end;
         end; // case Kenwood...
      rtYaesu1:
         begin    // Yaesu does not support sending free-form text via CAT.
         ;     // You can send memories that are previously programmed though.
         end;     // This is not applicable to this program however.

      rtIcom:
         begin
         if RadioModel in RadioSupportsCWByCAT then
            begin
            if Msg[1] = CWByCATBufferTerminator then // Flush if Msg = CWByCATBufferTerminator
               begin
               Msg := CWByCATBuffer;               // ny4i 4.44.5
               msgLen := length(CWByCATBuffer);    //length(Msg);
               len := Min(msgLen, 28);
               // Max for Icom radio. TODO Optimally, this should be sent in multiple batches
               localMsg := Format('%s', [Msg]);

               // SO2R: stop the other radio's CW if it is sending
               if Self.active then
                  begin
                  if InactiveRadioPtr.CWByCAT_Sending then
                     begin
                     InactiveRadioPtr.StopSendingCW;
                     DEBUGMSG('Stopping Sending in SendCW - Inactive');
                     end;
                  end
               else // Inactive
                  begin
                  if ActiveRadioPtr.CWByCAT_Sending then
                     begin
                     ActiveRadioPtr.StopSendingCW;
                     DEBUGMSG('Stopping Sending in SendCW - ACTIVE');
                     end;
                  end;

               elements := CalculateElements(Msg);  // ny4i Issue 153
               DebugMsg('Total CW Elements for ' + Msg + ' = ' + IntToStr(elements));
               Self.EnableCWBYCATTimer(Round(( (1200 / DisplayedCodeSpeed) * elements) * 1.25)); //ny4i Issue153 When timer fires, reset CWBYCAT_Sending

               if Self.tNetObject <> nil then
                  begin
                  // Network path: route through TIcomRadio.BufferCW/SendCW
                  DebugMsg('SendCW for Icom network[' + IntToStr(len) + ' bytes]=' + localMsg);
                  Self.tNetObject.BufferCW(Copy(Msg, 1, len));
                  Self.tNetObject.SendCW;
                  end
               else
                  begin
                  // Legacy serial path: build raw CI-V frame
                  DebugMsg('Sending to Icom[' + IntToStr(len) + ' bytes]=' + localMsg);
                  CommandsTempBuffer[0] := Chr(7 + len);
                  CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[3] := CHR(ReceiverAddress);
                  CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
                  CommandsTempBuffer[5] := ICOM_SEND_CW;
                  for i := 1 to len do
                     begin
                     CommandsTempBuffer[5 + i] := Chr(Ord(Msg[i]));
                     end;
                  CommandsTempBuffer[6 + len] := ICOM_END_OF_MESSAGE_CODE;
                  AddCommandToBuffer;
                  end;

               Self.CWByCAT_Sending := true;
               logger.trace('Self.CWByCAT_Sending set to TRUE - Icom');
               CWByCATBuffer := '';
               end
            else
               begin // Add to CWBYCATBuffer
               if Msg = ControlF then// increase speed
                  begin
                  //CodeSpeed := CodeSpeed + Round(CodeSpeed * 0.06); // increase 6 %
                  //SetRadioCWSpeed(CodeSpeed);
                  //sendNow := true;
//                  charProcessed := true;
                  end
               else if Msg = ControlS then
                  begin       // Speed down by 6 %
                  //CodeSpeed := CodeSpeed - Round(CodeSpeed * 0.06); // increase 6 %
                  //SetRadioCWSpeed(CodeSpeed);
                  //sendNow := true;
//                  charProcessed := true;
                  end
               else if Msg = '^' then           // ny4i Issue131 Added Special CW Characters
                  begin // There is no half space in Icom CW strings
                  Self.CWByCATBuffer := Self.CWByCATBuffer + ' '; // Use a whole space
//                  charProcessed := true;
                  end
               else if Msg = '!' then   // SN
                  begin
                  Self.CWByCATBuffer := Self.CWByCATBuffer + '^SN';
//                  charProcessed := true;
                  end
               {else if Msg = '&' then // AS      // & is really MYSTATE but documented as AS
                  begin
                  Self.CWByCATBuffer := Self.CWByCATBuffer + '^AS';
                  charProcessed := true;
                  end}
               else if Msg = '+' then // AR
                  begin
                  Self.CWByCATBuffer := Self.CWByCATBuffer + '^AR';
//                  charProcessed := true;
                  end
               else if Msg = '<' then // SK
                  begin
                  Self.CWByCATBuffer := Self.CWByCATBuffer + '^SK';
//                  charProcessed := true;
                  end
               else if Msg = '=' then // BT
                  begin
                  Self.CWByCATBuffer := Self.CWByCATBuffer + '^BT';
//                  charProcessed := true;
                  end
               else
                  begin
                  CWByCATBuffer := CWByCATBuffer + Msg;    // ny4i 4.44.5
                  end;
               end;
            end;
         end;
      rtOrion:     // Add special character processing to Orion routines.
         begin
         localMsg := Format('/%s#13', [Msg]);   // ny4i Issue 112
         WriteToCATPort(localMsg[1], length(localMsg));
         Self.CWByCAT_Sending := true;
         logger.trace('Self.CWByCAT_Sending set to TRUE - Orion');
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.StopSendingCW;

//   localMsg: string;
begin
   if Self.tNetObject <> nil then
      begin
      Self.tNetObject.StopCW;
      Exit;
      end;
   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // localMsg := Format('KY %s;', [Msg]);
         case RadioModel of
            K2:
               begin
               AddToOutputBuffer('KY @;RX;', 8);   // Stops the K2 // ny4i Issue 157
               end;
            K3, KX3, K4:
               begin
              AddToOutputBuffer('KY ' + Chr(4) + ';RX;', 8); // Chr(4) stops the K3 // ny4i Issue 157
               end;
            TS480, TS570, TS590, TS890, TS950, TS990, TS2000, TS850:
               begin
               AddToOutputBuffer('KY0;', 4);
               AddToOutputBuffer('RX;', 3);
               end;
            FLEX:
               begin
               AddToOutputBuffer('ZZSS;', 5);
               end; // PowerSDR command-no Kenwood equivilent
            end; // case RadioModel
         end;
      rtYaesu1:
         begin
         if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
            begin
            ;
            end;
         end;

      rtIcom:
         begin   // This was missing for Icom ny4i Issue 100 4.45.4
         if RadioModel in RadioSupportsCWByCAT then     // ny4i
            begin
            CommandsTempBuffer[0] := CHR(8);
            // Number of items used in this array for command ny4i Issue 100 4.45.4
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SEND_CW;
            CommandsTempBuffer[6] := CHR(255);
            // Documented in Icom manuals. FF in the subcode terminates CW  ny4i
            CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
            AddCommandToBuffer;
            end;
         end;
      rtOrion:
         begin
         //i := Format(tOrionFreq, '*CS%02u'#13, speed);
         //WriteToCATPort(tOrionFreq, i);
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
function RadioObject.DetermineNetworkRadioModel: TRadioModel;
begin
   // This is only called for network radios (tCATPortType = Network)
   Result := rmNone;

   logger.Info('[%s.DetermineNetworkRadioModel] RadioModel=%d, UseHamLib=%s',
               [Self.RadioName, Ord(Self.RadioModel), BoolToStr(Self.UseHamLib, True)]);

   // Check if this radio should use HamLib Direct DLL
   if Self.UseHamLib then
   begin
      Result := rmHamLibDirect;
      logger.Info('[%s] Using HamLib Direct (DLL mode)', [Self.RadioName]);
      Exit;
   end;

   // Otherwise, determine specific network radio model
   Result := Self.MapRadioModelToFactory;
   if Result <> rmNone then
      logger.Info('[%s] Using factory model: %s', [Self.RadioName, TRadioFactory.ModelToString(Result)])
   else
      begin
      logger.warn('[%s] Unknown network radio model %d, no factory mapping', [Self.RadioName, Ord(Self.RadioModel)]);
      end;
end;
//------------------------------------------------------------------------------
function RadioObject.MapRadioModelToFactory: TRadioModel;
begin
   // Issue #1028 -- the InterfacedRadioType -> TRadioModel mapping now lives on
   // the radio factory (single source of truth, alongside the per-model network
   // metadata).  Delegate to it.
   Result := TRadioFactory.ModelForInterfacedType(Self.RadioModel);
end;
//------------------------------------------------------------------------------
procedure RadioObject.SetUpRadioInterface;
var
   hand: HWND;
//   TempCardinal: cardinal;
   dwFlagsAndAttributes: DWORD;
   EvtChar: char;
   networkRadioModel: TRadioModel;
   factoryModel: TRadioModel;
begin
   // If a radio object already exists, stop the polling thread and free it before creating a new one.
   // This prevents the old thread from accessing freed memory (dangling pointer AV).
   if Self.tNetObject <> nil then
      begin
      logger.Info('[%s.SetUpRadioInterface] Stopping polling thread before reinit', [Self.RadioName]);
      Self.PollingStopRequested := True;
      if Self.tRadioInterfaceThreadHandle <> 0 then
         begin
         WaitForSingleObject(Self.tRadioInterfaceThreadHandle, 3000);
         CloseHandle(Self.tRadioInterfaceThreadHandle);
         Self.tRadioInterfaceThreadHandle := 0;
         Self.tRadioInterfaceThreadID := 0;
         end;
      Self.PollingStopRequested := False;
      logger.Info('[%s.SetUpRadioInterface] Freeing existing radio object before reinit', [Self.RadioName]);
      Self.tNetObject.Disconnect;
      Self.tNetObject.Free;
      Self.tNetObject := nil;
      end;

   // Check if we should use HamLib Direct (works with both serial and network)
   if Self.UseHamLib then
   begin
      logger.Info('[%s.SetUpRadioInterface] Using HamLib Direct', [Self.RadioName]);

      // Create HamLib Direct radio via factory
      Self.tNetObject := TRadioFactory.CreateRadioNetwork(
         rmHamLibDirect,
         '',  // Address will be set below based on port type
         0,   // Port will be set below based on port type
         nil  // msgCallback
      );

      if Self.tNetObject <> nil then
      begin
         if Self.tNetObject is THamLibDirect then
         begin
            with THamLibDirect(Self.tNetObject) do
            begin
               HamLibModelID := RadioParametersArray[Self.RadioModel].hamlibID;

               // Check if using network or serial connection
               if tCATPortType = Network then
               begin
                  // Network connection
                  logger.Info('[%s] HamLib via network: %s:%d',
                              [Self.RadioName, Self.IPAddress, Self.RadioTCPPort]);
                  UseIPAddress := True;
                  IPAddress := Self.IPAddress;
                  IPPort := Self.RadioTCPPort;
               end
               else if tCATPortType in [Serial1..Serial20] then
               begin
                  // Serial connection
                  COMPortName := ConvertPortTypeToCOMString(Self.tCATPortType);
                  BaudRate := Self.RadioBaudRate;
                  logger.Info('[%s] HamLib via serial: %s at %d baud',
                              [Self.RadioName, COMPortName, BaudRate]);
                  UseIPAddress := False;
               end;

               if Self.ReceiverAddress > 0 then
                  CIVAddress := IntToStr(Self.ReceiverAddress);
            end;
         end;

         // Connect the radio
         Self.tNetObject.Connect;
         logger.Info('[%s.SetUpRadioInterface] HamLib Direct connected', [Self.RadioName]);
      end
      else
         logger.error('[%s.SetUpRadioInterface] Failed to create HamLib Direct radio', [Self.RadioName]);
   end
   else if tCATPortType in [Serial1..Serial20] then
      begin
      // Check if we should use modern radio class (e.g., K4, Icom) or legacy serial code
      if (Self.RadioModel in [K4, IC7610, IC7300, IC9700, IC705, IC7300MK2, IC7600, IC7760, IC7850, IC7851, IC905, IC7100]) then
         begin
         factoryModel := Self.MapRadioModelToFactory;

         if factoryModel <> rmNone then
            begin
            // Use factory for modern radios (K4, Icom, etc.)
            logger.Info('[%s.SetUpRadioInterface] Setting up %s serial via factory: Port=%d, Baud=%d, DataBits=%d, Parity=%d, StopBits=%d',
                        [Self.RadioName, TRadioFactory.ModelToString(factoryModel), Ord(tCATPortType),
                         RadioBaudRate, RadioNumberBits, Ord(RadioParity), RadioStopBits]);
            Self.tNetObject := TRadioFactory.CreateRadioSerial(
               factoryModel,
               tCATPortType,
               RadioBaudRate,
               RadioNumberBits,
               RadioStopBits,
               Ord(RadioParity),
               nil,
               tr4w_cat_rts_state = RtsDtr_ON,
               tr4w_cat_dtr_state = RtsDtr_ON
            );
            if Self.tNetObject <> nil then
               begin
               Self.tNetObject.Connect;
               logger.Info('[%s.SetUpRadioInterface] %s serial radio connected via factory',
                          [Self.RadioName, TRadioFactory.ModelToString(factoryModel)]);
               end
            else
               logger.Error('[%s.SetUpRadioInterface] Failed to create %s serial radio',
                           [Self.RadioName, TRadioFactory.ModelToString(factoryModel)]);

            // Initialize timer and event handlers — must happen for all radio paths
            Self.EventHandlers := EventHandlers;
            Self.tmrCWByCAT := TTimer.Create(nil);
            Self.tmrCWByCAT.Enabled := false;
            Self.tmrCWByCAT.OnTimer := Self.EventHandlers.OnTimerTick;
            // Reset filtered status
            with FilteredStatus do
               begin
               Band := NoBand;
               Mode := NoMode;
               Freq := 0;
               end;
            // Send startup command if configured
            if length(Self.StartupCommand) > 0 then
               begin
               if Self.tNetObject <> nil then
                  begin
                  Self.tNetObject.SendToRadio(Self.StartupCommand);
                  end;
               end;
            // Exit to prevent any legacy serial code from executing
            Exit;
            end;
         end
      else
         begin
         // Legacy serial port code (non-HamLib, non-K4)
         logger.Info('[%s.SetUpRadioInterface] Using legacy serial port code: Port=%d, Baud=%d, DataBits=%d, Parity=%d, StopBits=%d',
                     [Self.RadioName, Ord(tCATPortType), RadioBaudRate, RadioNumberBits, Ord(RadioParity), RadioStopBits]);

      dwFlagsAndAttributes := FILE_ATTRIBUTE_NORMAL;
      EvtChar := #0;
{$IF MASKEVENT}

      if RadioModel in [Orion] then
         begin
         dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED;
         EvtChar := #13;
         end;
      if RadioModel in [KenwoodRadios, K2, K3, KX3, K4] then
         begin
         dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED;
         EvtChar := ';';
         end;
{$IFEND}

      hand := CPUKeyer.SerialPortConfigured_Handle[tCATPortType];
      if hand = INVALID_HANDLE_VALUE then
         begin
         hand := InitializeSerialPort(tCATPortType, RadioBaudRate, RadioNumberBits,
            RadioParity, RadioStopBits, dwFlagsAndAttributes, EvtChar);
         end;
      GetMem(TimeoutBuffer, sizeof(COMMTIMEOUTS));

      GetCommTimeouts(hand, TimeoutBuffer^);
      TimeoutBuffer.ReadIntervalTimeout := 3;
      TimeoutBuffer.ReadTotalTimeoutMultiplier := 3;
      TimeoutBuffer.ReadTotalTimeoutConstant := 2;
      TimeoutBuffer.WriteTotalTimeoutMultiplier := 3;
      TimeoutBuffer.WriteTotalTimeoutConstant := 2;
      SetCommTimeouts(hand, TimeoutBuffer^);

      FreeMem(TimeoutBuffer, sizeof(COMMTIMEOUTS));
{$IF MASKEVENT}

      if RadioModel in [KenwoodRadios, K2, K3, KX3, K4, Orion] then
         begin
         if SetCommMask(hand, EV_RXFLAG) then
            begin
            lpOverlapped.hEvent := CreateEvent(nil, False, False, nil);
            pOver := @lpOverlapped;
            end;
         end;
{$IFEND}

      if hand <> INVALID_HANDLE_VALUE then
         begin
         CPUKeyer.SerialPortConfigured_Handle[tCATPortType] := hand;
         tCATPortHandle := hand;

         if tr4w_cat_dtr_state = RtsDtr_ON then
            begin
            TREscapeCommFunction(hand, SETDTR);
            end;
         if tr4w_cat_dtr_state = RtsDtr_OFF then
            begin
            TREscapeCommFunction(hand, CLRDTR);
            end;
         if tr4w_cat_rts_state = RtsDtr_ON then
            begin
            TREscapeCommFunction(hand, SETRTS);
            end;
         if tr4w_cat_rts_state = RtsDtr_OFF then
            begin
            TREscapeCommFunction(hand, CLRRTS);
            end;

         //      OpenCATDebugFile(tCATPortType);
         end;

         end; // end legacy serial port code else block
      end
   else if tCATPortType = Network then
      begin
      // Non-HamLib network radio (e.g., K4, Icom with native network protocol)
      logger.Info('[%s.SetUpRadioInterface] Setting up non-HamLib network radio: IP=%s, Port=%d',
                  [Self.RadioName, Self.IPAddress, Self.RadioTCPPort]);

      // Determine which network radio model to use
      factoryModel := Self.MapRadioModelToFactory;
      if factoryModel <> rmNone then
         begin
         Self.tNetObject := TRadioFactory.CreateRadioNetwork(
            factoryModel,
            Self.IPAddress,
            Self.RadioTCPPort,
            nil
         );
         logger.Info('[%s] Using %s network protocol', [Self.RadioName, TRadioFactory.ModelToString(factoryModel)]);
         end
      else
         begin
         logger.warn('[%s] Unknown network radio model (RadioModel=%d), cannot create factory instance',
                    [Self.RadioName, Ord(Self.RadioModel)]);
         end;

      if Self.tNetObject <> nil then
      begin
         Self.tNetObject.rigLabel := Self.RadioName;  // "Rig 1" / "Rig 2"

         // If this is an Icom radio, set network credentials before connecting
         if Self.tNetObject is TIcomRadio then
         begin
            TIcomRadio(Self.tNetObject).NetworkUsername := Self.NetworkUsername;
            TIcomRadio(Self.tNetObject).NetworkPassword := Self.NetworkPassword;
            logger.Info('[%s.SetUpRadioInterface] Set Icom network credentials (user=%s, pass=*******)',
                        [Self.RadioName, Self.NetworkUsername]);
            if Self.IcomDataModeID in [1..3] then
               begin
               TIcomRadio(Self.tNetObject).DataModeID := Self.IcomDataModeID;
               logger.Info('[%s.SetUpRadioInterface] Icom data mode ID set to D%d',
                           [Self.RadioName, Self.IcomDataModeID]);
               end;
         end;

         // Kenwood TS-890 also requires LAN credentials (Issue #436).
         if Self.tNetObject is TKenwoodTS890Radio then
         begin
            TKenwoodTS890Radio(Self.tNetObject).NetworkUsername := Self.NetworkUsername;
            TKenwoodTS890Radio(Self.tNetObject).NetworkPassword := Self.NetworkPassword;
            logger.Info('[%s.SetUpRadioInterface] Set Kenwood TS-890 LAN credentials (user=%s, pass=*******)',
                        [Self.RadioName, Self.NetworkUsername]);
         end;

         // Connect is deferred to the polling thread (pNetworkRadio).  Running
         // it synchronously here blocked the main thread for up to 10 s
         // (Indy ConnectTimeout) whenever the radio was off or unreachable.
         // The polling thread's existing reconnect-with-backoff path now
         // handles the very first connect as well.  Issue #436.
         Self.StartupCommandSent := False;  // pNetworkRadio sends StartupCommand once after first connect
         logger.Info('[%s.SetUpRadioInterface] Network radio %s:%d configured; Connect deferred to polling thread (main thread not blocked)',
                     [Self.RadioName, Self.IPAddress, Self.RadioTCPPort]);
      end
      else
         logger.error('[%s.SetUpRadioInterface] Failed to create network radio', [Self.RadioName]);
      end;

   { Initialize the radio variables }

   Self.tmrCWByCAT := TTimer.Create(nil);
   Self.tmrCWByCAT.Enabled := false;
   Self.EventHandlers := EventHandlers;
   Self.tmrCWByCAT.OnTimer := Self.EventHandlers.OnTimerTick;

   PollStatus := NoPollStatus;

   with CurrentStatus do
      begin
      Band := NoBand;
      Mode := NoMode;
      Freq := 0;
      VFO[VFOA].Frequency := 0;
      VFO[VFOB].Frequency := 0;
      end;

   with PreviousStatus do
      begin
      Band := NoBand;
      Mode := NoMode;
      Freq := 0;
      end;

   with FilteredStatus do
      begin
      Band := NoBand;
      Mode := NoMode;
      Freq := 0;
      end;
   logger.debug('[RadioObject.SetUpRadioInterface] Startup command length = %d, startup command = %s',[length(Self.StartupCommand),Self.StartupCommand]);
   if length(Self.StartupCommand) > 0 then
      begin
      if Self.tNetObject <> nil then
         begin
         // Network radios: pNetworkRadio sends StartupCommand on first
         // successful connect.  Sending here would race the deferred
         // Connect (Issue #436).
         end
      else
         begin
         case RadioParametersArray[RadioModel].rt of
         rtKenwood: AddToOutputBuffer (addr(Self.StartupCommand[1]), length(Self.StartupCommand));
         rtYaesu2,
         rtYaesu3,
         rtYaesu4:  AddToOutputBuffer (addr(Self.StartupCommand[1]), length(Self.StartupCommand));
         rtIcom: logger.Warn('Startup command not yet implemented for Icom');
         //rtOrion: WriteToCATPort(addr(Self.StartupCommand[1]), length(Self.StartupCommand));
         else
            begin
            end;
         end;
      end;
      end;
   { Enable polling }

   //  PollingEnable := True;
end;

//------------------------------------------------------------------------------
procedure RadioObject.SetRadioCWSpeed(speed: longint);
var
   i: integer;
begin
   if not (RadioModel in RadioSupportsCWSpeedSync) then
      begin
      DebugMsg('Current radio model does not support CWSpeedSync');
      exit;
      end;

   if Self.tNetObject <> nil then
      begin
      Self.tNetObject.SetCWSpeed(speed);
      Exit;
      end;

   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // Format(@tKenwood14Bytes, 'KS%003u;', speed);
         // AddToOutputBuffer (tKenwood14Bytes, 6);
         Format(@tKenwood14Bytes, 'KS%003u;', speed);
         AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 6);
         end;
      rtYaesu2,
      rtYaesu3,
      rtYaesu4:  // Yaesu1 does not support this command
         begin
         Format(@tKenwood14Bytes, 'KS%003u;', speed);
         AddToOutputBuffer(tKenwood14Bytes, 6);
         end;
      rtIcom:
         begin
         if (True) or (RadioModel in [IC7800, IC7850, IC7851]) then
            // ny4i 4.45.2. This looks odd because the 7800..7851 calculate speed differently but I have not added this yet. When added, just remove this if so we try this for all Icom radios.
            begin
            // Calculate Icom speed of WPM to 000-255.
            //001 = 6wpm, 254 = 48 wpm. Each extra wpm is 6 decimal higher
            //Speed (in icom decimal) = ((speed(wpm) * (42/255)) + 6)

            //speed := ((icom_dec_value * (42/255) + 6)
            // icom_dec_value = (speed - 6) * 255/42);

            CommandsTempBuffer[0] := CHR(10);
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SET_SLIDERS;
            CommandsTempBuffer[6] := ICOM_SET_CW_SPEED;
            i := Round((speed - 6) * (255 / 42));
            CommandsTempBuffer[7] := Chr(i div 100);  // Puts 00,01 or 02 into first byte
            i := i mod 100; // remove the hundreds part and BCD the remainder
            //AddStringToTelnetConsole(PChar('dec='+IntToStr(i) + ', bcd = ' + IntToStr(IntegerToBCD(i))),tstAlert);
            //AddStringToTelnetConsole(PChar('bcd='+IntToStr(n)),tstAlert);
            CommandsTempBuffer[8] := CHR(IntegerToBCD(i));
            // 20 wpm returns 85 which in BCD makes 131 which makes hex 85 when used with Chr()
            CommandsTempBuffer[9] := ICOM_END_OF_MESSAGE_CODE;

            AddCommandToBuffer;
            end;
         end;
      rtOrion:
         begin
         i := Format(tOrionFreq, '*CS%02u'#13, speed);
         WriteToCATPort(tOrionFreq, i);
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char; extendedMode: ExtendedModeType);
begin
   Self.nextExtendedMode := extendedMode;
   Self.SetRadioFreq(Freq, Mode, VFO);
end;

// Returns mode adjusted for frequency: if mode is SSB, selects LSB below 8 MHz
// and USB at or above 8 MHz (standard ham radio sideband convention).
// Non-SSB modes are returned unchanged.
function AdjustSSBModeForFreq(mode: TRadioMode; freq: longint): TRadioMode;
begin
   if mode in [rmLSB, rmUSB] then
      begin
      if freq < 8000000 then
         begin
         Result := rmLSB;
         end
      else
         begin
         Result := rmUSB;
         end;
      end
   else
      begin
      Result := mode;
      end;
end;

procedure RadioObject.SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char);

var
//   FreqStr: Str20;
   CharPointer: integer;
   nBytesToWrite: integer;
   i: integer;
   SendByte, TempByte: byte;
   TempChar: char;
//   lpNumberOfBytesWritten: cardinal;
//   VFOByte: byte;
//   p: PChar;
   tempFilterWidth: integer;
   skipMode : boolean;
   bStateDataModeRequired : boolean;
   tNetMode: TRadioMode;
const
   FT847ModeString = CHR(0) + CHR(0) + CHR(0) + CHR(7);

begin
   logger.debug('[SetRadioFreq] set frequency to %u',[freq]);

   if Freq <= 0 then
      begin
      logger.debug('[SetRadioFreq] freq <= 0 (no band memory or default for this band/mode) -- skipping tune');
      Exit;
      end;

   // Issue #795 vs bandmap double-click: record the app-commanded VFO-A
   // frequency so the auto-S&P "QSY clears the entry" logic (uRadioPolling) can
   // tell a COMMANDED QSY (bandmap/spot/typed freq -- a call may have been
   // placed deliberately) from a MANUAL dial QSY (which #795 wants to clear).
   if VFO = 'A' then
      Self.tCommandedQSYFreq := Freq;

   if Self.tNetObject <> nil then
      begin
      if VFO = 'B' then
         begin
         tNetMode := AdjustSSBModeForFreq(ModeTypeToNetMode(mode), freq);
         Self.tNetObject.SetFrequency(freq,nrVFOB,tNetMode);
         end
      else
         begin
         tNetMode := AdjustSSBModeForFreq(ModeTypeToNetMode(mode), freq);
         Self.tNetObject.SetFrequency(freq,nrVFOA,tNetMode);
         end;
      Exit;
      end;

   skipMode := false;
      try
      case RadioParametersArray[RadioModel].rt of
         rtYaesu1:
            begin

            { Select VFO B on the radio }
            if RadioModel in [FT890, FT990] then
               begin
               if VFO = 'B' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[3] := $01;
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
               end;

            {SplitOff}
            if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
               begin
               ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
               tYaesuMode5Bytes[4] := $01;
               WriteToCATPort(tYaesuMode5Bytes, 5);
               end;

            {Set Mode}
            ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
            tYaesuMode5Bytes[4] := RadioParametersArray[RadioModel].SMOC;

            if Freq < 10000000 then
               begin
               if Mode = Phone then
                  begin
                  TempByte := RadioParametersArray[RadioModel].LSB;
                  end;
               if Mode = Digital then
                  begin
                  TempByte := RadioParametersArray[RadioModel].DIGL;
                  end;
               end
            else
               begin
               if Mode = Phone then
                  begin
                  TempByte := RadioParametersArray[RadioModel].USB;
                  end;
               if Mode = Digital then
                  begin
                  TempByte := RadioParametersArray[RadioModel].DIGU;
                  end;
               end;

            if Mode = CW then
               begin
               TempByte := RadioParametersArray[RadioModel].CW;

               if RadioModel in [FT100, FT817, FT818, FT847, FT857, FT897, FT920, FT1000MP] then
                  begin
                  if FT1000MPCWReverse then
                     begin
                     TempByte := $03;
                     end else
                     begin
                     TempByte := $02;
                     end;
                  end;

               if RadioModel in [FT747GX, FT840, FT890, FT900, FT990, FT1000] then
                  begin
                  if WideCWFilter then
                     begin
                     TempByte := $02;
                     end else
                     begin
                     TempByte := $03;
                     end;
                  end;
               end;

            if VFO = 'B' then
               begin
               if RadioModel in [FT1000, FT1000MP, FT920] then
                  begin
                  Inc(TempByte, $80);
                  end;
               end;

            tYaesuMode5Bytes[RadioParametersArray[RadioModel].mb] := TempByte;
            if RadioModel in [FT857, FT897] then
               begin
               tYaesuSendMode := True;
               end else
               begin
               WriteToCATPort(tYaesuMode5Bytes, 5);
               end;

            Sleep(100);

            {Set Freq}
            FreqToBCD(Freq, boolean(RadioParametersArray[RadioModel].SW),
               RadioParametersArray[RadioModel].SFOC);

            if VFO = 'B' then
               begin
               if RadioModel in [FT1000, FT1000MP, FT920] then
                  begin
                  Inc(tYaesuFreq5Bytes[4], $80);
                  end;
               end;

            if RadioModel in [FT857, FT897] then
               begin
               tYaesuSendFreq := True;
               end else
               begin
               WriteToCATPort(tYaesuFreq5Bytes, 5);
               end;

            {set VFOA}
            if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
               begin
               if VFO = 'A' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
               end;

            { Put radio back on VFO A }
            if RadioModel in [FT890, FT990] then
               begin
               if VFO = 'B' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
               end;

            end;

         rtYaesu2,
         rtYaesu3,
         rtYaesu4:
            begin
            if RadioParametersArray[RadioModel].rt in [rtYaesu3, rtYaesu4] then  //ny4i Issue 218 - Only change to this command if the freq is 9 bytes long.
               begin
               if VFO = 'B' then
                  begin
                  Format(@tKenwood14Bytes, 'FB%09u;', Freq);    // Kenwood14Bytes is a terribly specific name for a shared buffer.
                  end
               else
                  begin
                  Format(@tKenwood14Bytes, 'FA%09u;', Freq);
                  end;
               nBytesToWrite := 12;
               end
            else
               begin
               Format(@tKenwood14Bytes, 'FA%08u;', Freq);
               nBytesToWrite := 11;
               end;
            tKenwood14Bytes[1] := VFO;
            WriteToCATPort(tKenwood14Bytes, nBytesToWrite);

            if Freq < 10000000 then
               begin
               if Mode = Phone then
                  begin
                  TempChar := '1';
                  end; { LSB }
               if Mode = Digital then
                  begin
                  TempChar := '6';
                  end; { RTTY-LSB }
               if Mode = CW then
                  begin
                  TempChar := '3';
                  end {'7'};
               end
            else
               begin
               if Mode = Phone then
                  begin
                  TempChar := '2';
                  end; { USB }
               if Mode = Digital then
                  begin
                  TempChar := '9';
                  end; { RTTY-USB }
               if Mode = CW then
                  begin
                  TempChar := '3';
                  end;
               if Mode = FM then
                  begin
                  TempChar := '4';
                  end;
               end;
            if (Mode = Digital) and (ActiveRadioPtr.CurrentStatus.Mode = Digital) then  // Issue 681 ny4i Used code from Kenwood branch below.
               begin
               logger.debug('Skipping Yaesu mode change because MODE was already DIGITAL');
               end
            else
               begin
               tKenwood14Bytes[0] := 'M';
               tKenwood14Bytes[1] := 'D';
               tKenwood14Bytes[2] := '0'; //Ord(VFO) - 17;
               tKenwood14Bytes[3] := TempChar;
               tKenwood14Bytes[4] := ';';
               WriteToCATPort(tKenwood14Bytes, 5);
               end;
            end;

         rtKenwood:
            begin
            logger.trace ('In SetRadioFreq, rtKenwood branch');
            Format(@tKenwood14Bytes, 'FA%011u;', Freq);
            tKenwood14Bytes[1] := VFO;
            AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 14);

            //if VFO = 'B' then
            //   begin
            //   AddToOutputBuffer {WriteToCATPort}('FR1;FT1;', 8);
            //   end; //temporary active vfo is vfo b for set mode

            case Mode of
               CW:
                  begin
                  TempByte := Ord('3');
                  end;
               Digital:
                  begin
                  TempByte := Ord('6');
                  end;
               FM:
                  begin
                  TempByte := Ord('4');
                  end;

               else { SSB }
                  begin
                  if Freq < 10000000 then
                     begin
                     TempByte := Ord('1');
                     end { LSB }
                  else
                     begin
                     TempByte := Ord('2');
                     end;
                  end; { USB }
               end;
            if (Mode = Digital) and (ActiveRadioPtr.CurrentStatus.Mode = Digital) then  // 4.97.11
               begin
               logger.debug('Skipping Kenwood mode change because MODE was already DIGITAL');
               end
            else
               begin
               tKenwood14Bytes[0] := 'M';
               tKenwood14Bytes[1] := 'D';
               tKenwood14Bytes[2] := CHR(TempByte);
               tKenwood14Bytes[3] := ';';
               AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 4);
               end

            //if (VFO = 'B') then
            //   begin
            //   AddToOutputBuffer {WriteToCATPort}('FR0;FT0;', 8);
            //   end; //back to vfo a
            // TLogger.GetInstance.Debug('Leaving Kenwood code');
            end;
         end;
      (*************************************************************************
           I C O M        I C O M       I C O M      I C O M     I C O M
       ************************************************************************)
      case RadioModel of
      (* Older Icom radios could not directly change VFO B. The code had to make VFO B active and then change things.
         This is now different for radios that support VFOB. IcomRadiosThatSupportVFOB is a radio group that supports this command.
         So, if the radioModel is in IcomRadiosThatSupportVFOB, then just directly address VFOB and do nto do the switch-a-roo.
       *)

        IC78..IC9700, OMNI6: {KK1L: 6.73 Added OMNI6}
            begin
            // TLogger.GetInstance.Debug('In Icom radio code');
            if VFO = 'B' then
               begin
               if not (RadioModel in IcomRadiosThatSupportVFOB) then   // For old radios, swap the VFOs  ny4i
                  begin
                  CommandsTempBuffer[0] := CHR(8);
                  CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[3] := CHR(ReceiverAddress);
                  CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
                  CommandsTempBuffer[5] := ICOM_SET_VFO_COMMAND;
                  CommandsTempBuffer[6] := ICOM_SET_VFO_B_COMMAND;
                  CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
                  AddCommandToBuffer;
                  end;
               end;



            { Send the mode information }
            // TLogger.GetInstance.Debug('Sending Icom mode information');
            // If the mode is digital, only send a fresh one of it changed.
            if Mode = Digital then
               begin
               if ActiveRadioPtr.CurrentStatus.Mode = Digital then
                  begin
                  skipMode := true;
                  end;
               end;

            if Mode = FM then
               begin
               TempChar := #5;
               end
            else if Mode = CW then
               begin
               TempChar := #3;
               end
            else if Mode = Digital then
               begin
               if nextExtendedMode <> eNoMode then
                  begin
                  if nextExtendedMode = eRTTY then
                     begin
                     TempChar := #4;
                     end
                  else if RadioModel in IcomRadiosThatSupportPSKMode then
                     begin
                     TempChar := #12; // PSK
                     end
                  else // all others
                     begin
                     TempChar := #1; // USB for Icom
                     bStateDataModeRequired := true;
                     end;
                  end;
               end
            else
               begin      //must be phone
               if Freq < 10000000 then
                  begin
                  TempChar := #0;
                  end
               else
                  begin
                  TempChar := #1;
                  end;
               end;
            // TLogger.GetInstance.Debug(Format('Sending Icom mode information - %u',[Ord(Mode)]));
            if RadioModel in IcomRadiosThatSupportVFOB then
               begin
               if not skipMode then
                  begin   // Build VFO and frequency into Command $25, mode and filter byte into command $26
                  // Mode - Command $26
                  CommandsTempBuffer[0] := CHR(11);
                  CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[3] := CHR(ReceiverAddress);
                  CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
                  CommandsTempBuffer[5] := ICOM_GET_EXTENDEDMODE;  // Sets too...
                  if VFO = 'A' then
                     begin
                     CommandsTempBuffer[6] := Chr(0);
                     end
                  else
                     begin
                     CommandsTempBuffer[6] := Chr(1);
                     end;
                  if Mode = FM then
                     begin
                     CommandsTempBuffer[7] := Chr(5); //TempChar := #5;
                     end
                  else if Mode = CW then
                     begin
                     CommandsTempBuffer[7] := Chr(3); //TempChar := #3;
                     end
                  else if Mode = Digital then
                     begin
                     CommandsTempBuffer[7] := Chr(1); //TempChar := #4;  // Icom uses mode USB with Digital flag enabled.
                     end
                  else
                     begin      //must be phone
                     if Freq < 10000000 then
                        begin
                        CommandsTempBuffer[7] := Chr(0); //TempChar := #0;
                        end
                     else
                        begin
                        CommandsTempBuffer[7] := Chr(1); //TempChar := #1;
                        end;
                     end;

                 // CommandsTempBuffer[7] := Chr(TempByte);

                  if mode = Digital then                  // Sets Data mode setting field
                     begin
                     CommandsTempBuffer[8] := Chr(1);
                     end
                  else
                     begin
                     CommandsTempBuffer[8] := Chr(0);
                     end;

                  CommandsTempBuffer[9] := CHR(CalculateIcomFilterWidth);
                  CommandsTempBuffer[10] := ICOM_END_OF_MESSAGE_CODE;
                  AddCommandToBuffer;
                  end;
                  // Now send frequency for selected VFO

                  CommandsTempBuffer[0]  := CHR(13);
                  CommandsTempBuffer[1]  := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[2]  := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[3]  := CHR(ReceiverAddress);
                  CommandsTempBuffer[4]  := ICOM_CONTROLLER_ADDRESS;
                  CommandsTempBuffer[5]  := ICOM_GET_EXTENDEDVFO;
                  if VFO = 'A' then
                     begin
                     CommandsTempBuffer[6] := Chr(0);
                     end
                  else
                     begin
                     CommandsTempBuffer[6] := Chr(1);
                     end;


                  Format(wsprintfBuffer, '%10.10u', Freq);
                  i := 6;
                  for CharPointer := 9 downto 0 do
                     begin
                     if not Odd(CharPointer) then
                        begin
                        Inc(i);
                        TempByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                        SendByte := SendByte or (TempByte shl 4);
                        CommandsTempBuffer[i] := CHR(SendByte);
                        end
                     else
                        begin
                        SendByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                        end;
                     end;

                     CommandsTempBuffer[12] := ICOM_END_OF_MESSAGE_CODE;
                     AddCommandToBuffer;

                  end
               else
                  begin              // For older Icom radios that do not support VFOB selection (Commands 25 and 26)
                  if not skipMode then
                     begin
                     CommandsTempBuffer[0] := CHR(9);
                     CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
                     CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
                     CommandsTempBuffer[3] := CHR(ReceiverAddress);
                     CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
                     CommandsTempBuffer[5] := ICOM_SET_MODE;
                     CommandsTempBuffer[6] := TempChar;

                  // ny4i: I'm trying to understand this logic   // 4.43.4
                  // The way Dave indicated this is supposed to work is that
                  // if the CFG option of ICOM_FILTER_BYTE is set to 0, then we want to send
                  // whatever the filter setting the rig had.
                  // If the value is 1, 2 or 3, then we want to send that when we change
                  // mode.
                  // tIcomFilterWidth is the value from the CFG file
                  //     if Mode = Phone then  CommandsTempBuffer[7] := CHR(tIcomFilterWidth);
                     if (RadioModel = OMNI6) and (Mode = CW) then      // n4af 4.43.3
                        begin
                        CommandsTempBuffer[0] := Chr(8); // Have to update since we are not adding filter Byte  // ny4i
                        CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;   // n4af 4.43.3
                        end
                     else
                        begin // ny4i 4.43.6
                        CommandsTempBuffer[7] := CHR(CalculateIcomFilterWidth);
                        // ny4i // n4af 4.43.4  set icom filter
                        CommandsTempBuffer[8] := ICOM_END_OF_MESSAGE_CODE;
                        end;
                     AddCommandToBuffer;

                     if bStateDataModeRequired then
                        begin
                        CommandsTempBuffer[0]  := CHR(9);
                        CommandsTempBuffer[1]  := ICOM_PREAMBLE_CODE;
                        CommandsTempBuffer[2]  := ICOM_PREAMBLE_CODE;
                        CommandsTempBuffer[3]  := CHR(ReceiverAddress);
                        CommandsTempBuffer[4]  := ICOM_CONTROLLER_ADDRESS;
                        CommandsTempBuffer[5]  := ICOM_STATE;
                        CommandsTempBuffer[6]  := ICOM_STATE_DATA_MODE;
                        CommandsTempBuffer[7]  := CHR(1);
                        CommandsTempBuffer[8]  := ICOM_END_OF_MESSAGE_CODE;
                        AddCommandToBuffer;
                        bStateDataModeRequired := false;
                        end;
                     end; // if not skipMode


                  CommandsTempBuffer[0]  := CHR(12);
                  CommandsTempBuffer[1]  := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[2]  := ICOM_PREAMBLE_CODE;
                  CommandsTempBuffer[3]  := CHR(ReceiverAddress);
                  CommandsTempBuffer[4]  := ICOM_CONTROLLER_ADDRESS;
                  CommandsTempBuffer[5]  := ICOM_SET_FREQ;
                  CommandsTempBuffer[11] := ICOM_END_OF_MESSAGE_CODE;

                  Format(wsprintfBuffer, '%10.10u', Freq);
                  i := 5;
                  for CharPointer := 9 downto 0 do
                     begin
                     if not Odd(CharPointer) then
                        begin
                        Inc(i);
                        TempByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                        SendByte := SendByte or (TempByte shl 4);
                        CommandsTempBuffer[i] := CHR(SendByte);
                        end
                     else
                        begin
                        SendByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                        end;
                     end;

                  if RadioModel = IC735 then
                     begin
                     CommandsTempBuffer[0]  := CHR(11);
                     CommandsTempBuffer[10] := ICOM_END_OF_MESSAGE_CODE;
                     end;

                  AddCommandToBuffer;

                  if VFO = 'B' then
                     begin
                     CommandsTempBuffer[0] := CHR(8);
                     CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
                     CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
                     CommandsTempBuffer[3] := CHR(ReceiverAddress);
                     CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
                     CommandsTempBuffer[5] := ICOM_SET_VFO_COMMAND;
                     CommandsTempBuffer[6] := ICOM_SET_VFO_A_COMMAND;
                     CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
                     AddCommandToBuffer;
                     end;
                  end;
               end;

         Orion:
            begin
            i := Format(tOrionFreq, '*AF%02u.%05u'#13, Freq div 1000000,
               (Freq div 10) mod 100000);

            tOrionFreq[1] := VFO; // Changed AF to BF if VFO 2.
            WriteToCATPort(tOrionFreq, i);
            
            case Mode of
               CW:
                  begin
                  if FT1000MPCWReverse then
                     begin
                     TempChar := '3';
                     end
                  else
                     begin
                     TempChar := '2';
                     end;
                  end;
               Phone:
                  begin
                  if Freq < 10000000 then
                     begin
                     TempChar := '1';
                     end
                  else
                     begin
                     TempChar := '0';
                     end;
                  end;
               Digital:
                  begin
                  TempChar := '6';        // FSK Mode
                  end;
               FM:
                  begin
                  TempChar := '5';
                  end;
               end;
            Windows.ZeroMemory(@tOrionMode, SizeOf(tOrionMode));
            Windows.lstrcat(tOrionMode, '*RMM?'#13);    // The ? is replaced with the tempChar for mode.
            tOrionMode[4] := TempChar;
            if VFO = 'B' then
               begin
               tOrionMode[2] := 'S';                  // If VFO B, the first M changes to S to become *RS...
               end;
            WriteToCATPort(tOrionMode, 6);   // This was commented out for some reason. Issue 683
            end;
         end;
      except //on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In SetRadioFreq, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
end;

procedure RadioObject.UpdateBandOutputInfo(Band: BandType; Mode: ModeType);

begin
   if BandOutputPort <> NoPort then
      begin
      OutputBandInfo(tBandOutputPortBaseAddress {BandOutputPort}, Band, Mode);
      end;
end;

function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;

{ This function will generate a string with the complete status of a
  RadioStatusRecord. }

var
   StatusString, TempString: string;
   TempValue: real;

begin
   StatusString := '';

   with StatusRecord do
      begin
      TempValue := Freq;
      TempValue := TempValue / 1000; { Convert to kHz }
      Str(TempValue: 5: 1, TempString);
      StatusString := StatusString + TempString + ' ';

      StatusString := StatusString + BandStringsArray[Band] + ' ';
      StatusString := StatusString + ModeStringArray[Mode] + ' ';

      if Split = True then
         begin
         StatusString := StatusString + 'Split      ';
         end
      else
         begin
         StatusString := StatusString + 'Transceive ';
         end;

      StatusString := StatusString + 'VFOA= ';

      TempValue := VFO[VFOA].Frequency;
      TempValue := TempValue / 1000; { Convert to kHz }
      Str(TempValue: 5: 1, TempString);
      StatusString := StatusString + TempString + ' ';

      StatusString := StatusString + BandStringsArray[VFO[VFOA].Band] + ' ';
      StatusString := StatusString + ModeStringArray[VFO[VFOA].Mode] + ' ';
      {
               case VFOA.TXRX of
                  VFODisabled: StatusString := StatusString + 'Off ';
                  RXOnly: StatusString := StatusString + 'RX  ';
                  TXOnly: StatusString := StatusString + 'TX  ';
                  Transceive: StatusString := StatusString + 'T/R ';
                  UnknownTXRX: StatusString := StatusString + '??? ';
               end;
      }
      StatusString := StatusString + 'VFOB= ';

      TempValue := VFO[VFOB].Frequency;
      TempValue := TempValue / 1000; { Convert to kHz }
      Str(TempValue: 5: 1, TempString);
      StatusString := StatusString + TempString + ' ';

      StatusString := StatusString + ModeStringArray[VFO[VFOB].Mode] + ' ';
      {
               case VFOB.TXRX of
                  VFODisabled: StatusString := StatusString + 'Off';
                  RXOnly: StatusString := StatusString + 'RX ';
                  TXOnly: StatusString := StatusString + 'TX ';
                  Transceive: StatusString := StatusString + 'T/R';
                  UnknownTXRX: StatusString := StatusString + '???';
               end;
              }
      end;

   Result := StatusString;
end;

procedure TestRadioInterface;

{ This procedure will display the data coming back from the interfaced
  radios }

var
   RadioOneLastDisplayedCurrentStatus:  Str80;
   RadioOneLastDisplayedPreviousStatus: Str80;
   RadioOneLastDisplayedFilteredStatus: Str80;

   RadioTwoLastDisplayedCurrentStatus:  Str80;
   RadioTwoLastDisplayedPreviousStatus: Str80;
   RadioTwoLastDisplayedFilteredStatus: Str80;

//   TempStatusString: Str80;
//   TempValue: real;

begin
   //{WLI}    Window (1, 1, 80, 25);

   //{WLI}    TextBackground (Black);
   //{WLI}    NoCursor;

   ShowMessage('TEST RADIO INTERFACE');

   //{WLI}    WriteLn ('This procedure will display the data coming back from the interfaced radios');
   //{WLI}    WriteLn ('Press the ESCAPE key to exit and halt TR.');
   //{WLI}    WriteLn;

   RadioOneLastDisplayedCurrentStatus  := '';
   RadioOneLastDisplayedPreviousStatus := '';
   RadioOneLastDisplayedFilteredStatus := '';

   RadioTwoLastDisplayedCurrentStatus  := '';
   RadioTwoLastDisplayedPreviousStatus := '';
   RadioTwoLastDisplayedFilteredStatus := '';


end;

function RadioObject.CheckAutoCallTerminate: boolean;
begin
  Result := False;
  if AutoCallTerminate then
     begin
     if not ExchangeHasBeenSent then
        if tAutoSendMode then
           if not ControlAMode then
              begin
              //ReturnInCQOpMode;
              Result := True;
              end;
     end;
end;
function OpenCATDebugFile(port: PortType): boolean;

begin

end;


function tPTTVIACAT(PTTOn: boolean): boolean;

var
   IntRadioType: InterfacedRadioType;
   ro: TNetRadioBase;
//   SerialPort: PortType;
   TempString: Str80;
   WaitAnswer: cardinal;
const

   FT890PTTOn =
      CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($0F);
   FT890PTTOff =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($0F);

   FT817PTTOn =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($08);
   FT817PTTOff =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($88);

begin
   WaitAnswer := 0;
   Result := False;
   if not tPTTViaCommand then
      begin
      logger.debug('**** tPTTVIACAT called but tPTTViaCommand is false');
      Exit;
      end;
   if NoPollDuringPTT then
      begin
      Exit;
      end;
   if ActiveRadio = RadioOne then
      begin
      IntRadioType := Radio1.RadioModel;
      ro := Radio1.tNetObject;
//      SerialPort := Radio1.tCATPortType;
      end
   else
      begin
      IntRadioType := Radio2.RadioModel;
      ro := Radio2.tNetObject;
 //     SerialPort := Radio2.tCATPortType;
      end;
   if ro <> nil then
      begin
      if PTTOn then
         begin
         ro.Transmit;
         end
      else
         begin
         ro.Receive;
         end;
      Result := true;
      Exit;
      end;
   case IntRadioType of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS890, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3, KX3, K4:
         begin
         if PTTOn then
            begin
            TempString := 'TX;';
            DEBUGMSG('Setting Kenwood/Flex/K3/KX3/K4 to TX mode');
            end else
            begin
            DEBUGMSG('Setting Kenwood/Flex/K3/KX3/K4 to RX mode');
            TempString := 'RX;';
            end;
         end;

      FTDX10, FTDX101, FTX1F, FT710, FT450, FT950, FT891, FT991, FT1200, FT2000,
      FTDX3000, FTDX5000, FTDX9000:
         begin
         if PTTOn then
            begin
            TempString := 'TX1;';
            end
         else
            begin
            TempString := 'TX0;';
            end;
         end;

      FT747GX, FT100, FT840, FT890, FT900, FT990, FT1000, FT1000MP:
         begin
         if PTTOn then
            begin
            TempString := FT890PTTOn;
            end else
            begin
            TempString := FT890PTTOff;
            end;
         end;

      FT736R, FT817, FT818, FT847 {, FT857, FT897}:
         begin
         if PTTOn then
            begin
            TempString := FT817PTTOn;
            end else
            begin
            TempString := FT817PTTOff;
            end;
         end;

      FT920, FT767:
         begin
         logger.debug('FT920 or FT767 do not support PTT via CAT commands');
         Exit;
         end;
  

    IC78..IC9700:
       begin
          TempString := CHR($FE) + CHR($FE) + CHR(Radio1.ReceiverAddress) + CHR($E0) + CHR($1C) + CHR($00) + CHR($00) + CHR($FD);
          if PTTOn then
             begin
             logger.debug('Setting Icom to TX');
             TempString[7] := CHR($01);
             end
          else
             begin
             logger.debug('Setting Icom to RX');
             end;
          WaitAnswer := 14;
       end;

      //      IC78..IC9700, OMNI6: Exit;

      Orion:
         begin
         if PTTOn then
            begin
            TempString := '*TK' + CarriageReturn;
            end
         else
            begin
            TempString := '*TU' + CarriageReturn;
            end;
         end;
      else
         begin
         logger.warn('Radio model does not support TX/RX commands');
         Exit;
         end;
      end;

   //  CPUKeyer.AddSerialPortString(SerialPort, TempString);
   ActiveRadioPtr.WriteToCATPort(TempString[1], length(TempString));
   if WaitAnswer <> 0 then
      begin
      ReadFromCOMPort(WaitAnswer, @Radio1);
      end;
   Result := True;
end;

function RadioObject.CalculateIcomFilterWidth: integer;
begin
   Result := 0;
   case tIcomFilterWidth of             // Not set in CFG so send current value
      0: begin
         if Icom_Filter_Width > 0 then     // this is the module global stored fromthe rig message in uRadioPolling
            begin
            Result := Icom_Filter_Width;  // n4af 4.43.4    tIcomFilterWidth
            end
         else
            begin
            Result := 1;       // Default to 1 if no CFG set and we do not have a value from the radio. We cannot send 0 to some radios as they reject the command. Others handle the zero though.
            end;
         end;
      1..3: Result := tIcomFilterWidth;
      else
         begin
         Result := 0;
         end;
      end; // case
end;


procedure InitRadios;
var
   TempRadio: RadioPtr;
   i: integer;
const
   ra: array[1..2] of RadioPtr = (@Radio1, @Radio2);
begin
   RadioSupportsCWByCAT := [TS850, K2, K3, KX3, K4, TS480, TS570, TS590, TS890, TS990, TS2000,
                            FLEX, IC705, IC7100, IC7300, IC7410, IC7600, IC7610, IC7700, IC7760,
                            IC7800, IC7850, IC7851, IC9100, IC9700, IC905, IC7300MK2, Orion];  // TS890 -- Issue #436
   // ny4i Issue 119
   RadioSupportsCWSpeedSync :=
      [TS850, K2, K3, K4, TS480, TS570, TS590, TS890, TS990, TS2000, FLEX, FTDX10, FTDX101, FTX1F, FT450, FT710, FT891, FT950, FT991,
      FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000, IC718, IC746, IC746PRO, IC756PROII,
      IC756PROIII, IC910, IC705, IC7100, IC7200, IC7300, IC7410, IC7600, IC7610,
      IC7700, IC7760, IC7800, IC7850, IC7851, IC9100, IC9700, IC905, IC7300MK2, Orion];  // ny4i Issue 120; TS890 -- Issue #436

   RadioSupportsPlayDVK := [ K2, K3, K4 // We do not support the KX2 and KX3? I guess not a lot of call for it.
                            ,IC705, IC7300, IC7610, IC7760, IC7850, IC7851, IC9100, IC9700, IC905, IC7300MK2
                            ,FT710, FT991, FT1200, FTDX3000, FTDX5000, FTDX9000, FTDX10, FTDX101, FTX1F
                            ,TS480, TS570, TS590, TS850, TS890, TS950, TS990, TS2000
                            ]; // NY4I Issue 639; TS890 -- Issue #436
   IcomRadiosThatSupportRIT := [IC705, IC7100, IC7300, IC7800, IC7850, IC7851, IC7600, IC7610, IC7700, IC7760, IC9700, IC905, IC7300MK2];
   IcomRadiosThatSupportVFOB := [IC705, IC7100, IC7300, IC7800, IC7850, IC7851, IC7600, IC7610, IC7700, IC7760, IC9700, IC905, IC7300MK2];
   IcomRadiosThatSupportPSKMode := [IC7600, IC7610, IC7760];
   ICOMRadios := [IC78..IC9700];
   KenwoodRadios := [TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850,
                     TS870, TS890, TS940, TS950, TS990, TS2000, FLEX];  // TS890 -- Issue #436
   YaesuRadios := [FTDX10, FTDX101, FTX1F, FT450, FT710, FT736R, FT747GX, FT767, FT817,
                   FT818, FT840, FT847, FT857, FT890, FT891, FT897, FT900, FT920,
                   FT950, FT990, FT991, FT1000, FT1000MP, FT1200, FT2000,
                   FTDX3000, FTDX5000, FTDX9000];
   HamLibONLYRadios := [FLRIG,TRXMANAGER,FT757GXII,EXPERTTCI,ACLOG,HAMLIBANY];  // TS890 removed -- now has native serial via rtKenwood (Issue #436)
   for i := 1 to 2 do
      begin
      TempRadio := ra[i];

      TempRadio.RadioNumberBits := 8;
      TempRadio.RadioStopBits  := 2;
      TempRadio.tCATPortHandle := INVALID_HANDLE_VALUE;

      TempRadio.tKeyerPortHandle := INVALID_HANDLE_VALUE;
      TempRadio.tr4w_keyer_rts_state := RtsDtr_PTT;
      TempRadio.tr4w_keyer_DTR_state := RtsDtr_CW;
      TempRadio.tr4w_cat_rts_state := RtsDtr_OFF; //CAT RTS
      TempRadio.tr4w_cat_dtr_state := RtsDtr_OFF; //CAT DTR
      TempRadio.PollingEnable := True;
      //    TempRadio.ICOM_COMMAND_PTT := #255;
      TempRadio.SpeedMemory := InitialCodeSpeed;
      TempRadio.tIcomFilterWidth := 2;
      InitializeCriticalSection(TempRadio.CATSerialLock);

      end;
   Radio1.RadioName := TC_RADIO1;
   Radio2.RadioName := TC_RADIO2;
   Radio1.active := true;
   Radio2.active := false;

   // Create CWByCATTimer

end;



initialization
   InitRadios;

finalization
   DeleteCriticalSection(Radio1.CATSerialLock);
   DeleteCriticalSection(Radio2.CATSerialLock);

end.
