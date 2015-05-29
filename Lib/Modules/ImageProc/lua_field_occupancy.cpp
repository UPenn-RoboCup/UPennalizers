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

  int countdown[nRegions];
  int count[nRegions];
  int flag[nRegions] ;

  for (int i = 0; i < nRegions; i++) {
    count[i] = 0;
    flag[i] = 0;
    countdown[i] = 0;
  }

  // number of occupied pixels in one colume
  int nOccupiedPx = 0;
  // last occupied pixels in one colume
  int lastOccupiedPx = 0;
  // number of clusters of occupied pixels
  int nOPClusters = 0;
  // threshold to separate cluster
  int thCluster = 5;
  // number of occupied pixels in every cluster (max == #row)
  int OClusterPxs[nj];
  // First Occupied pixel pos in every cluster
  int OClusterPosFirst[nj];
  // Last Occupied Pixel pos in every cluster
  int OClusterPosLast[nj];
  for (int i = 0; i < ni; i++) {
    nOccupiedPx = 0;
    nOPClusters = -1;
    lastOccupiedPx = -1;
    // initiate Cluster stats
    for (int j = 0; j < nj; j++) {
      OClusterPxs[j] = 0;
      OClusterPosFirst[j] = 0;
      OClusterPosLast[j] = 0;
    }
    uint8 *im_row = im_ptr + i;
    for (int j = 0; j < nj; j++) {
      uint8 label = *im_row;
      if (!isFree(label)) {
        nOccupiedPx++;
        if ((lastOccupiedPx == -1) || (j - lastOccupiedPx > thCluster)) {
          OClusterPxs[++nOPClusters]++;
          OClusterPosFirst[nOPClusters] = j;
        }
        else {
          OClusterPxs[nOPClusters]++;
        }
        lastOccupiedPx = j;
      }
      im_row += ni;
    }

    // close cluster
    nOPClusters++;
    for (int cnt = 0; cnt < nOPClusters; cnt++) {
      OClusterPosLast[cnt] = OClusterPosFirst[cnt] + OClusterPxs[cnt] - 1;
    }
    // no black pixels found, return type 1
    if (nOccupiedPx < 0.05 * nj) {
      flag[i] = 1;
      count[i] = nj - 1;
      continue;
    }
    // all occupied pixels, no freespace found , return type 3
    else if (nOccupiedPx > 0.95 * nj) {
      flag[i] = 3;
      count[i] = 0;
      continue;
    }
    
    for (int cnt = nOPClusters-1; cnt >= 0; cnt--) {
      // occupied cluster shoud not start from button and occupied cluster should large enought
      if ((OClusterPosLast[cnt] >= nj - 2) || (OClusterPxs[cnt] < 0.1 * nj)) {
        flag[i] = 1;
        count[i] = nj - 1;
        continue;
      }
      flag[i] = 2;
      count[i] = nj - OClusterPosLast[cnt] - 1;
    }
  }
  // return state
  lua_createtable(L,0,2);
  
  lua_pushstring(L,"range");
  lua_createtable(L,nRegions,0);
  for (int i = 0; i < nRegions; i++){
    lua_pushinteger(L, count[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_settable(L, -3);
  
  lua_pushstring(L,"flag");
  lua_createtable(L,nRegions,0);
  for (int i = 0; i < nRegions; i++){
    lua_pushinteger(L, flag[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_settable(L, -3);
  
  return 1;
}
