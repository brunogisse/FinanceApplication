unit UfrmProduto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.Imaging.pngimage, Vcl.ExtCtrls,
  Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls,
  Vcl.ComCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client, StrUtils;

type
  TfrmProdutosTipos = class(TForm)
    painelTopo: TPanel;
    btnNovo: TImage;
    btnSalvar: TImage;
    btnCancelar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    brnSair: TImage;
    PageControl: TPageControl;
    pageProdutos: TTabSheet;
    PageSTipoProduto: TTabSheet;
    gridTipoProduto: TDBGrid;
    ControlBar1: TControlBar;
    gridProduto: TDBGrid;
    FDtcProdutosEtipos: TFDTransaction;
    FDqryProdutos: TFDQuery;
    FDqryTipoProduto: TFDQuery;
    dsProdutos: TDataSource;
    dsTipoProduto: TDataSource;
    FDqryProdutosPRODUTO_ID: TIntegerField;
    FDqryProdutosDESCRICAO: TStringField;
    FDqryProdutosVALOR: TFMTBCDField;
    FDqryProdutosESTOQUE_MINIMO: TIntegerField;
    FDqryProdutosTIPO_ID: TIntegerField;
    FDqryProdutosTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutosTIPO: TStringField;
    FDqryTipoProdutoTIPO_PRODUTO_ID: TIntegerField;
    FDqryTipoProdutoDESCRICAO: TStringField;
    labelTipoDescricao: TLabel;
    editDescricaoTipo: TDBEdit;
    labelPesqTipo: TLabel;
    editPesqTipoAbaProduto: TEdit;
    FDqryProdutosESTOQUE: TIntegerField;
    labelPesqCatFK: TLabel;
    editPesqTipoAbaTipo: TEdit;
    gbEdits: TGroupBox;
    labelDescricao: TLabel;
    editDescricao: TDBEdit;
    labelValor: TLabel;
    editValor: TDBEdit;
    Label1: TLabel;
    editEstoque: TDBEdit;
    labelEstoqueMinimo: TLabel;
    editEstoqueMinimo: TDBEdit;
    labelTipo: TLabel;
    editTipo: TDBEdit;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure brnSairClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure editValorChange(Sender: TObject);
    procedure editPesqTipoAbaTipoChange(Sender: TObject);
    procedure editPesqTipoAbaProdutoChange(Sender: TObject);
    procedure editDescricaoTipoKeyPress(Sender: TObject; var Key: Char);
    procedure btnAlterarClick(Sender: TObject);
    procedure gridTipoProdutoDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure gridProdutoDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure labelPesqCatFKDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure FDqryProdutosBeforePost(DataSet: TDataSet);
    procedure PageSTipoProdutoShow(Sender: TObject);
    procedure pageProdutosShow(Sender: TObject);
  private
    { Private declarations }

    procedure ConfigurarEnables(status: integer);
    procedure novoRegistro;
    procedure cancelarRegistro;
    procedure salvarRegistro;
    procedure editarRegistro;
    procedure atualizarBanco;
    procedure filtrarCategoria;
    procedure excluirRegistro;
    procedure setarFoco;
    function FormatarMoeda(valor : string) : string;  //sempre declarar StrUtils em Uses


  public
    { Public declarations }
  end;

var
  frmProdutosTipos: TfrmProdutosTipos;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmEntradaNF, UfrmItensEntrada, UfrmPesquisaProduto;

procedure TfrmProdutosTipos.editarRegistro;
begin
   if PageControl.TabIndex = 1 then
      FDqryTipoProduto.Edit;
   if PageControl.TabIndex = 0 then
      FDqryProdutos.Edit;
end;

procedure TfrmProdutosTipos.editDescricaoTipoKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
    begin
      salvarRegistro;
      configurarEnables(1);
      setarFoco;
      novoRegistro;
      Key := #0;
    end;
end;

procedure TfrmProdutosTipos.filtrarCategoria;
var trecho : string;
begin
 if PageControl.TabIndex = 0 then
    trecho := editPesqTipoAbaProduto.Text;
 if PageControl.TabIndex = 1 then
    trecho := editPesqTipoAbaTipo.Text;
 with FDqryTipoProduto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select * from TIPO_PRODUTO where DESCRICAO like ' + QuotedStr('%'+trecho+'%')+ 'ORDER BY DESCRICAO ASC');
      Open;
    end;

