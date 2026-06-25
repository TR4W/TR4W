unit uIcomNetworkTypes;

{
  Icom Network Protocol Types and Constants

  All packed record types for the Icom proprietary UDP network protocol.
  Used for controlling Icom radios over Ethernet/WiFi.

  Byte order convention:
    - Packet header fields (Len, PktType, Seq, SentID, RcvdID): Little-endian
    - Payload fields (PayloadSize, InnerSeq, CivPort, etc.): Big-endian

  Reference: docs/ICOM_NETWORK_DELPHI_REFERENCE.md
}

interface

uses
  SysUtils;

const
  // Default ports
  ICOM_DEFAULT_CONTROL_PORT = 50001;
  ICOM_DEFAULT_CIV_PORT = 50002;        // Fallback if radio reports 0
  ICOM_CLIENT_NAME = 'TR4W';

  // Packet types (in PktType field, little-endian)
  ICOM_PKT_DATA           = $0000;
  ICOM_PKT_AUTH           = $0001;  // Auth/session packets: login resp, token, capabilities, status
  ICOM_PKT_ARE_YOU_THERE  = $0003;
  ICOM_PKT_I_AM_HERE      = $0004;
  ICOM_PKT_DISCONNECT     = $0005;
  ICOM_PKT_ARE_YOU_READY  = $0006;
  ICOM_PKT_PING           = $0007;

  // Packet sizes
  ICOM_CONTROL_PKT_SIZE   = $10;   // 16 bytes
  ICOM_PING_PKT_SIZE      = $15;   // 21 bytes
  ICOM_DATA_HDR_SIZE      = $15;   // 21 bytes (header only, before CI-V data)
  ICOM_OPENCLOSE_PKT_SIZE = $16;   // 22 bytes
  ICOM_LOGIN_PKT_SIZE     = $80;   // 128 bytes
  ICOM_LOGIN_RESP_SIZE    = $60;   // 96 bytes
  ICOM_TOKEN_PKT_SIZE     = $40;   // 64 bytes
  ICOM_STATUS_PKT_SIZE    = $50;   // 80 bytes
  ICOM_CONNINFO_PKT_SIZE  = $90;   // 144 bytes
  ICOM_CAPABILITIES_HDR   = $42;   // 66 bytes header
  ICOM_RADIOCAP_SIZE      = $66;   // 102 bytes per radio entry

  // Timer intervals (ms)
  ICOM_PING_INTERVAL             = 500;
  ICOM_IDLE_INTERVAL             = 100;
  ICOM_TOKEN_RENEWAL_INTERVAL    = 60000;   // 60 seconds
  ICOM_RETRANSMIT_CHECK_INTERVAL = 100;
  ICOM_CIV_WATCHDOG_INTERVAL     = 500;
  ICOM_CIV_TIMEOUT_THRESHOLD     = 2000;    // 2 seconds
  ICOM_PING_DEAD_TIMEOUT_MS      = 3000;    // 3 seconds without a ping -> declare link lost.  Radio sends pings every 100 ms, so 30 missed pings is unambiguous; a transient sub-3-second network glitch won't trigger a false reconnect cycle.  Was 15000 -- felt sluggish to operators turning the radio off (Issue: IC-7760 disconnect detection delay).
  ICOM_CIV_OPERATIONAL_TIMEOUT_MS = 3000;   // No inbound CI-V data for this long => the radio is no longer answering (powered off / link lost), so report not-operational.  The polling thread queries the radio (PollRadioState) every ~500 ms and a powered radio answers each with CI-V data, so 3 s = ~6 missed poll cycles: comfortably clears an idle-but-connected radio while catching a powered-off one within a few seconds.  Drives the freq-display alert color and the UDP RadioInfo IsConnected field.  Issue #1062.

  // "Are You There" retry config
  ICOM_AYT_MAX_RETRIES    = 10;
  ICOM_AYT_INITIAL_INTERVAL = 500;
  ICOM_AYT_MAX_INTERVAL   = 5000;

  // Auth
  ICOM_AUTH_SEQ_START      = $0030;
  ICOM_AUTH_FAILED         = $FEFFFFFF;

  // Data packet markers
  ICOM_DATA_REPLY_MARKER   = $C1;
  ICOM_OPENCLOSE_DATA      = $01C0;

  // Open/Close magic values
  ICOM_MAGIC_OPEN          = $04;
  ICOM_MAGIC_CLOSE         = $00;

  // Token request types
  ICOM_TOKEN_ACK           = $02;
  ICOM_TOKEN_RENEW         = $05;

  // ConnInfo request type
  ICOM_CONNINFO_REQUEST    = $03;

  // Timer IDs (for Windows SetTimer)
  ICOM_TIMER_PING          = 5001;
  ICOM_TIMER_IDLE          = 5002;
  ICOM_TIMER_TOKEN         = 5003;
  ICOM_TIMER_RETRANSMIT    = 5004;
  ICOM_TIMER_CIV_WATCHDOG  = 5005;
  ICOM_TIMER_AYT           = 5006;
  ICOM_TIMER_LOGIN         = 5007;

  // Login retry timing (for when radio has stale session and doesn't respond)
  ICOM_LOGIN_TIMEOUT       = 5000;   // 5 seconds between login retries
  ICOM_LOGIN_MAX_RETRIES   = 6;      // 6 retries = 30 seconds max

  // CI-V markers
  CIV_PREAMBLE             = $FE;
  CIV_EOM                  = $FD;

  // TX buffer for retransmit responses
  ICOM_BUFSIZE             = 500;    // Max entries in tx seq buffers
  // Note: Retransmit request uses PktType=$0001, same as ICOM_PKT_AUTH.
  // Context determines meaning: during auth it's auth data, when connected it's retransmit.

  // Reset capability value
  ICOM_RESET_CAP           = $0798;

