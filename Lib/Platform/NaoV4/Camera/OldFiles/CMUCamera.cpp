#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <iostream>

#include <fcntl.h>
#include <math.h>
#include <unistd.h>
#include <stropts.h>
#include <errno.h>
#include <sys/mman.h>
#include <linux/videodev2.h>

#include "NaoCamera.h"
#include "shared/ConfigFile/ConfigFile.h"

// Define the logging constants
#define COMPONENT MAIN_MODULE
#define CLASS_LOG_LEVEL LOG_LEVEL_INFO
//#define CLASS_LOG_LEVEL LOG_LEVEL_DEBUG
//#define DISABLE_LOG_SHAPE
#include "Log/LogSettings.h"

NaoCamera::NaoCamera(ConfigFile & configFile, Log & _log)
  : V4L2_CID_AUTO_EXPOSURE(10094849),
    NUM_FRAME_BUFFERS(configFile.getInt("camera/numFrameBuffers", 4)),
    IMAGE_WIDTH(configFile.getInt("camera/imageWidth", 320)),
    IMAGE_HEIGHT(configFile.getInt("camera/imageHeight", 240)),
    FRAMES_PER_SECOND(configFile.getInt("camera/framesPerSecond", 0)),
    IMAGE_SIZE(IMAGE_WIDTH * IMAGE_HEIGHT * 2),
    BRIGHTNESS_TOP            (configFile.getInt("camera/top/brightness", 55)),
    CONTRAST_TOP              (configFile.getInt("camera/top/contrast", 32)),
    SATURATION_TOP            (configFile.getInt("camera/top/saturation", 128)),
    HUE_TOP                   (configFile.getInt("camera/top/hue", 0)),
    AUTO_WHITE_BALANCE_TOP    (configFile.getInt("camera/top/autoWhiteBalance", 0)),
    WHITE_BALANCE_TOP         (configFile.getInt("camera/top/whiteBalance", 0)),
    AUTO_EXPOSURE_TOP         (configFile.getInt("camera/top/autoExposure", 0)),
    EXPOSURE_TOP              (configFile.getInt("camera/top/exposure", 0)),
    GAIN_TOP                  (configFile.getInt("camera/top/gain", 32)),
    HORIZONTAL_FLIP_TOP       (configFile.getInt("camera/top/horizontalFlip", 0)),
    VERTICAL_FLIP_TOP         (configFile.getInt("camera/top/verticalFlip", 0)),
    SHARPNESS_TOP             (configFile.getInt("camera/top/sharpness", 0)),
    BACKLIGHT_COMPENSATION_TOP(configFile.getInt("camera/top/backlightCompensation", 1)),
    BRIGHTNESS_BOTTOM            (configFile.getInt("camera/bottom/brightness", BRIGHTNESS_TOP)),
    CONTRAST_BOTTOM              (configFile.getInt("camera/bottom/contrast", CONTRAST_TOP)),
    SATURATION_BOTTOM            (configFile.getInt("camera/bottom/saturation", SATURATION_TOP)),
    HUE_BOTTOM                   (configFile.getInt("camera/bottom/hue", HUE_TOP)),
    AUTO_WHITE_BALANCE_BOTTOM    (configFile.getInt("camera/bottom/autoWhiteBalance", AUTO_WHITE_BALANCE_TOP)),
    WHITE_BALANCE_BOTTOM         (configFile.getInt("camera/bottom/whiteBalance", WHITE_BALANCE_TOP)),
    AUTO_EXPOSURE_BOTTOM         (configFile.getInt("camera/bottom/autoExposure", AUTO_EXPOSURE_TOP)),
    EXPOSURE_BOTTOM              (configFile.getInt("camera/bottom/exposure", EXPOSURE_TOP)),
    GAIN_BOTTOM                  (configFile.getInt("camera/bottom/gain", GAIN_TOP)),
    HORIZONTAL_FLIP_BOTTOM       (configFile.getInt("camera/bottom/horizontalFlip", HORIZONTAL_FLIP_TOP)),
    VERTICAL_FLIP_BOTTOM         (configFile.getInt("camera/bottom/verticalFlip", VERTICAL_FLIP_TOP)),
    SHARPNESS_BOTTOM             (configFile.getInt("camera/bottom/sharpness", SHARPNESS_TOP)),
    BACKLIGHT_COMPENSATION_BOTTOM(configFile.getInt("camera/bottom/backlightCompensation", BACKLIGHT_COMPENSATION_TOP)),
    log(_log),
    topCameraFd(-1),
    bottomCameraFd(-1),
    buffersTop(NULL),
    buffersBottom(NULL),
    numBuffersTop(0),
    numBuffersBottom(0),
    currentBufferTop(0),
    currentBufferBottom(0),
    v4l2BuffersTop(),
    v4l2BuffersBottom(),
    currentV4l2BufferTop(&v4l2BuffersTop[0]),
    currentV4l2BufferBottom(&v4l2BuffersBottom[0]),
    nextV4l2BufferTop(&v4l2BuffersTop[1]),
    nextV4l2BufferBottom(&v4l2BuffersBottom[1]),
    topCameraThread(),
    bottomCameraThread(),
    topThreadRunning(false),
    bottomThreadRunning(false),
    freshImage(),
    freshImageMutex(),
    freshImageTop(false),
    freshImageBottom(false),
    usingBottomCamera(true),
    enqueuedTop(false),
    enqueuedBottom(false) {
  // Create the condition variable and its mutex
  if (pthread_cond_init(&freshImage, NULL) < 0) {
    return;
  }
  if (pthread_mutex_init(&freshImageMutex, NULL) < 0) {
    return;
  }

}

