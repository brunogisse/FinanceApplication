unit UConta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.Grids, Vcl.DBGrids,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls, Vcl.Imaging.pngimage,
  Vcl.Buttons;

type
  TfrmConta = class(TForm)
    FDtcConta: TFDTransaction;
    FDqryConta: TFDQuery;
    dsConta: TDataSource;
    FDqryContaCONTA_ID: TIntegerField;
    FDqryContaDESCRICAO: TStringField;
    gridContas: TDBGrid;
    Panel1: TPanel;
    btnNovo: TImage;
    editContas: TDBEdit;
    labelConta: TLabel;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    Image1: TImage;
    procedure btnNovoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BitBtn1Click(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure editContasKeyPress(Sender: TObject; var Key: Char);
    procedure gridContasDblClick(Sender: TObject);
    procedure gridContasCellClick(Column: TColumn);
  private
    { Private declarations }

    procedure configurarEnables(status : integer);
    procedure salvarRegistro;
    procedure alterarRegistro;
    procedure novoRegistro;
  public
    { Public declarations }

    var Pesquisa : string;

  end;

var
  frmConta: TfrmConta;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmLancamentos;

procedure TfrmConta.novoRegistro;
begin
  configurarEnables(1);
  editContas.SetFocus;
  FDqryConta.Insert;
end;


procedure TfrmConta.alterarRegistro;
begin
  FDqryConta.Edit;
  configurarEnables(1);
end;


procedure TfrmConta.salvarRegistro;
begin
  FDqryConta.Post;
 try
   // FDqryConta.Transaction.StartTransaction;
    FDtcConta.Commit;
except
    FDtcConta.RollbackRetaining;
end;
end;


procedure TfrmConta.configurarEnables(status : integer);
begin
    if status = 0 then
    begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editContas.Enabled := False;
    end
   else
    begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editContas.Enabled := True;
    end;
end;


procedure TfrmConta.editContasKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = #13 then
    begin
      salvarRegistro;
      novoRegistro;
      Key := #0;
    end;
end;

procedure TfrmConta.BitBtn1Click(Sender: TObject);
begin
FDqryConta.Insert;
end;

procedure TfrmConta.btnNovoClick(Sender: TObject);
begin
 novoRegistro;
end;

procedure TfrmConta.btnAlterarClick(Sender: TObject);
begin
alterarRegistro;
end;

procedure TfrmConta.btnCancelarClick(Sender: TObject);
begin
FDqryConta.Cancel;
configurarEnables(0);
end;

procedure TfrmConta.btnSalvarClick(Sender: TObject);
begin
configurarEnables(0);
salvarRegistro;
end;

procedure TfrmConta.FormClose(Sender: TObject; var Action: TCloseAction);
begin
FDqryConta.Close;
Pesquisa := 'n�o';
end;

procedure TfrmConta.FormShow(Sender: TObject);
begin
FDqryConta.Open;
configurarEnables(0);
end;

procedure TfrmConta.gridContasCellClick(Column: TColumn);
begin
FDqryConta.Cancel;
configurarEnables(0);
end;

procedure TfrmConta.gridContasDblClick(Sender: TObject);
begin

    if Pesquisa = 'pesquisando' then
    begin
    frmLancamento.editContaPesq.Text := FDqryConta['DESCRICAO'];
    frmLancamento.editContaPesq.Enabled := False;
    Close;
    end
   else
    begin
     if MessageBox(Application.Handle,'Deseja alterar essa conta?','Confirma��o',MB_YESNO + MB_ICONQUESTION) = mrYes then
        alterarRegistro;
    end;
end;

procedure TfrmConta.Image1Click(Sender: TObject);
begin
Close;
end;

procedure TfrmConta.btnExcluirClick(Sender: TObject);
 var AuxErro : string;
begin
  configurarEnables(0);
 if MessageBox(Application.Handle,'Deseja excluir essa conta?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
     try
      FDqryConta.Delete;
     except
      on E : exception do
       begin
        AuxErro := copy (E.Message,20,25);
        ShowMessage(AuxErro);
       end;
     end;
    end;
end;
end.
