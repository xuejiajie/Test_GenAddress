unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, TB97, TB97Tlbr, EwDbNavigator, EWNavigatorDock, EWNavigator,
  StdCtrls, EwERI, Jsons, IdHTTP, ExtCtrls, EWPanel, EWMsgBox;

type
  TForm1 = class(TForm)
    EwnNavigatorDock1: EwnNavigatorDock;
    EwnNavigator1: EwnNavigator;
    Memo1: TMemo;
    EwnNavigatorDock4: EwnNavigatorDock;
    EwnNavigatorDock3: EwnNavigatorDock;
    EwnNavigatorDock2: EwnNavigatorDock;
    EwnPanel1: EwnPanel;
    EwnPanel2: EwnPanel;
    EwnPanel3: EwnPanel;
    ListBoxCounty: TListBox;
    ListBoxTown: TListBox;
    Splitter1: TSplitter;
    Splitter2: TSplitter;
    Splitter3: TSplitter;
    ListBoxRoad: TListBox;
    procedure EwnNavigator1BtnClick(Sender: TObject; tBtnName: String);
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ListBoxCountyClick(Sender: TObject);
    procedure ListBoxTownClick(Sender: TObject);
  private
    FIsGening: Boolean;
    FCountyERI: TStrings;
    FMemoZipCode: TStrings;
    function vHandlerAshx(tFunctionName: String; tCounty: String=''; tTown: String=''): String;
    function vZipCode(tCounty, tTown: String): String;
    procedure vGenSQL;
    procedure vGenCSV;
    procedure vGetList(List: TStrings; tFunctionName, tNoteName, tItemName: string; tCounty: String=''; tTown: String='');
    procedure vGetCountyList(CountyList: TStrings);
    procedure vGetTownList(TownList: TStrings; tCounty: String);
    procedure vGetRoadList(RoadList: TStrings; tCounty, tTown: String);
    procedure vGetCountyFile(tType: String);
    procedure vGetTownFile(tCountyERI, tCounty, tType: String);
    procedure vGetRoadFile(tTownERI, tCounty, tTown, tType: String);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

//==============================================================================
procedure TForm1.EwnNavigator1BtnClick(Sender: TObject; tBtnName: String);
begin
  if tBtnName='SQL' then // test10
    vGenSQL
  else
  if tBtnName='CSV' then
    vGenCSV;
end;
//==============================================================================
procedure TForm1.vGenSQL;
begin
  Memo1.Lines.Text := ' DELETE FROM ADDRESS ';
  vGetCountyFile('SQL');
end;
//==============================================================================
procedure TForm1.vGenCSV;
begin
  Memo1.Lines.Text := '"ERI","PARENTERI","DATA","LEVL","APCODE","LASTUPD"';
  vGetCountyFile('CSV');
end;
//==============================================================================
procedure TForm1.vGetCountyFile(tType: String);
var
  i         : Integer;
  CountyList: TStrings;
  tCounty   : String;
  tCountyERI: String;
  tString   : String;
