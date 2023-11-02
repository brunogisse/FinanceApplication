unit UfrmLancamentosEmLote;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.ExtCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Buttons, ComObj,
  FireDAC.Stan.Async, FireDAC.DApt, Vcl.DBCtrls;

type
  TfrmLancamentosEmLote = class(TForm)
    pnlGeral: TPanel;
    pnlTopo: TPanel;
    cldsPlanilhaLote: TFDMemTable;
    dsPlanilhaLote: TDataSource;
    cldsPlanilhaLoteDESCRICAO: TStringField;
    cldsPlanilhaLoteVALOR_PAGO: TFloatField;
    cldsPlanilhaLoteDATA_VENCIMENTO: TDateField;
    btnPlanilha: TSpeedButton;
    labelBanco: TLabel;
    editCaminhoPlanilha: TEdit;
    btnCarregarPlanilha: TSpeedButton;
    OpenDialog1: TOpenDialog;
    gridLote: TDBGrid;
    btnLimpar: TSpeedButton;
    gbSelecao: TGroupBox;
    labelPesqDespSub: TLabel;
    editPesquisaDespSub: TEdit;
    FDqryLcto: TFDQuery;
    FDqryLctoGASTOS_ID: TFDAutoIncField;
    FDqryLctoCATEGORIA_FK: TIntegerField;
    FDqryLctoSUBCATEGORIA_FK: TIntegerField;
    FDqryLctoCONTA_FK: TIntegerField;
    FDqryLctoLANCAMENTO: TStringField;
    FDqryLctoVALOR_PAGO: TSingleField;
    FDqryLctoVALOR_PREVISTO: TSingleField;
    FDqryLctoNOTA_FISCAL: TIntegerField;
    FDqryLctoCHEQUE: TIntegerField;
    FDqryLctoCHEQUE_COMPENSADO: TStringField;
    FDqryLctoDATA_VENCIMENTO: TDateField;
    FDqryLctoDATA_PAGAMENTO: TDateField;
    FDqryLctoPAGO: TIntegerField;
    FDqryLctoCATEGORIA_ID: TIntegerField;
    FDqryLctoCATEGORIA: TStringField;
    FDqryLctoSUBCATEGORIA_ID: TIntegerField;
    FDqryLctoSUBCATEGORIA: TStringField;
    FDqryLctoCONTA_ID: TIntegerField;
    FDqryLctoCONTA: TStringField;
    FDqryLctoFORMA_DE_PAGAMENTO_ID: TIntegerField;
    FDqryLctoFORMA_DE_PAGAMENTO: TStringField;
    FDqryLctoOBS: TStringField;
    FDqryLctoDATA_CADASTRO: TDateField;
    FDqryLctoFORMA_DE_PAGAMENTO_FK: TIntegerField;
    FDqryLctoENTRADA_ID: TIntegerField;
    FDqryLctoSITUACAO_STATUS: TStringField;
    FDqryLctoUSERID: TIntegerField;
    dsLcto: TDataSource;
    FDtcLcto: TFDTransaction;
    labelConta: TLabel;
    dsContas: TDataSource;
    FDqryContas: TFDQuery;
    FDqryContasCONTA_ID: TIntegerField;
    FDqryContasDESCRICAO: TStringField;
    cmbContas: TDBComboBox;
    btnSalvar: TBitBtn;
    procedure btnPlanilhaClick(Sender: TObject);
    procedure btnCarregarPlanilhaClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure editPesquisaDespSubKeyPress(Sender: TObject; var Key: Char);
    procedure editPesquisaDespSubDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
  private

    { Private declarations }
  public
    { Public declarations }
    procedure CarregarDadosDoExcel;
  end;

var
  frmLancamentosEmLote: TfrmLancamentosEmLote;

implementation

{$R *.dfm}

uses UfrmLancamentos, UfrmPesqDespesas, UfrmPrincipal;

procedure TfrmLancamentosEmLote.CarregarDadosDoExcel;

var
  ExcelApp: Variant;
  Planilha: Variant;
  Linha: Integer;
  NomePlanilha, NomeArquivo: String;
