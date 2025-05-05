program chmViewer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Windows, Dialogs, SysUtils, StrUtils,
  uCEFApplication,  // WICHTIG: Initialisiert CEF
  Forms, main
  { you can add units after this };

{$R *.res}

begin
  GlobalCEFApp := TCefApplication.Create;

  if not GlobalCEFApp.StartMainProcess then
  begin
    GlobalCEFApp.Free;
    Halt(0);
  end;

  try
    try
      RequireDerivedFormResource := True;
      Application.Scaled:=True;
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message + #10 +
        SysErrorMessage(GetLastError));
        Halt(3);
      end;
    end;
  finally
  end;
end.

