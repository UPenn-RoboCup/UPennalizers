/*
  x = time;

  MEX file to get Webots simulation time.

  Daniel D. Lee, 4/09 <ddlee@seas.upenn.edu>
*/

#include "timeScalar.h"
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  plhs[0] = mxCreateDoubleScalar(time_scalar());
}
