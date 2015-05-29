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
//field 0x08 and ball 0x01 are all considered field
static uint8_t colorField = 0x09;
static int widthMin = 1;
static int widthMax = 10;

/*
  Simple state machine for field line detection:
  green --> white --> green is a line piece
  use transition state to jump over one black pixel
  integer input i to deal with row/column switch
  Use lineState(0) to initialize, then call with color labels
  Returns width of line when detected, otherwise 0
*/
int lineState(uint8_t label, int i)
{
  enum {STATE_NONE, STATE_FIELD, STATE_LINE, STATE_TRANS};
  static int state = STATE_NONE;
  static int width = 0;
  static int jump = 0;
  if (i==0){
    state=STATE_NONE;
    jump = 0;
    width = 0;
  }
  switch (state) {
  case STATE_NONE:
    if (label & colorField){
      state = STATE_FIELD;
    }
    break;
  case STATE_FIELD:
    width = 0;
    if (label & colorLine){
      state = STATE_LINE;
      width = 1;
    }else if (label & colorField==0){
      state = STATE_TRANS;
    }
    break;
  case STATE_LINE:
    if (label & colorLine){
      ++width;      
    }else if(label & colorField){
      state = STATE_FIELD;
      return width;
    }else{
      ++width;
      state = STATE_TRANS;
    }
    break;
  case STATE_TRANS:
    if (label & colorField){
      state = STATE_FIELD;
      if (width>0){
        return width;
      }
    }else if(label & colorLine){
      state = STATE_LINE;
      ++width;
    }else{
      if (jump >= 1){
        state = STATE_NONE;
        jump = 0;
        width = 0;
      }else
        ++jump;
    }
  }   
  return 0;
}



// Maximum number of segments to consider
//#define MAX_SEGMENTS 50

//TODO: better handling of short noisy lines
#define MAX_SEGMENTS 200

struct SegmentStats {
  int state; //0 for inactive, 1 for active, 2 for ended
  int gap; //gap handling
  int count; //the horizontal length of the line
  int x0,y0; //start point
  int x1,y1; //end point
  double xMean;
  double yMean;
  double grad;//gradient, dy/dx
  double invgrad; //inv gradient, dx/dy
  int x,y,xy,xx,yy; //for gradient stats
  int updated;
  double length;
  double mean_width;
  int max_width; 
};

static struct SegmentStats segments[MAX_SEGMENTS];
static int num_segments;

void segment_init(){
  for(int i=0;i<MAX_SEGMENTS;i++){
    segments[i].state=0;
    segments[i].gap=0;
    segments[i].count=0;
    segments[i].xy=0;
    segments[i].xx=0;
    segments[i].x=0;
    segments[i].y=0;
    segments[i].updated=0;
    segments[i].grad=0;
    segments[i].invgrad=0;
    segments[i].max_width=0;
    segments[i].mean_width=0;
  }
  num_segments=0;
}

void segment_refresh(){
  //end active segments if they were not updated for one line scan
  for(int i=0;i<num_segments;i++){
    if ((segments[i].state==1) && (segments[i].updated==0)){ 
      if (segments[i].gap>0)
	      segments[i].gap--;
      else{
        //printf("terminating segments %d\n",i);
        segments[i].state=2;
      }
    }
    segments[i].updated=0;
  }
}

void segment_terminate(){
  //end all segments
  for(int i=0;i<num_segments;i++) segments[i].state=2;
}

void updateLineStat(struct SegmentStats *statPtr, int i, int j, int width, int max_gap){
  struct SegmentStats &stat=*statPtr;
  stat.xMean=(stat.count*stat.xMean + i)/(stat.count+1);
  stat.yMean=(stat.count*stat.yMean + j)/(stat.count+1);
  stat.x=stat.x+i;
  stat.y=stat.y+j;
  stat.xy=stat.xy+i*j;
  stat.xx=stat.xx+i*i;
  stat.yy=stat.yy+j*j;
  stat.mean_width=(stat.mean_width*stat.count+width)/(stat.count+1);
  stat.count++;
  stat.gap++;
  if (stat.gap>max_gap+1) stat.gap=max_gap+1;
}

