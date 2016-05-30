# mod-dump
A program to produce compatibility dumps on bethesda plugins built on top of the xEdit codebase.  Provided both as a command line application and as a DLL.

## usage

### stdin

You can run ModDump.exe through Mod Organizer, or (if you don't use Mod Organizer) on its own, without any target line parameters.  You will then be prompted to choose a game mode and a plugin to dump.  Upon making a valid selection Mod Dump will perform the dump.

NOTE: If you run ModDump.exe directly it will close immediately after the dump finishes executing.  This may be undesireable, so I recommend either running it from the command line (by opening a command prompt in the same directory as ModDump.exe and entering `ModDump.exe`) or using a batch script:

```
@echo off
ModDump.exe
pause
```


### params

`ModDump.exe "file path" -game`

- file path: a relative or absolute path to an esp or esm file.  You can also use a text document list of paths.
- game
  - fo4: Fallout 4
  - sk: Skyrim
  - ob: Oblivion
  - fnv: Fallout New Vegas
  - fo3: Fallout 3
  
### settings

The program settings will be stored in settings.ini alongsede the executable.  The dummyPluginPath and dumpPath settings will use substitution in the form of `{{var}}` for the following variables:

- gameName: `Skyrim`, `Oblivion`, `FalloutNV`, `Fallout3`, or `Fallout4`
- longName: `Skyrim`, `Oblivion`, `Fallout New Vegas`, `Fallout 3`, or `Fallout 4`
- appName: `TES5`, `TES4`, `FNV`, `FO3`, or `FO4`
- abbrName: `sk`, `ob`, `fnv`, `fo3`, or `fo4`

#### general settings

- dummyPluginPath: path to an empty plugin for a particular game mode
  - defaults to `{{gameName}}\EmptyPlugin.esp`
  - If you need an empty plugin you can produce it fairly easily using xEdit.
- dumpPath: path where dump files will be saved to
  - defaults to `{{gameName}}\`
- bPrintHashes: if set to true, the program will print the hashes of every plugin it loads during execution
  - defaults to `false`
- bSaveToDisk: if set to true, the program will save a json version of the dump to disk
  - defaults to `false`
  - You probably want to set this to true if you're using the executable
- bAllowDummies: if set to true, the program will use the file at dummyPluginPath to produce dummies of master plugins that cannot be found, which allows for the dump to be performed (though it won't be complete)
  - defaults to `false`
  - You should not enable this in most circumstances.  This is mostly intended if you were analyzing plugins on a server and needed to be able to analyze a plugin without necessarily having its masters.

#### games settings

- skyrimPath: skyrim data path
  - defaults to the path the program finds in the registry
- oblivionPath: oblivion data path
  - defaults to the path the program finds in the registry
- fallout4Path: fallout 4 data path
  - defaults to the path the program finds in the registry
- fallout3Path: fallout 3 data path
  - defaults to the path the program finds in the registry
- falloutNVPath: fallout new vegas data path
  - defaults to the path the program finds in the registry

## information that is dumped

- Filename
- File size
- File hash (CRC32)
- Masters
- Number of records
- Number of override records
- Description
- Override records
  - Signature
  - FormID
- Errors
  - ITMs - Identical to Master records
  - ITPOs - Identical to Previous Override records
  - UDRs - Undelete and Disable References
  - UESs - Unexpected Subrecords
  - URRs - Unresolved References
  - UERs - Unexpected References
- Record groups
  - Group signature
  - Record Count
  - Override Record Count

### json format

TODO: Write this section

## dll interface

The following functions are extern:
* `procedure Initialize; StdCall; external 'ModDumpLib.dll';`
* `function GetBuffer: Pchar; StdCall; external 'ModDumpLib.dll';`
* `procedure Finalize; StdCall; external 'ModDumpLib.dll';`
* `procedure SetGameMode(mode: Integer); stdcall; external 'ModDumpLib.dll';`
* `function Prepare(TargetFile: PChar): Boolean; stdcall; external 'ModDumpLib.dll';`
* `function Dump: Boolean; stdcall; external 'ModDumpLib.dll';`
