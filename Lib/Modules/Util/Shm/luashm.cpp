/*
  Lua module to provide shared memory IPC
*/

#include <boost/utility/binary.hpp>
#include <boost/interprocess/managed_shared_memory.hpp>
#include <boost/interprocess/allocators/allocator.hpp>
#include <vector>
#include <string>

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

using namespace boost::interprocess;

// Typedefs of allocators and containers
typedef double value_t;
//typedef boost::variant<double, std::string> value_t;


static managed_shared_memory * lua_checkshm(lua_State *L, int narg) {
  void *ud = luaL_checkudata(L, narg, "shm_mt");
  luaL_argcheck(L, *(managed_shared_memory **)ud != NULL, narg, "invalid shm");
  return *(managed_shared_memory **)ud;
}

static int lua_shm_create(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  int size = luaL_optinteger(L, 2, 65536);

  managed_shared_memory **ud = (managed_shared_memory **)
    lua_newuserdata(L, sizeof(managed_shared_memory *));
  *ud = new managed_shared_memory(open_or_create, name, size);
  luaL_getmetatable(L, "shm_mt");
  lua_setmetatable(L, -2);
  return 1;
}

static int lua_shm_open(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);

  managed_shared_memory **ud = (managed_shared_memory **)
    lua_newuserdata(L, sizeof(managed_shared_memory *));
  *ud = new managed_shared_memory(open_only, name);
  luaL_getmetatable(L, "shm_mt");
  lua_setmetatable(L, -2);
  return 1;
}

static int lua_shm_destroy(lua_State *L) {
  const char *name = luaL_checkstring(L, 1);
  shared_memory_object::remove(name);
  return 0;
}

static int lua_shm_delete(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);
  delete shm;
  return 0;
}

static int lua_shm_create_empty_variable(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);

  const char *key = luaL_checkstring(L, 2);
  std::vector<value_t> val(1);

  // get the number of bytes 
  int nbytes = lua_tointeger(L, 3);
  // calculate size of the shm array (based on sizeof(value_t)
  int nval = nbytes >> 3;
  if (nbytes & BOOST_BINARY(111)) {
    // if the data does not fit evenly into the value_t types
    nval++;
  }

  // Find key in shm
  std::pair<value_t*, std::size_t> ret;
  ret = shm->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;

  if (pr == NULL) {
    // construct the shm key if it doesn't exist
    //printf("Size of memory segment: %u bytes\n", shm->get_size());
    //printf("Size of value_t: %u bytes\n", sizeof(value_t) );
    pr = shm->construct<value_t>(key)[nval]();
  } else if (n != nval) {
    // if it exists but is not the correct size
    // create a new key with the correct size
//    printf("WARNING: Input size %d != current block size %d. Resizing %s block.\n", nval, n, key);
    shm->destroy_ptr(pr);
    pr = shm->construct<value_t>(key)[nval]();
  }

  return 0;
}

static int lua_shm_set(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);

  const char *key = luaL_checkstring(L, 2);
  int nval = 0;
  std::vector<value_t> val(1);

  const void* light_ptr = NULL;
  unsigned int light_bytes = 0;

  if (lua_isnumber(L, 3)) {
    nval = 1;
    val[0] = lua_tonumber(L, 3);
  } else if (lua_istable(L, 3)) {
    nval = lua_objlen(L, 3);
    val.resize(nval);
    for (int i = 0; i < nval; i++) {
      lua_rawgeti(L, 3, i+1);
      val[i] = lua_tonumber(L, -1);
      lua_pop(L, 1);
    }
  } else if (lua_islightuserdata(L, 3)) {
    // if the input is a pointer then use memcpy
    light_ptr = lua_topointer(L, 3);
    // get the number of bytes to copy
    light_bytes = lua_tointeger(L, 4);
    // calculate size of the shm array (based on sizeof(value_t)
    nval = light_bytes >> 3;
    if (light_bytes & BOOST_BINARY(111)) {
      // if the data does not fit evenly into the value_t types
      nval++;
    }
  }
  
  // Find key in shm
  std::pair<value_t*, std::size_t> ret;
  ret = shm->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;

  if (pr == NULL) {
    // construct the shm key if it doesn't exist
    //printf("Size of memory segment: %u bytes\n", shm->get_size());
    //printf("Size of value_t: %u bytes\n", sizeof(value_t) );
    pr = shm->construct<value_t>(key)[nval]();
  } else if (n != nval) {
    // if it exists but is not the correct size
    // create a new key with the correct size
//    printf("WARNING: Input size %d != current block size %d. Resizing %s block.\n", nval, n, key);
    shm->destroy_ptr(pr);
    pr = shm->construct<value_t>(key)[nval]();
  }

  if (light_ptr != NULL) {
    // use memcpy if the input is a pointer
    memcpy( pr, light_ptr, light_bytes );
  } else {
    // otherwise copy the array data
    for (int i = 0; i < nval; i++) {
      pr[i] = val[i];
    }
  }

  return 0;
}

