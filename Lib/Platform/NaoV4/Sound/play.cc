/**
 * program that will play a PCM audio signal from standard in
 *
 * usage:
 *  ./play < audio_signal
 *
 * The PCM array should have the following format:
 *  - 16000 Hz
 *  - 2 channel, interleaved
 *  - signed 16bit values
 *  - little endian
 */

#include "alsa_util.h"
#include "sound_params.h"

snd_pcm_t *tx;
snd_pcm_hw_params_t *txParams;


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

  // open PCM device for playback
  fprintf(stderr, "opening transmitter device..."); fflush(stderr);
  open_transmitter(&tx);
  fprintf(stderr, "done\n");

  // allocate parameters struct
  fprintf(stderr, "setting transmitter parameters..."); fflush(stderr);
  snd_pcm_hw_params_alloca(&txParams);
  if (txParams == NULL) {
    fprintf(stderr, "unable to allocate transmitter parameter object.\n");
    return -1;
  }
  ret = set_device_params(tx, txParams);
  if (ret < 0) {
    fprintf(stderr, "error setting transmitter parameters.\n");
    return ret;
  }
  fprintf(stderr, "done\n");


  // allocate buffer for 1 period
  snd_pcm_hw_params_get_period_size(txParams, &frames, &dir);
  // 4 bytes per frame: 2 bytes per sample, 2 channels
  size = frames * 4; 
  buffer = (char *)malloc(size);

  // TODO: this should be based on the file size
  //loop for 5 seconds
  snd_pcm_hw_params_get_period_time(txParams, &val, &dir);
  // number of loops = 5 sec (in us) divided by period time
  loops = 5000000 / val;

  while (loops > 0) {
    loops -= 1;

    rc = read(0, buffer, size);
    if (rc == 0) {
      fprintf(stderr, "end of file on input\n");
      break;
    } else if (rc != size) {
      fprintf(stderr, "short read: read %d bytes\n", rc);
    }

    rc = snd_pcm_writei(tx, buffer, frames);
    if (rc == -EPIPE) {
      // EPIPE mean underrun
      fprintf(stderr, "underrun occurred\n");
      snd_pcm_prepare(tx);
    } else if (rc < 0) {
      fprintf(stderr, "error from writei: %s\n", snd_strerror(rc));
    } else if (rc != (int)frames) {
      fprintf(stderr, "short write, write %d frames\n", rc);
    }
  }

  snd_pcm_drain(tx);

  fprintf(stderr, "closing device..."); fflush(stderr);
  snd_pcm_close(tx);
  fprintf(stderr, "done\n");

  free(buffer);

  return 0;
}

