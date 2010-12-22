/* UltraStar Deluxe - Karaoke Game
 *
 * UltraStar Deluxe is the legal property of its developers, whose names
 * are too numerous to list here. Please refer to the COPYRIGHT
 * file distributed with this source distribution.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING. If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 *
 * $URL$
 * $Id$
 */
#ifndef _PLUGIN_CORE_H_
#define _PLUGIN_CORE_H_

#ifdef _MSC_VER
typedef __int8            int8_t;
typedef __int16           int16_t;
typedef __int32           int32_t;
typedef __int64           int64_t;
typedef unsigned __int8   uint8_t;
typedef unsigned __int16  uint16_t;
typedef unsigned __int32  uint32_t;
typedef unsigned __int64  uint64_t;
#ifdef _WIN64
   typedef __int64           intptr_t;
   typedef unsigned __int64  uintptr_t;
#else // !_WIN64
   typedef _W64 int               intptr_t;
   typedef _W64 unsigned int      uintptr_t;
#endif // _WIN64
#else
#include <stdint.h>
#endif

#ifdef _WIN32
#include <windows.h>
#endif

/*
 * C Interface
 */

#ifdef __cplusplus
extern "C" {
#endif

/* declaration for export */
#if defined(_WIN32)
# define DECLSPEC_EXPORT	__declspec(dllexport)
#else
# if defined(__GNUC__) && __GNUC__ >= 4
#  define DECLSPEC_EXPORT	__attribute__ ((visibility("default")))
# else
#  define DECLSPEC_EXPORT
# endif
#endif

/* use C calling convention */
#ifndef CDECL
#if defined(_WIN32) && !defined(__GNUC__)
#define CDECL __cdecl
#else
#define CDECL
#endif
#endif /* CDECL */

#define PLUGIN_CALL CDECL

/* VERSION: AAABBBCCC (A: Major, B: Minor, C: Revision) */
#define MAKE_VERSION(a,b,c) ((((a) * 1000 + (b)) * 1000) + (c))

#ifndef _WIN32
/* already defined in windows.h */
typedef enum { FALSE , TRUE } BOOL;
#endif

typedef enum log_level {
	LOG_DEBUG,
	LOG_INFO,
	LOG_STATUS,
	LOG_WARN,
	LOG_ERROR,
	LOG_CRITICAL
} log_level;

typedef struct{} fileStream_t;
typedef struct{} cond_t;
typedef struct{} mutex_t;
typedef struct{} thread_t;

#define FILE_OPEN_MODE_READ  0x01
#define FILE_OPEN_MODE_WRITE 0x02
#define FILE_OPEN_MODE_READ_WRITE (FILE_OPEN_MODE_READ | FILE_OPEN_MODE_WRITE)

/* returned by condWaitTimeout() if a timeout occurs. */
#define MUTEX_TIMEDOUT 1

typedef struct pluginCore_t {
	int version;

	void PLUGIN_CALL (*log)(int level, const char *msg, const char *context);
	uint32_t PLUGIN_CALL (*ticksMillis)();

	fileStream_t* PLUGIN_CALL (*fileOpen)(const char *utf8Filename, int mode);
	void PLUGIN_CALL (*fileClose)(fileStream_t *stream);
	int64_t PLUGIN_CALL (*fileRead)(fileStream_t *stream, uint8_t *buf, int size);
	int64_t PLUGIN_CALL (*fileWrite)(fileStream_t *stream, const uint8_t *buf, int size);
	int64_t PLUGIN_CALL (*fileSeek)(fileStream_t *stream, int64_t pos, int whence);
	int64_t PLUGIN_CALL (*fileSize)(fileStream_t *stream);

	thread_t* PLUGIN_CALL (*threadCreate)(int (PLUGIN_CALL *fn)(void *), void *data);
	uint32_t PLUGIN_CALL (*threadCurrentID)();
	uint32_t PLUGIN_CALL (*threadGetID)(thread_t *thread);
	void PLUGIN_CALL (*threadWait)(thread_t *thread, int *status);
	void PLUGIN_CALL (*threadSleep)(uint32_t millisecs);

	mutex_t* PLUGIN_CALL (*mutexCreate)();
	void PLUGIN_CALL (*mutexDestroy)(mutex_t *mutex);
	int PLUGIN_CALL (*mutexLock)(mutex_t *mutex);
	int PLUGIN_CALL (*mutexUnlock)(mutex_t *mutex);

	cond_t* PLUGIN_CALL (*condCreate)();
	void PLUGIN_CALL (*condDestroy)(cond_t *cond);
	int PLUGIN_CALL (*condSignal)(cond_t *cond);
	int PLUGIN_CALL (*condBroadcast)(cond_t *cond);
	int PLUGIN_CALL (*condWait)(cond_t *cond, mutex_t *mutex);
	int PLUGIN_CALL (*condWaitTimeout)(cond_t *cond, mutex_t *mutex, uint32_t ms);
} pluginCore_t;

typedef enum audioSampleFormat_t {
	AUDIO_SAMPLE_FORMAT_UNKNOWN, // unknown format
	AUDIO_SAMPLE_FORMAT_U8,      // unsigned 8 bits
	AUDIO_SAMPLE_FORMAT_S8,      // signed 8 bits
	AUDIO_SAMPLE_FORMAT_U16LSB,  // unsigned 16 bits (endianness: LSB)
	AUDIO_SAMPLE_FORMAT_S16LSB,  // signed 16 bits (endianness: LSB)
	AUDIO_SAMPLE_FORMAT_U16MSB,  // unsigned 16 bits (endianness: MSB)
	AUDIO_SAMPLE_FORMAT_S16MSB,  // signed 16 bits (endianness: MSB)
	AUDIO_SAMPLE_FORMAT_U16,     // unsigned 16 bits (endianness: System)
	AUDIO_SAMPLE_FORMAT_S16,     // signed 16 bits (endianness: System)
	AUDIO_SAMPLE_FORMAT_S32,     // signed 32 bits (endianness: System)
	AUDIO_SAMPLE_FORMAT_FLOAT,   // float
	AUDIO_SAMPLE_FORMAT_DOUBLE   // double
} audioSampleFormat_t;

// Size of one sample (one channel only) in bytes
static const int g_audioSampleSize[] = {
	0,        // Unknown
	1, 1,     // U8, S8
	2, 2,     // U16LSB, S16LSB
	2, 2,     // U16MSB, S16MSB
	2, 2,     // U16,    S16
	3,        // S24
	4,        // S32
	4,        // Float
};

typedef struct audioFormatInfo_t {
    double sampleRate;
    uint8_t channels;
    audioSampleFormat_t format;
} audioFormatInfo_t;

typedef struct{} audioDecodeStream_t;
typedef struct{} audioConvertStream_t;
typedef struct{} videoDecodeStream_t;

typedef struct audioDecoderInfo_t {
	int priority;
	BOOL PLUGIN_CALL (*init)();
	BOOL PLUGIN_CALL (*finalize)();
	audioDecodeStream_t* PLUGIN_CALL (*open)(const char *filename);
	void PLUGIN_CALL (*close)(audioDecodeStream_t *stream);
	double PLUGIN_CALL (*getLength)(audioDecodeStream_t *stream);
	void PLUGIN_CALL (*getAudioFormatInfo)(audioDecodeStream_t *stream, audioFormatInfo_t *info);
	double PLUGIN_CALL (*getPosition)(audioDecodeStream_t *stream);
	void PLUGIN_CALL (*setPosition)(audioDecodeStream_t *stream, double time);
	BOOL PLUGIN_CALL (*getLoop)(audioDecodeStream_t *stream);
	void PLUGIN_CALL (*setLoop)(audioDecodeStream_t *stream, BOOL enabled);
	BOOL PLUGIN_CALL (*isEOF)(audioDecodeStream_t *stream);
	BOOL PLUGIN_CALL (*isError)(audioDecodeStream_t *stream);
	int PLUGIN_CALL (*readData)(audioDecodeStream_t *stream, uint8_t *buffer, int bufferSize);
} audioDecoderInfo_t;

typedef struct audioConverterInfo_t {
	int priority;
	BOOL PLUGIN_CALL (*init)();
	BOOL PLUGIN_CALL (*finalize)();
	audioConvertStream_t* PLUGIN_CALL (*open)(audioFormatInfo_t *inputFormat,
			audioFormatInfo_t *outputFormat);
	void PLUGIN_CALL (*close)(audioConvertStream_t *stream);
	int PLUGIN_CALL (*convert)(audioConvertStream_t *stream,
			uint8_t *input, uint8_t *output, int *numSamples);
	int PLUGIN_CALL (*getOutputBufferSize)(audioConvertStream_t *stream, int inputSize);
    double PLUGIN_CALL (*getRatio)(audioConvertStream_t *stream);
} audioConverterInfo_t;

typedef enum videoFrameFormat_t {
	FRAME_FORMAT_UNKNOWN,
	FRAME_FORMAT_RGB,   // packed RGB  24bpp (R:8,G:8,B:8)
	FRAME_FORMAT_RGBA,	// packed RGBA 32bpp (R:8,G:8,B:8,A:8)
	FRAME_FORMAT_BGR,   // packed RGB  24bpp (B:8,G:8,R:8)
	FRAME_FORMAT_BGRA,	// packed BGRA 32bpp (B:8,G:8,R:8,A:8)
} videoFrameFormat_t;

const int videoFrameFormatSize[5] = {
	-1, 3, 4, 3, 4
};

typedef struct videoFrameInfo_t {
	int width;
	int height;
	double aspect;
	videoFrameFormat_t format;
} videoFrameInfo_t;

typedef struct videoDecoderInfo_t {
	int priority;
	BOOL PLUGIN_CALL (*init)();
	BOOL PLUGIN_CALL (*finalize)();
	videoDecodeStream_t* PLUGIN_CALL (*open)(const char *filename, videoFrameFormat_t format);
	void PLUGIN_CALL (*close)(videoDecodeStream_t *stream);
	void PLUGIN_CALL (*setLoop)(videoDecodeStream_t *stream, BOOL enable);
	BOOL PLUGIN_CALL (*getLoop)(videoDecodeStream_t *stream);
	void PLUGIN_CALL (*setPosition)(videoDecodeStream_t *stream, double time);
	double PLUGIN_CALL (*getPosition)(videoDecodeStream_t *stream);
	void PLUGIN_CALL (*getFrameInfo)(videoDecodeStream_t *stream, videoFrameInfo_t *info);
	uint8_t* PLUGIN_CALL (*getFrame)(videoDecodeStream_t *stream, long double time);
} videoDecoderInfo_t;

typedef struct pluginInfo_t {
	int version;
	const char *name;
	BOOL PLUGIN_CALL (*initialize)();
	BOOL PLUGIN_CALL (*finalize)();
	const audioDecoderInfo_t *audioDecoder;
	const audioConverterInfo_t *audioConverter;
	const videoDecoderInfo_t *videoDecoder;
} pluginInfo_t;


// plugin entry function (must be implemented by the plugin)
extern DECLSPEC_EXPORT const pluginInfo_t* PLUGIN_CALL Plugin_register(const pluginCore_t *core);

// must be provided by the plugin and initialized on plugin initialization
extern const pluginCore_t *pluginCore;

BOOL pluginInitCore(const pluginCore_t *core);

#ifdef __cplusplus
}
#endif

#endif /* _PLUGIN_CORE_H_ */