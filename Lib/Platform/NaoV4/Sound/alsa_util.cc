#include "alsa_util.h"

// audio parameters
#include "sound_params.h"

void print_alsa_lib_version() {
  printf("ALSA library version: %s\n", SND_LIB_VERSION_STR);
}

void print_alsa_formats() {
  int val;

  printf("\nPCM stream types:\n");
  for (val = 0; val <= SND_PCM_STREAM_LAST; val++) {
    printf("  %s\n", snd_pcm_stream_name((snd_pcm_stream_t)val));
  }

  printf("\nPCM access types:\n");
  for (val = 0; val <= SND_PCM_ACCESS_LAST; val++) {
    printf("  %s\n", snd_pcm_access_name((snd_pcm_access_t)val));
  }

  printf("\nPCM formats:\n");
  for (val = 0; val <= SND_PCM_FORMAT_LAST; val++) {
    if (snd_pcm_format_name((snd_pcm_format_t)val) != NULL) {
      printf("  %s (%s)\n", snd_pcm_format_name((snd_pcm_format_t)val),
                            snd_pcm_format_description((snd_pcm_format_t)val));
    }
  }

  printf("\nPCM subformats:\n");
  for (val = 0; val <= SND_PCM_SUBFORMAT_LAST; val++) {
    printf("  %s (%s)\n", snd_pcm_subformat_name((snd_pcm_subformat_t)val),
                          snd_pcm_subformat_description((snd_pcm_subformat_t)val));
  }

  printf("\nPCM states:\n");
  for (val = 0; val <= SND_PCM_STATE_LAST; val++) {
    printf("  %s\n", snd_pcm_state_name((snd_pcm_state_t)val));
  }
}


int open_transmitter(snd_pcm_t **handle, const char *name) {
  // open transmitter (speakers)
  int ret = snd_pcm_open(handle, name, SND_PCM_STREAM_PLAYBACK, 0);
  if (ret < 0) {
    fprintf(stderr, "unable to open transmitter pcm device: %s\n", snd_strerror(ret));
    return ret;
  }

  return 0;
}


int open_receiver(snd_pcm_t **handle, const char *name) {
  // open receiver (microphones)
  int ret = snd_pcm_open(handle, name, SND_PCM_STREAM_CAPTURE, 0);
  if (ret < 0) {
    fprintf(stderr, "unable to open receiver pcm device: %s\n", snd_strerror(ret));
    return ret;
  }

  return 0;
}


int set_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params) {
  int ret;
  int dir = 1;
  snd_pcm_uframes_t frames;

  // fill it in with default values
  ret = snd_pcm_hw_params_any(handle, params);
  if (ret < 0) {
    fprintf(stderr, "unable to initialize parameter object: %s\n", snd_strerror(ret));
    return ret;
  }

  // interleaved mode
  ret = snd_pcm_hw_params_set_access(handle, params, SND_PCM_ACCESS_RW_INTERLEAVED);
  if (ret < 0) {
    fprintf(stderr, "unable to set access type: %s\n", snd_strerror(ret));
    return ret;
  }
  // signed 16-bit little-endian format
  ret = snd_pcm_hw_params_set_format(handle, params, SND_PCM_FORMAT_S16_LE);
  if (ret < 0) {
    fprintf(stderr, "unable to set sample format: %s\n", snd_strerror(ret));
    return ret;
  }
  // two channels (stereo)
  ret = snd_pcm_hw_params_set_channels(handle, params, NCHANNEL);
  if (ret < 0) {
    fprintf(stderr, "unable to set number of channels: %s\n", snd_strerror(ret));
    return ret;
  }
  // sampling rate
  //  dir - sub unit direction (not sure what that actually means
  ret = snd_pcm_hw_params_set_rate(handle, params, SAMPLING_RATE, dir);
  if (ret < 0) {
    fprintf(stderr, "unable to set sample rate: %s\n", snd_strerror(ret));
    return ret;
  }
  // TODO: is it actually possible to set the frame size on the nao?
  /*
  // set period size
  //ret = snd_pcm_hw_params_set_period_size_near(handle, params, &frames, &dir);
  ret = snd_pcm_hw_params_set_period_size(handle, params, FRAMES_PER_PERIOD, 0);
  if (ret < 0) {
    fprintf(stderr, "unable to set sample rate: %s\n", snd_strerror(ret));
    return ret;
  }
  */
  // write the parameters to the driver
  ret = snd_pcm_hw_params(handle, params);
  if (ret < 0) {
    fprintf(stderr, "unable to set hw parameters: %s\n", snd_strerror(ret));
    return ret;
  }

  return 0;
}

