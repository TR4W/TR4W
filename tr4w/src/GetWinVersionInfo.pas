unit GetWinVersionInfo platform;

interface

uses
  Windows;

{$IF RTLVersion < 18}
{$MESSAGE Warn 'Not tested on Delphi versions before 2007!'}
{$IFEND}


function GetOSInfo: string;
function GetWindowsBuildDetail: string;

var
  GetProductInfo: function (dwOSMajorVersion, dwOSMinorVersion,
                            dwSpMajorVersion, dwSpMinorVersion: DWORD;
                            var pdwReturnedProductType: DWORD): BOOL stdcall = nil;
var
  GetNativeSystemInfo: procedure(var SysInfo: TSystemInfo); stdcall = nil;

implementation

uses Registry, SysUtils;

{$IF RTLVersion < 19}

// Only used for pre-unicode versions of Delphi. Provides some definitions that
// Windows.pas doesn't provide in earlier versions of Delphi (most likely because
// they didn't exist them.
//
// No support for the W versions of the API definitions

type
  _OSVERSIONINFOEX = record
    dwOSVersionInfoSize : DWORD;
    dwMajorVersion      : DWORD;
    dwMinorVersion      : DWORD;
    dwBuildNumber       : DWORD;
    dwPlatformId        : DWORD;
    szCSDVersion        : array[0..127] of AnsiChar;
    wServicePackMajor   : WORD;
    wServicePackMinor   : WORD;
    wSuiteMask          : WORD;
    wProductType        : BYTE;
    wReserved           : BYTE;
  end;
  TOSVERSIONINFOEX = _OSVERSIONINFOEX;

const
  VER_NT_WORKSTATION    :Integer = 1;
  VER_SUITE_ENTERPRISE  :Integer = 2;
  VER_NT_SERVER         :Integer = 3;
  VER_SUITE_DATACENTER  :Integer = 128;
  VER_SUITE_PERSONAL    :Integer = 512;

