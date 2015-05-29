#ifndef luaDarwinKinematics_h_DEFINED
#define luaDarwinKinematics_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_XOSKinematics(lua_State *L);

#endif
