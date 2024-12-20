﻿object frmPesquisaCategoria: TfrmPesquisaCategoria
  Left = 0
  Top = 0
  Caption = 'frmPesquisaCategoria'
  ClientHeight = 721
  ClientWidth = 985
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
  object PainelPesquisaCategoria: TPanel
    Left = 0
    Top = 0
    Width = 985
    Height = 81
    Align = alTop
    TabOrder = 0
    object labelPesqCategoria: TLabel
      Left = 128
      Top = 7
      Width = 17
      Height = 13
      Caption = 'De:'
    end
    object labelAtéPesCategoria: TLabel
      Left = 242
      Top = 7
      Width = 21
      Height = 13
      Caption = 'At'#233':'
    end
    object btnEscolherCategoria: TBitBtn
      Left = 6
      Top = 7
      Width = 105
      Height = 34
      Caption = 'Escolher Despesa'
      TabOrder = 0
      OnClick = btnEscolherCategoriaClick
    end
    object editRotuloDaCategoria: TEdit
      Left = 6
      Top = 51
      Width = 331
      Height = 21
      Enabled = False
      TabOrder = 1
    end
    object dataDePesquisaCAtegoria: TDateTimePicker
      Left = 128
      Top = 20
      Width = 97
      Height = 21
      Date = 44621.000000000000000000
      Time = 0.796357233797607500
      TabOrder = 2
    end
    object dataAtePesquisaCategoria: TDateTimePicker
      Left = 241
      Top = 20
      Width = 96
      Height = 21
      Date = 44621.000000000000000000
      Time = 0.796469456021441100
      TabOrder = 3
    end
    object btnCategoriaOK: TBitBtn
      Left = 480
      Top = 45
      Width = 74
      Height = 27
      Caption = 'Buscar'
      TabOrder = 4
      OnClick = btnCategoriaOKClick
    end
    object btnImprimir: TBitBtn
      Left = 624
      Top = 45
      Width = 77
      Height = 27
      Caption = 'Imprimir'
      TabOrder = 5
      OnClick = btnImprimirClick
    end
    object gbFiltro: TGroupBox
      Left = 343
      Top = 7
      Width = 130
      Height = 65
      Caption = 'Status do Pagamento: '
      TabOrder = 6
      object rbPago: TRadioButton
        Left = 10
        Top = 17
        Width = 65
        Height = 17
        Caption = 'Pago'
        TabOrder = 0
      end
      object rbNaoPago: TRadioButton
        Left = 10
        Top = 40
        Width = 66
        Height = 17
        Caption = 'N'#227'o Pago'
        TabOrder = 1
      end
    end
  end
  object DBGrid1: TDBGrid
    Left = 0
    Top = 81
    Width = 985
    Height = 335
    Align = alClient
    DataSource = dsPesquisaCategoria
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    OnDblClick = DBGrid1DblClick
    OnMouseWheel = DBGrid1MouseWheel
    Columns = <
      item
        Expanded = False
        FieldName = 'DESCRICAO'
        Width = 341
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CATEGORIA'
        Width = 350
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_PREVISTO'
        Width = 110
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_PAGO'
        Width = 141
        Visible = True
      end>
  end
  object gridSub: TDBGrid
    Left = 0
    Top = 416
    Width = 985
    Height = 256
    Align = alBottom
    DataSource = dsRelatorioSubcategoria
    TabOrder = 2
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -11
    TitleFont.Name = 'Tahoma'
    TitleFont.Style = []
    Visible = False
    Columns = <
      item
        Expanded = False
        FieldName = 'LANCAMENTO'
        Width = 318
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_PREVISTO'
        Width = 92
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'VALOR_PAGO'
        Width = 93
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATA_VENCIMENTO'
        Width = 78
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'DATA_PAGAMENTO'
        Width = 73
        Visible = True
      end
      item
        Expanded = False
        FieldName = 'CONTA'
        Width = 285
        Visible = True
      end>
  end
  object painelRodapeSub: TPanel
    Left = 0
    Top = 672
    Width = 985
    Height = 49
    Align = alBottom
    TabOrder = 3
    object btnImprimirSubdetalhado: TBitBtn
      Left = 672
      Top = 6
      Width = 153
      Height = 35
      Caption = 'Imprimir Detalhamento'
      TabOrder = 0
      Visible = False
      OnClick = btnImprimirSubdetalhadoClick
    end
  end
  object fdqryPesquisaCategoria: TFDQuery
    MasterSource = frmPrincipal.dsVencimentos
    Connection = frmPrincipal.FDconexao
    SQL.Strings = (
      ''
      'select'
      ''
      'S.SUBCATEGORIA_ID, S.DESCRICAO,'
      
        'S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as C' +
        'ATEGORIA, reg.subcategoria_id,'
      
        'sum(reg.valor_previsto) as Valor_previsto, sum(reg.valor_pago) a' +
        's Valor_pago'
      ''
      'from'
      ''
      'SUBCATEGORIA S, CATEGORIA C, registro_de_gastos reg'
      ''
      'where'
      ''
      '(S.CATEGORIA_ID = C.CATEGORIA_ID) and'
      '(C.DESCRICAO = :DESC) and'
      '(reg.data_pagamento between :d1 and :d2) and'
      '(reg.subcategoria_id = s.subcategoria_id)'
      ''
      'group by S.SUBCATEGORIA_ID, S.DESCRICAO,'
      'CATEGORIA_FK, C.CATEGORIA_ID, CATEGORIA, reg.subcategoria_id'
      ''
      'order by s.descricao')
    Left = 296
    Top = 288
    ParamData = <
      item
        Name = 'DESC'
        DataType = ftString
        ParamType = ptInput
        Size = 100
        Value = ''
      end
      item
        Name = 'D1'
        DataType = ftDate
        ParamType = ptInput
        Value = Null
      end
      item
        Name = 'D2'
        DataType = ftDate
        ParamType = ptInput
        Value = Null
      end>
    object fdqryPesquisaCategoriaSUBCATEGORIA_ID: TIntegerField
      FieldName = 'SUBCATEGORIA_ID'
      Origin = 'SUBCATEGORIA_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object fdqryPesquisaCategoriaDESCRICAO: TStringField
      DisplayLabel = 'Descri'#231#227'o'
      FieldName = 'DESCRICAO'
      Origin = 'DESCRICAO'
      Size = 100
    end
    object fdqryPesquisaCategoriaCATEGORIA_FK: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA_FK'
      Origin = 'CATEGORIA_FK'
      ProviderFlags = []
      ReadOnly = True
    end
    object fdqryPesquisaCategoriaCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA_ID'
      Origin = 'CATEGORIA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object fdqryPesquisaCategoriaCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Categoria'
      FieldName = 'CATEGORIA'
      Origin = 'CATEGORIA'
      ProviderFlags = []
      ReadOnly = True
      Size = 100
    end
    object fdqryPesquisaCategoriaSUBCATEGORIA_ID_1: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'SUBCATEGORIA_ID_1'
      Origin = 'SUBCATEGORIA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object fdqryPesquisaCategoriaVALOR_PREVISTO: TFloatField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Valor Previsto'
      FieldName = 'VALOR_PREVISTO'
      Origin = 'VALOR_PREVISTO'
      ProviderFlags = []
      ReadOnly = True
      currency = True
    end
    object fdqryPesquisaCategoriaVALOR_PAGO: TFloatField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Valor Pago'
      FieldName = 'VALOR_PAGO'
      Origin = 'VALOR_PAGO'
      ProviderFlags = []
      ReadOnly = True
      currency = True
    end
  end
  object dsPesquisaCategoria: TDataSource
    DataSet = fdqryPesquisaCategoria
    Left = 416
    Top = 296
  end
  object reportPesquisaCategoria: TfrxReport
    Version = '6.7.6'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick, pbCopy, pbSelection]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Default'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.CreateDate = 44622.539484143500000000
    ReportOptions.LastChange = 44633.737715347200000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      ''
      'end.')
    Left = 288
    Top = 200
    Datasets = <
      item
        DataSet = dtsReportPesquisaCategoria
        DataSetName = 'frxDBDataset1'
      end>
    Variables = <
      item
        Name = ' Datas'
        Value = Null
      end
      item
        Name = 'DataInicio'
        Value = ''
      end
      item
        Name = 'DataFim'
        Value = ''
      end
      item
        Name = ' Strings'
        Value = Null
      end
      item
        Name = 'Despesa'
        Value = ''
      end>
    Style = <>
    object Data: TfrxDataPage
      Height = 1000.000000000000000000
      Width = 1000.000000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
      object ReportTitle1: TfrxReportTitle
        FillType = ftBrush
        Frame.Typ = []
        Height = 86.929190000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 2.692950000000000000
          Top = 2.779530000000000000
          Width = 321.260050000000000000
          Height = 30.236240000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -20
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Relat'#243'rio de Despesa/Subdespesa')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        Frame.Typ = []
        Height = 71.811070000000000000
        Top = 128.504020000000000000
        Width = 718.110700000000000000
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 46.338590000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Subdespesa:')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 8.322820000000000000
          Top = -3.779530000000000000
          Width = 71.811070000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Despesa:')
          ParentFont = False
        end
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 418.102660000000000000
          Top = 46.338590000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'R$ Previsto:')
          ParentFont = False
        end
        object Line1: TfrxLineView
          AllowVectorExport = True
          Left = 1.559060000000000000
          Top = 67.795300000000000000
          Width = 718.110700000000000000
          Color = clBlack
          Frame.Typ = []
          Diagonal = True
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 566.842920000000000000
          Top = 47.338590000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'R$ Pago:')
          ParentFont = False
        end
        object Memo9: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 23.118120000000000000
          Width = 177.637910000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Relat'#243'rio gerado entre as datas:')
          ParentFont = False
        end
        object DataInicio: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 186.551330000000000000
          Top = 24.118120000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DataInicio]')
          ParentFont = False
        end
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 256.260050000000000000
          Top = 22.677180000000000000
          Width = 11.338590000000000000
          Height = 18.897650000000000000
          Frame.Typ = []
          Memo.UTF8W = (
            'e')
        end
        object DataFim: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 271.937230000000000000
          Top = 24.118120000000000000
          Width = 79.370130000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DataFim]')
          ParentFont = False
        end
        object Despesa: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 75.385900000000000000
          Top = -3.779530000000000000
          Width = 627.401980000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -15
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Despesa]')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Frame.Typ = []
        Height = 22.677180000000000000
        Top = 260.787570000000000000
        Width = 718.110700000000000000
        DataSet = dtsReportPesquisaCategoria
        DataSetName = 'frxDBDataset1'
        RowCount = 0
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 9.118120000000000000
          Top = 1.559060000000000000
          Width = 404.409710000000000000
          Height = 18.897650000000000000
          DataField = 'DESCRICAO'
          DataSet = dtsReportPesquisaCategoria
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."DESCRICAO"]')
          ParentFont = False
        end
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 418.016080000000000000
          Top = 2.338590000000000000
          Width = 147.401670000000000000
          Height = 18.897650000000000000
          DataField = 'VALOR_PREVISTO'
          DataSet = dtsReportPesquisaCategoria
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -12
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."VALOR_PREVISTO"]')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 567.063390000000000000
          Top = 1.000000000000000000
          Width = 147.401670000000000000
          Height = 18.897650000000000000
          DataField = 'VALOR_PAGO'
          DataSet = dtsReportPesquisaCategoria
          DataSetName = 'frxDBDataset1'
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."VALOR_PAGO"]')
        end
      end
      object ReportSummary1: TfrxReportSummary
        FillType = ftBrush
        Frame.Typ = []
        Height = 147.401670000000000000
        Top = 343.937230000000000000
        Width = 718.110700000000000000
        object TotalDespesa: TfrxMemoView
          AllowVectorExport = True
          Left = 146.149660000000000000
          Top = 32.338590000000000000
          Width = 563.149970000000000000
          Height = 34.015770000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -17
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[SUM(<frxDBDataset1."VALOR_PREVISTO">,MasterData1,3)]')
          ParentFont = False
          Formats = <
            item
              FormatStr = 'R$ %2.2n'
              Kind = fkNumeric
            end
            item
            end>
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 31.338590000000000000
          Width = 132.283550000000000000
          Height = 26.456710000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -17
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Previsto:')
          ParentFont = False
        end
        object Line2: TfrxLineView
          AllowVectorExport = True
          Left = 0.779530000000000000
          Top = 11.338590000000000000
          Width = 714.331170000000000000
          Color = clBlack
          Frame.Typ = []
          Diagonal = True
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 7.559060000000000000
          Top = 83.370130000000000000
          Width = 132.283550000000000000
          Height = 26.456710000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -20
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Pago:')
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          AllowVectorExport = True
          Left = 147.401670000000000000
          Top = 83.149660000000000000
          Width = 551.811380000000000000
          Height = 34.015770000000000000
          DisplayFormat.FormatStr = 'R$ %2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -20
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[SUM(<frxDBDataset1."VALOR_PAGO">,MasterData1,3)]')
          ParentFont = False
        end
      end
    end
  end
  object dtsReportPesquisaCategoria: TfrxDBDataset
    UserName = 'frxDBDataset1'
    CloseDataSource = False
    DataSet = fdqryPesquisaCategoria
    BCDToCurrency = False
    Left = 400
    Top = 200
  end
  object qryRelatorioSubcategoria: TFDQuery
    Connection = frmPrincipal.FDconexao
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
      'REG.OBS, REG.DATA_CADASTRO'
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
    Left = 136
    Top = 536
    ParamData = <
      item
        Name = 'INICIO'
        DataType = ftString
        ParamType = ptInput
        Value = '01/01/2020'
      end
      item
        Name = 'FIM'
        DataType = ftDate
        ParamType = ptInput
        Value = 44168d
      end>
    object qryRelatorioSubcategoriaGASTOS_ID: TIntegerField
      FieldName = 'GASTOS_ID'
      Origin = 'GASTOS_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      Required = True
    end
    object qryRelatorioSubcategoriaCATEGORIA_FK: TIntegerField
      FieldName = 'CATEGORIA_FK'
      Origin = 'CATEGORIA_ID'
      Required = True
    end
    object qryRelatorioSubcategoriaSUBCATEGORIA_FK: TIntegerField
      FieldName = 'SUBCATEGORIA_FK'
      Origin = 'SUBCATEGORIA_ID'
      Required = True
    end
    object qryRelatorioSubcategoriaCONTA_FK: TIntegerField
      FieldName = 'CONTA_FK'
      Origin = 'CONTA_ID'
      Required = True
    end
    object qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO_FK: TIntegerField
      FieldName = 'FORMA_DE_PAGAMENTO_FK'
      Origin = 'FORMA_DE_PAGAMENTO_ID'
      Required = True
    end
    object qryRelatorioSubcategoriaLANCAMENTO: TStringField
      DisplayLabel = 'Lan'#231'amento'
      FieldName = 'LANCAMENTO'
      Origin = 'DESCRICAO'
      Size = 200
    end
    object qryRelatorioSubcategoriaVALOR_PAGO: TSingleField
      DisplayLabel = 'Valor Pago'
      FieldName = 'VALOR_PAGO'
      Origin = 'VALOR_PAGO'
      currency = True
    end
    object qryRelatorioSubcategoriaVALOR_PREVISTO: TSingleField
      DisplayLabel = 'Valor Previsto'
      FieldName = 'VALOR_PREVISTO'
      Origin = 'VALOR_PREVISTO'
      currency = True
    end
    object qryRelatorioSubcategoriaNOTA_FISCAL: TIntegerField
      FieldName = 'NOTA_FISCAL'
      Origin = 'NOTA_FISCAL'
    end
    object qryRelatorioSubcategoriaCHEQUE: TIntegerField
      FieldName = 'CHEQUE'
      Origin = 'CHEQUE'
    end
    object qryRelatorioSubcategoriaCHEQUE_COMPENSADO: TStringField
      FieldName = 'CHEQUE_COMPENSADO'
      Origin = 'CHEQUE_COMPENSADO'
      FixedChar = True
      Size = 1
    end
    object qryRelatorioSubcategoriaDATA_VENCIMENTO: TDateField
      DisplayLabel = 'Data Venc.'
      FieldName = 'DATA_VENCIMENTO'
      Origin = 'DATA_VENCIMENTO'
    end
    object qryRelatorioSubcategoriaDATA_PAGAMENTO: TDateField
      DisplayLabel = 'Data Pgto.'
      FieldName = 'DATA_PAGAMENTO'
      Origin = 'DATA_PAGAMENTO'
    end
    object qryRelatorioSubcategoriaPAGO: TIntegerField
      FieldName = 'PAGO'
      Origin = 'PAGO'
    end
    object qryRelatorioSubcategoriaENTRADA_ID: TIntegerField
      FieldName = 'ENTRADA_ID'
      Origin = 'ENTRADA_ID'
    end
    object qryRelatorioSubcategoriaSITUACAO_STATUS: TStringField
      FieldName = 'SITUACAO_STATUS'
      Origin = 'SITUACAO_STATUS'
      Size = 10
    end
    object qryRelatorioSubcategoriaCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA_ID'
      Origin = 'CATEGORIA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object qryRelatorioSubcategoriaCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      FieldName = 'CATEGORIA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 100
    end
    object qryRelatorioSubcategoriaSUBCATEGORIA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'SUBCATEGORIA_ID'
      Origin = 'SUBCATEGORIA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object qryRelatorioSubcategoriaSUBCATEGORIA: TStringField
      AutoGenerateValue = arDefault
      FieldName = 'SUBCATEGORIA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 100
    end
    object qryRelatorioSubcategoriaCONTA_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'CONTA_ID'
      Origin = 'CONTA_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object qryRelatorioSubcategoriaCONTA: TStringField
      AutoGenerateValue = arDefault
      DisplayLabel = 'Conta'
      FieldName = 'CONTA'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 50
    end
    object qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO_ID: TIntegerField
      AutoGenerateValue = arDefault
      FieldName = 'FORMA_DE_PAGAMENTO_ID'
      Origin = 'FORMA_DE_PAGAMENTO_ID'
      ProviderFlags = []
      ReadOnly = True
    end
    object qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO: TStringField
      AutoGenerateValue = arDefault
      FieldName = 'FORMA_DE_PAGAMENTO'
      Origin = 'DESCRICAO'
      ProviderFlags = []
      ReadOnly = True
      Size = 50
    end
    object qryRelatorioSubcategoriaOBS: TStringField
      FieldName = 'OBS'
      Origin = 'OBS'
      Size = 200
    end
    object qryRelatorioSubcategoriaDATA_CADASTRO: TDateField
      FieldName = 'DATA_CADASTRO'
      Origin = 'DATA_CADASTRO'
    end
  end
  object dsRelatorioSubcategoria: TDataSource
    DataSet = qryRelatorioSubcategoria
    Left = 288
    Top = 536
  end
  object dsSubcategoriaRel: TfrxDBDataset
    UserName = 'frxDBDataset1'
    CloseDataSource = False
    DataSet = qryRelatorioSubcategoria
    BCDToCurrency = False
    Left = 248
    Top = 608
  end
  object reportSubcategoria: TfrxReport
    Version = '6.7.6'
    DotMatrixReport = False
    IniFile = '\Software\Fast Reports'
    PreviewOptions.Buttons = [pbPrint, pbLoad, pbSave, pbExport, pbZoom, pbFind, pbOutline, pbPageSetup, pbTools, pbEdit, pbNavigator, pbExportQuick, pbCopy, pbSelection]
    PreviewOptions.Zoom = 1.000000000000000000
    PrintOptions.Printer = 'Default'
    PrintOptions.PrintOnSheet = 0
    ReportOptions.CreateDate = 44633.627179976900000000
    ReportOptions.LastChange = 44639.361812962960000000
    ScriptLanguage = 'PascalScript'
    ScriptText.Strings = (
      'begin'
      ''
      'end.')
    Left = 136
    Top = 608
    Datasets = <
      item
        DataSet = dsSubcategoriaRel
        DataSetName = 'frxDBDataset1'
      end>
    Variables = <
      item
        Name = ' Var Datas'
        Value = Null
      end
      item
        Name = 'DataInicio'
        Value = ''
      end
      item
        Name = 'DataFim'
        Value = ''
      end
      item
        Name = ' Var strings'
        Value = Null
      end
      item
        Name = 'Despesa'
        Value = ''
      end>
    Style = <>
    object Data: TfrxDataPage
      Height = 1000.000000000000000000
      Width = 1000.000000000000000000
    end
    object Page1: TfrxReportPage
      PaperWidth = 210.000000000000000000
      PaperHeight = 297.000000000000000000
      PaperSize = 9
      LeftMargin = 10.000000000000000000
      RightMargin = 10.000000000000000000
      TopMargin = 10.000000000000000000
      BottomMargin = 10.000000000000000000
      Frame.Typ = []
      MirrorMode = []
      object ReportTitle1: TfrxReportTitle
        FillType = ftBrush
        Frame.Typ = []
        Height = 79.370130000000000000
        Top = 18.897650000000000000
        Width = 718.110700000000000000
        object Memo23: TfrxMemoView
          AllowVectorExport = True
          Left = 117.165430000000000000
          Top = 18.897650000000000000
          Width = 551.811380000000000000
          Height = 56.692950000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -27
          Font.Name = 'verdana'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Relat'#243'rio detalhado de subdespesas')
          ParentFont = False
        end
      end
      object PageHeader1: TfrxPageHeader
        FillType = ftBrush
        Frame.Typ = []
        Height = 83.149660000000000000
        Top = 120.944960000000000000
        Width = 718.110700000000000000
        object Memo1: TfrxMemoView
          AllowVectorExport = True
          Left = 3.779530000000000000
          Top = 56.913420000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Lan'#231'amentos:')
          ParentFont = False
        end
        object Memo2: TfrxMemoView
          AllowVectorExport = True
          Left = 505.984540000000000000
          Top = 58.133890000000000000
          Width = 64.252010000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Previsto:')
          ParentFont = False
        end
        object Memo3: TfrxMemoView
          AllowVectorExport = True
          Left = 620.165740000000000000
          Top = 58.913420000000000000
          Width = 52.913420000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Pago:')
          ParentFont = False
        end
        object Line1: TfrxLineView
          AllowVectorExport = True
          Left = 1.559060000000000000
          Top = 77.031540000000000000
          Width = 714.331170000000000000
          Color = clBlack
          Frame.Typ = [ftTop]
        end
        object Memo24: TfrxMemoView
          AllowVectorExport = True
          Left = 4.338590000000000000
          Top = 22.779530000000000000
          Width = 162.519790000000000000
          Height = 15.118120000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'verdana'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Relat'#243'rio gerado entre as datas:')
          ParentFont = False
        end
        object DataInicio: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 3.779530000000000000
          Top = 38.456710000000000000
          Width = 60.472480000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'verdana'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DataInicio]')
          ParentFont = False
        end
        object DataFim: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 69.708720000000000000
          Top = 38.236240000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'verdana'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[DataFim]')
          ParentFont = False
        end
        object Despesa: TfrxMemoView
          IndexTag = 1
          AllowVectorExport = True
          Left = 73.185398713195260000
          Top = 1.000000000000000000
          Width = 636.161541286804800000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[Despesa]')
          ParentFont = False
        end
        object Memo25: TfrxMemoView
          AllowVectorExport = True
          Left = 3.527520000000000000
          Width = 67.450967950000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'verdana'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Despesa:')
          ParentFont = False
        end
      end
      object MasterData1: TfrxMasterData
        FillType = ftBrush
        Frame.Typ = []
        Height = 83.960730000000000000
        Top = 264.567100000000000000
        Width = 718.110700000000000000
        DataSet = dsSubcategoriaRel
        DataSetName = 'frxDBDataset1'
        RowCount = 0
        object Memo4: TfrxMemoView
          AllowVectorExport = True
          Left = 5.118120000000000000
          Top = 4.338590000000000000
          Width = 699.213050000000000000
          Height = 18.897650000000000000
          DataField = 'LANCAMENTO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'verdana'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."LANCAMENTO"]')
          ParentFont = False
        end
        object Memo5: TfrxMemoView
          AllowVectorExport = True
          Left = 6.118120000000000000
          Top = 27.574830000000000000
          Width = 18.897650000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'NF:')
          ParentFont = False
        end
        object Memo6: TfrxMemoView
          AllowVectorExport = True
          Left = 26.692950000000000000
          Top = 26.574830000000000000
          Width = 56.692950000000000000
          Height = 15.118120000000000000
          DataField = 'NOTA_FISCAL'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."NOTA_FISCAL"]')
          ParentFont = False
        end
        object Memo7: TfrxMemoView
          AllowVectorExport = True
          Left = 7.118120000000000000
          Top = 51.370130000000000000
          Width = 60.472480000000000000
          Height = 11.338590000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Subdespesa:')
          ParentFont = False
        end
        object Memo8: TfrxMemoView
          AllowVectorExport = True
          Left = 6.118120000000000000
          Top = 64.826840000000000000
          Width = 702.992580000000000000
          Height = 18.897650000000000000
          DataField = 'SUBCATEGORIA'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."SUBCATEGORIA"]')
          ParentFont = False
        end
        object Memo9: TfrxMemoView
          AllowVectorExport = True
          Left = 309.953000000000000000
          Top = 27.913420000000000000
          Width = 45.354360000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '| Cheque:')
          ParentFont = False
        end
        object Memo10: TfrxMemoView
          AllowVectorExport = True
          Left = 349.866420000000000000
          Top = 28.456710000000000000
          Width = 52.913420000000000000
          Height = 15.118120000000000000
          DataField = 'CHEQUE'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."CHEQUE"]')
          ParentFont = False
        end
        object Memo11: TfrxMemoView
          AllowVectorExport = True
          Left = 403.575140000000000000
          Top = 28.015770000000000000
          Width = 68.031540000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Compensa'#231#227'o:')
          ParentFont = False
        end
        object Memo12: TfrxMemoView
          AllowVectorExport = True
          Left = 470.181510000000000000
          Top = 27.574830000000000000
          Width = 22.677180000000000000
          Height = 18.897650000000000000
          DataField = 'CHEQUE_COMPENSADO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."CHEQUE_COMPENSADO"]')
          ParentFont = False
        end
        object Memo13: TfrxMemoView
          AllowVectorExport = True
          Left = 91.078850000000000000
          Top = 27.236240000000000000
          Width = 34.015770000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            'Conta:')
          ParentFont = False
        end
        object Memo14: TfrxMemoView
          AllowVectorExport = True
          Left = 122.330860000000000000
          Top = 27.015770000000000000
          Width = 185.196970000000000000
          Height = 18.897650000000000000
          DataField = 'CONTA'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."CONTA"]')
          ParentFont = False
        end
        object Memo15: TfrxMemoView
          AllowVectorExport = True
          Left = 509.354670000000000000
          Top = 39.779530000000000000
          Width = 102.047310000000000000
          Height = 18.897650000000000000
          DataField = 'VALOR_PREVISTO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."VALOR_PREVISTO"]')
          ParentFont = False
        end
        object Memo16: TfrxMemoView
          AllowVectorExport = True
          Left = 618.622450000000000000
          Top = 38.826840000000000000
          Width = 94.488250000000000000
          Height = 18.897650000000000000
          DataField = 'VALOR_PAGO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."VALOR_PAGO"]')
          ParentFont = False
        end
        object Memo17: TfrxMemoView
          AllowVectorExport = True
          Left = 508.236550000000000000
          Top = 24.929190000000000000
          Width = 94.488250000000000000
          Height = 15.118120000000000000
          DataField = 'DATA_VENCIMENTO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."DATA_VENCIMENTO"]')
          ParentFont = False
        end
        object Memo18: TfrxMemoView
          AllowVectorExport = True
          Left = 620.622450000000000000
          Top = 24.149660000000000000
          Width = 94.488250000000000000
          Height = 15.118120000000000000
          DataField = 'DATA_PAGAMENTO'
          DataSet = dsSubcategoriaRel
          DataSetName = 'frxDBDataset1'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -9
          Font.Name = 'Arial'
          Font.Style = []
          Frame.Typ = []
          Memo.UTF8W = (
            '[frxDBDataset1."DATA_PAGAMENTO"]')
          ParentFont = False
        end
        object Line2: TfrxLineView
          AllowVectorExport = True
          Left = 1.779530000000000000
          Top = 83.960730000000000000
          Width = 714.331170000000000000
          Color = clBlack
          Frame.Typ = [ftTop]
        end
      end
      object ReportSummary1: TfrxReportSummary
        FillType = ftBrush
        Frame.Typ = []
        Height = 98.267780000000000000
        Top = 408.189240000000000000
        Width = 718.110700000000000000
        object Memo19: TfrxMemoView
          AllowVectorExport = True
          Left = 6.118120000000000000
          Top = 30.677180000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Previsto:')
          ParentFont = False
        end
        object Memo20: TfrxMemoView
          AllowVectorExport = True
          Left = 8.118120000000000000
          Top = 61.472480000000000000
          Width = 98.267780000000000000
          Height = 18.897650000000000000
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            'Total Pago:')
          ParentFont = False
        end
        object Memo21: TfrxMemoView
          AllowVectorExport = True
          Left = 109.606370000000000000
          Top = 31.338590000000000000
          Width = 585.827150000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = 'R$ %2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[SUM(<frxDBDataset1."VALOR_PREVISTO">,MasterData1,3)]')
          ParentFont = False
        end
        object Memo22: TfrxMemoView
          AllowVectorExport = True
          Left = 109.606370000000000000
          Top = 62.574830000000000000
          Width = 585.827150000000000000
          Height = 18.897650000000000000
          DisplayFormat.FormatStr = 'R$ %2.2n'
          DisplayFormat.Kind = fkNumeric
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -13
          Font.Name = 'Arial'
          Font.Style = [fsBold]
          Frame.Typ = []
          Memo.UTF8W = (
            '[SUM(<frxDBDataset1."VALOR_PAGO">,MasterData1,3)]')
          ParentFont = False
        end
      end
      object PageFooter1: TfrxPageFooter
        FillType = ftBrush
        Frame.Typ = []
        Height = 30.236240000000000000
        Top = 529.134200000000000000
        Width = 718.110700000000000000
      end
    end
  end
end
