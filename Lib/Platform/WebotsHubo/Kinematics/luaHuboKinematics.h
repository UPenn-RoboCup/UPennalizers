#ifndef luaHuboKinematics_h_DEFINED
#define luaHuboKinematics_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_HuboKinematics(lua_State *L);

#endif
