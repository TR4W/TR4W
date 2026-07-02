unit uRadioElecraftK4;

interface
uses uNetRadioBase, uRadioBand, StrUtils, SysUtils, Math, TF, Log4D, VC;


Type TK4Radio = class(TNetRadioBase)
   private
      CWBuffer: string;
      firstProcessMessage: boolean;
      logger: TLogLogger;  // Per-instance logger; shadows MainUnit.logger so all log calls in this class are radio-identified
      function ParseIFCommand(cmd: string): boolean;
      function ModeStrToMode(sMode: string; sDataMode: string): TRadioMode;
      function BandNumToBand(sBand: string): TRadioBand;
      //procedure ProcessMessage(sMessage: string);
      procedure Initialize;
      function ModeTypeToInteger(mode: TRadioMode; var dataModeInt: integer): integer;
      //function IsDataMode(mode: TRadioMode): boolean;

   public
      Constructor Create;
      function Connect: integer; override;
      procedure Transmit; override;
      procedure Receive; override;
      procedure ProcessMsg(msg: string); override;
      procedure BufferCW(cwChars: string); overload; override;
      procedure SendCW; override;
      procedure StopCW; override;

      // Base class overrides with VFO parameters
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode); override;
      procedure SetMode(mode: TRadioMode; vfo: TVFO = nrVFOA); override;
      function  ToggleMode(vfo: TVFO = nrVFOA): TRadioMode; override;
      procedure SetCWSpeed(speed: integer); override;
      procedure RITClear(whichVFO: TVFO); override;
      procedure XITClear(whichVFO: TVFO); override;
      procedure RITBumpDown; override;
      procedure RITBumpUp; override;
      procedure RITOn(whichVFO: TVFO); override;
      procedure RITOff(whichVFO: TVFO); override;
      procedure XITOn(whichVFO: TVFO); override;
      procedure XITOff(whichVFO: TVFO); override;
      procedure Split(splitOn: boolean); override;
      procedure SetRITFreq(whichVFO: TVFO; hz: integer); override;
      procedure SetXITFreq(whichVFO: TVFO; hz: integer); override;
      procedure SetBand(band: TRadioBand; vfo: TVFO = nrVFOA); override;
      function  ToggleBand(vfo: TVFO = nrVFOA): TRadioBand; override;
      procedure SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA); override;
      function  SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer; override;
      function  MemoryKeyer(mem: integer): boolean; override;
      procedure VFOBumpDown(whichVFO: TVFO); override;
      procedure VFOBumpUp(whichVFO: TVFO); override;

      // K4-specific methods
      procedure PollRadioState; override;
      procedure SendToRadio(whichVFO: TVFO; sCmd: string; sData: string); overload;
      procedure ProcessMessage(sMessage: string);
      procedure SetAIMode(i: integer);
end;

implementation

Uses MainUnit;

Constructor TK4Radio.Create;
begin
   inherited Create(ProcessMessage);

   // Generic logger until rigLabel is set by LOGRADIO after creation
   logger := TLogLogger.GetLogger('TR4WDebugLog.K4-Radio');

   firstProcessMessage := true;  // Call Initialize on first message received
   // K4 supports auto-info mode - no polling needed
   requiresPolling := False;
   autoUpdateCommand := 'AI5;';     // Enable auto-info mode level 5
   pollingInterval := 0;            // Not used for K4
end;

function TK4Radio.Connect: integer;
begin
   Self.readTerminator := ';';
   Result := Inherited Connect;
   if Self.IsConnected then
      begin
      if Self.serialPort <> NoPort then
         begin
         // Serial: disable AI to avoid flooding the serial port.
         // Use periodic polling instead (same approach as legacy K3 code).
         Self.SetAIMode(0);
         Self.requiresPolling := True;
         Self.pollingInterval  := 100; // Default; overridden by FREQUENCY POLL RATE in pNetworkRadio
         end
      else
         begin
         // Network: AI5 pushes state changes -- no polling needed for
         // state.  But the K4 server drops clients that send nothing
         // for 10 seconds (per K4 Programmer's Reference, PING/PONG
         // section -- Issue #897).  Enable a 1 Hz poll that sends
         // PING; as a keep-alive.  ProcessMessage handles the PONG;
         // response explicitly (case 17, 'PO') and at the top calls
         // UpdateLastValidResponse, refreshing the inbound watchdog.
         Self.SetAIMode(5);
         Self.requiresPolling := True;
         Self.pollingInterval := 1000; // 1 Hz keep-alive ping
         end;
      Self.SendToRadio('RT;XT;RO;FT;ID;MD;DT$;IF;');
      Self.SendToRadio('RT$;XT$;RO$;MD$;DT$;IF$;');
      end;
