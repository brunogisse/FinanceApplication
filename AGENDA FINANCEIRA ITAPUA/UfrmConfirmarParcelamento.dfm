object frmConfirmarParcelamentos: TfrmConfirmarParcelamentos
  Left = 0
  Top = 0
  Caption = 'Tela de Confirma'#231#227'o de Parcelamento'
  ClientHeight = 96
  ClientWidth = 496
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object MemoInform: TMemo
    Left = 0
    Top = 0
    Width = 496
    Height = 49
    Align = alClient
    Enabled = False
    Lines.Strings = (
      'MemoInform')
    TabOrder = 0
    ExplicitWidth = 580
    ExplicitHeight = 70
  end
  object Panel1: TPanel
    Left = 0
    Top = 49
    Width = 496
    Height = 47
    Align = alBottom
    TabOrder = 1
    ExplicitTop = 72
    ExplicitWidth = 580
    object btnConfirmar: TBitBtn
      Left = 87
      Top = 6
      Width = 121
      Height = 35
      Caption = 'Confirmar'
      TabOrder = 0
      OnClick = btnConfirmarClick
    end
    object btnCancelar: TBitBtn
      Left = 279
      Top = 6
      Width = 121
      Height = 35
      Cursor = crAppStart
      Caption = 'Cancelar'
      TabOrder = 1
      OnClick = btnCancelarClick
    end
  end
end
