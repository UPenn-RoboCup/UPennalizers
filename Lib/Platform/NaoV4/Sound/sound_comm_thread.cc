#include "sound_comm_thread.h"

// thread variables
static pthread_t rxthread;
static pthread_t txthread;
// detection variables mutex
static pthread_mutex_t detectionMutex;
// playlist mutex (this one is probably not needed)
static pthread_mutex_t playlistMutex;
// debug pcm mutex
pthread_mutex_t pcmDebugMutex;

// transmitter and reciever handles
snd_pcm_t *tx;
snd_pcm_t *rx;
// transmitter and reciever parameter objects
snd_pcm_hw_params_t *txParams;
snd_pcm_hw_params_t *rxParams;

// receive buffer
short rxBuffer[PSAMPLE];

// pause variables for transmitter/receiver
bool txPauseCmd = false;
bool rxPauseCmd = false;
bool txPaused = false;
bool rxPaused = false;


// detection values
static DetStruct detection;

// audio play list
std::queue< std::vector<short> * > playlist;

// debugging arrays
short pcmDebugBuffer[pcmDebugLen];
short pcmDebug[pcmDebugLen];


int init_devices() {
  int ret;
  print_alsa_lib_version();

  // open devices
  printf("opening transmitter audio device..."); fflush(stdout);
  ret = open_transmitter(&tx);
  if (ret < 0) {
    fprintf(stderr, "error opening transmitter.\n");
    return ret;
  }
  printf("done\n");
  printf("opening reciever audio device..."); fflush(stdout);
  ret = open_receiver(&rx);
  if (ret < 0) {
    fprintf(stderr, "error opening reciever.\n");
    return ret;
  }
  printf("done\n");


  // set parameters
  printf("setting transmitter parameters..."); fflush(stdout);
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
  printf("done\n");
  print_device_params(tx, txParams, 0);

  printf("setting receiver parameters..."); fflush(stdout);
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
  printf("done\n");
  print_device_params(rx, rxParams, 0); 

  return 0;
}



/***********************************************************************************
 * *********************************************************************************
 *                  RECEVIER THREAD FUNCTIONS
 * *********************************************************************************
 * *********************************************************************************/