end;


function TfrmProdutosTipos.FormatarMoeda(valor: string): string;
var
  decimais, centena: string;
  i: Integer;
begin
  Result := EmptyStr;

  for i := 0 to Length(valor) - 1 do
    if not(valor[i] in ['0' .. '9']) then
      delete(valor, i, 1);

  if copy(valor, 1, 1) = '0' then
    valor := copy(valor, 2, Length(valor));

  decimais := RightStr(valor, 2);
  centena := copy(RightStr(valor, 5), 1, 3);

  case Length(valor) of
    1:
      Result := '0,0' + valor;
    2:
      Result := '0,' + valor;
  else
    Result := LeftStr(valor, Length(valor) - 2) + ',' + decimais;
  end;
end;

procedure TfrmProdutosTipos.cancelarRegistro;
begin
   if PageControl.TabIndex = 1 then
      FDqryTipoProduto.Cancel;
  if  PageControl.TabIndex = 0 then
     begin
      FDqryProdutos.Cancel;
     end;
end;

procedure TfrmProdutosTipos.editPesqTipoAbaProdutoChange(Sender: TObject);
begin
 filtrarCategoria;
end;

procedure TfrmProdutosTipos.editPesqTipoAbaTipoChange(Sender: TObject);
begin
 filtrarCategoria;
end;

procedure TfrmProdutosTipos.editValorChange(Sender: TObject);
begin
 editValor.Text := FormatarMoeda(editValor.Text);
 editValor.SelStart := Length(editValor.Text);
end;

