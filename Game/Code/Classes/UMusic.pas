unit UMusic;

interface

uses Classes, MPlayer, Windows, Messages, SysUtils, Forms, ULog, USongs, Bass;//, DXSounds;

procedure InitializeSound;

type
  TPos = record
    CP:   integer;
    line: integer;
    note: integer;
  end;

  TSongMode = (smNormal, smParty, smChallenge, smMedley);

  TSoundCard = record
    Name:     string;
    Source:   array of string;
  end;

  TFFTData  = array [0..256] of Single;
  
  TCustomSoundEntry = record
    Filename: String;
    Handle: hStream;
  end;

  TMusic = class
    private
//      MediaPlayer:        TMediaPlayer;       // It will be replaced by another component;
{      MediaPlayerStart:   TMediaPlayer;       // or maybe not if done this way ;)
      MediaPlayerBack:    TMediaPlayer;
      MediaPlayerSwoosh:  TMediaPlayer;
      MediaPlayerChange:  TMediaPlayer;
      MediaPlayerOption:  TMediaPlayer;
      MediaPlayerClick:   TMediaPlayer;
      MediaPlayerDrum:    TMediaPlayer;
      MediaPlayerHihat:   TMediaPlayer;
      MediaPlayerClap:    TMediaPlayer;
      MediaPlayerShuffle: TMediaPlayer;}
      BassStart:          hStream;            // Wait, I've replaced this with BASS
      BassBack:           hStream;            // It has almost all features we need
      BassSwoosh:         hStream;
      BassChange:         hStream;            // Almost? It aleady has them all :)
      BassOption:         hStream;
      BassClick:          hStream;
      BassDrum:           hStream;
      BassHihat:          hStream;
      BassClap:           hStream;
      BassShuffle:        hStream;
      BassApplause:       hStream;

      BassVoices:         array of hStream;

      //Custom Sounds
      CustomSounds: array of TCustomSoundEntry;


      Loaded:             boolean;
      Loop:               boolean;
      CaptureStarted:     boolean;
//    DXSound:  TDXSound;
//    Player:   TcmxMp3;
      DSP_VocalRemover:   HDSP;
    public
      Bass:               hStream;
      PlayerI:            array of integer;
      
//      SoundCard:          array of TSoundCard;
      procedure InitializePlayback;
      procedure InitializeRecord;
      procedure SetVolume(Volume: integer);
      procedure SetMusicVolume(Volume: integer);
      procedure Fade(InitVolume, TargetVolume: Integer; FadeTime: real);
      procedure FadeStop(FadeTime: real);
      procedure SetLoop(Enabled: boolean);
      function Open(Name: string): boolean; // true if succeed
      procedure Rewind;
      procedure MoveTo(Time: real);
      procedure Play;
      procedure Pause; //Pause Mod
      procedure Stop;
      procedure Close;
      function Finished: boolean;
      function isOpen: boolean;
      function Length: real;
      function Position: real;
      procedure PlayStart;
      procedure PlayBack;
      procedure PlaySwoosh;
      procedure PlayChange;
      procedure PlayOption;
      procedure PlayClick;
      procedure PlayDrum;
      procedure PlayHihat;
      procedure PlayClap;
      procedure PlayShuffle;
      procedure StopShuffle;
      procedure PlayApplause;

      function  VoicesOpen(Names: array of string): integer;
      procedure VoicesPlay;
      procedure VoicesStop;
      procedure VoicesClose;

      procedure CaptureStart;
      procedure CaptureStop;
      procedure CaptureCard(RecordI: byte);
      procedure StopCard(Card: byte);
      function LoadPlayerFromFile(var MediaPlayer: TMediaPlayer; Name: string): boolean;
      function LoadSoundFromFile(var hStream: hStream; Name: string): boolean;

      //Equalizer
      function GetFFTData: TFFTData;

      //Custom Sounds
      function LoadCustomSound(const Filename: String): Cardinal;
      procedure PlayCustomSound(const Index: Cardinal);

      procedure EnableVocalRemover;
      procedure DisableVocalRemover;
      function VocalRemoverActivated(): boolean;

end;

const
  RecordSystem = 1;

function FindNote(beat: integer): TPos;

type
  TMuzyka = record
    Path:   string;
    Start:  integer;        // start of song in ms
