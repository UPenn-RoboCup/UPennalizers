#ifndef __ALSA_UTIL_H__
#define __ALSA_UTIL_H__

// use the newer alsa api
#define ALSA_PCM_NEW_HW_PARAMS_API
#include <alsa/asoundlib.h>

/**
 * print the alsa library version
 */
void print_alsa_lib_version();

/**
 * print out available alsa formats
 */
void print_alsa_formats();

/**
 * initializes an audio transmitter device
 *
 * **handle - pointer to a alsa handle pointer
 * name - optional device name
 * return - 0 on success
 */
int open_transmitter(snd_pcm_t **handle, const char *name = "default");

/**
 * initializes an audio reciever device
 *
 * **handle - pointer to a alsa handle pointer
 * name - optional device name
 * return - 0 on success
 */
int open_receiver(snd_pcm_t **handle, const char *name = "default");

/**
 * sets the audio parameters from the given defines
 *
 * handle - alsa device handle
 * params - alsa parameter object
 *
 * return - 0 on success 
 */
int set_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params);

/**
 * prints out useful audio parameters for the given device
 *
 * handle - alsa device handle
 * params - alsa parameter object
 * full - flag indicating if all parameters should be printed,
 *          otherwise only a few important ones are
 */
void print_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params, int full);

/**
 * pauses a pcm audio device
 *
 * *handle - alsa handle for the device
 * return - <0 on error
 */
int pause_device(snd_pcm_t *handle);

/**
 * enables/resumes a paused pcm audio device
 *
 * *handle - alsa handle for the device
 * return - <0 on error
 */
int enable_device(snd_pcm_t *handle);

/**
 * set volume for playback
 *
 * volume - [0..100] volume to set
 * return - 0 on success
 */
int set_playback_volume(int volume, const char *card, const char *selemName);

/**
 * set volume for capture 
 *
 * volume - [0..100] volume to set
 * return - 0 on success
 */
int set_capture_volume(int volume, const char *card, const char *selemName);

#endif
