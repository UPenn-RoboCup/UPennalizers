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

//#define IP "192.168.255.255"
#define IP "255.255.255.255"
#define PORT 54321
#define MDELAY 2
#define TTL 16
#define MAX_LENGTH 16000
//#define MAX_LENGTH 160000 //Needed for 640*480 yuyv

const int maxQueueSize = 16;
static std::deque<std::string> recvQueue;
static int send_fd;

void mexExit(void)
{
	if (send_fd > 0)
		close(send_fd);
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

		i = 1;
		if (setsockopt(send_fd, SOL_SOCKET, SO_REUSEADDR,
		(const char *) &i, sizeof(i)) < 0)
			mexErrMsgTxt("Could not set reuse option");
    
		struct sockaddr_in dest_addr;
		bzero((char *) &dest_addr, sizeof(dest_addr));
		dest_addr.sin_family = AF_INET;
		bcopy(hostptr->h_addr, (char *) &dest_addr.sin_addr, hostptr->h_length);
		dest_addr.sin_port = htons(PORT);
		if (connect(send_fd, (struct sockaddr *) &dest_addr,
		sizeof(dest_addr)) < 0)
			mexErrMsgTxt("Could not connect to destination address");

		printf("Setting up udp_send on: %s:%d\n", IP,PORT);

		mexAtExit(mexExit);
		init = true;
	}

	if ((nrhs < 1) || (!mxIsChar(prhs[0])))
		mexErrMsgTxt("Incorrect input argument");
	std::string str(mxArrayToString(prhs[0]));

	if (str == "getQueueSize") {
		plhs[0] = mxCreateDoubleScalar(recvQueue.size());
	}
	else if (str == "send") {
		if (nrhs < 2)
			mexErrMsgTxt("No input argument");
		int n = mxGetNumberOfElements(prhs[1])*mxGetElementSize(prhs[1]);
		int ret = send(send_fd, mxGetData(prhs[1]), n, 0);
		plhs[0] = mxCreateDoubleScalar(ret);
	}
}
