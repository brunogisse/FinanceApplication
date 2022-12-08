unit Upropriedade;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, Vcl.DBCtrls,
  Vcl.Imaging.pngimage, Vcl.ExtCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids,
  FireDAC.Stan.Intf, FireDAC.Stan.Option, FireDAC.Stan.Param,
  FireDAC.Stan.Error, FireDAC.DatS, FireDAC.Phys.Intf, FireDAC.DApt.Intf,
  FireDAC.Stan.Async, FireDAC.DApt, FireDAC.Comp.DataSet, FireDAC.Comp.Client;

type
  TfrmPropriedade = class(TForm)
    PainelTopo: TPanel;
    btnNovo: TImage;
    labelPropriedade: TLabel;
    btnCancelar: TImage;
    btnSalvar: TImage;
    btnAlterar: TImage;
    btnExcluir: TImage;
    Image1: TImage;
    editPropriedade: TDBEdit;
    gridContas: TDBGrid;
    FDtcPropriedade: TFDTransaction;
    FDqryPropriedade: TFDQuery;
    dsPropriedade: TDataSource;
    FDqryPropriedadeDESCRICAO: TStringField;
    FDqryPropriedadePROPRIEDADE_ID: TIntegerField;
    Image2: TImage;
    procedure btnNovoClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnSalvarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
    procedure btnAlterarClick(Sender: TObject);
    procedure btnExcluirClick(Sender: TObject);
    procedure Image2Click(Sender: TObject);
  private
    { Private declarations }

    procedure ConfigurarEnables(status : integer);

  public
    { Public declarations }
  end;

var
  frmPropriedade: TfrmPropriedade;

implementation

{$R *.dfm}

uses UfrmPrincipal;


procedure TfrmPropriedade.btnAlterarClick(Sender: TObject);
begin
  FDqryPropriedade.Edit;
  ConfigurarEnables(1);
end;

procedure TfrmPropriedade.btnCancelarClick(Sender: TObject);
begin
  ConfigurarEnables(0);
  FDqryPropriedade.Cancel;
end;

procedure TfrmPropriedade.btnExcluirClick(Sender: TObject);
 var
 AuxErro : string;
begin
  configurarEnables(0);
 if MessageBox(Application.Handle,'Deseja excluir essa Propriedade?','Confirmação', MB_YESNO + MB_ICONQUESTION) = mrYes then
    begin
     try
      FDqryPropriedade.Delete;
     except
      on E : exception do
       begin
        AuxErro := copy (E.Message,20,25);
        ShowMessage(AuxErro);
       end;
     end;
    end;
end;


procedure TfrmPropriedade.btnNovoClick(Sender: TObject);
begin
  ConfigurarEnables(1);
  editPropriedade.SetFocus;
  FDqryPropriedade.Insert;
end;

procedure TfrmPropriedade.btnSalvarClick(Sender: TObject);
begin
  FDqryPropriedade.Post;
  try
    FDtcPropriedade.CommitRetaining;
  except
    FDtcPropriedade.RollbackRetaining;
  end;
  ConfigurarEnables(0);
end;

procedure TfrmPropriedade.configurarEnables(status : integer);
begin
    if status = 0 then
    begin
      btnNovo.Enabled := True;
      btnAlterar.Enabled := True;
      btnExcluir.Enabled := True;
      btnCancelar.Enabled := False;
      btnSalvar.Enabled := False;
      editPropriedade.Enabled := False;
    end
   else
    begin
      btnNovo.Enabled := False;
      btnAlterar.Enabled := False;
      btnExcluir.Enabled := False;
      btnCancelar.Enabled := True;
      btnSalvar.Enabled := True;
      editPropriedade.Enabled := True;
    end;
end;



procedure TfrmPropriedade.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 FDqryPropriedade.Close;
end;

procedure TfrmPropriedade.FormShow(Sender: TObject);
begin
  ConfigurarEnables(0);
  FDqryPropriedade.Open;
end;

procedure TfrmPropriedade.Image2Click(Sender: TObject);
begin
 frmPropriedade.Close;
end;

end.
