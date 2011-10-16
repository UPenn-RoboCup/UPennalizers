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
#define IP "192.168.123.255" // OP wired
//#define IP "192.168.1.255" // OP, wireless
//#define IP "192.168.255.255"
//#define IP "158.130.103.255" // AirPennNet-Guest specific
//#define IP "158.130.104.255" //AIRPENNET
//#define IP "10.66.68.255"
//#define IP "192.168.118.255" // OP, Istanbul

#define PORT 111111
#define MDELAY 2
#define TTL 16
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

static int lua_darwinopcomm_update(lua_State *L) {
  static sockaddr_in source_addr;
  static char data[MAX_LENGTH];

  static bool init = false;
  if (!init) {
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

static int lua_darwinopcomm_size(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

  lua_pushinteger(L, recvQueue.size());
  return 1;
}

static int lua_darwinopcomm_receive(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

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


static int lua_darwinopcomm_send(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

  // TODO: implement send command
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


static int lua_darwinopcomm_send_yuyv(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

  std::string dataStrY;
  std::string dataStrU;
  std::string dataStrV;

  uint32_t *yuyv = (uint32_t *) lua_touserdata(L, 1);//yuyv image
  if ((yuyv == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input YUYV not light user data");
  }
  int m = luaL_checkint(L, 2);    //Width (in macro pixel)
  int n = luaL_checkint(L, 3);    //Height
  int samplerate = luaL_checkint(L, 4);    //sampling rate
  int robotid = luaL_checkint(L, 5);    //robot ID

  int m_sample=m/samplerate;
  int n_sample=n/samplerate;

  dataStrY.push_back(14);	//yuyv data Y
  dataStrY.push_back(m_sample/256); //High bit of width
  dataStrY.push_back(m_sample%256); //Low bit of width
  dataStrY.push_back(n_sample/256); //High bit of height
  dataStrY.push_back(n_sample%256); //Low bit of height
  dataStrY.push_back(robotid);	//robot ID


  dataStrU.push_back(15);	//yuyv data U
  dataStrU.push_back(m_sample/256); //High bit of width
  dataStrU.push_back(m_sample%256); //Low bit of width
  dataStrU.push_back(n_sample/256); //High bit of height
  dataStrU.push_back(n_sample%256); //Low bit of height
  dataStrU.push_back(robotid);	//robot ID

  dataStrV.push_back(16);	//yuyv data V
  dataStrV.push_back(m_sample/256); //High bit of width
  dataStrV.push_back(m_sample%256); //Low bit of width
  dataStrV.push_back(n_sample/256); //High bit of height
  dataStrV.push_back(n_sample%256); //Low bit of height
  dataStrV.push_back(robotid);	//robot ID


  for (int j = 0; j < n; j++) {
          for (int i = 0; i < m; i++) {
		if (((i%samplerate==0) && (j%samplerate==0)) || samplerate==1)	{
		    char indexY= (*yuyv & 0xFC000000) >> 26;
		    char indexU= (*yuyv & 0x0000FC00) >> 10;
		    char indexV= (*yuyv & 0xFC0000FC) >> 2;
		    dataStrY.push_back(indexY);
		    dataStrU.push_back(indexU);
		    dataStrV.push_back(indexV);
		}
	        yuyv++;
          }
  }

  int ret1 = send(send_fd, dataStrY.c_str(), dataStrY.size(), 0);
  int ret2 = send(send_fd, dataStrU.c_str(), dataStrU.size(), 0);
  int ret3 = send(send_fd, dataStrV.c_str(), dataStrV.size(), 0);
  lua_pushinteger(L, ret1+ret2+ret3);
  return 1;
}


static int lua_darwinopcomm_send_label(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

  std::string dataStr;
  uint8_t *label = (uint8_t *) lua_touserdata(L, 1);//label image

  if ((label == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input Label not light user data");
  }

  int m = luaL_checkint(L, 2);    //Width 
  int n = luaL_checkint(L, 3);    //Height
  int samplerate = luaL_checkint(L, 4);    //downsample rate
  int robotid = luaL_checkint(L, 5);    //robot ID

  int m_sample=m/samplerate;
  int n_sample=n/samplerate;

  dataStr.push_back(17);	//Label data
  dataStr.push_back(m_sample/256); //High bit of width
  dataStr.push_back(m_sample%256); //Low bit of width
  dataStr.push_back(n_sample/256); //High bit of height
  dataStr.push_back(n_sample%256); //Low bit of height
  dataStr.push_back(robotid);	//robot ID

  for (int j = 0; j < n; j++) {
          for (int i = 0; i < m; i++) {
	    if(  ( (i%samplerate==0) && (j%samplerate==0)) || (samplerate==1))
		    dataStr.push_back(*label);
            label++;
          }
  }

  int ret = send(send_fd, dataStr.c_str(), dataStr.size(), 0);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_darwinopcomm_send_yuyv2(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);

  std::string dataStrY;
  std::string dataStrU;
  std::string dataStrV;

  uint32_t *yuyv = (uint32_t *) lua_touserdata(L, 1);//yuyv image
  if ((yuyv == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input YUYV not light user data");
  }
  int m = luaL_checkint(L, 2);    //Width (in macro pixel)
  int n = luaL_checkint(L, 3);    //Height
  int robotid = luaL_checkint(L, 4);    //robot ID

//I had to divide the image into sections and send one by one

  int division = luaL_checkint(L, 5);    //How many division?
  int section = luaL_checkint(L, 6);	//Which section?    

  yuyv=yuyv+ m*(n/division)*section;   //Skip unused section

  dataStrY.push_back(18);	//Partitioned yuyv data Y
  dataStrY.push_back(robotid);	//robot ID
  dataStrY.push_back(division);	//division
  dataStrY.push_back(section);	//section

  dataStrU.push_back(19);	//Partitioned yuyv data U
  dataStrU.push_back(robotid);	//robot ID
  dataStrU.push_back(division);	//division
  dataStrU.push_back(section);	//section

  dataStrV.push_back(20);	//Partitioned yuyv data V
  dataStrV.push_back(robotid);	//robot ID
  dataStrV.push_back(division);	//division
  dataStrV.push_back(section);	//section


  for (int j = 0; j < n/division; j++) {
        for (int i = 0; i < m; i++) {
		char indexY= (*yuyv & 0xFC000000) >> 26;
		char indexU= (*yuyv & 0x0000FC00) >> 10;
		char indexV= (*yuyv & 0xFC0000FC) >> 2;
		dataStrY.push_back(indexY);
		dataStrU.push_back(indexU);
	        dataStrV.push_back(indexV);
	        yuyv++;
        }
  }
  int ret1 = send(send_fd, dataStrY.c_str(), dataStrY.size(), 0);
  int ret2 = send(send_fd, dataStrU.c_str(), dataStrU.size(), 0);
  int ret3 = send(send_fd, dataStrV.c_str(), dataStrV.size(), 0);
  lua_pushinteger(L,ret1+ret2+ret3);
  return 1;
}


static int lua_darwinopcomm_send_particle(lua_State *L) {
  int updateRet = lua_darwinopcomm_update(L);
  std::string dataStr;
  int n_sample = luaL_checkint(L, 1);
  int robotid = luaL_checkint(L, 2);    //robot ID
  const char *data = luaL_checkstring(L, 3);

  dataStr.push_back(21);	//Particle data
  dataStr.push_back(robotid);	//robot ID
  dataStr.push_back(n_sample);	//robot ID

  for (int i=0;i<n_sample;i++){
	dataStr.push_back(*data++);
	dataStr.push_back(*data++);
	dataStr.push_back(*data++);
  }

  int ret = send(send_fd, dataStr.c_str(), dataStr.size(), 0);
  lua_pushinteger(L, ret);
  return 1;
}


static const struct luaL_reg NSLCommWired_lib [] = {
  {"size", lua_darwinopcomm_size},
  {"receive", lua_darwinopcomm_receive},
  {"send", lua_darwinopcomm_send},
  {"send_label", lua_darwinopcomm_send_label},
  {"send_yuyv", lua_darwinopcomm_send_yuyv},
  {"send_yuyv2", lua_darwinopcomm_send_yuyv2},
  {"send_particle", lua_darwinopcomm_send_particle},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_NSLCommWired (lua_State *L) {
  luaL_register(L, "NSLCommWired", NSLCommWired_lib);

  return 1;
}

