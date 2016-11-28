/*
  c = color_count(x);

  Matlab 7.4 MEX file to count color pixels.

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 3/09
*/

#include "mex.h"

typedef unsigned char uint8;
const int nColor = 256;

mxArray *countArray = NULL;
static int count[nColor];

void mexExit(void)
{
  if (countArray) {
    mxDestroyArray(countArray);
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if ((nrhs < 1) || (!mxIsUint8(prhs[0]))) {
    mexErrMsgTxt("Need input image argument");
  }
  uint8 *x = (uint8 *) mxGetData(prhs[0]);
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  if (countArray == NULL) {
    countArray = mxCreateDoubleMatrix(1, nColor-1, mxREAL);
    mexMakeArrayPersistent(countArray);
    mexAtExit(mexExit);
  }
  
  for (int i = 0; i < nColor; i++) {
    count[i] = 0;
  }

  for (int i = 0; i < mx*nx; i++) {
    count[x[i]]++;
  }

  double *c = mxGetPr(countArray);
  for (int i = 0; i < nColor-1; i++) {
    c[i] = count[i+1];
  }

  plhs[0] = countArray;
}
