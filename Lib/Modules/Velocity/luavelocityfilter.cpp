#include "luavelocityfilter.h"

const double MIN_ERROR_DISTANCE = 50;
const double ERROR_DEPTH_FACTOR = 0.08;
const double ERROR_ANGLE = 3*PI/180;

#ifdef PREDICT
#if MODEL==1
static CvBoost *boost;
#elif MODEL==2
static CvDTree *ddtree;
#elif MODEL==3
static CvRTrees *rtrees;
#else
static CvSVM *svm;
#endif

static CvDTree *ddtree_dir;

#endif

static int lua_get_ball(lua_State *L) {

  static BallModel bm; // Keep the model of the ball static

  double xObject = lua_tonumber(L, 1);
  double yObject = lua_tonumber(L, 2);
  double uncertainty = lua_tonumber(L, 3);

  double distance = sqrt(xObject*xObject+yObject*yObject);
  double angle = atan2(-xObject, yObject);

  double errorDepth = ERROR_DEPTH_FACTOR*(distance+MIN_ERROR_DISTANCE);
  double errorAzimuthal = ERROR_ANGLE*(distance+MIN_ERROR_DISTANCE);

  Gaussian2d objGaussian;
  objGaussian.setMean(xObject, yObject);
  objGaussian.setCovarianceAxis(errorAzimuthal, errorDepth, angle);

  bm.BallObservation(objGaussian, (int)(uncertainty));

  double x,y,vx,vy,ex,evx;
  bm.getBall( x, y, vx, vy, ex, evx);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  lua_pushnumber(L, vx);
  lua_pushnumber(L, vy);
  lua_pushnumber(L, ex);
  lua_pushnumber(L, evx);

  return 6;
}

#ifdef PREDICT
static int lua_loadmodel( lua_State *L ){
  // Load the model that made from training
  #if MODEL==1
  boost->load("./boostmodel.xml");
  #elif MODEL==2
  ddtree->load("./ddtreemodel.xml");
  #elif MODEL==3
  rtrees->load("./rtreemodel.xml");
  #else
  svm->load("./svmmodel.xml");
  #endif

  ddtree_dir->load("./ddtreemodel_dir.xml");

  return 0;
}

static int lua_predict( lua_State *L ){
  // Grab the user parameters
  double x = lua_tonumber(L, 1); // Current x
  double y = lua_tonumber(L, 2); // Current y
  double vx = lua_tonumber(L, 3); // Current x velocity
  double vy = lua_tonumber(L, 4); // Current y velocity
  double ep = lua_tonumber(L, 5); // Position uncertainty
  double evp = lua_tonumber(L, 6); // Velocity uncertainty
  double th = lua_tonumber(L, 7); // Velocity uncertainty
  double vth = lua_tonumber(L, 8); // Velocity uncertainty
  double px = lua_tonumber(L, 9);
  double py = lua_tonumber(L, 10);
  double pth = lua_tonumber(L, 11); // Velocity uncertainty

  double r = sqrt(x*x+y*y);
  double vr = sqrt(vx*vx+vy*vy);
  double pr = sqrt(px*px+py*py);

  // Set up the 8 paramter sample Matrix
  // Can I send an array to do this faster, though?
  // training_data = [obs_ep(range) obs_evp(range) obs_th(range) obs_pr(range) obs_pth(range) hit_range(range)];

  // training_data_dir = [obs_x(hit_range) obs_y(hit_range) obs_vx(hit_range) obs_vy(hit_range) obs_ep(hit_range) obs_evp(hit_range) obs_th(hit_range) obs_vth(hit_range) obs_r(hit_range) obs_vr(hit_range) obs_px(hit_range) obs_py(hit_range) obs_pr(hit_range) obs_pth(hit_range) th_diff(hit_range) dodge_dir];
  CvMat* sample = cvCreateMat( 1, 5, CV_32FC1 );
  cvmSet(sample,0,0,ep);
  cvmSet(sample,0,1,evp);
  cvmSet(sample,0,2,th);
  cvmSet(sample,0,3,pr);
  cvmSet(sample,0,4,pth);

  CvMat* sample2 = cvCreateMat( 1, 15, CV_32FC1 );
  cvmSet(sample2,0,0,x);
  cvmSet(sample2,0,1,y);
  cvmSet(sample2,0,2,vx);
  cvmSet(sample2,0,3,vy);
  cvmSet(sample2,0,4,ep);
  cvmSet(sample2,0,5,evp);
  cvmSet(sample2,0,6,th);
  cvmSet(sample2,0,7,vth);
  cvmSet(sample2,0,8,r);
  cvmSet(sample2,0,9,vr);
  cvmSet(sample2,0,10,px);
  cvmSet(sample2,0,11,py);
  cvmSet(sample2,0,12,pr);
  cvmSet(sample2,0,13,pth);
  cvmSet(sample2,0,14,pth-th);


  // Predict a move
  #if MODEL==1
  double p = boost->predict( sample );
  #elif MODEL==2
  double p = ddtree->predict( sample )->value;
  #elif MODEL==3
  double p = rtrees->predict( sample );
  #else
  double p = svm->predict( sample );
  #endif

  // Predict direction (only if should dodge
  double pdir = 0;
  if(p==1){
    pdir = ddtree_dir->predict( sample2 )->value;
    if( pdir == 0 )
      pdir = -1;
  }

  lua_pushnumber(L, p);
//  lua_pushnumber(L, pdir);

  // Free the sample that we created
  cvReleaseMat( &sample );
  cvReleaseMat( &sample2 );
  return 1;
}

#endif


static const struct luaL_reg velocityfilter_lib [] = {
  {"get_ball", lua_get_ball},
#ifdef PREDICT
  {"loadModel", lua_loadmodel},
  {"predictmove", lua_predict},
#endif
  {NULL, NULL}
};

extern "C"
int luaopen_velocityfilter (lua_State *L) {
  luaL_register(L, "velocityfilter", velocityfilter_lib);
  #ifdef PREDICT
  #if MODEL==1
  boost = new CvBoost;
  #elif MODEL==2
  ddtree = new CvDTree;
  #elif MODEL==3
  rtrees = new CvRTrees;
  #else
  svm = new CvSVM;
  #endif
  ddtree_dir = new CvDTree;
  #endif
  return 1;
}

