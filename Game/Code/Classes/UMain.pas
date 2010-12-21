unit UMain;

interface
uses SDL, UGraphic, UMusic, URecord, UTime, SysUtils, UDisplay, UIni, ULog, ULyrics, UScreenSing,
  gl, zlportio {you can disable it and all PortWriteB calls}, UThemes{, UScreenPopup};

type
  TPlayer = record
    Name:         string;
    VoiceFile:    string; //Recorded Voice

    Score:        real;
    ScoreLine:    real;
    ScoreGolden:  real;

    ScoreI:       integer;
    ScoreLineI:   integer;
    ScoreGoldenI: integer;
    ScoreTotalI:  integer;



    //SingBar Mod
    ScoreLast:    Real;//Last Line Score
    ScorePercent:    integer;//Aktual Fillstate of the SingBar
    ScorePercentTarget:  integer;//Target Fillstate of the SingBar
    //end Singbar Mod

    ScoreMax:     integer; //max possible score (actual)

    //PhrasenBonus - Line Bonus Mod
    LineBonus_PosX:     Single;
    LineBonus_PosY:     Single;
    LineBonus_Alpha:    Single;
    LineBonus_Visible:  boolean;
    LineBonus_Text:     string;
    LineBonus_Color:    TRGB;
    LineBonus_Age:      Integer;

    //Variable vor Positioning -> Set on ScreenShow, different when Playercount Changes
    LineBonus_TargetX:  integer;
    LineBonus_TargetY:  integer;
    LineBonus_StartX:  integer;
    LineBonus_StartY:  integer;
    //PhrasenBonus - Line Bonus Mod End

    //PerfectLineTwinkle Mod (effect)
    LastSentencePerfect: Boolean;
    //PerfectLineTwinkle Mod end


//    Meter:        real;

    HighNut:  integer;
    IlNut:    integer;
    Nuta:     array of record
      Start:      integer;
      Dlugosc:    integer;
      //Detekt:     real;     // dokladne miejsce, w ktorym wykryto ta nute
      Ton:        real;
      Perfect:    boolean; // true if the note matches the original one, lit the star



      // Half size Notes Patch
      Hit:        boolean; // true if the note Hits the Line
      //end Half size Notes Patch



    end;
  end;

  TStats = record
    Player: array of TPlayer;
    SongArtist:   String;
    SongTitle:    String;
  end;

  TMedleyPlaylist = record
    Song:               array of integer;
    NumMedleySongs:     integer;
    CurrentMedleySong:  integer;
    ApplausePlayed:     boolean;
    Stats:              array of TStats;
    NumPlayer:          integer;
  end;


var
  OGL:      Boolean;
  Done:     Boolean;
  Event:    TSDL_event;
  FileName: string;
  Restart:  boolean;

  // gracz i jego nuty
  Player:         array of TPlayer;
  PlayersPlay:    integer;
  PlaylistMedley: TMedleyPlaylist;


procedure MainLoop;
procedure CheckEvents;
procedure Sing(Sender: TScreenSing);
procedure NewSentence(CP: integer; Sender: TScreenSing);
procedure NewBeat(CP: integer; Sender: TScreenSing); // executed when on then new beat
procedure NewBeatC(CP: integer; Sender: TScreenSing); // executed when on then new beat for click
procedure NewBeatD(CP: integer; Sender: TScreenSing); // executed when on then new beat for detection
//procedure NewHalf; // executed when in the half between beats
procedure NewNote(P: integer; Sender: TScreenSing); // detect note
function GetMidBeat(Time: real): real;
function GetTimeFromBeat(Beat: integer): real;
procedure ClearScores(PlayerNum: integer);

implementation
uses USongs, Math, UCommandLine, UVideo, UWebCam;

procedure MainLoop;
var
  Delay:    integer;
begin
  SDL_EnableKeyRepeat(125, 125);
  While not Done do
  Begin
    PerfLog.CycleStart;
    // keyboard events
    CheckEvents;

    // display
    done := not Display.Draw;
    SwapBuffers;

    // delay
    CountMidTime;

    Delay := Floor(1000 / 100 - 1000 * TimeMid);
    if Delay >= 1 then
      SDL_Delay(Delay);
    CountSkipTime;

    // reinitialization of graphics
    if Restart then begin
      Reinitialize3D;
      Restart := false;
    end;
    PerfLog.CycleEnd;
  End;
  wClose;
  acClose;
  FreeOpenGL;
End;

