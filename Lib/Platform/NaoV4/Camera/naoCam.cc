#include "naoCam.h"
#include "naoCamThread.h"

#include <string>

typedef unsigned char uint8;
typedef unsigned int uint32;

// Defined in naoCamThread.cc:
extern uint32 *bufArray;
extern CAMERA_STATUS *cameraStatus;

int init = 0;

static int lua_get_height(lua_State *L) {
  int height = nao_cam_thread_get_height();
  lua_pushinteger(L, height);
  return 1;
}

static int lua_get_width(lua_State *L) {
  int width = nao_cam_thread_get_width();
  lua_pushinteger(L, width);
  return 1;
}

static int lua_get_image(lua_State *L) {
  uint32* image = bufArray;
  //write_yuyv(image, 640*480*4/2);
  lua_pushlightuserdata(L, image);
  return 1;
}

static int lua_camera_status(lua_State *L) {
  lua_createtable(L, 0, 4);

  lua_pushinteger(L, cameraStatus->count);
  lua_setfield(L, -2, "count");
  lua_pushinteger(L, cameraStatus->select);
  lua_setfield(L, -2, "select");
  lua_pushnumber(L, cameraStatus->time);
  lua_setfield(L, -2, "time");

  lua_createtable(L, 22, 0);
  for (int i = 0; i < 22; i++) {
    lua_pushnumber(L, cameraStatus->joint[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_setfield(L, -2, "joint");

  return 1;
}

static int lua_select_camera(lua_State *L) {
  int bottom = luaL_checkint(L, 1);
  nao_cam_thread_camera_select(bottom);
  return 1;
}

static int lua_selected_camera(lua_State *L) {
  int bottom = nao_cam_thread_get_selected_camera();
  lua_pushinteger(L, bottom);
  return 1;
}

static int lua_set_param(lua_State *L) {
  const char *param = luaL_checkstring(L, 1);
  double value = luaL_checknumber(L, 2);

  int ret = nao_cam_thread_set_control(param, value);
  lua_pushnumber(L, ret);

  return 1;
}

static int lua_get_param(lua_State *L) {
  const char *param = luaL_checkstring(L, 1);

  double ret = nao_cam_thread_get_control(param);
  lua_pushnumber(L, ret);

  return 1;
}

static const struct luaL_reg camera_lib [] = {
  {"get_height", lua_get_height},
  {"get_width", lua_get_width},
  {"get_image", lua_get_image},
  {"get_camera_status", lua_camera_status},
  {"get_select", lua_selected_camera},
  {"select_camera", lua_select_camera},
  {"set_param", lua_set_param},
  {"get_param", lua_get_param},


  {NULL, NULL}
};

extern "C"
int luaopen_NaoCam (lua_State *L) {
  luaL_register(L, "camera", camera_lib);
  if (!init) {
    if (nao_cam_thread_init() == 0)
      init = 1;
  }
  
  return 1;
}
