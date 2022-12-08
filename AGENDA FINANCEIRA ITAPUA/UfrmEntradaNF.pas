unit UfrmEntradaNF;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.ComCtrls, Data.DB,
  Vcl.Grids, Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet,
  FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Mask, Vcl.Buttons,
  Vcl.Imaging.pngimage, Vcl.Menus, frxClass, frxDBSet;

type
  TfrmEntradaNF = class(TForm)
    PainelTopo: TPanel;
    PainelPrincipal: TPanel;
    PainelBottom: TPanel;
    PageControlEntradaNF: TPageControl;
    AbaEntrada: TTabSheet;
    AbaItens: TTabSheet;
    GridEntradaNF: TDBGrid;
    GridItensEntrada: TDBGrid;
    FDtcEntradaNF: TFDTransaction;
    FDqryEntradaNF: TFDQuery;
    dsEntradaNF: TDataSource;
    FDqryFornecedor: TFDQuery;
    dsFornecedor: TDataSource;
    FDqryEntradaNFCADASTRO_NF_ID: TIntegerField;
    FDqryEntradaNFFORNECEDOR_ID: TIntegerField;
    FDqryEntradaNFDATA: TDateField;
    FDqryEntradaNFVALOR_NF: TFMTBCDField;
    FDqryEntradaNFNF: TIntegerField;
    FDqryEntradaNFDATA_EMISSAO_NF: TDateField;
    FDqryEntradaNFOBS: TStringField;
    FDqryEntradaNFNOME_FANTASIA: TStringField;
    FDqryEntradaNFRAZAO_SOCIAL: TStringField;
    FDqryItensNF: TFDQuery;
    dsItensNF: TDataSource;
    FDqryItensNFITEM_NF_ID: TIntegerField;
    FDqryItensNFNF_ID: TIntegerField;
    FDqryItensNFPRODUTO_ID: TIntegerField;
    FDqryItensNFVALOR_ITEM: TFMTBCDField;
    FDqryItensNFQTDE_ITEM: TIntegerField;
    FDqryItensNFCADASTRO_NF_ID: TIntegerField;
    FDqryItensNFPRODUTO: TStringField;
    btnNovo: TBitBtn;
    labelRotuloCodigoEntrada: TLabel;
    labelCodigoDAentrada: TLabel;
    btnSalvar: TBitBtn;
    FDqryFornecedorFORNECEDOR_ID: TIntegerField;
    FDqryFornecedorNOME_FANTASIA: TStringField;
    FDqryFornecedorCNPJ: TStringField;
    FDqryFornecedorTELEFONE: TStringField;
    FDqryFornecedorRAZAO_SOCIAL: TStringField;
    gbPrincipal: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    DataEntrada: TDateTimePicker;
    editPesquisarFornecedor: TEdit;
    Label4: TLabel;
    DataEmissao: TDateTimePicker;
    Label5: TLabel;
    memoOBS: TDBMemo;
    editNumeroNF: TDBEdit;
    Label3: TLabel;
    Label6: TLabel;
    editValorNF: TDBEdit;
    btnCancelar: TBitBtn;
    btnExcluir: TBitBtn;
    FDqryProduto: TFDQuery;
    FDqryProdutoPRODUTO_ID: TIntegerField;
    FDqryProdutoDESCRICAO: TStringField;
    FDqryProdutoVALOR: TFMTBCDField;
    FDqryProdutoESTOQUE_MINIMO: TIntegerField;
    FDqryProdutoTIPO: TIntegerField;
    FDqryProdutoESTOQUE: TIntegerField;
    FDqryProdutoTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutoTIPO_DESCRICAO: TStringField;
    dsProduto: TDataSource;
    FDqryItensNFVALOR_TOTAL_ITEM: TFMTBCDField;
    FDqryEntradaNFSTATUS: TStringField;
    btnProcessarNF: TBitBtn;
    brnSair: TImage;
    FDqryEntradaNFADD_ITEM: TStringField;
    FDqryMovProduto: TFDQuery;
    dsMovProduto: TDataSource;
    FDqryMovProdutoMOVIMENTACAO_ID: TIntegerField;
    FDqryMovProdutoDATA: TDateField;
    FDqryMovProdutoPRODUTO_ID: TIntegerField;
    FDqryMovProdutoTIPO: TStringField;
    FDqryMovProdutoQTDE: TIntegerField;
    FDqryMovProdutoSALDO_ATUAL: TIntegerField;
    FDqryMovProdutoOBS: TStringField;
    FDqryMovProdutoVALOR_PRODUTO: TFMTBCDField;
    FDqryMovProdutoADICIONAIS: TStringField;
    FDqryEntradaNFNF_LANCADA: TStringField;
    gbEntradaAjuste: TGroupBox;
    rbEntrada: TRadioButton;
    rbAjuste: TRadioButton;
    gbDataGeral: TGroupBox;
    dataGeralInicio: TDateTimePicker;
    dataGeralFim: TDateTimePicker;
    labelPeriodoGeral: TLabel;
    btnDataGeral: TBitBtn;
    rbEntradasApenas: TRadioButton;
    rbAjusteApenas: TRadioButton;
    gbConsultaNF: TGroupBox;
    rbConsultaNF: TRadioButton;
    rbConsultaEntrada: TRadioButton;
    editConsultaNFEntrada: TEdit;
    btnConsultaNFEntrada: TBitBtn;
    reportEntradaNF: TfrxReport;
    frxDBDataset1: TfrxDBDataset;
    fdqryRelatorio: TFDQuery;
    dsRelatorio: TDataSource;
    fdqryRelatorioCADASTRO_NF_ID: TIntegerField;
    fdqryRelatorioFORNECEDOR_ID: TIntegerField;
    fdqryRelatorioDATA: TDateField;
    fdqryRelatorioDATA_EMISSAO_NF: TDateField;
    fdqryRelatorioVALOR_NF: TFMTBCDField;
    fdqryRelatorioNF: TIntegerField;
    fdqryRelatorioSTATUS: TStringField;
    fdqryRelatorioNF_LANCADA: TStringField;
    fdqryRelatorioOBS: TStringField;
    fdqryRelatorioPRODUTO_ID: TIntegerField;
    fdqryRelatorioDESCRICAO: TStringField;
    fdqryRelatorioITEM_NF_ID: TIntegerField;
    fdqryRelatorioPRODUTO_ID_1: TIntegerField;
    fdqryRelatorioNF_ID: TIntegerField;
    fdqryRelatorioVALOR_ITEM: TFMTBCDField;
    fdqryRelatorioQTDE_ITEM: TIntegerField;
    fdqryRelatorioVALOR_TOTAL_ITEM: TFMTBCDField;
    btnImprimirNF: TBitBtn;
    fdqryRelatorioNOME_FANTASIA: TStringField;
    fdqryRelatorioFORNECEDOR_ID_1: TIntegerField;
    FDQuery1: TFDQuery;
    DataSource1: TDataSource;
    frxReport1: TfrxReport;
    frxDBDataset2: TfrxDBDataset;
    procedure btnNovoClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure editPesquisarFornecedorDblClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure brnSairClick(Sender: TObject);
    procedure dsEntradaNFDataChange(Sender: TObject; Field: TField);
    procedure editPesquisarFornecedorKeyPress(Sender: TObject; var Key: Char);
    procedure btnProcessarNFClick(Sender: TObject);
    procedure GridEntradaNFDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure GridEntradaNFCellClick(Column: TColumn);
    procedure btnDataGeralClick(Sender: TObject);
    procedure rbEntradasApenasClick(Sender: TObject);
    procedure rbAjusteApenasClick(Sender: TObject);
    procedure btnConsultaNFEntradaClick(Sender: TObject);
    procedure rbConsultaNFClick(Sender: TObject);
    procedure rbConsultaEntradaClick(Sender: TObject);
    procedure editConsultaNFEntradaKeyPress(Sender: TObject; var Key: Char);
    procedure btnImprimirNFClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
        procedure EnableDisable(status : integer);
        procedure ProcedureCommitOrRollbackRetaining;
        procedure VerificarCamposVazios;
        procedure AtualizarEstoqueDeProdutos;
        procedure AdicionarItensNaNF;
        procedure RegistrarMovimentacaoProduto(TipoOperacao : string);
        procedure VerificarEstoqueZerado;
        procedure AplicarDataGeral;

        var EntradaNormalOuAjuste : String;


  public
    { Public declarations }

        procedure RefreshDatasets;
        var TotalNF : double;
  end;

