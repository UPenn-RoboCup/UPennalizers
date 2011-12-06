/*
  stats = connected_regions(im, mask);

  MEX file to compute statistics of connected regions in uint8 image im.

  To compile:
  mex -O connected_regions.cc ConnectRegions.cc RegionProps.cc

  Daniel D. Lee, 06/2009
  <ddlee@seas.upenn.edu>
*/

#include "ConnectRegions.h"
#include "mex.h"

typedef unsigned char uint8;
const int nlabel_max = 16;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static std::vector<RegionProps> props;

  // Check arguments
  if ((nrhs < 1)  || !mxIsUint8(prhs[0]))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *)mxGetData(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);

  uint8 mask = 0x01;
  if (nrhs >= 2)
    mask = mxGetScalar(prhs[1]);

  int nlabel = ConnectRegions(props, im_ptr, m, n, mask);
  if (nlabel < 0)
    mexErrMsgTxt("Could not run ConnectRegions()");

  const char *fields[] = {"area", "centroid", "boundingBox"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(nlabel, 1, nfields, fields);
  for (int i = 0; i < nlabel; i++) {
    mxSetField(plhs[0], i, "area", mxCreateDoubleScalar(props[i].area));

    double centroidI = (double)props[i].sumI/props[i].area;
    double centroidJ = (double)props[i].sumJ/props[i].area;
    mxArray *centroid = mxCreateDoubleMatrix(1, 2, mxREAL); 
    // Flipping order of 0-indexed coordinates to go with order of dimensions
    // This is different from Matlab regionprops!
    mxGetPr(centroid)[0] = centroidI;
    mxGetPr(centroid)[1] = centroidJ;
    mxSetField(plhs[0], i, "centroid", centroid);

    mxArray *bbox = mxCreateDoubleMatrix(2, 2, mxREAL);
    // This definition is also quite different from Matlab regionprops!
    mxGetPr(bbox)[0] = props[i].minI;
    mxGetPr(bbox)[1] = props[i].maxI;
    mxGetPr(bbox)[2] = props[i].minJ;
    mxGetPr(bbox)[3] = props[i].maxJ;
    mxSetField(plhs[0], i, "boundingBox", bbox);
  }
}
