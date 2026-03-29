[Setup]
AppName=Étude
AppVersion=1.1.0.2
AppPublisher=RoyaAfricca
DefaultDirName={localappdata}\Étude
DefaultGroupName=Étude
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\etude.exe
Compression=lzma2
SolidCompression=yes
OutputDir=E:\etude\website
OutputBaseFilename=application_etude
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=E:\etude\windows\runner\resources\app_icon.ico

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "E:\etude\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Étude"; Filename: "{app}\etude.exe"
Name: "{autodesktop}\Étude"; Filename: "{app}\etude.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\etude.exe"; Description: "{cm:LaunchProgram,Étude}"; Flags: nowait postinstall skipifsilent
