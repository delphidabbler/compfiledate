{
 * UParams.pas
 * Revision $Rev$ of $Date$
 *
 * Class that parses command line and exposes results in properties.
}


unit UParams;


interface


uses
  // Delphi
  Classes;


type

  {
  TSwitchId:
    Ids representing each valid command line switch.
  }
  TSwitchId = (
    siHelp,         // show help screen
    siVerbose       // verbose output
  );

  {
  TParams:
    Class that parses command line and exposes results in properties.
  }
  TParams = class(TObject)
  private
    fParams: TStringList;   // List of command line parameters
    fVerbose: Boolean;      // Value of Verbose property
    fHelp: Boolean;         // Value of Help property
    fFileName2: string;     // Value of FileName1 property
    fFileName1: string;     // Value of FileName2 property
    function SwitchToId(const Switch: string; out Id: TSwitchId): Boolean;
      {Finds id of a switch.
        @param Switch [in] Text defining switch.
        @param Id [out] Id of switch. Undefined if switch is invalid.
        @return True if switch is valid, False otherwise.
      }
    procedure HandleSwitch(const Id: TSwitchId; var ParamIdx: Integer);
      {Processes switch, updating config file.
        @param Id [in] Id of switch to handle.
        @param ParamIdx [in/out]. Index of current switch in fParams[]. ParamIdx
          should be incremented if an addition parameter is read.
      }
  public
    constructor Create;
      {Class constructor. Initialises object.
        @param Config [in] Configuration object to be updated from command line.
      }
    destructor Destroy; override;
      {Class destructor. Tears down object.
      }
    procedure Parse;
      {Parses the command line.
        @except Exception raised if error in command line.
      }
    property Verbose: Boolean read fVerbose;
      {Flag true if -v switch has been provided on command line}
    property Help: Boolean read fHelp;
      {Flag true if -h or -? switch has been provided on command line}
    property FileName1: string read fFileName1;
      {First file name on command line}
    property FileName2: string read fFileName2;
      {Second file name on command line}
  end;


implementation


uses
  // Delphi
  StrUtils, SysUtils, Windows {for inlining},
  // Project
  UAppException;


const
  // Map of switches onto switch id.
  cSwitches: array[1..3] of record
    Switch: string;   // switch
    Id: TSwitchId;    // switch id
  end = (
    // -v causes verbose output
    (Switch: '-v';        Id: siVerbose;),
    (Switch: '-h';        Id: siHelp),
    (Switch: '-?';        Id: siHelp)
  );


{ TParams }

constructor TParams.Create;
  {Class constructor. Initialises object.
    @param Config [in] Configuration object to be updated from command line.
  }
var
  Idx: Integer; // loops through all parameters
begin
  inherited Create;
  // Stores program parameters
  fParams := TStringList.Create;
  for Idx := 1 to ParamCount do
    fParams.Add(Trim(ParamStr(Idx)));
  // Set defaults
  fVerbose := False;
  fFileName1 := '';
  fFileName2 := '';
end;

destructor TParams.Destroy;
  {Class destructor. Tears down object.
  }
begin
  FreeAndNil(fParams);
  inherited;
end;

procedure TParams.HandleSwitch(const Id: TSwitchId; var ParamIdx: Integer);
  {Processes switch, updating config file.
    @param Id [in] Id of switch to handle.
    @param ParamIdx [in/out]. Index of current switch in fParams[]. ParamIdx
      should be incremented if an addition parameter is read.
  }
begin
  case Id of
    siVerbose:
      fVerbose := True;
    siHelp:
      fHelp := True;
  end;
end;

procedure TParams.Parse;
  {Parses the command line.
    @except Exception raised if error in command line.
  }
var
  Idx: Integer;         // loops through all parameters on command line
  SwitchId: TSwitchId;  // id of each switch
begin
  // Loop through all switches on command line
  Idx := 0;
  while Idx < fParams.Count do
  begin
    // Check we have a switch
    if not AnsiStartsStr('-', fParams[Idx]) then
    begin
      if fFileName1 = '' then
        fFileName1 := fParams[Idx]
      else if fFileName2 = '' then
        fFileName2 := fParams[Idx]
      else
        raise EApplication.Create(sAppErrTooManyFiles, cAppErrTooManyFiles);
    end
    else if SwitchToId(fParams[Idx], SwitchId) then
      HandleSwitch(SwitchId, Idx)
    else
      raise EApplication.CreateFmt(
        sAppErrBadSwitch, [fParams[Idx], cAppErrBadSwitch]
      );
    // Next switch parameter
    Inc(Idx);
  end;
  if not Help then
  begin
    if (fFileName1 = '') or (fFileName2 = '') then
      raise EApplication.Create(sAppErr2FilesNeeded, cAppErr2FilesNeeded);
    if AnsiSameText(fFileName1, fFileName2) then
      raise EApplication.Create(sAppErrFileNamesSame, cAppErrFileNamesSame);
  end;
end;

function TParams.SwitchToId(const Switch: string; out Id: TSwitchId): Boolean;
  {Finds id of a switch.
    @param Switch [in] Text defining switch.
    @param Id [out] Id of switch. Undefined if switch is invalid.
    @return True if switch is valid, False otherwise.
  }
var
  Idx: Integer; // loops through list of valid switches
begin
  Result := False;
  for Idx := Low(cSwitches) to High(cSwitches) do
  begin
    if Switch = cSwitches[Idx].Switch then
    begin
      Id := cSwitches[Idx].Id;
      Result := True;
      Break;
    end;
  end;
end;

end.
