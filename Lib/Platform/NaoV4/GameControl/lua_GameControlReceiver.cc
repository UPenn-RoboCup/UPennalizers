#include "timeScalar.h"
#include "string.h"
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <assert.h>
#include <netdb.h>
#include <stdio.h>
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

static int sock_fd, send_fd;
static struct RoboCupGameControlData gameControlData;
static struct RoboCupGameControlReturnData gameControlReturnData;
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

  lua_createtable(L, 0, 13);  

  lua_pushstring(L, "time");
  lua_pushnumber(L, recvTime);
  lua_settable(L, -3);

  // version field
  lua_pushstring(L, "version");
  lua_pushnumber(L, data->version);
  lua_settable(L, -3);

  // number incremented with each packet sent (with wraparound)
  lua_pushstring(L, "packetNumber");
  lua_pushnumber(L, data->packetNumber);
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

  lua_pushstring(L, "secondaryTime");
  lua_pushnumber(L, data->secondaryTime);
  lua_settable(L, -3);

  lua_pushstring(L, "teams");
  lua_createtable(L, 2, 0);

  for (int iteam = 0; iteam < 2; iteam++) {
		struct TeamInfo ti = data->teams[iteam];
    lua_createtable(L, 0, 6);

    lua_pushstring(L, "teamNumber");
    lua_pushnumber(L, ti.teamNumber);
    lua_settable(L, -3);

    lua_pushstring(L, "teamColour");
    lua_pushnumber(L, ti.teamColour);
    lua_settable(L, -3);
 
    lua_pushstring(L, "score");
    lua_pushnumber(L, ti.score);
    lua_settable(L, -3);

    lua_pushstring(L, "penaltyShot");
    lua_pushnumber(L, ti.penaltyShot);
    lua_settable(L, -3);

    lua_pushstring(L, "singleShots");
    lua_pushnumber(L, ti.singleShots);
    lua_settable(L, -3);

    // coach message
    lua_pushstring(L, "coachMessage");
    // NOTE: Assume \0 terminated
    lua_pushstring(L, (const char*)ti.coachMessage);
    lua_settable(L, -3);

    // Coach
    lua_pushstring(L, "coach");
    lua_createtable(L, 0, 2);
    lua_pushstring(L, "penalty");
    lua_pushnumber(L, ti.coach.penalty);
    lua_settable(L, -3);
    lua_pushstring(L, "secsRemaining");
    lua_pushnumber(L, ti.coach.secsTillUnpenalised);
    lua_settable(L, -3);
    lua_settable(L,-3);

    lua_pushstring(L, "player");
    lua_createtable(L, MAX_NUM_PLAYERS, 0);

    for (int iplayer = 0; iplayer < MAX_NUM_PLAYERS; iplayer++) {
      lua_createtable(L, 0, 2);

      lua_pushstring(L, "penalty");
      lua_pushnumber(L, ti.players[iplayer].penalty);
      lua_settable(L, -3);

      lua_pushstring(L, "secsRemaining");
      lua_pushnumber(L, ti.players[iplayer].secsTillUnpenalised);
      lua_settable(L, -3);

      lua_rawseti(L, -2, iplayer+1);
    }
    lua_settable(L, -3);

    lua_rawseti(L, -2, iteam+1);
  }

  lua_settable(L, -3);
  return 1;
}


static int lua_gamecontrolreturn_send(lua_State *L) {
  static bool send_init = false;
  gameControlReturnData.team = (uint8_t)luaL_checkint(L, 1);
  gameControlReturnData.player = (uint8_t)luaL_checkint(L, 2);
  gameControlReturnData.message = (uint8_t)luaL_checkint(L, 3);
  const char *ip = luaL_checkstring(L, 4);
  struct hostent *hostptr = gethostbyname(ip);
  if (hostptr == NULL) {
    printf("Could not get hostname\n");
    return -1;
  }

  if (!send_init) {
    send_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (send_fd < 0) {
      printf("Could not open datagram send socket\n");
      return -1;
    }
  
    int i = 1;
    if (setsockopt(send_fd, SOL_SOCKET, SO_BROADCAST, (const char *) &i, sizeof(i)) < 0) {
      printf("Could not set broadcast option\n");
      return -1;
    }

    struct sockaddr_in dest_addr;
    bzero((char *) &dest_addr, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    bcopy(hostptr->h_addr, (char *) &dest_addr.sin_addr, hostptr->h_length);
    dest_addr.sin_port = htons(GAMECONTROLLER_PORT);

    if (connect(send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr)) < 0) {
      printf("Could not connect to destination address\n");
      return -1;
    }
    send_init = true;
  }

  int ret = send(send_fd, &gameControlReturnData, sizeof(gameControlReturnData),0);
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
      return luaL_error(L, "Could not open datagram socket\n");
    }

    struct sockaddr_in local_addr;
    bzero((char *) &local_addr, sizeof(local_addr));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(GAMECONTROLLER_PORT);
    if (bind(sock_fd, (struct sockaddr *) &local_addr, sizeof(local_addr)) < 0) {
      return luaL_error(L, "Could not bind to port\n");
    }

    // Nonblocking receive:
    int flags  = fcntl(sock_fd, F_GETFL, 0);
    if (flags == -1)
      flags = 0;
    if (fcntl(sock_fd, F_SETFL, flags | O_NONBLOCK) < 0) {
      return luaL_error(L, "Could not set nonblocking mode\n");
    }

    // TODO: set lua on close? is it possible
    init = true;
  }


  // Process incoming game controller messages:
  static sockaddr_in source_addr;
  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(sock_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);

  while (len > 0) {
    //printf("Packet: %d bytes of %zu\n", len, sizeof(RoboCupGameControlData));

    // Verify game controller header:
    if (memcmp(data, GAMECONTROLLER_STRUCT_HEADER, sizeof(GAMECONTROLLER_STRUCT_HEADER) - 1) == 0) {
if( len >= sizeof(RoboCupGameControlData) ){
      memcpy(&gameControlData, data, sizeof(RoboCupGameControlData));
      nGameControlData++;
      //printf("Game control: %d received.\n", nGameControlData);
}
    }
    len = recvfrom(sock_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);

		recvTime = time_scalar();
  }

  if (nGameControlData == 0) {
    // no messages received yet
    return 0;
  } else {
    return lua_gamecontrolpacket_parse(L, &gameControlData); 
  }

}

static const struct luaL_reg GameControlReceiver_lib [] = {
  {"receive", lua_gamecontrolpacket_receive},
  //{"parse", lua_gamecontrolpacket_parse},
  {"send", lua_gamecontrolreturn_send},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_GameControlReceiver (lua_State *L) {
  luaL_register(L, "GameControlReceiver", GameControlReceiver_lib);

  return 1;
}

