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

