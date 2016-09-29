library ModDumpLib;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  //fastmm4,
  ShareMem,
  SysUtils,
  Classes,
  superobject,
  mteHelpers,
  mdConfiguration in 'mdConfiguration.pas',
  mdCore in 'mdCore.pas',
  mdDump in 'mdDump.pas',
  mdMessages in 'mdMessages.pas',
  mdThreads in 'mdThreads.pas',
  mdShared in 'mdShared.pas';

{$R *.res}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

procedure GetBuffer(str: PAnsiChar; len: Integer); StdCall;
begin
  StrLCopy(str, PAnsiChar(AnsiString(MessageBuffer.Text)), len);
end;

procedure FlushBuffer; StdCall;
begin
  MessageBuffer.Clear;
end;

procedure SetGameMode(mode: Integer); stdcall;
begin
  SetGame(mode);
  AddMessage('Game: ' + ProgramStatus.GameMode.longName);
  AddMessage('DataPath: ' + settings.gameDataPath);
  AddMessage(' ');
end;

function Prepare(FilePath: PAnsiChar): WordBool; stdcall;
begin
  TargetFile := String(AnsiString(FilePath));
  // get target file param
  if not FileExists(TargetFile) then begin
    TargetFile := settings.GameDataPath + TargetFile;
    if not FileExists(TargetFile) then begin
      AddMessage('Target file not found.');
      Result := false;
      exit;
    end;
  end;

  // raise exception if target file is not a plugin file or a text file
  bIsPlugin := IsPlugin(TargetFile);
  bIsText := StrEndsWith(TargetFile, '.txt');
  if bIsPlugin then
    AddMessage('Dumping plugin: ' + ExtractFileName(TargetFile))
  else if bIsText then
    AddMessage('Dumping plugins in list: ' + ExtractFileName(TargetFile))
  else
    AddMessage('Target file does not match *.esp, *.esm, or *.txt');

  // set result
  Result := bIsPlugin or bIsText;
end;

function GetDumpResult(str: PAnsiChar; len: Integer): WordBool; stdcall;
begin
  Result := false;
  if Assigned(DumpResult) and (DumpResult <> nil) then begin
    Result := true;
    StrLCopy(str, PAnsiChar(AnsiString(DumpResult.AsJSON)), len);
    DumpResult := nil;
  end;
end;

function Dump: WordBool; stdcall;
begin
  Result := false;

  // raise error if no plugin or list is loaded
  if not bIsPlugin or bIsText then begin
    AddMessage('ERROR: No plugin or list loaded.');
    exit;
  end;

  // start a thread for dumping
  DumpResult := nil;
  TDumpThread.Create;
  Result := true;
end;

procedure StartModDump; stdcall;
begin
  AddMessage('ModDump v' + ProgramStatus.ProgramVersion);

  // get program path
  PathList.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
end;

exports
  StartModDump,
  GetBuffer,
  FlushBuffer,
  SetGameMode,
  Prepare,
  Dump,
  GetDumpResult;

begin
  IsMultiThread := True;
end.


