unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.Imaging.pngimage;

type result = Record
  vards : string[255];
  rezult: integer;
  laiks : TDateTime;
End;


type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Label1: TLabel;
    Image1: TImage;
    Label2: TLabel;
    SaveDialog1: TSaveDialog;
    Button4: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);

    // Custom procedures
    procedure recalculateField();
    procedure CreateLabel(x : Integer; y : Integer; number : Integer);
    procedure KillLabel(x,y : integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure doCalculations(i : integer; j : integer; dir : integer);
    procedure randomSpawn();
    procedure ResetGame();

  private
  public
  end;

{Global vars}
var
  Form1: TForm1;
  isOn, moved, simulate : Boolean;
  field: Array[1..4, 1..4] of TLabel; // Spēles laukums
  diehardfix:array[1..16] of boolean; // Aizsargātie lauciņi
  Score, failureCases : Integer;
implementation

{$R *.dfm}

{Spawnojam random skaitlļus}
procedure TForm1.randomSpawn();
var I,J,vrand: Integer;
begin
repeat
  for I := 1 to 4 do
  begin
    for J := 1 to 4 do
    begin
      if moved = true then
      begin
        if field[I,J] = nil then
        begin
            vrand := Random(5);
            if vrand = 1 then
            begin
              vrand := Random(10);
              if vrand = 1 then CreateLabel(I,J,4) //10% spawn chance
            else CreateLabel(I,J,2);
             moved := false;
            end;
        end;
      end;
    end;
  end;
until  moved = false;
recalculateField;
end;

{"Sākt Spēli"}
procedure TForm1.Button1Click(Sender: TObject);
begin
Label1.Visible := false;
Button1.Visible := false;
Button2.Visible := false;
Button3.Visible := false;
Button4.Visible := false;

isOn := true;
simulate := false;
failurecases := 0;
Image1.Visible := true;
Score := 0;
Label2.Caption := 'Rezultāts: 0';

moved := true;
randomSpawn;
moved := true;
randomSpawn;

recalculateField;
end;

{Atbrīvojam lauciņu}
procedure TForm1.KillLabel(x : Integer; y : Integer);
begin
field[x,y].Free;
field[x,y] := nil;
end;

{Izveidojam jaunu skaitli}
procedure TForm1.CreateLabel(x : Integer; y : Integer; number : Integer);
begin
field[x,y] := TLabel.Create(self);
field[x,y].Parent := Form1;
field[x,y].Caption := IntToStr(number);

// Atkarībā no skaitļa izmēra pielāgojam to lauciņam. Nav tas labākais variants, bet nu...
if number < 10 then begin
  field[x,y].Font.Size := 80;
  field[x,y].Font.Color :=  clWebMaroon;
end
else if number < 100 then begin
  field[x,y].Font.Size := 60;
  field[x,y].Font.Color :=  clWebIndianRed;
end
else if number < 1000 then begin
  field[x,y].Font.Size := 47;
  field[x,y].Font.Color :=  clWebOrange;
end
else begin
  field[x,y].Font.Size := 36;
  field[x,y].Font.Color := clYellow;
end;
end;

{"Rekordi"}
procedure TForm1.Button2Click(Sender: TObject);
var saveRez : file of result;
    temp    : Array[1..5] of result;
    temp2   : result;
    output  : string;
    I       : Integer;
begin
if FileExists('2048.bin') then
begin

try
AssignFile(saveRez, '2048.bin');
FileMode := fmOpenRead;
Reset(SaveRez);
i := 1;
while not EOF(saverez) do
begin
  Read(saverez,temp2);
  temp[i] := temp2;
  Inc(i);
end;
finally Closefile(saverez);
end;


output := '';
for i := 1 to 5 do {WARN: hardcoded max scores}
begin
output := output + temp[i].vards + ' ieguva ' + inttostr(temp[i].rezult) + ' ' + FormatDateTime('c', temp[i].laiks)  +#13#10;
end;

showMessage(output);
end
else
  showMessage('Rezultātu fails neeksistē.');
end;
{"Iziet"}
procedure TForm1.Button3Click(Sender: TObject);
begin
Form1.Close;
end;
{"Instrukcijas"}
procedure TForm1.Button4Click(Sender: TObject);
begin
showmessage('2048 ir slīdošu lauciņu puzzles spēle. Spēles mērķis ir sasniegt 2048  (2^11) skaitli.' + #13#10 +
            'Spēles sākumā ir doti divi lauciņi/skaitļi, kuru vērtības var būt 2 vai 4 ' +
            'un katru gājienu jebkurā laiciņā var uzrasties jauns skaitlis (2, vai 4).' + #13#10 +
            'Izmantojot ←↑→↓ (virzientaustiņus) tu pabīdi visus skaitļus uz laikuma uz noteikto virzienu' +
            ' (ja iespējams), un ja skaitļi ir vienādi, tad tie saskaitās. Spēle turpinās līdz jūs sasniedzat' +
            '2048 lauciņu vai jūs zaudējat (gājieni vairs nav iespējami).');
end;

{Formas sākuma vērt.}
procedure TForm1.FormCreate(Sender: TObject);
begin
Randomize;
Form1.KeyPreview := true;
Form1.DoubleBuffered := true;
end;

{Katru gājienu atzīmējam visus lauciņus kā neaizsargātus}
procedure resetFix();
var I : Integer;
begin
  for I := 1 to Length(diehardfix) do
    diehardfix[i] := false;
end;

{Faila (rezultātu) saglabāšana}
procedure saveresult();
var buttonSelected,I,J,loc     : integer;
    saveRez                    : file of result;
    temp                       : Array[1..5] of result;
    temp2                      : result;
    dowrite                    : Boolean;
begin
buttonSelected := MessageDlg('Vai saglabāt rezultātu failā?',mtCustom,
                              [mbYes,mbNo], 0);
if buttonSelected = mrYes    then
begin
  if FileExists('2048.bin') then
  begin
  // Ielādējam rezultātus atmiņā lai tos varētu sakārtot
  AssignFile(saveRez, '2048.bin');
  FileMode := fmOpenRead;
  Reset(SaveRez);
  i := 1;
  try
  while not EOF(saverez) do
  begin
    Read(saverez,temp2);
    temp[i] := temp2;
    Inc(i);
  end;
  finally Closefile(saverez);
  end;

  loc := 0;
  for I := 1 to 5 do
  begin
    if Score >= temp[i].rezult then
    begin
      loc := i;
      for J := 5 downto loc+1 do
        temp[j] := temp[j-1];
      dowrite := true;
      break;
    end;
  end;
  if loc = 0 then
  begin
    dowrite := false;
    showmessage('Rezultāts ir pārāk mazs lai to iekļautu top 5.');
  end;
  end
  else
  begin
  // Ja fails neeksistē, izveidojam jaunu, rezultātu ierakstīs pirmajā vietā.
  dowrite := true;
  AssignFile(saveRez, '2048.bin');
  Rewrite(saveRez);
  for I := 1 to 5 do
  begin
    temp[i].vards := 'none';
    temp[i].rezult := 0;
    temp[i].laiks := Now();
  end;
  try
    for i := 1 to 5 do
      Write(saveRez, temp[i]);
  finally CloseFile(saveRez);

  loc := 1;
  end;
  end;

  if dowrite then
  begin
  AssignFile(saveRez, '2048.bin');
  ReWrite(saverez);

  repeat
  temp[loc].vards := InputBox('Vards', 'Ludzu ievadat savu vardu', 'Vards');
  until temp[loc].vards <> '';
  temp[loc].rezult := score;
  temp[loc].laiks := Now();

  try
    for i := 1 to 5 do
      Write(saveRez, temp[i]);
  finally CloseFile(saveRez);
  Form1.Button2Click(form1);
  end;
  end;

end;
Form1.ResetGame;
end;

{Pārbaudam vai esam uzvarējuši}
procedure checkForWin(number : Integer);
var buttonSelected : Integer;
begin
  if number = 2048 then {WARN: hardcoded win}
  begin
    ShowMessage('Uzvara! Rezultāts: ' + inttostr(score));
    buttonSelected := MessageDlg('Vai vēlaties turpināt?',mtCustom,
                              [mbYes,mbNo], 0);
    if buttonSelected = mrNo    then
    begin
      saveresult;
      isOn := False;
    end;
  end;
end;

{Simulējam visus iespējamos gājienus lai pārbaudītu vai esam zaudējuši}
procedure checkForDefeat();
var I,J, count: integer;
begin
count := 0; //dcc32 warning
// Pirmā pārbaude - vai visi lauciņi ir aizpildīti?
for I := 1 to 4 do
  for J := 1 to 4 do
    if field[i,j] <> nil then
      count := count + 1;

// Otrā pārbaude - simulējam visus gājienus
if count = 16 then
begin
simulate := true;
for I := 1 to 4 do
  for J := 1 to 4 do
  begin
  if simulate = false then break;
    Form1.doCalculations(I,J,1);
    Form1.doCalculations(I,J,2);
    Form1.doCalculations(I,J,3);
    Form1.doCalculations(I,J,4);
  end;
  if failurecases = 64 then // 4x4 laukums, lauciņiem ir 4 kustības virzieni.
  begin
    isOn := false;
    showmessage('Spēle beigusies ar rezultātu: ' + inttostr(score));
    saveresult;
  end;
end;
end;

{Pārzīmējam laukumu}
procedure TForm1.recalculateField();
var I,J, offset : integer;
begin
for I := 1 to 4 do  {WARN: hardcoded fieldsize}
  for J := 1 to 4 do
  begin
  if field[I,J] <> nil then
  begin
    offset := Round((80 - Field[i,j].Font.Size)/2);

    field[i,j].Top :=  10+((I-1)*120)+offset;
    field[i,j].Left := 40+((J-1)*120)-offset;
  end;
  end;
end;

{Galvenie aprēķini}
procedure TForm1.doCalculations(i : integer; j : integer; dir : integer);
var x,y,num,col : integer;
begin
{
  Ok, un šeit parādās tas, ka es neesmu gulējis ļoti, ļoti ilgu laiku.
  Tā vietā lai visu glabātu struct (record) un zīmētu labelus skatoties
  uz koordinātām, es izmantoju Array[1..4, 1..4] of TLabel, un izmantoju
  to vērtības lai veiktu visus aprēķinus. Ļoti tizls veids kā darīt, bet
  laiks pārrakstīt arī nebija. Oh well, strādā. Oh, un jāpiezīmē, ka x un y
  koordinātas šajā procedūrā ir sajauktas vietām. heh.

  Algoritms šajā procedūrā:
  1) Iegūsti virzienu
  2) Atzīmē gala punktu kā mērķi (piem pa labi - x: 4)
  3) Iziet cauri visiem lauciņiem līdz galapunktam, pārbaudīt vai kaut kas ir priekšā
  4.1) Ja ir, paŗbaudi vai šis lauciņš ir vienāds ar pašreizēju lauciņu, un ja ir - vai tas ir aizsargāts
  ( šis aptur vairākas apvienošanas vienā gājienā ).
  4.2) Ja nav, tad pārvietosim skaitli blakus.
  5) Pārbaudam vai šī ir simulācija vai nav (lai zinātu vai esam zaudējuši)
  6.1) Ja ir, tad mēs atzīmējam to, vai šis gājiens bija iespējams vai ne, un ko vēlāk apkopos checkfordefeat
  6.2) Ja nav, tad mēs veicam (vai neveicam, atkarībā no tā vai gājiens ir iespējams) gājienu
}
if field[i,j] <> nil then
begin
  num := strtoint(Field[i,j].Caption);
  x := i;
  y := j;

  if dir = 1 then // Pa labi
  begin
  y := 4;
 for col := j+1 to y do
  begin
    if field[i,col] <> nil then
    begin
      if strtoint(field[i,j].Caption) = strtoint(field[i,col].Caption) then
      begin
        y := col;
        if diehardfix[x*(x-1)+y] <> true then
        begin
          num := strtoint(field[i,j].Caption)*2;
          if simulate = false then Score := Score + num;
          checkforWin(num);
          diehardfix[x*(x-1)+y] := true;
        end
        else
        begin
          y := col-1;
          break;
        end;
        end
      else
      begin
        y := col-1;
        break;
      end;
      end;
    end;
  end
  else if dir = 2 then // Pa kreisi
    begin
  y := 1;
 for col := j-1 downto y do
  begin
    if field[i,col] <> nil then
    begin
      if strtoint(field[i,j].Caption) = strtoint(field[i,col].Caption) then
      begin
        y := col;
        if diehardfix[x*(x-1)+y] <> true then
        begin
          num := strtoint(field[i,j].Caption)*2;
          if simulate = false then Score := Score + num;
          checkforWin(num);
          diehardfix[x*(x-1)+y] := true;
        end
        else
        begin
          y := col+1;
          break;
        end;
        end
      else
      begin
        y := col+1;
        break;
      end;
      end;
    end;
  end
  else if dir = 3 then // Uz augšu
  begin
    x := 1;
    for col := i-1 downto x do
    begin
    if field[col,j] <> nil then
      if strtoint(field[i,j].Caption) = strtoint(field[col,j].Caption) then
      begin
        x := col;
        if diehardfix[x*(x-1)+y] <> true then
        begin
        num := strtoint(field[i,j].Caption)*2;
        if simulate = false then Score := Score + num;
        checkforWin(num);
        diehardfix[x*(x-1)+y] := true;
        end
        else
        begin
          x := col+1;
          break;
        end;
      end
      else
      begin
      x := col+1;
      break;
      end;
    end;
  end
  else if dir = 4 then // Uz leju
  begin
    x := 4;
    for col := i+1 to x do
    if field[col,j] <> nil then
    begin
      if strtoint(field[i,j].Caption) = strtoint(field[col,j].Caption) then
      begin
        x := col;
        if diehardfix[x*(x-1)+y] <> true then
        begin
        num := strtoint(field[i,j].Caption)*2;
        if simulate = false then Score := Score + num;
        checkforWin(num);
        diehardfix[x*(x-1)+y] := true;
        end
        else
        begin
          x:=col-1;
          break;
        end;
        end
      else
        x := col-1;
        break;
      end;
    end;

  if (i <> x) or (j <> y) then moved := true;
  // BUG: Dažreiz lauciņi nemergosies.
  if (moved) and (simulate = false) then
  begin

  if field[x,y] <> nil then killlabel(x,y);
  KillLabel(i,j);
  CreateLabel(x,y,num);
  end;
  if (moved = true) and (simulate = true) then
  begin
  simulate := false;
  moved := false;
  end;
  if (moved = false) and (simulate = true) then failurecases := failurecases+1;