const
  PRODUCT_UNDEFINED                           = $00000000;
  PRODUCT_ULTIMATE                            = $00000001;
  PRODUCT_HOME_BASIC                          = $00000002;
  PRODUCT_HOME_PREMIUM                        = $00000003;
  PRODUCT_ENTERPRISE                          = $00000004;
  PRODUCT_HOME_BASIC_N                        = $00000005;
  PRODUCT_BUSINESS                            = $00000006;  { Business }
  PRODUCT_STANDARD_SERVER                     = $00000007;
  PRODUCT_DATACENTER_SERVER                   = $00000008;
  PRODUCT_SMALLBUSINESS_SERVER                = $00000009;
  PRODUCT_ENTERPRISE_SERVER                   = $0000000A;
  PRODUCT_STARTER                             = $0000000B;
  PRODUCT_DATACENTER_SERVER_CORE              = $0000000C;
  PRODUCT_STANDARD_SERVER_CORE                = $0000000D;
  PRODUCT_ENTERPRISE_SERVER_CORE              = $0000000E;
  PRODUCT_ENTERPRISE_SERVER_IA64              = $0000000F;
  PRODUCT_BUSINESS_N                          = $00000010;
  PRODUCT_WEB_SERVER                          = $00000011;
  PRODUCT_CLUSTER_SERVER                      = $00000012;
  PRODUCT_HOME_SERVER                         = $00000013;
  PRODUCT_STORAGE_EXPRESS_SERVER              = $00000014;
  PRODUCT_STORAGE_STANDARD_SERVER             = $00000015;
  PRODUCT_STORAGE_WORKGROUP_SERVER            = $00000016;
  PRODUCT_STORAGE_ENTERPRISE_SERVER           = $00000017;
  PRODUCT_SERVER_FOR_SMALLBUSINESS            = $00000018;
  PRODUCT_SMALLBUSINESS_SERVER_PREMIUM        = $00000019;
  PRODUCT_HOME_PREMIUM_N                      = $0000001A;
  PRODUCT_ENTERPRISE_N                        = $0000001B;
  PRODUCT_ULTIMATE_N                          = $0000001C;
  PRODUCT_WEB_SERVER_CORE                     = $0000001D;
  PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT    = $0000001E;
  PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY      = $0000001F;
  PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING     = $00000020;
  PRODUCT_SERVER_FOUNDATION                   = $00000021;
  PRODUCT_HOME_PREMIUM_SERVER                 = $00000022;
  PRODUCT_SERVER_FOR_SMALLBUSINESS_V          = $00000023;
  PRODUCT_STANDARD_SERVER_V                   = $00000024;
  PRODUCT_DATACENTER_SERVER_V                 = $00000025;
  PRODUCT_ENTERPRISE_SERVER_V                 = $00000026;
  PRODUCT_DATACENTER_SERVER_CORE_V            = $00000027;
  PRODUCT_STANDARD_SERVER_CORE_V              = $00000028;
  PRODUCT_ENTERPRISE_SERVER_CORE_V            = $00000029;
  PRODUCT_HYPERV                              = $0000002A;
  PRODUCT_STORAGE_EXPRESS_SERVER_CORE         = $0000002B;
  PRODUCT_STORAGE_STANDARD_SERVER_CORE        = $0000002C;
  PRODUCT_STORAGE_WORKGROUP_SERVER_CORE       = $0000002D;
  PRODUCT_STORAGE_ENTERPRISE_SERVER_CORE      = $0000002E;
  PRODUCT_STARTER_N                           = $0000002F;
  PRODUCT_PROFESSIONAL                        = $00000030;
  PRODUCT_PROFESSIONAL_N                      = $00000031;
  PRODUCT_SB_SOLUTION_SERVER                  = $00000032;
  PRODUCT_SERVER_FOR_SB_SOLUTIONS             = $00000033;
  PRODUCT_STANDARD_SERVER_SOLUTIONS           = $00000034;
  PRODUCT_STANDARD_SERVER_SOLUTIONS_CORE      = $00000035;
  PRODUCT_SB_SOLUTION_SERVER_EM               = $00000036;
  PRODUCT_SERVER_FOR_SB_SOLUTIONS_EM          = $00000037;
  PRODUCT_SOLUTION_EMBEDDEDSERVER             = $00000038;
  PRODUCT_SOLUTION_EMBEDDEDSERVER_CORE        = $00000039;
  PRODUCT_SMALLBUSINESS_SERVER_PREMIUM_CORE   = $0000003F;
  PRODUCT_ESSENTIALBUSINESS_SERVER_MGMT       = $0000003B;
  PRODUCT_ESSENTIALBUSINESS_SERVER_ADDL       = $0000003C;
  PRODUCT_ESSENTIALBUSINESS_SERVER_MGMTSVC    = $0000003D;
  PRODUCT_ESSENTIALBUSINESS_SERVER_ADDLSVC    = $0000003E;
  PRODUCT_CLUSTER_SERVER_V                    = $00000040;
  PRODUCT_EMBEDDED                            = $00000041;
  PRODUCT_STARTER_E                           = $00000042;
  PRODUCT_HOME_BASIC_E                        = $00000043;
  PRODUCT_HOME_PREMIUM_E                      = $00000044;
  PRODUCT_PROFESSIONAL_E                      = $00000045;
  PRODUCT_ENTERPRISE_E                        = $00000046;
  PRODUCT_ULTIMATE_E                          = $00000047;
  PRODUCT_UNLICENSED                          = $ABCDABCD;

const
  PROCESSOR_ARCHITECTURE_INTEL            = 0;
  PROCESSOR_ARCHITECTURE_AMD64            = 9;
  SM_MEDIACENTER                          = 87;
  SM_SERVERR2                             = 89; {GetSystemMetrics for Win Server 2K3}

function GetVersionEx(var lpVersionInformation: TOSVersionInfo): BOOL; stdcall; overload;
  external kernel32 name 'GetVersionExA';
function GetVersionEx(var lpVersionInformationEx: TOSVERSIONINFOEX): BOOL; stdcall; overload;
  external kernel32 name 'GetVersionExA';

{$IFEND}

  // Not in the Windows.pas unit as of XE3
