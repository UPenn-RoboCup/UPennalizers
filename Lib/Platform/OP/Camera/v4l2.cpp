// C++ routines to access V4L2 camera

#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>
#include <assert.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/videodev2.h>
#include <cctype>
#include <string>
#include <algorithm>
#include <vector>
#include <map>
#include <string.h>
#include <stdint.h>

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

//added

int video_fd = -1;
int nbuffer = 2;
int width = 320;
int height = 240;
char invert = 1;
//int width = 640;
//int height = 480;



uint8_t* yuyv_rotate(uint8_t* frame, int width, int height);

struct buffer {
  void * start;
  size_t length;
};

std::map<std::string, struct v4l2_queryctrl> ctrlMap;
std::map<std::string, struct v4l2_querymenu> menuMap;

std::vector<struct buffer> buffers;

static int xioctl(int fd, int request, void *arg) {
  int r;
  do
    r = ioctl(fd, request, arg);
  while (r == -1 && errno == EINTR);
  return r;
}

void string_tolower(std::string &str) {
  std::transform(str.begin(), 
      str.end(), 
      str.begin(),
      (int(*)(int)) std::tolower);
}

int v4l2_error(const char *error_msg) {
  if (video_fd >= 0)
    close(video_fd);
  video_fd = 0;
  int x = errno;
  fprintf(stderr, "Err: %d\n", x);
  fprintf(stderr, "V4L2 error: %s\n", error_msg);
  return -2;
}

int v4l2_query_menu(struct v4l2_queryctrl &queryctrl) {
  struct v4l2_querymenu querymenu;

  querymenu.id = queryctrl.id;
  for (querymenu.index = queryctrl.minimum;
      querymenu.index <= queryctrl.maximum;
      querymenu.index++) {
    if (ioctl(video_fd, VIDIOC_QUERYMENU, &querymenu) == 0) {
      fprintf(stdout, "querymenu: %s\n", querymenu.name);
      menuMap[(char *)querymenu.name] = querymenu;
    }
    else {
      // error
    }
  }
  return 0;
}

int v4l2_query_ctrl(unsigned int addr_begin, unsigned int addr_end) {
  struct v4l2_queryctrl queryctrl;
  std::string key;

  for (queryctrl.id = addr_begin;
      queryctrl.id < addr_end;
      queryctrl.id++) {
    if (ioctl(video_fd, VIDIOC_QUERYCTRL, &queryctrl) == -1) {
      if (errno == EINVAL)
        continue;
      else
        return v4l2_error("Could not query control");
    }
    fprintf(stdout, "queryctrl: \"%s\" 0x%x\n", 
        queryctrl.name, queryctrl.id);

    switch (queryctrl.type) {
      case V4L2_CTRL_TYPE_MENU:
        v4l2_query_menu(queryctrl);
        // fall throught
      case V4L2_CTRL_TYPE_INTEGER:
      case V4L2_CTRL_TYPE_BOOLEAN:
      case V4L2_CTRL_TYPE_BUTTON:
        key = (char *)queryctrl.name;
        string_tolower(key);
        ctrlMap[key] = queryctrl;
        break;
      default:
        break;
    }
  }
}

int v4l2_set_ctrl(const char *name, int value) {
  std::string key(name);
  string_tolower(key);
  std::map<std::string, struct v4l2_queryctrl>::iterator ictrl
    = ctrlMap.find(name);
  if (ictrl == ctrlMap.end()) {
    fprintf(stderr, "Unknown control '%s'\n", name);
    return -1;
  }


  int v4l2_cid_base=0x00980900;

  fprintf(stderr, "Setting ctrl %s, id %d\n", name,(ictrl->second).id-v4l2_cid_base);
  struct v4l2_control ctrl;
  ctrl.id = (ictrl->second).id;
  ctrl.value = value;
  int ret=xioctl(video_fd, VIDIOC_S_CTRL, &ctrl);
  return ret;
}


