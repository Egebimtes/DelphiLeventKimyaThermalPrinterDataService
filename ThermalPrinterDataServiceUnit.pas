unit ThermalPrinterDataServiceUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.SvcMgr, Vcl.Dialogs,
  Vcl.ExtCtrls, System.IniFiles, ADODB, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, StrUtils, DateUtils;

type
  TMasThermalDataPrinterService = class(TService)
    TimerServis: TTimer;
    IdHTTP1: TIdHTTP;
    procedure ServiceCreate(Sender: TObject);
    procedure ServiceExecute(Sender: TService);
    procedure TimerServisTimer(Sender: TObject);
  private
    { Private declarations }
    Durum:Boolean;
    procedure Servis;
    procedure DosyaLogYaz(aMesaj: String);
    procedure HttpPost(aUrlPage, aParamString: String);
  public
    plcIP:String;
    function GetServiceController: TServiceController; override;
    { Public declarations }
  end;

var
  MasThermalDataPrinterService: TMasThermalDataPrinterService;

implementation

{$R *.dfm}

uses dmMAS;

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  MasThermalDataPrinterService.Controller(CtrlCode);
end;

function TMasThermalDataPrinterService.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure TMasThermalDataPrinterService.ServiceCreate(Sender: TObject);
var
  qry:TADOQuery;
  IniDosya: TIniFile;
  SorguYenilemeSn:Integer;

begin

  try
    try
      IniDosya := TIniFile.Create('C:\MAS\BIN\PLCWebRequestParam.ini');

      plcIP := IniDosya.ReadString('AYAR', 'PlcIp', '192.168.16.90');

      SorguYenilemeSn := IniDosya.ReadInteger('AYAR','SorguYenilemeSn',3);

      iniDosya.Free;

      TimerServis.Enabled := False;

      TimerServis.Interval := SorguYenilemeSn;


    except on E:Exception do

    end;

  finally


  end;

end;

procedure TMasThermalDataPrinterService.ServiceExecute(Sender: TService);
begin
  TimerServis.Enabled := True;

  while not Terminated do
    ServiceThread.ProcessRequests(True); // wait for termination

  TimerServis.Enabled := False;
end;

procedure TMasThermalDataPrinterService.Servis;
var
  qrySorgu,qryIslem: TADOQuery;
  FileName:string;
  HttpReturn,workCenterCode,materialCode,materialName,lotNumber:String;
  workCenterId,batchAmount,batchBarcodeCounter,plcBatchAmount,plcBatchBarcodeCounter,lastBatchBarcodeCounter:Integer;
  Time1,Time2:TDateTime;
  ProcessTimeSn,VirgulKarakterSira,productionMasterId:Integer;
