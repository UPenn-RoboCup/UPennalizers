/**
 * Lua module to expose some common c utilties
 *
 * University of Pennsylvania
 * 2010
 */

#include <stdlib.h>
#include <stdint.h>
#include <math.h>
#include <vector>
#include <string>
#include <map>

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


const char ascii_lut[] = "0123456789abcdef";
const int8_t byte_lut[] = { 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
                            0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0};


std::map<std::string, int> dataTypeMap;

// use matlab support datatype names
void init_dataTypeMap() {
  dataTypeMap["int8"]     = sizeof(int8_t);
  dataTypeMap["int16"]    = sizeof(int16_t);
  dataTypeMap["int32"]    = sizeof(int32_t);
  dataTypeMap["int64"]    = sizeof(int64_t);
  dataTypeMap["uint8"]    = sizeof(uint8_t);
  dataTypeMap["uint16"]   = sizeof(uint16_t);
  dataTypeMap["uint32"]   = sizeof(uint32_t);
  dataTypeMap["uint64"]   = sizeof(uint64_t);
  dataTypeMap["single"]   = sizeof(float);
  dataTypeMap["double"]   = sizeof(double);
}


static int lua_array2string(lua_State *L) {
  uint8_t *data = (uint8_t *) lua_touserdata(L, 1);
  if ((data == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  
  int width = luaL_checkint(L, 2);
  int height = luaL_checkint(L, 3);
  std::string dtype(luaL_checkstring(L, 4));
  std::string name(luaL_checkstring(L, 5));

  std::map<std::string, int>::iterator idataTypeMap = dataTypeMap.find(dtype);
  if (idataTypeMap == dataTypeMap.end()) {
    return luaL_error(L, "unkown dtype: %s", dtype.c_str());
  }
  int nbytes = idataTypeMap->second;

  int size = width*height * nbytes;
  char cdata[(2*size) + 1];

  int ind = 0;
  int cind = 0;
  while (ind < size) {
    cdata[cind] = ascii_lut[(data[ind] & 0xf0) >> 4];
    cdata[cind+1] = ascii_lut[(data[ind] & 0x0f)];
    ind += 1;
    cind += 2;
  }
  cdata[(2*size)] = '\0';

  // create lua table
  lua_createtable(L, 0, 5);

  lua_pushstring(L, "name");
  lua_pushstring(L, name.c_str());
  lua_settable(L, -3);

  lua_pushstring(L, "width");
  lua_pushnumber(L, width);
  lua_settable(L, -3);

  lua_pushstring(L, "height");
  lua_pushnumber(L, height);
  lua_settable(L, -3);

  lua_pushstring(L, "dtype");

  lua_createtable(L, 0, 2);
  lua_pushstring(L, "name");
  lua_pushstring(L, dtype.c_str());
  lua_settable(L, -3);

  lua_pushstring(L, "nbytes");
  lua_pushnumber(L, nbytes);
  lua_settable(L, -3);

  lua_settable(L, -3);

  lua_pushstring(L, "data");
  lua_pushstring(L, cdata);
  lua_settable(L, -3);

  return 1;
}

static int lua_string2userdata(lua_State *L) {
  uint8_t *dout = (uint8_t *) lua_touserdata(L, 1);
  if ((dout == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "output argument not light user data");
  }

  const char *cdata = luaL_checkstring(L, 2);

  int ind = 0;
  int cind = 0;
  while (cdata[cind] != '\0' && cdata[cind+1] != '\0') {
    uint8_t bh = cdata[cind] >= 'a' ? cdata[cind] - 'a' + 10 : cdata[cind] - '0';
    uint8_t bl = cdata[cind+1] >= 'a' ? cdata[cind+1] - 'a' + 10 : cdata[cind+1] - '0';
    dout[ind] = (uint8_t)((bh<<4) | bl);

    ind += 1;
    cind += 2;
  }

  return 1;
}

static int lua_ptradd(lua_State *L) {
  uint8_t *ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "ptr argument not light user data");
  }

  int n = luaL_checkinteger(L, 2);
  std::string dtype(luaL_checkstring(L, 3));

  std::map<std::string, int>::iterator idataTypeMap = dataTypeMap.find(dtype);
  if (idataTypeMap == dataTypeMap.end()) {
    return luaL_error(L, "unkown dtype: %s", dtype.c_str());
  }
  int nbytes = n * (idataTypeMap->second);

  lua_pushlightuserdata(L, ptr + nbytes); 

  return 1;
}

static int lua_sizeof(lua_State *L) {
  std::string dtype(luaL_checkstring(L, 1));

  std::map<std::string, int>::iterator idataTypeMap = dataTypeMap.find(dtype);
  if (idataTypeMap == dataTypeMap.end()) {
    return luaL_error(L, "unkown dtype: %s", dtype.c_str());
  }
  int nbytes = idataTypeMap->second;

  lua_pushinteger(L, nbytes); 

  return 1;
}

static int lua_testarray(lua_State *L) {
  static uint32_t *ptr = NULL;
  int size = 160*230;
  if (ptr == NULL) {
    ptr = (uint32_t*)malloc(size*sizeof(uint32_t));
    for (int i = 0; i < size; i++) {
      ptr[i] = i;
    }
  }

  lua_pushlightuserdata(L, ptr);

  return 1;
}

static int lua_bitand(lua_State *L) {
  int a = luaL_checkint(L, 1); 
  int b = luaL_checkint(L, 2); 

  lua_pushinteger(L, a & b);

  return 1;
}


static int lua_bitor(lua_State *L) {
  int a = luaL_checkint(L, 1); 
  int b = luaL_checkint(L, 2); 

  lua_pushinteger(L, a | b);

  return 1;
}

static int lua_bitxor(lua_State *L) {
  int a = luaL_checkint(L, 1); 
  int b = luaL_checkint(L, 2); 

  lua_pushinteger(L, a ^ b);

  return 1;
}

static int lua_bitnot(lua_State *L) {
  int a = luaL_checkint(L, 1); 

  lua_pushinteger(L, ~a);

  return 1;
}

static const struct luaL_reg cutil_lib [] = {
  {"array2string", lua_array2string},
  {"string2userdata", lua_string2userdata},
  {"ptr_add", lua_ptradd},
  {"bit_and", lua_bitand},
  {"bit_or", lua_bitor},
  {"bit_xor", lua_bitxor},
  {"bit_not", lua_bitnot},
  {"sizeof", lua_sizeof},
  {"test_array", lua_testarray},

  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_cutil (lua_State *L) {
  luaL_register(L, "cutil", cutil_lib);

  init_dataTypeMap();
  
  return 1;
}

