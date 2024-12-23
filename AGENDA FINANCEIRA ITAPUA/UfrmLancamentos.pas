unit UfrmLancamentos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Data.DB,
  Vcl.Grids, Vcl.DBGrids, Vcl.Imaging.pngimage, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.DBCtrls,
  Vcl.Mask,
  Vcl.Buttons, frxClass, frxDBSet, StrUtils, frxExportPDF, {frxExportBaseDialog}  {frxExportMail} frxExportBaseDialog
  {frxExportPDF}, ComObj, Math;

type
  TfrmLancamento = class(TForm)
    Panel1: TPanel;
    PageControlLancamentos: TPageControl;
    Aba1: TTabSheet;
    Aba2: TTabSheet;
    btnSair: TImage;
    FDtcLcto: TFDTransaction;
    FDqryLcto: TFDQuery;
    dsLcto: TDataSource;
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
    dsFormaPgto: TDataSource;
    dsSubdespesa: TDataSource;
    dsDespesa: TDataSource;
    dsContas: TDataSource;
    FDqryFormaPgto: TFDQuery;
    FDqrySubdespesa: TFDQuery;
    FDqryDespesa: TFDQuery;
    FDqryContas: TFDQuery;
    FDqrySubdespesaSUBCATEGORIA_ID: TIntegerField;
    FDqrySubdespesaDESCRICAO: TStringField;
    FDqrySubdespesaVALOR_MAXIMO: TSingleField;
    FDqrySubdespesaCATEGORIA_FK: TIntegerField;
    FDqrySubdespesaCATEGORIA_ID: TIntegerField;
    FDqrySubdespesaCATEGORIA: TStringField;
    gbCadastro: TGroupBox;
    labelConta: TLabel;
    cmbContas: TDBLookupComboBox;
    editPesquisaDespSub: TEdit;
    labelPesqDespSub: TLabel;
    dataPrevista: TDateTimePicker;
    labelDataPrevista: TLabel;
    labelLcto: TLabel;
    editDesricao: TDBEdit;
    labelValorPrev: TLabel;
    gbDadosPagos: TGroupBox;
    Label1: TLabel;
    cmbFormaPgto: TDBLookupComboBox;
    gbCheque: TGroupBox;
    editCheque: TDBEdit;
    labelCheque: TLabel;
    labelCheqComp: TLabel;
    editChCompensado: TDBEdit;
    painelBottom: TPanel;
    memoOBS: TDBMemo;
    gridLancamento: TDBGrid;
    dataPago: TDateTimePicker;
    labelDataPago: TLabel;
    labelValorPago: TLabel;
    editValorPago: TDBEdit;
    FDqryFormaPgtoFORMA_DE_PAGAMENTO_ID: TIntegerField;
    FDqryFormaPgtoDESCRICAO: TStringField;
    FDqryContasCONTA_ID: TIntegerField;
    FDqryContasDESCRICAO: TStringField;
    FDqryDespesaCATEGORIA_ID: TIntegerField;
    FDqryDespesaDESCRICAO: TStringField;
    cboxConfirmarPgto: TCheckBox;
    FDqrySomaSubPP: TFDQuery;
    dsSomaSubPP: TDataSource;
    FDqryValidarNF: TFDQuery;
    dsValidarNF: TDataSource;
    FDqryValidarNFNOTA_FISCAL: TIntegerField;
    FDqryValidarNFDESCRICAO: TStringField;
    dataBancoInicio: TDateTimePicker;
    dataBancoFim: TDateTimePicker;
    FDqryLctoDATA_CADASTRO: TDateField;
    btnPesquisar: TBitBtn;
    cboxINICIO: TCheckBox;
    labelEntre: TLabel;
    reportLancamento: TfrxReport;
    dtsReportLancamento: TfrxDBDataset;
    gbPesquisa: TGroupBox;
    FDqrySOMAsubMAXIMO: TFDQuery;
    dsSOMAsub: TDataSource;
    FDqrySOMAsubMAXIMOVALOR_MAXIMO: TFloatField;
    gbSubdespesaVALORES: TGroupBox;
    labellegendaValorMax: TLabel;
    labelGBlegendaPago: TLabel;
    labelGBmaximo: TLabel;
    labelGBpago: TLabel;
    FDqrySomaSubPPVALORPREVISTO: TFloatField;
    FDqrySomaSubPPVALORPAGO: TFloatField;
    labelGBlegendaSaldoPrevisto: TLabel;
    labelGBprevisto: TLabel;
    FDqryLctoFORMA_DE_PAGAMENTO_FK: TIntegerField;
    painelRodape: TPanel;
    labelOBS: TLabel;
    labelTOTALprevisto: TLabel;
    labelROTULOtotalPREVISTO: TLabel;
    labelROTULOpago: TLabel;
    labelTOTALpago: TLabel;
    gbBotoes: TGroupBox;
    btnNovo: TImage;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    gbPesquisaPrincipal: TGroupBox;
    btnPagarEmLote: TBitBtn;
    cboxPagarTodas: TCheckBox;
    GroupBox1: TGroupBox;
    btnPesquisaPrevisto: TBitBtn;
    btnRelatorio: TBitBtn;
    NovaSubcategoriaREL: TBitBtn;
    btnClearSub: TBitBtn;
    btnPesqContaMenos: TBitBtn;
    btnPesqContaMais: TBitBtn;
    editContaPesq: TEdit;
    labelContaPesq: TLabel;
    editRELATORIOpesqDS: TEdit;
    labelRelatorioSubcategoria: TLabel;
    cbPago: TComboBox;
    dataPesquisaPrevistoFim: TDateTimePicker;
    dataPesquisaPrevistoInicio: TDateTimePicker;
    labelAt�: TLabel;
    labelDE: TLabel;
    cboxIntervaloData: TCheckBox;
    labelSTATUS: TLabel;
    gbPesqDescNFdoc: TGroupBox;
    rbDescricao: TRadioButton;
    rbNF: TRadioButton;
    rbChequeDocumento: TRadioButton;
    editPesqLancamento: TEdit;
    frxPDFExport1: TfrxPDFExport;
    FDqryCadastroNF: TFDQuery;
    dsCadastroNF: TDataSource;
    FDqryCadastroNFCADASTRO_NF_ID: TIntegerField;
    FDqryCadastroNFFORNECEDOR_ID: TIntegerField;
    FDqryCadastroNFDATA: TDateField;
    FDqryCadastroNFVALOR_NF: TFMTBCDField;
    FDqryCadastroNFNF: TIntegerField;
    FDqryCadastroNFOBS: TStringField;
    FDqryCadastroNFDATA_EMISSAO_NF: TDateField;
    FDqryCadastroNFSTATUS: TStringField;
    labelNotaFiscal: TLabel;
    editValorPrev: TEdit;
    FDqryCadastroNFNF_LANCADA: TStringField;
    FDqryLctoENTRADA_ID: TIntegerField;
    btnGerarParcelas: TBitBtn;
    FDqryLctoSITUACAO_STATUS: TStringField;
    rbStatus: TRadioButton;
    gbSituacaoStatus: TGroupBox;
    rbEmEspera: TRadioButton;
    rbLiberada: TRadioButton;
    btnSituacao: TBitBtn;
    btnAnularNF: TBitBtn;
    btnBuscarCategoria: TBitBtn;
    labelPesquisaGeralCategoria: TLabel;
    rbChequeCompensado: TRadioButton;
    dataChequeInicio: TDateTimePicker;
    dataChequeFim: TDateTimePicker;
    btnPesqLancamento: TBitBtn;
    editNF: TDBEdit;
    rbValor: TRadioButton;
    editValorInicial: TEdit;
    editValorFinal: TEdit;
    gbValores: TGroupBox;
    rbValorPrevisto: TRadioButton;
    rbValorPago: TRadioButton;
    reportConsultaLancamento: TfrxReport;
    dtsReportConsultaLancamento: TfrxDBDataset;
    btnImprimirConsulta: TBitBtn;
    qryLogin: TFDQuery;
    dsLogin: TDataSource;
    qryLoginLOGIN_ID: TIntegerField;
    qryLoginNOME: TStringField;
    qryLoginSENHA: TStringField;
    qryLoginNIVEL: TIntegerField;
    btnCarregarPlanilha: TSpeedButton;
    FDqryLctoUSERID: TIntegerField;
    BitBtn1: TBitBtn;
    ProgressBar1: TProgressBar;
    procedure btnSairClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure editPesquisaDespSubDblClick(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure editNFExit(Sender: TObject);
    procedure gridLancamentoCellClick(Column: TColumn);
    procedure cboxConfirmarPgtoClick(Sender: TObject);
    procedure btnPesquisarClick(Sender: TObject);
    procedure cboxINICIOClick(Sender: TObject);
    procedure btnPesquisaPrevistoClick(Sender: TObject);
    procedure btnRelatorioClick(Sender: TObject);
    procedure NovaSubcategoriaRELClick(Sender: TObject);
    procedure btnClearSubClick(Sender: TObject);
    procedure editPesquisaDespSubKeyPress(Sender: TObject; var Key: Char);
    procedure gridLancamentoDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure cboxIntervaloDataClick(Sender: TObject);
    procedure btnPagarEmLoteClick(Sender: TObject);
    procedure cboxPagarTodasClick(Sender: TObject);
    procedure editValorPagoChange(Sender: TObject);
    procedure editValorPrevChange(Sender: TObject);
    procedure btnPesqLancamentoClick(Sender: TObject);
    procedure editPesqLancamentoKeyPress(Sender: TObject; var Key: Char);
    procedure btnPesqContaMaisClick(Sender: TObject);
    procedure btnPesqContaMenosClick(Sender: TObject);
    procedure cbCadastroNFClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure cbCadastroNFExit(Sender: TObject);
    procedure btnGerarParcelasClick(Sender: TObject);
    procedure btnSituacaoClick(Sender: TObject);
    procedure rbStatusClick(Sender: TObject);
    procedure editDesricaoKeyPress(Sender: TObject; var Key: Char);
    procedure btnAnularNFClick(Sender: TObject);
    procedure btnBuscarCategoriaClick(Sender: TObject);
    procedure editPesqLancamentoExit(Sender: TObject);
    procedure cbPagoClick(Sender: TObject);
    procedure rbValorClick(Sender: TObject);
    procedure rbValorPrevistoClick(Sender: TObject);
    procedure btnImprimirConsultaClick(Sender: TObject);
    procedure btnCarregarPlanilhaClick(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private

    procedure refreshBanco;
    procedure configurarEnables(status: Integer);
    procedure salvarRegistros;
    procedure novoRegistro;
    procedure cancelarOperacao;
    procedure alterarRegistro;
    procedure deletarRegistro;
    function verificarCamposVazios(textoEdit: string): string;
    procedure pesquisaPeriodo(dataInicio, dataFim: TDateTime;
      condicaoPeriodo, condicaoPAGO, condicaoSubcategoria,
      varCondicaoSubcategoria, condicaoConta, varCondicaoConta: string;
      varCondicaoPago: Integer);
    procedure atribuirDataDoDia;
    procedure Totais;
    procedure salvarRegistrosEMLOTE;
    procedure AlterarNFlancada(tipo: string);
    procedure CalcularValorNFentrada;
    procedure allowPrint(status: String);
    procedure procPermitirAlterarExcluir;
    procedure ExportarParaExcel;
    // function FormatarMoeda(valor : string) : string;

    { Private declarations }
  public
    { Public declarations }
  var
    valorMAXIMOsubdespesa: Currency;
    CategoriaPesquisa: string;
    Parcelando: String;

  end;

var
  frmLancamento: TfrmLancamento;
  inicio, fim: TDateTime;
  condicaoPeriodo, condicaoPAGO, condicaoSubcategoria, varCondicaoSubcategoria,
    condicaoConta, varCondicaoConta: string;
  varCondicaoPago: Integer;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmPesqDespesas, UConta, UfrmConfirmarParcelamento,
  UpesquisaCategoria, UfrmLancamentosEmLote;

procedure TfrmLancamento.allowPrint(status: String);
begin
  if status = 'print' then
    btnRelatorio.Enabled := True;
  if status = 'notPrint' then
    btnRelatorio.Enabled := False;
end;

procedure TfrmLancamento.CalcularValorNFentrada;
begin
  // if cbCadastroNF.Text <> '' then
  // editValorPrev.Text := FloatToStr(FDqryCadastroNF['VALOR_NF']);
  // if (FDqryLcto['VALOR_PREVISTO'] > 0) and (cbCadastroNF.Text = '') then
  // editValorPrev.Text := FloatToStr(FDqryLcto['VALOR_PREVISTO']);
end;

procedure TfrmLancamento.AlterarNFlancada(tipo: string);
begin
  with FDqryCadastroNF do
  begin
    Close;
    SQL.Clear;
    SQL.Add('select * from CADASTRO_NF');
    Open;
  end;

  if FDqryCadastroNF.Locate('CADASTRO_NF_ID', FDqryLcto['ENTRADA_ID'], []) then
  begin
    FDqryCadastroNF.Edit;
    if tipo = 'EDIC�O\EXCLUS�O' then
      FDqryCadastroNF['NF_LANCADA'] := 'N�O';
    if (tipo = 'CANCELANDO') or (Parcelando = 'SIM') then
    // Parcelando faz parte do bot�o gerar parcelas, que precisa excluir
      FDqryCadastroNF['NF_LANCADA'] := 'SIM';
    // o registro e atribuir NF_LANCADA para SIM
    FDqryCadastroNF.Post
  end;

  with FDqryCadastroNF do
  begin
    Close;
    SQL.Clear;
    SQL.Add('select * from CADASTRO_NF where (NF_LANCADA = ''N�O'')');
    Open;
  end;

end;

{ function TfrmLancamento.FormatarMoeda(valor: string): string;
  var
  decimais, centena, milhar, milhoes, bilhoes, trilhoes, quadrilhoes: string;
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
  milhar := copy(RightStr(valor, 8), 1, 3);
  milhoes := copy(RightStr(valor, 11), 1, 3);
  bilhoes := copy(RightStr(valor, 14), 1, 3);
  trilhoes := copy(RightStr(valor, 17), 1, 3);
  quadrilhoes := LeftStr(valor, Length(valor) - 17);

  case Length(valor) of
  1:
  Result := '0,0' + valor;
  2:
  Result := '0,' + valor;
  6 .. 8:
  begin
  milhar := LeftStr(valor, Length(valor) - 5);
  Result := milhar + '' + centena + ',' + decimais;
  end;
  9 .. 11:
  begin
  milhoes := LeftStr(valor, Length(valor) - 8);
  Result := milhoes + '' + milhar + '' + centena + ',' + decimais;
  end;
  12 .. 14:
  begin
  bilhoes := LeftStr(valor, Length(valor) - 11);
  Result := bilhoes + '' + milhoes + '' + milhar + '' + centena + ',' + decimais;
  end;
  15 .. 17:
  begin
  trilhoes := LeftStr(valor, Length(valor) - 14);
  Result := trilhoes + '' + bilhoes + '' + milhoes + '' + milhar + '' + centena + ','
  + decimais;
  end;
  18 .. 20:
  begin
  quadrilhoes := LeftStr(valor, Length(valor) - 17);
  Result := quadrilhoes + '' + trilhoes + '' + bilhoes + '' + milhoes + '' + milhar + '.'
  + centena + ',' + decimais;
  end
  else
  Result := LeftStr(valor, Length(valor) - 2) + ',' + decimais;
  end;
  end; }

procedure TfrmLancamento.salvarRegistrosEMLOTE;
var
  valorpago: Currency;
begin
  if MessageBox(Application.Handle, 'Todos os dados exibidos ser�o pagos' + #13
    + 'Esta opera��o � irrevers�vel.', 'Aten��o', MB_YESNO + MB_ICONQUESTION) = mrYes
  then
  begin
    FDqryLcto.First;
    FDqryLcto.DisableControls;
    while not FDqryLcto.Eof do
    begin
      if FDqryLcto['PAGO'] = 0 then
      begin
        valorpago := FDqryLcto['VALOR_PREVISTO'];
        FDqryLcto.Edit;
        FDqryLcto['DATA_PAGAMENTO'] := Now;
        FDqryLcto['PAGO'] := 1;
        FDqryLcto['VALOR_PAGO'] := valorpago;
        FDqryLcto.Post;
        FDqryLcto.Next;
      end;
    end;
    FDqryLcto.EnableControls;
    configurarEnables(0);
    try
      FDtcLcto.CommitRetaining;
    except
      FDtcLcto.RollbackRetaining;
    end;
  end;
end;

procedure TfrmLancamento.Totais;
var
  totalPREVISTO, totalPAGO, saldoPREVISTO, saldoPAGO: Currency;
begin
  totalPREVISTO := 0;
  totalPAGO := 0;
  saldoPREVISTO := 0;
  saldoPAGO := 0;
  FDqryLcto.DisableControls;

  try
    while not FDqryLcto.Eof do
    begin
      totalPREVISTO := totalPREVISTO + FDqryLcto.FieldByName('VALOR_PREVISTO')
        .AsCurrency;
      totalPAGO := totalPAGO + FDqryLcto.FieldByName('VALOR_PAGO').AsCurrency;
      FDqryLcto.Next;
    end;
  finally
    FDqryLcto.EnableControls;
    labelTOTALprevisto.Caption := FormatFloat('R$,0.00', totalPREVISTO);
    labelTOTALpago.Caption := FormatFloat('R$,0.00,', totalPAGO);
  end;

  if (editRELATORIOpesqDS.Text <> '') and (FDqryLcto.RecordCount > 0) then
  begin
    gbSubdespesaVALORES.Visible := True;
    saldoPREVISTO := valorMAXIMOsubdespesa - totalPREVISTO;
    saldoPAGO := valorMAXIMOsubdespesa - totalPAGO;
    labelGBprevisto.Caption := FormatFloat('R$,0.00', saldoPREVISTO);
    labelGBpago.Caption := FormatFloat('R$,0.00', saldoPAGO);
    labelGBmaximo.Caption := FormatFloat('R$,0.00', valorMAXIMOsubdespesa);
  end
  else
    gbSubdespesaVALORES.Visible := False;
end;

procedure TfrmLancamento.atribuirDataDoDia;
begin
  dataPrevista.Date := Now;
  dataPago.Date := Now;
  // dataPesquisaPrevistoInicio.Date := Now;
  // dataPesquisaPrevistoFim.Date := Now;
end;

procedure TfrmLancamento.BitBtn1Click(Sender: TObject);
begin
  ExportarParaExcel;
end;

procedure TfrmLancamento.btnRelatorioClick(Sender: TObject);
var
  caminhoRelatorio: string;
begin
  caminhoRelatorio := ExtractFilePath(Application.ExeName);
  reportLancamento.LoadFromFile(caminhoRelatorio + 'Lan�amento.fr3');
  reportLancamento.Variables['dtInicio'] :=
    QuotedStr(DateToStr(dataPesquisaPrevistoInicio.Date));
  reportLancamento.Variables['dtFim'] :=
    QuotedStr(DateToStr(dataPesquisaPrevistoFim.Date));
  reportLancamento.ShowReport();
end;

procedure TfrmLancamento.pesquisaPeriodo(dataInicio, dataFim: TDateTime;
  condicaoPeriodo, condicaoPAGO, condicaoSubcategoria, varCondicaoSubcategoria,
  condicaoConta, varCondicaoConta: string; varCondicaoPago: Integer);
begin
  with FDqryLcto do
  begin
    Close;
    SQL.Clear;
    SQL.Add('select ' +
      'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
      + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
      + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
      + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
      + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
      ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
      + ' where ' +
      '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and (REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and (REG.CONTA_ID = CT.CONTA_ID) and (REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) '
      + condicaoPeriodo + '' + condicaoPAGO + '' + condicaoSubcategoria +
      condicaoConta + 'order by REG.DATA_VENCIMENTO');

    ParamByName('INICIO').AsDate := dataInicio;
    ParamByName('FIM').AsDate := dataFim;
    if varCondicaoPago > -1 then
    // par�metro carregado com o valor do checkbox "cbPago" (status). Essa vari�vel traz o valor atribuido no evento do btnPesquisaPrevisto.
      ParamByName('PAGO').AsInteger := varCondicaoPago;
    if varCondicaoSubcategoria <> '' then
    begin
      ParamByName('SUBCATEGORIA').AsString := varCondicaoSubcategoria;
      ParamByName('CATEGORIA').AsString := CategoriaPesquisa;
    end;
    if varCondicaoConta <> '' then
      ParamByName('CONTA').AsString := varCondicaoConta;
    Open;
  end;
end;

procedure TfrmLancamento.deletarRegistro;
var
  auxErro: string;
begin
  PageControlLancamentos.TabIndex := 0;
  if MessageBox(Application.Handle, 'Deseja realmente excluir este registro?',
    'Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
  begin
    try
      AlterarNFlancada('EDIC�O\EXCLUS�O');
      FDqryLcto.Delete;
    except
      on E: exception do
      begin
        auxErro := copy(E.Message, 0, 500);
        ShowMessage('Imposs�vel excluir este lan�amento em raz�o do motivo: '
          + auxErro);
      end;
    end;
  end;
  try
    FDtcLcto.CommitRetaining;
  except
    FDtcLcto.RollbackRetaining;
  end;
end;

procedure TfrmLancamento.Edit1Change(Sender: TObject);
begin
  // editValorPrev.Text := FormatarMoeda(editValorPrev.Text);
  // editValorPrev.SelStart := Length(editValorPrev.Text);
end;

procedure TfrmLancamento.procPermitirAlterarExcluir;
begin
  if (frmPrincipal.FDqryLogin['LOGIN_ID'] <> 1) then
  begin
    if (FDqryLcto['USERID'] <> frmPrincipal.FDqryLogin['LOGIN_ID']) then
    begin
      qryLogin.Close;
      qryLogin.ParamByName('ID').AsInteger := FDqryLcto['USERID'];
      qryLogin.Open();
      MessageDlg('N�o h� permiss�o para editar esse lan�amento.' + #13 + #13 +
        'Apenas os usu�rios que fizeram o lan�amento podem alter�-los ou exclu�-los.'
        + #13 + #13 + 'Fale com o(a) User ' + qryLogin['NOME'] +
        ' para continuar.', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
      Abort;
    end;
  end;
end;

procedure TfrmLancamento.alterarRegistro;
begin
  PageControlLancamentos.TabIndex := 0;
  AlterarNFlancada('EDIC�O\EXCLUS�O');
  FDqryCadastroNF.Close;
  FDqryCadastroNF.Open;
  FDqryCadastroNF.Locate('CADASTRO_NF_ID', FDqryLcto['ENTRADA_ID'], []);
  FDqryLcto.Edit;

  // atribui os valores j� cadastrados aos campos que n�o est�o ligados ao datasource para serem gravados novamente ou alterados.
  dataPrevista.Date := FDqryLcto['DATA_VENCIMENTO'];
  editValorPrev.Text := FormatFloat('0.00', FDqryLcto['VALOR_PREVISTO']);
  editPesquisaDespSub.Text := FDqryLcto['SUBCATEGORIA'] + ' [' +
    FDqryLcto['CATEGORIA'] + ']';
  if FDqryLcto['DATA_PAGAMENTO'] <> null then
    dataPago.Date := FDqryLcto['DATA_PAGAMENTO'];
  FDqryContas.Locate('CONTA_ID', FDqryLcto['CONTA_FK'], []);
  cmbContas.KeyValue := FDqryContas['CONTA_ID'];
  FDqryFormaPgto.Locate('FORMA_DE_PAGAMENTO_ID',
    FDqryLcto['FORMA_DE_PAGAMENTO_FK'], []);
  cmbFormaPgto.KeyValue := FDqryFormaPgto['FORMA_DE_PAGAMENTO_ID'];
  // if FDqryCadastroNF.Locate('CADASTRO_NF_ID',FDqryLcto['ENTRADA_ID'],[]) then
  // cbCadastroNF.KeyValue := FDqryCadastroNF['CADASTRO_NF_ID'];

  configurarEnables(1);
end;

function TfrmLancamento.verificarCamposVazios(textoEdit: string): string;
begin
  if (editDesricao.Text = '') or (editValorPrev.Text = '') or
    (editPesquisaDespSub.Text = '') or (cmbContas.Text = '') then
  begin
    textoEdit := 'vazio';
    ShowMessage('Antes de salvar, verifique os campos vazios');
  end
  else
  begin
    textoEdit := 'OK';
  end;
  Result := textoEdit;
end;

procedure TfrmLancamento.cancelarOperacao;
begin
  AlterarNFlancada('CANCELANDO');
  FDqryCadastroNF.Close;
  FDqryCadastroNF.Open;
  FDqryLcto.Cancel;
  editPesquisaDespSub.Clear;
  atribuirDataDoDia;
  configurarEnables(0);
end;

procedure TfrmLancamento.cbCadastroNFClick(Sender: TObject);
begin
  CalcularValorNFentrada;
end;

procedure TfrmLancamento.cbCadastroNFExit(Sender: TObject);
begin
  { if cbCadastroNF.Text <> '' then
    Begin
    FDqryValidarNF.Open;
    if FDqryValidarNF.Locate('NOTA_FISCAL',cbCadastroNF.Text,[]) then
    ShowMessage('NF j� cadastrada para a empresa: ' + FDqryValidarNF['DESCRICAO']);
    FDqryValidarNF.Close;
    end;
  }
end;

procedure TfrmLancamento.cboxConfirmarPgtoClick(Sender: TObject);
begin
  if cboxConfirmarPgto.Checked = True then
  begin
    dataPago.Visible := True;
    editValorPago.Visible := True;
    labelDataPago.Visible := True;
    labelValorPago.Visible := True;
  end
  else
  begin
    dataPago.Visible := False;
    editValorPago.Visible := False;
    labelDataPago.Visible := False;
    labelValorPago.Visible := False;
  end;

end;

procedure TfrmLancamento.cboxINICIOClick(Sender: TObject);
begin

  if cboxINICIO.Checked = True then
  begin
    labelEntre.Visible := True;
    dataBancoInicio.Visible := True;
    dataBancoFim.Visible := True;
    btnPesquisar.Visible := True;
  end
  else
  begin
    labelEntre.Visible := False;
    dataBancoInicio.Visible := False;
    dataBancoFim.Visible := False;
    btnPesquisar.Visible := False;
  end;
end;

procedure TfrmLancamento.cboxIntervaloDataClick(Sender: TObject);
begin
  btnPesquisaPrevisto.Click;
end;

procedure TfrmLancamento.cboxPagarTodasClick(Sender: TObject);
begin
  if cboxPagarTodas.Checked = True then
    btnPagarEmLote.Visible := True
  else
    btnPagarEmLote.Visible := False;
end;

procedure TfrmLancamento.cbPagoClick(Sender: TObject);
begin
  allowPrint('notPrint');
end;

procedure TfrmLancamento.novoRegistro;
begin
  PageControlLancamentos.TabIndex := 0;
  editPesquisaDespSub.Text := '';
  configurarEnables(1);
  editDesricao.SetFocus;
  atribuirDataDoDia;
  FDqryLcto.Insert;
end;

procedure TfrmLancamento.salvarRegistros;
var
  textoEdit, situacaoCampo: string;
begin
  PageControlLancamentos.TabIndex := 0;
  situacaoCampo := verificarCamposVazios(textoEdit);
  // vari�vel carregada com a fun��o que verifica se h� campos vazios.
  if situacaoCampo <> 'vazio' then
  begin
    FDqryLcto['CONTA_FK'] := FDqryContas['CONTA_ID'];
    FDqryLcto['FORMA_DE_PAGAMENTO_FK'] := FDqryFormaPgto
      ['FORMA_DE_PAGAMENTO_ID'];
    FDqryLcto['USERID'] := frmPrincipal.FDqryLogin['LOGIN_ID'];
    FDqryLcto['DATA_VENCIMENTO'] := dataPrevista.Date;
    FDqryLcto['DATA_CADASTRO'] := Now;
    FDqryLcto['VALOR_PREVISTO'] := StrToFloat(editValorPrev.Text);
    // if editCheque.Text = '' then
    // FDqryLcto['CHEQUE'] := 0;
    if editChCompensado.Text = '' then
      FDqryLcto['CHEQUE_COMPENSADO'] := 'N';
    // if cbCadastroNF.Text <> '' then
    // begin
    // FDqryLcto['NOTA_FISCAL'] := FDqryCadastroNF['NF'];
    // FDqryLcto['ENTRADA_ID'] := FDqryCadastroNF['CADASTRO_NF_ID'];
    // FDqryCadastroNF.Edit;
    // FDqryCadastroNF['NF_LANCADA'] := 'SIM';
    // FDqryCadastroNF.Post;
    // end;
    if cboxConfirmarPgto.Checked = True then
    begin
      FDqryLcto['DATA_PAGAMENTO'] := dataPago.Date;
      FDqryLcto['PAGO'] := 1;
    end
    else
    begin
      FDqryLcto['PAGO'] := 0;
      FDqryLcto['VALOR_PAGO'] := 0;
    end;
    FDqryLcto.Post;
    configurarEnables(0);
    try
      FDtcLcto.CommitRetaining;
    except
      FDtcLcto.RollbackRetaining;
    end;
    refreshBanco;
    btnPesquisar.Click;
  end;
end;

procedure TfrmLancamento.configurarEnables(status: Integer);
begin
  if status = 0 then
  begin
    btnNovo.Enabled := True;
    btnAlterar.Enabled := True;
    btnExcluir.Enabled := True;
    btnCancelar.Enabled := False;
    btnSalvar.Enabled := False;
    gbCadastro.Enabled := False;
    memoOBS.Enabled := False;
    btnGerarParcelas.Enabled := True;
  end
  else
  begin
    btnNovo.Enabled := False;
    btnAlterar.Enabled := False;
    btnExcluir.Enabled := False;
    btnCancelar.Enabled := True;
    btnSalvar.Enabled := True;
    gbCadastro.Enabled := True;
    memoOBS.Enabled := True;
    btnGerarParcelas.Enabled := False;
  end;
end;

procedure TfrmLancamento.rbStatusClick(Sender: TObject);
begin

  if gbValores.Visible = True then
    gbValores.Visible := False;

  editPesqLancamento.Clear;
  editPesqLancamento.SetFocus;
end;

procedure TfrmLancamento.rbValorClick(Sender: TObject);
begin

  gbValores.Visible := True;
  editValorInicial.Clear;
  editValorFinal.Clear;
  editValorInicial.SetFocus;
  rbValorPrevisto.Checked := True;

  editPesqLancamento.Clear;

end;

procedure TfrmLancamento.rbValorPrevistoClick(Sender: TObject);
begin
  editValorInicial.SetFocus;
end;

procedure TfrmLancamento.refreshBanco;
var
  dataInicio, dataFim: TDateTime;
begin
  FDqryContas.Close;
  FDqryContas.Open;
  FDqrySubdespesa.Close;
  FDqrySubdespesa.Open;
  FDqryDespesa.Close;
  FDqryDespesa.Open;
  FDqryFormaPgto.Close;
  FDqryFormaPgto.Open;
  FDqryCadastroNF.Close;
  FDqryCadastroNF.Open;
  dataInicio := IncMonth(Date, -6);
  dataFim := Now;
  dataBancoInicio.Date := dataInicio;
  dataBancoFim.Date := dataFim;
  with FDqryLcto do
  begin
    Close;
    ParamByName('INICIO').AsDate := dataBancoInicio.Date;
    ParamByName('FIM').AsDate := dataBancoFim.Date;
    Open;
  end;
end;

procedure TfrmLancamento.btnPagarEmLoteClick(Sender: TObject);
begin
  salvarRegistrosEMLOTE;
  FDqryLcto.Close;
  FDqryLcto.Open;
  refreshBanco;
  frmPrincipal.btnAtualizarVencimentos.Click;
end;

procedure TfrmLancamento.btnPesqContaMaisClick(Sender: TObject);
begin
  editContaPesq.Enabled := True;
  frmConta.Pesquisa := 'pesquisando';
  frmConta.ShowModal;
end;

procedure TfrmLancamento.btnPesqContaMenosClick(Sender: TObject);
begin
  editContaPesq.Clear;
  editContaPesq.Enabled := False;
end;

procedure TfrmLancamento.btnPesqLancamentoClick(Sender: TObject);
var
  paymentCondition, dataInicio, SUBCATEGORIA, CONTA: String;

begin
  allowPrint('print');
  if cbPago.Text = 'Pago' then
    paymentCondition := ' and (REG.PAGO = ''1'') ';
  if cbPago.Text = 'N�o Pago' then
    paymentCondition := ' and (REG.PAGO = ''0'') ';
  if cbPago.Text = '(TODOS)' then
    paymentCondition := '';

   if editRELATORIOpesqDS.Text <> '' then
    SUBCATEGORIA := '(S.DESCRICAO = ' + QuotedStr(editRELATORIOpesqDS.Text) + ') and '
  else
    SUBCATEGORIA := '';

  if editContaPesq.Text <> '' then
    CONTA := '(CT.DESCRICAO = ' + QuotedStr(editContaPesq.Text) + ') and '
  else
    CONTA := '';

  if rbDescricao.Checked = True then
  begin
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' + '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' +
        '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and ' +
        '(REG.CONTA_ID = CT.CONTA_ID) ' + paymentCondition + 'and ' +
        '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) ' +
        ' and (DATA_VENCIMENTO between :INICIO and :FIM) and ' + SUBCATEGORIA + CONTA +
        ' REG.DESCRICAO like ' + QuotedStr('%' + editPesqLancamento.Text + '%')
        + 'order by REG.DATA_VENCIMENTO');
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
     // showmessage(SQL.Text);
      Open;
    end;
  end;

  if rbNF.Checked = True then
  begin
    dataInicio := DateToStr(dataChequeInicio.Date);
    dataChequeInicio.Date := StrToDate('01/01/2018');
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE, SITUACAO_STATUS,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' + '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' +
        '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and ' +
        '(REG.CONTA_ID = CT.CONTA_ID) and ' +  SUBCATEGORIA + CONTA +
        '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and '
        // +'(DATA_CADASTRO between :INICIO and :FIM) and REG.NOTA_FISCAL like ' + QuotedStr('%'+ editPesqLancamento.Text +'%') + 'order by REG.DATA_VENCIMENTO');
        + '(DATA_CADASTRO between :INICIO and :FIM) and ' +
        'REG.NOTA_FISCAL = :NF order by REG.DATA_VENCIMENTO');
      ParamByName('NF').AsInteger := StrToInt(editPesqLancamento.Text);
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
      Open;

      dataChequeInicio.Date := StrToDate(dataInicio);
    end;
  end;

  if rbChequeDocumento.Checked = True then
  begin
    dataInicio := DateToStr(dataChequeInicio.Date);
    dataChequeInicio.Date := StrToDate('01/01/2018');
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' + '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' +
        '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and ' +
        '(REG.CONTA_ID = CT.CONTA_ID) and ' +
        '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and ' + SUBCATEGORIA + CONTA +
        '(DATA_VENCIMENTO between :INICIO and :FIM) and ' + 'REG.CHEQUE like ' +
        QuotedStr('%' + editPesqLancamento.Text + '%') +
        'order by REG.DATA_VENCIMENTO');
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
      Open;

      dataChequeInicio.Date := StrToDate(dataInicio);

    end;
  end;

  if (rbValor.Checked = True) and (rbValorPrevisto.Checked = True) then
  begin
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' + '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' +
        '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and ' +
        '(REG.CONTA_ID = CT.CONTA_ID) and ' +
        '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and ' + SUBCATEGORIA + CONTA +
        '(DATA_VENCIMENTO between :INICIO and :FIM) and ' +
        '(REG.VALOR_PREVISTO between :VALORINICIO and :VALORFIM) ' +
        'order by REG.DATA_VENCIMENTO');
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
      ParamByName('VALORINICIO').AsFloat := StrToFloat(editValorInicial.Text);
      ParamByName('VALORFIM').AsFloat := StrToFloat(editValorFinal.Text);
      Open;
    end;
  end;

  if (rbValor.Checked = True) and (rbValorPago.Checked = True) then
  begin
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' + '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' +
        '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and ' +
        '(REG.CONTA_ID = CT.CONTA_ID) and ' +
        '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and ' + SUBCATEGORIA + CONTA +
        '(DATA_PAGAMENTO between :INICIO and :FIM) and ' +
        '(REG.VALOR_PAGO between :VALORINICIO and :VALORFIM) ' +
        'order by REG.DATA_VENCIMENTO');
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
      ParamByName('VALORINICIO').AsFloat := StrToFloat(editValorInicial.Text);
      ParamByName('VALORFIM').AsFloat := StrToFloat(editValorFinal.Text);
      Open;
    end;
  end;

  if rbStatus.Checked = True then
  begin
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' +
        '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and (REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and (REG.CONTA_ID = CT.CONTA_ID)  and ' + SUBCATEGORIA + CONTA + '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and (DATA_CADASTRO between :INICIO and :FIM) and REG.SITUACAO_STATUS like '
        + QuotedStr('%' + editPesqLancamento.Text + '%') +
        'order by REG.DATA_VENCIMENTO');
      ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      ParamByName('FIM').AsDate := dataChequeFim.Date;
      Open;
    end;
  end;

  if rbChequeCompensado.Checked = True then
  begin
    with FDqryLcto do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select ' +
        'REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK,'
        + 'REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL, REG.CHEQUE,'
        + 'REG.CHEQUE_COMPENSADO, REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, SITUACAO_STATUS,'
        + 'C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO,'
        + 'REG.OBS, REG.DATA_CADASTRO, REG.USERID' + ' from ' +
        ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP'
        + ' where ' +
        '(REG.CATEGORIA_ID = C.CATEGORIA_ID) and ' + SUBCATEGORIA + CONTA + '(REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and (REG.CONTA_ID = CT.CONTA_ID) and '
        + '(REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and REG.CHEQUE_COMPENSADO like '
        + QuotedStr('%' + editPesqLancamento.Text + '%') +
        ' order by REG.DATA_VENCIMENTO');
      // ParamByName('INICIO').AsDate := dataChequeInicio.Date;
      // ParamByName('FIM').AsDate := dataChequeFim.Date;
      Open;
    end;
  end;

  Totais;

