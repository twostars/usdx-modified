unit URecord;

interface
uses Classes, Math, SysUtils, {DXSounds, Wave, }UMusic, UIni, BASS;

type
  TSound = class
    BufferNew:    TMemoryStream; // buffer for newest sample
    BufferArray:  array[1..4096] of smallint; // (Signal) newest 4096 samples
    BufferLong:   array of TMemoryStream;     // full buffer

    Num:          integer;
    n:            integer; // length of Signal to analyze
//    Spectrum:     array[1..8192] of single;   // sound buffer from above as FFT
//    Spektogram:   array[0..100] of TSpekt;    // FFT(t)

    // pitch detection
    SzczytJest:   boolean;       // czy jest szczyt
    Szczyt:       integer;    // pozycja szczytu na osi poziomej
    TonDokl:      real;       // ton aktualnego szczytu
    Ton:          integer;    // ton bez ulamka
    TonGamy:      integer;    // ton w gamie. wartosci: 0-11
    Skala:        real;       // skala FFT

    // procedures
    procedure ProcessNewBuffer;
    procedure AnalizujBufor;    // use to analyze sound from buffers to get new pitch
    procedure AnalizujByAutocorrelation;    // we call it to analyze sound by checking Autocorrelation
    function  AnalyzeAutocorrelationFreq(Freq: real): real;   // use this to check one frequency by Autocorrelation
    function  GetToneString: string; //from usdx 1.1
  end;

  TSoundCardInput = record
    Name:   string;
  end;

  TSoundCard = record
    // here can be the soundcard information - whole database from which user will select recording source
    Description:    string;
    Input:          array of TSoundCardInput;
    InputSeleceted: integer;

    // bass record
    BassRecordStream: hStream;
  end;

  TRecord = class
    SoundCard:  array of TSoundCard;
    constructor Create;
  end;

  smallintarray = array [0..maxInt shr 1-1] of smallInt;
  psmallintarray = ^smallintarray;

  // procedures - bass record
  function GetMicrophone(handle: HSTREAM; buffer: Pointer; len: DWORD; user: DWORD): boolean; stdcall;


var
  Sound:      array of TSound;
  SoundCard:  array of TSoundCard;
  Poz:        integer;
  Recording:  TRecord;

const
  // from usdx 1.1
  ToneStrings: array[0..11] of string = (
    'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
  );

implementation
uses UMain, ULog;

// from usdx 1.1
function TSound.GetToneString: string;
begin
  if (SzczytJest) then
    Result := ToneStrings[TonGamy] + IntToStr(Ton div 12 + 2)
  else
    Result := '-';
end;

procedure TSound.ProcessNewBuffer;
var
  S:    integer;
  L:    integer;
  A:    integer;
begin
  // process BufferArray
  S := 0;
  L := BufferNew.Size div 2;
  if L > n then begin
    S := L - n;
    L := n;
  end;
  
  // copy to array
  for A := L+1 to n do
    BufferArray[A-L] := BufferArray[A];

  BufferNew.Seek(2*S, soBeginning);
  BufferNew.ReadBuffer(BufferArray[1+n-L], 2*L);

  // process BufferLong
  if Ini.SavePlayback = 1 then begin
    BufferNew.Seek(0, soBeginning);
    BufferLong[0].CopyFrom(BufferNew, BufferNew.Size);
  end;
end;

procedure TSound.AnalizujBufor;
begin
  AnalizujByAutocorrelation;
end;

procedure TSound.AnalizujByAutocorrelation;
var
  T:        integer;  // tone
  F:        real; // freq
  Wages:    array[0..35] of real; // wages
  MaxT:     integer; // max tone
  MaxW:     real; // max wage
  V:        real; // volume
  MaxV:     real; // max volume
  S:        integer; // Signal
  Threshold:  real; // threshold
begin
//  Log.LogAnalyze('[Analyze by Autocorrelation]');
  SzczytJest := false;

  // find maximum volume of first 1024 words of signal
  MaxV := 0;
  for S := 1 to 1024 do begin // 0.5.2: fix. was from 0 to 1023
