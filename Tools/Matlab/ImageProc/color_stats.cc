/*
  x = color_stats(im, color, bbox);

  Matlab 7.4 MEX file to compute color pixel statistics
  within bounding box of image.

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 4/09
*/

#include <math.h>
#include "mex.h"

typedef unsigned char uint8;
typedef unsigned int uint;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Check arguments
  if ((nrhs < 1)  || !((mxGetClassID(prhs[0]) == mxUINT8_CLASS)))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *)mxGetData(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);

  uint8 color = 1;
  if (nrhs >= 2){
    color = mxGetScalar(prhs[1]);
  }

  int i0 = 0;
  int i1 = m-1;
  int j0 = 0;
  int j1 = n-1;
  if (nrhs >= 3) {
    double *bbox = mxGetPr(prhs[2]);
    i0 = bbox[0];
    if (i0 < 0) i0 = 0;
    i1 = bbox[1];
    if (i1 > m-1) i1 = m-1;
    j0 = bbox[2];
    if (j0 < 0) j0 = 0;
    j1 = bbox[3];
    if (j1 > n-1) j1 = n-1;
  }

  // Imtialize statistics
  int area = 0;
  int minI = m-1, maxI = 0;
  int minJ = n-1, maxJ = 0;
  int sumI = 0, sumJ = 0;
  int sumII = 0, sumJJ = 0, sumIJ = 0;

  for (int j = j0; j <= j1; j++) {
    uint8 *im_col = im_ptr + m*j;
    for (int i = i0; i <= i1; i++) {
      if (im_col[i] == color) {
	area++;
	if (i < minI) minI = i;
	if (i > maxI) maxI = i;
	if (j < minJ) minJ = j;
	if (j > maxJ) maxJ = j;
	sumI += i;
	sumJ += j;
	sumII += i*i;
	sumJJ += j*j;
	sumIJ += i*j;
      }
    }
  }
  
  const char *fields[] = {"area", "centroid", "boundingBox",
			  "axisMajor", "axisMinor", "orientation"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(1, 1, nfields, fields);
  mxSetField(plhs[0], 0, "area", mxCreateDoubleScalar(area));

  if (area == 0) return;

  double centroidI = (double) sumI/area;
  double centroidJ = (double) sumJ/area;
  mxArray *centroid = mxCreateDoubleMatrix(1, 2, mxREAL); 
  // This defimtion is different from Matlab regionprops!
  mxGetPr(centroid)[0] = centroidI;
  mxGetPr(centroid)[1] = centroidJ;
  mxSetField(plhs[0], 0, "centroid", centroid);
  
  mxArray *bbox = mxCreateDoubleMatrix(2, 2, mxREAL);
  // This defimtion is also quite different from Matlab regionprops!
  mxGetPr(bbox)[0] = minI;
  mxGetPr(bbox)[1] = maxI;
  mxGetPr(bbox)[2] = minJ;
  mxGetPr(bbox)[3] = maxJ;
  mxSetField(plhs[0], 0, "boundingBox", bbox);

  double covII = sumII/area -centroidI*centroidI;
  double covJJ = sumJJ/area -centroidJ*centroidJ;
  double covIJ = sumIJ/area -centroidI*centroidJ;
  double covTrace = covII + covJJ;
  double covDet = covII*covJJ - covIJ*covIJ;
  double covFactor = sqrt(fmax(covTrace*covTrace-4*covDet, 0));
  double covAdd = .5*(covTrace + covFactor);
  double covSubtract = .5*fmax((covTrace - covFactor), 0);
  double axisMajor = sqrt(12*covAdd) + 0.5;
  double axisMinor = sqrt(12*covSubtract) + 0.5;
  double orientation = atan2(covJJ-covIJ-covSubtract, covII-covIJ-covSubtract);
  mxSetField(plhs[0], 0, "axisMajor", mxCreateDoubleScalar(axisMajor));
  mxSetField(plhs[0], 0, "axisMinor", mxCreateDoubleScalar(axisMinor));
  mxSetField(plhs[0], 0, "orientation", mxCreateDoubleScalar(orientation));
}
