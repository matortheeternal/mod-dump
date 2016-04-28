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
  ShareMem,
  SysUtils,
  Classes,
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

function GetMessageBuffer: string; stdcall;
begin
  Result := MessageBuffer.Text;
  MessageBuffer.Clear;
end;

procedure SetGameMode(mode: Integer); stdcall;
begin
  SetGame(mode);
  Writeln('Game: ', ProgramStatus.GameMode.longName);
  Writeln(' ');
  LoadSettings;
  SaveSettings;
end;

function Prepare(TargetFile: string): Boolean; stdcall;
begin
  // get target file param
  if not FileExists(TargetFile) then
    raise Exception.Create('Target file not found');

  // raise exception if target file is not a plugin file or a text file
  bIsPlugin := IsPlugin(TargetFile);
  bIsText := StrEndsWith(TargetFile, '.txt');
  if bIsPlugin then
    AddMessage('Dumping plugin: ' + ExtractFileName(TargetFile))
  else if bIsText then
    Writeln('Dumping plugins in list: ' + ExtractFileName(TargetFile))
  else
    AddMessage('Target file does not match *.esp, *.esm, or *.txt');

  // set result
  Result := bIsPlugin or bIsText;
end;

function Dump: Boolean; stdcall;
begin
  if not bIsPlugin or bIsText then begin
    AddMessage('ERROR: No plugin or list loaded.');
    Result := false;
    exit;
  end;

  try
    if bIsPlugin then
      DumpPlugin(TargetFile)
    else if bIsText then
      DumpPluginsList(TargetFile);
    Result := true;
  except
    on E: Exception do begin
      Result := false;
      AddMessage(E.ClassName + ': ' + E.Message);
    end;
  end;
end;

procedure Close; stdcall;
begin
  MessageBuffer.Free;
end;

exports
  GetMessageBuffer, SetGameMode, Prepare, Dump, Close;

begin
  MessageBuffer := TStringList.Create;
  AddMessage('ModDump v' + ProgramStatus.ProgramVersion);
end.


