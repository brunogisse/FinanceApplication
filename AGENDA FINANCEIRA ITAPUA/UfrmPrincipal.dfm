﻿object frmPrincipal: TfrmPrincipal
  Left = 0
  Top = 0
  Caption = 'Agenda financeira | Raul Luiz Juliatti de Carvalho'
  ClientHeight = 605
  ClientWidth = 1299
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel3: TPanel
    Left = 1090
    Top = 0
    Width = 209
    Height = 586
    Align = alRight
    Color = 7171382
    ParentBackground = False
    TabOrder = 0
    object btnSair: TImage
      Left = 109
      Top = 17
      Width = 52
      Height = 50
      Cursor = crHandPoint
      Hint = 'Sair'
      ParentCustomHint = False
      ParentShowHint = False
      Picture.Data = {
        0954506E67496D61676589504E470D0A1A0A0000000D49484452000000300000
        003008060000005702F9870000000473424954080808087C0864880000000970
        48597300000B1300000B1301009A9C18000001DC4944415478DAED9A4D2B0551
        18C7CF5DD8B1F252220B59A364E165E73310B2900F204B16B85EB250CA279085
        5CB7ECA5C89688944FA02CE4FA0294EBFF343399C6CCDC7BC7739EE79EDC7FFD
        1677CEEDF4FFCD34A7337572E627FD60194C80769033F59777700976C0A30995
        9C0587A049BB6195F9040BE08804E8CEDF39543E2C314C02C76046BB4DC61449
        E015746837C99812097C99DF2FEC1EB8D66E17C918588A5EA4E2E5983F4F8253
        EDC6914C834243A021E090400F787655601C9C196F35CBBB2610946FF67F6F30
        49880844CB07E190B02E4073DD83C184F1BF4A883C816E7005FA2C48240A70C7
        968498802D0951011B12E202DC122A029C128902127B9E4E309A325E8D444DCB
        A8462A49D4BD4025092704F2BE84930269E553054E04CA75196FA397B57CAA80
        EDD0870D2DA3BD09E3EB60B38A795404B8CAAB0870961717A8547E0D6CD538A7
        98808DF2A9029C1F34B6CA8B08D05C0F6020617C156C672C2F22401901E7A085
        B9BC98409C0447795181B0C42E537971010A6D1F5E98CAAB0870A721A09DFF25
        B00F6EB41B47422BDB62E45A99044AA055BB5DC6BC9140114C6937C9980209D0
        DEE5D6B877D4E0030C05DBE93970E09004959F37FE1308424F62C578C76DDAB4
        1BC684161B7A5F2F8C77DCE6892E7E0349FFA3888DF15AF50000000049454E44
        AE426082}
      ShowHint = True
      OnClick = btnSairClick
    end
    object PainelNotificação: TPanel
      Left = 1
      Top = 472
      Width = 207
      Height = 0
      Align = alBottom
      TabOrder = 0
      object Label4: TLabel
        Left = 40
        Top = 48
        Width = 31
        Height = 13
        Caption = 'Label4'
      end
    end
    object PainelNotification: TPanel
      Left = 1
      Top = 472
      Width = 207
      Height = 113
      Align = alBottom
      TabOrder = 1
      Visible = False
      object labelNotification: TLabel
        Left = 16
        Top = 45
        Width = 80
        Height = 13
        Caption = 'Notifica'#231#245'es'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object btnAtualizarVencimentos: TBitBtn
        Left = 128
        Top = 147
        Width = 75
        Height = 25
        Caption = 'Atualizar'
        Font.Charset = ANSI_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Verdana'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnAtualizarVencimentosClick
      end
    end
  end
  object StatusBarMenu: TStatusBar
    Left = 0
    Top = 586
    Width = 1299
    Height = 19
    Panels = <
      item
        Alignment = taCenter
        Text = 'Login'
        Width = 450
      end
      item
        Alignment = taCenter
        Text = 'Data'
        Width = 160
      end
      item
        Alignment = taCenter
        Text = 'Hora'
        Width = 100
      end>
  end
  object FDconexao: TFDConnection
    Params.Strings = (
      'User_Name=SYSDBA'
      'Password=masterkey'
      'Server=localhost'
      
        'Database=C:\PROGRAMAS\V OFICIAL\AGENDA FINANCEIRA ITAPUA\Win32\D' +
        'ebug\Dados\DADOS_14032022_ZERADO.FDB'
      'DriverID=FB')
    UpdateOptions.AssignedValues = [uvGeneratorName]
    LoginPrompt = False
    Left = 33
    Top = 32
  end
  object TimerStatusbar: TTimer
    OnTimer = TimerMenu
    Left = 24
    Top = 544
  end
  object FDqryLogin: TFDQuery
    Connection = FDconexao
    UpdateOptions.AssignedValues = [uvGeneratorName]
    UpdateOptions.GeneratorName = 'GEN_LOGIN_ID'
    UpdateOptions.UpdateTableName = 'LOGIN'
    UpdateOptions.KeyFields = 'LOGIN_ID'
    UpdateOptions.AutoIncFields = 'LOGIN_ID'
    SQL.Strings = (
      'select * from LOGIN')
    Left = 33
    Top = 96
    object FDqryLoginLOGIN_ID: TFDAutoIncField
      FieldName = 'LOGIN_ID'
      Origin = 'LOGIN_ID'
      ProviderFlags = [pfInUpdate, pfInWhere, pfInKey]
      IdentityInsert = True
    end
    object FDqryLoginNOME: TStringField
      FieldName = 'NOME'
      Origin = 'NOME'
      Required = True
    end
    object FDqryLoginSENHA: TStringField
      FieldName = 'SENHA'
      Origin = 'SENHA'
      Required = True
    end
    object FDqryLoginNIVEL: TIntegerField
      FieldName = 'NIVEL'
      Origin = 'NIVEL'
      Required = True
    end
  end
  object NotificationCenterVencimentos: TNotificationCenter
    Left = 632
    Top = 520
  end
  object FDqryVencimentos: TFDQuery
    Connection = FDconexao
    SQL.Strings = (
      'select * from REGISTRO_DE_GASTOS '
      ''
      'where'
      ''
      '(DATA_VENCIMENTO <= :VENCIMENTO) AND (PAGO = 0)')
    Left = 33
    Top = 160
    ParamData = <
      item
        Name = 'VENCIMENTO'
        DataType = ftString
        ParamType = ptInput
        Value = '08/06/2020'
      end>
  end
  object dsVencimentos: TDataSource
    DataSet = FDqryVencimentos
    Left = 136
    Top = 168
  end
  object MainMenu1: TMainMenu
    Left = 568
    Top = 8
    object Cadastros: TMenuItem
      Caption = 'Cadastros | Financeiro'
      object Contas: TMenuItem
        Caption = 'Contas'
        OnClick = ContasClick
      end
      object formapgto: TMenuItem
        Caption = 'Forma de pagamento'
        OnClick = formapgtoClick
      end
      object DespSub: TMenuItem
        Caption = 'Despesas e Subdespesas'
        OnClick = DespSubClick
      end
    end
    object Mov: TMenuItem
      Caption = 'Movimenta'#231#227'o'
      object lcto: TMenuItem
        Caption = 'Lan'#231'amentos'
        OnClick = lctoClick
      end
      object rel: TMenuItem
        Caption = 'Relat'#243'rios'
        OnClick = relClick
      end
      object menuBackup: TMenuItem
        Caption = 'BackUp'
        OnClick = menuBackupClick
      end
    end
    object Sobre: TMenuItem
      Caption = 'Sobre'
      OnClick = SobreClick
    end
    object User: TMenuItem
      Caption = 'Cadastrar usu'#225'rio'
      Visible = False
      OnClick = UserClick
    end
    object Cadastros_Estoque: TMenuItem
      Caption = 'Cadastros | Estoque'
      object cadPropriedade: TMenuItem
        Caption = 'Propriedades'
        OnClick = cadPropriedadeClick
      end
      object cadDestino: TMenuItem
        Caption = 'Destino'
        OnClick = cadDestinoClick
      end
      object cadFornecedores: TMenuItem
        Caption = 'Fornecedores'
        OnClick = cadFornecedoresClick
      end
      object cadProdutoEtipo: TMenuItem
        Caption = 'Produtos e Tipos'
        OnClick = cadProdutoEtipoClick
      end
    end
    object MovimentacaoEstoque: TMenuItem
      Caption = 'Movimenta'#231#227'o de Estoque'
      object EntradaDEcompra: TMenuItem
        Caption = 'Entrada de Compra'
        OnClick = EntradaDEcompraClick
      end
      object saidaProduto: TMenuItem
        Caption = 'Sa'#237'da de Produtos - baixa estoque'
        OnClick = saidaProdutoClick
      end
    end
    object Consultas: TMenuItem
      Caption = 'Consultas [Estoque]'
      object MovmentacaoEstoque: TMenuItem
        Caption = 'Movimenta'#231#227'o de Estoque'
        OnClick = MovmentacaoEstoqueClick
      end
      object ConsultaItemEstoque: TMenuItem
        Caption = 'Item Estoque'
        OnClick = ConsultaItemEstoqueClick
      end
      object RelatorioSaidas: TMenuItem
        Caption = 'Relat'#243'rio de Sa'#237'das'
        OnClick = RelatorioSaidasClick
      end
    end
  end
end
