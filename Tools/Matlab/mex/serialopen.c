/*
	 fid = serialopen(port, baud, async);

	 Matlab Mac OS X MEX file
	 to open serial port and return Matlab file identifier.

	 Daniel D. Lee, 08/08.
	 <ddlee@ddlee.com>
	 */

#include <stdio.h>
#include <getopt.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <IOKit/serial/ioss.h>

#include "mex.h"

#define DEVICE_NAME "/dev/tty.usbserial"
#define SPEED 57600

/*
	 fidFdopen takes a Unix file descriptor fd and
	 returns a Matlab-usable file identifier with
	 permissions given by mode.
	 */

int fiFdopen(int fd, char *mode)
{
	int fopenfd, matlab_fid;
	int fopen_nlhs, fopen_nrhs;
	mxArray *fopen_lhs[1], *fopen_rhs[2];
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
	fopen_nrhs = 2;
	fopen_rhs[0] = mxCreateString(tmpfilename);
	fopen_rhs[1] = mxCreateString(mode);
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
	char *device_name=DEVICE_NAME;
	int tty_fd;
	speed_t speed=SPEED;
	struct termios tio;

	if (nrhs >= 1) {
		if (mxIsChar(prhs[0]))
			device_name = mxArrayToString(prhs[0]);
	}

	if (nrhs >= 2) {
		speed = mxGetScalar(prhs[1]);
	}

	/* Open serial port */
	if ((tty_fd = open(device_name, O_RDWR|O_NOCTTY|O_NONBLOCK)) < 0)
		mexErrMsgTxt("Could not open serial port.");

	if (tcgetattr(tty_fd, &tio) == -1) {
		close(tty_fd);
		mexErrMsgTxt("Error getting tty attributes.");
	}

	//  tio.c_cflag = CS8 | CLOCAL | CREAD | CRTSCTS;
	tio.c_cflag = CS8 | CLOCAL | CREAD;
	tio.c_iflag = IGNPAR;
	tio.c_oflag = 0;
	tio.c_lflag = 0;  /* Set to ICANON for line processing */
	tio.c_cc[VEOF] = 4;  /* ctrl-d */
	tio.c_cc[VMIN] = 1;  /* Min number of characters */
	tio.c_cc[VTIME] = 10; /* TIME*0.1s */

	if (tcsetattr(tty_fd,TCSANOW,&tio) == -1) {
		close(tty_fd);
		mexErrMsgTxt("Could not set tty attributes.");
	}

	if (ioctl(tty_fd, IOSSIOSPEED, &speed) == -1) {
		close(tty_fd);
		mexErrMsgTxt("Could not set speed.");
	}

	/*
		 if (fcntl(tty_fd, F_SETFL, O_NONBLOCK) == -1) {
		 close(tty_fd);
		 mexErrMsgTxt("Could not set nonblocking I/O.");
		 }
		 */

	/* Create output arguments */
	plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL);
	mxGetPr(plhs[0])[0] = fiFdopen(tty_fd, "w+");
}
