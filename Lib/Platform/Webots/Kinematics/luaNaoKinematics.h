#ifndef luaNaoKinematics_h_DEFINED
#define luaNaoKinematics_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_kinematics(lua_State *L);

#endif
