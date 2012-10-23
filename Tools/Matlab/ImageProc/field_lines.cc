/*
  x = field_lines(im);

  Matlab 7.4 MEX file to compute field lines.

  Compile with:
  mex -O field_lines.cc RadonTransform.cc

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 6/09
*/

#include <vector>
#include "mex.h"

#include "RadonTransform.h"

typedef unsigned char uint8;
typedef unsigned int uint;

static RadonTransform radonTransform;

uint8 colorLine = 0x10;
uint8 colorField = 0x08;
int widthMin = 1;
int widthMax = 10;

/*
  Simple state machine for field line detection:
  ==colorField -> &colorLine -> ==colorField
  Use lineState(0) to initialize, then call with color labels
  Returns width of line when detected, otherwise 0
*/
int lineState(uint8 label)
{
  enum {STATE_NONE, STATE_FIELD, STATE_LINE};
  static int state = STATE_NONE;
  static int width = 0;

  switch (state) {
  case STATE_NONE:
    if (label == colorField)
      state = STATE_FIELD;
    break;
  case STATE_FIELD:
    if (label & colorLine) {
      state = STATE_LINE;
      width = 1;
    }
    else if (label != colorField) {
      state = STATE_NONE;
    }
    break;
  case STATE_LINE:
    if (label == colorField) {
      state = STATE_FIELD;
      return width;
    }
    else if (!(label & colorLine)) {
      state = STATE_NONE;
    }
    else {
      width++;
    }
  }
  return 0;
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  // Check arguments
  if ((nrhs < 1)  || !((mxGetClassID(prhs[0]) == mxUINT8_CLASS)))
    mexErrMsgTxt("Need uint8 input image.");

  uint8 *im_ptr = (uint8 *) mxGetData(prhs[0]);
  int ni = mxGetM(prhs[0]);
  int nj = mxGetN(prhs[0]);

  if (nrhs >= 2)
    widthMax = mxGetScalar(prhs[1]);
  
  /*
  mwSize dims[2];
  dims[0] = ni;
  dims[1] = nj;
  mxArray *bwArray = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
  uint8 *bwArrayPtr = (uint8 *) mxGetData(bwArray);
  */

  radonTransform.clear();
  // Scan for vertical line pixels:
  for (int j = 0; j < nj; j++) {
    uint8 *im_col = im_ptr + ni*j;
    lineState(0); // Initialize
    for (int i = 0; i < ni; i++) {
      uint8 label = *im_col++;
      int width = lineState(label);
      if ((width >= widthMin) && (width <= widthMax)) {
	int iline = i - (width+1)/2;
	radonTransform.addVerticalPixel(iline, j);
	//	bwArrayPtr[iline+ni*j]++;
      }
    }
  }

  // Scan for horizontal field line pixels:
  for (int i = 0; i < ni; i++) {
    uint8 *im_row = im_ptr + i;
    lineState(0); //Initialize
    for (int j = 0; j < nj; j++) {
      uint8 label = *im_row;
      im_row += ni;
      int width = lineState(label);
      if ((width >= widthMin) && (width <= widthMax)) {
	int jline = j - (width+1)/2;
	radonTransform.addHorizontalPixel(i, jline);
	//	bwArrayPtr[i+ni*jline]++;
      }
    }
  }

  LineStats bestLine = radonTransform.getLineStats();
  const char *fields[] = {"count", "centroid", "endpoint"};
  const int nfields = sizeof(fields)/sizeof(*fields);
  mxArray *lineArray = mxCreateStructMatrix(1, 1, nfields, fields);
  mxSetField(lineArray, 0, "count", mxCreateDoubleScalar(bestLine.count));

  mxArray *centroid = mxCreateDoubleMatrix(1, 2, mxREAL); 
  // 0-indexed, dim order: different from Matlab image processing toolbox!
  mxGetPr(centroid)[0] = bestLine.iMean;
  mxGetPr(centroid)[1] = bestLine.jMean;
  mxSetField(lineArray, 0, "centroid", centroid);

  mxArray *endpoint = mxCreateDoubleMatrix(2, 2, mxREAL);
  mxGetPr(endpoint)[0] = bestLine.iMin;
  mxGetPr(endpoint)[1] = bestLine.iMax;
  mxGetPr(endpoint)[2] = bestLine.jMin;
  mxGetPr(endpoint)[3] = bestLine.jMax;
  mxSetField(lineArray, 0, "endpoint", endpoint);

  plhs[0] = lineArray;
}
