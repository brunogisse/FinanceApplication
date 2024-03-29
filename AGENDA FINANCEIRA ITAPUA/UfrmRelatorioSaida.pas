unit UfrmRelatorioSaida;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.DBCtrls, Vcl.StdCtrls,
  Vcl.Buttons, Vcl.ComCtrls, frxClass, frxDBSet;

type
  TfrmRelatorioSaidas = class(TForm)
    FDtcSaidaProdutosREL: TFDTransaction;
    FDqrySaidaProdutosRel: TFDQuery;
    dsSaidaProdutosREL: TDataSource;
    FDqryDestinoREL: TFDQuery;
    FDqryDestinoRELDESTINO_ID: TIntegerField;
    FDqryDestinoRELDESCRICAO: TStringField;
    dsDestinoREL: TDataSource;
    FDqryPropriedadeREL: TFDQuery;
    FDqryPropriedadeRELDESCRICAO: TStringField;
    FDqryPropriedadeRELPROPRIEDADE_ID: TIntegerField;
    dsPropriedadeREL: TDataSource;
    FDqryProdutoREL: TFDQuery;
    FDqryProdutoRELPRODUTO_ID: TIntegerField;
    FDqryProdutoRELDESCRICAO: TStringField;
    FDqryProdutoRELVALOR: TFMTBCDField;
    FDqryProdutoRELESTOQUE_MINIMO: TIntegerField;
    FDqryProdutoRELTIPO: TIntegerField;
    FDqryProdutoRELESTOQUE: TIntegerField;
    FDqryProdutoRELTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutoRELTIPO_DESCRICAO: TStringField;
    dsProdutoREL: TDataSource;
    gbPeriodo: TGroupBox;
    dataFim: TDateTimePicker;
    dataInicio: TDateTimePicker;
    labelInicio: TLabel;
    labelFim: TLabel;
    gbParametros: TGroupBox;
    cbDestino: TDBLookupComboBox;
    cbPropriedade: TDBLookupComboBox;
    editProduto: TEdit;
    frxReportREL: TfrxReport;
    labelProduto: TLabel;
    labelPropriedade: TLabel;
    labelDestino: TLabel;
    btnImprimir: TBitBtn;
    FDqrySaidaProdutosRelSAIDA_PRODUTO_ID: TFDAutoIncField;
    FDqrySaidaProdutosRelDESTINO_ID: TIntegerField;
    FDqrySaidaProdutosRelPROPRIEDADE_ID: TIntegerField;
    FDqrySaidaProdutosRelPRODUTO_ID: TIntegerField;
    FDqrySaidaProdutosRelDATA: TDateField;
    FDqrySaidaProdutosRelQTDE: TIntegerField;
    FDqrySaidaProdutosRelOBS: TStringField;
    FDqrySaidaProdutosRelDESTINO: TStringField;
    FDqrySaidaProdutosRelPROPRIEDADE: TStringField;
    FDqrySaidaProdutosRelPRODUTO: TStringField;
    FDqrySaidaProdutosRelVALOR_SAIDA: TFMTBCDField;
    frxDBDatasetREL: TfrxDBDataset;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    btnApagarPropriedade: TBitBtn;
    btnApagarDestino: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure editProdutoDblClick(Sender: TObject);
    procedure editProdutoKeyPress(Sender: TObject; var Key: Char);
    procedure btnImprimirClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure btnApagarPropriedadeClick(Sender: TObject);
    procedure btnApagarDestinoClick(Sender: TObject);
  private
    { Private declarations }

  var DescricaoProduto, DescricaoDestino, DescricaoPropriedade : String;

    procedure Impressao;

  public
    { Public declarations }
  end;

var
  frmRelatorioSaidas: TfrmRelatorioSaidas;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmPesquisaProduto;

