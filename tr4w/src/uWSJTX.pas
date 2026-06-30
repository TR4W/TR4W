{
 Copyright Thomas M. Schaefer, NY4I (c) 2020.
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
unit uWSJTX;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, IdComponent, IdUDPBase, IdUDPServer, IdTCPServer, IdUDPClient,
    IdContext,
  IdBaseComponent, IdSocketHandle, IdGlobal, IdStackConsts, StdCtrls,
  NetworkMessageUtils, DateUtils, StrUtils, LOGRADIO, IdThreadSafe, IdThread
  ;

type
  TColorRec = record
    R: byte;
    G: byte;
    B: byte;
  end;
type
  TWSJTXServer = class(TObject)
  private
    udpServ: TIdUDPServer;
    tcpServ: TIdTCPServer;
    started: boolean;
    peerPort: word;
    peerIP: string;   // source IP of the WSJT-X instance; colorization replies go here, not a hard-coded loopback
    FUDPPort: integer;
    FTCPPort: integer;
    SNR: LongInt;
    frequency: Int64;
    firstTime: boolean;
    isConnected: boolean;
    colorsMultFore: TColorRec;
    colorsDupeFore: TColorRec;
    colorsMultBack: TColorRec;
    colorsDupeBack: TColorRec;
    buffer: TIdBytes;
    sBuffer: string;
    TXKludge: boolean;
    txKludgeStart: TDateTime;
    RXKludge: boolean;
    FSendColorization: boolean;
    rxKludgeStart: TDateTime;
    processingCmdSplit: boolean;
    processingCmdSetTXFreq: boolean;
    processingCmdQSXSplit: boolean;
    processingCmdSetFreq: boolean;
    requestedTXFreq: extended;
    processingCmdSetFreqMode: boolean;
    slCQMessage: TStringList;
    sCallSentToWindow: string;
    procedure SetUDPPort(nPort: integer);
    procedure SetTCPPort(nPort: integer);
    function GetNextADIFField(var sBuffer: string; var fieldName: string; var
      fieldValue: string): boolean;
    procedure HandleMessage_Clear;
  protected
    procedure OnServerRead(ASender: TIdUDPListenerThread; const AData: TIdBytes;
      ABinding: TIdSocketHandle);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
  public
    constructor Create; overload;
    constructor Create(nUDPPort: integer; nTCPPort: integer); overload;
    //constructor Create(radio: radioObject); overload;
    procedure Start;
      // May want to add the port number to a constructor - for now use default
    procedure Stop;
    procedure JoinMulticastGroup(const AGroupIP: string);
    destructor Destroy;
    procedure HighlightCall(sCall: string; color: integer; sId: string);
    procedure ClearColors(sId: string);
    property connected: boolean read isConnected;

    //procedure SetDupeBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetDupeBackgroundColor(rgb: cardinal);
    //procedure SetMultBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetMultBackgroundColor(rgb: cardinal);

    //procedure SetDupeForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetDupeForegroundColor(rgb: cardinal);

    //procedure SetMultForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
    procedure SetMultForegroundColor(rgb: cardinal);

    function ConvertSNRToRST(snr: integer): integer;
    procedure Display(p_sender: string; p_message: string);

    property UDPPort: integer read FUDPPort write SetUDPPort;

    property TCPPort: integer read FTCPPort write SetTCPPort;

    property SendColorization: boolean read FSendColorization write
      FSendColorization;

  end;

const
  KLUDGESECONDSV = 2;
implementation

uses
  VC // For ContestExchange
  , MainUnit // For ParseADIFRecord
  , LogDupe // For ClearContestExchange - Stuff is all over the place in this code! de NY4I
  , uCTYDAT // For ctyLocateCall
  , utils_file // For tWriteFile
  , LOGSUBS2 // For LogContact
  , LogStuff // For CalculateQSOPoints
  , LogEdit // For ShowStationInformation and DetermineIfNewMult and DetermineIfNewDomesticMult
  , LOGWIND // for GetBandMapBandModeFromFrequency
  , TF // for SetMainWindowText
  , Tree // for LooksLikeAGrid
  , utils_text
  , LogK1EA // for tPTTViaCommand
  , LogDOM // for ActiveDomesticMult
  , uCFG // for WSJTXRadioControlEnabled
  , PostUnit
  , uCabrilloFormat // for tCabrilloFreqString (moved here from PostUnit; see uCabrilloFormat.pas)
  , IdStack // for GStack.AddMulticastMembership
  ;
// {$R *.dfm}

// Warn (non-modally) when the operator in a WSJT-X-logged ADIF record
// differs from TR4W's current operator -- the user may have changed the
// operator in one program but not the other.  The QSO is still logged
// as-is (with WSJT-X's operator); this only flags the mismatch so the
// user can reconcile it.  Banner + beep, never a modal dialog: FT4/FT8
// auto-sequences QSOs and the mismatch persists across all of them, so a
// per-QSO dialog would be unusable.
procedure WarnIfWSJTXOperatorMismatch(const adifOp, tr4wOp: OperatorType);
var
   msg, adifStr, tr4wStr : string;
begin
   // Trim so a blank or whitespace-only operator (e.g. a stray space
   // left in WSJT-X's Operator field, which arrives as <operator:1> )
   // is treated as "no operator" and never flags a mismatch.
   adifStr := Trim(string(PChar(@adifOp[0])));
   tr4wStr := Trim(string(PChar(@tr4wOp[0])));
   logger.Debug('[uWSJTX] op-mismatch check: ADIF=[%s] TR4W=[%s]',
                [adifStr, tr4wStr]);
   if (adifStr = '') or (tr4wStr = '') then
      Exit;
   if AnsiCompareText(adifStr, tr4wStr) = 0 then
      Exit;
   msg := 'OP MISMATCH: WSJT-X=' + adifStr + '  TR4W=' + tr4wStr;
   // QuickDisplayError = flashing QuickCommand banner + DoABeep, and it
   // auto-clears after ~30s.  (The bare SetTextInQuickCommandWindow used
   // before had no persistence, so the next status write overwrote it
   // before it could be seen.)
   QuickDisplayError(PChar(msg));
   logger.Warn('[uWSJTX] ' + msg);
end;

constructor TWSJTXServer.Create;
begin
  started := false;
  slCQMessage := TStringList.Create;
  FSendColorization := true;
  firstTime := true;
  udpServ := TIdUDPServer.Create(nil);
  udpServ.ThreadedEvent := true;
  // rsTrue causes TIdSocketHandle.Bind to call SetSockOpt(SO_REUSEADDR, True),
  // allowing JT-Alert (and other tools) to bind the same port simultaneously.
  udpServ.ReuseSocket := rsTrue;
  if FUDPPort = 0 then
  begin
    FUDPPort := 2237;
  end;

  if FTCPPort = 0 then
  begin
    FTCPPort := 52002;
  end;

  udpServ.DefaultPort := FUDPPort;
  udpServ.Bindings.Add.IP := '';
  udpServ.OnUDPRead := Self.OnServerRead;
  colorsDupeBack.R := $FF;
  colorsDupeBack.G := $00;
  colorsDupeBack.B := $00;

  colorsMultBack.R := $FF;
  colorsMultBack.G := $FF;
  colorsMultBack.B := $00;

  colorsDupeFore.R := $00;
  colorsDupeFore.G := $00;
  colorsDupeFore.B := $00;

  colorsMultFore.R := $00;
  colorsMultFore.G := $00;
  colorsMultFore.B := $00;


  if WSJTXRadioControlEnabled then
     begin
     logger.Debug('[WSJT-X]Creating tcpServ on port %d',[FTCPPort]);
     tcpServ := TIdTCPServer.Create(nil);
     logger.Debug('[WSJT-X] Created tcpServ on port %d',[FTCPPort]);
     tcpServ.OnExecute := Self.IdTCPServer1Execute;
     tcpServ.OnConnect := Self.IdTCPServer1Connect;
     tcpServ.OnDisconnect := Self.IdTCPServer1Disconnect;
     end;
end;

constructor TWSJTXServer.Create(nUDPPort: integer; nTCPPort: integer);
begin
  FUDPPort := nUDPPort;
  FTCPPort := nTCPPort;
  inherited Create;
end;

{constructor TWSJTXServer.Create(radio: radioObject);
begin
   inherited Create;
   Self.radio := radio;
end;
}
procedure TWSJTXServer.JoinMulticastGroup(const AGroupIP: string);
var
   i: Integer;
begin
   // Join the multicast group on every bound socket handle so the OS delivers
   // multicast datagrams to this socket.  SO_REUSEADDR (set via udpServ.ReuseSocket)
   // allows JT-Alert and other tools to bind the same port simultaneously.
   if not udpServ.Active then
      begin
      logger.Warn('[WSJT-X] JoinMulticastGroup called but UDP server not active');
      exit;
      end;
   if logger.IsInfoEnabled then
      logger.Info('[WSJT-X] Joining multicast group ' + AGroupIP);
   for i := 0 to udpServ.Bindings.Count - 1 do
      begin
      try
         GStack.AddMulticastMembership(udpServ.Bindings[i].Handle, AGroupIP, '0.0.0.0');
         if logger.IsInfoEnabled then
            logger.Info('[WSJT-X] Joined multicast group ' + AGroupIP +
                        ' on binding ' + IntToStr(i));
      except
         on E: Exception do
            if logger.IsWarnEnabled then
               logger.Warn('[WSJT-X] Failed to join multicast group ' + AGroupIP +
                           ' on binding ' + IntToStr(i) + ': ' + E.Message);
      end;
      end;
end;

procedure TWSJTXServer.Start;
begin
   if not started then
      begin
         try
            udpServ.Active := true;
            started := true;
            // Join multicast group if configured (e.g. '224.0.0.1' to match WSJT-X
            // default).  This allows JT-Alert and TR4W to both receive from WSJT-X
            // simultaneously.  Leave empty for legacy unicast/loopback operation.
            if WSJTXMulticastGroup <> '' then
               JoinMulticastGroup(WSJTXMulticastGroup);
         except
            on E: Exception do
               begin
               logger.Error('[WSJT-X] Exception binding UDP port ' + IntToStr(FUDPPort) + ': ' + E.Message);
               QuickDisplay(PChar('WSJT-X bind error port ' + IntToStr(FUDPPort) + ': ' + E.Message));
               end;
         end;

      if tcpServ <> nil then
         begin
         tcpServ.Bindings.Clear;
         tcpServ.MaxConnections := 1; // Just allow the single client
         tcpServ.Bindings.Add.Port := FTCPPort;
            try
               tcpServ.Active := true;
            except
               on E: Exception do
                  begin
                  logger.Error('Exception when making TCP server active - Is DX Commander running?: exception=%s', [E.Message]);
                  QuickDisplay('Error offering Commander proxy TCP Port');
                  end;
             end;
         end;
      end;
end;

procedure TWSJTXServer.Stop;
begin
  if started then
  begin
    udpServ.Active := false;
    if tcpServ <> nil then
       begin
       tcpServ.IOHandler.Shutdown;
       tcpServ.Active := false;
       end;
    started := false;
  end;
end;

destructor TWSJTXServer.Destroy;
begin
  udpServ.Active := false;
  FreeAndNil(udpServ);

  if tcpServ <> nil then
     begin
     tcpServ.IOHandler.Shutdown;
     tcpServ.Active := false;
     FreeAndNil(tcpServ);
     end;

  FreeAndNil(slCQMessage);

end;

procedure TWSJTXServer.SetUDPPort(nPort: integer);
begin
  Self.FUDPPort := nPort;
  if Self.udpServ.Active then
  begin
    Self.udpServ.active := false;
    udpServ.DefaultPort := Self.FUDPPort;
    try
       udpServ.Active := true;
    except
       logger.warn('Exception trying to make udpServ active');
    end;
  end;
end;

procedure TWSJTXServer.SetTCPPort(nPort: integer);
begin
  Self.FTCPPort := nPort;
end;

procedure TWSJTXServer.OnServerRead(ASender: TIdUDPListenerThread; const AData:
  TIdBytes; ABinding: TIdSocketHandle);
var
  index: Integer;
  magic, schema, messageType: LongInt;
  id, mode, DXCall, report, TXMode, message, DXGrid, DEGrid, DECall,
    reportReceived: string;
  call: CallString;
  TXPower, comments, DXName, adif: string;
  i: integer;
  foundCall: boolean;
  foundGrid: boolean;

  isNew, TXEnabled, transmitting, Decoding: Boolean;
  tm: Longword;
  ztime: TDateTime;
  DT: Double;
  DF: Cardinal;
  date: TDateTime;
  RXDF, TXDF: integer;
  TempRXData: ContestExchange;
  TempMode: ModeType;
  TempBand: BandType;
  TempFreq: integer;
  grid: string;
  nResult: integer;
  shortStr: shortString;
  len: integer;
  newMessage: string;
  n: integer;
  callIndex: integer;
  gridIndex: integer;

begin
  //FUDP.IdUDPServer1.Bindings := '127.0.0.1:2237,[::]:2237';
  index := 0;
  peerPort := ABinding.PeerPort;
  peerIP := ABinding.PeerIP;   // reply colorization to the instance that sent the decode (local or remote)
  newMessage := '';
  //  peerPort := 2237;

  while index < Length(AData) do
  begin
    Unpack(AData, index, magic);
    //DEBUGMSG('WSJTX >>> index:' + IntToStr(index) + ' magic:$' + IntToHex(magic,8));
    if (magic = LongInt($ADBCCBDA)) and (index < Length(AData)) then
    begin
      Unpack(AData, index, schema);
      if (schema = 2) and (index < Length(AData)) then
      begin
        Unpack(AData, index, messageType);
        Unpack(AData, index, id);
        if logger.IsTraceEnabled then
        begin
          logger.trace('[uWSJTX] Message type:' + IntToStr(messageType) +
            ' from:[' + id + ']');
        end;

        case messageType of
          WSJTX_MESSAGETYPE_HEARTBEATV:
            begin
              logger.trace('[uWSJTX] WSJTX >>> Heartbeat!');
              if logger.IsTraceEnabled then
              begin
                logger.trace('[uWSJTX] In UDP Heartbeat, Radio frequency = ' +
                  IntToStr(radio1.CurrentStatus.VFO[VFOA].Frequency));
              end;
              SetMainWindowText(mweWSJTX, 'WSJTX');
              Windows.ShowWindow(wh[mweWSJTX], SW_SHOW);
              isConnected := true;
              if firstTime then
                 begin
                ClearColors(id);
                firstTime := false;
                end;
            end;
          WSJTX_MESSAGETYPE_STATUSV:
            begin
              logger.trace('[uWSJTX] WSJTX_MESSAGETYPE_STATUSV message received');
              Unpack(AData, index, frequency);
              Unpack(AData, index, mode);
              Unpack(AData, index, DXCall);
              Unpack(AData, index, report);
              Unpack(AData, index, TXMode);
              Unpack(AData, index, TXEnabled);
              Unpack(AData, index, transmitting);

              Unpack(AData, index, Decoding);
              Unpack(AData, index, RXDF);
              Unpack(AData, index, TXDF);
              Unpack(AData, index, DECall);
              Unpack(AData, index, DEGrid);
              Unpack(AData, index, DXGrid);

              // Issue #978: with no radio defined, follow the WSJT-X dial
              // frequency to set the active band (band only, and only on an
              // actual change).  GoToBand applies the same multi-band gate
              // and display refresh as an Alt-B band change.
              if (ActiveRadioPtr.RadioModel = NoInterfacedRadio) and
                 (ActiveRadioPtr.tNetObject = nil) then
                begin
                GetBandMapBandModeFromFrequency(frequency, TempBand, TempMode);
                if (TempBand <> NoBand) and (TempBand <> ActiveBand) then
                  begin
                  logger.debug('[uWSJTX] No radio defined; following WSJT-X to band '
                    + string(BandStringsArray[TempBand]) + ' (' + IntToStr(frequency)
                    + ' Hz)');
                  GoToBand(TempBand);
                  end;
                end;

              if logger.IsTraceEnabled then
                begin
                logger.trace('[uWSJTX] WSJTX Status>>> Frequency: ' +
                  IntToStr(frequency) + ' Mode: ' + mode + ' DX Call: ' + DXCall
                  + ' Report: ' + report + ' TX Mode: ' + TXMode +
                    ' TX Enabled: ' + BooleanToStr(TXEnabled)
                  + ' Transmitting: ' + BooleanToStr(transmitting) +
                    ' Decoding: ' + BooleanToStr(Decoding)
                  + ' RXDF: ' + intToStr(RXDF) + ' TXDF: ' + intToStr(TXDF) +
                    ' DECall: ' + DECall + ' DEGrid: ' + DEGrid
                  + ' DXGrid: ' + DXGrid);
                end;
              if transmitting then
                begin
                logger.debug('[uWSJTX] Calling station %s, TotalContacts = %d',
                  [DXCall, TotalContacts]);
                if DXCall <> sCallSentToWindow then
                  begin
                  sCallSentToWindow := DXCall;
                  VisibleLog.ShowQSOStatus(DXCall);
                  //ShowStationInformation(@DXCall);
                  PutCalltoCallWindow(DXCall);
                  if ActiveDomesticMult = GridFields then
                    begin
                    VisibleLog.ShowDomesticMultiplierStatus(AnsiLeftStr(DXGrid,
                      2));
                    end
                  else
                    begin
                    VisibleLog.ShowDomesticMultiplierStatus(DXGrid);
                    end;
                  DisplayBeamHeading(DXCall, DXGrid);
                  end
                else
                   begin
                   logger.debug('DXCall (%s) was not equal to sCallSentToWindow (%s)', [DXCall, sCallSentToWindow]);
                   end;
                end
              else
                 begin
                 logger.debug('[uWSJTX]Status message received for %s, but Transmitting is false in WSJT-X UDP Message', [DXCall])
                 end;
              end;

          WSJTX_MESSAGETYPE_DECODEV:
            begin {............................................................Decode}
              logger.trace('[uWSJTX] WSJTX_MESSAGETYPE_DECODEDVV message received');
              // This is where we need to look for CQ decodes and highlight the call by sending back
              // a message to the UDP receiver in WSJT-X.
              Unpack(AData, index, isNew);
              Unpack(AData, index, tm);
              //ztime := IncMilliSecond(0, tm);
              Unpack(AData, index, SNR);
              Unpack(AData, index, DT);
              Unpack(AData, index, DF);
              Unpack(AData, index, mode);
              Unpack(AData, index, message);

              //logger.debug('[uWSJTX] Decode: IsNew=%s %s %d %s %d %s %s %s %s %d',
              //               [BoolToStr(isNew),FormatDateTime('hhmm',ztime),tm,FloatToStrF(DT, ffGeneral,4,1),
              //                DF,mode, message,timeToStr(ztime), FloatToStr(DT), tm]);

              if MidStr(message, 1, 2) = 'CQ' then
                 begin
                 slCQMessage.Clear;
                 slCQMessage.Delimiter := ' ';
                 // cq ny4i el87     a1   OR cq fd ny4i el87  a1
                 slCQMessage.DelimitedText := message;
                 logger.debug('[uWSJTX] Processing message %s', [message]);
                 if slCQMessage[0] = 'CQ' then
                    begin
                    for i := 1 to slCQMessage.Count - 1 do
                       // We start at one to skip the CQ
                       begin
                       if not foundCall then
                          begin
                          if IsValidCallsign(slCQMessage[i]) then
                             begin
                             foundCall := true;
                            // CallIndex := i;
                             DXCall := slCQMessage[i];
                             logger.debug('Found callsign %s', [DXCall]);
                             end;
                         end
                       else if not foundGrid then
                          begin
                          shortStr := slCQMessage[i];
                          if LooksLikeAGridIgnoreAE(shortStr) then
                             begin
                             foundGrid := true;
                             //gridIndex := i;
                             grid := slCQMessage[i];
                             logger.debug('Found grid %s', [grid]);
                             end;
                       end;

                       
                       if (foundCall) and (foundGrid) then
                          begin
                          Break;
                          end;
                    end;
                 if (not foundCall) or (not foundGrid) then
                    begin
                    logger.Warn('Either DXCall (%s) or grid (%s) was not present in CQ message: %s', [DXCall, grid, message]);
                    end;
                 call := DXCall;
                 if call <> '' then
                    begin
                    // Here we cheat a little bit on Frequency. The idea is that the status command is sent enough that it gives
                    // us the frequency. So turn the frequency into the band.
                    // We could also use the radio object to check
                    GetBandMapBandModeFromFrequency(frequency, TempBand,
                                                     TempMode);
                    TempMode := Digital;
                     // override TempMode since we know it is digital. Until a contest differentiates between FT8 and FT4 that is ok
                    if VisibleLog.CallIsADupe(call, TempBand, TempMode) then
                       begin
                       logger.debug('[uWSJTX] %s is a DUPE', [DXCall]);
                       HighLightCall(DXCall, 1, id);
                       end
                    // Issue #750-adjacent cleanup: gate the multiplier
                    // checks on at least one multiplier dimension being
                    // active for the current contest.  Contests like
                    // ARRL-DIGI / CQ-WPX-DIGI score on QSO count only --
                    // every Doing*Mults global is False -- so the
                    // DetermineIfNewMult and DetermineIfNewDomesticMult
                    // calls below always return False but still log
                    // confusing "Checking if grid FN is a multiplier"
                    // lines that suggest TR4W is doing mult work it
                    // is not.  Cheap to skip cleanly.
                    else if DoingDomesticMults or
                            DoingDXMults       or
                            DoingPrefixMults   or
                            DoingZoneMults     then
                       begin
                       if VisibleLog.DetermineIfNewMult(call, TempBand,
                                                       TempMode) then
                          begin
                          logger.debug('[uWSJTX] %s is a MULT (from callsign',
                                                                [DXCall]);

                          HighlightCall(grid, 2, id);
                           // Pass back id as given to us but without ? or a1..a7, etc.
                          end
                       else if grid <> '' then
                           // Even if gridFields (2 digit) grid, the DeterimeIfNewDomesticMult only checks left 2 bytes
                          begin
                          logger.debug('[uWSJTX] Checking if grid %s is a multiplier (call=%s)', [AnsiLeftStr(grid, 2), DXCall]);
                          VisibleLog.DetermineIfNewDomesticMult(grid, TempBand,
                                                                TempMode, nResult);
                          if nResult = 1 then
                             begin
                             logger.debug('[uWSJTX] %s is a domestic MULT',
                                           [AnsiLeftStr(grid, 2)]);
                             HighLightCall(grid, 2, id);
                             // Pass back id as given to us
                             end
                          else
                             begin
                             logger.debug('[uWSJTX] %s is NOT a domestic MULT',
                                          [AnsiLeftStr(grid, 2)]);
                             end;
                          end;
                       end;
                    // else: no multiplier dimensions in this contest;
                    // not a dupe -> no highlight (operator works
                    // everyone by default; only the exceptions need a
                    // color hint).
                     end // if call <> ...
                  else
                  begin
                    logger.warn('[uWSJTX] Call is blank for message = ' +
                      message);
                  end;
                end;
              end;
            end;

          WSJTX_MESSAGETYPE_CLEARV:
             begin
             logger.trace('[uWSJTX] WSJTX_MESSAGETYPE_CLEARV message received');
             Self.HandleMessage_Clear;
             end;

          WSJTX_MESSAGETYPE_QSOV:
            begin {..........I may grab this from the ADIF record so this would not be needed   QSO logged}
              logger.trace('[uWSJTX] WSJTX_MESSAGETYPE_QSOV message received');
              if logger.IsTraceEnabled then
              begin
                Unpack(AData, index, date);
                Unpack(AData, index, DXCall);
                Unpack(AData, index, DXGrid);
                Unpack(AData, index, frequency);
                Unpack(AData, index, mode);
                Unpack(AData, index, report);
                Unpack(AData, index, reportReceived);
                Unpack(AData, index, TXPower);
                Unpack(AData, index, comments);
                Unpack(AData, index, DXName);
              end;

              if logger.IsTraceEnabled then
              begin
                logger.Trace('[uWSJTX::WSJTX_MESSAGETYPE_QSOV] QSO logged: Date:' +
                  FormatDateTime('dd-mmm-yyyy hh:mm:ss', date)
                  + ' DX Call:' + DXCall + ' DX Grid:' + DXGrid
                  + ' Frequency:' + IntToStr(frequency) + ' Mode:' + mode +
                    ' Report sent: ' + report
                  + ' Report received:' + reportReceived + ' TX Power:' + TXPower
                  + ' Comments:' + comments + ' Name:' + DXName);
              end;
            end;
          WSJTX_MESSAGETYPE_CLOSEV:
            begin
              logger.Info('[uWSJTX] WSJT-X close message received');
                // We may want to indicate it somehow on main screen
              SetMainWindowText(mweWSJTX, '');
              Windows.ShowWindow(wh[mweWSJTX], SW_HIDE);
              isConnected := false;
            end;
          WSJTX_MESSAGETYPE_WSPRDECODEV:
            begin
              logger.Trace('[uWSJTX] Received message WSJTX_MESSAGETYPE_WSPRDECODEV');
            end;
          WSJTX_MESSAGETYPE_LOGGEDADIFV:
            begin // Note that ParseADIFRecord has some logic to determine where to put the gridsquare
              logger.Trace('[uWSJTX] Received message WSJTX_MESSAGETYPE_LOGGEDADIFV');
              if logger.IsDebugEnabled then
              begin
                logger.debug('[uWSJTX] TotalContacts at start of uWSJTX ADIF UDP message = ' + IntToStr(TotalContacts));
              end;
              Unpack(AData, index, adif);
              logger.Trace('[uWSJTX] >>> ADIF Record to log: ' + adif);
              ClearContestExchange(TempRXData);

              if ParseADIFRecord(adif, TempRXData) then
                // processed a record if true
              begin
                 logger.Debug('[uWSJTX] QTHString is %s',[TempRXData.QTHString]);
                // Flag a WSJT-X/TR4W operator mismatch (non-modal).  Done
                // here, before the ParametersOkay gate, so it runs for
                // every parsed record regardless of whether the QSO logs.
                WarnIfWSJTXOperatorMismatch(TempRXData.ceOperator,
                  CurrentOperator);
                ctyLocateCall(TempRXData.Callsign, TempRXData.QTH);

                if DoingDXMults then
                   begin
                   GetDXQTH(TempRXData);
                   end;
                if DoingPrefixMults then
                   begin
                   SetPrefix(TempRXData);
                   end;

                //CalculateQSOPoints(TempRXData);
                logger.debug('[uWSJTX] TotalContacts right before update of NumberSent in uWSJTX ADIF UDP message = %d', [TotalContacts]);

                //TempRXData.NumberSent := TotalContacts;
                //LogContact(TempRXData, true);

                // ParseADIFRecord populates QTHString (state/grid/zone) for most
                // contests but does not always copy it into ExchString.
                // ParametersOkay requires a non-empty ExchString to call
                // ProcessExchange — fall back to QTHString when ExchString is empty.
                if TempRXData.ExchString = '' then
                   begin
                   TempRXData.ExchString := TempRXData.QTHString;
                   end;
                if TempRXData.Band <> NoBand then
                   begin
                   tempBand := TempRXData.Band;
                   end
                else
                   begin
                   tempBand := ActiveBand;
                   end;

                if TempRXData.Frequency <> 0 then
                   begin
                   tempFreq := TempRXData.Frequency;
                   end
                else
                   begin
                   if ActiveRadioPtr.LastDisplayedFreq = 0 then // No connected radio so use default for band
                      begin
                      tempFreq := StrToInt(tCabrilloFreqString[TempRXData.Band]) * 1000; //14000 in array but needs to be 14000000
                      end
                   else
                      begin
                      tempFreq := ActiveRadioPtr.LastDisplayedFreq;
                      end;
                   end;

                if ParametersOkay(TempRXData.Callsign,
                  {TempRXData.QTHString}TempRXData.ExchString, tempBand,
                  Digital, tempFreq
                  {LastDisplayedFreq[ActiveRadio]}, TempRXData) then
                begin
                  TempRXData.DomesticQTH := TempRXData.QTHString;
                  // Set these on the record actually being logged
                  // (TempRXData), not ReceivedData -- otherwise the
                  // WSJT-X QSO logs with a blank Computer ID and an
                  // unset S&P flag.
                  TempRXData.ceSearchAndPounce := OpMode =
                    SearchAndPounceOpMode;
                  TempRXData.ceComputerID := ComputerID;
                  LogContact(TempRXData, True);
                  tElapsedTimeFromLastQSO := Windows.GetTickCount;
                  UpdateWindows;
                  //ShowStationInformation(@TempRXData.Callsign);
                  ClearContestExchange(TempRXData);
                  LastTwoLettersCrunchedOn := '';
                  CallAlreadySent := False;
                  ExchangeHasBeenSent := False;
                  EditingCallsignSent := False;
                  SeventyThreeMessageSent := False;
                  EscapeDeletedCallEntry := CallWindowString;
                  tCleareCallWindow;
                  tCleareExchangeWindow;
                  tCallWindowSetFocus;
                  CleanUpDisplay;
                  sCallSentToWindow := '';
                end;

                //tCleareCallWindow;

                //ShowStationInformation(@TempRXData.Callsign);
                //UpdateWindows;
              end;
            end;
        else
          begin
            logger.Error('[uWSJTX]  >>> Unrecognized message type: %d',
              [messageType]);
          end;
        end;
      end;
    end;
  end;
end;

{

Highlight Callsign In   13                     quint32    Integer

                           Id (unique key)        utf8
                           Callsign               utf8
                           Background Color       QColor
                           Foreground Color       QColor
                           Highlight last         bool

}

procedure TWSJTXServer.HighlightCall(sCall: string; color: integer; sId:
  string);
var
  AData: TIdBytes;
  messageType, magic, schema: LongInt;
  id: string;
  colorType: byte;
begin

  if not FSendColorization then
  begin
    logger.debug('[uWSJTX] FSendColorization is false so not highlighting %s',
      [sCall]);
    Exit;
  end;
  // Build a header for a message

     // Send colors for Dupes (QSOB4)

  magic := $ADBCCBDA;

  schema := 2;
  messageType := 13;
  id := sID;

  colorType := 1; // RGB

  pack(AData, magic); {.............................................Magic number}

  pack(AData, schema); {..............................................Schema}
  Pack(AData, messageType);
    {............................................MessageType}
  pack(AData, id); {..........................................ID}
  Pack(AData, Trim(sCall));

  if color = 1 then
    // DUPE  defaults to red - Add code to pull from config if there

     begin
     logger.debug('[uWSJTX] Highlighting call %s as a dupe with RGB colors %3d:%3d:%3d', [sCall, colorsDupeBack.R, colorsDupeBack.G, colorsDupeBack.B]);
     // Background QColor first

     Pack(AData, colorType); // RGB
     PackFF00(AData); // Alpha
     Pack(AData, Byte(colorsDupeBack.R));
     Pack(AData, Byte(0)); // Red
     Pack(AData, Byte(colorsDupeBack.G));
     Pack(AData, Byte(0)); // Green
     Pack(AData, Byte(colorsDupeBack.B));
     Pack(AData, Byte(0)); // Blue
     PackFF00(AData); //Pack(AData,Word(65280));   // R
     Pack(AData, Word(0)); // Padding

     // foreground
     Pack(AData, colorType); // RGB
     PackFF00(AData); // Alpha
     Pack(AData, Byte(colorsDupeFore.R));
     Pack(AData, Byte(0)); // Red
     Pack(AData, Byte(colorsDupeFore.G));
     Pack(AData, Byte(0)); // Green
     Pack(AData, Byte(colorsDupeFore.B));
     Pack(AData, Byte(0)); // Blue
     PackFF00(AData); //Pack(AData,Word(65280));   // R
     Pack(AData, Word(0)); // Padding
     end
  else if color = 2 then // multiplier
     begin // Background QColor first
     logger.debug('[uWSJTX] Highlighting call %s as a MULT with RGB colors %3d:%3d:%3d', [sCall, colorsMultBack.R, colorsMultBack.G, colorsMultBack.B]);
     Pack(AData, colorType);
     PackFF00(AData); //Pack(AData,Word(65280));     // Alpha
     Pack(AData, Byte(colorsMultBack.R));
     Pack(AData, Byte(0)); // Red
     Pack(AData, Byte(colorsMultBack.G));
     Pack(AData, Byte(0)); // Green
     Pack(AData, Byte(colorsMultBack.B));
     Pack(AData, Byte(0)); // Blue
     Pack(AData, Word(0)); // Padding
     Pack(AData, colorType);
     PackFF00(AData); //Pack(AData,Word(65280));     // Alpha
     Pack(AData, Byte(colorsMultFore.R));
     Pack(AData, Byte(0)); // Red
     Pack(AData, Byte(colorsMultFore.G));
     Pack(AData, Byte(0)); // Green
     Pack(AData, Byte(colorsMultFore.B));
     Pack(AData, Byte(0)); // Blue
     Pack(AData, Word(0)); // Padding
     end;

  Pack(AData, true); // Highlight last only
  logger.trace('[uWSJTX] Sending command to highlight ' + Trim(sCall));
  udpServ.SendBuffer(peerIP, PeerPort, AData);

end;

procedure TWSJTXServer.ClearColors(sId: string);

var
  AData: TIdBytes;
  messageType, magic, schema: LongInt;
  id: string;
  colorType: byte;

begin

  // Build a header for a message

  magic := $ADBCCBDA;

  schema := 2;
  messageType := 13;
  id := sID;

 // colorType := 0; // RGB

  pack(AData, magic); {.............................................Magic number}

  pack(AData, schema); {..............................................Schema}
  Pack(AData, messageType);
    {............................................MessageType}
  pack(AData, id); {..........................................ID}
  Pack(AData, ' '); // blank call?

  // Background QColor first

  //

  Pack(AData, Byte(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));
  Pack(AData, Byte(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));
  Pack(AData, Word(0));

  Pack(AData, true); // Highlight last only
  logger.debug('[uWSJTX] Sending Reset Colors');

  udpServ.SendBuffer(peerIP, PeerPort, AData);

end;

(*procedure TWSJTXServer.SetDupeBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsDupeBack.R := bRed;
   Self.colorsDupeBack.G := bGreen;
   Self.colorsDupeBack.B := bBlue;
end;
*)
procedure TWSJTXServer.SetDupeBackgroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
  //rgb := ColorToRGB(tc);
  logger.Debug('[uWSJTX] Setting DupeBackgroundColor to %d:%d:%d',
    [GetRValue(rgb), GetGValue(rgb), GetBValue(rgb)]);
  Self.colorsDupeBack.R := GetRValue(rgb);
  Self.colorsDupeBack.G := GetGValue(rgb);
  Self.colorsDupeBack.B := GetBValue(rgb);
end;

{
procedure TWSJTXServer.SetMultBackgroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsMultBack.R := bRed;
   Self.colorsMultBack.G := bGreen;
   Self.colorsMultBack.B := bBlue;
end;
}
procedure TWSJTXServer.SetMultBackgroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
  //rgb := ColorToRGB(tc);
  logger.Debug('[uWSJTX] Setting MultBackgroundColor to %d:%d:%d',
    [GetRValue(rgb), GetGValue(rgb), GetBValue(rgb)]);
  Self.colorsMultBack.R := GetRValue(rgb);
  Self.colorsMultBack.G := GetGValue(rgb);
  Self.colorsMultBack.B := GetBValue(rgb);
end;

{
procedure TWSJTXServer.SetDupeForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsDupeFore.R := bRed;
   Self.colorsDupeFore.G := bGreen;
   Self.colorsDupeFore.B := bBlue;
end;
}
procedure TWSJTXServer.SetDupeForegroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
  //rgb := ColorToRGB(tc);
  logger.Debug('[uWSJTX] Setting DupeForegroundColor to %d:%d:%d',
    [GetRValue(rgb), GetGValue(rgb), GetBValue(rgb)]);
  Self.colorsDupeFore.R := GetRValue(rgb);
  Self.colorsDupeFore.G := GetGValue(rgb);
  Self.colorsDupeFore.B := GetBValue(rgb);
end;

{
procedure TWSJTXServer.SetMultForegroundColor(bRed: byte; bGreen: byte; bBlue: byte);
begin
   Self.colorsMultFore.R := bRed;
   Self.colorsMultFore.G := bGreen;
   Self.colorsMultFore.B := bBlue;
end;
}
procedure TWSJTXServer.SetMultForegroundColor(rgb: cardinal);
//var rgb: cardinal;
begin
  //rgb := ColorToRGB(tc);
  logger.Debug('[uWSJTX] Setting MultForegroundColor to %d:%d:%d',
    [GetRValue(rgb), GetGValue(rgb), GetBValue(rgb)]);
  Self.colorsMultFore.R := GetRValue(rgb);
  Self.colorsMultFore.G := GetGValue(rgb);
  Self.colorsMultFore.B := GetBValue(rgb);
end;

procedure TWSJTXServer.IdTCPServer1Execute(AContext: TIdContext);
var

  PeerPort: Integer;
  PeerIP: string;

  sFreq: string;
  sDebug: string;
  s: string;
  sReply: string;
  freq: extended;
  fieldName, fieldValue: string;
  saveDecimalSeparator: char;
  saveThousandSeparator: char;

begin
  // ... get message from client
  saveDecimalSeparator := DecimalSeparator;
  saveThousandSeparator := ThousandSeparator;
  try
    AContext.Connection.IOHandler.ReadBytes(buffer, -1, true);
    sBuffer := BytesToString(buffer);
    RemoveBytes(buffer, length(sBuffer));

    // ... getting IP address, Port and PeerPort from Client that connected
    peerIP := AContext.Binding.PeerIP;
    peerPort := AContext.Binding.PeerPort;

    // ... message log
    Display('CLIENT', '[uWSJTX] (Peer=' + PeerIP + ':' + IntToStr(PeerPort) +
      ') ' + sBuffer);
    // ...

    { The TX and RX Kludge business is just that...a kludge. The problem is that WSJT-X wants to see the effected state change
      (TX on in response to a CmdTX or RX on in response to a CmdRX) in one second. Due to the polling interval of the attached radio
      we may not have a reply that fast. If WSJT-X does not get that, it aborts the connection. So we fool it. When the TX status
      change is requested, we force it to be what WSJT-X wants for 5 seconds to give us plenty of time to get the status from the radio.
      Not a great system but short of a much faster indication if we are transmitting, this seems to work.
      Work should be done to speed up the actual state change notification so this can be a truer indication or at least the
      timer lowered from 5 seconds.   // NY4I wrote this and the kludge--lest anyone else get blamed for this nastiness...
    }
    while Self.GetNextADIFField(sBuffer, fieldName, fieldValue) do
    begin
      if TXKludge then
      begin
        if SecondsBetween(txKludgeStart, Now) > KLUDGESECONDSV then
        begin
          TXKludge := false;
        end
        else
        begin
          logger.trace('[uWSJTX] TXKludge is true');
        end;
      end;

      if RXKludge then
      begin
        if SecondsBetween(rxKludgeStart, Now) > KLUDGESECONDSV then
        begin
          RXKludge := false;
        end
        else
        begin
          logger.trace('[uWSJTX] RXKludge is true');
        end;
      end;

      if fieldValue = 'CmdGetFreq' then
      begin
        if (ActiveRadioPtr.RadioModel = NoInterfacedRadio) or
          (radio1.CurrentStatus.VFO[VFOA].Frequency = 0) then
        begin
          logger.error('[uWSJTX] **** radio1.CurrentStatus.VFO[VFOA].Frequency = 0');
          logger.trace('[uWSJTX] Sending VFOA frequency as .000');
          AContext.Connection.IOHandler.Write('<CmdFreq:4>.000');
        end
        else
        begin
          // Commander interface forces . as decimal for Get
          saveDecimalSeparator := DecimalSeparator;
          saveThousandSeparator := ThousandSeparator;
          try
             DecimalSeparator := '.';
             ThousandSeparator := ',';
             sFreq := SysUtils.FormatFloat(',0.000',
             radio1.CurrentStatus.VFO[VFOA].Frequency / 1000);
             logger.Trace('[uWSJTX] Sending VFOA frequency: ' +
                          SysUtils.Format('<CmdFreq:%u>%s', [length(sFreq), sFreq]));
             AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdFreq:%u>%s',
                                                 [length(sFreq), sFreq]));
          finally
             DecimalSeparator := SaveDecimalSeparator;
             ThousandSeparator := saveThousandSeparator;
          end;
        end;
      end
      else if fieldValue = 'CmdSetFreq' then
      begin
        processingCmdSetFreq := true;
        logger.Trace('[uWSJTX] Setting processingCmdSetFreq');
      end
      else if fieldValue = 'CmdSetFreqMode' then
      begin
        processingCmdSetFreqMode := true;
        logger.Trace('[uWSJTX] Setting processingCmdSetFreqMode');
      end
      else if fieldName = 'xcvrfreq' then
      begin
        freq := SafeFloat(fieldValue);
        logger.trace('[uWSJTX] freq fieldValue = %n', [freq]);
        if processingCmdSetFreq then // Set Main VFO
        begin
          logger.Trace('[uWSJTX] Setting VFOA to frequency ' +
            IntToStr(Trunc(freq)));
          ActiveRadioPtr.SetRadioFreq(Trunc(freq * 1000), Digital, 'A');
            // A is for VFO A
          processingCmdSetFreq := false;
          logger.Trace('[uWSJTX] Resetting processingCmdSetFreq');
        end
        else if processingCmdSetFreqMode then
        begin
          logger.Trace('[uWSJTX] Setting VFOA to frequency ' +
            IntToStr(Trunc(freq)));
          ActiveRadioPtr.SetRadioFreq(Trunc(freq * 1000), Digital, 'A',eData);
            // A is for VFO A
        end
        else if processingCmdSetTXFreq then
        begin
          logger.Trace('[uWSJTX] [processingCmdSetTXFreq] Setting VFOB to frequency ' + IntToStr(Trunc(freq)));
          Self.requestedTXFreq := Trunc(freq * 1000);
          ActiveRadioPtr.SetRadioFreq(Trunc(freq * 1000), Digital, 'B');
            // B is for VFO B
          processingCmdSetTXFreq := false;
          logger.Trace('[uWSJTX] Resetting processingCmdSetTXFreq');
        end
        else if processingCmdQSXSplit then
        begin
          logger.Trace('[uWSJTX] [processingCmdQSXSplit] Setting VFOB to frequency ' + IntToStr(Trunc(freq)));
          Self.requestedTXFreq := Trunc(freq * 1000);
          radio1.SetRadioFreq(Trunc(freq * 1000), Digital, 'B');
            // B is for VFO B
          ActiveRadioPtr.PutRadioIntoSplit;
          processingCmdQSXSplit := false;
          logger.Trace('[uWSJTX] Resetting processingCmdQSXSplit');
        end
        else
        begin
          logger.Debug('[uWSJTX] <***** ERROR ******> Received xcvrfreq to ' +
            IntToStr(Trunc(freq)) + ' without state variable');
        end;

      end
      else if fieldValue = 'CmdSetTXFreq' then
      begin
        processingCmdSetTXFreq := true;
        logger.Trace('[uWSJTX] Setting processingCmdSetTXFreq');
      end
      else if fieldName = 'SuppressDual' then
      begin
      end
      else if fieldValue = 'CmdSetMode' then
      begin
        logger.Trace('[uWSJTX] CmdSetMode received ' + sBuffer);
      end
      else if fieldValue = 'CmdSendSplit' then
      begin
        if ActiveRadioPtr.CurrentStatus.Split then
        begin
          AContext.Connection.IOHandler.Write('<CmdSplit:2>ON');
          logger.trace('[uWSJTX] Sending ' + '<CmdSplit:2>ON');
        end
        else
        begin
          AContext.Connection.IOHandler.Write('<CmdSplit:3>OFF');
          logger.trace('[uWSJTX] Sending ' + '<CmdSplit:3>OFF');
        end;
      end
      else if fieldValue = 'CmdRX' then // No reply
      begin
        if not tPTTViaCommand then
        begin
          QuickDisplay('PTT VIA COMMANDS (CTRL-J) option must be true for WSJT-X use - Setting to true');
          tPTTViaCommand := true;
        end;
        logger.Debug('[uWSJTX] <<<<<<<<<<<<<<<<<<<<< PTT OFF *********************');
        tPTTVIACAT(false);
        TXKludge := false;
        RXKludge := true;
        rxKludgeStart := Now;
      end
      else if fieldValue = 'CmdTX' then
      begin
        if not tPTTViaCommand then
        begin
          QuickDisplay('PTT VIA COMMANDS (CTRL-J) option must be true for WSJT-X use - Setting to true');
          logger.Info('[uWSJTX] Set tPTTViaCommand for user');
          tPTTViaCommand := true;
        end;
        logger.debug('>>>>>>>>>>>>>>>>>>> PTT ON *********************');
        tPTTVIACAT(true);
        txKludgeStart := Now;
        TXKludge := true;
        RXKludge := false;
      end
      else if fieldValue = 'CmdSendMode' then
      begin
        case ActiveRadioPtr.CurrentStatus.ExtendedMode of
          eAM: s := 'AM';
          eCW: s := 'CW';
          eCW_R: s := 'CW-R';
          eDATA_R: s := 'DATA-L';
          eDATA: s := 'DATA-U';
          eFM: s := 'FM';
          eLSB: s := 'LSB';
          eUSB: s := 'USB';
          eRTTY: s := 'RTTY';
          eRTTY_R: s := 'RTTY-R';
          ePSK31: s := 'DATA-U';
        else
          begin
            logger.Error('[uWSJTX] <***** ERROR ******> Mode not handled in SENDMODE ' + IntToStr(Ord(ActiveRadioPtr.CurrentStatus.ExtendedMode)));
            s := 'DATA-U';
          end;
        end;
        AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdMode:%u>%s',
          [length(s), s]));
        logger.Trace('[uWSJTX] Sending ' + SysUtils.Format('<CmdMode:%u>%s',
          [length(s), s]));
      end
      else if fieldValue = 'CmdSendTx' then
      begin
        if TXKludge then
        begin
          sReply := '<CmdTX:2>ON';
        end
        else if RXKludge then
        begin
          sReply := '<CmdTX:3>OFF';
        end
        else
        begin
          if ActiveRadioPtr.CurrentStatus.TXOn then
          begin
            sReply := '<CmdTX:2>ON';
          end
          else
          begin
            sReply := '<CmdTX:3>OFF';
          end;
        end;
        sDebug := '';
        if TXKludge then
        begin
          sDebug := ' TXKludge ';
        end;
        if RXKludge then
        begin
          sDebug := sDebug + ' RXKludge ';
        end;
        if Length(sDebug) > 0 then
        begin
          sDebug := '[' + sDebug + '] ';
        end;
        sDebug := sDebug + 'Sending ' + sReply;
        logger.Trace('[uWSJTX] %s', [sDebug]);
        AContext.Connection.IOHandler.Write(sReply);
      end
      else if fieldValue = 'CmdGetTXFreq' then
      begin // Return VFO B
        if (ActiveRadioPtr.RadioModel = NoInterfacedRadio) or
          (ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency = 0) then
        begin
          //DEBUGMSG('**** radio1.CurrentStatus.VFO[VFOB].Frequency = 0');
          logger.error('[uWSJTX]        ActiveRadioPtr.CurrentStatus.VFO[VFOB] = ' +
            SysUtils.FormatFloat(',0.000',
            ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency / 1000));
          logger.trace('[uWSJTX] Sending VFOB frequency as requestedTXFreq since we do not have frequency [' + SysUtils.Format('<CmdFreq:%u>%s', [length(sFreq), sFreq]) + ']');
          sFreq := SysUtils.FormatFloat(',0.000', Self.requestedTXFreq / 1000);
          AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdTXFreq:%u>%s',
            [length(sFreq), sFreq]));
        end
        else
        begin
          sFreq := SysUtils.FormatFloat(',0.000',
            ActiveRadioPtr.CurrentStatus.VFO[VFOB].Frequency / 1000);
          logger.Trace('[uWSJTX] Sending VFOB frequency as ' +
            SysUtils.Format('<CmdFreq:%u>%s', [length(sFreq), sFreq]));
          AContext.Connection.IOHandler.Write(SysUtils.Format('<CmdTXFreq:%u>%s',
            [length(sFreq), sFreq]));
        end;
      end
      else if fieldValue = 'xcvrmode' then
      begin
        if processingCmdSetFreqMode then
        begin
          processingCmdSetFreqMode := false;
          logger.Trace('[uWSJTX] Resetting processingCmdSetFreqMode');
        end
        else
        begin
          logger.debug('[uWSJTX] Received unexpected xcvrmode');
        end;
      end
      else if fieldValue = 'CmdQSXSplit' then
      begin
        processingCmdQSXSplit := true;
        logger.Trace('[uWSJTX] Setting processingCmdQSXSplit');
      end
      else if fieldValue = 'CmdSplit' then
      begin
        processingCmdSplit := true;
        logger.Trace('[uWSJTX] Setting processingCmdSplit');
      end
      else if fieldValue = 'off' then
      begin
        if processingCmdSplit then
        begin
          processingCmdSplit := false;
          logger.Trace('[uWSJTX] Resetting processingCmdSplit');
          ActiveRadioPtr.PutRadioOutOfSplit;
        end
        else
        begin
          logger.Error('[uWSJTX] <***** ERROR ******> off command received for unknown reason');
        end;
      end
      else if fieldValue = 'on' then
      begin
        if processingCmdSplit then
        begin
          processingCmdSplit := false;
          logger.Trace('[uWSJTX] Resetting processingCmdSplit');
          ActiveRadioPtr.PutRadioIntoSplit;
        end
        else
        begin
          logger.Error('[uWSJTX] <***** ERROR ******> on command received for unknown reason');
        end;
      end;

    end;

    logger.Trace('length(sBuffer) = ' + IntToStr(length(sBuffer)));
  except
    on E: Exception do
      if E.message <> 'Connection Closed Gracefully.' then
      begin
        logger.error('[uWSJTX]  Error processing TCP message %s', [E.message]);
      end;
  end;
