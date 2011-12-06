/*
  x = field_occupancy(im);

  Matlab 7.4 MEX file to compute field occupancy.

  Compile with:
  mex -O field_occupancy.cc

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 6/09
*/

#include "mex.h"

typedef unsigned char uint8;

uint8 colorBall = 0x01;
uint8 colorField = 0x08;
const int nRegions = 4;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Check arguments
  if ((nrhs < 1)  || !((mxGetClassID(prhs[0]) == mxUINT8_CLASS)))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *) mxGetData(prhs[0]);
  int ni = mxGetM(prhs[0]);
  int nj = mxGetN(prhs[0]);

  int count[nRegions];
  for (int i = 0; i < nRegions; i++)
    count[i] = 0;

  // Scan vertical lines:
  for (int i = 0; i < ni; i++) {
    int iRegion = nRegions*i/ni;
    uint8 *im_row = im_ptr + i;
    for (int j = 0; j < nj; j++) {
      uint8 label = *im_row;
      if ((label & colorField) || (label & colorBall))
	count[iRegion]++;
      im_row += ni;
    }
  }

  plhs[0] = mxCreateDoubleMatrix(1, nRegions, mxREAL);
  for (int i = 0; i < nRegions; i++) {
    mxGetPr(plhs[0])[i] = count[i];
  }
}
