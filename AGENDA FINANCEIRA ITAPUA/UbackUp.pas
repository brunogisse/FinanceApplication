unit UbackUp;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  FireDAC.Phys.FBDef, FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.IBBase,
  FireDAC.Phys.FB, FireDAC.Stan.Def, FireDAC.VCLUI.Wait, FireDAC.Phys.IBWrapper,
  FireDAC.UI.Intf, FireDAC.Comp.UI;

type
  TfrmBackUp = class(TForm)
    btnBackUp: TSpeedButton;
    FDPhysFBDriverLink1: TFDPhysFBDriverLink;
    FDIBBackup1: TFDIBBackup;
    OpenDialog1: TOpenDialog;
    btnBanco: TSpeedButton;
    editBanco: TEdit;
    editBackup: TEdit;
    SpeedButton1: TSpeedButton;
    labelBanco: TLabel;
    labelBackupRestore: TLabel;
    FDGUIxWaitCursor1: TFDGUIxWaitCursor;
    procedure btnBackUpClick(Sender: TObject);
    procedure btnBancoClick(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmBackUp: TfrmBackUp;

implementation

{$R *.dfm}

uses UfrmPrincipal;

procedure TfrmBackUp.btnBackUpClick(Sender: TObject);
var
  Origem, Destino: string;
begin
  Origem  := editBanco.Text;
  Destino := editBackup.Text;

  if not CopyFile(PChar(Origem), PChar(Destino), true) then
    ShowMessage('Erro ao copiar ' + Origem + ' para ' + Destino)
    else
    ShowMessage('Arquivo copiado com sucesso!');
end;

procedure TfrmBackUp.SpeedButton1Click(Sender: TObject);
begin
    OpenDialog1.Execute();
    editBackup.Text := OpenDialog1.FileName;
end;

procedure TfrmBackUp.btnBancoClick(Sender: TObject);
begin
   if OpenDialog1.Execute() then;
    editBanco.Text :=  OpenDialog1.FileName;

end;



end.