end;
procedure TK4Radio.Transmit;
begin
   Self.SendToRadio('TX;');
end;

procedure TK4Radio.Receive;
begin
   Self.SendToRadio('RX;');
end;

procedure TK4Radio.StopCW;
begin
   Self.SendToRadio(Chr(4) + ';RX;');
end;

procedure TK4Radio.SendCW;
//var s: string;
begin
   if Self.CWBuffer = '' then
      begin
      logger.Warn('[K4Radio.SendCW] CW buffer is empty - nothing to send');
      Exit;
      end;

   logger.Info('[K4Radio.SendCW] Sending CW: "%s"', [Self.CWBuffer]);
   Self.SendToRadio('KY ' + Self.CWBuffer + ';');
   Self.CWBuffer := '';
end;

procedure TK4Radio.BufferCW(cwChars: string);
begin
   Self.CWBuffer := Self.CWBuffer + cwChars;
   logger.Info('[K4Radio.BufferCW] Buffered: "%s", Total buffer: "%s"', [cwChars, Self.CWBuffer]);
end;

procedure TK4Radio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
var sCmd: string;
begin
   case vfo of
      nrVFOA: sCmd := 'FA';
      nrVFOB: sCmd := 'FB';
      else
         begin
         logger.error('[SetFrequency] Invalid VFO passed');
         Exit;
         end;
      end;
   Self.SendToRadio(Format('%2s%.11d;',[sCmd,freq]));
   if mode <> rmNone then
      Self.SetMode(mode, vfo);
end;

procedure TK4Radio.SetMode(mode:TRadioMode; vfo: TVFO = nrVFOA);
var
  // sMode: string;
   modeInt: integer;
   dataModeInt: integer;
  // isData: boolean;

begin
   modeInt := Self.ModeTypeToInteger(mode,dataModeInt);
   if modeInt > 0 then
      begin
      Self.SendToRadio(vfo,'MD',IntToStr(modeInt));
      if dataModeInt >= 0 then
         begin
         Self.SendToRadio(vfo,'DT',IntToStr(dataModeInt));
         end;
      end
   else
      begin
      logger.error('[SetMode] Invalid mode passed Ordinal of mode = %d',[Ord(mode)]);
      Exit;
      end;
end;

function TK4Radio.ToggleMode(vfo: TVFO): TRadioMode;
begin
   // TODO: Implement mode toggling for K4
   Result := rmNone;
end;

procedure TK4Radio.SetCWSpeed(speed: integer);
begin
   if IntegerBetween(speed,8,100) then
      begin
      Self.localCWSpeed := speed;
      Self.SendToRadio(Format('KS%3d;',[speed]));
      end
   else
      begin
      logger.Error ('K4 supports a CW speed of 8 wpm to 100 wpm');
      end;
end;

procedure TK4Radio.RITClear(whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'RC','');
end;

procedure TK4Radio.XITClear(whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'RC','');
end;

procedure TK4Radio.RITBumpDown;
begin
   Self.SendToRadio('RD;');
end;

procedure TK4Radio.RITBumpUp;
begin
   Self.SendToRadio('RU;');
end;

procedure TK4Radio.RITOn (whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'RT','1');
end;

procedure TK4Radio.RITOff (whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'RT','0');
end;

procedure TK4Radio.XITOn(whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'XT','1');
end;

procedure TK4Radio.XITOff(whichVFO: TVFO);
begin
   Self.SendToRadio(whichVFO,'XT','0');
end;

procedure TK4Radio.Split(splitOn: boolean);
begin
   if splitOn then
      begin
      Self.SendToRadio('FT1;');
      end
   else
      begin
      Self.SendToRadio('FT0;');
      end;
