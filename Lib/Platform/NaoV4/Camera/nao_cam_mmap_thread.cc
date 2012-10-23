
#include "nao_cam_thread.h"
#include "cam_util.h"
#include "timeScalar.h"

// undocumented auto gain parameter
#define V4L2_CID_AUTO_EXPOSURE 10094849


// camera device paths
const char *cameraDevices[] = {"/dev/video0", "/dev/video1"};
// camera file descriptors
static int cameraFd[NCAMERA_DEVICES];
// number of v4l2 buffers for each camera
static int nbuf[NCAMERA_DEVICES];
// array of v4l2 buffers for each camera
struct v4l2_buffer *v4l2buffers[NCAMERA_DEVICES];
// array of image buffers for each camera
uint32 **imbuffers[NCAMERA_DEVICES];
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

// camera status structs
CAMERA_STATUS *cameraStatus[NCAMERA_DEVICES];

// thread variables
static pthread_t camthreads[NCAMERA_DEVICES];
pthread_mutex_t camMutexes[NCAMERA_DEVICES];


static int selectCurrent = 0;
static int selectCount = 0;

static std::map<std::string, int> v4l2ControlMap[NCAMERA_DEVICES];

int nao_cam_thread_get_selected_camera() {
  return selectCurrent;
}

void *nao_cam_thread_func(void *cameraIndex) {
  // get camera index
  int cid = (int)cameraIndex;

  printf("starting NaoCam thread for %s\n", cameraDevices[cid]);

  sigset_t sigs;
  sigfillset(&sigs);
  pthread_sigmask(SIG_BLOCK, &sigs, NULL);

  // initialize current buffer index
  currBufIndex[cid] = 0;

  // initialize current and next v4l2 buffers
  currV4l2Buf[cid] = &v4l2buffers[cid][0];
  nextV4l2Buf[cid] = &v4l2buffers[cid][1];

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
    } else {
      cameraStatus[cid]->count = nframe[cid];
      cameraStatus[cid]->time = time_scalar();
      cameraStatus[cid]->select = cid;

      for (int ji = 0; ji < 22; ji++) {
        cameraStatus[cid]->joint[ji] = 0;
      }
    }

    pthread_testcancel();

    usleep(1000);
  }
}

int nao_cam_thread_init() {
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

    if (construct_parameter_map(cameraFd[i], v4l2ControlMap[i]) < 0) {
      printf("error constructing parameter map\n");
      return -1;
    }

    if (start_stream(cameraFd[i]) < 0) {
      printf("unable to start camera stream: %s\n", cameraDevices[i]);
      return -1;
    } 

    // allocate camera status struct
    cameraStatus[i] = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));
    if (cameraStatus == NULL) {
      printf("unable to allocate memory for camera status struct\n");
      return -1;
    }

   // initialize mutexes
    //camMutexes[i] = PTHREAD_MUTEX_INITIALIZER;
  }



  // start each camera thread
  for (int i = 0; i < NCAMERA_DEVICES; i++) {
    printf("starting camera %d thread\n", i);
    int ret = pthread_create(&camthreads[i], NULL, nao_cam_thread_func, (void *)i);
    if (ret != 0) {
      printf("error creating pthread: %d\n", ret);
      return -1;
    }
  }

  return 0;
}

void nao_cam_thread_cleanup() {
  // TODO: cleanup everything
  /*
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
  */
}

uint32 *nao_cam_thread_get_image() {
  // TODO: mutex
  return imbuffers[selectCurrent][currBufIndex[selectCurrent]];
}

void nao_cam_thread_camera_select(int bottom) {
  if (bottom >= NCAMERA_DEVICES) {
    printf("warning: attempted to switch to a camera that is out of range %d/%d\n", bottom, NCAMERA_DEVICES);
  } else {
    selectCurrent = bottom;
  }
}

int nao_cam_thread_get_camera_select() {
  return selectCurrent;
}

int construct_parameter_map(int fd, std::map<std::string, int> &paramMap) {
  // query available controls and set them in the control table
  struct v4l2_queryctrl queryctrl;
  memset(&queryctrl, 0, sizeof(v4l2_queryctrl));
  printf("querying camera parameters:\n");

  // need to increase the range because auto gain is not in the standard range
  for (queryctrl.id = V4L2_CID_BASE; queryctrl.id < V4L2_CID_LASTP1+1000000; queryctrl.id++) {
    if (0 == ioctl(fd, VIDIOC_QUERYCTRL, &queryctrl)) {
      if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED) {
        continue;
      }

      // set control in menu
      printf("  %d: %s %d %d %d\n", queryctrl.id, queryctrl.name, queryctrl.minimum, queryctrl.maximum, queryctrl.default_value);
      paramMap[(char *)queryctrl.name] = queryctrl.id;
    } else {
      if (errno == EINVAL) {
        continue;
      }
      printf("error querying control: %d\n", queryctrl.id);
      return -1;
    }
  }

  for (queryctrl.id = V4L2_CID_PRIVATE_BASE; ; queryctrl.id++) {
    if (0 == ioctl(fd, VIDIOC_QUERYCTRL, &queryctrl)) { 
      if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED) {
        continue;
      }

      // set control in menu
      printf("%s\n", queryctrl.name);
      paramMap[(char *)queryctrl.name] = queryctrl.id;
    } else {
      if (errno == EINVAL) {
        break;
      }

      printf("error querying control: %d\n", queryctrl.id);
      return -1;
    }
  }

  return 0;
}

int nao_cam_thread_set_control(const char *name, int val) {
 // printf("trying to set prameter %s to %d\n", name, val);
  static struct v4l2_control ctrl;

  // TODO: lock mutex here
  int cid = selectCurrent;

  std::map<std::string, int>::iterator iControlMap = v4l2ControlMap[cid].find(name);
  if (iControlMap == v4l2ControlMap[cid].end()) {
    return -1;
  }
  int id = iControlMap->second;

  if (set_camera_param(cameraFd[cid], id, val) < 0) {
    printf("failed to set parameter %s :: %d\n", name, val);
    return -1;
  }

  return 0;
}

int nao_cam_thread_get_control(const char *name) {
  // TODO: lock mutex here
  int cid = selectCurrent;

  std::map<std::string, int>::iterator iControlMap = v4l2ControlMap[cid].find(name);
  if (iControlMap == v4l2ControlMap[cid].end()) {
    return -1;
  }
  int id = iControlMap->second;
  
  int val;
  if (get_camera_param(cameraFd[cid], id, val) < 0) {
    printf("unable to get v4l2 control for %s\n", name);
    return -1;
  }

  return val;
}

int nao_cam_thread_get_height() {
  // return the image height
  return HEIGHT;
}

int nao_cam_thread_get_width() {
  // return the image width
  return WIDTH;
}

