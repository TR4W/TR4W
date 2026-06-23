program tr4w;
{$IMPORTEDDATA OFF}

// VERSIONINFO PE resource (Windows Properties dialog: File version /
// Product name / Language / Copyright fields).  Generated per-build
// by FullBuild.ps1 / Write-VersionInfoResource with the language and
// version values from Version.pas substituted in.  Guarded so the
// Delphi 7 IDE -- which doesn't run FullBuild.ps1 -- compiles cleanly
// without the file present (just produces an EXE with blank version
// fields, same as the historical behaviour).  Command-line builds
// pass -DVERSIONINFO_RES to enable.
{$IFDEF VERSIONINFO_RES}
{$R tr4w_versioninfo.res}
{$ENDIF}

//https://groups.google.com/group/tr4w/feeds?hl=ru
uses
  Messages,
  MMSystem,
  Windows,
  iniFiles,
  SysUtils,
  MainUnit in 'src\MainUnit.pas',
  BeepUnit in 'src\trdos\BeepUnit.pas',
  CFGCMD in 'src\trdos\CfgCmd.pas',
  CFGDEF in 'src\trdos\CFGDEF.PAS',
  FCONTEST in 'src\trdos\FCONTEST.PAS',
  LogCfg in 'src\trdos\LogCfg.pas',
  LogCW in 'src\trdos\LogCW.pas',
  LogDom in 'src\trdos\LOGDOM.PAS',
  LogDupe in 'src\trdos\LOGDUPE.PAS',
  LOGDVP in 'src\trdos\LOGDVP.PAS',
  LogEdit in 'src\trdos\LOGEDIT.PAS',
  LogGrid in 'src\trdos\LOGGRID.PAS',
  LogK1EA in 'src\trdos\LOGK1EA.PAS',
  LogNet in 'src\trdos\LOGNET.PAS',
  LogPack in 'src\trdos\LOGPACK.PAS',
  LogRadio in 'src\trdos\LOGRADIO.PAS',
  LogSCP in 'src\trdos\LOGSCP.PAS',
  LogStuff in 'src\trdos\LOGSTUFF.PAS',
  LOGWAE in 'src\trdos\LOGWAE.PAS',
  LogWind in 'src\trdos\LOGWIND.PAS',
  Tree in 'src\trdos\tree.pas',
  ZoneCont in 'src\trdos\ZONECONT.PAS',
  LOGSUBS2 in 'src\trdos\LOGSUBS2.PAS',
  LOGSUBS1 in 'src\trdos\LOGSUBS1.PAS',
  LOGSend in 'src\trdos\LogSend.pas',
  uCT1BOH in 'src\uCT1BOH.pas',
  PostUnit in 'src\trdos\PostUnit.PAS',
  uCabrilloFormat in 'src\uCabrilloFormat.pas',
  uCabrilloExchange in 'src\uCabrilloExchange.pas',
  uInputQuery in 'src\uInputQuery.pas',
  uNewContest in 'src\uNewContest.pas',
  uRadioPolling in 'src\uRadioPolling.pas',
  uMissingMults in 'src\uMissingMults.pas',
  uEditQSO in 'src\uEditQSO.pas',
  uLogSearch in 'src\uLogSearch.pas',
  uBeacons in 'src\uBeacons.pas',
  uNet in 'src\uNet.pas',
  uTotal in 'src\uTotal.pas',
  uMaster in 'src\uMaster.pas',
  uRemMults in 'src\uRemMults.pas',
  uDupesheet in 'src\uDupesheet.pas',
  uSendSpot in 'src\uSendSpot.pas',
  uSendKeyboard in 'src\uSendKeyboard.pas',
  uOption in 'src\uOption.pas',
  uRadio12 in 'src\uRadio12.pas',
  uFunctionKeys in 'src\uFunctionKeys.pas',
  uinet in 'src\uinet.pas',
  uTelnet in 'src\uTelnet.pas',
  uBandmap in 'src\uBandmap.pas',
  uFileView in 'src\uFileView.pas',
  uAutoCQ in 'src\uAutoCQ.pas',
  uCAT in 'src\uCAT.pas',
  uDialogs in 'src\uDialogs.pas',
  Version in 'src\Version.pas',
  VC in 'src\VC.pas',
  uCommctrl in 'src\uCommctrl.pas',
  uGradient in 'src\uGradient.pas',
  uMessages in 'src\uMessages.pas',
  uWinManager in 'src\uWinManager.pas',
  uCbrSum in 'src\uCbrSum.pas',
  uQTCR in 'src\uQTCR.pas',
  uQTCS in 'src\uQTCS.pas',
  LPT in 'src\LPT.pas',
  uGetServerLog in 'src\uGetServerLog.pas',
  TF in 'src\TF.pas',
  uFreqTimeFormat in 'src\uFreqTimeFormat.pas',
  uLogEdit in 'src\uLogEdit.pas',
  uIntercom in 'src\uIntercom.pas',
  uLogCompare in 'src\uLogCompare.pas',
  uMixW in 'src\uMixW.pas',
  uCallsigns in 'src\uCallsigns.pas',
  uSpots in 'src\uSpots.pas',
  uGetScores in 'src\uGetScores.pas',
  uStations in 'src\uStations.pas',
  uAltD in 'src\uAltD.pas',
  uWinKey in 'src\uWinKey.pas',
  uCFG in 'src\uCFG.pas',
  uCRC32 in 'src\uCRC32.pas',
  uMP3Recorder in 'src\uMP3Recorder.pas',
  uAltP in 'src\uAltP.pas',
  uEditMessage in 'src\uEditMessage.pas',
  uCheckLatestVersion in 'src\uCheckLatestVersion.pas',
  uErmak in 'src\uErmak.pas',
  uProcessCommand in 'src\uProcessCommand.pas',
  uMults in 'src\uMults.pas',
  HtmlHelp in 'src\HtmlHelp.pas',
  uSSL in 'src\uSSL.pas',
  uQuickEdit in 'src\uQuickEdit.pas',
  uIO in 'src\uIO.pas',
  uBMCF in 'src\uBMCF.pas',
  uCTYDAT in 'src\uCTYDAT.PAS',
  uCallSignRoutines in 'src\uCallSignRoutines.pas',
  uSynTime in 'src\uSynTime.pas',
  uMMTTY in 'src\uMMTTY.pas',
  uProfiler in 'src\uProfiler.pas',
  uMessagesList in 'src\uMessagesList.pas',
  uRussiaOblasts in 'src\uRussiaOblasts.pas',
  uMenu in 'src\uMenu.pas',
  winsock2 in 'include\WinSock2.pas',
  utils_net in 'src\utils\utils_net.pas',
  utils_hw in 'src\utils\utils_hw.pas',
  utils_text in 'src\utils\utils_text.pas',
  utils_math in 'src\utils\utils_math.pas',
  utils_file in 'src\utils\utils_file.pas',
  exportto_trlog in 'src\exportto_trlog.pas',
  uWSJTX in 'src\uWSJTX.pas',
  uHamScore in 'src\uHamScore.pas',
  uExchangeBuilder in 'src\uExchangeBuilder.pas',
  uGridLookup in 'src\uGridLookup.pas',
  Log4D in 'src\Log4D.pas',
  uNetRadioBase in 'src\uNetRadioBase.pas',
  uSerialPort in 'src\uSerialPort.pas',
  uRadioFactory in 'src\uRadioFactory.pas',
  uRadioElecraftK4 in 'src\uRadioElecraftK4.pas',
  uRadioKenwoodTS890 in 'src\uRadioKenwoodTS890.pas',
  uIcomNetworkTypes in 'src\uIcomNetworkTypes.pas',
  uIcomNetworkTransport in 'src\uIcomNetworkTransport.pas',
  uIcomNetworkDiscovery in 'src\uIcomNetworkDiscovery.pas',
  uRadioIcomBase in 'src\uRadioIcomBase.pas',
  uRadioIcom9700 in 'src\uRadioIcom9700.pas',
  uRadioIcom7610 in 'src\uRadioIcom7610.pas',
  uRadioIcom7300 in 'src\uRadioIcom7300.pas',
  uRadioIcom705 in 'src\uRadioIcom705.pas',
  uRadioIcom7300MK2 in 'src\uRadioIcom7300MK2.pas',
  uRadioIcom7600 in 'src\uRadioIcom7600.pas',
  uRadioIcom7760 in 'src\uRadioIcom7760.pas',
  uRadioIcom7850 in 'src\uRadioIcom7850.pas',
  uRadioIcom905 in 'src\uRadioIcom905.pas',
  GetWinVersionInfo in 'src\GetWinVersionInfo.pas',
  uSuperCheckPartialFileUpload in 'src\uSuperCheckPartialFileUpload.pas',
  uHamLibDirect in 'src\uHamLibDirect.pas',
  uRadioHamLibDirect in 'src\uRadioHamLibDirect.pas',
  uExternalLoggerBase in 'src\uExternalLoggerBase.pas',
  uExternalLogger in 'src\uExternalLogger.pas',
  uExternalLoggerFactory in 'src\uExternalLoggerFactory.pas',
  // uExternalLoggerManager uses Generics.Collections (Delphi 2009+) - not Delphi 7 IDE compatible
  //uExternalLoggerManager in 'src\uExternalLoggerManager.pas',
  uDXLabPathfinder in 'src\uDXLabPathfinder.pas',
  uYCCCSO2R in 'src\uYCCCSO2R.pas',
  uFlexRadio6000 in 'src\uFlexRadio6000.pas',
  uRadioBand in 'src\uRadioBand.pas',
  uBandLookup in 'src\uBandLookup.pas',
  uRadioIcom7100 in 'src\uRadioIcom7100.pas',
  uIcomCIV in 'src\uIcomCIV.pas',
  // uRadioManager uses Generics.Collections (Delphi 2009+) - not Delphi 7 IDE compatible
  //uRadioManager in 'src\uRadioManager.pas',
  // uDXSSpotsFilter and uSpotsFilter reference SendViaSocket which is not defined - unfinished code
  //uDXSSpotsFilter in 'src\uDXSSpotsFilter.pas',
  //uSpotsFilter in 'src\uSpotsFilter.pas',
  // uRemMults_DOM/DX/Zone: dead code since initial commit, depends on Country9.pas which was never in the repo
  //uRemMults_DOM in 'src\uRemMults_DOM.pas',
  //uRemMults_DX in 'src\uRemMults_DX.pas',
  //uRemMults_Zone in 'src\uRemMults_Zone.pas',
  uAbout in 'src\uAbout.pas',
  uHardWare in 'src\uHardWare.pas',
  uReminder in 'src\uReminder.pas',
  // uSCP: never referenced anywhere, was never compiled prior to this session - orphaned code
  //uSCP in 'src\uSCP.pas',
  // uMultsFrequencies: never referenced (commented out in MainUnit and uNet) - orphaned code
  //uMultsFrequencies in 'src\uMultsFrequencies.pas',
  uMakeHelpFile in 'src\uMakeHelpFile.pas',
  uTrayBalloon in 'src\uTrayBalloon.pas',
  uVariants in 'src\uVariants.pas',
  uPOTAParks in 'src\uPOTAParks.pas',
  uPendingCounties in 'src\uPendingCounties.pas',
  uCTYUpdate in 'src\uCTYUpdate.pas';
  //cty in 'src\cty.pas';  // Excluded: unit name 'cty' conflicts with global variable 'CTY' from uCTYDAT