Procedure CheckEvents;
Begin
  if not Assigned(Display.NextScreen) then
  While SDL_PollEvent( @event ) = 1 Do
  Begin
    Case Event.type_ Of
      SDL_ACTIVEEVENT: //workaround for alt-tab bug
        begin
          if (Event.active.gain=1) then
          begin
            SDL_SetModState(KMOD_NONE);
            if (Ini.FullScreen = 1) or (Params.FullScreen) then
              SDL_ShowCursor(0);
            //EnableVideoDraw := true;
          end;

          if (Event.active.gain=0) then
          begin
            if (Ini.FullScreen = 1) or (Params.FullScreen) then
              SDL_ShowCursor(1);
            //EnableVideoDraw := false;
          end;
        end;

      SDL_QUITEV:
        begin
        Display.Fade := 0;
        Display.NextScreenWithCheck := nil;
        Display.CheckOK := True;
        end;
{      SDL_MOUSEBUTTONDOWN:
        With Event.button Do
        Begin
          If State = SDL_BUTTON_LEFT Then
          Begin
            //
          End;
        End; // With}
      SDL_KEYDOWN:
        begin
          //ScreenShot hack. If Print is pressed-> Make screenshot and Save to Screenshots Path
          if (Event.key.keysym.sym = SDLK_SYSREQ) or (Event.key.keysym.sym = SDLK_PRINT) then
          begin
//            ScreenPopupError.ShowPopup('How dare you press the <Print> key'); //show error message
            if (SDL_GetModState and KMOD_LCTRL = KMOD_LCTRL) then
              Display.PrintScreen //jpeg
            else
              Display.ScreenShot; //bmp
          end
          // popup hack... if there is a visible popup then let it handle input instead of underlying screen
          // shoud be done in a way to be sure the topmost popup has preference (maybe error, then check)
          else if (ScreenPopupError <> NIL) and (ScreenPopupError.Visible) then
            done := not ScreenPopupError.ParseInput(Event.key.keysym.sym, Event.key.keysym.unicode, True)
          else if (ScreenPopupCheck <> NIL) AND (ScreenPopupCheck.Visible) then
            done := not ScreenPopupCheck.ParseInput(Event.key.keysym.sym, Event.key.keysym.unicode, True)
          else if (ScreenPopupHelp <> NIL) AND (ScreenPopupHelp.Visible) then
            done := not ScreenPopupHelp.ParseInput(Event.key.keysym.sym, Event.key.keysym.unicode, True)
          // end of popup hack

          else
          begin
            // check for Screen want to Exit
            done := Not Display.ActualScreen^.ParseInput(Event.key.keysym.sym, Event.key.keysym.unicode, True);

            //If Screen wants to Exit
            if done then
            begin
              //If Question Option is enabled then Show Exit Popup
              if (Ini.AskbeforeDel = 1) then
              begin
                Display.ActualScreen^.CheckFadeTo(NIL,'MSG_QUIT_USDX');
              end
              else //When asking for exit is disabled then simply exit
              begin
                Display.Fade := 0;
                Display.NextScreenWithCheck := nil;
                Display.CheckOK := True;
              end;
            end;

          end;            //        if (Not Display.ActualScreen^.ParseInput(Event.key.keysym.scancode, True)) then
        end;
//      SDL_JOYAXISMOTION:
//        begin
//          beep
//        end;
      SDL_JOYBUTTONDOWN:
        begin
          beep
        end;
    End; // Case Event.type_
  End; // While
End; // CheckEvents

function GetTimeForBeats(BPM, Beats: real): real;
begin
  Result := 60 / BPM * Beats;
end;

function GetBeats(BPM, msTime: real): real;
begin
  Result := BPM * msTime / 60;
end;

procedure GetMidBeatSub(BPMNum: integer; var Time: real; var CurBeat: real);
var
  NewTime:  real;
begin
  if High(AktSong.BPM) = BPMNum then
  begin
    // last BPM
    CurBeat := AktSong.BPM[BPMNum].StartBeat + GetBeats(AktSong.BPM[BPMNum].BPM, Time);
    Time := 0;
  end else
  begin
    // not last BPM
    // count how much time is it for start of the new BPM and store it in NewTime
    NewTime := GetTimeForBeats(AktSong.BPM[BPMNum].BPM, AktSong.BPM[BPMNum+1].StartBeat - AktSong.BPM[BPMNum].StartBeat);

    // compare it to remaining time
    if (Time - NewTime) > 0 then
    begin
      // there is still remaining time
      CurBeat := AktSong.BPM[BPMNum].StartBeat;
      Time := Time - NewTime;
    end else
    begin
      // there is no remaining time
      CurBeat := AktSong.BPM[BPMNum].StartBeat + GetBeats(AktSong.BPM[BPMNum].BPM, Time);
      Time := 0;
    end; // if
  end; // if
end;

function GetMidBeat(Time: real): real;
var
  CurBeat:  real;
  CurBPM:   integer;

begin
  Result := 0;
  if Length(AktSong.BPM) = 1 then Result := Time * AktSong.BPM[0].BPM / 60;

  (* more BPMs *)
  if Length(AktSong.BPM) > 1 then
  begin

    CurBeat := 0;
    CurBPM := 0;
    while (Time > 0) do
    begin
      GetMidBeatSub(CurBPM, Time, CurBeat);
      Inc(CurBPM);
    end;

    Result := CurBeat;
  end; // if
end;

function GetTimeFromBeat(Beat: integer): real;
var
  CurBPM:   integer;
begin
  Result := 0;
  if Length(AktSong.BPM) = 1 then Result := AktSong.GAP / 1000 + Beat * 60 / AktSong.BPM[0].BPM;

  (* more BPMs *)
  if Length(AktSong.BPM) > 1 then
  begin
    Result := AktSong.GAP / 1000;
    CurBPM := 0;
    while (CurBPM <= High(AktSong.BPM)) and (Beat > AktSong.BPM[CurBPM].StartBeat) do
    begin
      if (CurBPM < High(AktSong.BPM)) and (Beat >= AktSong.BPM[CurBPM+1].StartBeat) then
      begin
        // full range
        Result := Result + (60 / AktSong.BPM[CurBPM].BPM) * (AktSong.BPM[CurBPM+1].StartBeat - AktSong.BPM[CurBPM].StartBeat);
      end;

      if (CurBPM = High(AktSong.BPM)) or (Beat < AktSong.BPM[CurBPM+1].StartBeat) then
      begin
        // in the middle
        Result := Result + (60 / AktSong.BPM[CurBPM].BPM) * (Beat - AktSong.BPM[CurBPM].StartBeat);
      end;
      Inc(CurBPM);
    end;
  end; // if}
end;

procedure Sing(Sender: TScreenSing);
var
  Pet:    integer;
  PetGr:  integer;
  CP:     integer;
  Done:   real;
  N:      integer;
begin
  //Czas.Teraz := Czas.Teraz + TimeSkip;
  Czas.Teraz := Music.Position+Ini.LipSync*0.01;

  Czas.OldBeat := Czas.AktBeat;
  Czas.MidBeat := GetMidBeat(Czas.Teraz - (AktSong.Gap{ + 90 I've forgotten for what it is}) / 1000); // new system with variable BPM in function
  Czas.AktBeat := Floor(Czas.MidBeat);

  Czas.OldBeatC := Czas.AktBeatC;
  Czas.MidBeatC := GetMidBeat(Czas.Teraz - (AktSong.Gap) / 1000);
  Czas.AktBeatC := Floor(Czas.MidBeatC);

  Czas.OldBeatD := Czas.AktBeatD;
  Czas.MidBeatD := -0.5+GetMidBeat(Czas.Teraz - Ini.LipSync*0.01 - (AktSong.Gap + 120 + Ini.Delay*10) / 1000); // MidBeat with addition GAP
  Czas.AktBeatD := Floor(Czas.MidBeatD);
  Czas.FracBeatD := Frac(Czas.MidBeatD);

  // sentences routines
  PetGr := 0;
  if AktSong.isDuet then
    PetGr := 1;
    
  for CP := 0 to PetGr do
  begin
    // ustawianie starej czesci
    Czas.OldCzesc[CP] := Czesci[CP].Akt;

    // wybieranie aktualnej czesci
    for Pet := 0 to Czesci[CP].High do
    begin
      if Czas.AktBeat >= Czesci[CP].Czesc[Pet].Start then
      begin
        if (GetTimeFromBeat(Czesci[CP].Czesc[Pet].StartNote) <= Czas.Teraz+10) then
          Czesci[CP].Akt := Pet;
      end;
    end;

    // czysczenie nut gracza, gdy to jest nowa plansza
    // (optymizacja raz na halfbeat jest zla)
    if Czesci[CP].Akt <> Czas.OldCzesc[CP] then
      NewSentence(CP, Sender);

    // wykonuje operacje raz na beat
    if (Czas.AktBeat >= 0) and (Czas.OldBeat <> Czas.AktBeat) then
      NewBeat(CP, Sender);

    // make some operations on clicks
    if {(Czas.AktBeatC >= 0) and }(Czas.OldBeatC <> Czas.AktBeatC) then
      NewBeatC(CP, Sender);

    // make some operations when detecting new voice pitch
    if (Czas.AktBeatD >= 0) and (Czas.OldBeatD <> Czas.AktBeatD) then
      NewBeatD(CP, Sender);

    // plynnie przesuwa text
    Done := 1;
    if (Length(Czesci[CP].Czesc[Czesci[CP].Akt].Nuta)>0) then
    begin
      for N := 0 to Czesci[CP].Czesc[Czesci[CP].Akt].HighNut do
        if (Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Start <= Czas.MidBeat)
        and (Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Start + Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Dlugosc >= Czas.MidBeat) then
          Done := (Czas.MidBeat - Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Start) / (Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Dlugosc);

      N := Czesci[CP].Czesc[Czesci[CP].Akt].HighNut;

      // wylacza ostatnia nute po przejsciu
      if (Ini.LyricsEffect = 1) and (Done = 1) and
        (Czas.MidBeat > Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Start + Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[N].Dlugosc)
        then
      begin
        Sender.LyricMain[CP].Selected := -1
      end;

      if Done > 1 then
        Done := 1;

      Sender.LyricMain[CP].Done := Done;
    end;
  end;
end;

procedure NewSentence(CP: integer; Sender: TScreenSing);
var
G: Integer;
begin
  // czyszczenie nut graczy
  if AktSong.isDuet then
  begin
    for G := 0 to High(Player) do
    begin
      if (G mod 2 = CP) then
      begin
        Player[G].IlNut := 0;
        Player[G].HighNut := -1;
        SetLength(Player[G].Nuta, 0);
      end;
    end;
  end else
  begin
    for G := 0 to High(Player) do
    begin
      Player[G].IlNut := 0;
      Player[G].HighNut := -1;
      SetLength(Player[G].Nuta, 0);
    end;
  end;

  // wstawianie tekstow
  with Sender do
  begin
    LyricMain[CP].AddCzesc(CP, Czesci[CP].Akt);
    if Czesci[CP].Akt < Czesci[CP].High then
      LyricSub[CP].AddCzesc(CP, Czesci[CP].Akt+1)
    else
      LyricSub[CP].Clear;
  end;
  
  //On Sentence Change...
  Sender.onSentenceChange(CP, Czesci[CP].Akt);
end;

procedure NewBeat(CP: integer; Sender: TScreenSing);
var
  Pet:      integer;
//  TempBeat: integer;
begin
  if (Length(Czesci[CP].Czesc[Czesci[CP].Akt].Nuta)=0) then
    Exit;

  for Pet := 0 to Czesci[CP].Czesc[Czesci[CP].Akt].HighNut do
  begin
    if (Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[Pet].Start <= Czas.AktBeat) and
      (Sender.LyricMain[CP].Selected <> Pet) then
    begin
      // operates on currently beated note
      Sender.LyricMain[CP].Selected := Pet;
    end;
  end;
end;

procedure NewBeatC(CP: integer; Sender: TScreenSing);
var
  Pet:    integer;
//  LPT_1:  integer;
//  LPT_2:  integer;
begin
//  LPT_1 := 1;
//  LPT_2 := 1;

  // beat click
  if (Ini.BeatClick = 1) and ((Czas.AktBeatC + Czesci[CP].Resolution + Czesci[CP].NotesGAP) mod Czesci[CP].Resolution = 0) then
    Music.PlayClick;

  if (Length(Czesci[CP].Czesc[Czesci[CP].Akt].Nuta)=0) then
    Exit;
    
  for Pet := 0 to Czesci[CP].Czesc[Czesci[CP].Akt].HighNut do
    if (Czesci[CP].Czesc[Czesci[CP].Akt].Nuta[Pet].Start = Czas.AktBeatC) then
    begin
      // click assist
      if Ini.ClickAssist = 1 then
        Music.PlayClick;


      // drum machine
(*      TempBeat := Czas.AktBeat;// + 2;
      if (TempBeat mod 8 = 0) then Music.PlayDrum;
      if (TempBeat mod 8 = 4) then Music.PlayClap;
//      if (TempBeat mod 4 = 2) then Music.PlayHihat;
      if (TempBeat mod 4 <> 0) then Music.PlayHihat;*)
    end;

  //PortWriteB($378, LPT_1 + LPT_2 * 2); // 0 zapala
end;

procedure NewBeatD(CP: integer; Sender: TScreenSing);
begin
  NewNote(CP, Sender);
end;

//procedure NewHalf;
//begin
//  NewNote;
//end;

procedure NewNote(P: integer; Sender: TScreenSing);
const
  DEBUG_NOTE_HIT = false;

var
  CP:     integer; // current player
  S:      integer; // sentence
  N:      integer;
  SumN:   real;
  NumS:   integer;
  tap:    integer;
  SMin:   integer;
  SMax:   integer;
  SDet:   integer; // temporary: sentence of detected note
  BRange: integer; // beat range

  AktTon: integer;

  Pet:    integer;
  Mozna:  boolean;
  Nowa:   boolean;
  Range:  integer;
  NoteHit:boolean;
begin
  SDet := 0;

  for CP := 0 to PlayersPlay-1 do
  begin
    if (not AktSong.isDuet) then
    begin
      // analyze buffer
      Sound[CP].AnalizujBufor;

      // 0.5.0: count min and max sentence range for checking (detection is delayed to the notes we see on the screen)
      SMin := Czesci[P].Akt-1;
      if SMin < 0 then
        SMin := 0;
      SMax := Czesci[P].Akt;

      for BRange := Czas.OldBeatD+1 to Czas.AktBeatD do
      begin
        SDet := SMin;
        // check if we can add new note
        Mozna := false;
        for S := SMin to SMax do
        begin
          for Pet := 0 to Czesci[P].Czesc[S].HighNut do
          begin
            if ((Czesci[P].Czesc[S].Nuta[Pet].Start <= BRange)
              and (Czesci[P].Czesc[S].Nuta[Pet].Start + Czesci[P].Czesc[S].Nuta[Pet].Dlugosc - 1 >= BRange))
              and (not Czesci[P].Czesc[S].Nuta[Pet].FreeStyle) // but don't allow when it's FreeStyle note
              and (Czesci[P].Czesc[S].Nuta[Pet].Dlugosc > 0) // and make sure the note lenghts is at least 1
              then
            begin
              SDet := S;
              Mozna := true;
              Break;
            end;
          end;
        end;

        S := SDet;

        if (Sound[CP].SzczytJest or DEBUG_NOTE_HIT) and Mozna then
        begin
          // operate on the actual note
          for Pet := 0 to Czesci[P].Czesc[S].HighNut do
          begin
            if (Czesci[P].Czesc[S].Nuta[Pet].Start <= BRange)
              and (Czesci[P].Czesc[S].Nuta[Pet].Start +
              Czesci[P].Czesc[S].Nuta[Pet].Dlugosc > BRange) then
            begin
              // przesuwanie tonu w odpowiednia game => shifting tone in the corresponding game?
              while (Sound[CP].TonGamy - Czesci[P].Czesc[S].Nuta[Pet].Ton > 6) do
                Sound[CP].TonGamy := Sound[CP].TonGamy - 12;
              while (Sound[CP].TonGamy - Czesci[P].Czesc[S].Nuta[Pet].Ton < -6) do
                Sound[CP].TonGamy := Sound[CP].TonGamy + 12;

              // Half size Notes Patch
              NoteHit := false;
              AktTon := Sound[CP].TonGamy;

              Range := 2 - Ini.Difficulty;
              if (abs(Czesci[P].Czesc[S].Nuta[Pet].Ton - Sound[CP].TonGamy) <= Range) or
                DEBUG_NOTE_HIT then
              begin
                AktTon := Czesci[P].Czesc[S].Nuta[Pet].Ton;

                // Half size Notes Patch
                NoteHit := true;

                if (Ini.LineBonus = 0) then
                begin
                  // add points without LineBonus
                  case Czesci[P].Czesc[S].Nuta[Pet].Wartosc of
                    1:  Player[CP].Score := Player[CP].Score + 10000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                    2:  Player[CP].ScoreGolden := Player[CP].ScoreGolden + 10000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                  end;
                end else
                begin
                  // add points with Line Bonus
                  case Czesci[P].Czesc[S].Nuta[Pet].Wartosc of
                    1:  Player[CP].Score := Player[CP].Score + 9000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                    2:  Player[CP].ScoreGolden := Player[CP].ScoreGolden + 9000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                  end;
                end;

                Player[CP].ScoreI := Floor(Player[CP].Score / 10) * 10;
                Player[CP].ScoreGoldenI := Floor(Player[CP].ScoreGolden / 10) * 10;

                Player[CP].ScoreTotalI := Player[CP].ScoreI + Player[CP].ScoreGoldenI + Player[CP].ScoreLineI;
              end;
            end; // operowanie
          end;

          // checking whether a new note, or extend
          if S = SMax then
          begin
            Nowa := true;
            // if the latter has the same tone
            if (Player[CP].IlNut > 0 ) and (Player[CP].Nuta[Player[CP].HighNut].Ton = AktTon)
              and (Player[CP].Nuta[Player[CP].HighNut].Start + Player[CP].Nuta[Player[CP].HighNut].Dlugosc = BRange)
              then
              Nowa := false;

            // If there is a new note on the checked Beat
            for Pet := 0 to Czesci[P].Czesc[S].HighNut do
              if (Czesci[P].Czesc[S].Nuta[Pet].Start = BRange) then
                Nowa := true;

            // add a new note
            if Nowa then
            begin
              // nowa nuta
              Player[CP].IlNut := Player[CP].IlNut + 1;
              Player[CP].HighNut := Player[CP].HighNut + 1;
              SetLength(Player[CP].Nuta, Player[CP].IlNut);
              Player[CP].Nuta[Player[CP].HighNut].Start := BRange;
              Player[CP].Nuta[Player[CP].HighNut].Dlugosc := 1;
              Player[CP].Nuta[Player[CP].HighNut].Ton := AktTon; // Ton || TonDokl
              //Player[CP].Nuta[Player[CP].HighNut].Detekt := Czas.MidBeat;

              // Half Note Patch
              Player[CP].Nuta[Player[CP].HighNut].Hit := NoteHit;
            end else
            begin
              // extend notes
              Player[CP].Nuta[Player[CP].HighNut].Dlugosc := Player[CP].Nuta[Player[CP].HighNut].Dlugosc + 1;
            end;


            // check for perfect note and then lit the star (on Draw)
            for Pet := 0 to Czesci[P].Czesc[S].HighNut do
            begin
              if (Czesci[P].Czesc[S].Nuta[Pet].Start = Player[CP].Nuta[Player[CP].HighNut].Start)
                and (Czesci[P].Czesc[S].Nuta[Pet].Dlugosc = Player[CP].Nuta[Player[CP].HighNut].Dlugosc)
                and (Czesci[P].Czesc[S].Nuta[Pet].Ton = Player[CP].Nuta[Player[CP].HighNut].Ton) then
              begin
                Player[CP].Nuta[Player[CP].HighNut].Perfect := true;
              end;

            end;// else beep; // if S = SMax
          end; //for
        end; // if moze
      end; // for BRange
      //calc score last
      SumN := 0;
      NumS := 0;
      for S := Czesci[P].Akt to Czesci[P].High do
      begin
        for N := 0 to Czesci[P].Czesc[S].HighNut do
        begin
          if (Czesci[P].Czesc[S].Nuta[N].Start > Czas.AktBeatD) then
          begin
            tap := Czesci[P].Czesc[S].Nuta[N].Dlugosc;
            if (Czesci[P].Czesc[S].Nuta[N].Start + tap < Czas.AktBeatD) then
              tap := Czas.AktBeatD - Czesci[P].Czesc[S].Nuta[N].Start - tap;

            if (tap<>0) then
            begin
              if (Ini.LineBonus = 0) then
                // add points without LineBonus
                SumN := SumN + 10000 / Czesci[P].Wartosc * Czesci[P].Czesc[S].Nuta[N].Wartosc * tap
              else
                // add points with Line Bonus
                SumN := SumN + 9000 / Czesci[P].Wartosc * Czesci[P].Czesc[S].Nuta[N].Wartosc * tap;
            end;
          end;
        end;

        if (Czesci[P].Czesc[S].TotalNotes>0) and
          (Czesci[P].Czesc[S].Koniec > Czas.AktBeatD) then
          Inc(NumS);
      end;

      N := (Czesci[P].Ilosc - ScreenSing.NumEmptySentences[P]);
      if (N>0) and (Ini.LineBonus > 0) then
        Player[CP].ScoreMax := Floor((SumN + NumS*1000 / N)/10)*10;

      Player[CP].ScoreMax := Player[CP].ScoreTotalI + Player[CP].ScoreMax;

    end else
    begin     //############################ DUET #####################
      if (CP mod 2 = P) then
      begin
      // analyze buffer
      Sound[CP].AnalizujBufor;

      // 0.5.0: count min and max sentence range for checking (detection is delayed to the notes we see on the screen)
      SMin := Czesci[P].Akt-1;
      if SMin < 0 then
        SMin := 0;
      SMax := Czesci[P].Akt;

      for BRange := Czas.OldBeatD+1 to Czas.AktBeatD do
      begin
        SDet := SMin;
        // check if we can add new note
        Mozna := false;
        for S := SMin to SMax do
        begin
          for Pet := 0 to Czesci[P].Czesc[S].HighNut do
          begin
            if ((Czesci[P].Czesc[S].Nuta[Pet].Start <= BRange)
              and (Czesci[P].Czesc[S].Nuta[Pet].Start + Czesci[P].Czesc[S].Nuta[Pet].Dlugosc - 1 >= BRange))
              and (not Czesci[P].Czesc[S].Nuta[Pet].FreeStyle) // but don't allow when it's FreeStyle note
              and (Czesci[P].Czesc[S].Nuta[Pet].Dlugosc > 0) // and make sure the note lenghts is at least 1
              then
            begin
              SDet := S;
              Mozna := true;
              Break;
            end;
          end;
        end;

        S := SDet;

        if (Sound[CP].SzczytJest or DEBUG_NOTE_HIT) and (Mozna) then
        begin
          // operowanie na ostatniej nucie
          for Pet := 0 to Czesci[P].Czesc[S].HighNut do
          begin
            if (Czesci[P].Czesc[S].Nuta[Pet].Start <= BRange)
              and (Czesci[P].Czesc[S].Nuta[Pet].Start +
              Czesci[P].Czesc[S].Nuta[Pet].Dlugosc > BRange) then
            begin
              // przesuwanie tonu w odpowiednia game
              while (Sound[CP].TonGamy - Czesci[P].Czesc[S].Nuta[Pet].Ton > 6) do
                Sound[CP].TonGamy := Sound[CP].TonGamy - 12;
              while (Sound[CP].TonGamy - Czesci[P].Czesc[S].Nuta[Pet].Ton < -6) do
                Sound[CP].TonGamy := Sound[CP].TonGamy + 12;

              // Half size Notes Patch
              NoteHit := false;
              AktTon := Sound[CP].TonGamy;
              
              Range := 2 - Ini.Difficulty;
              if (abs(Czesci[P].Czesc[S].Nuta[Pet].Ton - Sound[CP].TonGamy) <= Range) or
                DEBUG_NOTE_HIT then
              begin
                AktTon := Czesci[P].Czesc[S].Nuta[Pet].Ton;

                // Half size Notes Patch
                NoteHit := true;

                if (Ini.LineBonus = 0) then
                begin
                  // add points without LineBonus
                  case Czesci[P].Czesc[S].Nuta[Pet].Wartosc of
                    1:  Player[CP].Score := Player[CP].Score + 10000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                    2:  Player[CP].ScoreGolden := Player[CP].ScoreGolden + 10000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                  end;
                end else
                begin
                  // add points with Line Bonus
                  case Czesci[P].Czesc[S].Nuta[Pet].Wartosc of
                    1:  Player[CP].Score := Player[CP].Score + 9000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                    2:  Player[CP].ScoreGolden := Player[CP].ScoreGolden + 9000 / Czesci[P].Wartosc *
                          Czesci[P].Czesc[S].Nuta[Pet].Wartosc;
                  end;
                end;

                Player[CP].ScoreI := Floor(Player[CP].Score / 10) * 10;
                Player[CP].ScoreGoldenI := Floor(Player[CP].ScoreGolden / 10) * 10;

                Player[CP].ScoreTotalI := Player[CP].ScoreI + Player[CP].ScoreGoldenI + Player[CP].ScoreLineI;
              end;
            end; // operowanie
          end;

          // sprawdzanie czy to nowa nuta, czy przedluzenie
          if S = SMax then
          begin
            Nowa := true;
            // jezeli ostatnia ma ten sam ton
            if (Player[CP].IlNut > 0 ) and (Player[CP].Nuta[Player[CP].HighNut].Ton = AktTon)
              and (Player[CP].Nuta[Player[CP].HighNut].Start + Player[CP].Nuta[Player[CP].HighNut].Dlugosc = BRange)
              then
              Nowa := false;

            // jezeli jest jakas nowa nuta na sprawdzanym beacie
            for Pet := 0 to Czesci[P].Czesc[S].HighNut do
              if (Czesci[P].Czesc[S].Nuta[Pet].Start = BRange) then
                Nowa := true;

            // dodawanie nowej nuty
            if Nowa then
            begin
              // nowa nuta
              Player[CP].IlNut := Player[CP].IlNut + 1;
              Player[CP].HighNut := Player[CP].HighNut + 1;
              SetLength(Player[CP].Nuta, Player[CP].IlNut);
              Player[CP].Nuta[Player[CP].HighNut].Start := BRange;
              Player[CP].Nuta[Player[CP].HighNut].Dlugosc := 1;
              Player[CP].Nuta[Player[CP].HighNut].Ton := AktTon; // Ton || TonDokl
              //Player[CP].Nuta[Player[CP].HighNut].Detekt := Czas.MidBeat;

              // Half Note Patch
              Player[CP].Nuta[Player[CP].HighNut].Hit := NoteHit;
            end else
            begin
              // przedluzenie nuty
              Player[CP].Nuta[Player[CP].HighNut].Dlugosc := Player[CP].Nuta[Player[CP].HighNut].Dlugosc + 1;
            end;


            // check for perfect note and then lit the star (on Draw)
            for Pet := 0 to Czesci[P].Czesc[S].HighNut do
            begin
              if (Czesci[P].Czesc[S].Nuta[Pet].Start = Player[CP].Nuta[Player[CP].HighNut].Start)
                and (Czesci[P].Czesc[S].Nuta[Pet].Dlugosc = Player[CP].Nuta[Player[CP].HighNut].Dlugosc)
                and (Czesci[P].Czesc[S].Nuta[Pet].Ton = Player[CP].Nuta[Player[CP].HighNut].Ton) then
              begin
                Player[CP].Nuta[Player[CP].HighNut].Perfect := true;
              end;

            end;// else beep; // if S = SMax
          end; //for
        end; // if moze
      end; // for BRange

      //calc score last
      SumN := 0;
      NumS := 0;
      for S := Czesci[P].Akt to Czesci[P].High do
      begin
        for N := 0 to Czesci[P].Czesc[S].HighNut do
        begin
          if (Czesci[P].Czesc[S].Nuta[N].Start > Czas.AktBeatD) then
          begin
            tap := Czesci[P].Czesc[S].Nuta[N].Dlugosc;
            if (Czesci[P].Czesc[S].Nuta[N].Start + tap < Czas.AktBeatD) then
              tap := Czas.AktBeatD - Czesci[P].Czesc[S].Nuta[N].Start - tap;

            if (tap<>0) then
            begin
              if (Ini.LineBonus = 0) then
                // add points without LineBonus
                SumN := SumN + 10000 / Czesci[P].Wartosc * Czesci[P].Czesc[S].Nuta[N].Wartosc * tap
              else
                // add points with Line Bonus
                SumN := SumN + 9000 / Czesci[P].Wartosc * Czesci[P].Czesc[S].Nuta[N].Wartosc * tap;
            end;
          end;
        end;

        if (Czesci[P].Czesc[S].TotalNotes>0) and
          (Czesci[P].Czesc[S].Koniec > Czas.AktBeatD) then
          Inc(NumS);
      end;

      N := (Czesci[P].Ilosc - ScreenSing.NumEmptySentences[P]);
      if (N>0) and (Ini.LineBonus > 0) then
        Player[CP].ScoreMax := Floor((SumN + NumS*1000 / N)/10)*10;

      Player[CP].ScoreMax := Player[CP].ScoreTotalI + Player[CP].ScoreMax;
      end; //if mod 2
    end;

  end; // for CP

  //On Sentence End -> For LineBonus + SingBar
  if (sDet >= low(Czesci[P].Czesc)) AND (sDet <= high(Czesci[P].Czesc)) then
  begin
    if (Length(Czesci[P].Czesc[SDet].Nuta)>0) then
    begin
      if ((Czesci[P].Czesc[SDet].Nuta[Czesci[P].Czesc[SDet].HighNut].Start +
        Czesci[P].Czesc[SDet].Nuta[Czesci[P].Czesc[SDet].HighNut].Dlugosc - 1) = Czas.AktBeatD) then
        Sender.onSentenceEnd(P, sDet);
    end;
  end;
end;

procedure ClearScores(PlayerNum: integer);
begin
  Player[PlayerNum].Score := 0;
  Player[PlayerNum].ScoreI := 0;
  Player[PlayerNum].ScoreLine := 0;
  Player[PlayerNum].ScoreLineI := 0;
  Player[PlayerNum].ScoreGolden := 0;
  Player[PlayerNum].ScoreGoldenI := 0;
  Player[PlayerNum].ScoreTotalI := 0;


  //SingBar Mod
  Player[PlayerNum].ScoreLast := 0;
  Player[PlayerNum].ScorePercent := 50;// Sets to 50% when song starts
  Player[PlayerNum].ScorePercentTarget := 50;// Sets to 50% when song starts
  //end SingBar Mod

  Player[PlayerNum].ScoreMax := 9990;

  //PhrasenBonus - Line Bonus Mod
  Player[PlayerNum].LineBonus_Visible := False; //Hide Line Bonus
  Player[PlayerNum].LineBonus_Alpha   := 0;
  //Player[PlayerNum].LineBonus_TargetX := 70 + PlayerNum*500;  //will be done by onShow
  //Player[PlayerNum].LineBonus_TargetY := 30;                  //will be done by onShow
  //PhrasenBonus - Line Bonus Mod End

end;

end.