end;

procedure TWSJTXServer.IdTCPServer1Connect(AContext: TIdContext);
begin
  logger.debug('[uWSJTX] TCP client Connected');
end;

procedure TWSJTXServer.IdTCPServer1Disconnect(AContext: TIdContext);

begin

  logger.debug('[uWSJTX] TCP Client disconnected');

end;

function TWSJTXServer.GetNextADIFField(var sBuffer: string; var fieldName:
  string; var fieldValue: string): boolean;

var

  i, z, x, dataLen: integer;

  aaa, sLen: string;

begin

  Result := false;

  // Assumes we are pointing at the < in the next field

  z := AnsiPos('<', sBuffer);

  if z = 0 then
  begin
    if length(sBuffer) > 0 then
    begin
      logger.Trace('[uWSJTX] sBuffer does not start with < ' + sBuffer);
      sBuffer := '';
    end;
    exit; //  there is no other record - disappearing.
  end;

  aaa := copy(sBuffer, z + 1, length(sBuffer));

  z := AnsiPos(':', aaa);
  x := AnsiPos('>', aaa);
  if x = 0 then

  begin

    exit; //  the record was not terminated ... disappearing

  end;

  for i := z + 1 to x do

  begin
    if aaa[i] in ['0'..'9'] then
    begin
      slen := slen + aaa[i];
    end;
  end;

  if slen = '' then
  begin
    DataLen := 0;
  end
  else
  begin
    DataLen := StrToInt(slen);
  end;
  //logger.Trace('[uWSJTX] Got length:' + IntToStr(DataLen));

  if z <> 0 then
  begin
    fieldName := trim(copy(aaa, 1, z - 1));
  end
  else
  begin
    fieldName := trim(copy(aaa, 1, x - 1));
  end;

  aaa := copy(aaa, x + 1, length(aaa));

  z := AnsiPos('<', aaa);
  //i := AnsiPos('_INTL', AnsiUppercase(fieldName));
  //if dmData.DebugLevel >=1 then Write(' pos INTL:',i);
  if z = 0 then
  begin
    fieldValue := copy(aaa, 1, DataLen);
    //logger.Trace('1-Trimming sBuffer to [' + copy(aaa,z,length(aaa)) + ']');
    sBuffer := copy(aaa, z, length(aaa)); // Was vstup:=''
  end
  else
  begin
    fieldValue := copy(aaa, 1, DataLen);
    //logger.Trace('2-Trimming sBuffer to [' + copy(aaa,z,length(aaa)) + ']');
    sBuffer := copy(aaa, z, length(aaa))
  end;
  fieldValue := Trim(fieldValue);

  Result := true;

  logger.Trace('[uWSJTX] %s = %s', [fieldName, fieldValue]);

