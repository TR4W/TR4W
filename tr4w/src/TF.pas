{ Copyright Dmitriy Gulyaev UA4WLI 2015.

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
unit TF;
{$IMPORTEDDATA OFF}
interface

uses

  VC,
  utils_text,
  Windows,
  SysUtils,
  ActiveX,
  Messages;

type
  TServerBrowseDialogA0 = function(HWND: HWND; pchBuffer: Pointer; cchBufSize: DWORD): BOOL; stdcall;

type
  MYDLGTEMPLATE = packed record
   {04}Style: DWORD;
   {04}dwExtendedStyle: DWORD;
   {02}cdit: Word;
   {02}X: SHORT;
   {02}Y: SHORT;
   {02}cx: SHORT;
   {02}cy: SHORT;
{18}
{04}d: Word;
{
b:byte;
b2:byte;
bbb: array[0..5] of Byte;
c80: array[0..3] of Byte;
    fn: array[0..170] of Char;
  }end;

  TEnumLinesFunc = procedure(Line: PShortString);

  TShellexecuteFunc = function(HWND: HWND; Operation, FileName, Parameters, Directory: PChar; showCmd: integer): hInst; stdcall;

  //function Shellexecute(HWND: HWND; Operation, FileName, Parameters, Directory: PChar; showCmd: integer): hInst; stdcall;
const
  LB_STYLE_1                            = LBS_NOTIFY or LBS_OWNERDRAWFIXED or LBS_NOINTEGRALHEIGHT or LBS_MULTICOLUMN or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_TABSTOP;
  LB_STYLE_2                            = LBS_NOTIFY or LBS_OWNERDRAWFIXED or LBS_HASSTRINGS or LBS_NOINTEGRALHEIGHT or LBS_MULTICOLUMN or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_HSCROLL or WS_TABSTOP;
  LB_STYLE_3                            = LBS_NOTIFY or LBS_MULTIPLESEL or LBS_HASSTRINGS or LBS_NOINTEGRALHEIGHT or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP;

  Ten                                   : Double = 10.0;
  Layout                                : array[0..9] of Char = ('0', '0', '0', '0', '0', '4', '0', '9', #0, #0);
  UNKNOWNTYPE                           = 255;
const
  LISTVIEW                              = 'SysListView32';
  ES_SAVESEL                            = $00008000;
var
//  StrCompCOUNT                     : integer;
  tempDLGTEMPLATE                       : MYDLGTEMPLATE;
  Shell32LibHandle                      : DWORD;
  ButtonPChar                           : PChar = 'Button';
  StaticPChar                           : PChar = 'STATIC';
  COMBOBOX                              : PChar = 'COMBOBOX';
  EditPChar                             : PChar = 'Edit';
  LISTBOX                               : PChar = 'LISTBOX';

  wsprintfBuffer                        : array[0..4096 - 1] of Char;
  tempprintfBuffer                      : array[0..4096 - 1] of Char;   // To use with wsPrintfBuffer Issue 601 ny4i
  MillisecondsBuffer                    : array[0..31] of Char;
  QuickDisplayBuffer                    : array[0..255] of Char;
  TempBuffer1                           : array[0..255] of Char;
  TempBuffer2                           : array[0..255] of Char;
  SetDlgItemTextBuffer                  : array[0..255] of Char;
  TelnetBuffer                          : array[0..4096 * 5 - 1] of Char;
  spotsBuffer                            : array[0..4096 * 5 - 1] of Char;
  NetBuffer                             : array[1..4096] of Char;
  SyncNetBuffer                         : array[0..4096 - 1] of Char;
  SYSERRORBUFFER                        : array[0..255] of Char;

  GETREALPATHBUFFER                     : array[0..255] of Char;

  LogDisplayBuffer                      : array[0..128 - 1] of Char;
  IntToPCharBuffer                      : array[0..15] of Char;
  FreqToPCharBuffer                     : array[0..15] of Char;

  GetDateFormatBuffer                   : array[0..31] of Char;

  GetTimeStringBuffer                   : array[0..31] of Char;
  SystemTimeToStringBuffer              : array[0..31] of Char;
  GetFullTimeStringBuffer               : array[0..31] of Char;
  GetYearStringBuffer                   : array[0..7] of Char;
  GetDateStringBuffer                   : array[0..15] of Char;
  IQPrompt                              : array[0..63] of Char;

function CreateRichEdit(hwndParent: HWND): HWND;
function Createmsctls_progress32(X, Y, Width, Height: integer; hwndParent: HWND; HMENU: HMENU): HWND;

function CreateOwnerDrawListBox(dwStyle: DWORD; hwndParent: HWND): HWND;
function EnumerateLinesInFile(FileName: PChar; Func: TEnumLinesFunc; UpperCase: boolean): boolean;
function EnumerateLinesInFile_old(FileName: PChar; Func: TEnumLinesFunc; UpperCase: boolean): boolean;
function tGetDateFormat(DT: TQSOTime): PChar; //assembler;
procedure UnableToFindFileMessage(FileName: PChar);
function DeleteSlashes(p: PChar): PChar;
function SetParameterInArray(ArrayPtr: PInteger; ArrayLength: integer; aVar: PInteger; ValueToSet: integer): boolean;
function GetGUID: string;
function GetValueFromArray(PCharArrayAddress: PChar; ArraySize: Byte; CMD: PChar): Byte;
function StrPos(const Str1, Str2: PChar): PChar;
function StrPosPartial(const Str1, Str2: PChar): PChar;
function GetDialogItemText(h: HWND; Control: integer): ShortString;
function GetNumberFromCharBuffer(p: PChar): integer;
procedure tLoadKeyboardLayout;
function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer;
function GetContestFromString(ContestString: ShortString): ContestType;
function STToInt64(St: SYSTEMTIME): int64;
function RealToStr(Num: REAL): string;
function RealToStr2(Num: REAL): string;
function IntToStr(Num: integer): ShortString;
function StrToInt(s: ShortString): integer;
function PCharToInt(p: PChar): integer;
function BooleanToStr(b: boolean): string;
//function CenterString(s: string; count: byte): string;
procedure strU(var Str: ShortString);
procedure SetMainWindowText(Window: TMainWindowElement; Text: PChar);
function IntegerBetween(v: integer; i: integer; k: integer): boolean;

function ValExt(Source: PChar; var code: integer): extended;

function tCreateThread(lpStartAddress: TFNThreadStartRoutine; var lpThreadId: DWORD; Quiet: boolean = False): THandle;

//function tgethostbyname(h_Name: PChar): PChar;
function tDialogBox(WindowID: Byte; WinProcAdr: Pointer): integer;
function tWM_SETFONT(h: HWND; Font: HFONT): HWND;
procedure tLB_SETCOLUMNWIDTH(h: HWND; Width: integer);
function tLB_GETCURSEL(h: HWND): integer;
function tLB_SETCURSEL(h: HWND; pos: wParam): integer;
procedure tCB_SETCURSEL(ParentHandle: HWND; Control: integer; pos: Cardinal);
procedure tCB_ADDSTRING(ParentHandle: HWND; Control: integer; s: string);
procedure tCB_ADDSTRING_PCHAR(ParentHandle: HWND; Control: integer; s: PChar);
function tLB_ADDSTRING(h: HWND; Text: PChar): integer;
function tLB_RESETCONTENT(h: HWND): integer;
function tCB_GETCURSEL(ParentHandle: HWND; Control: integer): integer;

procedure tSetWindowText(WindowHandle: HWND; s: string);
procedure tSetWindowRedraw(wnd: HWND; Redraw: boolean);
function SystemTimeToString(SysTime: SYSTEMTIME): PChar;
procedure SelectParentDir(h: HWND);

//function StrLen(const Str: PChar): Cardinal;
function tWindowsExist(wID: WindowsType): boolean;

function GetWindowByHandle(h: HWND): WindowsType;

procedure tEnableMenuItem(uIDEnableItem: UINT; uEnable: UINT);


function SysErrorMessage(ErrorCode: Cardinal): PChar;
procedure showwarning(Text: PChar);
procedure ShowSysErrorMessage(ID: PChar);


//function tr4w_GetTimeString: PChar;
function RITFreqToPchar(i: integer): PChar;
function FreqToPChar(i: integer): PChar;
function FreqToPChar2(i: integer): PChar;
function FreqToPCharWithoutHZ(i: integer): PChar;
function kHzToPChar(Freq: Word): PChar;
//function InitSysMonthCal32: boolean;
function BitmapFromIcon(Handle: HWND; i: HICON): HBITMAP;
function ExtractBigIcon(IconIndex: integer): HICON;
function MillisecondsToFormattedString(msecs: Cardinal; WithMsec: boolean): PChar;

//function Pos(Substr: string; S: string): Integer;
function ArrayToString(const a: array of Char): string;
procedure InvertBoolean(var b: boolean);
function inttopchar(i: integer): PChar;
function inttopcharHEX(i: integer): PChar;
procedure DragWindow(h: HWND);
//procedure SaveStructure(Address: Pointer; Count: integer; FileName: string);
function SetLink(HWindow: HWND; Link: PChar): BOOL;
procedure EnableWindowTrue(h: HWND; nIDDlgItem: integer);
procedure EnableWindowFalse(h: HWND; nIDDlgItem: integer);
function _StrInt64(Val: int64; Width: integer): ShortString;
function ShowServerDialog(AHandle: THandle): string;
//function tShellexecute(HWND: HWND; Operation, FileName, Parameters, Directory: PChar; showCmd: integer): hInst; // 4.75.3
function tSetDlgItemIntFalse(hDlg: HWND; nIDDlgItem: integer; uValue: UINT): BOOL; stdcall;
function tSetDlgItemIntSigned(hDlg: HWND; nIDDlgItem: integer; uValue: integer): BOOL; stdcall;
function CreateModalDialog(Width, Height: integer; ParentHWND: HWND; lpDialogFunc: TFNDlgProc; dwInitParam: lParam): integer;
function CreateListBox(X, Y, nWidth, nHeight: Word; hwndParent: HWND; HMENU: HMENU): HWND;
function CreateButton(dwStyle: Cardinal; lpWindowName: PChar; X, Y, nWidth: integer; hwndParent: HWND; HMENU: HMENU): HWND;
function CreateStatic(lpWindowName: PChar; X, Y, nWidth: integer; hwndParent: HWND; HMENU: HMENU): HWND;
function CreateEdit(dwStyle: Cardinal; X, Y, Width, Height: integer; hwndParent: HWND; HMENU: HMENU): HWND;
function CreateListView2(X, Y, nWidth, nHeight: Word; hwndParent: HWND): HWND;
function CreateComboBox(hwndParent: HWND; HMENU: HMENU): HWND;
function SendDlgItemMessage(hDlg: HWND; nIDDlgItem: integer; Msg: UINT): LONGINT; stdcall;

function tOpenFileForRead(var h: HWND; FileName: PChar): boolean;

procedure GetTime(var Hour, Minute, Second, Sec100: Word);
procedure GetDate(var Year, Month, Day, DayOfWeek: Word);

{$EXTERNALSYM Format}
function Format(Output: PChar; Format: PChar; c: Char): integer; overload; cdecl; overload;

function Format(Output: PChar; Format: PChar; s1: PChar; u1: integer; u2: integer; u3: integer; u4: integer; u5: integer; u6: integer; s2: PChar; s3: PChar): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; p4: PChar): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; p4: PChar; p5: PChar): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; i: integer): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; i: integer; i2: integer): integer; overload; cdecl; overload;

