/*
	 fid = tcpopen(address,port);

	 Matlab 5.3 Linux MEX file
	 to open TCP connection and return Matlab file identifier.

	 Daniel D. Lee, 12/01.
	 <ddlee@ddlee.com>
	 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <ctype.h>
#include "mex.h"

/*
	 fidFdopen takes a Unix file descriptor fd and
	 returns a Matlab-usable file identifier with
	 permissions given by mode.
	 */

int fiFdopen(int fd, char *mode, char *format)
{
	int fopenfd, matlab_fid;
	int fopen_nlhs, fopen_nrhs;
	mxArray *fopen_lhs[1], *fopen_rhs[3];
	struct stat stat_tmpfile, statbuf;
	char *tmpfilename;

	/* First open a temporary file and get file status info */

	if ((tmpfilename = tmpnam(NULL)) == NULL)
		mexErrMsgTxt("Could not generate tmpfile name.");

	if ((fopenfd = open(tmpfilename, O_CREAT|O_RDWR, 0777)) < 0)
		mexErrMsgTxt("Could not create tmpfile");
	if (fstat(fopenfd, &stat_tmpfile) < 0)
		mexErrMsgTxt("Could not stat tmpfile");

	/* Now close the temporary file */

	close(fopenfd);

	/* Now call the Matlab function "fopen" to open the same temporary file */

	fopen_nlhs = 1;
	fopen_nrhs = 3;
	fopen_rhs[0] = mxCreateString(tmpfilename);
	fopen_rhs[1] = mxCreateString(mode);
	fopen_rhs[2] = mxCreateString(format);
	mexCallMATLAB(fopen_nlhs, fopen_lhs, fopen_nrhs, fopen_rhs, "fopen");

	if ((matlab_fid = mxGetScalar(fopen_lhs[0])) < 0)
		mexErrMsgTxt("Could not open tmpfile");

	/* Now delete temporary file and remap Matlab fopen to new file descriptor */

	if (unlink(tmpfilename) < 0)
		mexErrMsgTxt("Could not unlink tmpfile");

	if (fstat(fopenfd, &statbuf) < 0)
		mexErrMsgTxt("Could not stat file descriptor");
	if ((statbuf.st_dev != stat_tmpfile.st_dev) ||
			(statbuf.st_ino != stat_tmpfile.st_ino))
		mexErrMsgTxt("Could not find matching file descriptor");

	if (dup2(fd, fopenfd) < 0)
		mexErrMsgTxt("Could not duplicate file descriptor.");

	close(fd);

	return matlab_fid;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
	int sock_fd;
	int i, len, source_addr_len, dims[2];
	int buflen, port = 80, nonblock = 0;
	struct sockaddr_in local_addr, serv_addr;
	struct hostent *hostptr;
	char *buf;

	if (nrhs < 1)
		mexErrMsgTxt("Need to input server address.");

	if (mxIsChar(prhs[0]))
		buf = mxArrayToString(prhs[0]);

	if ((hostptr = gethostbyname(buf)) == NULL)
		mexErrMsgTxt("Could not get hostname.");

	if (nrhs >= 2)
		port = mxGetScalar(prhs[1]);

	if (nrhs >= 3)
		if (mxIsChar(prhs[2])) {
			nonblock = (toupper(mxArrayToString(prhs[2])[0]) == 'A');
		}

	/* Get host info */
	bzero((char *) &serv_addr, sizeof(serv_addr));
	serv_addr.sin_family = AF_INET;
	bcopy(hostptr->h_addr, (char *) &serv_addr.sin_addr, hostptr->h_length);
	serv_addr.sin_port = htons(port);

	if ((sock_fd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
		mexErrMsgTxt("Could not open socket.");

	/* Set read buffer for performance in MacOS X */
	i = 65535;
	if (setsockopt(sock_fd, SOL_SOCKET, SO_RCVBUF, &i, sizeof(int)) < 0)
		mexErrMsgTxt("Could not set socket option.");

	if (connect(sock_fd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
		mexErrMsgTxt("Could not connect to server.");

	/* Set nonblocking I/O */
	if (nonblock) {
		if (fcntl(sock_fd, F_SETFL, O_NONBLOCK) == -1) {
			close(sock_fd);
			mexErrMsgTxt("Could not set nonblocking I/O.");
		}
	}

	/* Create output arguments */
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	/* mxGetPr(plhs[0])[0] = fiFdopen(sock_fd, "w+", "native"); */
	mxGetPr(plhs[0])[0] = fiFdopen(sock_fd, "a+", "ieee-le");

}

