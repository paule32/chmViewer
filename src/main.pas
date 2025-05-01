unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Buttons, StdCtrls, Grids, Menus, uCEFChromiumWindow;

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
begin
  if Assigned(ChromiumWindow1.ChromiumBrowser) then
  ChromiumWindow1.LoadURL('https://www.google.de');
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

