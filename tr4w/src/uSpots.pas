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
unit uSpots;
{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  uDupesheet,
  LogStuff,
  WinSock2,
  Windows,
  Messages,
  LogDupe,
  LogEdit,
  LogPack,
  LogRadio,
  LogSCP,
  Tree,
  SyncObjs;

type

  PSpotsList = ^TSpotsList;
  TSpotsList = array[0..1000] of TSpotRecord;

  PSpotsListBuffer = ^TSpotsListBuffer; // Gav 4.45.6
  TSpotsListBuffer = array[0..1000] of TSpotRecord; // Gav 4.45.6

  TDXSpotsList = object {class}

  private
    FList: PSpotsList;
    FCount{, j}: integer;
    FCurrentCursorFreq: integer;
    FCapacity: integer;
    BList: PSpotsListBuffer; // Gav 4.45.6
    BCount: integer; // Gav 4.45.6
    BCapacity: integer; // Gav 4.45.6
    FCriticalSection: TCriticalSection;
    procedure Grow;
    procedure GrowBuffer; // Gav 4.45.6


  protected
    function GetCapacity: integer;
    procedure SetCapacity(NewCapacity: integer);
    procedure SetCapacityBuffer(NewCapacity: integer); // Gav 4.45.6
    function CompareStrings(const s1, s2: CallString): integer;
    procedure InsertSpot(Index: integer; const Spot: TSpotRecord); virtual;
    procedure InsertSpotBuffer(Index: integer; const Spot: TSpotRecord); virtual;
      // Gav 4.45.6

  public
    //destructor Destroy; override;
    constructor Init;
    function Get(Index: integer): TSpotRecord;
    function AddSpot(var Spot: TSpotRecord; SendToNetwork: boolean): integer;
    procedure Clear;
    procedure SendAndClearBuffer;
    procedure SetCursor;
    procedure DecrementSpotsTimes;
    procedure UpdateSpotsMultiplierStatus;
    procedure UpdateSpotsDupeStatus(RXCall: CallString; RXBand: BandType;
      RXMode: ModeType);
    procedure Display;
    procedure Delete(Index: integer);
    //    procedure ClearDupes;
    procedure ResetSpotsTimes;
    procedure ResetSpotsDupes;

    procedure DisplayCallsignOnThisFreq(Freq: integer);
    procedure TuneDupeCheck(Freq: integer);
    function FindSpot(const Spot: TSpotRecord; var Index: integer): boolean;
      virtual;
    property Count: integer read FCount;
  end;

var
  SpotsList: TDXSpotsList;
  SpotsDisplayed: integer;

implementation
uses
  SysUtils,   // Issue #997: Format/StrPCopy
  LOGSUBS2,
  MainUnit,
  uNet,
  uBandmap,
  LogWind;

{ TStringList }

constructor TDXSpotsList.Init;
begin
  Grow;
  GrowBuffer; // Gav 4.45.6
  FCriticalSection := TCriticalSection.Create;
end;

//destructor TDXSpotsList.Destroy;
//begin
//   FreeAndNil(FCriticalSection);
//end;

function TDXSpotsList.AddSpot(var Spot: TSpotRecord; SendToNetwork: boolean):
  integer;
label
  add;
var
  i: integer;
  //ie: str80;

begin

  SetCursor;
  ie_check := False;
  if BandMapPreventRefresh then
    exit;
  if BandMapSO2RDisplay then
    if ((Radio1.FilteredStatus.Freq <> 0) and (Radio2.FilteredStatus.Freq <> 0))
      then
      if ((ActiveBand <> Spot.Fband) and (InactiveRadioptr.BandMemory <>
        Spot.Fband)) then
        exit; // 4.105.14
  for i := 0 to FCount - 1 do
  begin
    // 4.102.5 - filter the added spots to match the actual bm display

    if not BandMapAllBands then
      if FList^[i].FBand <> BandmapBand then
        Continue; //Gav  ActiveBand changed to BandmapBand
    if not BandMapAllModes then
      if FList^[i].FMode <> BandmapMode then
        Continue; //Gav  ActiveMode changed to BandmapMode
    if not BandMapDupeDisplay then
      if FList^[i].FDupe then
        Continue;
    if not BandMapDisplayCQ then
      if FList^[i].FCQ then
        Continue;
    if not WARCBandsEnabled then
      if FList^[i].FWARCBand then
        Continue;
    //if TwoRadioMode then
    if ((ActiveBand <> Spot.Fband) and (InactiveRadioptr.BandMemory <>
      Spot.Fband)) then
      Continue;
    if BandMapMultsOnly then
      if not ((FList^[i].FMult) or (FList^[i].FCQ)) then
        Continue; //Gav added or FCQ to stop CQ spots being trapped by Mult only filter
    if not VHFBandsEnabled then
      if (FList^[i].FBand > Band12) then
        Continue;
    if (FList^[i].FBand = Spot.FBand) and (FList^[i].FCall = Spot.FCall) then
      continue;
  end;
  if Spot.FBand in [Band30, Band17, Band12] then
    Spot.FWARCBand := True;
  if (IE_Switch) then
  begin
    ie_check := True;
    if (InitialExchangeEntry(Spot.FCall) = '') then
      exit;
  end;

  if FindSpot(Spot, Result) then
    goto Add;
  FCriticalSection.Enter;
  try
     InsertSpot(Result, Spot);
  finally
     FCriticalSection.Leave;
  end;
  Add:    // How to experienced programmers write GoTo statements? I don't get it! // ny4i
  FList^[Result] := Spot;
  //  if CallWinKeyDown then
  //   Windows.SetFocus(wh[mweCall]);
  // end;

  if SendToNetwork then
    if PInteger(@Spot.FCall[1])^ <> tCQAsInteger then
      if NetSocket <> 0 then
      begin
        NetDXSpot.dsSpot := Spot;
        SendToNet(NetDXSpot, SizeOf(NetDXSpot));
      end;

end;

procedure TDXSpotsList.Display;
var
  FiltSpotIndex: array of Integer;
  FilteredSpotCount: integer;
  k: integer;
  i: integer;
  bottom: integer;
  top: integer;
  centre: integer;
  centrefound: boolean;
  CurrentCursorPos: integer;
  //    CurCursorPosData                     : integer;
  NumberEntriesDisplayed: integer;
  // Diagnostic counters -- per-filter rejection tallies (issue: bandmap-startup-clear).
  // Total of all reject* + rejNoNext + NumberEntriesDisplayed should equal FCount.
  rejDupeNext, rejBand, rejMode, rejDupeFlag, rejCQ, rejWARC, rejMultsOnly, rejVHF: Integer;
begin
  bottom := 0;
  top := 1;
  centrefound := False; // 4.79.3
  rejDupeNext := 0; rejBand := 0; rejMode := 0; rejDupeFlag := 0;
  rejCQ := 0; rejWARC := 0; rejMultsOnly := 0; rejVHF := 0;
  //  inc(SpotsDisplayed);
  //  setwindowtext(OpModeWindowHandle,inttopchar(SpotsDisplayed));
  if BandMapListBox = 0 then
    begin
    logger.Trace('[SpotsList.Display] exit: BandMapListBox=0');
    Exit;
    end;
  if BandMapPreventRefresh then
    begin
    logger.Trace('[SpotsList.Display] exit: BandMapPreventRefresh=True');
    Exit; // Gav 4.45.6
    end;
  TDXSpotsList.UpdateSpotsMultiplierStatus;
  CurrentCursorPos := tLB_GETCURSEL(BandMapListBox); //0;
  setlength(FiltSpotIndex, FCount);
  NumberEntriesDisplayed := 0;
  k := 0;
  for i := 0 to FCount - 1 do
  begin
    if (FList^[i].FCall = FList^[i + 1].FCall) then
      begin
      Inc(rejDupeNext);
      continue;
      end;
    if not BandMapAllBands then
      if FList^[i].FBand <> BandmapBand then
        begin
        Inc(rejBand);
        Continue; //Gav  ActiveBand changed to BandmapBand
        end;
    if not BandMapAllModes then
      if FList^[i].FMode <> BandmapMode then
        begin
        Inc(rejMode);
        Continue; //Gav  ActiveMode changed to BandmapMode
        end;
    if not BandMapDupeDisplay then
      if FList^[i].FDupe then
        begin
        Inc(rejDupeFlag);
        Continue;
        end;
    if not BandMapDisplayCQ then
      if FList^[i].FCQ then
        begin
        Inc(rejCQ);
        Continue;
        end;
    if not WARCBandsEnabled then
      if FList^[i].FWARCBand then
        begin
        Inc(rejWARC);
        Continue;
        end;
    if BandMapMultsOnly then
      if not ((FList^[i].FMult) or (FList^[i].FCQ)) then
        begin
        Inc(rejMultsOnly);
        Continue; //Gav added or FCQ to stop CQ spots being trapped by Mult only filter
        end;
    if not VHFBandsEnabled then
      if (FList^[i].FBand > Band12) then
        begin
        Inc(rejVHF);
        Continue;
        end;

    // SendMessage(BandMapListBox, LB_ADDSTRING, 0, integer(i));         //GAV original message send

    if FList^[i].FFrequency = FCurrentCursorFreq then
      CurrentCursorPos := NumberEntriesDisplayed;
    FiltSpotIndex[k] := i;
    inc(NumberEntriesDisplayed);
    inc(k);

  end;
  logger.Trace('[SpotsList.Display] filter pass: FCount=%d, passed=%d, rejected by: NextDup=%d Band=%d Mode=%d DupeFlag=%d CQ=%d WARC=%d MultsOnly=%d VHF=%d',
    [FCount, NumberEntriesDisplayed, rejDupeNext, rejBand, rejMode, rejDupeFlag,
     rejCQ, rejWARC, rejMultsOnly, rejVHF]);

  //Gav   Start of added section to limit and centre bandmap on vfo, using pointers to Flist stored in FiltSpotIndex arrray

  FilteredSpotCount := k;

  if k > BandMapDisplayLimit then
  begin
    if FList^[0].FFrequency >= BandMapCursorFrequency then
    begin
      top := BandMapDisplayLimit - 1;
      bottom := 0;
      centrefound := true;
    end;

    if FList^[FilteredSpotCount].FFrequency <= BandMapCursorFrequency then
    begin
      top := FilteredSpotCount - 1;
      bottom := FilteredSpotCount - BandMapDisplayLimit;
      centrefound := true;
    end;

    for k := 0 to k - 1 do
    begin
      if FList^[FiltSpotIndex[k]].FFrequency > BandMapCursorFrequency then
      begin
        centre := k;
        if (centre >= (BandMapDisplayLimit div 2)) and (centre <=
          (FilteredSpotCount - (BandMapDisplayLimit div 2))) then
        begin
          top := centre + ((BandMapDisplayLimit div 2) - 1);
          bottom := centre - (BandMapDisplayLimit div 2);
          centrefound := true;
        end;
        if centre > (FilteredSpotCount - (BandMapDisplayLimit div 2)) then
        begin
          top := FilteredSpotCount - 1;
          bottom := FilteredSpotCount - BandMapDisplayLimit;
          centrefound := true;
        end;
        if centre < (BandMapDisplayLimit div 2) then
        begin
          top := BandMapDisplayLimit - 1;
          bottom := 0;
          centrefound := true;
        end;
        break;
      end;
    end;

    if (centrefound <> true) then
    begin
      centre := abs((k - 1) div 2);
      top := centre + ((BandMapDisplayLimit div 2) - 1);
      bottom := centre - (BandMapDisplayLimit div 2);
    end;
  end

  else
  begin
    top := k - 1;
    bottom := 0;
  end;

  tSetWindowRedraw(BandMapListBox, False);
  tLB_RESETCONTENT(BandMapListBox);
  SendMessage(BandMapListBox, LB_INITSTORAGE, k, 10000);
  for k := bottom to top do
    SendMessage(BandMapListBox, LB_ADDSTRING, 0, FiltSpotIndex[k]);
  tLB_SETCURSEL(BandMapListBox, CurrentCursorPos);
  tSetWindowRedraw(BandMapListBox, True);
  logger.Trace('[SpotsList.Display] listbox populated: bottom=%d, top=%d, items_added=%d, CurrentCursorPos=%d, BandMapDisplayLimit=%d',
    [bottom, top, top - bottom + 1, CurrentCursorPos, BandMapDisplayLimit]);
  // WM_SETREDRAW(True) causes the list box to queue an erase+paint, which
  // produces a visible flash. Cancel the pending erase, then repaint
  // immediately without erasing — owner-draw items fill their own background.
  ValidateRect(BandMapListBox, nil);
  RedrawWindow(BandMapListBox, nil, 0, RDW_INVALIDATE or RDW_NOERASE or RDW_UPDATENOW);
  // Issue #997: asm-push wsprintf -> SysUtils.Format (TC_SPOTS = '%d spots').
  StrPCopy(wsprintfBuffer, SysUtils.Format(TC_SPOTS, [NumberEntriesDisplayed]));
  SetTextInBMSB(5, wsprintfBuffer);
  if NumberEntriesDisplayed = 0 then
    ClearSpotInfo;

end;

// Gav end of section added

procedure TDXSpotsList.Clear;
begin
  FCriticalSection.Enter;
  try
     if FCount <> 0 then
        begin
        FCount := 0;
        SetCapacity(0);
        end;
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.SendAndClearBuffer; // Gav 4.45.6
var
  i: integer;
begin
  if BCount <> 0 then
  begin
    i := BCount;
    for i := 0 to i - 1 do
    begin
      AddSpot(BList^[i], False)
    end;
  end;
  BCount := 0;
end;

procedure TDXSpotsList.Delete(Index: integer);
begin
  if (Index < 0) or (Index >= FCount) then
    Exit; //Error(@SListIndexError, Index);
  try
     dec(FCount);
     if Index < FCount then
        begin
        System.Move(FList^[Index + 1], FList^[Index], (FCount - Index) * SizeOf(TSpotRecord));
        end;
  finally
     FCriticalSection.Leave;
  end;
end;

function TDXSpotsList.FindSpot(const Spot: TSpotRecord; var Index: integer):
  boolean;
var
  l, h, i, c: integer;
begin
  Result := False;
  l := 0;
  h := FCount - 1;
  while l <= h do
  begin
    i := (l + h) shr 1;
    c := FList^[i].FFrequency - Spot.FFrequency;
      //CompareStrings(FList^[I].FCall, s);
    if c < 0 then
      l := i + 1
    else
    begin
      h := i - 1;
      if c = 0 then
      begin
        Result := True;
        l := i;
      end;
    end;
  end;
  Index := l;
end;

function TDXSpotsList.Get(Index: integer): TSpotRecord;
begin
  FillChar(Result, SizeOf(Result), 0); // ny4i Test to return null Issue #115
  if (Index < 0) or (Index >= FCount) then
    Exit; //ERROR(@SListIndexError, Index);
  Result := FList^[Index];
end;

function TDXSpotsList.GetCapacity: integer;
begin
  Result := FCapacity;
end;

procedure TDXSpotsList.UpdateSpotsMultiplierStatus;
var
  i: integer;
begin
  for i := 0 to FCount - 1 do
  begin

    if PInteger(@FList^[i].FCall[1])^ <> tCQAsInteger then
      if PInteger(@FList^[i].FCall[1])^ <> tNEWAsInteger then
        FList^[i].FMult := VisibleLog.DetermineIfNewMult(FList^[i].FCall,
          FList^[i].FBand, FList^[i].FMode);
    //    FList^[i].FMult := MultString <> 0;
  end;
  //  Display;
end;

procedure TDXSpotsList.DecrementSpotsTimes;
label
  NextSpot;
var
  i: integer;
  CurrentTime: integer;
  Difference: integer;
  St: SYSTEMTIME;
begin
  if FCount = 0 then
    Exit;
  GetSystemTime(St);
  CurrentTime := St.wMinute + St.wHour * 60 + St.wDay * 60 * 24 + St.wMonth * 60
    * 24 * 30;

  i := 0;
  NextSpot:

  Difference := CurrentTime - FList^[i].FSysTime;
  FList^[i].FMinutesLeft := Difference;
  if Difference >= BandMapDecayTime then
    Delete(i)
  else
    inc(i);
  if i = FCount then
    Exit;
  goto NextSpot;
end;

procedure TDXSpotsList.UpdateSpotsDupeStatus(RXCall: CallString; RXBand:
  BandType; RXMode: ModeType);
var
  i: integer;
begin
  for i := 0 to FCount - 1 do
  begin
    if FList^[i].FBand = RXBand then
      if FList^[i].FMode = RXMode then
        if FList^[i].FCall = RXCall then
          FList^[i].FDupe := True;
  end;
  Display;
end;

procedure TDXSpotsList.Grow;
var
  delta: integer;
begin
  if FCapacity > 64 then
    delta := FCapacity div 4
  else if FCapacity > 8 then
    delta := 16
  else
    delta := 4;
  SetCapacity(FCapacity + delta);
end;

procedure TDXSpotsList.GrowBuffer; // Gav 4.45.6
var
  delta: integer;
begin
  if BCapacity > 64 then
    delta := BCapacity div 4
  else if BCapacity > 8 then
    delta := 16
  else
    delta := 4;
  SetCapacityBuffer(BCapacity + delta);
end;

procedure TDXSpotsList.InsertSpot(Index: integer; const Spot: TSpotRecord);
begin
  FCriticalSection.Enter;
  try
     if FCount = FCapacity then
        begin
        Grow;
        end;
     if Index < FCount then
        begin
        System.Move(FList^[Index], FList^[Index + 1],(FCount - Index) * SizeOf(TSpotRecord));
        end;
     FList^[Index] := Spot;
     inc(FCount);
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.InsertSpotBuffer(Index: integer; const Spot: TSpotRecord);
  // Gav 4.45.6
begin
  FCriticalSection.Enter;
  try
     if BCount = BCapacity then
       GrowBuffer;
     if Index < BCount then
       System.Move(BList^[Index], BList^[Index + 1],
         (BCount - Index) * SizeOf(TSpotRecord));
     BList^[Index] := Spot;
     inc(BCount);
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.SetCapacity(NewCapacity: integer);
begin
  ReallocMem(FList, NewCapacity * SizeOf(TSpotRecord));
  FCapacity := NewCapacity;
end;

procedure TDXSpotsList.SetCapacityBuffer(NewCapacity: integer); // Gav 4.45.6
begin
  ReallocMem(BList, NewCapacity * SizeOf(TSpotRecord));
  BCapacity := NewCapacity;
end;

function TDXSpotsList.CompareStrings(const s1, s2: CallString): integer;
var
  L1, L2, l, i: integer;
begin
  L1 := length(s1);
  L2 := length(s2);
  if L1 > L2 then
    l := L2
  else
    l := L1;
  for i := 1 to l do
  begin
    Result := Ord(s1[i]) - Ord(s2[i]);
    if Result <> 0 then
      Exit;
  end;
  if Result = 0 then
    Result := L1 - L2;

  //  Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @s1[1], length(s1), @s2[1], length(s2)) - 2;

end;

procedure TDXSpotsList.ResetSpotsTimes;
var
  Index: integer;
begin
  FCriticalSection.Enter;
  try
     if Assigned(FList) then
     begin
       for Index := 0 to FCount - 1 do
       begin
         FList^[Index].FMinutesLeft := 0;
       end;
     end;
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.ResetSpotsDupes;
var
  Index: integer;
begin
  FCriticalSection.Enter;
  try
     if Assigned(FList) then
     begin
       for Index := 0 to FCount - 1 do
       begin
         FList^[Index].FDupe := False;
       end;
     end;
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.SetCursor;
begin
  FCriticalSection.Enter;
  try
     if BandMapListBox <> 0 then
     begin
       FCurrentCursorFreq := GetBMSelItemData;
       if FCurrentCursorFreq <> LB_ERR then
       begin
         if Assigned(FList) then
         begin
           FCurrentCursorFreq := FList^[FCurrentCursorFreq].FFrequency;
         end
         else
         begin
           DebugMsg('FList was nil in SetCursor');
         end;
       end;
     end;
  finally
     FCriticalSection.Leave;
  end;
end;

procedure TDXSpotsList.TuneDupeCheck(Freq: integer);
var
  Index: integer;
  Index2: integer;
  d: integer;
  a: integer;
begin
  if not BandMapEnable then
    Exit;
  if not Assigned(FList) then
  begin
    exit;
  end;

  d := MAXLONG;
  //  Index2 := 0; // 4.79.3
  for Index := 0 to FCount - 1 do
  begin
    a := Abs(FList^[Index].FFrequency - Freq);
    if a = 0 then
      exit;
    if (a < BandMapGuardBand) and (PInteger(@FList^[Index].FCall[1])^ <>
      tCQAsInteger) then
    begin
      if (a < d) then
      begin
        d := a;
        Index2 := Index;
      end;
      DupeInfoCall := FList^[Index2].FCall;
      break; // stop search on match 4.130.1
    end;
  end;
  if (d >= BandMapGuardBand) or (Pos(MyCall, Flist^[Index2].FCall) > 0) then
    // 4.57.8  // 4.72.1
  begin
    ClearAltD;
    tClearDupeInfoCall;

  end;

  if d <= BandMapGuardBand then
  begin
    {  if not SprintQSYRule then
       begin
        switch := False;    // n4af 4.56.1
        switchnext := False;
       end;   }
    tClearDupeInfoCall; // 4.57.10
    ClearAltD; // 4.65.2
    DupeInfoCall := FList^[Index2].FCall; // 4.65.2
    DupeCheckOnInactiveRadio(True);
    DupeInfoCallWindowCleared := False;
    tCallWindowSetFocus;
  end;
end;

procedure TDXSpotsList.DisplayCallsignOnThisFreq(Freq: integer);
var
  Index: integer;
  Index2: integer;
  d: integer;
  a: integer;
begin
  if not BandMapEnable then
    Exit;
  if not BandMapCallWindowEnable then
    Exit;
  if CallsignIsTypedByOperator then
    Exit;

  d := MAXLONG;
  //  index2 := 0; // 4.79.3
  for Index := 0 to FCount - 1 do
  begin
    a := Abs(FList^[Index].FFrequency - Freq);
    {logger.debug('[TDXSpotsList.DisplayCallsignOnThisFreq] a = %d, BandMapGuardBand = %d,  PInteger(@FList^[Index].FCall[1])^ = %d, tCQAsInteger = %d',
                  [a, BandMapGuardBand, PInteger(@FList^[Index].FCall[1])^, tCQAsInteger]);}
    if (a < BandMapGuardBand) and (PInteger(@FList^[Index].FCall[1])^ <>  tCQAsInteger) then
    begin
      if a < d then
      begin
        d := a;
        Index2 := Index;
      end;
    end;
  end;

  if d <= BandMapGuardBand then
  begin
    //if (Pos(MyCall,Flist^[Index2].FCall)>0) then continue;
    if FList^[Index2].FCall <> MyCall then
      if OpMode = SearchAndPounceOpMode then // n4af 4.45.10
      begin
        tCleareCallWindow;
        tClearDupeInfoCall; // 4.55.6
        PutCallToCallWindow(FList^[Index2].FCall);
        SendMessage(wh[mweCall], EM_SETSEL, 0, -1);
        CallsignIsPastedFromBandMap := True;
       // tSetExchWindInitExchangeEntry ; // 4.139.1
       // Windows.SetFocus(wh[mweCall]);      // 4.139.2
       end;


   Exit;
  end;

  if not CallWindowEmpty then
    if (CallsignIsPastedFromBandMap)  then
    begin
      tCleareCallWindow;
      tCleareExchangeWindow;
      //tCallWindowSetFocus;
    end
    else
     if CallWindowEmpty then
    begin
     tcleareExchangeWindow;
     tcleareCallWindow;
     tCallWindowSetFocus;
    end;

end;

begin
  //  SpotsList := TDXSpotsList.Create;
  SpotsList.Init;
  SpotsList.FCurrentCursorFreq := -1;
  tCallWindowSetFocus;    // 4.139.1
end.


