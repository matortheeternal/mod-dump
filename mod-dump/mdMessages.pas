unit mdMessages;

interface

uses
  Classes;

  procedure AddMessage(const msg: String);
  procedure SaveBuffer;
  procedure ErrorMessage(const msg: String);

var
  MessageBuffer: TStringList;

implementation

procedure AddMessage(const msg: String);
begin
  if Length(msg) = 0 then exit;
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

procedure ErrorMessage(const msg: String);
begin
  if Length(msg) = 0 then exit;
  {$IFDEF CONSOLE}
  WriteLn(ErrOutput, msg);
  {$ELSE}
  MessageBuffer.Add(msg);
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
