/*
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
  	: Stephen McGill 10/10
    : Yida Zhang 05/13
*/
			
#ifndef v4l2driver_h_DEFINED
#define v4l2driver_h_DEFINED

#define INVERT 0
#define NBUFFERS 2

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#include <unistd.h>
#include <fcntl.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <sys/mman.h>

#include <assert.h>
#include <ctype.h>

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

/* struct for query ctrl and menu */
typedef struct query_node query_node;
struct query_node {
    char * key;
    void * value;
    query_node * next;
};

/* struct for uvc camera object */
typedef struct {
    int fd;
    int init;
    int width;
    int height;
    int count;
    const char * pixelformat; 
    void ** buffer;
    int *buf_len;
    query_node *ctrl_map; 
    query_node *menu_map;
} v4l2_device;

int v4l2_error(const char *error_msg);
int v4l2_open(const char *device);
int v4l2_init(v4l2_device * vdev);
int v4l2_close(v4l2_device * vdev);
int v4l2_stream_on(v4l2_device * vdev);
int v4l2_stream_off(v4l2_device * vdev);
int v4l2_get_ctrl(v4l2_device * vdev, const char *name, int *value);
int v4l2_set_ctrl(v4l2_device * vdev, const char *name, int value);
int v4l2_read_frame(v4l2_device * vdev);
int v4l2_init_mmap(v4l2_device * vdev);
int v4l2_uninit_mmap(v4l2_device * vdev);
int v4l2_close_query(v4l2_device * vdev);

//int v4l2_set_ctrl_by_id(int id, int value);
//int v4l2_read_frame(void);
//uint8_t* yuyv_rotate(uint8_t* frame);

#endif