{$IF LANG = 'ENG'}{$R res\tr4w_eng.res}{$IFEND}
{$IF LANG = 'RUS'}{$R res\tr4w_rus.res}{$IFEND}
{$IF LANG = 'SER'}{$R res\tr4w_ser.res}{$IFEND}
{$IF LANG = 'ESP'}{$R res\tr4w_esp.res}{$IFEND}
{$IF LANG = 'MNG'}{$R res\tr4w_mng.res}{$IFEND}
{$IF LANG = 'POL'}{$R res\tr4w_pol.res}{$IFEND}
{$IF LANG = 'CZE'}{$R res\tr4w_cze.res}{$IFEND}
{$IF LANG = 'ROM'}{$R res\tr4w_rom.res}{$IFEND}
{$IF LANG = 'CHN'}{$R res\tr4w_chn.res}{$IFEND}
{$IF LANG = 'GER'}{$R res\tr4w_ger.res}{$IFEND}
{$IF LANG = 'UKR'}{$R res\tr4w_ukr.res}{$IFEND}

{$R 'Win11.res'}

// Column-double-click padding (Issue #750 follow-up).
//
// Windows' default ListView/Header response to a double-click on a
// column divider is to auto-fit the column to its widest content.
// The auto-fit chooses the header-divider position, which is a few
// pixels narrower than the cell-content area because the ListView's
// cell layout adds an internal left/right margin.  At the just-fits
// threshold the saved value triggers ellipsis on the very content
// that fit visually pre-save.
//
// Fix: intercept HDN_DIVIDERDBLCLICK directly -- run the auto-fit
// ourselves with LVSCW_AUTOSIZE_USEHEADER, add COLUMN_DOUBLECLICK_PAD_PX
// for breathing room, apply that width, and save.  We must do all
// the work inside HDN_DIVIDERDBLCLICK and suppress the default OS
// behaviour: HDN_ENDTRACK only fires for end-of-drag, not for
// double-click auto-fit, so a "set a flag in HDN_DIVIDERDBLCLICK
// and add padding in HDN_ENDTRACK" approach silently drops the
// save on double-click.  Manual drag is handled in HDN_ENDTRACK
// without padding -- the dragged width is the operator's explicit
// choice.
const
  COLUMN_DOUBLECLICK_PAD_PX = 12;

