object MasThermalDataPrinterService: TMasThermalDataPrinterService
  OldCreateOrder = False
  OnCreate = ServiceCreate
  DisplayName = 'MasThermalDataPrinterService'
  OnExecute = ServiceExecute
  Height = 226
  Width = 350
  object TimerServis: TTimer
    Enabled = False
    OnTimer = TimerServisTimer
    Left = 88
    Top = 40
  end
  object IdHTTP1: TIdHTTP
    AllowCookies = True
    ProxyParams.BasicAuthentication = False
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentRangeInstanceLength = -1
    Request.Accept = 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    Request.Ranges.Units = 'bytes'
    Request.Ranges = <>
    HTTPOptions = [hoForceEncodeParams]
    Left = 160
    Top = 40
  end
end
