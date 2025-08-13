unit Roselt.SystemInformation;

interface

uses
  {$IFDEF MACOS}
    MacApi.CoreFoundation,
    MacApi.Foundation,
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    Winapi.Windows,
    Winapi.ActiveX,
    Winapi.WinSock,
    System.Win.ComObj,
  {$ENDIF}
  {$IFDEF ANDROID}
    Androidapi.Helpers,
    Androidapi.JNIBridge,
    Androidapi.JNI.GraphicsContentViewText,
    Androidapi.JNI.App,
    Androidapi.JNI.Net,
    Androidapi.JNI.JavaTypes,
    Androidapi.JNI,
    Androidapi.JNI.Java.Net,
    Androidapi.JNI.Os,
    FMX.Helpers.Android,
  {$ENDIF}
  {$IFDEF WEBLIB}
    Web,
  {$ENDIF}
  {$IFNDEF WEBLIB}
    FMX.Forms,
    FMX.Platform,
    System.IOUtils,
    System.Sensors,
  {$ENDIF}

  System.SysUtils,
  System.Classes,
  System.Variants,
  System.TypInfo;

  {$IFDEF ANDROID}
    type
      JWifiManagerClass = interface(JObjectClass)
      ['{69F35EA7-3EB9-48AA-B7FC-4FFD0E7D712F}']
        function _GetACTION_PICK_WIFI_NETWORK: JString;
        function _GetEXTRA_WIFI_INFO: JString;
        function _GetWIFI_STATE_CHANGED_ACTION: JString;
        property ACTION_PICK_WIFI_NETWORK: JString read _GetACTION_PICK_WIFI_NETWORK;
        property EXTRA_WIFI_INFO: JString read _GetEXTRA_WIFI_INFO;
        property WIFI_STATE_CHANGED_ACTION: JString read _GetWIFI_STATE_CHANGED_ACTION;
      end;

      [JavaSignature('android/net/wifi/WifiInfo')]
      JWifiInfo = interface(JObject)
      ['{4F09E865-DB04-4E64-8C81-AEFB36DABC45}']
        function getBSSID:jString; cdecl;
        function getHiddenSSID:Boolean; cdecl;
        function getIpAddress:Integer; cdecl;
        function getLinkSpeed:integer; cdecl;
        function getMacAddress:JString; cdecl;
        function getNetworkId:integer; cdecl;
        function getRssi:integer; cdecl;
        function GetSSID:jString; cdecl;
      end;

      JWifiInfoClass = interface(JObjectClass)
      ['{2B1CE79F-DE4A-40D9-BB2E-7F9F118D8C08}']
        function _GetLINK_SPEED_UNITS:JString;
        property LINK_SPEED_UNITS: JString read _GetLINK_SPEED_UNITS;
      end;

      TJWifiInfo= class(TJavaGenericImport<JWifiInfoClass, JWifiInfo>) end;

      [JavaSignature('android/net/wifi/WifiManager')]
      JWifiManager = interface(JObject)
      ['{DA7107B9-1FAD-4A9E-AA09-8D5B84614E60}']
        function isWifiEnabled:Boolean;cdecl;
        function setWifiEnabled(enabled:Boolean):Boolean; cdecl;
        function getConnectionInfo :JWifiInfo; cdecl;
        function getWifiState :Integer; cdecl;
        function disconnect :Boolean; cdecl;
      end;

      TJWifiManager = class(TJavaGenericImport<JWifiManagerClass, JWifiManager>) end;
  {$ENDIF}

