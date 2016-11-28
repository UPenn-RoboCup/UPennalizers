/*
 * MATLAB mex file to send and receive zmq messages (PUB/SUB)
 * Stephen G. McGill copyright 2013 <smcgill3@seas.upenn.edu>
 * */
#include <string>
#include <stdio.h>
#include <zmq.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include "mex.h"
/* 1MB-ish buffer */
#define BUFLEN 1000000
/* Do not exceed 255 since indexed by uint8_t */
#define MAX_SOCKETS 10

char *command, *protocol, *channel;
double* port_ptr;
/* Channel name */
char zmq_channel[200];
void * ctx;
void * sockets[MAX_SOCKETS];
zmq_pollitem_t poll_items [MAX_SOCKETS];
uint8_t socket_cnt = 0, socket_id;
int result, rc;
static int initialized = 0;
mwSize ret_sz[]={1};
char* recv_buffer;

/* Cleaning up the data */
void cleanup( void ){
	free( recv_buffer );
	mexPrintf("ZMQMEX: closing sockets and context.\n");
	for(int i=0;i<socket_cnt;i++)
		zmq_close( sockets[i] );
	zmq_term( ctx );
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {

	/* First run will initialize the context */
	if (!initialized) {
		mexPrintf("ZMQMEX: creating a 2 thread ZMQ context.\n");
		recv_buffer = (char*) malloc( BUFLEN );
		ctx = zmq_init(2);
		initialized = 1;
		/* 'clear all' and 'clear mex' calls this function */
		mexAtExit(cleanup);
	}

	/* Should Have a least a few arguments */
	if (nrhs < 1)
		mexErrMsgTxt("Usage: zmq('[subscribe|publish|poll|receive]','[ipc|tcp|udp|pgm]','{name|IP}','PORT')");

	/* Grab the command string */
	if ( !(command = mxArrayToString(prhs[0])) )
		mexErrMsgTxt("Could not read command string. (1st argument)");

	/* Setup a publisher */
	if( strcmp(command, "publish")==0 ){
		
		/* Check that we have enough socket spaces available */
		if( socket_cnt==MAX_SOCKETS )
			mexErrMsgTxt("Cannot create any more sockets!");
		
		/* Grab the protocol and channel */
		if( !(protocol=mxArrayToString(prhs[1])) )
			mexErrMsgTxt("Bad protocol string.");
		if( nrhs<3 || !(channel=mxArrayToString(prhs[2])) )
			mexErrMsgTxt("Bad channel string.");
		
		/* Protocol specific channel formation */
	  if( strcmp(protocol, "ipc")==0 ){
			sprintf(zmq_channel, "ipc:///tmp/%s", channel );
		} else if( strcmp(protocol, "tcp")==0 ) {
			if(nrhs!=4)
				mexErrMsgTxt("Usage: zmq('subscribe','tcp','IP',PORT)");
			if( nrhs!=4 || !(port_ptr=(double*)mxGetData(prhs[3])) )
				mexErrMsgTxt("Usage: zmq('subscribe','udp',multicast_address,port)");
			sprintf(zmq_channel, "tcp://%s:%d", channel, (int)port_ptr[0] );
		} else if( strcmp(protocol, "pgm")==0  ) {
			if( nrhs!=4 || !(port_ptr=(double*)mxGetData(prhs[3])) )
				mexErrMsgTxt("Usage: zmq('subscribe','pgm',multicast_address,port)");
			/* http://en.wikipedia.org/wiki/Multicast_address */
			/* Channel should be 224.0.0.1 by default */
			sprintf(zmq_channel, "pgm://en0;%s:%d", channel, (int)port_ptr[0] );
		}
		
		/* Connect to the socket */
		mexPrintf("ZMQMEX: Binding to {%s}.\n", zmq_channel);
		if( (sockets[socket_cnt]=zmq_socket(ctx, ZMQ_PUB))==NULL)
			mexErrMsgTxt("Could not create socket!");
		rc = zmq_connect( sockets[socket_cnt], zmq_channel );
		if(rc!=0)
			mexErrMsgTxt("Could not bind to socket!");
		poll_items[socket_cnt].socket = sockets[socket_cnt];
		/* poll_items[socket_cnt].events = ZMQ_POLLOUT; */
		
		/* MATLAB specific return of the socket ID */
		ret_sz[0] = 1;
		plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
		uint8_t* out = (uint8_t*)mxGetData(plhs[0]);
		out[0] = socket_cnt;
		socket_cnt++;
	}
	/* Set up a subscriber */
	else if( strcmp(command, "subscribe")==0 ){

		/* Check that we have enough socket spaces available */
		if( socket_cnt==MAX_SOCKETS )
			mexErrMsgTxt("Cannot create any more sockets!");
		
		/* Grab the protocol and channel */
		if( !(protocol=mxArrayToString(prhs[1])) )
			mexErrMsgTxt("Bad protocol string.");
		if( nrhs<3 || !(channel=mxArrayToString(prhs[2])) )
			mexErrMsgTxt("Bad channel string.");
		
		/* Protocol specific channel formation */
	  if( strcmp(protocol, "ipc")==0 ){
			sprintf(zmq_channel, "ipc:///tmp/%s", channel );
		} else if( strcmp(protocol, "tcp")==0 ) {
			if(nrhs!=4)
				mexErrMsgTxt("Usage: zmq('subscribe','tcp','IP',PORT)");
			if( nrhs!=4 || !(port_ptr=(double*)mxGetData(prhs[3])) )
				mexErrMsgTxt("Usage: zmq('subscribe','udp',multicast_address,port)");
			sprintf(zmq_channel, "tcp://%s:%d", channel, (int)port_ptr[0] );
		} else if( strcmp(protocol, "pgm")==0  ) {
			if( nrhs!=4 || !(port_ptr=(double*)mxGetData(prhs[3])) )
				mexErrMsgTxt("Usage: zmq('subscribe','pgm',multicast_address,port)");
			/* http://en.wikipedia.org/wiki/Multicast_address */
			/* Channel should be 224.0.0.1 by default */
			sprintf(zmq_channel, "pgm://en0;%s:%d", channel, (int)port_ptr[0] );
		}
		
		/* Bind to the socket */
		mexPrintf("ZMQMEX: Connecting to {%s}.\n", zmq_channel);
		if( (sockets[socket_cnt]=zmq_socket(ctx, ZMQ_SUB))==NULL)
			mexErrMsgTxt("Could not create socket!");
		zmq_setsockopt( sockets[socket_cnt], ZMQ_SUBSCRIBE, "", 0 );
		rc=zmq_connect( sockets[socket_cnt], zmq_channel );
		if(rc!=0)
			mexErrMsgTxt("Could not connect to socket!");

		/* Add the connected socket to the poll items */
		poll_items[socket_cnt].socket = sockets[socket_cnt];
		poll_items[socket_cnt].events = ZMQ_POLLIN;

		/* MATLAB specific return of the socket ID */
		ret_sz[0] = 1;
		plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
		uint8_t* out = (uint8_t*)mxGetData(plhs[0]);
		out[0] = socket_cnt;
		socket_cnt++;
	}
	/* Send data over a socket */
	else if (strcasecmp(command, "send") == 0){
		if( nrhs != 3 )
			mexErrMsgTxt("Please provide a socket id and a message to send");
		if ( !mxIsClass(prhs[1],"uint8") || mxGetNumberOfElements(prhs[1])!=1 )
			mexErrMsgTxt("Please provide a valid handle");
		socket_id = *( (uint8_t*)mxGetData(prhs[1]) );
		if( socket_id>socket_cnt )
			mexErrMsgTxt("Bad socket id!");
		
		size_t n_el = mxGetNumberOfElements(prhs[2]);
		size_t el_sz = mxGetElementSize(prhs[2]);		
		size_t msglen = n_el*el_sz;
		/* Get the data and send it  */
		void* msg = (void*)mxGetData(prhs[2]);
		int nbytes = zmq_send( sockets[ socket_id ], msg, msglen, 0 );
		/* Check the outcome of the send */
		if(nbytes!=msglen)
			mexErrMsgTxt("Did not send correct number of bytes.");
		if(nlhs>0) {
			ret_sz[0] = 1;
			plhs[0] = mxCreateNumericArray(1,ret_sz,mxINT32_CLASS,mxREAL);
			int* out = (int*)mxGetData(plhs[0]);
			out[0] = nbytes;
		}
	} else if (strcasecmp(command, "receive") == 0){
		if (nrhs != 2)
			mexErrMsgTxt("Please provide a socket id.");
		if ( !mxIsClass(prhs[1],"uint8") || mxGetNumberOfElements( prhs[1] )!=1 )
			mexErrMsgTxt("Please provide a valid handle");
		socket_id = *( (uint8_t*)mxGetData(prhs[1]) );
		if( socket_id>socket_cnt )
			mexErrMsgTxt("Bad socket id!");

		/* If a file descriptor, then return the fd */
		if( poll_items[socket_id].socket == NULL ){
			ret_sz[0] = 1;
			plhs[0] = mxCreateDoubleScalar( poll_items[socket_id].fd );
			plhs[1] = mxCreateDoubleScalar( 0 );
			return;
		}

		/* Blocking Receive */
		int nbytes = zmq_recv(sockets[socket_id], recv_buffer, BUFLEN, 0);
		/* Non-blocking Receive */
		/*zmq_recv(sockets[socket], recv_buffer, BUFLEN, ZMQ_DONTWAIT);*/
		if(nbytes==-1)
			mexErrMsgTxt("Did not receive anything from ZMQ");
		
		/* Check if multipart */
		int has_more;
		size_t has_more_size = sizeof(has_more);
		rc = zmq_getsockopt( sockets[socket_id], ZMQ_RCVMORE, 
			&has_more, &has_more_size );
		if( rc!=0 )
			mexErrMsgTxt("Bad ZMQ_RCVMORE call!");
		
		/* Output the data to MATLAB */
		ret_sz[0] = nbytes;
		plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
		void* start = mxGetData( plhs[0] );
		memcpy(start,recv_buffer,nbytes);
		/* has_more variable */
		plhs[1] = mxCreateDoubleScalar( has_more );
	}
	/* Poll for data at a specified interval.  Default interval: indefinite */
	else if (strcasecmp(command, "poll") == 0){
		long mytimeout = -1;
		if (nrhs > 1 && mxGetNumberOfElements(prhs[1])==1 ){
			double* timeout_ptr = (double*)mxGetData(prhs[1]);
			mytimeout = (long)(timeout_ptr[0]);
		}
		/* Get the number of objects that have data */
		rc = zmq_poll (poll_items, socket_cnt, mytimeout);
		if(rc<0)
			mexErrMsgTxt("Poll error!");

		/* 
			 Create a cell mxArray to hold the poll elements, and have an
			 index array to know which channel received data
			 */
		ret_sz[0] = rc;
		mxArray* idx_array_ptr = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
		uint8_t* idx = (uint8_t*)mxGetData(idx_array_ptr);
		int r = 0;
		for(int i=0;i<socket_cnt;i++)
			if(poll_items[i].revents)
				idx[r++] = i;
		plhs[0] = idx_array_ptr;
		return;
	}
	/* Add a file descriptor to the polling list (typically udp) */
	else if(strcasecmp(command, "fd") == 0){
		if( socket_cnt==MAX_SOCKETS )
			mexErrMsgTxt("Cannot create any more poll items!");
		if (nrhs != 2)
			mexErrMsgTxt("Please provide a file descriptor.");
		if ( !mxIsClass(prhs[1],"uint32") || mxGetNumberOfElements( prhs[1] )!=1 )
			mexErrMsgTxt("Please provide a valid file descriptor.");
		uint32_t fd = *( (uint32_t*)mxGetData(prhs[1]) );
		if( fd<3 )
			mexErrMsgTxt("Bad file descriptor!");
		poll_items[socket_cnt].socket = NULL;
		poll_items[socket_cnt].fd = fd;
		poll_items[socket_cnt].events = ZMQ_POLLIN;
		ret_sz[0] = 1;
		plhs[0] = mxCreateNumericArray(1,ret_sz,mxUINT8_CLASS,mxREAL);
		uint8_t* out = (uint8_t*)mxGetData(plhs[0]);
		out[0] = socket_cnt;
		socket_cnt++;
	}
	else
		mexErrMsgTxt("Unrecognized command.");
}
