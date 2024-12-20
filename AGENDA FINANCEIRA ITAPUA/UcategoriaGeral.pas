unit UcategoriaGeral;

interface

uses
   Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
   System.Classes, Vcl.Graphics,
   Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.ExtCtrls, Vcl.Grids,
   Vcl.DBGrids, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls, Vcl.ComCtrls,
   FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
   FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
   FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client,
   Vcl.Imaging.jpeg, Vcl.Imaging.pngimage, StrUtils;

type
   TfrmCategoriaGeral = class(TForm)
      gridSubcategoria: TDBGrid;
      ControlBar1: TControlBar;
      gridCategoria: TDBGrid;
      PageControl: TPageControl;
      pageCategoria: TTabSheet;
      PageSubcategoria: TTabSheet;
      painelTopo: TPanel;
      labelCategoria: TLabel;
      editCategoria: TDBEdit;
      labelPesquisaCategoria: TLabel;
      editPesqCat: TEdit;
      RadioGroup1: TRadioGroup;
      labelSubcategoria: TLabel;
      editSubcategoria: TDBEdit;
      labelPesqCatFK: TLabel;
      editPesqCatS: TEdit;
      RadioGroup2: TRadioGroup;
      FDtcCatSub: TFDTransaction;
      FDqryCategoria: TFDQuery;
      FDqrySubcategoria: TFDQuery;
      dsCategoria: TDataSource;
      dsSubcategoria: TDataSource;
      FDqryCategoriaCATEGORIA_ID: TIntegerField;
      FDqryCategoriaDESCRICAO: TStringField;
      FDqrySubcategoriaSUBCATEGORIA_ID: TIntegerField;
      FDqrySubcategoriaDESCRICAO: TStringField;
      FDqrySubcategoriaCATEGORIA: TStringField;
      FDqrySubcategoriaCATEGORIA_FK: TIntegerField;
      FDqrySubcategoriaCATEGORIA_ID: TIntegerField;
      btnNovo: TImage;
      Label2: TLabel;
      editCategoriaS: TDBEdit;
      btnSalvar: TImage;
      btnCancelar: TImage;
      btnAlterar: TImage;
      btnExcluir: TImage;
      labelCategoriaAtribuida: TLabel;
      brnSair: TImage;
      labelValorMaximo: TLabel;
      editValorMaximo: TDBEdit;
      FDqrySubcategoriaVALOR_MAXIMO: TSingleField;
      procedure btnNovoClick(Sender: TObject);
      procedure FormClose(Sender: TObject; var Action: TCloseAction);
      procedure FormShow(Sender: TObject);
      procedure btnSalvarClick(Sender: TObject);
      procedure editPesqCatChange(Sender: TObject);
      procedure FormCreate(Sender: TObject);
      procedure editPesqCatSChange(Sender: TObject);
      procedure btnCancelarClick(Sender: TObject);
      procedure btnExcluirClick(Sender: TObject);
      procedure btnAlterarClick(Sender: TObject);
      procedure editCategoriaKeyPress(Sender: TObject; var Key: Char);
      procedure editSubcategoriaKeyPress(Sender: TObject; var Key: Char);
      procedure gridCategoriaCellClick(Column: TColumn);
      procedure gridSubcategoriaCellClick(Column: TColumn);
      procedure gridCategoriaDblClick(Sender: TObject);
      procedure gridSubcategoriaDblClick(Sender: TObject);
      procedure brnSairClick(Sender: TObject);
      procedure editValorMaximoKeyPress(Sender: TObject; var Key: Char);
      procedure editValorMaximoChange(Sender: TObject);
      procedure gridCategoriaDrawColumnCell(Sender: TObject; const Rect: TRect;
        DataCol: Integer; Column: TColumn; State: TGridDrawState);
      procedure gridSubcategoriaDrawColumnCell(Sender: TObject;
        const Rect: TRect; DataCol: Integer; Column: TColumn;
        State: TGridDrawState);
   private
      { Private declarations }

      procedure novoRegistro;
      procedure cancelarRegistro;
      procedure salvarRegistro;
      procedure editarRegistro;
      procedure atualizarBanco;
      procedure filtrarCategoria;
      procedure excluirRegistro;
      procedure configurarEnables(status: Integer);
      procedure setarFoco;
      function FormatarMoeda(valor: string): string;

   public
      { Public declarations }
   end;

var
   frmCategoriaGeral: TfrmCategoriaGeral;

implementation

{$R *.dfm}

uses UfrmPrincipal;

function TfrmCategoriaGeral.FormatarMoeda(valor: string): string;
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
      { 6 .. 8:
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
        end }
   else
      Result := LeftStr(valor, Length(valor) - 2) + ',' + decimais;
   end;
end;

