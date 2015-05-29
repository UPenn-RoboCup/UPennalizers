#include <stdint.h>
#include <string.h>
#include <stdio.h>
#include <vector>
#include "zlib.h"

#ifdef __cplusplus
extern "C"
{
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#ifdef __cplusplus
}
#endif

using namespace std;

#define BYTE uint8_t

#define MAX_UNCOMPRESSED_SIZE 1000000

vector<uint8_t> temp;
vector<uint8_t> temp_un(MAX_UNCOMPRESSED_SIZE);

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

static int lua_z_compress(lua_State *L) {
  uint8_t * dataSrc = (uint8_t *) luaL_checkstring(L, 1);
  if ((dataSrc == NULL) || !lua_isstring(L, 1)) {
    return luaL_error(L, "ZCompress: First argument must be string");
  }
  int lenSrc = luaL_checkint(L, 2);

  int lenDst= GetMaxCompressedLen(lenSrc);

  temp.resize(lenDst);

  //printf("%d %d\n",lenSrc,lenDst);
  int lenPacked= CompressData( dataSrc, lenSrc, &(temp[0]), lenDst );

  if (lenPacked > 0) {
    lua_pushlstring(L, (const char *)&(temp[0]), lenPacked);
  }
  else {
    return luaL_error(L, "Compress Error");
  }

  return 1;
}

static int lua_z_uncompress(lua_State *L) {
  uint8_t * dataSrc = (uint8_t *) luaL_checkstring(L, 1);
  if ((dataSrc == NULL) || !lua_isstring(L, 1)) {
    return luaL_error(L, "ZUncompress: First argument must be string");
  }
  int lenSrc = luaL_checkint(L, 2);
 
  //printf("%d %d\n",lenSrc,lenDst);
  int lenUnpacked= UncompressData( dataSrc, lenSrc, &(temp_un[0]), temp_un.size() );

  if (lenUnpacked > 0) {
    lua_pushlstring(L, (const char *)&(temp_un[0]), lenUnpacked);
  }
  else {
    return luaL_error(L, "Uncompress Error");
  }

  return 1;
}

static const luaL_Reg Z_lib [] = {
  {"compress", lua_z_compress},
  {"uncompress", lua_z_uncompress},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_Z (lua_State *L) {
#if LUA_VERSION_NUM == 502
  luaL_newlib(L, Z_lib);
#else
  luaL_register(L, "Z", Z_lib);
#endif

  return 1;
}

