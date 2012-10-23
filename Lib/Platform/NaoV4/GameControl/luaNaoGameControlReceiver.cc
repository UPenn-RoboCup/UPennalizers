#include "timeScalar.h"
#include "string.h"
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

// Needed typedefs:
typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;

#include "RoboCupGameControlData.h"

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

#define PORT 3838

static int sock_fd = 0;
static struct RoboCupGameControlData gameControlData;
static int nGameControlData = 0;
static double recvTime = 0;

/*
void mexExit(void)
{
  if (sock_fd > 0)
    close(sock_fd);
}
*/
  

static int lua_gamecontrolpacket_parse(lua_State *L, RoboCupGameControlData *data) {
  if (data == NULL) {
    return 0;
  }

  if (strncmp(data->header, GAMECONTROLLER_STRUCT_HEADER, 4) != 0) {
    return 0;
  }

  lua_createtable(L, 0, 11);

  lua_pushstring(L, "time");
  lua_pushnumber(L, recvTime);
  lua_settable(L, -3);

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

static int lua_gamecontrolpacket_receive(lua_State *L) {
  const int MAX_LENGTH = 4096;
  static char data[MAX_LENGTH];
  static bool init = false;

  // TODO: figure out lua error throw method
  if (!init) {
    sock_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock_fd < 0) {
      printf("Could not open datagram socket\n");
      return -1;
    }

    struct sockaddr_in local_addr;
    bzero((char *) &local_addr, sizeof(local_addr));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(PORT);
    if (bind(sock_fd, (struct sockaddr *) &local_addr, sizeof(local_addr)) < 0) {
      printf("Could not bind to port\n");
      return -1;
    }

    // Nonblocking receive:
    int flags  = fcntl(sock_fd, F_GETFL, 0);
    if (flags == -1)
      flags = 0;
    if (fcntl(sock_fd, F_SETFL, flags | O_NONBLOCK) < 0) {
      printf("Could not set nonblocking mode\n");
      return -1;
    }

    // TODO: set lua on close? is it possible
    init = true;
  }


  // Process incoming game controller messages:
  static sockaddr_in source_addr;
  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(sock_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);

  while (len > 0) {
    //printf("Packet: %d bytes\n", len);

    // Verify game controller header:
    if (memcmp(data, GAMECONTROLLER_STRUCT_HEADER, sizeof(GAMECONTROLLER_STRUCT_HEADER) - 1) == 0) {
      memcpy(&gameControlData, data, sizeof(RoboCupGameControlData));    
      nGameControlData++;
      //printf("Game control: %d received.\n", nGameControlData);
    }
    len = recvfrom(sock_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);

		recvTime = time_scalar();
  }

  if (nGameControlData == 0) {
    // no messages received yet
    lua_pushnil(L); 
  } else {
    return lua_gamecontrolpacket_parse(L, &gameControlData); 
  }

  return 1;
}

static const struct luaL_reg NaoGameControlReceiver_lib [] = {
  {"receive", lua_gamecontrolpacket_receive},
  //{"parse", lua_gamecontrolpacket_parse},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_NaoGameControlReceiver (lua_State *L) {
  luaL_register(L, "NaoGameControlReceiver", NaoGameControlReceiver_lib);

  return 1;
}

