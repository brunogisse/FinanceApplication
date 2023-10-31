unit UfrmLancamentosEmLote;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Vcl.ExtCtrls, FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.StdCtrls, Vcl.Buttons, ComObj;

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
    procedure btnPlanilhaClick(Sender: TObject);
    procedure btnCarregarPlanilhaClick(Sender: TObject);
    procedure btnLimparClick(Sender: TObject);
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

procedure TfrmLancamentosEmLote.CarregarDadosDoExcel;

var
  ExcelApp: Variant;
  Planilha: Variant;
  Linha: Integer;
  NomePlanilha, NomeArquivo : String;
begin
  try
    try
      ExcelApp := CreateOleObject('Excel.Application'); // Cria uma inst�ncia do Excel
      ExcelApp.Workbooks.Open(editCaminhoPlanilha.Text); // Substitua pelo caminho da sua planilha

      NomePlanilha := ExtractFileName(editCaminhoPlanilha.Text);

      Planilha := ExcelApp.Worksheets['Planilha1']; // Substitua 'Planilha' pelo nome da sua planilha

     // cldsPlanilhaLote.FieldDefs.Clear; // Limpa as defini��es de campo existentes

      cldsPlanilhaLote.EmptyDataSet;
      gridLote.DataSource := nil;


      // Adiciona os campos ao FDMemTable baseado nas colunas da planilha
      for Linha := 2 to Planilha.UsedRange.Rows.Count -1 do
      begin
    //    if Linha = 1 then
    //    begin
    //      // Adiciona os campos na primeira linha
    //      cldsPlanilhaLote.FieldDefs.Add(Planilha.Cells[Linha, 1], ftString, 50);
    //      cldsPlanilhaLote.FieldDefs.Add(Planilha.Cells[Linha, 2], ftFloat);
    //      cldsPlanilhaLote.FieldDefs.Add(Planilha.Cells[Linha, 3], ftDate);
    //      // ... adicione os outros campos conforme necess�rio
    //    end
    //    else
        begin
          // Adiciona os registros nas linhas seguintes
          cldsPlanilhaLote.Append;
          cldsPlanilhaLote.Fields[0].AsString := Planilha.Cells[Linha, 1];
          cldsPlanilhaLote.Fields[1].AsFloat := Planilha.Cells[Linha, 2];
          cldsPlanilhaLote.Fields[2].AsDateTime := Planilha.Cells[Linha, 3];
          // ... atribua os outros campos conforme necess�rio
          cldsPlanilhaLote.Post;
        end;
      end;
    finally
      ExcelApp.Quit; // Fecha o Excel
      ExcelApp := Unassigned; // Libera a inst�ncia do Excel
      gridLote.DataSource := dsPlanilhaLote;
      cldsPlanilhaLote.First;
    end;
  Except
    ExcelApp.Quit; // Fecha o Excel
    ExcelApp := Unassigned; // Libera a inst�ncia do Excel
  end;
end;


procedure TfrmLancamentosEmLote.btnCarregarPlanilhaClick(Sender: TObject);
begin
  CarregarDadosDoExcel;
end;

procedure TfrmLancamentosEmLote.btnLimparClick(Sender: TObject);
begin
  cldsPlanilhaLote.EmptyDataSet;
end;

procedure TfrmLancamentosEmLote.btnPlanilhaClick(Sender: TObject);
begin
   if OpenDialog1.Execute() then;
    editCaminhoPlanilha.Text :=  OpenDialog1.FileName;
end;

end.
