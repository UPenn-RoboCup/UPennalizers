/*
  x = Comm;

  MEX file to send and receive UDP messages.
  Daniel D. Lee, 6/09 <ddlee@seas.upenn.edu>
*/

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
#include "mex.h"

//#define IP "255.255.255.255"
//#define IP "10.66.68.255"
//#define IP "172.17.118.255"

//#define IP "192.168.123.255" //OP, wired
//#define IP "158.130.103.255" //AirPennNet-Guest
//#define IP "192.168.1.255" //OP, linksys router
// turkey robocup
//#define IP "192.168.255.255" 


#define IP "192.168.255.255"
//#define IP "192.168.1.255"
//#define IP "139.140.218.255"
#define PORT 12500
#define MDELAY 2
#define TTL 16
//#define MAX_LENGTH 16000
#define MAX_LENGTH 160000 //Needed for 640*480 yuyv

const int maxQueueSize = 16;

static std::deque<std::string> recvQueue;
static int send_fd, recv_fd;


void mexExit(void)
{
  if (send_fd > 0)
    close(send_fd);
  if (recv_fd > 0)
    close(recv_fd);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static sockaddr_in source_addr;
  static char data[MAX_LENGTH];

  static bool init = false;
  if (!init) {
    struct hostent *hostptr = gethostbyname(IP);
    if (hostptr == NULL)
      mexErrMsgTxt("Could not get hostname");

    send_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (send_fd < 0)
      mexErrMsgTxt("Could not open datagram send socket");

    int i = 1;
    if (setsockopt(send_fd, SOL_SOCKET, SO_BROADCAST,
		   (const char *) &i, sizeof(i)) < 0)
      mexErrMsgTxt("Could not set broadcast option");

    /*
    i = 1;
    if (setsockopt(send_fd, SOL_SOCKET, SO_REUSEADDR,
		   (const char *) &i, sizeof(i)) < 0)
      mexErrMsgTxt("Could not set broadcast option");
    */

    struct sockaddr_in dest_addr;
    bzero((char *) &dest_addr, sizeof(dest_addr));
    dest_addr.sin_family = AF_INET;
    bcopy(hostptr->h_addr, (char *) &dest_addr.sin_addr, hostptr->h_length);
    dest_addr.sin_port = htons(PORT);
    if (connect(send_fd, (struct sockaddr *) &dest_addr,
		sizeof(dest_addr)) < 0)
      mexErrMsgTxt("Could not connect to destination address");

    recv_fd = socket(AF_INET, SOCK_DGRAM, 0);
    if (recv_fd < 0)
      mexErrMsgTxt("Could not open datagram recv socket");

    struct sockaddr_in local_addr;
    bzero((char *) &local_addr, sizeof(local_addr));
    local_addr.sin_family = AF_INET;
    local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    local_addr.sin_port = htons(PORT);
    if (bind(recv_fd, (struct sockaddr *) &local_addr,
		sizeof(local_addr)) < 0)
      mexErrMsgTxt("Could not bind to port");

    // Nonblocking receive:
    int flags  = fcntl(recv_fd, F_GETFL, 0);
    if (flags == -1) flags = 0;
    if (fcntl(recv_fd, F_SETFL, flags | O_NONBLOCK) < 0)
      mexErrMsgTxt("Could not set nonblocking mode");

    printf("Setting up naoComm on: %s\n", IP);

    mexAtExit(mexExit);
    init = true;
  }

  // Process incoming messages:
  socklen_t source_addr_len = sizeof(source_addr);
  int len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
		     (struct sockaddr *) &source_addr, &source_addr_len);
  while (len > 0) {
    std::string msg((const char *) data, len);
    recvQueue.push_back(msg);

    len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
		   (struct sockaddr *) &source_addr, &source_addr_len);
  }

  // Remove older messages:
  while (recvQueue.size() > maxQueueSize) {
    recvQueue.pop_front();
  }

  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Incorrect input argument");
  std::string str(mxArrayToString(prhs[0]));

  if (str == "getQueueSize") {
    plhs[0] = mxCreateDoubleScalar(recvQueue.size());
  }
  else if (str == "receive") {
    if (recvQueue.empty()) {
      plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
      return;
    }

    int n = recvQueue.front().size();
    mwSize dims[2];
    dims[0] = 1;
    dims[1] = n;
    plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    memcpy(mxGetData(plhs[0]), recvQueue.front().c_str(), n);
    recvQueue.pop_front();
  }
  else if (str == "send") {
    if (nrhs < 2)
      mexErrMsgTxt("No input argument");
    int n = mxGetNumberOfElements(prhs[1])*mxGetElementSize(prhs[1]);
    int ret = send(send_fd, mxGetData(prhs[1]), n, 0);
    plhs[0] = mxCreateDoubleScalar(ret);

    // Put it in receive queue as well:
    /*
    std::string msg((const char *) mxGetData(prhs[1]), n);
    recvQueue.push_back(msg);
    */
  }
}
