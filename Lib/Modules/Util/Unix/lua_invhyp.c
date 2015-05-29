#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include <math.h>
#include <stdio.h>

static int lua_acosh (lua_State *L) {
  lua_pushnumber(L, acosh(luaL_checknumber(L, 1)));
  return 1;
}

static int lua_asinh (lua_State *L) {
  lua_pushnumber(L, asinh(luaL_checknumber(L, 1)));
  return 1;
}

static int lua_atanh (lua_State *L) {
  lua_pushnumber(L, atanh(luaL_checknumber(L, 1)));
  return 1;
}

static const luaL_Reg invhyp_lib [] = {
  {"asinh", lua_asinh},
  {"acosh", lua_acosh},
  {"atanh", lua_atanh},
  {NULL, NULL}
};

int luaopen_invhyp (lua_State *L) {
#if LUA_VERSION_NUM == 502
  luaL_newlib(L, invhyp_lib);
#else
  luaL_register(L, "invhyp", invhyp_lib);
#endif

  return 1;
}


