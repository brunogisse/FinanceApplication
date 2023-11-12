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
      Height = 167
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      object lblQuantidade: TLabel
        Left = 5
        Top = 136
        Width = 327
        Height = 24
        Caption = 'Quantidade de registros importados: '
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -20
        Font.Name = 'Roboto'
        Font.Style = []
        ParentFont = False
      end
      object gbSelecao: TGroupBox
        Left = 544
        Top = 8
        Width = 609
        Height = 127
        Caption = '  Selecione conta e a categoria do lote que ser'#225' lan'#231'ado  '
        TabOrder = 0
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
          Height = 15
          Caption = 'Conta:'
        end
        object Label1: TLabel
          Left = 221
          Top = 64
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
          Width = 196
          Height = 23
          BevelInner = bvNone
          Color = 15395562
          DataField = 'DESCRICAO'
          DataSource = dsContas
          TabOrder = 1
        end
        object btnSalvar: TBitBtn
          Left = 449
          Top = 71
          Width = 119
          Height = 39
          Caption = 'Iniciar lan'#231'amento'
          TabOrder = 2
          OnClick = btnSalvarClick
        end
        object cmbFormaPgto: TDBComboBox
          Left = 221
          Top = 79
          Width = 196
          Height = 23
          BevelInner = bvNone
          Color = 15395562
          DataField = 'DESCRICAO'
          DataSource = dsFormaPgto
          TabOrder = 3
        end
      end
      object GroupBox1: TGroupBox
        Left = 0
        Top = 8
        Width = 545
        Height = 127
        Caption = 'GroupBox1'
        TabOrder = 1
        object labelBanco: TLabel
          Left = 16
          Top = 23
          Width = 97
          Height = 15
          Caption = 'Escolher planilha'
        end
        object btnPlanilha: TSpeedButton
          Left = 423
          Top = 39
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
        object btnCarregarPlanilha: TSpeedButton
          Left = 16
          Top = 77
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
          Top = 77
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
        object editCaminhoPlanilha: TEdit
          Left = 16
          Top = 39
          Width = 401
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
    end
    object gridLote: TDBGrid
      Left = 0
      Top = 166
      Width = 1212
      Height = 403
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
      'select * from FORMA_DE_PAGAMENTO order by DESCRICAO asc')
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
  object imgTipoPg: TPngImageList
    Height = 48
    Width = 48
    PngImages = <
      item
        Background = clWindow
        Name = 'checked48'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
          87000000097048597300000B1300000B1301009A9C18000009A94944415478DA
          ED5A09509447167EFD0333C3009E09CC408C219258A21515E488BAA0C6ACC683
          281A5DE37AE049560C87220415359AC49BA0AC8AD1280B1601312A586675D715
          4477515434AE95B81EC4A899194C7901C3FDF7BEFEE7E01F986118C4D254E555
          C9FCDDFDBAFFF7F5F1BDF7FA97C06F5CC8F336E07700CFDB80DF01B4C3189C42
          119C4001E6E168322C1F059E5FA5D114961A14DCDCFEE049389208943C914A21
          EEF6ED82EA1706809B32683501B24C5C47296809D0446767794A4585368202F9
          941090EB1B67A8D5A7FEF6420070751DFC3A6767F7233E3A585029C77F2EA272
          1D021884008A5F08006ECAE0341C60BABE78128D8BC3DFAF8090BECD9429BD8C
          7FE7B6A7F13600F075502A9D67F200FDB0600FC2CC528A9DA371083BA6D140F8
          41F77F29FC37D375533A45130A7311881750B84E09DDA5515526015CA8138FEA
          EE1ED4BF81C2781C836D2FB652F578964ACA54B017A0A0BE9D00F83A2814CEF9
          A839D0A20A853CB5BA20445CB5B9B87AE2C33B775E7DC9DD6B57642079D2B4CB
          D4A874E5C99C3DA57C4383B4F962D1331A75E5D0A680DB04C055193C8763DBC2
          92ED144A64521886CCF2C850977CAE761E059AAAC30677F1EF82687F59AEA13D
          E95C75488DB66ADBB659533C6AABAA2CCC093F47A32ADCFDD4009065B623CB84
          EBADDD836C52845BA9132B72402F01684FAB5417B406FDD4F354AEE56B6FE2C0
          0A5383E00821FC314AB911D83686D5A96F5E87D24B1781AFAF2F3F7F687F4255
          65A50F6EBB309D3EDDAE519DFA4B3B00084E258CE38551F970B5BA30B525FD2F
          8BAA970047D6591BB7F98CD325EB424694A345DBF5805335AA82F0F600B00995
          62F46F89C5BDBED1D0B6F542A53BA9A77C0375D23EA8026D1779F5704A48360E
          EB626D5C3310CAF725C466DFB9FAFD6C5692B938EF589499BD7AA1AFD32F4F05
          00BDEC5AD48AD3CF4A02CECA17C24C9FADD98FF5136D37D4B2FC27E71B2848FF
          5A780E0C9D0C4366CC662B938DE767B2CD00148AA1DD29E113D0A3CE4235469D
          C003FD6399EAD43F369FAF5072BC438B33D316292DB900592B3FD119C671D0F3
          EDC110342D0C3A79B8BAC70C7056B51600870777151E5C36EB460FCBD8862315
          83D9817D5600EA6AAA21233E0634B76E18EBECECED412A9727DDBA96B7589843
          6B00148AA0A5C8046B4C2A91E731089B6EA0CA75A7A98B5452DB8CDB5B2B8FCB
          CA202F692DDCBF5D0A63A3E3C1CB2FC0D8565359816DEBE146715113131AB76F
          8B00DC14C13F235576D377CB27C02D53A9F2CF887556FC974A3A6B6B6BDA62FC
          4F974BE0F0C6CFA1EAC963A1FC46C0409890B0B299DEBD1FAE42C1BE3DF0F395
          EFF500E86DA4D5D75A03E00102E8ACEFE587AC73BEA94EF2D9AA919470DFD96A
          FCF9DC83F0AF3DA9186DEB760267EF00A1F1CB710502CDEAAB6FFC0FF62E8AD0
          9942E9AF1AF5A997AD03100568D8E992464DFC0C7189CE49D52CC0F6E5B65265
          D1B759909FD6E8585DBA74857168BC474F6FB3FA186208C69795DE14CAEE6FF6
          BC307F536AD0FC01442BD66B068085C884B3BB6288DF290F4B349A820D49676B
          E6A2F22AECA1B4C5708AB37D3C35054AFE7EC458E7D1AB378C8F4B04E7CE9D2D
          F63BFBED7E3899A68B601CA43298BD25153AB929557816564407488DA18D591A
          C583BC080FB2CE616134199F7B0CB98DE48875EAEB6A217B550232C64D089E1A
          063EA343CC1A726CFB1613E3D97619B76429D84BA4D092A486CF84872A1DD10D
          0B9B07FEE3442E87D2D0A800D9418B00BCBDBD250F1EBE7C1F1F3BB0F2DC945D
          B15DBBBDBA41AC73F7C7AB9011176D2CF70E1A06A3231709FBDA20CC2931E764
          D419F20E8C5AB848A0C696841DF0E4691F08CF52B91344A6679B8C8BDE3E3CDA
          4F92DAD20AC4E00A6C32AC40D4917C3F195F7B95ADBE78053297C6C2BD6B3F18
          FB79F6F785894B3F053B0707283E7C004E7CDD183631E3C744C60A0EAA35225E
          817766CD07BFF727189AEE557392DEF103C863B300F409F8156C72D2D94FE390
          BED66F2EAA1ECD71E48858B7A1AE0EFEB97B07947C9767ACEB337438F41A3C04
          723E4B14F6BF61DB847EB20230FD6C95F14C8A0E6643FEDE5DC2B3838C9D819D
          78061438261D1F1D283B64D06B9185581AA856930106164A3A5793670885C572
          E69B0C28CC6CCCD3D91669A8D72554DD7ABF0593577E6675CF3715C64269310B
          40F3D32DFDC4BCCB56302F2A406A72D86CF2035F16574500E5B69A7B21639A8B
          47734DEA3ABABAC28C8D2920EFD8C926E30DA2BA7E0DD2162F149E1D3B748485
          E9591131FE8E7FB50640E489E124E6BACB74B9AE1081E6628FB196662C67CD72
          B87551879751DF9FD76E06B7D7BDDA643C2389C28CBD70FBCA65E3647CB433C3
          FA0A60F8BC0C6B579B54622C1496BC2DC3CDD32BABA597D6682BE1C0E72B046A
          1D8D6CF3264693B68AA5582878DA2C787BE29FAC9F01B0108DBED4FDB5BA191B
          B638B0997D5652575D0DE9F1D146EFCB849DA7C0099361F094E9488C82B9F708
          2FF1365C14D8940F4C5EF50578F6F37D6600D8F663CE51304C940F74517A98E8
          59F503A6401A3332C3323E2B31979199156B9E582CE29C38686A58F9C04953DA
          90EFB64EC4F10F0B1D580861623706A8F827D16A2CD40480F156422677FC386A
          DF2147E06059DB12F79685C54C2C7662D26FE41818F9D1C706D3CB31175BE368
          2F4DB11A8D3607D0FC5EE895DE7DFD7B0CF09BEDD9D707DC7ABCD1266359FA78
          179396B2D252215F953AC985B0E4CA89E3427BFFF7C6C288709D0F203C3F2232
          D0F1B8B9719EEA664EE2E808117B32F1576E93F18C2AF7611C25669BA6326A61
          0CBC357CA4F0ECC8492438F366AF195B71371A6CEFA6C0D4929041B602A82A7F
          028E2E1D9AD5E7AC496CC6F36279C5BB0F7CB866833176B2974B5C22FA908A36
          02D08370A7D391BF1887DAA351BCCF7B63C27B060E6AB68598473E977B002E1F
          3B2A44939D95EED077C428F00F992018240EC339A44ADFB1E3057E6777A4AC5D
          D1C34B887BC4819F3DAD53460438AB9F0280A958BA5661779D47B76E36BB355C
          3D7BC0A8886838B9F72B637820046851B156DFC7737536DD0BB54A92CE5567E1
          E19E6428B3C02B3D3E06F8FAC6ADCAB6566D95D66C7FE661E7A4ECC615B292A1
          529A859C6FD1F93CD5171AB612ECB7169CB45BC6BD1BCA37D4095E88851B4153
          6780CFA81021423DB52F4D601DB10C9CF421EACC145B5A4E29FDE0915676C2D1
          059C2450291C2C4B33DF2E00C4D2BD7BB0ACA686AE77EFD96B60C8E2045F967C
          18E491460DA733D331542816B2351FA4C8C0D049A6D9194FE3A20265EB6D7D6F
          BB7F27B6E5FB80A84D2DE7243D9A3AA9E70280495271ED7C42E90E7DF11E2174
          41A49FECB0A13DB9B8FA7D4A094B4C3C744690F991FE929D6D79D733FB52CFBE
          9111E0BA720D0E99E6BE912517D10EBC5DDD1442F95FA3FC6507DAFA9EDFFC7F
          35F83FACDFFA5E2F5820EB0000000049454E44AE426082}
      end
      item
        Background = clWindow
        Name = 'unchecked48'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000300000003008060000005702F9
          87000000097048597300000B1300000B1301009A9C180000030F4944415478DA
          EDD96F4813611800F0E7DDA6B3FC508E853BB58290024129D20A8A5DFF240984
          A03282FA52D81F946823FF948244466A921F32428AFA501FC4FA207D08FA43B4
          4150390812FCE067EB3626A320D36DB7BD3D776D6BCD5BDCAD6ED7D53D70ECBD
          7707F7FC8EF7B9DBEE21A0F3205A276000B44E4025006B2965A81B074D404935
          2150A87622944204089DC4E1588023D7003C7C8E00D6E260E833FC6ABBDA4967
          C500F52062B71CC4224029E3EC2040FAB44A3E0DD111E0BC03B9007C08D8288C
          E340BBEC25B38353535311B513AEAAAA2A0C85EC6D40486F02E043409D728083
          0D27D7BCAD2468CD47F2C9A8AC6CB07E999B5F1001581301BFC7AA18E060589A
          1CFB394FDEEF524ACF2F1B30F2E8C3D282AF730338710877ED6A01CEBB9A53E3
          2B43B7868B4D45ED4D4DABE695003EE207831B8780B2E4FC9DD1E9613CB845AD
          C4B30084A574FDD8E1B567E4031C4EA1708EE276CFEFF74E24E7EF8E4E0741C5
          2B9F0D808220CEDDC665E1C2648730A70BBF04640B0450B9C7FE510046E7D9E6
          887063912AEC45808A8A2D4B78BE6893C5B2F07666E6756AED6909489FCB2C6C
          89E7002B1CE1C46CBD01CEC3EA0E80451C4FCC533CD8A44780E46DD400180003
          60000C80013000FF03A0EBDC4988C7E260329BE0F2E088FE00E30FEFC39B571E
          D8BC95857D078EE80F204434128682C21F3FFB7507C80C5D01386E0626DFF9A0
          7A432D304C85FE007D173BE0F3A7102C5B6E83CE9E7EFD017EFF2F65963773F9
          00C4781EBADB4E8B63B3D902BD8337730030CE0902A456DCA1B4DB669BBD2A20
          D406C4623C785F3C81A78FC7C5FDF295ABA1D5DD9D13A01D01FD6A262B271A1A
          F703BBB3413920D1DC788E0816348A3595EBE0F829B7F834CE019042081D9A83
          40494D3E3A34C29A77949543CDFA3AD8C6D6A79217DFCCB94FAC5008F839D20B
          5B282CE164F98A48387CA3A7B3B5E5BB45C69B3949405A61EFDAD338B7A37E6F
          B1EA08BCF2D168F8C1A52E5730CAF33DE29444D3432EE0AF286CA9B693CC97BB
          DA1736A6FFD2CF91FACCC69F820E4CFE0B3BD17A7D0F71321608C09054D7F25F
          6D74EB270C80D6F10D71EE384FCD07547C0000000049454E44AE426082}
      end>
    Left = 464
    Top = 320
  end
end
