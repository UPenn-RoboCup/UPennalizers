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

#include "RegionProps.h"

static const int NMAX = 256;

static int countJ[NMAX];
static int minJ[NMAX];

//Do a tilted scan at labelB image
//and return the lower boundary for every scaned lines


int lua_robots(lua_State *L) {
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int m = luaL_checkint(L, 2);
  int n = luaL_checkint(L, 3);
  uint8_t mask = luaL_optinteger(L, 4, 1); //field
  double tiltAngle = luaL_optnumber(L, 5, 0.0);
  int max_gap = luaL_optinteger(L, 6, 1 );

  double increment= tan(tiltAngle);
  int index_offset = m/2;

  // Initialize arrays
  for (int i = 0;i<m; i++ ){
    minJ[i] = n;
  }

  // Iterate through image getting projection statistics
  for (int i = -index_offset; i < m+index_offset; i++) {
    int state = 0; //0 for initial, 1 for scanning, 2 for ended
    int gap = 0;
    for (int j = n-1; j >=0 ; j--) {
      double shift = (double) j*increment;
      int index_i =(int) (i+shift+0.5); //round up

      //check current pixel is within the image
      if ((index_i>=0) && (index_i<m)) {
        int index_ij =j*m + index_i;
        uint8_t pixel = *(im_ptr+index_ij);
	if (pixel & mask) {
	  state=1;
	  if (j<minJ[index_i]) minJ[index_i]=j;
	}else{
	  if (state==1) {
	    gap++;
	    if (gap>max_gap) state=2; //end scan
	  }
	}
      }
    }
  }

  lua_pushstring(L, "minJ");
  lua_createtable(L, m, 0);
  for (int i=0;i<m;i++) {
    lua_pushnumber(L, minJ[i]);
    lua_rawseti(L, -2, i+1);
  }
  return 1;
}