end;
procedure TK4Radio.SetRITFreq(whichVFO: TVFO; hz: integer);
var s: string;
begin
   if (hz > -10000) and (hz < 10000) then
      begin
      if hz >= 0 then
         begin
         s := '+';
         end
      else
         begin
         s := '-';
         end;
      s := s + Format('%4d',[Abs(hz)]);
      Self.SendToRadio('RO' + s + ';');
      end
   else
      begin
      logger.Error('[SetRITFreq] RIT frequency must be between -9999 and 9999 (%d)',[hz]);
      end;
end;

procedure TK4Radio.SetXITFreq(whichVFO: TVFO; hz: integer);
begin
   Self.SetRITFreq(whichVFO, hz); // Same on K4
end;

procedure TK4Radio.SetBand(band: TRadioBand; vfo: TVFO = nrVFOA);
var s: string;
begin

   case band of
      rb160m: s := '00';
      rb80m: s := '01';
      rb60m: s := '02';
      rb40m: s := '03';
      rb30m: s := '04';
      rb20m: s := '05';
      rb17m: s := '06';
      rb15m: s := '07';
      rb12m: s := '08';
      rb10m: s := '09';
      rb6m:  s := '10';
   else
      begin
      logger.Error('Invalid band requested %d',[Ord(band)]);
      Exit;
      end;
   end;
   Self.SendToRadio(Format('BN%2d;',[Ord(band)]));
end;

procedure TK4Radio.VFOBumpDown(whichVFO: TVFO);
begin
   if whichVFO = nrVFOA then
      begin
      Self.SendToRadio('DN;');
      end
   else if whichVFO = nrVFOB then
      begin
      Self.SendToRadio('DNB;');
      end
   else
      begin
      logger.Warn('[TK4Radio.VFOBumpDown] Invalid vfo passed in whichVFO');
      end;
end;

procedure TK4Radio.VFOBumpUp(whichVFO: TVFO);
begin
   if whichVFO = nrVFOA then
      begin
      Self.SendToRadio('UP;');
      end
   else if whichVFO = nrVFOB then
      begin
      Self.SendToRadio('UPB;');
      end
   else
      begin
      logger.Warn('[TK4Radio.VFOBumpUp] Invalid vfo passed in whichVFO');
      end;
end;

function  TK4Radio.ToggleBand(vfo: TVFO = nrVFOA): TRadioBand;
//var newBand: TRadioBand;
begin
   //newBand := Self.priorBand;
   //Self.priorBand := Self.band;
   //Self.SetBand(newBand, vfo);
   //Result := newBand;
   logger.Warn('ToggleBand not yet implemented');
   Result := rbNone;
end;

procedure TK4Radio.SetFilter(filter: TRadioFilter; vfo: TVFO = nrVFOA);
var filterInt: integer;
begin
   // Convert TRadioFilter enum to K4 filter number (1-5)
   case filter of
      rfNarrow: filterInt := 1;
      rfMid:    filterInt := 3;
      rfWide:   filterInt := 5;
   else
      filterInt := 3;  // Default to middle filter
   end;

   if IntegerBetween(filterInt, 1, 5) then
      begin
      logger.Info('[SetFilter] Setting filter on VFO %s to %d',[VFOToString(vfo),filterInt]);
      if vfo = nrVFOA then
         begin
         Self.SendToRadio(Format('FP%d;',[filterInt]));
         end
      else if vfo = nrVFOB then
         begin
         Self.SendToRadio(Format('FP$%d;',[filterInt]));
         end;
      end
   else
      begin
      logger.error('[SetFilter] filter out of range 1..5 - %d',[filterInt]);
      end;
end;

function  TK4Radio.SetFilterHz(hz: integer; vfo: TVFO = nrVFOA): integer;
begin
   logger.Warn('SetFilterHz is not yet implemented on the K4');
   Result := 0;
end;

function TK4Radio.MemoryKeyer(mem: integer): boolean;
begin
   Result := true; // True is an error...default to that value to fail closed
   if mem = 0 then
      begin
      logger.debug('[K4-MemoryKeyer] Stopping DVK');
      Self.SendToRadio('DA0;');  // DA0; Stops all DVK activity
      Result := false;
      end
   else if IntegerBetween(mem,1,8) then
      begin
      logger.debug('[K4-MemoryKeyer] Playing memory %d',[mem]);
      Self.SendToRadio(Format('DAMP%d00000;',[mem]));  // DAMPmnnnnn; where m is mem number and nnnnn is repeat in ms (set to 00000)
      Result := false;
      end
   else
      begin
      logger.error('Memory value (%d) out of range for a K4 in MemoryKeyer',[mem]);
      Result := true;
      end;