static int lua_shm_get(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);
  const char *key = luaL_checkstring(L, 2);

  std::pair<value_t*, std::size_t> ret;
  ret = shm->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;
  if ((pr == NULL) || (n == 0)) {
    // key does not exist in the shm segment
    lua_pushnil(L);
  } else if (n == 1) {
    lua_pushnumber(L, *pr);
  } else {
    lua_createtable(L, n, 0);
    for (int i = 0; i < n; i++) {
      lua_pushnumber(L, pr[i]);
      lua_rawseti(L, -2, i+1);
    }
  }

  return 1;
}

static int lua_shm_size(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);
  const char *key = luaL_checkstring(L, 2);

  std::pair<value_t*, std::size_t> ret;
  ret = shm->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;
  if ((pr == NULL) || (n == 0)) {
    // key does not exist in the shm segment
    lua_pushnumber(L, 0);
  } else {
    lua_pushnumber(L, n);
  }

  return 1;
}

static int lua_shm_pointer(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);
  const char *key = luaL_checkstring(L, 2);

  // Find key
  std::pair<value_t*, std::size_t> ret;
  ret = shm->find<value_t>(key);
  value_t *pr = ret.first;
  int n = ret.second;

  lua_pushlightuserdata(L, pr);
  lua_pushstring(L, "double");
  lua_pushinteger(L, n);
  return 3;
}

static int lua_shm_next(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);

  typedef managed_shared_memory::const_named_iterator const_named_it;
  const_named_it named_beg = shm->named_begin();
  const_named_it named_end = shm->named_end();

  if (lua_isnil(L, 2) || lua_isnone(L, 2)) {
    // if it is not empty return the first
    if (named_beg != named_end) { 
      lua_pushstring(L, named_beg->name());
      lua_pushlightuserdata(L, (void *)named_beg->value());
      return 2;
    } else {
      lua_pushnil(L);
      return 1;
    }
  }

  const char *key = luaL_checkstring(L, 2);
  bool find = false;
  do {
    if (find) {
      lua_pushstring(L, named_beg->name());
      lua_pushlightuserdata(L, (void *)named_beg->value());
      return 2;
    } else {
      const managed_shared_memory::char_type *name = named_beg->name();
      std::size_t name_len = named_beg->name_length();
      if (std::string(key) == std::string(name)) {
        find = true;
      }
    }
  } while (++named_beg != named_end);

  lua_pushnil(L);
  return 1;
}

static int lua_shm_tostring(lua_State *L) {
  managed_shared_memory *shm = lua_checkshm(L, 1);
  lua_pushfstring(L, "shm(%p): %d bytes, %d free, %d named, %d unique",
                    shm, shm->get_size(), shm->get_free_memory(),
                    shm->get_num_named_objects(), shm->get_num_unique_objects());
  return 1;
}

static const struct luaL_reg shm_functions[] = {
  {"new", lua_shm_create},
  {"open", lua_shm_open},
  {"destroy", lua_shm_destroy},
  {NULL, NULL}
};

static const struct luaL_reg shm_methods[] = {
  {"empty", lua_shm_create_empty_variable},
  {"set", lua_shm_set},
  {"get", lua_shm_get},
  {"pointer", lua_shm_pointer},
  {"next", lua_shm_next},
  {"size", lua_shm_size},
  {"__gc", lua_shm_delete},
  {"__newindex", lua_shm_set},
  {"__tostring", lua_shm_tostring},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_shm (lua_State *L) {
  luaL_newmetatable(L, "shm_mt");

  // OO access: mt.__index = mt
  // Not compatible with array access
  lua_pushvalue(L, -1);
  lua_setfield(L, -2, "__index");

  /*
  // Array access: mt.__index = get(); mt.__newindex = set()
  // Not compatible with OO access
  lua_pushstring(L, "__index");
  lua_pushcfunction(L, lua_shm_get);
  lua_settable(L, -3);
  */

  luaL_register(L, NULL, shm_methods);
  luaL_register(L, "shm", shm_functions);

  return 1;
}
