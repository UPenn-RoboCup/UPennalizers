/*
   c = getch;

   Matlab MEX file tot ry to read
   character from keyboard asynchronously.

   Daniel D. Lee, 1/07.
   <ddlee@seas.upenn.edu>
*/

#include <unistd.h>
#include <fcntl.h>

#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int n, dims[2];
  char str[2];

  if (fcntl(0, F_SETFL, O_NONBLOCK) == -1)
    mexErrMsgTxt("Could not set nonblocking input.");

  str[0] = 0;
  str[1] = 0;

  n = read(0, &str, 1);

  /* Create output arguments */
  plhs[0] = mxCreateString(str);

}