end;

function TK4Radio.ParseIFCommand(cmd: string): boolean;
var
   s: string;
   hz: integer;
   ritMultiplier: integer;
   xitMultiplier: integer;
   ritOffset: integer;
   //xitOffset: integer;
   sVFO: string;
   sMode: string;
   sDataMode: string;
   vfo: TRadioVFO;
begin
{
IF (Transceiver Information; GET only)
RSP format: IF[f]*****+yyyyrx*00tmvspbd1*; where the fields are defined as follows:
[f] Operating frequency, excluding any RIT/XIT offset (11 digits; see FA command format)
* represents a space (BLANK, or ASCII 0x20)
+ either "+" or "-" (sign of RIT/XIT offset)
yyyy RIT/XIT offset in Hz (range is -9999 to +9999 Hz when computer-controlled)
r 1 if RIT is on, 0 if off
x 1 if XIT is on, 0 if off
t 1 if the K3 is in transmit mode, 0 if receive
m operating mode (see MD command)
v receive-mode VFO selection, 0 for VFO A, 1 for VFO B
s 1 if scan is in progress, 0 otherwise
p 1 if the transceiver is in split mode, 0 otherwise
b Basic RSP format: always 0; K2 Extended RSP format (K22): 1 if present IF response
is due to a band change; 0 otherwise
d Basic RSP format: always 0; K3 Extended RSP format (K31): DATA sub-mode,
if applicable (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)
}
   Result := false;
   ritMultiplier := 1;
   xitMultiplier := 1;
   if not length(cmd) in [36,38] then
      begin
      logger.Error('[ParseIFCommand] length of IF command not 36 or 38 bytes - %s',[cmd]);
      Exit;
      end;

   s := cmd;
   if AnsiLeftStr(s,2) = 'IF' then
      begin
      Delete(s,1,2);
      end;
   hz := StrToIntDef(AnsiLeftStr(s,11),-999);   //[f]*****+yyyyrx*00tmvspbd1*;
   if hz = -999 then
      begin
      logger.Error('[ParseIFCommand] frequency returned in IF command was not a number %s',[AnsiLeftStr(s,11)]);
      Exit;
      end;
   

   Delete(s,1,11); // Remove frequency
   Delete(s,1,5); // Remove 5 blanks          // *****+yyyyrx*00tmvspbd1*;
   if AnsiLeftStr(s,1) = '-' then
      begin
      ritMultiplier := -1;
      xitMultiplier := -1;
      end
   else if AnsiLeftStr(s,1) = '+' then
      begin
      ritMultiplier := 1;
      xitMultiplier := 1;
      end;
   Delete(s,1,1);                      // yyyyrx*00tmvspbd1*;
   ritOffset := StrToIntDef(AnsiLeftStr(s,4),-999);
   if ritOffset = -999 then
      begin
      logger.Error('[ParseIFCommand] RIT offset returned in IF command was not a number %s',[AnsiLeftStr(s,4)]);
      Exit;
      end;

   Self.localRITOffset := (ritOffset * ritMultiplier);
   Self.localXITOffset := (Self.localRITOffset); // Because on K4, these are the same
   logger.trace('[ParseIFCommand] RITOffset = %d',[Self.localRITOffset]);
   
   Delete(s,1,4);                      // rx*00tmvspbd1*;
   Self.RITState := AnsiLeftStr(s,1) = '1';
   logger.trace('In IF processor, RIT is %s',[AnsiLeftStr(s,1)]);

   Delete(s,1,1);                      // x*00tmvspbd1*;
   Self.XITState := AnsiLeftStr(s,1) = '1';
   logger.trace('In IF processor, XIT is %s',[AnsiLeftStr(s,1)]);

   Delete(s,1,1);
   Delete(s,1,1); // Skip space       // *00tmvspbd1*;
   Delete(s,1,2); // Skip 00          // 00tmvspbd1*;

   if AnsiLeftStr(s,1) = '1' then     // tmvspbd1*;
      begin
      Self.RadioState := rsTransmit;
      end
   else
      begin
      Self.RadioState := rsReceive;
      end;
   Delete(s,1,1);
   logger.trace('[ParseIFCommand] string at mode = %s',[s]);
   sMode := AnsiLeftStr(s,1);          // mvspbd1*;

   Delete(s,1,1);
   logger.trace('[ParseIFCommand] string at vfo = %s',[s]);
   sVFO := AnsiLeftStr(s,1);           // vspbd1*;

   Delete(s,1,2); // Skip s as we do not care if scanning  // spbd1*;
   logger.trace('[ParseIFComand] Checking split command in %s',[s]);
   Self.localSplitEnabled := AnsiLeftStr(s,1) = '1';           // pbd1*;


   Delete(s,1,1);

   Delete(s,1,1); // Skip the b // bd1*;

   // (0=DATA A, 1=AFSK A, 2= FSK D, 3=PSK D)

   sDataMode := AnsiLeftStr(s,1);

   // Post processing from gathered variables to the right VFO
   if sVFO = '0' then // VFO A
      begin
      vfo := Self.vfo[nrVFOA];
      end
   else
      begin
      vfo := Self.vfo[nrVFOB];
      end;

   vfo.frequency := hz;
   vfo.band := FreqToRadioBand(hz);
      // Serial polling only sends IF;FB; (AI off), so BN never arrives on a
      // band change -- derive band from frequency here, as every other modern
      // radio class does (Icom/Flex/TS-890).  Keeps the band label in sync when
      // the operator changes bands on the radio over a serial connection.
   vfo.mode := ModeStrToMode(sMode,sDataMode);