//    BPM:    array of TBPM;
//    Gap:    real;
    IlNut:  integer;
    DlugoscNut:   integer;
//    WartoscNut:   integer;
  end;

  TCzesci = record          //Lines
    Akt:      integer;      // aktualna czesc utworu do rysowania
    High:     integer;
    Ilosc:    integer;
    Resolution: integer;
    NotesGAP: integer;
    Wartosc:  integer;
    Czesc:    array of record    //Line
      Start:    integer;
      StartNote:  integer;
      Lyric:      string;
      LyricWidth: real;
      Koniec:   integer;         //Ende?
      BaseNote: integer;
      HighNut:  integer;
      IlNut:    integer;
      TotalNotes: integer;
      Nuta:     array of record       //Note
        Color:      integer;
        Start:      integer;
        Dlugosc:    integer;
        Ton:        integer;
        TonGamy:    integer;
        Tekst:      string;         //Silbe?
        FreeStyle:  boolean;
        Wartosc:    integer;    // zwykla nuta x1, zlota nuta x2
        IsMedley:   boolean;     //just for editor
        IsStartPreview: boolean; //just for editor




      end;
    end;
  end;

  TCzas = record              // wszystko, co dotyczy aktualnej klatki
//    BajtowTotal:  integer;
//    BajtowTeraz:  integer;
//    BajtowNaSek:  integer;
    OldBeat:      integer;    // poprzednio wykryty beat w utworze
    AktBeat:      integer;    // aktualny beat w utworze
    MidBeat:      real;       // dokladny AktBeat

    // should not be used
//    OldHalf:      integer;    // poprzednio wykryta polowka
//    AktHalf:      integer;    // aktualna polowka w utworze
//    MidHalf:      real;       // dokladny AktHalf

    // now we use this for super synchronization!
    // only used when analyzing voice
    OldBeatD:     integer;    // poprzednio wykryty beat w utworze
    AktBeatD:     integer;    // aktualny beat w utworze
    MidBeatD:     real;       // dokladny AktBeatD
    FracBeatD:    real;       // fractional part of MidBeatD

    // we use this for audiable clicks
    OldBeatC:     integer;    // poprzednio wykryty beat w utworze
    AktBeatC:     integer;    // aktualny beat w utworze
    MidBeatC:     real;       // dokladny AktBeatC
    FracBeatC:    real;       // fractional part of MidBeatC


    OldCzesc:     array [0..1] of integer;    // poprzednio wyswietlana czesc
                              // akt jest w czesci.akt

    Teraz:        real;       // actual time
    Razem:        real;       // total time
//    TerazSek:     integer;
  end;

var
  Form:     TForm;
  Music:    TMusic;

  // muzyka
  Muzyka:   TMuzyka;

  // czesci z nutami;
  Czesci:   array of TCzesci;

  // czas
  Czas:     TCzas;

  fHWND:        Thandle;

const
  ModeStr:  array[TMPModes] of string = ('Not ready', 'Stopped', 'Playing', 'Recording', 'Seeking', 'Paused', 'Open');

implementation
uses UGraphic, URecord, UFiles, UIni, UMain, UThemes, UTime;

//from http://www.un4seen.com/forum/?topic=5943.0;hl=sbvocalcut16
procedure SBVocalCut16(handle: DWORD; channel: DWORD; buffer: Pointer; length: DWORD; user: DWORD); stdcall;
var
  i:        DWORD;
  dmch:     Smallint;
  lch, rch: PSmallint;

begin
  i := 0;
  lch := buffer;
  rch := buffer;
  Inc(rch);

  while (i < length) do
  begin
    dmch := round((((0 - lch^) + (rch^)) / 2)*1.5);

    lch^ := dmch;
    rch^ := dmch;

    Inc(lch, 2);
    Inc(rch, 2);
    Inc(i, SizeOf(SmallInt) * 2);
  end;
end;

function FindNote(beat: integer): TPos;
var
  I, J:   integer;
  found:  boolean;
  min:    integer;
  diff:   integer;