function WindowProc(TRHWND: HWND; Msg: UINT; wParam: wParam; lParam: lParam): longword; stdcall;

label
  GoToExit, CallDefWindowProc;
var
  HDNotifyPtr: PHDNotify;
  lplvcd: PNMLVCustomDraw;
  hdrColIdx: Integer;
  hdrNewWidth: Integer;
begin

  case Msg of

//    WM_POWERBROADCAST: ShowMessage(PChar('WM_POWERBROADCAST' + IntToStr(wParam)));

    WM_DISPLAYCHANGE:
      begin
        if wParam <= 8 then tEightBitsPerPixel := True else tEightBitsPerPixel := False;
        // Issue #1060: a monitor was added/removed or resolution changed -- pull
        // any now-off-screen TR4W window back onto an active monitor.
        RevalidateOpenWindowsOnScreen;
      end;

    // Issue #912: headless server-log auto-sync.  RunSyncThread (worker)
    // SendMessages here once the download is complete; we close the temp
    // file handle and call ReplaceLogByServerLog on the UI thread so
    // LoadinLog's ListView access is safe.
    WM_USER_HEADLESS_SYNC_REPLACE:
      begin
        if NewServerLogHandle <> INVALID_HANDLE_VALUE then
          begin
          CloseHandle(NewServerLogHandle);
          NewServerLogHandle := INVALID_HANDLE_VALUE;
          end;
        ReplaceLogByServerLog(True);
        logger.Info('Auto-sync: local log replaced with server log.');
        HeadlessSyncMode := False;
      end;

//    WM_MOUSEWHEEL: SetStackPointerOnMouseWheel(SHORT(HiWord(Cardinal(wParam))));
    WM_TRAYBALLON:
      begin

      end;
    WM_TIMECHANGE:
      begin
        GetSystemTime(UTC);
        SystemTimeChanging;
      end;

    //    WM_CONTEXTMENU: if HWND(wParam) = _NewELogWindow then ShowLogPopupMenu(tr4whandle);

