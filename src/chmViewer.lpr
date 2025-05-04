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
  Forms, main, misc
  { you can add units after this };

{$R *.res}

var
  dirpath: String;
  hdir: THandle;
// Function to recursively delete a directory and its contents
function DeleteDirectory(const Path: string): Boolean;
var
  SearchRec: TSearchRec;
begin
  Result := False;
  if FindFirst(Path + '\*.*', faAnyFile, SearchRec) = 0 then
  try
    repeat
      if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
      begin
        if (SearchRec.Attr and faDirectory) <> 0 then
          DeleteDirectory(Path + '\' + SearchRec.Name)
        else
          DeleteFile(Path + '\' + SearchRec.Name);
      end;
    until FindNext(SearchRec) <> 0;
  finally
    FindClose(SearchRec);
  end;
  Result := RemoveDir(Path);
end;

var
  LockerThread: TFileLockerThread;

begin
  GlobalCEFApp := TCefApplication.Create;

  if not GlobalCEFApp.StartMainProcess then
  begin
    GlobalCEFApp.Free;
    Halt(0);
  end;

  DirPath := ExtractFilePath(ParamStr(0)) + '\lib';
  ShowMessage(DirPath);

  if DirectoryExists(DirPath) then
  DeleteDirectory(DirPath);
  CreateDir(DirPath);

  try
    try
      LockerThread := TFileLockerThread.Create(DirPath);

      RequireDerivedFormResource := True;
      Application.Scaled:=True;
      Application.Initialize;
      Application.CreateForm(TForm1, Form1);
      Application.Run;

      LockerThread.Terminate;
      LockerThread.WaitFor;
      LockerThread.Free;

    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message + #10 +
        SysErrorMessage(GetLastError));
        Halt(3);
      end;
    end;
  finally
    DeleteDirectory(DirPath);
  end;
end.

