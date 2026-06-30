unit uExternalLogger;

interface
uses uExternalLoggerBase, StrUtils, SysUtils, Math, TF, VC, LOGSUBS2, LogWind, LogDupe, Tree, uCFG, PostUnit,
     IdTCPClient;


Type TExternalLogger = class(TExternalLoggerBase)
   private
     // localCE: ContestExchange;
      procedure Initialize;
      procedure SendToLogger(sCmd: string; sData: string); overload;
      function AddADIFField(sFieldName: string; sValue: string): string; overload;
      function AddADIFField(sFieldName: string; nValue: integer): string; overload;

      // DXKeeper -- these now BUILD and return the DXKeeper message; the actual
      // send is queued (one connect-per-command op on the sender thread). Issue #957.
      function BuildDXKeeperLogMessage(ce: ContestExchange): string;
      function BuildDXKeeperDeleteMessage(ce: ContestExchange): string; // These functions should be changed to an interface so we just call one based on the interface (by log type). ny4i
      function LookupCallsignToDXKeeper(ce: ContestExchange): integer;

      // ACLog
      function LogQSOToACLog(ce: ContestExchange): integer;

      // HRD
      function LogQSOToHRD(ce: ContestExchange): integer;



      // Add a QueueQSO to copy the record then return to the caller. This allows the actual sending of the TCP message ot be done from a different thread to not slow down the program.

      // I could also generalize this into post QSO Processing and let the UDP happen from the thread too. Worth exploring the actual amont of time per QSO to send to UDP and TCP. If it is very fast, this complication may not be necessary.
   protected
      // DXKeeper transport: one connect -> send one command -> let DXKeeper close
      // (its by-design model; confirmed with AA6YQ). Issue #957.
      function DeliverCommand(const cmd: string): boolean; override;

   public
      Constructor Create(); overload;
      Constructor Create(logType: ExternalLoggerType{sLoggerType: string}); overload;

      function Connect: integer; overload;
      procedure ProcessMessage(sMessage: string);
      function LogQSO(ce: ContestExchange): integer;
      function DeleteQSO(ce: ContestExchange): integer;
      function ReplaceQSO(ce: ContestExchange): integer;   // Issue #957 -- edit = atomic delete + re-log
      function LookupCallsign(ce:ContestExchange): integer;

end;


var
   firstProcessMessage: boolean = true;
implementation

Uses MainUnit;

Constructor TExternalLogger.Create();
begin
   inherited Create(ProcessMessage);
end;

Constructor TExternalLogger.Create(logType: ExternalLoggerType) {sLoggerType: string)};
begin
  // Self.loggerID := sLoggerType;
  Self.logType := logType;
  Self.logTypeSet := true;
   Self.Create(ProcessMessage);
end;

function TExternalLogger.Connect: integer;
begin
   Self.readTerminator := ';';
   Result := Inherited Connect;
   if Self.IsConnected then
      begin
      end;
end;

procedure TExternalLogger.ProcessMessage(sMessage: string);
var
   sCommand: string;
  // i: integer;
begin
// This is called by the process that receives data on the socket - Event
   logger.Debug('[TExternalLogger.ProcessMessage] Received from external logger: (%s)',[sMessage]);
   sCommand := AnsiLeftStr(sMessage,2);

   
   if firstProcessMessage then
      begin
      firstProcessMessage := false;
      Initialize;
      end;
end;



procedure TExternalLogger.Initialize;
begin

end;

const
   DXK_CONNECT_TIMEOUT_MS = 2000;   // DXKeeper is normally local; fail fast and retry
   DXK_READ_TIMEOUT_MS    = 1000;   // bound the wait for a response / the close

function TExternalLogger.DeliverCommand(const cmd: string): boolean;
var
   client: TIdTCPClient;
   resp: string;
