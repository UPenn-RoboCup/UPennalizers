/*
  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
  	    : Stephen McGill 10/10
        : Yida Zhang 05/13
*/

#ifdef _cplusplus
extern "C" {
#endif
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>
#ifdef _cplusplus
}
#endif

#include "v4l2.h"
#include "timeScalar.h"

#include <stdint.h>
#include <stdio.h>

/* metatable name for uvc */
#define MT_NAME "uvc_mt"

/* default video device if not named */
#define VIDEO_DEVICE "/dev/video0"

/* default image size */
#define WIDTH 640
#define HEIGHT 480

static v4l2_device * lua_checkuvc(lua_State *L, int narg) {
    void *ud = luaL_checkudata(L, narg, MT_NAME);
    luaL_argcheck(L, ud != NULL, narg, "invalid uvc userdata");
    return (v4l2_device *) ud;
}

static int lua_uvc_index(lua_State *L) {
    if (!lua_getmetatable(L, 1)) { /* push metatable */
        lua_pop(L, 1); 
        return 0;
    }
    lua_pushvalue(L, 2); /* copy key */
    lua_rawget(L, -2); /* get metatable function */
    lua_remove(L, -2);  /* delte metatable */
    return 1;
}

static int lua_uvc_delete(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    if (ud->init)
        v4l2_stream_off(ud);
        if (v4l2_close(ud) != 0)
            luaL_error(L, "Closing video device Error");
    return 0;
}

static int lua_uvc_init(lua_State *L) {
    const char * video_device = luaL_optstring(L, 1, VIDEO_DEVICE);
    v4l2_device *ud = (v4l2_device *)lua_newuserdata(L, sizeof(v4l2_device));
    ud->width = luaL_optint(L, 2, WIDTH);
    ud->height = luaL_optint(L, 3, HEIGHT);
    ud->pixelformat = luaL_optstring(L, 4, "yuyv");
    
    ud->init = 0;
    ud->count = 0;
    ud->ctrl_map = NULL;
    ud->menu_map = NULL;
    ud->buf_len = NULL;
    ud->buffer = NULL;

    ud->fd = v4l2_open(video_device);

    if (ud->fd > 0){
        ud->init = 1;
        v4l2_init(ud);
        v4l2_stream_on(ud);
    } else
        luaL_error(L, "Could not open video device");
    fprintf(stdout, "open video device %d\n", ud->fd);
    fflush(stdout);

    luaL_getmetatable(L, MT_NAME);
    lua_setmetatable(L, -2);
    return 1;
}

static int lua_uvc_fd(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    if (ud->init)
        lua_pushinteger(L, ud->fd);
    else
        luaL_error(L, "uvc not init");
    return 1;
}

static int lua_uvc_get_width(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    if (ud->init)
        lua_pushinteger(L, ud->width);
    else
        luaL_error(L, "uvc not init");
    return 1;
}

static int lua_uvc_get_height(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    if (ud->init)
        lua_pushinteger(L, ud->height);
    else
        luaL_error(L, "uvc not init");
    return 1;
}

static int lua_uvc_set_param(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    const char *param = luaL_checkstring(L, 2);
    int value = luaL_checkint(L, 3);
 
    int ret = v4l2_set_ctrl(ud, param, value);
    lua_pushnumber(L, ret);
    return 1;
}

static int lua_uvc_get_param(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    const char *param = luaL_checkstring(L, 2);
    int value;
    v4l2_get_ctrl(ud, param, &value);
    lua_pushnumber(L, value);
    return 1;
}

static int lua_uvc_get_raw(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    int buf_num = v4l2_read_frame(ud);
    if( buf_num < 0 ){
      lua_pushnumber(L,buf_num);
      return 1;
    }
    uint32_t* image = (uint32_t*)ud->buffer[buf_num];
    ud->count ++;
    lua_pushlightuserdata(L, image);
    lua_pushnumber(L, ud->buf_len[buf_num]);
    lua_pushnumber(L, ud->count);
    lua_pushnumber(L, time_scalar());
    return 4;
}

static int lua_uvc_reset_resolution(lua_State *L) {
    v4l2_device *ud = lua_checkuvc(L, 1);
    ud->width = luaL_checkint(L, 2);
    ud->height = luaL_checkint(L, 3);
    ud->pixelformat = luaL_optstring(L, 4, "yuyv");

    v4l2_stream_off(ud);
    v4l2_uninit_mmap(ud);
    v4l2_close_query(ud);

    v4l2_init(ud);
    v4l2_stream_on(ud);
    return 1;
}

static const struct luaL_Reg uvc_functions [] = {
    {"init", lua_uvc_init},
    {NULL, NULL}
};

static const struct luaL_Reg uvc_methods [] = {
    {"descriptor", lua_uvc_fd},
    {"close", lua_uvc_delete},
    {"get_width", lua_uvc_get_width},
    {"get_height", lua_uvc_get_height},
    {"reset", lua_uvc_reset_resolution},
    {"set_param", lua_uvc_set_param},
    {"get_param", lua_uvc_get_param},
    {"get_image", lua_uvc_get_raw},
    {"__index", lua_uvc_index},
    {"__gc", lua_uvc_delete},
    {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_uvc (lua_State *L) {
    /* create metatable for uvc module */
    luaL_newmetatable(L, MT_NAME);

#if LUA_VERSION_NUM == 502
    luaL_setfuncs(L, uvc_methods, 0);
	  luaL_newlib(L, uvc_functions);
#else 
    luaL_register(L, NULL, uvc_methods);
    luaL_register(L, "uvc", uvc_functions);
#endif
    return 1;
}
