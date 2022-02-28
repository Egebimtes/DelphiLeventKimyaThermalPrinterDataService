object dm: Tdm
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 150
  Width = 362
  object conMAS: TADOConnection
    ConnectionString = 'FILE NAME=C:\MAS_TTTR\BIN\MAS.Udl'
    LoginPrompt = False
    Provider = 'C:\MAS_TTTR\BIN\MAS.Udl'
    Left = 72
    Top = 32
  end
end