{$IF MMTTYMODE}
    WM_SIZE:
      begin
        if MMTTY.MMTTYEngine <> 0 then
        begin
          if wParam = SIZE_MINIMIZED then Windows.ShowWindow(MMTTY.MMTTYEngine, SW_SHOWMINNOACTIVE);
          if wParam = SIZE_RESTORED then Windows.ShowWindow(MMTTY.MMTTYEngine, SW_RESTORE);
        end;
      end;
{$IFEND}

    WM_WINDOWPOSCHANGING: WINDOWPOSCHANGINGPROC(PWindowPos(lParam));
    WM_NOTIFY:
      begin

        with PNMHdr(lParam)^ do

          if (hWndFrom = wh[mweEditableLog]) then
            case code of

              NM_DBLCLK: EditableLogWindowDblClick;

              // Issue #750: gray out the editable-log row for X-QSO
              // records.  The X-QSO flag is stashed in the row's
              // per-item lParam by tAddContestExchangeToLog ->
              // SetRowXQSOFlag.  We must return CDRF_NOTIFYITEMDRAW
              // at the table-level prepaint to be called back per
              // item; then at item prepaint, replace the text colour
              // with mid-gray ($808080) when the item's lParam is 1.
              // CDRF_NEWFONT tells the listview to apply the new
              // colour.  Exit; bypasses the trailing DefWindowProc
              // call so our Result is what gets returned to the
              // listview's parent-wndproc dispatch.
              NM_CUSTOMDRAW:
                begin
                  lplvcd := PNMLVCustomDraw(lParam);
                  case lplvcd.nmcd.dwDrawStage of
                     CDDS_PREPAINT:
                        begin
                        Result := CDRF_NOTIFYITEMDRAW;
                        Exit;
                        end;
                     CDDS_ITEMPREPAINT:
                        begin
                        if lplvcd.nmcd.lItemlParam = 1 then
                           lplvcd.clrText := $00808080; // mid-gray
                        Result := CDRF_NEWFONT;
                        Exit;
                        end;
                  end;
                end;

              NM_SETFOCUS:
                begin
                  ActiveMainWindow := awEditableLog;
                end;
              NM_KILLFOCUS:
                begin
                end;
            end
          else if (hWndFrom = ListView_GetHeader(wh[mweEditableLog])) then
            begin
            // HDN_DIVIDERDBLCLICK: operator double-clicked the divider
            // to auto-fit.  Do EVERYTHING here (auto-fit, padding,
            // save) instead of deferring to a follow-up HDN_ENDTRACK:
            // per Win32, HDN_ENDTRACK only fires for end-of-drag.  The
            // OS's internal auto-fit during double-click does not
            // generate one, so a flag-based "wait for HDN_ENDTRACK"
            // approach silently drops the save.
            //
            // We run the auto-fit ourselves with LVSCW_AUTOSIZE_USEHEADER,
            // add COLUMN_DOUBLECLICK_PAD_PX for breathing room, apply
            // that to the column, and save.  Returning a non-zero
            // Result suppresses the default header auto-fit; Exit
            // bypasses DefWindowProc which would otherwise overwrite
            // Result with its own return value.
            if (code = HDN_DIVIDERDBLCLICKA) or (code = HDN_DIVIDERDBLCLICKW) then
               begin
               HDNotifyPtr := PHDNotify(lParam);
               hdrColIdx := HDNotifyPtr^.Item;
               ListView_SetColumnWidth(wh[mweEditableLog], hdrColIdx,
                                       LVSCW_AUTOSIZE_USEHEADER);
               hdrNewWidth := ListView_GetColumnWidth(wh[mweEditableLog],
                                                     hdrColIdx)
                              + COLUMN_DOUBLECLICK_PAD_PX;
               ListView_SetColumnWidth(wh[mweEditableLog], hdrColIdx,
                                       hdrNewWidth);
               SaveColumnWidthToConfig(hdrColIdx, hdrNewWidth);
               Result := 1; // suppress default header auto-fit
               Exit;
               end
            else if (code = HDN_ENDTRACK) or (code = HDN_ENDTRACKW) then
               begin
               // Normal end-of-drag: save the dragged width exactly
               // as the operator left it.  No padding here -- the
               // operator explicitly chose this width.
               HDNotifyPtr := PHDNotify(lParam);
               if (HDNotifyPtr^.pItem <> nil) and
                  ((HDNotifyPtr^.pItem^.mask and HDI_WIDTH) <> 0) then
                  SaveColumnWidthToConfig(HDNotifyPtr^.Item,
                                          HDNotifyPtr^.pItem^.cxy)
               else
                  // pItem unavailable — fall back to querying the ListView directly
                  SaveColumnWidthToConfig(HDNotifyPtr^.Item,
                     ListView_GetColumnWidth(wh[mweEditableLog],
                                             HDNotifyPtr^.Item));
               end;
            end;
      end;
    WM_MEASUREITEM: if wParam = MainWindowPCLID then
        PMeasureItemStruct(lParam).itemHeight := ws;
       
    WM_DRAWITEM:
      begin
        if wParam = MainWindowPCLID then
          PossibleCallsProc(PDrawItemStruct(lParam));
      end;


    WM_LBUTTONDOWN: DragWindow(TRHWND);

    WM_SETFOCUS:
      begin
        if ActiveMainWindow = awExchangeWindow then
          tExchangeWindowSetFocus
        else
          tCallWindowSetFocus;
        ShowFMessages(0);
      end;

    WM_POTA_DOWNLOAD_DONE:
      begin
      // Fired by the async download thread (see uPOTAParks).
      // wParam=1: file saved OK; wParam=0: download failed.
      if wParam = 1 then
         begin
         if LoadPOTAParks(POTAParksFilePath) > 0 then
            QuickDisplay(PChar('POTA parks loaded'))
         else
            QuickDisplay(PChar('POTA parks file could not be loaded'));
         end
      else
         QuickDisplay(PChar('POTA parks download failed'));
      end;

    WM_POTA_LOAD_DONE:
      begin
      // Fired by TPOTALoadThread after parsing the CSV off the UI thread.
      // lParam is the parsed TStringList — ApplyLoadedParks takes ownership.
      ApplyLoadedParks(lParam);
      end;

    WM_CTY_VERSION_CHECKED:
      begin
      if wParam = 1 then
         begin
         // Silent startup notice — no MessageBox, no blocking
         Format(wsprintfBuffer,
            'Newer CTY.DAT available (dated %d). Press Alt-O to download.',
            lParam);
         QuickDisplay(wsprintfBuffer);
         end;
      end;

    WM_CTY_DOWNLOAD_DONE:
      begin
      if wParam = 1 then
         begin
         QuickDisplay(PChar('CTY.DAT downloaded. Reloading...'));
         // Reload on main thread — CTY tables have no locking, so background
         // reload would race with callsign lookups. Message handler is a safe
         // quiescent point.
         ctyLoadInCountryFile(TR4W_CTY_FILENAME, False, True);
         QuickDisplay(PChar('CTY.DAT reloaded successfully.'));
         end
      else
         QuickDisplay(PChar('CTY.DAT download failed.'));
      end;

    WM_CTLCOLORLISTBOX, WM_CTLCOLOREDIT, WM_CTLCOLORSTATIC:
      begin
        Result := DrawWindows(lParam, wParam);
        if Result <> 0 then Exit;
      end;

    WM_CLOSE:
      begin
        GoToExit:
        ExitProgram(True);
        Msg := 0;
      end;

    WM_COMMAND:
      begin
        case wParam of
          66:
            begin
              EditableLogWindowDblClick;
            end;
        end;
{$IF tDebugMode}
        if HiWord(wParam) = BN_CLICKED then
        begin
          if lParam = integer(CPUButtonHandle) then CPUButtonProc;
          FrmSetFocus;
        end;
{$IFEND}

        if (LoWord(wParam) >= 10000) and (LoWord(wParam) <= 10700) then
           ProcessMenu(wParam);
        if (LoWord(wParam) >= 10700) and (LoWord(wParam) <= 10750) then
            RunPlugin(LoWord(wParam));

        if lParam = integer(wh[mweCall]) then
        begin
          if HiWord(wParam) = EN_KILLFOCUS then
          begin
            if tr4w_CustomCaret then DestroyCaret;
            CheckQuestionMark;
          end;
          if HiWord(wParam) = EN_UPDATE {EN_CHANGE} then CallWindowChange;

          if HiWord(wParam) = EN_SETFOCUS then
          begin
            ActiveMainWindow := awCallWindow;
            ChangeCaret(wh[mweCall]);
{$IF MORSERUNNER}
//            Windows.SendMessage(MorseRunner_Callsign, WM_SETFOCUS, 0, 0);
{$IFEND}
          end;
        end;

        if lParam = integer(wh[mweExchange]) then
        begin
          if HiWord(wParam) = EN_KILLFOCUS then
          begin
            if tr4w_CustomCaret then DestroyCaret;
          end;
          if HiWord(wParam) = EN_CHANGE then ExchangeWindowChange;
          if HiWord(wParam) = EN_SETFOCUS then
          begin
            ActiveMainWindow := awExchangeWindow;
            ChangeCaret(wh[mweExchange]);
{$IF MORSERUNNER}
//            Windows.SendMessage(MorseRunner_nUMBER, WM_SETFOCUS, 0, 0);
{$IFEND}
          end;
        end;

      end;

  end; {of case}

{$IF MMTTYMODE}
  if Msg = MMTTY.mmttyMSG then mmttyProcessMessage(wParam, lParam);
{$IFEND}

  CallDefWindowProc:
  Result := longword(DefWindowProc(TRHWND, Msg, wParam, lParam));
end;

label
  NoTransMess, TransMess, CommandLine;
