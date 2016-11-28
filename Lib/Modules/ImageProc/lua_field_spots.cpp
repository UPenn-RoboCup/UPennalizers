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

#include "ConnectRegions.h"

static uint8_t colorSpot = 0x10;
static uint8_t colorField = 0x08;

bool CheckArea(RegionProps &prop, int area_th){
  int width = prop.maxI-prop.minI+1;
  int height = prop.maxJ-prop.minJ+1;
  if (prop.area<width*height*0.5 or prop.area<area_th)
    return false;
  else
    return true;
}

bool CheckEdge(RegionProps &prop, int width, int height){
  if (prop.maxI>=width-1 or prop.maxJ>= height-1 or
        prop.minI == 0 or prop.minJ==0)
    return false;
  else
    return true;
}

bool CheckBoundary(RegionProps &prop, uint8_t *im_ptr,
		   int m, int n, uint8_t color)
{
  int i0 = prop.minI - 1;
  if (i0 < 0) i0 = 0;
  int i1 = prop.maxI + 1;
  if (i1 > m-1) i1 = m-1;
  int j0 = prop.minJ - 1;
  if (j0 < 0) j0 = 0;
  int j1 = prop.maxJ + 1;
  if (j1 > n-1) j1 = n-1;

  // Check top and bottom boundary:
  uint8_t *im_top = im_ptr + m*j0 + i0;
  uint8_t *im_bottom = im_ptr + m*j1 + i0;
  for (int i = 0; i <= i1-i0; i++) {
    if ((*im_top != color) || (*im_bottom != color))
      return false;
    im_top++;
    im_bottom++;
  }

  // Check side boundaries:
  uint8_t *im_left = im_ptr + m*(j0+1) + i0;
  uint8_t *im_right = im_ptr + m*(j0+1) + i1;
  for (int j = 0; j < j1-j0-1; j++) {
    if ((*im_left != color) || (*im_right != color))
      return false;
    im_left += m;
    im_right += m;
  }

  return true;
}

int lua_field_spots(lua_State *L) {
  std::vector<RegionProps> props;

  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int m = luaL_checkint(L, 2);
  int n = luaL_checkint(L, 3);
  int min_area = luaL_optinteger(L, 4, 5);
  int nlabel = ConnectRegions(props, im_ptr, m, n, colorSpot);
  if (nlabel <= 0) {
    return 0;
  }

  std::vector<int> valid;
  for (int i = 0; i < nlabel; i++) {
    if (CheckArea(props[i], min_area)) {
      if (CheckEdge(props[i],m,n)){
        valid.push_back(i);
        //printf("Region number %d\n",i+1);
        //printf("  Left: %d; Right: %d;\n", props[i].minI, props[i].maxI);
        //printf("  Top: %d; Bottom: %d;\n", props[i].minJ, props[i].maxJ);
      }
    }
  }
  int nvalid = valid.size();
  if (nvalid < 1) {
    return 0;
  }

  lua_createtable(L, nvalid, 0);
  for (int i = 0; i < nvalid; i++) {
    lua_createtable(L, 0, 3);
    // area field
    lua_pushstring(L, "area");
    lua_pushnumber(L, props[valid[i]].area);
    lua_settable(L, -3);

    // centroid field
    lua_pushstring(L, "centroid");
    double centroidI = (double)props[valid[i]].sumI/props[valid[i]].area;
    double centroidJ = (double)props[valid[i]].sumJ/props[valid[i]].area;
    lua_createtable(L, 2, 0);
    lua_pushnumber(L, centroidI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, centroidJ);
    lua_rawseti(L, -2, 2);
    lua_settable(L, -3);

    // boundingBox field
    lua_pushstring(L, "boundingBox");
    lua_createtable(L, 4, 0);
    lua_pushnumber(L, props[valid[i]].minI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, props[valid[i]].maxI);
    lua_rawseti(L, -2, 2);
    lua_pushnumber(L, props[valid[i]].minJ);
    lua_rawseti(L, -2, 3);
    lua_pushnumber(L, props[valid[i]].maxJ);
    lua_rawseti(L, -2, 4);
    lua_settable(L, -3);

    lua_rawseti(L, -2, i+1);
  }
  return 1;
}
