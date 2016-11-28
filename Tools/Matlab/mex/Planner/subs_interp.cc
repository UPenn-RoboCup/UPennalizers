/*
  b = subsinterp(a,x,y);

  MEX file to interpolate subscript index values a(x,y)
  using bilinear interpolation

  Daniel D. Lee, 06/2007
  <ddlee@seas.upenn.edu>
*/

#include <math.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 3) {
    mexErrMsgTxt("Need three input arguments.");
  }

  double *a = mxGetPr(prhs[0]);
  int nx = mxGetM(prhs[0]);
  int ny = mxGetN(prhs[0]);

  double *x = mxGetPr(prhs[1]);
  double *y = mxGetPr(prhs[2]);

  int mb = mxGetM(prhs[1]);
  int nb = mxGetN(prhs[1]);
  if ((mxGetM(prhs[2]) != mb) || (mxGetN(prhs[2]) != nb)) {
    mexErrMsgTxt("Index array sizes need to match");
  }

  plhs[0] = mxCreateDoubleMatrix(mb, nb, mxREAL);
  double *b = mxGetPr(plhs[0]);

  for (int i = 0; i < mb*nb; i++) {
    int ix = floor(x[i])-1;
    int iy = floor(y[i])-1;

    if ((ix >= 0) && (ix < nx-1) && (iy >= 0) && (iy < ny-1)) {
      // Bilinear interpolation
      double dx = x[i]-1-ix;
      double dy = y[i]-1-iy;

      int index = nx*iy+ix;
      double a0 = a[index];
      double dax = a[index+1]-a0;
      double day = a[index+nx]-a0;
      double daxy = a[index+nx+1]-a0;

      b[i] = a0 + dx*dax + dy*day + dx*dy*(daxy-dax-day);
    }
    else {
      // Clip to valid region
      if (ix < 0) ix = 0;
      else if (ix > nx-1) ix = nx-1;
      if (iy < 0) iy = 0;
      else if (iy > ny-1) iy = ny-1;

      int index = nx*iy+ix;
      b[i] = a[index];
    }
  }

}
