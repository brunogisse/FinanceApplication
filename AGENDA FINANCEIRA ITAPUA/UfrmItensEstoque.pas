unit UfrmItensEstoque;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.StdCtrls, Vcl.Buttons, Vcl.DBCtrls;

type
  TfrmItensEstoque = class(TForm)
    PainelTopo: TPanel;
    DBGrid1: TDBGrid;
    FDqryProdutos: TFDQuery;
    FDqryProdutosPRODUTO_ID: TIntegerField;
    FDqryProdutosDESCRICAO: TStringField;
    FDqryProdutosVALOR: TFMTBCDField;
    FDqryProdutosESTOQUE_MINIMO: TIntegerField;
    FDqryProdutosTIPO_ID: TIntegerField;
    FDqryProdutosTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutosTIPO: TStringField;
    FDqryProdutosESTOQUE: TIntegerField;
    dsProdutos: TDataSource;
    FDqryTipoProduto: TFDQuery;
    FDqryTipoProdutoTIPO_PRODUTO_ID: TIntegerField;
    FDqryTipoProdutoDESCRICAO: TStringField;
    dsTipoProduto: TDataSource;
    GroupBox1: TGroupBox;
    labelTipoProduto: TLabel;
    labelProduto: TLabel;
    labelCodigoProduto: TLabel;
    editCodigoProduto: TEdit;
    CBtipoProduto: TDBLookupComboBox;
    editProduto: TEdit;
    procedure FormShow(Sender: TObject);
    procedure editCodigoProdutoKeyPress(Sender: TObject; var Key: Char);
    procedure editProdutoKeyPress(Sender: TObject; var Key: Char);


  private
    { Private declarations }

    procedure BuscarDadosPor(condicao : string);

  public
    { Public declarations }
  end;

var
  frmItensEstoque: TfrmItensEstoque;

implementation

{$R *.dfm}

procedure TfrmItensEstoque.BuscarDadosPor(condicao : string);
begin
   if (condicao = 'CODIGO') and (editCodigoProduto.Text <> '') then
      begin
         with FDqryProdutos do
           begin
             close;
             SQL.Clear;
             SQL.Add('select '
             +'P.PRODUTO_ID, '
             +'P.DESCRICAO, '
             +'P.VALOR, '
             +'P.ESTOQUE_MINIMO, '
             +'P.TIPO as TIPO_ID, '
             +'P.ESTOQUE, '
             +'T.TIPO_PRODUTO_ID, '
             +'T.DESCRICAO as TIPO '
             +'from PRODUTO P, TIPO_PRODUTO T '
             +'where '
             +'(P.TIPO = T.TIPO_PRODUTO_ID) and '
             +'(PRODUTO_ID = :CODIGOPRODUTO) '
             +'order by P.DESCRICAO ASC');
             ParamByName('CODIGOPRODUTO').AsInteger := StrToInt(editCodigoProduto.Text);
             Open;
           end;
      end;
   if (condicao = 'DESCRICAO') {and (editProduto.Text <> '')} then
      begin
         with FDqryProdutos do
           begin
             close;
             SQL.Clear;
             SQL.Add('select '
             +'P.PRODUTO_ID, '
             +'P.DESCRICAO, '
             +'P.VALOR, '
             +'P.ESTOQUE_MINIMO, '
             +'P.TIPO as TIPO_ID, '
             +'P.ESTOQUE, '
             +'T.TIPO_PRODUTO_ID, '
             +'T.DESCRICAO as TIPO '
             +'from PRODUTO P, TIPO_PRODUTO T '
             +'where '
             +'(P.TIPO = T.TIPO_PRODUTO_ID) and '
             +' (P.DESCRICAO LIKE ' + QuotedStr('%'+ editProduto.Text + '%') + ') order by P.DESCRICAO ASC');
             Open;
           end;
      end;
   if (condicao = 'DESCRICAOCOMTIPO') {and (editProduto.Text <> '')} then
      begin
         with FDqryProdutos do
           begin
             close;
             SQL.Clear;
             SQL.Add('select '
             +'P.PRODUTO_ID, '
             +'P.DESCRICAO, '
             +'P.VALOR, '
             +'P.ESTOQUE_MINIMO, '
             +'P.TIPO as TIPO_ID, '
             +'P.ESTOQUE, '
             +'T.TIPO_PRODUTO_ID, '
             +'T.DESCRICAO as TIPO '
             +'from PRODUTO P, TIPO_PRODUTO T '
             +'where '
             +'(P.TIPO = T.TIPO_PRODUTO_ID) and '
             +'(T.TIPO_PRODUTO_ID = :TIPO) and '
             +' (P.DESCRICAO LIKE ' + QuotedStr('%'+ editProduto.Text + '%') + ') order by P.DESCRICAO ASC');
             ParamByName('TIPO').AsInteger := FDqryTipoProduto['TIPO_PRODUTO_ID'];
             Open;
           end;
      end;
end;

procedure TfrmItensEstoque.editCodigoProdutoKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
    begin
       BuscarDadosPor('CODIGO');
       editProduto.Clear;
       Key := #0
    end;
end;

procedure TfrmItensEstoque.editProdutoKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = #13 then
   begin
      if CBtipoProduto.Text <> '' then
      BuscarDadosPor('DESCRICAOCOMTIPO')
      else
      BuscarDadosPor('DESCRICAO');
      editCodigoProduto.Clear;
      Key := #0;
   end;
end;

procedure TfrmItensEstoque.FormShow(Sender: TObject);
begin
 FDqryTipoProduto.Open;
end;

end.
