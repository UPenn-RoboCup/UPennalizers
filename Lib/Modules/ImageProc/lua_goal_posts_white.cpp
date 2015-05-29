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

static uint8_t colorGoal = 0x10;
static int widthMin = 2;
static int widthMax = 20;

/*
  Simple state machine for field line detection:
  ==colorField -> &colorGoal -> ==colorField
  Use goalState(0) to initialize, then call with color labels
  Returns width of line when detected, otherwise 0
*/
int goalState(uint8_t label, int i)
{
  enum {STATE_NONE, STATE_GOAL};
  static int state = STATE_NONE;
  static int width = 0;
  switch (state) {
  case STATE_NONE:
    if (label & colorGoal){
      state = STATE_GOAL;
      width = 1;
    }
    break;
  case STATE_GOAL:
    if (label & colorGoal){
      //if i is zero, than we are at the beginning of a line
      //Need to cut the segment and start a new one
      if (i!=0) width++;
      else {
        int width_old = width;
        width=1;
        return width_old;
      }
    }
    else {
      state = STATE_NONE;
      return width;
    }
  }
  return 0;
}

// Maximum number of segments to consider
#define MAX_SEGMENTS 150
struct SegmentStats {
  int state; //0 for inactive, 1 for active, 2 for ended
  int updated;
  int x0,y0; //topleft point
  int x1,y1; //bottomright point
  double xMean;//only need xMean to align segments
  int height; 
  double mean_width;
  int xsum,ysum;
  int gap;//gap handling
  int area;
};

static struct SegmentStats segments[MAX_SEGMENTS];
static int num_segments;

void goal_segment_init(){
  for(int i=0;i<MAX_SEGMENTS;i++){
    segments[i].state=0;
    segments[i].area=0;
    segments[i].gap=0;
    segments[i].x0=0;
    segments[i].y0=0;
    segments[i].x1=0;
    segments[i].y1=0;
    segments[i].height=0;
    segments[i].xsum=0;
    segments[i].ysum=0;
    segments[i].updated=0;
  }
  num_segments=0;
}

void goal_segment_refresh(){
  //end active segments if they were not updated for one line scan
  for(int i=0;i<num_segments;i++){
    if ((segments[i].state==1) && (segments[i].updated==0)){ 
      if (segments[i].gap>0)
	      segments[i].gap--;
      else
        segments[i].state=2;
    }
    segments[i].updated=0;
  }
}

void goal_segment_terminate(){
  //end all segments
  for(int i=0;i<num_segments;i++) segments[i].state=2;
}

void initStat(struct SegmentStats *statPtr,int ileft, int iright, int j){
  struct SegmentStats &stat=*statPtr;
  int width=iright-ileft+1;
  double middle=(double(iright+ileft))/2;
  stat.state=1;
  stat.height=1;
  stat.gap=1;
  stat.x0=ileft;
  stat.y0=j;
  stat.x1=iright;
  stat.y1=j;
  stat.mean_width=width;
  stat.area=width;
  stat.xMean=middle;
  stat.updated=1;
  stat.xsum=(iright+ileft)*width/2;
  stat.ysum=j*width;
}

void updateStat(struct SegmentStats *statPtr, int ileft, int iright, int j, int max_gap){
  struct SegmentStats &stat=*statPtr;
  int width=iright-ileft+1;
  double middle=(double(ileft+iright))/2;
  stat.xMean=(stat.height*stat.xMean + middle)/(stat.height+1);
  stat.mean_width=(stat.mean_width*stat.height+width)/(stat.height+1);
  if (ileft<stat.x0) stat.x0=ileft;
  if (iright>stat.x1) stat.x1=iright;
  stat.y1=j;//always from top to bottom
  stat.height++;
  stat.area+=width;
  stat.xsum+=(iright+ileft)*width/2;
  stat.ysum+=j*width;
  stat.updated=1;
  stat.gap++;
  if (stat.gap>max_gap+1) stat.gap=max_gap+1;
}

