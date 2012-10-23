/*
 * Mex file to test the find_first_max function
 * 
 * To compile:
 * mex -O mycrosscorr.cc
 *  
 * Jordan Brindza; <brindza@seas.upenn.edu>
 */

#include <stdio.h>

#include "mex.h"
#include "dtmf.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  // Check arguments
  if (nrhs < 1) {
    mexErrMsgTxt("Need to input array.");
  }

  int *x;
  int freeArray = 0;
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);
  int len = (n > m) ? n : m;
  
  if (mxGetClassID(prhs[0]) == mxDOUBLE_CLASS) {
    double *in = mxGetPr(prhs[0]);

    freeArray = 1;
    x = (int *)malloc(sizeof(int) * (len));
    for (int i = 0; i < len; i++) {
      x[i] = (int)in[i];
    }
  } else if (mxGetClassID(prhs[0]) == mxINT32_CLASS) {
    x = (int *)mxGetData(prhs[0]);
  } else {
    mexErrMsgTxt("Input array must be int32 or double type.");
  }
  
  double threshold = 0;
  if (nlhs >= 2) {
    threshold = mxGetScalar(prhs[1]);
  } else {
    double stdThreshold = 3;
    double stdDev = standard_deviation(x, len);
    threshold = stdThreshold * stdDev;
  }
  int offset = 0;
  if (nrhs >= 3) {
    offset = (int)mxGetScalar(prhs[2]);
  } else {
    offset = PFRAME;
  }


  int fm = find_first_max(x, len, threshold, offset);

  plhs[0] = mxCreateDoubleScalar(fm);

  if (freeArray) {
    free(x);
  }
}

