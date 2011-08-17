/*
  naoCamThread using video4linux2 and i2c for Nao
  Written by Daniel D. Lee, <ddlee@seas.upenn.edu>, 6/09.
*/


#include "naoCamThread.h"
#include "i2cBus.h"
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

#include <boost/interprocess/managed_shared_memory.hpp>
using namespace boost::interprocess;

static const char sensorShmName[] = "dcmSensor";
static managed_shared_memory *sensorShm;

typedef unsigned char uint8;
typedef unsigned int uint32;

#define VIDEO_DEVICE "/dev/video0"
#define I2C_DEVICE "/dev/i2c-0"
#define I2C_ADDRESS 0x08

#define WIDTH 320
#define HEIGHT 240

// Nao ov7670 camera init
#ifndef V4L2_CID_CAM_INIT
//#define V4L2_CID_CAM_INIT (V4L2_CID_BASE+25) // NaoQi 1.2.0
#define V4L2_CID_CAM_INIT (V4L2_CID_BASE+33) // NaoQi 1.3.8
// Undocumented CID for changing auto exposure:
#define V4L2_CID_AUTO_EXPOSURE (V4L2_CID_BASE+32) // NaoQi 1.3.8
#endif

// Nao ov7670 HD QVGA standard
#ifndef V4L2_STD_UNK106
#define V4L2_STD_UNK106 0x04000000UL
#endif

static int video_fd = 0;
static int i2c_fd = 0;

const int nbuf = 4;
static std::vector <uint32 *> bufArrayVec;
uint32 *bufArray = NULL;
CAMERA_STATUS *cameraStatus = NULL;

static pthread_t nao_cam_thread = 0;
pthread_mutex_t cam_mutex = PTHREAD_MUTEX_INITIALIZER;

static int selectCurrent = 0;
static int selectRequest = 0;
static int selectSlowMode = 1;
static int selectCount = 0;

static std::map<std::string, int> v4l2ControlMap;

int camera_select_fast(int bottom_camera) {
  int ret = 0;

  uint8 cmd[1];
  int value;
  if (bottom_camera) {
    cmd[0] = 0x02;
    value = 0;
  } else {
    cmd[0] = 0x01;
    value = 1;
  }

  // Set camera with SMBus write
  if ((ret = i2c_smbus_write_block_data(i2c_fd,
					I2C_ADDRESS, 220, 5, 1, cmd)) < 0) {
    printf("I2C_SMBUS write 220");
    return ret;
  }

  selectCurrent = bottom_camera;
  return ret;
}

int camera_select_standard(int bottom_camera) {
  int ret = 0;
  struct v4l2_control ctrl;

  if (video_fd > 0) {
    close(video_fd);
    video_fd = 0;
  }

  camera_select_fast(bottom_camera);

  // Open video device
  if ((video_fd = open(VIDEO_DEVICE, O_RDWR)) < 0) {
    printf("Couldn't open video device.");
    return video_fd;
  }

  int value;
  if (bottom_camera) {
    value = 0;
  } else {
    value = 1;
  }
  ctrl.id = V4L2_CID_VFLIP;
  ctrl.value = value;
  if ((ret = ioctl(video_fd, VIDIOC_S_CTRL, &ctrl)) < 0) {
    printf("VIDIOC_S_CTRL V4L2_CID_VFLIP");
    return ret;
  }
  ctrl.id = V4L2_CID_HFLIP;
  ctrl.value = value;
  if ((ret = ioctl(video_fd, VIDIOC_S_CTRL, &ctrl)) < 0) {
    printf("VIDIOC_S_CTRL V4L2_CID_HFLIP");
    return ret;
  }

  v4l2_std_id id;
  if ((ret = ioctl(video_fd, VIDIOC_G_STD, &id)) < 0) {
    printf("VIDIOC_G_STD");
    return ret;
  }
  id = V4L2_STD_UNK106;
  if ((ret = ioctl(video_fd, VIDIOC_S_STD, &id)) < 0) {
    printf("VIDIOC_S_STD");
    return ret;
  }

  struct v4l2_format video_fmt;
  video_fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  video_fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
  video_fmt.fmt.pix.field       = V4L2_FIELD_ANY;
  video_fmt.fmt.pix.width       = WIDTH;
  video_fmt.fmt.pix.height      = HEIGHT;
  if ((ret = ioctl(video_fd, VIDIOC_S_FMT, &video_fmt)) < 0) {
    printf("VIDIOC_S_FMT");
    return ret;
  }

  selectCurrent = bottom_camera;
  return ret;
}

int nao_cam_thread_get_selected_camera() {
  return selectCurrent;
}

