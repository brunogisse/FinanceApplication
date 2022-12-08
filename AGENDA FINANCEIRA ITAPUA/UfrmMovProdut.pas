unit UfrmMovProdut;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, Vcl.StdCtrls, Vcl.ComCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.DBCtrls, Vcl.Buttons;

type
  TfrmMoviProduto = class(TForm)
    PainelTopo: TPanel;
    gridMovProdutos: TDBGrid;
    gbTopo: TGroupBox;
    editCodigo: TEdit;
    labelCodigo: TLabel;
    editProduto: TEdit;
    DataInicio: TDateTimePicker;
    DataFim: TDateTimePicker;
    labelIntervalo: TLabel;
    labelAte: TLabel;
    FDtcMovimentacaoProduto: TFDTransaction;
    FDqryMovimentacaoProduto: TFDQuery;
    dsMovimentacaoProduto: TDataSource;
    FDqryMovimentacaoProdutoMOVIMENTACAO_ID: TIntegerField;
    FDqryMovimentacaoProdutoDATA: TDateField;
    FDqryMovimentacaoProdutoPRODUTO_ID: TIntegerField;
    FDqryMovimentacaoProdutoTIPO: TStringField;
    FDqryMovimentacaoProdutoQTDE: TIntegerField;
    FDqryMovimentacaoProdutoSALDO_ATUAL: TIntegerField;
    FDqryMovimentacaoProdutoOBS: TStringField;
    FDqryMovimentacaoProdutoVALOR_PRODUTO: TFMTBCDField;
    DBMemo1: TDBMemo;
    FDqryProdutos: TFDQuery;
    dsProdutos: TDataSource;
    FDqryProdutosPRODUTO_ID: TIntegerField;
    FDqryProdutosDESCRICAO: TStringField;
    FDqryProdutosVALOR: TFMTBCDField;
    FDqryProdutosESTOQUE_MINIMO: TIntegerField;
    FDqryProdutosTIPO: TIntegerField;
    FDqryProdutosESTOQUE: TIntegerField;
    btnBuscar: TBitBtn;
    FDqryMovimentacaoProdutoADICIONAIS: TStringField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure editCodigoExit(Sender: TObject);
    procedure btnBuscarClick(Sender: TObject);
    procedure gridMovProdutosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmMoviProduto: TfrmMoviProduto;

implementation

{$R *.dfm}

uses UfrmPrincipal;

procedure TfrmMoviProduto.btnBuscarClick(Sender: TObject);
begin
 with FDqryMovimentacaoProduto do
    begin
      Close;
      ParamByName('CODIGOPRODUTO').AsInteger := StrToInt(editCodigo.Text);
      ParamByName('INICIO').AsDate := DataInicio.Date;
      ParamByName('FIM').AsDate := DataFim.Date;
      Open;
    end;
end;

procedure TfrmMoviProduto.gridMovProdutosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
   with gridMovProdutos do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridMovProdutos).CellRect( DataCol ,TStringGrid(gridMovProdutos).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;

procedure TfrmMoviProduto.editCodigoExit(Sender: TObject);
begin
  FDqryProdutos.Locate('produto_id',StrToInt(editCodigo.Text),[]);
  editProduto.Text := FDqryProdutos['DESCRICAO'];
end;

procedure TfrmMoviProduto.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FDqryMovimentacaoProduto.Close;
 FDqryProdutos.Close;
end;

procedure TfrmMoviProduto.FormShow(Sender: TObject);
begin
// FDqryMovimentacaoProduto.Open;
   FDqryProdutos.Open;
   DataInicio.Date := Now;
   DataFim.Date := Now;
end;

end.
