#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <vector>
#include "zlib.h"
#include <mex.h>
#define BYTE uint8_t

#define MAX_UNCOMPRESSED_SIZE 1000000

using namespace std;

vector<uint8_t> temp(MAX_UNCOMPRESSED_SIZE);

int UncompressData( const BYTE* abSrc, int nLenSrc, BYTE* abDst, int nLenDst )
{
    z_stream zInfo ={0};
    zInfo.total_in=  zInfo.avail_in=  nLenSrc;
    zInfo.total_out=0;
    zInfo.avail_out= nLenDst;
    zInfo.next_in= (BYTE*)abSrc;
    zInfo.next_out= abDst;

    int nErr, nRet= -1;
    nErr= inflateInit( &zInfo );
    if (nErr != Z_OK)
    {
      printf("zlibUncompress: could not initialized inflate\n");
      return -1;
    }

    
    nErr= inflate( &zInfo, Z_FINISH );
    if ( nErr == Z_STREAM_END ) {
        nRet= zInfo.total_out;
    }
    else
    {
      printf("zlibUncompress: could not inflate\n");
      return -1;
    }
    
    inflateEnd( &zInfo );
    return( nRet ); // -1 or len of output
}


void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  if (nrhs != 1)
  {
    printf("zlibUncompress: need exactly one argument\n");
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);
    return;
  }

  int lenSrc = mxGetNumberOfElements(prhs[0])*mxGetElementSize(prhs[0]);
  uint8_t * dataSrc = (uint8_t*)mxGetData(prhs[0]);
  

  //printf("%d %d\n",lenSrc,lenDst);
  int lenUnpacked= UncompressData( dataSrc, lenSrc, &(temp[0]), temp.size() );

  if (lenUnpacked > 0)
  {
    const int ndims =2;
    int dims[] = {1,lenUnpacked};
    plhs[0] = mxCreateNumericArray(ndims,dims,mxUINT8_CLASS,mxREAL);
    memcpy(mxGetData(plhs[0]),&(temp[0]),lenUnpacked);
  }
  else
    plhs[0] = mxCreateDoubleMatrix(0,0,mxREAL);

}
