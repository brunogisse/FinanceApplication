object frmBackUp: TfrmBackUp
  Left = 0
  Top = 0
  Caption = 'BackUp do banco'
  ClientHeight = 161
  ClientWidth = 577
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI Semibold'
  Font.Style = [fsBold]
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object btnBackUp: TSpeedButton
    Left = 16
    Top = 113
    Width = 97
    Height = 34
    Caption = 'Fazer backup'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = btnBackUpClick
  end
  object btnBanco: TSpeedButton
    Left = 528
    Top = 34
    Width = 35
    Height = 21
    Caption = '...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = btnBancoClick
  end
  object SpeedButton1: TSpeedButton
    Left = 528
    Top = 74
    Width = 35
    Height = 21
    Caption = '...'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
    OnClick = SpeedButton1Click
  end
  object labelBanco: TLabel
    Left = 16
    Top = 18
    Width = 34
    Height = 13
    Caption = 'Banco:'
  end
  object labelBackupRestore: TLabel
    Left = 16
    Top = 59
    Width = 40
    Height = 13
    Caption = 'Backup:'
  end
  object editBanco: TEdit
    Left = 16
    Top = 34
    Width = 506
    Height = 21
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 0
    Text = 'Y:\Dados\DADOS_14032022_ZERADO.FDB'
  end
  object editBackup: TEdit
    Left = 16
    Top = 74
    Width = 506
    Height = 21
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI Semibold'
    Font.Style = [fsBold]
    ParentFont = False
    TabOrder = 1
    Text = 'C:\Users\Usuario\Desktop\Novo sistema\DADOS_14032022_ZERADO.FDB'
  end
  object FDPhysFBDriverLink1: TFDPhysFBDriverLink
    VendorLib = 'C:\Program Files\Firebird\Firebird_2_5\bin\fbclient.dll'
    Left = 296
    Top = 112
  end
  object FDIBBackup1: TFDIBBackup
    DriverLink = FDPhysFBDriverLink1
    Verbose = True
    Left = 240
    Top = 112
  end
  object OpenDialog1: TOpenDialog
    Left = 424
    Top = 104
  end
  object FDGUIxWaitCursor1: TFDGUIxWaitCursor
    Provider = 'Forms'
    Left = 368
    Top = 112
  end
end
