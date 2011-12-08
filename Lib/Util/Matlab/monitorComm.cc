/*
   x = monitorComm;

   MEX file to send and receive UDP messages.
   Daniel D. Lee, 6/09 <ddlee@seas.upenn.edu>
 */


#include "mex.h"
#include "libMonitor.h"
#include <string.h>

void mexExit(void) { close_comm(); }

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  static bool init = false;
  if (!init) {
    printf("Initializing monitorComm...\n");
    int ret = init_comm();
    switch( ret ){
      case 0:
        printf("Success!\n");
        break;
      case -1:
        mexErrMsgTxt("Could not connect to destination address");
        break;
      case -2:
        mexErrMsgTxt("Could not open datagram recv socket");
        break;
      case -3:
        mexErrMsgTxt("Could not bind to port");
        break;
      case -4:
        mexErrMsgTxt("Could not set nonblocking mode");
        break;
      case -5:
        mexErrMsgTxt("Could not get hostname");
        break;
      case -6:
        mexErrMsgTxt("Could not open datagram send socket");
        break;
      case -7:
        mexErrMsgTxt("Could not set broadcast option");
        break;
      default:
        break;
    }
    
    mexAtExit(mexExit);
    init = true;
  }

  // Process incoming messages:
  process_message();
  
  if ((nrhs < 1) || (!mxIsChar(prhs[0])))
    mexErrMsgTxt("Incorrect input argument");

  char* str = mxArrayToString(prhs[0]);
  if( str[0] =='g' ) {//  if (str == "getQueueSize") {
    plhs[0] = mxCreateDoubleScalar( getQueueSize() );
  }
  else if( str[0] =='r' ){//  else if (str == "receive") {

    if ( queueIsEmpty() ) {
      plhs[0] = mxCreateDoubleMatrix(0, 0, mxREAL);
      return;
    }

    int n = get_front_size();
    mwSize dims[2];
    dims[0] = 1;
    dims[1] = n;
    plhs[0] = mxCreateNumericArray(2, dims, mxUINT8_CLASS, mxREAL);
    memcpy(mxGetData(plhs[0]), get_front_data(), n);
    pop_data();
  } 
  else if( str[0] =='s' ){//  else if (str == "send") {

    if (nrhs < 2)
      mexErrMsgTxt("No input argument");
    int n = mxGetNumberOfElements(prhs[1])*mxGetElementSize(prhs[1]);
    int ret = send_message( mxGetData(prhs[1]), n );
    plhs[0] = mxCreateDoubleScalar(ret);
  }
}
