object frmLancamentosEmLote: TfrmLancamentosEmLote
  Left = 0
  Top = 0
  Caption = 'Lan'#231'amentos em lote'
  ClientHeight = 569
  ClientWidth = 1212
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Roboto'
  Font.Style = []
  OldCreateOrder = False
  Position = poDesktopCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object pnlGeral: TPanel
    Left = 0
    Top = 0
    Width = 1212
    Height = 569
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object pnlTopo: TPanel
      Left = 0
      Top = 0
      Width = 1212
      Height = 258
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitTop = 7
      object btnPlanilha: TSpeedButton
        Left = 590
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
        Width = 97
        Height = 15
        Caption = 'Escolher planilha'
      end
      object btnCarregarPlanilha: TSpeedButton
        Left = 16
        Top = 61
        Width = 97
        Height = 25
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
        Height = 25
        Caption = 'Limpar informa'#231#245'es'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
        OnClick = btnLimparClick
      end
      object lblQuantidade: TLabel
        Left = 648
        Top = 232
        Width = 317
        Height = 24
        Caption = 'Quantidade de registros importada: '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = 'Roboto'
        Font.Style = []
        ParentFont = False
      end
      object editCaminhoPlanilha: TEdit
        Left = 16
        Top = 34
        Width = 568
        Height = 21
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Segoe UI Semibold'
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object gbSelecao: TGroupBox
        Left = 16
        Top = 99
        Width = 609
        Height = 154
        Caption = '  Selecione conta e a categoria do lote que ser'#225' lan'#231'ado  '
        TabOrder = 1
        object labelPesqDespSub: TLabel
          Left = 13
          Top = 23
          Width = 74
          Height = 15
          Caption = 'Subdespesa:'
        end
        object labelConta: TLabel
          Left = 13
          Top = 64
          Width = 36
          Height = 16
          Caption = 'Conta:'
        end
        object Label1: TLabel
          Left = 13
          Top = 106
          Width = 124
          Height = 15
          Caption = 'Forma de pagamento:'
        end
        object editPesquisaDespSub: TEdit
          Left = 13
          Top = 37
          Width = 555
          Height = 23
          CharCase = ecUpperCase
          Color = 15395562
          ReadOnly = True
          TabOrder = 0
          OnDblClick = editPesquisaDespSubDblClick
          OnKeyPress = editPesquisaDespSubKeyPress
        end
        object cmbContas: TDBComboBox
          Left = 13
          Top = 79
          Width = 273
          Height = 23
          BevelInner = bvNone
          Color = 15395562
          DataField = 'DESCRICAO'
          DataSource = dsContas
          TabOrder = 1
        end
        object btnSalvar: TBitBtn
          Left = 449
          Top = 85
          Width = 119
          Height = 39
          Caption = 'Iniciar lan'#231'amento'
          TabOrder = 2
          OnClick = btnSalvarClick
        end
        object cmbFormaPgto: TDBComboBox
          Left = 13
          Top = 121
          Width = 273
          Height = 23
          BevelInner = bvNone
          Color = 15395562
          DataField = 'DESCRICAO'
          DataSource = dsFormaPgto
          TabOrder = 3
        end
      end
    end
    object gridLote: TDBGrid
      Left = 0
      Top = 271
      Width = 1212
      Height = 298
      Align = alBottom
      DataSource = dsPlanilhaLote
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -13
      TitleFont.Name = 'Roboto'
      TitleFont.Style = []
    end
  end
  object cldsPlanilhaLote: TFDMemTable
    Active = True
    FieldDefs = <
      item
        Name = 'DATA'
        DataType = ftDate
      end
      item
        Name = 'DESCRICAO'
        DataType = ftString
        Size = 200
      end
      item
        Name = 'VALOR'
        DataType = ftFloat
        Precision = 15
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
    object cldsPlanilhaLoteDATA: TDateField
      DisplayWidth = 10
      FieldKind = fkInternalCalc
      FieldName = 'DATA'
    end
    object cldsPlanilhaLoteDESCRICAO: TStringField
      DisplayWidth = 132
      FieldKind = fkInternalCalc
      FieldName = 'DESCRICAO'
      Size = 200
    end
    object cldsPlanilhaLoteVALOR: TFloatField
      DisplayWidth = 20
      FieldKind = fkInternalCalc
      FieldName = 'VALOR'
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
  object FDqryLcto: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcLcto
    UpdateOptions.AssignedValues = [uvGeneratorName, uvCheckReadOnly, uvAutoCommitUpdates]
    UpdateOptions.GeneratorName = 'GEN_REGISTRO_DE_GASTOS_ID'
    UpdateOptions.CheckReadOnly = False
    UpdateOptions.AutoCommitUpdates = True
    UpdateOptions.UpdateTableName = 'REGISTRO_DE_GASTOS'
    UpdateOptions.KeyFields = 'GASTOS_ID'
    UpdateOptions.AutoIncFields = 'GASTOS_ID'
    SQL.Strings = (
      'select'
      ''
      
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORI' +
        'A_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_' +
        'PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
      
        'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO,' +
        ' REG.NOTA_FISCAL,REG.CHEQUE,'
      
        'REG.CHEQUE_COMPENSADO,REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, R' +
        'EG.PAGO, REG.ENTRADA_ID, REG.SITUACAO_STATUS,'
      
        'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.D' +
        'ESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP' +
        '.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
      'REG.OBS, REG.DATA_CADASTRO, REG.USERID'
      ''
      'from'
      ''
      
        'REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, ' +
        'FORMA_DE_PAGAMENTO FP'
      ''
      ''
      'where'
      ''
      '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and'
      '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and'
      '(REG.CONTA_ID = CT.CONTA_ID) and'
      '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and'
      '(DATA_CADASTRO between :INICIO and :FIM)'
      ''
      'order by REG.DATA_VENCIMENTO')
    Left = 83
    Top = 338
    ParamData = <
      item
        Name = 'INICIO'
        DataType = ftDate
        ParamType = ptInput
        Value = Null
      end
      item
        Name = 'FIM'
        DataType = ftDate
        ParamType = ptInput
      end>
    object FDqryLctoGASTOS_ID: TFDAutoIncField
      FieldName = 'GASTOS_ID'
      Origin = 'GASTOS_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      IdentityInsert = True
    end
    object FDqryLctoCATEGORIA_FK: TIntegerField
      FieldName = 'CATEGORIA_FK'
      Origin = 'CATEGORIA_ID'
      Required = True
    end
    object FDqryLctoSUBCATEGORIA_FK: TIntegerField
      FieldName = 'SUBCATEGORIA_FK'
      Origin = 'SUBCATEGORIA_ID'
      Required = True
    end
    object FDqryLctoCONTA_FK: TIntegerField
      FieldName = 'CONTA_FK'
      Origin = 'CONTA_ID'
      Required = True
    end
    object FDqryLctoLANCAMENTO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      FieldName = 'LANCAMENTO'
      Origin = 'DESCRICAO'
      Size = 200
    end
    object FDqryLctoVALOR_PAGO: TSingleField
      DisplayLabel = 'R$ pago'
      FieldName = 'VALOR_PAGO'
      Origin = 'VALOR_PAGO'
      currency = True
    end
    object FDqryLctoVALOR_PREVISTO: TSingleField
      DisplayLabel = 'R$ previsto'
      FieldName = 'VALOR_PREVISTO'
      Origin = 'VALOR_PREVISTO'
      currency = True
    end
    object FDqryLctoNOTA_FISCAL: TIntegerField
      DisplayLabel = 'NF'
      FieldName = 'NOTA_FISCAL'
      Origin = 'NOTA_FISCAL'
    end
    object FDqryLctoCHEQUE: TIntegerField
      DisplayLabel = 'Cheque'
      FieldName = 'CHEQUE'
      Origin = 'CHEQUE'
    end
    object FDqryLctoCHEQUE_COMPENSADO: TStringField
      DisplayLabel = 'Ch. comp.'
      FieldName = 'CHEQUE_COMPENSADO'
      Origin = 'CHEQUE_COMPENSADO'
      FixedChar = True
      Size = 1
    end
    object FDqryLctoDATA_VENCIMENTO: TDateField
      DisplayLabel = 'Vencimento'
      FieldName = 'DATA_VENCIMENTO'
      Origin = 'DATA_VENCIMENTO'
    end
    object FDqryLctoDATA_PAGAMENTO: TDateField
      DisplayLabel = 'Data pago'
      FieldName = 'DATA_PAGAMENTO'
      Origin = 'DATA_PAGAMENTO'
    end
    object FDqryLctoPAGO: TIntegerField
      FieldName = 'PAGO'
      Origin = 'PAGO'
    end
    object FDqryLctoCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA_ID'
      Origin = 'CATEGORIA_ID'
      ProviderFlags = []
    end
    object FDqryLctoCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Categoria'
      FieldName = 'CATEGORIA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      Size = 100
    end
    object FDqryLctoSUBCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'SUBCATEGORIA_ID'
      Origin = 'SUBCATEGORIA_ID'
      ProviderFlags = []
    end
    object FDqryLctoSUBCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Subcategoria'
      FieldName = 'SUBCATEGORIA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      Size = 100
    end
    object FDqryLctoCONTA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CONTA_ID'
      Origin = 'CONTA_ID'
      ProviderFlags = []
    end
    object FDqryLctoCONTA: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Conta'
      FieldName = 'CONTA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      Size = 50
    end
    object FDqryLctoFORMA_DE_PAGAMENTO_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'FORMA_DE_PAGAMENTO_ID'
      Origin = 'FORMA_DE_PAGAMENTO_ID'
      ProviderFlags = []
    end
    object FDqryLctoFORMA_DE_PAGAMENTO: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Forma Pgto.'
      FieldName = 'FORMA_DE_PAGAMENTO'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      Size = 50
    end
    object FDqryLctoOBS: TStringField
      FieldName = 'OBS'
      Origin = 'OBS'
      Size = 200
    end
    object FDqryLctoDATA_CADASTRO: TDateField
      FieldName = 'DATA_CADASTRO'
      Origin = 'DATA_CADASTRO'
    end
    object FDqryLctoFORMA_DE_PAGAMENTO_FK: TIntegerField
      FieldName = 'FORMA_DE_PAGAMENTO_FK'
      Origin = 'FORMA_DE_PAGAMENTO_ID'
    end
    object FDqryLctoENTRADA_ID: TIntegerField
      DisplayLabel = 'Entrada:'
      FieldName = 'ENTRADA_ID'
      Origin = 'ENTRADA_ID'
    end
    object FDqryLctoSITUACAO_STATUS: TStringField
      DisplayLabel = 'Status:'
      FieldName = 'SITUACAO_STATUS'
      Origin = 'SITUACAO_STATUS'
      Size = 10
    end
    object FDqryLctoUSERID: TIntegerField
      FieldName = 'USERID'
      Origin = 'USERID'
      Required = True
    end
  end
  object dsLcto: TDataSource
    DataSet = FDqryLcto
    Left = 132
    Top = 339
  end
  object FDtcLcto: TFDTransaction
    Options.AutoStop = False
    Connection = frmPrincipal.FDconexao
    Left = 24
    Top = 448
  end
  object dsContas: TDataSource
    DataSet = FDqryContas
    Left = 749
    Top = 394
  end
  object FDqryContas: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcLcto
    UpdateOptions.AssignedValues = [uvGeneratorName]
    UpdateOptions.GeneratorName = 'GEN_CONTAS_ID'
    UpdateOptions.UpdateTableName = 'CONTAS'
    UpdateOptions.KeyFields = 'CONTA_ID'
    SQL.Strings = (
      'select * from CONTAS order by DESCRICAO asc')
    Left = 672
    Top = 392
    object FDqryContasCONTA_ID: TIntegerField
      FieldName = 'CONTA_ID'
      Origin = 'CONTA_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object FDqryContasDESCRICAO: TStringField
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 50
    end
  end
  object FDqryFormaPgto: TFDQuery
    Connection = frmPrincipal.FDconexao
    Transaction = FDtcLcto
    UpdateOptions.AssignedValues = [uvGeneratorName]
    UpdateOptions.GeneratorName = 'GEN_FORMA_DE_PAGAMENTO_ID'
    UpdateOptions.UpdateTableName = 'FORMA_DE_PAGAMENTO'
    UpdateOptions.KeyFields = 'FORMA_DE_PAGAMENTO_ID'
    UpdateOptions.AutoIncFields = 'FORMA_DE_PAGAMENTO_ID'
    SQL.Strings = (
      'select * from FORMA_DE_PAGAMENTO')
    Left = 864
    Top = 394
    object FDqryFormaPgtoFORMA_DE_PAGAMENTO_ID: TIntegerField
      AutoGenerateValue = arAutoInc
      FieldName = 'FORMA_DE_PAGAMENTO_ID'
      Origin = 'FORMA_DE_PAGAMENTO_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
    end
    object FDqryFormaPgtoDESCRICAO: TStringField
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 50
    end
  end
  object dsFormaPgto: TDataSource
    DataSet = FDqryFormaPgto
    Left = 944
    Top = 395
  end
end
