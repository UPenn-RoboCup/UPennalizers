#include "mex.h"

#include <vector>

typedef unsigned char uint8;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  static std::vector<uint32_t> mask;

  uint8 *label = (uint8 *) mxGetData(prhs[0]);
  int mx = mxGetM(prhs[0]);
  int nx = mxGetN(prhs[0]);

  for (int cnt = 0; cnt < mx * nx; cnt++)
    mask.push_back(0);
  int idx = 0, counter = 0;
  for (int n = 0; n < nx; n++) 
    for (int m = 0; m < mx; m++) {
      idx = n * mx + m;
      if (label[idx] == 0)
        mask[idx] = 1; 
    } 

  plhs[0] = mxCreateDoubleMatrix(1, mx * nx, mxREAL);
  for (int i = 0; i < mx * nx; i++)
    mxGetPr(plhs[0])[i] = mask[i];
}
