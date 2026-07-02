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
unit uMixW;
{$IMPORTEDDATA OFF}

interface

uses
  TF,
  VC,
//  Commctrl,
  Windows,
  Messages,
  LogWind,
{$IF MIXWMODE}
  ComObj,
  ActiveX,
{$IFEND}
  Tree
  ;

function MixW2DlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
{$IF MIXWMODE}
function MyGetActiveOleObject: IDispatch;
{$IFEND}
procedure DisplayMixWConnection;
procedure SendMessageToMixW(mess: string);

implementation
uses
  uFileView,
  MainUnit;

{var
  MixW                                  : OleVariant;
  MixWLoaded                            : boolean;
  MixWConnectionStatusWnd               : HWND;
}
function MixW2DlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1, con;
//var
 // p                                     : PChar;
begin
{$IF MIXWMODE}
  RESULT := False;
  case Msg of
    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    WM_EXITSIZEMOVE: FrmSetFocus;

    WM_INITDIALOG:
      begin

        MixWConnectionStatusWnd := Windows.GetDlgItem(hwnddlg, 103);
        CoBuildVersion;
        CoInitialize(nil);
        DisplayMixWConnection;
        if not MixWLoaded then goto con;

      end;

    WM_COMMAND:
      begin
        case LoWord(wParam) of
          102:
            begin
              con:

              if MixWLoaded then Exit;
              MixWLoaded := True;
              MixW := MyGetActiveOleObject;
              DisplayMixWConnection;

            end;
        end;
      end;

    WM_LBUTTONDOWN: DragWindow(hwnddlg);

    WM_DESTROY:
      begin
      end;

    WM_NCDESTROY:
      begin

      end;

    WM_CLOSE: 1: CloseTR4WWindow(tw_MixWWINDOW_INDEX);
  end;
{$IFEND}
end;

{$IF MIXWMODE}
function MyGetActiveOleObject: IDispatch;
var
  ClassID                               : TCLSID;
  Unknown                               : IUnknown;
begin
  CLSIDFromProgID(PWideChar(WideString('MixW2.Application')), ClassID);
  GetActiveObject(ClassID, nil, Unknown);
  if Unknown = nil then
  begin
    MixWLoaded := False;
    Exit;
  end;
  Unknown.QueryInterface(IDispatch, RESULT);
end;
{$IFEND}

procedure DisplayMixWConnection;
//var
 // p                                     : PChar;
begin
{$IF MIXWMODE}
  if MixWLoaded = True then p := TC_MIXW_CONNECTED else p := TC_MIXW_DISCONNECTED;
  Windows.SetWindowText(MixWConnectionStatusWnd, p);
{$IFEND}
end;

procedure SendMessageToMixW(mess: string);
begin
 {$IF MIXWMODE}
  try
    if MixWLoaded then MixW.ExecuteMacros(mess);
  except
    begin
      MixWLoaded := False;
      DisplayMixWConnection;
    end;
  end;
{$IFEND}
end;

end.