NaoCamera::~NaoCamera() {
  // Stop the thread
  topThreadRunning = false;
  bottomThreadRunning = false;
  pthread_join(topCameraThread, NULL);
  pthread_join(bottomCameraThread, NULL);

  pthread_mutex_lock(&freshImageMutex);
  pthread_cond_signal(&freshImage);
  pthread_mutex_unlock(&freshImageMutex);

  pthread_cond_destroy(&freshImage);
  pthread_mutex_destroy(&freshImageMutex);

  deinitializeCamera(topCameraFd, &buffersTop, numBuffersTop);
  deinitializeCamera(bottomCameraFd, &buffersBottom, numBuffersBottom);
}

bool NaoCamera::initialize() {
  std::cout << "==================================================" << std::endl;
  std::cout << "=            NaoCamera::initialize()             =" << std::endl;
  std::cout << "==================================================" << std::endl;

  std::cout << "=            Initializing TOP camera             =" << std::endl;
  if (initializeCamera(topCameraFd, "/dev/video0", &buffersTop, numBuffersTop, currentBufferTop, 0, false)) {
    LOG_ERROR("Error initializing top camera.");
    return true;
  }
  std::cout << "==================================================" << std::endl;

  std::cout << "=           Initializing BOTTOM camera           =" << std::endl;
  if (initializeCamera(bottomCameraFd, "/dev/video1", &buffersBottom, numBuffersBottom, currentBufferBottom, 1, true)) {
    LOG_ERROR("Error initializing bottom camera.");
    return true;
  }
  std::cout << "==================================================" << std::endl;

  std::cout << "= Starting camera threads ...............";
  // Start the threads to read images
  if (pthread_create(&topCameraThread, NULL, startTopThread, this) < 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Error creating top camera thread.");
    return true;
  }
  if (pthread_create(&bottomCameraThread, NULL, startBottomThread, this) < 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Error creating bottom camera thread.");
    return true;
  }
  std::cout << ".. DONE =" << std::endl;
  std::cout << "==================================================" << std::endl;

  return false;
}

void NaoCamera::setCamera(bool useBottomCamera) {
  usingBottomCamera = useBottomCamera;
}

bool NaoCamera::initializeCamera(int & cameraFd,
                                 char const * cameraDevice,
                                 Buffer ** buffers,
                                 int & numBuffers,
                                 int & currentBuffer,
                                 int inputId,
                                 bool isBottomCamera) {
//  struct v4l2_capability cap;
  struct v4l2_format format;
  struct v4l2_streamparm streamparm;
  struct v4l2_requestbuffers reqbuf;
  struct v4l2_buffer buffer;
//  char formatName[5];
  int i;

  errno = 0;

  std::cout << "= Opening video device ..................";
  cameraFd = open(cameraDevice, O_RDWR);
  if (!cameraFd) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to open video device.");
    return true;
  }
  std::cout << ".. DONE =" << std::endl;

