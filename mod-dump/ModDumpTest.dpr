program ModDumpTest;

{$APPTYPE CONSOLE}

uses
  SysUtils;

procedure StartModDump; StdCall; external 'ModDumpLib.dll';
procedure GetBuffer(str: PAnsiChar; len: Integer); StdCall; external 'ModDumpLib.dll';
procedure EndModDump; StdCall; external 'ModDumpLib.dll';
procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';
function Prepare(TargetFile: PAnsiChar): WordBool; stdcall; external 'ModDumpLib.dll';
function Dump(str: PAnsiChar; len: Integer): WordBool; stdcall; external 'ModDumpLib.dll';

var
  msg: PAnsiChar;
  json: PAnsiChar;

begin
  StartModDump;
  SetGameMode(1);
  Prepare('iHUD.esp');
  Dump(json, 4 * 1024 * 1024);
  GetBuffer(msg, 4096);
  WriteLn(msg);
  WriteLn('Output JSON:');
  WriteLn(json);
  EndModDump;
  Readln;
end.
