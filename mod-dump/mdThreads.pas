unit mdThreads;

interface

uses
  SysUtils, Classes,
  SuperObject;

type
  TDumpThread = class(TThread)
  protected
    procedure Execute; override;
  end;

implementation

uses
  mdShared, mdDump, mdMessages;

procedure TDumpThread.Execute;
begin
  try
    if bIsPlugin then
      DumpResult := DumpPlugin(TargetFile)
    else if bIsText then
      DumpResult := DumpPluginsList(TargetFile);
  except
    on E: Exception do begin
      DumpResult := SO;
      AddMessage(E.Message);
      SaveBuffer;
    end;
  end;
end;

end.
