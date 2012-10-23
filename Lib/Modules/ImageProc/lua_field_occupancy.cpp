#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif

#include <stdint.h>
#include <math.h>
#include <iostream>

typedef unsigned char uint8;

static uint8 colorBall = 0x01;
static uint8 colorField = 0x08;
static uint8 colorWhite = 0x10;

inline bool isFree(uint8 label) 
{
  return (label & colorField) || (label & colorBall) || (label & colorWhite);
}

int lua_field_occupancy(lua_State *L) {
  // Check arguments
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }  
  int ni = luaL_checkint(L, 2);
  int nj = luaL_checkint(L, 3);
  const int nRegions = ni;

  int blockpos[nj];
  int blockcluster[nj];
  int countdown[nRegions];
  int count[nRegions];
  int flag[nRegions] ;

  for (int i = 0; i < nRegions; i++) {
    count[i] = 0;
    flag[i] = 0;
    countdown[i] = 0;
  }


  // Scan vertical lines: Uphalf
  int nBlocks = 0, nBlockClusters = 0;
  for (int i = 0; i < ni; i++) {
    int iRegion = nRegions*i/ni;
    uint8 *im_row = im_ptr + i;
    nBlocks = 0;
    nBlockClusters = 0;
    for (int j = 0; j < nj; j++) {
      blockpos[j] = 0;
      blockcluster[j] = 0;
    }
    for (int j = 0; j < nj; j++) {
      uint8 label = *im_row;
      if (!isFree(label)) {
        blockpos[nBlocks++] = j;
        if (nBlocks == 1) {
          blockcluster[nBlockClusters] = j;
          nBlockClusters++;
        }
        else if ((blockpos[nBlocks] - blockpos[nBlocks - 1]) > 5) {
          blockcluster[nBlockClusters] = j;
          nBlockClusters++;
        }
      }
      im_row += ni;
    }
//    std::cout << nBlocks << ' ' << nBlockClusters << std::endl;
//    std::cout << nBlockClusters << ' ';
    // no black pixels found, return type 1
    if (nBlocks < 0.05 * nj) {
      flag[i] = 1;
      count[i] = nj - 1;
      continue;
    }
    // all black pixels, return type 3
    if ((blockpos[nBlocks-1] == (nj - 1)) && (blockcluster[nBlockClusters - 1] == 0)) {
      flag[i] = 3;
      count[i] = 0;
      continue;
    }
    // found black switch to green (up to down), return type 2;
    if (blockpos[nBlocks-1] != (nj - 1)) {
      flag[i] = 2;
      count[i] = nj - blockpos[nBlocks-1] - 1;
      continue;
    }
    // found green switch to black (up to down), return type 4;
    if (blockcluster[nBlockClusters-1] != 0) {
      flag[i] = 4;
      count[i] = nj - blockcluster[nBlockClusters-1] - 1;
      continue;
    }
  }
//  std::cout << std::endl; 
  // return state
  lua_createtable(L,0,2);
  
  lua_pushstring(L,"range");
  lua_createtable(L,nRegions,0);
//  std::cout << "counts: ";
  for (int i = 0; i < nRegions; i++){
//    std::cout << count[i] << ' '; 
    lua_pushinteger(L, count[i]);
    lua_rawseti(L, -2, i+1);
  }
//  std::cout << std::endl;
  lua_settable(L, -3);
  
  lua_pushstring(L,"flag");
  lua_createtable(L,nRegions,0);
//  std::cout << "flags: ";
  for (int i = 0; i < nRegions; i++){
//    std::cout << flag[i] << ' ';
    lua_pushinteger(L, flag[i]);
    lua_rawseti(L, -2, i+1);
  }
//  std::cout << std::endl;
  lua_settable(L, -3);
  
  return 1;
}
