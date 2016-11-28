/*
  x = field_occupancy(im);

  Matlab 7.4 MEX file to compute field occupancy.

  Compile with:
  mex -O field_occupancy.cc

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 6/09
  Modified: Yida Zhang <yida@seas.upenn.edu>, 12/11

*/

#include "mex.h"
#include "math.h"
#include "stdlib.h"
#include "stdio.h"

typedef unsigned char uint8;

uint8 colorBall = 0x01;
uint8 colorField = 0x08;
uint8 colorWhite = 0x10;

inline bool isFree(uint8 label) 
{
  return (label & colorField) || (label & colorBall) || (label & colorWhite);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Check arguments
  if ((nrhs < 1)  || !((mxGetClassID(prhs[0]) == mxUINT8_CLASS)))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *) mxGetData(prhs[0]);
  int ni = mxGetM(prhs[0]);
  int nj = mxGetN(prhs[0]);
  const int nRegions = ni;

  int countup[nRegions];
  int countdown[nRegions];
  int count[nRegions];
  int flag[nRegions] ;

  for (int i = 0; i < nRegions; i++) {
    count[i] = 0;
    flag[i] = 0;
    countup[i] = 0;
    countdown[i] = 0;
  }

  // Scan vertical lines: Uphalf
  for (int i = 0; i < ni; i++) {
    int iRegion = nRegions*i/ni;
    uint8 *im_row = im_ptr + i;
    for (int j = 0; j < nj/2; j++) {
      uint8 label = *im_row;
      if (isFree(label)) {
        countup[iRegion]++;
      }
      im_row += ni;
    }
  }
  uint8 *im_ptrdown = im_ptr + (int)(ni * round(nj/2));
  // Scan vertical lines: downhalf
  for (int i = 0; i < ni; i++) {
    int iRegion = nRegions*i/ni;
    uint8 *im_row = im_ptrdown + i;
    for (int j = nj/2; j < nj; j++) {
      uint8 label = *im_row;
      if (isFree(label)) {
        countdown[iRegion]++;
      }
      im_row += ni;
    }
  }
  
  // Evaluate bound
  for (int i = 0; i < nRegions; i++){
    count[i] = countup[i] + countdown[i];
    // whole free, flag <- 2;
    if (countup[i] == nj/2){
      count[i] = nj;
      flag[i] = 2;
      continue;
    }
    // whole block, flag <- 3
    if (count[i] == 0){
      flag[i] = 3;
      continue;
    }
    int pxIdx = (nj - count[i] + 1) * ni + i;
    uint8 label = *(im_ptr + pxIdx);
    if (isFree(label)) 
      flag[i] = 1;
    else {
      //printf("Seeking\n");
      int j = nj - count[i] + 1;
      for (; j < nj; j++){
        int searchIdx = j * ni + i;
        uint8 searchLabel = *(im_ptr + searchIdx);
        if (isFree(searchLabel)) 
            break;
      }
      count[i] = nj - j + 1;
      flag[i] = 1;
    }
  }

  plhs[0] = mxCreateDoubleMatrix(1, nRegions, mxREAL);
  plhs[1] = mxCreateDoubleMatrix(1, nRegions, mxREAL);
  for (int i = 0; i < nRegions; i++){
    mxGetPr(plhs[0])[i] = count[i];
    mxGetPr(plhs[1])[i] = flag[i];
  }
}
