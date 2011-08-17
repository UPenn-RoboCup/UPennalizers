#ifndef naoCamThread_h_DEFINED
#define naoCamThread_h_DEFINED

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
  int count; 
  int select;
  double time;
  double joint[22];
} CAMERA_STATUS; 

int nao_cam_thread_init();
void nao_cam_thread_cleanup();

void nao_cam_thread_camera_select_slow(int bottom);
void nao_cam_thread_camera_select_fast(int bottom);
int nao_cam_thread_set_control(const char *name, int val);
int nao_cam_thread_get_control(const char *name);

int nao_cam_thread_get_height();
int nao_cam_thread_get_width();
int nao_cam_thread_get_selected_camera();

#ifdef __cplusplus
}
#endif

#endif // naoCamThread_h_DEFINED
