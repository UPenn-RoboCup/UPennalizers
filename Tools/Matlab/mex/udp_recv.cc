/*
x = Comm;

MEX file to send and receive UDP messages.
Daniel D. Lee, 6/09 <ddlee@seas.upenn.edu>

Add multiple port support
Yida Zhang, 04/13 <yida@seas.upenn.edu>

*/

#include <string>
#include <map>
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

#define MDELAY 2
#define TTL 16
#define MAX_LENGTH 16000
//#define MAX_LENGTH 160000 //Needed for 640*480 yuyv

const int maxQueueSize = 16;
//static std::deque<std::string> recvQueue;
//static int recv_fd;
static mwSize ret_sz[]={1};

std::map<int, std::deque<std::string>*> recv_handles;

void recvExit(void)
{
  for (std::map<int, std::deque<std::string>*>::iterator it = recv_handles.begin();
      it != recv_handles.end(); ++it) {
    printf("closing receiver %d\n", it->first);
    if (it->first > 0) close(it->first);
    delete it->second;
  }
}

void recv_create(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int port = 54321;
  if (nrhs >= 1)
    port = mxGetScalar(prhs[0]);

	int recv_fd = socket(AF_INET, SOCK_DGRAM, 0);
	if (recv_fd < 0)
		mexErrMsgTxt("Could not open datagram recv socket");
  recv_handles[recv_fd] = new std::deque<std::string>;

	struct sockaddr_in local_addr;
	bzero((char *) &local_addr, sizeof(local_addr));
	local_addr.sin_family = AF_INET;
	local_addr.sin_addr.s_addr = htonl(INADDR_ANY);
	local_addr.sin_port = htons(port);
	if (bind(recv_fd, (struct sockaddr *) &local_addr,
	sizeof(local_addr)) < 0)
		mexErrMsgTxt("Could not bind to port");

	// Nonblocking receive:
	int flags  = fcntl(recv_fd, F_GETFL, 0);
	if (flags == -1) flags = 0;
	if (fcntl(recv_fd, F_SETFL, flags | O_NONBLOCK) < 0)
		mexErrMsgTxt("Could not set nonblocking mode");
	
	fprintf(stdout, "Setting up udp_recv on port: %d\n", port);
  fflush(stdout);
	mexAtExit(recvExit);

	ret_sz[0] = 1;
	plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT32_CLASS,mxREAL);
	uint32_t* out = (uint32_t*)mxGetData(plhs[0]);
	out[0] = recv_fd;
  
  return;
}


void recv_size(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  int recv_fd = mxGetScalar(prhs[0]);
  std::map<int, std::deque<std::string>*>::iterator iRecv = recv_handles.find(recv_fd);
  if (iRecv == recv_handles.end())
    mexErrMsgTxt("Unknown receiver");
  std::deque<std::string> *recvQueue = recv_handles[recv_fd];

	sockaddr_in source_addr;
	char data[MAX_LENGTH];

	// Process incoming messages:
	socklen_t source_addr_len = sizeof(source_addr);
	int len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
	(struct sockaddr *) &source_addr, &source_addr_len);
	while (len > 0) {
		std::string msg((const char *) data, len);
		recvQueue->push_back(msg);

		len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
		(struct sockaddr *) &source_addr, &source_addr_len);
	}

	// Remove older messages:
	while (recvQueue->size() > maxQueueSize) {
		recvQueue->pop_front();
	}

  plhs[0] = mxCreateDoubleScalar(recvQueue->size());

}

void recv_get(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  int recv_fd = mxGetScalar(prhs[0]);
  std::map<int, std::deque<std::string>*>::iterator iRecv = recv_handles.find(recv_fd);
  if (iRecv == recv_handles.end())
    mexErrMsgTxt("Unknown receiver");
  std::deque<std::string> *recvQueue = recv_handles[recv_fd];

	sockaddr_in source_addr;
	char data[MAX_LENGTH];

	// Process incoming messages:
	socklen_t source_addr_len = sizeof(source_addr);
	int len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
	(struct sockaddr *) &source_addr, &source_addr_len);
	while (len > 0) {
		std::string msg((const char *) data, len);
		recvQueue->push_back(msg);

		len = recvfrom(recv_fd, data, MAX_LENGTH, 0,
		(struct sockaddr *) &source_addr, &source_addr_len);
	}

	// Remove older messages:
	while (recvQueue->size() > maxQueueSize) {
		recvQueue->pop_front();
	}

	if (recvQueue->empty()) {
		plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
		return;
	}

	int n = recvQueue->front().size();
	mwSize dims[2];
	dims[0] = 1;
	dims[1] = n;
	plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
	memcpy(mxGetData(plhs[0]), recvQueue->front().c_str(), n);
	recvQueue->pop_front();
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static bool init = false;
  static std::map<std::string, void(*)(int nlhs, mxArray *plhs[], 
      int nrhs, const mxArray *prhs[])> funcMap;

  if (!init) {
    recv_handles.clear();
    funcMap["new"] = recv_create;
    funcMap["getQueueSize"] = recv_size;
    funcMap["receive"] = recv_get;

    mexAtExit(recvExit);
    init = true;
  }

  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Need to input string argument");
  std::string fname(mxArrayToString(prhs[0]));

  std::map<std::string, void (*)(int nlhs, mxArray *plhs[],
    int nrhs, const mxArray *prhs[])>::iterator iFuncMap = funcMap.find(fname);

  if (iFuncMap == funcMap.end())
    mexErrMsgTxt("Unknown function argument");

  (iFuncMap->second)(nlhs, plhs, nrhs-1, prhs+1);

}