void print_device_params(snd_pcm_t *handle, snd_pcm_hw_params_t *params, int full) {
  unsigned int val;
  unsigned int val2;
  int dir;
  snd_pcm_uframes_t frames;
  snd_pcm_format_t fmt;

  // display information about th e PCM interface

  // handle name
  printf("PCM handle name = '%s'\n", snd_pcm_name(handle));
  // device state
  printf("PCM state = %s\n", snd_pcm_state_name(snd_pcm_state(handle)));
  // access type
  snd_pcm_hw_params_get_access(params, (snd_pcm_access_t *)&val);
  printf("access type = %s\n", snd_pcm_access_name((snd_pcm_access_t) val));
  // pcm format
  snd_pcm_hw_params_get_format(params, &fmt);
  printf("format = '%s' (%s)\n", snd_pcm_format_name((snd_pcm_format_t)fmt),
                                 snd_pcm_format_description((snd_pcm_format_t)fmt));
  // number of channels
  snd_pcm_hw_params_get_channels(params, &val);
  printf("channels = %d\n", val);
  // sampling rate
  snd_pcm_hw_params_get_rate(params, &val, &dir);
  printf("rate = %d bps\n", val);
  // period time
  snd_pcm_hw_params_get_period_time(params, &val, &dir);
  printf("period time = %d us\n", val);
  // period size
  snd_pcm_hw_params_get_period_size(params, &frames, &dir);
  printf("period size = %d frames\n", (int)frames);
  // can pause
  val = snd_pcm_hw_params_can_pause(params);
  printf("can pause = %d\n", val);
  // can resume
  val = snd_pcm_hw_params_can_resume(params);
  printf("can resume = %d\n", val);

  if (full) {
    // buffer time
    snd_pcm_hw_params_get_buffer_time(params, &val, &dir);
    printf("buffer time = %d us\n", val);
    // buffer size
    snd_pcm_hw_params_get_buffer_size(params, (snd_pcm_uframes_t *)&val);
    printf("buffer size = %d frames\n", val);
    // number of periods
    snd_pcm_hw_params_get_periods(params, &val, &dir);
    printf("periods per buffer = %d\n", val);
    // sampling rate
    snd_pcm_hw_params_get_rate_numden(params, &val, &val2);
    printf("exact rate = %d/%d bps\n", val, val2);
    // significant bits
    val = snd_pcm_hw_params_get_sbits(params);
    printf("significant bits = %d\n", val);
    // tick time (depricated)
    //snd_pcm_hw_params_get_tick_time(params, &val, &dir);
    //printf("tick time = %d us\n", val);
    // is batch
    val = snd_pcm_hw_params_is_batch(params);
    printf("is batch = %d\n", val);
    // is block transfer
    val = snd_pcm_hw_params_is_block_transfer(params);
    printf("is block transfer = %d\n", val);
    // is double
    val = snd_pcm_hw_params_is_double(params);
    printf("is double = %d\n", val);
    // is half duplex
    val = snd_pcm_hw_params_is_half_duplex(params);
    printf("is half duplex = %d\n", val);
    // is joint duplex
    val = snd_pcm_hw_params_is_joint_duplex(params);
    printf("is joint duplex = %d\n", val);
    // can overrange?
    val = snd_pcm_hw_params_can_overrange(params);
    printf("can overrange = %d\n", val);
    // can mmap sample resolution
    val = snd_pcm_hw_params_can_mmap_sample_resolution(params);
    printf("can mmap sample resolution = %d\n", val);
    // can sync start
    val = snd_pcm_hw_params_can_sync_start(params);
    printf("can sync start = %d\n", val);
  }
}


int pause_device(snd_pcm_t *handle) {
  int rc = snd_pcm_pause(handle, 1);
  if (rc < 0) {
    fprintf(stderr, "unable to pause device: %s\n", snd_strerror(rc));
  }
  return rc;
}


int enable_device(snd_pcm_t *handle) {
  int rc = snd_pcm_pause(handle, 0);
  if (rc < 0) {
    fprintf(stderr, "unable to enable device: %s\n", snd_strerror(rc));
  }
  return rc;
}

