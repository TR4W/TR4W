unit uSuperCheckPartialFileUpload;

interface


uses Classes, SysUtils, IdSSLOpenSSLHeaders, IdHashSHA, IdHttp, IdGlobal, Log4D,
     IdCoderMIME, IdSSLOpenSSL, IdIOHandler, IdIOHandlerSocket, IdLogFile, DateUtils, Windows;


const
   SCP_TESTURL = 'https://www.supercheckpartial.com/api/v1/testcabsubmit';
   //SCP_TESTURL = 'https://192.168.1.1';
   SCP_PRODURL = 'https://www.supercheckpartial.com/api/v1/cabsubmit';
   SCP_CANAME = 'Encrypt';

   

Type TSCPUpload = class(TObject)
   private
      m_loggerName: string;
      m_trace: boolean;
      m_loggerHash: string;
      m_production: boolean;
      m_timestamp: string;
      m_uploadURL: string;
      m_cabHash: string;
      m_cabEncoded: string;
      m_httpResult: string;
      m_errorResult: string;
      m_httpStatusCode: integer;
      m_JSON: string;
      indyLog: TIdLogFile;
      sslOpts: TIdSSLIOHandlerSocketOpenSSL;
      http: TIdHTTP;
      logger: TLogLogger;
      appender: TLogFileAppender;
      localLog: boolean;
      function GetLoggerName: string;
      procedure SetLoggerName(loggerName: string);
      function SSLIOHandlerVerifyPeer(ThePeerCert: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;


   public
      constructor Create(bProduction: boolean; FLogger: TLogLogger);
      destructor Destroy;
      function GetHashSHA256(_string: string): string;
      function GetHashSHA256File(_filename: string): string;
      function SendFile(_filename: string): boolean;
      Property loggerName: string read GetLoggerName write SetLoggerName;
      property httpStatusCode: integer read m_httpStatusCode;
      property errorResult: string read m_errorResult;
      property httpResult: string read m_httpResult;
      property trace: boolean read m_trace write m_trace;
   end;

implementation

constructor TSCPUpload.Create(bProduction: boolean; FLogger: TLogLogger);

begin
   Self.m_trace := false;
   IdSSLOpenSSLHeaders.Load();
   if FLogger = nil then
      begin
      appender := TLogRollingFileAppender.Create('name','scp.log');
      appender.Layout := TLogPatternLayout.Create('%d ' + TTCCPattern);
      TLogBasicConfigurator.Configure(appender);
      //logLevels := llError; // For after we load config so we can set the value.
      //TLogLogger.GetRootLogger.Level := Error;
      logger := TLogLogger.GetLogger('SCPDebugLog');
      localLog := true;
      end
   else
      begin
      localLog := false;
      logger := FLogger;
      end;
   if bProduction then
      begin
      logger.Info('Calling supercheckpartial in production mode - %s',[SCP_PRODURL]);
      Self.m_production := true;
      Self.m_uploadURL := SCP_PRODURL;
      Self.m_timestamp := '2022-04-06 13:25:27';
      end
   else
      begin
      logger.Info('Calling supercheckpartial in test mode - %s',[SCP_TESTURL]);
      Self.m_uploadURL := SCP_TESTURL;
      Self.m_timestamp := '2022-04-01 00:01:02';
      m_production := false;
      end;
   http := TIdHttp.Create(nil);
   http.HandleRedirects := true;
   http.Request.ContentType := 'application/json';
   http.Request.UserAgent := 'TR4W';
   http.Request.Accept := 'application/json';
   sslOpts := TIdSSLIOHandlerSocketOpenSSL.Create;
   sslOpts.SSLOptions.Method := TIdSSLVersion(sslvTLSv1_2);
   //sslOpts.SSLOptions.CertFile := 'cacert.pem';
   sslOpts.SSLOptions.VerifyMode := [sslvrfPeer];
   sslOpts.OnVerifyPeer := Self.SSLIOHandlerVerifyPeer;
   http.IOHandler := sslOpts;

   // Logging
   if Self.m_trace then
      begin
      indyLog := TIdLogFile.Create(nil);
      indyLog.Filename := 'indy.log';
      http.Intercept := indyLog;
      indyLog.Active := true;
      end;




end;

destructor TSCPUpload.Destroy;
begin
   if http <> nil then
      begin
      FreeAndNil(http);
      end;
  if sslOpts <> nil then
     begin
     FreeANdNil(sslOpts);
     end;
  if localLog then
     begin
     if logger <> nil then
        begin
        FreeAndNil(logger);
        end;
     if appender <> nil then
        begin
        FreeAndNil(appender);
        end;
     end;
end;

function TSCPUpload.SendFile(_filename: string): boolean;
var fs: TFileStream;
    ms: TMemoryStream;
    //s: string;
    httpResult: string;
    hash: string;
    json: TSTringStream;
   // response: TStringStream;
    sCabRaw: string;
begin
   //Result := false;
   // First check that the log file exists
   if not FileExists(_filename) then
      begin
      Result := false;
      self.m_errorResult := 'Request log file to send does not exist [' + _filename + ']';
      Exit;
      end;
   // Check that SHA256 is available
   if not TIdHashSHA256.IsAvailable then
      begin
      Result := false;
      Self.m_errorResult := 'SHA256 is not available to this instance of Indy - CheckOpenSSL dlls are available';
      Exit;
      end;
   // Store the hash of the CAB file
   Self.m_cabHash := Self.GetHashSHA256File(_filename);

   // Get the Base64 encoded value of file
   try
      fs:= TFileStream.Create(_filename, fmOpenRead);
      Self.m_cabEncoded := TIdEncoderMime.EncodeStream(fs);
   finally
      fs.Free;
   end;

   // Read the entire log into memory
   try
      ms := TMemoryStream.Create;
      ms.LoadFromFile(_filename);
      if ms.Size > 0 then
         begin
         SetLength(sCabRaw,ms.Size);
         Move(ms.Memory^,sCabRaw[1],ms.Size);
         end;
   finally
      if ms <> nil then
         begin
         ms.Free;
         end;
   end;



   // Set the logger name
   Self.loggerName := 'TR4W';  // Sets m_loggerHash too.


   // Set the hash-signature
   // Build the hash from the sharedSecret sha256[(m_credentials) and can (plain text)]
   hash := AnsiLowerCase(Self.GetHashSHA256(Self.m_loggerHash + sCabRaw));

   // Build the JSON
   Self.m_JSON := '{' +
                  '"Version": "1.0",' +
                  '"Logger": "' + Self.GetLoggerName + '",' +
                  '"Timestamp": "' + Self.m_timestamp + '",' +
                  '"Hash": "' + hash + '",' +
                  '"File": "' + Self.m_cabEncoded + '"' +
                  '}';
   json := TStringStream.Create(Self.m_JSON);
   try
      httpResult := Self.http.Post(Self.m_uploadURL, json);
      Self.m_httpResult := httpResult;
      Self.m_httpStatusCode := Self.http.ResponseCode;
      Result := Self.http.ResponseCode = 200;
   except
      on E: Exception do
         begin
         Result := false;
         Self.m_errorResult := '***ERROR*** ' + E.ClassName + ' ' + E.Message;
         end;
   end;
end;

function TSCPUpload.GetLoggerName: string;
begin
   Result := Self.m_loggerName;
end;

procedure TSCPUpload.SetLoggerName(loggerName: string);
//var s: string;
begin
   Self.m_loggerName := loggerName;
   Self.http.Request.UserAgent := loggerName;
   if Self.m_production then
      begin
      // Assemble the shared secret key into m_credentials
      Self.m_loggerHash := 'fd69e886e1cab8a22698046375664888f3783b93ce533824d1454c141ffca179';
      end
   else
      begin
      Self.m_loggerHash := AnsiLowerCase(Self.GetHashSHA256(Self.m_loggerName + Self.m_timestamp));
      end;
end;

function TSCPUpload.GetHashSHA256File(_filename: string): string;
var
   sha: TIdHashSHA256;
   fs: TFileStream;
begin
   if TIdHashSHA256.IsAvailable then
      begin
      sha:= TIdHashSHA256.Create;
      try
         fs:= TFileStream.Create(_filename, fmOpenRead);
         try
            Result:= sha.HashStreamAsHex(fs);
         finally
            sha.Free;
         end;
      finally
         fs.Free;
      end;
    end;
end;

function TSCPUpload.GetHashSHA256(_string: string): string;
  var
   sha: TIdHashSHA256;
  begin
   if TIdHashSHA256.IsAvailable then
    begin
     sha:= TIdHashSHA256.Create;
     try
      Result:= sha.HashStringAsHex(_string);
     finally
      sha.Free;
     end;
    end;
  end;

function TSCPUpload.SSLIOHandlerVerifyPeer(ThePeerCert: TIdX509; AOk: Boolean; ADepth, AError: Integer): Boolean;
var sTemp: string;
   sActualIssuerName: string;
   sActualPeerName: string;
  // bVerifiedPeer: boolean;
   begin
//Note this is called MULTIPLE times, one for each cert in the chain, starting
//with the CA cert & ending with the user cert.
   Result := false;
   if AOk = True then
      begin
      sTemp := 'SSLIOHandlerVerifyPeer called with AOk = TRUE';
      end
   else
      begin
      sTemp := 'SSLIOHandlerVerifyPeer called with AOk = FALSE';
      end;
  // TheHttpLog.LogWriteString(sTemp+#13#10);
   sActualIssuerName := ThePeerCert.Issuer.OneLine;
   //TheHttpLog.LogWriteString('Peer certificate issuer name: '+sActualPeerName+#13#10);
   sActualPeerName := ThePeerCert.Subject.OneLine;
   //TheHttpLog.LogWriteString('Peer certificate subject name: '+sActualPeerName+#13#10);
   //TheHttpLog.LogWriteString('Peer certificate fingerprint: '+ThePeerCert.FingerprintAsString+#13#10);
   if CompareDateTime(Now,ThePeerCert.notBefore) = 1 then
      begin
      if CompareDateTime(Now,ThePeerCert.notAfter) = -1 then
         begin
         if (Pos(UpperCase(SCP_CANAME), UpperCase(sActualIssuerName)) > 0) or
            ((Pos(UpperCase('supercheckpartial.com'), UpperCase(sActualPeerName)) > 0)) then
            begin
            //bVerifiedPeer := True;
            Result := True;
            end;
         end;
      end;
   end;
end.
