#ifndef __SOUND_PARAMS_H__
#define __SOUND_PARAMS_H__

// number of channels (stereo)
static const int NCHANNEL = 2;
// sampling rate
static const int SAMPLING_RATE = 16000;

// 1 sample = 2 bytes
static const int BYTES_PER_SAMPLE = 2;
// 1 frame = 2 samples = 1 left and 1 right value
static const int SAMPLES_PER_FRAME = 2;
// 1 period = x frames
// NOTE: the nao driver will not allow any other period size that 341 (per channel)
static const int FRAMES_PER_PERIOD = 341;
// number of total frames
static const int NFRAME = FRAMES_PER_PERIOD;
// number of samples per period (number of elements in each audio sequence)
static const int ASAMPLE = (FRAMES_PER_PERIOD*SAMPLES_PER_FRAME);

// number of frames in audio segment we want to process
static const int PFRAME = 512;
// size of audio segment we want to process
static const int PSAMPLE = (PFRAME*SAMPLES_PER_FRAME);

#endif