var
  TempHDC                               : HDC;
  TempColor                             : tr4wColors;
  TempTLogBrush                         : TLogBrush {= (lbStyle: BS_SOLID; lbHatch: 0)};
  c                                     : Cardinal;
  TempString                            : ShortString;
   //  P                                   : Pchar; //n4af
   //   P1                                   : boolean; //n4af
   // S1                                   : String; //n4af
{$IF not tDebugMode}
  s                                     : string;
{$IFEND}
  logBuffer                             : string;
  tempStickyKey                         : STICKYKEYS;
  tc                                    : tcolor;
  sDebugLevel                           : string;
  i                                     : tLogLevels;
  rgb                                   : cardinal;
  iniFile                               : TINIFile;                    // Used to simply find the DEBUG setting so we can set it when the logger object is created.
                                                                       // This way we can log before we read the DEBUG LOG LEVEL the legacy method in uCFG. // ny4i
begin
   // Enable thread-safe memory management. TR4W creates threads via Win32
   // CreateThread (not TThread), which does NOT set this flag automatically.
   // Without it, concurrent GetMem calls from different threads can corrupt
   // the heap, causing random AVs at startup when radio polling threads and
   // the main thread initialize simultaneously.
   IsMultiThread := True;

   // Check for another running instance BEFORE opening any shared files
   // (log file, etc.) to avoid an EFOpenError crash on the second instance.
   tMutex := CreateMutex(nil, False, tr4w_ClassName);
   if tMutex = 0 then
      begin
      Exit;
      end;
   if GetLastError = ERROR_ALREADY_EXISTS then
      begin
      MessageBox(0, Pchar(TC_RUNWARN), tr4w_ClassName, MB_OK or MB_ICONWARNING or MB_SYSTEMMODAL or MB_TOPMOST);
      Exit;
      end;

   TR4W_PATH_NAME[Windows.GetCurrentDirectory(SizeOf(TR4W_PATH_NAME), @TR4W_PATH_NAME)] := '\';
   Format(TR4W_INI_FILENAME, '%ssettings\tr4w.ini', TR4W_PATH_NAME);
   iniFile := TINIFile.create(TR4W_INI_FILENAME);
   try
   appender := TLogRollingFileAppender.Create('name','tr4w.log');
   appender.Layout := TLogPatternLayout.Create('%d ' + TTCCPattern);
   TLogBasicConfigurator.Configure(appender);
   logger := TLogLogger.GetLogger('TR4WDebugLog');
   sDebugLevel := iniFile.ReadString('COMMANDS','DEBUG LOG LEVEL', 'ERROR');
   for i := Low(tLogLevelsSA) to High(tLogLevelsSA) do
      begin
      if sDebugLevel = tLogLevelsSA[i] then
         begin
         logLevels := tLogLevels(i);
         break;
         end;
      end;
   UpdateDebugLogLevel;

   logger.info('******************** PROGRAM STARTUP ************************');
   logger.Trace('trace output');
   logger.Info('DecimalSeparator = ' + DecimalSeparator);



  TR4W_PATH_NAME[Windows.GetCurrentDirectory(SizeOf(TR4W_PATH_NAME), @TR4W_PATH_NAME)] := '\';

 Format(TR4W_INI_FILENAME, '%ssettings\tr4w.ini', TR4W_PATH_NAME);
  LuconSZLoadded := AddFontResource(TR4W_LC_FILENAME) <> 0;
  MainFixedFont := tCreateFont(15, FW_BOLD * Ord(BoldFont), @MainFontName[1]);
  MSSansSerifFont := tCreateFont(15, FW_DONTCARE, 'MS Sans Serif');
  CreateDirectoryIfNotExist;

{$IF tDebugMode}
  //uHistory.MakeRevisionHistory;
  TR4W_CFG_FILENAME := 'c:\TR4W\debug.cfg';
{$ELSE}

  s := ParamStr(1);
  if s <> '' then
  begin
    Windows.CopyMemory(@TR4W_CFG_FILENAME, @s[1], length(s));
    goto CommandLine;
  end;

  begin
    CreateModalDialog(305, 235, tr4whandle, @NewContestDlgProc, 0);
    if TR4W_CFG_FILENAME[0] = '_' then Exit;
  end;
{$IFEND}

  CommandLine:



  InitializeStrings;

  for TempColor := Low(tr4wColors) to High(tr4wColors) do
  begin
    TempTLogBrush.lbColor := tr4wColorsArray[TempColor];
    tr4wBrushArray[TempColor] := CreateBrushIndirect(TempTLogBrush);
  end;

  tr4w_osverinfo.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
  Windows.GetVersionEx(tr4w_osverinfo);

  WindowsOSversion := tr4w_osverinfo.dwPlatformId;

  StickyKeysAtStartup.cbSize := sizeof(STICKYKEYS); // This prevents multiple shift keys from activating sticky keys. It saves settng and restore upon exit. ny4i
  Windows.SystemParametersInfo(SPI_GETSTICKYKEYS, sizeof(STICKYKEYS), @StickyKeysAtStartup, 0);
  tempStickyKey.cbSize := StickyKeysAtStartup.cbSize;
  tempStickyKey.dwFlags := StickyKeysAtStartup.dwFlags and not (SKF_STICKYKEYSON or SKF_HOTKEYACTIVE);
  SystemParametersInfo( SPI_SETSTICKYKEYS, SizeOf(tempStickyKey), @tempStickyKey, 0 );
  Windows.SystemParametersInfo(SPI_GETWORKAREA, 0, @tWorkingAreaRect, 0);
  TempHDC := Windows.GetWindowDC(tr4whandle);

  tEightBitsPerPixel := Windows.GetDeviceCaps(TempHDC, BITSPIXEL) <= 8;
  ReleaseDC(tr4whandle, TempHDC);

  SetUpFileNames;

  RenameCommands;


  LoadTR4WPOSFILE;


  if not ctyLoadInCountryFile(TR4W_CTY_FILENAME, False, True) then
  begin
    UnableToFindFileMessage(TR4W_CTY_FILENAME);
    logger.Fatal('Unable to find ' + TR4W_CTY_FILENAME);
    halt;
  end;

  SetConfigurationDefaultValues;

  {Temporary - Feb 2010}


  ReadInConfigFile(cfgINI);

  ReadInConfigFile(cfgCFG);          //n4af 4.31.5
  ReadInConfigFile(cfgCommMes);      //common messages gets precedence - n4af

  // Issue #1012: the S&P F1 caption is derived from DE ENABLE, whose value is
  // only known after the config files above are read.  Recompute it now so
  // DE ENABLE = FALSE shows "Call" instead of the default "DE+Call".
  UpdateSAndPF1Caption;

  if WSJTXEnabled then
     begin
     wsjtx := TWSJTXServer.Create;
     end;
  logger.debug('[tr4w] SpotCollectorEnabled = %s', [BooleanToStr(SpotCollectorEnabled)]);
  if SpotCollectorEnabled then
     StartDXLabPathfinder;
  if elLogType <> lt_NoExternalLogger then
     begin
     externalLogger := TExternalLogger.Create(elLogType);
     externalLogger.loggerPort := externalLoggerPort;
     externalLogger.loggerAddress := externalLoggerAddress;
     end;
  // Issue #783 -- start the HamScore RTC uploader if HAMSCORE ENABLE = TRUE.
  // No-op if disabled or password is empty.
  HamScoreInit;
  UpdateDebugLogLevel;
  //logger.debug('**************** Program Startup ************************');
  logger.info('DecimalSeparator = ' + DecimalSeparator);
  logger.debug('Current program version = %s',[TR4W_CURRENTVERSION]);
  logger.debug('Current TR4W Server version = %s',[TR4WSERVER_CURRENTVERSION]);
  logger.debug('Current log version = %s',[LOGVERSION]);
  logger.info('HamLib version = %s',[GetHamLibVersion]);
  logger.debug('Windows version = %s %s (raw: %d.%d Build %d)',[GetOSInfo, GetWindowsBuildDetail, tr4w_osverinfo.dwMajorVersion, tr4w_osverinfo.dwMinorVersion, tr4w_osverinfo.dwBuildNumber]);
  if CTY.CtyRFOblMode then       // n4af 4.42.6
     ctyLoadInRFOblList;



  if CTY.ctyR150SMode then
  begin
    ctyLoadInR150SList;
    TempString := 'MY CALL';
    CheckCommand(@TempString, MyCall);
  end;