begin
  CountyList := TStringList.Create;
  try
    FIsGening := true;
    vGetCountyList(CountyList);
    for i := 0 to CountyList.Count - 1 do begin
      tCounty    := CountyList[i];
      tCountyERI := tGenERI(60);
      if tType='SQL' then
        tString := ' INSERT INTO ADDRESS (ERI,PARENTERI,DATA,LEVL,APCODE,LASTUPD) VALUES (''%s'',''%s'',''%s'',1,'''',''%s'') '
      else
      if tType='CSV' then
        tString := '"%s","%s","%s","1","","%s"';
      Memo1.Lines.Add(Format(tString, [tCountyERI, '', tCounty, FormatDateTime('yymmddHHMMSS',Now)]));
      vGetTownFile(tCountyERI, tCounty, tType);
    end;
    Memo1.Lines.SaveToFile('ADDRESS.' + tType);
    iShowMessage('¶×¥X§¹¦¨!');
    FIsGening := false;
  finally
    FreeAndNil(CountyList);
  end;
end;{vUpdateAddress}
//==============================================================================
procedure TForm1.vGetTownFile(tCountyERI, tCounty, tType: String);
var
  i       : Integer;
  TownList: TStrings;
  tTown   : String;
  tTownERI: String;
  tString : String;
begin
  TownList := TStringList.Create;
  try
    vGetTownList(TownList, tCounty);
    for i := 0 to TownList.Count - 1 do begin
      tTown    := TownList[i];
      tTownERI := tGenERI(60);
      if tType='SQL' then
        tString := ' INSERT INTO ADDRESS (ERI,PARENTERI,DATA,LEVL,APCODE,LASTUPD) VALUES (''%s'',''%s'',''%s'',2,'''',''%s'') '
      else
      if tType='CSV' then
        tString := '"%s","%s","%s","2","","%s"';
      Memo1.Lines.Add(Format(tString, [tTownERI, tCountyERI, tTown + vZipCode(tCounty, tTown), FormatDateTime('yymmddHHMMSS',Now)]));
      vGetRoadFile(tTownERI, tCounty, tTown, tType);
    end;
  finally
    FreeAndNil(TownList);
  end;
end;
//==============================================================================
procedure TForm1.vGetRoadFile(tTownERI, tCounty, tTown, tType: String);
var
  i       : Integer;
  RoadList: TStrings;
  tRoad   : String;
  tRoadERI: String;
  tString : String;