procedure TfrmCategoriaGeral.setarFoco;
begin
   if PageControl.TabIndex = 1 then
      editSubcategoria.SetFocus
   else
      editCategoria.SetFocus;
end;

procedure TfrmCategoriaGeral.configurarEnables(status: Integer);
begin
   if status = 0 then
   begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editCategoria.Enabled := False;
      editSubcategoria.Enabled := False;
      editCategoriaS.Enabled := False;
   end
   else
   begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editCategoria.Enabled := True;
      editSubcategoria.Enabled := True;
      editCategoriaS.Enabled := True;
   end;
end;

procedure TfrmCategoriaGeral.excluirRegistro;
var
   AuxErro: string;
begin
   if MessageBox(Application.Handle, 'Deseja realmente Excluir esse registro?',
     'Aten��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
   begin
      try
         if PageControl.TabIndex = 0 then
         begin
            FDqryCategoria.delete;
         end;
         if PageControl.TabIndex = 1 then
         begin
            FDqrySubcategoria.delete;
         end;
      except
         on E: exception do
         begin
            AuxErro := copy(E.Message, 20, 25);
            MessageDlg('N�o � poss�vel excluir o registro no momento.' + #13 +
              #13 + 'Este registro est� sendo referenciado em outra tabela. ' +
              #13 + #13 + 'Para mais informa��es, pesquise sobre o termo: ' +
              AuxErro, TMsgDlgType.mtWarning, [TMsgDlgBtn.mbOK], 0);
         end;
      end;

   end;
end;

procedure TfrmCategoriaGeral.editarRegistro;
begin
   if PageControl.TabIndex = 0 then
   begin
      FDqryCategoria.Edit;
      PageControl.TabIndex := 0;
   end;
   if PageControl.TabIndex = 1 then
   begin
      PageControl.TabIndex := 0;
      FDqrySubcategoria.Edit;
      labelCategoriaAtribuida.Visible := True;
      labelCategoriaAtribuida.Caption := '[Atribuir para a Despesa: ' +
        FDqryCategoria['DESCRICAO'] + ']';
   end;
end;

procedure TfrmCategoriaGeral.editCategoriaKeyPress(Sender: TObject;
  var Key: Char);
begin
   if Key = #13 then
   begin
      salvarRegistro;
      novoRegistro;
      setarFoco;
      Key := #0;
   end;
end;

procedure TfrmCategoriaGeral.cancelarRegistro;
begin
   if PageControl.TabIndex = 0 then
      FDqryCategoria.Cancel;
   if PageControl.TabIndex = 1 then
   begin
      FDqrySubcategoria.Cancel;
      labelCategoriaAtribuida.Visible := False;
   end;
end;

procedure TfrmCategoriaGeral.filtrarCategoria;
var
   trecho: string;
begin
   if PageControl.TabIndex = 0 then
      trecho := editPesqCat.Text;
   if PageControl.TabIndex = 1 then
      trecho := editPesqCatS.Text;
   with FDqryCategoria do
   begin
      Close;
      SQL.Clear;
      SQL.Add('select * from CATEGORIA where DESCRICAO like ' +
        QuotedStr('%' + trecho + '%') + 'ORDER BY DESCRICAO ASC');
      Open;
   end;

end;

procedure TfrmCategoriaGeral.btnNovoClick(Sender: TObject);
begin
   configurarEnables(1);
   setarFoco;
   novoRegistro;
end;

procedure TfrmCategoriaGeral.btnSalvarClick(Sender: TObject);
begin
   salvarRegistro;
   configurarEnables(0);
end;

procedure TfrmCategoriaGeral.btnAlterarClick(Sender: TObject);
begin
   editarRegistro;
   configurarEnables(1);
end;

procedure TfrmCategoriaGeral.btnCancelarClick(Sender: TObject);
begin
   cancelarRegistro;
   configurarEnables(0);
end;

procedure TfrmCategoriaGeral.btnExcluirClick(Sender: TObject);
begin
   excluirRegistro;
   configurarEnables(0);
end;

procedure TfrmCategoriaGeral.editPesqCatChange(Sender: TObject);
begin
   filtrarCategoria;
end;

procedure TfrmCategoriaGeral.editPesqCatSChange(Sender: TObject);
begin
   filtrarCategoria;
end;

procedure TfrmCategoriaGeral.editSubcategoriaKeyPress(Sender: TObject;
  var Key: Char);
begin
   if Key = #13 then
   begin
      salvarRegistro;
      novoRegistro;
      setarFoco;
      Key := #0;
   end;

end;

procedure TfrmCategoriaGeral.editValorMaximoChange(Sender: TObject);
begin
   editValorMaximo.Text := FormatarMoeda(editValorMaximo.Text);
   editValorMaximo.SelStart := Length(editValorMaximo.Text);
end;

procedure TfrmCategoriaGeral.editValorMaximoKeyPress(Sender: TObject;
  var Key: Char);
begin
   if Key = #13 then
   begin
      salvarRegistro;
      novoRegistro;
      setarFoco;
      Key := #0;
   end;
end;

procedure TfrmCategoriaGeral.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
   FDqryCategoria.Close;
   FDqrySubcategoria.Close;
end;

procedure TfrmCategoriaGeral.FormCreate(Sender: TObject);
begin
   if (Screen.Width = 800) and (Screen.Height = 600) then
      frmCategoriaGeral.Position := poDefault
   else
      frmCategoriaGeral.Position := poScreenCenter;
end;

procedure TfrmCategoriaGeral.FormShow(Sender: TObject);
begin
   FDqryCategoria.Open;
   FDqrySubcategoria.Open;
   configurarEnables(0);
   PageControl.TabIndex := 0;
end;

procedure TfrmCategoriaGeral.gridCategoriaCellClick(Column: TColumn);
begin
   FDqryCategoria.Cancel;
   FDqrySubcategoria.Cancel;
   configurarEnables(0);
end;

procedure TfrmCategoriaGeral.gridCategoriaDblClick(Sender: TObject);
begin
   if MessageBox(Application.Handle, 'Deseja alterar esta Despesa?',
     'Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
   begin
      PageControl.TabIndex := 0;
      editarRegistro;
      configurarEnables(1);
   end;
end;

procedure TfrmCategoriaGeral.gridCategoriaDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
   with gridCategoria do
   begin
      if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then
      // Cor da linha selecionada
         if (Rect.Top = TStringGrid(gridCategoria).CellRect(DataCol,
           TStringGrid(gridCategoria).Row).Top) or (gdSelected in State) then
         begin
            Canvas.FillRect(Rect);
            Canvas.Brush.Color := $00FFCCCE;
            canvas.Font.Color := clgray;
            DefaultDrawDataCell(Rect, Column.Field, State)
         end;
   end;
end;

procedure TfrmCategoriaGeral.gridSubcategoriaCellClick(Column: TColumn);
begin
   FDqryCategoria.Cancel;
   FDqrySubcategoria.Cancel;
   configurarEnables(0);
end;

procedure TfrmCategoriaGeral.gridSubcategoriaDblClick(Sender: TObject);
begin
   if MessageBox(Application.Handle, 'Deseja alterar esta Subdespesa?',
     'Confirma��o', MB_YESNO + MB_ICONQUESTION) = mrYes then
   begin
      PageControl.TabIndex := 1;
      editarRegistro;
      configurarEnables(1);
   end;
end;

procedure TfrmCategoriaGeral.gridSubcategoriaDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn; State: TGridDrawState);
begin
   with gridSubcategoria do
   begin
      if DataSource.DataSet.State in [dsEdit, dsInsert, dsBrowse] then
      // Cor da linha selecionada
         if (Rect.Top = TStringGrid(gridSubcategoria).CellRect(DataCol,
           TStringGrid(gridSubcategoria).Row).Top) or (gdSelected in State) then
         begin
            Canvas.FillRect(Rect);
            Canvas.Brush.Color := $00FFCCCE;
            canvas.Font.Color := clgray;
            DefaultDrawDataCell(Rect, Column.Field, State)
         end;
   end;
end;

procedure TfrmCategoriaGeral.brnSairClick(Sender: TObject);
begin
   Close;
end;

procedure TfrmCategoriaGeral.novoRegistro;
begin
   if PageControl.TabIndex = 0 then
   begin
      FDqryCategoria.Insert;
   end;
   if PageControl.TabIndex = 1 then
   begin
      FDqrySubcategoria.Insert;
      labelCategoriaAtribuida.Visible := True;
      labelCategoriaAtribuida.Caption := '[Atribuir para a Despesa: ' +
        FDqryCategoria['DESCRICAO'] + ']';
   end;
end;

procedure TfrmCategoriaGeral.atualizarBanco;
begin
   FDqryCategoria.Close;
   FDqrySubcategoria.Close;
   FDqryCategoria.Open;
   FDqrySubcategoria.Open;
end;

procedure TfrmCategoriaGeral.salvarRegistro;
begin
   if PageControl.TabIndex = 0 then
      FDqryCategoria.Post;
   if PageControl.TabIndex = 1 then
   begin
      FDqrySubcategoria['CATEGORIA_FK'] := FDqryCategoria['CATEGORIA_ID'];
      if editValorMaximo.Text = '' then
         FDqrySubcategoria['VALOR_MAXIMO'] := 0;
      FDqrySubcategoria.Post;
      labelCategoriaAtribuida.Visible := False;
   end;
   try
      FDtcCatSub.CommitRetaining;
   except
      FDtcCatSub.RollbackRetaining;
   end;
   FDqrySubcategoria.Close;
   FDqrySubcategoria.Open;

end;

end.
