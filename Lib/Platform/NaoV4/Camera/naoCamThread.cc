#include "naoCamThread.h"
#include "timeScalar.h"

#include <map>
#include <string>
#include <vector>
#include <pthread.h>
#include <signal.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <linux/videodev2.h>
#include <stdio.h>
#include <errno.h>
#include <string>
#include <string.h>
#include <stdlib.h>

/*
#include <boost/interprocess/managed_shared_memory.hpp>
using namespace boost::interprocess;

static const char sensorShmName[] = "dcmSensor";
static managed_shared_memory *sensorShm;
*/

typedef unsigned char uint8;
typedef unsigned int uint32;

#define NVIDEO_DEVICES 2
const char *video_devices[] = {"/dev/video0", "/dev/video1"};

#define WIDTH 640
#define HEIGHT 480

static int video_fd[] = {0, 0};

const int nbuf = 4;
static std::vector <uint32 *> bufArrayVec;
uint32 *bufArray = NULL;
CAMERA_STATUS *cameraStatus = NULL;

static pthread_t nao_cam_thread = 0;
pthread_mutex_t cam_mutex = PTHREAD_MUTEX_INITIALIZER;

static int selectCurrent = 0;
static int selectRequest = 0;
static int selectCount = 0;

static std::map<std::string, int> v4l2ControlMap;

void write_yuyv(uint32 *ptr, int len) {
  printf("opening save file...");
  FILE *pfile = fopen("testim.raw", "wb");
  printf("done\n");
  if (pfile != NULL) {
    printf("writing image save file...");
    fwrite(ptr, 1, len, pfile);
    printf("done\n");
    printf("closing file...");
    fclose(pfile);
    printf("done\n");
  }
}


void query_ctrls(int fd) {
  // query available controls and set them in the control table
  struct v4l2_queryctrl queryctrl;
  memset(&queryctrl, 0, sizeof(v4l2_queryctrl));
  //for (queryctrl.id = V4L2_CID_BASE; queryctrl.id < V4L2_CID_LASTP1; queryctrl.id++) {
  for (queryctrl.id = V4L2_CID_BASE; queryctrl.id < V4L2_CID_LASTP1+1000000; queryctrl.id++) {
    if (0 == ioctl(fd, VIDIOC_QUERYCTRL, &queryctrl)) {
      if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED) {
        continue;
      }

      // set control in menu
      printf("%d: %s\n", queryctrl.id - V4L2_CID_BASE, queryctrl.name);
      v4l2ControlMap[(char *)queryctrl.name] = queryctrl.id;

    } else {
      if (errno == EINVAL) {
        continue;
      }
      perror("VIDIOC_QUERYCTRL");
      exit(EXIT_FAILURE);
    }
  }

  for (queryctrl.id = V4L2_CID_PRIVATE_BASE; ; queryctrl.id++) {
    if (0 == ioctl(fd, VIDIOC_QUERYCTRL, &queryctrl)) { 
      if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED) {
        continue;
      }

      // set control in menu
      printf("%s\n", queryctrl.name);
      v4l2ControlMap[(char *)queryctrl.name] = queryctrl.id;
    } else {
      if (errno == EINVAL) {
        break;
      }

      perror("VIDIOC_QUERYCTRL");
      exit(EXIT_FAILURE);
    }
  }
}

int camera_select(int bottom_camera) {
  int ret = 0;

  // switch cameras
  selectCurrent = bottom_camera;
  return ret;
}

int nao_cam_thread_get_selected_camera() {
  return selectCurrent;
}

void *nao_cam_thread_func(void *id) {
  int ret;
  static int count = 0;

  printf("Starting naoCam thread...\n");
  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK, &sigs, NULL);

  while (1) {
    if (selectCurrent != selectRequest) {
      selectCount = 0;
      pthread_mutex_lock(&cam_mutex);
      if (camera_select(selectRequest) < 0) {
        printf("Could not select camera");
        pthread_exit(NULL);
      }
      pthread_mutex_unlock(&cam_mutex);
    }

    usleep(20000); // 20 ms
    count++;

    int ibuf = count % bufArrayVec.size();
    uint32 *readArray = bufArrayVec[ibuf];
    selectCount++;

    pthread_mutex_lock(&cam_mutex);


    int framesize = (WIDTH/2 * HEIGHT) * (sizeof(uint32));
    if (read(video_fd[selectCurrent], readArray, framesize) < 0) {
      printf("Could not read frame");
      pthread_exit(NULL);
    }

    if (selectCount > 2) {
      bufArray = readArray;
      cameraStatus->count = count;
      cameraStatus->time = time_scalar();
      cameraStatus->select = selectCurrent;

      for (int ji = 0; ji < 22; ji++) {
        cameraStatus->joint[ji] = 0;
      }
      /*
      std::pair<double *, std::size_t> ret;
      ret = sensorShm->find<double>("position");
      double *p = ret.first;
      if (p != NULL) {
        for (int ji = 0; ji < 22; ji++) {
          cameraStatus->joint[ji] = p[ji];
        }
      }
      */
    }

    pthread_mutex_unlock(&cam_mutex);

    pthread_testcancel();
  }
}

