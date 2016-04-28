program ModDumpTest;

{$APPTYPE CONSOLE}

uses
  SysUtils;

procedure StartModDump; StdCall; external 'ModDumpLib.dll';
procedure GetBuffer(str: PAnsiChar; len: Integer); StdCall; external 'ModDumpLib.dll';
procedure EndModDump; StdCall; external 'ModDumpLib.dll';
procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';
function Prepare(TargetFile: PAnsiChar): WordBool; stdcall; external 'ModDumpLib.dll';
function Dump: WordBool; stdcall; external 'ModDumpLib.dll';

var
  msg: PAnsiChar;

begin
  WriteLn('Test');
  StartModDump;
  SetGameMode(1);
  Prepare('Skyrim\iHUD.esp');
  Dump;
  GetBuffer(msg, 4096);
  WriteLn(msg);
  EndModDump;
  WriteLn('Done');
  Readln;
end.