type
  // Connection state machine (matches wfview's 7 states)
  TIcomConnectionState = (
    icsDisconnected,
    icsWaitingForHere,      // Sent "Are You There", waiting for "I Am Here"
    icsWaitingForReady,     // Sent "Are You Ready", waiting for "I Am Ready"
    icsWaitingForLogin,     // Sent login, waiting for response
    icsAuthenticated,       // Login OK, sent token ack, waiting for capabilities
    icsStreamRequested,     // Sent stream request, waiting for CI-V port
    icsConnected            // Connected — CI-V handshake happens within this state
  );

  // Control Packet (0x10 = 16 bytes)
  // Used for: Are You There ($03), I Am Here ($04), Disconnect ($05),
  //           Are You Ready / I Am Ready ($06)
  TControlPacket = packed record
    Len:      LongWord;   // $00 - Always $10 (16)
    PktType:  Word;       // $04 - Packet type
    Seq:      Word;       // $06 - Sequence number
    SentID:   LongWord;   // $08 - Sender's ID
    RcvdID:   LongWord;   // $0C - Receiver's ID
  end;

  // Ping Packet (0x15 = 21 bytes)
  TPingPacket = packed record
    Len:      LongWord;   // $00 - Always $15 (21)
    PktType:  Word;       // $04 - Always $07
    Seq:      Word;       // $06 - Ping sequence number
    SentID:   LongWord;   // $08
    RcvdID:   LongWord;   // $0C
    Reply:    Byte;       // $10 - 0=request, 1=response
    Time:     LongWord;   // $11 - Uptime in ms
  end;

  // Data Packet Header (0x15 = 21 bytes + CI-V data follows)
  TDataPacket = packed record
    Len:      LongWord;   // $00 - Total packet length (header + CI-V data)
    PktType:  Word;       // $04 - Always $00
    Seq:      Word;       // $06 - Outer UDP sequence number
    SentID:   LongWord;   // $08
    RcvdID:   LongWord;   // $0C
    Reply:    Byte;       // $10 - $C1 for data
    DataLen:  Word;       // $11 - Length of CI-V data following (big-endian!)
    SendSeq:  Word;       // $13 - Inner CI-V stream sequence (big-endian!)
  end;

  // Open/Close Packet (0x16 = 22 bytes)
  TOpenClosePacket = packed record
    Len:      LongWord;   // $00 - Always $16 (22)
    PktType:  Word;       // $04 - Always $00
    Seq:      Word;       // $06 - Outer sequence
    SentID:   LongWord;   // $08
    RcvdID:   LongWord;   // $0C
    Data:     Word;       // $10 - Always $01C0
    Unused:   Byte;       // $12
    SendSeq:  Word;       // $13 - Inner sequence (big-endian!)
    Magic:    Byte;       // $15 - $04=Open, $00=Close
  end;

  // Login Packet (0x80 = 128 bytes)
  TLoginPacket = packed record
    Len:          LongWord;                // $00 - Always $80 (128)
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian! Value = $70
    RequestReply: Byte;                    // $14 - Always $01
    RequestType:  Byte;                    // $15 - Always $00
    InnerSeq:     Word;                    // $16 - Big-endian! Auth sequence
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A - Random token request ID
    Token:        LongWord;               // $1C - 0 for initial login
    UnusedC:      array[0..31] of Byte;    // $20
    Username:     array[0..15] of Byte;    // $40 - Encoded username
    Password:     array[0..15] of Byte;    // $50 - Encoded password
    ClientName:   array[0..15] of Byte;    // $60 - ASCII client name
    UnusedF:      array[0..15] of Byte;    // $70
  end;

  // Login Response Packet (0x60 = 96 bytes)
  TLoginResponsePacket = packed record
    Len:          LongWord;                // $00 - Always $60 (96)
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian
    RequestReply: Byte;                    // $14
    RequestType:  Byte;                    // $15
    InnerSeq:     Word;                    // $16 - Big-endian
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A
    Token:        LongWord;               // $1C - THE TOKEN (save this!)
    AuthStartID:  Word;                    // $20
    UnusedD:      array[0..13] of Byte;    // $22
    Error:        LongWord;               // $30 - $FEFFFFFF = auth failed, 0 = success
    UnusedE:      array[0..11] of Byte;    // $34
    Connection:   array[0..15] of Byte;    // $40
    UnusedF:      array[0..15] of Byte;    // $50
  end;

  // Token Packet (0x40 = 64 bytes)
  TTokenPacket = packed record
    Len:          LongWord;                // $00 - Always $40 (64)
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian
    RequestReply: Byte;                    // $14 - $01
    RequestType:  Byte;                    // $15 - $02=ack, $05=renew
    InnerSeq:     Word;                    // $16 - Big-endian
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A
    Token:        LongWord;               // $1C
    AuthStartID:  Word;                    // $20
    UnusedG2:     array[0..1] of Byte;     // $22
    ResetCap:     Word;                    // $24 - Big-endian, send $0798
    UnusedG1:     Byte;                    // $26
    CommonCap:    Word;                    // $27
    UnusedH:      Byte;                    // $29
    MacAddress:   array[0..5] of Byte;     // $2A
    Response:     LongWord;               // $30
    UnusedE:      array[0..11] of Byte;    // $34
  end;

  // Status Packet (0x50 = 80 bytes)
  TStatusPacket = packed record
    Len:          LongWord;                // $00 - Always $50 (80)
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian
    RequestReply: Byte;                    // $14
    RequestType:  Byte;                    // $15
    InnerSeq:     Word;                    // $16 - Big-endian
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A
    Token:        LongWord;               // $1C
    AuthStartID:  Word;                    // $20
    UnusedD:      array[0..4] of Byte;     // $22
    CommonCap:    Word;                    // $27
    UnusedE:      Byte;                    // $29
    MacAddress:   array[0..5] of Byte;     // $2A
    Error:        LongWord;               // $30 - $FFFFFFFF = connection failed
    UnusedG:      array[0..11] of Byte;    // $34
    Disc:         Byte;                    // $40 - $01 = disconnected
    UnusedH:      Byte;                    // $41
    CivPort:      Word;                    // $42 - Big-endian! CI-V UDP port
    UnusedI:      Word;                    // $44
    AudioPort:    Word;                    // $46
    UnusedJ:      array[0..7] of Byte;     // $48 - 8 bytes to reach $50 total
  end;

  // ConnInfo / Stream Request Packet (0x90 = 144 bytes)
  TConnInfoPacket = packed record
    Len:          LongWord;                // $00 - Always $90 (144)
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian ($80)
    RequestReply: Byte;                    // $14 - $01
    RequestType:  Byte;                    // $15 - $03
    InnerSeq:     Word;                    // $16 - Big-endian
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A
    Token:        LongWord;               // $1C
    GUID:         array[0..15] of Byte;    // $20
    UnusedAB:     array[0..15] of Byte;    // $30
    RadioName:    array[0..31] of Byte;    // $40
    Username:     array[0..15] of Byte;    // $60 - Encoded username
    RxEnable:     Byte;                    // $70 - 1 = enable
    TxEnable:     Byte;                    // $71 - 0 = disable (control only)
    RxCodec:      Byte;                    // $72 - $04 = LPCM
    TxCodec:      Byte;                    // $73 - 0
    RxSample:     LongWord;               // $74 - Big-endian, 8000
    TxSample:     LongWord;               // $78 - 0
    CivPort:      LongWord;               // $7C - Big-endian, YOUR local CI-V port
    AudioPort:    LongWord;               // $80 - 0
    TxBuffer:     LongWord;               // $84 - 0
    Convert:      Byte;                    // $88 - 1
    UnusedL:      array[0..6] of Byte;     // $89
  end;

  // Capabilities Packet Header (variable size: header + N * TRadioCapPacket)
  TCapabilitiesPacket = packed record
    Len:          LongWord;                // $00
    PktType:      Word;                    // $04
    Seq:          Word;                    // $06
    SentID:       LongWord;               // $08
    RcvdID:       LongWord;               // $0C
    PayloadSize:  LongWord;               // $10 - Big-endian
    RequestReply: Byte;                    // $14
    RequestType:  Byte;                    // $15
    InnerSeq:     Word;                    // $16 - Big-endian
    UnusedB:      array[0..1] of Byte;     // $18
    TokRequest:   Word;                    // $1A
    Token:        LongWord;               // $1C
    UnusedD:      array[0..31] of Byte;    // $20
    NumRadios:    Word;                    // $40 - Big-endian, number of radio entries
    // Followed by NumRadios * TRadioCapPacket
  end;

  // Radio Capability Entry (0x66 = 102 bytes each)
  TRadioCapPacket = packed record
    UnusedE:      array[0..6] of Byte;     // $00
    CommonCap:    Word;                    // $07 - $8010 = uses MAC, else uses GUID
    Unused:       Byte;                    // $09
    MacAddress:   array[0..5] of Byte;     // $0A
    RadioName:    array[0..31] of Byte;    // $10 - e.g. "IC-7760" null-terminated
    AudioName:    array[0..31] of Byte;    // $30
    ConnType:     Word;                    // $50
    CivAddress:   Byte;                    // $52 - CI-V address (e.g. $B2 for IC-7760)
    RxSample:     Word;                    // $53
    TxSample:     Word;                    // $55
    EnableA:      Byte;                    // $57
    EnableB:      Byte;                    // $58
    EnableC:      Byte;                    // $59
    BaudRate:     LongWord;               // $5A - Big-endian
    CapF:         Word;                    // $5E
    UnusedI:      Byte;                    // $60
    CapG:         Word;                    // $61
    UnusedJ:      array[0..2] of Byte;     // $63
  end;

  // Discovered radio info (returned by discovery)
  TDiscoveredRadio = record
    IPAddress:  string;
    RadioName:  string;
    CivAddress: Byte;
    RemoteId:   LongWord;
  end;
  PDiscoveredRadio = ^TDiscoveredRadio;

  // TX sequence buffer entry — stores sent packets for radio's retransmit requests
  TSeqBufEntry = record
    Seq:              Word;
    Data:             string;       // Raw packet bytes
    SendTime:         LongWord;     // GetTickCount when sent
    RetransmitCount:  Byte;
  end;
  PSeqBufEntry = ^TSeqBufEntry;

