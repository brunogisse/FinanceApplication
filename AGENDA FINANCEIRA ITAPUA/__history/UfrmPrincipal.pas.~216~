unit UfrmPrincipal;

interface

uses
   Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
   System.Classes, Vcl.Graphics,
   Vcl.Controls, Vcl.Forms, Vcl.Dialogs, IniFiles, FireDAC.Stan.Intf,
   FireDAC.Stan.Option, FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf,
   FireDAC.Stan.Def, FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys,
   FireDAC.Phys.FB, FireDAC.Phys.FBDef, FireDAC.VCLUI.Wait, Data.DB,
   FireDAC.Comp.Client, Vcl.ExtCtrls, Vcl.Menus, Vcl.StdCtrls, Vcl.ComCtrls,
   FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
   FireDAC.Comp.DataSet, Vcl.Imaging.pngimage, frxClass, System.Notification,
   Vcl.Imaging.jpeg, Vcl.Buttons;

type
   TfrmPrincipal = class(TForm)
      FDconexao: TFDConnection;
      Panel3: TPanel;
      StatusBarMenu: TStatusBar;
      TimerStatusbar: TTimer;
      FDqryLogin: TFDQuery;
      FDqryLoginLOGIN_ID: TFDAutoIncField;
      FDqryLoginNOME: TStringField;
      FDqryLoginSENHA: TStringField;
      FDqryLoginNIVEL: TIntegerField;
      btnSair: TImage;
      PainelNotificação: TPanel;
      Label4: TLabel;
      NotificationCenterVencimentos: TNotificationCenter;
      FDqryVencimentos: TFDQuery;
      dsVencimentos: TDataSource;
      MainMenu1: TMainMenu;
      Cadastros: TMenuItem;
      Contas: TMenuItem;
      formapgto: TMenuItem;
      DespSub: TMenuItem;
      Mov: TMenuItem;
      lcto: TMenuItem;
      rel: TMenuItem;
      PainelNotification: TPanel;
      labelNotification: TLabel;
      btnAtualizarVencimentos: TBitBtn;
      Sobre: TMenuItem;
      User: TMenuItem;
      Cadastros_Estoque: TMenuItem;
      cadPropriedade: TMenuItem;
      cadDestino: TMenuItem;
      cadFornecedores: TMenuItem;
      cadProdutoEtipo: TMenuItem;
      MovimentacaoEstoque: TMenuItem;
      EntradaDEcompra: TMenuItem;
      Consultas: TMenuItem;
      MovmentacaoEstoque: TMenuItem;
      ConsultaItemEstoque: TMenuItem;
      saidaProduto: TMenuItem;
      RelatorioSaidas: TMenuItem;
      menuBackup: TMenuItem;
    Image1: TImage;
    Timer1: TTimer;
    backupautomtico1: TMenuItem;
      procedure FormCreate(Sender: TObject);
      procedure TimerMenu(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure btnSairClick(Sender: TObject);
      procedure ContasClick(Sender: TObject);
      procedure formapgtoClick(Sender: TObject);
      procedure DespSubClick(Sender: TObject);
      procedure lctoClick(Sender: TObject);
      procedure relClick(Sender: TObject);
      procedure btnAtualizarVencimentosClick(Sender: TObject);
      procedure SobreClick(Sender: TObject);
      procedure UserClick(Sender: TObject);
      procedure cadPropriedadeClick(Sender: TObject);
      procedure cadDestinoClick(Sender: TObject);
      procedure cadFornecedoresClick(Sender: TObject);
      procedure cadProdutoEtipoClick(Sender: TObject);
      procedure EntradaDEcompraClick(Sender: TObject);
      procedure MovmentacaoEstoqueClick(Sender: TObject);
      procedure ConsultaItemEstoqueClick(Sender: TObject);
      procedure saidaProdutoClick(Sender: TObject);
      procedure RelatorioSaidasClick(Sender: TObject);
      procedure menuBackupClick(Sender: TObject);
    procedure backupautomtico1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
   private
      { Private declarations }

      procedure verificarVencimentos;
      procedure abrirTeladeLancamentos;
      procedure verificarVencimentosONSHOW;
      procedure CaminhoBanco;

   public
      { Public declarations }

      AcessoNivel: string;

   end;

var
   frmPrincipal: TfrmPrincipal;

implementation

{$R *.dfm}

uses UcategoriaGeral, Ulogin, UConta, UformaPgto, UfrmLancamentos, Usobre,
   UcadastroUser, Upropriedade, UfrmDestino, UfrmFornecedores, UfrmProduto,
   UfrmEntradaNF, UfrmItensEntrada, UfrmMovProdut, UfrmItensEstoque,
   UfrmSaidaProdutos, UfrmRelatorioSaida, UbackUp;

procedure TfrmPrincipal.verificarVencimentosONSHOW;
var
   qtdVencendo: Integer;
begin
   verificarVencimentos;
   qtdVencendo := FDqryVencimentos.RecordCount;
   if qtdVencendo > 0 then
   begin
      PainelNotification.Visible := True;
      labelNotification.Caption := 'Há ' + IntToStr(qtdVencendo) +
        ' despesa(s) a pagar ';
   end;
end;

procedure TfrmPrincipal.abrirTeladeLancamentos;
begin
   try
      Application.CreateForm(TfrmLancamento, frmLancamento);
      if AcessoNivel <> 'OK' then
      begin
         frmLancamento.gbBotoes.Visible := False;
         frmLancamento.gbSituacaoStatus.Visible := False;
         frmLancamento.btnPagarEmLote.Visible := False;
         frmLancamento.cboxPagarTodas.Visible := False;
      end;
      frmLancamento.ShowModal;
      btnAtualizarVencimentos.Click;
   finally
      FreeAndNil(frmLancamento);
   end;
end;

procedure TfrmPrincipal.verificarVencimentos;
begin
   with FDqryVencimentos do
   begin
      Close;
      ParamByName('VENCIMENTO').AsDate := Now;
      Open;
   end;
end;

procedure TfrmPrincipal.CaminhoBanco;
var
   arquivoINI: TIniFile;
   server, User, password, database, auxError, driver: string;
begin
   if FDconexao.Connected then
      FDconexao.Connected := False;
   arquivoINI := TIniFile.Create(System.SysUtils.ExtractFilePath(ParamStr(0)) +
     '\config.ini');
   server := arquivoINI.ReadString('Sistema', 'Server', '');
   User := arquivoINI.ReadString('Sistema', 'User', '');
   password := arquivoINI.ReadString('Sistema', 'password', '');
   database := arquivoINI.ReadString('Sistema', 'Database', '');
   try
      FDconexao.Params.Strings[0] := 'User_Name=' + User;
      FDconexao.Params.Strings[1] := 'Password=' + password;
      FDconexao.Params.Strings[2] := 'Database=' + database;
      FDconexao.Params.Strings[3] := 'Server=' + server;
      FDconexao.Connected := True;
   except
      on E: exception do
      begin
         auxError := Copy(E.Message, 20, 500);
         MessageDlg('Erro ao tentar se conectar com o banco de dados.' + #13 +
           #13 + 'Sugestão: certifique-se de ter inserido o caminho correto no arquivo Config.INI'
           + #13 + #13 + 'Notificação técnica do erro:' + #13 + #13 + '' +
           auxError, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
         Application.Terminate;
      end;
   end;
end;

procedure TfrmPrincipal.ConsultaItemEstoqueClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmItensEstoque, frmItensEstoque);
      frmItensEstoque.ShowModal;
   finally
      FreeAndNil(frmItensEstoque);
   end;
end;

procedure TfrmPrincipal.ContasClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmConta, frmConta);
      frmConta.ShowModal;
   finally
      FreeAndNil(frmConta);
   end;
