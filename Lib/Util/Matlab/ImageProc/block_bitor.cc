/*
  y = block_bitor(x);

  Matlab 7.4 MEX file to compute bitor blocks.

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 3/09
*/

#include "mex.h"

typedef unsigned char uint8;

mxArray *blockArray = NULL;

void mexExit(void)
{
  if (blockArray) {
    mxDestroyArray(blockArray);
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  int msub = 2;
  int nsub = 2;

  if ((nrhs < 1) || (!mxIsUint8(prhs[0]))) {
    mexErrMsgTxt("Need input label image");
  }
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  if (nrhs >= 2) {
    double *xsub = mxGetPr(prhs[1]);
    msub = xsub[0];
    nsub = xsub[1];
  }
  

  int my = 1+(mx-1)/msub;
  int ny = 1+(nx-1)/nsub;
  if ((blockArray == NULL) ||
      (my != mxGetM(blockArray)) || (ny != mxGetN(blockArray))) {
    if (blockArray) {
      mxDestroyArray(blockArray);
    }
    mwSize dims[2];
    dims[0] = my;
    dims[1] = ny;
    blockArray = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    mexMakeArrayPersistent(blockArray);
    mexAtExit(mexExit);
  }
  
  uint8 *y = (uint8 *) mxGetData(blockArray);
  for (int iy = 0; iy < my*ny; iy++) {
    y[iy] = 0;
  }
  uint8 *x = (uint8 *) mxGetData(prhs[0]);
  for (int jx = 0; jx < nx; jx++) {
    int jy = jx/nsub;
    uint8 *y1 = y + jy*my;
    for (int ix = 0; ix < mx; ix++) {
      int iy = ix/msub;
      y1[iy] |= *x++;
    }
  }

  plhs[0] = blockArray;
}