end;

(*--------------------------------------------------------------------------------------------------------------------------------*)
procedure TWSJTXServer.HandleMessage_Clear;
begin

  logger.Trace('[uWSJTX] WSJTX >>> Clear');
  tCleareCallWindow;
  tCleareExchangeWindow;
  tCallWindowSetFocus;
  CleanUpDisplay;
  sCallSentToWindow := '';

end;

procedure TWSJTXServer.Display(p_sender: string; p_message: string);

begin
  try
    logger.trace('[uWSJTX] %s', [p_message]);
  except
  end;

end;

function TWSJTXServer.ConvertSNRToRST(snr: integer): integer;
begin
  if snr <= -20 then
  begin
    Result := 509;
  end
  else if snr < -14 then
  begin
    Result := 519;
  end
  else if snr < -8 then
  begin
    Result := 529;
  end
  else if snr < -2 then
  begin
    Result := 539;
  end
  else if snr < 4 then
  begin
    Result := 549;
  end
  else if snr < 10 then
  begin
    Result := 559;
  end
  else if snr < 16 then
  begin
    Result := 569;
  end
  else if snr < 22 then
  begin
    Result := 579;
  end
  else if snr < 28 then
  begin
    Result := 589;
  end
  else
  begin
    Result := 599;
  end;
end;

end.