end;

procedure TfrmLancamento.btnPesquisaPrevistoClick(Sender: TObject);
begin

  allowPrint('print');

  if cboxIntervaloData.Checked = True then
  begin
    dataPesquisaPrevistoInicio.Date := IncMonth(Date, -6);
    inicio := dataPesquisaPrevistoInicio.Date;
    dataPesquisaPrevistoInicio.Enabled := False;
    dataPesquisaPrevistoFim.Enabled := False;
  end
  else
  begin
    dataPesquisaPrevistoInicio.Enabled := True;
    dataPesquisaPrevistoFim.Enabled := True;
    inicio := dataPesquisaPrevistoInicio.Date;
  end;
  fim := dataPesquisaPrevistoFim.Date;
  condicaoPAGO := 'and (PAGO = :PAGO)';
  condicaoPeriodo := 'and (DATA_VENCIMENTO between :INICIO and :FIM) ';

  if editRELATORIOpesqDS.Text <> '' then
  begin
    condicaoSubcategoria :=
      'and (S.DESCRICAO = :SUBCATEGORIA) and (C.DESCRICAO = :CATEGORIA)';
    varCondicaoSubcategoria := editRELATORIOpesqDS.Text;
    editRELATORIOpesqDS.Enabled := False;
  end
  else
  begin
    condicaoSubcategoria := '';
    varCondicaoSubcategoria := '';
    editRELATORIOpesqDS.Text := '';
    editRELATORIOpesqDS.Enabled := True;
  end;

  if editContaPesq.Text <> '' then
  begin
    condicaoConta := ' and (CT.DESCRICAO = :CONTA) ';
    varCondicaoConta := editContaPesq.Text;
    editContaPesq.Enabled := False;
  end
  else
  begin
    condicaoConta := '';
    varCondicaoConta := '';
    editContaPesq.Text := '';
    editContaPesq.Enabled := True;
  end;

  if cbPago.Text = 'Pago' then
    varCondicaoPago := 1;
  if cbPago.Text = 'N�o Pago' then
    varCondicaoPago := 0;
  if cbPago.Text = '(TODOS)' then
  begin
    varCondicaoPago := -1;
    condicaoPAGO := '';
  end;
  pesquisaPeriodo(inicio, fim, condicaoPeriodo, condicaoPAGO,
    condicaoSubcategoria, varCondicaoSubcategoria, condicaoConta,
    varCondicaoConta, varCondicaoPago);
  Totais;
  cboxINICIO.Checked := False;
  FDqryLcto.First;
