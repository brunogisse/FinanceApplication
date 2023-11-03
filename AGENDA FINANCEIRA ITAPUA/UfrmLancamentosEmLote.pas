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
    cldsPlanilhaLoteDATA: TDateField;
    cldsPlanilhaLoteDESCRICAO: TStringField;
    cldsPlanilhaLoteVALOR: TFloatField;
    lblQuantidade: TLabel;
    Label1: TLabel;
    cmbFormaPgto: TDBComboBox;
    FDqryFormaPgto: TFDQuery;
    FDqryFormaPgtoFORMA_DE_PAGAMENTO_ID: TIntegerField;
    FDqryFormaPgtoDESCRICAO: TStringField;
    dsFormaPgto: TDataSource;
    procedure btnPlanilhaClick(Sender: TObject);
    procedure btnCarregarPlanilhaClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
    procedure editPesquisaDespSubKeyPress(Sender: TObject; var Key: Char);
    procedure editPesquisaDespSubDblClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
  private
    function LimparNumero(Str: string): string;

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
  DataStr: string;
  DataValida: TDateTime;
  ValorStr: string;
  ValorFloat: Double;
  DescricaoConcatenada: String;
begin
  try
    try
      ExcelApp := CreateOleObject('Excel.Application');
      ExcelApp.Workbooks.Open(editCaminhoPlanilha.Text);
      NomePlanilha := ExtractFileName(editCaminhoPlanilha.Text);
      Planilha := ExcelApp.Worksheets['Planilha1'];
      cldsPlanilhaLote.EmptyDataSet;
      gridLote.DataSource := nil;

      for Linha := 2 to Planilha.UsedRange.Rows.Count do
      begin
        DataStr := VarToStr(Planilha.Cells[Linha, 1]);
        DescricaoConcatenada := '';

        //Caso a linha de baixo da planilha tenha data vazia, ou seja, ainda perten�a ao registro de cima, ent�o edita concatena a descri��o
        if (DataStr = '') then
        begin
          cldsPlanilhaLote.Last;
          DescricaoConcatenada := cldsPlanilhaLoteDESCRICAO.AsString;
          DescricaoConcatenada := DescricaoConcatenada + ' - ' + VarToStr(Planilha.Cells[Linha, 2]);
          cldsPlanilhaLote.Edit;
          cldsPlanilhaLote.Fields[1].AsString := DescricaoConcatenada;
          cldsPlanilhaLote.Post;
        end
        else  //se houver data, ele adiciona novo registro..
        begin
          cldsPlanilhaLote.Append;

          DataValida := StrToDate(DataStr);
          cldsPlanilhaLote.Fields[0].AsDateTime := DataValida;
          cldsPlanilhaLote.Fields[1].AsString := Planilha.Cells[Linha, 2];

          ValorStr := LimparNumero(Planilha.Cells[Linha, 3]);
          ValorFloat := StrToFloat(ValorStr);
          cldsPlanilhaLote.Fields[2].AsFloat := ValorFloat;

          cldsPlanilhaLote.Post;
        end;
      end;
    finally
      ExcelApp.Quit;
      ExcelApp := Unassigned;
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
        ExcelApp.Quit;
      ExcelApp := Unassigned;
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
  FDqryFormaPgto.Close;
end;

procedure TfrmLancamentosEmLote.FormShow(Sender: TObject);
begin
  FDqryLcto.Open();
  FDqryContas.Open();
  FDqryFormaPgto.Open();

  FDqryContas.First;
  while (not FDqryContas.Eof) do
  begin
    cmbContas.Items.Add(FDqryContas.FieldByName('DESCRICAO').AsString);
    FDqryContas.Next;
  end;
  FDqryContas.First;

  FDqryFormaPgto.First;
  while (not FDqryFormaPgto.Eof) do
  begin
    cmbFormaPgto.Items.Add(FDqryFormaPgto.FieldByName('DESCRICAO').AsString);
    FDqryFormaPgto.Next;
  end;
  FDqryFormaPgto.First;

end;

procedure TfrmLancamentosEmLote.btnCarregarPlanilhaClick(Sender: TObject);
begin
  if editCaminhoPlanilha.Text = '' then
  begin
    MessageDlg('Por favor, escolha um documento v�lido para ser aberto',
      TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
    Exit;
  end;

  CarregarDadosDoExcel;
  lblQuantidade.Caption := lblQuantidade.Caption +
    IntToStr(cldsPlanilhaLote.RecordCount);
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

procedure TfrmLancamentosEmLote.btnSalvarClick(Sender: TObject);
var
  CategoriaID, SubCategoriaID : Integer;
begin
  CategoriaID    := FDqryLcto['CATEGORIA_FK'];
  SubCategoriaID := FDqryLcto['SUBCATEGORIA_FK'];

  cldsPlanilhaLote.First;
  while not cldsPlanilhaLote.Eof do
  begin
    if not (dsLcto.State in [dsInsert]) then
    begin
      FDqryLcto.Insert;
      FDqryLcto['CATEGORIA_FK'] := CategoriaID;
      FDqryLcto['SUBCATEGORIA_FK'] := SubCategoriaID;
    end;
    FDqryLcto['CONTA_FK'] := FDqryContas['CONTA_ID'];
    FDqryLcto['FORMA_DE_PAGAMENTO_FK'] := FDqryFormaPgto['FORMA_DE_PAGAMENTO_ID'];
    FDqryLcto['USERID'] := frmPrincipal.FDqryLogin['LOGIN_ID'];
    FDqryLcto.FieldByName('LANCAMENTO').asstring := cldsPlanilhaLote.FieldByName('DESCRICAO').AsString;
    FDqryLcto['DATA_VENCIMENTO'] := cldsPlanilhaLote.FieldByName('DATA').AsDateTime;
    FDqryLcto['DATA_CADASTRO'] := Now;
    FDqryLcto['VALOR_PREVISTO'] := cldsPlanilhaLote.FieldByName('VALOR').AsFloat;
    FDqryLcto.FieldByName('VALOR_PAGO').AsFloat := cldsPlanilhaLote.FieldByName('VALOR').AsFloat;
    FDqryLcto['CHEQUE'] := 0;
    FDqryLcto['CHEQUE_COMPENSADO'] := 'N';
    FDqryLcto['NOTA_FISCAL'] := 0;
    FDqryLcto['ENTRADA_ID'] := 0;
    FDqryLcto['DATA_PAGAMENTO'] := cldsPlanilhaLote.FieldByName('DATA').AsDateTime;
    FDqryLcto['PAGO'] := 1;
    FDqryLcto.Post;
    cldsPlanilhaLote.Next;
  end;

   try
    FDtcLcto.CommitRetaining;
  except
    FDtcLcto.RollbackRetaining;
  end;
end;

function TfrmLancamentosEmLote.LimparNumero(Str: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Str) do
  begin
    if (Str[i] >= '0') and (Str[i] <= '9') then
      Result := Result + Str[i]
    else if Str[i] = ',' then
      Result := Result + ',';
  end;
end;

end.