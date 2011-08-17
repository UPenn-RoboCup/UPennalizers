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

// Set the IP address for where to listen
//#define IP "255.255.255.255"
//#define IP "172.18.255.255"
//#define IP "192.168.123.255" // OP specific
//#define IP "192.168.1.255" // OP, new
//#define IP "192.168.0.255" 
//#define IP "192.168.255.255"
//#define IP "158.130.103.255" // AirPennNet-Guest specific
//#define IP "158.130.104.255" //AIRPENNET
//#define IP "10.66.68.255"

// lan
//#define IP "192.168.0.255"
// upenn wireless router
#define IP "192.168.0.255"
// turkey robocup
//#define IP "192.168.255.255"
//#define IP "192.168.0.255"

#define PORT 54321
#define MDELAY 2
#define TTL 16
//#define MAX_LENGTH 16000
#define MAX_LENGTH 160000 //Size for sending 640*480 yuyv data without resampling

const int maxQueueSize = 6;

static std::deque<std::string> recvQueue;
static int send_fd, recv_fd;

/*
void mexExit(void)
{
  if (send_fd > 0)
    close(send_fd);
  if (recv_fd > 0)
    close(recv_fd);
}
*/

static int lua_naocomm_update(lua_State *L) {
  static sockaddr_in source_addr;
  static char data[MAX_LENGTH];

  static bool init = false;
  if (!init) {
    printf("Comm connecting to %s\n", IP);

    struct hostent *hostptr = gethostbyname(IP);
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

    // TODO: set at exit
    init = true;
  }

  // Process incoming messages:
  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(recv_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);
  while (len > 0) {
    std::string msg((const char *) data, len);
    recvQueue.push_back(msg);

    len = recvfrom(recv_fd, data, MAX_LENGTH, 0, (struct sockaddr *) &source_addr, &source_addr_len);
  }

  // Remove older messages:
  while (recvQueue.size() > maxQueueSize) {
    recvQueue.pop_front();
  }

  return 1;
}

static int lua_naocomm_size(lua_State *L) {
  int updateRet = lua_naocomm_update(L);

  lua_pushinteger(L, recvQueue.size());
  return 1;
}

static int lua_naocomm_receive(lua_State *L) {
  int updateRet = lua_naocomm_update(L);

  if (recvQueue.empty()) {
    lua_pushnil(L);
    return 1;
  }

  // TODO: is this enough or do i need to pass an array with the bytes 
  lua_pushstring(L, recvQueue.front().c_str());
  recvQueue.pop_front();

  /*
  int n = recvQueue.front().size();
  mwSize dims[2];
  dims[0] = 1;
  dims[1] = n;
  plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
  memcpy(mxGetData(plhs[0]), recvQueue.front().c_str(), n);
  recvQueue.pop_front();
  */

  return 1;
}


static int lua_naocomm_send(lua_State *L) {
  int updateRet = lua_naocomm_update(L);

  const char *data = luaL_checkstring(L, 1);

  std::string dataStr(data);

  int ret = send(send_fd, dataStr.c_str(), dataStr.size(), 0);
    
  lua_pushinteger(L, ret);

  /*
  if (nrhs < 2)
    mexErrMsgTxt("No input argument");
  int n = mxGetNumberOfElements(prhs[1])*mxGetElementSize(prhs[1]);
  int ret = send(send_fd, mxGetData(prhs[1]), n, 0);
  plhs[0] = mxCreateDoubleScalar(ret);

  // Put it in receive queue as well:
  //std::string msg((const char *) mxGetData(prhs[1]), n);
  //recvQueue.push_back(msg);
  */

  return 1;
}

static const struct luaL_reg NaoComm_lib [] = {
  {"size", lua_naocomm_size},
  {"receive", lua_naocomm_receive},
  {"send", lua_naocomm_send},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_NaoComm (lua_State *L) {
  luaL_register(L, "NaoComm", NaoComm_lib);

  return 1;
}