function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; i: integer): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar): integer; overload; cdecl; overload;

function Format(Output: PChar; Format: PChar; i: integer; i2: integer; i3: integer): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; i: integer; i2: integer; p: PChar): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; i: integer): integer; overload; cdecl; overload;
function Format(Output: PChar; Format: PChar; i: integer; i2: integer): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; i: integer; p: PChar): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; i: integer): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; i: integer; i2: integer): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; p: PChar; i: integer; P2: PChar): integer; cdecl; overload;
function Format(Output: PChar; Format: PChar; i: integer; p: PChar; i2: integer): integer; cdecl; overload;

function Format(Output: PChar; Format: PChar; P1, P2, p3, p4, p5, p6, p7: PChar): integer; cdecl; overload;
//function pos(Substr: string; s: string): integer;
const
  shell32                               = 'shell32.dll';
  { $ E X TERNALSYM Shell Execute}
  //function Shellexecute(HWND: HWND; Operation, FileName, Parameters, Directory: PChar; showCmd: integer): hInst; stdcall;
  { $ E X TERNALSYM Extract IconEx }
  //function ExtractIconEx(lpszFile: PChar; nIconIndex: integer; var phiconLarge, phiconSmall: HICON; nIcons: UINT): UINT; stdcall;

implementation

uses MainUnit, uFreqTimeFormat, uStrSearch;   // Issue #997: freq/time formatters + PChar search helpers extracted + golden-tested
function Format(Output: PChar; Format: PChar; c: Char): integer; external user32 Name 'wsprintfA';

function Format(Output: PChar; Format: PChar; s1: PChar; u1: integer; u2: integer; u3: integer; u4: integer; u5: integer; u6: integer; s2: PChar; s3: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; p4: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; p4: PChar; p5: pChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; i: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; p3: PChar; i: integer; i2: integer): integer; external user32 Name 'wsprintfA';

function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar; i: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; P2: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar): integer; external user32 Name 'wsprintfA';

function Format(Output: PChar; Format: PChar; i: integer; i2: integer; i3: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; i: integer; i2: integer; p: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; i: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; i: integer; i2: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; i: integer; p: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; i: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; i: integer; i2: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; p: PChar; i: integer; P2: PChar): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; i: integer; p: PChar; i2: integer): integer; external user32 Name 'wsprintfA';
function Format(Output: PChar; Format: PChar; P1, P2, p3, p4, p5, p6, p7: PChar): integer; external user32 Name 'wsprintfA';
//uses mainunit;

function SysErrorMessage(ErrorCode: Cardinal): PChar;
begin
  FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, ErrorCode, 0, SYSERRORBUFFER, SizeOf(SYSERRORBUFFER), nil);
  Result := SYSERRORBUFFER;
end;

procedure showwarning(Text: PChar);
begin
  logger.Warn(Text);
  MessageBox(0, Text, tr4w_ClassName, MB_OK or MB_ICONWARNING or MB_SYSTEMMODAL or MB_TOPMOST);
end;

function FreqToPChar2(i: integer): PChar;
begin
  Format(FreqToPCharBuffer, '%u.%u', i div 1000, (i mod 1000) div 100);
  Result := FreqToPCharBuffer;
end;

function RITFreqToPchar(i: integer): PChar;
var absI: integer;
begin  // This does not handle negative numbers very well.
   if i < 0 then
      begin
      absI := i * -1;
      Format(FreqToPCharBuffer, '-%u.%02u', absI div 1000, (absI mod 1000) div 10); // %02u zero-pads hundredths: -1080 -> "-1.08", not "-1. 8"
      end
   else
      begin
      Format(FreqToPCharBuffer, '%d.%02u', i div 1000, (abs(i) mod 1000) div 10); // %02u zero-pads hundredths: 2060 -> "2.06", not "2. 6"
      end;
   Result := FreqToPCharBuffer;
end;

function FreqToPChar(i: integer): PChar;
begin
  // Issue #997: extracted to uFreqTimeFormat (golden-master tested).
  Result := uFreqTimeFormat.FreqToPChar(i);
end;

function FreqToPCharWithoutHZ(i: integer): PChar;
begin
  Result := uFreqTimeFormat.FreqToPCharWithoutHZ(i);   // Issue #997: extracted
end;

