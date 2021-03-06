program ModDump;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Classes,
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
  TargetFile, TargetGame, again: string;
  bIsPlugin, bIsText, bDumpGroups, bDumpMasters, bManualMode: boolean;

{ HELPER METHODS }

procedure Welcome;
begin
  // print program version
  Writeln('ModDump v', ProgramStatus.ProgramVersion);

  // get program path
  PathList.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
end;

procedure ListAvailablePlugins;
var
  rec: TSearchRec;
begin
  AddMessage('Available plugins: ');
  if FindFirst(settings.gameDataPath + '*.*', faAnyFile, rec) = 0 then try
    repeat
      if StrEndsWith(rec.Name, '.esp') or StrEndsWith(rec.Name, '.esm') then
        AddMessage(Format('  %s', [rec.Name]));
    until FindNext(rec) <> 0;
  finally
    FindClose(rec);
  end;
end;

procedure LoadParams;
begin
  // get target game param
  TargetGame := ParamStr(2);
  if not SetGameParam(TargetGame) then
    raise Exception.Create(Format('Invalid GameMode "%s"', [TargetGame]));
  AddMessage('Game: ' + ProgramStatus.GameMode.longName);
  AddMessage('DataPath: ' + settings.gameDataPath);
  AddMessage(' ');

  // dump record groups
  if ParamStr(1) = '-dumpGroups' then begin
    bDumpGroups := true;
    exit;
  end;

  // get target file param
  TargetFile := ParamStr(1);
  AddMessage('Target File: ' + TargetFile);
  if not FindPlugin(TargetFile) then
    raise Exception.Create('Target file not found');

  // dump masters
  if ParamStr(3) = '-dumpMasters' then begin
    bDumpMasters := true;
    exit;
  end;
end;

function FindFile(var filePath: String): boolean;
begin
  if FileExists(filePath) then begin
    Result := true;
  end
  else if FileExists(settings.GameDataPath + filePath) then begin
    Result := true;
    filePath := settings.gameDataPath + filePath;
  end
  else begin
    Result := FileExists(PathList.Values['ProgramPath'] + filePath);
    if Result then
      filePath := PathList.Values['ProgramPath'] + filePath;
  end;

  if Result then
    AddMessage(Format('Found file at "%s"', [filepath]));
end;

procedure ReadInput;
var
  bGameAssigned, bSuccess: boolean;
begin
  bDumpMasters := False;
  bGameAssigned := ProgramStatus.bGameAssigned;
  while not bGameAssigned do begin
    // get game abbr
    AddMessage(' ');
    AddMessage('Enter the game mode you want to use.');
    AddMessage('Options: sse, sk, ob, fo4, fnv, fo3 (SkyrimSE, Skyrim, Oblivion, Fallout 4, Fallout New Vegas, and Fallout 3)');
    AddMessage(' ');
    ReadLn(TargetGame);

    // set game mode
    bGameAssigned := SetGameAbbr(TargetGame);
    if not bGameAssigned then
      AddMessage(Format('Invalid GameMode "%s"', [TargetGame]));
  end;

  // set game param
  AddMessage(' ');
  AddMessage('Game: ' + ProgramStatus.GameMode.longName);
  AddMessage('DataPath: ' + settings.gameDataPath);
  bSuccess := false;

  repeat
    // get target file
    AddMessage(' ');
    AddMessage('Enter the plugin filename to dump.  Enter "list" to see a list of available plugins.');
    AddMessage(' ');
    ReadLn(TargetFile);

    // list if user asked for it
    if TargetFile = 'list' then begin
      ListAvailablePlugins;
      continue;
    end;

    // list if user asked for it
    if TargetFile = 'masters' then begin
      bDumpMasters := not bDumpMasters;
      continue;
    end;

    // check if the plugin exists
    if not FindFile(TargetFile) then
      AddMessage(Format('Plugin not found: "%s"', [settings.GameDataPath + TargetFile]))
    else begin
      bSuccess := IsPlugin(TargetFile) or StrEndsWith(TargetFile, '.txt');
      if not bSuccess then
        AddMessage('Target file does not match *.esp, *.esm, or *.txt');
    end;
  until bSuccess;
end;

procedure DetermineMode;
begin
  // raise exception if target file is not a plugin file or a text file
  AddMessage(' ');
  bIsPlugin := IsPlugin(TargetFile);
  bIsText := StrEndsWith(TargetFile, '.txt');
  if bIsPlugin then
    AddMessage('Dumping plugin: ' + ExtractFileName(TargetFile))
  else if bIsText then
    AddMessage('Dumping plugins in list: ' + ExtractFileName(TargetFile))
  else
    raise Exception.Create('Target file does not match *.esp, *.esm, or *.txt');
end;

procedure DumpMasters;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Delimiter := ';';
  sl.StrictDelimiter := true;
  try
    GetPluginMasters(TargetFile, sl);
    if sl.Count = 0 then
      AddMessage('NO MASTERS')
    else
      AddMessage(Trim(sl.DelimitedText));
  finally
    sl.Free;
  end;
end;

{ MAIN PROGRAM EXECUTION }

procedure PerformDump;
begin
  // do the dump
  if bDumpMasters then
    DumpMasters
  else if bDumpGroups then
    DumpGroups
  else if bIsPlugin then
    DumpPlugin(TargetFile)
  else if bIsText then
    DumpPluginsList(TargetFile);
end;

procedure ManualDump;
begin
  repeat
    ReadInput;
    DetermineMode;
    PerformDump;
    AddMessage('Dump another plugin? y/n ');
    ReadLn(again);
  until (not SameText(again, 'y'));
end;

procedure AutoDump;
begin
  LoadParams;
  DetermineMode;
  PerformDump;
end;

begin
  try
    Welcome;
    bManualMode := ParamCount <= 1;
    if bManualMode then
      ManualDump
    else
      AutoDump;
  except
    on E: Exception do
      AddMessage(E.ClassName + ': ' + E.Message);
  end;
end.
