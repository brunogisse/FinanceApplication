unit UfrmSaidaProdutos;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Data.DB, Vcl.Grids,
  Vcl.DBGrids, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.DBCtrls, Vcl.Buttons, Vcl.Mask;

type
  TfrmSaidaProdutos = class(TForm)
    PainelTopo: TPanel;
    PainelEdits: TPanel;
    gridSaidaProdutos: TDBGrid;
    PainelBottom: TPanel;
    FDtcSaidaProdutos: TFDTransaction;
    FDqrySaidaProdutos: TFDQuery;
    dsSaidaProdutos: TDataSource;
    FDqrySaidaProdutosSAIDA_PRODUTO_ID: TIntegerField;
    FDqrySaidaProdutosDESTINO_ID: TIntegerField;
    FDqrySaidaProdutosPROPRIEDADE_ID: TIntegerField;
    FDqrySaidaProdutosPRODUTO_ID: TIntegerField;
    FDqrySaidaProdutosDATA: TDateField;
    FDqrySaidaProdutosQTDE: TIntegerField;
    FDqrySaidaProdutosOBS: TStringField;
    FDqrySaidaProdutosDESTINO: TStringField;
    FDqrySaidaProdutosPROPRIEDADE: TStringField;
    FDqrySaidaProdutosPRODUTO: TStringField;
    dsDestino: TDataSource;
    dsPropriedade: TDataSource;
    dsProduto: TDataSource;
    FDqryDestino: TFDQuery;
    FDqryPropriedade: TFDQuery;
    FDqryProduto: TFDQuery;
    FDqryProdutoPRODUTO_ID: TIntegerField;
    FDqryProdutoDESCRICAO: TStringField;
    FDqryProdutoVALOR: TFMTBCDField;
    FDqryProdutoESTOQUE_MINIMO: TIntegerField;
    FDqryProdutoTIPO: TIntegerField;
    FDqryProdutoESTOQUE: TIntegerField;
    FDqryProdutoTIPO_PRODUTO_ID: TIntegerField;
    FDqryProdutoTIPO_DESCRICAO: TStringField;
    FDqryPropriedadeDESCRICAO: TStringField;
    FDqryPropriedadePROPRIEDADE_ID: TIntegerField;
    FDqryDestinoDESTINO_ID: TIntegerField;
    FDqryDestinoDESCRICAO: TStringField;
    gbPrincipal: TGroupBox;
    DataSaida: TDateTimePicker;
    labelData: TLabel;
    cbDestino: TDBLookupComboBox;
    labelDestino: TLabel;
    cbPropriedade: TDBLookupComboBox;
    labelPropriedade: TLabel;
    labelProduto: TLabel;
    editProduto: TEdit;
    labelQtde: TLabel;
    editQTDE: TEdit;
    btnNovo: TBitBtn;
    btnCancelar: TBitBtn;
    btnSalvar: TBitBtn;
    btnExcluir: TBitBtn;
    memoOBS: TDBMemo;
    FDqryMovProduto: TFDQuery;
    FDqryMovProdutoMOVIMENTACAO_ID: TIntegerField;
    FDqryMovProdutoDATA: TDateField;
    FDqryMovProdutoPRODUTO_ID: TIntegerField;
    FDqryMovProdutoTIPO: TStringField;
    FDqryMovProdutoQTDE: TIntegerField;
    FDqryMovProdutoSALDO_ATUAL: TIntegerField;
    FDqryMovProdutoVALOR_PRODUTO: TFMTBCDField;
    FDqryMovProdutoOBS: TStringField;
    FDqryMovProdutoADICIONAIS: TStringField;
    dsMovProduto: TDataSource;
    gbProdutos: TGroupBox;
    labelCodigoProduto: TLabel;
    editCodigoProdut: TDBEdit;
    labelValorProduto: TLabel;
    editValorProduto: TDBEdit;
    labelEstoqueProduto: TLabel;
    editEstoqueProduto: TDBEdit;
    labelTipoProduto: TLabel;
    editTipoProduto: TDBEdit;
    labelValorSaida: TLabel;
    editValorSaida: TEdit;
    FDqrySaidaProdutosVALOR_SAIDA: TFMTBCDField;
    gbDataGeral: TGroupBox;
    labelPeriodoGeral: TLabel;
    dataGeralInicio: TDateTimePicker;
    dataGeralFim: TDateTimePicker;
    btnDataGeral: TBitBtn;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure editProdutoDblClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure editProdutoKeyPress(Sender: TObject; var Key: Char);
    procedure editQTDEExit(Sender: TObject);
    procedure editQTDEChange(Sender: TObject);
    procedure btnDataGeralClick(Sender: TObject);
  private
    { Private declarations }

    procedure EnableDisable(status : integer);
    function VerificarCamposVazios() : boolean;
    procedure CommitOrRollback_Retaining;
    procedure RefreshDatasets;
    procedure MovimentarEstoque(tipo : string);
    procedure VerificarEstoqueZerado;
    procedure RegistrarMovimentacaoProduto(TipoOperacao : string);
    procedure SQLcomParametros;
    procedure AplicarDataGeral;


  public
    { Public declarations }

    var MotivoExclusao : string;
  end;