void *sound_comm_rx_thread_func(void*) {

  printf("starting SoundComm receiver thread\n");

  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK, &sigs, NULL);

  snd_pcm_uframes_t frames = NFRAME;

  // number of frames in buffer
  int nrxFrames = 0;
  // current buffer index
  int irxBuffer = 0;
  while (1) {

    if (rxPauseCmd) {
      // pause requested

      // the nao drivers do not acutally support pausing the audio device
      //  so I am just continuously resetting the device buffer to avoid
      //  overruns

      // reset the device buffer
      int ret = snd_pcm_reset(rx);
      if (ret < 0) {
        fprintf(stderr, "error reseting receiver: %s\n", snd_strerror(ret));
      }

      // reset the local buffer variables
      nrxFrames = 0;
      irxBuffer = 0;

      rxPaused = true;

      usleep(100000);
    } else {

      if (rxPaused) {
        // reset the device buffer 
        int ret = snd_pcm_reset(rx);
        if (ret < 0) {
          fprintf(stderr, "error reseting receiver: %s\n", snd_strerror(ret));
        }

        rxPaused = false;
      }

      if (nrxFrames + frames < PFRAME) {
        // all frames fit within buffer, read all available frames
        int rframes = snd_pcm_readi(rx, rxBuffer+irxBuffer, frames);
        if (rframes == -EPIPE) {
          // EPIPE mean overrun
          fprintf(stderr, "overrun occurred\n");
          snd_pcm_prepare(rx);
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } else if (rframes < 0) {
          fprintf(stderr, "error from read: %s\n", snd_strerror(rframes));
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } else if (rframes != (int)frames) {
          fprintf(stderr, "short read: read %d frames\n", rframes);
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } 
        
        // update rx buffer
        nrxFrames += rframes;
        irxBuffer += rframes * SAMPLES_PER_FRAME;

      } else {
        // read enough frames to fill buffer
        int nframes = PFRAME - nrxFrames;
        int rframes = snd_pcm_readi(rx, rxBuffer+irxBuffer, nframes);
        if (rframes == -EPIPE) {
          // EPIPE mean overrun
          fprintf(stderr, "overrun occurred\n");
          snd_pcm_prepare(rx);
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } else if (rframes < 0) {
          fprintf(stderr, "error from read: %s\n", snd_strerror(rframes));
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } else if (rframes != (int)nframes) {
          fprintf(stderr, "short read: read %d frames\n", rframes);
          // reset rx buffer
          irxBuffer = 0;
          continue;
        } 

        // process audio sample
        char symbol;
        long frame;
        int xLIndex;
        int xRIndex;
        int toneCount = check_tone(rxBuffer, symbol, frame, xLIndex, xRIndex);
        if (toneCount == -1) {
          pthread_mutex_lock(&detectionMutex);
          // detection time
          struct timeval t;
          gettimeofday(&t, NULL);
          detection.time = t.tv_sec + 1E-6*t.tv_usec;
          detection.symbol = symbol;
          detection.lIndex = xLIndex;
          detection.rIndex = xRIndex;
          detection.count += 1;
          pthread_mutex_unlock(&detectionMutex);

          // copy the pcm array for debugging
          int n = PSAMPLE * (THRESHOLD_COUNT + NUM_CHIRP_COUNT - 1);
          for (int i = 0; i < n; i++) {
            pcmDebug[i] = pcmDebugBuffer[i];
          }
          for (int i = 0; i < PSAMPLE; i++) {
            pcmDebug[n+i] = rxBuffer[i];
          }
        } else if (toneCount > 0) {
          // store the pcm array for debugging
          pthread_mutex_lock(&pcmDebugMutex);
          int n = PSAMPLE * (toneCount-1);
          for (int i = 0; i < PSAMPLE; i++) {
            pcmDebugBuffer[n+i] = rxBuffer[i];
          }
          pthread_mutex_unlock(&pcmDebugMutex);
        }

        // read remaining audio from buffer
        nframes = NFRAME - rframes;
        rframes = snd_pcm_readi(rx, rxBuffer, nframes);
        if (rframes == -EPIPE) {
          // EPIPE mean overrun
          fprintf(stderr, "overrun occurred\n");
          snd_pcm_prepare(rx);
          // reset rx buffer
          irxBuffer = 0;
          continue;
          
        } else if (rframes < 0) {
          fprintf(stderr, "error from read: %s\n", snd_strerror(rframes));
          // reset rx buffer
          irxBuffer = 0;
          continue;

        } else if (rframes != (int)nframes) {
          fprintf(stderr, "short read: read %d frames\n", rframes);
          // reset rx buffer
          irxBuffer = 0;
          continue;

        } 

        // update rx buffer
        nrxFrames = rframes;
        irxBuffer = rframes * SAMPLES_PER_FRAME;
      }
    }

    pthread_testcancel();
  }
}


void sound_comm_rx_thread_cleanup() {
  // stop the thread if needed
  if (rxthread) {
    pthread_cancel(rxthread);
    usleep(500000L);
  }

  // TODO: free mutexes

  // clear any pending buffers
  snd_pcm_drain(rx);

  // close device
  printf("closing receiver device..."); fflush(stdout);
  snd_pcm_close(rx);
  printf("done\n");
}



/***********************************************************************************
 * *********************************************************************************
 *                  RECEVIER THREAD FUNCTIONS
 * *********************************************************************************
 * *********************************************************************************/



