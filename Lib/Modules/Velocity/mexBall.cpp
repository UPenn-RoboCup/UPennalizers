/*
   ret = dcmSensor(args);

   mex -O dcmSensor.cpp -I/usr/local/boost -lrt

   Matlab MEX file to access shared memory using Boost interprocess
Author: Stephen McGill w/ Daniel Lee
*/

#include "mex.h"
#include "BallModel.h"

const double MIN_ERROR_DISTANCE = 50;
const double ERROR_DEPTH_FACTOR = 0.08;
const double ERROR_ANGLE = 3*PI/180;

void mexExit(void)
{
  // reset the ball somehow...
  fprintf(stdout, "Exiting ballmodel.\n");
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

  static bool init = false;
  static BallModel bm;

  if (!init) {
    mexAtExit(mexExit);
    init = true;
  }

  // Check input values
  if ((nrhs < 2) || (!mxIsDouble(prhs[0])) || (!mxIsDouble(prhs[1])) )
    mexErrMsgTxt("Need to input [x,y] coordinates as argument, with uncertainty as other arg.");
  double *val = mxGetPr(prhs[0]);
  // Get the uncertainty from the user
  double *uncertainty = mxGetPr(prhs[1]);
  //int nElements = mxGetNumberOfElements(prhs[1]);

  // Add a gaussian observation
  double xObject = val[0];
  double yObject = val[1];

  double distance = sqrt(xObject*xObject+yObject*yObject);
  double angle = atan2(-xObject, yObject);

  double errorDepth = ERROR_DEPTH_FACTOR*(distance+MIN_ERROR_DISTANCE);
  double errorAzimuthal = ERROR_ANGLE*(distance+MIN_ERROR_DISTANCE);

  Gaussian2d objGaussian;
  objGaussian.setMean(xObject, yObject);
  objGaussian.setCovarianceAxis(errorAzimuthal, errorDepth, angle);

  bm.BallObservation(objGaussian, (int)(*uncertainty));
  
  // Send the output
  plhs[0] = mxCreateDoubleMatrix(1, 6, mxREAL);
  double* vals = mxGetPr(plhs[0]);
  bm.getBall( vals[0], vals[1], vals[2], vals[3], vals[4], vals[5] );

}