end;

{
Type TRadioMode = (rmNone,rmCW, rmCWRev, rmLSB, rmUSB, rmFM, rmAM,
                   rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev,
                   rmAFSK, rmAFSKRev);
                   }

// Helper functions
function TK4Radio.ModeStrToMode(sMode: string; sDataMode: string): TRadioMode;
var iMode: integer;
begin
   iMode := StrToIntDef(sMode,-999);
   case iMode of
      0: Result := rmNone;
      1: Result := rmLSB;
      2: Result := rmUSB;
      3: Result := rmCW;
      4: Result := rmFM;
      5: Result := rmAM;
      6: begin
            case StrToIntDef(sDataMode,-9) of
            0: Result := rmData;
            1: Result := rmAFSK;
            2: Result := rmFSK;
            3: Result := rmPSK;
            -9:begin
               logger.Error('[ModeStrToMode] Non-numeric string passed for sDataMode (%s)',[sDataMode]);
               Result := rmData;
               end;
            else
               begin
               logger.Error('[ModeStrToMode] Unexpected string passed for sDataMode (%s)',[sDataMode]);
               Result := rmData;
               end;
            end;
         end;
      7: Result := rmCWRev;
      9: Result := rmDataRev;
      -999: begin
            logger.error('[ModeStrToMode] Non-numeric string passed for sMode (%s)',[sMode]);
            Result := rmNone;
            end;
      else
         begin
         logger.error('[ModeStrToMode] Unexpected string passed for sMode (%s)',[sMode]);
         Result := rmNone;
         end;
      end; // case
end;
procedure TK4Radio.ProcessMsg(msg: string);
begin
   // Forward to ProcessMessage to maintain compatibility
   ProcessMessage(msg);
end;

procedure TK4Radio.ProcessMessage(sMessage: string);
var
   sCommand: string;
   sData: string;
  // sMode: string;
   hz: integer;
   i: integer;
   RITSign: integer;
   ritHz : integer;
   sDataMode: string;
   vfo: TRadioVFO;
   vfoBCommand: boolean;
