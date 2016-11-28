/*
  x = time;

  MEX file to get Webots simulation time.

  Daniel D. Lee, 4/09 <ddlee@seas.upenn.edu>
*/

#include <sys/time.h>
#include <stdlib.h>
#include "mex.h"

double time_scalar() {
  static struct timeval t;
  gettimeofday(&t, NULL);
  return t.tv_sec + 1E-6*t.tv_usec;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  plhs[0] = mxCreateDoubleScalar(time_scalar());
}