//    Log.LogDebug('1');
//    Log.LogDebug(IntTostr(S));
    V := Abs(BufferArray[S]) / $10000;
//    Log.LogDebug('2');
//    Log.LogDebug(IntTostr(S) + ': ' + FloatToStr(V) + ', MaxV='+floattostr(maxv)+', buf='+inttostr(length(BufferArray)));
    if V > MaxV then MaxV := V;
//    Log.LogDebug('3');
//    Log.LogDebug(IntTostr(S) + ': ' + FloatToStr(V) + ', MaxV='+floattostr(maxv)+', buf='+inttostr(length(BufferArray)));
  end;


  // prepare to analyze
  MaxW := 0;
  MaxT := 0;

  // analyze all 12 halftones
  for T := 0 to 35 do begin // to 11, then 23, now 35 (for Whitney and my high voice)
    F := 130.81*Power(1.05946309436, T)/2; // let's analyze below 130.81
    Wages[T] := AnalyzeAutocorrelationFreq(F);

    if Wages[T] > MaxW then begin // this frequency has better wage
      MaxW := Wages[T];
      MaxT := T;
    end;
  end; // for T

  Threshold := 0.1;
  case Ini.Threshold of
    0:  Threshold := 0.05;
    1:  Threshold := 0.1;
    2:  Threshold := 0.15;
    3:  Threshold := 0.2;
  end;

  //Log.LogDebug('Sound -> AnalyzeByAutocorrelation: MaxV='+floattostr(maxv)+', Threshold='+floattostr(threshold));
  if MaxV >= Threshold then begin // found acceptable volume // 0.1
    SzczytJest := true;
    TonGamy := MaxT mod 12;
    Ton := MaxT;
  end;

//  Log.LogAnalyze('--> Weight: ')
//  Log.LogAnalyze('--> Selected: ' + BoolToStr(SzczytJest, true) +
//    ', TonGamy: ' + IntToStr(Ton) +
//    ', MaxV: ' + FloatToStr(MaxV));
//  Log.LogAnalyze('');


end;

function TSound.AnalyzeAutocorrelationFreq(Freq: real): real; // result medium difference
var
  Count:      real;
  Src:        integer;
  Dst:        integer;
  Move:       integer;
  Il:         integer; // how many counts were done
begin
  // we use Signal as source
  Count := 0;
  Il := 0;
  Src := 1;
  Move := Round(44100/Freq);
  Dst := Src + Move;

  // ver 1 - sample 1 and compare n-times
{  while (Src <= Move) do begin // process by moving Src by one
    while (Dst < n) do begin // process up to n (4KB) of Signal
      Count := Count + Abs(Signal[Src] - Signal[Dst]) / $10000;
      Inc(Dst, Move);
      Inc(Il);
    end;

    Inc(Src);
    Dst := Src + Move;
  end;}

  // ver 2 - compare in vertical
  while (Dst < n) do begin // process up to n (4KB) of Signal
    Count := Count + Abs(BufferArray[Src] - BufferArray[Dst]) / $10000;
    Inc(Src);
    Inc(Dst);
    Inc(Il);
  end;

  Result := 1 - Count / Il;
end;

function GetMicrophone(handle: HSTREAM; buffer: Pointer; len: DWORD; user: DWORD): boolean; stdcall;
var
  L:    integer;
  S:    integer;
  PB:   pbytearray;
  PSI:  psmallintarray;
  I:    integer;
  Skip: integer;
  P1:   integer;
  P2:   integer;
  Boost:  byte;

begin
//  Log.LogDebug('Record -> GetMicrophone: len='+inttstr(len));
  // set boost
  case Ini.MicBoost of
    0:  Boost := 1;
    1:  Boost := 2;
    2:  Boost := 4;
    3:  Boost := 8;
    else Boost := 1;
  end;

  // boost buffer
  L := Len div 2; // number of samples
  PSI := Buffer;
  for S := 0 to L-1 do begin
    I := PSI^[S] * Boost;
    if I > 32767 then I := 32767; // 0.5.0: limit
    if I < -32768 then I := -32768; // 0.5.0: limit
    PSI^[S] := I;
  end;

  // decode user
  P1 := (user and 255) - 1;
  P2 := (user div 256) - 1;

