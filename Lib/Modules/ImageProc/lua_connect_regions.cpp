#include <lua.hpp>
#include <stdint.h>
#include <math.h>
#include <vector>
#include "lua_connect_regions.h"
#include "RegionProps.h"
#include "ConnectRegions.h"

#ifdef TORCH
#include <torch/luaT.h>
#ifdef __cplusplus
extern "C"
{
#endif
#include <torch/TH/TH.h>
#ifdef __cplusplus
}
#endif
#endif

int lua_connected_regions_obs(lua_State *L) {
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

  int nlabel = ConnectRegions_obs(props, x, mx, nx, mask);
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


int lua_connected_regions(lua_State *L) {
  static std::vector<RegionProps> props;
  uint8_t *x;
  int mx, nx;
  int8_t mask;
  
	if( lua_islightuserdata(L,1) ){
		x = (uint8_t *) lua_touserdata(L, 1);
		mx = luaL_checkint(L, 2);
		nx = luaL_checkint(L, 3);
    mask = luaL_optinteger(L, 4, 1);
	}
#ifdef TORCH
	else if(luaT_isudata(L,1,"torch.ByteTensor")){
		THByteTensor* b_t =
			(THByteTensor *) luaT_checkudata(L, 1, "torch.ByteTensor");
		x = b_t->storage->data;
    nx = b_t->size[0];
		mx = b_t->size[1];
    mask = luaL_optinteger(L, 2, 1);
	}
#endif
	else {
		return luaL_error(L, "Input image invalid");
	}

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