void *sound_comm_tx_thread_func(void*) {
  printf("starting SoundComm transmitter thread\n");

  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK, &sigs, NULL);

  // currently playing signal
  std::vector<short> *txBuffer = NULL;

  // current playing index
  int itxBuffer = 0;
  while (1) {
    // is paused?
    if (txPauseCmd) {
      // pause requested, pause the transmitter if needed

      // the nao audio drivers do not actually support pausing the device
      //  so I am just continuously sending zeros to avoid an underrun
      short zeros[ASAMPLE];
      memset(zeros, 0, sizeof(short)*ASAMPLE);
      snd_pcm_uframes_t zframes = NFRAME;
      int ret = snd_pcm_writei(tx, zeros, zframes);
      if (ret == -EPIPE) {
        // EPIPE mean underrun
        fprintf(stderr, "underrun occurred\n");
        snd_pcm_prepare(tx);
      } else if (ret < 0) {
        fprintf(stderr, "error from writei: %s\n", snd_strerror(ret));
      } else if (ret != (int)zframes) {
        fprintf(stderr, "short write, write %d frames\n", ret);
      }

      txPaused = true;

    } else {
      // is the device paused?
      if (txPaused) {
        // enable the device
        int ret = snd_pcm_pause(tx, 0);
        if (ret < 0) {
          fprintf(stderr, "error resuming transmitter: %s\n", snd_strerror(ret));
        }

        txPaused = false;
      }

      // are we currently playing a signal?
      if (txBuffer == NULL) {
        // check if there are any queued signals
        pthread_mutex_lock(&playlistMutex);
        if (playlist.size() > 0) {
          // get the next signal to play
          txBuffer = playlist.front();
          playlist.pop();

          // init buffer index to 0
          itxBuffer = 0;
        }
        // unlock detection mutex
        pthread_mutex_unlock(&playlistMutex);
      }

      // if there is a signal to play use that
      if (txBuffer) {
        bool doneCurrent = false;
        // number of frames to write
        int nframe = NFRAME;

        // are we at the end of the signal?
        //  the audio drivers will cause a continuous large cpu usage spike
        //  if the number of frames written to the device is not the same as the
        //  number of frames per period.
        //  pad the array with zeros if needed
        int ret;
        if (txBuffer->size() - itxBuffer <= ASAMPLE) {
          short tmpPCM[ASAMPLE];
          int tsample = txBuffer->size() - itxBuffer;

          memcpy(tmpPCM, &(*txBuffer)[itxBuffer], sizeof(short) * (tsample));
          memset(tmpPCM+tsample, 0, sizeof(short) * ASAMPLE);

          // send the pcm signal to the audio device
          ret = snd_pcm_writei(tx, tmpPCM, nframe);

          doneCurrent = true;
        } else {
          // send the pcm signal to the audio device
          ret = snd_pcm_writei(tx, &(*txBuffer)[itxBuffer], nframe);
        }

        if (ret == -EPIPE) {
          // EPIPE mean underrun
          fprintf(stderr, "underrun occurred\n");
          snd_pcm_prepare(tx);
        } else if (ret < 0) {
          fprintf(stderr, "error from writei: %s\n", snd_strerror(ret));
        } else if (ret != (int)nframe) {
          fprintf(stderr, "short write, write %d frames\n", ret);
        }

        if (doneCurrent) {
          // we are done playing the audio clip so free the vector
          delete txBuffer;
          txBuffer = NULL;
        } else {
          // increment the buffer pointer
          itxBuffer += (nframe * SAMPLES_PER_FRAME);
        }

      } else {
        // nothing to play

        // the nao audio drivers do not actually support pausing the device
        //  so I am just continuously sending zeros to avoid an underrun
        short zeros[ASAMPLE];
        memset(zeros, 0, sizeof(short)*ASAMPLE);
        snd_pcm_uframes_t zframes = NFRAME;
        int ret = snd_pcm_writei(tx, zeros, zframes);
        if (ret == -EPIPE) {
          // EPIPE mean underrun
          fprintf(stderr, "underrun occurred\n");
          snd_pcm_prepare(tx);
        } else if (ret < 0) {
          fprintf(stderr, "error from writei: %s\n", snd_strerror(ret));
        } else if (ret != (int)zframes) {
          fprintf(stderr, "short write, write %d frames\n", ret);
        }
      }

      usleep(1000);
    }

    pthread_testcancel();
  }
}


