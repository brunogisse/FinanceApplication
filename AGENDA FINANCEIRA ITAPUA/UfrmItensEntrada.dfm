object frmEntradaItens: TfrmEntradaItens
  Left = 0
  Top = 0
  Caption = 'Entrada de Itens'
  ClientHeight = 601
  ClientWidth = 690
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
  object painelTopo: TPanel
    Left = 0
    Top = 0
    Width = 690
    Height = 147
    Align = alTop
    TabOrder = 0
    object Lentrada: TLabel
      Left = 6
      Top = 7
      Width = 42
      Height = 13
      Caption = 'Entrada:'
    end
    object labelEntrada: TLabel
      Left = 52
      Top = 7
      Width = 60
      Height = 13
      Caption = 'labelEntrada'
    end
    object LNF: TLabel
      Left = 6
      Top = 22
      Width = 35
      Height = 13
      Caption = 'N'#186'  NF:'
    end
    object labelNF: TLabel
      Left = 52
      Top = 22
      Width = 35
      Height = 13
      Caption = 'labelNF'
    end
    object gbProdutos: TGroupBox
      Left = 6
      Top = 38
      Width = 611
      Height = 103
      TabOrder = 0
      object Label1: TLabel
        Left = 15
        Top = 8
        Width = 42
        Height = 13
        Caption = 'Produto:'
      end
      object Label2: TLabel
        Left = 15
        Top = 49
        Width = 28
        Height = 13
        Caption = 'Valor:'
      end
      object Label3: TLabel
        Left = 124
        Top = 49
        Width = 28
        Height = 13
        Caption = 'Qtde:'
      end
      object Label4: TLabel
        Left = 183
        Top = 49
        Width = 55
        Height = 13
        Caption = 'Valor Total:'
      end
      object editProdutoInserido: TEdit
        Left = 15
        Top = 23
        Width = 579
        Height = 21
        CharCase = ecUpperCase
        TabOrder = 0
        OnDblClick = editProdutoInseridoDblClick
        OnExit = editProdutoInseridoExit
        OnKeyPress = editProdutoInseridoKeyPress
      end
      object editValorItem: TEdit
        Left = 15
        Top = 63
        Width = 101
        Height = 21
        TabOrder = 1
        Text = '0'
        OnChange = editValorItemChange
        OnExit = editValorItemExit
      end
      object editQtdeItem: TEdit
        Left = 122
        Top = 63
        Width = 55
        Height = 21
        TabOrder = 2
        Text = '1'
        OnExit = editQtdeItemExit
      end
      object btnInserirItem: TBitBtn
        Left = 288
        Top = 61
        Width = 35
        Height = 23
        Glyph.Data = {
          42040000424D4204000000000000420000002800000010000000100000000100
          20000300000000040000130B0000130B000000000000000000000000FF0000FF
          0000FF000000000000000000000000000000000000000000002D000000810000
          0085000000810000008100000085000000810000002C00000000000000000000
          0000000000000000000000000000000000070000008100000066000000060000
          000000000000000000000000000000000006000000660000007E000000060000
          0000000000000000000000000007000000940000002000000000000000000000
          0000000000000000000000000000000000000000000000000021000000940000
          0006000000000000000000000082000000200000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000210000
          007E000000000000002D00000065000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00660000002C0000008200000006000000000000000000000000000000000000
          0035000000050000003200000000000000000000000000000000000000000000
          00060000008100000085000000000000000000000000000000000000005B0000
          0081000000780000008200000034000000000000000000000000000000000000
          000000000085000000810000000000000000000000000000005B000000560000
          00000000005A000000520000008C0000001B0000000000000000000000000000
          000000000081000000810000000000000000000000050000004A000000000000
          0000000000000000007A00000038000000950000000A00000000000000000000
          0000000000810000008500000000000000000000000000000000000000000000
          0000000000000000000200000091000000300000008E00000002000000000000
          0000000000850000008200000006000000000000000000000000000000000000
          000000000000000000000000000B0000001D0000002600000008000000000000
          0006000000810000002D00000065000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          00660000002D0000000000000082000000200000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000200000
          0081000000000000000000000007000000940000002000000000000000000000
          0000000000000000000000000000000000000000000000000020000000940000
          0007000000000000000000000000000000070000008200000065000000060000
          0000000000000000000000000000000000060000006500000081000000070000
          000000000000000000000000000000000000000000000000002D000000820000
          0085000000810000008100000085000000820000002D00000000000000000000
          000000000000}
        TabOrder = 3
        OnClick = btnInserirItemClick
      end
      object btnExcluirItem: TBitBtn
        Left = 329
        Top = 61
        Width = 34
        Height = 23
        Glyph.Data = {
          42040000424D4204000000000000420000002800000010000000100000000100
          20000300000000040000130B0000130B000000000000000000000000FF0000FF
          0000FF0000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000006666660500000000000000000000
          0000000000000000000000000000000000000000000066666605000000000000
          000000000000000000000000000053535344515151EC515151CC4E4E4E1A0000
          00000000000000000000000000004E4E4E1A515151CC515151EB535353440000
          0000000000000000000000000000515151B9515151FF515151FF515151D94E4E
          4E1A00000000000000004E4E4E1A515151D9515151FF515151FF505050B80000
          00000000000000000000000000005252525D515151FF515151FF515151FF5151
          51D94E4E4E1A4E4E4E1A515151D9515151FF515151FF515151FF5252525D0000
          0000000000000000000000000000000000005050506C515151FF515151FF5151
          51FF515151D9515151D9515151FF515151FF515151FF5050506C000000000000
          000000000000000000000000000000000000000000005050506C515151FF5151
          51FF515151FF515151FF515151FF515151FF5050506C00000000000000000000
          00000000000000000000000000000000000000000000000000005151517E5151
          51FF515151FF515151FF515151FF5252527D0000000000000000000000000000
          0000000000000000000000000000000000000000000052525219515151D95151
          51FF515151FF515151FF515151FF515151D85252521900000000000000000000
          00000000000000000000000000000000000052525219515151D8515151FF5151
          51FF515151FF515151FF515151FF515151FF515151D855555518000000000000
          000000000000000000000000000055555518515151D8515151FF515151FF5151
          51FF5252526D5151516E515151FF515151FF515151FF515151D7555555180000
          0000000000000000000000000000505050A8515151FF515151FF515151FF5151
          516E00000000000000005050506F515151FF515151FF515151FF505050A80000
          000000000000000000000000000050505092515151FF515151FF5050506F0000
          000000000000000000000000000052525270515151FF515151FF515151910000
          0000000000000000000000000000494949075252526D50505049000000000000
          000000000000000000000000000000000000505050495252526D494949070000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          0000000000000000000000000000000000000000000000000000000000000000
          000000000000}
        TabOrder = 4
        OnClick = btnExcluirItemClick
      end
      object gbTotal: TGroupBox
        Left = 448
        Top = 49
        Width = 146
        Height = 48
        Caption = 'Total Produtos '
        Enabled = False
        TabOrder = 5
        object editTotalProdutos: TDBEdit
          Left = 10
          Top = 16
          Width = 121
          Height = 24
          DataField = 'ITENS_SOMADOS_PARA_NF'
          DataSource = dsSomaItens
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
        end
      end
      object editValorTotalItem: TEdit
        Left = 183
        Top = 63
        Width = 98
        Height = 21
        Enabled = False
        TabOrder = 6
        Text = '0'
      end
    end
  end
  object gridEntradaDEitens: TDBGrid
    Left = 0
    Top = 147
    Width = 690
    Height = 413
    Align = alClient
    DataSource = dsEntradaItens
    ReadOnly = True
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDrawColumnCell = gridEntradaDEitensDrawColumnCell
    Columns = <
      item
        Expanded = False
        FieldName = 'PRODUTO'
        Width = 408
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'QTDE_ITEM'
        Width = 56
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_ITEM'
        Width = 77
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_TOTAL_ITEM'
        Width = 84
        Visible = True
      end>
  end
  object painelBottom: TPanel
    Left = 0
    Top = 560
    Width = 690
    Height = 41
    Align = alBottom
    TabOrder = 2
  end
  object FDqryEntradaItens: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcItensEntrada
    UpdateOptions.AssignedValues = [uvFetchGeneratorsPoint, uvGeneratorName]
    UpdateOptions.GeneratorName = 'GEN_ITEM_NF_ID'
    UpdateOptions.UpdateTableName = 'ITEM_NF'
    UpdateOptions.KeyFields = 'ITEM_NF_ID'
    UpdateOptions.AutoIncFields = 'ITEM_NF_ID'
    SQL.Strings = (
      'select'
      ''
      ' I.ITEM_NF_ID,'
      ' I.NF_ID,'
      ' I.PRODUTO_ID,'
      ' I.VALOR_ITEM,'
      ' I.VALOR_TOTAL_ITEM,'
      ' I.QTDE_ITEM,'
      ' CAD.CADASTRO_NF_ID,'
      ' P.PRODUTO_ID as ID_DO_PRODUTO,'
      ' P.DESCRICAO as PRODUTO'
      ''
      'from'
      ''
      ' ITEM_NF I, CADASTRO_NF CAD, PRODUTO P'
      ''
      'where'
      '  '
      ' (I.NF_ID = CAD.CADASTRO_NF_ID) and'
      ' (I.NF_ID = :ENTRADA) and'
      ' (I.PRODUTO_ID = P.PRODUTO_ID)')
    Left = 336
    Top = 312
    ParamData = <
      item
        Name = 'ENTRADA'
        DataType = ftInteger
        ParamType = ptInput
        Value = Null
      end>
    object FDqryEntradaItensITEM_NF_ID: TIntegerField
      DisplayLabel = 'Item ID:'
      FieldName = 'ITEM_NF_ID'
      Origin = 'ITEM_NF_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqryEntradaItensNF_ID: TIntegerField
      DisplayLabel = 'NF ID:'
      FieldName = 'NF_ID'
      Origin = 'NF_ID'
    end
    object FDqryEntradaItensPRODUTO_ID: TIntegerField
      DisplayLabel = 'C'#243'd. Produto'
      FieldName = 'PRODUTO_ID'
      Origin = 'PRODUTO_ID'
    end
    object FDqryEntradaItensVALOR_ITEM: TFMTBCDField
      DisplayLabel = 'Valor:'
      FieldName = 'VALOR_ITEM'
      Origin = 'VALOR_ITEM'
      currency = True
      Precision = 18
      Size = 2
    end
    object FDqryEntradaItensQTDE_ITEM: TIntegerField
      DisplayLabel = 'Qtde:'
      FieldName = 'QTDE_ITEM'
      Origin = 'QTDE_ITEM'
    end
    object FDqryEntradaItensCADASTRO_NF_ID: TIntegerField
      AutoGenerateValue = arDefault
      DisplayLabel = 'C'#243'd. NF'
      FieldName = 'CADASTRO_NF_ID'
      Origin = 'CADASTRO_NF_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object FDqryEntradaItensID_DO_PRODUTO: TIntegerField
      AutoGenerateValue = arDefault
      DisplayLabel = 'C'#243'd. table prod.'
      FieldName = 'ID_DO_PRODUTO'
      Origin = 'PRODUTO_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object FDqryEntradaItensPRODUTO: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Produto:'
      FieldName = 'PRODUTO'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 40
    end
    object FDqryEntradaItensVALOR_TOTAL_ITEM: TFMTBCDField
      DisplayLabel = 'Valor Total:'
      FieldName = 'VALOR_TOTAL_ITEM'
      Origin = 'VALOR_TOTAL_ITEM'
      currency = True
      Precision = 18
      Size = 2
    end
  end
  object dsEntradaItens: TDataSource
    DataSet = FDqryEntradaItens
    Left = 432
    Top = 312
  end
  object dsProduto: TDataSource
    DataSet = FDqryProduto
    Left = 432
    Top = 368
  end
  object FDqryProduto: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcItensEntrada
    UpdateOptions.UpdateTableName = 'PRODUTO'
    UpdateOptions.KeyFields = 'PRODUTO_ID'
    SQL.Strings = (
      'select'
      ''
      ' P.PRODUTO_ID,'
      ' P.DESCRICAO,'
      ' P.VALOR,'
      ' P.ESTOQUE_MINIMO,'
      ' P.TIPO,'
      ' P.ESTOQUE,'
      ' T.TIPO_PRODUTO_ID,'
      ' T.DESCRICAO as TIPO_DESCRICAO'
      ''
      'from'
      ''
      ' PRODUTO P, TIPO_PRODUTO T'
      ''
      'where'
      ''
      ' (P.TIPO = T.TIPO_PRODUTO_ID)')
    Left = 336
    Top = 368
    object FDqryProdutoPRODUTO_ID: TIntegerField
      FieldName = 'PRODUTO_ID'
      Origin = 'PRODUTO_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqryProdutoDESCRICAO: TStringField
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 40
    end
    object FDqryProdutoVALOR: TFMTBCDField
      FieldName = 'VALOR'
      Origin = 'VALOR'
      Precision = 18
      Size = 2
    end
    object FDqryProdutoESTOQUE_MINIMO: TIntegerField
      FieldName = 'ESTOQUE_MINIMO'
      Origin = 'ESTOQUE_MINIMO'
    end
    object FDqryProdutoTIPO: TIntegerField
      FieldName = 'TIPO'
      Origin = 'TIPO'
    end
    object FDqryProdutoESTOQUE: TIntegerField
      FieldName = 'ESTOQUE'
      Origin = 'ESTOQUE'
    end
    object FDqryProdutoTIPO_PRODUTO_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'TIPO_PRODUTO_ID'
      Origin = 'TIPO_PRODUTO_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object FDqryProdutoTIPO_DESCRICAO: TStringField
      AutoGenerateValue = arDefault
      FieldName = 'TIPO_DESCRICAO'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 40
    end
  end
  object dsEntradaNF: TDataSource
    DataSet = FDqryEntradaNF
    Left = 432
    Top = 432
  end
  object FDqryEntradaNF: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcItensEntrada
    UpdateOptions.UpdateTableName = 'CADASTRO_NF'
    UpdateOptions.KeyFields = 'CADASTRO_NF_ID'
    SQL.Strings = (
      'select * from CADASTRO_NF')
    Left = 336
    Top = 432
    object FDqryEntradaNFCADASTRO_NF_ID: TIntegerField
      FieldName = 'CADASTRO_NF_ID'
      Origin = 'CADASTRO_NF_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqryEntradaNFFORNECEDOR_ID: TIntegerField
      FieldName = 'FORNECEDOR_ID'
      Origin = 'FORNECEDOR_ID'
    end
    object FDqryEntradaNFDATA: TDateField
      FieldName = 'DATA'
      Origin = '"DATA"'
    end
    object FDqryEntradaNFVALOR_NF: TFMTBCDField
      FieldName = 'VALOR_NF'
      Origin = 'VALOR_NF'
      Precision = 18
      Size = 2
    end
    object FDqryEntradaNFNF: TIntegerField
      FieldName = 'NF'
      Origin = 'NF'
    end
    object FDqryEntradaNFOBS: TStringField
      FieldName = 'OBS'
      Origin = 'OBS'
      Size = 200
    end
    object FDqryEntradaNFDATA_EMISSAO_NF: TDateField
      FieldName = 'DATA_EMISSAO_NF'
      Origin = 'DATA_EMISSAO_NF'
    end
    object FDqryEntradaNFSTATUS: TStringField
      FieldName = 'STATUS'
      Origin = 'STATUS'
      Size = 10
    end
    object FDqryEntradaNFNF_LANCADA: TStringField
      FieldName = 'NF_LANCADA'
      Origin = 'NF_LANCADA'
      Size = 3
    end
  end
  object FdqrySomaItens: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcItensEntrada
    SQL.Strings = (
      
        'select SUM(VALOR_TOTAL_ITEM) as ITENS_SOMADOS_PARA_NF from (sele' +
        'ct'
      ''
      ' I.ITEM_NF_ID,'
      ' I.NF_ID,'
      ' I.PRODUTO_ID,'
      ' I.VALOR_ITEM,'
      ' I.VALOR_TOTAL_ITEM,'
      ' I.QTDE_ITEM,'
      ' CAD.CADASTRO_NF_ID,'
      ' P.PRODUTO_ID as ID_DO_PRODUTO,'
      ' P.DESCRICAO as PRODUTO'
      ''
      'from'
      ''
      ' ITEM_NF I, CADASTRO_NF CAD, PRODUTO P'
      ''
      'where'
      '  '
      ' (I.NF_ID = CAD.CADASTRO_NF_ID) and'
      ' (I.NF_ID = :ENTRADA) and'
      ' (I.PRODUTO_ID = P.PRODUTO_ID))')
    Left = 336
    Top = 496
    ParamData = <
      item
        Name = 'ENTRADA'
        DataType = ftInteger
        ParamType = ptInput
        Value = Null
      end>
    object FdqrySomaItensITENS_SOMADOS_PARA_NF: TFMTBCDField
      AutoGenerateValue = arDefault
      FieldName = 'ITENS_SOMADOS_PARA_NF'
      Origin = 'ITENS_SOMADOS_PARA_NF'
      ProviderFlags = []
      ReadOnly = True
      currency = True
      Precision = 18
      Size = 2
    end
  end
  object dsSomaItens: TDataSource
    DataSet = FdqrySomaItens
    Left = 432
    Top = 496
  end
  object FDtcItensEntrada: TFDTransaction
    Options.AutoStop = False
    Connection = frmPrincipal.FDconexao
    Left = 224
    Top = 320
  end
end