//  std::cout << "= Setting initial camera params .........";
//  if (setInitialCameraParams(cameraFd, isBottomCamera)) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Failed to set initial camera params.");
//    return true;
//  }
//  std::cout << ".. DONE =" << std::endl;
//
//  std::cout << "= Closing and re-opening video device ...";
//  close(cameraFd);
//  cameraFd = open(cameraDevice, O_RDWR);
//  if (!cameraFd) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Failed to re-open video device.");
//    return true;
//  }
//  std::cout << ".. DONE =" << std::endl;

//  std::cout << "= Setting input .........................";
//  int numInput = inputId;
//  if (ioctl(cameraFd, VIDIOC_S_INPUT, &numInput) < 0) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Failed to set input.");
//    return true;
//  }
//  std::cout << ".. DONE =" << std::endl;
//
//  std::cout << "= Querying capabilities .................";
//  if (ioctl(cameraFd, VIDIOC_QUERYCAP, &cap) < 0) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Failed to query capabilities.");
//    return true;
//  }
//  if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Video device cannot capture.");
//    return true;
//  }
//  std::cout << ".. DONE =" << std::endl;

  std::cout << "= Setting resolution ....................";
  memset(&format, 0, sizeof(struct v4l2_format));
  format.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (ioctl(cameraFd, VIDIOC_G_FMT, &format) < 0)
  {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to get format (1).");
    return true;
  }
  format.fmt.pix.width = IMAGE_WIDTH;
  format.fmt.pix.height = IMAGE_HEIGHT;
  format.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
  format.fmt.pix.field = V4L2_FIELD_NONE;
//  format.fmt.pix.bytesperline = format.fmt.pix.width * 2;
  if (ioctl(cameraFd, VIDIOC_S_FMT, &format) < 0)
  {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to set format.");
    return true;
  }
  if (format.fmt.pix.sizeimage != (unsigned int)IMAGE_SIZE) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Image size does not match.");
    return true;
  }
//  // Make sure the image format was set correctly
//  format.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
//  if (ioctl(cameraFd, VIDIOC_G_FMT, &format) < 0)
//  {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Failed to get format (2).");
//    return true;
//  }
//  int width = format.fmt.pix.width;
//  int height = format.fmt.pix.height;
//  int *formatNamePtr = (int *)formatName;
//  *formatNamePtr = format.fmt.pix.pixelformat;
//  formatName[4] = 0;
//  if ((width != IMAGE_WIDTH) || (height != IMAGE_HEIGHT) || (strcmp(formatName, "YUYV") != 0)) {
//    std::cout << " FAILED =" << std::endl;
//    LOG_ERROR("Error: camera acquiring image of size %dx%d in format %s.\n", width, height, formatName);
//  }
  std::cout << ".. DONE =" << std::endl;

  std::cout << "= Setting frame rate ....................";
  memset(&streamparm, 0, sizeof(struct v4l2_streamparm));
  streamparm.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (ioctl(cameraFd, VIDIOC_G_PARM, &streamparm) != 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to get stream parameters.");
    return true;
  }

  streamparm.parm.capture.timeperframe.numerator = 1;
  streamparm.parm.capture.timeperframe.denominator = FRAMES_PER_SECOND;
//  streamparm.parm.capture.capability = V4L2_CAP_TIMEPERFRAME;
  if (ioctl(cameraFd, VIDIOC_S_PARM, &streamparm) != 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to set frame rate.");
    return true;
  }
  std::cout << ".. DONE =" << std::endl;

  std::cout << "= Setting up buffers ....................";
  memset(&reqbuf, 0, sizeof (reqbuf));
  reqbuf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  reqbuf.memory = V4L2_MEMORY_MMAP;
  reqbuf.count = NUM_FRAME_BUFFERS;

  if (ioctl(cameraFd, VIDIOC_REQBUFS, &reqbuf) < 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to set buffer request mode.");
    return true;
  }
  numBuffers = reqbuf.count;

  *buffers = (Buffer*)calloc(numBuffers, sizeof(Buffer));
  if (*buffers == NULL) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to allocate memory for buffers.");
    return true;
  }

  for (i = 0; i < numBuffers; i++) {
    memset(&buffer, 0, sizeof(buffer));
    buffer.type = reqbuf.type;
    buffer.memory = V4L2_MEMORY_MMAP;
    buffer.index = i;
    if (ioctl(cameraFd, VIDIOC_QUERYBUF, &buffer) < 0) {
      std::cout << " FAILED =" << std::endl;
      LOG_ERROR("Error in VIDIOC_QUERYBUF.");
      return true;
    }
    (*buffers)[i].length = buffer.length;               /* remember for munmap() */
    (*buffers)[i].start  = mmap(NULL, buffer.length,
                             PROT_READ | PROT_WRITE, /* recommended */
                             MAP_SHARED,             /* recommended */
                             cameraFd, buffer.m.offset);
    if (MAP_FAILED == (*buffers)[i].start) {
      /* If you do not exit here you should unmap() and free()
       * the buffers mapped so far.                            */
      std::cout << " FAILED =" << std::endl;
      LOG_ERROR("Error in mmap for buffer %d.\n", i);
      for (int j = 0; j < i; j++) {
        munmap((*buffers)[j].start, (*buffers)[j].length);
      }
      return true;
    }
  }

  currentBuffer = 0;
  // Do we need this section?
  for (i = 0; i < numBuffers; i++) {
    memset(&buffer, 0, sizeof(buffer));
    buffer.memory = V4L2_MEMORY_MMAP;
    buffer.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buffer.length = (*buffers)[i].length;
    buffer.index = i;
  }

  std::cout << ".. DONE =" << std::endl;