{$IF SCPDEBUG}
  scpLoadInDateBase('trmaster.dta');
{$IFEND}

  mo.FillVisibleBytes;
  ws := ws + 12;

  tSetupExchangeNumbers;

  if (HFBandEnable = False) and (VHFBandsEnabled = True) then
     begin
     ActiveBand := Band6;
     BandMapDisplayGhz := True;    // n4af 4.42.8
     end;
  if HFBandEnable then
     BandMapDisplayGhz := False;    // n4af 4.42.8

  SetWindowSize;
  CreateFonts;

  with tr4w_WinClass do
  begin
    HICON := LoadIcon(SysInit.hInstance, MAKEINTRESOURCE('MAINICON'));
    lpfnWndProc := @WindowProc;
    hInstance := SysInit.hInstance;
    HCURSOR := LoadCursor(0, IDC_ARROW);
    hbrBackground := tr4wBrushArray[TWindows[mweWholeScreen].mweBackG {trBtnFace}];
  end;

  //tr4w_main_menu := LoadMenu(hInstance, 'T');
  tr4w_main_menu := CreateTR4WMenu(@T_MENU_ARRAY, T_MENU_ARRAY_SIZE, False);

{$IFDEF AUTOSPOT}
   ShowMessage('AUTOSPOT is enabled - Test Mode Only'); // Hard on relays - be careful
{$ENDIF}
  tr4w_accelerators := LoadAccelerators(hInstance, 'T');
  // Ctrl+T → menu_repeat_pota_parks is defined directly in the .res file.

  RegisterClass(tr4w_WinClass);

  CursorBitmap := LoadImage(hInstance, 'cursor.bmp', IMAGE_BITMAP, ws2 * 3, ws + 2, LR_LOADFROMFILE);

  SetUpExchangeInformation(ActiveExchange, ExchangeInformation);
  SetColumnsWidth;
  CreateMainWindow;
  CreateMultsWindows;
  CreateQSONeedWindows;

  Windows.ShowWindow(wh[mweWSJTX], SW_HIDE);
  SetUpGlobalsAndInitialize;
  if SayHiEnable then
     DisplayNamePercentage;
  SetStereoPin(StereoControlPin, StereoPinState);
  DisplayRadio(ActiveRadio);
  DisplayBandMode(ActiveBand, ActiveMode, False);
  tDisplayCQTotal;
  ClearContestExchange(ReceivedData);
  SetUpToSendOnActiveRadio;

  UpdateTimeAndRateDisplays(True, True);
  SystemTimeChanging;
  DisplayRate(0);
  tDispalyMyComputerID;
  SetMainWindowText(mweCurrentOperator, CurrentOperator);

  ntBeepInit;
  OpenOtherWindows;

  tLoadKeyboardLayout;

  tCallWindowSetFocus;

  LoadInPlugins;

  CheckNTPAtStartup;

  // Load POTA parks database off the UI thread (file may be ~3 MB / 50k entries).
  // TPOTALoadThread parses the CSV and posts WM_POTA_LOAD_DONE when done.
  LoadPOTAParksAsync(tr4whandle);

  // Silent background CTY version check — posts WM_CTY_VERSION_CHECKED when done.
  // Config is already loaded at this point so CTYUpdateCheckOnStartup is valid.
  if CTYUpdateCheckOnStartup then
     CheckCTYVersionAsync(tr4whandle);

  asm
  mov  ebx,0
  push ebx
  push ebx
  push ebx
  push ebx
  call CreateEvent
  mov  [tCW_Event],eax

  sub  esp,16
  call CreateEvent
  mov  [tCWPaddle_Event],eax

  sub  esp,16
  call CreateEvent
  mov  [tDVP_Event],eax

  sub  esp,16
  call CreateEvent
  mov  [tNet_Event],eax
  end;


  if not tHandLogMode then
     begin
     SetTimer(tr4whandle, ONE_SECOND_TIMER_HANDLE, 1000, @OneSecTimerProc);
     SetTimer(tr4whandle, BANDMAP_REFRESH_TIMER_HANDLE, 250, @BandMapRefreshTimerProc);
     for c := menu_alt_increment_time_1 to menu_alt_increment_time_0 do EnableMenuItem(tr4w_main_menu, c, MF_GRAYED + MF_BYCOMMAND);
     end
  else
     begin
     showwarning('HAND LOG MODE = TRUE');
     end;

