unit UfrmItensEntrada;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls, Vcl.Buttons, StrUtils;

type
  TfrmEntradaItens = class(TForm)
    painelTopo: TPanel;
    gridEntradaDEitens: TDBGrid;
    painelBottom: TPanel;
    FDqryEntradaItens: TFDQuery;
    dsEntradaItens: TDataSource;
    FDqryEntradaItensITEM_NF_ID: TIntegerField;
    FDqryEntradaItensNF_ID: TIntegerField;
    FDqryEntradaItensPRODUTO_ID: TIntegerField;
    FDqryEntradaItensVALOR_ITEM: TFMTBCDField;
    FDqryEntradaItensQTDE_ITEM: TIntegerField;
    FDqryEntradaItensCADASTRO_NF_ID: TIntegerField;
    FDqryEntradaItensID_DO_PRODUTO: TIntegerField;
    FDqryEntradaItensPRODUTO: TStringField;
    dsProduto: TDataSource;
    FDqryProduto: TFDQuery;
    dsEntradaNF: TDataSource;
    FDqryEntradaNF: TFDQuery;
    FDqryProdutoPRODUTO_ID: TIntegerField;
    FDqryProdutoDESCRICAO: TStringField;
    FDqryProdutoVALOR: TFMTBCDField;
    FDqryProdutoESTOQUE_MINIMO: TIntegerField;
    FDqryProdutoTIPO: TIntegerField;
    FDqryProdutoESTOQUE: TIntegerField;
    FDqryProdutoTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutoTIPO_DESCRICAO: TStringField;
    FDqryEntradaNFCADASTRO_NF_ID: TIntegerField;
    FDqryEntradaNFFORNECEDOR_ID: TIntegerField;
    FDqryEntradaNFDATA: TDateField;
    FDqryEntradaNFVALOR_NF: TFMTBCDField;
    FDqryEntradaNFNF: TIntegerField;
    FDqryEntradaNFOBS: TStringField;
    FDqryEntradaNFDATA_EMISSAO_NF: TDateField;
    Lentrada: TLabel;
    labelEntrada: TLabel;
    FdqrySomaItens: TFDQuery;
    dsSomaItens: TDataSource;
    FdqrySomaItensITENS_SOMADOS_PARA_NF: TFMTBCDField;
    FDtcItensEntrada: TFDTransaction;
    gbProdutos: TGroupBox;
    Label1: TLabel;
    editProdutoInserido: TEdit;
    Label2: TLabel;
    editValorItem: TEdit;
    editQtdeItem: TEdit;
    Label3: TLabel;
    btnInserirItem: TBitBtn;
    btnExcluirItem: TBitBtn;
    gbTotal: TGroupBox;
    editTotalProdutos: TDBEdit;
    FDqryEntradaItensVALOR_TOTAL_ITEM: TFMTBCDField;
    editValorTotalItem: TEdit;
    Label4: TLabel;
    LNF: TLabel;
    labelNF: TLabel;
    FDqryEntradaNFSTATUS: TStringField;
    FDqryEntradaNFNF_LANCADA: TStringField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure editValorItemChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure editProdutoInseridoDblClick(Sender: TObject);
    procedure btnInserirItemClick(Sender: TObject);
    procedure btnExcluirItemClick(Sender: TObject);
    procedure editProdutoInseridoKeyPress(Sender: TObject; var Key: Char);
    procedure editQtdeItemExit(Sender: TObject);
    procedure gridEntradaDEitensDrawColumnCell(Sender: TObject;
      const Rect: TRect; DataCol: Integer; Column: TColumn;
      State: TGridDrawState);
    procedure editValorItemExit(Sender: TObject);
    procedure editProdutoInseridoExit(Sender: TObject);

  private
    { Private declarations }
    function FormatarMoeda(valor : string) : string;

    procedure RefreshDatasets ;
    procedure SalvarOuAlterarItem(Status : String);
    procedure BuscarProduto;
    procedure AtualizarEstoqueDoProduto(AtualizarPara : string);
    procedure EscreverNoBanco;
    procedure CalcularValorItens;
    function VerificarCamposVazios(situacao : string) : string ;



  public
    { Public declarations }
  end;

