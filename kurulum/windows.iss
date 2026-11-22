; Bogahost Destek Windows kurulumu (Inno Setup 6). CI tanımları: Uygulama (destek), Dosya, Surum, Kaynak, Cikti, Simge.
#define Ad "Bogahost Destek"
#define Exe "destek.exe"
#define Kimlik "{{B0A7D3C2-5E41-4F7A-9C88-2D6E1F0A4B57}"

[Setup]
AppId={#Kimlik}
AppName={#Ad}
AppVersion={#Surum}
AppVerName={#Ad} {#Surum}
AppPublisher=Bogahost
AppPublisherURL=https://chat.bogahost.com
DefaultDirName={autopf}\Bogahost\{#Ad}
DefaultGroupName={#Ad}
DisableProgramGroupPage=yes
OutputDir={#Cikti}
OutputBaseFilename={#Dosya}
SetupIconFile={#Simge}
UninstallDisplayIcon={app}\{#Exe}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequiredOverridesAllowed=dialog
CloseApplications=yes

[Languages]
Name: "turkish"; MessagesFile: "compiler:Languages\Turkish.isl"

[Tasks]
Name: "masaustu"; Description: "Masaüstüne kısayol oluştur"; GroupDescription: "Kısayollar:"

[Files]
Source: "{#Kaynak}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#Ad}"; Filename: "{app}\{#Exe}"
Name: "{autodesktop}\{#Ad}"; Filename: "{app}\{#Exe}"; Tasks: masaustu

[Run]
Filename: "{app}\{#Exe}"; Description: "{#Ad} uygulamasını başlat"; Flags: nowait postinstall skipifsilent
