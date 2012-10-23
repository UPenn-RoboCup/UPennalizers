/*
  y = rgbselect(x,r,c,threshold);

  MEX file to flood select region of RGB image x;

  To compile:
  mex -O rgbselect.cc

  Daniel D. Lee, 03/2006
  <ddlee@seas.upenn.edu>
*/

#include <deque>
#include <math.h>
#include "mex.h"

using namespace std;
typedef unsigned char uint8;

class Node {
public:
  Node(int x0=0, int y0=0) : x(x0), y(y0) {}
  int x,y;
};

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  const int MAX_COLS = 65536;

  // Check arguments
  if ((nrhs < 1)  || 
      (mxGetClassID(prhs[0]) != mxUINT8_CLASS) ||
      (mxGetNumberOfDimensions(prhs[0]) != 3)) {
    mexErrMsgTxt("Need input RGB image.");
  }

  int ix0 = 0;
  if (nrhs >= 2)
    ix0 = (int)mxGetScalar(prhs[1]) - 1;

  int iy0 = 0;
  if (nrhs >= 3)
    iy0 = (int)mxGetScalar(prhs[2]) - 1;

  double threshold = 16;
  if (nrhs >= 4)
    threshold = mxGetScalar(prhs[3]);


  uint8 *in_ptr = (uint8 *)mxGetData(prhs[0]);
  const int *dims = mxGetDimensions(prhs[0]);
  int ny = dims[0];
  int nx = dims[1];

  // Create output argument
  plhs[0] = mxCreateLogicalArray(2, dims);
  uint8 *out_ptr = (uint8 *)mxGetData(plhs[0]);

  // Construct array pointers
  uint8 *r_in[MAX_COLS], *g_in[MAX_COLS], *b_in[MAX_COLS];
  uint8 *label[MAX_COLS];
  for (int ix = 0; ix < nx; ix++) {
    r_in[ix] = in_ptr + ix*ny;
    g_in[ix] = in_ptr + (nx+ix)*ny;
    b_in[ix] = in_ptr + (2*nx+ix)*ny;
    label[ix] = out_ptr + ix*ny;
  }

  double rmean = r_in[ix0][iy0];
  double gmean = g_in[ix0][iy0];
  double bmean = b_in[ix0][iy0];
  int nmean = 0;

  deque<Node> stack;
  stack.push_back(Node(ix0,iy0));

  while (!stack.empty()) {
    Node node = stack.front();
    stack.pop_front();

    int ix = node.x;
    int iy = node.y;

    // Skip test if pixel was already checked
    if (label[ix][iy] > 0) continue;

    double r_diff = r_in[ix][iy] - rmean;
    double g_diff = g_in[ix][iy] - gmean;
    double b_diff = b_in[ix][iy] - bmean;

    if ((fabs(r_diff) < threshold) &&
	(fabs(g_diff) < threshold) &&
	(fabs(b_diff) < threshold)) {

      label[ix][iy] = 1;
      nmean++;
      rmean += r_diff/nmean;
      gmean += g_diff/nmean;
      bmean += b_diff/nmean;

      // Add unchecked neighboring nodes to stack:
      if ((iy > 0) && (!label[ix][iy-1]))
	stack.push_back(Node(ix, iy-1));
      if ((iy < ny-1) && (!label[ix][iy+1]))
	stack.push_back(Node(ix, iy+1));
      if ((ix > 0) && (!label[ix-1][iy]))
	stack.push_back(Node(ix-1, iy));
      if ((ix < nx-1) && (!label[ix+1][iy]))
	stack.push_back(Node(ix+1, iy));

    }
    else {
      // Label pixel as checked but not selected
      label[ix][iy] = 2;
    }

  }

  // Remove checked labels
  for (int ix = 0; ix < nx; ix++) {
    for (int iy = 0; iy < ny; iy++) {
      if (label[ix][iy] > 1)
	label[ix][iy] = 0;
    }
  }

}