begin
  qrySorgu := TADOQuery.Create(nil);
  qrySorgu.Connection := dm.conMAS;

  qryIslem := TADOQuery.Create(nil);
  qryIslem.Connection := dm.conMAS;

  try
    try

      with qrySorgu do
      Begin
        SQL.Add(' SELECT ');
        SQL.Add(' WC.[Id] AS WorkCenterId, ');
        SQL.Add(' PM.[Id] AS ProductionMasterId, ');
        SQL.Add(' WC.[Code] AS WorkCenterCode, ');
        SQL.Add(' MAT.[Code] AS MaterialCode, ');
        SQL.Add(' MAT.[Name] AS MaterialName, ');
        SQL.Add(' ISNULL(MAT.[BatchAmount],0) AS BatchAmount, ');
        SQL.Add(' WPS.[Counter] ');
        SQL.Add(' FROM Production.ProductionMaster AS PM WITH(NOLOCK) ');
        SQL.Add(' LEFT JOIN Production.ProductionDetail AS PD WITH(NOLOCK) ON PD.ProductionMasterId = PM.Id ');
        SQL.Add(' LEFT JOIN Planning.WorkOrder AS WO WITH(NOLOCK) ON WO.Id = PD.WorkOrderId ');
        SQL.Add(' LEFT JOIN Inventory.Material AS MAT WITH(NOLOCK) ON MAT.Id = WO.MaterialId ');
        SQL.Add(' LEFT JOIN DataCollection.WorkCenterPlcSetting AS WPS WITH(NOLOCK) ON WPS.WorkCenterId = PM.WorkCenterId AND WPS.CounterTypeId = 12 ');
        SQL.Add(' LEFT JOIN Organization.WorkCenter AS WC WITH(NOLOCK) ON PM.WorkCenterId = WC.Id ');
        SQL.Add(' WHERE 1 = 1 ');
        SQL.Add(' AND PM.EndDateTime IS NULL ');
        SQL.Add(' AND PM.WorkCenterId IN(1,2,3,38,40) ');
        SQL.Add(' ORDER BY PM.WorkCenterId ');
        Open;
      End;


      HttpReturn:='';

      While Not qrySorgu.Eof do
      begin
        workCenterId := 0;

        batchAmount := 0;
        batchBarcodeCounter := 0;

        plcBatchAmount := 0;
        plcBatchBarcodeCounter := 0;



        workCenterId        := qrySorgu.FieldByName('WorkCenterId').AsInteger;
        productionMasterId  := qrySorgu.FieldByName('ProductionMasterId').AsInteger;

        HttpReturn:=IdHTTP1.Get('http://'+plcIP+'/awp/myApp/ReadBatchInfo'+IntToStr(workCenterId)+'.htm');


        VirgulKarakterSira   := AnsiPos(',',HttpReturn);

        plcBatchAmount         := StrToInt(MidStr(HttpReturn,1,VirgulKarakterSira-1));
        plcBatchBarcodeCounter :=  StrToInt(MidStr(HttpReturn,VirgulKarakterSira+1,10));

        batchAmount            := qrySorgu.FieldByName('BatchAmount').AsInteger;
        batchBarcodeCounter    := qrySorgu.FieldByName('Counter').AsInteger;


        if (plcBatchAmount <> batchAmount) then
        Begin
          HttpPost('http://'+plcIP+'/awp/myApp/WriteBatchInfo.htm','"BatchAmount".m'+IntToStr(workCenterId)+'='+IntToStr(batchAmount)+'');
        End;

        if (plcBatchBarcodeCounter <> batchBarcodeCounter) and (plcBatchBarcodeCounter > 0) then
        Begin

          //lotNumber := AnsiRightStr(qrySorgu.FieldByName('MaterialCode').AsString, 5) +'-'+FormatDateTime('ddmmyy',Now)+'-1-'+IntToStr(plcBatchBarcodeCounter);
          lotNumber := AnsiRightStr(qrySorgu.FieldByName('MaterialCode').AsString, 5) +'-'+ FormatDateTime('ddmmyy',Now) +'-'+  IntToStr(productionMasterId) +'-'+ IntToStr(plcBatchBarcodeCounter);

          with qryIslem do
          Begin
            Close;
            SQL.Clear;
            SQL.Add(' INSERT INTO [LeventKimya].[ThermalPrinterData]');
            SQL.Add(' (WorkCenterId, ');
            SQL.Add(' WorkCenterCode, ');
            SQL.Add(' MaterialCode, ');
            SQL.Add(' MaterialName, ');
            SQL.Add(' LotNumber, ');
            SQL.Add(' RecordDateTime, ');
            SQL.Add(' IsTransferred) ');
            SQL.Add(' VALUES ');
            SQL.Add(' (:WorkCenterId, ');
            SQL.Add(' :WorkCenterCode, ');
            SQL.Add(' :MaterialCode, ');
            SQL.Add(' :MaterialName, ');
            SQL.Add(' :LotNumber, ');
            SQL.Add(' :RecordDateTime, ');
            SQL.Add(' :IsTransferred) ');
            Parameters.ParamByName('WorkCenterId').Value   := qrySorgu.FieldByName('WorkCenterId').AsInteger;
            Parameters.ParamByName('WorkCenterCode').Value := qrySorgu.FieldByName('WorkCenterCode').AsString;
            Parameters.ParamByName('MaterialCode').Value   := qrySorgu.FieldByName('MaterialCode').AsString;
            Parameters.ParamByName('MaterialName').Value   := qrySorgu.FieldByName('MaterialName').AsString;
            Parameters.ParamByName('LotNumber').Value      := lotNumber;
            Parameters.ParamByName('RecordDateTime').Value := Now;
            Parameters.ParamByName('IsTransferred').Value  := 0;
            ExecSQL;
          End;

          with qryIslem do
          Begin
            Close;
            SQL.Clear;
            SQL.Add(' UPDATE [DataCollection].WorkCenterPlcSetting SET Counter=:Counter ,UpdatedOn=GETDATE(), UpdatedBy=''MasThermalDataService'' ');
            SQL.Add(' Where WorkCenterId=:WorkCenterId and CounterTypeId=12 ');
            Parameters.ParamByName('WorkCenterId').Value := workCenterId;
            Parameters.ParamByName('Counter').Value      := plcBatchBarcodeCounter;
            ExecSQL;
          End;

        End;

        qrySorgu.Next;
      end;



    except on e:Exception do
      begin
        DosyaLogYaz(DateTimeToStr(now)+e.Message);
        Durum:= False;

      end;
    end;
  finally
    qrySorgu.Close;
    FreeAndNil(qrySorgu);
    qryIslem.Close;
    FreeAndNil(qryIslem);

  end;

end;

procedure TMasThermalDataPrinterService.TimerServisTimer(Sender: TObject);
begin
  Durum:= True;
  TimerServis.Enabled:= False;
  try
    try
      Servis;

      if Durum = False then
      begin
        //dm.DataModuleCreate(Sender);
        dm.conMAS.Close;
        dm.conMAS.Open;
      end;

    except
      //dm.conMAS.Close;
      //dm.conMAS.Open;
      //TimerServis.Enabled := False;
      //TimerServis.Enabled := True;
    end;
  finally
    TimerServis.Enabled:= True;
  end;

end;

procedure TMasThermalDataPrinterService.DosyaLogYaz(aMesaj:String);
var
Dosya: Textfile;
begin
  if (FileExists('C:\Services\ThermalPrinterDataService\ThermalPrinterDataServiceLog.txt')=false) then
  Begin
    AssignFile(Dosya, 'C:\Services\ThermalPrinterDataService\ThermalPrinterDataServiceLog.txt');
    ReWrite(Dosya);
  End;

  AssignFile(Dosya, 'C:\Services\ThermalPrinterDataService\ThermalPrinterDataServiceLog.txt');
  //Reset(Dosya);
  Append(Dosya);
  Writeln(Dosya, aMesaj);
  Closefile(Dosya);
end;

procedure TMasThermalDataPrinterService.HttpPost(aUrlPage: String; aParamString:String);
var
  myData : TStringStream;
begin

  try
    try
      //ParamString :=  "M1020.0"=1'
      myData := TStringStream.Create(aParamString, TEncoding.UTF8);

      IdHTTP1.Request.ContentType := 'application/json';
      IdHTTP1.Request.CharSet     := 'utf-8';
      IdHTTP1.Post(aUrlPage, myData);

    except on E:Exception do
      DosyaLogYaz(DateTimeToStr(now)+' PLC Web Servere Veri G?nderilirken Hata Olu?tu.G?nderilen Veri: '+aParamString);
    end;

  finally
  end;
end;
end.
