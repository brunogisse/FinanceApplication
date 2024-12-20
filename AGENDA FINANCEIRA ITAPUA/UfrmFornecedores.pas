unit UfrmFornecedores;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Data.DB, Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls;

type
  TfrmFornecedor = class(TForm)
    PainelTopo: TPanel;
    btnNovo: TImage;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    Image1: TImage;
    gridFornecedores: TDBGrid;
    dsFornecedores: TDataSource;
    FDtcFornecedores: TFDTransaction;
    FDqryFornecedores: TFDQuery;
    FDqryFornecedoresFORNECEDOR_ID: TIntegerField;
    FDqryFornecedoresCNPJ: TStringField;
    FDqryFornecedoresTELEFONE: TStringField;
    labelDescricao: TLabel;
    editNomeFantasia: TDBEdit;
    labelCNPJ: TLabel;
    editCNPJ: TDBEdit;
    labelTelefone: TLabel;
    editTelefone: TDBEdit;
    FDqryFornecedoresNOME_FANTASIA: TStringField;
    FDqryFornecedoresRAZAO_SOCIAL: TStringField;
    labelRazaoSocial: TLabel;
    editRazaoSocial: TDBEdit;
    gbPesquisaFornecedor: TGroupBox;
    editPesquisaFornecedor: TEdit;
    RBrazaoSocial: TRadioButton;
    RBnomeFantasia: TRadioButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure editPesquisaFornecedorChange(Sender: TObject);
    procedure RBrazaoSocialClick(Sender: TObject);
    procedure RBnomeFantasiaClick(Sender: TObject);
    procedure gridFornecedoresDblClick(Sender: TObject);
    procedure gridFornecedoresKeyPress(Sender: TObject; var Key: Char);
    procedure editPesquisaFornecedorKeyPress(Sender: TObject; var Key: Char);
    procedure gridFornecedoresDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    { Private declarations }

    procedure ConfigurarEnables(status: integer);
    procedure CapturarETransferirFornecedor;


  public
    { Public declarations }

    var DuploClickNaGrid : String;

  end;

var
  frmFornecedor: TfrmFornecedor;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmEntradaNF;

procedure TfrmFornecedor.CapturarETransferirFornecedor;
begin
 if (FDqryFornecedores.RecordCount > 0) and (DuploClickNaGrid = 'SUPPLIER') then
   begin
      frmEntradaNF.FDqryFornecedor.Refresh;
      frmEntradaNF.editPesquisarFornecedor.Text := FDqryFornecedores['NOME_FANTASIA'];
      frmEntradaNF.FDqryFornecedor.Locate('FORNECEDOR_ID',FDqryFornecedores['FORNECEDOR_ID'],[]);
      Close;
   end;
end;


procedure TfrmFornecedor.btnAlterarClick(Sender: TObject);
begin
 ConfigurarEnables(1);
 FDqryFornecedores.Edit;
end;

procedure TfrmFornecedor.btnCancelarClick(Sender: TObject);
begin
  ConfigurarEnables(0);
  FDqryFornecedores.Cancel;
end;

procedure TfrmFornecedor.btnExcluirClick(Sender: TObject);
 var AuxErro : string;
begin
  configurarEnables(0);
 if MessageBox(Application.Handle,'Deseja excluir esse Fornecedor?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
     try
      FDqryFornecedores.Delete;
     except
      on E : exception do
       begin
        AuxErro := copy (E.Message,20,25);
        ShowMessage(AuxErro);
       end;
     end;
    end;
end;

procedure TfrmFornecedor.btnNovoClick(Sender: TObject);
begin
 ConfigurarEnables(1);
 editNomeFantasia.SetFocus;
 FDqryFornecedores.Insert;
end;

procedure TfrmFornecedor.btnSalvarClick(Sender: TObject);
begin
 if editRazaoSocial.Text <> '' then
   begin
     ConfigurarEnables(0);
     FDqryFornecedores.Post;
      try
       FDtcFornecedores.CommitRetaining;
      finally
       FDtcFornecedores.RollbackRetaining;
      end;
   end
   else
   MessageDlg('Por favor, informe a Raz�o Social', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
end;

procedure TfrmFornecedor.configurarEnables(status : integer);
begin
    if status = 0 then
      begin
        btnNovo.Enabled := True;
        btnAlterar.Enabled := True;
        btnExcluir.Enabled := True;
        btnCancelar.Enabled := False;
        btnSalvar.Enabled := False;
        editNomeFantasia.Enabled := False;
        editRazaoSocial.Enabled := False;
        editCNPJ.Enabled := False;
        editTelefone.Enabled := False;
      end
     else
      begin
        btnNovo.Enabled := False;
        btnAlterar.Enabled := False;
        btnExcluir.Enabled := False;
        btnCancelar.Enabled := True;
        btnSalvar.Enabled := True;
        editNomeFantasia.Enabled := True;
        editRazaoSocial.Enabled :=  True;
        editCNPJ.Enabled := True;
        editTelefone.Enabled := True;
      end;
end;

procedure TfrmFornecedor.editPesquisaFornecedorChange(Sender: TObject);
var
   FornecedorPesquisado : string;
begin
      if RBrazaoSocial.Checked = True  then
         FornecedorPesquisado := ' RAZAO_SOCIAL ';
      if RBnomeFantasia.Checked = True then
         FornecedorPesquisado := ' NOME_FANTASIA ';

   with FDqryFornecedores do
     begin
       close;
       DisableControls;
       SQL.Clear;
       SQL.Add('select * from FORNECEDOR where '+ FornecedorPesquisado +' like '+ QuotedStr('%'+ editPesquisaFornecedor.Text +'%'));
       EnableControls;
       Open;
     end;

end;

procedure TfrmFornecedor.editPesquisaFornecedorKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
   begin
     CapturarETransferirFornecedor;
     Key := #0;
   end;
end;

procedure TfrmFornecedor.FormClose(Sender: TObject; var Action: TCloseAction);
begin
FDqryFornecedores.Close;
end;

procedure TfrmFornecedor.FormShow(Sender: TObject);
begin
 FDqryFornecedores.Open;
 RBrazaoSocial.Checked := True;
 editPesquisaFornecedor.Clear;
 ConfigurarEnables(0);
end;

procedure TfrmFornecedor.gridFornecedoresDblClick(Sender: TObject);
begin
 CapturarETransferirFornecedor;
end;

procedure TfrmFornecedor.gridFornecedoresDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
     with gridFornecedores do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridFornecedores).CellRect( DataCol ,TStringGrid(gridFornecedores).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;

procedure TfrmFornecedor.gridFornecedoresKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
   begin
     CapturarETransferirFornecedor;
     Key := #0;
   end;
end;

procedure TfrmFornecedor.Image1Click(Sender: TObject);
begin
 frmFornecedor.Close;
end;

procedure TfrmFornecedor.RBnomeFantasiaClick(Sender: TObject);
begin
editPesquisaFornecedor.SetFocus;
end;

procedure TfrmFornecedor.RBrazaoSocialClick(Sender: TObject);
begin
 editPesquisaFornecedor.SetFocus;
end;

end.
