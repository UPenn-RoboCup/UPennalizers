#include <stdio.h>
#include <errno.h>
#include <string>
#include <string.h>
#include <stdlib.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <pthread.h>

#include <map>
#include <string>
#include <vector>

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/mman.h> 

#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <linux/videodev2.h>

#include "cam_util.h"
#include "timeScalar.h"

#define WIDTH 640
#define HEIGHT 480

#define NUM_FRAME_BUFFERS 4

#define NCAMERA_DEVICES 2

// camera device paths
const char *cameraDevices[] = {"/dev/video0", "/dev/video1"};
// camera file descriptors
static int cameraFd[NCAMERA_DEVICES];
// number of v4l2 buffers for each camera
static int nbuf[NCAMERA_DEVICES];
// array of v4l2 buffers for each camera
struct v4l2_buffer *v4l2buffers[NCAMERA_DEVICES];
// array of image buffers for each camera
uint32 *imbuffers[NCAMERA_DEVICES];
// flags indicating if a v4l2 buffer is enqueued for that camera
int enqueued[NCAMERA_DEVICES];
// number of frames received per camera
int nframe[NCAMERA_DEVICES];
// current buffer index for each camera
int currBufIndex[NCAMERA_DEVICES];
// current v4l2 buffer per camera
struct v4l2_buffer *currV4l2Buf[NCAMERA_DEVICES];
// next v4l2 buffer per camera
struct v4l2_buffer *nextV4l2Buf[NCAMERA_DEVICES];

// thread variables
pthread_t camthreads[NCAMERA_DEVICES];


// main thread function to continuously grab camera frames
void *run_camera(void *cameraIndex) {
  // get camera index
  int cid = (int)cameraIndex;

  // initialize current buffer index
  currBufIndex[cid] = 0;

  // initialize current and next v4l2 buffers
  currV4l2Buf[cid] = &v4l2buffers[cid][0];
  nextV4l2Buf[cid] = &v4l2buffers[cid][1];

  printf("starting camera loop for %s.\n", cameraDevices[cid]);
  double t0 = time_scalar();
  while (1) {
    int ret = grab_frame(cameraFd[cid],
                          v4l2buffers[cid],
                          currV4l2Buf[cid],
                          nextV4l2Buf[cid],
                          nbuf[cid],
                          enqueued[cid],
                          currBufIndex[cid],
                          nframe[cid]);
    if (ret < 0) {
      printf("failed to grab frame\n");
    }
    if (nframe[cid] % 100 == 0) {
      printf("%s fps: %f\n", cameraDevices[cid], (100 / (time_scalar() - t0)));
      t0 = time_scalar();
    }
    usleep(1000);
  }
  pthread_exit(NULL);
}



int main() {

  // initialize each camera
  for (int i = 0; i < NCAMERA_DEVICES; i++) {
    cameraFd[i] = init_camera(cameraDevices[i], WIDTH, HEIGHT);
    if (cameraFd[i] < 0) {
      printf("unable to init camera: %s\n", cameraDevices[i]);
      return -1;
    }
    
    nbuf[i] = init_mmap(cameraFd[i], &v4l2buffers[i], &imbuffers[i], NUM_FRAME_BUFFERS);
    if (nbuf[i] < 0) {
      printf("unable to init memory map: %s\n", cameraDevices[i]);
      return -1;
    }

    if (start_stream(cameraFd[i]) < 0) {
      printf("unable to start camera stream: %s\n", cameraDevices[i]);
      return -1;
    } 
  }



  // start each camera thread
  for (int i = 0; i < NCAMERA_DEVICES; i++) {
    printf("starting camera %d thread\n", i);
    int ret = pthread_create(&camthreads[i], NULL, run_camera, (void *)i);
    if (ret != 0) {
      printf("error creating pthread: %d\n", ret);
      return -1;
    }
  }

  /* Last thing that main() should do */
  pthread_exit(NULL);
}


