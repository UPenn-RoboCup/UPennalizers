/* 
  Lua interface to Image Processing utilities

  To compile on Mac OS X:
  g++ -arch i386 -o luaImageUtil.dylib -bundle -undefined dynamic_lookup luaImageUtil.cpp -lm
*/

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif

#include <stdint.h>
#include <math.h>
#include <vector>
#include <string>

#include "color_count.h"
#include "block_bitor.h"
#include "ConnectRegions.h"

#include "lua_color_stats.h"
#include "lua_goal_posts.h"
#include "lua_field_lines.h"
#include "lua_field_spots.h"

static int lua_rgb_to_index(lua_State *L) {
  static std::vector<uint32_t> index;

  uint8_t *rgb = (uint8_t *) lua_touserdata(L, 1);
  if ((rgb == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input RGB not light user data");
  }
  int n = luaL_checkint(L, 2);

  index.resize(n);
  for (int i = 0; i < n; i++) {
    uint8_t r = *rgb++;
    uint8_t g = *rgb++;
    uint8_t b = *rgb++;

    uint8_t y = g;
    uint8_t u = 128 + (b-g)/2;
    uint8_t v = 128 + (r-g)/2;
    
    // Construct Y6U6V6 index
    index[i] = ((v & 0xFC) >> 2) | ((u & 0xFC) << 4) | ((y & 0xFC) << 10);
  }
  lua_pushlightuserdata(L, &index[0]);
  return 1;
}

static int lua_rgb_to_yuyv(lua_State *L) {
  static std::vector<uint32_t> yuyv;

  uint8_t *rgb = (uint8_t *) lua_touserdata(L, 1);
  if ((rgb == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input RGB not light user data");
  }
  int m = luaL_checkint(L, 2);
  int n = luaL_checkint(L, 3);

  yuyv.resize(m*n/2);

  int count=0;
  for (int i = 0; i < n; i++){
    for (int j = 0; j < m; j++) {
    uint8_t r = *rgb++;
    uint8_t g = *rgb++;
    uint8_t b = *rgb++;

    uint8_t y = g;
    uint8_t u = 128 + (b-g)/2;
    uint8_t v = 128 + (r-g)/2;
    
    // Construct Y6U6V6 index
    //SJ: only convert every other pixels (to make m/2 by n yuyv matrix)
    if (j%2==0)
        yuyv[count++] = (v << 24) | (y << 16) | (u << 8) | y;
    }
  }
  lua_pushlightuserdata(L, &yuyv[0]);
  return 1;
}

// Only labels every other pixel
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
  
  // Label will be half the height and half the width of the original image
  label.resize(m*n/2);
  int label_ind = 0;

  for (int j = 0; j < n/2; j++){
     for (int i = 0; i < m; i++) {

       // Construct Y6U6V6 index
       uint32_t index = ((*yuyv & 0xFC000000) >> 26)  
                         | ((*yuyv & 0x0000FC00) >> 4)
                         | ((*yuyv & 0x000000FC) << 10);

	   // Put labeled pixel into label vector
       label[label_ind] = cdt[index];
       
	   yuyv++;
	   label_ind++;
    }
	// Skip every other line (to maintain image ratio)
	yuyv += m;
  }
  // Pushing light data
  lua_pushlightuserdata(L, &label[0]);
  return 1;
}


static int lua_index_to_label(lua_State *L) {
  static std::vector<uint8_t> label;

  uint32_t *index = (uint32_t *) lua_touserdata(L, 1);
  if ((index == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input INDEX not light user data");
  }

  uint8_t *cdt = (uint8_t *) lua_touserdata(L, 2);
  if (cdt == NULL) {
    return luaL_error(L, "Input CDT not light user data");
  }

  int n = luaL_checkint(L, 3);

  label.resize(n);
  for (int i = 0; i < n; i++) {
    label[i] = cdt[index[i]];
  }
  lua_pushlightuserdata(L, &label[0]);
  return 1;
}

static int lua_color_count(lua_State *L) {
  uint8_t *label = (uint8_t *) lua_touserdata(L, 1);
  if ((label == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input LABEL not light user data");
  }
  int n = luaL_checkint(L, 2);

  int *count = color_count(label, n);
  lua_createtable(L, nColor, 0);
  for (int i = 0; i < nColor; i++) {
    lua_pushinteger(L, count[i]);
    lua_rawseti(L, -2, i);
  }
  return 1;
}

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

static int lua_connected_regions(lua_State *L) {
  static std::vector<RegionProps> props;

  uint8_t *x = (uint8_t *) lua_touserdata(L, 1);
  if ((x == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int mx = luaL_checkint(L, 2);
  int nx = luaL_checkint(L, 3);
  int8_t mask = luaL_optinteger(L, 4, 1);

  // horizon attempt
  //int no = luaL_checkint(L, 4);
  //uint8_t mask = luaL_optinteger(L, 5, 1);
  //int rowOffset = no * mx * sizeof(uint8);
  //int nlabel = ConnectRegions(props, x+rowOffset, mx, nx-no, mask);

  int nlabel = ConnectRegions(props, x, mx, nx, mask);
  if (nlabel <= 0) {
    return 0;
  }

  lua_createtable(L, nlabel, 0);
  for (int i = 0; i < nlabel; i++) {
    lua_createtable(L, 0, 3);

    // area field
    lua_pushstring(L, "area");
    lua_pushnumber(L, props[i].area);
    lua_settable(L, -3);

    // centroid field
    lua_pushstring(L, "centroid");
    double centroidI = (double)props[i].sumI/props[i].area;
    double centroidJ = (double)props[i].sumJ/props[i].area;
    //double centroidJ = (double)props[i].sumJ/props[i].area + rowOffset;
    lua_createtable(L, 2, 0);
    lua_pushnumber(L, centroidI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, centroidJ);
    lua_rawseti(L, -2, 2);
    lua_settable(L, -3);

    // boundingBox field
    lua_pushstring(L, "boundingBox");
    lua_createtable(L, 2, 0);
    lua_pushnumber(L, props[i].minI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, props[i].maxI);
    lua_rawseti(L, -2, 2);
    lua_pushnumber(L, props[i].minJ);
    //lua_pushnumber(L, props[i].minJ + rowOffset);
    lua_rawseti(L, -2, 3);
    lua_pushnumber(L, props[i].maxJ);
    //lua_pushnumber(L, props[i].maxJ + rowOffset);
    lua_rawseti(L, -2, 4);
    lua_settable(L, -3);

    lua_rawseti(L, -2, i+1);
  }
  return 1;
}

static const struct luaL_reg imageProc_lib [] = {
  {"rgb_to_index", lua_rgb_to_index},
  {"rgb_to_yuyv", lua_rgb_to_yuyv},
  {"yuyv_to_label", lua_yuyv_to_label},
  {"index_to_label", lua_index_to_label},
  {"color_count", lua_color_count},
  {"color_stats", lua_color_stats},
  {"block_bitor", lua_block_bitor},
  {"connected_regions", lua_connected_regions},
  {"goal_posts", lua_goal_posts},
  {"field_lines", lua_field_lines},
  {"field_spots", lua_field_spots},

  {NULL, NULL}
};

extern "C"
int luaopen_ImageProc (lua_State *L) {
  luaL_register(L, "ImageProc", imageProc_lib);
  
  return 1;
}
