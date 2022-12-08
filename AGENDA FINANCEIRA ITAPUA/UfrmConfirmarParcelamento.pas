unit UfrmConfirmarParcelamento;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Buttons;

type
  TfrmConfirmarParcelamentos = class(TForm)
    MemoInform: TMemo;
    Panel1: TPanel;
    btnConfirmar: TBitBtn;
    btnCancelar: TBitBtn;
    procedure btnConfirmarClick(Sender: TObject);
    procedure btnCancelarClick(Sender: TObject);
  private
    { Private declarations }


  public
    { Public declarations }

  Var ConfirmarParcelamento : Boolean;

  end;

var
  frmConfirmarParcelamentos: TfrmConfirmarParcelamentos;

implementation

{$R *.dfm}

uses UfrmLancamentos;


procedure TfrmConfirmarParcelamentos.btnCancelarClick(Sender: TObject);
begin
   ConfirmarParcelamento := False;
   Close;
end;

procedure TfrmConfirmarParcelamentos.btnConfirmarClick(Sender: TObject);
begin
   ConfirmarParcelamento := True;
   Close;
end;

end.