void initStat(struct SegmentStats *statPtr,int i, int j){
  struct SegmentStats &stat=*statPtr;
  stat.state=1;
  stat.count=1;
  stat.gap=1;
  stat.grad=0;
  stat.x0=i;
  stat.y0=j;
  stat.x=i;
  stat.y=j;
  stat.xx=i*i;
  stat.xy=i*j;
  stat.yy=j*j;
  stat.xMean=i;
  stat.yMean=j;
  stat.updated=1;
}


//We always add pixel from left to right
void addHorizontalPixel(int i, int j, double connect_th, int max_gap, int width){
  //Find best matching active segment
  int seg_updated=0;
  for (int k=0;k<num_segments;k++){
    if(segments[k].state==1){
      double yProj = segments[k].yMean + segments[k].grad*(i-segments[k].xMean);
      double yErr = j-yProj;if (yErr<0) yErr=-yErr;
      if (yErr<connect_th){
        //printf("Add piece (%d %d) to segment %d starting at (%d %d)\n",
          //i,j,k,segments[k].x0,segments[k].y0);
	      updateLineStat(&segments[k],i,j,width,max_gap);
        segments[k].grad=(double) 
		      (segments[k].xy- segments[k].x*segments[k].y/segments[k].count)
		      /(segments[k].xx-segments[k].x*segments[k].x/segments[k].count);
        if ((segments[k].grad>1.0) ||(segments[k].grad<-1.0)){
	        //printf("segment %d killed by grad\n",k);
          segments[k].state=2; //kill anything that exceeds 45 degree
	        segments[k].count=0;
	      }
	      segments[k].updated=1;
        segments[k].x1=i;
        segments[k].y1=j;
        if (width > segments[k].max_width) {
          segments[k].max_width = width;
        }
        seg_updated=seg_updated+1;
        break;
      }
    }
  }
  if ((seg_updated==0)&&(num_segments<MAX_SEGMENTS)){
    //printf("New segment %d started at %d,%d\n",num_segments,i,j);
    initStat(&segments[num_segments],i,j);
    num_segments++;
  }
}


