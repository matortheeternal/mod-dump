unit mdMessages;

interface

uses
  Classes;

  procedure AddMessage(msg: String);

var
  MessageBuffer: TStringList;

implementation

procedure AddMessage(msg: String);
begin
  {$IFDEF CONSOLE}
  WriteLn(msg);
  {$ELSE}
  MessageBuffer.Add(msg);
  {$ENDIF}
end;

end.
