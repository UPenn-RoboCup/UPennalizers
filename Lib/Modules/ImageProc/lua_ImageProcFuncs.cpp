/* 
   Lua interface to Image Processing utilities

   To compile on Mac OS X:
   g++ -arch i386 -o luaImageUtil.dylib -bundle -undefined dynamic_lookup luaImageUtil.cpp -lm
 */

#include <lua.hpp>

#include <stdint.h>
#include <math.h>
#include <vector>
#include <string>
#include <algorithm>
#include <iostream>

#include "block_bitor.h"
#include "ConnectRegions.h"
#include "lua_color_stats.h"
#include "lua_color_count.h"
#include "lua_colorlut_gen.h"
#include "lua_connect_regions.h"
#include "lua_goal_posts.h"
#include "lua_goal_posts_white.h"
#include "lua_field_lines.h"
#include "lua_field_spots.h"
#include "lua_field_occupancy.h"
#include "lua_robots.h"

// clip value between 0 and 255
#define CLIP(value) (uint8_t)(((value)>0xFF)?0xff:(((value)<0)?0:(value)))

//Downsample camera YUYV image for monitor

static int lua_block_bitor(lua_State *L) {
  uint8_t *label = (uint8_t *) lua_touserdata(L, 1);
  if ((label == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input LABEL not light user data");
  }
  int mx = luaL_checkint(L, 2);
  int nx = luaL_checkint(L, 3);
  int msub = luaL_checkint(L, 4);
  int nsub = luaL_checkint(L, 5);

  uint8_t *block = block_bitor(label, mx, nx, msub, nsub);
  lua_pushlightuserdata(L, block);
  return 1;
}


static int lua_yuyv_to_label(lua_State *L) {
  static std::vector<uint8_t> label;

  // 1st Input: Original YUYV-format input image
  uint32_t *yuyv = (uint32_t *) lua_touserdata(L, 1);
  if ((yuyv == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input YUYV not light user data");
  }

  // 2nd Input: YUYV->Label Lookup Table
  uint8_t *cdt = (uint8_t *) lua_touserdata(L, 2);
  if (cdt == NULL) {
    return luaL_error(L, "Input CDT not light user data");
  }
  
  // 3rd Input: Width (in YUYV macropixels) of the original YUYV image
  int m = luaL_checkint(L, 3);

  // 4th Input: Height (in YUVY macropixels) of the original YUYV image
  int n = luaL_checkint(L, 4);

  // 5th Input: scaleA, subsampling rate, default 1
  int scale = luaL_optinteger(L, 5, 1);

  // keep ratio
  label.resize(m * n / scale / scale);
  int end_m = m / scale;
  int end_n = n / scale;

  int label_ind = 0;
  uint32_t index1 = 0, index2 = 0;
  while(label_ind < end_m * end_n){
    // Construct Y6U6V6 index
    index1 = ((*yuyv & 0xfc000000) >> 26)  
      | ((*yuyv & 0x0000fc00) >> 4)
      | ((*yuyv & 0x000000fc) << 10);
    label[label_ind++] = cdt[index1];

    if (scale == 1) {
      index2 = ((*yuyv & 0xfc000000) >> 26)  
        | ((*yuyv & 0x0000fc00) >> 4)
        | ((*yuyv & 0x00fc0000) >> 6);
      label[label_ind++] = cdt[index2];
      yuyv ++;
    } else if (scale == 2) {
      yuyv ++;
      if (label_ind % end_m == 0) {
        yuyv += (m / 2);
      } 
    } else if (scale == 4) {
      yuyv += 2;
      if (label_ind % end_m == 0)
        yuyv += (3 * m / 2);
    } else
      luaL_error(L, "Scale rate not support");
  }

  // Pushing light data
  lua_pushlightuserdata(L, &label[0]);
  return 1;
}


static int lua_rgb_to_yuyv(lua_State *L) {
  static std::vector<uint32_t> yuyv;

  /* Get the RGB Image */
  uint8_t *rgb = (uint8_t *) lua_touserdata(L, 1);
  if ((rgb == NULL) || !lua_islightuserdata(L, 1))
    return luaL_error(L, "Input RGB not light user data");
  
  /* Get the width and height */
  int m = luaL_checkint(L, 2);
  int n = luaL_checkint(L, 3);

  /* YUYV is 2px per pixel */
  yuyv.resize(m*n/2);

  int count=0;
  uint8_t r,g,b,y1,u,y2,v;
  for (int i = 0; i < n; i++){
    /* Every other RGB Pixel for YUYV */
    for (int j = 0; j < m; j+=2) {
      r = *rgb++;
      g = *rgb++;
      b = *rgb++;
      
      // Formulate YUV
      y1 = g;
      u = 128 + (b-g)/2;
      v = 128 + (r-g)/2;

      r = *rgb++;
      g = *rgb++;
      b = *rgb++;
      // Add the other Y
      y2 = g;
      // Construct Y6U6V6 index
      yuyv[count++] = (v << 24) | (y2 << 16) | (u << 8) | y1;
    }
  }
    
  lua_pushlightuserdata(L, &yuyv[0]);
  return 1;
}


static int lua_rgb_to_label(lua_State *L) {
  static std::vector<uint8_t> label;

  // 1st Input: Original RGB-format input image
  uint8_t *rgb = (uint8_t *) lua_touserdata(L, 1);
  if ((rgb == NULL) || !lua_islightuserdata(L, 1))
    return luaL_error(L, "Input RGB not light user data");

  // 2nd Input: YUYV->Label Lookup Table
  uint8_t *cdt = (uint8_t *) lua_touserdata(L, 2);
  if (cdt == NULL)
    return luaL_error(L, "Input CDT not light user data");

  // 3rd Input: Width (in pixels) of the original RGB image  
  int m = luaL_checkint(L, 3);
  // 4th Input: Width (in pixels) of the original RGB image
  int n = luaL_checkint(L, 4);
  label.resize(m*n);
  
  int label_ind = 0;
  uint8_t r,g,b,y,u,v;
  uint32_t index;
  while(label_ind<m*n){   
    r = *rgb++;
    g = *rgb++;
    b = *rgb++;
    // Formulate YUV data
    y = g;
    u = 128 + (b-g)/2;
    v = 128 + (r-g)/2;
    // Construct Y6U6V6 index
    index = ((v & 0xFC) >> 2) | ((u & 0xFC) << 4) | ((y & 0xFC) << 10);
    // Put labeled pixel into label vector
    label[label_ind++] = cdt[index];
  }
  
  lua_pushlightuserdata(L, &label[0]);
  return 1;
}












static const struct luaL_Reg imageProcFuncs_lib [] = {
  {"block_bitor", lua_block_bitor},
  {"yuyv_to_label", lua_yuyv_to_label},
  {"label_to_mask", lua_label_to_mask},
  {"yuyv_mask_to_lut", lua_yuyv_mask_to_lut},
  {"color_stats", lua_color_stats},
  {"tilted_color_stats", lua_tilted_color_stats},
  {"connected_regions", lua_connected_regions},
  {"goal_posts", lua_goal_posts},
  {"goal_posts_white", lua_goal_posts_white},
  {"tilted_goal_posts", lua_tilted_goal_posts},
  {"field_lines", lua_field_lines},
  {"line_connect",lua_line_connect},
  {"field_spots", lua_field_spots},
  {"field_occupancy", lua_field_occupancy},
  {"robots", lua_robots},

  //WHY THE HELL WERE THEY REMOVED?????
  {"rgb_to_yuyv", lua_rgb_to_yuyv},
  {"rgb_to_label", lua_rgb_to_label},
  {"color_count", lua_color_count},
  {NULL, NULL}
};

extern "C"
int luaopen_ImageProcFuncs (lua_State *L) {
#if LUA_VERSION_NUM == 502
  luaL_newlib(L, imageProcFuncs_lib);
#else
  luaL_register(L, "ImageProc", imageProcFuncs_lib);
#endif
  return 1;
}
