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
#include <vector>

#include "RegionProps.h"

static const int NMAX = 256;
static const int thresholdDefault = 5;

static int countJ[NMAX];
static int minJ[NMAX];
static int maxJ[NMAX];
static int sumJ[NMAX];


int lua_goal_posts(lua_State *L) {
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int m = luaL_checkint(L, 2);
  int n = luaL_checkint(L, 3);
  uint8_t mask = luaL_optinteger(L, 4, 1);
  int threshold = luaL_optinteger(L, 5, thresholdDefault);

  // Initialize arrays
  for (int i = 0; i < m; i++) {
    countJ[i] = 0;
    minJ[i] = n-1;
    maxJ[i] = 0;
    sumJ[i] = 0;
  }

  // Iterate through image getting projection statistics
  for (int i = 0; i < m; i++) {
    uint8_t *im_row = im_ptr + i;
    for (int j = 0; j < n; j++) {
      uint8_t pixel = *im_row;
      im_row += m;
      if (pixel & mask) {
        countJ[i]++;
        if (j < minJ[i]) minJ[i] = j;
        if (j > maxJ[i]) maxJ[i] = j;
        sumJ[i] += j;
      }
    }
  }

  std::vector<RegionProps> postVec;
  postVec.clear();
  RegionProps post;
  // Find connected posts
  bool connect = false;
  for (int i = 0; i < m; i++) {
    if (countJ[i] > threshold) {
      if (!connect) {
        post.area = countJ[i];
        post.sumI = countJ[i]*i;
        post.sumJ = sumJ[i];
        post.minI = i;
        post.maxI = i;
        post.minJ = minJ[i];
        post.maxJ = maxJ[i];
        connect = true;
      }
      else {
        post.area += countJ[i];
        post.sumI += countJ[i]*i;
        post.sumJ += sumJ[i];
        post.maxI = i;
        if (minJ[i] < post.minJ) post.minJ = minJ[i];
        if (maxJ[i] > post.maxJ) post.maxJ = maxJ[i];
      }
      connect = true;
    }
    else {
      if (connect) {
        postVec.push_back(post);
      }
      connect = false;
    }
  }
  if (connect) {
    postVec.push_back(post);
  }

  int npost = postVec.size();
  if (npost < 1) {
    return 0;
  }

  lua_createtable(L, npost, 0);
  for (int i = 0; i < npost; i++) {
    lua_createtable(L, 0, 3);
    // area field
    lua_pushstring(L, "area");
    lua_pushnumber(L, postVec[i].area);
    lua_settable(L, -3);

    // centroid field
    lua_pushstring(L, "centroid");
    double centroidI = (double)postVec[i].sumI/postVec[i].area;
    double centroidJ = (double)postVec[i].sumJ/postVec[i].area;
    lua_createtable(L, 2, 0);
    lua_pushnumber(L, centroidI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, centroidJ);
    lua_rawseti(L, -2, 2);
    lua_settable(L, -3);

    // boundingBox field
    lua_pushstring(L, "boundingBox");
    lua_createtable(L, 4, 0);
    lua_pushnumber(L, postVec[i].minI);
    lua_rawseti(L, -2, 1);
    lua_pushnumber(L, postVec[i].maxI);
    lua_rawseti(L, -2, 2);
    lua_pushnumber(L, postVec[i].minJ);
    lua_rawseti(L, -2, 3);
    lua_pushnumber(L, postVec[i].maxJ);
    lua_rawseti(L, -2, 4);
    lua_settable(L, -3);

    lua_rawseti(L, -2, i+1);
  }
  return 1;
}
