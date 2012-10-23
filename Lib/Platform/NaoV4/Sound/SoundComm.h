#ifndef __SOUNDCOMM_H__
#define __SOUNDCOMM_H__

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_SoundComm(lua_State *L);

#endif
