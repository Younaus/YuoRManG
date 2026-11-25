; YouRManG — Windows kurulum betiği (Inno Setup 6)
;
; Önce release derlemesi:   cd frontend && flutter build windows --release
; Sonra derle:              ISCC.exe windows\installer\yourmang.iss
;                           (sürüm: ISCC.exe /DAppVersion=1.2.0 windows\installer\yourmang.iss)
; Çıktı:                    frontend\build\windows\installer\YouRManG-Setup.exe
;
; Yönetici izni istemez; kullanıcının %LOCALAPPDATA%\YouRManG klasörüne kurar.

#define AppName "YouRManG"
#define AppExeName "yourmang.exe"
#define AppPublisher "YouRManG"
#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

; Yollar bu betiğin konumuna göre (frontend\windows\installer).
#define FrontendDir AddBackslash(SourcePath) + "..\.."
#define ReleaseDir FrontendDir + "\build\windows\x64\runner\Release"

; Visual C++ çalışma zamanı (Flutter Windows dağıtım rehberi): uygulama, VC++ Redistributable
; kurulu olmayan makinelerde de açılsın diye 64-bit DLL'ler exe'nin yanına konur.
; ISCC 32-bit çalıştığı için 64-bit System32'ye "Sysnative" üzerinden erişilir.
#define WinDir GetEnv("windir")
#if DirExists(WinDir + "\Sysnative")
  #define VcRuntimeDir WinDir + "\Sysnative"
#else
  #define VcRuntimeDir WinDir + "\System32"
#endif

#if !FileExists(ReleaseDir + "\" + AppExeName)
  #error "Release derlemesi bulunamadı. Önce: flutter build windows --release"
#endif

[Setup]
; AppId kurulumlar arası güncelleme/kaldırma için sabit kalmalı.
AppId={{C5D5B4AA-AA5D-4F60-86DB-D94A1E6E5D5F}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
VersionInfoVersion={#AppVersion}
DefaultDirName={localappdata}\{#AppName}
DefaultGroupName={#AppName}
DisableProgramGroupPage=yes
DisableDirPage=auto
PrivilegesRequired=lowest
UsedUserAreasWarning=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#FrontendDir}\build\windows\installer
OutputBaseFilename={#AppName}-Setup
SetupIconFile={#FrontendDir}\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
UninstallDisplayName={#AppName}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
; Kurulum/kaldırma sırasında açık uygulamayı (ör. köşe kapsülü) kapatmayı önerir.
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Release klasörünün tamamı: exe, flutter_windows.dll, eklenti DLL'leri ve data\ (flutter_assets, icudtl.dat, app.so).
; *.lib / *.exp yalnızca bağlama (link) çıktısıdır, çalışma zamanında gerekmez (~21 MB).
Source: "{#ReleaseDir}\*"; DestDir: "{app}"; Excludes: "*.lib,*.exp"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#VcRuntimeDir}\msvcp140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcRuntimeDir}\vcruntime140.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#VcRuntimeDir}\vcruntime140_1.dll"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{group}\{cm:UninstallProgram,{#AppName}}"; Filename: "{uninstallexe}"
Name: "{userdesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent
