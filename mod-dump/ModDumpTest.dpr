program ModDumpTest;

{$APPTYPE CONSOLE}

uses
  SysUtils;

procedure StartModDump; StdCall; external 'ModDumpLib.dll';
function GetBuffer: PAnsiChar; StdCall; external 'ModDumpLib.dll';
procedure EndModDump; StdCall; external 'ModDumpLib.dll';
procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';
function Prepare(TargetFile: PAnsiChar): WordBool; stdcall; external 'ModDumpLib.dll';
function Dump: WordBool; stdcall; external 'ModDumpLib.dll';

begin
  WriteLn('Test');
  StartModDump;
  SetGameMode(1);
  Prepare('Skyrim\iHUD.esp');
  Dump;
  WriteLn(GetBuffer);
  EndModDump;
  WriteLn('Done');
  Readln;
end.