end;

procedure TfrmLancamento.btnPesquisarClick(Sender: TObject);
var
  inicio, fim: TDateTime;
  condicao: string;
begin
  inicio := dataBancoInicio.Date;
  fim := dataBancoFim.Date;
  condicao := ' and (DATA_CADASTRO between :INICIO and :FIM) ';
  pesquisaPeriodo(inicio, fim, condicao, '', '', '', '', '', -1);
  Totais;
  FDqryLcto.First;
end;

procedure TfrmLancamento.btnAlterarClick(Sender: TObject);
begin
//  procPermitirAlterarExcluir;
  alterarRegistro;
  gridLancamento.Enabled := False;
  if FDqryLcto['PAGO'] = 1 then
    cboxConfirmarPgto.Checked := True
  else
    cboxConfirmarPgto.Checked := False;
end;

procedure TfrmLancamento.btnAnularNFClick(Sender: TObject);
begin
  // cbCadastroNF.KeyValue := -1;
  // CalcularValorNFentrada;
end;

procedure TfrmLancamento.btnBuscarCategoriaClick(Sender: TObject);
begin
  frmPesquisaCategoria.ShowModal;
end;

procedure TfrmLancamento.btnCancelarClick(Sender: TObject);
begin
  cancelarOperacao;
  gridLancamento.Enabled := True;
  cboxConfirmarPgto.Checked := False;
  editValorPrev.Clear;
