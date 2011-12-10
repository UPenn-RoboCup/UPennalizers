/*
  Lua module to parse game control packets
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

#include "string.h"
#include "RoboCupGameControlData.h"

static int lua_gamecontrolpacket_parse(lua_State *L) {
  struct RoboCupGameControlData *data = NULL;
  size_t len;

  switch (lua_type(L, 1)) {
    case LUA_TLIGHTUSERDATA:
    case LUA_TUSERDATA:
      data = (struct RoboCupGameControlData *)lua_topointer(L, 1);
      break;
    case LUA_TSTRING:
      data = (struct RoboCupGameControlData *)lua_tolstring(L, 1, &len);
      if (len < sizeof(struct RoboCupGameControlData)) {
        return 0;
      }
      break;
  }

  if (data == NULL) {
    return 0;
  }

  if (strncmp(data->header, GAMECONTROLLER_STRUCT_HEADER, 4) != 0) {
    return 0;
  }

  lua_createtable(L, 0, 10);

  // version field
  lua_pushstring(L, "version");
  lua_pushnumber(L, data->version);
  lua_settable(L, -3);

  lua_pushstring(L, "playersPerTeam");
  lua_pushnumber(L, data->playersPerTeam);
  lua_settable(L, -3);

  lua_pushstring(L, "state");
  lua_pushnumber(L, data->state);
  lua_settable(L, -3);

  lua_pushstring(L, "firstHalf");
  lua_pushnumber(L, data->firstHalf);
  lua_settable(L, -3);

  lua_pushstring(L, "kickOffTeam");
  lua_pushnumber(L, data->kickOffTeam);
  lua_settable(L, -3);

  lua_pushstring(L, "secondaryState");
  lua_pushnumber(L, data->secondaryState);
  lua_settable(L, -3);

  lua_pushstring(L, "dropInTeam");
  lua_pushnumber(L, data->dropInTeam);
  lua_settable(L, -3);

  lua_pushstring(L, "dropInTime");
  lua_pushnumber(L, data->dropInTime);
  lua_settable(L, -3);

  lua_pushstring(L, "secsRemaining");
  lua_pushnumber(L, data->secsRemaining);
  lua_settable(L, -3);

  lua_pushstring(L, "teams");
  lua_createtable(L, 2, 0);

  for (int iteam = 0; iteam < 2; iteam++) {
    lua_createtable(L, 0, 4);

    lua_pushstring(L, "teamNumber");
    lua_pushnumber(L, data->teams[iteam].teamNumber);
    lua_settable(L, -3);

    lua_pushstring(L, "teamColour");
    lua_pushnumber(L, data->teams[iteam].teamColour);
    lua_settable(L, -3);

    lua_pushstring(L, "score");
    lua_pushnumber(L, data->teams[iteam].score);
    lua_settable(L, -3);

    lua_pushstring(L, "player");
    lua_createtable(L, MAX_NUM_PLAYERS, 0);
    // TODO: Populate robot info tables
    for (int iplayer = 0; iplayer < MAX_NUM_PLAYERS; iplayer++) {
      lua_createtable(L, 0, 2);

      lua_pushstring(L, "penalty");
      lua_pushnumber(L, data->teams[iteam].players[iplayer].penalty);
      lua_settable(L, -3);

      lua_pushstring(L, "secsRemaining");
      lua_pushnumber(L, data->teams[iteam].players[iplayer].secsTillUnpenalised);
      lua_settable(L, -3);

      lua_rawseti(L, -2, iplayer+1);
    }
    lua_settable(L, -3);

    lua_rawseti(L, -2, iteam+1);
  }

  lua_settable(L, -3);
  return 1;
}

static const struct luaL_reg gamecontrolpacket_functions[] = {
  {"parse", lua_gamecontrolpacket_parse},

  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_GameControlPacket (lua_State *L) {
  luaL_register(L, "GameControlPacket", gamecontrolpacket_functions);
  return 1;
}