function kHzToPChar(Freq: Word): PChar;
begin
  Result := uFreqTimeFormat.kHzToPChar(Freq);   // Issue #997: extracted
end;

function ArrayToString(const a: array of Char): string;
begin
  if Length(a)>0 then
    SetString(Result, PChar(@a[0]), Length(a))
  else
    Result := '';
end;

{
function InitSysMonthCal32: boolean;
var
  icex                                  : TInitCommonControlsEx;
begin
  icex.dwSize := SizeOf(icex);
  icex.dwICC := ICC_DATE_CLASSES;
  Result := INITCOMMONCONTROLSEX(icex);
end;
}

function GetGUID: string;   // Returns 32-char lowercase hex, no dashes or braces
var
   MyGUID: TGUID;
begin
   Result := '';
   if CreateGUID(MyGUID) <> S_OK then
      begin
      logger.Warn('Could not create GUID');
      Exit;
      end;
   Result := LowerCase(
      Format('%.8x%.4x%.4x%.2x%.2x%.2x%.2x%.2x%.2x%.2x%.2x',
         [MyGUID.D1, MyGUID.D2, MyGUID.D3,
          MyGUID.D4[0], MyGUID.D4[1], MyGUID.D4[2], MyGUID.D4[3],
          MyGUID.D4[4], MyGUID.D4[5], MyGUID.D4[6], MyGUID.D4[7]]));
   logger.Debug('GUID created %s', [Result]);
end;


function BitmapFromIcon(Handle: HWND; i: HICON): HBITMAP;
var
  winDC, srcdc, destdc                  : HDC;
  OldBitmap                             : HBITMAP;
  iinfo                                 : TICONINFO;
begin
  GetIconInfo(i, iinfo);
  winDC := GetDC(Handle);
  srcdc := CreateCompatibleDC(winDC);
  destdc := CreateCompatibleDC(winDC);
  OldBitmap := SelectObject(srcdc, iinfo.hbmMask);
  BitBlt(destdc, 11, 1, 16, 16, srcdc, 0, 0, SRCPAINT);
  Result := SelectObject(destdc, OldBitmap);
  DeleteDC(destdc);
  DeleteDC(srcdc);
  DeleteDC(winDC);
end;

function ExtractBigIcon(IconIndex: integer): HICON;
var
  BigIcon                               : HICON;
begin
  //     ExtractIconEx('shell32.dll', IconIndex, BigIcon, SmallIcon, 1);
  Result := BigIcon {SmallIcon};
end;

function MillisecondsToFormattedString(msecs: Cardinal; WithMsec: boolean): PChar;
begin
  // Issue #997: extracted to uFreqTimeFormat (golden-master tested).
  Result := uFreqTimeFormat.MillisecondsToFormattedString(msecs, WithMsec);
  //  MessageBox(0, Result, '���������', MB_OK);

end;

procedure InvertBoolean(var b: boolean);
begin
  b := not b;
end;

function inttopchar(i: integer): PChar;
begin
  Format(IntToPCharBuffer, '%d', i);
  Result := IntToPCharBuffer;
end;

function inttopcharHEX(i: integer): PChar;
begin
  Format(IntToPCharBuffer, '%#x', i);
  Result := IntToPCharBuffer;
end;

procedure DragWindow(h: HWND);
begin
  PostMessage(h, WM_SYSCOMMAND, $F012, 0);
end;

function tWM_SETFONT(h: HWND; Font: HFONT): HWND;
begin
  SendMessage(h, WM_SETFONT, wParam(Font), 0);
  Result := h;
end;

procedure tLB_SETCOLUMNWIDTH(h: HWND; Width: integer);
begin
  if h = 0 then Exit;
  Windows.SendDlgItemMessage(h, 101, LB_SETCOLUMNWIDTH, wParam(Width), 0);
end;

function tLB_GETCURSEL(h: HWND): integer;
begin
  Result := SendMessage(h, LB_GETCURSEL, 0, 0);
end;

function tLB_SETCURSEL(h: HWND; pos: wParam): integer;
begin
  Result := SendMessage(h, LB_SETCURSEL, pos, 0);
end;

procedure tCB_SETCURSEL(ParentHandle: HWND; Control: integer; pos: Cardinal);
begin
  Windows.SendDlgItemMessage(ParentHandle, integer(Control), CB_SETCURSEL, wParam(pos), 0);
end;

function tCB_GETCURSEL(ParentHandle: HWND; Control: integer): integer;
begin
  Result := SendDlgItemMessage(ParentHandle, integer(Control), CB_GETCURSEL);
end;

procedure tCB_ADDSTRING(ParentHandle: HWND; Control: integer; s: string);
begin
  Windows.SendDlgItemMessage(ParentHandle, integer(Control), CB_ADDSTRING, 0, integer(PChar(s)));
end;

procedure tCB_ADDSTRING_PCHAR(ParentHandle: HWND; Control: integer; s: PChar);
begin
  Windows.SendDlgItemMessage(ParentHandle, integer(Control), CB_ADDSTRING, 0, integer(s));
end;

function tLB_ADDSTRING(h: HWND; Text: PChar): integer;
begin
  Result := -1;
  if h = 0 then Exit;
  Result := SendMessage(h, LB_ADDSTRING, 0, integer(Text));
end;

function tLB_RESETCONTENT(h: HWND): integer;
begin
  if h = 0 then Exit;
  Result := SendMessage(h, LB_RESETCONTENT, 0, 0);
end;

{------------------------------------------------------------------}
{  Function to convert int to string. (No sys utils = smaller EXE)  }
{------------------------------------------------------------------}
{
function RealToInt(Num: REAL): integer;

begin

   Result := StrToInt(RealToStr(Num));
end;
}

function RealToStr(Num: REAL): string;
begin
  //procedure Str(X [: Width [: Decimals ]]; var S);
  Str(Num: 0: 0, Result);
end;

function RealToStr2(Num: REAL): string;
begin
  //procedure Str(X [: Width [: Decimals ]]; var S);
  Str(Num: 2: 2, Result);
end;

function IntToStr(Num: integer): ShortString;
begin
  Str(Num, Result);
end;

function BooleanToStr(b: boolean): string;
begin
   Result := 'FALSE';
   if b then
      begin
      Result := 'TRUE';
      end;
end;

{  Function to convert string to int. (No sys utils = smaller EXE)  }
{------------------------------------------------------------------}

function StrToInt(s: ShortString): integer;
var
  i1, i2                                : integer;
begin
  //   Result := StrToInt32_JOH_IA32_7(s);

  Val(s, i1, i2);
  Result := i1;
end;

function PCharToInt(p: PChar): integer;
label
  1, 2;
var
  i                                     : integer;
  Negative                              : boolean;
begin
  Result := 0;
  i := 0;
  Negative := False;

  if p[i] = '-' then
  begin
    i := 1;
    Negative := True;
  end;

  1:
  if p[i] in ['0'..'9'] then Result := Result * 10 + (Ord(p[i]) - 48)
  else goto 2;
  inc(i);
  goto 1;
  2:
  if Negative then Result := Result * -1;
end;

{
function CenterString(s: string; count: byte): string;
begin
  RESULT := s;
  while length(RESULT) < count do
    RESULT := ' ' + RESULT + ' ';
end;
}

{
procedure AddStringsToComoBox(a: array);
begin

end;
}
{
procedure SaveStructure(Address: Pointer; Count: integer; FileName: string);
var
  FileHandle                            : HWND;
begin
  FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_NEW, FILE_ATTRIBUTE_ARCHIVE, 0);
  if FileHandle = INVALID_HANDLE_VALUE then
    FileHandle := CreateFile(PChar(FileName), GENERIC_WRITE, FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, 0);
  sWriteFile(FileHandle, Address, Count);
  CloseHandle(FileHandle);
end;
}
function SetLink(HWindow: HWND; Link: PChar): BOOL;
begin
  Result := SetProp(HWindow, 'LINKCURSOR', LONGINT(Link));
end;