void *nao_cam_thread_func(void *id) {
  int ret;
  static int count = 0;

  printf("Starting naoCam thread...");
  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK, &sigs, NULL);

  while (1) {
    if (selectCurrent != selectRequest) {
      selectCount = 0;
      pthread_mutex_lock(&cam_mutex);
      if (selectSlowMode) {
        if (camera_select_standard(selectRequest) < 0) {
          printf("Could not select camera");
          pthread_exit(NULL);
        }
      } else {
        if (camera_select_fast(selectRequest) < 0) {
          printf("Could not select camera");
          pthread_exit(NULL);
        }
      }
      pthread_mutex_unlock(&cam_mutex);
      // Need to wait at least 100 ms before acquiring frame after fast switch:
      //usleep(80000); // 80 ms
    }

    usleep(20000); // 20 ms
    count++;

    int ibuf = count % bufArrayVec.size();
    uint32 *readArray = bufArrayVec[ibuf];
    selectCount++;

    pthread_mutex_lock(&cam_mutex);


    int framesize = (WIDTH/2 * HEIGHT) * (sizeof(uint32));
    if (read(video_fd, readArray, framesize) < 0) {
      printf("Could not read frame");
      pthread_exit(NULL);
    }

    if (selectCount > 2) {
      bufArray = readArray;
      cameraStatus->count = count;
      cameraStatus->time = time_scalar();
      cameraStatus->select = selectCurrent;
      std::pair<double *, std::size_t> ret;
      ret = sensorShm->find<double>("position");
      double *p = ret.first;
      if (p != NULL) {
        for (int ji = 0; ji < 22; ji++) {
          cameraStatus->joint[ji] = p[ji];
        }
      }
    }
    pthread_mutex_unlock(&cam_mutex);

    pthread_testcancel();
  }
}

int nao_cam_thread_init() {
  int ret = 0;

  printf("Initializing I2CCamera...");
  if ((i2c_fd = i2c_open(I2C_DEVICE, O_RDWR)) < 0) {
    printf("Couldn't open i2c device.");
    return i2c_fd;
  }
  
  // Get dsPIC version
  int val = i2c_smbus_read_byte_data(i2c_fd,
				     I2C_ADDRESS, 170); // 0xAA smbus read command
  if (val < 0) {
    printf("I2C_SMBUS read 170");
    return val;
  }
  else if (val < 2) {
    printf("Nao V2 identified.\n");
  }
  else {
    printf("Nao V3 identified.\n");
  }

  // Get which camera is active from dsPIC
  val = i2c_smbus_read_byte_data(i2c_fd,
				 I2C_ADDRESS, 220); // 0xDC smbus read command
  if (val < 0) {
    printf("I2C_SMBUS read 220");
    return val;
  }

  // Need to set bottom camera for initialization
  ret = camera_select_fast(1);
  if (ret < 0) {
    printf("Unable to select camera");
    return ret;
  }

  printf("Initializing video device...");
  // Open video device
  if ((video_fd = open(VIDEO_DEVICE, O_RDWR)) < 0) {
    printf("Couldn't open video device.");
    return video_fd;
  }

  // Nao ov7670 CAM_INIT
  struct v4l2_control ctrl;
  ctrl.id = V4L2_CID_CAM_INIT;
  ctrl.value = 0;
  if ((ret = ioctl(video_fd, VIDIOC_S_CTRL, &ctrl)) < 0) {
    printf("VIDIOC_S_CTRL V4L2_CID_CAM_INIT");
    return ret;
  }

  // Need to do standard camera switches:
  ret = camera_select_standard(0);
  if (ret < 0) {
    printf("Unable to select top camera");
    return ret;
  }

  ret = camera_select_standard(1);
  if (ret < 0) {
    printf("Unable to select botom camera");
    return ret;
  }

  // Setup Video4Linux2 controls map:
  v4l2ControlMap["brightness"] = V4L2_CID_BRIGHTNESS;
  v4l2ControlMap["contrast"] = V4L2_CID_CONTRAST;
  v4l2ControlMap["saturation"] = V4L2_CID_SATURATION;
  v4l2ControlMap["hue"] = V4L2_CID_HUE;
  v4l2ControlMap["auto_white_balance"] = V4L2_CID_AUTO_WHITE_BALANCE;
  v4l2ControlMap["red_balance"] = V4L2_CID_RED_BALANCE;
  v4l2ControlMap["blue_balance"] = V4L2_CID_BLUE_BALANCE;
  v4l2ControlMap["gamma"] = V4L2_CID_GAMMA;
  v4l2ControlMap["whiteness"] =  V4L2_CID_WHITENESS;
  v4l2ControlMap["exposure"] = V4L2_CID_EXPOSURE;
  v4l2ControlMap["autogain"] = V4L2_CID_AUTOGAIN;
  v4l2ControlMap["gain"] = V4L2_CID_GAIN;
  v4l2ControlMap["hflip"] =  V4L2_CID_HFLIP;
  v4l2ControlMap["vflip"] = V4L2_CID_VFLIP;
  v4l2ControlMap["hcenter"] = V4L2_CID_HCENTER;
  v4l2ControlMap["vcenter"] = V4L2_CID_VCENTER;
  v4l2ControlMap["auto_exposure"] = V4L2_CID_AUTO_EXPOSURE;

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

	fprintf(stdout, "Attaching sensor shm...");
	sensorShm = new managed_shared_memory(open_only, sensorShmName);

  ret = pthread_create(&nao_cam_thread, NULL,
		       nao_cam_thread_func, NULL);
  
  return ret;
}

void nao_cam_thread_cleanup() {
  if (nao_cam_thread) {
    pthread_cancel(nao_cam_thread);
    usleep(500000L);
  }

  if (video_fd > 0) {
    close(video_fd);
  }

  if (i2c_fd > 0) {
    close(i2c_fd);
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

void nao_cam_thread_camera_select_slow(int bottom) {
  selectRequest = bottom;
  selectSlowMode = true;
}

void nao_cam_thread_camera_select_fast(int bottom) {
  selectRequest = bottom;
  selectSlowMode = false;
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
  int ret = ioctl(video_fd, VIDIOC_S_CTRL, &ctrl);
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
  int ret = ioctl(video_fd, VIDIOC_G_CTRL, &ctrl);
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