procedure TfrmProdutosTipos.excluirRegistro;
var AuxErro : string;
begin
  if MessageBox(Application.Handle,'Deseja realmente Excluir esse registro?','Aten��o',MB_YESNO + MB_ICONQUESTION) = mrYes then
   begin
   try
      if PageControl.TabIndex = 1 then
        begin
         FDqryTipoProduto.Delete;
        end;
      if PageControl.TabIndex = 0 then
        begin
         FDqryProdutos.Delete;
        end;
   except
     on E : exception do
      begin
        AuxErro := copy (E.Message,20,25);
        MessageDlg('N�o � poss�vel excluir o registro no momento.' +#13
        +#13+ 'Este registro est� sendo referenciado em outra tabela. '+#13
        +#13+ 'Para mais informa��es, pesquise sobre o termo: ' + AuxErro, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
       end;
   end;

  end;
end;

procedure TfrmProdutosTipos.FDqryProdutosBeforePost(DataSet: TDataSet);
begin
if editDescricao.Text = '' then
  begin
    MessageDlg('Aten��o, o campo Descri��o n�o pode ficar vazio' + #13 + 'Clique novamente em "Adicionar Novo Registro". ' , TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
    cancelarRegistro;
    configurarEnables(0);
    Abort;
  end;
end;

procedure TfrmProdutosTipos.setarFoco;
begin
  if PageControl.TabIndex = 1 then
     editDescricaoTipo.SetFocus
    else
     editDescricao.SetFocus;
end;


procedure TfrmProdutosTipos.atualizarBanco;
begin
  FDqryProdutos.Close;
  FDqryTipoProduto.Close;
  FDqryProdutos.Open;
  FDqryTipoProduto.Open;
end;

procedure TfrmProdutosTipos.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FDqryProdutos.Close;
  FDqryTipoProduto.Close;
end;

procedure TfrmProdutosTipos.FormShow(Sender: TObject);
begin
 editValor.Text := FormatarMoeda(editValor.Text);
 editValor.SelStart := Length(editValor.Text);


  FDqryProdutos.Open;
  FDqryTipoProduto.Open;
  ConfigurarEnables(0);
  PageControl.TabIndex := 0;
end;

procedure TfrmProdutosTipos.gridProdutoDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
     with gridProduto do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridProduto).CellRect( DataCol ,TStringGrid(gridProduto).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;

procedure TfrmProdutosTipos.gridTipoProdutoDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  with gridTipoProduto do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridTipoProduto).CellRect( DataCol ,TStringGrid(gridTipoProduto).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;

procedure TfrmProdutosTipos.labelPesqCatFKDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
Accept := True;
end;

procedure TfrmProdutosTipos.novoRegistro;
var TipoProduto, AuxErro : string;
begin
 if PageControl.TabIndex = 1 then
    begin
        FDqryTipoProduto.Insert;
    end;
 if PageControl.TabIndex = 0 then
    begin
       Try
            TipoProduto := FDqryTipoProduto['DESCRICAO'];
         if Application.MessageBox(pchar('Cadastrando novo produto do tipo ' + TipoProduto +'.' + #13 + 'Confirma a opera��o?'),' Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
            FDqryProdutos.Insert
           else
            begin
              cancelarRegistro;
              configurarEnables(0);
            end;
       Except
          on E: Exception do
           begin
             AuxErro := Copy(E.Message,0,200);
             MessageDlg('Novo registro negado. Motivo: '+ #13 + 'Primeiro � necess�rio cadastrar um tipo para este produto.' + #13 + #13 + 'Dados t�cnicos sobre este erro: ' + #13 + AuxErro, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
             cancelarRegistro;
             configurarEnables(0);
           end
       end
    end;
end;



procedure TfrmProdutosTipos.pageProdutosShow(Sender: TObject);
begin
 cancelarRegistro;
 configurarEnables(0);
end;

procedure TfrmProdutosTipos.PageSTipoProdutoShow(Sender: TObject);
begin
 cancelarRegistro;
 configurarEnables(0);
end;

procedure TfrmProdutosTipos.brnSairClick(Sender: TObject);
begin
 frmProdutosTipos.Close;
end;

procedure TfrmProdutosTipos.btnAlterarClick(Sender: TObject);
begin
editarRegistro;
configurarEnables(1);
end;

procedure TfrmProdutosTipos.btnCancelarClick(Sender: TObject);
begin
 cancelarRegistro;
 configurarEnables(0);
end;

procedure TfrmProdutosTipos.btnExcluirClick(Sender: TObject);
begin
excluirRegistro;
configurarEnables(0);
end;

procedure TfrmProdutosTipos.btnNovoClick(Sender: TObject);
begin
  configurarEnables(1);
  setarFoco;
  novoRegistro;
end;

procedure TfrmProdutosTipos.btnSalvarClick(Sender: TObject);
begin
 salvarRegistro;
end;

procedure TfrmProdutosTipos.configurarEnables(status : Integer);
begin
  if status = 0 then
    begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editDescricao.Enabled := False;
      editValor.Enabled := False;
      editEstoqueMinimo.Enabled := False;
      editDescricaoTipo.Enabled := False;
      gridTipoProduto.Enabled := True;
      gridProduto.Enabled := True;
    end
   else
    begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editDescricao.Enabled := True;
      editValor.Enabled := True;
      editEstoqueMinimo.Enabled := True;
      editDescricaoTipo.Enabled := True;
      gridTipoProduto.Enabled := False;
      gridProduto.Enabled := False;
    end;
end;


procedure TfrmProdutosTipos.salvarRegistro;
begin


  if PageControl.TabIndex = 1 then          //Condi��o que verifica se as informa��es er�o
      FDqryTipoProduto.Post;                //salvas em TIPO_PRODUTO ou em PRODUTO
                                            //uma vez que os mesmos bot�es s�o usados para gravar as informa��es.

  if PageControl.TabIndex = 0 then
         begin
           FDqryProdutos['TIPO_ID']  := FDqryTipoProduto['TIPO_PRODUTO_ID'];
           if editValor.Text = '0,00' then
           FDqryProdutos['VALOR'] := 0;
           if editEstoqueMinimo.Text = '' then
           FDqryProdutos['ESTOQUE_MINIMO'] := 1;
           FDqryProdutos['ESTOQUE'] := 0;
           FDqryProdutos.Post;
         end;

   try
     FDtcProdutosEtipos.CommitRetaining;
   except
     FDtcProdutosEtipos.RollbackRetaining;
   end;
      FDqryProdutos.Close;
      FDqryProdutos.Open;
      configurarEnables(0);
end;

end.