var
  frmEntradaNF: TfrmEntradaNF;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmItensEntrada, UfrmProduto, UfrmFornecedores;

procedure tfrmEntradaNF.AplicarDataGeral;
var caralho : string;
begin

  if rbEntradasApenas.Checked = True then
    begin

       with FDqryEntradaNF do
         begin
            Close;
            SQL.Clear;
            SQL.Add('select '
             +' NF.CADASTRO_NF_ID, '
             +''''' as ADD_ITEM, '
             +' NF.FORNECEDOR_ID, '
             +'NF.DATA, '
             +' NF.VALOR_NF, '
             +' NF.NF, '
             +' NF.DATA_EMISSAO_NF, '
             +' NF.OBS, '
             +' NF.STATUS, '
             +' NF.NF_LANCADA, '
             +' F.NOME_FANTASIA, '
             +' F.RAZAO_SOCIAL '
             +' from '
             +' CADASTRO_NF NF, FORNECEDOR F '
             +' where '
             +' (NF.FORNECEDOR_ID = F.FORNECEDOR_ID) and '
             +' (NF.DATA between :INICIO and :FIM) and (NF.NF_LANCADA <> ''AJU'') '
             +' order by NF.CADASTRO_NF_ID ASC ');
             ParamByName('INICIO').AsDate := dataGeralInicio.Date;
             ParamByName('FIM').AsDate := dataGeralFim.Date;
             Open;
         end;
    end;


    if rbAjusteApenas.Checked = True then
      begin

       with FDqryEntradaNF do
         begin
            Close;
            SQL.Clear;
            SQL.Add('select '
             +' NF.CADASTRO_NF_ID, '
             +''''' as ADD_ITEM, '
             +' NF.FORNECEDOR_ID, '
             +'NF.DATA, '
             +' NF.VALOR_NF, '
             +' NF.NF, '
             +' NF.DATA_EMISSAO_NF, '
             +' NF.OBS, '
             +' NF.STATUS, '
             +' NF.NF_LANCADA, '
             +' F.NOME_FANTASIA, '
             +' F.RAZAO_SOCIAL '
             +' from '
             +' CADASTRO_NF NF, FORNECEDOR F '
             +' where '
             +' (NF.FORNECEDOR_ID = F.FORNECEDOR_ID) and '
             +' (NF.DATA between :INICIO and :FIM) and (NF.NF_LANCADA = ''AJU'') '
             +' order by NF.CADASTRO_NF_ID ASC ');
             ParamByName('INICIO').AsDate := dataGeralInicio.Date;
             ParamByName('FIM').AsDate := dataGeralFim.Date;
             Open;
         end;
      end;
