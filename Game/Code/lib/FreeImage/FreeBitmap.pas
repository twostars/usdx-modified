unit FreeBitmap;

{$I switches.inc}


// ==========================================================
//
// Delphi wrapper for FreeImage 3
//
// Design and implementation by
// - Anatoliy Pulyaevskiy (xvel84@rambler.ru)
//
// Contributors:
// - Enzo Costantini (enzocostantini@libero.it)
//
// This file is part of FreeImage 3
//
// COVERED CODE IS PROVIDED UNDER THIS LICENSE ON AN "AS IS" BASIS, WITHOUT WARRANTY
// OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, WITHOUT LIMITATION, WARRANTIES
// THAT THE COVERED CODE IS FREE OF DEFECTS, MERCHANTABLE, FIT FOR A PARTICULAR PURPOSE
// OR NON-INFRINGING. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE COVERED
// CODE IS WITH YOU. SHOULD ANY COVERED CODE PROVE DEFECTIVE IN ANY RESPECT, YOU (NOT
// THE INITIAL DEVELOPER OR ANY OTHER CONTRIBUTOR) ASSUME THE COST OF ANY NECESSARY
// SERVICING, REPAIR OR CORRECTION. THIS DISCLAIMER OF WARRANTY CONSTITUTES AN ESSENTIAL
// PART OF THIS LICENSE. NO USE OF ANY COVERED CODE IS AUTHORIZED HEREUNDER EXCEPT UNDER
// THIS DISCLAIMER.
//
// Use at your own risk!
//
// ==========================================================
//
// From begining all code of this file is based on C++ wrapper to
// FreeImage - FreeImagePlus.
//
// ==========================================================

interface

uses
  SysUtils, Classes, Windows, FreeImage;

