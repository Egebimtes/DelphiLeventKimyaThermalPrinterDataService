unit dmMAS;

interface

uses
  SysUtils, Classes, DB, ADODB,
  Inifiles, Windows, Forms, Menus;

type
  Tdm = class(TDataModule)
    conMAS: TADOConnection;
    procedure DataModuleCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    p: string;
    Path: string;
    UDLAdi: string;
    ERPSirket, ERPKullanici, ERPSifre: string;
    ERPSubeKodu: Integer;
  end;

var
  dm: Tdm;

implementation

{%CLASSGROUP 'System.Classes.TPersistent'}

{$R *.dfm}

procedure Tdm.DataModuleCreate(Sender: TObject);
var
  param2  : string;
begin
  conMAS.Close;
  p := ExtractFilepath(Application.ExeName);

  if paramstr(2) = '' then
    param2 := 'MAS.UDL'
  else
    param2 := paramstr(2);

  Path := p + 'Settings\';
  UDLAdi := param2;

  ForceDirectories(Path);
  conMAS.ConnectionString := 'FILE NAME=' + p + UDLAdi;
  conMAS.Open;


end;

end.