begin
// This is called by the process that receives data on the socket - Event
// K4 messages are seperated by semi-colons (;) but each message should not have the ; as that is the ReadLn delimiter.
// This is a command that has been parsed into its parts. For example, if the radio
// sends RX;DT5;, this procedure is called once with RX; and once with DT5;
   logger.Trace('[ProcessMessage] Received from radio: (%s)',[sMessage]);
   UpdateLastValidResponse;  // Any message from the radio means it's connected
   sCommand := AnsiLeftStr(sMessage,2);
   if AnsiMidStr(sMessage,3,1) = '$' then
      begin
      logger.trace('[ProcessMessage] VFO B message received %s',[sMessage]);
      vfoBCommand := true;
      sData := AnsiMidStr(sMessage,4,length(sMessage));
      vfo := Self.vfo[nrVFOB];
      end
   else
      begin
      logger.trace('[ProcessMessage] VFO A message received %s',[sMessage]);
      vfoBCommand := false;
      sData := AnsiMidStr(sMessage,3,length(sMessage));
      vfo := Self.vfo[nrVFOA];
      end;
   if AnsiRightStr(sData,1) = ';' then      // Remove ; at end.
      begin
      SetLength(sData,length(sData)-1);
      end;

   Case AnsiIndexText(AnsiUppercase(sCommand), ['AI','BI','BN','DT','FA','FB','FT','IF','KS','MA','MD','RT','RX','TX','XT','RO','FP','PO']) of
      0: begin                                     // AI
         logger.debug('[ProcessMessage] AI command set to %s',[sData]);
         end;
      1: begin            // BI
         if sData = '1' then
            begin
            Self.bandIndependence := true;
            end;
         end;
      2: begin              // BN
         if Self.BandNumToBand(sData) <> vfo.band then
            begin    // band change so prime RIT, MD settings
            logger.debug('[TK4Radio.ProcessMessage] BN Received %s - Sending BN;BN$;MD;MD$;DT;DT$;FA;FB;IF;IF$;FP;FP$; to radio',[sData]);
            Self.SendToRadio('BN;BN$;MD;MD$;DT;DT$;FA;FB;IF;IF$;FP;FP$;');
            end;
         vfo.band := Self.BandNumToBand(sData);   // if I just set this, then CurrentStatus.band does not get set. It requires the next line to show up upon resetting the ports.
         Self.vfo[nrVFOA].band := Self.BandNumToBand(sData);     // These two things should be the same.
         logger.trace('[ProcessMessage] Received band number of %s',[sData]);
         end;
      3: begin             // DT
         // DT updates only the remembered data sub-mode.
         // The K4 sends DT responses even when in SSB/CW — the sub-mode register persists.
         // vfo.mode must NOT be set here; doing so would overwrite a valid SSB/CW mode.
         // The MD handler already applies vfo.datamode → vfo.mode when MD=6 arrives.
         sDataMode := AnsiLeftStr(sData,1);
         case StrToIntDef(sDataMode,-9) of
            0: vfo.datamode := rmData;
            1: vfo.datamode := rmAFSK;
            2: vfo.datamode := rmFSK;
            3: vfo.datamode := rmPSK;
            -9:logger.error('[ProcessMessage] Non-numeric passed with DT command (%s)',[sData]);
            end;
         // If currently in a data mode, sync vfo.mode with the new sub-mode.
         if vfo.mode in [rmData, rmDataRev, rmFSK, rmFSKRev, rmPSK, rmPSKRev, rmAFSK, rmAFSKRev] then
            vfo.mode := vfo.datamode;
         end;
      4: begin             // FA
         hz := StrToIntDef(AnsiLeftStr(sData,11),-9);
         if hz >= 0 then
            begin
            Self.vfo[nrVFOA].frequency := hz;
            Self.vfo[nrVFOA].band := FreqToRadioBand(hz);   // keep band in sync with frequency (see ParseIFCommand note)
            end
         else
            begin
            logger.error('[ProcessMessage] non-numeric passed in sData with FA command (%s)',[AnsiLeftStr(sData,11)]);
            end;
         end;
      5: begin             // FB
         hz := StrToIntDef(AnsiLeftStr(sData,11),-9);
         if hz >= 0 then
            begin
            Self.vfo[nrVFOB].frequency := hz;
            Self.vfo[nrVFOB].band := FreqToRadioBand(hz);   // keep band in sync with frequency (see ParseIFCommand note)
            end
         else
            begin
            logger.error('[ProcessMessage] non-numeric passed in sData with FB command (%s)',[AnsiLeftStr(sData,11)]);
            end;
         end;
      6: begin             // FT
         Self.localSplitEnabled := AnsiLeftStr(sData,1) = '1';
         logger.trace('[ProcessMessage] FT (Split) received - Split is %s - localSplitEnabled = %s',[AnsiLeftStr(sData,1),BoolToString(Self.localSplitEnabled)]);
         end;
      7: begin             // IF
         Self.ParseIFCommand(sData);
         end;
      8: begin             // KS
         logger.debug('Received %s in response to KS command',[sData]);
         i := StrToIntDef(AnsiLeftStr(sData,3),-1);
         if IntegerBetween(i,8,100) then
            begin
            Self.localCWSpeed := i;
            end
         else
            begin
            logger.Warn('[ProcessMessage] Invalid CW speed received in KS command (%s)',[AnsiLeftStr(sData,3)]);
            end;
         end;
      9: begin             // MA
         end;
      10:begin             // MD
         // For DATA mode (6), the sub-mode comes separately via DT response.
         // Use the already-known vfo.datamode to avoid a spurious ModeStrToMode error.
         if AnsiLeftStr(sData,1) = '6' then
            vfo.mode := vfo.datamode
         else
            vfo.mode := Self.ModeStrToMode(AnsiLeftStr(sData,1),' ');
         end;
      11:begin              // RT
         vfo.RITState := AnsiLeftStr(sData,1) = '1';
         //Self.RITState := AnsiLeftStr(sData,1) = '1';
         logger.debug('[ProcessMsg] RIT Enabled is %s',[AnsiLeftStr(sData,1)]);
         end;
      12:Self.radioState := rsReceive; // RX
      13:Self.radioState := rsTransmit; // TX
      14:begin              // XT
         vfo.XITState := AnsiLeftStr(sData,1) = '1';
         //Self.XITState := AnsiLeftStr(sData,1) = '1';
         logger.trace('[ProcessMessage] XIT Enabled is %s',[AnsiLeftStr(sData,1)]);
         end;
      15:begin    // RO
         RITSign := IfThen(AnsiLeftStr(sData,1) = '-',-1,1);
         {if AnsiLeftStr(sData,1) = '-' then
            begin
            RITSign := -1;
            end
         else
            begin
            RITSign := 1;
            end;}
         ritHz := StrToIntDef(AnsiMidStr(sData,2,4),99999);
         if ritHz = 99999 then
            begin
            ritHz := 0;
            logger.error('[ProcessMessage] Invalid value passed in RO command: %s',[sData]);
            end
         else
            begin
            ritHz := ritHz * ritSign;
            vfo.RITOffset := ritHz;
            vfo.XITOffset := ritHz;
            //Self.localRITOffset := ritHz;
            //Self.localXITOffset := ritHz; // Because on K4, this is the same value
            end;

         end;
      16:begin    // FP
         i := StrToIntDef(AnsiLeftStr(sData,1),-1);
         if i <> -1 then
            begin
            vfo.filter := i;
            end
         else
            begin
            logger.error('[ProcessMessage] For FP command, invalid value in sData (%s)',[sData]);
            end;
         end;
      17:begin    // PO (response to PING -- the full token is PONG;)
         // The K4 server drops clients that send nothing for 10 s.
         // We send PING; at 1 Hz from PollRadioState in network mode
         // (see Connect's network branch and Issue #897).  PONG; is
         // the documented response.  Nothing to do here: the call to
         // UpdateLastValidResponse at the top of ProcessMessage has
         // already refreshed the inbound watchdog, which is the only
         // state PONG carries.  Explicit case branch (rather than a
         // fall-through) so future maintainers can see that PONG is
         // an expected message and is handled, not ignored by accident.
         logger.Trace('[ProcessMessage] PONG keep-alive response');
         end;
   end; // of case
   if firstProcessMessage then
      begin
      firstProcessMessage := false;
      Initialize;
      end;
