#ifndef luacarray_h_DEFINED
#define luacarray_h_DEFINED

#ifdef __cplusplus
extern "C"
{
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C"
#endif
int luaopen_cutil(lua_State *L);

#endif

