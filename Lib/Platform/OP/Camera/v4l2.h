#include <stdlib.h>

int v4l2_open(const char *device);
int v4l2_set_ctrl(const char *name, int value);
int v4l2_set_ctrl_by_id(int id, int value);
int v4l2_get_ctrl(const char *name, int *value);
int v4l2_get_height();
int v4l2_get_width();
int v4l2_init( int resolution );
int v4l2_stream_on();
int v4l2_read_frame();
void *v4l2_get_buffer(int index, size_t *length);
int v4l2_stream_off();
int v4l2_close();
