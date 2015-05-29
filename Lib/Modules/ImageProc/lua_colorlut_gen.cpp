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
#include <vector>
#include <iostream>

int lua_rgb_mask_to_lut(lua_State *L) {
  static std::vector<uint8_t> cdt;

  std::cout << "rgb and mask to lut" << std::endl;
  // 1st Input: Original RGB-format input image
  uint8_t *rgb = (uint8_t *) lua_touserdata(L, 1);
  if ((rgb == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input RGB not light user data");
  }

  // 2nd Input: Mask
  uint32_t *mask = (uint32_t *) lua_touserdata(L, 2);
  if (mask == NULL) {
    return luaL_error(L, "Input Mask not light user data");
  }

  // 3rd Input: Lookup Table
  uint8_t *lut = (uint8_t *) lua_touserdata(L, 3);
  if (lut == NULL) {
    return luaL_error(L, "Input Lut not light user data");
  }

  // 4rd Input: Width (in pixels) of the original RGB image  
  int m = luaL_checkint(L, 4);
  // 5th Input: Width (in pixels) of the original RGB image
  int n = luaL_checkint(L, 5);

  for (int cnt = 0; cnt < 262144; cnt ++) {
    cdt.push_back(*lut);
    lut++;
  }

  for (int cnt = 0; cnt < m * n; cnt++)
    if (mask[cnt] != 0) {
      uint8_t r = rgb[3 * mask[cnt]];
      uint8_t g = rgb[3 * mask[cnt] + 1];
      uint8_t b = rgb[3 * mask[cnt] + 2];

      uint8_t y = g;
      uint8_t u = 128 + (b-g)/2;
      uint8_t v = 128 + (r-g)/2;

      uint32_t index = ((v & 0xFC) >> 2) | ((u & 0xFC) << 4) | ((y & 0xFC) << 10);
      cdt[index] = 1;
    }

  lua_pushlightuserdata(L, &cdt[0]);
  
  return 1;
}

int lua_yuyv_mask_to_lut(lua_State *L) {
  static std::vector<uint8_t> cdt;

  // 1st Input: Original RGB-format input image
  uint32_t *yuyv = (uint32_t *) lua_touserdata(L, 1);
  if ((yuyv == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input RGB not light user data");
  }

  // 2nd Input: Mask
  uint32_t *mask = (uint32_t *) lua_touserdata(L, 2);
  if (mask == NULL) {
    return luaL_error(L, "Input Mask not light user data");
  }

  // 3rd Input: Lookup Table
  uint8_t *lut = (uint8_t *) lua_touserdata(L, 3);
  if (lut == NULL) {
    return luaL_error(L, "Input Lut not light user data");
  }

  // 4rd Input: Width (in pixels) of the original RGB image  
  int m = luaL_checkint(L, 4);
  // 5th Input: Width (in pixels) of the original RGB image
  int n = luaL_checkint(L, 5);

  for (int cnt = 0; cnt < 262144; cnt ++) {
    cdt.push_back(*lut);
    lut++;
  }

  int labeln = 0, labelm = 0, yuyvidx = 0;
  for (int cnt = 0; cnt < m * n; cnt++)
    if (mask[cnt] != 0) {
      labelm = mask[cnt] % m;
      labeln = (mask[cnt] - labelm) / m;
      yuyvidx = labelm + (labeln - 1) * 3 * m; 
      uint32_t index = ((yuyv[yuyvidx] & 0xFC000000) >> 26)  
        | ((yuyv[yuyvidx] & 0x0000FC00) >> 4)
        | ((yuyv[yuyvidx] & 0x000000FC) << 10);
      cdt[index] = (cdt[index] < 1)? 1 : cdt[index];
    }

  lua_pushlightuserdata(L, &cdt[0]);
  return 1;
}

int lua_label_to_mask(lua_State *L) {
  static std::vector<uint32_t> mask;

  uint8_t *label = (uint8_t *) lua_touserdata(L, 1);
  if ((label == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input LABEL not light user data");
  }
  int mx = luaL_checkint(L, 2);
  int nx = luaL_checkint(L, 3);
  for (int cnt = 0; cnt < mx * nx; cnt++)
    mask.push_back(0);
  int idx = 0, counter = 0;
  for (int n = 0; n < nx; n++) 
    for (int m = 0; m < mx; m++) {
      idx = n * mx + m;
      if (label[idx] == 0)
        mask[counter++] = idx; 
    } 

  lua_pushlightuserdata(L, &mask[0]);

  return 1;
}