int set_capture_volume(int volume, const char *card, const char *selemName) {
  int ret;
  long vmin;
  long vmax;
  snd_mixer_t *mixer;
  snd_mixer_selem_id_t *selemid;

  // open mixer (mode is not used by alsa)
  int mode = 0;
  ret = snd_mixer_open(&mixer, mode);
  if (ret < 0) {
    fprintf(stderr, "unable to open mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // attach mixer to the sound card
  ret = snd_mixer_attach(mixer, card);
  if (ret < 0) {
    fprintf(stderr, "unable to attach card to mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // register the mixer 
  ret = snd_mixer_selem_register(mixer, NULL, NULL);
  if (ret < 0) {
    fprintf(stderr, "unable to register mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // load the mixer
  ret = snd_mixer_load(mixer);
  if (ret < 0) {
    fprintf(stderr, "unable to load mixer: %s\n", snd_strerror(ret));
    return ret;
  }

  // create new sound element object
  snd_mixer_selem_id_alloca(&selemid);
  if (selemid == NULL) {
    fprintf(stderr, "unable to allocate selemid.\n");
    return ret;
  }
  snd_mixer_selem_id_set_index(selemid, 0);
  snd_mixer_selem_id_set_name(selemid, selemName);
  snd_mixer_elem_t* elem = snd_mixer_find_selem(mixer, selemid);
  if (elem == NULL) {
    fprintf(stderr, "unable to find selem.\n"); 
    return ret;
  }

  // get playback volume range
  ret = snd_mixer_selem_get_capture_volume_range(elem, &vmin, &vmax);
  if (ret < 0) {
    fprintf(stderr, "unable to get capture volume range: %s\n", snd_strerror(ret));
    return ret;
  }
  ret = snd_mixer_selem_set_capture_volume_all(elem, vmax*((float)volume/100));
  if (ret < 0) {
    fprintf(stderr, "unable to set capture volume: %s\n", snd_strerror(ret));
    return ret;
  }

  // free the sound element object
  snd_mixer_selem_id_free(selemid);
  // close the mixer
  ret = snd_mixer_close(mixer);
  if (ret < 0) {
    fprintf(stderr, "unable to close mixer: %s\n", snd_strerror(ret));
    return ret;
  }

  return 0;
}


int set_playback_volume(int volume, const char *card, const char *selemName) {
  int ret;
  long vmin;
  long vmax;
  snd_mixer_t *mixer;
  snd_mixer_selem_id_t *selemid;

  // open mixer (mode is not used by alsa)
  int mode = 0;
  ret = snd_mixer_open(&mixer, mode);
  if (ret < 0) {
    fprintf(stderr, "unable to open mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // attach mixer to the sound card
  ret = snd_mixer_attach(mixer, card);
  if (ret < 0) {
    fprintf(stderr, "unable to attach card to mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // register the mixer 
  ret = snd_mixer_selem_register(mixer, NULL, NULL);
  if (ret < 0) {
    fprintf(stderr, "unable to register mixer: %s\n", snd_strerror(ret));
    return ret;
  }
  // load the mixer
  ret = snd_mixer_load(mixer);
  if (ret < 0) {
    fprintf(stderr, "unable to load mixer: %s\n", snd_strerror(ret));
    return ret;
  }

  // create new sound element object
  snd_mixer_selem_id_alloca(&selemid);
  if (selemid == NULL) {
    fprintf(stderr, "unable to allocate selemid.\n");
    return ret;
  }
  snd_mixer_selem_id_set_index(selemid, 0);
  snd_mixer_selem_id_set_name(selemid, selemName);
  snd_mixer_elem_t* elem = snd_mixer_find_selem(mixer, selemid);
  if (elem == NULL) {
    fprintf(stderr, "unable to find selem.\n"); 
    return ret;
  }

  // get playback volume range
  ret = snd_mixer_selem_get_playback_volume_range(elem, &vmin, &vmax);
  if (ret < 0) {
    fprintf(stderr, "unable to get playback volume range: %s\n", snd_strerror(ret));
    return ret;
  }
  ret = snd_mixer_selem_set_playback_volume_all(elem, vmax*((float)volume/100));
  if (ret < 0) {
    fprintf(stderr, "unable to set playback volume: %s\n", snd_strerror(ret));
    return ret;
  }

  // free the sound element object
  snd_mixer_selem_id_free(selemid);
  // close the mixer
  ret = snd_mixer_close(mixer);
  if (ret < 0) {
    fprintf(stderr, "unable to close mixer: %s\n", snd_strerror(ret));
    return ret;
  }

  return 0;
}

