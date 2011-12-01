#ifndef luaOPKinematics_h_DEFINED
#define luaOPKinematics_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_OPKinematics(lua_State *L);

#endif