// Byte-order helpers
function SwapWord(Value: Word): Word;
function SwapLongWord(Value: LongWord): LongWord;

// Password encoding
procedure IcomPasscode(const Input: string; var Output: array of Byte);

// Client ID generation
function CalculateMyId(LocalIP: LongWord; LocalPort: Word): LongWord;

// Connection state name for logging
function IcomStateToString(State: TIcomConnectionState): string;

implementation

function SwapWord(Value: Word): Word;
begin
  Result := (Value shr 8) or (Value shl 8);
end;

function SwapLongWord(Value: LongWord): LongWord;
begin
  Result := ((Value and $000000FF) shl 24) or
            ((Value and $0000FF00) shl 8) or
            ((Value and $00FF0000) shr 8) or
            ((Value and $FF000000) shr 24);
end;

procedure IcomPasscode(const Input: string; var Output: array of Byte);
const
  Sequence: array[0..127] of Byte = (
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
    $47,$5D,$4C,$42,$66,$20,$23,$46,$4E,$57,$45,$3D,$67,$76,$60,$41,
    $62,$39,$59,$2D,$68,$7E,$7C,$65,$7D,$49,$29,$72,$73,$78,$21,$6E,
    $5A,$5E,$4A,$3E,$71,$2C,$2A,$54,$3C,$3A,$63,$4F,$43,$75,$27,$79,
    $5B,$35,$70,$48,$6B,$56,$6F,$34,$32,$6C,$30,$61,$6D,$7B,$2F,$4B,
    $64,$38,$2B,$2E,$50,$40,$3F,$55,$33,$37,$25,$77,$24,$26,$74,$6A,
    $28,$53,$4D,$69,$22,$5C,$44,$31,$36,$58,$3B,$7A,$51,$5F,$52,0
  );
