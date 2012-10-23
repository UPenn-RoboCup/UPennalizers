/*
  x = yuyv2label(yuyv, lut);

  Matlab 7.4 MEX file to compute color index.

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 3/09
*/

#include "mex.h"

typedef unsigned char uint8;
typedef unsigned int uint32;

mxArray *labelArray = NULL;

void mexExit(void)
{
  if (labelArray) {
    mxDestroyArray(labelArray);
  }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if ((nrhs < 1) || (!mxIsUint32(prhs[0]))) {
    mexErrMsgTxt("Unknown input YUYV image");
  }
  if ((nrhs < 2) || (!mxIsUint8(prhs[1]))) {
    mexErrMsgTxt("Unknown color detection table format");
  }

  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);
  
  if ((labelArray == NULL) ||
      (m != mxGetM(labelArray)) || (n != 2*mxGetN(labelArray))) {
    if (labelArray) {
      mxDestroyArray(labelArray);
    }
    mwSize dims[2];
    dims[0] = m;
    dims[1] = n/2;
    labelArray = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    mexMakeArrayPersistent(labelArray);
    mexAtExit(mexExit);
  }

  uint32 *y = (uint32 *) mxGetData(prhs[0]);
  uint8 *cdt = (uint8 *) mxGetData(prhs[1]);
  uint8 *label = (uint8 *) mxGetData(labelArray);

  // m x n/2 label array
  for (int i = 0; i < n/2; i++) {
    for (int j = 0; j < m; j++) {

      // Construct Y6U6V6 index
      uint32 index = ((*y & 0xFC000000) >> 26) | // V
	((*y & 0x0000FC00) >> 4) | // U
	((*y & 0x000000FC) << 10); // Y

      *label++ = cdt[index];
      y++;
    }
    // Skip next line:
    y += m; // uint32
  }

  plhs[0] = labelArray;
}