const
  PRODUCT_PROFESSIONAL_WMC                    = $00000067; {Professional with Media Center}

function GetOSInfo: string;
var
  NTBres, BRes: Boolean;
  OSVI: TOSVERSIONINFO;
  OSVI_NT: TOSVERSIONINFOEX;
  tmpStr: string;
  pdwReturnedProductType : DWORD;
  SI: TSystemInfo;
begin
  Result := 'Error';
  NTBRes := FALSE;
  try
    OSVI_NT.dwOSVersionInfoSize := SizeOf(TOSVERSIONINFOEX);
    NTBRes := GetVersionEx(OSVI_NT);
    OSVI.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    BRes := GetVersionEx(OSVI);
  except
    OSVI.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
    BRes := GetVersionEx(OSVI);
  end;
  if (not BRes) and (not NTBres) then
    Exit;
  Move( OSVI, OSVI_NT, SizeOf(TOSVersionInfo) );

  if Assigned(GetNativeSystemInfo) then
    GetNativeSystemInfo(SI)
  else
    GetSystemInfo(SI);

  case OSVI_NT.dwPlatformId of
     VER_PLATFORM_WIN32_NT:
       begin
         if OSVI_NT.dwMajorVersion <= 4 then
           Result := 'Windows NT ';
         if (OSVI_NT.dwMajorVersion = 5) then
         begin
           case OSVI_NT.dwMinorVersion of
             0: Result := 'Windows 2000 ';
             1: begin
                  Result := 'Windows XP ';
                  if (GetSystemMetrics(SM_MEDIACENTER) <> 0) then
                    Result := Result + 'Media Center';
                end;
             2: begin
                 if (OSVI_NT.wProductType = VER_NT_WORKSTATION) and
                    (SI.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64) then
                   Result := 'Windows XP Professional x64 '
                 else
                 begin
                   if GetSystemMetrics(SM_SERVERR2) <> 0 then
                     Result := 'Windows Server 2003 R2'
                   else
                     Result := 'Windows Server 2003 ';
                end;
             end;
           end;
         end;
         if (OSVI_NT.dwMajorVersion = 6) then
         begin
           case OSVI_NT.dwMinorVersion of
             0: begin
                  if OSVI_NT.wProductType = VER_NT_WORKSTATION then
                    Result := 'Windows Vista '
                  else
                   Result := 'Windows Server 2008 ';
                 end;
             1:  begin
                   if OSVI_NT.wProductType = VER_NT_WORKSTATION then
                     Result := 'Windows 7 '
                   else
                     Result := 'Windows Server 2008 R2 ';
                 end;
             2:  begin
                   if OSVI_NT.wProductType = VER_NT_WORKSTATION then
                     Result := 'Windows 8 '
                   else
                     Result := 'Windows Server 2012 ';
                 end;
           else
             Result := 'Unknown Windows version ';
           end;

           if Assigned(GetProductInfo) then
           begin
             GetProductInfo(OSVI_NT.dwMajorVersion,
                            OSVI_NT.dwMinorVersion,
                            0,
                            0,
                            pdwReturnedProductType);
             case pdwReturnedProductType of
               PRODUCT_PROFESSIONAL,
               PRODUCT_PROFESSIONAL_N:
                 tmpStr := 'Professional';
               PRODUCT_PROFESSIONAL_WMC:
                 tmpStr := 'Professional with Media Center';
               PRODUCT_BUSINESS,
               PRODUCT_BUSINESS_N:
                 tmpStr := 'Business Edition';
               PRODUCT_CLUSTER_SERVER:
                 tmpStr := 'Cluster Server Edition';
               PRODUCT_DATACENTER_SERVER:
                 tmpStr := 'Server Datacenter Edition (full installation)';
               PRODUCT_DATACENTER_SERVER_CORE:
                 tmpStr := 'Server Datacenter Edition (core installation)';
               PRODUCT_ENTERPRISE,
               PRODUCT_ENTERPRISE_N:
                 tmpStr := 'Enterprise Edition';
               PRODUCT_ENTERPRISE_SERVER:
                 tmpStr := 'Server Enterprise Edition (full installation)';
               PRODUCT_ENTERPRISE_SERVER_CORE:
                 tmpStr := 'Server Enterprise Edition (core installation)';
               PRODUCT_ENTERPRISE_SERVER_IA64:
                 tmpStr := 'Server Enterprise Edition for Itanium-based Systems';
               PRODUCT_HOME_BASIC,
               PRODUCT_HOME_BASIC_N:
                 tmpStr := 'Home Basic Edition';
               PRODUCT_HOME_PREMIUM,
               PRODUCT_HOME_PREMIUM_N:
                 tmpStr := 'Home Premium Edition';
               PRODUCT_HOME_PREMIUM_SERVER:
                 tmpStr := 'Home Premium Server Edition';
               PRODUCT_HOME_SERVER:
                 tmpStr := 'Home Server Edition';
               PRODUCT_HYPERV:
                 tmpStr := 'Hyper-V Server Edition';
               PRODUCT_MEDIUMBUSINESS_SERVER_MANAGEMENT:
                 tmpStr := 'Windows Essential Business Server Management Server Edition';
               PRODUCT_MEDIUMBUSINESS_SERVER_SECURITY:
                 tmpStr := 'Windows Essential Business Server Security Server Edition';
               PRODUCT_MEDIUMBUSINESS_SERVER_MESSAGING:
                 tmpStr := 'Windows Essential Business Server Messaging Server Edition';
               PRODUCT_SERVER_FOR_SMALLBUSINESS:
                 tmpStr := 'Server for Small Business Edition';
               PRODUCT_SERVER_FOUNDATION:
                 tmpStr := 'Server Foundation';
               PRODUCT_SMALLBUSINESS_SERVER:
                 tmpStr := 'Small Business Server';
               PRODUCT_SMALLBUSINESS_SERVER_PREMIUM:
                 tmpStr := 'Small Business Server Premium Edition';
               PRODUCT_STANDARD_SERVER:
                 tmpStr := 'Server Standard Edition (full installation)';
               PRODUCT_STANDARD_SERVER_CORE:
                 tmpStr := 'Server Standard Edition (core installation)';
               PRODUCT_STARTER:
                 tmpStr := 'Starter Edition';
               PRODUCT_STORAGE_ENTERPRISE_SERVER:
                 tmpStr := 'Storage Server Enterprise Edition';
               PRODUCT_STORAGE_EXPRESS_SERVER:
                 tmpStr := 'Storage Server Express Edition';
               PRODUCT_STORAGE_STANDARD_SERVER:
                 tmpStr := 'Storage Server Standard Edition';
               PRODUCT_STORAGE_WORKGROUP_SERVER:
                 tmpStr := 'Storage Server Workgroup Edition';
               PRODUCT_UNDEFINED:
                 tmpStr := 'An unknown product';
               PRODUCT_ULTIMATE,
               PRODUCT_ULTIMATE_N:
                 tmpStr := 'Ultimate Edition';
               PRODUCT_WEB_SERVER:
                 tmpStr := 'Web Server Edition';
               PRODUCT_WEB_SERVER_CORE:
                 tmpStr := 'Web Server Edition (core installation)';
               PRODUCT_UNLICENSED:
                 tmpStr := 'Unlicensed product'
             else
               tmpStr := '';
             end;{ pdwReturnedProductType }
             Result := Result + tmpStr;
             NTBRes := FALSE;
           end;{ GetProductInfo<>NIL }
         end;{ Vista }

         if (OSVI_NT.dwMajorVersion = 10) then
   begin
   if OSVI_NT.dwMinorVersion = 0 then
      begin
      if OSVI_NT.wProductType = VER_NT_WORKSTATION then
         begin
         if OSVI_NT.dwBuildNumber >= 22000 then
            begin
            Result := 'Windows 11 ';
            end
         else
            begin
            Result := 'Windows 10 ';
            end;
         end
      end
   else
      begin
      Result := 'Windows Server 2016 ';
      end;
   end;
         if OSVI_NT.dwMajorVersion >= 6 then
         begin
           if (SI.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64) then
             Result := Result + ' 64-bit '
           else if (SI.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_INTEL) then
             Result := Result + ' 32-bit ';
         end;

         if NTBres then
         begin
           if OSVI_NT.wProductType = VER_NT_WORKSTATION then
           begin
             case OSVI_NT.wSuiteMask of
               512: Result := Result + 'Personal';
               768: Result := Result + 'Home Premium';
             else
               Result := Result + 'Professional';
             end;
           end
           else if OSVI_NT.wProductType = VER_NT_SERVER then
           begin
             if OSVI_NT.wSuiteMask = VER_SUITE_DATACENTER then
               Result := Result + 'DataCenter Server'
             else if OSVI_NT.wSuiteMask = VER_SUITE_ENTERPRISE then
               Result :=  Result + 'Advanced Server'
             else
               Result := Result + 'Server';
           end{ wProductType=VER_NT_WORKSTATION }
           else
           begin
             with TRegistry.Create do
               try
                 RootKey := HKEY_LOCAL_MACHINE;
                 if OpenKeyReadOnly('SYSTEM\CurrentControlSet\' +
                                    'Control\ProductOptions') then
                   try
                     tmpStr := UpperCase(ReadString('ProductType'));
                     if tmpStr = 'WINNT' then
                       Result := Result + 'Workstation';
                     if tmpStr = 'SERVERNT' then
                       Result := Result + 'Server';
                   finally
                     CloseKey;
                   end;
               finally
                 Free;
               end;
   end;{ wProductType<>VER_NT_WORKSTATION }
           end;{ NTBRes }
         end;{ VER_PLATFORM_WIN32_NT }
     VER_PLATFORM_WIN32_WINDOWS:
       begin
         if (OSVI.dwMajorVersion = 4) and (OSVI.dwMinorVersion = 0) then
         begin
           Result := 'Windows 95 ';
           if OSVI.szCSDVersion[1] = 'C' then
             Result := Result + 'OSR2';
         end;
         if (OSVI.dwMajorVersion = 4) and (OSVI.dwMinorVersion = 10) then
         begin
           Result := 'Windows 98 ';
           if OSVI.szCSDVersion[1] = 'A' then
             Result := Result + 'SE';
         end;
         if (OSVI.dwMajorVersion = 4) and (OSVI.dwMinorVersion = 90) then
           Result := 'Windows Me';
       end;{ VER_PLATFORM_WIN32_WINDOWS }
     VER_PLATFORM_WIN32s:
       Result := 'Microsoft Win32s';
  else
    Result := 'Unknown';
  end;{ OSVI_NT.dwPlatformId }
