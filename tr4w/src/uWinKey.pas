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
unit uWinKey;
{$IMPORTEDDATA OFF}
interface

uses
  LogRadio,
  uCommctrl,
  Messages,
  Windows,
  VC,
  utils_file,
  TF,
  Tree
  ;

function wkOpen: boolean;
function wkOpenPort: boolean;
function wkSend(const Buffer; nNumberOfBytesToWrite: DWORD): Cardinal;
procedure wkSendAdminCommand(const Buffer);
function wkSendByte(b: Byte): Cardinal;
function wkSendTwoBytes(B1, B2: Byte): Cardinal;
procedure wkSetSpeed(Speed: integer);
//procedure wkChangeSpeedBuffered;
function wkRead(nNumberOfBytesToRead: DWORD): boolean;
procedure wkClose;
procedure wkClearBuffer;
procedure wkSetupSpeedPot;
function WinKeyer2SettingsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
//procedure wkSaveSettings;
//procedure wkLoadSettings;
function wkTurnPTT(Turn: boolean): boolean;
procedure wkDispayState;
procedure wkReadThreadProc;
procedure wkReadThreadProc1;
procedure wkAddCWMessageToInternalBuffer(Msg: Str160);
procedure wkAddCharToHostBuffer(c: Char);
procedure wkSetKeyerOutput(r: RadioPtr);
function wkSendNextByteFromHostBuffer: boolean;
procedure wkSwapTune;
procedure wkWriteToDebugFile(b: Char; TX: boolean);
//procedure wkSetLeadInTail;

type
  TWK2KeyerMode = (kmIambicB, kmIambicA, kmUltimatic, kmBugMode);
  TWKSidetoneFrequency = (stf4000, stf2000, stf1333, stf1000, stf800, stf666, stf571, stf500, stf444, stf400);

const
  KeyerModeSA                           : array[TWK2KeyerMode] of PChar = ('IAMBIC B', 'IAMBIC A', 'ULTIMATIC', 'BUG MODE');
  SidetoneFrequencySA                   : array[TWKSidetoneFrequency] of PChar = ('4000', '2000', '1333', '1000', '800', '666', '571', '500', '444', '400');
type
  TwkValueList = packed record
    {(*}
    vlCommandCode      : Byte;//$0F - default value
    vlModeRegister     : Byte;//$02 - default value
    vlSpeedinWPM       : Byte;//$10 - default value
    vlSidetoneFrequency: TWKSidetoneFrequency{Byte};//$05 - default value

    vlWeight           : Byte;//$32 - default value
    vlLeadInTime       : Byte;//$00 - default value
    vlTailTime         : Byte;//$00 - default value
    vlMinWPM           : Byte;//$05 - default value

    vlWPMRange         : Byte;//$14 - default value
    vl1stExtension     : Byte;//$00 - default value
    vlKeyCompensation  : Byte;//$00 - default value
    vlFarnsworthWPM    : Byte;//$12 - default value

    vlPaddleSWPoint    : Byte;//$32 - default value
    vlDitDahRatio      : Byte;//$32 - default value
    vlPinConfiguration : Byte;//$06 - default value
    vlDontcare         : Byte;//$FF - default value
    {*)}
  end;

type
  TWinKeySettings = packed record
    {(*}
    {16}wksValueList      : TwkValueList;

    {01}wksWinKey2Port    : PortType;
    {01}wksWinKey2Enable  : boolean;
    {01}wksAutospace      : boolean;
    {01}wksCTSpacing      : boolean;

    {01}wksPaddleSwap     : boolean;
    {01}wksKeyerMode      : TWK2KeyerMode;
    {01}wksIgnoreSpeedSpot: boolean;
    {01}wksSideTEnable    : boolean;

    {01}wksPadOnlySideT   : boolean;
    {01}wkres02           : Byte;
    {01}wkres03           : Byte;
    {01}wkres04           : Byte;

    {01}wkres05           : Byte;
    {01}wkres06           : Byte;
    {01}wkres07           : Byte;
    {01}wkres08           : Byte;

    {01}wkres09           : Byte;
    {01}wkres10           : Byte;
    {01}wkres11           : Byte;
    {01}wkres12           : Byte;

    {01}wkres13           : Byte;
    {01}wkres14           : Byte;
    {01}wkres15           : Byte;
    {01}wkres16           : Byte;
//    {01}wkres17           : Byte;
//    {01}wkres18           : Byte;
    {*)}
  end;

const
  wkDebugFileHeader                     = '<HTML><STYLE>.RX {BACKGROUND:#00FF00} .ST{BACKGROUND:#FFFF00}</STYLE><BODY><TABLE BORDER=1 WIDTH=40% ALIGN=LEFT>';
  wkCALIBRATE                           = #$00#$00;
  wkRESET                               = #$00#$01;
  wkHOSTOPEN                            = #$00#$02;
  wkHOSTCLOSE                           = #$00#$03;
  wkECHOTEST                            = #$00#$04;
  wkGETVALUES                           = #$00#$07;

  wkSETWK1MODE                          = #$00#$0A;
  wkSETWK2MODE                          = #$00#$0B;

  wkECHOTESTBYTE                        = $55;

  WKCMD_SIDETONECONTROL                 = $01;
  wkCMD_SETWPMSPEED                     = $02;
  wkCMD_SETWEIGHTING                    = $03;
  wkCMD_SETPTTLEADTAIL                  = $04;
  wkCMD_SETUPSPEEDPOT                   = $05;
  wkCMD_GETPOT                          = $07;
  wkCMD_BACKSPACE                       = $08;

  wkCMD_SETPINCONFIG                    = $09;
  wkCMD_CLEARBUFFER                     = $0A;
  wkCMD_KEYIMMEDIATE                    = $0B;
  wkCMD_SETWINKEYER2MODE                = $0E;
  wkCMD_LOADDEFAULTS                    = $0F;
  wkCMD_NULLIMM                         = $13;
  wkCMD_SETDITDAHRATIO                  = $17;
  wkCMD_PTTONOFF                        = $18;
  wkCMD_CHANGESPEEDBUFFERED             = #$1C;
  SizeOfHostBuffer                      = 512;