end;

procedure TfrmLancamento.btnCarregarPlanilhaClick(Sender: TObject);
begin
  try
    Application.CreateForm(TfrmLancamentosEmLote, frmLancamentosEmLote);
    frmLancamentosEmLote.ShowModal;
  finally
    FreeAndNil(frmLancamentosEmLote);
    Close;
  end;
end;

procedure TfrmLancamento.btnClearSubClick(Sender: TObject);
begin
  editRELATORIOpesqDS.Clear;
  gbSubdespesaVALORES.Visible := False;
end;

procedure TfrmLancamento.btnExcluirClick(Sender: TObject);
begin
  procPermitirAlterarExcluir;
  deletarRegistro;
  cboxConfirmarPgto.Checked := False;
end;

procedure TfrmLancamento.btnGerarParcelasClick(Sender: TObject);
var
  TextoQTDEparcela: String;
  Parcelamento, I: Integer;
  LctoID: Integer;
  USERID: Integer;
  CategoriaID: Integer;
  SubcategoriaID: Integer;
  ContaID: Integer;
  FormaDEpagamentoID: Integer;
  Descricao: String;
  valorpago: double;
  Cheque: Integer;
  ChequeCompensado: string;
  DataVencimento: TDateTime;
  // DataPagamento : TDateTime;
  Pago: Integer;
  OBS: string;
  ValorPrevisto: double;
  NF: Integer;
  DataCadastro: TDateTime;
  EntradaID: Integer;
  ValorParcelado: double;

