#ifndef lua_ImageProc_h_DEFINED
#define lua_ImageProc_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}


extern "C"
int luaopen_ImageProcFuncs(lua_State *L);

#endif