//  wk_STATUS_BYTE_START                  = 196;
//  wk_STATUS_BYTE_END                    = 192;
var
{$IF K6VVA_WK_DEBUG}
//  wkDebugFileRX                         : HWND;
  wkDebugFileTX                         : HWND;
  wkDebu1310                            : PChar = #13#10;
  wkDebugBuffer                         : array[0..63] of Char;
  wkDebugFileRecordNumber               : integer;
{$IFEND}
  wkTune                                : boolean;
  WK2                                   : boolean;
  wkSpeedUp                             : integer;
  wkSpeedDown                           : integer;

  wkSpeedChanged                        : boolean;
  wkActive                              : LongBool = False;
  wkCWSpeed                             : integer;

  wkBUSY                                : boolean = False; // 4.90.5
  wkBREAKIN                             : boolean;
  wkXOFF                                : boolean;

  wkThreadID                            : Cardinal;
  wkCWThreadID                          : Cardinal;

//  wkThreadHWND                          : HWND = INVALID_HANDLE_VALUE;
  WinKeyHandle                          : HWND = INVALID_HANDLE_VALUE;

  wkBuffer                              : array[0..7] of Byte;
  wkREADBuffer                          : array[0..32] of Byte;
  wkThreadReadBuffer                    : array[0..15] of Byte;
  wkInternalCWBuffer                    : array[0..SizeOfHostBuffer - 1] of Char;

  wkHostBufferIndex                     : integer;
  wkHostBufferSendIndex                 : integer;

  wkWaitingBytesInHost                  : integer;
  wkWaitingBytesInWK                    : integer;

//  wkClearEnable                         : boolean;
  wkPTTOn                               : boolean;

//  wkSpeedUpPos                          : integer = -1;
//  wkSpeedDownPos                        : integer = -1;

//  wkSpeedUpValue                        : integer = -1;
//  wkSpeedDownValue                      : integer = -1;

  wklpCommTimeouts                      : TCommTimeouts;
  wkDCB                                 : TDCB;

  WinKeySettings                        : TWinKeySettings =
    (
{(*}
    wksValueList: (
    vlCommandCode:       wkCMD_LOADDEFAULTS;
    vlModeRegister:      2;
    vlSpeedinWPM:        35;
    vlSidetoneFrequency: stf800; //10000100
    vlWeight:            $32;
    vlLeadInTime:        0;
    vlTailTime:          0;
    vlMinWPM:            2;
    vlWPMRange:          99;
    vl1stExtension:      0;
    vlKeyCompensation:   0;
    vlFarnsworthWPM:     $12;
    vlPaddleSWPoint:     $32;
    vlDitDahRatio:       $32;
    vlPinConfiguration:  6;
    vlDontcare:          $FF;
    );
    wksWinKey2Port:      NoPort;
    wksWinKey2Enable:    False;

    wksAutospace:        False;
    wksCTSpacing:        False;
    wksPaddleSwap:       False;
    wksKeyerMode:        kmIambicB;
    wksIgnoreSpeedSpot:  True;
    wksSideTEnable:   True;
{*)}
    );

    //0F 02 5D 06 32 00 00 05 5E 00 00 12 32 32 06 FF   07 15

const
  wkMINWPM                              = 10;
  wkWPMRANGE                            = 40;

implementation
uses
  SysUtils,
  uNet,
  LogDupe,
  uTelnet, {LogRadio,}
  LogWind,
  LogCW,
  LogK1EA,
  CFGCMD,
  MainUnit;

function wkOpen: boolean;
var
  versionByte : Byte;
  family      : Byte;
  msg         : string;
begin
  Result := False;

  if WinKeySettings.wksWinKey2Enable = False then Exit;
  if WinKeySettings.wksWinKey2Port = NoPort then Exit;

  if not wkOpenPort then Exit;

  // Send three null commands to resync host to WK2
  wkSendByte(wkCMD_NULLIMM);
  wkSendByte(wkCMD_NULLIMM);
  wkSendByte(wkCMD_NULLIMM);

  wkSendAdminCommand(wkECHOTEST);
  wkSendByte(wkECHOTESTBYTE);
//  Sleep(150);

  if ((not wkRead(1)) or (wkREADBuffer[0] <> wkECHOTESTBYTE)) then
  begin
    wkClose;
    Exit;
  end;

  wkSendAdminCommand(wkHOSTOPEN);
//  Sleep(150);

  PCardinal(@wkREADBuffer[0])^ := 0;   // Issue #997: was asm (zero first dword)
  if wkRead(1) then
  begin
    // The keyer's HOST OPEN response is its firmware-revision byte.
    // Map it to a family digit for the status display:
    //   v < 20   -> WK1     (legacy WinKeyer)
    //   v 20-29  -> WK2     (WinKeyer2)
    //   v >= 30  -> WK3     (WinKeyer3 — was previously displayed as WK2
    //                        because the family was tracked as a single
    //                        Boolean WK2 := version >= 20.  Issue #891)
    versionByte := wkREADBuffer[0];
    WK2 := versionByte >= 20;
    if versionByte >= 30 then
      family := 3
    else if versionByte >= 20 then
      family := 2
    else
      family := 1;
    msg := Format('WK%d v%d', [family, versionByte]);
    SetMainWindowText(mweWinKey, PChar(msg));
  end;
  logger.Info('Calling tCreateThread from WkOpen');
  tCreateThread(@wkReadThreadProc, wkThreadID);
  logger.Info('Created WK thread with id %d',[wkThreadId]);

  wklpCommTimeouts.ReadTotalTimeoutConstant := 10 - 0;
