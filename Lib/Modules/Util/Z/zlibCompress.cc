#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <vector>
#include "zlib.h"
#include <mex.h>
#define BYTE uint8_t

using namespace std;

vector<uint8_t> temp;

int GetMaxCompressedLen( int nLenSrc ) 
{
    int n16kBlocks = (nLenSrc+16383) / 16384; // round up any fraction of a block
    return ( nLenSrc + 6 + (n16kBlocks*5) );
}

int CompressData( const BYTE* abSrc, int nLenSrc, BYTE* abDst, int nLenDst )
{
    z_stream zInfo ={0};

    int nErr, nRet= -1;
    nErr= deflateInit( &zInfo, Z_BEST_SPEED);
    if (nErr != Z_OK)
    {
      printf("zlibCompress: could not initialized deflate\n");
      return -1;
    }

    zInfo.total_in=  zInfo.avail_in=  nLenSrc;
    zInfo.total_out=0;
    zInfo.avail_out= nLenDst;
    zInfo.next_in= (BYTE*)abSrc;
    zInfo.next_out= abDst;
    
    nErr= deflate( &zInfo, Z_FINISH );              
    if ( nErr == Z_STREAM_END ) {
        nRet= zInfo.total_out;
    }
    else
    {
      printf("zlibCompress: could not deflate\n");
      return -1;
    }
    
    deflateEnd( &zInfo );    

    //printf("packed size = %d\n",nRet);
 
    return( nRet );
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 1)
  {
    printf("zlibCompress: need exactly one argument\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  int lenSrc = mxGetNumberOfElements(prhs[0])*mxGetElementSize(prhs[0]);
  uint8_t * dataSrc = (uint8_t*)mxGetData(prhs[0]);

  int lenDst= GetMaxCompressedLen(lenSrc);
  
  temp.resize(lenDst);

  //printf("%d %d\n",lenSrc,lenDst);
  int lenPacked= CompressData( dataSrc, lenSrc, &(temp[0]), lenDst );

  if (lenPacked > 0)
  {
    const int ndims =2;
    int dims[] = {1,lenPacked};
    plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT8_CLASS,mxREAL);
    memcpy(mxGetData(plhs[0]),&(temp[0]),lenPacked);
  }
  else
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);

}