//  queryCameraParams(cameraFd);

  std::cout << "= Setting camera params .................";
  if (setCameraParams(cameraFd, isBottomCamera)) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to set camera params.");
    return true;
  }
  std::cout << ".. DONE =" << std::endl;

  std::cout << "= Start streaming .......................";
  i = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (ioctl(cameraFd, VIDIOC_STREAMON, &i) < 0) {
    std::cout << " FAILED =" << std::endl;
    LOG_ERROR("Failed to begin streaming.");
    return true;
  }
  std::cout << ".. DONE =" << std::endl;

  return false;
}

bool NaoCamera::setCameraParams(const int & cameraFd, bool isBottomCamera) {
  if (setCameraParam(cameraFd, "HFlip", V4L2_CID_HFLIP, isBottomCamera ? HORIZONTAL_FLIP_BOTTOM : HORIZONTAL_FLIP_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "VFlip", V4L2_CID_VFLIP, isBottomCamera ? VERTICAL_FLIP_BOTTOM : VERTICAL_FLIP_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Auto Exposure 1", V4L2_CID_AUTO_EXPOSURE, 1)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Brightness", V4L2_CID_BRIGHTNESS, isBottomCamera ? BRIGHTNESS_BOTTOM : BRIGHTNESS_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Contrast", V4L2_CID_CONTRAST, isBottomCamera ? CONTRAST_BOTTOM : CONTRAST_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Saturation", V4L2_CID_SATURATION, isBottomCamera ? SATURATION_BOTTOM : SATURATION_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Hue", V4L2_CID_HUE, isBottomCamera ? HUE_BOTTOM : HUE_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Auto White Balance", V4L2_CID_AUTO_WHITE_BALANCE, isBottomCamera ? AUTO_WHITE_BALANCE_BOTTOM : AUTO_WHITE_BALANCE_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Sharpness", V4L2_CID_SHARPNESS, isBottomCamera ? SHARPNESS_BOTTOM : SHARPNESS_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Backlight Compensation", V4L2_CID_BACKLIGHT_COMPENSATION, isBottomCamera ? BACKLIGHT_COMPENSATION_BOTTOM : BACKLIGHT_COMPENSATION_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Auto Exposure", V4L2_CID_AUTO_EXPOSURE, isBottomCamera ? AUTO_EXPOSURE_BOTTOM : AUTO_EXPOSURE_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Exposure", V4L2_CID_EXPOSURE, isBottomCamera ? EXPOSURE_BOTTOM : EXPOSURE_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "Gain", V4L2_CID_GAIN, isBottomCamera ? GAIN_BOTTOM : GAIN_TOP)) {
    return true;
  }
  if (setCameraParam(cameraFd, "White Balance", V4L2_CID_DO_WHITE_BALANCE, isBottomCamera ? WHITE_BALANCE_BOTTOM : WHITE_BALANCE_TOP)) {
    return true;
  }

  return false;
}

bool NaoCamera::setCameraParam(const int & cameraFd, int id, int value) {
  return setCameraParam(cameraFd, NULL, id, value);
}