end;

procedure TfrmPrincipal.DespSubClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmCategoriaGeral, frmCategoriaGeral);
      frmCategoriaGeral.ShowModal;
   finally
      FreeAndNil(frmCategoriaGeral);
   end;
end;

procedure TfrmPrincipal.EntradaDEcompraClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmEntradaNF, frmEntradaNF);
      frmEntradaNF.ShowModal;
   finally
      FreeAndNil(frmEntradaNF);
   end;
end;

procedure TfrmPrincipal.formapgtoClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmFormapgto, frmFormapgto);
      frmFormapgto.ShowModal;
   finally
      FreeAndNil(frmFormapgto);
   end;
end;

procedure TfrmPrincipal.FormCreate(Sender: TObject);
begin
   CaminhoBanco;

   if (Screen.Width = 800) and (Screen.Height = 600) then
      frmPrincipal.Position := poDefault
   else
      frmPrincipal.Position := poScreenCenter;
end;

procedure TfrmPrincipal.FormShow(Sender: TObject);

begin
   FDqryLogin.Open;
   try
      Application.CreateForm(TfrmLogin, frmLogin);
      frmLogin.ShowModal;
   finally
      FreeAndNil(frmLogin);
   end;

   verificarVencimentosONSHOW;

end;

procedure TfrmPrincipal.backupautomtico1Click(Sender: TObject);
begin
   if Timer1.Enabled = True then
      begin
         Timer1.Enabled := False;
         TMenuItem(Sender).Caption := 'Iniciar Backup Automático';
      end
      else
      begin
         Timer1.Enabled := True;
         TMenuItem(Sender).Caption := 'Pausar Backup Automático';
      end;
