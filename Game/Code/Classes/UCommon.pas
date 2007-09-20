unit UCommon;

interface

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses

{$IFDEF win32}
   windows;
{$ELSE}
   lcltype,
   messages;
{$ENDIF}

{$IFNDEF win32}
type
  hStream        = THandle;
  HGLRC          = THandle;
  TLargeInteger  = Int64;
  TWin32FindData = LongInt;
{$ENDIF}

{$IFDEF FPC}

type
  TWndMethod = procedure(var Message: TMessage) of object;

function  RandomRange(aMin: Integer; aMax: Integer) : Integer;
//function  AllocateHWnd(Method: TWndMethod): HWND;
//procedure DeallocateHWnd(Wnd: HWND);

function MaxValue(const Data: array of Double): Double;
function MinValue(const Data: array of Double): Double;
{$ENDIF}

{$IFNDEF win32}
(*
  function QueryPerformanceCounter(lpPerformanceCount:TLARGEINTEGER):Bool;
  function QueryPerformanceFrequency(lpFrequency:TLARGEINTEGER):Bool;
*)
  procedure ZeroMemory( Destination: Pointer; Length: DWORD );
{$ENDIF}

implementation

{$IFNDEF win32}
procedure ZeroMemory( Destination: Pointer; Length: DWORD );
begin
  FillChar( Destination^, Length, 0 );
end; //ZeroMemory

(*
function QueryPerformanceCounter(lpPerformanceCount:TLARGEINTEGER):Bool;

  // From http://en.wikipedia.org/wiki/RDTSC
  function RDTSC: Int64; register;
  asm
    rdtsc
  end;

begin
  // Use clock_gettime  here maybe ... from libc
  lpPerformanceCount := RDTSC();
  result := true;
end;

function QueryPerformanceFrequency(lpFrequency:TLARGEINTEGER):Bool;
begin
  lpFrequency := 0;
  result := true;
end;
*)
{$ENDIF}


{$IFDEF FPC}

function MaxValue(const Data: array of Double): Double;
var
  I: Integer;
begin
  Result := Data[Low(Data)];
  for I := Low(Data) + 1 to High(Data) do
    if Result < Data[I] then
      Result := Data[I];
end;

function MinValue(const Data: array of Double): Double;
var
  I: Integer;
begin
  Result := Data[Low(Data)];
  for I := Low(Data) + 1 to High(Data) do
    if Result > Data[I] then
      Result := Data[I];
end;

function RandomRange(aMin: Integer; aMax: Integer) : Integer;
begin
RandomRange := Random(aMax-aMin) + aMin ;
end;


// NOTE !!!!!!!!!!
// AllocateHWnd is in lclintfh.inc

{
// TODO : JB this is dodgey and bad... find a REAL solution !
function AllocateHWnd(Method: TWndMethod): HWND;
var
  TempClass: TWndClass;
  ClassRegistered: Boolean;
begin
  Result := CreateWindowEx(WS_EX_TOOLWINDOW, '', '', WS_POPUP , 0, 0, 0, 0, 0, 0, HInstance, nil);
end;

procedure DeallocateHWnd(Wnd: HWND);
var
  Instance: Pointer;
begin
  Instance := Pointer(GetWindowLong(Wnd, GWL_WNDPROC));
  DestroyWindow(Wnd);
end;
}

{$ENDIF}


end.