end;

function TK4Radio.BandNumToBand(sBand: string): TRadioBand;
var
   iBand: integer;
begin
   iBand := StrToIntDef(sBand,-9);
   logger.trace('[BandNumToBand] Converting band string "%s" to iBand=%d', [sBand, iBand]);
   case iBand of
      0: Result := rb160m;
      1: Result := rb80m;
      2: Result := rb60m;
      3: Result := rb40m;
      4: Result := rb30m;
      5: Result := rb20m;
      6: Result := rb17m;
      7: Result := rb15m;
      8: Result := rb12m;
      9: Result := rb10m;
      10:Result := rb6m;
      -9:begin
         logger.Error('[BandNumToBand] Invalid band requested (non-numeric): %s',[sBand]);
         Result := rbNone;
         end;
   else
      begin
      logger.Error('[BandNumToBand] Unhandled band value: %d (from string: %s)',[iBand, sBand]);
      Result := rbNone;
      end;
   end;
   logger.trace('[BandNumToBand] Result band = %d', [Ord(Result)]);
end;

procedure TK4Radio.PollRadioState;
begin
   if Self.serialPort <> NoPort then
      begin
      // Serial: poll state (no AI on serial).
      // IF gives VFO A freq + mode + RIT/XIT/split/TX state in one response.
      // FB gives VFO B frequency.
      Self.SendToRadio('IF;FB;');
      end
   else
      begin
      // Network: AI5 already pushes state changes; just keep the
      // connection alive.  PING; is the documented keep-alive
      // command (Issue #897, K4 Programmer's Reference).  The K4
      // server drops clients that go silent for 10 s, so we send
      // PING; at 1 Hz from Connect's pollingInterval.
      Self.SendToRadio('PING;');
      end;
