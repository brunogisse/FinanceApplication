unit uFonteParaRealCategoria;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf,
  FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt, Data.DB,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client, Vcl.ExtCtrls, Vcl.Grids,
  Vcl.DBGrids;

type
  TfrmFonteParaRelCategoria = class(TForm)
    fdqryFonteParaRelCategoria: TFDQuery;
    dsFonteParaRelCategoria: TDataSource;
    painelFonteParaRelCategoria: TPanel;
    DBGrid1: TDBGrid;
    fdqryFonteParaRelCategoriaCATEGORIA_ID: TIntegerField;
    fdqryFonteParaRelCategoriaDESCRICAO: TStringField;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmFonteParaRelCategoria: TfrmFonteParaRelCategoria;

implementation

{$R *.dfm}

uses UcategoriaGeral, UfrmPesqDespesas, UfrmPrincipal, UpesquisaCategoria;

procedure TfrmFonteParaRelCategoria.DBGrid1DblClick(Sender: TObject);
begin
 frmPesquisaCategoria.editRotuloDaCategoria.Text := fdqryFonteParaRelCategoria['DESCRICAO'];
 Close;
end;

procedure TfrmFonteParaRelCategoria.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
fdqryFonteParaRelCategoria.Close;
end;

procedure TfrmFonteParaRelCategoria.FormShow(Sender: TObject);
begin
 fdqryFonteParaRelCategoria.Open;
end;

end.
