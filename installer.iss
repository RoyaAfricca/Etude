[Setup]
AppId={{85FB3E06-99D1-486A-AE43-45B2D8462512}}
AppName=Etude
AppVersion=1.3.0
AppPublisher=RoyaAfricca
DefaultDirName={localappdata}\Etude
DefaultGroupName=Etude
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\etude_app.exe
Compression=lzma2
SolidCompression=yes
OutputDir=E:\etude\website\03042026
OutputBaseFilename=application_etude_v1.3.0
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
SetupIconFile=E:\etude\windows\runner\resources\app_icon.ico

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "E:\etude\Adel\EtudeWindows\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Etude"; Filename: "{app}\etude_app.exe"
Name: "{group}\Désinstaller Etude"; Filename: "{uninstallexe}"
Name: "{autodesktop}\Etude"; Filename: "{app}\etude_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\etude_app.exe"; Description: "{cm:LaunchProgram,Etude}"; Flags: nowait postinstall skipifsilent
