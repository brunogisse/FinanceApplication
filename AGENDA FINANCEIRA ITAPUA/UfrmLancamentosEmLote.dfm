object frmLancamentosEmLote: TfrmLancamentosEmLote
  Left = 0
  Top = 0
  Caption = 'Lan'#231'amentos em lote'
  ClientHeight = 569
  ClientWidth = 977
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Roboto'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  PixelsPerInch = 96
  TextHeight = 13
  object pnlGeral: TPanel
    Left = 0
    Top = 0
    Width = 977
    Height = 569
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitHeight = 221
    object pnlTopo: TPanel
      Left = 0
      Top = 0
      Width = 977
      Height = 121
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object btnPlanilha: TSpeedButton
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
        OnClick = btnPlanilhaClick
      end
      object labelBanco: TLabel
        Left = 16
        Top = 18
        Width = 85
        Height = 13
        Caption = 'Escolher planilha'
      end
      object btnCarregarPlanilha: TSpeedButton
        Left = 16
        Top = 61
        Width = 97
        Height = 34
        Caption = 'Carregar Grid'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnCarregarPlanilhaClick
      end
      object btnLimpar: TSpeedButton
        Left = 119
        Top = 61
        Width = 114
        Height = 34
        Caption = 'Limpar informa'#231#245'es'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnLimparClick
      end
      object editCaminhoPlanilha: TEdit
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
      end
    end
    object gridLote: TDBGrid
      Left = 0
      Top = 127
      Width = 977
      Height = 442
      Align = alBottom
      DataSource = dsPlanilhaLote
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Roboto'
      TitleFont.Style = []
    end
  end
  object cldsPlanilhaLote: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'DESCRICAO'
        DataType = ftString
        Size = 20
      end
      item
        Name = 'VALOR_PAGO'
        DataType = ftFloat
        Precision = 15
      end
      item
        Name = 'DATA_VENCIMENTO'
        DataType = ftDate
      end>
    IndexDefs = <>
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    StoreDefs = True
    Left = 768
    Top = 320
    object cldsPlanilhaLoteDESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      DisplayWidth = 89
      FieldKind = fkInternalCalc
      FieldName = 'DESCRICAO'
    end
    object cldsPlanilhaLoteVALOR_PAGO: TFloatField
      DisplayLabel = 'Valor Pago'
      DisplayWidth = 37
      FieldKind = fkInternalCalc
      FieldName = 'VALOR_PAGO'
    end
    object cldsPlanilhaLoteDATA_VENCIMENTO: TDateField
      DisplayLabel = 'Vencimento'
      DisplayWidth = 17
      FieldKind = fkInternalCalc
      FieldName = 'DATA_VENCIMENTO'
    end
  end
  object dsPlanilhaLote: TDataSource
    DataSet = cldsPlanilhaLote
    Left = 672
    Top = 320
  end
  object OpenDialog1: TOpenDialog
    Left = 864
    Top = 320
  end
end
