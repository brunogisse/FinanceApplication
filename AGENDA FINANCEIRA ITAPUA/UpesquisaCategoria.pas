unit UpesquisaCategoria;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.ExtCtrls, Vcl.DBCtrls, Vcl.Buttons, Vcl.ComCtrls, frxClass,
  frxDBSet;

type
  TfrmPesquisaCategoria = class(TForm)
    PainelPesquisaCategoria: TPanel;
    DBGrid1: TDBGrid;
    fdqryPesquisaCategoria: TFDQuery;
    dsPesquisaCategoria: TDataSource;
    fdqryPesquisaCategoriaSUBCATEGORIA_ID: TIntegerField;
    fdqryPesquisaCategoriaDESCRICAO: TStringField;
    fdqryPesquisaCategoriaCATEGORIA_FK: TIntegerField;
    fdqryPesquisaCategoriaCATEGORIA_ID: TIntegerField;
    fdqryPesquisaCategoriaCATEGORIA: TStringField;
    fdqryPesquisaCategoriaSUBCATEGORIA_ID_1: TIntegerField;
    fdqryPesquisaCategoriaVALOR_PAGO: TFloatField;
    btnEscolherCategoria: TBitBtn;
    editRotuloDaCategoria: TEdit;
    dataDePesquisaCAtegoria: TDateTimePicker;
    dataAtePesquisaCategoria: TDateTimePicker;
    labelPesqCategoria: TLabel;
    labelAtéPesCategoria: TLabel;
    btnCategoriaOK: TBitBtn;
    reportPesquisaCategoria: TfrxReport;
    dtsReportPesquisaCategoria: TfrxDBDataset;
    btnImprimir: TBitBtn;
    fdqryPesquisaCategoriaVALOR_PREVISTO: TFloatField;
    qryRelatorioSubcategoria: TFDQuery;
    dsRelatorioSubcategoria: TDataSource;
    qryRelatorioSubcategoriaGASTOS_ID: TIntegerField;
    qryRelatorioSubcategoriaCATEGORIA_FK: TIntegerField;
    qryRelatorioSubcategoriaSUBCATEGORIA_FK: TIntegerField;
    qryRelatorioSubcategoriaCONTA_FK: TIntegerField;
    qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO_FK: TIntegerField;
    qryRelatorioSubcategoriaLANCAMENTO: TStringField;
    qryRelatorioSubcategoriaVALOR_PAGO: TSingleField;
    qryRelatorioSubcategoriaVALOR_PREVISTO: TSingleField;
    qryRelatorioSubcategoriaNOTA_FISCAL: TIntegerField;
    qryRelatorioSubcategoriaCHEQUE: TIntegerField;
    qryRelatorioSubcategoriaCHEQUE_COMPENSADO: TStringField;
    qryRelatorioSubcategoriaDATA_VENCIMENTO: TDateField;
    qryRelatorioSubcategoriaDATA_PAGAMENTO: TDateField;
    qryRelatorioSubcategoriaPAGO: TIntegerField;
    qryRelatorioSubcategoriaENTRADA_ID: TIntegerField;
    qryRelatorioSubcategoriaSITUACAO_STATUS: TStringField;
    qryRelatorioSubcategoriaCATEGORIA_ID: TIntegerField;
    qryRelatorioSubcategoriaCATEGORIA: TStringField;
    qryRelatorioSubcategoriaSUBCATEGORIA_ID: TIntegerField;
    qryRelatorioSubcategoriaSUBCATEGORIA: TStringField;
    qryRelatorioSubcategoriaCONTA_ID: TIntegerField;
    qryRelatorioSubcategoriaCONTA: TStringField;
    qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO_ID: TIntegerField;
    qryRelatorioSubcategoriaFORMA_DE_PAGAMENTO: TStringField;
    qryRelatorioSubcategoriaOBS: TStringField;
    qryRelatorioSubcategoriaDATA_CADASTRO: TDateField;
    gridSub: TDBGrid;
    dsSubcategoriaRel: TfrxDBDataset;
    reportSubcategoria: TfrxReport;
    painelRodapeSub: TPanel;
    btnImprimirSubdetalhado: TBitBtn;
    gbFiltro: TGroupBox;
    rbPago: TRadioButton;
    rbNaoPago: TRadioButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnEscolherCategoriaClick(Sender: TObject);
    procedure btnCategoriaOKClick(Sender: TObject);
    procedure btnImprimirClick(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure btnImprimirSubdetalhadoClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmPesquisaCategoria: TfrmPesquisaCategoria;

implementation

{$R *.dfm}

uses UfrmLancamentos, UfrmPrincipal, uFonteParaRealCategoria;

procedure TfrmPesquisaCategoria.btnCategoriaOKClick(Sender: TObject);
begin
  qryRelatorioSubcategoria.Close;
  if rbNaoPago.Checked = True then
 begin
 with fdqryPesquisaCategoria do
   begin
     Close;
     SQL.Clear;
     SQL.Add('SELECT S.SUBCATEGORIA_ID, S.DESCRICAO, S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, reg.subcategoria_id, sum(reg.valor_pago) as Valor_pago, sum(reg.valor_previsto) as Valor_previsto from SUBCATEGORIA S, CATEGORIA C, '
     + ' registro_de_gastos reg where (S.CATEGORIA_ID = C.CATEGORIA_ID) and (C.DESCRICAO = :DESC) and (reg.data_vencimento between :d1 and :d2) and (reg.pago = 0) and '
     + '(reg.subcategoria_id = s.subcategoria_id) group by S.SUBCATEGORIA_ID, S.DESCRICAO, CATEGORIA_FK, C.CATEGORIA_ID, CATEGORIA, reg.subcategoria_id order by s.descricao');
     ParamByName('DESC').AsString := editRotuloDaCategoria.Text;
     ParamByName('D1').AsDate := dataDePesquisaCAtegoria.Date;
     ParamByName('D2').AsDate := dataAtePesquisaCategoria.Date;
     Open;
   end;
 end;


    if rbPago.Checked = true then
 begin
 with fdqryPesquisaCategoria do
   begin
     Close;
     SQL.Clear;
     SQL.Add('SELECT S.SUBCATEGORIA_ID, S.DESCRICAO, S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, reg.subcategoria_id, sum(reg.valor_pago) as Valor_pago, sum(reg.valor_previsto) as Valor_previsto from SUBCATEGORIA S, CATEGORIA C, '
     + ' registro_de_gastos reg where (S.CATEGORIA_ID = C.CATEGORIA_ID) and (C.DESCRICAO = :DESC) and (reg.data_pagamento between :d1 and :d2) and '
     + '(reg.subcategoria_id = s.subcategoria_id) group by S.SUBCATEGORIA_ID, S.DESCRICAO, CATEGORIA_FK, C.CATEGORIA_ID, CATEGORIA, reg.subcategoria_id order by s.descricao');
     ParamByName('DESC').AsString := editRotuloDaCategoria.Text;
     ParamByName('D1').AsDate := dataDePesquisaCAtegoria.Date;
     ParamByName('D2').AsDate := dataAtePesquisaCategoria.Date;
     Open;
   end;
 end;


end;

procedure TfrmPesquisaCategoria.btnEscolherCategoriaClick(Sender: TObject);
begin
     editRotuloDaCategoria.Clear;
     fdqryPesquisaCategoria.Open;
     frmFonteParaRelCategoria.ShowModal;
end;

procedure TfrmPesquisaCategoria.btnImprimirClick(Sender: TObject);
var caminhoRelatorio : string;
begin

  caminhoRelatorio := ExtractFilePath(Application.ExeName);
  reportPesquisaCategoria.LoadFromFile(caminhoRelatorio +'relatorioDespesa.fr3');
  reportPesquisaCategoria.Variables['DataInicio'] := QuotedStr(DateToStr(dataDePesquisaCAtegoria.Date));
  reportPesquisaCategoria.Variables['DataFim'] := QuotedStr(DateToStr(dataAtePesquisaCategoria.Date));
  reportPesquisaCategoria.Variables['Despesa'] := QuotedStr(fdqryPesquisaCategoria['CATEGORIA']);
  reportPesquisaCategoria.ShowReport();
end;

procedure TfrmPesquisaCategoria.btnImprimirSubdetalhadoClick(Sender: TObject);
var caminhoRelatorio : string;
begin
  caminhoRelatorio := ExtractFilePath(Application.ExeName);
  reportSubcategoria.LoadFromFile(caminhoRelatorio +'RelatorioSubdespesaDetalhado.fr3');
  reportSubcategoria.Variables['DataInicio'] := QuotedStr(DateToStr(dataDePesquisaCAtegoria.Date));
  reportSubcategoria.Variables['DataFim'] := QuotedStr(DateToStr(dataAtePesquisaCategoria.Date));
  reportSubcategoria.Variables['Despesa'] := QuotedStr(qryRelatorioSubcategoria['CATEGORIA']);
  reportSubcategoria.ShowReport();
end;

procedure TfrmPesquisaCategoria.DBGrid1DblClick(Sender: TObject);
begin
     if rbNaoPago.Checked = true then
  begin
   with qryRelatorioSubcategoria do
    begin
     Close;
     SQL.Clear;
     SQL.Add('select '
           + ' REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK, '
           + ' REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL,REG.CHEQUE, '
           + ' REG.CHEQUE_COMPENSADO,REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, REG.SITUACAO_STATUS, '
           + ' C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO, '
           + ' REG.OBS, REG.DATA_CADASTRO '

           + ' from '

           + ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP '


           + ' where '

           + ' (REG.CATEGORIA_ID = C.CATEGORIA_ID) and '
           + ' (REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and '
           + ' (REG.CONTA_ID = CT.CONTA_ID) and '
           + ' (REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and '
           + ' (reg.data_vencimento between :INICIO and :FIM) and '
           + ' (reg.pago = 0) and '   //não pago
           + ' (reg.subcategoria_id = :subid) '

           + ' order by REG.DATA_VENCIMENTO');
              ParamByName('INICIO').AsDate:= dataDePesquisaCAtegoria.Date;
              ParamByName('FIM').AsDate:= dataAtePesquisaCategoria.Date;
              ParamByName('subid').AsInteger:= fdqryPesquisaCategoria['SUBCATEGORIA_ID'];
              Open;
    end;
  end;


     if rbPago.Checked = true then
  begin
   with qryRelatorioSubcategoria do
    begin
     Close;
     SQL.Clear;
     SQL.Add('select '
           + ' REG.GASTOS_ID, REG.CATEGORIA_ID as CATEGORIA_FK, REG.SUBCATEGORIA_ID as SUBCATEGORIA_FK, REG.CONTA_ID as CONTA_FK, REG.FORMA_DE_PAGAMENTO_ID as FORMA_DE_PAGAMENTO_FK, '
           + ' REG.DESCRICAO as LANCAMENTO, REG.VALOR_PAGO, REG.VALOR_PREVISTO, REG.NOTA_FISCAL,REG.CHEQUE, '
           + ' REG.CHEQUE_COMPENSADO,REG.DATA_VENCIMENTO, REG.DATA_PAGAMENTO, REG.PAGO, REG.ENTRADA_ID, REG.SITUACAO_STATUS, '
           + ' C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA, S.SUBCATEGORIA_ID, S.DESCRICAO as SUBCATEGORIA, CT.CONTA_ID, CT.DESCRICAO as CONTA, FP.FORMA_DE_PAGAMENTO_ID, FP.DESCRICAO as FORMA_DE_PAGAMENTO, '
           + ' REG.OBS, REG.DATA_CADASTRO '

           + ' from '

           + ' REGISTRO_DE_GASTOS REG, CATEGORIA C, SUBCATEGORIA S, CONTAS CT, FORMA_DE_PAGAMENTO FP '


           + ' where '

           + ' (REG.CATEGORIA_ID = C.CATEGORIA_ID) and '
           + ' (REG.SUBCATEGORIA_ID = S.SUBCATEGORIA_ID) and '
           + ' (REG.CONTA_ID = CT.CONTA_ID) and '
           + ' (REG.FORMA_DE_PAGAMENTO_ID = FP.FORMA_DE_PAGAMENTO_ID) and '
           + ' (reg.data_pagamento between :INICIO and :FIM) and '
           + ' (reg.pago = 1) and '     // pago
           + ' (reg.subcategoria_id = :subid) '

           + ' order by REG.DATA_VENCIMENTO');
              ParamByName('INICIO').AsDate:= dataDePesquisaCAtegoria.Date;
              ParamByName('FIM').AsDate:= dataAtePesquisaCategoria.Date;
              ParamByName('subid').AsInteger:= fdqryPesquisaCategoria['SUBCATEGORIA_ID'];
              Open;
    end;
  end;
    gridSub.Visible:= True;
    btnImprimirSubdetalhado.Visible:= True;


end;

procedure TfrmPesquisaCategoria.DBGrid1MouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint;
  var Handled: Boolean);
begin
gridSub.Visible:= False;
btnImprimirSubdetalhado.Visible:= False;
end;

procedure TfrmPesquisaCategoria.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
fdqryPesquisaCategoria.Close;
qryRelatorioSubcategoria.Close;
end;

procedure TfrmPesquisaCategoria.FormShow(Sender: TObject);
begin

  dataDePesquisaCAtegoria.Date:= Now;
  dataAtePesquisaCategoria.Date := Now;
  rbPago.Checked := True;
end;

end.