//  wklpCommTimeouts.WriteTotalTimeoutConstant := 1;
  SetCommTimeouts(WinKeyHandle, wklpCommTimeouts);

  wkSendAdminCommand(wkSETWK1MODE);

//  WinKeySettings.wksValueList.vlModeRegister := WinKeySettings.wksValueList.vlModeRegister + 4;
  WinKeySettings.wksValueList.vlModeRegister :=
    integer(WinKeySettings.wksCTSpacing) * 1 +
    integer(WinKeySettings.wksAutospace) * 2 +
    4 +
    integer(WinKeySettings.wksPaddleSwap) * 8 +
    integer(WinKeySettings.wksKeyerMode) * 16 +
    128;

//          if WinKeySettings.wksKeyerMode = kmIambicA then TempInteger := TempInteger + 16;
//          if WinKeySettings.wksKeyerMode = kmUltimatic then TempInteger := TempInteger + 32;
//          if WinKeySettings.wksKeyerMode = kmBugMode then TempInteger := TempInteger + 48;

  WinKeySettings.wksValueList.vlSpeedinWPM := ActiveRadioPtr.SpeedMemory;
  sWriteFile(WinKeyHandle, WinKeySettings.wksValueList, SizeOf(TwkValueList));
//  wkSetupSpeedPot;
  wkSendByte(wkCMD_GETPOT);
//  wkSendTwoBytes(wkCMD_SETWEIGHTING, WinKeySettings.wkWeighting);
//  wkSendTwoBytes(wkCMD_SETDITDAHRATIO, WinKeySettings.wkDitDahRatio);
  wkSendTwoBytes(WKCMD_SIDETONECONTROL, Byte(WinKeySettings.wksPadOnlySideT) * 128 + Byte(WinKeySettings.wksValueList.vlSidetoneFrequency) + 1);
  wkSetKeyerOutput(ActiveRadioPtr);
  wkClearBuffer;
//  wkSetLeadInTail;
end;

function wkSend(const Buffer; nNumberOfBytesToWrite: DWORD): Cardinal;
begin
  logger.Debug('[wkSend] writing %d byte(s) to WinKeyer', [nNumberOfBytesToWrite]);
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  tWriteFile(WinKeyHandle, Buffer, nNumberOfBytesToWrite, Result);
end;

procedure wkSendAdminCommand(const Buffer);
var
  Bytes: array[0..1] of Byte absolute Buffer;
begin
  logger.Trace('[wkSendAdminCommand] B1=$%s B2=$%s', [IntToHex(Bytes[0], 2), IntToHex(Bytes[1], 2)]);
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  sWriteFile(WinKeyHandle, Buffer, 2);
end;

function wkSendByte(b: Byte): Cardinal;
begin
  logger.Trace('[wkSendByte] b=%s ($%s)', [string(Char(b)), IntToHex(b, 2)]);
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  sWriteFile(WinKeyHandle, b, 1);
{$IF K6VVA_WK_DEBUG}
  wkWriteToDebugFile(Char(b), True);
{$IFEND}

//  wkBuffer[0] := b;
//  tWriteFile(WinKeyHandle, wkBuffer, 1, RESULT);
//  wkWriteToDebugFile(Char(wkBuffer[0]), True);
end;

function wkSendTwoBytes(B1, B2: Byte): Cardinal;
var
  TwoBytesBuffer                        : array[0..1] of Byte;
begin
  logger.Trace('[wkSendTwoBytes] B1=%s ($%s) B2=%s ($%s)',
               [string(Char(B1)), IntToHex(B1, 2), string(Char(B2)), IntToHex(B2, 2)]);
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  TwoBytesBuffer[0] := B1;
  TwoBytesBuffer[1] := B2;
  tWriteFile(WinKeyHandle, TwoBytesBuffer, 2, Result);
{$IF K6VVA_WK_DEBUG}
  wkWriteToDebugFile(Char(B1), True);
  wkWriteToDebugFile(Char(B2), True);
{$IFEND}

//  wkSendByte(B1);
//  wkSendByte(B2);
{
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkBuffer[0] := B1;
  wkBuffer[1] := B2;
  tWriteFile(WinKeyHandle, wkBuffer, 2, RESULT);
  wkWriteToDebugFile(Char(wkBuffer[0]), True);
  wkWriteToDebugFile(Char(wkBuffer[1]), True);
}
end;
{
procedure wkSetLeadInTail;
begin
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkBuffer[0] := wkCMD_SETPTTLEADTAIL;
  wkBuffer[1] := WinKeySettings.wksLeadIn;
  wkBuffer[2] := WinKeySettings.wkTail;
  sWriteFile(WinKeyHandle, wkBuffer, 3);
end;
}

procedure wkSetSpeed(Speed: integer);
begin
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkSendTwoBytes(wkCMD_SETWPMSPEED, Speed);
  wkCWSpeed := Speed;
end;


function wkRead(nNumberOfBytesToRead: DWORD): boolean;
var
  lpNumberOfBytesRead                   : DWORD;
begin
  Windows.ReadFile(WinKeyHandle, wkREADBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead, nil);
  Result := lpNumberOfBytesRead = nNumberOfBytesToRead;
end;

procedure wkClose;
begin
  wkActive := False;
  wkDispayState;
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkClearBuffer;
  wkSendAdminCommand(wkHOSTCLOSE);
  CloseHandle(WinKeyHandle);
  WinKeyHandle := INVALID_HANDLE_VALUE;
end;

