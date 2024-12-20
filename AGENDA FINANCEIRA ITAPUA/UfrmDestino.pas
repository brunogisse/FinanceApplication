unit UfrmDestino;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
  {uImportExcel,} System.Win.ComObj, Vcl.ComCtrls;

type
  TfrmDestino = class(TForm)
    Panel1: TPanel;
    btnNovo: TImage;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    Image1: TImage;
    gridContas: TDBGrid;
    FDtcDestino: TFDTransaction;
    FDqryDestino: TFDQuery;
    dsDestino: TDataSource;
    FDqryDestinoDESTINO_ID: TIntegerField;
    FDqryDestinoDESCRICAO: TStringField;
    labelDestino: TLabel;
    editDescricao: TDBEdit;
    btnExportarExcel: TButton;
    ProgressBar1: TProgressBar;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure btnNovoClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure Image1Click(Sender: TObject);
    procedure btnExportarExcelClick(Sender: TObject);
  private
    { Private declarations }

    procedure ConfigurarEnables(status : integer);


  public
    { Public declarations }
  end;

var
  frmDestino: TfrmDestino;

implementation

{$R *.dfm}

uses UfrmPrincipal;

procedure TfrmDestino.btnAlterarClick(Sender: TObject);
begin
 ConfigurarEnables(1);
 FDqryDestino.Edit;
end;

procedure TfrmDestino.btnCancelarClick(Sender: TObject);
begin
 ConfigurarEnables(0);
 FDqryDestino.Cancel;
end;

procedure TfrmDestino.btnExcluirClick(Sender: TObject);
var AuxErro : string;
begin
  configurarEnables(0);
 if MessageBox(Application.Handle,'Deseja excluir esse registro?','Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
     try
      FDqryDestino.Delete;
     except
      on E : exception do
       begin
        AuxErro := copy (E.Message,20,25);
        ShowMessage(AuxErro);
       end;
     end;
end;
end;

procedure TfrmDestino.btnExportarExcelClick(Sender: TObject);
 Var planilha : Variant;
     linha, contar : Integer;
begin
       ProgressBar1.Visible := True;
       contar := FDqryDestino.RecordCount;
       ProgressBar1.Max := contar;
       ProgressBar1.Position := 0;

       FDqryDestino.Filtered := False;
       Linha := 2;

       planilha := CreateOleObject('Excel.Application');
       planilha.Caption := 'Tabela de Destinos';
       planilha.workbooks.Add(1);

       Planilha.cells[1,1] :=  'C�digo';
       Planilha.cells[1,2] :=  'Descri��o';

       FDqryDestino.First;

       try
         while not FDqryDestino.Eof do
         begin
           planilha.cells[linha,1] := FDqryDestinoDESTINO_ID.Value;
           planilha.cells[linha,2] := FDqryDestinoDESCRICAO.value;
           linha := linha +1;
           FDqryDestino.Next;
           ProgressBar1.Position := ProgressBar1.Position + 1;
         end;
           planilha.Columns.autofit;
           planilha.visible := true;
           ShowMessage('Processo conclu�do');
           ProgressBar1.Visible := False;
       finally
           planilha := Unassigned;
       end;
end;

procedure TfrmDestino.btnNovoClick(Sender: TObject);
begin
 ConfigurarEnables(1);
 editDescricao.SetFocus;
 FDqryDestino.Insert;
end;

procedure TfrmDestino.btnSalvarClick(Sender: TObject);
begin
  ConfigurarEnables(0);
  FDqryDestino.Post;
  try
    FDtcDestino.CommitRetaining;
  finally
    FDtcDestino.RollbackRetaining;
  end;
end;

procedure TfrmDestino.configurarEnables(status : integer);
begin
    if status = 0 then
    begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editDescricao.Enabled := False;
    end
   else
    begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editDescricao.Enabled := True;
    end;
end;

procedure TfrmDestino.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FDqryDestino.Close;
end;

procedure TfrmDestino.FormShow(Sender: TObject);
begin
 FDqryDestino.Open;
 ConfigurarEnables(0);
end;

procedure TfrmDestino.Image1Click(Sender: TObject);
begin
 frmDestino.Close;
end;

end.
