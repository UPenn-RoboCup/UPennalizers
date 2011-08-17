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

#include "RadonTransform.h"

static RadonTransform radonTransform;

static uint8_t colorLine = 0x10;
static uint8_t colorField = 0x08;
static int widthMin = 1;
static int widthMax = 10;

/*
  Simple state machine for field line detection:
  ==colorField -> &colorLine -> ==colorField
  Use lineState(0) to initialize, then call with color labels
  Returns width of line when detected, otherwise 0
*/
int lineState(uint8_t label)
{
  enum {STATE_NONE, STATE_FIELD, STATE_LINE};
  static int state = STATE_NONE;
  static int width = 0;

  switch (state) {
  case STATE_NONE:
    if (label == colorField)
      state = STATE_FIELD;
    break;
  case STATE_FIELD:
    if (label & colorLine) {
      state = STATE_LINE;
      width = 1;
    }
    else if (label != colorField) {
      state = STATE_NONE;
    }
    break;
  case STATE_LINE:
    if (label == colorField) {
      state = STATE_FIELD;
      return width;
    }
    else if (!(label & colorLine)) {
      state = STATE_NONE;
    }
    else {
      width++;
    }
  }
  return 0;
}


int lua_field_lines(lua_State *L) {
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int ni = luaL_checkint(L, 2);
  int nj = luaL_checkint(L, 3);
  if (lua_gettop(L) >= 4)
    widthMax = luaL_checkint(L, 4);

  radonTransform.clear();
  // Scan for vertical line pixels:
  for (int j = 0; j < nj; j++) {
    uint8_t *im_col = im_ptr + ni*j;
    lineState(0); // Initialize
    for (int i = 0; i < ni; i++) {
      uint8_t label = *im_col++;
      int width = lineState(label);
      if ((width >= widthMin) && (width <= widthMax)) {
	int iline = i - (width+1)/2;
	radonTransform.addVerticalPixel(iline, j);
      }
    }
  }

  // Scan for horizontal field line pixels:
  for (int i = 0; i < ni; i++) {
    uint8_t *im_row = im_ptr + i;
    lineState(0); //Initialize
    for (int j = 0; j < nj; j++) {
      uint8_t label = *im_row;
      im_row += ni;
      int width = lineState(label);
      if ((width >= widthMin) && (width <= widthMax)) {
	int jline = j - (width+1)/2;
	radonTransform.addHorizontalPixel(i, jline);
      }
    }
  }

  LineStats bestLine = radonTransform.getLineStats();
  lua_createtable(L, 0, 3);
  
  // count field
  lua_pushstring(L, "count");
  lua_pushnumber(L, bestLine.count);
  lua_settable(L, -3);

  // centroid field
  lua_pushstring(L, "centroid");
  double centroidI = bestLine.iMean;
  double centroidJ = bestLine.jMean;
  lua_createtable(L, 2, 0);
  lua_pushnumber(L, centroidI);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, centroidJ);
  lua_rawseti(L, -2, 2);
  lua_settable(L, -3);

  // endpoint field
  lua_pushstring(L, "endpoint");
  lua_createtable(L, 4, 0);
  lua_pushnumber(L, bestLine.iMin);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, bestLine.iMax);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, bestLine.jMin);
  lua_rawseti(L, -2, 3);
  lua_pushnumber(L, bestLine.jMax);
  lua_rawseti(L, -2, 4);
  lua_settable(L, -3);

  return 1;
}
