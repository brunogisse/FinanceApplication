object frmFonteParaRelCategoria: TfrmFonteParaRelCategoria
  Left = 0
  Top = 0
  Caption = 'frmFonteParaRelCategoria'
  ClientHeight = 586
  ClientWidth = 778
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object painelFonteParaRelCategoria: TPanel
    Left = 0
    Top = 0
    Width = 778
    Height = 65
    Align = alTop
    TabOrder = 0
    ExplicitWidth = 635
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 65
    Width = 778
    Height = 521
    Align = alClient
    DataSource = dsFonteParaRelCategoria
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDblClick = DBGrid1DblClick
  end
  object fdqryFonteParaRelCategoria: TFDQuery
    Connection = frmPrincipal.FDconexao
    SQL.Strings = (
      'select * from categoria')
    Left = 304
    Top = 320
    object fdqryFonteParaRelCategoriaCATEGORIA_ID: TIntegerField
      DisplayLabel = 'C'#243'd.'
      FieldName = 'CATEGORIA_ID'
      Origin = 'CATEGORIA_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object fdqryFonteParaRelCategoriaDESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 100
    end
  end
  object dsFonteParaRelCategoria: TDataSource
    DataSet = fdqryFonteParaRelCategoria
    Left = 296
    Top = 376
  end
end
