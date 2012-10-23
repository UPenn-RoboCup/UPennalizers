/**
 * program that will write the PCM audio signal to standard out
 *
 * usage:
 *  ./record > audio_signal
 *
 * The output PCM array will have the following format:
 *  - 16000 Hz
 *  - 2 channel, interleaved
 *  - signed 16bit values
 *  - little endian
 */

#include "alsa_util.h"
#include "sound_params.h"

snd_pcm_t *rx;
snd_pcm_hw_params_t *rxParams;

int main() {
  fprintf(stderr, "ALSA library version: %s\n", SND_LIB_VERSION_STR);

  int rc;
  int ret;
  int dir;
  int size;
  unsigned int val;
  long loops;
  char *buffer;
  snd_pcm_uframes_t frames;

  // open PCM device for capture
  fprintf(stderr, "opening receiver device..."); fflush(stderr);
  open_receiver(&rx);
  fprintf(stderr, "done\n");

  // allocate parameters struct
  fprintf(stderr, "setting receiver parameters..."); fflush(stderr);
  snd_pcm_hw_params_alloca(&rxParams);
  if (rxParams == NULL) {
    fprintf(stderr, "unable to allocate receiver parameter object.\n");
    return -1;
  }
  ret = set_device_params(rx, rxParams);
  if (ret < 0) {
    fprintf(stderr, "error setting receiver parameters.\n");
    return ret;
  }
  fprintf(stderr, "done\n");


  // allocate buffer for 1 period
  snd_pcm_hw_params_get_period_size(rxParams, &frames, &dir);
  // 4 bytes per frame: 2 bytes per sample, 2 channels
  size = frames * 4; 
  buffer = (char *)malloc(size);

  // TODO: this should be a command line argument or based on <CTRL>+C
  //loop for 5 seconds
  snd_pcm_hw_params_get_period_time(rxParams, &val, &dir);
  // number of loops = 5 sec (in us) divided by period time
  loops = 5000000 / val;

  while (loops > 0) {
    loops -= 1;

    rc = snd_pcm_readi(rx, buffer, frames);
    if (rc == -EPIPE) {
      // EPIPE mean overrun
      fprintf(stderr, "overrun occurred\n");
      snd_pcm_prepare(rx);
    } else if (rc < 0) {
      fprintf(stderr, "error from read: %s\n", snd_strerror(rc));
    } else if (rc != (int)frames) {
      fprintf(stderr, "short read: read %d frames\n", rc);
    }

    rc = write(1, buffer, size);
    if (rc != size) {
      fprintf(stderr, "short write: wrote %d bytes\n", rc);
    }
  }

  snd_pcm_drain(rx);

  fprintf(stderr, "closing device..."); fflush(stderr);
  snd_pcm_close(rx);
  fprintf(stderr, "done\n");

  free(buffer);

  return 0;
}

