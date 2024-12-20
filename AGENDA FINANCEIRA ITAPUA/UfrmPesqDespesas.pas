unit UfrmPesqDespesas;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls,
  Data.DB, Vcl.Grids, Vcl.DBGrids, Vcl.ExtCtrls, FireDAC.Stan.Intf,
  FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
  FireDAC.Phys.Intf, FireDAC.DApt.Intf, FireDAC.Stan.Async, FireDAC.DApt,
  FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TfrmPesqDespSub = class(TForm)
    gridPesqDespSub: TDBGrid;
    Panel1: TPanel;
    editPesquisa: TEdit;
    dsSubdespesa: TDataSource;
    FDqrySubdespesa: TFDQuery;
    FDqrySubdespesaSUBCATEGORIA_ID: TIntegerField;
    FDqrySubdespesaDESCRICAO: TStringField;
    FDqrySubdespesaVALOR_MAXIMO: TSingleField;
    FDqrySubdespesaCATEGORIA_FK: TIntegerField;
    FDqrySubdespesaCATEGORIA_ID: TIntegerField;
    FDqrySubdespesaCATEGORIA: TStringField;
    rgOrdenar: TRadioGroup;
    procedure editPesquisaChange(Sender: TObject);
    procedure gridPesqDespSubDblClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure gridPesqDespSubKeyPress(Sender: TObject; var Key: Char);
    procedure rgOrdenarClick(Sender: TObject);
    procedure gridPesqDespSubDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure editPesquisaKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure editPesquisaKeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }

    procedure enviarSubdespesa;
    procedure ordenarSQL;

  public
    { Public declarations }
  var
    setarEditFoco: string;

  end;

var
  frmPesqDespSub: TfrmPesqDespSub;

implementation

{$R *.dfm}

uses UfrmLancamentos, UfrmLancamentosEmLote;

procedure TfrmPesqDespSub.ordenarSQL;
begin

  if rgOrdenar.ItemIndex = 0 then
  begin
    with FDqrySubdespesa do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select S.SUBCATEGORIA_ID, S.DESCRICAO,S.VALOR_MAXIMO, S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA from SUBCATEGORIA S, CATEGORIA C where (S.CATEGORIA_ID = C.CATEGORIA_ID) and (S.DESCRICAO LIKE '
        + QuotedStr('%' + editPesquisa.Text + '%') + ') order by C.DESCRICAO');
      Open;
    end;
  end;

  if rgOrdenar.ItemIndex = 1 then
  begin
    with FDqrySubdespesa do
    begin
      Close;
      SQL.Clear;
      SQL.Add('select S.SUBCATEGORIA_ID, S.DESCRICAO,S.VALOR_MAXIMO, S.CATEGORIA_ID as CATEGORIA_FK, C.CATEGORIA_ID, C.DESCRICAO as CATEGORIA from SUBCATEGORIA S, CATEGORIA C where (S.CATEGORIA_ID = C.CATEGORIA_ID) and (S.DESCRICAO LIKE '
        + QuotedStr('%' + editPesquisa.Text + '%') + ') order by S.DESCRICAO');
      Open;
    end;
  end;

end;

procedure TfrmPesqDespSub.rgOrdenarClick(Sender: TObject);
begin
  ordenarSQL;
end;

procedure TfrmPesqDespSub.editPesquisaKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  If Key = VK_DOWN then
    FDqrySubdespesa.Next;
  if Key = VK_UP then
    FDqrySubdespesa.Prior;
end;

procedure TfrmPesqDespSub.editPesquisaKeyPress(Sender: TObject; var Key: Char);
begin
  if Key = #13 then
  begin
    enviarSubdespesa;
    Key := #0;
  end;
end;

procedure TfrmPesqDespSub.enviarSubdespesa;                 //frmLancamentosEmLote
begin
  if setarEditFoco = 'relatório' then
  begin
    frmLancamento.editRELATORIOpesqDS.Text := FDqrySubdespesa['DESCRICAO'];
    frmLancamento.CategoriaPesquisa := FDqrySubdespesa['CATEGORIA'];
    frmLancamento.editRELATORIOpesqDS.Enabled := False;
    if FDqrySubdespesa['VALOR_MAXIMO'] <> null then
      frmLancamento.valorMAXIMOsubdespesa := FDqrySubdespesa['VALOR_MAXIMO'];
  end

  else if setarEditFoco = 'cadastro' then

  begin
    frmLancamento.editPesquisaDespSub.Text := FDqrySubdespesa['DESCRICAO'] +
      '  [' + FDqrySubdespesa['CATEGORIA'] + ']';
    frmLancamento.FDqryLcto['SUBCATEGORIA_FK'] := FDqrySubdespesa['SUBCATEGORIA_ID'];
    frmLancamento.FDqryLcto['CATEGORIA_FK'] := FDqrySubdespesa['CATEGORIA_ID'];
  end

  else if setarEditFoco = 'cadastro em lote' then

  begin
    frmLancamentosEmLote.editPesquisaDespSub.Text := FDqrySubdespesa['DESCRICAO'] +
      '  [' + FDqrySubdespesa['CATEGORIA'] + ']';
    frmLancamentosEmLote.FDqryLcto['SUBCATEGORIA_FK'] := FDqrySubdespesa['SUBCATEGORIA_ID'];
    frmLancamentosEmLote.FDqryLcto['CATEGORIA_FK'] := FDqrySubdespesa['CATEGORIA_ID'];
  end;

  setarEditFoco := '';
  frmPesqDespSub.Close;
end;

procedure TfrmPesqDespSub.editPesquisaChange(Sender: TObject);
begin

  ordenarSQL;

end;

procedure TfrmPesqDespSub.FormShow(Sender: TObject);
begin
  editPesquisa.Clear;
  FDqrySubdespesa.Close;
  FDqrySubdespesa.Open;
  rgOrdenar.ItemIndex := 0;
  editpesquisa.SetFocus;
end;

procedure TfrmPesqDespSub.gridPesqDespSubDblClick(Sender: TObject);
begin
  enviarSubdespesa;
end;

procedure TfrmPesqDespSub.gridPesqDespSubDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
  with gridPesqDespSub do
  begin
    if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then
    // Cor da linha selecionada
      if (Rect.Top = TStringGrid(gridPesqDespSub).CellRect(DataCol,
        TStringGrid(gridPesqDespSub).Row).Top) or (gdSelected in State) then
      begin
        Canvas.FillRect(Rect);
        Canvas.Brush.Color := clblue;
        Canvas.Font.Color := clwhite;
        DefaultDrawDataCell(Rect, Column.Field, State)
      end;
  end;
end;

procedure TfrmPesqDespSub.gridPesqDespSubKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    enviarSubdespesa;
    Key := #0;
  end;
end;

end.