procedure EnableWindowTrue(h: HWND; nIDDlgItem: integer);
begin
  Windows.EnableWindow(GetDlgItem(h, nIDDlgItem), True);
end;

procedure EnableWindowFalse(h: HWND; nIDDlgItem: integer);
begin
  Windows.EnableWindow(GetDlgItem(h, nIDDlgItem), False);
end;

{From System}

function _StrInt64(Val: int64; Width: integer): ShortString;
var
  d                                     : array[0..31] of Char; { need 19 digits and a sign }
  i, k                                  : integer;
  sign                                  : boolean;
  spaces                                : integer;
begin
  { Produce an ASCII representation of the number in reverse order }

  Windows.ZeroMemory(@Result, SizeOf(Result));
  i := 0;
  sign := Val < 0;
  repeat
    d[i] := CHR(Abs(Val mod 10) + Ord('0'));
    inc(i);
    Val := Val div 10;
  until Val = 0;
  if sign then
  begin
    d[i] := '-';
    inc(i);
  end;

  { Fill the Result with the appropriate number of blanks }
  if Width > 255 then
    Width := 255;
  k := 1;
  spaces := Width - i;
  while k <= spaces do
  begin
    Result[k] := ' ';
    inc(k);
  end;

  { Fill the Result with the number }
  while i > 0 do
  begin
    dec(i);
    Result[k] := d[i];
    inc(k);
  end;

  { Result is k-1 characters long }
  SetLength(Result, k - 1);

end;

function ShowServerDialog(AHandle: THandle): string;
var
  ServerBrowseDialogA0                  : TServerBrowseDialogA0;
  LANMAN_DLL                            : DWORD;
  Buffer                                : array[0..256] of Char;
  bLoadLib                              : boolean;
begin
  LANMAN_DLL := GetModuleHandle('NTLANMAN.DLL');
  if LANMAN_DLL = 0 then
  begin
    LANMAN_DLL := LoadLibrary('NTLANMAN.DLL');
    bLoadLib := True;
  end;
  if LANMAN_DLL <> 0 then
  begin
    @ServerBrowseDialogA0 := GetProcAddress(LANMAN_DLL, {'ShareAsDialogA0'} 'ServerBrowseDialogA0');
    ServerBrowseDialogA0(AHandle, @Buffer, 256);
      //         if Buffer[0] = '\' then
    begin
      Result := Buffer;
    end;
    if bLoadLib then
      FreeLibrary(LANMAN_DLL);
  end;
end;

{
function Pos(Substr: string; S: string): Integer;
begin
   Result := Pos_JOH_IA32_6(Substr,s);
end;
}

//function Shellexecute; EXTERNAL shell32 Name 'ShellExecuteA';
//function ExtractIconEx; EXTERNAL shell32 Name 'ExtractIconExA';
{
function tShellexecute(HWND: HWND; Operation, FileName, Parameters, Directory: PChar; showCmd: integer): hInst;
var
  SF                                    : TShellexecuteFunc;
begin
  if Shell32LibHandle = 0 then Shell32LibHandle := LoadLibrary('shell32.dll');
  if Shell32LibHandle <> 0 then
  begin
    @SF := GetProcAddress(Shell32LibHandle, 'ShellExecuteA');
    if @SF <> nil then
      RESULT := SF(HWND, Operation, FileName, Parameters, Directory, showCmd);
//    FreeLibrary(Shell32LibHandle);
  end;
end;
}

function STToInt64(St: SYSTEMTIME): int64;
var
  TEMPFILETIME                          : FILETIME;
begin
  Windows.SystemTimeToFileTime(St, TEMPFILETIME);
  Result := int64(TEMPFILETIME);
  Result := round(Result / 10000);
end;
{
function tgethostbyname(h_Name: PChar): PChar;
var
  myhostent                        : Phostent;
begin
  Result := nil;
  myhostent := WinSock2.gethostbyname(h_Name);
  if myhostent <> nil then Result := iNet_ntoa(PInAddr(myhostent^.h_addr_list^)^);
end;
}

procedure tSetWindowText(WindowHandle: HWND; s: string);
begin
  Windows.SetWindowText(WindowHandle, PChar(s));
end;

procedure tSetWindowRedraw(wnd: HWND; Redraw: boolean);
begin
  SendMessage(wnd, WM_SETREDRAW, integer(Redraw), 0);
end;

function SystemTimeToString(SysTime: SYSTEMTIME): PChar;
begin
  // Issue #997: extracted to uFreqTimeFormat (golden-master tested).
  Result := uFreqTimeFormat.SystemTimeToString(SysTime);
end;

function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer;
begin
  // Issue #997: extracted to uStrSearch (golden-master tested).
  Result := uStrSearch.StrComp_JOH_IA32_6(Str1, Str2);
end;

procedure tLoadKeyboardLayout;
begin
  // showint(loword(GetKeyboardLayout(0)));
  // 68748313 - $4190419-rus
  // 67699721 - $4090409-eng
  {
  Hello Dmitriy,

and thank you for considering adding the Scandinavian characters. The
value of GetKeyboardLayout = 1245108 .

> and please tell me value of 'GetKeyboardLayout = ' in caption of the
> main window in TR4W.

73 and Happy New Year!

Jari OH6BG
//  Showint(LoWord(1245108));//65460   - $FFB4
  }
//  if LoWord(GetKeyboardLayout(0)) = $0419 then
//     LoadKeyboardLayout('00000409', KLF_ACTIVATE);   // issue 178 force Latin
end;
{
procedure tSetDlgItemTypText(hDlg: HWND; nIDDlgItem: integer; lpString: PChar);
begin
  Windows.CopyMemory(@SetDlgItemTextBuffer, lpString + 1, Cardinal(lpString^));
  SetDlgItemTextBuffer[Cardinal(lpString^)] := #0;
  Windows.SetDlgItemText(hDlg, nIDDlgItem, SetDlgItemTextBuffer);
end;
}

function GetContestFromString(ContestString: ShortString): ContestType;
var
  TempContest                           : ContestType;
begin
  ContestString[Ord(ContestString[0]) + 1] := #0;
  for TempContest := Succ(DUMMYCONTEST) to High(ContestType) do
    if Windows.lstrcmp(ContestTypeSA[TempContest], @ContestString[1]) = 0 then
    begin
      Result := TempContest;
      Exit;
    end;
  Result := DUMMYCONTEST;
end;

function GetDialogItemText(h: HWND; Control: integer): ShortString;
var
  Len                                   : integer;
  TempHWND                              : HWND;
begin

  if Control = -1 then
    TempHWND := h
  else
    TempHWND := Windows.GetDlgItem(h, Control);
  Len := Windows.SendMessage(TempHWND, WM_GETTEXTLENGTH, 0, 0);
  Windows.ZeroMemory(@Result, SizeOf(Result));
  SetLength(Result, Len);
  if Len <> 0 then Windows.SendMessage(TempHWND, WM_GETTEXT, Len + 1, LONGINT(Pointer(@Result[1])));
end;

function GetNumberFromCharBuffer(p: PChar): integer;
label
  1;
var
  b                                     : Byte;
  i                                     : integer;
begin
  Result := 0;
  i := 0;
  1:
  if p[i] in ['0'..'9'] then
  begin
    b := Byte(p[i]) - $30;
    Result := b + (Result * 10);
    inc(i);
    goto 1;
  end;
end;
{
function StrLen(const Str: PChar): Cardinal; assembler;
asm
        CMP    EAX , 0
        JZ     @@1
        MOV    EDX,EDI
        MOV    EDI,EAX
        MOV    ECX,0FFFFFFFFH
        XOR    AL,AL
        REPNE  SCASB
        MOV    EAX,0FFFFFFFEH
        SUB    EAX,ECX
        MOV    EDI,EDX
@@1:
end;
}

function tSetDlgItemIntFalse(hDlg: HWND; nIDDlgItem: integer; uValue: UINT): BOOL; stdcall;
begin
  Windows.SetDlgItemInt(hDlg, nIDDlgItem, uValue, False);
