#ifndef luadcm_h_DEFINED
#define luadcm_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_luadcm(lua_State *L);

#endif