end;


procedure TfrmEntradaNF.VerificarEstoqueZerado;
 var ProdutoZerado : string;
begin
     ProdutoZerado := '';
     while not FDqryItensNF.Eof do
       begin
         if FDqryProduto['ESTOQUE'] < FDqryItensNF['QTDE_ITEM'] then
           begin
             ProdutoZerado := ProdutoZerado + #13 + FDqryProduto['DESCRICAO'] + ' - Estoque [' + IntToStr(FDqryProduto['ESTOQUE']) +'] - Tentando excluir [' +  IntToStr(FDqryItensNF['QTDE_ITEM']) +']   ' ;
             FDqryItensNF.Next;
           end
          else
             FDqryItensNF.Next;
       end;
   if ProdutoZerado <> '' then
       begin
         MessageDlg('N�o foi poss�vel excluir a Entrada. '+ #13 + '� necess�rio verificar o saldo do(s) produto(s) abaixo: ' + #13 + #13 + ' ' + ProdutoZerado, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
         Abort;
       end;
end;

procedure TfrmEntradaNF.RegistrarMovimentacaoProduto(TipoOperacao : string);
begin
       FDqryMovProduto.Insert;
       FDqryMovProduto['PRODUTO_ID'] := FDqryProduto['PRODUTO_ID'];
       FDqryMovProduto['DATA'] := Now;
       FDqryMovProduto['QTDE'] := FDqryItensNF['QTDE_ITEM'];
       FDqryMovProduto['SALDO_ATUAL'] := FDqryProduto['ESTOQUE'];
       FDqryMovProduto['VALOR_PRODUTO'] := FDqryProduto['VALOR'];
    if TipoOperacao = 'SALVANDO' then
    begin
       FDqryMovProduto['TIPO'] := 'E';
       FDqryMovProduto['ADICIONAIS'] :=  'Processamento da NF ' + IntToStr(FDqryEntradaNF['NF']) + ' | Entrada: ' + IntToStr(FDqryEntradaNF['CADASTRO_NF_ID']) + ' - feito pelo User: ' + frmPrincipal.FDqryLogin['NOME'] + '.';
    if FDqryEntradaNF['OBS'] <> '' then
       FDqryMovProduto['OBS'] := FDqryEntradaNF['OBS']
       else
       FDqryMovProduto['OBS'] := '';
    end
  else if TipoOperacao = 'EXCLUINDO' then
    begin
       FDqryMovProduto['TIPO'] := 'S';
       FDqryMovProduto['ADICIONAIS'] := 'Ajuste de estoque pela exclus�o de NF [Entrada]';
       FDqryMovProduto['OBS'] := 'Exclus�o da Entrada NF: '+ IntToStr(FDqryEntradaNF['NF']) +' | Entrada '+ IntToStr(FDqryEntradaNF['CADASTRO_NF_ID']) + ' | User: ' + frmPrincipal.FDqryLogin['NOME'] + '.';
    end;
       FDqryMovProduto.Post;
end;

procedure TfrmEntradaNF.AdicionarItensNaNF;
begin
    if FDqryEntradaNF.RecordCount > 0 then
    begin
      if FDqryEntradaNF['STATUS'] = 'NF ABERTA' then
         begin
           frmEntradaItens.labelEntrada.Caption := IntToStr(FDqryEntradaNF['CADASTRO_NF_ID']);
           frmEntradaItens.labelNF.Caption := IntToStr(FDqryEntradaNF['NF']);
           frmEntradaItens.ShowModal;
           FDqryEntradaNF.Edit;
           FDqryEntradaNF['VALOR_NF'] := TotalNF;
           TotalNF := 0;
           FDqryEntradaNF.Post;
           ProcedureCommitOrRollbackRetaining;
           RefreshDatasets;
           FDqryEntradaNF.Locate('CADASTRO_NF_ID',frmEntradaItens.labelEntrada.Caption,[]);
         end
       else
       MessageDlg('N�o � poss�vel efetuar altera��es em entradas j� processadas', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
    end
  else
  MessageDlg('N�o h� Entrada selecionada para adicionar itens', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
end;

procedure TfrmEntradaNF.AtualizarEstoqueDeProdutos;
 var AtualizarValorEstoque : string;
begin
 if MessageBox(Application.Handle,'Deseja atualizar o valor dos produtos'+#13+'com os valores desta entrada?','Confirma��o',MB_YESNO + MB_ICONQUESTION) = mrYes then
    AtualizarValorEstoque := 'SIM'
   else
    AtualizarValorEstoque := 'N�O';
  while not FDqryItensNF.Eof do
   begin
      FDqryProduto.Locate('PRODUTO_ID',FDqryItensNF['PRODUTO_ID'],[]);
      FDqryProduto.Edit;
    //  FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] + FDqryItensNF['QTDE_ITEM'];
   if AtualizarValorEstoque = 'SIM' then
      FDqryProduto['VALOR'] := FDqryItensNF['VALOR_ITEM'];
    //  RegistrarMovimentacaoProduto('SALVANDO'); // procedure que registra a entrada do produto na tabela MOVIMENTACAO_PRODUTO.
      FDqryProduto.Post;
      FDqryItensNF.Next;
   end;
  AtualizarValorEstoque := '';
end;


procedure TfrmEntradaNF.btnConsultaNFEntradaClick(Sender: TObject);
begin

if editConsultaNFEntrada.Text = '' then
   Abort;

  if rbConsultaNF.Checked = True then
    begin

       with FDqryEntradaNF do
         begin
            Close;
            SQL.Clear;
            SQL.Add('select '
             +' NF.CADASTRO_NF_ID, '
             +''''' as ADD_ITEM, '
             +' NF.FORNECEDOR_ID, '
             +'NF.DATA, '
             +' NF.VALOR_NF, '
             +' NF.NF, '
             +' NF.DATA_EMISSAO_NF, '
             +' NF.OBS, '
             +' NF.STATUS, '
             +' NF.NF_LANCADA, '
             +' F.NOME_FANTASIA, '
             +' F.RAZAO_SOCIAL '
             +' from '
             +' CADASTRO_NF NF, FORNECEDOR F '
             +' where '
             +' (NF.FORNECEDOR_ID = F.FORNECEDOR_ID) and '
             +' (NF.DATA between :INICIO and :FIM) and (NF.NF = :NF) '
             +' order by NF.CADASTRO_NF_ID ASC ');
             ParamByName('INICIO').AsDate := dataGeralInicio.Date;
             ParamByName('FIM').AsDate := dataGeralFim.Date;
             ParamByName('NF').AsInteger := StrToInt(editConsultaNFEntrada.Text);
             Open;
         end;
    end;

      if rbConsultaEntrada.Checked = True then
    begin

       with FDqryEntradaNF do
         begin
            Close;
            SQL.Clear;
            SQL.Add('select '
             +' NF.CADASTRO_NF_ID, '
             +''''' as ADD_ITEM, '
             +' NF.FORNECEDOR_ID, '
             +'NF.DATA, '
             +' NF.VALOR_NF, '
             +' NF.NF, '
             +' NF.DATA_EMISSAO_NF, '
             +' NF.OBS, '
             +' NF.STATUS, '
             +' NF.NF_LANCADA, '
             +' F.NOME_FANTASIA, '
             +' F.RAZAO_SOCIAL '
             +' from '
             +' CADASTRO_NF NF, FORNECEDOR F '
             +' where '
             +' (NF.FORNECEDOR_ID = F.FORNECEDOR_ID) and '
             +' (NF.DATA between :INICIO and :FIM) and (NF.CADASTRO_NF_ID = :ENTRADA) '
             +' order by NF.CADASTRO_NF_ID ASC ');
             ParamByName('INICIO').AsDate := dataGeralInicio.Date;
             ParamByName('FIM').AsDate := dataGeralFim.Date;
             ParamByName('ENTRADA').AsInteger := StrToInt(editConsultaNFEntrada.Text);
             Open;
         end;
    end;
end;

procedure TfrmEntradaNF.VerificarCamposVazios;
begin
  if (editPesquisarFornecedor.Text = '') or (editNumeroNF.Text = '') or (memoOBS.Text = '') then
     begin
       MessageBox(Application.Handle,'Verifique os campos vazios','Aten��o', MB_OK + MB_ICONINFORMATION);
       editPesquisarFornecedor.SetFocus;
       Abort
     end;
end;

procedure TfrmEntradaNF.ProcedureCommitOrRollbackRetaining;
begin
   try
    FDtcEntradaNF.CommitRetaining;
   finally
    FDtcEntradaNF.RollbackRetaining;
   end;
end;


procedure TfrmEntradaNF.rbAjusteApenasClick(Sender: TObject);
begin
 AplicarDataGeral;
end;

procedure TfrmEntradaNF.rbConsultaEntradaClick(Sender: TObject);
begin
 editConsultaNFEntrada.Clear;
 editConsultaNFEntrada.SetFocus;
end;

procedure TfrmEntradaNF.rbConsultaNFClick(Sender: TObject);
begin
 editConsultaNFEntrada.Clear;
 editConsultaNFEntrada.SetFocus;
end;

procedure TfrmEntradaNF.rbEntradasApenasClick(Sender: TObject);
begin
 AplicarDataGeral;
end;

procedure TfrmEntradaNF.EnableDisable;
begin
   if status = 0 then
       begin
              gbPrincipal.Enabled := False;
             btnSalvar.Enabled := False;
            btnCancelar.Enabled := False;
          btnNovo.Enabled := True;
         btnExcluir.Enabled := True;
       end
      else if status = 1 then
       begin
         gbPrincipal.Enabled := True;
          btnSalvar.Enabled := True;
           btnCancelar.Enabled := True;
             btnNovo.Enabled := False;
              btnExcluir.Enabled := False;
       end;
end;

procedure TfrmEntradaNF.RefreshDatasets;
begin
  FDqryEntradaNF.Close;
   FDqryFornecedor.Close;
    FDqryItensNF.Close;
     FDqryEntradaNF.Open;
      FDqryFornecedor.Open;
       FDqryItensNF.Open;
        FDqryProduto.Close;
         FDqryProduto.Open;
          FDqryMovProduto.Close;
           FDqryMovProduto.Open;
end;


procedure TfrmEntradaNF.btnSalvarClick(Sender: TObject);
 begin
         VerificarCamposVazios; //procedure que verifica campos vazios e aborta a opera��o caso haja.
         EnableDisable(0);
         FDqryEntradaNF['FORNECEDOR_ID'] := FDqryFornecedor['FORNECEDOR_ID'];
      if FDqryEntradaNF['VALOR_NF'] = null then
         FDqryEntradaNF['VALOR_NF'] := 0;
         FDqryEntradaNF['STATUS'] := 'NF ABERTA';
         FDqryEntradaNF['NF_LANCADA'] := 'N�O';
         FDqryEntradaNF['DATA'] := DataEntrada.Date;
         FDqryEntradaNF['DATA_EMISSAO_NF'] := DataEmissao.Date;
         FDqryEntradaNF.Post;
         ProcedureCommitOrRollbackRetaining;
         RefreshDatasets;
         FDqryEntradaNF.Last;
         labelCodigoDAentrada.Visible:= True;
         labelCodigoDAentrada.Caption := IntToStr(FDqryEntradaNF['CADASTRO_NF_ID']);
         editPesquisarFornecedor.Clear;
 end;

procedure TfrmEntradaNF.Button1Click(Sender: TObject);
var  caminhoRelatorio : string;
begin
  with FDQuery1 do
     begin
         Close;
         SQL.Clear;
         SQL.Add('select '
                +' CAD.cadastro_nf_id, CAD.fornecedor_id, CAD.data, CAD.data_emissao_nf, CAD.valor_nf, CAD.nf, CAD.status, CAD.nf_lancada, CAD.obs, '
                +' P.produto_id, P.descricao, '
                +' I.item_nf_id, I.produto_id, I.nf_id, I.valor_item, I.qtde_item, I.valor_total_item, '
                +' f.Nome_fantasia, f.fornecedor_id '
                +' from '
                +' cadastro_nf CAD, produto P, item_nf I, fornecedor f '
                +' WHERE '
                +' (i.nf_id = cad.cadastro_nf_id) and '
                +' (I.produto_id = P.produto_id) and '
                +' (cad.fornecedor_id = f.fornecedor_id) and '
                +' (CAD.data between :datainicio and :datafim)');
         //ParamByName('NOTAFISCAL').AsInteger := FDqryEntradaNF['CADASTRO_NF_ID'];
           ParamByName('datainicio').AsDate := dataGeralInicio.Date;
           ParamByName('datafim').AsDate := dataGeralInicio.Date;
         Open;

         caminhoRelatorio := ExtractFilePath(Application.ExeName);
         frxReport1.LoadFromFile(caminhoRelatorio +'RelatorioCadastroNF - Teste.fr3');
         frxReport1.ShowReport();

     end;
end;

procedure TfrmEntradaNF.dsEntradaNFDataChange(Sender: TObject; Field: TField);
begin
   { if FDqryEntradaNF.RecordCount > 0 then
     begin
         labelCodigoDAentrada.Visible := True;
         labelCodigoDAentrada.Caption := FDqryEntradaNF['CADASTRO_NF_ID'];
         editPesquisarFornecedor.Text := FDqryEntradaNF['NOME_FANTASIA'];
         DataEmissao.Date := FDqryEntradaNF['DATA_EMISSAO_NF'];
         DataEntrada.Date := FDqryEntradaNF['DATA'];
      if FDqryItensNF.RecordCount > 0 then
         btnAdicionarItens.Caption := 'Alterar Itens'
        else
         btnAdicionarItens.Caption := 'Add Itens';
     end; }
end;

procedure TfrmEntradaNF.brnSairClick(Sender: TObject);
begin
Close;
end;

procedure TfrmEntradaNF.btnCancelarClick(Sender: TObject);
begin
 FDqryEntradaNF.Cancel;
  editPesquisarFornecedor.Clear;
   EnableDisable(0);
end;

procedure TfrmEntradaNF.btnDataGeralClick(Sender: TObject);
begin
AplicarDataGeral;
end;

procedure TfrmEntradaNF.btnExcluirClick(Sender: TObject);
var AuxErro : string;
begin
   if MessageBox(Application.Handle,'Aten��o! '+#13 +'Essa opera��o excluir� a entrada selecionada e todos os itens que foram cadastrados nela.' +#13 + 'Deseja continuar?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
         // if FDqryEntradaNF['STATUS'] = 'PROCESSADA' then //se aberta, n�o fez altera��o de estoque, portanto, n�o precisa verificar estoque.
         //   VerificarEstoqueZerado;  //proibi��o de estoque negativo - impede exclus�o se o saldo do produto for menor do que a qtd a ser exclu�da.
      if FDqryEntradaNF['NF_LANCADA'] = 'SIM' then
         begin
           MessageDlg('N�o h� permiss�o para excluir essa Entrada.' + #13 +'Ela j� foi cadastrada em um lan�amento financeiro.' +#13+ #13+'Para exclu�-la, � necess�rio deletar o lan�amento no registro financeiro.  ', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
           Abort;
         end;
     begin
       try
         FDqryItensNF.First;
         while not FDqryItensNF.Eof do   //Trecho abaixo retirado para n�o haver tentativa de atualiza��o do estoque do produto. Apenas os itens da NF ser�o exclui�dos.
            begin
             {if FDqryEntradaNF['STATUS'] = 'PROCESSADA' then
              begin
                FDqryProduto.Edit;  //N�o � necess�rio locate no produto em raz�o da FDqryProduto ser filha no MASTERDATA da FDqryItensNF
                FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] - FDqryItensNF['QTDE_ITEM'];
               // RegistrarMovimentacaoProduto('EXCLUINDO');
                FDqryProduto.Post;
              end;}
                FDqryItensNF.Delete;
            end;
         FDqryEntradaNF.Delete;
        except
        on E : exception do
         begin
          AuxErro := copy (E.Message,20,25);
          MessageDlg('N�o � poss�vel excluir o registro no momento ' + AuxErro, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
         end;
       end;
     end;
      ProcedureCommitOrRollbackRetaining;
      RefreshDatasets;
    end;
end;

procedure TfrmEntradaNF.btnImprimirNFClick(Sender: TObject);
var  caminhoRelatorio : string;
begin
  with fdqryRelatorio do
     begin
         Close;
         SQL.Clear;
         SQL.Add('select '
                +' CAD.cadastro_nf_id, CAD.fornecedor_id, CAD.data, CAD.data_emissao_nf, CAD.valor_nf, CAD.nf, CAD.status, CAD.nf_lancada, CAD.obs, '
                +' P.produto_id, P.descricao, '
                +' I.item_nf_id, I.produto_id, I.nf_id, I.valor_item, I.qtde_item, I.valor_total_item, '
                +' f.Nome_fantasia, f.fornecedor_id '
                +' from '
                +' cadastro_nf CAD, produto P, item_nf I, fornecedor f '
                +' WHERE '
                +' (i.nf_id = cad.cadastro_nf_id) and '
                +' (I.produto_id = P.produto_id) and '
                +' (cad.fornecedor_id = f.fornecedor_id) and '
                +' (CAD.cadastro_nf_id = :NOTAFISCAL)');
         ParamByName('NOTAFISCAL').AsInteger := FDqryEntradaNF['CADASTRO_NF_ID'];
         Open;

         caminhoRelatorio := ExtractFilePath(Application.ExeName);
         reportEntradaNF.LoadFromFile(caminhoRelatorio +'RelatorioCadastroNF.fr3');
         reportEntradaNF.ShowReport();

     end;
end;

procedure TfrmEntradaNF.btnNovoClick(Sender: TObject);
begin
   rbEntrada.Checked := False;
   rbAjuste.Checked := False;
   EnableDisable(1);
   editPesquisarFornecedor.SetFocus;
   FDqryEntradaNF.Insert;
end;

procedure TfrmEntradaNF.btnProcessarNFClick(Sender: TObject);
 begin
  // if (rbEntrada.Checked = True) or (rbAjuste.Checked = True) then
   //   begin
         if (FDqryEntradaNF.RecordCount > 0) and (FDqryItensNF.RecordCount > 0) and (FDqryEntradaNF['STATUS'] = 'NF ABERTA') then
            begin
               if MessageBox(Application.Handle,'Aten��o! '+#13+'Esta opera��o n�o poder� ser desfeita. Deseja continuar?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
                    begin
                     AtualizarEstoqueDeProdutos;
                        FDqryEntradaNF.Edit;
                        FDqryEntradaNF['STATUS'] := 'PROCESSADA';
                    // if rbAjuste.Checked = True then
                    //  FDqryEntradaNF['NF_LANCADA'] := 'AJU';
                    // if rbEntrada.Checked then
                        FDqryEntradaNF['NF_LANCADA'] := 'N�O';
                        FDqryEntradaNF.Post;
                        ProcedureCommitOrRollbackRetaining;
                        RefreshDatasets;
                        rbAjuste.Checked := False;
                        rbEntrada.Checked := False;
                    end;
            end
               else
                  MessageDlg('N�o h� Entrada/Itens ou a NF j� foi processada', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
   //   end
  // else
  //    MessageDlg('Por favor, escolha o par�metro da entrada ("Entrada Normal ou Ajuste de Estoque") ', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
 end;

procedure TfrmEntradaNF.editConsultaNFEntradaKeyPress(Sender: TObject;
  var Key: Char);
begin
if Key = #13 then
   begin
     btnConsultaNFEntrada.Click;
     Key := #0;
   end;
end;

procedure TfrmEntradaNF.editPesquisarFornecedorDblClick(Sender: TObject);
begin
 try
   Application.CreateForm(TfrmFornecedor,frmFornecedor);
   frmFornecedor.DuploClickNaGrid := 'SUPPLIER';
   frmFornecedor.ShowModal;

 finally
   FreeAndNil(frmFornecedor);
 end;
end;

procedure TfrmEntradaNF.editPesquisarFornecedorKeyPress(Sender: TObject;
  var Key: Char);
begin
 if Key = #13 then
    begin
       try
       Application.CreateForm(TfrmFornecedor,frmFornecedor);
       frmFornecedor.DuploClickNaGrid := 'SUPPLIER';
       frmFornecedor.ShowModal;
       finally
        FreeAndNil(frmFornecedor);
       end;
       Key := #0;
    end;
end;

procedure TfrmEntradaNF.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FDqryEntradaNF.Close;
 FDqryFornecedor.Close;
 FDqryItensNF.Close;
 FDqryProduto.Close;
 FDqryMovProduto.Close;
end;

procedure TfrmEntradaNF.FormShow(Sender: TObject);
begin
 FDqryEntradaNF.Open;
 FDqryFornecedor.Open;
 FDqryItensNF.Open;
 FDqryProduto.Open;
 FDqryMovProduto.Open;
 DataEntrada.Date := Now;
 DataEmissao.Date := Now;
 dataGeralInicio.Date := IncMonth(Date,-6);
 dataGeralFim.Date := Now;
 EnableDisable(0);
 PageControlEntradaNF.TabIndex := 0;
 rbEntradasApenas.Checked := True;
 AplicarDataGeral;

end;

procedure TfrmEntradaNF.GridEntradaNFCellClick(Column: TColumn);
begin
   if (GridEntradaNF.SelectedField.FieldName = 'ADD_ITEM') and (FDqryEntradaNF['STATUS'] = 'NF ABERTA') then
     AdicionarItensNaNF;
end;

procedure TfrmEntradaNF.GridEntradaNFDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
var
  BUTTON: Integer;
  R: TRect;
  SCapt : string;
begin
  if (Column.FieldName = 'ADD_ITEM') and (FDqryEntradaNF['STATUS'] = 'NF ABERTA') then
  begin
    GridEntradaNF.Canvas.FillRect(Rect);
    BUTTON := 0;
    R:=Rect;
    SCapt := 'Add Itens';
    InflateRect(R,-1,-1); //Diminue o tamanho do Bot�o
    DrawFrameControl(GridEntradaNF.Canvas.Handle,R,BUTTON, BUTTON or BUTTON);
    with GridEntradaNF.Canvas do
    begin
      Brush.Style := bsClear;
      Font.Color := clBtnText;
      Font.Size := 8;
      Font.Name := 'Consolas';
     TextRect(Rect, (Rect.Left + Rect.Right - TextWidth(SCapt)) div 2, (Rect.Top + Rect.Bottom - TextHeight(SCapt)) div 2, SCapt);
    end;
  end;
end;

end.
