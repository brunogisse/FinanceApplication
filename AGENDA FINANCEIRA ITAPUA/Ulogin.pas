unit Ulogin;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Buttons,
  Vcl.Mask, Vcl.DBCtrls;

type
  TfrmLogin = class(TForm)
    FDqryLogin: TFDQuery;
    Label1: TLabel;
    dsLogin: TDataSource;
    Label2: TLabel;
    btnLogar: TBitBtn;
    btnCancelar: TBitBtn;
    edtLogin: TEdit;
    edtSenha: TEdit;
    FDqryLoginLOGIN_ID: TFDAutoIncField;
    FDqryLoginNOME: TStringField;
    FDqryLoginSENHA: TStringField;
    FDqryLoginNIVEL: TIntegerField;
    procedure edtLoginExit(Sender: TObject);
    procedure btnLogarClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelarClick(Sender: TObject);
    procedure edtSenhaKeyPress(Sender: TObject; var Key: Char);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }

    procedure validarNivel;

  public
    { Public declarations }

    acesso: string;
  end;

var
  frmLogin: TfrmLogin;

  nivel: integer;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmLancamentos;

procedure TfrmLogin.validarNivel;
begin
  if FDqryLogin['NIVEL'] < 2 then

  begin
    frmPrincipal.Cadastros.Visible := False;
    frmPrincipal.lcto.Visible := False;
    frmPrincipal.User.Visible := False;
    frmPrincipal.AcessoNivel := 'restrito';
  end
  else
  begin
    frmPrincipal.AcessoNivel := 'OK';
    if FDqryLogin['NIVEL'] = 3 then
      frmPrincipal.User.Visible := True;
  end;
end;

procedure TfrmLogin.btnCancelarClick(Sender: TObject);
begin
  frmLogin.Close;
end;

procedure TfrmLogin.btnLogarClick(Sender: TObject);
begin
  if edtSenha.Text = FDqryLogin['SENHA'] then
  begin
    showmessage('Bem vindo(a) ' + FDqryLogin['NOME']);
    acesso := 'Aceito';
    nivel := FDqryLogin['NIVEL'];
    validarNivel;
    frmPrincipal.StatusBarMenu.Panels[0].Text := 'Login atual: ' + FDqryLogin
      ['NOME'] + ' | Par�metro de acesso [' + IntToStr(nivel) + ']';
    frmPrincipal.FDqryLogin.Locate('LOGIN_ID', FDqryLogin['LOGIN_ID'], []);

    if (FDqryLogin['LOGIN_ID'] <> 1) then
    begin
      frmPrincipal.Timer1.Enabled := False;
      frmPrincipal.backupautomtico1.Visible := False;
      frmPrincipal.menuBackup.Visible := False;
    end
    else
      frmPrincipal.Timer1.Enabled := True;

    frmPrincipal.backupautomtico1.Caption := 'Pausar Backup Autom�tico';
    frmLogin.Close;
  end
  else
  begin
    showmessage('Senha inv�lida');
    application.Terminate;
  end;
end;

procedure TfrmLogin.edtLoginExit(Sender: TObject);
begin
  FDqryLogin.Open;
  if edtLogin.Text <> '' then
  begin
    if not FDqryLogin.Locate('NOME', edtLogin.Text, [loCaseInsensitive]) then
    begin
      showmessage('Usu�rio n�o encontrado');
      edtLogin.Clear;
      edtLogin.SetFocus;
    end;
  end;

end;

procedure TfrmLogin.edtSenhaKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    btnLogar.Click;
    Key := #0;
  end;
end;

procedure TfrmLogin.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if acesso <> 'Aceito' then
    application.Terminate;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  edtLogin.SetFocus;
end;

end.
