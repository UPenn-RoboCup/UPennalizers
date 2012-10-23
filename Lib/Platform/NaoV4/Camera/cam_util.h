#ifndef __CAM_UTIL_H__
#define __CAM_UTIL_H__

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

typedef unsigned char uint8;
typedef unsigned int uint32;


// initializes the camera at the given dev path
//  return the file descriptor on success and -1 on error
int init_camera(const char *dev, int width, int height);


// initialize memory map for image buffer
//  return number of buffers on success and -1 on error
int init_mmap(int fd, struct v4l2_buffer **v4l2buffers, uint32 ***imbuffers, int nbufDesired);


// iterate over all possible camera parameters and print any 
//  parameters that are supported
void query_camera_params(int fd);


// attempt to set camera parameter in a loop
//  return 0 on success and -1 on failure
int set_camera_param(int fd, int id, int value);

// attempt to get camera parameter 
//  return 0 on success and -1 on failure
int get_camera_param(int fd, int id, int &value);

// starts the actual camera stream
//  return 0 on success and -1 on failure
int start_stream(int fd);


// gets the next frame from the camera if one is available
//  fd - camera file descriptor
//  v4l2buffers - array of v4l2 buffer structs for this camera stream
//  currV4l2Buf - pointer to the current v4l2 buffer
//  nextV4l2Buf - pointer to the next v4l2 buffer
//  nextV4l2Buf - pointer to the next v4l2 buffer
//  nbuf - total number of v4l2 buffers
//  enqueued - flag indicating if a buffer is currently queued
//  ibuf - index of the current v4l2 buffer 
//  nframe - counter for total number of frames 
//
//  return 0 on success and -1 on failure
//
int grab_frame(int fd, struct v4l2_buffer *v4l2buffers, struct v4l2_buffer *currV4l2Buf, v4l2_buffer *nextV4l2Buf, int nbuf, int &enqueued, int &ibuf, int &nframe);

#endif
