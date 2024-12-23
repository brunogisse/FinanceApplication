unit UformaPgto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, Vcl.Imaging.pngimage, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.Client, FireDAC.Comp.DataSet;

type
  TfrmFormapgto = class(TForm)
    painelTopofpgto: TPanel;
    gridFormapgto: TDBGrid;
    btnNovo: TImage;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    btnSair: TImage;
    editFormapgto: TDBEdit;
    FDqryFormapgto: TFDQuery;
    FDtcFormapgto: TFDTransaction;
    dsFormapgto: TDataSource;
    FDqryFormapgtoFORMA_DE_PAGAMENTO_ID: TIntegerField;
    FDqryFormapgtoDESCRICAO: TStringField;
    procedure btnNovoClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure gridFormapgtoCellClick(Column: TColumn);
    procedure editFormapgtoKeyPress(Sender: TObject; var Key: Char);
    procedure gridFormapgtoDblClick(Sender: TObject);
  private
    { Private declarations }

    procedure configurarEnables(status : integer);
    procedure novoRegistro;
    procedure salvarRegistro;
    procedure alterarRegistro;

  public
    { Public declarations }
  end;

var
  frmFormapgto: TfrmFormapgto;

implementation

{$R *.dfm}

uses UfrmPrincipal;


procedure TfrmFormapgto.alterarRegistro;
begin
  if MessageBox(Application.Handle,'Deseja realmente alterar esta forma de pagamento','Confirma��o',MB_YESNO + MB_ICONQUESTION) = mrYes then
     begin
      FDqryFormapgto.Edit;
      configurarEnables(1);
      editFormapgto.SetFocus;
     end;
end;


procedure TfrmFormapgto.salvarRegistro;
begin
     configurarEnables(0);
     FDqryFormapgto.Post;
   try
     FDtcFormapgto.CommitRetaining;
   except
     FDtcFormapgto.RollbackRetaining;
   end;
end;


procedure TfrmFormapgto.novoRegistro;
begin
    configurarEnables(1);
    editFormapgto.SetFocus;
    FDqryFormapgto.Insert;
end;


procedure TfrmFormapgto.configurarEnables(status : integer);
begin
    if status = 0 then
    begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editFormapgto.Enabled := False;

    end
   else if status = 1 then
    begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editFormapgto.Enabled := True;
    end;
end;


procedure TfrmFormapgto.editFormapgtoKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = #13 then
   begin
     novoRegistro;
     Key := #0;
   end;
end;

procedure TfrmFormapgto.btnAlterarClick(Sender: TObject);
begin
 alterarRegistro;
end;

procedure TfrmFormapgto.btnCancelarClick(Sender: TObject);
begin
 FDqryFormapgto.Cancel;
 configurarEnables(0);
end;

procedure TfrmFormapgto.btnExcluirClick(Sender: TObject);
  var auxErro : string;
begin
 if MessageBox(Application.Handle,'Deseja realmente excluir esta forma de pagamento?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
      try
        FDqryFormapgto.Delete;
       except
         on E : exception do
         begin
           auxErro := copy (E.Message,0,43);
           MessageDlg('N�o � poss�vel excluir o registro no momento.' +#13
          +#13+ 'Este registro est� sendo referenciado em outra tabela. '+#13
          +#13+ 'Para mais informa��es, pesquise sobre a ocorr�ncia: ' + AuxErro, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
         end;
      end;
    end;
end;

procedure TfrmFormapgto.btnNovoClick(Sender: TObject);
var sim : string;
begin
novoRegistro;
end;

procedure TfrmFormapgto.btnSairClick(Sender: TObject);
begin
Close;
end;

procedure TfrmFormapgto.btnSalvarClick(Sender: TObject);
begin
 salvarRegistro;
end;

procedure TfrmFormapgto.FormClose(Sender: TObject; var Action: TCloseAction);
begin
FDqryFormapgto.Close;
end;

procedure TfrmFormapgto.FormShow(Sender: TObject);
begin
FDqryFormapgto.Open;
configurarEnables(0);
end;

procedure TfrmFormapgto.gridFormapgtoCellClick(Column: TColumn);
begin
 FDqryFormapgto.Cancel;
 configurarEnables(0);
end;

procedure TfrmFormapgto.gridFormapgtoDblClick(Sender: TObject);
begin
alterarRegistro;
end;

end.