//  wkLoadSettings;
   if WinKeySettings.wksWinKey2Enable then
      begin
      logger.Info('Calling tCreateThread from WinKeyer');
      tCreateThread(@wkOpen, wkThreadID);
      logger.Info('Created WinKeyer thread with threadid of %d',[wkThreadID] );
      end;

   if YCCCSo2rEnable then
      begin
      logger.Info('Opening YCCC SO2R box');
      if not YCCCOpen then
         logger.Warn('YCCC SO2R box not found or failed to open');
      end;

{$IF MIXWMODE}
  tEnableMenuItem(menu_windows_mmtty, MF_ENABLED);
{$IFEND}

  CD.MasterFileExists := FileExists(CD.ActiveFilename);

  if not CD.MasterFileExists then
  begin
    Format(QuickDisplayBuffer, 'TRMASTER.DTA : %s', SysErrorMessage(GetLastError));
    QuickDisplay(QuickDisplayBuffer);
  end;

{$IF not tDebugMode}
  Windows.CopyMemory(@TR4W_LATESTCFG_FILENAME, @TR4W_CFG_FILENAME, SizeOf(FileNameType));
//  Windows.CharLower(TR4W_LATESTCFG_FILENAME);
  Windows.WritePrivateProfileString(_COMMANDS, LATEST_CONFIG_FILE, TR4W_LATESTCFG_FILENAME, TR4W_INI_FILENAME);
{$IFEND}