end;
end;

{Ievades apstrādāšana}
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
var I,J : integer;
begin
//Katram virzienam ir sava secība kādā rēķinam lauciņu kustību
if isOn then // Neveicam liekus aprēķinus tad kad nevajag.
begin
if Key in [vk_right] then
for I := 1 to 4 do {WARN: hardcoded fieldsize}
  for J := 4 downto 1 do doCalculations(I,J,1)
else if Key in [vk_left] then
for I := 1 to 4 do
  for J := 1 to 4 do doCalculations(I,J,2)
else if Key in [vk_up] then
for J := 1 to 4 do
  for I := 1 to 4 do doCalculations(I,J,3)
else if Key in [vk_down] then
for J := 1 to 4 do
  for I := 4 downto 1 do doCalculations(I,J,4);


Label2.Caption := 'Rezultāts: '+IntToStr(Score);
resetFix;

if (moved = true) and (simulate = false) then
begin
randomspawn;
recalculateField;
end
else if (moved = false) and (simulate = false) then
begin
checkfordefeat;
failurecases := 0;
end;
end;
end;

{Spēle ir beigusies, atpakaļ uz izvēlni}
procedure TForm1.ResetGame();
var I,J:integer;
begin
Label1.Visible := true;
Label2.Caption := 'Pēdējās spēles rezultāts: ' + inttostr(score);
Button1.Visible := true;
Button2.Visible := true;
Button3.Visible := true;
Button4.Visible := true;

isOn := false;
Image1.Visible := false;

resetFix;
for I := 1 to 4 do
  for J := 1 to 4 do
    KillLabel(i,j);
end;

end.
