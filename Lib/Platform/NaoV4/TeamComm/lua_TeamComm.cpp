// --------------------------
// SPL Team Communication
// (c) 2014 Qin He
// --------------------------

#include <iostream>
#include <string>
#include <deque>
#include "string.h"
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <assert.h>

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

#include <vector>
#include <algorithm>
#include <stdint.h>

#include "SPLStandardMessage.h"

#define MAX_LENGTH 16000 //10240

static struct SPLStandardMessage SPLMessageData;
static int nSPLMessageData = 0;
static double recvTime = 0;

//TODO: How long do we want the queue to be?
const int maxQueueSize = 10;
static std::string IP;
static int PORT = 0;
static int parsed = 0;

static std::deque<SPLStandardMessage> recvQueue;
static int send_fd, recv_fd;


// Set IP and PORT
static int lua_teamcomm_init(lua_State *L) {
	const char *ip = luaL_checkstring(L, 1);
	int port = luaL_checkint(L,2);
	IP = ip;
	PORT = port;

  assert(IP.empty()!=1);
  assert(PORT!=0);

  struct hostent *hostptr = gethostbyname(IP.c_str());
  if (hostptr == NULL) {
    printf("Could not get hostname\n");
    return -1;
  }

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
  dest_addr.sin_port = htons(PORT);

  if (connect(send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr)) < 0) {
    printf("Could not connect to destination address\n");
    return -1;
  }

  recv_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (recv_fd < 0) {
    printf("Could not open datagram recv socket\n");
    return -1;
  }

  struct sockaddr_in local_addr;
  bzero((char *) &local_addr, sizeof(local_addr));
  local_addr.sin_family = AF_INET;
  local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
  local_addr.sin_port = htons(PORT);
  if (bind(recv_fd, (struct sockaddr *) &local_addr, sizeof(local_addr)) < 0) {
    printf("Could not bind to port\n");
    return -1;
  }

  // Nonblocking receive:
  int flags  = fcntl(recv_fd, F_GETFL, 0);
  if (flags == -1)
    flags = 0;
  if (fcntl(recv_fd, F_SETFL, flags | O_NONBLOCK) < 0) {
    printf("Could not set nonblocking mode\n");
    return -1;
  }
  
 	return 1;
}