var
  frmEntradaItens: TfrmEntradaItens;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmEntradaNF, UfrmProduto, UfrmPesquisaProduto;

procedure TfrmEntradaItens.CalcularValorItens;
var
  ValorItem, QtdeItem, ValorTotal : double;
begin
if editQtdeItem.Text <> '' then
    begin
     ValorItem := StrToFloat(editValorItem.Text);
     QtdeItem := StrToFloat(editQtdeItem.Text);
     ValorTotal := ValorItem * QtdeItem;

     editValorTotalItem.Text := FormatFloat('0.00',ValorTotal);
    end
   else
    begin
     MessageDlg('Informe a quantidade', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
     editQtdeItem.Text := '1';
     editQtdeItem.SetFocus;
    end;

end;

procedure TfrmEntradaItens.EscreverNoBanco;
begin
  try
    FDtcItensEntrada.CommitRetaining;
  except
    FDtcItensEntrada.RollbackRetaining;
  end;
end;

procedure TfrmEntradaItens.AtualizarEstoqueDoProduto(AtualizarPara : string);
 begin
  FDqryProduto.Edit;

   if AtualizarPara = 'ENTRADA' then
       begin
         if FDqryEntradaItens['QTDE_ITEM'] = Null then
            FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] - 0
         else
            FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] - FDqryEntradaItens['QTDE_ITEM'];
            FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] + StrToInt(editQtdeItem.Text);
       end;

  if AtualizarPara = 'SAIDA' then

       begin
          FDqryProduto.Locate('PRODUTO_ID',FDqryEntradaItens['PRODUTO_ID'],[]);
          FDqryProduto.Edit;
          FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] - FDqryEntradaItens['QTDE_ITEM'];
       end;
          FDqryProduto.Post;
 end;

function TfrmEntradaItens.VerificarCamposVazios(situacao : string) : string;
begin
  if (editProdutoInserido.Text = '') or (editQtdeItem.Text = '') then
      situacao := 'VAZIO'
     else
      situacao := 'OK';
  result := situacao;
end;

procedure TfrmEntradaItens.BuscarProduto;
var valorProduto : double;
begin
  frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'ENTRADA';
  frmPesquisarProdutos.ShowModal;
  valorProduto := FDqryProduto['VALOR'] * 100;    // em raz�o da fun��o FORMATAR MOEDAS,
  editValorItem.Text := FloatToStr(valorProduto); // o valor do produto vem dividido por 100.
  valorProduto := 0;                              // Consertei isso com essa multiplica��o por 100.
end;

procedure TfrmEntradaItens.SalvarOuAlterarItem(status : string);
begin
  if status = 'Salvar' then
      FDqryEntradaItens.Insert
     else
  if status = 'Alterar' then
      FDqryEntradaItens.Edit;
      FDqryEntradaItens['NF_ID'] := StrToInt(labelEntrada.Caption);
      FDqryEntradaItens['PRODUTO_ID'] := FDqryProduto['PRODUTO_ID'];
      FDqryEntradaItens['VALOR_ITEM'] := StrToFloat(editValorItem.Text);
      FDqryEntradaItens['VALOR_TOTAL_ITEM'] := StrToFloat(editValorTotalItem.Text);
      FDqryEntradaItens['QTDE_ITEM'] := StrToInt(editQtdeItem.Text);
      FDqryEntradaItens.Post;

      EscreverNoBanco;

      editProdutoInserido.SetFocus;
      FDqryEntradaItens.Close;
      FDqryEntradaItens.Open;
      FdqrySomaItens.Close;
      FdqrySomaItens.Open;
      FDqryProduto.Close;
      FDqryProduto.Open;
      editValorItem.Clear;
      editProdutoInserido.Clear;
      editQtdeItem.Clear;
      editValorTotalItem.Clear;
end;