bool NaoCamera::setCameraParam(const int & cameraFd, char const *paramName, int id, int value) {
  struct v4l2_control control;

  bool done = false;
  int numTries = 0;
  while (!done) {
    control.id = id;
    control.value = value;
    if (ioctl(cameraFd, VIDIOC_S_CTRL, &control) < 0) {
      LOG_ERROR("Failed to set parameter %d to %d.\n", id, value);
      return true;
    }
    memset(&control, 0, sizeof(v4l2_control));
    control.id = id;
    if (ioctl(cameraFd, VIDIOC_G_CTRL, &control) < 0) {
      LOG_ERROR("Failed to get parameter %d.\n", id);
      return true;
    }
    if (control.value == value) {
      done = true;
    }
    else {
      numTries++;
      if (numTries % 10 == 0) {
        if (paramName != NULL) {
          LOG_INFO("Trying to set parameter %s to %d for the %d time but got %d", paramName, value, numTries, control.value);
        }
        else {
          LOG_INFO("Trying to set parameter %d to %d for the %d time but got %d", id, value, numTries, control.value);
        }
      }
      usleep(10000);
    }
  }

  return false;
}

void NaoCamera::deinitializeCamera(int & cameraFd, Buffer ** buffers, int numBuffers) {
  // Stop streaming
  int i = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (ioctl(cameraFd, VIDIOC_STREAMOFF, &i) < 0) {
    LOG_ERROR("Failed to stop streaming.");
  }
  // Unmap buffers
  for (int i = 0; i < numBuffers; i++) {
    munmap((*buffers)[i].start, (*buffers)[i].length);
  }
  free(*buffers);
  *buffers = NULL;
  // Close the device
  if (cameraFd != -1) {
    close(cameraFd);
  }
}

void NaoCamera::queryCameraParams(const int & cameraFd) {
  struct v4l2_queryctrl ctrl;
  for (int i = V4L2_CID_BASE; i <= V4L2_CID_LASTP1; i++)
  {
    ctrl.id = i;
    if (ioctl(cameraFd, VIDIOC_QUERYCTRL, &ctrl) == -1)
      continue;
    LOG_INFO("%d %s %d %d %d", i, ctrl.name, ctrl.minimum, ctrl.maximum, ctrl.default_value);
  }

  ctrl.id = V4L2_CID_AUTO_EXPOSURE;
  errno = 0;
  if (ioctl(cameraFd, VIDIOC_QUERYCTRL, &ctrl) == -1) {
    LOG_ERROR("Error querying about auto exposure.");
    perror(NULL);
  }
  else {
    LOG_INFO("%d %s %d %d %d", V4L2_CID_AUTO_EXPOSURE, ctrl.name, ctrl.minimum, ctrl.maximum, ctrl.default_value);
  }

//  LOG_INFO("Brightness: %d\nContrast: %d\nSaturation: %d\nHue: %d\nAuto White: %d\nWhite balance: %d\nExposure: %d\nGain: %d\nHFlip: %d\nVFlip: %d\nSharpness: %d\nBacklight: %d",
//         V4L2_CID_BRIGHTNESS,
//         V4L2_CID_CONTRAST,
//         V4L2_CID_SATURATION,
//         V4L2_CID_HUE,
//         V4L2_CID_AUTO_WHITE_BALANCE,
//         V4L2_CID_DO_WHITE_BALANCE,
//         V4L2_CID_EXPOSURE,
//         V4L2_CID_GAIN,
//         V4L2_CID_HFLIP,
//         V4L2_CID_VFLIP,
//         V4L2_CID_SHARPNESS,
//         V4L2_CID_BACKLIGHT_COMPENSATION);
}

bool NaoCamera::grabTopFrame() {
  struct v4l2_buffer *temp;

  // Dequeue top
  if (enqueuedTop) {
    LOG_DEBUG("Dequeue top");
    if (ioctl(topCameraFd, VIDIOC_DQBUF, nextV4l2BufferTop) < 0) {
      LOG_ERROR("Failed to dequeue buffer for top camera.");
      enqueuedTop = false;
      return true;
    }
    LOG_DEBUG("Dequeued top");

    temp = currentV4l2BufferTop;
    currentV4l2BufferTop = nextV4l2BufferTop;
    nextV4l2BufferTop    = temp;
    freshImageTop = true;
  }

  // Enqueue top
  memset(nextV4l2BufferTop, 0, sizeof(struct v4l2_buffer));
  nextV4l2BufferTop->type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  nextV4l2BufferTop->memory = V4L2_MEMORY_MMAP;
  nextV4l2BufferTop->index  = currentBufferTop;
  nextV4l2BufferTop->length = buffersTop[currentBufferTop].length;
  currentBufferTop++;
  if (currentBufferTop >= numBuffersTop) {
    currentBufferTop = 0;
  }
  LOG_DEBUG("Enqueue top");
  if (ioctl(topCameraFd, VIDIOC_QBUF, nextV4l2BufferTop) < 0) {
    LOG_ERROR("Failed to enqueue buffer for top camera.");
    enqueuedTop = false;
    return true;
  }
  LOG_DEBUG("Enqueued top");
  enqueuedTop = true;

  pthread_mutex_lock(&freshImageMutex);
  pthread_cond_signal(&freshImage);
  pthread_mutex_unlock(&freshImageMutex);

  return false;
}