end;

procedure TK4Radio.SetAIMode(i: integer);
begin
   Self.SendToRadio(Format('AI%d;',[i]));
end;

procedure TK4Radio.Initialize;
begin
   // Now rigLabel is set by LOGRADIO — reinitialize logger with the radio's identity.
   // Inherits root appender and format; category name appears in every log line.
   if Self.rigLabel <> '' then
      logger := TLogLogger.GetLogger('TR4WDebugLog.K4-' + Self.rigLabel)
   else
      logger := TLogLogger.GetLogger('TR4WDebugLog.K4-Radio');

   if Self.serialPort <> NoPort then
      Self.SetAIMode(0)   // Serial: polling mode; AI5 would flood the serial port
   else
      Self.SetAIMode(5);
   logger.debug('[TK4Radio.Initialize] Sending KS;BN;RT;XT;RO;FT;ID;MD;DT$;IF;FP; to radio');
   Self.SendToRadio('KS;BN;RT;XT;RO;FT;ID;MD;DT;IF;FP;');
   Self.SendToRadio('BN$;RT$;XT$;RO$;MD$;DT$;IF$;FP$;');
end;

procedure TK4Radio.SendToRadio(whichVFO: TVFO; sCmd: string; sData: string);
begin
   if whichVFO = nrVFOB then
      begin
      Inherited SendToRadio(Format('%s$%s;',[sCmd,sData]));
      end
   else if whichVFO = nrVFOA then
      begin
      Inherited SendToRadio(Format('%s%s;',[sCmd,sData]));
      end
   else
      begin
      logger.error('[SendToRadio] Invalid VFO passed for command %s - data = %s',[sCmd, sData]);
      end;

end;

function TK4Radio.ModeTypeToInteger(mode: TRadioMode; var dataModeInt: integer): integer; // This converts the class mode to the K4 mode MD command
begin
   Result := -1;
   dataModeInt := -1; // So we do not mislead the caller since DATA A is 0.
   case mode of
      rmNone: Result := 0;
      rmCW: Result := 3;
      rmCWRev: Result := 7;
      rmLSB: Result := 1;
      rmUSB: Result := 2;
      rmFM: Result := 4;
      rmAM: Result := 5;
      rmData:
         begin
         Result := 6;
         dataModeInt := 0;
         end;
      rmDataRev:
         begin
         Result := 9;
         dataModeInt := 0;
         end;
      rmFSK:
         begin
         Result := 6;
         dataModeInt := 2;
         end;
      rmFSKRev:
         begin
         Result := 6;
         dataModeInt := 2;
         end;
      rmPSK:
         begin
         Result := 6;
         dataModeInt := 3;
         end;
      rmPSKRev:
         begin
         Result := 9;
         dataModeInt := 3;
         end;
      rmAFSK:
         begin
         Result := 6;
         dataModeInt := 1;
         end;
      rmAFSKRev:
         begin
         Result := 9;
         dataModeInt := 1;
         end;
      end;

end;

{
// Not called for some reason - But reserve for future use
function TK4Radio.IsDataMode(mode: TRadioMode): boolean;
begin
   Result := mode in [rmData,rmDataRev];
end;
}

end.
