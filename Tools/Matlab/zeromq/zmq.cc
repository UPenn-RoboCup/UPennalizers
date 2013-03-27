#include <string>
#include <stdio.h>
#include <zmq.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include "mex.h"
#define BUFLEN 8192
#define MAX_SOCKETS 10

char* command;
char zmq_channel[200];//name
void *ctx;
void * sockets[MAX_SOCKETS];
zmq_pollitem_t poll_items [MAX_SOCKETS];
uint8_t socket_cnt = 0;
int result, rc;
static int initialized = 0;
mwSize ret_sz[]={1};
char recv_buffer[BUFLEN];

void cleanup( void ){
  mexPrintf("ZMQMEX: closing sockets and context.\n");
  for(int i=0;i<socket_cnt;i++)
    zmq_close( sockets[i] );
  zmq_term( ctx );
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  if (!initialized) {
    mexPrintf("ZMQMEX: creating a 2 thread ZMQ context.\n");
    ctx = zmq_init(2);
    initialized = 1;
    mexAtExit(cleanup);
  }

  if ( mxIsChar(prhs[0]) != 1)
    mexErrMsgTxt("Could not read command string. (1st argument)");
  command = mxArrayToString(prhs[0]);

  // Setup a publisher
  if( strcmp(command, "publish")==0 ){
    if( socket_cnt==MAX_SOCKETS )
      mexErrMsgTxt("Cannot create any more sockets!");
    if (nrhs != 2)
      mexErrMsgTxt("Please provide a name for the ZMQ channel");
    if ( mxIsChar(prhs[1]) != 1){
      if ( mxGetNumberOfElements( prhs[1] )!=1 )
        mexErrMsgTxt("Please provide a valid handle");
      double* channelid = (double*)mxGetData(prhs[1]);
      unsigned int ch_id = (unsigned int)channelid[0];
      sprintf(zmq_channel, "tcp://*:%u", ch_id );
    } else {
      char* ch_name = mxArrayToString(prhs[1]);
      sprintf(zmq_channel, "ipc:///tmp/%s", ch_name );
    }
    printf("Publishing to %s\n",zmq_channel);
    sockets[socket_cnt] = zmq_socket (ctx, ZMQ_PUB);
    rc = zmq_bind( sockets[socket_cnt], zmq_channel );
    if(rc!=0)
      mexErrMsgTxt("Could not bind!");
    // Auto poll setup
    poll_items[socket_cnt].socket = sockets[socket_cnt];
    //poll_items[socket_cnt].events = ZMQ_POLLOUT; // TODO
    // Set the output to be our internal id
    ret_sz[0] = 1;
    plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
    uint8_t* out = (uint8_t*)mxGetData(plhs[0]);
    out[0] = socket_cnt;
    socket_cnt++;
  }
  // Set up a subscriber
  else if( strcmp(command, "subscribe")==0 ){
    if( socket_cnt==MAX_SOCKETS )
      mexErrMsgTxt("Cannot create any more sockets!");
    if (nrhs != 2)
      mexErrMsgTxt("Please provide a name for the ZMQ channel");
    if ( mxIsChar(prhs[1]) != 1){
      if ( mxGetNumberOfElements( prhs[1] )!=1 )
        mexErrMsgTxt("Please provide a valid handle");
      double* channelid = (double*)mxGetData(prhs[1]);
      unsigned int ch_id = (unsigned int)channelid[0];
      sprintf(zmq_channel, "tcp://localhost:%u", ch_id );
    } else {
      char* ch_name = mxArrayToString(prhs[1]);
      sprintf(zmq_channel, "ipc:///tmp/%s", ch_name );
    }
    printf("Subscribing to %s\n",zmq_channel);
    sockets[socket_cnt] = zmq_socket (ctx, ZMQ_SUB);
    zmq_setsockopt( sockets[socket_cnt], ZMQ_SUBSCRIBE, "", 0 );
    rc = zmq_connect( sockets[socket_cnt], zmq_channel );
    if(rc!=0)
      mexErrMsgTxt("Could not connect!");
    // Auto poll setup
    poll_items[socket_cnt].socket = sockets[socket_cnt];
    poll_items[socket_cnt].events = ZMQ_POLLIN;
    plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
    uint8_t* out = (uint8_t*)mxGetData(plhs[0]);
    out[0] = socket_cnt;
    socket_cnt++;
  }
  // Send data over a socket
  else if (strcasecmp(command, "send") == 0){
    if( nrhs != 3 )
      mexErrMsgTxt("Please provide a socket id and a string message to send");
    if ( !mxIsClass(prhs[1],"uint8") || mxGetNumberOfElements(prhs[1])!=1 )
      mexErrMsgTxt("Please provide a valid handle");
    uint8_t* socketid = (uint8_t*)mxGetData(prhs[1]);
    int socket = socketid[0];
    if( socket>socket_cnt)
      mexErrMsgTxt("Bad socket id!");
    if ( !mxIsChar(prhs[2]) )
      mexErrMsgTxt("Could not read string. (3rd argument)");
    size_t msglen = (mxGetM(prhs[2]) * mxGetN(prhs[2])) + 1;
    char* msg = mxArrayToString(prhs[2]);
    int nbytes = zmq_send( sockets[ socket ], (void*)msg, msglen, 0 );
    printf("Sent %d bytes: %s\n",nbytes,msg);
    if(nbytes!=msglen)
      mexErrMsgTxt("Did not send correct number of bytes.");
  } else if (strcasecmp(command, "receive") == 0){
    if (nrhs != 2)
      mexErrMsgTxt("Please provide a socket id.");
    if ( !mxIsClass(prhs[1],"uint8") || mxGetNumberOfElements( prhs[1] )!=1 )
      mexErrMsgTxt("Please provide a valid handle");
    uint8_t* socketid = (uint8_t*)mxGetData(prhs[1]);
    int socket = socketid[0];
    if( socket>socket_cnt)
      mexErrMsgTxt("Bad socket id!");
    int nbytes = zmq_recv(sockets[socket], recv_buffer, BUFLEN, 0);
    //int nbytes = zmq_recv(sockets[socket], recv_buffer, BUFLEN, ZMQ_DONTWAIT);
    if(nbytes==-1)
      mexErrMsgTxt("Did not receive anything");
    ret_sz[0] = nbytes;
    plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
    void* start = mxGetData( plhs[0] );
    memcpy(start,recv_buffer,nbytes);
  } else if (strcasecmp(command, "poll") == 0){
    long mytimeout = -1;
    if (nrhs > 1 && mxGetNumberOfElements(prhs[1])==1 ){
      double* timeout_ptr = (double*)mxGetData(prhs[1]);
      mytimeout = (long)(timeout_ptr[0]);
    }
    rc = zmq_poll (poll_items, socket_cnt, mytimeout);

    // If not data, or error
    if(rc<0)
      mexErrMsgTxt("Poll error!");

    // Create a cell mxArray to hold the poll elements, and have an
    // index array to know which channel received data
    ret_sz[0] = rc;
    mxArray* idx_array_ptr = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
    uint8_t* idx = (uint8_t*)mxGetData(idx_array_ptr);
    mxArray* cell_array_ptr = mxCreateCellMatrix((mwSize)rc,1);
    int r = 0;
    for(int i=0;i<socket_cnt;i++)
      if(poll_items[i].revents){
        int nbytes = zmq_recv(sockets[i], recv_buffer, BUFLEN, 0);
        idx[r] = i;
        ret_sz[0] = nbytes;
        mxArray* tmp = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
        void* start = mxGetData( tmp );
        memcpy(start, recv_buffer, nbytes);
        mxSetCell(cell_array_ptr, r, tmp );
        r++;
      }// if an event
    // Push the output
    plhs[0] = cell_array_ptr;
    plhs[1] = idx_array_ptr;
    return;
  } else
    mexErrMsgTxt("Unrecognized command.");
}
