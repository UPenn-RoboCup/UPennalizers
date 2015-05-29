/*
  y = deserialize(x);

  MEX file to deserialize Matlab array.

  Daniel D. Lee, 02/05
  <ddlee@seas.upenn.edu>
*/

#include "mex.h"

/*
  mxDeserialize is not officially in external reference API.
  However, it is in libmx and is used by the Distributed Computation
  distcompdeserialize Mex function.
*/

extern mxArray *mxDeserialize(const char *buf, int nbuf);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;

  /* Check arguments */
  if (nrhs < 1)
    mexErrMsgTxt("Need at least one input argument.");

  for (i=0; i<nrhs; i++) {
    plhs[i] = mxDeserialize(mxGetData(prhs[i]), mxGetNumberOfElements(prhs[i]));
  }

}