type
  { TFreeObject }

  TFreeObject = class(TObject)
  public
    function IsValid: Boolean; virtual;
  end;

  { TFreeTag }

  TFreeTag = class(TFreeObject)
  private
    // fields
    FTag: PFITAG;

    // getters & setters
    function GetCount: Cardinal;
    function GetDescription: string;
    function GetID: Word;
    function GetKey: string;
    function GetLength: Cardinal;
    function GetTagType: FREE_IMAGE_MDTYPE;
    function GetValue: Pointer;
    procedure SetCount(const Value: Cardinal);
    procedure SetDescription(const Value: string);
    procedure SetID(const Value: Word);
    procedure SetKey(const Value: string);
    procedure SetLength(const Value: Cardinal);
    procedure SetTagType(const Value: FREE_IMAGE_MDTYPE);
    procedure SetValue(const Value: Pointer);
  public
    // construction & destruction
    constructor Create(ATag: PFITAG = nil); virtual;
    destructor Destroy; override;

    // methods
    function Clone: TFreeTag;
    function IsValid: Boolean; override;
    function ToString(Model: FREE_IMAGE_MDMODEL; Make: PChar = nil): string;

    // properties
    property Key: string read GetKey write SetKey;
    property Description: string read GetDescription write SetDescription;
    property ID: Word read GetID write SetID;
    property TagType: FREE_IMAGE_MDTYPE read GetTagType write SetTagType;
    property Count: Cardinal read GetCount write SetCount;
    property Length: Cardinal read GetLength write SetLength;
    property Value: Pointer read GetValue write SetValue;
    property Tag: PFITAG read FTag;
  end;

  { forward declarations }

  TFreeBitmap = class;
  TFreeMemoryIO = class;

  { TFreeBitmap }

  TFreeBitmapChangingEvent = procedure(Sender: TFreeBitmap; var OldDib, NewDib: PFIBITMAP; var Handled: Boolean) of object;

  TFreeBitmap = class(TFreeObject)
  private
    // fields
    FDib: PFIBITMAP;
    FOnChange: TNotifyEvent;
    FOnChanging: TFreeBitmapChangingEvent;

    procedure SetDib(Value: PFIBITMAP);
  protected
    function DoChanging(var OldDib, NewDib: PFIBITMAP): Boolean; dynamic;
    function Replace(NewDib: PFIBITMAP): Boolean; dynamic;
  public
    constructor Create(ImageType: FREE_IMAGE_TYPE = FIT_BITMAP; Width: Integer = 0; Height: Integer = 0; Bpp: Integer = 0);
    destructor Destroy; override;
    function SetSize(ImageType: FREE_IMAGE_TYPE; Width, Height, Bpp: Integer; RedMask: Cardinal = 0; GreenMask: Cardinal = 0; BlueMask: Cardinal = 0): Boolean;
    procedure Change; dynamic;
    procedure Assign(Source: TFreeBitmap);
    function CopySubImage(Left, Top, Right, Bottom: Integer; Dest: TFreeBitmap): Boolean;
    function PasteSubImage(Src: TFreeBitmap; Left, Top: Integer; Alpha: Integer = 256): Boolean;
    procedure Clear; virtual;
    function Load(const FileName: string; Flag: Integer = 0): Boolean;
    function LoadU(const FileName: WideString; Flag: Integer = 0): Boolean;
    function LoadFromHandle(IO: PFreeImageIO; Handle: fi_handle; Flag: Integer = 0): Boolean;
    function LoadFromMemory(MemIO: TFreeMemoryIO; Flag: Integer = 0): Boolean;
    function LoadFromStream(Stream: TStream; Flag: Integer = 0): Boolean;
    // save functions
    function CanSave(fif: FREE_IMAGE_FORMAT): Boolean;
    function Save(const FileName: string; Flag: Integer = 0): Boolean;
    function SaveU(const FileName: WideString; Flag: Integer = 0): Boolean;
    function SaveToHandle(fif: FREE_IMAGE_FORMAT; IO: PFreeImageIO; Handle: fi_handle; Flag: Integer = 0): Boolean;
    function SaveToMemory(fif: FREE_IMAGE_FORMAT; MemIO: TFreeMemoryIO; Flag: Integer = 0): Boolean;
    function SaveToStream(fif: FREE_IMAGE_FORMAT; Stream: TStream; Flag: Integer = 0): Boolean;
    // image information
    function GetImageType: FREE_IMAGE_TYPE;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetScanWidth: Integer;
    function IsValid: Boolean; override;
    function GetInfo: PBitmapInfo;
    function GetInfoHeader: PBitmapInfoHeader;
    function GetImageSize: Cardinal;
    function GetBitsPerPixel: Integer;
    function GetLine: Integer;
    function GetHorizontalResolution: Double;
    function GetVerticalResolution: Double;
    procedure SetHorizontalResolution(Value: Double);
    procedure SetVerticalResolution(Value: Double);
    // palette operations
    function GetPalette: PRGBQUAD;
    function GetPaletteSize: Integer;
    function GetColorsUsed: Integer;
    function GetColorType: FREE_IMAGE_COLOR_TYPE;
    function IsGrayScale: Boolean;
    // pixels access
    function AccessPixels: PByte;
    function GetScanLine(ScanLine: Integer): PByte;
    function GetPixelIndex(X, Y: Cardinal; var Value: PByte): Boolean;
    function GetPixelColor(X, Y: Cardinal; Value: PRGBQUAD): Boolean;
    function SetPixelIndex(X, Y: Cardinal; Value: PByte): Boolean;
    function SetPixelColor(X, Y: Cardinal; Value: PRGBQUAD): Boolean;
    // convertion
    function ConvertToStandardType(ScaleLinear: Boolean): Boolean;
    function ConvertToType(ImageType: FREE_IMAGE_TYPE; ScaleLinear: Boolean): Boolean;
    function Threshold(T: Byte): Boolean;
    function ConvertTo4Bits: Boolean;
    function ConvertTo8Bits: Boolean;
    function ConvertTo16Bits555: Boolean;
    function ConvertTo16Bits565: Boolean;
    function ConvertTo24Bits: Boolean;
    function ConvertTo32Bits: Boolean;
    function ConvertToGrayscale: Boolean;
    function ColorQuantize(Algorithm: FREE_IMAGE_QUANTIZE): Boolean;
    function Dither(Algorithm: FREE_IMAGE_DITHER): Boolean;
    function ConvertToRGBF: Boolean;
    function ToneMapping(TMO: FREE_IMAGE_TMO; FirstParam, SecondParam: Double): Boolean;
    // transparency
    function IsTransparent: Boolean;
    function GetTransparencyCount: Cardinal;
    function GetTransparencyTable: PByte;
    procedure SetTransparencyTable(Table: PByte; Count: Integer);
    function HasFileBkColor: Boolean;
    function GetFileBkColor(var BkColor: PRGBQuad): Boolean;
    function SetFileBkColor(BkColor: PRGBQuad): Boolean;
    // channel processing routines
    function GetChannel(Bitmap: TFreeBitmap; Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
    function SetChannel(Bitmap: TFreeBitmap; Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
    function SplitChannels(RedChannel, GreenChannel, BlueChannel: TFreeBitmap): Boolean;
    function CombineChannels(Red, Green, Blue: TFreeBitmap): Boolean;
    // rotation and flipping
    function RotateEx(Angle, XShift, YShift, XOrigin, YOrigin: Double; UseMask: Boolean): Boolean;
    function Rotate(Angle: Double): Boolean;
    function FlipHorizontal: Boolean;
    function FlipVertical: Boolean;
    // color manipulation routines
    function Invert: Boolean;
    function AdjustCurve(Lut: PByte; Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
    function AdjustGamma(Gamma: Double): Boolean;
    function AdjustBrightness(Percentage: Double): Boolean;
    function AdjustContrast(Percentage: Double): Boolean;
    function GetHistogram(Histo: PDWORD; Channel: FREE_IMAGE_COLOR_CHANNEL = FICC_BLACK): Boolean;
    // upsampling / downsampling
    procedure MakeThumbnail(const Width, Height: Integer; DestBitmap: TFreeBitmap);
    function Rescale(NewWidth, NewHeight: Integer; Filter: FREE_IMAGE_FILTER; Dest: TFreeBitmap = nil): Boolean;
    // metadata routines
    function FindFirstMetadata(Model: FREE_IMAGE_MDMODEL; var Tag: TFreeTag): PFIMETADATA;
    function FindNextMetadata(MDHandle: PFIMETADATA; var Tag: TFreeTag): Boolean;
    procedure FindCloseMetadata(MDHandle: PFIMETADATA);
    function SetMetadata(Model: FREE_IMAGE_MDMODEL; const Key: string; Tag: TFreeTag): Boolean;
    function GetMetadata(Model: FREE_IMAGE_MDMODEL; const Key: string; var Tag: TFreeTag): Boolean;
    function GetMetadataCount(Model: FREE_IMAGE_MDMODEL): Cardinal;

    // properties
    property Dib: PFIBITMAP read FDib write SetDib;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnChanging: TFreeBitmapChangingEvent read FOnChanging write FOnChanging;
  end;
  
  { TFreeWinBitmap }


  { TFreeMemoryIO }

  TFreeMemoryIO = class(TFreeObject)
  private
    FHMem: PFIMEMORY;
  public
    // construction and destruction
    constructor Create(Data: PByte = nil; SizeInBytes: DWORD = 0);
    destructor Destroy; override;

    function GetFileType: FREE_IMAGE_FORMAT;
    function Read(fif: FREE_IMAGE_FORMAT; Flag: Integer = 0): PFIBITMAP;
    function Write(fif: FREE_IMAGE_FORMAT; dib: PFIBITMAP; Flag: Integer = 0): Boolean;
    function Tell: Longint;
    function Seek(Offset: Longint; Origin: Word): Boolean;
    function Acquire(var Data: PByte; var SizeInBytes: DWORD): Boolean;
    // overriden methods
    function IsValid: Boolean; override;
  end;

  { TFreeMultiBitmap }

  TFreeMultiBitmap = class(TFreeObject)
  private
    FMPage: PFIMULTIBITMAP;
    FMemoryCache: Boolean;
  public
    // constructor and destructor
    constructor Create(KeepCacheInMemory: Boolean = False);
    destructor Destroy; override;

    // methods
    function Open(const FileName: string; CreateNew, ReadOnly: Boolean; Flags: Integer = 0): Boolean;
    function Close(Flags: Integer = 0): Boolean;
    function GetPageCount: Integer;
    procedure AppendPage(Bitmap: TFreeBitmap);
    procedure InsertPage(Page: Integer; Bitmap: TFreeBitmap);
    procedure DeletePage(Page: Integer);
    function MovePage(Target, Source: Integer): Boolean;
    procedure LockPage(Page: Integer; DestBitmap: TFreeBitmap);
    procedure UnlockPage(Bitmap: TFreeBitmap; Changed: Boolean);
    function GetLockedPageNumbers(var Pages: Integer; var Count: Integer): Boolean;    
    // overriden methods
    function IsValid: Boolean; override;

    // properties
    // change of this property influences only on the next opening of a file
    property MemoryCache: Boolean read FMemoryCache write FMemoryCache;
  end;

implementation

const
  ThumbSize = 150;

// marker used for clipboard copy / paste

procedure SetFreeImageMarker(bmih: PBitmapInfoHeader; dib: PFIBITMAP);
begin
  // Windows constants goes from 0L to 5L
	// Add $FF to avoid conflicts
	bmih.biCompression := $FF + FreeImage_GetImageType(dib);
end;

function GetFreeImageMarker(bmih: PBitmapInfoHeader): FREE_IMAGE_TYPE;
begin
  Result := FREE_IMAGE_TYPE(bmih.biCompression - $FF);
end;

{ TFreePersistent }

function TFreeObject.IsValid: Boolean;
begin
  Result := False
end;

{ TFreeBitmap }

function TFreeBitmap.AccessPixels: PByte;
begin
  Result := FreeImage_GetBits(FDib)
end;

function TFreeBitmap.AdjustBrightness(Percentage: Double): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_AdjustBrightness(FDib, Percentage);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.AdjustContrast(Percentage: Double): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_AdjustContrast(FDib, Percentage);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.AdjustCurve(Lut: PByte;
  Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_AdjustCurve(FDib, Lut, Channel);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.AdjustGamma(Gamma: Double): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_AdjustGamma(FDib, Gamma);
    Change;
  end
  else
    Result := False
end;

procedure TFreeBitmap.Assign(Source: TFreeBitmap);
var
  SourceBmp: TFreeBitmap;
  Clone: PFIBITMAP;
begin
  if Source = nil then
  begin
    Clear;
    Exit;
  end;
  
  if Source is TFreeBitmap then
  begin
    SourceBmp := TFreeBitmap(Source);
    if SourceBmp <> Self then
    begin
      if SourceBmp.IsValid then
      begin
        Clone := FreeImage_Clone(SourceBmp.FDib);
        Replace(Clone);
      end
      else
        Clear;
    end;
  end;
end;

function TFreeBitmap.CanSave(fif: FREE_IMAGE_FORMAT): Boolean;
var
  ImageType: FREE_IMAGE_TYPE;
  Bpp: Word;
begin
  Result := False;
  if not IsValid then Exit;

  if fif <> FIF_UNKNOWN then
  begin
    // check that the dib can be saved in this format
    ImageType := FreeImage_GetImageType(FDib);
    if ImageType = FIT_BITMAP then
    begin
      // standard bitmap type
      Bpp := FreeImage_GetBPP(FDib);
      Result := FreeImage_FIFSupportsWriting(fif)
                and FreeImage_FIFSupportsExportBPP(fif, Bpp);
    end
    else // special bitmap type
      Result := FreeImage_FIFSupportsExportType(fif, ImageType);
  end;
end;

procedure TFreeBitmap.Change;
begin
  if Assigned(FOnChange) then FOnChange(Self)
end;

procedure TFreeBitmap.Clear;
begin
  if FDib <> nil then
  begin
    FreeImage_Unload(FDib);
    FDib := nil;
    Change;
  end;
end;

function TFreeBitmap.ColorQuantize(
  Algorithm: FREE_IMAGE_QUANTIZE): Boolean;
var
  dib8: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib8 := FreeImage_ColorQuantize(FDib, Algorithm);
    Result := Replace(dib8);
  end
  else
    Result := False;
end;

function TFreeBitmap.CombineChannels(Red, Green,
  Blue: TFreeBitmap): Boolean;
var
  Width, Height: Integer;
begin
  if FDib = nil then
  begin
    Width := Red.GetWidth;
    Height := Red.GetHeight;
    FDib := FreeImage_Allocate(Width, Height, 24, FI_RGBA_RED_MASK,
            FI_RGBA_GREEN_MASK, FI_RGBA_BLUE_MASK);
  end;

  if FDib <> nil then
  begin
    Result := FreeImage_SetChannel(FDib, Red.FDib, FICC_RED) and
              FreeImage_SetChannel(FDib, Green.FDib, FICC_GREEN) and
              FreeImage_SetChannel(FDib, Blue.FDib, FICC_BLUE);

    Change
  end
  else
    Result := False;
end;

function TFreeBitmap.ConvertTo16Bits555: Boolean;
var
  dib16_555: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib16_555 := FreeImage_ConvertTo16Bits555(FDib);
    Result := Replace(dib16_555);
  end
  else
    Result := False
end;

function TFreeBitmap.ConvertTo16Bits565: Boolean;
var
  dib16_565: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib16_565 := FreeImage_ConvertTo16Bits565(FDib);
    Result := Replace(dib16_565);
  end
  else
    Result := False
end;

function TFreeBitmap.ConvertTo24Bits: Boolean;
var
  dibRGB: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dibRGB := FreeImage_ConvertTo24Bits(FDib);
    Result := Replace(dibRGB);
  end
  else
    Result := False
end;

function TFreeBitmap.ConvertTo32Bits: Boolean;
var
  dib32: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib32 := FreeImage_ConvertTo32Bits(FDib);
    Result := Replace(dib32);
  end
  else
    Result := False
end;

function TFreeBitmap.ConvertTo4Bits: Boolean;
var
  dib4: PFIBITMAP;
begin
  Result := False;
  if IsValid then
  begin
    dib4 := FreeImage_ConvertTo4Bits(FDib);
    Result := Replace(dib4);
  end;
end;

function TFreeBitmap.ConvertTo8Bits: Boolean;
var
  dib8: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib8 := FreeImage_ConvertTo8Bits(FDib);
    Result := Replace(dib8);
  end
  else
    Result := False
end;

function TFreeBitmap.ConvertToGrayscale: Boolean;
var
  dib8: PFIBITMAP;
begin
  Result := False;

  if IsValid then
  begin
    dib8 := FreeImage_ConvertToGreyscale(FDib);
    Result := Replace(dib8);
  end
end;

function TFreeBitmap.ConvertToRGBF: Boolean;
var
  ImageType: FREE_IMAGE_TYPE;
  NewDib: PFIBITMAP;
begin
  Result := False;
  if not IsValid then Exit;

  ImageType := GetImageType;

  if (ImageType = FIT_BITMAP) then
  begin
    if GetBitsPerPixel < 24 then
      if not ConvertTo24Bits then
        Exit
  end;
  NewDib := FreeImage_ConvertToRGBF(FDib);
  Result := Replace(NewDib);
end;

function TFreeBitmap.ConvertToStandardType(ScaleLinear: Boolean): Boolean;
var
  dibStandard: PFIBITMAP;
begin
  if IsValid then
  begin
    dibStandard := FreeImage_ConvertToStandardType(FDib, ScaleLinear);
    Result := Replace(dibStandard);
  end
  else
    Result := False;
end;

function TFreeBitmap.ConvertToType(ImageType: FREE_IMAGE_TYPE;
  ScaleLinear: Boolean): Boolean;
var
  dib: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib := FreeImage_ConvertToType(FDib, ImageType, ScaleLinear);
    Result := Replace(dib)
  end
  else
    Result := False
end;

function TFreeBitmap.CopySubImage(Left, Top, Right, Bottom: Integer;
  Dest: TFreeBitmap): Boolean;
begin
  if FDib <> nil then
  begin
    Dest.FDib := FreeImage_Copy(FDib, Left, Top, Right, Bottom);
    Result := Dest.IsValid;
  end else
    Result := False;
end;

constructor TFreeBitmap.Create(ImageType: FREE_IMAGE_TYPE; Width, Height,
  Bpp: Integer);
begin
  inherited Create;

  FDib := nil;
  if (Width > 0) and (Height > 0) and (Bpp > 0) then
    SetSize(ImageType, Width, Height, Bpp);
end;

destructor TFreeBitmap.Destroy;
begin
  if FDib <> nil then
    FreeImage_Unload(FDib);
  inherited;
end;

function TFreeBitmap.Dither(Algorithm: FREE_IMAGE_DITHER): Boolean;
var
  dib: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib := FreeImage_Dither(FDib, Algorithm);
    Result := Replace(dib);
  end
  else
    Result := False;
end;

function TFreeBitmap.DoChanging(var OldDib, NewDib: PFIBITMAP): Boolean;
begin
  Result := False;
  if (OldDib <> NewDib) and Assigned(FOnChanging) then
    FOnChanging(Self, OldDib, NewDib, Result);
end;

procedure TFreeBitmap.FindCloseMetadata(MDHandle: PFIMETADATA);
begin
  FreeImage_FindCloseMetadata(MDHandle);
end;

function TFreeBitmap.FindFirstMetadata(Model: FREE_IMAGE_MDMODEL;
  var Tag: TFreeTag): PFIMETADATA;
begin
  Result := FreeImage_FindFirstMetadata(Model, FDib, Tag.FTag);
end;

function TFreeBitmap.FindNextMetadata(MDHandle: PFIMETADATA;
  var Tag: TFreeTag): Boolean;
begin
  Result := FreeImage_FindNextMetadata(MDHandle, Tag.FTag);
end;

function TFreeBitmap.FlipHorizontal: Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_FlipHorizontal(FDib);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.FlipVertical: Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_FlipVertical(FDib);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.GetBitsPerPixel: Integer;
begin
  Result := FreeImage_GetBPP(FDib)
end;

function TFreeBitmap.GetChannel(Bitmap: TFreeBitmap;
  Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
begin
  if FDib <> nil then
  begin
    Bitmap.Dib := FreeImage_GetChannel(FDib, Channel);
    Result := Bitmap.IsValid;
  end
  else
    Result := False
end;

function TFreeBitmap.GetColorsUsed: Integer;
begin
  Result := FreeImage_GetColorsUsed(FDib)
end;

function TFreeBitmap.GetColorType: FREE_IMAGE_COLOR_TYPE;
begin
  Result := FreeImage_GetColorType(FDib);
end;

function TFreeBitmap.GetFileBkColor(var BkColor: PRGBQuad): Boolean;
begin
  Result := FreeImage_GetBackgroundColor(FDib, BkColor)
end;

function TFreeBitmap.GetHeight: Integer;
begin
  Result := FreeImage_GetHeight(FDib)
end;

function TFreeBitmap.GetHistogram(Histo: PDWORD;
  Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
begin
  if FDib <> nil then
    Result := FreeImage_GetHistogram(FDib, Histo, Channel)
  else
    Result := False
end;

function TFreeBitmap.GetHorizontalResolution: Double;
begin
  Result := FreeImage_GetDotsPerMeterX(FDib) / 100
end;

function TFreeBitmap.GetImageSize: Cardinal;
begin
  Result := FreeImage_GetDIBSize(FDib);
end;

function TFreeBitmap.GetImageType: FREE_IMAGE_TYPE;
begin
  Result := FreeImage_GetImageType(FDib);
end;

function TFreeBitmap.GetInfo: PBitmapInfo;
begin
  Result := FreeImage_GetInfo(FDib^)
end;

function TFreeBitmap.GetInfoHeader: PBITMAPINFOHEADER;
begin
  Result := FreeImage_GetInfoHeader(FDib)
end;

function TFreeBitmap.GetLine: Integer;
begin
  Result := FreeImage_GetLine(FDib)
end;

function TFreeBitmap.GetMetadata(Model: FREE_IMAGE_MDMODEL;
  const Key: string; var Tag: TFreeTag): Boolean;
begin
  Result := FreeImage_GetMetaData(Model, FDib, PChar(Key), Tag.FTag);
end;

function TFreeBitmap.GetMetadataCount(Model: FREE_IMAGE_MDMODEL): Cardinal;
begin
  Result := FreeImage_GetMetadataCount(Model, FDib);
end;

function TFreeBitmap.GetPalette: PRGBQUAD;
begin
  Result := FreeImage_GetPalette(FDib)
end;

function TFreeBitmap.GetPaletteSize: Integer;
begin
  Result := FreeImage_GetColorsUsed(FDib) * SizeOf(RGBQUAD)
end;

function TFreeBitmap.GetPixelColor(X, Y: Cardinal; Value: PRGBQUAD): Boolean;
begin
  Result := FreeImage_GetPixelColor(FDib, X, Y, Value)
end;

function TFreeBitmap.GetPixelIndex(X, Y: Cardinal;
  var Value: PByte): Boolean;
begin
  Result := FreeImage_GetPixelIndex(FDib, X, Y, Value)
end;

function TFreeBitmap.GetScanLine(ScanLine: Integer): PByte;
var
  H: Integer;
begin
  H := FreeImage_GetHeight(FDib);
  if ScanLine < H then
    Result := FreeImage_GetScanLine(FDib, ScanLine)
  else
    Result := nil;
end;

function TFreeBitmap.GetScanWidth: Integer;
begin
  Result := FreeImage_GetPitch(FDib)
end;

function TFreeBitmap.GetTransparencyCount: Cardinal;
begin
  Result := FreeImage_GetTransparencyCount(FDib)
end;

function TFreeBitmap.GetTransparencyTable: PByte;
begin
  Result := FreeImage_GetTransparencyTable(FDib)
end;

function TFreeBitmap.GetVerticalResolution: Double;
begin
  Result := FreeImage_GetDotsPerMeterY(Fdib) / 100
end;

function TFreeBitmap.GetWidth: Integer;
begin
  Result := FreeImage_GetWidth(FDib)
end;

function TFreeBitmap.HasFileBkColor: Boolean;
begin
  Result := FreeImage_HasBackgroundColor(FDib)
end;

function TFreeBitmap.Invert: Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_Invert(FDib);
    Change;
  end
  else
    Result := False
end;

function TFreeBitmap.IsGrayScale: Boolean;
begin
  Result := (FreeImage_GetBPP(FDib) = 8)
            and (FreeImage_GetColorType(FDib) = FIC_PALETTE); 
end;

function TFreeBitmap.IsTransparent: Boolean;
begin
  Result := FreeImage_IsTransparent(FDib);
end;

function TFreeBitmap.IsValid: Boolean;
begin
  Result := FDib <> nil
end;

function TFreeBitmap.Load(const FileName: string; Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin

  // check the file signature and get its format
  fif := FreeImage_GetFileType(PChar(Filename), 0);
  if fif = FIF_UNKNOWN then
    // no signature?
    // try to guess the file format from the file extention
    fif := FreeImage_GetFIFFromFilename(PChar(FileName));

    // check that the plugin has reading capabilities ...
    if (fif <> FIF_UNKNOWN) and FreeImage_FIFSupportsReading(FIF) then
    begin
      // free the previous dib
      if FDib <> nil then
        FreeImage_Unload(dib);

      // load the file
      FDib := FreeImage_Load(fif, PChar(FileName), Flag);

      Change;
      Result := IsValid;
    end else
      Result := False;
end;

function TFreeBitmap.LoadFromHandle(IO: PFreeImageIO; Handle: fi_handle;
  Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin
  // check the file signature and get its format
  fif := FreeImage_GetFileTypeFromHandle(IO, Handle, 16);
  if (fif <> FIF_UNKNOWN) and FreeImage_FIFSupportsReading(fif) then
  begin
    // free the previous dib
    if FDib <> nil then
      FreeImage_Unload(FDib);

    // load the file
    FDib := FreeImage_LoadFromHandle(fif, IO, Handle, Flag);

    Change;
    Result := IsValid;
  end else
    Result := False;
end;

function TFreeBitmap.LoadFromMemory(MemIO: TFreeMemoryIO;
  Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin

  // check the file signature and get its format
  fif := MemIO.GetFileType;
  if (fif <> FIF_UNKNOWN) and FreeImage_FIFSupportsReading(fif) then
  begin
    // free the previous dib
    if FDib <> nil then
      FreeImage_Unload(FDib);

    // load the file
    FDib := MemIO.Read(fif, Flag);

    Result := IsValid;
    Change;
  end else
    Result := False;
end;

function TFreeBitmap.LoadFromStream(Stream: TStream;
  Flag: Integer): Boolean;
var
  MemIO: TFreeMemoryIO;
  Data: PByte;
  MemStream: TMemoryStream;
  Size: Cardinal;
begin
  Size := Stream.Size;

  MemStream := TMemoryStream.Create;
  try
    MemStream.CopyFrom(Stream, Size);
    Data := MemStream.Memory;

    MemIO := TFreeMemoryIO.Create(Data, Size);
    try
      Result := LoadFromMemory(MemIO);
    finally
      MemIO.Free;
    end;
  finally
    MemStream.Free;
  end;
end;

function TFreeBitmap.LoadU(const FileName: WideString;
  Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin

  // check the file signature and get its format
  fif := FreeImage_GetFileTypeU(PWideChar(Filename), 0);
  if fif = FIF_UNKNOWN then
    // no signature?
    // try to guess the file format from the file extention
    fif := FreeImage_GetFIFFromFilenameU(PWideChar(FileName));

    // check that the plugin has reading capabilities ...
    if (fif <> FIF_UNKNOWN) and FreeImage_FIFSupportsReading(FIF) then
    begin
      // free the previous dib
      if FDib <> nil then
        FreeImage_Unload(dib);

      // load the file
      FDib := FreeImage_LoadU(fif, PWideChar(FileName), Flag);

      Change;
      Result := IsValid;
    end else
      Result := False;
end;

procedure TFreeBitmap.MakeThumbnail(const Width, Height: Integer;
  DestBitmap: TFreeBitmap);
type
  PRGB24 = ^TRGB24;
  TRGB24 = packed record
    B: Byte;
    G: Byte;
    R: Byte;
  end;
var
  x, y, ix, iy: integer;
  x1, x2, x3: integer;

  xscale, yscale: single;
  iRed, iGrn, iBlu, iRatio: Longword;
  p, c1, c2, c3, c4, c5: TRGB24;
  pt, pt1: PRGB24;
  iSrc, iDst, s1: integer;
  i, j, r, g, b, tmpY: integer;

  RowDest, RowSource, RowSourceStart: integer;
  w, h: Integer;
  dxmin, dymin: integer;
  ny1, ny2, ny3: integer;
  dx, dy: integer;
  lutX, lutY: array of integer;

  SrcBmp, DestBmp: PFIBITMAP;
begin
  if not IsValid then Exit;

  if (GetWidth <= ThumbSize) and (GetHeight <= ThumbSize) then
  begin
    DestBitmap.Assign(Self);
    Exit;
  end;

  w := Width;
  h := Height;

  // prepare bitmaps
  if GetBitsPerPixel <> 24 then
    SrcBmp := FreeImage_ConvertTo24Bits(FDib)
  else
    SrcBmp := FDib;
  DestBmp := FreeImage_Allocate(w, h, 24);
  Assert(DestBmp <> nil, 'TFreeBitmap.MakeThumbnail error');

{  iDst := (w * 24 + 31) and not 31;
  iDst := iDst div 8; //BytesPerScanline
  iSrc := (GetWidth * 24 + 31) and not 31;
  iSrc := iSrc div 8;
}
  // BytesPerScanline
  iDst := FreeImage_GetPitch(DestBmp);
  iSrc := FreeImage_GetPitch(SrcBmp);

  xscale := 1 / (w / FreeImage_GetWidth(SrcBmp));
  yscale := 1 / (h / FreeImage_GetHeight(SrcBmp));

  // X lookup table
  SetLength(lutX, w);
  x1 := 0;
  x2 := trunc(xscale);
  for x := 0 to w - 1 do
  begin
    lutX[x] := x2 - x1;
    x1 := x2;
    x2 := trunc((x + 2) * xscale);
  end;

  // Y lookup table
  SetLength(lutY, h);
  x1 := 0;
  x2 := trunc(yscale);
  for x := 0 to h - 1 do
  begin
    lutY[x] := x2 - x1;
    x1 := x2;
    x2 := trunc((x + 2) * yscale);
  end;

  Dec(w);
  Dec(h);
  RowDest := integer(FreeImage_GetScanLine(DestBmp, 0));
  RowSourceStart := integer(FreeImage_GetScanLine(SrcBmp, 0));
  RowSource := RowSourceStart;

  for y := 0 to h do
  // resampling
  begin
    dy := lutY[y];
    x1 := 0;
    x3 := 0;
    for x := 0 to w do  // loop through row
    begin
      dx:= lutX[x];
      iRed:= 0;
      iGrn:= 0;
      iBlu:= 0;
      RowSource := RowSourceStart;
      for iy := 1 to dy do
      begin
        pt := PRGB24(RowSource + x1);
        for ix := 1 to dx do
        begin
          iRed := iRed + pt.R;
          iGrn := iGrn + pt.G;
          iBlu := iBlu + pt.B;
          inc(pt);
        end;
        RowSource := RowSource + iSrc;
      end;
      iRatio := 65535 div (dx * dy);
      pt1 := PRGB24(RowDest + x3);
      pt1.R := (iRed * iRatio) shr 16;
      pt1.G := (iGrn * iRatio) shr 16;
      pt1.B := (iBlu * iRatio) shr 16;
      x1 := x1 + 3 * dx;
      inc(x3,3);
    end;
    RowDest := RowDest + iDst;
    RowSourceStart := RowSource;
  end; // resampling

  if FreeImage_GetHeight(DestBmp) >= 3 then
  // Sharpening...
  begin
    s1 := integer(FreeImage_GetScanLine(DestBmp, 0));
    iDst := integer(FreeImage_GetScanLine(DestBmp, 1)) - s1;
    ny1 := Integer(s1);
    ny2 := ny1 + iDst;
    ny3 := ny2 + iDst;
    for y := 1 to FreeImage_GetHeight(DestBmp) - 2 do
    begin
      for x := 0 to FreeImage_GetWidth(DestBmp) - 3 do
      begin
        x1 := x * 3;
        x2 := x1 + 3;
        x3 := x1 + 6;

        c1 := pRGB24(ny1 + x1)^;
        c2 := pRGB24(ny1 + x3)^;
        c3 := pRGB24(ny2 + x2)^;
        c4 := pRGB24(ny3 + x1)^;
        c5 := pRGB24(ny3 + x3)^;

        r := (c1.R + c2.R + (c3.R * -12) + c4.R + c5.R) div -8;
        g := (c1.G + c2.G + (c3.G * -12) + c4.G + c5.G) div -8;
        b := (c1.B + c2.B + (c3.B * -12) + c4.B + c5.B) div -8;

        if r < 0 then r := 0 else if r > 255 then r := 255;
        if g < 0 then g := 0 else if g > 255 then g := 255;
        if b < 0 then b := 0 else if b > 255 then b := 255;

        pt1 := pRGB24(ny2 + x2);
        pt1.R := r;
        pt1.G := g;
        pt1.B := b;
      end;
      inc(ny1, iDst);
      inc(ny2, iDst);
      inc(ny3, iDst);
    end;
  end; // sharpening

  if SrcBmp <> FDib then
    FreeImage_Unload(SrcBmp);
  DestBitmap.Replace(DestBmp);
end;

function TFreeBitmap.PasteSubImage(Src: TFreeBitmap; Left, Top,
  Alpha: Integer): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_Paste(FDib, Src.Dib, Left, Top, Alpha);
    Change;
  end else
    Result := False;
end;

function TFreeBitmap.Replace(NewDib: PFIBITMAP): Boolean;
begin
  Result := False;
  if NewDib = nil then Exit;

  if not DoChanging(FDib, NewDib) and IsValid then
    FreeImage_Unload(FDib);

  FDib := NewDib;
  Result := True;
  Change;
end;

function TFreeBitmap.Rescale(NewWidth, NewHeight: Integer;
  Filter: FREE_IMAGE_FILTER; Dest: TFreeBitmap): Boolean;
var
  Bpp: Integer;
  DstDib: PFIBITMAP;
begin
  Result := False;

  if FDib <> nil then
  begin
    Bpp := FreeImage_GetBPP(FDib);

    if Bpp < 8 then
      if not ConvertToGrayscale then Exit
    else
    if Bpp = 16 then
    // convert to 24-bit
      if not ConvertTo24Bits then Exit;

    // perform upsampling / downsampling
    DstDib := FreeImage_Rescale(FDib, NewWidth, NewHeight, Filter);
    if Dest = nil then
      Result := Replace(DstDib)
    else
      Result := Dest.Replace(DstDib)
  end
end;

function TFreeBitmap.Rotate(Angle: Double): Boolean;
var
  Bpp: Integer;
  Rotated: PFIBITMAP;
begin
  Result := False;
  if IsValid then
  begin
    Bpp := FreeImage_GetBPP(FDib);
    if Bpp in [1, 8, 24, 32] then
    begin
      Rotated := FreeImage_RotateClassic(FDib, Angle);
      Result := Replace(Rotated);
    end
  end;
end;

function TFreeBitmap.RotateEx(Angle, XShift, YShift, XOrigin,
  YOrigin: Double; UseMask: Boolean): Boolean;
var
  Rotated: PFIBITMAP;
begin
  Result := False;
  if FDib <> nil then
  begin
    if FreeImage_GetBPP(FDib) >= 8 then
    begin
      Rotated := FreeImage_RotateEx(FDib, Angle, XShift, YShift, XOrigin, YOrigin, UseMask);
      Result := Replace(Rotated);
    end
  end;
end;

function TFreeBitmap.Save(const FileName: string; Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin
  Result := False;

  // try to guess the file format from the file extension
  fif := FreeImage_GetFIFFromFilename(PChar(Filename));
  if CanSave(fif) then
    Result := FreeImage_Save(fif, FDib, PChar(FileName), Flag);
end;

function TFreeBitmap.SaveToHandle(fif: FREE_IMAGE_FORMAT; IO: PFreeImageIO;
  Handle: fi_handle; Flag: Integer): Boolean;
begin
  Result := False;
  if CanSave(fif) then
    Result := FreeImage_SaveToHandle(fif, FDib, IO, Handle, Flag)
end;

function TFreeBitmap.SaveToMemory(fif: FREE_IMAGE_FORMAT;
  MemIO: TFreeMemoryIO; Flag: Integer): Boolean;
begin
  Result := False;

  if CanSave(fif) then
    Result := MemIO.Write(fif, FDib, Flag)
end;

function TFreeBitmap.SaveToStream(fif: FREE_IMAGE_FORMAT; Stream: TStream;
  Flag: Integer): Boolean;
var
  MemIO: TFreeMemoryIO;
  Data: PByte;
  Size: Cardinal;
begin
  MemIO := TFreeMemoryIO.Create;
  try
    Result := SaveToMemory(fif, MemIO, Flag);
    if Result then
    begin
      MemIO.Acquire(Data, Size);
      Stream.WriteBuffer(Data^, Size);
    end;
  finally
    MemIO.Free;
  end;
end;

function TFreeBitmap.SaveU(const FileName: WideString;
  Flag: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin
  Result := False;

  // try to guess the file format from the file extension
  fif := FreeImage_GetFIFFromFilenameU(PWideChar(Filename));
  if CanSave(fif) then
    Result := FreeImage_SaveU(fif, FDib, PWideChar(FileName), Flag);
end;

function TFreeBitmap.SetChannel(Bitmap: TFreeBitmap;
  Channel: FREE_IMAGE_COLOR_CHANNEL): Boolean;
begin
  if FDib <> nil then
  begin
    Result := FreeImage_SetChannel(FDib, Bitmap.FDib, Channel);
    Change;
  end
  else
    Result := False
end;

procedure TFreeBitmap.SetDib(Value: PFIBITMAP);
begin
  Replace(Value);
end;

function TFreeBitmap.SetFileBkColor(BkColor: PRGBQuad): Boolean;
begin
  Result := FreeImage_SetBackgroundColor(FDib, BkColor);
  Change;
end;

procedure TFreeBitmap.SetHorizontalResolution(Value: Double);
begin
  if IsValid then
  begin
    FreeImage_SetDotsPerMeterX(FDib, Trunc(Value * 100 + 0.5));
    Change;
  end;
end;

function TFreeBitmap.SetMetadata(Model: FREE_IMAGE_MDMODEL;
  const Key: string; Tag: TFreeTag): Boolean;
begin
  Result := FreeImage_SetMetadata(Model, FDib, PChar(Key), Tag.Tag);
end;

function TFreeBitmap.SetPixelColor(X, Y: Cardinal;
  Value: PRGBQUAD): Boolean;
begin
  Result := FreeImage_SetPixelColor(FDib, X, Y, Value);
  Change;
end;

function TFreeBitmap.SetPixelIndex(X, Y: Cardinal; Value: PByte): Boolean;
begin
  Result := FreeImage_SetPixelIndex(FDib, X, Y, Value);
  Change;
end;

function TFreeBitmap.SetSize(ImageType: FREE_IMAGE_TYPE; Width, Height,
  Bpp: Integer; RedMask, GreenMask, BlueMask: Cardinal): Boolean;
var
  Pal: PRGBQuad;
  I: Cardinal;
begin
  Result := False;

  if FDib <> nil then
    FreeImage_Unload(FDib);

  FDib := FreeImage_Allocate(Width, Height, Bpp, RedMask, GreenMask, BlueMask);
  if FDib = nil then Exit;

  if ImageType = FIT_BITMAP then
  case Bpp of
    1, 4, 8:
    begin
      Pal := FreeImage_GetPalette(FDib);
      for I := 0 to FreeImage_GetColorsUsed(FDib) - 1 do
      begin
        Pal.rgbBlue := I;
        Pal.rgbGreen := I;
        Pal.rgbRed := I;
        Inc(Pal, SizeOf(RGBQUAD));
      end;
    end;
  end;

  Result := True;
  Change;
end;

procedure TFreeBitmap.SetTransparencyTable(Table: PByte; Count: Integer);
begin
  FreeImage_SetTransparencyTable(FDib, Table, Count);
  Change;
end;

procedure TFreeBitmap.SetVerticalResolution(Value: Double);
begin
  if IsValid then
  begin
    FreeImage_SetDotsPerMeterY(FDib, Trunc(Value * 100 + 0.5));
    Change;
  end;
end;

function TFreeBitmap.SplitChannels(RedChannel, GreenChannel,
  BlueChannel: TFreeBitmap): Boolean;
begin
  if FDib <> nil then
  begin
    RedChannel.FDib := FreeImage_GetChannel(FDib, FICC_RED);
    GreenChannel.FDib := FreeImage_GetChannel(FDib, FICC_GREEN);
    BlueChannel.FDib := FreeImage_GetChannel(FDib, FICC_BLUE);
    Result := RedChannel.IsValid and GreenChannel.IsValid and BlueChannel.IsValid;
  end
  else
    Result := False  
end;

function TFreeBitmap.Threshold(T: Byte): Boolean;
var
  dib1: PFIBITMAP;
begin
  if FDib <> nil then
  begin
    dib1 := FreeImage_Threshold(FDib, T);
    Result := Replace(dib1);
  end
  else
    Result := False
end;

function TFreeBitmap.ToneMapping(TMO: FREE_IMAGE_TMO; FirstParam,
  SecondParam: Double): Boolean;
var
  NewDib: PFIBITMAP;
begin
  Result := False;
  if not IsValid then Exit;

  NewDib := FreeImage_ToneMapping(Fdib, TMO, FirstParam, SecondParam);
  Result := Replace(NewDib);
end;


{ TFreeMultiBitmap }

procedure TFreeMultiBitmap.AppendPage(Bitmap: TFreeBitmap);
begin
  if IsValid then
    FreeImage_AppendPage(FMPage, Bitmap.FDib);
end;

function TFreeMultiBitmap.Close(Flags: Integer): Boolean;
begin
  Result := FreeImage_CloseMultiBitmap(FMPage, Flags);
  FMPage := nil;
end;

constructor TFreeMultiBitmap.Create(KeepCacheInMemory: Boolean);
begin
  inherited Create;
  FMemoryCache := KeepCacheInMemory;
end;

procedure TFreeMultiBitmap.DeletePage(Page: Integer);
begin
  if IsValid then
    FreeImage_DeletePage(FMPage, Page);
end;

destructor TFreeMultiBitmap.Destroy;
begin
  if FMPage <> nil then Close;
  inherited;
end;

function TFreeMultiBitmap.GetLockedPageNumbers(var Pages,
  Count: Integer): Boolean;
begin
  Result := False;
  if not IsValid then Exit;
  Result := FreeImage_GetLockedPageNumbers(FMPage, Pages, Count)
end;

function TFreeMultiBitmap.GetPageCount: Integer;
begin
  Result := 0;
  if IsValid then
    Result := FreeImage_GetPageCount(FMPage)
end;

procedure TFreeMultiBitmap.InsertPage(Page: Integer; Bitmap: TFreeBitmap);
begin
  if IsValid then
    FreeImage_InsertPage(FMPage, Page, Bitmap.FDib);
end;

function TFreeMultiBitmap.IsValid: Boolean;
begin
  Result := FMPage <> nil
end;

procedure TFreeMultiBitmap.LockPage(Page: Integer; DestBitmap: TFreeBitmap);
begin
  if not IsValid then Exit;

  if Assigned(DestBitmap) then
  begin
    DestBitmap.Replace(FreeImage_LockPage(FMPage, Page));
  end;
end;

function TFreeMultiBitmap.MovePage(Target, Source: Integer): Boolean;
begin
  Result := False;
  if not IsValid then Exit;
  Result := FreeImage_MovePage(FMPage, Target, Source);
end;

function TFreeMultiBitmap.Open(const FileName: string; CreateNew,
  ReadOnly: Boolean; Flags: Integer): Boolean;
var
  fif: FREE_IMAGE_FORMAT;
begin
  Result := False;

  // try to guess the file format from the filename
  fif := FreeImage_GetFIFFromFilename(PChar(FileName));

  // check for supported file types
  if (fif <> FIF_UNKNOWN) and (not fif in [FIF_TIFF, FIF_ICO, FIF_GIF]) then
    Exit;

  // open the stream
  FMPage := FreeImage_OpenMultiBitmap(fif, PChar(FileName), CreateNew, ReadOnly, FMemoryCache, Flags);

  Result := FMPage <> nil;  
end;

procedure TFreeMultiBitmap.UnlockPage(Bitmap: TFreeBitmap;
  Changed: Boolean);
begin
  if IsValid then
  begin
    FreeImage_UnlockPage(FMPage, Bitmap.FDib, Changed);
    // clear the image so that it becomes invalid.
    // don't use Bitmap.Clear method because it calls FreeImage_Unload
    // just clear the pointer
    Bitmap.FDib := nil;
    Bitmap.Change;
  end;
end;

{ TFreeMemoryIO }

function TFreeMemoryIO.Acquire(var Data: PByte;
  var SizeInBytes: DWORD): Boolean;
begin
  Result := FreeImage_AcquireMemory(FHMem, Data, SizeInBytes);
end;

constructor TFreeMemoryIO.Create(Data: PByte; SizeInBytes: DWORD);
begin
  inherited Create;
  FHMem := FreeImage_OpenMemory(Data, SizeInBytes);
end;

destructor TFreeMemoryIO.Destroy;
begin
  FreeImage_CloseMemory(FHMem);
  inherited;
end;

function TFreeMemoryIO.GetFileType: FREE_IMAGE_FORMAT;
begin
  Result := FreeImage_GetFileTypeFromMemory(FHMem);
end;

function TFreeMemoryIO.IsValid: Boolean;
begin
  Result := FHMem <> nil
end;

function TFreeMemoryIO.Read(fif: FREE_IMAGE_FORMAT;
  Flag: Integer): PFIBITMAP;
begin
  Result := FreeImage_LoadFromMemory(fif, FHMem, Flag)
end;

function TFreeMemoryIO.Seek(Offset: Longint; Origin: Word): Boolean;
begin
  Result := FreeImage_SeekMemory(FHMem, Offset, Origin)
end;

function TFreeMemoryIO.Tell: Longint;
begin
  Result := FreeImage_TellMemory(FHMem)
end;

function TFreeMemoryIO.Write(fif: FREE_IMAGE_FORMAT; dib: PFIBITMAP;
  Flag: Integer): Boolean;
begin
  Result := FreeImage_SaveToMemory(fif, dib, FHMem, Flag)
end;

{ TFreeTag }

function TFreeTag.Clone: TFreeTag;
var
  CloneTag: PFITAG;
begin
  Result := nil;
  if not IsValid then Exit;

  CloneTag := FreeImage_CloneTag(FTag);
  Result := TFreeTag.Create(CloneTag);
end;

constructor TFreeTag.Create(ATag: PFITAG);
begin
  inherited Create;

  if ATag <> nil then
    FTag := ATag
  else
    FTag := FreeImage_CreateTag;
end;

destructor TFreeTag.Destroy;
begin
  if IsValid then
    FreeImage_DeleteTag(FTag);
    
  inherited;
end;

function TFreeTag.GetCount: Cardinal;
begin
  Result := 0;
  if not IsValid then Exit;

  Result := FreeImage_GetTagCount(FTag);
end;

function TFreeTag.GetDescription: string;
begin
  Result := '';
  if not IsValid then Exit;

  Result := FreeImage_GetTagDescription(FTag);
end;

function TFreeTag.GetID: Word;
begin
  Result := 0;
  if not IsValid then Exit;

  Result := FreeImage_GetTagID(FTag);
end;

function TFreeTag.GetKey: string;
begin
  Result := '';
  if not IsValid then Exit;

  Result := FreeImage_GetTagKey(FTag);
end;

function TFreeTag.GetLength: Cardinal;
begin
  Result := 0;
  if not IsValid then Exit;

  Result := FreeImage_GetTagLength(FTag);
end;

function TFreeTag.GetTagType: FREE_IMAGE_MDTYPE;
begin
  Result := FIDT_NOTYPE;
  if not IsValid then Exit;

  Result := FreeImage_GetTagType(FTag);
end;

function TFreeTag.GetValue: Pointer;
begin
  Result := nil;
  if not IsValid then Exit;

  Result := FreeImage_GetTagValue(FTag);
end;

function TFreeTag.IsValid: Boolean;
begin
  Result := FTag <> nil;
end;

procedure TFreeTag.SetCount(const Value: Cardinal);
begin
  if IsValid then
    FreeImage_SetTagCount(FTag, Value);
end;

procedure TFreeTag.SetDescription(const Value: string);
begin
  if IsValid then
    FreeImage_SetTagDescription(FTag, PChar(Value));
end;

procedure TFreeTag.SetID(const Value: Word);
begin
  if IsValid then
    FreeImage_SetTagID(FTag, Value);
end;

procedure TFreeTag.SetKey(const Value: string);
begin
  if IsValid then
    FreeImage_SetTagKey(FTag, PChar(Value));
end;

procedure TFreeTag.SetLength(const Value: Cardinal);
begin
  if IsValid then
    FreeImage_SetTagLength(FTag, Value);
end;

procedure TFreeTag.SetTagType(const Value: FREE_IMAGE_MDTYPE);
begin
  if IsValid then
    FreeImage_SetTagType(FTag, Value);
end;

procedure TFreeTag.SetValue(const Value: Pointer);
begin
  if IsValid then
    FreeImage_SetTagValue(FTag, Value);
end;

function TFreeTag.ToString(Model: FREE_IMAGE_MDMODEL; Make: PChar): string;
begin
  Result := FreeImage_TagToString(Model, FTag, Make);
end;

end.