end;

procedure TfrmPrincipal.btnAtualizarVencimentosClick(Sender: TObject);
begin
   verificarVencimentosONSHOW;
end;

procedure TfrmPrincipal.btnSairClick(Sender: TObject);
begin
   Close;
end;

procedure TfrmPrincipal.cadDestinoClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmDestino, frmDestino);
      frmDestino.ShowModal;
   finally
      FreeAndNil(frmDestino);
   end;
end;

procedure TfrmPrincipal.cadFornecedoresClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmFornecedor, frmFornecedor);
      frmFornecedor.DuploClickNaGrid := 'MAIN';
      frmFornecedor.ShowModal;
   finally
      FreeAndNil(frmFornecedor);
   end;
end;

procedure TfrmPrincipal.cadProdutoEtipoClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmProdutosTipos, frmProdutosTipos);
      frmProdutosTipos.ShowModal;
   finally
      FreeAndNil(frmProdutosTipos);
   end;
end;

procedure TfrmPrincipal.cadPropriedadeClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmPropriedade, frmPropriedade);
      frmPropriedade.ShowModal;
   finally
      FreeAndNil(frmPropriedade);
   end;
end;

procedure TfrmPrincipal.lctoClick(Sender: TObject);
begin
   abrirTeladeLancamentos;
end;

procedure TfrmPrincipal.menuBackupClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmBackUp, frmBackUp);
      frmBackUp.ShowModal;
   finally
      FreeAndNil(frmBackUp);
   end;
end;

procedure TfrmPrincipal.MovmentacaoEstoqueClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmMoviProduto, frmMoviProduto);
      frmMoviProduto.ShowModal;
   finally
      FreeAndNil(frmMoviProduto);
   end;
end;

procedure TfrmPrincipal.RelatorioSaidasClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmRelatorioSaidas, frmRelatorioSaidas);
      frmRelatorioSaidas.ShowModal;
   finally
      FreeAndNil(frmRelatorioSaidas);
   end;
end;

procedure TfrmPrincipal.relClick(Sender: TObject);
begin
   abrirTeladeLancamentos;
end;

procedure TfrmPrincipal.saidaProdutoClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmSaidaProdutos, frmSaidaProdutos);
      frmSaidaProdutos.ShowModal;
   finally
      FreeAndNil(frmSaidaProdutos);
   end;
end;

procedure TfrmPrincipal.SobreClick(Sender: TObject);
begin

   try
      Application.CreateForm(TfrmSobre, frmSobre);
      frmSobre.ShowModal;
   finally
      FreeAndNil(frmSobre);
   end;

end;

procedure TfrmPrincipal.Timer1Timer(Sender: TObject);
begin
// Caminho em produção - mudar timer para 30000 (backup a cada 5 minutos)
  if not CopyFile(PChar('Y:\Dados\DADOS_14032022_ZERADO.FDB'),
      PChar('C:\Users\Usuario\Desktop\Novo sistema\DADOS_14032022_ZERADO.FDB'), false) then

   // Descomentar para testar no desenvolvimento - colocar timer de 5000 (5 segundos para testes)

  //  if not CopyFile(PChar('C:\PROGRAMAS\V OFICIAL\AGENDA FINANCEIRA ITAPUA\Win32\Debug\Dados\DADOS_14032022_ZERADO.FDB'),
  //       PChar('C:\Users\bruno\OneDrive\Área de Trabalho\DADOS_14032022_ZERADO.FDB'), false) then


      ShowMessage('Erro ao fazer backup');

  //  else
  //  ShowMessage('Arquivo copiado com sucesso!');
end;

procedure TfrmPrincipal.TimerMenu(Sender: TObject);
begin
   StatusBarMenu.Panels[1].Text := 'Data: ' + DateToStr(Date);
   StatusBarMenu.Panels[2].Text := 'Hora: ' + TimeToStr(Time);
end;

procedure TfrmPrincipal.UserClick(Sender: TObject);
begin
   try
      Application.CreateForm(TfrmCadUser, frmCadUser);
      frmCadUser.ShowModal;
   finally
      FreeAndNil(frmCadUser);
   end;
end;

end.