begin
  found := false;

  for I := 0 to length(Czesci[0].Czesc) - 1 do
  begin
    for J := 0 to length(Czesci[0].Czesc[I].Nuta) - 1 do
    begin
      if (beat>=Czesci[0].Czesc[I].Nuta[J].Start) and
        (beat<=Czesci[0].Czesc[I].Nuta[J].Start + Czesci[0].Czesc[I].Nuta[J].Dlugosc) then
      begin
        Result.CP := 0;
        Result.line := I;
        Result.note := J;
        found:=true;
        break;
      end;
    end;
  end;

  if found then //found exactly
    exit;

  if AktSong.isDuet then
  begin
    for I := 0 to length(Czesci[1].Czesc) - 1 do
    begin
      for J := 0 to length(Czesci[1].Czesc[I].Nuta) - 1 do
      begin
        if (beat>=Czesci[1].Czesc[I].Nuta[J].Start) and
          (beat<=Czesci[1].Czesc[I].Nuta[J].Start + Czesci[1].Czesc[I].Nuta[J].Dlugosc) then
        begin
          Result.CP := 1;
          Result.line := I;
          Result.note := J;
          found:=true;
          break;
        end;
      end;
    end;
  end;

  if found then //found exactly
    exit;

  min := high(integer);
  //second try (approximating)
  for I := 0 to length(Czesci[0].Czesc) - 1 do
  begin
    for J := 0 to length(Czesci[0].Czesc[I].Nuta) - 1 do
    begin
      diff := abs(Czesci[0].Czesc[I].Nuta[J].Start - beat);
      if diff<min then
      begin
        Result.CP := 0;
        Result.line := I;
        Result.note := J;
        min := diff;
      end;
    end;
  end;

  if AktSong.isDuet then
  begin
    for I := 0 to length(Czesci[1].Czesc) - 1 do
    begin
      for J := 0 to length(Czesci[1].Czesc[I].Nuta) - 1 do
      begin
        diff := abs(Czesci[1].Czesc[I].Nuta[J].Start - beat);
        if diff<min then
        begin
          Result.CP := 1;
          Result.line := I;
          Result.note := J;
          min := diff;
        end;
      end;
    end;
  end;
end;

procedure InitializeSound;
begin
  Log.LogStatus('Initializing Playback', 'InitializeSound');  Music.InitializePlayback;
  Log.LogStatus('Initializing Record', 'InitializeSound');    Music.InitializeRecord;
end;

procedure TMusic.InitializePlayback;
begin
  Log.BenchmarkStart(4);
  Log.LogStatus('Initializing Playback Subsystem', 'Music Initialize');
  Loaded := false;
  Loop := false;
  fHWND := Classes.AllocateHWND( nil);

  BASS_SetConfig(BASS_CONFIG_DEV_DEFAULT, 1);

  if BASS_Init(-1, 44100, 0, fHWND, nil) = false then
  begin
    Application.MessageBox ('Could not initialize BASS', 'Error');
    Exit;
  end;

  BASS_SetConfig(BASS_CONFIG_VERIFY, high(WORD));
  DSP_VocalRemover := 0;
  SetLength(BassVoices, 0);
  Log.BenchmarkEnd(4); Log.LogBenchmark('--> Bass Init', 4);

  // config playing buffer
  //BASS_SetConfig(BASS_CONFIG_UPDATEPERIOD, 0);
  //BASS_SetConfig(BASS_CONFIG_BUFFER, 100);

{  MediaPlayer := TMediaPlayer.Create( nil );
  MediaPlayer.ParentWindow := fHWND;
  MediaPlayer.Wait := true;}

  Log.LogStatus('Loading Sounds', 'Music Initialize');

{  LoadPlayerFromFile(MediaPlayerStart,  SoundPath + 'Common Start.mp3');
  LoadPlayerFromFile(MediaPlayerBack,   SoundPath + 'Common Back.mp3');
  LoadPlayerFromFile(MediaPlayerSwoosh, SoundPath + 'menu swoosh.mp3');
  LoadPlayerFromFile(MediaPlayerChange, SoundPath + 'select music change music.mp3');
  LoadPlayerFromFile(MediaPlayerOption, SoundPath + 'option change col.mp3');
  LoadPlayerFromFile(MediaPlayerClick,  SoundPath + 'rimshot022b.mp3');

  LoadPlayerFromFile(MediaPlayerDrum,   SoundPath + 'bassdrumhard076b.mp3');
  LoadPlayerFromFile(MediaPlayerHihat,  SoundPath + 'hihatclosed068b.mp3');
  LoadPlayerFromFile(MediaPlayerClap,   SoundPath + 'claps050b.mp3');

  LoadPlayerFromFile(MediaPlayerShuffle, SoundPath + 'Shuffle.mp3');}

  Log.BenchmarkStart(4);
  LoadSoundFromFile(BassStart,  SoundPath + 'Common Start.mp3');
  LoadSoundFromFile(BassBack,   SoundPath + 'Common Back.mp3');
  LoadSoundFromFile(BassSwoosh, SoundPath + 'menu swoosh.mp3');
  LoadSoundFromFile(BassChange, SoundPath + 'select music change music 50.mp3');
  LoadSoundFromFile(BassOption, SoundPath + 'option change col.mp3');
  LoadSoundFromFile(BassClick,  SoundPath + 'rimshot022b.mp3');