//  Log.LogDebug('Record -> GetMicrophone: P1='+inttostr(p1)+', P2='+inttostr(p2));

  // 2 players USB mic, left channel
  if P1 >= 0 then begin
    L := Len div 4; // number of samples
    PB := Buffer;
//    Log.LogDebug('Record -> GetMicrophone -> Sound[P1].BufferNew.Clear');
    Sound[P1].BufferNew.Clear; // 0.5.2: problem on exiting
    for S := 1 to L do begin
      Sound[P1].BufferNew.Write(PB[(S-1)*4], 2);
    end;
    Sound[P1].ProcessNewBuffer;
  end;

  // 2 players USB mic, right channel
//  if Ini.Debug = 0 then Skip := 2
//  else Skip := 0;
  Skip := 2;

  if P2 >= 0 then begin
    L := Len div 4; // number of samples
    PB := Buffer;
    Sound[P2].BufferNew.Clear;
    for S := 1 to L do begin
      Sound[P2].BufferNew.Write(PB[Skip + (S-1)*4], 2);
    end;
    Sound[P2].ProcessNewBuffer;
  end;

//  Log.LogDebug('Record -> GetMicrophone -> Finish');

  Result := true;
end;

constructor TRecord.Create;
var
  Info:       BASS_DEVICEINFO;
  SC:         integer; // soundcard
  SCI:        integer; // soundcard input
  Descr:      string;
  InputName:  string;
  Flags:      integer;
  No:         integer;
  Proceed:    boolean;

  function isDuplicate(Desc: String): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    //Check for Soundcard with same Description
    For I := 0 to SC-1 do
    begin
      if (SoundCard[I].Description = Desc) then
      begin
        Result := True;
        Break;
      end;
    end;
  end;

begin
  // checks for recording devices and puts them into array;
  //Log.LogError('Init recoding devices...');
  SetLength(SoundCard, 0);
  BASS_RecordFree;
  SC := 0;
  Proceed := BASS_RecordGetDeviceInfo(SC, &Info);

  while Proceed and not (info.flags and BASS_DEVICE_ENABLED=0) do
  begin
    Descr := Info.name;
    //If there is another SoundCard with the Same ID, Search an available Name
    if (IsDuplicate(Descr)) then
    begin
      No:= 1; //Count of SoundCards with  same Name
      Repeat
      Inc(No)
      Until not IsDuplicate(Descr + ' (' + InttoStr(No) + ')');
      //Set Description
      Descr := Descr + ' (' + InttoStr(No) + ')';
    end;

    SetLength(SoundCard, SC+1);
    //Log.LogError('Device #' + IntToStr(SC+1) + ': ' + Descr);
    SoundCard[SC].Description := Descr;

    //check for recording inputs
    SCI := 0;
    BASS_RecordInit(SC);
    Flags := BASS_RecordGetInput(SCI, PSingle(nil)^);
    InputName := BASS_RecordGetInputName(SCI);
    //Log.LogError('Input #' + IntToStr(SCI) + ' (' + IntToStr(Flags) + '): ' + InputName);

    SetLength(SoundCard[SC].Input, 1);
    SoundCard[SC].Input[SCI].Name := InputName;

    // process each input
    while (Flags <> -1) and (Flags and BASS_INPUT_TYPE_MIC<>0) do
    begin
      if SCI >= 1 then
      begin
        SetLength(SoundCard[SC].Input, SCI+1);
        InputName := BASS_RecordGetInputName(SCI);
        SoundCard[SC].Input[SCI].Name := InputName;
        //Log.LogError('Input #' + IntToStr(SCI) + ' (' + IntToStr(Flags) + '): ' + InputName);
      end;

      Inc(SCI);
      Flags := BASS_RecordGetInput(SCI, PSingle(nil)^);
    end;

    BASS_RecordFree;

    Inc(SC);
    Proceed := BASS_RecordGetDeviceInfo(SC, &Info);
  end; // while
  //Log.LogError('End of Init recoding devices.');
end;
end.

