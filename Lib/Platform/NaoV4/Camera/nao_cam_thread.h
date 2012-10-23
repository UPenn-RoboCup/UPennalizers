#ifndef __NAO_CAM_THREAD_H__
#define __NAO_CAM_THREAD_H__



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

typedef unsigned char uint8;
typedef unsigned int uint32;

#define WIDTH 640
#define HEIGHT 480

#define NUM_FRAME_BUFFERS 4

#define NCAMERA_DEVICES 2


typedef struct {
  int count; 
  int select;
  double time;
  double joint[22];
} CAMERA_STATUS; 

int construct_parameter_map(int fd, std::map<std::string, int> &paramMap);

#ifdef __cplusplus
extern "C" {
#endif

void write_yuyv(uint32 *ptr, int len);
int nao_cam_thread_init();
void nao_cam_thread_cleanup();

void nao_cam_thread_camera_select(int bottom);
int nao_cam_thread_set_control(const char *name, int val);
int nao_cam_thread_get_control(const char *name);

uint32 *nao_cam_thread_get_image();
int nao_cam_thread_get_height();
int nao_cam_thread_get_width();
int nao_cam_thread_get_selected_camera();

#ifdef __cplusplus
}
#endif

#endif 
