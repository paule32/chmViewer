unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Buttons, StdCtrls, Grids, Menus, RegExpr, chmreader, chmfiftimain,
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
  htmlText: String;

  DocTitle: String;
  DocURL: String;

  k, currTopic: Integer;
  html: TStringList;

  function RenameImagesInHtml(HtmlText: string; ImageMap: TStrings): string;
  var
    Regex: TRegExpr;
    OldPath, NewPath: string;
    ImgCount: Integer;
  begin
    Regex := TRegExpr.Create;
    try
      Regex.Expression := '<img[^>]*src=["'']([^"''>]+)["'']';
      Regex.ModifierI := True;
      Regex.ModifierG := True;
      ImgCount := ImageMap.Count;

      Result := HtmlText;

      while Regex.Exec(Result) do
      begin
        OldPath := Regex.Match[1];
//        showmessage('old: ' + oldpath);
        if ImageMap.IndexOfName(OldPath) < 0 then
        begin
          Inc(ImgCount);
          NewPath := Format('T:\b\Lazarus\chmViewer\src\packed\lib\img_%4.4d%s', [ImgCount, ExtractFileExt(OldPath)]);
//          showmessage('new: ' + newpath);

          result := StringReplace(htmlText, oldpath, newpath, [rfReplaceAll]);
//          ShowMessage(result);
          exit;
//          ImageMap.Values[OldPath] := NewPath;
//          break;
        end else
        begin
          NewPath := ImageMap.Values[OldPath];
          showmessage('new: ' + oldpath);
        end;

        // Ersetze alle Vorkommen im HTML
        Result := StringReplace(Result, OldPath, NewPath, [rfReplaceAll]);
      end;
    finally
      Regex.Free;
    end;
  end;

  procedure ExtractImagesFromChm(ImageMap: TStrings; const OutputFolder: string);
  var
    i: Integer;
    Stream: TMemoryStream;
    OldPath, NewPath, SavePath: string;
  begin
    ForceDirectories(OutputFolder);

    for i := 0 to ImageMap.Count - 1 do
    begin
      OldPath := ImageMap.Names[i];
      NewPath := ImageMap.ValueFromIndex[i];
      Stream := TMemoryStream.Create;
      try
        Stream := ChmRead.GetObject(OldPath);
        if stream <> nil then
        begin
          SavePath := IncludeTrailingPathDelimiter(OutputFolder) + NewPath;
          Stream.SaveToFile(SavePath);
        end else
        begin
          ShowMessage('stream error');
          exit;
        end;
      finally
        Stream.Free;
      end;
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
        ShowMessage(htmlText);
        htmlText := RenameImagesInHtml(htmlText, html);
        ShowMessage(htmltext);

        ChromiumWindow1.ChromiumBrowser.LoadString(htmlText);
      except
        on E: Exception do
        begin
          ChromiumWindow1.ChromiumBrowser.LoadString(
          '<h2>Page not found.</h2>');
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
  if not ChromiumWindow1.Initialized then
  ChromiumWindow1.CreateBrowser;
  printFlag := false;
end;

procedure TForm1.MenuItem5Click(Sender: TObject);
begin
  Close;
end;

end.