//added to manually set parameters not shown on query lists
int v4l2_set_ctrl_by_id(int id, int value){
  struct v4l2_control ctrl;
  ctrl.id = id;
  ctrl.value = value;
  int v4l2_cid_base=0x00980900;

  fprintf(stderr, "Setting id %d value %d\n", id-v4l2_cid_base,value);

  int ret=xioctl(video_fd, VIDIOC_S_CTRL, &ctrl);
  return ret;
}



int v4l2_get_ctrl(const char *name, int *value) {
  std::string key(name);
  string_tolower(key);
  std::map<std::string, struct v4l2_queryctrl>::iterator ictrl
    = ctrlMap.find(name);
  if (ictrl == ctrlMap.end()) {
    fprintf(stderr, "Unknown control '%s'\n", name);
    return -1;
  }

  struct v4l2_control ctrl;
  ctrl.id = (ictrl->second).id;
  int ret=xioctl(video_fd, VIDIOC_G_CTRL, &ctrl);
  *value = ctrl.value;
  return ret;
}

// Change on Dec 30, 2010 from Steve McGill
// Default is opening in blocking mode
int v4l2_open(const char *device) {
  if (device == NULL) {
    // Default video device name
    device = "/dev/video0";
  }

  // Open video device
  if ((video_fd = open(device, O_RDWR|O_NONBLOCK, 0)) == -1)
    //  if ((video_fd = open(device, O_RDWR, 0)) == -1)
    return v4l2_error("Could not open video device");
  fprintf(stdout, "open: %d\n", video_fd);

  return 0;
}

int v4l2_init_mmap() {
  struct v4l2_requestbuffers req;
  req.count = nbuffer;
  req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  req.memory = V4L2_MEMORY_MMAP;
  if (xioctl(video_fd, VIDIOC_REQBUFS, &req))
    return v4l2_error("VIDIOC_REQBUFS");
  if (req.count < 2)
    return v4l2_error("Insufficient buffer memory\n");

  buffers.resize(req.count);
  for (int i = 0; i < req.count; i++) {
    struct v4l2_buffer buf;
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    if (xioctl(video_fd, VIDIOC_QUERYBUF, &buf) == -1)
      return v4l2_error("VIDIOC_QUERYBUF");
    buffers[i].length = buf.length;
    buffers[i].start = 
      mmap(NULL, // start anywhere
          buf.length,
          PROT_READ | PROT_WRITE, // required
          MAP_SHARED, // recommended
          video_fd,
          buf.m.offset);
    if (buffers[i].start == MAP_FAILED)
      return v4l2_error("mmap");
  }
  return 0;
}

int v4l2_uninit_mmap() {
  for (int i = 0; i < buffers.size(); i++) {
    if (munmap(buffers[i].start, buffers[i].length) == -1)
      return v4l2_error("munmap");
  }
  buffers.clear();
}