//  LoadSoundFromFile(BassDrum,   SoundPath + 'bassdrumhard076b.mp3');
//  LoadSoundFromFile(BassHihat,  SoundPath + 'hihatclosed068b.mp3');
//  LoadSoundFromFile(BassClap,   SoundPath + 'claps050b.mp3');

//  LoadSoundFromFile(BassShuffle, SoundPath + 'Shuffle.mp3');
  LoadSoundFromFile(BassApplause,  SoundPath + 'Applause.mp3');
  Log.BenchmarkEnd(4); Log.LogBenchmark('--> Loading Sounds', 4);
end;

procedure TMusic.InitializeRecord;
var
  S:        integer;

begin
  CaptureStarted := false;
  if RecordSystem = 1 then begin
    SetLength(Sound, 6 {max players});//Ini.Players+1);
    for S := 0 to High(Sound) do begin //Ini.Players do begin
      Sound[S] := TSound.Create;
      Sound[S].Num := S;
      Sound[S].BufferNew := TMemoryStream.Create;
      SetLength(Sound[S].BufferLong, 1);
      Sound[S].BufferLong[0] := TMemoryStream.Create;
      Sound[S].n := 4*1024;
    end;


    // check for recording devices;
    {device := 0;
    descr := BASS_RecordGetDeviceDescription(device);

    SetLength(SoundCard, 0);
    while (descr <> '') do begin
      SC := High(SoundCard) + 1;
      SetLength(SoundCard, SC+1);

      Log.LogAnalyze('Device #'+IntToStr(device)+': '+ descr);
      SoundCard[SC].Description := Descr;

      // check for recording inputs
      mic[device] := -1; // default to no change
      input := 0;
      BASS_RecordInit(device);
      Log.LogAnalyze('Input #' + IntToStr(Input) + ': ' + BASS_RecordGetInputName(input));
      flags := BASS_RecordGetInput(input);

      SetLength(SoundCard[SC].Input, 0);
      while (flags <> -1) do begin
        SCI := High(SoundCard[SC].Input) + 1;
        SetLength(SoundCard[SC].Input, SCI+1);

        Log.LogAnalyze('Input #' + IntToStr(Input) + ': ' + BASS_RecordGetInputName(input));
        SoundCard[SC].Input[SCI].Name := BASS_RecordGetInputName(Input);

        if (flags and BASS_INPUT_TYPE_MASK) = BASS_INPUT_TYPE_MIC then begin
          mic[device] := input; // auto set microphone
        end;
        Inc(Input);
        flags := BASS_RecordGetInput(input);
      end;

      if mic[device] <> -1 then begin
        Log.LogAnalyze('Found the mic at input ' + IntToStr(Mic[device]))
      end else begin
        Log.LogAnalyze('Mic not found');
        mic[device] := 0; // setting to the first one (for kxproject)
      end;
      SoundCard[SC].InputSeleceted := Mic[Device];


      BASS_RecordFree;

      inc(Device);
      descr := BASS_RecordGetDeviceDescription(Device);
    end; // while}
  end; // if
end;

procedure TMusic.SetVolume(Volume: integer);
begin
  //Old Sets Wave Volume
  //BASS_SetVolume(Volume);
  //New: Sets Volume only for this Application
  BASS_SetConfig(BASS_CONFIG_GVOL_SAMPLE, Volume*100);
  BASS_SetConfig(BASS_CONFIG_GVOL_STREAM, Volume*100);
  BASS_SetConfig(BASS_CONFIG_GVOL_MUSIC, Volume*100);
end;

procedure TMusic.SetMusicVolume(Volume: Integer);
begin
  //Max Volume Prevention
  if Volume > 100 then
    Volume := 100;

  //Set MP3 Volume
  BASS_ChannelSetAttribute(Bass, BASS_ATTRIB_VOL, Volume/100);

  //Set Applause Volume
  BASS_ChannelSetAttribute(BassApplause, BASS_ATTRIB_VOL, Volume/100);
end;

procedure TMusic.Fade(InitVolume, TargetVolume: Integer; FadeTime: real);
var
  time: DWORD;
begin
  //Max Volume Prevention
  if TargetVolume > 100 then
    TargetVolume := 100
  else if TargetVolume<0 then
    TargetVolume := 0;

  BASS_ChannelSetAttribute(Bass, BASS_ATTRIB_VOL, InitVolume/100);
  time := round(FadeTime*1000);
  BASS_ChannelSlideAttribute(Bass, BASS_ATTRIB_VOL, TargetVolume/100, time);
end;

procedure TMusic.FadeStop(FadeTime: real);
var
  time: DWORD;
begin
  time := round(FadeTime*1000);
  BASS_ChannelSlideAttribute(Bass, BASS_ATTRIB_VOL, -1, time);  //fade out and stop
end;

procedure TMusic.SetLoop(Enabled: boolean);
begin
  Loop := Enabled;
end;

function TMusic.Open(Name: string): boolean;
var
  errorCode: integer;
begin
  Loaded := false;

  if FileExists(Name) then
  begin
{    MediaPlayer.FileName := Name;
    MediaPlayer.Open;}

    Bass := Bass_StreamCreateFile(false, PChar(Name), 0, 0, BASS_STREAM_PRESCAN);
    if (Bass>0) then
      Loaded := true
    else
    begin
      errorCode := BASS_ErrorGetCode();
      Log.LogError('Error (' + IntToStr(errorCode) + ') on open File: ' + Name);
    end;

    DSP_VocalRemover:=0;
    //Set Max Volume
    //SetMusicVolume (100);
  end;

  Result := Loaded;

//  Player := TcmxMp3.Create(Name);
end;

procedure TMusic.Rewind;
begin
  if Loaded then begin
//    MediaPlayer.Position := 0;

  end;
end;

procedure TMusic.MoveTo(Time: real);
var
  bytes:    QWORD;
begin
//  if Loaded then begin
//    MediaPlayer.StartPos := Round(Time);
    bytes := BASS_ChannelSeconds2Bytes(Bass, Time);
    BASS_ChannelSetPosition(Bass, bytes, BASS_POS_BYTE);
//  end;
end;

procedure TMusic.Play;
begin
  if Loaded then
  begin
//    MediaPlayer.Play;
    if Loop then BASS_ChannelPlay(Bass, True); // start from beginning... actually bass itself does not loop, nor does this TMusic Class
    BASS_ChannelPlay(Bass, False); // for setting position before playing
  end;
end;

procedure TMusic.Pause; //Pause Mod
begin
  if Loaded then
  begin
    BASS_ChannelPause(Bass); // Pauses Song
  end;
end;

procedure TMusic.Stop;
begin
  Bass_ChannelStop(Bass);
//  Bass_StreamFree(Bass);
//  if ModeStr[MediaPlayer.Mode] = 'Playing' then begin
//    MediaPlayer.Stop;
//  end;
end;

procedure TMusic.Close;
begin
  Bass_StreamFree(Bass);
  DSP_VocalRemover:=0;
  Loaded := false;
//  Player.Free;
//  MediaPlayer.Close;
end;

function TMusic.Length: real;
var
  bytes:    QWORD;
begin
  //Result := 60;

  bytes  := BASS_ChannelGetLength(Bass, BASS_POS_BYTE);
  Result := BASS_ChannelBytes2Seconds(Bass, bytes);

{  if Assigned(MediaPlayer) then begin
    if Loaded then Result := MediaPlayer.Length / 1000;
  end;}
//  if Assigned(Player) then
//    Result := Player.LengthInSeconds;
end;

function TMusic.Position: real;
var
  bytes:    QWORD;
begin
  //Result := 0;//MediaPlayer.Position / 1000;
  bytes := BASS_ChannelGetPosition(BASS, BASS_POS_BYTE);
  Result := BASS_ChannelBytes2Seconds(BASS, bytes);
end;

function TMusic.isOpen: boolean;
begin
  Result := Loaded;
end;

function TMusic.Finished: boolean;
begin
  Result := false;
//  if ModeStr[MediaPlayer.Mode] = 'Stopped' then Result := true;
  if BASS_ChannelIsActive(BASS) = BASS_ACTIVE_STOPPED then
  begin
//    beep;
    Result := true;
  end;
end;

{function myeffect( chan : integer; stream : Pointer; len : integer; udata : Pointer ): Pointer; cdecl;
var
  dane:   pwordarray;
  pet:    integer;
  Prev:     smallint;
  PrevNew:  smallint;
begin
  dane := stream;
  Prev := 0;
  for pet := 0 to len div 2 -1 do begin
    PrevNew := Dane[Pet];

//    Dane[pet] := Round(PrevNew*1/8 + Prev*7/8);

    Prev := Dane[Pet];
  end;
end;}

procedure TMusic.PlayStart;
{var
  Music:    PMix_Chunk;}
begin
{  Mix_OpenAudio(44100, 16, 1, 16*1024);
  Music := Mix_LoadWAV('D:\Rozne\UltraStar\Old\Boys - Hej Sokoly 30s.wav');
  Mix_RegisterEffect(0, myeffect, nil, 0);
  Mix_PlayChannel(0, Music, 0);}

//  MediaPlayerStart.Rewind;
//  MediaPlayerStart.Play;
  BASS_ChannelPlay(BassStart, True);
end;

procedure TMusic.PlayBack;
begin
//  MediaPlayerBack.Rewind;
//  MediaPlayerBack.Play;
//  if not
  BASS_ChannelPlay(BassBack, True);// then
//    Application.MessageBox ('Error playing stream!', 'Error');
end;

procedure TMusic.PlaySwoosh;
begin
//  MediaPlayerSwoosh.Rewind;
//  MediaPlayerSwoosh.Play;
  BASS_ChannelPlay(BassSwoosh, True);
end;

procedure TMusic.PlayChange;
begin
//  MediaPlayerChange.Rewind;
//  MediaPlayerChange.Play;
  BASS_ChannelPlay(BassChange, True);
end;

procedure TMusic.PlayOption;
begin
//  MediaPlayerOption.Rewind;
//  MediaPlayerOption.Play;
  BASS_ChannelPlay(BassOption, True);
end;

procedure TMusic.PlayClick;
begin
//  MediaPlayerClick.Rewind;
//  MediaPlayerClick.Play;
  BASS_ChannelPlay(BassClick, True);
end;

procedure TMusic.PlayDrum;
begin
//  MediaPlayerDrum.Rewind;
//  MediaPlayerDrum.Play;
  BASS_ChannelPlay(BassDrum, True);
end;

procedure TMusic.PlayHihat;
begin
//  MediaPlayerHihat.Rewind;
//  MediaPlayerHihat.Play;
  BASS_ChannelPlay(BassHihat, True);
end;

procedure TMusic.PlayClap;
begin
//  MediaPlayerClap.Rewind;
//  MediaPlayerClap.Play;
  BASS_ChannelPlay(BassClap, True);
end;

procedure TMusic.PlayShuffle;
begin
//  MediaPlayerShuffle.Rewind;
//  MediaPlayerShuffle.Play;
  BASS_ChannelPlay(BassShuffle, True);
end;

procedure TMusic.StopShuffle;
begin
  BASS_ChannelStop(BassShuffle);
end;

procedure TMusic.PlayApplause;
begin
//  MediaPlayerShuffle.Rewind;
//  MediaPlayerShuffle.Play;
  BASS_ChannelPlay(BassApplause, True);
end;

procedure TMusic.CaptureStart;
var
  S:        integer;
  SC:       integer;
  P1:       integer;
  P2:       integer;
begin
  if CaptureStarted then
    Exit;

  for S := 0 to High(Sound) do
    Sound[S].BufferLong[0].Clear;

  SetLength(PlayerI, High(Ini.CardList)+1);

  for SC := 0 to High(Ini.CardList) do begin
    P1 := Ini.CardList[SC].ChannelL;
    P2 := Ini.CardList[SC].ChannelR;
    if P1 > PlayersPlay then P1 := 0;
    if P2 > PlayersPlay then P2 := 0;
    PlayerI[SC] := P1 + P2*256;
    if (P1 > 0) or (P2 > 0) then
      CaptureCard(SC);
  end;

  CaptureStarted := true;
end;

procedure TMusic.CaptureStop;
var
  SC:   integer;
  P1:       integer;
  P2:       integer;
begin
  for SC := 0 to High(Ini.CardList) do begin
    P1 := Ini.CardList[SC].ChannelL;
    P2 := Ini.CardList[SC].ChannelR;
    if P1 > PlayersPlay then P1 := 0;
    if P2 > PlayersPlay then P2 := 0;
    if (P1 > 0) or (P2 > 0) then StopCard(SC);
  end;
  CaptureStarted := false;
end;

//procedure TMusic.CaptureCard(RecordI, SoundNum, PlayerLeft, PlayerRight: byte);
procedure TMusic.CaptureCard(RecordI: byte);
var
  Error:      integer;
  ErrorMsg:   string;
  //Player:     integer;
begin
  if not BASS_RecordInit(RecordI) then begin
    Error := BASS_ErrorGetCode;

    ErrorMsg := IntToStr(Error);
    if Error = BASS_ERROR_DX then ErrorMsg := 'No DX5';
    if Error = BASS_ERROR_ALREADY then ErrorMsg := 'The device has already been initialized';
    if Error = BASS_ERROR_DEVICE then ErrorMsg := 'The device number specified is invalid';
    if Error = BASS_ERROR_DRIVER then ErrorMsg := 'There is no available device driver';

    {Log.LogAnalyze('Error initializing record [' + IntToStr(RecordI) + ', '
      + IntToStr(PlayerLeft) + ', '+ IntToStr(PlayerRight) + ']: '
      + ErrorMsg);}
    Log.LogError('Error initializing record [' + IntToStr(RecordI) + ', '
      //+ IntToStr(PlayerLeft) + ', '+ IntToStr(PlayerRight) + ']: '
      + ErrorMsg);
    Log.LogError('Music -> CaptureCard: Error initializing record: ' + ErrorMsg);


  end else
  begin
  //Player := PlayerLeft + PlayerRight*256;
  //SoundCard[RecordI].BassRecordStream := BASS_RecordStart(44100, 2, MakeLong(0, 20) , @GetMicrophone, PlayerLeft + PlayerRight*256);
  Recording.SoundCard[RecordI].BassRecordStream := BASS_RecordStart(44100, 2, MakeLong(0, 20) , @GetMicrophone, Pointer(PlayerI[RecordI]));

  {if SoundCard[RecordI].BassRecordStream = 0 then begin
    Error := BASS_ErrorGetCode;

    ErrorMsg := IntToStr(Error);
    if Error = BASS_ERROR_INIT then ErrorMsg := 'Not successfully called';
    if Error = BASS_ERROR_ALREADY then ErrorMsg := 'Recording is already in progress';
    if Error = BASS_ERROR_NOTAVAIL then ErrorMsg := 'The recording device is not available';
    if Error = BASS_ERROR_FORMAT then ErrorMsg := 'The specified format is not supported';
    if Error = BASS_ERROR_MEM then ErrorMsg := 'There is insufficent memory';
    if Error = BASS_ERROR_UNKNOWN then ErrorMsg := 'Unknown';

    Log.LogError('Error creating record stream [' + IntToStr(RecordI) + ', '
      + IntToStr(PlayerLeft) + ', '+ IntToStr(PlayerRight) + ']: '
      + ErrorMsg);
  end;         }
  end;
end;

procedure TMusic.StopCard(Card: byte);
begin
  BASS_RecordSetDevice(Card);
  BASS_RecordFree;
end;

function TMusic.LoadPlayerFromFile(var MediaPlayer: TMediaPlayer; Name: string): boolean;
begin
  Log.LogStatus('Loading Sound: "' + Name + '"', 'LoadPlayerFromFile');
  if FileExists(Name) then begin
    try
      MediaPlayer := TMediaPlayer.Create( nil );
    except
      Log.LogError('Failed to create MediaPlayer', 'LoadPlayerFromFile');
    end;
    try
      MediaPlayer.ParentWindow := fHWND;
      MediaPlayer.Wait := true;
      MediaPlayer.FileName := Name;
      MediaPlayer.DeviceType := dtAutoSelect;
      MediaPlayer.Display := nil;
    except
      Log.LogError('Failed setting MediaPlayer: ' + MediaPlayer.ErrorMessage, 'LoadPlayerFromFile');
    end;
    try
      MediaPlayer.Open;
    except
      Log.LogError('Failed to open using MediaPlayer', 'LoadPlayerFromFile');
    end;
  end else begin
    Log.LogError('Sound not found: "' + Name + '"', 'LoadPlayerFromFile');
    exit;
  end;
end;

function TMusic.LoadSoundFromFile(var hStream: hStream; Name: string): boolean;
var
  L: Integer;
begin
  if FileExists(Name) then begin
    Log.LogStatus('Loading Sound: "' + Name + '"', 'LoadPlayerFromFile');
    try
      hStream := BASS_StreamCreateFile(False, pchar(Name), 0, 0, 0);
      //Add CustomSound
      L := High(CustomSounds) + 1;
      SetLength (CustomSounds, L + 1);
      CustomSounds[L].Filename := Name;
      CustomSounds[L].Handle := hStream;
    except
      Log.LogError('Failed to open using BASS', 'LoadPlayerFromFile');
    end;
  end else begin
    Log.LogError('Sound not found: "' + Name + '"', 'LoadPlayerFromFile');
    exit;
  end;
end;

//Equalizer
function TMusic.GetFFTData: TFFTData;
{var
Data: TFFTData;}
begin
  //Get Channel Data Mono and 256 Values
  BASS_ChannelGetData(Bass, @Result, BASS_DATA_FFT512);
  //Result := Data;
end;

function TMusic.LoadCustomSound(const Filename: String): Cardinal;
var
  S: hStream;
  I: Integer;
  F: String;
begin
  //Search for Sound in already loaded Sounds
  F := UpperCase(SoundPath + FileName);
  For I := 0 to High(CustomSounds) do
  begin
    if (UpperCase(CustomSounds[I].Filename) = F) then
    begin
      Result := I;
      Exit;
    end;
  end;

  if LoadSoundFromFile(S, SoundPath + Filename) then
    Result := High(CustomSounds)
  else
    Result := 0;
end;

procedure TMusic.PlayCustomSound(const Index: Cardinal);
begin
if Index <= High(CustomSounds) then
  BASS_ChannelPlay(CustomSounds[Index].Handle, True);
end;

procedure TMusic.EnableVocalRemover;
begin
  if DSP_VocalRemover=0 then
    DSP_VocalRemover := Bass_ChannelSetDSP(Bass, @SBVocalCut16, 0, 0);

end;

procedure TMusic.DisableVocalRemover;
begin
  if DSP_VocalRemover<>0 then
  begin
    BASS_ChannelRemoveDSP(Bass, DSP_VocalRemover);
    DSP_VocalRemover := 0;
  end;
end;

function TMusic.VocalRemoverActivated(): boolean;
begin
  Result := (DSP_VocalRemover <> 0);
end;


function TMusic.VoicesOpen(Names: array of string): integer;
var
  I:    integer;
  num:  integer;

begin
  SetLength(BassVoices, 0);

  for I := 0 to high(Names) do
  begin
    if FileExists(Names[I]) then
    begin
      num := high(BassVoices)+1;
      SetLength(BassVoices, num+1);
      BassVoices[num] := Bass_StreamCreateFile(false, pchar(Names[I]), 0, 0, 0);
      DSP_VocalRemover:=0;
    end;
  end;

  Result := high(BassVoices)+1;
end;

procedure TMusic.VoicesPlay;
var
  I:  integer;
begin
  for I := 0 to high(BassVoices) do
  begin
    BASS_ChannelPlay(BassVoices[I], True);
  end;
end;

procedure TMusic.VoicesStop;
var
  I:  integer;
begin
  for I := 0 to high(BassVoices) do
    Bass_ChannelStop(BassVoices[I]);
end;


procedure TMusic.VoicesClose;
var
  I:  integer;
begin
  for I := 0 to high(BassVoices) do
  begin
    Bass_StreamFree(BassVoices[I]);
    DSP_VocalRemover:=0;
  end;
  SetLength(BassVoices, 0);
end;
end.