//We always add pixel from top to bottom
void addVerticalPixel(int i, int j, double connect_th, int max_gap, int width){
  //Find best matching active segment
  int seg_updated=0;
  for (int k=0;k<num_segments;k++){
    if(segments[k].state==1){
      double xProj = segments[k].xMean + segments[k].invgrad*(j-segments[k].yMean);
      double xErr = i-xProj;if (xErr<0) xErr=-xErr;
      if (xErr<connect_th){
        //printf("Add piece (%d %d) to segment %d starting at (%d %d)\n",
          //i,j,k,segments[k].x0,segments[k].y0);
        updateLineStat(&segments[k],i,j,width,max_gap);
        segments[k].invgrad=(double) 
		      (segments[k].xy- segments[k].x*segments[k].y/segments[k].count)
		      /(segments[k].yy-segments[k].y*segments[k].y/segments[k].count);

        if ((segments[k].invgrad>1.0) ||(segments[k].invgrad<-1.0)){
          //printf("segment %d killed by invgrad\n",k);
          segments[k].state=2; //kill anything that exceeds 45 degree
          segments[k].count=0;
        }
    	  segments[k].updated=1;
        segments[k].x1=i;
        segments[k].y1=j;
        seg_updated=seg_updated+1;
        if (width > segments[k].max_width){
          segments[k].max_width = width;
        }
        break;
      }
    }
  }
  if ((seg_updated==0)&&(num_segments<MAX_SEGMENTS)){
    //printf("New segment %d started at:%d,%d\n",num_segments,i,j);
    initStat(&segments[num_segments],i,j);
    num_segments++;
  }
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

  double connect_th = luaL_optnumber(L, 5, 1.4);
  int max_gap = luaL_optinteger(L, 6, 1);
  int min_count = luaL_optinteger(L, 7, 5);

  segment_init();
  // Scan for vertical line pixels:
  //printf("===== VERTICAL =====\n");
  for (int j = 0; j < nj; j++) {
    uint8_t *im_col = im_ptr + ni*j;
    for (int i = 0; i < ni; i++) {
      uint8_t label = *im_col++;
      int width = lineState(label,i);
      if ((width >= widthMin) && (width <= widthMax)) {
	      int iline = i - (width+1)/2;
        addVerticalPixel(iline,j,connect_th,max_gap,width);
      }
    }
    segment_refresh();
  }
  segment_terminate();
  //printf("===== HORIZONTAL =====\n");
  // Scan for horizontal field line pixels:
  for (int i = 0; i < ni; i++) {
    uint8_t *im_row = im_ptr + i;
    for (int j = 0; j < nj; j++) {
      uint8_t label = *im_row;
      im_row += ni;
      int width = lineState(label,j);
      if ((width >= widthMin) && (width <= widthMax)) {
        int jline = j-(width+1)/2;
        addHorizontalPixel(i,jline,connect_th,max_gap,width);
      }

    }
    segment_refresh();
  }

  int valid_segments=0;
  for (int k=0;k<num_segments;k++){
    int dx=segments[k].x1-segments[k].x0;
    int dy=segments[k].y1-segments[k].y0;
    segments[k].length = (double) sqrt(dx*dx+dy*dy);

    if (segments[k].count>min_count){
      valid_segments++;
    }
  }

  lua_createtable(L, valid_segments, 0);

  int seg_count=0;
  for (int k=0;k<num_segments;k++){
    if (segments[k].count>min_count){
      lua_createtable(L, 0, 3);

      // length field
      lua_pushstring(L, "length");
      lua_pushnumber(L, segments[k].length);
      lua_settable(L, -3);

      // average_width field
      lua_pushstring(L, "mean_width");
      lua_pushnumber(L, segments[k].mean_width);
      lua_settable(L, -3);
     
      //x_mean and y_mean
      lua_pushstring(L, "meanpoint");
      lua_createtable(L, 2, 0);
      lua_pushnumber(L, segments[k].xMean);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, segments[k].yMean);
      lua_rawseti(L, -2, 2);
      lua_settable(L, -3);

      // endpoint field
      lua_pushstring(L, "endpoint");
      lua_createtable(L, 4, 0);
      lua_pushnumber(L, segments[k].x0);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, segments[k].x1);
      lua_rawseti(L, -2, 2);
      lua_pushnumber(L, segments[k].y0);
      lua_rawseti(L, -2, 3);
      lua_pushnumber(L, segments[k].y1);
      lua_rawseti(L, -2, 4);
      lua_settable(L, -3);

      lua_rawseti(L, -2, seg_count+1);
      seg_count++;
    }
  }
  return 1;
}





























/*
int lua_field_lines_old(lua_State *L) {
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

  //LineStats bestLine0 = radonTransform.getLineStats();
  //LineStats bestLine[10];
  //bestLine[0]=bestLine0;

  LineStats* bestLine = radonTransform.getMultiLineStats(ni,nj,im_ptr);

  int lines_num=0;
  for (int i=0;i<MAXLINES;i++){
    if (bestLine[i].count>5) lines_num=i;
  }
  
  lua_createtable(L, lines_num, 0);
  for (int i = 0; i < lines_num; i++) {
      lua_createtable(L, 0, 3);

      // count field
      lua_pushstring(L, "count");
      lua_pushnumber(L, bestLine[i].count);
      lua_settable(L, -3);

      // centroid field
      lua_pushstring(L, "centroid");
      double centroidI = bestLine[i].iMean;
      double centroidJ = bestLine[i].jMean;
      lua_createtable(L, 2, 0);
      lua_pushnumber(L, centroidI);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, centroidJ);
      lua_rawseti(L, -2, 2);
      lua_settable(L, -3);

      // endpoint field
      lua_pushstring(L, "endpoint");
      lua_createtable(L, 4, 0);
      lua_pushnumber(L, bestLine[i].iMin);
      lua_rawseti(L, -2, 1);
      lua_pushnumber(L, bestLine[i].iMax);
      lua_rawseti(L, -2, 2);
      lua_pushnumber(L, bestLine[i].jMin);
      lua_rawseti(L, -2, 3);
      lua_pushnumber(L, bestLine[i].jMax);
      lua_rawseti(L, -2, 4);
      lua_settable(L, -3);

      lua_rawseti(L, -2, i+1);
  }

  return 1;
}

*/
