{*****************************************************************
 * Configuration file for UltraStar Deluxe 1.1
 *****************************************************************}

{* Libraries *}

{$DEFINE HaveFFmpeg}

{$IF Defined(IncludeConstants)}
  LUA_LIB_NAME        = 'lua';
  LUA_VERSION_INT     = 5001005;
  LUA_VERSION_RELEASE = '5';
  LUA_VERSION_MINOR   = '1';
  LUA_VERSION_MAJOR   = '5';
  LUA_VERSION         = '5.1.5';
{$IFEND}

{$DEFINE HaveFFmpeg}
{$IF Defined(HaveFFmpeg)}
  {$IFNDEF FFMPEG_DIR}
    {$IF (7 > 0) or (0 > 0)}
      {$DEFINE FFMPEG_DIR := 'ffmpeg-0.7'}
      {$DEFINE FF_API_OLD_DECODE_AUDIO}
    {$ELSE}
      {$DEFINE FFMPEG_DIR := 'ffmpeg'}
      {$DEFINE useOLD_FFMPEG}
    {$IFEND}
  {$ENDIF}
  {$IF Defined(IncludeConstants)}
    FFMPEG_VERSION_INT = 7000;

    av__codec = 'avcodec-52';
    LIBAVCODEC_VERSION_MAJOR   = 52;
    LIBAVCODEC_VERSION_MINOR   = 67;
    LIBAVCODEC_VERSION_RELEASE = 2;

    av__format = 'avformat-52';
    LIBAVFORMAT_VERSION_MAJOR   = 52;
    LIBAVFORMAT_VERSION_MINOR   = 62;
    LIBAVFORMAT_VERSION_RELEASE = 0;

    av__util = 'avutil-50';
    LIBAVUTIL_VERSION_MAJOR   = 50;
    LIBAVUTIL_VERSION_MINOR   = 15;
    LIBAVUTIL_VERSION_RELEASE = 2;
  {$IFEND}
{$IFEND}

{$DEFINE HaveSWScale}
{$IF Defined(HaveSWScale) and Defined(IncludeConstants)}
  sw__scale = 'swscale-0';
  LIBSWSCALE_VERSION_MAJOR   = 0;
  LIBSWSCALE_VERSION_MINOR   = 10;
  LIBSWSCALE_VERSION_RELEASE = 0;
{$IFEND}

{$DEFINE HaveProjectM}
{$IF Defined(HaveProjectM) and Defined(IncludeConstants)}
  ProjectM_DataDir = 'Visuals\projectM';
  PROJECTM_VERSION_MAJOR   = 1;
  PROJECTM_VERSION_MINOR   = 10;
  PROJECTM_VERSION_RELEASE = 0;
{$IFEND}

{$UNDEF HavePortaudio}
{$IF Defined(HavePortaudio) and Defined(IncludeConstants)}
  PORTAUDIO_VERSION_MAJOR   = 19;
  PORTAUDIO_VERSION_MINOR   = 0;
  PORTAUDIO_VERSION_RELEASE = 0;
{$IFEND}

{$UNDEF HavePortmixer}

{$UNDEF HaveLibsamplerate}
{$IF Defined(HaveLibsamplerate) and Defined(IncludeConstants)}
  LIBSAMPLERATE_VERSION_MAJOR   = 0;
  LIBSAMPLERATE_VERSION_MINOR   = 1;
  LIBSAMPLERATE_VERSION_RELEASE = 3;
{$IFEND}
