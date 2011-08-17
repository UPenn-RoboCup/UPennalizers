/**
 * Lua module to provide efficient access to C arrays
 *
 * University of Pennsylvania
 * 2010
 */

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

typedef struct {
  const void *ptr;
  char type;
  int size;
  int own; // 1 if array was created by Lua and needs to be deleted
} structCArray;

static structCArray * lua_checkcarray(lua_State *L, int narg) {
  void *ud = luaL_checkudata(L, narg, "carray_mt");
  luaL_argcheck(L, *(structCArray **)ud != NULL, narg, "invalid carray");
  return (structCArray *)ud;
}

static int lua_carray_new(lua_State *L) {
  const char *type = luaL_optstring(L, 1, "double");
  int size = luaL_optinteger(L, 2, 1);
  structCArray *ud = (structCArray *)lua_newuserdata(L, sizeof(structCArray));

  ud->size = size;
  ud->type = type[0];
  ud->own = 1;

  switch (ud->type) {
    case 'c':
      ud->ptr = new char[size];
      break;
    case 's':
      ud->ptr = new short[size];
      break;
    case 'i':
      ud->ptr = new int[size];
      break;
    case 'u':
      ud->ptr = new unsigned int[size];
      break;
    case 'f':
      ud->ptr = new float[size];
      break;
    case 'd':
      ud->ptr = new double[size];
      break;
    default:
      ud->ptr = new char[size];
  }

  luaL_getmetatable(L, "carray_mt");
  lua_setmetatable(L, -2);
  return 1;
}

static int lua_carray_cast(lua_State *L) {
  const char *type = luaL_optstring(L, 2, "double");
  int size = luaL_optinteger(L, 3, 1);
  structCArray *ud = (structCArray *)lua_newuserdata(L, sizeof(structCArray));
  ud->ptr = lua_topointer(L, 1);
  ud->size = size;
  ud->type = type[0];
  ud->own = 0;

  luaL_getmetatable(L, "carray_mt");
  lua_setmetatable(L, -2);
  return 1;
}

static int lua_carray_delete(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);
  if (p->own) {
    delete p->ptr;
  }

  return 0;
}

static int lua_carray_set(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);
  // Convert lua 1-index to C 0-index
  int index = luaL_checkint(L, 2) - 1; 
  if ((index < 0) || (index >= p->size)) {
    return luaL_error(L, "index out of bounds");
  }

  double val = lua_tonumber(L, 3);
  switch (p->type) {
    case 'c':
      ((char *)p->ptr)[index] = val;
      break;
    case 's':
      ((short *)p->ptr)[index] = val;
      break;
    case 'i':
      ((int *)p->ptr)[index] = val;
      break;
    case 'u':
      ((unsigned int *)p->ptr)[index] = val;
      break;
    case 'f':
      ((float *)p->ptr)[index] = val;
      break;
    case 'd':
      ((double *)p->ptr)[index] = val;
      break;
    default:
      ((char *)p->ptr)[index] = val;
  }

  return 0;
}

static int lua_carray_get(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);
  // Convert lua 1-index to C 0-index
  int index = luaL_checkint(L, 2) - 1; 
  double val;

  switch (p->type) {
    case 'c':
      val = ((char *)p->ptr)[index];
      break;
    case 's':
      val = ((short *)p->ptr)[index];
      break;
    case 'i':
      val = ((int *)p->ptr)[index];
      break;
    case 'u':
      val = ((unsigned int *)p->ptr)[index];
      break;
    case 'f':
      val = ((float *)p->ptr)[index];
      break;
    case 'd':
      val = ((double *)p->ptr)[index];
      break;
    default:
      lua_pushnil(L);
      return 1;
  }

  lua_pushnumber(L, val);
  return 1;
}

static int lua_carray_pointer(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);

  lua_pushlightuserdata(L, (void *) p->ptr);
  lua_pushlstring(L, &(p->type), 1);
  lua_pushinteger(L, p->size);
  return 3;
}

static int lua_carray_tostring(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);
  lua_pushfstring(L, "carray(%p): '%c' type, %d len, %d own",
		  p->ptr, p->type, p->size, p->own);
  return 1;
}

static int lua_carray_len(lua_State *L) {
  structCArray *p = lua_checkcarray(L, 1);
  lua_pushinteger(L, p->size);
  return 1;
}

static const struct luaL_reg carray_functions[] = {
  {"new", lua_carray_new},
  {"cast", lua_carray_cast},
  {"set", lua_carray_set},
  {"get", lua_carray_get},
  {"pointer", lua_carray_pointer},
  {NULL, NULL}
};

static const struct luaL_reg carray_methods[] = {
  {"__gc", lua_carray_delete},
  {"__newindex", lua_carray_set},
  {"__tostring", lua_carray_tostring},
  {"__len", lua_carray_len},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_carray (lua_State *L) {
  luaL_newmetatable(L, "carray_mt");

  // Array access: mt.__index = get(); mt.__newindex = set()
  // Not compatible with OO access
  lua_pushstring(L, "__index");
  lua_pushcfunction(L, lua_carray_get);
  lua_settable(L, -3);

  luaL_register(L, NULL, carray_methods);
  luaL_register(L, "carray", carray_functions);
  return 1;
}

