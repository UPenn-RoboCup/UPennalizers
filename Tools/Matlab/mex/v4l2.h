/*
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
  	: Stephen McGill 10/10
*/
			
#ifndef v4l2driver_h_DEFINED
#define v4l2driver_h_DEFINED

#define INVERT 0
#define WIDTH 640
#define HEIGHT 480
#define NBUFFERS 2
#define VIDEO_DEVICE "/dev/video0"

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <sys/mman.h>

#include <string>
#include <vector>

#include <assert.h>
#include <cctype>
#include <algorithm>
#include <map>

#include <linux/videodev2.h>

// Logitech UVC controls
#ifndef V4L2_CID_FOCUS
#define V4L2_CID_FOCUS 0x0A046D04
#endif
#ifndef V4L2_CID_LED1_MODE
#define V4L2_CID_LED1_MODE 0x0A046D05
#endif
#ifndef V4L2_CID_LED1_FREQUENCY
#define V4L2_CID_LED1_FREQUENCY 0x0A046D06
#endif
#ifndef V4L2_CID_DISABLE_PROCESSING
#define V4L2_CID_DISABLE_PROCESSING 0x0A046D71
#endif
#ifndef V4L2_CID_RAW_BITS_PER_PIXEL
#define V4L2_CID_RAW_BITS_PER_PIXEL 0x0A046D72
#endif


int v4l2_open(const char *device);
int v4l2_set_ctrl(const char *name, int value);
int v4l2_set_ctrl_by_id(int id, int value);
int v4l2_get_ctrl(const char *name, int *value);
int v4l2_get_height(void);
int v4l2_get_width(void);
int v4l2_init(void);
int v4l2_stream_on(void);
int v4l2_read_frame(void);
void *v4l2_get_buffer(int index, size_t *length);
int v4l2_stream_off(void);
int v4l2_close(void);
uint8_t* yuyv_rotate(uint8_t* frame);

#endif
