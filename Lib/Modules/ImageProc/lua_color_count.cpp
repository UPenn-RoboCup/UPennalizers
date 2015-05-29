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

#include "color_count.h"

int lua_color_count(lua_State *L) {
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
  
int lua_color_count_obs(lua_State *L) {
  uint8_t *label = (uint8_t *) lua_touserdata(L, 1);
  if ((label == NULL) || !lua_islightuserdata(L, 1)) {
     return luaL_error(L, "Input LABEL not light user data");
   }
 int n = luaL_checkint(L, 2);

   int *count = color_count_obs(label, n);
 lua_createtable(L, nColor, 0);
 for (int i = 0; i < nColor; i++) {
     lua_pushinteger(L, count[i]);
     lua_rawseti(L, -2, i);
   }
 return 1;
}