begin
  if MessageBox(Application.Handle,
    'Deseja realmente gerar parcelas para este lan�amento?   ', 'Confirma��o',
    MB_YESNO + MB_ICONQUESTION) = mrYes then
  begin
    // esse escopo carrega as vari�veis com o lan�amento original, que se tornar� dividido em parcelas.
    LctoID := FDqryLcto['GASTOS_ID'];
    Parcelamento := StrToInt(InputBox('Informe', 'Quantas parcelas?', ''));
    ValorPrevisto := FDqryLcto['VALOR_PREVISTO'];
    ValorParcelado := ValorPrevisto / Parcelamento;

    frmConfirmarParcelamentos.MemoInform.Text := 'Ser�o geradas ' + #13 + #13 +
      IntToStr(Parcelamento) + ' parcelas de ' + FormatFloat('R$ ,0.00,',
      ValorParcelado) + '';
    frmConfirmarParcelamentos.ShowModal;
    if frmConfirmarParcelamentos.ConfirmarParcelamento = False then
      Abort;
    CategoriaID := FDqryLcto['CATEGORIA_FK'];
    SubcategoriaID := FDqryLcto['SUBCATEGORIA_FK'];
    ContaID := FDqryLcto['CONTA_FK'];
    FormaDEpagamentoID := FDqryLcto['FORMA_DE_PAGAMENTO_FK'];

    Descricao := FDqryLcto['LANCAMENTO'];
    valorpago := FDqryLcto['VALOR_PAGO'];
    USERID := FDqryLcto['USERID'];
    if FDqryLcto['CHEQUE'] <> null then
      Cheque := FDqryLcto['CHEQUE'];
    if FDqryLcto['CHEQUE_COMPENSADO'] <> null then
      ChequeCompensado := FDqryLcto['CHEQUE_COMPENSADO'];
    DataVencimento := IncMonth(FDqryLcto['DATA_VENCIMENTO'], -1);
    Pago := FDqryLcto['PAGO'];
    OBS := 'Gerada automaticamente pelo parcelamento';
    if FDqryLcto['NOTA_FISCAL'] <> null then
      NF := FDqryLcto['NOTA_FISCAL'];
    DataCadastro := FDqryLcto['DATA_CADASTRO'];
    if FDqryLcto['ENTRADA_ID'] <> null then
      EntradaID := FDqryLcto['ENTRADA_ID'];

    // La�o que utiliza as vari�veis do lan�amento original para carregar cada campo de cada parcela
    for I := 1 to Parcelamento do
    begin
      FDqryLcto.Insert;
      FDqryLcto['CATEGORIA_FK'] := CategoriaID;
      FDqryLcto['SUBCATEGORIA_FK'] := SubcategoriaID;
      FDqryLcto['CONTA_FK'] := ContaID;
      FDqryLcto['FORMA_DE_PAGAMENTO_FK'] := FormaDEpagamentoID;
      FDqryLcto['USERID'] := USERID;
      FDqryLcto['LANCAMENTO'] := Descricao + ' ' + IntToStr(I) + '/' +
        IntToStr(Parcelamento);
      FDqryLcto['VALOR_PAGO'] := valorpago;
      if Cheque <> null then
        FDqryLcto['CHEQUE'] := Cheque;
      if ChequeCompensado <> null then
        FDqryLcto['CHEQUE_COMPENSADO'] := ChequeCompensado;
      FDqryLcto['DATA_VENCIMENTO'] := IncMonth(DataVencimento, I);
      // FDqryLcto['DATA_PAGAMENTO'] :=  DataPagamento;
      FDqryLcto['PAGO'] := Pago;
      FDqryLcto['OBS'] := OBS;
      FDqryLcto['VALOR_PREVISTO'] := ValorPrevisto / Parcelamento;
      if NF <> null then
        FDqryLcto['NOTA_FISCAL'] := NF;
      FDqryLcto['DATA_CADASTRO'] := DataCadastro;
      if EntradaID <> null then
        FDqryLcto['ENTRADA_ID'] := EntradaID;
      FDqryLcto.Post;
    end;
    try
      FDtcLcto.CommitRetaining;
    except
      FDtcLcto.RollbackRetaining;
    end;

    FDqryLcto.Locate('GASTOS_ID', LctoID, []);
    Parcelando := 'SIM';
    deletarRegistro;
    Parcelando := 'N�O';
    refreshBanco;
  end;
