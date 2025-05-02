unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Buttons, StdCtrls, Grids, Menus, RegExpr, base64, chmreader, chmfiftimain,
  uCEFChromiumWindow;

type

  { TForm1 }

  TForm1 = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    BitBtn5: TBitBtn;
    BitBtn6: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    ChromiumWindow1: TChromiumWindow;
    ComboBox1: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    Separator1: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TreeView1: TTreeView;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure BitBtn5Click(Sender: TObject);
    procedure ChromiumWindow1AfterCreated(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
  private
    printFlag: Boolean;
  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

var
  TEMP_FOLDER: String;

{ TForm1 }

procedure TForm1.BitBtn1Click(Sender: TObject);
begin
  if PageControl1.Visible then
  PageControl1.Visible := false else
  PageControl1.Visible := true;
end;

procedure TForm1.BitBtn2Click(Sender: TObject);
begin
  if printFlag then
  begin
  ChromiumWindow1.LoadURL('https://www.google.de');
  printFlag := false;
  end else
  ChromiumWindow1.ChromiumBrowser.GoBack;
end;

procedure TForm1.BitBtn3Click(Sender: TObject);
begin
  ChromiumWindow1.ChromiumBrowser.GoForward;
end;

procedure TForm1.BitBtn4Click(Sender: TObject);
begin
  ChromiumWindow1.ChromiumBrowser.Print;
  printFlag := true;
end;

procedure TForm1.BitBtn5Click(Sender: TObject);
var
  htmlIndex : String;
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    try
      sl.LoadFromFile('index.html');
      ChromiumWindow1.ChromiumBrowser.LoadString(sl.Text);
    except
      on E: Exception do
      begin
        ShowMessage('Error: ' + E.Message);
        ChromiumWindow1.LoadURL('https://www.google.de');
        exit;
      end;
    end;
  finally
    sl.Free;
    sl := nil;
  end;
end;

procedure TForm1.ChromiumWindow1AfterCreated(Sender: TObject);
type
  TTopicEntry = record
    Topic:Integer;
    Hits: Integer;
    TitleHits: Integer;
    FoundForThisRound: Boolean;
  end;
  TFoundTopics = array of TTopicEntry;
var
  FoundTopics: TFoundTopics;

var
  chmRead: TChmReader;
  chmStream: TFileStream;

  topicResults: chmfiftimain.TChmWLCTopicArray;
  titleResults: chmfiftimain.TChmWLCTopicArray;

  FIftiMainStream: TMemoryStream;
  htmlStream: TMemoryStream;

  searchReader: TChmSearchReader;
  htmlText, newpath: String;

  k, currTopic: Integer;
  html: TStringList;

  function EncodeBase64(const Buffer: Pointer; const Size: Integer): string;
  const
    Base64Code: PAnsiChar = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  var
    I: Integer;
    P: PByte;
    Triplet: Cardinal;
  begin
    Result := '';
    P := Buffer;

    for I := 0 to (Size div 3) - 1 do
    begin
      Triplet := (P[0] shl 16) or (P[1] shl 8) or P[2];
      Result := Result +
                Base64Code[(Triplet shr 18) and $3F] +
                Base64Code[(Triplet shr 12) and $3F] +
                Base64Code[(Triplet shr 6) and $3F] +
                Base64Code[Triplet and $3F];
      Inc(P, 3);
    end;

    case Size mod 3 of
      1:
        begin
          Triplet := P[0] shl 16;
          Result := Result +
                    Base64Code[(Triplet shr 18) and $3F] +
                    Base64Code[(Triplet shr 12) and $3F] +
                    '==';
        end;
      2:
        begin
          Triplet := (P[0] shl 16) or (P[1] shl 8);
          Result := Result +
                    Base64Code[(Triplet shr 18) and $3F] +
                    Base64Code[(Triplet shr 12) and $3F] +
                    Base64Code[(Triplet shr 6) and $3F] +
                    '=';
        end;
    end;
  end;

  function ImageToBase64DataURI(const FilePath: string): string;
  var
    FS: TFileStream;
    Buffer: Pointer;
    Base64Str, MimeType: string;
  begin
    Result := '';
    if not FileExists(FilePath) then Exit;

    FS := TFileStream.Create(FilePath, fmOpenRead or fmShareDenyWrite);
    try
      GetMem(Buffer, FS.Size);
      try
        FS.ReadBuffer(Buffer^, FS.Size);
        Base64Str := EncodeBase64(Buffer, FS.Size);
      finally
        FreeMem(Buffer);
      end;
    finally
      FS.Free;
    end;

    // MIME-Type ermitteln
    case LowerCase(ExtractFileExt(FilePath)) of
      '.png':  MimeType := 'image/png';
      '.jpg', '.jpeg': MimeType := 'image/jpeg';
      '.gif':  MimeType := 'image/gif';
      '.bmp':  MimeType := 'image/bmp';
      '.svg':  MimeType := 'image/svg+xml';
    else
      MimeType := 'application/octet-stream';
    end;

    Result := Format('data:%s;base64,%s', [MimeType, Base64Str]);
  end;

  procedure SaveStreamToFile(Stream: TStream; const FileName: string);
  var
    FS: TFileStream;
  begin
    Stream.Position := 0;
    FS := TFileStream.Create(FileName, fmCreate);
    try
      FS.CopyFrom(Stream, Stream.Size);
    finally
      FS.Free;
    end;
  end;

  procedure SaveStreamToTextFile(Stream: TStream; const FileName: string);
  var
    StringStream: TStringStream;
    List: TStringList;
  begin
    Stream.Position := 0;

    StringStream := TStringStream.Create('');
    List := TStringList.Create;
    try
      StringStream.CopyFrom(Stream, Stream.Size);
      List.Text := StringStream.DataString;
      List.SaveToFile(FileName);
    finally
      StringStream.Free;
      List.Free;
    end;
  end;

  procedure CreateDirectories;
  begin
    //if not DirectoryExists(newpath) then
    begin
      ForceDirectories(TEMP_FOLDER + '\css');
      ForceDirectories(TEMP_FOLDER + '\img');
      ForceDirectories(TEMP_FOLDER + '\js');
      ForceDirectories(TEMP_FOLDER + '\lib');
      ForceDirectories(TEMP_FOLDER + '\lib\js');
    end;
  end;

  function ExtractJavaScriptSources(HTML: string): String;
  var
    RE: TRegExpr;
    SrcValue,s: string;
  begin
    result := html;
    RE := TRegExpr.Create;
    try
      // Suche nach <script src="..."> oder <script src='...'>
      RE.Expression := '<script[^>]*\bsrc\s*=\s*["'']([^"'']+)["'']';
      RE.ModifierI := True;

      if RE.Exec(HTML) then
      repeat
        SrcValue := RE.Match[1];
        newpath  := TEMP_FOLDER;
        s        := '/' + srcvalue;
        CreateDirectories;

        htmlStream.Clear;
        htmlStream.Position := 0;

        htmlStream := chmRead.GetObject(s);
        if htmlStream = nil then
        begin
          ShowMessage('error: can not get:' + #10 + s);
          Halt(3);
        end;

        newpath := Format('%s\%s', [newpath, SrcValue]);
        newpath := StringReplace(NewPath, '/', '\', [rfReplaceAll]);

        SaveStreamToTextFile(htmlStream, newpath);

        s       := ImageToBase64DataURI(NewPath);
        result  := StringReplace(result, srcvalue, s, [rfReplaceAll]);

      until not RE.ExecNext;
    finally
      RE.Free;
    end;
  end;

  function ExtractCSSLinks(HTML: string): string;
  var
    RE: TRegExpr;
    srcValue,s : string;
  begin
    result := html;
    RE := TRegExpr.Create;
    try
      // Suche nach <link ... rel="stylesheet" ... href="...">
      RE.Expression := '<link[^>]*rel\s*=\s*["'']stylesheet["''][^>]*href\s*=\s*["'']([^"'']+)["'']';
      RE.ModifierI := True;

      if RE.Exec(HTML) then
      repeat
        SrcValue := RE.Match[1];
        newpath  := TEMP_FOLDER;
        s        := '/' + srcvalue;
        CreateDirectories;

        htmlStream.Clear;
        htmlStream.Position := 0;

        htmlStream := chmRead.GetObject(s);
        if htmlStream = nil then
        begin
          ShowMessage('error: can not get:' + #10 + s);
          Halt(3);
        end;

        newpath := Format('%s\%s', [newpath, SrcValue]);
        newpath := StringReplace(NewPath, '/', '\', [rfReplaceAll]);

        SaveStreamToTextFile(htmlStream, newpath);

        s       := ImageToBase64DataURI(NewPath);
        result  := StringReplace(result, srcvalue, s, [rfReplaceAll]);

      until not RE.ExecNext;

    finally
      RE.Free;
    end;
  end;

  function ExtractImageSources(HTML: string): String;
  var
    RE: TRegExpr;
    SrcValue, s,newpath, img64: string;
  begin
    result := html;
    RE := TRegExpr.Create;
    try
      // Suche nach <img src="..."> oder <img src='...'>
      RE.Expression := '<img[^>]*\bsrc\s*=\s*["'']([^"'']+)["'']';
      RE.ModifierI := True;

      if RE.Exec(HTML) then
      repeat
        SrcValue := RE.Match[1];
        newpath  := TEMP_FOLDER;
        s        := '/' + srcvalue;
        CreateDirectories;

        htmlStream.Clear;
        htmlStream.Position := 0;

        htmlStream := chmRead.GetObject(s);
        if htmlStream = nil then
        begin
          ShowMessage('error: can not get:' + #10 + s);
          Halt(3);
        end;

        newpath := Format('%s\%s', [newpath, SrcValue]);
        newpath := StringReplace(NewPath, '/', '\', [rfReplaceAll]);

        SaveStreamToFile(htmlStream, newpath);

        img64    := ImageToBase64DataURI(NewPath);
        result   := StringReplace(result, srcvalue, img64, [rfReplaceAll]);

      until not RE.ExecNext;
    finally
      RE.Free;
    end;
  end;

begin
  if Assigned(ChromiumWindow1.ChromiumBrowser) then
  begin
    chmStream := TFileStream.Create(ParamStr(1), fmOpenRead or fmShareDenyWrite);
    chmRead := TChmReader.Create(CHMStream, false);
    html := TStringList.Create;
    try
      try
        FIftiMainStream := chmRead.GetObject('/$FIftiMain');
        if FIftiMainStream = nil then
        begin
          ShowMessage('Could not assign fiftimainstream.' + #10 + 'Aborting.');
          halt(3);
        end;

        htmlStream := chmRead.GetObject('/index.htm');
        if htmlStream = nil then
        begin
          ShowMessage('index not found');
          exit;
        end;
        htmlStream.Position := 0;
        html.LoadFromStream(htmlStream);

        htmlText := html.Text;

        htmlText := ExtractCSSLinks         (htmlText);
        htmlText := ExtractJavaScriptSources(htmlText);
        htmlText := ExtractImageSources     (htmlText);

        ChromiumWindow1.ChromiumBrowser.LoadString(htmlText);
      except
        on E: Exception do
        begin
          ChromiumWindow1.ChromiumBrowser.LoadString(
          '<style>body{background-color:white;}</style><h2>Page not found.</h2><br>' + E.Message);
          exit;
        end;
      end;
    finally
      chmStream.Free;
      chmRead.Free;
      chmStream := nil;
      chmRead := nil;
      html.Clear;
      html.Free;
      html := nil;
    end;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  TEMP_FOLDER := ExtractFilePath(ParamStr(0)) + 'lib';
  if not ChromiumWindow1.Initialized then
  ChromiumWindow1.CreateBrowser;
  printFlag := false;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
  Close;
end;

end.