begin
  RoadList := TStringList.Create;
  try
    vGetRoadList(RoadList, tCounty, tTown);
    for i := 0 to RoadList.Count - 1 do begin
      tRoad    := RoadList[i];
      tRoadERI := tGenERI(60);
      if tType='SQL' then
        tString := ' INSERT INTO ADDRESS (ERI,PARENTERI,DATA,LEVL,APCODE,LASTUPD) VALUES (''%s'',''%s'',''%s'',3,'''',''%s'') '
      else
      if tType='CSV' then
        tString := '"%s","%s","%s","3","","%s"';
      Memo1.Lines.Add(Format(tString, [tRoadERI, tTownERI, tRoad, FormatDateTime('yymmddHHMMSS',Now)]));
      Application.ProcessMessages;
    end;
  finally
    FreeAndNil(RoadList);
  end;
end;
//==============================================================================
procedure TForm1.vGetCountyList(CountyList: TStrings);
begin
  vGetList(CountyList, 'getcountylist', 'CountyList', 'COUNTY');
end;
//==============================================================================
procedure TForm1.vGetTownList(TownList: TStrings; tCounty: String);
begin
  vGetList(TownList, 'gettownlist', 'TownList', 'TOWN', tCounty);
end;
//==============================================================================
procedure TForm1.vGetRoadList(RoadList: TStrings; tCounty, tTown: String);
begin
  vGetList(RoadList, 'getroadlist', 'RoadList', 'ROAD', tCounty, tTown);
end;
//==============================================================================
procedure TForm1.vGetList(List: TStrings; tFunctionName, tNoteName, tItemName: string; tCounty: String=''; tTown: String='');
var
  i      : Integer;
  Json   : TJson;
  AsArray: TJsonArray;
begin
  Json := TJson.Create;
  try
    if tFunctionName = 'getroadlist' then
      Json.Parse(vHandlerAshx(tFunctionName, tCounty, tTown))
    else
    if tFunctionName = 'gettownlist' then
      Json.Parse(vHandlerAshx(tFunctionName, tCounty))
    else
      Json.Parse(vHandlerAshx(tFunctionName));

    AsArray := Json[tNoteName].AsArray;
    for i := 0 to AsArray.Count - 1 do
      List.Add(AsArray.Items[i].AsObject.Values[tItemName].AsString);
  finally
    FreeAndNil(Json);
  end;
end;
//==============================================================================
function TForm1.vHandlerAshx(tFunctionName: string; tCounty: string; tTown: string): String;
var
  IdHTTP : TIdHTTP;
  Strings: TStrings;
begin
  Result := '';

  Strings := TStringList.Create;
  IdHTTP  := TIdHTTP.Create(nil);
  try
    Strings.Add(Format('method=%s', [tFunctionName]));
    if (tFunctionName = 'getroadlist') or (tFunctionName = 'gettownlist') then
      Strings.Add(Format('County=%s', [UTF8Encode(tCounty)]));
    if (tFunctionName = 'getroadlist') then
      Strings.Add(Format('Town=%s'  , [UTF8Encode(tTown)]));

    Result := IdHTTP.Post('http://tgos.nat.gov.tw/TGOS_WEB_API/Sample_Codes/TGOSQueryAddr/WebService/Handler.ashx', Strings);
    Result := Utf8Decode(Result);

    if not FIsGening then
      Memo1.Lines.Text := Result;
  finally
    FreeAndNil(IdHTTP);
    FreeAndNil(Strings);
  end;
end;
//==============================================================================
function TForm1.vZipCode(tCounty, tTown: String): String;
var
  i: Integer;
  tAddress: String;
  tLine: String;
begin
  Result := '';

  tAddress := tCounty + ',' + tTown;
  for i := 0 to FMemoZipCode.Count - 1 do begin
    // tLine := UTF8ToAnsi(FMemoZipCode.Strings[i]);
    tLine := FMemoZipCode.Strings[i];
    if Pos(tAddress, tLine) > 0 then begin
      Result := Copy(tLine, 1, 3);
      break;
    end;
  end;

  if Result <> '' then
    Result := '(' + Result + ')';
end;
//==============================================================================
procedure TForm1.FormCreate(Sender: TObject);
var
  tCounty : String;
  tTown   : String;
begin
  FMemoZipCode := TStringList.Create;
  FMemoZipCode.LoadFromFile('ZipCode.csv');

  FCountyERI := TStringList.Create;

  ListBoxCounty.Clear;
  vGetCountyList(ListBoxCounty.Items);
  if ListBoxCounty.Count > 0 then
    ListBoxCounty.Selected[0] := true;

  tCounty := ListBoxCounty.Items[ListBoxCounty.ItemIndex];
  ListBoxTown.Clear;
  vGetTownList(ListBoxTown.Items, tCounty);
  if ListBoxTown.Count > 0 then
    ListBoxTown.Selected[0] := true;

  tTown := ListBoxTown.Items[ListBoxTown.ItemIndex];
  ListBoxRoad.Clear;
  vGetRoadList(ListBoxRoad.Items, tCounty, tTown);
  if ListBoxRoad.Count > 0 then
    ListBoxRoad.Selected[0] := true;
end;
//==============================================================================
procedure TForm1.ListBoxCountyClick(Sender: TObject);
var
  tCounty : String;
  tTown   : String;
begin
  tCounty := ListBoxCounty.Items[ListBoxCounty.ItemIndex];
  ListBoxTown.Clear;
  vGetTownList(ListBoxTown.Items, tCounty);
  if ListBoxTown.Count > 0 then
    ListBoxTown.Selected[0] := true;

  tTown := ListBoxTown.Items[ListBoxTown.ItemIndex];
  ListBoxRoad.Clear;
  vGetRoadList(ListBoxRoad.Items, tCounty, tTown);
  if ListBoxRoad.Count > 0 then
    ListBoxRoad.Selected[0] := true;
end;
//==============================================================================
procedure TForm1.ListBoxTownClick(Sender: TObject);
var
  tCounty : String;
  tTown   : String;
begin
  tCounty := ListBoxCounty.Items[ListBoxCounty.ItemIndex];
  tTown   := ListBoxTown.Items[ListBoxTown.ItemIndex];
  ListBoxRoad.Clear;
  vGetRoadList(ListBoxRoad.Items, tCounty, tTown);
  if ListBoxRoad.Count > 0 then
    ListBoxRoad.Selected[0] := true;
end;
//==============================================================================
procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  FreeAndNil(FMemoZipCode);
  FreeAndNil(FCountyERI);
end;
//==============================================================================
end.