end;

procedure TfrmLancamento.btnImprimirConsultaClick(Sender: TObject);
var
  caminhoRelatorio: string;
begin
  caminhoRelatorio := ExtractFilePath(Application.ExeName);
  reportLancamento.LoadFromFile(caminhoRelatorio + 'LancamentoConsulta.fr3');
  reportLancamento.Variables['dtInicio'] :=
    QuotedStr(DateToStr(dataChequeInicio.Date));
  reportLancamento.Variables['dtFim'] :=
    QuotedStr(DateToStr(dataChequeFim.Date));
  reportLancamento.ShowReport();
end;

procedure TfrmLancamento.btnNovoClick(Sender: TObject);
begin
  novoRegistro;
  gridLancamento.Enabled := False;
  cboxConfirmarPgto.Checked := False;
  editValorPrev.Clear;
end;

procedure TfrmLancamento.btnSairClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmLancamento.btnSalvarClick(Sender: TObject);
begin
  salvarRegistros;
  gridLancamento.Enabled := True;
  cboxConfirmarPgto.Checked := False;
  FDqryLcto.First;
  frmPrincipal.btnAtualizarVencimentos.Click;
  editPesquisaDespSub.Clear;
end;

procedure TfrmLancamento.btnSituacaoClick(Sender: TObject);
begin
  FDqryLcto.Edit;

  if rbEmEspera.Checked then
    FDqryLcto['SITUACAO_STATUS'] := 'AGUARDANDO';
  if rbLiberada.Checked then
    FDqryLcto['SITUACAO_STATUS'] := 'LIBERADA';

  FDqryLcto.Post;

  try
    FDtcLcto.CommitRetaining;
  except
    FDtcLcto.RollbackRetaining;
  end;

  refreshBanco;
  btnPesquisaPrevisto.Click;
