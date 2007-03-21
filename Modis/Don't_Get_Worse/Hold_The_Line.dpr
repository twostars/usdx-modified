library Hold_The_Line;

uses
  ModiSDK in '..\SDK\ModiSDK.pas',
  StrUtils in '..\SDK\StrUtils.pas',
  OpenGL12;

var
  PointerTex: TSmallTexture;
  CountSentences: Cardinal;
  Limit: Byte;
  fPrint: fModi_Print;
  Frame: Integer;
  PlayerTimes: array[0..5] of Integer;

//Gave the Plugins Info
procedure PluginInfo (var Info: TPluginInfo); stdcall;
begin
  Info.Name    := 'PLUGIN_HDL_NAME';
  Info.NumPlayers := 31;

  Info.Creator    := 'Whiteshark';
  Info.PluginDesc := 'PLUGIN_HDL_DESC';


  //Options
  Info.LoadSong := True;  //Whether or not a Song should be Loaded
  //Only When Song is Loaded:
  Info.ShowScore := True; //Whether or not the Score should be shown
  Info.ShowNotes := True; //Whether the Note Lines should be displayed
  Info.LoadVideo := True; //Should the Video be loaded ?
  Info.LoadBack  := True; //Should the Background be loaded ?

  Info.BGShowFull := False;   //Whether the Background or the Video should be shown Fullsize
  Info.BGShowFull_O := True;  //Whether the Background or the Video should be shown Fullsize

  Info.ShowRateBar:= True;   //Whether the Bar that shows how good the player was sould be displayed
  Info.ShowRateBar_O := False; //Load from Ini whether the Bar should be Displayed

  Info.EnLineBonus := False;  //Whether LineBonus Should be enabled
  Info.EnLineBonus_O := True; //Load from Ini whether LineBonus Should be enabled

  //Options even when song is Not loaded
  Info.ShowBars := False; //Whether the White Bars on Top and Bottom should be Drawn
  Info.TeamModeOnly := False;  //If True the Plugin can only be Played in Team Mode
  Info.GetSoundData := False;  //If True the RData Procedure is called when new SoundData is available
  Info.Dummy := False;         //Should be Set to False... for Updateing Plugin Interface
end;

//Executed on Game Start //If True Game begins, else Failure
function Init (const TeamInfo: TTeamInfo; var Playerinfo: TPlayerinfo; const Sentences: TSentences; const LoadTex: fModi_LoadTex; const Print: fModi_Print; LoadSound: fModi_LoadSound; PlaySound: fModi_PlaySound): boolean; stdcall;
var
  I: Integer;
  Texname, TexType: PChar;
begin {
  TexName := CreateStr(PChar('HDL_Pointer'));
  TexType := CreateStr(PChar('Plain'));
  //PointerTex := LoadTex(TexName, TexType);

  FreeStr(TexName);
  FreeStr(TexType);

  //CountSentences := Sentences.High;
  Limit := 0;
  Frame := 0;

  fPrint := Print;

  {for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    PlayerInfo.Playerinfo[I].Enabled := True;
    PlayerInfo.Playerinfo[I].Percentage := 100;
    PlayerTimes[I] := 0;
  end; }         

  Result := True;
end;

//Executed everytime the Screen is Drawed //If False The Game finishes
function Draw (var Playerinfo: TPlayerinfo; const CurSentence: Cardinal): boolean; stdcall;
var
  I: Integer;
  L: Byte;
  C: Byte;
  Text: PChar;
begin
  case Limit of
    0: L := 20;
    1: L := 50;
    2: L := 75;
  end;

  C:= 0;

  Inc(Frame);

  Result := True;

  //Inc Limit
  if (Limit = 0) And  (CurSentence >= CountSentences div 5 * 2) then
    Inc(Limit)
  else if (Limit = 1) And  (CurSentence >= CountSentences div 3 * 2) then
    Inc(Limit);

  for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
    if PlayerInfo.Playerinfo[I].Enabled then
    begin
      if PlayerInfo.Playerinfo[I].Bar < L then
      begin
        PlayerInfo.Playerinfo[I].Enabled := False;
        Inc(C);
        PlayerTimes[I] := Frame; //Save Tiem of Dismission
        //ToDo: PlaySound
      end;
      
      //Draw Pointer;
      //glBindTexture(GL_TEXTURE_2D, PointerTex.TexNum);

      glBegin(GL_QUADS);
        glTexCoord2f(1/32, 0); glVertex2f(PlayerInfo.Playerinfo[I].PosX + L - 3, PlayerInfo.Playerinfo[I].PosY - 4);
        glTexCoord2f(1/32, 1); glVertex2f(PlayerInfo.Playerinfo[I].PosX + L - 3, PlayerInfo.Playerinfo[I].PosY + 12);
        glTexCoord2f(31/32, 1); glVertex2f(PlayerInfo.Playerinfo[I].PosX+ L + 3, PlayerInfo.Playerinfo[I].PosY + 12);
        glTexCoord2f(31/32, 0); glVertex2f(PlayerInfo.Playerinfo[I].PosX+ L + 3, PlayerInfo.Playerinfo[I].PosY - 4);
      glEnd;

    end
    else
    begin
      Inc(C);
      //Draw Dismissed
      Text := CreateStr(PChar('PARTY_DISMISSED'));
      //Str := 'Test123';
      //fPrint (1, 6, PlayerInfo.Playerinfo[I].PosX, PlayerInfo.Playerinfo[I].PosY-8, Text);
      FreeStr(Text);
    end;
  end;
  {if (C >= PlayerInfo.NumPlayers-1) then
    Result := False; }
end;

//Is Executed on Finish, Returns the Playernum of the Winner
function Finish (var Playerinfo: TPlayerinfo): byte; stdcall;
var
  I:Integer;
begin
Result := 0;
for I := 0 to PlayerInfo.NumPlayers-1 do
  begin
  PlayerInfo.Playerinfo[I].Percentage := (PlayerTimes[I] * 100) div Frame;
    if (PlayerInfo.Playerinfo[I].Enabled) then
    begin
      Case I of
        0: Result := Result OR 1;
        1: Result := Result OR 2;
        2: Result := Result OR 4;
        3: Result := Result OR 8;
        4: Result := Result OR 16;
        5: Result := Result OR 32;
      end;
    end;
  end;
end;

exports
PluginInfo, Init, Draw, Finish;

begin

end.