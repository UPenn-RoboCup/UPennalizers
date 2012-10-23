#ifndef luaBALLFILTER_H_DEFINED
#define luaBALLFILTER_H_DEFINED

#include "BallModel.h"
#include <math.h>

// Prediction requires OpenCV
//#define PREDICT
#define MODEL 3
/*
  Model Type
  1 - boost
  2 - dtrees
  3 - random trees
  4 - SVM
*/

#ifdef PREDICT
#include <cv.h>
#include <ml.h>
#endif

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

extern "C"
int luaopen_ballfilter(lua_State *L);

#endif
