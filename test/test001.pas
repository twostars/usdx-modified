program test001;

{
This program tests the function glext_ExtensionSupported from unit glext.
}

uses
  SysUtils,
  SDL          in '../src/lib/JEDI-SDL/SDL/Pas/sdl.pas',
  moduleloader in '../src/lib/JEDI-SDL/SDL/Pas/moduleloader.pas',
  gl           in '../src/lib/JEDI-SDL/OpenGL/Pas/gl.pas',
  glext        in '../src/lib/JEDI-SDL/OpenGL/Pas/glext.pas';

const
  s1:  PAnsiChar = '';
  s2:  PAnsiChar = 'ext';
  s3:  PAnsiChar = ' ext';
  s4:  PAnsiChar = ' ext ';
  s5:  PAnsiChar = 'kkshf kjsfh ext';
  s6:  PAnsiChar = 'fakh sajhf ext jskdhf';
  s7:  PAnsiChar = 'ext jshf';
  s8:  PAnsiChar = 'sdkjfh ksjhext sjdha';
  s9:  PAnsiChar = 'sdkjfh ksjh extsjdha';
  s10: PAnsiChar = 'sdkjfh ksjhextsjdha';
  s11: PAnsiChar = 'sd kjf jdha';

  e1: PAnsiChar = '';
  e2: PAnsiChar = 'ext';
  e3: PAnsiChar = 'GL_ARB_window_pos';

  SCREEN_WIDTH  = 640;
  SCREEN_HEIGHT = 480;
  SCREEN_BPP    =  16;

var
  surface:    PSDL_Surface;
  videoFlags: integer;
  testFailed: boolean;
  
procedure treatTestFailure(testNumber: integer, var testFailed: boolean);
begin
  writeln;
  write ('test001, ', testNumber, ': failed');
  testFailed := true;
end;

begin
  write ('test001: Start ... ');
  testFailed := false;

// initialize SDL and OpenGL for the use of glGetString(GL_EXTENSIONS)
// within glext_ExtensionSupported.

  SDL_Init( SDL_INIT_VIDEO);

// the flags to pass to SDL_SetVideoMode
  videoFlags := SDL_OPENGL;

// get a SDL surface
  surface := SDL_SetVideoMode(SCREEN_WIDTH, SCREEN_HEIGHT, SCREEN_BPP, videoFlags);

// Initialization finished

  if     glext_ExtensionSupported(e1, s1)  then treatTestFailure( 1, testFailed);
  if     glext_ExtensionSupported(e1, s2)  then treatTestFailure( 2, testFailed);
  if     glext_ExtensionSupported(e2, s1)  then treatTestFailure( 3, testFailed);
  if not glext_ExtensionSupported(e2, s2)  then treatTestFailure( 4, testFailed);
  if not glext_ExtensionSupported(e2, s3)  then treatTestFailure( 5, testFailed);
  if not glext_ExtensionSupported(e2, s4)  then treatTestFailure( 6, testFailed);
  if not glext_ExtensionSupported(e2, s5)  then treatTestFailure( 7, testFailed);
  if not glext_ExtensionSupported(e2, s6)  then treatTestFailure( 8, testFailed);
  if not glext_ExtensionSupported(e2, s7)  then treatTestFailure( 9, testFailed);
  if     glext_ExtensionSupported(e2, s8)  then treatTestFailure(10, testFailed);
  if     glext_ExtensionSupported(e2, s9)  then treatTestFailure(11, testFailed);
  if     glext_ExtensionSupported(e2, s10) then treatTestFailure(12, testFailed);
  if     glext_ExtensionSupported(e2, s11) then treatTestFailure(13, testFailed);
  if not glext_ExtensionSupported(e3, s1)  then treatTestFailure(14, testFailed);

  if testFailed then
  begin
    writeln;
    writeln ('test001: End');
  end
  else
    writeln ('End');
end.