/*
 * Mex file to test the fft
 * 
 * To compile:
 * mex -O test_fft.cc
 *  
 * Jordan Brindza; <brindza@seas.upenn.edu>
 */

#include <stdio.h>

#include "mex.h"
#include "fft.h"

//const int NFFT_MULTIPLIER = 2;
//const int NFFT = NFFT_MULTIPLIER * NUM_SAMPLE;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  // Check arguments
  if (nrhs < 1) {
    mexErrMsgTxt("Need to input array.");
  }

  // pointer to input data
  double *in = mxGetPr(prhs[0]);

  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);
  if (n != 1 && m != 1) {
    mexErrMsgTxt("Input array must be 1 dimensional.");
  }

  int nsample = (n > m) ? n : m;
  int nfft_mult = 2;
  int nfft = nfft_mult * nsample;

  // create output array
  int dimr[2];
  int dimi[2];
  if (m > n) {
    dimr[0] = nfft;
    dimr[1] = 1;
    dimi[0] = nfft;
    dimi[1] = 1;
  } else {
    dimr[0] = 1;
    dimr[1] = nfft;
    dimi[0] = nfft;
    dimi[1] = 1;
  }
  plhs[0] = mxCreateNumericArray(2, dimr, mxINT32_CLASS, mxREAL);
  int *xr = (int *)mxGetData(plhs[0]);
  plhs[1] = mxCreateNumericArray(2, dimi, mxINT32_CLASS, mxREAL);
  int *xi = (int *)mxGetData(plhs[1]);

  // init arrays
  for (int i = 0; i < nsample; i++) {
    xr[i] = (int)in[i];
    xi[i] = 0;
  }
  for (int i = nsample; i < nfft; i++) {
    xr[i] = 0;
    xi[i] = 0;
  }
  fft(xr, xi, nfft); 
}
