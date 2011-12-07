#ifndef luaOPKinematics_h_DEFINED
#define luaOPKinematics_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_GenericKinematics(lua_State *L);

#endif
