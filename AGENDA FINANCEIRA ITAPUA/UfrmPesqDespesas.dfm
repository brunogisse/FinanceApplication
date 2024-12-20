object frmPesqDespSub: TfrmPesqDespSub
  Left = 0
  Top = 0
  Caption = 'frmPesqDespSub'
  ClientHeight = 600
  ClientWidth = 760
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poDesktopCenter
  OnShow = FormShow
  TextHeight = 13
  object gridPesqDespSub: TDBGrid
    Left = 0
    Top = 65
    Width = 760
    Height = 535
    Align = alClient
    DataSource = dsSubdespesa
    ReadOnly = True
    TabOrder = 0
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDrawColumnCell = gridPesqDespSubDrawColumnCell
    OnDblClick = gridPesqDespSubDblClick
    OnKeyPress = gridPesqDespSubKeyPress
    Columns = <
      item
        Expanded = False
        FieldName = 'DESCRICAO'
        Width = 387
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CATEGORIA'
        Width = 223
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_MAXIMO'
        Visible = True
      end>
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 760
    Height = 65
    Align = alTop
    TabOrder = 1
    ExplicitWidth = 738
    object editPesquisa: TEdit
      Left = 16
      Top = 23
      Width = 489
      Height = 21
      CharCase = ecUpperCase
      TabOrder = 0
      OnChange = editPesquisaChange
      OnKeyDown = editPesquisaKeyDown
      OnKeyPress = editPesquisaKeyPress
    end
    object rgOrdenar: TRadioGroup
      Left = 527
      Top = 0
      Width = 114
      Height = 59
      Caption = 'Ordenar por:'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Verdana'
      Font.Style = []
      Items.Strings = (
        'Despesas'
        'Subdespesas')
      ParentFont = False
      TabOrder = 1
      OnClick = rgOrdenarClick
    end
  end
  object dsSubdespesa: TDataSource
    DataSet = FDqrySubdespesa
    Left = 643
    Top = 400
  end
  object FDqrySubdespesa: TFDQuery
    Connection = frmPrincipal.FDconexao
    SQL.Strings = (
      'select'
      ''
      'S.SUBCATEGORIA_ID, S.DESCRICAO,S.VALOR_MAXIMO,'
      
        'S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as C' +
        'ATEGORIA'
      ''
      'from'
      ''
      'SUBCATEGORIA S, CATEGORIA C'
      ''
      'where'
      ''
      '(S.CATEGORIA_ID = C.CATEGORIA_ID)'
      ''
      'order by C.DESCRICAO')
    Left = 555
    Top = 400
    object FDqrySubdespesaSUBCATEGORIA_ID: TIntegerField
      FieldName = 'SUBCATEGORIA_ID'
      Origin = 'SUBCATEGORIA_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqrySubdespesaDESCRICAO: TStringField
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 100
    end
    object FDqrySubdespesaVALOR_MAXIMO: TSingleField
      FieldName = 'VALOR_MAXIMO'
      Origin = 'VALOR_MAXIMO'
      currency = True
    end
    object FDqrySubdespesaCATEGORIA_FK: TIntegerField
      FieldName = 'CATEGORIA_FK'
      Origin = 'CATEGORIA_ID'
      Required = True
    end
    object FDqrySubdespesaCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA_ID'
      Origin = 'CATEGORIA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object FDqrySubdespesaCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 100
    end
  end
end