procedure wkClearBuffer;            // 4.36.13 GM0GAV
begin
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkSendByte(wkCMD_CLEARBUFFER);
//  wkHostBufferIndex := 0;

  wkWaitingBytesInHost := 0;
  wkWaitingBytesInWK := 0;

  wkHostBufferIndex := 0; //
  wkHostBufferSendIndex := 0; //

  wkSendByte(wkCMD_NULLIMM);                               //Gav   add 4.36.13
  wkSendByte(wkCMD_NULLIMM);                                //Gav   4.36.13
  wkSendByte(wkCMD_NULLIMM);                                //Gav    4.36.13
 wkSendByte(wkCMD_CLEARBUFFER);                           //Gav     4.36.13


{$IF WINKEYDEBUG}
//  AddStringToTelnetConsole('CLEAR');
{$IFEND}

end;

procedure wkSetupSpeedPot;
begin
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkBuffer[0] := wkCMD_SETUPSPEEDPOT;
  wkBuffer[1] := wkMINWPM;
  wkBuffer[2] := wkWPMRANGE;
  wkBuffer[3] := 0;
  sWriteFile(WinKeyHandle, wkBuffer, 4);
end;

function wkTurnPTT(Turn: boolean): boolean;
begin
  Result := False;
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  wkBuffer[0] := wkCMD_PTTONOFF;
  wkBuffer[1] := Byte(Turn);
  Result := sWriteFile(WinKeyHandle, wkBuffer, 2);
{$IF WINKEYDEBUG}
//  AddStringToTelnetConsole('PTT');
{$IFEND}
end;

function WinKeyer2SettingsDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  ExitAndClose, 1;
var
  c                                     : Cardinal;
  Top                                   : Cardinal;
  Left                                  : Cardinal;
  TempInteger                           : integer;
  lpTranslated                          : BOOL;
  TempHWND                              : HWND;
const
  wkBool                                = 7;
  wkRange                               = 7;
  wkCombo                               = 4 - 1;

//  wkSidetoneFrequencyArrayWK1           : array[1..10] of Word = (3759, 1879, 1252, 0940, 0752, 0625, 0535, 0469, 0417, 0375);
//  wkSidetoneFrequencyArrayWK2           : array[1..10] of Word = (4000, 2000, 1333, 1000, 0800, 0666, 0571, 0500, 0444, 0400);

  wkSidetoneFrequencyArray              : array[1..20] of Word =
    (
    3759, 1879, 1252, 0940, 0752, 0625, 0535, 0469, 0417, 0375, //wk1
    4000, 2000, 1333, 1000, 0800, 0666, 0571, 0500, 0444, 0400 //wk2
    );

//  WK2HangTimeArray                      : array[1..4] of PChar = ('1.0', '1.33', '1.66', '2.0');
  WK2SettingsNamesArray                 : array[1..wkBool] of PChar = (TC_WINKEYERENABLE, TC_AUTOSPACE, TC_CTSPACING, TC_SIDETONE, TC_PADDLESWAP, TC_IGNORESPEEDPOT, TC_PADDLEONLYSIDETONE);
  WK2ComboSettingsNamesArray            : array[1..wkCombo] of PChar = (TC_WINKEYERPORT, TC_KEYERMODE, TC_SIDETONEFREQ {, TC_HANGTIME});
  WK2KeyerModesArray                    : array[1..4] of PChar = (TC_IAMBICB, TC_IAMBICA, TC_ULTIMATIC, TC_BUGMODE);

  WK2SliderLabelArray                   : array[1..wkRange] of PChar = (TC_WEIGHTING, TC_DITDAHRATIO, TC_LEADIN, TC_TAIL, TC_FIRSTEXTENSION, TC_KEYCOMP, TC_PADDLESWITCHPOINT);

  WK2UpDownValue                        : array[1..wkRange] of PByte = (
    @WinKeySettings.wksValueList.vlWeight,
    @WinKeySettings.wksValueList.vlDitDahRatio,
    @WinKeySettings.wksValueList.vlLeadInTime,
    @WinKeySettings.wksValueList.vlTailTime,
    @WinKeySettings.wksValueList.vl1stExtension,
    @WinKeySettings.wksValueList.vlKeyCompensation,
    @WinKeySettings.wksValueList.vlPaddleSWPoint
    );

  WK2BoolValue                          : array[1..wkBool] of PBoolean = (
    @WinKeySettings.wksWinKey2Enable,
    @WinKeySettings.wksAutospace,
    @WinKeySettings.wksCTSpacing,
    @WinKeySettings.wksSideTEnable,
    @WinKeySettings.wksPaddleSwap,
    @WinKeySettings.wksIgnoreSpeedSpot,
    @WinKeySettings.wksPadOnlySideT
    );

  WK2UpDownUpperValue                   : array[1..wkRange] of integer = (090, 066, 250, 250, 250, 250, 090);
  WK2UpDownLowerValue                   : array[1..wkRange] of integer = (010, 033, 000, 000, 000, 000, 010);

  CC                                    = 24;
  PORT_CB                               = 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + 1;
  MODE_CB                               = 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + 2;
  FREQ_CB                               = 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + 3;
  HANG_CB                               = 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + 4;

  WEIGHTING_SLIDER                      = 117;
  DITDAH_RATIO_SLIDER                   = WEIGHTING_SLIDER + 1;
  LEADIN_SLIDER                         = WEIGHTING_SLIDER + 2;
  TAIL_SLIDER                           = WEIGHTING_SLIDER + 3;
  w                                     = 130;
  w3                                    = 80;
  o                                     = 10;
  w2                                    = 25;
  w4                                    = ((wkBool div 2) + 1);
  UpDownControlStyle                    = WS_CHILD or WS_BORDER or WS_VISIBLE or UDS_NOTHOUSANDS or UDS_ARROWKEYS or UDS_ALIGNRIGHT or UDS_SETBUDDYINT;

  procedure SETCHECK(ID: integer; b: boolean);
  begin
    Windows.SendDlgItemMessage(hwnddlg, ID, BM_SETCHECK, integer(b), 0);
  end;