var
  frmSaidaProdutos: TfrmSaidaProdutos;

implementation

{$R *.dfm}

uses UfrmPrincipal, UfrmPesquisaProduto;


procedure tfrmSaidaProdutos.AplicarDataGeral;
begin
   with FDqrySaidaProdutos do
   begin
     Close;
     ParamByName('INICIO').AsDate := dataGeralInicio.Date;
     ParamByName('FIM').AsDate := dataGeralFim.Date;
     Open;
   end;
end;

procedure TfrmSaidaProdutos.SQLcomParametros;
begin
  with FDqrySaidaProdutos do
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
              +' (S.PRODUTO_ID = PRO.PRODUTO_ID) order by S.SAIDA_PRODUTO_ID');
      Open;
    end;
end;


procedure TfrmSaidaProdutos.RegistrarMovimentacaoProduto(TipoOperacao : string);
 begin
       FDqryMovProduto.Insert;
       FDqryMovProduto['PRODUTO_ID'] := FDqryProduto['PRODUTO_ID'];
       FDqryMovProduto['DATA'] := Now;
       FDqryMovProduto['SALDO_ATUAL'] := FDqryProduto['ESTOQUE'];
       FDqryMovProduto['VALOR_PRODUTO'] := FDqryProduto['VALOR'];

    if TipoOperacao = 'SALVANDO' then

        begin
           FDqryMovProduto['QTDE'] := StrToInt(editQTDE.Text);
           FDqryMovProduto['TIPO'] := 'S';
           FDqryMovProduto['ADICIONAIS'] :=  'C�digo da Sa�da: ' + IntToStr(FDqrySaidaProdutos['SAIDA_PRODUTO_ID']) + ' - feita pelo User: ' + frmPrincipal.FDqryLogin['NOME'] + '.';
        if FDqrySaidaProdutos['OBS'] <> '' then
           FDqryMovProduto['OBS'] := FDqrySaidaProdutos['OBS']
          else
           FDqryMovProduto['OBS'] := '';
        end

      else if TipoOperacao = 'EXCLUINDO' then

        begin
           FDqryMovProduto['QTDE'] := FDqrySaidaProdutos['QTDE'];
           FDqryMovProduto['TIPO'] := 'E';
           FDqryMovProduto['ADICIONAIS'] := 'Ajuste de estoque pela exclus�o de Sa�da';
           FDqryMovProduto['OBS'] := 'Exclus�o da Sa�da: '+ IntToStr(FDqrySaidaProdutos['SAIDA_PRODUTO_ID']) + ' | User: ' + frmPrincipal.FDqryLogin['NOME'] + ' Motivo: ' + MotivoExclusao + '.';
        end;
           FDqryMovProduto.Post;
 end;

procedure TfrmSaidaProdutos.VerificarEstoqueZerado;
 var ProdutoZerado : string;
 begin
     ProdutoZerado := '';
         if FDqryProduto['ESTOQUE'] < StrToInt(editQTDE.Text) then
             ProdutoZerado := ProdutoZerado + #13 + FDqryProduto['DESCRICAO'] + ' - Estoque [' + IntToStr(FDqryProduto['ESTOQUE']) +'] - Tentando dar baixa em [' + editQTDE.Text +']   ' ;
   if ProdutoZerado <> '' then
       begin
         MessageDlg('N�o foi poss�vel dar baixa no estoque. '+ #13 + '� necess�rio ajustar o saldo do produto abaixo: ' + #13 + #13 + ' ' + ProdutoZerado, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
         Abort;
       end;
 end;

procedure TfrmSaidaProdutos.MovimentarEstoque(tipo : string);
begin
   if tipo = 'SA�DA' then
     begin
      FDqryProduto.Edit;
      FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] - StrToInt(editQTDE.Text);
     end else
   if tipo = 'ENTRADA' then
     begin
      FDqryProduto.Locate('PRODUTO_ID',FDqrySaidaProdutos['PRODUTO_ID'],[]);
      FDqryProduto.Edit;
      FDqryProduto['ESTOQUE'] := FDqryProduto['ESTOQUE'] + FDqrySaidaProdutos['QTDE'];
     end;
      FDqryProduto.Post;
end;

procedure TfrmSaidaProdutos.RefreshDatasets;
begin
 FDqrySaidaProdutos.Close;
 FDqryDestino.Close;
 FDqryPropriedade.Close;
 FDqryProduto.Close;

 FDqrySaidaProdutos.Open;
 FDqryDestino.Open;
 FDqryPropriedade.Open;
 FDqryProduto.Open;
end;

procedure TfrmSaidaProdutos.CommitOrRollback_Retaining;
begin
  try
    FDtcSaidaProdutos.CommitRetaining;
  Except
     FDtcSaidaProdutos.RollbackRetaining;
  end;
end;

function TfrmSaidaProdutos.VerificarCamposVazios() : boolean;
begin
  if (editProduto.Text = '') or (editQTDE.Text = '') or (cbDestino.Text = '') or (cbPropriedade.Text = '') or (memoOBS.Text = '') then
     begin
       MessageBox(Application.Handle,'Verifique os campos vazios','Aten��o', MB_OK + MB_ICONINFORMATION);
       Result := True;
     end
    else
       Result := False;