{$IF NEWER_DEBUG}
  //QuickDisplay('Warning - This is a Debug version');
{$IFEND}
  if CPUKeyer.SerialPortDebug then
    ShowMessage('Command SERIAL PORT DEBUG is no longer supported.'#13#10'Use instead Portmon program:'#13#10'http://technet.microsoft.com/sysinternals/bb896644.aspx');

  if MyGrid = '' then
    SetCommand('MY GRID');

//  Format(wsprintfBuffer, 'cty.dat: "%s" version', CTY.ctyTable[cty.ctyVersion].Name);
//  SetMainWindowText(mweBeamHeading, wsprintfBuffer);

{$IF tKeyerDebug}
//  CreateModalDialog(150, 90, tr4whandle, @KeyerDebugDlgProc, 0);
//  CreateDialog(hInstance, MAKEINTRESOURCE(72), 0, @KeyerDebugDlgProc);
  CreateDialogIndirectParam(hInstance, PDlgTemplate(@MAINTR4WDLGTEMPLATE)^, tr4whandle, @KeyerDebugDlgProc, 0);
  FrmSetFocus;

{$IFEND}

{$IF MORSERUNNER}
  GetMorseRunnerWindow;
{$IFEND}


   if WSJTXEnabled then
      begin
   // Send colors for Dupes (QSOB4)

   wsjtx.SetDupeBackgroundColor(ColorToRGB(tr4wColorsArray[TWindows[mweQSOB4Status].mweBackG]));
   wsjtx.SetDupeForegroundColor(ColorToRGB(tr4wColorsArray[TWindows[mweQSOB4Status].mweColor]));

   // Send colors for multipliers
   wsjtx.SetMultBackgroundColor(ColorToRGB(tr4wColorsArray[TWindows[mweNewMultStatus].mweBackG]));
   wsjtx.SetMultForegroundColor(ColorToRGB(tr4wColorsArray[TWindows[mweNewMultStatus].mweColor]));

   wsjtx.SendColorization := WSJTXSendColorization;
   if WSJTXEnabled then     // This boolean is in uCFG (default to true). This is so we start if the parameter is not set.
      begin
      wsjtx.Start;
      end;
   end;
    {****************************  Main CallBack  ****************************}

  while (GetMessage(Msg, 0, 0, 0)) do
  begin

    // Issue #23 -- when a clipboard/edit key (Ctrl-C/V/X/A/Z) is pressed with
    // the DX Cluster command field focused, skip the main accelerator table so
    // the keystroke reaches the field (e.g. Ctrl-V pastes) instead of firing
    // Execute Config File / Clear Mult Sheet.
    if (not TelnetWantsClipboardKey(Msg)) and
       (TranslateAccelerator(tr4whandle, tr4w_accelerators, Msg) <> 0) then
    begin
      asm nop end;
      goto NoTransMess;
    end;
    case Msg.Message of

      WM_CHAR:
        begin
          if (Char(Msg.wParam) = QuickQSLKey1) or (Char(Msg.wParam) = QuickQSLKey2) then QuickQSLProcedure(Char(Msg.wParam));
          if (Msg.HWND = wh[mweCall]) or (Msg.HWND = wh[mweExchange]) then
          begin
            if (Msg.HWND = wh[mweCall]) then
               begin
               CallWindowKeyDownProc(Msg.wParam);
               if CallWindowCharConsumed then
                  begin
                  CallWindowCharConsumed := False;
                  goto NoTransMess;
                  end;
               end
            else if Msg.HWND = wh[mweExchange] then       // ny4i Issue 87
               begin
               ExchangeWindowKeyDownProc(Msg.wParam);     // 4.102.7
               end;
              if KeyboardCallsignChar(Msg.wParam, boolean(ActiveMainWindow) {tr4w_ExchangeWindowActive}) = False then
               begin
               goto NoTransMess;
               end;
          end;
        end;

      WM_SYSKEYDOWN, WM_KEYDOWN:
        begin

          if KeypadCWMemories then
            if Msg.wParam in [VK_NUMPAD0..VK_NUMPAD9] then
            begin
              if Msg.wParam <> VK_NUMPAD0 then
                ProcessFuntionKeys(Msg.wParam + 27)
              else
                ProcessFuntionKeys(Msg.wParam + 37);
              goto NoTransMess;
            end;

          if (Msg.HWND = wh[mweEditableLog]) and (Msg.wParam = VK_DOWN) then
            if ListView_GetNextItem(wh[mweEditableLog], LVNI_ALL, LVNI_SELECTED) = tLogIndex - 1 then
              tCallWindowSetFocus;

          if (Msg.HWND = wh[mweCall]) or (Msg.HWND = wh[mweExchange]) then
          begin
            // Ctrl+= : repeat the exact characters last sent on CW (call +
            // exchange windows, CW mode).  '=' alone is QUICK QSL KEY 2, so a
            // bare key collides; a Ctrl combo avoids that and is dispatched
            // here like the other WM_KEYDOWN shortcuts, then fully consumed.
            if (Msg.wParam = 187 {VK_OEM_PLUS '='}) and (ActiveMode = CW) and
               ((GetKeyState(VK_CONTROL) and $8000) <> 0) then
            begin
              RepeatLastCWMessage;
              goto NoTransMess;
            end;
            if Msg.wParam in [VK_F1..vk_f12] then ProcessFuntionKeys(Msg.wParam);
            if Msg.wParam = VK_F4 then goto NoTransMess;
            if Msg.wParam > 40 then goto TransMess;
            if Msg.wParam = VK_RIGHT {39} then if Msg.HWND = wh[mweExchange] then TryPutSpaceinExchangeWindow;
            if Msg.wParam = VK_PRIOR {33} then ProcessMenu(menu_cwspeedup);
            if Msg.wParam = VK_NEXT {34} then ProcessMenu(menu_cwspeeddown);
            if Msg.wParam = VK_SPACE {32} then if Msg.HWND = wh[mweCall] then
              begin
                SpaceBarProc2;
//                if ActiveRadioPtr^.CWByCAT then BackToInactiveRadioAfterQSO;
                goto NoTransMess;
              end;

            if (Msg.wParam = VK_UP)                                      and
               (ActiveMainWindow = awCallWindow {tr4w_CallWindowActive}) and
               (CallWindowString = '')                                   then
                begin
                if tLogIndex <> 0 then
                   begin
                   tAltE;
                   end;
                end;

            if (Msg.wParam = VK_UP {38}) or (Msg.wParam = VK_DOWN {40}) then
            begin
              ProcessTAB(0);
              Msg.wParam := 0;
            end;
            if {18} Msg.wParam = VK_MENU then ShowFMessages(24);
            if {17} Msg.wParam = VK_CONTROL then

              ShowFMessages(12);


  if Msg.wParam = VK_SHIFT  then
            begin
              if ShiftKeyEnable then    // 4.105.6
                {*in S&P the shift key tunes the K3 VFO with the RIT or XIT on, but RIT/XIT do not change
                  ?In RUN mode the shift key should tune the RIT and not the xmit VFO...  but the VFO DISPLAY must change to show the RX frequency
                *}
              begin
                if lobyte(HiWord(Msg.lParam)) = 42 then
                if OpMode = CQOpMode then      // 4.97.3
                {RITBumpDown;} RITBumpDown
                  else        // 4.105.6
                   VFOBumpDown;
                if lobyte(HiWord(Msg.lParam)) = 54 then
                 if OpMode = CQOpMode then       // 4.97.3
                 {RITBumpUp;} RITBumpUp
                  else
                   VFOBumpUP;
                end;
              end;
            end;
          end;

      WM_KEYUP:
        begin
      {    if (Msg.wParam = VK_SPACE) and (Msg.HWND = wh[mweCall]) then           //   4.102.4
          tailend;       }
          if (Msg.wParam = VK_CONTROL) or (Msg.wParam = VK_MENU) then ShowFMessages(0);
          if Msg.wParam < 40 then goto TransMess;

          if Msg.HWND = wh[mweCall] then
          begin

            if Msg.wParam = 222 then
            begin
              if StartSendingNowKey = '''' then
                StartSendingNow(True);
              goto NoTransMess;
            end;

                //                CallWindowKeyDownProc(Msg.wParam);

          end;

          if Msg.HWND = BandMapListBox then
          begin
            if Msg.wParam = VK_DELETE then DeleteSpotFromBandmap;
{ $ I F  O L DCTRLJ}
            if Msg.wParam in [66, 77, 68, 80, 206] then
            begin
              if Msg.wParam = 66 then InvertBoolean(BandMapAllBands);
              DisplayBandMap; //ProcessInput(BAB);
             if Msg.wParam = 77 then InvertBoolean(BandMapAllModes) ;
              DisplayBandMap; //ProcessInput(BAM);
              if Msg.wParam = 68 then InvertBoolean(BandMapDupeDisplay);
              DisplayBandMap; //ProcessInput(BDD);
              if Msg.wParam = 206 then InvertBoolean(BandMapSO2RDisplay);
              DisplayBandMap; //ProcessInput(BDD);
            end;
{ $ I F END}
          end;
        end;

      WM_SYSKEYUP:
        begin
          if (Msg.wParam = VK_MENU) then
          begin
            ShowFMessages(0);
            //if Cardinal(Msg.lParam) and 16777216 = 0 then goto NoTransMess;
          end;
          if Msg.wParam = VK_F10 then goto NoTransMess;
        end;

      WM_MOUSEMOVE:
        begin
//          SendMessage(hwndTT, TTM_RELAYEVENT, 0, integer(@Msg));
        end;

      WM_RBUTTONDBLCLK:
        begin
          GetButtonByRDblClick(Msg.HWND);
        end;

      WM_RBUTTONDOWN:
        begin
          // Issue #1001: right-click a function-key button -> context menu to
          // edit that key's message (CQ vs S&P aware). No-op elsewhere.
          ShowFunctionKeyContextMenu(Msg.HWND);
        end;
{
      WM_RBUTTONDOWN:
        begin
          if Msg.HWND = wh[mweBandMode] then ProcessMenu(75857);
          if Msg.HWND = CodeSpeedWindowHandle then ProcessMenu(76039);
        end;

      WM_LBUTTONDOWN:
        begin
          if Msg.HWND = wh[mweBandMode] then ProcessMenu(75858);
          if Msg.HWND = CodeSpeedWindowHandle then ProcessMenu(76040);
        end;

      WM_MBUTTONDOWN:
        if Msg.HWND = wh[mweBandMode] then ProcessMenu(75859);

      WM_LBUTTONDBLCLK:
        begin
          if (Msg.HWND = wh[mweClock]) or (Msg.HWND = wh[mweDate]) then ProcessMenu(75851);
          if (Msg.HWND = PaddleWindowHandle) or (Msg.HWND = FootSwWindowHandle) then ProcessMenu(menu_lpt);

//          Windows.GetWindowText(Msg.HWND, @wsprintfBuffer, 100);
//          GetTextFace(windows.GetDC (Msg.HWND), 100, @wsprintfBuffer);
//          ShowMessage(wsprintfBuffer);

        end;
}
    end; //of case
    TransMess:
      //      inc(Tw);
    TranslateMessage(Msg);
    DispatchMessage(Msg);
    NoTransMess:
//  except sm end;
  end;
  finally
     // Issue #783 -- stop the HamScore RTC uploader cleanly so the worker
     // thread isn't holding sockets when the process exits.
     HamScoreShutdown;
     if Assigned(iniFile) then
        begin
        iniFile.Free;
        //Pointer(TINIFile(iniFile)) := nil;
        end;
  end; // of Try...finally

end.