begin

  Result := False;
  case Msg of
    //    WM_HELP: tWinHelp(49);

    WM_INITDIALOG:
      begin
//        Windows.SendDlgItemMessage(hwnddlg, 300, TBM_SETTHUMBLENGTH , 10, 0);
        Top := 0;
        for c := 1 to length(WK2SettingsNamesArray) do
        begin

          if ((c - 1) mod 2) = 0 then
          begin
            Left := o;
            inc(Top, CC);
          end
          else

            Left := o * 2 + w;
//          Top := c * CC;
          tCreateButtonWindow(0, WK2SettingsNamesArray[c], $50010003, Left, Top, w, 17, hwnddlg, 100 + c);
//          showint(c mod 2);
        end;

        for c := 1 to wkCombo do
        begin
          Top := c * CC + w4 * CC;
          tCreateStaticWindow(WK2ComboSettingsNamesArray[c], LeftVisNoSunStyle, o {* 2 + w}, Top, w, 17, hwnddlg, 100 + High(WK2SettingsNamesArray) + c);

          CreateWindowEx(
            WS_EX_STATICEDGE,
            COMBOBOX,
            nil,
            CBS_DROPDOWNLIST or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP,
            o * 2 + w,
            Top,
            w3,
            200,
            hwnddlg,
            100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + c,
            hInstance,
            nil
            );

          // Issue #997: asm tWM_SETFONT (EAX = the COMBOBOX just created above);
          // re-fetch it by its child id and set its font.
          tWM_SETFONT(GetDlgItem(hwnddlg, 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + c), MSSansSerifFont);
        end;

        for c := 1 to wkRange do
        begin
          Top := c * CC + length(WK2ComboSettingsNamesArray) * CC + w4 * CC;
          tCreateStaticWindow(WK2SliderLabelArray[c], LeftVisNoSunStyle, o, Top, w, 17, hwnddlg, 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + length(WK2ComboSettingsNamesArray) + c);
          TempHWND := tCreateEditWindow(WS_EX_STATICEDGE, nil, ES_CENTER + ES_NUMBER + WS_CHILD or WS_TABSTOP or WS_VISIBLE, o * 2 + w, Top, w3, 20, hwnddlg, 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + length(WK2ComboSettingsNamesArray) + length(WK2SliderLabelArray) + c);
          CreateUpDownControl(UpDownControlStyle, 0, 0, 0, 0, hwnddlg, 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + length(WK2ComboSettingsNamesArray) + length(WK2SliderLabelArray) + c, hInstance, TempHWND, WK2UpDownUpperValue[c], WK2UpDownLowerValue[c], integer(WK2UpDownValue[c]^));
        end;

        for c := 1 to 4 do tCB_ADDSTRING(hwnddlg, MODE_CB, WK2KeyerModesArray[c]);
        tCB_SETCURSEL(hwnddlg, MODE_CB, Cardinal(WinKeySettings.wksKeyerMode));

        tCB_ADDSTRING(hwnddlg, PORT_CB, 'NONE');
        for c := 1 to 20 do
        begin
          // Issue #997: asm wsprintf-push -> TF.Format (c is the integer loop var).
          Format(@wkREADBuffer, 'SERIAL %u', c);
          tCB_ADDSTRING_PCHAR(hwnddlg, PORT_CB, @wkREADBuffer[0]);
        end;
        tCB_SETCURSEL(hwnddlg, PORT_CB, Cardinal(WinKeySettings.wksWinKey2Port));

        for c := 1 to 10 do
        begin
          TempInteger := integer(wk2) * 10 + c;
          tCB_ADDSTRING_PCHAR(hwnddlg, FREQ_CB, inttopchar(wkSidetoneFrequencyArray[TempInteger]));
        end;
        tCB_SETCURSEL(hwnddlg, FREQ_CB, Byte(WinKeySettings.wksValueList.vlSidetoneFrequency) - 1);
        goto 1;
      end;
    WM_COMMAND:
      begin
        if wParam = 2 then goto ExitAndClose;
        if wParam = 1 then
        begin
        {SIDETONE}
          Byte(WinKeySettings.wksValueList.vlSidetoneFrequency) := tCB_GETCURSEL(hwnddlg, FREQ_CB) + 1;
          WinKeySettings.wksKeyerMode := TWK2KeyerMode(tCB_GETCURSEL(hwnddlg, MODE_CB));

          for c := 1 to wkBool do
            WK2BoolValue[c]^ := boolean(TF.SendDlgItemMessage(hwnddlg, 100 + c, BM_GETCHECK));


          WinKeySettings.wksWinKey2Port := PortType(tCB_GETCURSEL(hwnddlg, PORT_CB));

//          if Windows.SendDlgItemMessage(hwnddlg, 104, BM_GETCHECK, 0, 0) = BST_CHECKED then WinKeySettings.wksValueList.vlSidetoneFrequency := WinKeySettings.wksValueList.vlSidetoneFrequency or (1 shl 7);

          TempInteger :=
            4 + 128 + //64 +
            integer(WinKeySettings.wksCTSpacing) * 1 +
            integer(WinKeySettings.wksAutospace) * 2 +
            integer(WinKeySettings.wksPaddleSwap) * 8;

          if WinKeySettings.wksKeyerMode = kmIambicA then TempInteger := TempInteger + 16;
          if WinKeySettings.wksKeyerMode = kmUltimatic then TempInteger := TempInteger + 32;
          if WinKeySettings.wksKeyerMode = kmBugMode then TempInteger := TempInteger + 48;