procedure TfrmEntradaItens.RefreshDatasets;
begin
    FDqryEntradaItens.Close;
    FDqryEntradaNF.Close;
    FDqryProduto.Close;
    FdqrySomaItens.Close;
    FDqryEntradaItens.Open;
    FDqryEntradaNF.Open;
    FDqryProduto.Open;
    FdqrySomaItens.Open;
end;

procedure TfrmEntradaItens.btnExcluirItemClick(Sender: TObject);
var AuxErro : string;
begin
   if MessageBox(Application.Handle,'Confirma a retirada deste item?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
     begin
       try
         FDqryEntradaItens.Delete;
        except
         on E : exception do
          begin
            AuxErro := copy (E.Message,20,25);
            ShowMessage(AuxErro);
          end;
       end;
     end;
     EscreverNoBanco;
     RefreshDatasets;
end;

procedure TfrmEntradaItens.btnInserirItemClick(Sender: TObject);
 var situacao, situacaoParametro : string;
begin
      situacao:= VerificarCamposVazios(situacaoParametro);
   if situacao = 'VAZIO' then
       begin
         ShowMessage('Verifique os campos vazios');
         editProdutoInserido.SetFocus;
         Abort;
       end;
  if FDqryEntradaItens.Locate('PRODUTO_ID',FDqryProduto['PRODUTO_ID'],[]) then
       begin
         if MessageBox(Application.Handle,'Item j� inserido. Deseja alter�-lo?','Confirma��o',MB_YESNO + MB_ICONQUESTION) = mrYes then
            SalvarOuAlterarItem('Alterar')
           else
            abort
       end
      else
       SalvarOuAlterarItem('Salvar');
end;

procedure TfrmEntradaItens.editProdutoInseridoDblClick(Sender: TObject);
begin
  BuscarProduto;
end;

procedure TfrmEntradaItens.editProdutoInseridoExit(Sender: TObject);
begin
CalcularValorItens;
end;

procedure TfrmEntradaItens.editProdutoInseridoKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
   begin
     BuscarProduto;
     Key := #0;
   end;
end;

procedure TfrmEntradaItens.editQtdeItemExit(Sender: TObject);
begin
   CalcularValorItens;
end;

procedure TfrmEntradaItens.editValorItemChange(Sender: TObject);
begin
 editValorItem.Text := FormatarMoeda(editValorItem.Text);
 editValorItem.SelStart := Length(editValorItem.Text);
end;

procedure TfrmEntradaItens.editValorItemExit(Sender: TObject);
begin
CalcularValorItens;
end;

function TfrmEntradaItens.FormatarMoeda(valor: string): string;
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

procedure TfrmEntradaItens.FormClose(Sender: TObject; var Action: TCloseAction);
begin
    editProdutoInserido.Clear;
    editQtdeItem.Clear;
    RefreshDatasets;
    if FdqrySomaItens['ITENS_SOMADOS_PARA_NF'] = Null  then
    frmEntradaNF.TotalNF := 0
    else
    frmEntradaNF.TotalNF := FdqrySomaItens['ITENS_SOMADOS_PARA_NF'];

    FDqryEntradaItens.Close;
    FDqryEntradaNF.Close;
    FDqryProduto.Close;
    FdqrySomaItens.Close;
end;

procedure TfrmEntradaItens.FormShow(Sender: TObject);
begin
 editValorItem.Text := FormatarMoeda(editValorItem.Text);
 editValorItem.SelStart := Length(editValorItem.Text);
 editQtdeItem.Text := '1';

 FDqryEntradaItens.ParamByName('ENTRADA').AsString := labelEntrada.Caption;
 FdqrySomaItens.ParamByName('ENTRADA').AsString := labelEntrada.Caption;

FDqryEntradaItens.Open;
FDqryEntradaNF.Open;
FDqryProduto.Open;
FdqrySomaItens.Open;
end;

procedure TfrmEntradaItens.gridEntradaDEitensDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
   with gridEntradaDEitens do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridEntradaDEitens).CellRect( DataCol ,TStringGrid(gridEntradaDEitens).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;



end.