begin
   // Issue #957 -- DXKeeper reads exactly one command per connection, then closes
   // (its by-design model, confirmed with AA6YQ).  So each command gets its own
   // fresh connection: connect -> send -> read any response until DXKeeper closes.
   // Runs on the sender thread, never the main thread.  The caller (DeliverWithRetry)
   // handles bounded retry on failure.
   Result := False;
   client := TIdTCPClient.Create(nil);
   try
      client.Host := Self.loggerAddress;
      client.Port := Self.loggerPort;
      client.ConnectTimeout := DXK_CONNECT_TIMEOUT_MS;
      client.ReadTimeout := DXK_READ_TIMEOUT_MS;
      try
         client.Connect;
         try
            client.IOHandler.WriteLn(cmd);
            Result := True;   // the command is on the wire = success
            logger.Debug('[DXKeeper.DeliverCommand] sent: %s', [cmd]);
            // Best-effort: read any response until DXKeeper closes (bounded).
            try
               while client.Connected do
                  begin
                  resp := client.IOHandler.ReadLn(';', DXK_READ_TIMEOUT_MS);
                  if client.IOHandler.ReadLnTimedout then
                     begin
                     Break;
                     end;
                  if resp <> '' then
                     begin
                     logger.Debug('[DXKeeper.DeliverCommand] response: %s', [resp]);
                     Self.ProcessMessage(resp);
                     end;
                  end;
            except
               on Exception do
                  begin
                  // DXKeeper closing after the command is the normal/expected path.
                  end;
            end;
         finally
            try
               if client.Connected then
                  begin
                  client.Disconnect;
                  end;
            except
               on Exception do
                  begin
                  // ignore disconnect errors
                  end;
            end;
         end;
      except
         on E: Exception do
            begin
            logger.Warn('[DXKeeper.DeliverCommand] %s:%d failed: %s - %s',
                        [Self.loggerAddress, Self.loggerPort, E.ClassName, E.Message]);
            // Result stays False unless WriteLn already succeeded -> caller retries.
            end;
      end;
   finally
      client.Free;
   end;
end;

procedure TExternalLogger.SendToLogger(sCmd: string; sData: string);
begin
   if not Self.IsConnected then
      begin
      Self.Connect;
      end;
   Inherited SendTologger(Format('%s%s;',[sCmd,sData])); // Build the externalcommand ADIF here

end;

function TExternalLogger.LogQSO(ce: ContestExchange): integer;
begin
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.LogQSO, logType set to NoExternalLogger');
         end;
      lt_DxKeeper:
         begin
         Self.QueueSingleCommand(Self.BuildDXKeeperLogMessage(ce), 'Log ' + ce.Callsign);
         Result := 0;
         end;
      lt_ACLog: Result := Self.LogQSOToACLog(ce);
      lt_HRD: Result := Self.LogQSOToHRD(ce);
   end;
end;

function TExternalLogger.DeleteQSO(ce: ContestExchange): integer;
begin
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.DeleteQSO, logType set to NoExternalLogger');
         end;
      lt_DxKeeper:
         begin
         Self.QueueSingleCommand(Self.BuildDXKeeperDeleteMessage(ce), 'Delete ' + ce.Callsign);
         Result := 0;
         end;
      //lt_ACLog: Result := Self.LogQSOToACLog(ce);
      //lt_HRD: Result := Self.LogQSOToHRD(ce);
   end;
end;

function TExternalLogger.ReplaceQSO(ce: ContestExchange): integer;
begin
   // Issue #957 -- an edit is a delete of the original followed by a re-log of the
   // edited QSO.  Queue it as ONE atomic replace so the re-log is sent only if the
   // delete succeeds, and so the two never share a TCP connection (DXKeeper reads
   // exactly one command per connection, then closes).
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.ReplaceQSO, logType set to NoExternalLogger');
         end;
      lt_DxKeeper:
         begin
         Self.QueueReplace(Self.BuildDXKeeperDeleteMessage(ce),
                           Self.BuildDXKeeperLogMessage(ce),
                           'Replace ' + ce.Callsign);
         Result := 0;
         end;
      else
         begin
         // Other loggers: best-effort delete then re-log (no atomic guarantee yet).
         Self.DeleteQSO(ce);
         Self.LogQSO(ce);
         Result := 0;
         end;
   end;
end;

function TExternalLogger.LookupCallsign(ce: ContestExchange): integer;
begin
   case Self.logType of
      lt_NoExternalLogger:
         begin
         Result := -1;
         logger.Error('Within TExternalLogger.LookupCallsign, logType set to NoExternalLogger');
         end;
      lt_DxKeeper: Result := Self.LookupCallsign(ce);
      //lt_ACLog: Result := Self.LogQSOToACLog(ce);
      //lt_HRD: Result := Self.LogQSOToHRD(ce);
   end;

end;

function TExternalLogger.BuildDXKeeperLogMessage(ce: ContestExchange): string;
var sCoreADIF: string;
    //n: integer;
    sMode: string;
    sOperator: string;
    nCoreADIFLength: integer;
    sOptions: string;
    nOptionsLength: integer;
    sMessage: string;
    sSubMode: string;
    sTemp: string;
    saveDecimalSeparator: char;