//1000 0100
          WinKeySettings.wksValueList.vlModeRegister := TempInteger;
//          showint(tCB_GETCURSEL(hwnddlg, 116) + 34);

          for c := 1 to wkRange do
          begin
            TempInteger := Windows.GetDlgItemInt(hwnddlg, 100 + High(WK2ComboSettingsNamesArray) + High(WK2SettingsNamesArray) + length(WK2ComboSettingsNamesArray) + length(WK2SliderLabelArray) + c, lpTranslated, False);
            if TempInteger <= WK2UpDownUpperValue[c] then
              if TempInteger >= WK2UpDownLowerValue[c] then
                WK2UpDownValue[c]^ := Byte(TempInteger);
          end;

          wkClose;
          wkOpen;
          goto ExitAndClose;
        end;

        if (HiWord(wParam) in [CBN_SELCHANGE {, BN_CLICKED}]) or (HiWord(wParam) = EN_CHANGE) then EnableWindowTrue(hwnddlg, 1);
        if HiWord(wParam) = BN_CLICKED then if LoWord(wParam) = 101 then
          begin
            1:
            TempInteger := TF.SendDlgItemMessage(hwnddlg, 101, BM_GETCHECK);
            for c := 102 to 124 + 3 do Windows.EnableWindow(GetDlgItem(hwnddlg, c), LongBool(TempInteger));
            if not wk2 then
            begin
              TF.EnableWindowFalse(hwnddlg, 107);
            end;
          end;
      end;

    WM_CLOSE:
      begin
        ExitAndClose:
        EndDialog(hwnddlg, 0);
      end;

  end;
end;

procedure wkReadThreadProc;
label
  1, 2;
var
  lpNumberOfBytesRead                   : DWORD;
  i                                     : integer;
begin
  wkActive := True;
  wkDispayState;
  while wkActive = True do
  begin
    if not wkSendNextByteFromHostBuffer then

    begin
      Windows.ReadFile(WinKeyHandle, wkThreadReadBuffer, SizeOf(wkThreadReadBuffer), lpNumberOfBytesRead, nil);
      if lpNumberOfBytesRead > 0 then
        for i := 0 to lpNumberOfBytesRead - 1 do
        begin
{$IF K6VVA_WK_DEBUG}
          wkWriteToDebugFile(Char(wkThreadReadBuffer[i]), False);
{$IFEND}

          if (wkThreadReadBuffer[i] and $C0) = $C0 then
          begin

//216 - 11011000
//220 - 11011100

//227 - 11100011
//192 - 11000000
//196 - 11000100
//198 - 11000110

          {it?s a status byte. (Host may or may not have asked for it.)process status change, note that it could be a pushbutton change}
{$IF WINKEYDEBUG}
            AddStringToTelnetConsole(PChar(string('status byte ' + IntToStr(wkThreadReadBuffer[i]))), tstSend);
//            sWriteFile(wkDebugFileRX, wkThreadReadBuffer[I], 1);
{$IFEND}
    {(*}
            wkBUSY    := (wkThreadReadBuffer[I] and (1 shl 2)) <> 0;
            wkBREAKIN := (wkThreadReadBuffer[I] and (1 shl 1)) <> 0;
            wkXOFF    := (wkThreadReadBuffer[I] and (1 shl 0)) <> 0;
    {*)}

{$IF WINKEYDEBUG}
            if wkBUSY then AddStringToTelnetConsole('YES', tstSend)
            else
              AddStringToTelnetConsole('NO', tstSend);

{$IFEND}

            ActiveRadioPtr.tPTTStatus := PTTStatusType(wkBUSY);
            logger.debug('PTTStatus=WKBUSY');
            // logger.debug('Exiting ParametersOkay early: ExchangeString=<%s>',[ExchangeString]);

            SendStationStatus(sstPTT);

          if not wkBUSY then
            begin
              logger.debug('PTTStatus=WK-NOT-BUSY');
              wkWaitingBytesInWK := 0;
//              wkHostBufferIndex := 0;
//              wkHostBufferSendIndex := 0;
//              wkWaitingBytesInHost := 0;
              if not tStartAutoCallTerminate(wkThreadID) then tStartAutoCQ;
             BackToInactiveRadioAfterQSO;
            end;
          end
          else
            if (wkThreadReadBuffer[i] and $C0) = $80 then
            begin
            {it?s a speed pot byte (Host may or may not have asked for it.) process speed pot change}
{$IF WINKEYDEBUG}
//              AddStringToTelnetConsole('speed pot byte');
{$IFEND}
              if not WinKeySettings.wksIgnoreSpeedSpot then
              begin
                SetSpeed(wkThreadReadBuffer[i] - 128 + wkMINWPM);
                DisplayCodeSpeed;
              end;
            end
            else
            begin

              begin
                if wkWaitingBytesInWK > 0 then dec(wkWaitingBytesInWK);
              end;
{$IF WINKEYDEBUG}
//              AddStringToTelnetConsole(PChar(string('> RX ' + CHR(wkThreadReadBuffer[I]))));
{$IFEND}
            end;
        end;

    end;
  end;
end;

procedure wkReadThreadProc1;
label
  1, 2;
var
  lpNumberOfBytesRead                   : DWORD;
  i                                     : integer;
begin
  wkActive := True;
  wkDispayState;

  while wkActive = True do
  begin
    Windows.ReadFile(WinKeyHandle, wkThreadReadBuffer, SizeOf(wkThreadReadBuffer), lpNumberOfBytesRead, nil);
    if lpNumberOfBytesRead = 0 then
    begin
      wkSendNextByteFromHostBuffer;
      goto 1;
    end;

    for i := 0 to lpNumberOfBytesRead - 1 do
    begin
{$IF WINKEYDEBUG}
      if wkThreadReadBuffer[i] >= $C0 then
      begin

      end
      else
