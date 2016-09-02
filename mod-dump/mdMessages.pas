unit mdMessages;

interface

uses
  Classes;

  procedure AddMessage(const msg: String);
  procedure SaveBuffer;

var
  MessageBuffer: TStringList;

implementation

procedure AddMessage(const msg: String);
begin
  if msg = '' then
    exit;

  {$IFDEF CONSOLE}
  WriteLn(msg);
  {$ELSE}
  MessageBuffer.Add(msg);
  {$ENDIF}
end;

procedure SaveBuffer;
begin
  {$IFNDEF CONSOLE}
  MessageBuffer.SaveToFile('mod_dump_log.txt');
  {$ENDIF}
end;

initialization
begin
  MessageBuffer := TStringList.Create;
end;

finalization
begin
  MessageBuffer.Free;
end;

end.