int v4l2_init(int resolution) {

  if( resolution == 1 ){
    width = 640;
    height = 480;
  } else {
    width = 320;
    height = 240;
  }

  struct v4l2_capability video_cap;
  if (xioctl(video_fd, VIDIOC_QUERYCAP, &video_cap) == -1)
    return v4l2_error("VIDIOC_QUERYCAP");
  if (!(video_cap.capabilities & V4L2_CAP_VIDEO_CAPTURE))
    return v4l2_error("No video capture device");
  if (!(video_cap.capabilities & V4L2_CAP_STREAMING))
    return v4l2_error("No capture streaming");

  struct v4l2_format video_fmt;
  video_fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;

  // Get the current format
  if (xioctl(video_fd, VIDIOC_G_FMT, &video_fmt) == -1)
    return v4l2_error("VIDIOC_G_FMT");

  fprintf(stdout, "Current Format\n");
  fprintf(stdout, "+------------+\n");
  fprintf(stdout, "width: %u\n", video_fmt.fmt.pix.width);
  fprintf(stdout, "height: %u\n", video_fmt.fmt.pix.height);
  fprintf(stdout, "pixel format: %u\n", video_fmt.fmt.pix.pixelformat);
  fprintf(stdout, "pixel field: %u\n", video_fmt.fmt.pix.field);


  video_fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  video_fmt.fmt.pix.width       = width;
  video_fmt.fmt.pix.height      = height;
  video_fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_YUYV;
  //video_fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_UYVY; // iSight
  video_fmt.fmt.pix.field       = V4L2_FIELD_ANY;
  if (xioctl(video_fd, VIDIOC_S_FMT, &video_fmt) == -1)
    v4l2_error("VIDIOC_S_FMT");

  // Query V4L2 controls:
  int addr_end = 22;
  v4l2_query_ctrl(V4L2_CID_BASE,
      V4L2_CID_LASTP1);
  v4l2_query_ctrl(V4L2_CID_PRIVATE_BASE,
      V4L2_CID_PRIVATE_BASE+20);
  v4l2_query_ctrl(V4L2_CID_CAMERA_CLASS_BASE+1,
      V4L2_CID_CAMERA_CLASS_BASE+addr_end);

  // Logitech specific controls:
  v4l2_query_ctrl(V4L2_CID_FOCUS,
      V4L2_CID_FOCUS+1);
  v4l2_query_ctrl(V4L2_CID_LED1_MODE,
      V4L2_CID_LED1_MODE+1);
  v4l2_query_ctrl(V4L2_CID_LED1_FREQUENCY,
      V4L2_CID_LED1_FREQUENCY+1);
  v4l2_query_ctrl(V4L2_CID_DISABLE_PROCESSING,
      V4L2_CID_DISABLE_PROCESSING+1);
  v4l2_query_ctrl(V4L2_CID_RAW_BITS_PER_PIXEL,
      V4L2_CID_RAW_BITS_PER_PIXEL+1);

  //hack
  v4l2_query_ctrl(V4L2_CID_BASE,
      V4L2_CID_BASE+500);

  /*
  // Flip the video
  // This control is not supported
  struct v4l2_queryctrl queryctrl;
  memset( &queryctrl, 0, sizeof(queryctrl) );
  queryctrl.id = V4L2_CID_VFLIP;
  printf("Video FD: %d.  CID: %x\n", video_fd, queryctrl.id);
  if (0 == ioctl (video_fd, VIDIOC_QUERYCTRL, &queryctrl)) {
  if (queryctrl.flags & V4L2_CTRL_FLAG_DISABLED)
  printf("Disabled the VFLIP control...\n");
  printf ("Control %s\n", queryctrl.name);
  } else {
  if (errno == EINVAL)
  printf("Error in the Input Value...\n");
  perror ("VIDIOC_QUERYCTRL");
  exit (EXIT_FAILURE);
  }
  struct v4l2_control ctrl;
  ctrl.id = V4L2_CID_VFLIP;
  ctrl.value = 1;
  int ret = xioctl(video_fd, VIDIOC_S_CTRL, &ctrl);
  printf("Return value on VFLIP: %d\n", ret);
   */


  // Initialize memory map
  v4l2_init_mmap();

  return 0;
}

int v4l2_stream_on() {
  for (int i = 0; i < buffers.size(); i++) {
    struct v4l2_buffer buf;
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;
    if (xioctl(video_fd, VIDIOC_QBUF, &buf) == -1)
      return v4l2_error("VIDIOC_QBUF");
  }

  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(video_fd, VIDIOC_STREAMON, &type) == -1)
    return v4l2_error("VIDIOC_STREAMON");

  return 0;
}

int v4l2_stream_off() {
  enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  if (xioctl(video_fd, VIDIOC_STREAMOFF, &type) == -1)
    return v4l2_error("VIDIOC_STREAMOFF");

  return 0;
}

void * v4l2_get_buffer(int index, size_t *length) {
  if (length != NULL)
    *length = buffers[index].length;
  if( invert==1 ) {
    return (void *) 
	yuyv_rotate( (uint8_t*)buffers[index].start, width, height );
  }
  return buffers[index].start;
}

