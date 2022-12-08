unit UfrmPesquisaProduto;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, Vcl.StdCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.Buttons;

type
  TfrmPesquisarProdutos = class(TForm)
    painelTopo: TPanel;
    gridPesquisaProdutos: TDBGrid;
    editPesquisarProdutos: TEdit;
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
    btnNovoProduto: TBitBtn;
    FDtcPesquisarProdutos: TFDTransaction;
    procedure editPesquisarProdutosChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnNovoProdutoClick(Sender: TObject);
    procedure gridPesquisaProdutosDblClick(Sender: TObject);
    procedure editPesquisarProdutosKeyPress(Sender: TObject; var Key: Char);
    procedure gridPesquisaProdutosDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure gridPesquisaProdutosKeyPress(Sender: TObject; var Key: Char);
    procedure editPesquisarProdutosKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

  private
    { Private declarations }

    Procedure CapturaETransporteDeProdutos;

  public
    { Public declarations }

    var EntradaOuSaidaOuRelatorio : string;

  end;

var
  frmPesquisarProdutos: TfrmPesquisarProdutos;

implementation

{$R *.dfm}

uses UfrmItensEntrada, UfrmPrincipal, UfrmProduto, UfrmEntradaNF,
  UfrmSaidaProdutos, UfrmRelatorioSaida;

procedure TfrmPesquisarProdutos.CapturaETransporteDeProdutos;
  begin
        if EntradaOuSaidaOuRelatorio = 'ENTRADA' then

            begin
               frmEntradaItens.FDqryProduto.Refresh;
               frmEntradaNF.FDqryEntradaNF.Refresh;
               frmEntradaItens.editProdutoInserido.Text := FDqryProdutos['DESCRICAO'];
               frmEntradaItens.FDqryProduto.Locate('PRODUTO_ID',FDqryProdutos['PRODUTO_ID'],[]);
               frmEntradaItens.editQtdeItem.Text := '1';
            end;

        if EntradaOuSaidaOuRelatorio = 'SAÍDA' then

            begin
               frmSaidaProdutos.FDqryProduto.Refresh;
               frmSaidaProdutos.editProduto.Text := FDqryProdutos['DESCRICAO'];
               frmSaidaProdutos.editValorSaida.Text := FloatToStr(FDqryProdutos['VALOR']);
               frmSaidaProdutos.editQTDE.Clear;
               frmSaidaProdutos.editQTDE.SetFocus;
               frmSaidaProdutos.FDqryProduto.Locate('PRODUTO_ID',FDqryProdutos['PRODUTO_ID'],[]);
            end;

        if EntradaOuSaidaOuRelatorio = 'RELATÓRIO' then

            begin
              frmRelatorioSaidas.FDqryProdutoREL.Refresh;
              frmRelatorioSaidas.editProduto.Text := FDqryProdutos['DESCRICAO'];
              frmRelatorioSaidas.FDqryProdutoREL.Locate('PRODUTO_ID',FDqryProdutos['PRODUTO_ID'],[]);
            end;

       close;
  end;

procedure TfrmPesquisarProdutos.btnNovoProdutoClick(Sender: TObject);
begin
     try
       Application.CreateForm(TfrmProdutosTipos,frmProdutosTipos);
       frmProdutosTipos.ShowModal;
     finally
        FreeAndNil(frmProdutosTipos);
     end;
  FDqryProdutos.Close;
  FDqryProdutos.Open;
end;

procedure TfrmPesquisarProdutos.gridPesquisaProdutosDblClick(Sender: TObject);
begin
 if FDqryProdutos.RecordCount > 0 then
    CapturaETransporteDeProdutos
   else
    MessageDlg('Item não localizado',TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
end;

procedure TfrmPesquisarProdutos.gridPesquisaProdutosDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
 with gridPesquisaProdutos do
       begin
         if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then //Cor da linha selecionada
           if (Rect.Top = TStringGrid(gridPesquisaProdutos).CellRect( DataCol ,TStringGrid(gridPesquisaProdutos).Row).Top)
             or( gdSelected in State)  then
            begin
              Canvas.FillRect(Rect);
              Canvas.Brush.Color := clNavy;
              canvas.Font.Color := clwhite;
              DefaultDrawDataCell(Rect,Column.Field,State)
            end;
       end;
end;

procedure TfrmPesquisarProdutos.gridPesquisaProdutosKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
   begin
      if FDqryProdutos.RecordCount > 0 then
      begin
         CapturaETransporteDeProdutos;
         Key := #0;
      end
   else
    MessageDlg('Item não localizado',TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
    Key := #0;
   end;
end;

procedure TfrmPesquisarProdutos.editPesquisarProdutosChange(Sender: TObject);
begin

 with FDqryProdutos do
  begin
    close;
    DisableControls;
    SQL.Clear;
    SQL.Add('select P.PRODUTO_ID, P.DESCRICAO, P.VALOR, P.ESTOQUE_MINIMO, P.TIPO as TIPO_ID, P.ESTOQUE, T.TIPO_PRODUTO_ID, T.DESCRICAO as TIPO'
             +' from PRODUTO P, TIPO_PRODUTO T where (P.DESCRICAO LIKE '+ QuotedStr('%'+ editPesquisarProdutos.Text +'%') + ') and (P.TIPO = T.TIPO_PRODUTO_ID) order by P.DESCRICAO ASC');
             Open;
             EnableControls;
  end;

end;

procedure TfrmPesquisarProdutos.editPesquisarProdutosKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
If key = VK_DOWN then
   FDqryProdutos.Next;
if Key = VK_UP then
   FDqryProdutos.Prior;
end;

procedure TfrmPesquisarProdutos.editPesquisarProdutosKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
   begin
      if FDqryProdutos.RecordCount > 0 then
      begin
         CapturaETransporteDeProdutos;
         Key := #0;
      end
   else
    MessageDlg('Item não localizado',TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
    Key := #0;
   end;
end;

procedure TfrmPesquisarProdutos.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 editPesquisarProdutos.Clear;
 FDqryProdutos.Close;
end;

procedure TfrmPesquisarProdutos.FormShow(Sender: TObject);
begin
FDqryProdutos.Open;
end;

end.
