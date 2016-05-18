unit mdDump;

interface

uses
  SysUtils, Classes, Windows,
  // third party libraries
  superobject,
  // xedit units
  wbInterface, wbImplementation,
  // mte units
  mteHelpers, mteBase,
  // md units
  mdConfiguration, mdCore, mdMessages;

  function IsPlugin(filename: string): boolean;
  procedure DumpGroups;
  function DumpPlugin(filePath: string): ISuperObject;
  function DumpPluginsList(filePath: string): ISuperObject;

implementation

function IsPlugin(filename: string): boolean;
begin
  Result := StrEndsWith(filename, '.esp') or StrEndsWith(filename, '.esm');
end;

procedure CreateDummyPlugin(path: string);
begin
  if not FileExists(settings.dummyPluginPath) then
    raise Exception.Create(Format('Empty plugin not found at "%s"',
      [settings.dummyPluginPath]));
  AddMessage('Creating empty plugin ' + path);
  CopyFile(PChar(settings.dummyPluginPath), PChar(path), true);
end;

procedure DumpGroups;
var
  i: Integer;
  sig: string;
  RDE: PwbRecordDefEntry;
  RecordDef: PwbRecordDef;
  slSeeds: TStringList;
  bChildGroup: Boolean;
begin
  slSeeds := TStringList.Create;
  try
    // get record def names, if available
    for i := 0 to High(wbRecordDefs) do begin
      RDE := @wbRecordDefs[i];
      RecordDef := @RDE.rdeDef;
      sig := String(RecordDef.Signatures[0]);
      bChildGroup := wbGroupOrder.IndexOf(sig) = -1;
      Writeln(Format('%s - %s', [sig, RecordDef.Name]));
      slSeeds.Add('RecordGroup.create(');
      slSeeds.Add('    game_id: game'+wbGameName+'.id,');
      slSeeds.Add('    signature: '''+sig+''',');
      slSeeds.Add('    name: '''+RecordDef.Name+''',');
      slSeeds.Add('    child_group: '+Lowercase(BoolToStr(bChildGroup, true)));
      slSeeds.Add(')');
    end;

    // save seeds
    slSeeds.SaveToFile(wbGameName+'\seeds.rb');
  finally
    slSeeds.Free;
  end;
end;

function FindPlugin(var filePath: string): boolean;
begin
  if FileExists(filePath) then
    Result := true
  else if FileExists(wbDataPath + filePath) then begin
    Result := true;
    filePath := wbDataPath + filePath;
  end
  else begin
    filePath := settings.pluginSearchPath + filePath;
    Result := FileExists(filePath);
  end;
end;

{
  1. Load plugin header
  2. See if masters are available
  3. If masters not available, create dummy files for them
  4. Masters that are available should cycle through 1-4
}
procedure BuildLoadOrder(filename: string; var sl: TStringList;
  bFirstFile: boolean = False);
var
  aFile: IwbFile;
  filePath, sMaster: string;
  slMasters: TStringList;
  i: Integer;
begin
  filePath := filename;
  // create empty plugin if plugin doesn't exist
  if not FindPlugin(filePath) then
    CreateDummyPlugin(filePath);

  // load the file and recurse through its masters
  aFile := wbFile(filePath, -1, '', True, False);
  slMasters := TStringList.Create;
  try
    GetMasters(aFile, slMasters);
    for i := 0 to Pred(slMasters.Count) do begin
      sMaster := slMasters[i];
      if sl.IndexOf(sMaster) = -1 then
        BuildLoadOrder(sMaster, sl);
    end;

    // add file to load order
    sl.Add(filename);
  finally
    slMasters.Free;
  end;
end;

procedure DeleteDummyPlugins;
var
  i: Integer;
  plugin: TPlugin;
  sFilePath: String;
begin
  AddMessage(' ');
  AddMessage('== DELETING DUMMIES ==');

  for i := 0 to Pred(PluginsList.Count) do begin
    plugin := TPlugin(PluginsList[i]);
    if (plugin.hash = dummyPluginHash) then begin
      sFilePath := settings.pluginSearchPath + plugin.filename;
      AddMessage('Deleting ' + sFilePath);
      DeleteFile(PChar(sFilePath));
    end;
  end;
end;

procedure PrintLoadOrder(var sl: TStringList);
var
  i: Integer;
begin
  // print load order
  AddMessage(' ');
  AddMessage('== LOAD ORDER ==');
  for i := 0 to Pred(sl.Count) do
    AddMessage(Format('[%s] %s', [IntToHex(i, 2), sl[i]]));
end;

procedure LoadPlugins(dumpFilePath: string; var sl: TStringList);
var
  i: Integer;
  bIsDumpFile: boolean;
  plugin: TPlugin;
  aFile: IwbFile;
  sFilePath, sFilename: string;
begin
  // print log messages
  AddMessage(' ');
  AddMessage('== LOADING PLUGINS ==');

  // print empty plugin hash
  if settings.bPrintHashes then
    AddMessage('Empty plugin hash: ' + dummyPluginHash);

  // load the plugins
  for i := 0 to Pred(sl.Count) do begin
    sFilePath := sl[i];
    FindPlugin(sFilePath);

    // print log message
    sFilename := ExtractFilename(sFilePath);
    AddMessage('Loading ' + sFilename + '...');
    AddMessage('['+sFilePath+']');

    // load plugin
    SetCurrentDir(wbDataPath);
    try
      plugin := TPlugin.Create;
      plugin.filepath := wbDataPath + sFileName;
      plugin.filename := sFilename;
      plugin._File := wbFile(sFilename, i, '', false, false);
      plugin._File._AddRef;
      bIsDumpFile := sFilePath = dumpFilePath;
      plugin.GetMdData(bIsDumpFile);
      PluginsList.Add(Pointer(plugin));

      // print the hash if the bPrintHashes setting is true
      if settings.bPrintHashes then
        AddMessage('  Hash = ' + plugin.hash);
      // update bUsedEmptyPlugins
      if plugin.hash = dummyPluginHash then
        ProgramStatus.bUsedDummyPlugins := true;
    except
      on x: Exception do begin
        AddMessage('Exception loading ' + sl[i]);
        AddMessage(x.Message);
        raise x;
      end;
    end;

    // load hardcoded dat
    if i = 0 then try
      aFile := wbFile(settings.pluginSearchPath + wbGameName + wbHardcodedDat, 0);
      aFile._AddRef;
    except
      on x: Exception do begin
        AddMessage('Exception loading ' + wbGameName + wbHardcodedDat);
        raise x;
      end;
    end;
  end;
end;

procedure WriteList(name: string; var sl: TStringList);
var
  i: Integer;
begin
  // write the name
  AddMessage(name + ':');

  // write the list indented by one space
  for i := 0 to Pred(sl.Count) do
    AddMessage(' ' + sl[i]);
end;


procedure WriteDump(plugin: TPlugin);
var
  i: Integer;
  group: TRecordGroup;
  error: TRecordError;
begin
  AddMessage(' ');
  AddMessage('== DUMP ==');

  // write main attributes
  AddMessage('Filename: ' + plugin.filename);
  AddMessage('Description'#13#10 + plugin.description.Text);
  AddMessage('Author: ' + plugin.author);
  AddMessage('Hash: ' + plugin.hash);
  AddMessage('File size: ' + FormatByteSize(plugin.fileSize));
  AddMessage('Masters'#13#10 + plugin.masters.Text);
  AddMessage('Number of records: ' + IntToStr(plugin.numRecords));
  AddMessage('Number of overrides: ' + IntToStr(plugin.numOverrides));

  // write record groups
  AddMessage('Record groups:');
  for i := 0 to Pred(plugin.groups.Count) do begin
    group := TRecordGroup(plugin.groups[i]);
    AddMessage(Format('sig: [%s]  Records:%5d, Overrides:%5d',
      [string(group.signature), group.numRecords, group.numOverrides]));
  end;
  if plugin.groups.Count = 0 then
    AddMessage(' No records');

  //Write overrides
  AddMessage('Overrides');
  for i := 0 to Pred(plugin.overrides.Count) do begin
    AddMessage(Format('Sig: [%s]  FormID: %s',
      [plugin.overrides[i], IntToHex(Integer(plugin.overrides.Objects[i]),8)]));
  end;

  // write errors
  AddMessage('Errors:');
  for i := 0 to Pred(plugin.errors.Count) do begin
    error := TRecordError(plugin.errors[i]);
    if error.path <> '' then
      AddMessage(Format(' [%s:%s] %s at %s', [string(error.signature),
        error.formID, error.&type.shortName, error.path]))
    else
      AddMessage(Format(' [%s:%s] %s', [string(error.signature),
        error.formID, error.&type.shortName]))
  end;
  if ProgramStatus.bUsedDummyPlugins then
    AddMessage(' Unknown')
  else if (plugin.errors.Count = 0) then
    AddMessage(' No errors');
end;

function JsonDump(plugin: TPlugin): ISuperObject;
var
  obj, childObj: ISuperObject;
  i, j: Integer;
  group: TRecordGroup;
  error: TRecordError;
  sl: TStringList;
begin
  obj := SO;
  obj.S['filename'] := plugin.filename;
  obj.S['description'] := plugin.description.Text;
  obj.S['author'] := plugin.author;
  obj.S['crc_hash'] := plugin.hash;
  obj.I['file_size'] := plugin.fileSize;
  obj.I['record_count'] := plugin.numRecords;
  obj.I['override_count'] := plugin.numOverrides;


  // dump masters
  obj.O['master_filenames'] := SA([]);
  for i := 0 to Pred(plugin.masters.Count) do
    obj.A['master_filenames'].S[i] := plugin.masters[i];

  // dump dummy masters
  obj.O['dummy_masters'] := SA([]);
  j := 0;
  for i := 0 to Pred(plugin.masters.Count) do begin
    if PluginByFilename(plugin.masters[i]).hash = dummyPluginHash then begin
      obj.A['dummy_masters'].S[j] := plugin.masters[i];
      Inc(j);
    end;
  end;

  // dump record groups
  obj.O['plugin_record_groups'] := SA([]);
  for i := 0 to Pred(plugin.groups.Count) do begin
    group := TRecordGroup(plugin.groups[i]);
    childObj := SO;
    childObj.S['sig'] := string(group.signature);
    childObj.I['record_count'] := group.numRecords;
    childObj.I['override_count'] := group.numOverrides;
    obj.A['plugin_record_groups'].O[i] := childObj;
  end;

  //Dump Overrides
  obj.O['overrides'] := SA([]);
  for i := 0 to Pred(plugin.overrides.Count) do begin
    childObj := SO;
    childObj.I['fid'] := Integer(plugin.overrides.Objects[i]);
    childObj.S['sig'] := plugin.overrides[i];
    obj.A['overrides'].O[i] := childObj;
  end;

  // dump errors
  obj.O['plugin_errors'] := SA([]);
  for i := 0 to Pred(plugin.errors.Count) do begin
    error := TRecordError(plugin.errors[i]);
    childObj := SO;
    childObj.I['type'] := Ord(error.&type.id);
    childObj.S['signature'] := string(error.signature);
    childObj.S['form_id'] := error.formID;
    childObj.S['name'] := error.name;
    if error.path <> '' then
      childObj.S['path'] := error.path;
    if error.data <> '' then
      childObj.S['data'] := error.data;
    obj.A['plugin_errors'].Add(childObj);
  end;

  // save to disk
  if settings.bSaveToDisk then begin
    sl := TStringList.Create;
    try
      sl.Text := obj.AsJSon;
      sl.SaveToFile(settings.dumpPath + plugin.filename + '.json');
    finally
      sl.Free;
    end;
  end;

  // result is JSON object
  Result := obj;
end;

function DumpPlugin(filePath: string): ISuperObject;
var
  slLoadOrder: TStringList;
  sFileName: string;
  plugin: TPlugin;
begin
  slLoadOrder := TStringList.Create;
  try
    // build and print load order
    BuildLoadOrder(filePath, slLoadOrder, true);
    wbFileForceClosed;
    PrintLoadOrder(slLoadOrder);

    // load plugins
    LoadPlugins(filePath, slLoadOrder);

    // dump info on our plugin
    sFileName := ExtractFilename(filePath);
    plugin := PluginByFilename(sFileName);
    WriteDump(plugin);
    Result := JsonDump(plugin);
  finally
    wbFileForceClosed;
    DeleteDummyPlugins;
    slLoadOrder.Free;
  end;
end;

function DumpPluginsList(filePath: string): ISuperObject;
var
  sl: TStringList;
  i: Integer;
  targetPath: string;
begin
  Result := SO;
  Result.O['plugins'] := SA([]);
  sl := TStringList.Create;
  try
    // load list of plugins to dump
    sl.LoadFromFile(filePath);

    // dump plugins in the list
    for i := 0 to Pred(sl.Count) do begin
      targetPath := sl[i];
      try
        // raise exception if a file doesn't exist at targetPath
        if not FileExists(targetPath) then
          raise Exception.Create('File not found');

        // raise exception if targetPath doesn't point to a plugin
        if not IsPlugin(targetPath) then
          raise Exception.Create('Does not match *.esp or *.esm');

        // dump the plugin
        Result.A['plugins'].O[i] := DumpPlugin(targetPath);
      except
        on x: Exception do
          AddMessage(Format('%s: %s', [targetPath, x.Message]));
      end;
    end;
  finally
    sl.Free;
  end;
end;

end.