end;{ GetOSInfo }

{ Diagnostic detail only - must never raise. Each value is checked first:
  UBR and DisplayVersion do not exist before Windows 10, and
  TRegistry.ReadInteger raises ERegistryException on a missing value
  (ReadString returns ''). An unguarded read crashed start-up on Windows 7. }
function GetWindowsBuildDetail: string;
const
  REG_KEY = 'SOFTWARE\Microsoft\Windows NT\CurrentVersion';
var
  Reg: TRegistry;
  sDisplay, sBuild: string;
begin
  Result := '';
  sDisplay := '';
  sBuild := '';
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly(REG_KEY) then
       begin
       try
         if Reg.ValueExists('DisplayVersion') then
            begin
            sDisplay := Reg.ReadString('DisplayVersion');
            end;
         if Reg.ValueExists('CurrentBuildNumber') then
            begin
            sBuild := Reg.ReadString('CurrentBuildNumber');
            end;
         Result := sDisplay + ' (Build ' + sBuild;
         if Reg.ValueExists('UBR') then
            begin
            Result := Result + '.' + IntToStr(Reg.ReadInteger('UBR'));
            end;
         Result := Result + ')';
       finally
         Reg.CloseKey;
       end;
       end;
  finally
    Reg.Free;
  end;
end;

initialization
  @GetProductInfo := GetProcAddress(GetModuleHandle('KERNEL32.DLL'),
                                     'GetProductInfo');

  @GetNativeSystemInfo := GetProcAddress(GetModuleHandle('KERNEL32.DLL'),
                                         'GetNativeSystemInfo');

end.



