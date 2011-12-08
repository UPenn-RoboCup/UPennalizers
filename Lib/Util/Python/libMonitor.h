#ifndef __LIBMONITOR
#define __LIBMONITOR

#define IP "192.168.0.255"
#define PORT 111111
#define MDELAY 2
#define TTL 16
#define MAX_LENGTH 160000 //Needed for 640*480 yuyv
int init_comm();
void close_comm();
void process_message();
int send_message( void* data, int num_data );
int getQueueSize();
int queueIsEmpty();
int get_front_size();
const void* get_front_data();
void pop_data();

#endif