var
  I, P: Integer;
  MaxLen: Integer;
begin
  // Clear output (assuming 16-byte array)
  for I := 0 to High(Output) do
    Output[I] := 0;

  MaxLen := Length(Input);
  if MaxLen > 16 then
    MaxLen := 16;

  for I := 1 to MaxLen do
  begin
    P := Ord(Input[I]) + (I - 1);  // Delphi strings are 1-based
    if P > 126 then
      P := 32 + (P mod 127);
    Output[I - 1] := Sequence[P];
  end;
end;

function CalculateMyId(LocalIP: LongWord; LocalPort: Word): LongWord;
begin
  // LocalIP is in host byte order (e.g., 192.168.1.100 = $C0A80164)
  Result := ((LocalIP shr 8) and $FF) shl 24    // 3rd octet
         or ((LocalIP) and $FF) shl 16           // 4th octet
         or (LocalPort and $FFFF);               // local port
end;

function IcomStateToString(State: TIcomConnectionState): string;
begin
  case State of
    icsDisconnected:       Result := 'Disconnected';
    icsWaitingForHere:     Result := 'WaitingForHere';
    icsWaitingForReady:    Result := 'WaitingForReady';
    icsWaitingForLogin:    Result := 'WaitingForLogin';
    icsAuthenticated:      Result := 'Authenticated';
    icsStreamRequested:    Result := 'StreamRequested';
    icsConnected:          Result := 'Connected';
  else
    Result := 'Unknown';
  end;
end;

end.
