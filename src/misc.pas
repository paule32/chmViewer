unit misc;

{$mode Delphi}

interface

uses
  Windows, Classes, SysUtils, Dialogs;

type
  TLockedFile = record
    Handle: THandle;
    FilePath: String;
  end;

type
  PFILE_NOTIFY_INFORMATION = ^FILE_NOTIFY_INFORMATION;
  FILE_NOTIFY_INFORMATION = record
    NextEntryOffset: DWORD;
    Action: DWORD;
    FileNameLength: DWORD;
    FileName: array[0..0] of PChar;
  end;

  TFileLockerThread = class(TThread)
  private
    FDirPath: string;
    FDirHandle: THandle;
    FFiles: array of TLockedFile;
    FLock: TRTLCriticalSection;
  protected
    procedure Execute; override;
    procedure LockFile(const FileName: string);
  public
    constructor Create(const DirPath: string);
    destructor Destroy; override;
  end;
implementation

procedure TFileLockerThread.LockFile(const FileName: string);
var
  FullPath: String;
  hFile: THandle;
  Entry: TLockedFile;
  Count: Integer;
begin
  FullPath := FDirPath + FileName;

  hFile := CreateFileW(
    PWideChar(FullPath),
    GENERIC_READ,
    0,
    nil,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
  );

  if hFile <> INVALID_HANDLE_VALUE then
  begin
    //Writeln('Neue Datei gesperrt: ', FullPath);
    ShowMessage('lock new file: ' + FullPath);
    Entry.Handle := hFile;
    Entry.FilePath := FullPath;

    EnterCriticalSection(FLock);
    Count := Length(FFiles);
    SetLength(FFiles, Count + 1);
    FFiles[Count] := Entry;
    LeaveCriticalSection(FLock);
  end;
end;

destructor TFileLockerThread.Destroy;
var
  i: Integer;
begin
  if FDirHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FDirHandle);

  EnterCriticalSection(FLock);
  try
    for i := 0 to High(FFiles) do
    begin
      CloseHandle(FFiles[i].Handle);
      if not DeleteFileW(PWideChar(FFiles[i].FilePath)) then
      ShowMessage('Error: could not delete: ' + FFiles[i].FilePath);
    end;
  finally
    LeaveCriticalSection(FLock);
    DoneCriticalSection(FLock);
  end;

  inherited Destroy;
end;

constructor TFileLockerThread.Create(const DirPath: string);
begin
  inherited Create(False);
  FreeOnTerminate := False;

  FDirPath := IncludeTrailingPathDelimiter(DirPath);
  InitializeCriticalSection(FLock);

  FDirHandle := CreateFileW(
    PWideChar(FDirPath),
    FILE_LIST_DIRECTORY,
    FILE_SHARE_READ or FILE_SHARE_WRITE or FILE_SHARE_DELETE,
    nil,
    OPEN_EXISTING,
    FILE_FLAG_BACKUP_SEMANTICS or FILE_FLAG_OVERLAPPED,
    0
  );

  if FDirHandle = INVALID_HANDLE_VALUE then
  raise Exception.CreateFmt('Error: could not open directory.' + #10 +
  'Error Code: ' + '%d', [GetLastError]);
end;

procedure TFileLockerThread.Execute;
const
  BUF_SIZE = 2048;
var
  Buffer: array[0..BUF_SIZE - 1] of Byte;
  BytesReturned: DWORD;
  NotifyInfo: PFILE_NOTIFY_INFORMATION;
  FileName: WideString;
begin
  while not Terminated do
  begin
    if ReadDirectoryChangesW(
      FDirHandle,
      @Buffer,
      SizeOf(Buffer),
      False,
      FILE_NOTIFY_CHANGE_FILE_NAME,
      @BytesReturned,
      nil,
      nil
    ) then
    begin
      NotifyInfo := @Buffer;
      repeat
        SetString(FileName, PChar(NotifyInfo^.FileName), NotifyInfo^.FileNameLength div SizeOf(WideChar));

        if NotifyInfo^.Action = FILE_ACTION_ADDED then
          LockFile(PChar(FileName));

        if NotifyInfo^.NextEntryOffset = 0 then
          Break;

        NotifyInfo := PFILE_NOTIFY_INFORMATION(PByte(NotifyInfo) + NotifyInfo^.NextEntryOffset);
      until False;
    end
    else
    begin
      ShowMessage('Error: ReadDirectoryChangesW: ' + IntToStr(GetLastError));
    end;
  end;
end;

procedure StartLock;
var
  LockerThread: TFileLockerThread;
begin
  try
    LockerThread := TFileLockerThread.Create('C:\Test');
    //Writeln('Überwachung läuft. ENTER zum Beenden...');
    //Readln;
    LockerThread.Terminate;
    LockerThread.WaitFor;
    LockerThread.Free;
  except
    on E: Exception do
    ShowMessage('Error: ' + E.Message);
  end;
end;

end.