//        sWriteFile(wkDebugFileRX, wkThreadReadBuffer[I], 1);
{$IFEND}
        if wkThreadReadBuffer[i] < $C0 then
        begin
{$IF WINKEYDEBUG}
//          AddStringToTelnetConsole(PChar(string('> RX ' + CHR(wkThreadReadBuffer[i]))));
{$IFEND}
          if wkWaitingBytesInWK > 0 then dec(wkWaitingBytesInWK);
//        wkSendNextByteFromHostBuffer;
          wkBUSY := True;
        end
        else
        begin
{$IF WINKEYDEBUG}
//          AddStringToTelnetConsole(PChar(string('> C0 ' + IntToStr(wkThreadReadBuffer[i]))));
{$IFEND}
        end;

      if wkThreadReadBuffer[i] = 192 then
      begin
{$IF WINKEYDEBUG}
//        AddStringToTelnetConsole('BUFFER=end');
{$IFEND}
        wkBUSY := False;
        wkWaitingBytesInWK := 0;
//        wkHostBufferIndex := 0;
        wkWaitingBytesInHost := 0;
        if tr4w_PTTStartTime <> 0 then tRestartInfo.riPTTOnTotalTime := tRestartInfo.riPTTOnTotalTime + GetTickCount - tr4w_PTTStartTime;
        tDispalyOnAirTime;
        wkPTTOn := False;
        if tAutoCQMode = True then
         begin
            
          tAutoCQTimerID := SetTimer(tr4whandle, AUTOCQ_TIMER_HANDLE, AutoCQDelayTime, @tAutoCQTimerProc);
         end;
      end;

      if (wkThreadReadBuffer[i] = 196) then
      begin
{$IF WINKEYDEBUG}
//        AddStringToTelnetConsole('START');
{$IFEND}
        if wkPTTOn = False then tr4w_PTTStartTime := GetTickCount;
        wkPTTOn := True;
      end;

{$IF WINKEYDEBUG}
      if (wkThreadReadBuffer[i] = 198) then
      begin
//        AddStringToTelnetConsole('PADDLE');
//        wkHostBufferIndex := 0;
        wkWaitingBytesInHost := 0;
        wkWaitingBytesInWK := 0;
      end;
{$IFEND}

      if (wkThreadReadBuffer[i] and $C0) = $80 then if not WinKeySettings.wksIgnoreSpeedSpot then
        begin
          SetSpeed(wkThreadReadBuffer[i] - 128 + wkMINWPM);
          DisplayCodeSpeed;
        end;
    end;
{$IF WINKEYDEBUG}
//    Windows.SetWindowText(InsertWindowHandle, inttopchar(wkWaitingBytesInWK));
{$IFEND}
    1:
    Sleep(0);
  end;
end;

procedure wkDispayState;
begin
  Windows.EnableWindow(wh[mweWinKey], wkActive);
end;

procedure wkAddCharToHostBuffer(c: Char);
begin

{$IF WINKEYDEBUG}
//  AddStringToTelnetConsole(PChar(string(c)));
{$IFEND}
  logger.Trace('[wkAddCharToHostBuffer] char=%s (ord=%d $%s)',
              [string(c), Ord(c), IntToHex(Ord(c), 2)]);
  wkInternalCWBuffer[wkHostBufferIndex] := c;
  inc(wkHostBufferIndex);
  if wkHostBufferIndex = SizeOfHostBuffer then wkHostBufferIndex := 0;
  inc(wkWaitingBytesInHost);
 
end;

procedure wkAddCWMessageToInternalBuffer(Msg: Str160);

  procedure CheckSpeedChange;
  begin
    if wkSpeedUp <> 0 then
    begin
      wkCWSpeed := round(wkCWSpeed * (1 + (0.06 * wkSpeedUp)));
      wkAddCharToHostBuffer(wkCMD_CHANGESPEEDBUFFERED);
      wkAddCharToHostBuffer(CHR(wkCWSpeed));
      wkSpeedUp := 0;
    end;

    if wkSpeedDown <> 0 then
    begin
      wkCWSpeed := round(wkCWSpeed * (1 - (0.06 * wkSpeedDown)));
      wkAddCharToHostBuffer(wkCMD_CHANGESPEEDBUFFERED);
      wkAddCharToHostBuffer(CHR(wkCWSpeed));
      wkSpeedDown := 0;
    end;
  end;

var
  i                                     : integer;
begin
  if length(Msg) = 0 then
  Exit;

  logger.Debug('[wkAddCWMessageToInternalBuffer] Msg="%s" len=%d', [Msg, length(Msg)]);

  for i := 1 to length(Msg) do
  begin
    if Msg[i] in ['A'..'Z', ' ', '0'..'9','.', '/', '?'] then
    begin
      CheckSpeedChange;
      wkAddCharToHostBuffer(Msg[i]);

    end;

    if Msg[i] = '^' then wkAddCharToHostBuffer('|');
    if Msg[i] = #$06 then inc(wkSpeedUp);
    if Msg[i] = #$13 then inc(wkSpeedDown);
  end;
  CheckSpeedChange;
end;

procedure wkSetKeyerOutput(r: RadioPtr);
var
  TempByte                              : Byte;
const
  WK_RADIO_ONE                          = 4;
  WK_RADIO_TWO                          = 8;
  WK_CW_MODE                            = 1;
begin
  if WinKeyHandle = INVALID_HANDLE_VALUE then Exit;
  if r = @Radio1 then TempByte := WK_RADIO_ONE else TempByte := WK_RADIO_TWO;
  if r.ModeMemory <> Phone then TempByte := TempByte + WK_CW_MODE;

 // if r = RadioOne then TempByte := 4 {+ 1} else TempByte := 8 {+ 1};
  TempByte := TempByte + Byte(WinKeySettings.wksSideTEnable) * 2;
  wkSendTwoBytes(wkCMD_SETPINCONFIG, TempByte);