end;

function tSetDlgItemIntSigned(hDlg: HWND; nIDDlgItem: integer; uValue: integer): BOOL; stdcall;
begin
  Windows.SetDlgItemInt(hDlg, nIDDlgItem, uValue, True);
end;

function GetWindowByHandle(h: HWND): WindowsType;
var
  wt                                    : WindowsType;
begin
  for wt := Low(WindowsType) to High(WindowsType) do
    if tr4w_WindowsArray[wt].WndHandle = h then
    begin
      Result := wt;
      Break;
    end;
end;

function tWindowsExist(wID: WindowsType): boolean;
begin
  Result := tr4w_WindowsArray[wID].WndHandle <> 0;
end;

procedure tEnableMenuItem(uIDEnableItem: UINT; uEnable: UINT);
begin
  EnableMenuItem(tr4w_main_menu, uIDEnableItem, uEnable);
  DrawMenuBar(tr4whandle);
end;



function StrPosPartial(const Str1, Str2: PChar): PChar;
begin
  // Issue #997: extracted to uStrSearch (golden-master tested).
  Result := uStrSearch.StrPosPartial(Str1, Str2);
end;

function StrPos(const Str1, Str2: PChar): PChar;
begin
  // Issue #997: extracted to uStrSearch (golden-master tested).
  Result := uStrSearch.StrPos(Str1, Str2);
end;

function GetValueFromArray(PCharArrayAddress: PChar; ArraySize: Byte; CMD: PChar): Byte;
var
  b                                     : Byte;
  p                                     : Pointer;
begin
  CMD[Ord(CMD[0]) + 1] := #0;
  for b := 0 to ArraySize {- 1} do
  begin
    p := PCharArrayAddress + (b * 4);
    p := Pointer(p^);
//    showmessage(p);
    if StrComp(@CMD[1], p) = 0 then
    begin
      Result := b;
      Exit;
    end;
  end;
  Result := UNKNOWNTYPE;
end;

function SetParameterInArray(ArrayPtr: PInteger; ArrayLength: integer; aVar: PInteger; ValueToSet: integer): boolean;
var
  b                                     : integer;
begin
  Result := False;

  for b := 0 to ArrayLength do
  begin

    if PInteger(PChar(ArrayPtr) + (b * 4))^ = ValueToSet then
{
      asm
    mov eax, ArrayPtr
    add eax, b
    mov p, eax
      end;
    if p^ = ValueToSet then
}
    begin
      aVar^ := ValueToSet;
      Result := True;
      Exit;
    end;
  end;
end;

function tGetDateFormat(DT: TQSOTime): PChar; //assembler;

 
begin
{ $ I F LANG <> 'E1212NG'}

  Format(GetDateFormatBuffer, '%02d-%02d-%02d', dt.qtDay, DT.qtMonth, DT.qtYear);
{
  St.wYear := 2000 + DT.qtYear;
  St.wMonth := dt.qtMonth;
  St.wDay := dt.qtDay;
  Windows.GetDateFormat(LOCALE_SYSTEM_DEFAULT, 0, @St, @DateFormat[1], @GetDateFormatBuffer, SizeOf(GetDateFormatBuffer));
}
 { $ E LSE}
{
  St.wYear := 2000 + DT.qtYear;
  St.wMonth := dt.qtMonth;
  St.wDay := dt.qtDay;
  Windows.GetDateFormat(LOCALE_SYSTEM_DEFAULT, 0, @St, 'dd-MMM-yy', @GetDateFormatBuffer, SizeOf(GetDateFormatBuffer));
}
{ $ I FEND}
  Result := GetDateFormatBuffer;
end;