begin
{   This is the example from https://www.dxlabsuite.com/Interoperation.htm
<command:11>externallog<parameters:341><ExternalLogADIF:187><CALL:4>P5DX <RST_SENT:3>599
<RST_RCVD:3>599 <FREQ:6>14.004 <BAND:3>20M <MODE:2>CW <QSO_DATE:8>20220411 <TIME_ON:6>072800
<STATION_CALLSIGN:5>AA6YQ <TX_PWR:4>1000 <GRIDSQUARE:4>PM29 <EOR><UploadeQSL:1>Y
<UploadLoTW:1>Y<UploadClubLog:1>Y<DeduceMissing:1>Y<QueryCallbook:1>Y<UpdateeQSL:1>Y<UpdateLoTW:1>Y<CheckOverrides:1>Y

This is all we need to send as we DO NOT want to send every contact to any of the online QSL services like LOTW, QRZ, eQSL or ClubLog.

<command:11>externallog<parameters:341><ExternalLogADIF:187><CALL:4>P5DX <RST_SENT:3>599
<RST_RCVD:3>599 <FREQ:6>14.004 <BAND:3>20M <MODE:2>CW <QSO_DATE:8>20220411 <TIME_ON:6>072800
<STATION_CALLSIGN:5>AA6YQ <TX_PWR:4>1000 <GRIDSQUARE:4>PM29 <EOR><UploadeQSL:1>N
<UploadLoTW:1>N<UploadClubLog:1>N<DeduceMissing:1>Y<QueryCallbook:1>Y<UpdateeQSL:1>N<UpdateLoTW:1>N<CheckOverrides:1>Y

}
   if CurrentOperator[0] = #0 then
       begin
       sOperator := MyCall;
       end
   else
      begin
      sOperator := ce.ceOperator;
      end;

   if ce.ExtMode <> eNoMode then
      begin
      sMode := ExtendedModeStringArray[ce.extMode];
      if ce.ExtMode = eFT4 then    // ??? In MFSKModes[TempRXData.ExtMode]?
         begin
         sMode := 'MFSK';
         sSubMode := ExtendedModeStringArray[ce.ExtMode];
         end
      end
   else
      begin
      case ce.Mode of
         CW: sMode := 'CW';
         Phone: sMode := 'SSB';
         Digital: sMode := 'RTTY';
         FM: sMode := 'FM';
         else sMode := 'CW';
         end; // of case
      end;

  sCoreADIF :=   AddADIFField('CALL',ce.Callsign)
               + AddADIFField('RST_SENT',ce.RSTSent)
               + AddADIFField('RST_RCVD',ce.RSTReceived);
  if ce.Frequency <> 0 then //14149280  or 7025000
     begin
     saveDecimalSeparator := DecimalSeparator;
        try
           DecimalSeparator := '.';
           sTemp := FloatToStr((ce.Frequency/1000000));
           sCoreADIF := sCoreADIF + AddADIFField('FREQ',sTemp);
        finally
           DecimalSeparator := saveDecimalSeparator;
        end;
     end;
     sCoreADIF :=   sCoreADIF
                  + AddADIFField('BAND',ADIFBANDSTRINGSARRAY[ce.Band])
                  + ADDADIFField('MODE',sMode)
                  + AddADIFField('CONTEST_ID',ContestTypeSA[ce.ceContest])
                  + AddADIFField('QSO_DATE',SysUtils.format('20%0.2d%0.2d%0.2d',
                                                            [ce.tSysTime.qtYear,
                                                             ce.tSysTime.qtMonth,
                                                             ce.tSysTime.qtDay]))
                  + AddADIFField('TIME_ON',SysUtils.format('%0.2d%0.2d%0.2d',
                                                          [ce.tSysTime.qtHour,
                                                           ce.tSysTime.qtMinute,
                                                           ce.tSysTime.qtSecond]))
                  + AddADIFField('STATION_CALLSIGN',MyCall)
                  + AddADIFField('OPERATOR',sOperator)

                  + AddADIFField('SRX_STRING', ce.ExchString)
                  + AddADIFField( 'STX_STRING',Trim(DeleteRepeatedSpaces(GetMyExchangeForExport)))



                  ;
  if ExchangeInformation.QSONumber then
     begin
     if ce.NumberReceived <> -1 then
        begin
        sCoreADIF := sCoreADIF + AddADIFField('SRX',IntToStr(ce.NumberReceived));
        end;
     if ce.NumberSent <> -1 then
        begin
        sCoreADIF := sCoreADIF + AddADIFField('STX',IntToStr(ce.NumberSent));
        end;
      end;

  if ce.Age <> 0 then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('AGE',IntToStr( ce.Age));
     end;

  if sSubMode <> '' then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('SUBMODE',sSubMode);
     end;
  if LooksLikeAGrid(ce.QTHString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.QTHString);
     end
  else if LooksLikeAGrid(ce.ExchString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.ExchString);
     end
  else if LooksLikeAGrid(ce.DomesticQTH) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('GRIDSQUARE',ce.DomesticQTH);
     end;
  if LooksLikeASection(ce.QTHString) then
     begin
     sCoreADIF := sCoreADIF + AddADIFField('ARRL_SECT', ce.QTHString);
     end;
   // TODO To include ARRL_SECTION, the EXCHANGEINFORMATION record should have a section indicator, thenuse that to grab section from   QTHString
  sCoreADIF := sCoreADIF + '<EOR>';
  nCoreADIFLength := length(sCoreADIF);
  sCoreADIF := '<ExternalLogADIF:' + IntToStr(nCoreADIFLength) + '>' + sCoreADIF;
  nCoreADIFLength := length(sCoreADIF); // Update to include the ExternalLogADIF field
  // Issue #957 -- option flags for the externallog command.
  // Enrichment + membership lookups are ON (Y): DeduceMissing, QueryCallbook,
  // CheckOverrides, UpdateeQSL, UpdateLoTW.  These only fill in or annotate
  // DXKeeper's local copy of the record, so they add useful data without the
  // edit-window concern below.  (An earlier "command in progress" rejection that
  // these appeared to trigger turned out to be a DXKeeper-side bug, since fixed.)
  // QSL-server UPLOADS are OFF (N): UploadeQSL, UploadLoTW, UploadClubLog,
  // UploadQRZ.  Uploading the instant the QSO is logged would leave no window to
  // edit it first; the operator uploads later (or via DXKeeper's own workflow).
  // NOTE: if DXKeeper's AutoUpload options are checked, the Upload* N values are
  // not honored.
  sOptions :=   AddADIFField('DeduceMissing','Y')
              + AddADIFField('QueryCallbook','Y')
              + AddADIFField('CheckOverrides','Y')
              + AddADIFField('UpdateeQSL','Y')
              + AddADIFField('UpdateLoTW','Y')
              + AddADIFField('UploadeQSL','N')
              + AddADIFField('UploadLoTW','N')
              + AddADIFField('UploadClubLog','N')
              + AddADIFField('UploadQRZ','N')
              ;
  nOptionsLength := length(sOptions);
  sMessage := '<command:11>externallog<parameters:' + IntToStr(nCoreADIFLength + nOptionsLength) + '>' + sCoreADIF + sOptions;
  Result := sMessage;