Type
  TSystemLocation = record
    Latitude: Double;
    Longitude: Double;
  end;

  // Static helper: no instantiation required; all members are class functions/properties
  TSystemInformation = class
  private
    class function GetSystemLanguage: String; static;
    class function GetSystemTotalMemory: String; static;
    class function GetScreenResolution: String; static;
    class function GetOperatingSystem: String; static;
    class function GetSystemArchitecture: String; static;
    class function GetIPAddress: String; static;
    class function GetAppVersion: String; static;
    class function GetAppCompiledDate: String; static;
    class function GetSystemLocation: TSystemLocation; static;
    class function GetUserName: String; static;
    class function GetMacAddress: String; static;
    class function GetVideoCardName: String; static;
    class function GetComputerName: String; static;
    class function GetApplicationType: String; static;
    {$IFDEF WEBLIB}
      class function GetBrowser(): String; static;
    {$ENDIF}
  public
    // Class properties for direct access: TSystemInformation.OperatingSystem, etc.
    class property VideoCard: String read GetVideoCardName;
    class property MacAddress: String read GetMacAddress;
    class property SystemLanguage: String read GetSystemLanguage;
    class property ComputerName: String read GetComputerName;
    class property IPAddress: String read GetIPAddress;
    class property ScreenResolution: String read GetScreenResolution;
    class property OperatingSystem: String read GetOperatingSystem;
    class property SystemArchitecture: String read GetSystemArchitecture;
    class property ApplicationType: String read GetApplicationType;
    class property TotalMemory: String read GetSystemTotalMemory;
    class property AppVersion: String read GetAppVersion;
    class property AppCompiledDate: String read GetAppCompiledDate;
    class property SystemLocation: TSystemLocation read GetSystemLocation;
    class property UserName: String read GetUserName;
    {$IFDEF WEBLIB}
      class property Browser: String read GetBrowser;
    {$ENDIF}
  end;

implementation

{ TSystemInformation }

{$IFDEF MACOS}
function NSUserName: Pointer; cdecl; external '/System/Library/Frameworks/Foundation.framework/Foundation' name _PU +'NSFullUserName';
{$ENDIF}

class function TSystemInformation.GetUserName: String;
begin
  Result := '';
  {$IFDEF MACOS}
    Result := TNSString.Wrap(NSUserName).UTF8String;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    // GetEnvironmentVariable('USERNAME') works on Windows, but is not safe as this can be modified by apps and isn't always accurate
    var nSize: DWord := 1024;
    SetLength(Result, nSize);
    if Winapi.Windows.GetUserName(PChar(Result), nSize) then
    begin
      SetLength(Result, nSize - 1)
    end
    else
    begin
      RaiseLastOSError;
    end
  {$ENDIF}
  {$IFDEF LINUX}
    Result := GetEnvironmentVariable('USERNAME');
  {$ENDIF}
end;

class function TSystemInformation.GetVideoCardName: String;
{$IFDEF MSWINDOWS}
  const
    WbemUser = '';
    WbemPassword = '';
    WbemComputer = 'localhost';
    wbemFlagForwardOnly = $00000020;
  var
    FSWbemLocator: OLEVariant;
    FWMIService: OLEVariant;
    FWbemObjectSet: OLEVariant;
    FWbemObject: OLEVariant;
    oEnum: IEnumvariant;
    iValue: LongWord;
{$ENDIF}
begin;
  Result := '';
  {$IFDEF MSWINDOWS}
    try
      FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
      FWMIService := FSWbemLocator.ConnectServer(WbemComputer, 'root\CIMV2', WbemUser, WbemPassword);
      FWbemObjectSet := FWMIService.ExecQuery('SELECT Name,PNPDeviceID FROM Win32_VideoController', 'WQL', wbemFlagForwardOnly);
      oEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumvariant;
      while oEnum.Next(1, FWbemObject, iValue) = 0 do
      begin
        Result := String(FWbemObject.Name);
        FWbemObject := Unassigned;
      end;
    except

    end;
  {$ENDIF}
  {$IFDEF WEBLIB}
    asm
      let canvas = document.createElement("canvas");
      let gl = canvas.getContext("experimental-webgl");

      if (gl != null) {
        let dbgRenderInfo = gl.getExtension("WEBGL_debug_renderer_info");
        if (dbgRenderInfo != null)
          Result = gl.getParameter(dbgRenderInfo.UNMASKED_RENDERER_WEBGL);
      }
    end;
  {$ENDIF}
end;

class function TSystemInformation.GetAppVersion: String;
var
  wMajor, wMinor, wRelease, wBuild: Word;
  VersionSuccess: Boolean;

  {$IF Defined(ANDROID)}
    PackageManager: JPackageManager;
    PackageInfo : JPackageInfo;
    VersionString: String;
  {$ENDIF}
  {$IF Defined(MSWINDOWS)}
    Size, Size2: DWord;
    Pt, Pt2: Pointer;
  {$ENDIF}
