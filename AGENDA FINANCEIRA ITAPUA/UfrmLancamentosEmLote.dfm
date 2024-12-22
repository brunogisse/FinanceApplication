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
  Position = poDesktopCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 15
  object pnlGeral: TPanel
    Left = 0
    Top = 0
    Width = 1212
    Height = 569
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitWidth = 1206
    ExplicitHeight = 563
    object pnlTopo: TPanel
      Left = 0
      Top = 0
      Width = 1212
      Height = 167
      Align = alTop
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitWidth = 1206
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
      OnCellClick = gridLoteCellClick
      OnDrawColumnCell = gridLoteDrawColumnCell
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
      end
      item
        Name = 'ATIVO'
        DataType = ftBoolean
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
    object cldsPlanilhaLoteATIVO: TBooleanField
      DisplayLabel = '[]'
      DisplayWidth = 2
      FieldKind = fkInternalCalc
      FieldName = 'ATIVO'
      OnChange = cldsPlanilhaLoteATIVOChange
    end
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
    Height = 20
    Width = 20
    PngImages = <
      item
        Background = clWindow
        Name = 'unchecked16'
        PngImage.Data = {
          89504E470D0A1A0A0000000D4948445200000014000000140803000000BA57ED
          3F0000017A504C544515163E0F0E3E17193E17193F18193F2E2F4013143E0000
          001C203F1B1D3E23263EAAAAE222244B0D0D3218183E18193E18183F1A1B3D1C
          1F3F17183F0F0F3D17193E17193F18193F18193F17193F17193E18193F18193F
          18193F18193F18193F18193F16183E17193F17193D1F2148434771474B754B4F
          7A2A2C53191A4018194018193F18193F202249A2ABDEA0A9DBA0A9DBA1AADC8D
          95C52728505D628F62669303022618193E17173D7D84B29FA8DA6F76A333365F
          12133918193F17193E575C879FA9DB14153A18193F18193F474A7414153A2A2C
          5318193F191A4025264E8B93C317193E16173D1E2047838ABA22244B15163C16
          173D191B412A2C5323244B17183E16183D14153B14143A17183F9FA8DAA0A9DB
          9098C92A2C549098C82A2C536E75A230325A30325B292B526E74A2939BCC3B3E
          67757CAA9DA6D88B93C32E3058A1AADC969FD04C517B7B82B02F325A9199CA7A
          81B026284F7279A7282A514649732E31595E638F6F75A37379A730335B2E3158
          FFFFFFACE4FA1D0000005B74524E530000000000000000000000000000000000
          0000000022545C5B521DC1DDD6D5DEB718552E121B1C1A43E34453C30F61C2C7
          C6CCF9991B0514350CC3F6D0443D9215C75A5DD81C5942B6E4F9FE1671FADDF0
          5316B8FBF0C01C505921AE89001000000001624B47447DA6B110C90000000970
          48597300000B1300000B1301009A9C180000000774494D4507E70B0C0F170183
          4BFC0E000000E04944415478DA9DD13B6B024110C0F1FDEFEDDDC54712F111C4
          46AC9418F201D25808D67E56AB5427E40B8410144308885A08BEAA40085E36A3
          F13CA39D03CBEEFE9861965914122A0A6B1DB9817F19ABD5AC08153AE7C5999B
          AAD1C51AA71C9A7DEA1665992AFC4318705D93AD12977FC02BE6414EA508A537
          C3274C0366F503D4E300937713C973D0E5E70493F03D394275C567FA5D30E7C7
          98D9BCBD1FE0DC78B5595DFF61566C29E5BA780FF91DAA02BDBBE700D734E196
          E9D64CE145A6D3C1335F6DA84E77032DBDD15DE02BC76FC122EA9F4A3CAE04AD
          0D0F3F24C3FC176FAF38847127A1860000002574455874646174653A63726561
          746500323032332D31312D31325431353A32323A35312B30303A3030B549A0C5
          0000002574455874646174653A6D6F6469667900323032332D31312D31325431
          353A32323A35312B30303A3030C41418790000002874455874646174653A7469
          6D657374616D7000323032332D31312D31325431353A32333A30312B30303A30
          3034235CFC0000000049454E44AE426082}
      end
      item
        Background = clWindow
        Name = 'checked16'
        PngImage.Data = {
          89504E470D0A1A0A0000000D49484452000000140000001408060000008D891D
          0D00000006624B474400FF00FF00FFA0BDA793000000097048597300000B1300
          000B1301009A9C180000000774494D4507E70B0C0F171B7E290574000004D049
          44415478DA7D540B704C5718FEEEDD47362FF290CD6E64E31595483C4A50241B
          62BC422A3AD20A55548D8A61A29DAA562B26958CB66254756A3C43A53374AA3A
          6A3C826C1EAA13B12445329E615443D95D92CDF6DEBBF79EFEF70AA54CCFCED9
          73EE7FFEFF3BE7FFFEEF1C0E2F68D1D1A9005300DE0070645014701C4DA8071A
          7928F4BB71A3F245A19AFB33CD6C4E45B039063EF73D30590E220F464E3E4574
          137E98C127CA12F3F378F8B0FAFF01CD663B9D8A81D7F3609A85C573E0D6D244
          4F86ADE499487313F914D14945D587DC610AD2A1D52DC2EDAEF90F60B41DCCCF
          789D91EF4E7E21B4B098CC298CB1461A4752F4039A97DCBD5B53161931CCA637
          06843270B70C06CE653002CD571DCF025AADE95018C6134D5FD2A7515D53FCFE
          65338A4B6A65495A27CBFEEA21D9A3BE3FB5F7E82447E9968F5BEFDF33298A72
          5A51E43C9D5EEFFA70FF112C1D6A0267B68C844F68418829564DB5808032A9AF
          EA141575277DC69CC6E431E3E6528AEBC9E6614CB9EC17C4A4BBCDD7421A8E1D
          A93A77E4A0ADB3C5F2C6CDDFEB9DED52A356382E2E660A24D64675F347D271D7
          D3AEA10B37EF5A11196B2B50643992809255461E67C2EB745ABF7ECED9BAFF8B
          D5FA4113271FEF9B9EB1F0AF9BCDB7F6157F062EDA6257FD7A12FA461A7B883E
          DF2705C76AEE30859DA06FC3BFE5E34014E09AB30EC6C040987BF484A3742B01
          9F81D0EE2D6CBE7CB4B04BD4109900D355F7C9E4BF9D29CABC1D2D55872ED589
          F3788EFF9A2830B00E0D4AA280D33FEFC3D94307303C271783325F85E86B47F9
          E66F70DE71DC199BD0776C98C5EAEA006456FADB131C16DEB864D75E81889E75
          A3FE6C584844249DA41705FAF0EB9E325CACAEC088D7672079F458E88D46785A
          6EE3C7E25548189EE625FB069DC1B09AB358D3544105900476844474B12CDA56
          1640F21851BE7923FE686AC498790BB4B1E1D8618C9AFD0E1253D3B5F4D553B7
          5CB9A4018E9DBF087D46A41E90156526176DD5524EA382EC96046171A1E354B0
          2448A55EB7DB5851BA05D7CFD66945B0BF3917FDC68C7BA4E60E4E6549C4C1AF
          D6C2EBF1B4652E7E3FD7EB71FDF298C3345A2FA3AA1E9E595CE2E93EE0E57C0A
          3090D6A0824675EB8EA1D9D3C0F37A951E0D8FD4802BB5A77072CF6E5066C2C4
          454BF32E54956F27C034D5C9C071BA0904B872E0F8CC4113F2F22956AF05FA05
          E189549E4887E771E7FA55FCB4A610B149FD307CDA74845BBB3A68AFD73A00D5
          0C78D06D288889EFB320A7A0E8EFA04E9D7B3C0DF27493493ECDF54E1CDFB609
          D9CB3E8535BEB7936C2544C70FDAD55379E4D534803C32AC08B7C6B40F9E34A5
          574AD654DA87D7F4A78E6A212E5655E00275AFDB451C4A98FAD1CAD6285BB72C
          49922A39F6D45D56054EDF914C9173ACF12FBD327ACEFC5971C903F86BCED338
          7FA21C9DA32DB0517A8E9D5B61E9D51B115D6DE89A90886EFD073E200AEC54AB
          069E1EBA278016AB5D2B60527A06728B0ACC82176F5FAC742456ECDC32950042
          DB5CF7E1BA7D0B969EBD3139FF03048747FC466115C4BB8B02B7D1DC9D3FCCF4
          FC03BBBE56D02AF967D3257CFE567FD3F4E5DFCD4EC9CA2E6EF7786ED6971F3A
          D9D79E91D1C51617465ACDA5E04A307A3F39597BB8F287063C0FB8AEAE8D8C0A
          F2078722EBDD0D786FD31253C319FF048351DF94D70F4DDF9EC700D127DA28B9
          A39490A8F02244046379CA23A87F0065B50DBE6A28421E000000257445587464
          6174653A63726561746500323032332D31312D31325431353A32333A32332B30
          303A3030C7D1D3CB0000002574455874646174653A6D6F646966790032303233
          2D31312D31325431353A32333A32332B30303A3030B68C6B7700000028744558
          74646174653A74696D657374616D7000323032332D31312D31325431353A3233
          3A32372B30303A303015D66EBB0000000049454E44AE426082}
      end>
    Left = 464
    Top = 320
  end
end
