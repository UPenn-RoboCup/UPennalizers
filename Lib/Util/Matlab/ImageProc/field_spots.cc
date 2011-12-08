/*
  x = field_spots(im);

  Matlab 7.4 MEX file to locate field penalty kick spots.

  Compile with:
  mex -O field_spots.cc ConnectRegions.cc

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 6/09
*/

#include <vector>
#include "ConnectRegions.h"
#include "mex.h"

typedef unsigned char uint8;

uint8 colorSpot = 0x10;
uint8 colorField = 0x08;

bool CheckBoundary(RegionProps &prop, uint8 *im_ptr,
		   int m, int n, uint8 color)
{
  int i0 = prop.minI - 1;
  if (i0 < 0) i0 = 0;
  int i1 = prop.maxI + 1;
  if (i1 > m-1) i1 = m-1;
  int j0 = prop.minJ - 1;
  if (j0 < 0) j0 = 0;
  int j1 = prop.maxJ + 1;
  if (j1 > n-1) j1 = n-1;

  // Check top and bottom boundary:
  uint8 *im_top = im_ptr + m*j0 + i0;
  uint8 *im_bottom = im_ptr + m*j1 + i0;
  for (int i = 0; i <= i1-i0; i++) {
    if ((*im_top != color) || (*im_bottom != color))
      return false;
    im_top++;
    im_bottom++;
  }

  // Check side boundaries:
  uint8 *im_left = im_ptr + m*(j0+1) + i0;
  uint8 *im_right = im_ptr + m*(j0+1) + i1;
  for (int j = 0; j < j1-j0-1; j++) {
    if ((*im_left != color) || (*im_right != color))
      return false;
    im_left += m;
    im_right += m;
  }

  return true;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static std::vector<RegionProps> props;

  // Check arguments
  if ((nrhs < 1)  || !mxIsUint8(prhs[0]))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *)mxGetData(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);

  int nlabel = ConnectRegions(props, im_ptr, m, n, colorSpot);
  if (nlabel < 0)
    mexErrMsgTxt("Could not run ConnectRegions()");
  //  printf("nlabel = %d\n", nlabel);

  std::vector<int> valid;
  for (int i = 0; i < nlabel; i++) {
    if (CheckBoundary(props[i], im_ptr, m, n, colorField)) {
      valid.push_back(i);
    }
  }
  int nvalid = valid.size();

  const char *fields[] = {"area", "centroid", "boundingBox"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(nvalid, 1, nfields, fields);
  for (int i = 0; i < nvalid; i++) {
    mxSetField(plhs[0], i, "area", mxCreateDoubleScalar(props[valid[i]].area));

    double centroidI = (double)props[valid[i]].sumI/props[valid[i]].area;
    double centroidJ = (double)props[valid[i]].sumJ/props[valid[i]].area;
    mxArray *centroid = mxCreateDoubleMatrix(1, 2, mxREAL); 
    // Flipping order of 0-indexed coordinates to go with order of dimensions
    // This is different from Matlab regionprops!
    mxGetPr(centroid)[0] = centroidI;
    mxGetPr(centroid)[1] = centroidJ;
    mxSetField(plhs[0], i, "centroid", centroid);

    mxArray *bbox = mxCreateDoubleMatrix(2, 2, mxREAL);
    // This definition is also quite different from Matlab regionprops!
    mxGetPr(bbox)[0] = props[valid[i]].minI;
    mxGetPr(bbox)[1] = props[valid[i]].maxI;
    mxGetPr(bbox)[2] = props[valid[i]].minJ;
    mxGetPr(bbox)[3] = props[valid[i]].maxJ;
    mxSetField(plhs[0], i, "boundingBox", bbox);
  }
}