//We always add pixel from top to bottom
void addVerticalPixel(int ileft, int iright, int j, double connect_th, int max_gap){
  //Find best matching active segment
  //printf("segment found: %d, %d, %d\n",ileft,iright,j);
  int seg_updated=0;
  int width=iright-ileft+1;
  double middle=(double(iright+ileft))/2;
  for (int k=0;k<num_segments;k++){
    if (segments[k].state==1 and seg_updated==0){
      double xErr = middle-segments[k].xMean;
      double wErr = width-segments[k].mean_width;
      if (xErr<0) xErr=-xErr;
      if (wErr<0) wErr=-wErr;
      if (xErr<=segments[k].mean_width*connect_th && wErr<=segments[k].mean_width*connect_th ){
        //printf("updated with number: %d, %f, %d\n",k,segments[k].xMean,segments[k].height);
        updateStat(&segments[k],ileft,iright,j,max_gap);
        seg_updated=1;
      }
    }
  }
  if ((seg_updated==0)&&(num_segments<MAX_SEGMENTS)){
    //printf("====== New segment %d start:%d,%d,%d ======\n",num_segments,ileft,iright,j);
    initStat(&segments[num_segments],ileft,iright,j);
    num_segments++;
  }
}

int lua_goal_posts_white(lua_State *L) {
  uint8_t *im_ptr = (uint8_t *) lua_touserdata(L, 1);
  if ((im_ptr == NULL) || !lua_islightuserdata(L, 1)) {
    return luaL_error(L, "Input image not light user data");
  }
  int ni = luaL_checkint(L, 2);
  int nj = luaL_checkint(L, 3);
  widthMin = luaL_optinteger(L, 4, 2);
  widthMax = luaL_optinteger(L, 5, 20);
  double connect_th = luaL_optnumber(L, 6, 0.25);
  int max_gap = luaL_optinteger(L, 7, 1);
  int min_height = luaL_optinteger(L, 8, 5);

  goal_segment_init();
  // Scan for vertical line pixels:
  for (int j = 0; j < nj; j++) {
    uint8_t *im_col = im_ptr + ni*j;
    for (int i = 0; i < ni; i++) {
      uint8_t label = *im_col++;
      int width = goalState(label,i);
      if ((width >= widthMin) && (width <= widthMax)) {
        if (i>0){
          int ileft=i-width;
	        addVerticalPixel(ileft,i-1,j,connect_th,max_gap);
        }else{ //i=0 means this is from last line
          int iright=ni-1;
          int ileft = iright-width;
          addVerticalPixel(ileft,iright,j-1,connect_th,max_gap);
        }
      }
    }
    goal_segment_refresh();
  }
  goal_segment_terminate();

  int valid_segments=0;
  for (int i=0;i<num_segments;i++){
    if (segments[i].height>min_height){
      valid_segments++;
    }
  }
  if (valid_segments<1) return 0;
  lua_createtable(L, valid_segments, 0);
  int seg_count=0;
 
  for (int i = 0; i < num_segments; i++) {
    if (segments[i].height>min_height){
      lua_createtable(L, 0, 3);
      // area field
      lua_pushstring(L, "area");
      lua_pushnumber(L, segments[i].area);
      lua_settable(L, -3);
      // centroid field
      lua_pushstring(L, "centroid");
      double centroidI=(double)segments[i].xsum/segments[i].area;
      double centroidJ=(double)segments[i].ysum/segments[i].area;

      lua_createtable(L, 2, 0);
      lua_pushnumber(L, centroidI);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, centroidJ);
      lua_rawseti(L, -2, 2);
      lua_settable(L, -3);
      // boundingBox field
      lua_pushstring(L, "boundingBox");
      lua_createtable(L, 4, 0);
      lua_pushnumber(L, segments[i].x0);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, segments[i].x1);
      lua_rawseti(L, -2, 2);
      lua_pushnumber(L, segments[i].y0);
      lua_rawseti(L, -2, 3);
      lua_pushnumber(L, segments[i].y1);
      lua_rawseti(L, -2, 4);
      lua_settable(L, -3);
      lua_rawseti(L, -2, seg_count+1);
      seg_count++;
    }
  }
  return 1;
}