end;

procedure TfrmLancamento.editDesricaoKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
    Key := #0;
end;

procedure TfrmLancamento.editNFExit(Sender: TObject);
begin
  { if cbCadastroNF.Text <> '' then
    Begin
    FDqryValidarNF.Open;
    if FDqryValidarNF.Locate('NOTA_FISCAL',cbCadastroNF.ListField,[]) then
    ShowMessage('NF j� cadastrada para a empresa: ' + FDqryValidarNF['DESCRICAO']);
    FDqryValidarNF.Close;
    end; }
end;

procedure TfrmLancamento.editPesqLancamentoExit(Sender: TObject);
begin
  if editPesqLancamento.Text <> '' then
    btnPesquisaPrevisto.Enabled := False;
  if editPesqLancamento.Text = '' then
    btnPesquisaPrevisto.Enabled := True;
end;

procedure TfrmLancamento.editPesqLancamentoKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    btnPesqLancamento.Click;
    Key := #0;
  end;
end;

procedure TfrmLancamento.editPesquisaDespSubDblClick(Sender: TObject);
begin
  frmPesqDespSub.setarEditFoco := 'cadastro';
  frmPesqDespSub.ShowModal;
end;

procedure TfrmLancamento.editPesquisaDespSubKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    frmPesqDespSub.setarEditFoco := 'cadastro';
    frmPesqDespSub.ShowModal;
    Key := #0;
  end;
end;

procedure TfrmLancamento.editValorPagoChange(Sender: TObject);
begin
  // editValorPago.Text := FormatarMoeda(editValorPago.Text);
  // editValorPago.SelStart := Length(editValorPago.Text);
end;

procedure TfrmLancamento.editValorPrevChange(Sender: TObject);
begin

  // editValorPrev.Text := FormatarMoeda(editValorPrev.Text);
  // editValorPrev.SelStart := Length(editValorPrev.Text);

end;

procedure TfrmLancamento.FormShow(Sender: TObject);
begin

  if (frmPrincipal.FDqryLogin.FieldByName('NIVEL').AsInteger < 3) then
  btnCarregarPlanilha.Visible := False
  else
  btnCarregarPlanilha.Visible := True;


  if frmPrincipal.FDqryVencimentos.RecordCount = 0 then
  begin
    PageControlLancamentos.TabIndex := 0;
    atribuirDataDoDia;
    dataPesquisaPrevistoFim.Date := Now;
    refreshBanco;
    Totais;
  end
  else
  begin
    atribuirDataDoDia;
    cboxIntervaloData.Checked := True;
    rbDescricao.Checked := True;
    cbPago.Text := '(TODOS)';
    PageControlLancamentos.TabIndex := 1;
    btnPesquisaPrevisto.Click;
    dataPesquisaPrevistoFim.Date := Now;
    refreshBanco;
  end;
  FDqryLcto.First;
  configurarEnables(0);
  dataChequeInicio.Date := Now;
  dataChequeFim.Date := Now;
  // editValorPrev.Text := FormatarMoeda(editValorPrev.Text);
  // editValorPrev.SelStart := Length(editValorPrev.Text);
end;

procedure TfrmLancamento.gridLancamentoCellClick(Column: TColumn);
begin
  cancelarOperacao;
end;

