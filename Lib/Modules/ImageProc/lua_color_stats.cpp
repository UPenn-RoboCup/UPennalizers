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

int lua_color_stats(lua_State *L) {

  uint8_t *im_ptr = (uint8_t *)lua_touserdata(L,1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }

  int width = luaL_checkint(L, 2);
  int height = luaL_checkint(L, 3);
  uint8_t color = luaL_optinteger(L, 4, 1);

  // bouding box
  int i0 = 0;
  int i1 = width-1;
  int j0 = 0;
  int j1 = height-1;
  if (lua_gettop(L) >= 5) {
    if (!lua_istable(L, 5)) {
      return luaL_error(L, "Bounding box input missing");
    }

    lua_rawgeti(L, 5, 1);
    i0 = luaL_checknumber(L, -1);
    if (i0 < 0) i0 = 0;
    lua_rawgeti(L, 5, 2);
    i1 = luaL_checknumber(L, -1);
    if (i1 > width-1) i1 = width-1;
    lua_rawgeti(L, 5, 3);
    j0 = luaL_checknumber(L, -1);
    if (j0 < 0) j0 = 0;
    lua_rawgeti(L, 5, 4);
    j1 = luaL_checknumber(L, -1);
    if (j1 > height-1) j1 = height-1;
    lua_pop(L, 4);
  }
  
	// initialize statistics
	int area = 0;
	int minI = width-1, maxI = 0;
	int minJ = height-1, maxJ = 0;
	int sumI = 0, sumJ = 0;
	int sumII = 0, sumJJ = 0, sumIJ = 0;

  // accumulate region statistics
	for (int j = j0; j <= j1; j++) {
		uint8_t *im_col = im_ptr + width*j;
		
		for (int i = i0; i <= i1; i++) {

			if (im_col[i] == color) {
				// increment area size
				area++;
				
				// update min/max row/column values
				if (i < minI)
					minI = i;
				if (i > maxI)
					maxI = i;
				if (j < minJ)
					minJ = j;
				if (j > maxJ)
					maxJ = j;
				
				sumI += i;
				sumJ += j;
				sumII += i*i;
				sumJJ += j*j;
				sumIJ += i*j;
			}
		}
	}
	
  // return stats	
  lua_createtable(L, 0, 6);
  
  // area field
  lua_pushstring(L, "area");
  lua_pushnumber(L, area);
  lua_settable(L, -3);

  if (area == 0) {
    return 1;
  }

  // centroid field
  lua_pushstring(L, "centroid");
  double centroidI = (double)sumI/area;
  double centroidJ = (double)sumJ/area;
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, centroidI);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, centroidJ);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  // boundingBox field
  lua_pushstring(L, "boundingBox");
  lua_createtable(L, 4, 0);
  lua_pushnumber(L, minI);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, maxI);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, minJ);
  lua_rawseti(L, -2, 3);
  lua_pushnumber(L, maxJ);
  lua_rawseti(L, -2, 4);
  lua_settable(L, -3);

	// axes and orientation
  double covII = sumII/area -centroidI*centroidI;
  double covJJ = sumJJ/area -centroidJ*centroidJ;
  double covIJ = sumIJ/area -centroidI*centroidJ;
  double covTrace = covII + covJJ;
  double covDet = covII*covJJ - covIJ*covIJ;
  double covFactor = sqrt(fmax(covTrace*covTrace-4*covDet, 0));
  double covAdd = .5*(covTrace + covFactor);
  double covSubtract = .5*fmax((covTrace - covFactor), 0);
  double axisMajor = sqrt(12*covAdd) + 0.5;
  double axisMinor = sqrt(12*covSubtract) + 0.5;
  double orientation = atan2(covJJ-covIJ-covSubtract, covII-covIJ-covSubtract);

  lua_pushstring(L, "axisMajor");
  lua_pushnumber(L, axisMajor);
  lua_settable(L, -3);

  lua_pushstring(L, "axisMinor");
  lua_pushnumber(L, axisMinor);
  lua_settable(L, -3);

  lua_pushstring(L, "orientation");
  lua_pushnumber(L, orientation);
  lua_settable(L, -3);

  return 1;
}