procedure tfrmRelatorioSaidas.Impressao;
begin

   if editProduto.Text <> '' then
      DescricaoProduto := ' and (PRO.DESCRICAO = :PRODUTO) '
     else
      DescricaoProduto := '';

   if cbDestino.Text <> '' then
      DescricaoDestino := ' and (D.DESCRICAO = :DESTINO) '
     else
      DescricaoDestino := '';

   if cbPropriedade.Text <> '' then
      DescricaoPropriedade := ' and (P.DESCRICAO = :PROPRIEDADE) '
     else
      DescricaoPropriedade := '';


  with FDqrySaidaProdutosRel do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select '
             +'S.SAIDA_PRODUTO_ID, '
              +'S.DESTINO_ID, '
              +'S.PROPRIEDADE_ID, '
              +'S.PRODUTO_ID, '
              +'S.DATA, '
              +'S.QTDE, '
              +'S.VALOR_SAIDA, '
              +'S.OBS, '
              +'D.DESCRICAO as DESTINO, '
              +'P.DESCRICAO as PROPRIEDADE, '
              +'PRO.DESCRICAO as PRODUTO '
              +'from '
              + 'SAIDA_PRODUTO S, DESTINO D, PROPRIEDADE P, PRODUTO PRO '
              +'where '
              +' (S.DESTINO_ID = D.DESTINO_ID) and '
              +' (S.PROPRIEDADE_ID = P.PROPRIEDADE_ID) and  '
              +' (S.PRODUTO_ID = PRO.PRODUTO_ID) and '
              +' (DATA between :INICIO and :FIM)  '+DescricaoProduto + DescricaoDestino + DescricaoPropriedade +'order by S.SAIDA_PRODUTO_ID');
              ParamByName('INICIO').AsDate := dataInicio.Date;
              ParamByName('FIM').AsDate := dataFim.Date;
           if editProduto.Text <> '' then
              ParamByName('PRODUTO').AsString := editProduto.Text;
           if cbDestino.Text <> '' then
              ParamByName('DESTINO').AsString := cbDestino.Text;
           if cbPropriedade.Text <> '' then
              ParamByName('PROPRIEDADE').AsString := cbPropriedade.Text;
      Open;
    end;
end;


procedure TfrmRelatorioSaidas.BitBtn1Click(Sender: TObject);
begin
frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'RELATÓRIO';
frmPesquisarProdutos.ShowModal;
end;

procedure TfrmRelatorioSaidas.BitBtn2Click(Sender: TObject);
begin
editProduto.Clear;
end;

procedure TfrmRelatorioSaidas.btnApagarPropriedadeClick(Sender: TObject);
begin
  cbPropriedade.KeyValue := -1;
end;

procedure TfrmRelatorioSaidas.btnApagarDestinoClick(Sender: TObject);
begin
  cbDestino.KeyValue := -1;
end;

procedure TfrmRelatorioSaidas.btnImprimirClick(Sender: TObject);
var caminhoRelatorio : string;
begin
  Impressao;
  caminhoRelatorio := ExtractFilePath(Application.ExeName);
  frxReportREL.LoadFromFile(caminhoRelatorio +'RelatorioSaida.fr3');
  frxReportREL.Variables['DataInicio'] := QuotedStr(DateToStr(dataInicio.Date));
  frxReportREL.Variables['DataFim'] := QuotedStr(DateToStr(dataFim.Date));
  frxReportREL.ShowReport();

  cbDestino.KeyValue := -1;
  cbPropriedade.KeyValue := -1;

end;

procedure TfrmRelatorioSaidas.editProdutoDblClick(Sender: TObject);
begin
frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'RELATÓRIO';
frmPesquisarProdutos.ShowModal;
end;

procedure TfrmRelatorioSaidas.editProdutoKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
    begin
      frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'RELATÓRIO';
      frmPesquisarProdutos.ShowModal;
      Key := #0;
    end;
end;

procedure TfrmRelatorioSaidas.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FDqrySaidaProdutosRel.Close;
 FDqryPropriedadeREL.Close;
 FDqryProdutoREL.Close;
 FDqryDestinoREL.Close;
end;

procedure TfrmRelatorioSaidas.FormShow(Sender: TObject);
begin
 FDqrySaidaProdutosRel.Open;
 FDqryPropriedadeREL.Open;
 FDqryProdutoREL.Open;
 FDqryDestinoREL.Open;
 dataInicio.Date := Now;
 dataFim.Date := Now;
end;

end.
