program ModDumpTest;

{$APPTYPE CONSOLE}

uses
  SysUtils;

procedure Initialize; StdCall; external 'ModDumpLib.dll';
function GetBuffer: Pchar; StdCall; external 'ModDumpLib.dll';
procedure Finalize; StdCall; external 'ModDumpLib.dll';
procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';

begin
  WriteLn('Test');
  Initialize;
  SetGameMode(1);
  WriteLn(GetBuffer);
  Finalize;
  WriteLn('Done');
  Readln;
end.