int nao_cam_thread_init() {
  int ret = 0;
  
  printf("Opening video devices...");
  for (int i = 0; i < NVIDEO_DEVICES; i++) {
    printf("%s...", video_devices[i]);
    if ((video_fd[i] = open(video_devices[i], O_RDWR)) < 0) {
      printf("Couldn't open video device.");
      return video_fd[i];
    }
  }
  printf("done\n");

  printf("Setting frame sizes...");
  for (int i = 0; i < NVIDEO_DEVICES; i++) {
    v4l2_format fmt;
    memset(&fmt, 0, sizeof(v4l2_format));

    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if ((ret = ioctl(video_fd[i], VIDIOC_G_FMT, &fmt)) < 0) {
      fprintf(stderr, "unable to query foramt: %s\n", strerror(errno));
      return ret;
    }

    // set to desired width/height
    fmt.fmt.pix.width = WIDTH;
    fmt.fmt.pix.height = HEIGHT;

    ret = ioctl(video_fd[i], VIDIOC_S_FMT, &fmt);
    if (ret < 0) {
      fprintf(stderr, "unable to set format\n");
      return ret;
    }
    if (fmt.fmt.pix.width != WIDTH || fmt.fmt.pix.height != HEIGHT) {
      fprintf(stderr, "pixel format unavailable\n");
      return -1;
    }
    printf("%s (%d,%d)...", video_devices[i], fmt.fmt.pix.width, fmt.fmt.pix.height); 
  }
  printf("done\n");

  // enumerate available controls instead of using a set list
  printf("Enumerating available controls:\n");
  for (int i = 0; i < NVIDEO_DEVICES; i++) {
    printf("device: %s:\n", video_devices[i]);
    query_ctrls(video_fd[i]);
  }
  printf("done\n");
  
  // initialize buffer array
  for (int i = 0; i < nbuf; i++) {
    uint32 *tbuf = (uint32 *)malloc((WIDTH/2 * HEIGHT) * sizeof(uint32));
    if (tbuf == NULL) {
      fprintf(stderr, "malloc failed");
      exit(EXIT_FAILURE);
    }
    
    bufArrayVec.push_back(tbuf);
  }


  
  // initialize status struct
  cameraStatus = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));
  if (cameraStatus == NULL) {
    fprintf(stderr, "malloc failed");
    exit(EXIT_FAILURE);
  }

	printf("Attaching sensor shm...");
	//sensorShm = new managed_shared_memory(open_only, sensorShmName);
  printf("done\n");

  ret = pthread_create(&nao_cam_thread, NULL,
		       nao_cam_thread_func, NULL);
  
  return ret;
}

void nao_cam_thread_cleanup() {
  if (nao_cam_thread) {
    pthread_cancel(nao_cam_thread);
    usleep(500000L);
  }

  for (int i = 0; i < NVIDEO_DEVICES; i++) {
    if (video_fd[i] > 0) {
      close(video_fd[i]);
    }
  }

  for (int i = 0; i < bufArrayVec.size(); i++) {
    if (bufArrayVec[i]) {
      free(bufArrayVec[i]);  
    }
  }

  if (cameraStatus) {
    free(cameraStatus);  
  }
}

void nao_cam_thread_camera_select(int bottom) {
  selectRequest = bottom;
}

int nao_cam_thread_get_camera_select() {
  return selectCurrent;
}

int nao_cam_thread_set_control(const char *name, int val) {
  static struct v4l2_control ctrl;
  while (selectCurrent != selectRequest) {
    usleep(1000);
  }

  std::map<std::string, int>::iterator iControlMap =
    v4l2ControlMap.find(name);

  if (iControlMap == v4l2ControlMap.end())
    return -1;

  ctrl.id = iControlMap->second;
  ctrl.value = val;
  pthread_mutex_lock(&cam_mutex);
  int ret = ioctl(video_fd[selectCurrent], VIDIOC_S_CTRL, &ctrl);
  pthread_mutex_unlock(&cam_mutex);

  return ret;
}

int nao_cam_thread_get_control(const char *name) {
  static struct v4l2_control ctrl;
  while (selectCurrent != selectRequest) {
    usleep(1000);
  }

  std::map<std::string, int>::iterator iControlMap =
    v4l2ControlMap.find(name);

  if (iControlMap == v4l2ControlMap.end())
    return -1;

  ctrl.id = iControlMap->second;
  pthread_mutex_lock(&cam_mutex);
  int ret = ioctl(video_fd[selectCurrent], VIDIOC_G_CTRL, &ctrl);
  pthread_mutex_unlock(&cam_mutex);

  if (ret < 0) {
    printf("Could not get v4l2 control");
    return ret;  
  }

  return ctrl.value;
}

int nao_cam_thread_get_height() {
  // return the image height
  return HEIGHT;
}

int nao_cam_thread_get_width() {
  // return the image width
  return WIDTH;
}