end;

procedure TfrmSaidaProdutos.btnCancelarClick(Sender: TObject);
begin
 PainelEdits.Height := 10;
 EnableDisable(0);
 FDqrySaidaProdutos.Cancel;
 gridSaidaProdutos.Enabled := True;
end;

procedure TfrmSaidaProdutos.btnDataGeralClick(Sender: TObject);
begin
AplicarDataGeral;
end;

procedure TfrmSaidaProdutos.btnExcluirClick(Sender: TObject);
 var AuxErro : string;
begin
  if MessageBox(Application.Handle,'Deseja realmente excluir esta sa�da?' + #13 + 'Essa opera��o � irrevers�vel' ,'Confirma��o',MB_YESNO + MB_ICONQUESTION) = mrYes then

       // MotivoExclusao := InputBox('Informe','Qual o motivo?','');

      try

       // MovimentarEstoque('ENTRADA');
       // RegistrarMovimentacaoProduto('EXCLUINDO');
        FDqrySaidaProdutos.Delete;

       except

        on E: exception do

         begin
          AuxErro := Copy(e.Message,0,100);
          MessageDlg('N�o foi poss�vel excluir a movimenta��o. Motivo:' + AuxErro, TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
         end;

      end;
end;

procedure TfrmSaidaProdutos.btnNovoClick(Sender: TObject);
begin
  PainelEdits.Height := 195;
  EnableDisable(1);
  FDqrySaidaProdutos.Insert;
  gridSaidaProdutos.Enabled := False;
end;

procedure TfrmSaidaProdutos.btnSalvarClick(Sender: TObject);
  begin
   if VerificarCamposVazios() = False then
      begin
       // VerificarEstoqueZerado;
        FDqrySaidaProdutos['PRODUTO_ID'] := FDqryProduto['PRODUTO_ID'];
        FDqrySaidaProdutos['DATA'] := DataSaida.Date;
        FDqrySaidaProdutos['QTDE'] := StrToInt(editQTDE.Text);
        FDqrySaidaProdutos['PROPRIEDADE_ID'] := FDqryPropriedade['PROPRIEDADE_ID'];
        FDqrySaidaProdutos['DESTINO_ID'] := FDqryDestino['DESTINO_ID'];
        FDqrySaidaProdutos['VALOR_SAIDA'] := StrToFloat(editValorSaida.Text);
       // MovimentarEstoque('SA�DA');
       // RegistrarMovimentacaoProduto('SALVANDO');
        FDqrySaidaProdutos.Post;
        CommitOrRollback_Retaining;
        RefreshDatasets;
        PainelEdits.Height := 10;
        gridSaidaProdutos.Enabled := True;
        EnableDisable(0);
        editProduto.Clear;
        editQTDE.Clear;
        cbPropriedade.KeyValue := Null;
        cbDestino.KeyValue := Null;
      end;
  end;

procedure TfrmSaidaProdutos.editProdutoDblClick(Sender: TObject);
begin
   frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'SA�DA';
   frmPesquisarProdutos.ShowModal;
end;

procedure TfrmSaidaProdutos.editProdutoKeyPress(Sender: TObject; var Key: Char);
begin
 if Key = #13 then
   begin
     frmPesquisarProdutos.EntradaOuSaidaOuRelatorio := 'SA�DA';
     frmPesquisarProdutos.ShowModal;
     Key := #0;
   end;
end;

procedure TfrmSaidaProdutos.editQTDEChange(Sender: TObject);
var qtde : integer; valorProduto : double;
begin
 if editQTDE.Text <> '' then
  begin
   qtde := StrToInt(editQTDE.Text);
   valorProduto := FDqryProduto['VALOR'];
   editValorSaida.Text := FormatFloat('0.00', qtde * valorProduto);
  end;
end;

procedure TfrmSaidaProdutos.editQTDEExit(Sender: TObject);
begin
 if editQTDE.Text = '' then
    begin
      MessageDlg('Informe a quantidade', TMsgDlgType.mtWarning,[TMsgDlgBtn.mbOK],0);
      editQTDE.Text := '1';
      editQTDE.SetFocus;
    end;

end;

procedure TfrmSaidaProdutos.EnableDisable(status : integer);
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


procedure TfrmSaidaProdutos.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
 FDqrySaidaProdutos.Close;
 FDqryDestino.Close;
 FDqryPropriedade.Close;
 FDqryProduto.Close;
 FDqryMovProduto.Close;

 end;

procedure TfrmSaidaProdutos.FormShow(Sender: TObject);
begin
 PainelEdits.Height := 10;
 FDqrySaidaProdutos.Open;
 FDqryDestino.Open;
 FDqryPropriedade.Open;
 FDqryProduto.Open;
 FDqryMovProduto.Open;
 DataSaida.Date := Now;
 dataGeralInicio.Date := IncMonth(Now,-6);
 dataGeralFim.Date := Now;
 EnableDisable(0);

 AplicarDataGeral;
end;

end.
