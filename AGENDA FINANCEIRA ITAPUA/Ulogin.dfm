object frmLogin: TfrmLogin
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Tela de Acesso'
  ClientHeight = 269
  ClientWidth = 393
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
  object Label1: TLabel
    Left = 104
    Top = 72
    Width = 25
    Height = 13
    Caption = 'Login'
  end
  object Label2: TLabel
    Left = 104
    Top = 115
    Width = 30
    Height = 13
    Caption = 'Senha'
  end
  object btnLogar: TBitBtn
    Left = 104
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Logar'
    TabOrder = 0
    OnClick = btnLogarClick
  end
  object btnCancelar: TBitBtn
    Left = 198
    Top = 176
    Width = 75
    Height = 25
    Caption = 'Cancelar'
    TabOrder = 1
    OnClick = btnCancelarClick
  end
  object edtLogin: TEdit
    Left = 104
    Top = 88
    Width = 169
    Height = 21
    TabOrder = 2
    OnExit = edtLoginExit
  end
  object edtSenha: TEdit
    Left = 104
    Top = 134
    Width = 169
    Height = 21
    PasswordChar = '*'
    TabOrder = 3
    OnKeyPress = edtSenhaKeyPress
  end
  object FDqryLogin: TFDQuery
    Connection = frmPrincipal.FDconexao
    UpdateOptions.AssignedValues = [uvGeneratorName, uvAutoCommitUpdates]
    UpdateOptions.GeneratorName = 'GEN_LOGIN_ID'
    UpdateOptions.UpdateTableName = 'LOGIN'
    UpdateOptions.KeyFields = 'LOGIN_ID'
    UpdateOptions.AutoIncFields = 'LOGIN_ID'
    SQL.Strings = (
      'select * from LOGIN')
    Left = 248
    Top = 40
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
  object dsLogin: TDataSource
    DataSet = FDqryLogin
    Left = 303
    Top = 41
  end
end
