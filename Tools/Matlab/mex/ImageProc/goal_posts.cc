/*
  x = goal_posts(im, mask, threshold);

  Matlab 7.4 MEX file to compute posts projected onto I axis.

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 6/09
*/

#include <vector>
#include "mex.h"

#include "RegionProps.h"

const int NMAX = 256;
int threshold = 5;

typedef unsigned char uint8;
typedef unsigned int uint;

static int countJ[NMAX];
static int minJ[NMAX];
static int maxJ[NMAX];
static int sumJ[NMAX];

static std::vector <struct RegionProps> postVec;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  uint8 mask = 0x01;

  // Check arguments
  if ((nrhs < 1)  || !((mxGetClassID(prhs[0]) == mxUINT8_CLASS)))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *)mxGetData(prhs[0]);
  int m = mxGetM(prhs[0]);
  int n = mxGetN(prhs[0]);
  if ((m > NMAX) || (n > NMAX))
    mexErrMsgTxt("Too large input");

  if (nrhs >= 2)
    mask = mxGetScalar(prhs[1]);

  if (nrhs >= 3)
    threshold = mxGetScalar(prhs[2]);

  // Initialize arrays
  for (int i = 0; i < m; i++) {
    countJ[i] = 0;
    minJ[i] = n-1;
    maxJ[i] = 0;
    sumJ[i] = 0;
  }

  // Iterate through image getting projection statistics
  for (int i = 0; i < m; i++) {
    uint8 *im_row = im_ptr + i;
    for (int j = 0; j < n; j++) {
      uint8 pixel = *im_row;
      im_row += m;
      if (pixel & mask) {
	countJ[i]++;
	if (j < minJ[i]) minJ[i] = j;
	if (j > maxJ[i]) maxJ[i] = j;
	sumJ[i] += j;
      }
    }
  }

  RegionProps post;
  postVec.clear();
  // Find connected posts
  bool connect = false;
  for (int i = 0; i < m; i++) {
    if (countJ[i] > threshold) {
      if (!connect) {
	post.area = countJ[i];
	post.sumI = countJ[i]*i;
	post.sumJ = sumJ[i];
	post.minI = i;
	post.maxI = i;
	post.minJ = minJ[i];
	post.maxJ = maxJ[i];
	connect = true;
      }
      else {
	post.area += countJ[i];
	post.sumI += countJ[i]*i;
	post.sumJ += sumJ[i];
	post.maxI = i;
	if (minJ[i] < post.minJ) post.minJ = minJ[i];
	if (maxJ[i] > post.maxJ) post.maxJ = maxJ[i];
      }
      connect = true;
    }
    else {
      if (connect) {
	postVec.push_back(post);
      }
      connect = false;
    }
  }
  if (connect) {
    postVec.push_back(post);
  }

  int npost = postVec.size();
  const char *fields[] = {"area", "centroid", "boundingBox"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  plhs[0] = mxCreateStructMatrix(1, npost, nfields, fields);
  for (int i = 0; i < npost; i++) {
    mxSetField(plhs[0], i, "area", mxCreateDoubleScalar(postVec[i].area));

    double centroidI = postVec[i].sumI/postVec[i].area;
    double centroidJ = postVec[i].sumJ/postVec[i].area;
    mxArray *centroid = mxCreateDoubleMatrix(1, 2, mxREAL);
    // This is different from Matlab regionprops!
    mxGetPr(centroid)[0] = centroidI;
    mxGetPr(centroid)[1] = centroidJ;
    mxSetField(plhs[0], i, "centroid", centroid);

    mxArray *bbox = mxCreateDoubleMatrix(2, 2, mxREAL);
    // This definition is also quite different from Matlab regionprops!
    mxGetPr(bbox)[0] = postVec[i].minI;
    mxGetPr(bbox)[1] = postVec[i].maxI;
    mxGetPr(bbox)[2] = postVec[i].minJ;
    mxGetPr(bbox)[3] = postVec[i].maxJ;
    mxSetField(plhs[0], i, "boundingBox", bbox);
  }
}