begin
  try
    wMajor := 0;
    wMinor := 0;
    wRelease := 0;
    wBuild := 0;
    {$IF Defined(IOS)}
      // Hasn't been implemented yet
    {$ELSEIF Defined(ANDROID)}
      PackageManager := SharedActivity.getPackageManager;
      PackageInfo := PackageManager.getPackageInfo(SharedActivityContext.getPackageName(), TJPackageManager.JavaClass.GET_ACTIVITIES);

      VersionString := JStringToString(PackageInfo.versionName);

      wMajor := Copy(VersionString,1,VersionString.IndexOf('.')).ToInteger;
      Delete(VersionString,1,wMajor.ToString.Length+1);
      wMinor := Copy(VersionString,1,VersionString.IndexOf('.')).ToInteger;
      Delete(VersionString,1,wMinor.ToString.Length+1);
      wRelease := VersionString.ToInteger; // This assumed there isn't a Build on Android.
      wBuild := 0;
    {$ELSEIF Defined(MACOS)}
      // Hasn't been implemented yet
      // http://codeverge.com/embarcadero.delphi.firemonkey/application-version-information/1049381 Will be useful for MacOS
    {$ELSEIF Defined(MSWINDOWS)}
      Size:= GetFileVersionInfoSize(PChar(ExtractFilePath(ParamStr(0)) + ExtractFileName(ParamStr(0))), Size2);
      if Size > 0 then
      begin
        GetMem(Pt, Size);
        GetFileVersionInfo(PChar(ExtractFilePath(ParamStr(0)) + ExtractFileName(ParamStr(0))), 0, Size, Pt);
        VerQueryValue(Pt, '\', Pt2, Size2);
        with TVSFixedFileInfo(Pt2^) do
        begin
          wMajor := HiWord(dwFileVersionMS);
          wMinor := LoWord(dwFileVersionMS);
          wRelease := HiWord(dwFileVersionLS);
          wBuild := LoWord(dwFileVersionLS);
        end;
        FreeMem(Pt, Size);
      end;
    {$ELSEIF Defined(LINUX)}
      // Hasn't been implemented yet
    {$ENDIF}
  finally
    VersionSuccess := TRUE;
  end;
  if not VersionSuccess then
  begin
    wMajor := 0;
    wMinor := 0;
    wRelease := 0;
    wBuild := 0;
  end;

  result := wMajor.ToString + '.' + wMinor.ToString + '.' + wRelease.ToString + '.' + wBuild.ToString;
end;


{$IFDEF WEBLIB}
class function TSystemInformation.GetBrowser: String;
var
  UserAgent: String;
begin
  UserAgent := window.navigator.userAgent;
  Result := 'Unknown';
  if (UserAgent.indexOf('Opera') <> -1) or (UserAgent.indexOf('OPR') <> -1) then Result := 'Opera';
  if (UserAgent.indexOf('Edg') <> -1) then Result := 'Edge';
  if (UserAgent.indexOf('Chrome') <> -1) then Result := 'Chrome';
  if (UserAgent.indexOf('Windows NT 6.0') <> -1) then Result := 'Windows Vista';
  if (UserAgent.indexOf('Windows NT 5.1') <> -1) then Result := 'Windows XP';
  if (UserAgent.indexOf('Windows NT 5.0') <> -1) then Result := 'Windows 2000';
  if (UserAgent.indexOf('Mac') <> -1) then Result := 'Mac/iOS';
  if (UserAgent.indexOf('X11') <> -1) then Result := 'UNIX';
  if (UserAgent.indexOf('Linux') <> -1) then Result := 'Linux';
end;
{$ENDIF}

class function TSystemInformation.GetIPAddress: String;
  {$IF Defined(MSWINDOWS)}
    type
      pu_long = ^u_long;
    var
      varTWSAData : TWSAData;
      varPHostEnt : PHostEnt;
      varTInAddr : TInAddr;
      namebuf : Array[0..255] of ansichar;
  {$ENDIF}
  {$IF Defined(ANDROID)}
    function GetWiFiManager: JWifiManager;
      var ConnectivityServiceNative: JObject;
    begin
      ConnectivityServiceNative := SharedActivityContext.getSystemService(TJContext.JavaClass.WIFI_SERVICE);
      if not Assigned(ConnectivityServiceNative) then
        raise Exception.Create('Could not locate Connectivity Service');
      Result := TJWifiManager.Wrap(
        (ConnectivityServiceNative as ILocalObject).GetObjectID);
      if not Assigned(Result) then
        raise Exception.Create('Could not access Connectivity Manager');
    end;
  {$ENDIF}
begin
  try
    {$IF Defined(IOS)}
      // Hasn't been implemented yet
    {$ELSEIF Defined(ANDROID)}
      result := GetWiFiManager.getConnectionInfo.getIpAddress.ToString;
    {$ELSEIF Defined(MACOS)}
      // Hasn't been implemented yet
    {$ELSEIF Defined(MSWINDOWS)}
      If WSAStartup($101,varTWSAData) <> 0 Then
      Result := ''
      Else Begin
        gethostname(namebuf,sizeof(namebuf));
        varPHostEnt := gethostbyname(namebuf);
        varTInAddr.S_addr := u_long(pu_long(varPHostEnt^.h_addr_list^)^);
        Result := inet_ntoa(varTInAddr);
      End;
      WSACleanup;
    {$ELSEIF Defined(LINUX)}
      // Hasn't been implemented yet
    {$ENDIF}
  except on E: Exception do
    result := '';
  end;
end;

class function TSystemInformation.GetMacAddress: String;
{$IFDEF MSWINDOWS}
var
  Lib: Cardinal;
  Func: function(GUID: PGUID): Longint; stdcall;
  GUID1, GUID2: TGUID;
  {$ENDIF}
begin
  Result := EmptyStr;
{$IFDEF MSWINDOWS}
  Lib := LoadLibrary('rpcrt4.dll');
  if Lib <> 0 then
  begin
    try
      @Func := GetProcAddress(Lib, 'UuidCreateSequential');
      if Assigned(Func) then
      begin
        if (Func(@GUID1) = 0) and
           (Func(@GUID2) = 0) and
           (GUID1.D4[2] = GUID2.D4[2]) and
           (GUID1.D4[3] = GUID2.D4[3]) and
           (GUID1.D4[4] = GUID2.D4[4]) and
           (GUID1.D4[5] = GUID2.D4[5]) and
           (GUID1.D4[6] = GUID2.D4[6]) and
           (GUID1.D4[7] = GUID2.D4[7]) then
        begin
          Result :=
            IntToHex(GUID1.D4[2], 2) + '-' +
            IntToHex(GUID1.D4[3], 2) + '-' +
            IntToHex(GUID1.D4[4], 2) + '-' +
            IntToHex(GUID1.D4[5], 2) + '-' +
            IntToHex(GUID1.D4[6], 2) + '-' +
            IntToHex(GUID1.D4[7], 2);
        end;
      end;
    finally
      FreeLibrary(Lib)
    end;
  end;
{$ENDIF}
end;

class function TSystemInformation.GetOperatingSystem: String;
{$IFDEF WEBLIB}
  var UserAgent: String;
{$ENDIF}
begin
  {$IFDEF WEBLIB}
    UserAgent := window.navigator.userAgent;
    Result := 'Unknown';
    if (UserAgent.indexOf('Windows NT 10.0') <> -1) then Result := 'Windows 10'
    else if (UserAgent.indexOf('Windows NT 6.2') <> -1) then Result := 'Windows 8'
    else if (UserAgent.indexOf('Windows NT 6.1') <> -1) then Result := 'Windows 7'
    else if (UserAgent.indexOf('Windows NT 6.0') <> -1) then Result := 'Windows Vista'
    else if (UserAgent.indexOf('Windows NT 5.1') <> -1) then Result := 'Windows XP'
    else if (UserAgent.indexOf('Windows NT 5.0') <> -1) then Result := 'Windows 2000'
    else if (UserAgent.indexOf('Windows Phone') <> -1) then Result := 'Windows 10 Mobile'
    else if (UserAgent.indexOf('iPhone') <> -1) then Result := 'iOS'
    else if (UserAgent.indexOf('Mac') <> -1) then Result := 'MacOS'
    else if (UserAgent.indexOf('AppleTV') <> -1) then Result := 'tvOS'
    else if (UserAgent.indexOf('Android') <> -1) then Result := 'Android'
    else if (UserAgent.indexOf('Linux') <> -1) then Result := 'Linux'
    else if (UserAgent.indexOf('X11') <> -1) then Result := 'UNIX';
  {$ELSE}
    Result := TOSVersion.Name;
  {$ENDIF}
end;

class function TSystemInformation.GetScreenResolution: String;
begin
  {$IFDEF WEBLIB}
    if ((UInt64(window['innerWidth']) > UInt64(window.screen['width'])) and
       (UInt64(window['innerHeight']) > UInt64(window.screen['height']))) then
        Result := String(window['innerWidth']) + 'x' + String(window['innerHeight']) // Browser Window Resolution
    else
        Result := String(window.screen['width']) + 'x' + String(window.screen['height']); // Screen Resolution
  {$ELSE}
    Result := Screen.Width.ToString + 'x' + Screen.Height.ToString;
  {$ENDIF}
end;

class function TSystemInformation.GetSystemArchitecture: String; // Consider using TOSVersion.Architecture
begin
  Result := 'Unknown Architecture';
  {$IFDEF MSWINDOWS} Result := 'X64'; {$ENDIF}
  {$IFDEF IOS} Result := 'X64'; {$ENDIF}
  {$IFDEF MACOS} Result := 'X64'; {$ENDIF}
  {$IFDEF LINUX} Result := 'X64'; {$ENDIF}
  {$IFDEF ANDROID} Result := 'X64'; {$ENDIF}
  {$IFDEF WEBLIB} Result := 'Web'; {$ENDIF}
end;

class function TSystemInformation.GetSystemLanguage: String;
  {$IFDEF MACOS}
    var
      Languages: NSArray;
  {$ENDIF}
  {$IFDEF ANDROID}
    var
      LocServ: IFMXLocaleService;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    var
      buffer: MarshaledString;
      UserLCID: LCID;
      BufLen: Integer;
  {$ENDIF}
begin
  {$IFDEF MACOS}
    Languages := TNSLocale.OCClass.preferredLanguages;
    Result := TNSString.Wrap(Languages.objectAtIndex(0)).UTF8String;
  {$ENDIF}

  {$IFDEF ANDROID}
    if TPlatformServices.Current.SupportsPlatformService(IFMXLocaleService, IInterface(LocServ)) then
      Result := LocServ.GetCurrentLangID;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    UserLCID := GetUserDefaultLCID;
    BufLen := GetLocaleInfo(UserLCID, LOCALE_SISO639LANGNAME, nil, 0);
    buffer := StrAlloc(BufLen);
    if GetLocaleInfo(UserLCID, LOCALE_SISO639LANGNAME, buffer, BufLen) <> 0 then
      Result := buffer
    else
      Result := 'en';
    StrDispose(buffer);
  {$ENDIF}
  {$IFDEF WEBLIB}
    Result := window.navigator.language;
  {$ENDIF}
end;

class function TSystemInformation.GetSystemLocation: TSystemLocation;
  {$IFDEF MSWINDOWS}
    var
      MyLocationSensorArray : TSensorArray;
      MyLocationSensor : TCustomLocationSensor;
  {$ENDIF}
  {$IFDEF ANDROID}
    var
      MyLocationSensorArray : TSensorArray;
      MyLocationSensor : TCustomLocationSensor;
  {$ENDIF}
  {$IFDEF MACOS}
    var
      MyLocationSensorArray : TSensorArray;
      MyLocationSensor : TCustomLocationSensor;
  {$ENDIF}
begin
  {$IFDEF MSWINDOWS}
    try
      TSensorManager.Current.Activate;
      MyLocationSensorArray := TSensorManager.Current.GetSensorsByCategory(TSensorCategory.Location);
      if MyLocationSensorArray <> nil then
      begin
        // Location Sensor Found
        MyLocationSensor := MyLocationSensorArray[0] as TCustomLocationSensor;
        MyLocationSensor.Start;

        result.Latitude := MyLocationSensor.Latitude;
        result.Longitude := MyLocationSensor.Longitude;

        MyLocationSensor.Stop;
      end else
      begin
        // Location Sensor Not Found
        result.Latitude := 0;
        result.Longitude := 0;
      end;
    finally
      TSensorManager.Current.DeActivate
    end;
  {$ENDIF}
  {$IFDEF ANDROID}
    try
      TSensorManager.Current.Activate;
      MyLocationSensorArray := TSensorManager.Current.GetSensorsByCategory(TSensorCategory.Location);
      if MyLocationSensorArray <> nil then
      begin
        // Location Sensor Found
        MyLocationSensor := MyLocationSensorArray[0] as TCustomLocationSensor;
        MyLocationSensor.Start;

        result.Latitude := MyLocationSensor.Latitude;
        result.Longitude := MyLocationSensor.Longitude;

        MyLocationSensor.Stop;
      end else
      begin
        // Location Sensor Not Found
        result.Latitude := 0;
        result.Longitude := 0;
      end;
    finally
      TSensorManager.Current.DeActivate
    end;
  {$ENDIF}
  {$IFDEF MACOS}
    try
      TSensorManager.Current.Activate;
      MyLocationSensorArray := TSensorManager.Current.GetSensorsByCategory(TSensorCategory.Location);
      if MyLocationSensorArray <> nil then
      begin
        // Location Sensor Found
        MyLocationSensor := MyLocationSensorArray[0] as TCustomLocationSensor;
        MyLocationSensor.Start;

        result.Latitude := MyLocationSensor.Latitude;
        result.Longitude := MyLocationSensor.Longitude;

        MyLocationSensor.Stop;
      end else
      begin
        // Location Sensor Not Found
        result.Latitude := 0;
        result.Longitude := 0;
      end;
    finally
      TSensorManager.Current.DeActivate
    end;
  {$ENDIF}
end;

class function TSystemInformation.GetSystemTotalMemory: String;
  {$IFDEF ANDROID}
    var
      MemoryInfo: JActivityManager_MemoryInfo;
  {$ENDIF}
  {$IFDEF MSWINDOWS}
    var
      MemoryInfo: TMemoryStatusEx;
  {$ENDIF}
begin
  Result := '';
  try
    {$IFDEF MSWINDOWS}
      MemoryInfo.dwLength := SizeOf(TMemoryStatusEx);
      GlobalMemoryStatusEx(MemoryInfo);
      Result := Format('%0.1f GB', [MemoryInfo.ullTotalPhys / (1024 * 1024 * 1024)]);
    {$ENDIF}
    {$IFDEF ANDROID}
      MemoryInfo:= TJActivityManager_MemoryInfo.JavaClass.init;
      TJActivityManager.Wrap((TAndroidHelper.Context.getSystemService(TJContext.JavaClass.ACTIVITY_SERVICE) as ILocalObject)
        .GetObjectID).getMemoryInfo(MemoryInfo);
      var TotalMb := MemoryInfo.totalMem shr 20; // Total Memory
      var AvailMb := MemoryInfo.availMem shr 20; // Available Memory
      Result := Format('%0.1f GB', [TotalMb]);
    {$ENDIF}
    {$IFDEF WEBLIB}
      // This doesn't work for devices that have more than 8GB of memory. It will return 8GB max.
      asm
        Result = window.navigator.deviceMemory;
      end;
    {$ENDIF}
  except on E: Exception do

  end;
end;

class function TSystemInformation.GetComputerName: String;
begin
  Result := '';
  {$IFDEF MSWINDOWS}
    Result := GetEnvironmentVariable('COMPUTERNAME');
  {$ENDIF}
  {$IFDEF LINUX}
    Result := GetEnvironmentVariable('HOSTNAME');
  {$ENDIF}
  // Other platforms not implemented
end;

class function TSystemInformation.GetAppCompiledDate: String;
begin
  Result := DateToStr(Date);
  {$IFNDEF WEBLIB}
    Result := DateToStr(TFile.GetLastWriteTime(ParamStr(0)));
  {$ENDIF}
end;

class function TSystemInformation.GetApplicationType: String;
begin
  // Preserve previous constant behavior
  Result := 'Application';
end;

end.