int lua_tilted_color_stats(lua_State *L) {

  uint8_t *im_ptr = (uint8_t *)lua_touserdata(L,1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }

  int width = luaL_checkint(L, 2);
  int height = luaL_checkint(L, 3);
  uint8_t color = luaL_optinteger(L, 4, 1);
  double tiltAngle = luaL_optnumber(L, 6, 0.0);
  double increment= tan(tiltAngle);

  // bounding box
  int i0 = 0;
  int i1 = width-1;
  int j0 = 0;
  int j1 = height-1;
  if (lua_gettop(L) >= 5) {
    if (!lua_istable(L, 5)) {
      return luaL_error(L, "Bounding box input missing");
    }

//Now bounding box edges can be negative
    lua_rawgeti(L, 5, 1);
    i0 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 5, 2);
    i1 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 5, 3);
    j0 = luaL_checknumber(L, -1);
    lua_rawgeti(L, 5, 4);
    j1 = luaL_checknumber(L, -1);
    lua_pop(L, 4);
  }

  // initialize statistics
  int area = 0;
  int minI = width-1, maxI = 0;
  int minJ = height-1, maxJ = 0;
  int sumI = 0, sumJ = 0;
  int sumII = 0, sumJJ = 0, sumIJ = 0;

  // accumulate region statistics
  for (int j = j0; j <= j1; j++) {
    uint8_t *im_col = im_ptr + width*j;
    double shift= (double) j*increment;
    int i2 = (int)  i0+ (shift + 0.5); //round up
    int i3 = (int)  i1+ (shift + 0.5); //round up
    if (i2>width-1) i2=width-1;
    if (i3>width-1) i3=width-1;
    if (i2<0) i2=0;
    if (i3<0) i3=0;
    for (int i = i2; i <= i3; i++) {
      if (im_col[i] == color) {
  	  // increment area size
  	  area++;
  	  // update min/max row/column values
	  if (i < minI) minI = i;
	  if (i > maxI) maxI = i;
	  if (j < minJ) minJ = j;
	  if (j > maxJ) maxJ = j;
	  sumI += i;
	  sumJ += j;
	  sumII += i*i;
	  sumJJ += j*j;
	  sumIJ += i*j;
      }
    }
  }
  // return states
  lua_createtable(L, 0, 6);
  // area field
  lua_pushstring(L, "area");
  lua_pushnumber(L, area);
  lua_settable(L, -3);
  if (area == 0) {
    return 1;
  }

  // centroid field
  lua_pushstring(L, "centroid");
  double centroidI = (double)sumI/area;
  double centroidJ = (double)sumJ/area;
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, centroidI);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, centroidJ);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  // boundingBox field
  lua_pushstring(L, "boundingBox");
  lua_createtable(L, 4, 0);
  lua_pushnumber(L, minI);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, maxI);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, minJ);
  lua_rawseti(L, -2, 3);
  lua_pushnumber(L, maxJ);
  lua_rawseti(L, -2, 4);
  lua_settable(L, -3);

	// axes and orientation
  double covII = sumII/area -centroidI*centroidI;
  double covJJ = sumJJ/area -centroidJ*centroidJ;
  double covIJ = sumIJ/area -centroidI*centroidJ;
  double covTrace = covII + covJJ;
  double covDet = covII*covJJ - covIJ*covIJ;
  double covFactor = sqrt(fmax(covTrace*covTrace-4*covDet, 0));
  double covAdd = .5*(covTrace + covFactor);
  double covSubtract = .5*fmax((covTrace - covFactor), 0);
  double axisMajor = sqrt(12*covAdd) + 0.5;
  double axisMinor = sqrt(12*covSubtract) + 0.5;
  double orientation = atan2(covJJ-covIJ-covSubtract, covII-covIJ-covSubtract);

  lua_pushstring(L, "axisMajor");
  lua_pushnumber(L, axisMajor);
  lua_settable(L, -3);

  lua_pushstring(L, "axisMinor");
  lua_pushnumber(L, axisMinor);
  lua_settable(L, -3);

  lua_pushstring(L, "orientation");
  lua_pushnumber(L, orientation);
  lua_settable(L, -3);

  return 1;
}
