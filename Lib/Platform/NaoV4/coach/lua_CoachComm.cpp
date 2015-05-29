#include <iostream>
#include <string>
#include <deque>
#include <string.h>
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
#include <errno.h>

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
#include <stdint.h>

#include "SPLCoachMessage.h"

static int send_fd;

// Set IP and PORT
static int lua_coachcomm_init(lua_State *L) {
	const char *ip = luaL_checkstring(L, 1);
  struct hostent *hostptr = gethostbyname(ip);
  if (hostptr == NULL) {
    return luaL_error(L, "Could not get hostname\n");
	}

  send_fd = socket(AF_INET, SOCK_DGRAM, 0);
  if (send_fd < 0) {
    return luaL_error(L, "Could not open datagram send socket\n");
  }

  int i = 1;
  if (setsockopt(send_fd, SOL_SOCKET, SO_BROADCAST, &i, sizeof(int)) < 0) {
    return luaL_error(L, "Could not set broadcast option: %s\n", strerror(errno));
  }

  struct sockaddr_in dest_addr;
  bzero((char *) &dest_addr, sizeof(dest_addr));
  dest_addr.sin_family = AF_INET;
  bcopy(hostptr->h_addr, (char *) &dest_addr.sin_addr, hostptr->h_length);
  dest_addr.sin_port = htons(SPL_COACH_MESSAGE_PORT);

  if (connect(send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr)) < 0) {
    return luaL_error(L, "Could not connect to destination address\n");
  }
 	return 0;
}

static int lua_coachcomm_send(lua_State *L) {
  struct SPLCoachMessage msg;
	/* header */
	*(uint32_t*) msg.header = *(const uint32_t*) SPL_COACH_MESSAGE_STRUCT_HEADER;
  /* version */
  msg.version = SPL_COACH_MESSAGE_STRUCT_VERSION;
	/* team number (0: blue, 1: red) */
	msg.team = (uint8_t) luaL_checkint(L, 1);
	/* message */
	size_t msg_len;
	const char* msg_str = (const char*)lua_tolstring(L, 2, &msg_len);
	/* Too long of a message? */
	if (msg_len >= SPL_COACH_MESSAGE_SIZE) {
    lua_pushstring(L, "Too long of a message");
		return 1;
	} else {
		strcpy( (char*)msg.message, msg_str);
	}
	/* Send the message */
	char* err = NULL;
  int ret = send(send_fd, &msg, sizeof(struct SPLCoachMessage), 0);
	/* Check if there was an error sending */
	if (ret == -1) {
		lua_pushstring(L, strerror(errno));
  } else {
		lua_pushinteger(L, ret);
	}
	return 1;
}

static const struct luaL_reg CoachComm_lib [] = {
  {"init", lua_coachcomm_init},
  {"send", lua_coachcomm_send},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_CoachComm (lua_State *L) {
  luaL_register(L, "CoachComm", CoachComm_lib);

  return 1;
}