end;

function wkOpenPort: boolean;
var
  msg: string;
begin
  Result := False;
  // Issue #997: asm wsprintf-push -> TF.Format (_COM = '\\.\COM%u', same as
  // tree.pas). wksWinKey2Port is a PortType enum -> Ord = the port number.
  Format(@wkREADBuffer, _COM, Ord(WinKeySettings.wksWinKey2Port));
  WinKeyHandle := CreateFile(@wkREADBuffer, GENERIC_READ or GENERIC_WRITE, 0, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL {FILE_FLAG_OVERLAPPED}, 0);
  if WinKeyHandle = INVALID_HANDLE_VALUE then
  begin
    // SysErrorMessage returns an AnsiString via a hidden var-parameter, not in
    // eax. Assign to a local so the string data remains alive, then build the
    // full message with SysUtils.Format. No inline asm / varargs juggling.
    msg := Format('Winkeyer port COM%d: %s',
                  [Integer(WinKeySettings.wksWinKey2Port),
                   SysErrorMessage(GetLastError)]);
    showwarning(PChar(msg));
    Exit;
  end;
  GetCommState(WinKeyHandle, wkDCB);
  wkDCB.BaudRate := CBR_1200;
  wkDCB.StopBits := ONESTOPBIT;
  wkDCB.Parity := NOPARITY;
  wkDCB.ByteSize := 8;
  wkDCB.Flags := dcb_DtrControlEnable;
  SetCommState(WinKeyHandle, wkDCB);

//  wklpOverlapped.hEvent := Windows.CreateEvent(nil, True, False, nil);
//  SetCommMask(WinKeyHandle, EV_RXCHAR);

  Windows.ZeroMemory(@wklpCommTimeouts, SizeOf(TCommTimeouts));
  wklpCommTimeouts.ReadTotalTimeoutConstant := 250;
  SetCommTimeouts(WinKeyHandle, wklpCommTimeouts);
  Sleep(200);
  PurgeComm(WinKeyHandle, PURGE_RXCLEAR);
  Result := True;
end;

function wkSendNextByteFromHostBuffer: boolean;
var
  BytesSendNow                          : integer;
begin
  Result := False;
  if wkWaitingBytesInHost <= 0 then Exit;

  BytesSendNow := 0;
  while BytesSendNow < 5 do
  begin
    if wkWaitingBytesInHost <= 0 then Exit;
{!!!}
{$IF NOT K6VVA_WK_DEBUG}
//    if wkXOFF then Exit;
{$IFEND}

    logger.Trace('[wkSendNextByteFromHostBuffer] sending char=%s (ord=%d $%s)',
                 [string(wkInternalCWBuffer[wkHostBufferSendIndex]),
                  Ord(wkInternalCWBuffer[wkHostBufferSendIndex]),
                  IntToHex(Ord(wkInternalCWBuffer[wkHostBufferSendIndex]), 2)]);
    wkSendByte(Ord(wkInternalCWBuffer[wkHostBufferSendIndex]));

{$IF K6VVA_WK_DEBUG}
    CID_TWO_BYTES[0] := wkInternalCWBuffer[wkHostBufferSendIndex];
    AddStringToTelnetConsole(CID_TWO_BYTES);
{$IFEND}

    if wkWaitingBytesInHost > 0 then dec(wkWaitingBytesInHost);
    inc(BytesSendNow);
    inc(wkHostBufferSendIndex);
    if wkHostBufferSendIndex >= SizeOfHostBuffer then wkHostBufferSendIndex := 0;
{$IF WINKEYDEBUG}
    Windows.SetWindowText(InsertWindowHandle, inttopchar(wkHostBufferSendIndex));
{$IFEND}
    inc(wkWaitingBytesInWK);
    Result := True;
    ;

  end;
end;

procedure wkSwapTune;
begin
  wkSendTwoBytes(wkCMD_KEYIMMEDIATE, Byte(not wkBUSY));
end;

procedure wkWriteToDebugFile(b: Char; TX: boolean);
const
  InOutArray                            : array[boolean] of PChar = ('RX <', 'TX >');
  InOutClassArray                       : array[boolean] of PChar = ('RX', 'TX');
{$IF K6VVA_WK_DEBUG}
var
  lpNumberOfBytesWritten                : Cardinal;
  DirectionChar                         : PChar;
  ClassName                             : PChar;
{$IFEND}
begin
{$IF K6VVA_WK_DEBUG}
  inc(wkDebugFileRecordNumber);
  DirectionChar := InOutArray[TX];
  ClassName := InOutClassArray[TX];
  if Ord(b) > 150 then ClassName := 'ST';
  asm
  xor eax,eax
  mov al,byte ptr b
  push eax
  push eax
  push DirectionChar
  call windows.GetTickCount
  push eax
  push wkDebugFileRecordNumber
  push ClassName
  end;
  lpNumberOfBytesWritten := wsprintf(wkDebugBuffer, '<TR CLASS=%s><TD>%u</TD><TD>%u</TD><TD>%s</TD><TD>%#02x</TD><TD><b>%C</b></TD></TR>');
  asm add esp,32
  end;

  sWriteFile(wkDebugFileTX, wkDebugBuffer, lpNumberOfBytesWritten);
{$IFEND}
end;

{$IF K6VVA_WK_DEBUG}
begin
  Tree.tOpenFileForWrite(wkDebugFileTX, 'wkDebug.html');
  sWriteFile(wkDebugFileTX, wkDebugFileHeader, length(wkDebugFileHeader));
{$IFEND}
end.

