program ModDumpTest;

{$APPTYPE CONSOLE}

uses
  ShareMem,
  SysUtils;

procedure StartModDump; StdCall; external 'ModDumpLib.dll';
procedure GetBuffer(str: PAnsiChar; len: Integer); StdCall; external 'ModDumpLib.dll';
procedure FlushBuffer; StdCall; external 'ModDumpLib.dll';
procedure EndModDump; StdCall; external 'ModDumpLib.dll';
procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';
function Prepare(TargetFile: PAnsiChar): WordBool; stdcall; external 'ModDumpLib.dll';
function Dump: WordBool; stdcall; external 'ModDumpLib.dll';
function GetDumpResult(str: PAnsiChar; len: Integer): WordBool; stdcall; external 'ModDumpLib.dll';

procedure WriteBuffer;
var
  str: PAnsiChar;
begin
  GetMem(str, 4096);
  GetBuffer(str, 4096);
  if Length(string(str)) > 0 then begin
    WriteLn(str);
    FlushBuffer();
  end;
end;

procedure DumpPlugin(filename: PAnsiChar);
var
  json: PAnsiChar;
  len: Integer;
begin
  Prepare(filename);
  Dump();
  len := 4 * 1024 * 1024;
  GetMem(json, len);
  while not GetDumpResult(json, len) do begin
    WriteBuffer;
    Sleep(100);
  end;
  WriteLn('Output JSON:');
  WriteLn(json);
end;

begin
  StartModDump;
  SetGameMode(3);
  WriteBuffer;
  DumpPlugin('Purewaters.esp');
  DumpPlugin('SV.esp');
  EndModDump;
  Readln;
end.