void sound_comm_tx_thread_cleanup() {
  // stop the thread if needed
  if (txthread) {
    pthread_cancel(txthread);
    usleep(500000L);
  }

  // TODO: free mutexes


  // clear any pending buffers
  snd_pcm_drain(tx);

  // close device
  printf("closing transmitter device..."); fflush(stdout);
  snd_pcm_close(tx);
  printf("done\n");
}


void sound_comm_thread_queue_pcm(std::vector<short> *pcm) {
  // queue the pcm signal in the playlist
  pthread_mutex_lock(&playlistMutex);
  playlist.push(pcm);
  // unlock detection mutex
  pthread_mutex_unlock(&playlistMutex);
}


DetStruct sound_comm_thread_get_detection() {
  // get detection lock
  pthread_mutex_lock(&detectionMutex);
  DetStruct det = detection;
  // unlock detection mutex
  pthread_mutex_unlock(&detectionMutex);
  return det;
}


int sound_comm_thread_set_transmitter_volume(int volume) {
  if (set_playback_volume(volume, "default", "PCM") < 0) {
    fprintf(stderr, "error setting 'PCM' playback volume.\n");
    return -1;
  }
  return 0;
}


int sound_comm_thread_set_receiver_volume(int volume) {
  if (set_capture_volume(volume, "default", "Front/Rear mics") < 0) {
    fprintf(stderr, "error setting 'Front/Read mics' capture volume.\n");
    return -1;
  }
  // TODO: why does Digital only show up sometimes?
  if (set_capture_volume(volume, "default", "Digital") < 0) {
    fprintf(stderr, "error setting 'Digital' capture volume.\n");
    //return -1;
  }
  if (set_capture_volume(volume, "default", "Left/Right mics") < 0) {
    fprintf(stderr, "error setting 'Left/Right mics' capture volume.\n");
    return -1;
  }

  return 0;
}


int sound_comm_thread_init() {
  int ret;

  // initialize audio devices (transmitter and receiver)
  ret = init_devices();
  if (ret < 0) {
    fprintf(stderr, "error initializing devices\n");
    return ret;
  }

  // set volumes
  if (sound_comm_thread_set_transmitter_volume(100) < 0) {
    fprintf(stderr, "unable to initialize transmitter volume.\n");
    return -1;
  }
  if (sound_comm_thread_set_receiver_volume(75) < 0) {
    fprintf(stderr, "unable to initialize reciever volume.\n");
    return -1;
  }
  

  // initialize detection variables
  detection.count = 0;
  detection.time = 0;
  detection.lIndex = -1;
  detection.rIndex = -1;
  detection.symbol = '\0';

  // create mutexes
  if ((ret = pthread_mutex_init(&detectionMutex, NULL)) != 0) {
    fprintf(stderr, "error initializing detection mutex: %d\n", ret);
    return ret;
  }
  if ((ret = pthread_mutex_init(&playlistMutex, NULL)) != 0) {
    fprintf(stderr, "error initializing playlist mutex: %d\n", ret);
    return ret;
  }
  if ((ret = pthread_mutex_init(&pcmDebugMutex, NULL)) != 0) {
    fprintf(stderr, "error initializing debug pcm mutex: %d\n", ret);
    return ret;
  }

  // start receiver thread
  printf("creating sound receiver thread\n");
  ret = pthread_create(&rxthread, NULL, sound_comm_rx_thread_func, NULL);
  if (ret != 0) {
    printf("error creating receiver pthread: %d\n", ret);
    return -1;
  }
  printf("creating sound transmitter thread\n");
  ret = pthread_create(&txthread, NULL, sound_comm_tx_thread_func, NULL);
  if (ret != 0) {
    printf("error creating transmitter pthread: %d\n", ret);
    return -1;
  }

  return 0;
}

