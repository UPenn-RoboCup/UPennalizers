/*
  b = subs_interp3_circular(a,x,y,t);

  MEX file to interpolate subscript index values a(x,y,t)
  using linear interpolation and circular boundary conditions on t

  Daniel D. Lee, 06/2007
  <ddlee@seas.upenn.edu>
*/

#include <math.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check arguments */
  if (nrhs < 4) {
    mexErrMsgTxt("Need three input arguments.");
  }

  if (mxGetNumberOfDimensions(prhs[0]) != 3) {
    mexErrMsgTxt("First argument should be a 3D array");
  }
  
  double *a = mxGetPr(prhs[0]);
  const int *dims = mxGetDimensions(prhs[0]);
  int nx = dims[0];
  int ny = dims[1];
  int nt = dims[2];

  double *x = mxGetPr(prhs[1]);
  double *y = mxGetPr(prhs[2]);
  double *t = mxGetPr(prhs[3]);

  int mb = mxGetM(prhs[1]);
  int nb = mxGetN(prhs[1]);
  if ((mxGetM(prhs[2]) != mb) || (mxGetN(prhs[2]) != nb) ||
      (mxGetM(prhs[3]) != mb) || (mxGetN(prhs[3]) != nb)) {
    mexErrMsgTxt("Index array sizes need to match");
  }

  plhs[0] = mxCreateDoubleMatrix(mb, nb, mxREAL);
  double *b = mxGetPr(plhs[0]);

  for (int i = 0; i < mb*nb; i++) {
    int ix = floor(x[i])-1;
    int iy = floor(y[i])-1;
    int it = (int)(floor(t[i])-1) % nt;

    if ((ix < 0) || (ix >= nx-1) ||
	(iy < 0) || (iy >= ny-1)) {
      // Clip to valid region
      if (ix < 0) ix = 0;
      else if (ix > nx-1) ix = nx-1;
      if (iy < 0) iy = 0;
      else if (iy > ny-1) iy = ny-1;
      
      int index = ix + nx*iy + nx*ny*it;
      b[i] = a[index];
    }
    else {
      // Linear interpolation

      double dx = x[i] - floor(x[i]);
      double dy = y[i] - floor(y[i]);
      double dt = t[i] - floor(t[i]);

      int ind000 = ix + nx*iy + nx*ny*it;
      int ind100 = ind000 + 1;
      int ind010 = ind000 + nx;
      int ind110 = ind010 + 1;
      int ind001 = ind000 + nx*ny;
      if (it == nt-1) {
	ind001 = ix + nx*iy; // Circular boundary condition
      }
      int ind101 = ind001 + 1;
      int ind011 = ind001 + nx;
      int ind111 = ind011 + 1;

      b[i] = (1-dx)*(1-dy)*(1-dt)*a[ind000] +
	dx*(1-dy)*(1-dt)*a[ind100] +
	(1-dx)*dy*(1-dt)*a[ind010] +
	dx*dy*(1-dt)*a[ind110] +
	(1-dx)*(1-dy)*dt*a[ind001] +
	dx*(1-dy)*dt*a[ind101] +
	(1-dx)*dy*dt*a[ind011] +
	dx*dy*dt*a[ind111];
    }
  }

}
