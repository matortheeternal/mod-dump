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
  // xedit units
  wbInterface,
  // mod dump units
  mdShared, mdConfiguration, mdDump, mdMessages;

procedure TDumpThread.Execute;
begin
  try
    if settings.bVerboseLog then
      wbProgressCallback := AddMessage;
    if bIsPlugin then
      DumpResult := DumpPlugin(TargetFile)
    else if bIsText then
      DumpResult := DumpPluginsList(TargetFile);
  except
    on x: Exception do begin
      DumpResult := SO;
      AddMessage('Exception Dumping ' + TargetFile);
      AddMessage(x.Message);
      SaveBuffer;
    end;
  end;
end;

end.