int v4l2_read_frame() {
  struct v4l2_buffer buf;
  buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
  buf.memory = V4L2_MEMORY_MMAP;
  if (xioctl(video_fd, VIDIOC_DQBUF, &buf) == -1) {
    switch (errno) {
      case EAGAIN:
        // Debug line
        //fprintf(stdout, "no frame available\n");
        return -1;
      case EIO:
        // Could ignore EIO
        // fall through
      default:
        return v4l2_error("VIDIOC_DQBUF");
    }
  }
  assert(buf.index < buffers.size());

  // process image
  // Give out the pointer, and hope they give it back to us soon!
  void *ptr = buffers[buf.index].start;

  if (xioctl(video_fd, VIDIOC_QBUF, &buf) == -1){
    fprintf(stderr, "QBUF Problem %d\n", errno);
    fprintf(stderr, "Buf Index: %d\n",buf.index);
    fprintf(stderr, "Buf Type: 0x%X\n", buf.type);
    // Sleep a little and try again?
    return v4l2_error("VIDIOC_QBUF");
  }

  return buf.index;
}

int v4l2_close() {
  v4l2_uninit_mmap();
  if (close(video_fd) == -1)
    v4l2_error("Closing video device");
  video_fd = -1;
}

int v4l2_get_width(){
  return width;
}

int v4l2_get_height(){
  return height;
}

void row_swap( uint32_t* row1addr, uint32_t* row2addr, int width ){

  // Swap into a temporary space
  int copy_amt = (width/2)*sizeof(uint32_t);
  uint32_t buffer_row[width/2];

  memcpy( buffer_row, row1addr, copy_amt ); // Copy 1 into tmp
  memcpy( row1addr, row2addr, copy_amt ); //Copy 2 into 1
  memcpy( row2addr, buffer_row, copy_amt ); // Copy tmp into 2
    
}


void yuyv_px_swap( uint8_t* ptr1, uint8_t* ptr2 ){
  uint8_t tmp_px[4]; // two pixels here

  // Put ptr1 into temporary space and swap Y values
  tmp_px[0] = ptr1[2];
  tmp_px[1] = ptr1[1];
  tmp_px[2] = ptr1[0];
  tmp_px[3] = ptr1[3];

  // Put ptr2 into ptr1
  ptr1[0] = ptr2[2];
  ptr1[1] = ptr2[1];
  ptr1[2] = ptr2[0];
  ptr1[3] = ptr2[3];

  // Copy tmp_px into ptr2
  memcpy( ptr2, tmp_px, 4*sizeof(uint8_t) );
}

uint8_t* yuyv_rotate(uint8_t* frame, int width, int height) {
  int i;
  //SJ: I maintain a second buffer here
  //So that we do not directly rewrite on camera buffer address

  static uint8_t frame2[640*480*4];

  //printf("WIDTH HEIGHT:%d %d\n",width,height);

  int siz = width*height/2;
  for (int i=0;i<siz/2;i++){
    int index_1 = i*4;
    int index_2 = (siz-1-i)*4;
    uint8_t x1,x2,x3,x4;
    frame2[index_2] = frame[index_1+2];
    frame2[index_2+1] = frame[index_1+1];
    frame2[index_2+2] = frame[index_1];
    frame2[index_2+3] = frame[index_1+3];

    frame2[index_1]=frame[index_2+2];
    frame2[index_1+1]=frame[index_2+1];
    frame2[index_1+2]=frame[index_2];
    frame2[index_1+3]=frame[index_2+3];

  }
  return frame2;


/*
  uint32_t* frame32 = (uint32_t*)frame;

  // Swap top and bottom
  for(i=0;i<height/2;i++){

    uint32_t* row1addr = frame32+i*width/2;
    uint32_t* row2addr = frame32+(height-1-i)*width/2;
    row_swap( row1addr, row2addr, width );
  
    // Swap the yuyv byte order for the swapped rows
    int j;
    for(j=0;j<width/4;j++){// width/4 since frame32 is width/2 long
      yuyv_px_swap( (uint8_t*)(row1addr+j), (uint8_t*)(row1addr+width/2-1-j) );
    }
    for(j=0;j<width/4;j++){// width/4 since frame32 is width/2 long
      yuyv_px_swap( (uint8_t*)(row2addr+j), (uint8_t*)(row2addr+width/2-1-j) );
    }

  }
*/

}

