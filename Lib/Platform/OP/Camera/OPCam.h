#ifndef luaNaoCam_h_DEFINED
#define luaNaoCam_H_DEFINED

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_darwinCam(lua_State *L);

#endif