bool NaoCamera::grabBottomFrame() {
  struct v4l2_buffer *temp;

  // Dequeue bottom
  if (enqueuedBottom) {
    LOG_DEBUG("Dequeue bottom");
    if (ioctl(bottomCameraFd, VIDIOC_DQBUF, nextV4l2BufferBottom) < 0) {
      LOG_ERROR("Failed to dequeue buffer for bottom camera.");
      enqueuedBottom = false;
      return true;
    }
    LOG_DEBUG("Dequeued bottom");

    temp = currentV4l2BufferBottom;
    currentV4l2BufferBottom = nextV4l2BufferBottom;
    nextV4l2BufferBottom    = temp;
    freshImageBottom = true;
  }

  // Enqueue bottom
  memset(nextV4l2BufferBottom, 0, sizeof(struct v4l2_buffer));
  nextV4l2BufferBottom->type   = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  nextV4l2BufferBottom->memory = V4L2_MEMORY_MMAP;
  nextV4l2BufferBottom->index  = currentBufferBottom;
  nextV4l2BufferBottom->length = buffersBottom[currentBufferBottom].length;
  currentBufferBottom++;
  if (currentBufferBottom >= numBuffersBottom) {
    currentBufferBottom = 0;
  }
  LOG_DEBUG("Enqueue bottom");
  if (ioctl(bottomCameraFd, VIDIOC_QBUF, nextV4l2BufferBottom) < 0) {
    LOG_ERROR("Failed to enqueue buffer for bottom camera.");
    return true;
  }
  LOG_DEBUG("Enqueued bottom");
  enqueuedBottom = true;

  pthread_mutex_lock(&freshImageMutex);
  pthread_cond_signal(&freshImage);
  pthread_mutex_unlock(&freshImageMutex);

  return false;
}

char const * NaoCamera::getImage(bool & newImage) {
  newImage = true;
  char const *topImage = NULL, *bottomImage = NULL;
  getBothImages(&topImage, &bottomImage);

  return (usingBottomCamera ? bottomImage : topImage);
}

bool NaoCamera::getBothImages(char const **topImage, char const **bottomImage) {
  pthread_mutex_lock(&freshImageMutex);
  pthread_cond_wait(&freshImage, &freshImageMutex);
  if (!freshImageTop || !freshImageBottom) {
    pthread_mutex_unlock(&freshImageMutex);
    *topImage = NULL;
    *bottomImage = NULL;
    return false;
  }
  *topImage    = static_cast<char const *>(buffersTop[currentV4l2BufferTop->index].start);
  *bottomImage = static_cast<char const *>(buffersBottom[currentV4l2BufferBottom->index].start);
  freshImageTop    = false;
  freshImageBottom = false;
  pthread_mutex_unlock(&freshImageMutex);

  return true;
}

int NaoCamera::getImageSize() {
  return IMAGE_SIZE;
}

void NaoCamera::runTopThread() {
  topThreadRunning = true;
  while (topThreadRunning) {
    if (grabTopFrame()) {
      LOG_ERROR("Failed to grab top image.");
    }
    usleep(1000);
  }
}

void NaoCamera::runBottomThread() {
  bottomThreadRunning = true;
  while (bottomThreadRunning) {
    if (grabBottomFrame()) {
      LOG_ERROR("Failed to grab bottom image.");
    }
    usleep(1000);
  }
}

void * NaoCamera::startTopThread(void *ptr) {
  ((NaoCamera *)ptr)->runTopThread();
  return NULL;
}

void * NaoCamera::startBottomThread(void *ptr) {
  ((NaoCamera *)ptr)->runBottomThread();
  return NULL;
}
