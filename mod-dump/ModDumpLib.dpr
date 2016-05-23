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
  SysUtils,
  Classes,
  superobject,
  mteHelpers,
  mdConfiguration in 'mdConfiguration.pas',
  mdCore in 'mdCore.pas',
  mdDump in 'mdDump.pas',
  mdMessages in 'mdMessages.pas';

{$R *.res}
{$MAXSTACKSIZE 2097152}

const
  IMAGE_FILE_LARGE_ADDRESS_AWARE = $0020;

var
  TargetFile: string;
  bIsPlugin, bIsText: boolean;

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
    AddMessage('Target file does not match *.esp, *.esm, or *.txt');

  // set result
  Result := bIsPlugin or bIsText;
end;

function Dump(str: PAnsiChar; len: Integer): WordBool; stdcall;
var
  obj: ISuperObject;
begin
  Result := false;
  if not bIsPlugin or bIsText then begin
    AddMessage('ERROR: No plugin or list loaded.');
    exit;
  end;

  try
    // dump the plugin/pluginslist
    if bIsPlugin then
      obj := DumpPlugin(TargetFile)
    else if bIsText then
      obj := DumpPluginsList(TargetFile);

    // return the json of the dump/s
    StrLCopy(str, PAnsiChar(AnsiString(obj.AsJSON)), len);
    Result := true;
  except
    on E: Exception do begin
      AddMessage(E.ClassName + ': ' + E.Message);
      SaveBuffer;
    end;
  end;
end;

procedure StartModDump; stdcall;
begin
  MessageBuffer := TStringList.Create;
  AddMessage('ModDump v' + ProgramStatus.ProgramVersion);

  // get program path
  PathList.Values['ProgramPath'] := ExtractFilePath(ParamStr(0));
end;

procedure EndModDump; stdcall;
begin
  MessageBuffer.Free;
end;

exports
  StartModDump,
  EndModDump,
  GetBuffer,
  FlushBuffer,
  SetGameMode,
  Prepare,
  Dump;

begin
  IsMultiThread := True;
end.