end;

//-------------------------------
function TExternalLogger.BuildDXKeeperDeleteMessage(ce: ContestExchange): string;
var sCoreADIF: string;
    //n: integer;

    nCoreADIFLength: integer;

    sMessage: string;

   // sTemp: string;

begin

  sCoreADIF :=   AddADIFField('CALL',ce.Callsign)
               + AddADIFField('QSO_DATE',SysUtils.format('20%0.2d%0.2d%0.2d',
                                                         [ce.tSysTime.qtYear,
                                                          ce.tSysTime.qtMonth,
                                                          ce.tSysTime.qtDay]))
               + AddADIFField('TIME_ON',SysUtils.format('%0.2d%0.2d%0.2d',
                                                        [ce.tSysTime.qtHour,
                                                         ce.tSysTime.qtMinute,
                                                         ce.tSysTime.qtSecond]))
               ;

  sCoreADIF := sCoreADIF + '<EOR>';
  //nCoreADIFLength := length(sCoreADIF);
 // sCoreADIF := '<ExternalLogADIF:' + IntToStr(nCoreADIFLength) + '>' + sCoreADIF;
  nCoreADIFLength := length(sCoreADIF); // Update to include the ExternalLogADIF field
  sMessage := '<command:9>deleteqso<parameters:' + IntToStr(nCoreADIFLength {+ nOptionsLength}) + '>' + sCoreADIF;
  Result := sMessage;
end;

function TExternalLogger.LookupCallsignToDXKeeper(ce: ContestExchange): integer;
var sMessage: string;
begin
  sMessage := '<command:5>check<parameters:' + IntToStr(length(ce.Callsign)) + '>' + ce.Callsign;
  logger.Debug('[TExternalLogger.LookupQSOToDXKeeper] Sending message to external logger: [%s]',[sMessage]);
  Self.SendToLogger(sMessage);
end;
//--------------------------------
function TExternalLogger.LogQSOToACLog(ce: ContestExchange): integer;
begin
   logger.Info('Logging to ACLog not yet implemented');
end;

function TExternalLogger.LogQSOToHRD(ce: ContestExchange): integer;
begin
   logger.Info('Logging to HRD not yet implemented');
end;

function TExternalLogger.AddADIFField(sFieldName: string; sValue: string): string;
begin
   result := '<' + sFieldName + ':' + IntToStr(length(sValue)) + '>' + sValue + ' ';
end;

function TExternalLogger.AddADIFField(sFieldName: string; nValue: integer): string;
begin
   result := '<' + sFieldName + ':' + IntToStr(DigitsIn(nValue)) + '>' + IntToStr(nValue) + ' ';
end;

end.