procedure UnableToFindFileMessage(FileName: PChar);
begin
  Format(wsprintfBuffer, '%s'#13#13'%s', SysErrorMessage(GetLastError), FileName);

  showwarning(wsprintfBuffer);
end;

function DeleteSlashes(p: PChar): PChar;
var
  TempInteger                           : integer;
begin
  Result := p;
  for TempInteger := 0 to 255 do
  begin
    if p[TempInteger] = '/' then p[TempInteger] := '_';
    if p[TempInteger] = #0 then Break;
  end;
end;

procedure ShowSysErrorMessage(ID: PChar);
begin
  Format(wsprintfBuffer, '%s: %s', ID, SysErrorMessage(Windows.GetLastError));
  showwarning(wsprintfBuffer);
end;

procedure SelectParentDir(h: HWND);
var
  i                                     : integer;
const
  c                                     = '[..]';
begin
  i := Windows.SendMessage(h, LB_FINDSTRING, -1, integer(PChar(c)));
  if i <> LB_ERR then
  begin
    Windows.SendMessage(h, LB_DELETESTRING, i, 0);
    Windows.SendMessage(h, LB_INSERTSTRING, 0, integer(PChar(c)));
  end;
  tLB_SETCURSEL(h, 0);
end;

function tDialogBox(WindowID: Byte; WinProcAdr: Pointer): integer;
var
  hwndParent                            : HWND;
begin
  hwndParent := tr4whandle;
  if CreateCabrilloWindow <> 0 then hwndParent := CreateCabrilloWindow;
  Result := DialogBox(hInstance, MAKEINTRESOURCE(WindowID), hwndParent, WinProcAdr);
//  Result := DialogBoxParamW(hInstance, MakeIntResourceW(WindowID), hwndParent, WinProcAdr, 0);

  //  SendMessage(Result, WM_SETICON, ICON_BIG, LoadIcon(thInstance, 'MAINICON'));
end;

procedure SetMainWindowText(Window: TMainWindowElement; Text: PChar);
begin

//  if Window = mweUserInfo then
//    asm nop end;

  if ((Text = nil) or (Text[0] = #0)) then
    if TWindows[Window].mweE then
    begin
//      inttopchar(integer(Window));
      Exit;
    end;
  Windows.SetWindowText(wh[Window], Text);

  if Text = nil then
    TWindows[Window].mweE := True
  else
  begin
    if Text[0] = #0 then
      TWindows[Window].mweE := True
    else
      TWindows[Window].mweE := False;
  end;

end;

function tCreateThread(lpStartAddress: TFNThreadStartRoutine; var lpThreadId: DWORD; Quiet: boolean): THandle;
begin
  Result := CreateThread(nil, 0, lpStartAddress, nil, 0, lpThreadId);
  // Issue #1041: Quiet suppresses this per-create debug line so the network
  // connect-retry loop (one thread every 5s while the server is unreachable)
  // does not spam the log -- loud on a genuine attempt, silent on retries.
  if not Quiet then
    logger.Debug('[tCreateThread] Created thread %d',[lpThreadId]);
end;

//function _Pow10(val: Extended; Power: Integer): Extended;

// Issue #997: DEFERRED to the Delphi 12 mirror clone. This is Borland's RTL
// internal _Pow10 (FPU + power-of-10 tables), called only by ValExt below.
// In D12, ValExt collapses to the RTL `Val` intrinsic and this helper is
// deleted outright. Converting the float-parse path now would need a careful
// golden harness (precision + the `code` error index + whitespace handling)
// and risks a subtle CTY.DAT lat/lon regression; not worth it in D7.
procedure _Pow10;
asm
// -> FST(0)  val
// -> EAX Power
// <- FST(0)  val * 10**Power

//  This routine generates 10**power with no more than two
//  floating point multiplications. Up to 10**31, no multiplications
//  are needed.

  PUSH  EBX
{$IFDEF PIC}
  PUSH  EAX
  CALL  GetGOT
  MOV   EBX,EAX
  POP   EAX
{$ELSE}
  XOR   EBX,EBX
{$ENDIF}
  TEST  EAX,EAX
  JL  @@neg
  JE  @@exit
  CMP EAX,5120
  JGE @@inf
  MOV EDX,EAX
  AND EDX,01FH
  LEA EDX,[EDX+EDX*4]
  FLD tbyte ptr @@tab0[EBX+EDX*2]

  FMULP

  SHR EAX,5
  JE  @@exit

  MOV EDX,EAX
  AND EDX,0FH
  JE  @@skip2ndMul
  LEA EDX,[EDX+EDX*4]
  FLD tbyte ptr @@tab1-10[EBX+EDX*2]
  FMULP

@@skip2ndMul:

  SHR EAX,4
  JE  @@exit
  LEA EAX,[EAX+EAX*4]
  FLD tbyte ptr @@tab2-10[EBX+EAX*2]
  FMULP
  JMP   @@exit

@@neg:
  NEG EAX
  CMP EAX,5120
  JGE @@zero
  MOV EDX,EAX
  AND EDX,01FH
  LEA EDX,[EDX+EDX*4]
  FLD tbyte ptr @@tab0[EBX+EDX*2]
  FDIVP

  SHR EAX,5
  JE  @@exit

  MOV EDX,EAX
  AND EDX,0FH
  JE  @@skip2ndDiv
  LEA EDX,[EDX+EDX*4]
  FLD tbyte ptr @@tab1-10[EBX+EDX*2]
  FDIVP

@@skip2ndDiv:

  SHR EAX,4
  JE  @@exit
  LEA EAX,[EAX+EAX*4]
  FLD tbyte ptr @@tab2-10[EBX+EAX*2]
  FDIVP

  JMP   @@exit

@@inf:
  FLD tbyte ptr @@infval[EBX]
  JMP   @@exit

@@zero:
  FLDZ

@@exit:
  POP EBX
  RET

@@infval:  DW  $0000,$0000,$0000,$8000,$7FFF
@@tab0:    DW  $0000,$0000,$0000,$8000,$3FFF  // 10**0
           DW  $0000,$0000,$0000,$A000,$4002    // 10**1
           DW  $0000,$0000,$0000,$C800,$4005    // 10**2
           DW  $0000,$0000,$0000,$FA00,$4008        // 10**3
           DW  $0000,$0000,$0000,$9C40,$400C        // 10**4
           DW  $0000,$0000,$0000,$C350,$400F        // 10**5
           DW  $0000,$0000,$0000,$F424,$4012        // 10**6
           DW  $0000,$0000,$8000,$9896,$4016        // 10**7
           DW  $0000,$0000,$2000,$BEBC,$4019        // 10**8
           DW  $0000,$0000,$2800,$EE6B,$401C        // 10**9
           DW  $0000,$0000,$F900,$9502,$4020        // 10**10
           DW  $0000,$0000,$B740,$BA43,$4023        // 10**11
           DW  $0000,$0000,$A510,$E8D4,$4026        // 10**12
           DW  $0000,$0000,$E72A,$9184,$402A        // 10**13
           DW  $0000,$8000,$20F4,$B5E6,$402D        // 10**14
           DW  $0000,$A000,$A931,$E35F,$4030        // 10**15
           DW  $0000,$0400,$C9BF,$8E1B,$4034        // 10**16
           DW  $0000,$C500,$BC2E,$B1A2,$4037        // 10**17
           DW  $0000,$7640,$6B3A,$DE0B,$403A        // 10**18
           DW  $0000,$89E8,$2304,$8AC7,$403E        // 10**19
           DW  $0000,$AC62,$EBC5,$AD78,$4041        // 10**20
           DW  $8000,$177A,$26B7,$D8D7,$4044        // 10**21
           DW  $9000,$6EAC,$7832,$8786,$4048        // 10**22
           DW  $B400,$0A57,$163F,$A968,$404B        // 10**23
           DW  $A100,$CCED,$1BCE,$D3C2,$404E        // 10**24
           DW  $84A0,$4014,$5161,$8459,$4052        // 10**25
           DW  $A5C8,$9019,$A5B9,$A56F,$4055        // 10**26
           DW  $0F3A,$F420,$8F27,$CECB,$4058        // 10**27
           DW  $0984,$F894,$3978,$813F,$405C        // 10**28
           DW  $0BE5,$36B9,$07D7,$A18F,$405F        // 10**29
           DW  $4EDF,$0467,$C9CD,$C9F2,$4062        // 10**30
           DW  $2296,$4581,$7C40,$FC6F,$4065        // 10**31

@@tab1:    DW  $B59E,$2B70,$ADA8,$9DC5,$4069        // 10**32
           DW  $A6D5,$FFCF,$1F49,$C278,$40D3        // 10**64
           DW  $14A3,$C59B,$AB16,$EFB3,$413D        // 10**96
           DW  $8CE0,$80E9,$47C9,$93BA,$41A8        // 10**128
           DW  $17AA,$7FE6,$A12B,$B616,$4212        // 10**160
           DW  $556B,$3927,$F78D,$E070,$427C        // 10**192
           DW  $C930,$E33C,$96FF,$8A52,$42E7        // 10**224
           DW  $DE8E,$9DF9,$EBFB,$AA7E,$4351        // 10**256
           DW  $2F8C,$5C6A,$FC19,$D226,$43BB        // 10**288
           DW  $E376,$F2CC,$2F29,$8184,$4426        // 10**320
           DW  $0AD2,$DB90,$2700,$9FA4,$4490        // 10**352
           DW  $AA17,$AEF8,$E310,$C4C5,$44FA        // 10**384
           DW  $9C59,$E9B0,$9C07,$F28A,$4564        // 10**416
           DW  $F3D4,$EBF7,$4AE1,$957A,$45CF        // 10**448
           DW  $A262,$0795,$D8DC,$B83E,$4639        // 10**480

@@tab2:    DW  $91C7,$A60E,$A0AE,$E319,$46A3        // 10**512
           DW  $0C17,$8175,$7586,$C976,$4D48        // 10**1024
           DW  $A7E4,$3993,$353B,$B2B8,$53ED        // 10**1536
           DW  $5DE5,$C53D,$3B5D,$9E8B,$5A92        // 10**2048
           DW  $F0A6,$20A1,$54C0,$8CA5,$6137        // 10**2560
           DW  $5A8B,$D88B,$5D25,$F989,$67DB        // 10**3072
           DW  $F3F8,$BF27,$C8A2,$DD5D,$6E80        // 10**3584
           DW  $979B,$8A20,$5202,$C460,$7525        // 10**4096
           DW  $59F0,$6ED5,$1162,$AE35,$7BCA        // 10**4608
end;

// Issue #997: DEFERRED to the Delphi 12 mirror clone. This is Borland's RTL
// internal _ValExt (string -> extended with a `code` error index), used only
// by uCTYDAT to parse CTY.DAT latitude/longitude. In D12 this becomes the RTL
// `Val(Source, Result, code)` intrinsic (which exists in D7 too), retiring
// both this body and _Pow10. Deferred because proving float-parse equivalence
// (precision, the `code` semantics, leading/trailing whitespace) needs a
// dedicated golden harness, and a lat/lon parse regression silently corrupts
// beam-heading/distance math.
function ValExt(Source: PChar; var code: integer): extended;
//function _ValExt( s: AnsiString; VAR code: Integer ) : Extended;
//procedure _ValExt;
asm
// -> EAX Pointer to string
//  EDX Pointer to code result
// <- FST(0)  Result

      PUSH    EBX
{$IFDEF PIC}
      PUSH    EAX
      CALL    GetGOT
      MOV     EBX,EAX
      POP     EAX
{$ELSE}
      XOR     EBX,EBX
{$ENDIF}
      PUSH    ESI
      PUSH    EDI

      PUSH    EBX     // SaveGOT = ESP+8
      MOV     ESI,EAX
      PUSH    EAX     // save for the error case

      FLDZ
      XOR     EAX,EAX
      XOR     EBX,EBX
      XOR     EDI,EDI

      PUSH    EBX     // temp to get digs to fpu

      TEST    ESI,ESI
      JE      @@empty

@@blankLoop:
      MOV     BL,[ESI]
      INC     ESI
      CMP     BL,' '
      JE      @@blankLoop

@@endBlanks:
      MOV     CH,0
      CMP     BL,'-'
      JE      @@minus
      CMP     BL,'+'
      JE      @@plus
      JMP     @@firstDigit

@@minus:
      INC     CH
@@plus:
      MOV     BL,[ESI]
      INC     ESI

@@firstDigit:
      TEST    BL,BL
      JE      @@error

      MOV     EDI,[ESP+8]     // SaveGOT

@@digLoop:
      SUB     BL,'0'
      CMP     BL,9
      JA      @@dotExp
      FMUL    qword ptr [EDI] + offset Ten
      MOV     dword ptr [ESP],EBX
      FIADD   dword ptr [ESP]

      MOV     BL,[ESI]
      INC     ESI

      TEST    BL,BL
      JNE     @@digLoop
      JMP     @@prefinish

@@dotExp:
      CMP     BL,'.' - '0'
      JNE     @@exp

      MOV     BL,[ESI]
      INC     ESI

      TEST    BL,BL
      JE      @@prefinish

//  EDI = SaveGot
@@fracDigLoop:
      SUB     BL,'0'
      CMP     BL,9
      JA      @@exp
      FMUL    qword ptr [EDI] + offset Ten
      MOV     dword ptr [ESP],EBX
      FIADD   dword ptr [ESP]
      DEC     EAX

      MOV     BL,[ESI]
      INC     ESI

      TEST    BL,BL
      JNE     @@fracDigLoop

@@prefinish:
      XOR     EDI,EDI
      JMP     @@finish

@@exp:
      CMP     BL,'E' - '0'
      JE      @@foundExp
      CMP     BL,'e' - '0'
      JNE     @@error
@@foundExp:
      MOV     BL,[ESI]
      INC     ESI
      MOV     AH,0
      CMP     BL,'-'
      JE      @@minusExp
      CMP     BL,'+'
      JE      @@plusExp
      JMP     @@firstExpDigit
@@minusExp:
      INC     AH
@@plusExp:
      MOV     BL,[ESI]
      INC     ESI
@@firstExpDigit:
      SUB     BL,'0'
      CMP     BL,9
      JA      @@error
      MOV     EDI,EBX
      MOV     BL,[ESI]
      INC     ESI
      TEST    BL,BL
      JZ      @@endExp
@@expDigLoop:
      SUB    BL,'0'
      CMP    BL,9
      JA     @@error
      LEA    EDI,[EDI+EDI*4]
      ADD    EDI,EDI
      ADD    EDI,EBX
      MOV    BL,[ESI]
      INC    ESI
      TEST   BL,BL
      JNZ    @@expDigLoop
@@endExp:
      DEC    AH
      JNZ    @@expPositive
      NEG    EDI
@@expPositive:
      MOVSX  EAX,AL

@@finish:
      ADD    EAX,EDI
      PUSH   EDX
      PUSH   ECX
      CALL   _Pow10
      POP    ECX
      POP    EDX

      DEC    CH
      JE     @@negate

@@successExit:

      ADD    ESP,12   // pop temp and saved copy of string pointer

      XOR    ESI,ESI   // signal no error to caller

@@exit:
      MOV    [EDX],ESI

      POP    EDI
      POP    ESI
      POP    EBX
      RET

@@negate:
      FCHS
      JMP    @@successExit

@@empty:
      INC    ESI

@@error:
      POP    EAX
      POP    EBX
      SUB    ESI,EBX
      ADD    ESP,4
      JMP    @@exit
end;

function EnumerateLinesInFile(FileName: PChar; Func: TEnumLinesFunc; UpperCase: boolean): boolean;
label
  2, 3, LastLine;
var
  h                                     : HWND;
  FileSize                              : Cardinal;
  MapFin                                : Cardinal;
  MapBase                               : PChar;
  StartPos, FilePos                     : Cardinal;
  TempString                            : ShortString;
  LineSize                              : integer;
  TempBuffer                            : array[0..255] of Char;
  NewLine                               : boolean;
begin
  Result := False;

  if strpos(FileName, '\') <> nil then
    tOpenFileForRead(h, FileName)
  else
  begin
    Format(TempBuffer, '%s%s', TR4W_LOG_PATH_NAME, FileName);
    if not tOpenFileForRead(h, TempBuffer) then
    begin
      Format(TempBuffer, '%s%s', TR4W_PATH_NAME, FileName);
      tOpenFileForRead(h, TempBuffer);
    end;
  end;

  if h = INVALID_HANDLE_VALUE then Exit;

  FileSize := Windows.GetFileSize(h, nil);
  MapFin := Windows.CreateFileMapping(h, nil, PAGE_READONLY, 0, 0, nil);
  if MapFin = 0 then goto 2;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_READ, 0, 0, 0);

  Result := True;

  StartPos := 0;
  NewLine := False;
  FilePos := 0;

  while FilePos < FileSize do
  begin
    if (MapBase[FilePos] in [#13, #10]) then
    begin

      if not NewLine then
      begin
        LastLine:

        LineSize := FilePos - StartPos;
        if LineSize > 0 then
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          TempString[0] := CHR(LineSize);
          Windows.CopyMemory(@TempString[1], @MapBase[StartPos], LineSize);
          if UpperCase then strU(TempString);
          //logger.debug('[TF.EnumerateLinesInFile] Reading config line %s',[TempString]);
          Func(@TempString);
        end;
      end;

      NewLine := True;

    end
    else
    begin
      if NewLine then
      begin
        NewLine := False;
        StartPos := FilePos;
      end;
    end;

    inc(FilePos);
  end;

  if not NewLine then
  begin
    // Issue #997: removed a bare `asm nop end;` no-op anchor (no codegen effect).
    goto LastLine;
  end;

  Windows.UnmapViewOfFile(MapBase);
  3:
  CloseHandle(MapFin);
  2:
  CloseHandle(h);
end;

function EnumerateLinesInFile_old(FileName: PChar; Func: TEnumLinesFunc; UpperCase: boolean): boolean;
label
  2, 3, LastLine;
var
  h                                     : HWND;
  FileSize                              : Cardinal;
  MapFin                                : Cardinal;
  MapBase                               : PChar;
  StartPos, FilePos                     : Cardinal;
  TempString                            : ShortString;
  LineSize                              : integer;
  TempBuffer                            : array[0..255] of Char;
  NewLine                               : boolean;
begin
  Result := False;

  if strpos(FileName, '\') <> nil then
    tOpenFileForRead(h, FileName)
  else
  begin
    Format(TempBuffer, '%s%s', TR4W_LOG_PATH_NAME, FileName);
    if not tOpenFileForRead(h, TempBuffer) then
    begin
      Format(TempBuffer, '%s%s', TR4W_PATH_NAME, FileName);
      tOpenFileForRead(h, TempBuffer);
    end;
  end;

  if h = INVALID_HANDLE_VALUE then Exit;

  FileSize := Windows.GetFileSize(h, nil);
  MapFin := Windows.CreateFileMapping(h, nil, PAGE_READONLY, 0, 0, nil);
  if MapFin = 0 then goto 2;

  MapBase := Windows.MapViewOfFile(MapFin, FILE_MAP_READ, 0, 0, 0);

  Result := True;

  StartPos := 0;
  NewLine := False;
  FilePos := 0;

  while FilePos < FileSize do
  begin
    if (MapBase[FilePos] in [#13, #10]) then
    begin

      if not NewLine then
      begin
        LastLine:

        LineSize := FilePos - StartPos;
        if LineSize > 0 then
        begin
          Windows.ZeroMemory(@TempString, SizeOf(TempString));
          TempString[0] := CHR(LineSize);
          Windows.CopyMemory(@TempString[1], @MapBase[StartPos], LineSize);
          if UpperCase then strU(TempString);
          Func(@TempString);
        end;
      end;

      NewLine := True;

    end
    else
    begin
      if NewLine then
      begin
        NewLine := False;
        StartPos := FilePos;
      end;
    end;

    inc(FilePos);
  end;

  if not NewLine then goto LastLine;

  Windows.UnmapViewOfFile(MapBase);
  3:
  CloseHandle(MapFin);
  2:
  CloseHandle(h);
end;



function CreateModalDialog(Width, Height: integer; ParentHWND: HWND; lpDialogFunc: TFNDlgProc; dwInitParam: lParam): integer;
type
  TDLGTEMPLATEEX = packed record
    dlgVer: Word;
    signature: Word;
    helpID: DWORD;
    exStyle: DWORD;
    Style: DWORD;
    cDlgItems: Word;
    X: Word;
    Y: Word;
    cx: Word;
    cy: Word;
    Menu: Word;
    windowClass: Word;
    Title: LPWSTR;
    ttt: array[0..127 - 5] of Char;
  end;
  PDLGTEMPLATEEX = ^TDLGTEMPLATEEX;

const
  ms                                    = DS_SETFONT or DS_CENTER or WS_SYSMENU or DS_MODALFRAME or WS_CAPTION or WS_VISIBLE;

var
//  tempDLGTEMPLATE                       : MYDLGTEMPLATE;
  tempDLGTEMPLATEex                     : TDLGTEMPLATEEX;
  p                                     : PDlgTemplate;
 
begin
  p := @ {tempDLGTEMPLATEex } tempDLGTEMPLATE;

  Windows.ZeroMemory(@tempDLGTEMPLATE, SizeOf(tempDLGTEMPLATE));
  Windows.ZeroMemory(@tempDLGTEMPLATEex, SizeOf(tempDLGTEMPLATEex));
{
  tempDLGTEMPLATEex.dlgVer := $ffff;
  tempDLGTEMPLATEex.signature := 1;
  tempDLGTEMPLATEex.cx := Width;
  tempDLGTEMPLATEex.cy := Height;
  tempDLGTEMPLATEex.Style := DS_SETFONT or DS_CENTER or WS_SYSMENU or DS_MODALFRAME or WS_CAPTION or WS_VISIBLE;
//  tempDLGTEMPLATEex.cDlgItems:
}

  tempDLGTEMPLATE.X := 10;
  tempDLGTEMPLATE.Y := 10;

  tempDLGTEMPLATE.cx := Width;
  tempDLGTEMPLATE.cy := Height;
  tempDLGTEMPLATE.Style := DS_SETFONT or DS_CENTER or WS_SYSMENU or DS_MODALFRAME or WS_CAPTION or WS_VISIBLE;

  Result := DialogBoxIndirectParam(hInstance, p^, ParentHWND, lpDialogFunc, dwInitParam);

//  if Result = -1 then MessageBox(0, SysErrorMessage(GetLastError), nil, MB_OK or MB_ICONINFORMATION {or MB_RTLREADING } or MB_TASKMODAL);
end;

procedure strU(var Str: ShortString);
begin
  // Issue #997: extracted to uStrSearch (golden-master tested). Now 'var' to
  // make the in-place upcase contract explicit (the old by-value asm modified
  // the caller's string anyway -- see uStrSearch / the LogCfg note).
  uStrSearch.StrU(Str);
end;

function CreateComboBox(hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(WS_EX_STATICEDGE, COMBOBOX, nil,

    CBS_DROPDOWN or CBS_AUTOHSCROLL or CBS_SORT or CBS_HASSTRINGS or WS_CHILD or WS_VISIBLE or WS_VSCROLL or WS_TABSTOP

    , 0, 0, 0, 23, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateListView2(X, Y, nWidth, nHeight: Word; hwndParent: HWND): HWND;
begin
  Result := CreateWindowEx(WS_EX_STATICEDGE, LISTVIEW, nil, LVS_REPORT or LVS_SINGLESEL or LVS_SHOWSELALWAYS or LVS_NOSORTHEADER or WS_VISIBLE or WS_CHILD or WS_TABSTOP, X, Y, nWidth, nHeight, hwndParent, 101, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateListBox(X, Y, nWidth, nHeight: Word; hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(WS_EX_STATICEDGE, LISTBOX, nil, LBS_NOINTEGRALHEIGHT or LBS_NOTIFY or LBS_SORT or WS_VSCROLL or WS_VISIBLE or WS_CHILD or WS_TABSTOP, X, Y, nWidth, nHeight, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateStatic(lpWindowName: PChar; X, Y, nWidth: integer; hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindow(StaticPChar, lpWindowName, SS_SUNKEN or SS_center or WS_CHILD or WS_VISIBLE, X, Y, nWidth, 23 {nHeight}, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateButton(dwStyle: Cardinal; lpWindowName: PChar; X, Y, nWidth: integer; hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(0, ButtonPChar, lpWindowName, dwStyle or WS_CHILD or BS_TEXT or WS_VISIBLE or WS_TABSTOP, X, Y, nWidth, 23 {nHeight}, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateEdit(dwStyle: Cardinal; X, Y, Width, Height: integer; hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindowEx(WS_EX_CLIENTEDGE or WS_EX_NOPARENTNOTIFY, EditPChar, nil, dwStyle or WS_CHILD or WS_VISIBLE or WS_TABSTOP, X, Y, Width, Height, hwndParent, HMENU, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function CreateOwnerDrawListBox(dwStyle: DWORD; hwndParent: HWND): HWND;
begin
  Result := CreateWindowEx(WS_EX_STATICEDGE, LISTBOX, nil, dwStyle, 0, 0, 0, 0, hwndParent, 101, hInstance, nil);
  tWM_SETFONT(Result, MSSansSerifFont);
end;

function Createmsctls_progress32(X, Y, Width, Height: integer; hwndParent: HWND; HMENU: HMENU): HWND;
begin
  Result := CreateWindow('msctls_progress32', nil, WS_CHILD or WS_VISIBLE or PBS_SMOOTH, X, Y, Width, Height, hwndParent, HMENU, hInstance, nil);
end;

function CreateRichEdit(hwndParent: HWND): HWND;
begin
  Result := CreateWindow('RichEdit', nil,
    ES_MULTILINE or ES_AUTOVSCROLL or ES_NOHIDESEL or ES_READONLY or ES_SAVESEL or WS_CHILD or WS_VISIBLE or WS_BORDER or WS_VSCROLL or WS_HSCROLL,
    0, 0, 0, 0, hwndParent, 101, hInstance, nil);
  tWM_SETFONT(Result, LucidaConsoleFont);
end;

function SendDlgItemMessage(hDlg: HWND; nIDDlgItem: integer; Msg: UINT): LONGINT; stdcall;
begin
  Result := Windows.SendDlgItemMessage(hDlg, nIDDlgItem, Msg, 0, 0);
end;

function IntegerBetween(v: integer; i: integer; k: integer): boolean;
begin
   Result := (v >= i) and (v <= k);
end;

procedure GetTime(var Hour, Minute, Second, Sec100: Word);
begin
  //DecodeTime(Now, Hour, Minute, Second, Sec100);
{
  tGetSystemTime;
  Hour := UTC.wHour;
  Minute := UTC.wMinute;
  Second := UTC.wSecond;
  Sec100 := UTC.wMilliseconds;
}
end;

procedure GetDate(var Year, Month, Day, DayOfWeek: Word);
var
  St                                    : SYSTEMTIME;
begin
  //  DecodeDateFully(Date, Year, Month, Day, DayOfWeek);
  GetSystemTime(St);
  Year := St.wYear;
  Month := St.wMonth;
  Day := St.wDay;
  DayOfWeek := St.wDayOfWeek;
end;

function tOpenFileForRead(var h: HWND; FileName: PChar): boolean;
begin
  h := CreateFile(FileName, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_ARCHIVE, 0);
  Result := h <> INVALID_HANDLE_VALUE;
end;

{
function StrLen(str: Pchar): cardinal;
asm
        MOV     EDI,EDX
        XOR     AL,AL
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
end;
}
end.