procedure TfrmLancamento.gridLancamentoDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin

  if FDqryLcto['PAGO'] = 1 then
  // todo o fundo onde foi pago fica cinza com o texto em branco.
  begin
    gridLancamento.Canvas.Font.Color := clWhite;
    gridLancamento.Canvas.Brush.Color := $00616161;
  end;

  if FDqryLcto['SITUACAO_STATUS'] = 'AGUARDANDO' then
  begin
    gridLancamento.Canvas.Brush.Color := $008000FF;
    gridLancamento.Canvas.Font.Color := clWhite;
  end;

  with gridLancamento do
  begin
    if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then
    // Cor da linha selecionada
      if (Rect.Top = TStringGrid(gridLancamento).CellRect(DataCol,
        TStringGrid(gridLancamento).Row).Top) or (gdSelected in State) then
      begin
        Canvas.FillRect(Rect);
        if FDqryLcto['PAGO'] = 0 then
        begin
          Canvas.Brush.Color := $00FFCCCE;
          Canvas.Font.Color := clgray;
        end;
        if FDqryLcto['PAGO'] = 1 then
        begin
          // Canvas.Brush.Color := $00646060; //fundo cinza escuro
          // canvas.Font.Color := clWindow;
          Canvas.Brush.Color := $00FFCCCE;
          Canvas.Font.Color := clgray;
        end;
        if FDqryLcto['SITUACAO_STATUS'] = 'AGUARDANDO' then
        begin
          gridLancamento.Canvas.Brush.Color := $005300A6;
          gridLancamento.Canvas.Font.Color := clWhite;
        end;
      end;
  end;
  gridLancamento.DefaultDrawDataCell(Rect, gridLancamento.columns[DataCol]
    .field, State);
end;

procedure TfrmLancamento.NovaSubcategoriaRELClick(Sender: TObject);
begin
  editRELATORIOpesqDS.Enabled := True;
  frmPesqDespSub.setarEditFoco := 'relat�rio';
  frmPesqDespSub.ShowModal;
end;

procedure TfrmLancamento.ExportarParaExcel;
var
  ExcelApp, ExcelSheet: Variant;
  i, j, col: Integer;
  ValorArredondado, SomaValorPrevisto, SomaValorPago: Double;
  CamposUtilizados: array of string;
  TotalRegistros, ContadorRegistros: Integer;
begin
  // Definir os campos desejados
  CamposUtilizados := ['LANCAMENTO', 'VALOR_PAGO', 'VALOR_PREVISTO', 'NOTA_FISCAL', 'CHEQUE', 'DATA_VENCIMENTO', 'DATA_PAGAMENTO', 'CONTA'];

  // Verifica se h� dados para exportar
  if FDqryLcto.IsEmpty then
  begin
    ShowMessage('N�o h� dados para exportar!');
    Exit;
  end;

  // Cria a inst�ncia do Excel
  ExcelApp := CreateOleObject('Excel.Application');

  // Desabilita a atualiza��o da tela e alertas
  ExcelApp.ScreenUpdating := False;
  ExcelApp.DisplayAlerts := False;

  // Mostra a mensagem de "Carregando..." durante a exporta��o
  Application.ProcessMessages;
 // ShowMessage('Iniciando exporta��o. Aguarde...');

  // Cria uma nova planilha
  ExcelApp.Workbooks.Add;
  ExcelSheet := ExcelApp.Workbooks[1].Sheets[1];

  // Inicializa as somas
  SomaValorPrevisto := 0;
  SomaValorPago := 0;

  // Calcula o total de registros para o ProgressBar
  TotalRegistros := FDqryLcto.RecordCount;
  ContadorRegistros := 0;

  ProgressBar1.Visible := True;

  // Define o progresso do ProgressBar
  ProgressBar1.Min := 0;               // Define o valor m�nimo
  ProgressBar1.Max := TotalRegistros;  // Define o valor m�ximo
  ProgressBar1.Position := 0;          // Inicia o progresso

  // Exporta os t�tulos das colunas
  i := 1; // Come�a na linha 1 (t�tulos)
  for j := 0 to FDqryLcto.FieldCount - 1 do
  begin
    if AnsiIndexStr(FDqryLcto.Fields[j].FieldName, CamposUtilizados) >= 0 then
    begin
      ExcelSheet.Cells[1, i] := FDqryLcto.Fields[j].FieldName;
      Inc(i); // Avan�a para a pr�xima coluna
    end;
  end;

  // Exporta os dados do DataSet
  FDqryLcto.First;
  i := 2; // Come�a na segunda linha para os dados
  while not FDqryLcto.Eof do
  begin
    col := 1; // Come�a na primeira coluna para os dados
    for j := 0 to FDqryLcto.FieldCount - 1 do
    begin
      if AnsiIndexStr(FDqryLcto.Fields[j].FieldName, CamposUtilizados) >= 0 then
      begin
        // Verifica se o campo � do tipo moeda ou valor e aplica a formata��o
        if (FDqryLcto.Fields[j].DataType in [ftFloat, ftCurrency]) or
           (FDqryLcto.Fields[j].FieldName = 'VALOR_PREVISTO') or (FDqryLcto.Fields[j].FieldName = 'VALOR_PAGO')then
        begin
          ValorArredondado := RoundTo(FDqryLcto.Fields[j].AsFloat, -2); // -2 significa 2 casas decimais
          ExcelSheet.Cells[i, col] := ValorArredondado;

          // Aplica a formata��o de moeda brasileira (R$)
          ExcelSheet.Cells[i, col].NumberFormat := '[$R$-416] #,##0.00';

          // Atualiza as somas
          if FDqryLcto.Fields[j].FieldName = 'VALOR_PREVISTO' then
            SomaValorPrevisto := SomaValorPrevisto + ValorArredondado
          else if FDqryLcto.Fields[j].FieldName = 'VALOR_PAGO' then
            SomaValorPago := SomaValorPago + ValorArredondado;
        end
        else
        begin
          // Exporta valores como texto
          ExcelSheet.Cells[i, col] := FDqryLcto.Fields[j].AsString;
        end;
        Inc(col); // Avan�a para a pr�xima coluna
      end;
    end;
    Inc(i); // Avan�a para a pr�xima linha
    FDqryLcto.Next;

    // Atualiza a interface para permitir que o usu�rio veja o progresso
    ProgressBar1.Position := i - 1; // Atualiza o progresso no ProgressBar
    Application.ProcessMessages;     // Permite que a interface seja atualizada
  end;

  Inc(i);
  // Adiciona a linha com as somas
  ExcelSheet.Cells[i, 1] := 'TOTAL'; // Coloca o t�tulo "Total"
  ExcelSheet.Cells[i, 2] := SomaValorPago;     // Soma dos valores do campo VALOR_PAGO
  ExcelSheet.Cells[i, 3] := SomaValorPrevisto; // Soma dos valores do campo VALOR_PREVISTO

  // Aplica a formata��o de moeda nas somas
  ExcelSheet.Cells[i, 2].NumberFormat := '[$R$-416] #,##0.00';
  ExcelSheet.Cells[i, 3].NumberFormat := '[$R$-416] #,##0.00';

  Inc(i); // Avan�a para a pr�xima linha ap�s a soma

  // Ajusta a largura das colunas automaticamente
  ExcelSheet.Columns.AutoFit;

  // Reabilita a atualiza��o de tela e alertas
  ExcelApp.ScreenUpdating := True;
  ExcelApp.DisplayAlerts := True;

  try
    // Reabilita a atualiza��o de tela e alertas
    ExcelApp.ScreenUpdating := True;
    ExcelApp.DisplayAlerts := True;
    // Exibe o Excel para o usu�rio
    ExcelApp.Visible := True;
    // Exibe a mensagem de sucesso
    ShowMessage('Dados exportados com sucesso para o Excel!');
  finally
    // Libera as refer�ncias aos objetos ExcelSheet e ExcelApp
    ExcelSheet := Unassigned; // Libera a planilha
    ExcelApp := Unassigned;   // Libera o aplicativo Excel
    ProgressBar1.Min := 0;
    ProgressBar1.Visible := False;
  end;
end;

end.