begin
  try
    try
      ExcelApp := CreateOleObject('Excel.Application');
      // Cria uma inst�ncia do Excel
      ExcelApp.Workbooks.Open(editCaminhoPlanilha.Text);
      // Substitua pelo caminho da sua planilha

      NomePlanilha := ExtractFileName(editCaminhoPlanilha.Text);

      Planilha := ExcelApp.Worksheets['Planilha1'];
      // Substitua 'Planilha' pelo nome da sua planilha

      cldsPlanilhaLote.EmptyDataSet;
      gridLote.DataSource := nil;

      // Adiciona os campos ao FDMemTable baseado nas colunas da planilha
      for Linha := 2 to Planilha.UsedRange.Rows.Count - 1 do
      begin
        // Adiciona os registros nas linhas seguintes
        cldsPlanilhaLote.Append;
        cldsPlanilhaLote.Fields[0].AsString := Planilha.Cells[Linha, 1];
        cldsPlanilhaLote.Fields[1].AsFloat := Planilha.Cells[Linha, 2];
        cldsPlanilhaLote.Fields[2].AsDateTime := Planilha.Cells[Linha, 3];
        // ... atribua os outros campos conforme necess�rio
        cldsPlanilhaLote.Post;
      end;
    finally
      ExcelApp.Quit; // Fecha o Excel
      ExcelApp := Unassigned; // Libera a inst�ncia do Excel
      gridLote.DataSource := dsPlanilhaLote;
      cldsPlanilhaLote.First;
    end;
  Except
    On E: Exception do
    begin
      MessageDlg('Por favor, escolha um documento v�lido para ser aberto.' + #13
        + #13 + 'Motivo do erro:' + #13 + E.Message, TMsgDlgType.mtWarning,
        [TMsgDlgBtn.mbOK], 0);

      if not(VarIsEmpty(ExcelApp)) then
        ExcelApp.Quit; // Fecha o Excel
      ExcelApp := Unassigned; // Libera a inst�ncia do Excel
      Abort;
    end;
  end;
end;

procedure TfrmLancamentosEmLote.editPesquisaDespSubDblClick(Sender: TObject);
begin
  if not(dsLcto.State in [dsEdit, dsInsert]) then
    FDqryLcto.Insert;
  frmPesqDespSub.setarEditFoco := 'cadastro em lote';
  frmPesqDespSub.ShowModal;
end;

procedure TfrmLancamentosEmLote.editPesquisaDespSubKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    if not(dsLcto.State in [dsEdit, dsInsert]) then
      FDqryLcto.Insert;
    frmPesqDespSub.setarEditFoco := 'cadastro em lote';
    frmPesqDespSub.ShowModal;
    Key := #0;
  end;
end;

procedure TfrmLancamentosEmLote.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  FDqryLcto.Close;
  FDqryContas.Close;
end;

procedure TfrmLancamentosEmLote.FormShow(Sender: TObject);
begin
  FDqryLcto.Open();
  FDqryContas.Open();

  FDqryContas.First;
  while (not FDqryContas.Eof) do
  begin
    cmbContas.Items.Add(FDqryContas.FieldByName('DESCRICAO').AsString);
    FDqryContas.Next;
  end;
  FDqryContas.First;
end;

procedure TfrmLancamentosEmLote.btnCarregarPlanilhaClick(Sender: TObject);
begin
  if editCaminhoPlanilha.Text = '' then
  begin
    MessageDlg('Por favor, escolha um documento v�lido para ser aberto', TMsgDlgType.mtWarning,
      [TMsgDlgBtn.mbOK], 0);
    Exit;
  end;

  CarregarDadosDoExcel;
end;

procedure TfrmLancamentosEmLote.btnLimparClick(Sender: TObject);
begin
  cldsPlanilhaLote.EmptyDataSet;
end;

procedure TfrmLancamentosEmLote.btnPlanilhaClick(Sender: TObject);
begin
  if OpenDialog1.Execute() then;
  editCaminhoPlanilha.Text := OpenDialog1.FileName;
end;

end.