// Parse incoming SPL standard message
static int lua_teamcomm_recv_parse(lua_State *L, SPLStandardMessage *data) {
  if (data == NULL) {
    return 0;
  }
  // Verify struct header
  if (strncmp(data->header, SPL_STANDARD_MESSAGE_STRUCT_HEADER, 4) != 0) {
    return 0;
  }

  lua_createtable(L, 0, 13);

  //TODO: recvTime

  // version field
  lua_pushstring(L, "version");
  lua_pushnumber(L, data->version);
  lua_settable(L, -3);

  // Player number: 1-5
  lua_pushstring(L, "playerNum");
  lua_pushnumber(L, data->playerNum);
  lua_settable(L, -3);

  // Team: 0-blue, 1-red
  lua_pushstring(L, "teamNum");
  lua_pushnumber(L, data->teamNum);
  lua_settable(L, -3);

  //1: fallen, 0: able to play
  lua_pushstring(L, "fallen");
  lua_pushnumber(L, data->fallen);
  lua_settable(L, -3);

  // position and orientation of robot
  // coordinates in millimeters, angle in radians
  lua_pushstring(L, "pose");
  lua_createtable(L, 3, 0);
  for (int i=0; i<3; i++) {
    lua_pushnumber(L, data->pose[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_settable(L, -3);


  // the robot's target position on the field
  // if the robot does not have any target,
  // this attribute should be set to the robot's position
  lua_pushstring(L, "walkingTo");
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, data->walkingTo[0]);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, data->walkingTo[1]);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  // the target position of the next shot (either pass or goal shot)
  // if the robot does not intend to shoot,
  //this attribute should be set to the robot's position
  lua_pushstring(L, "shootingTo");
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, data->shootingTo[0]);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, data->shootingTo[1]);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  // ms since this robot last saw the ball. -1 if we haven't seen it
  lua_pushstring(L, "ballAge");
  lua_pushnumber(L, data->ballAge);
  lua_settable(L, -3);

  // position of ball relative to the robot
  // coordinates in millimeters
  lua_pushstring(L, "ball");
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, data->ball[0]);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, data->ball[1]);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  lua_pushstring(L, "ballVel");
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, data->ballVel[0]);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, data->ballVel[1]);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  lua_pushstring(L, "suggestion");
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, data->suggestion[0]);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, data->suggestion[1]);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, data->suggestion[2]);
  lua_rawseti(L, -2, 3);
  lua_pushnumber(L, data->suggestion[3]);
  lua_rawseti(L, -2, 4);
  lua_pushnumber(L, data->suggestion[4]);
  lua_rawseti(L, -2, 5);
  lua_settable(L, -3);

  // Intention
  lua_pushstring(L, "intention");
  lua_pushnumber(L, data->intention);
  lua_settable(L, -3);
  
  lua_pushstring(L, "averageWalkSpeed");
  lua_pushnumber(L, data->averageWalkSpeed);
  lua_settable(L, -3);
  
  lua_pushstring(L, "maxKickDistance");
  lua_pushnumber(L, data->maxKickDistance);
  lua_settable(L, -3);
  
  lua_pushstring(L, "currentPositionConfidence");
  lua_pushnumber(L, data->currentPositionConfidence);
  lua_settable(L, -3);
  
  lua_pushstring(L, "currentSideConfidence");
  lua_pushnumber(L, data->currentSideConfidence);
  lua_settable(L, -3);

  lua_pushstring(L, "numOfDataBytes");
  lua_pushnumber(L, data->numOfDataBytes);
  lua_settable(L, -3);

  //Simple array instead of string
  uint16_t textlength = data->numOfDataBytes;
  lua_pushstring(L, "data");
  lua_createtable(L, textlength, 0);
  for (int i=0; i<textlength; i++) {
    lua_pushnumber(L, data->data[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_settable(L, -3);
  return 1;
}

// Set SPLStandardMessage struct
static int lua_teamcomm_send_parse(lua_State *L, SPLStandardMessage *msg) {
  luaL_checktype(L,1, LUA_TTABLE);

  // TODO: check if the key exists


  // header
  lua_pushstring(L, "header");
  lua_gettable(L, -2);
  *(uint32_t*) msg->header =  *(const uint32_t*)SPL_STANDARD_MESSAGE_STRUCT_HEADER;
  lua_pop(L, 1);
  
  lua_pushstring(L, "version");
  lua_gettable(L, -2);
  uint8_t userversion = (uint8_t)lua_tonumber(L, -1);
  if (userversion != SPL_STANDARD_MESSAGE_STRUCT_VERSION)
    printf("version wrong! Must use %d\n",SPL_STANDARD_MESSAGE_STRUCT_VERSION);
  msg->version = SPL_STANDARD_MESSAGE_STRUCT_VERSION;
  lua_pop(L, 1);

  lua_pushstring(L, "playerNum");
  lua_gettable(L, -2);
  msg->playerNum = lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "teamNum");
  lua_gettable(L, -2);
  msg->teamNum = lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "fallen");
  lua_gettable(L, -2);
  msg->fallen = lua_tonumber(L, -1);
  lua_pop(L, 1);

  //TODO: better way to get values from lua table?
  lua_pushstring(L, "pose");
  lua_gettable(L, -2);
  for (int i=0; i<3; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->pose[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);
    
  lua_pushstring(L, "walkingTo");
  lua_gettable(L, -2);
  for (int i=0; i<2; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->walkingTo[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);
    
  lua_pushstring(L, "shootingTo");
  lua_gettable(L, -2);
  for (int i=0; i<2; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->shootingTo[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);

  lua_pushstring(L, "ballAge");
  lua_gettable(L, -2);
  msg->ballAge = lua_tonumber(L, -1);
  lua_pop(L, 1);
      
  lua_pushstring(L, "ball");
  lua_gettable(L, -2);
  for (int i=0; i<2; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->ball[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);

  lua_pushstring(L, "ballVel");
  lua_gettable(L, -2);
  for (int i=0; i<2; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->ballVel[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);

  lua_pushstring(L, "suggestion");
  lua_gettable(L, -2);
  for (int i=0; i<5; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);
    msg->suggestion[i] = (int8_t)lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  lua_pop(L,1);

  lua_pushstring(L, "intention");
  lua_gettable(L, -2);
  msg->intention = (int8_t)lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "averageWalkSpeed");
  lua_gettable(L, -2);
  msg->averageWalkSpeed = (int16_t)lua_tonumber(L, -1);
  lua_pop(L, 1);
  
  lua_pushstring(L, "maxKickDistance");
  lua_gettable(L, -2);
  msg->maxKickDistance = (int16_t)lua_tonumber(L, -1);
  lua_pop(L, 1); 
  
  lua_pushstring(L, "currentPositionConfidence");
  lua_gettable(L, -2);
  msg->currentPositionConfidence = (int8_t)lua_tonumber(L, -1);
  lua_pop(L, 1);
  
  lua_pushstring(L, "currentSideConfidence");
  lua_gettable(L, -2);
  msg->currentSideConfidence = (int8_t)lua_tonumber(L, -1);
  lua_pop(L, 1);

  lua_pushstring(L, "numOfDataBytes");
  lua_gettable(L, -2);
  int num = lua_tonumber(L, -1);
  if (num>SPL_STANDARD_MESSAGE_DATA_SIZE){
    num = SPL_STANDARD_MESSAGE_DATA_SIZE;
    printf("Warning! Arbitrary data oversized. Only the first %d bytes will be sent\n",num);
  }
  msg->numOfDataBytes = num;
  lua_pop(L, 1);

  //Simple array instead of string
  lua_pushstring(L, "data");
  lua_gettable(L, -2);
  for (int i=0; i<num; i++) {
    lua_pushinteger(L, i+1);
    lua_gettable(L, -2);    
    msg->data[i] = (uint8_t)lua_tonumber(L, -1);;
    lua_pop(L, 1);
  }
  lua_pop(L,1);

  return 1;
}


static int lua_teamcomm_update(lua_State *L) {
  static sockaddr_in source_addr;
  static char data[MAX_LENGTH];

  // Process incoming messages
  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(recv_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);
  nSPLMessageData = 0;
  
  while (len > 0) {
    //TODO: this might be slow
    memcpy(&SPLMessageData, data, sizeof(SPLStandardMessage));
    nSPLMessageData++;
    //printf("parsed? %d\n", parsed);
    if (!recvQueue.empty() && parsed==1) {
    	parsed = 0;
    	recvQueue.pop_front();
    }
    recvQueue.push_back(SPLMessageData);
    // printf("Queue size: %d \n", recvQueue.size());

    len = recvfrom(recv_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);
  }

  // Remove older messages
  while (recvQueue.size() > maxQueueSize) {
    recvQueue.pop_front();
  }

  return 1;
}


static int lua_teamcomm_size(lua_State *L) {
  int updateRet = lua_teamcomm_update(L);
  lua_pushinteger(L, recvQueue.size());
  return 1;
}

static int lua_teamcomm_receive(lua_State *L) {
  int updateRet = lua_teamcomm_update(L);
  if (nSPLMessageData==0 || recvQueue.empty()) {
    // no messages received yet
    lua_pushnil(L);
    return 1;
  }
  if (!recvQueue.empty()) {
  	parsed = 1;
    return lua_teamcomm_recv_parse(L, &recvQueue.front());
  }
  return 1;
}

static int lua_teamcomm_send(lua_State *L) {
  struct SPLStandardMessage senddata;
  lua_teamcomm_send_parse(L, &senddata);
  
  int ret = send(send_fd, &senddata, sizeof(senddata), 0);
  lua_pushinteger(L, ret);
  return 1;
}


static const struct luaL_reg TeamComm_lib [] = {
  {"init", lua_teamcomm_init},
  {"size", lua_teamcomm_size},
  {"receive", lua_teamcomm_receive},
  {"send", lua_teamcomm_send},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_TeamComm (lua_State *L) {
  luaL_register(L, "TeamComm", TeamComm_lib);

  return 1;
}

