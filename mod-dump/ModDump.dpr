program ModDump;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  mteHelpers,
  mdConfiguration in 'mdConfiguration.pas',
  mdDump in 'mdDump.pas',
  mdCore in 'mdCore.pas',
  mdMessages in 'mdMessages.pas';

{$R *.res}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

{$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}

var
  TargetFile, TargetGame: string;
  bIsPlugin, bIsText, bDumpGroups: boolean;

{ HELPER METHODS }

procedure Welcome;
begin
  // print program version
  Writeln('ModDump v', ProgramStatus.ProgramVersion);

  // get program path
  PathList.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
end;

procedure LoadParams;
begin
  // get target game param
  TargetGame := ParamStr(2);
  if not SetGameParam(TargetGame) then
    raise Exception.Create(Format('Invalid GameMode "%s"', [TargetGame]));
  AddMessage('Game: ' + ProgramStatus.GameMode.longName);
  AddMessage(' ');

  // dump record groups
  if ParamStr(1) = '-dumpGroups' then begin
    bDumpGroups := true;
    exit;
  end;

  // get target file param
  TargetFile := ParamStr(1);
  if not FileExists(TargetFile) then
    raise Exception.Create('Target file not found');

  // raise exception if target file is not a plugin file or a text file
  bIsPlugin := IsPlugin(TargetFile);
  bIsText := StrEndsWith(TargetFile, '.txt');
  if bIsPlugin then
    AddMessage('Dumping plugin: ' + ExtractFileName(TargetFile))
  else if bIsText then
    AddMessage('Dumping plugins in list: ' + ExtractFileName(TargetFile))
  else
    raise Exception.Create('Target file does not match *.esp, *.esm, or *.txt');
end;

{ MAIN PROGRAM EXECUTION }

begin
  try
    Welcome;
    LoadParams;
    if bDumpGroups then
      DumpGroups
    else if bIsPlugin then
      DumpPlugin(TargetFile)
    else if bIsText then
      DumpPluginsList(TargetFile);
  except
    on E: Exception do
      AddMessage(E.ClassName + ': ' + E.Message);
  end;
end.
