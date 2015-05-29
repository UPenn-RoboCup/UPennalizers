/*
  y = serialize(x);

  MEX file to serialize Matlab array.

  Daniel D. Lee, 02/05
  <ddlee@seas.upenn.edu>
*/

#include "mex.h"

/*
  mxSerialize is not officially in external reference API.
  However, it is in libmx and is used by the Distributed Computation
  distcompserialize Mex function.
*/

extern mxArray *mxSerialize(const mxArray *pa);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int i;

  /* Check arguments */
  if (nrhs < 1)
    mexErrMsgTxt("Need at least one input argument.");

  for (i=0; i<nrhs; i++) {
    plhs[i] = mxSerialize(prhs[i]);
  }

}
