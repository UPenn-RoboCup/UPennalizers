/* 
  Lua interface to Nao Kinematics

  To compile on Mac OS X:
  g++ -arch i386 -o luaNaoKinematics.dylib -bundle -undefined dynamic_lookup luaNaoKinematics.cc naoKinematics.cc Transform.cc -lm
*/

#include "naoKinematics.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

#ifdef __cplusplus
}
#endif


static void lua_pushvector(lua_State *L, std::vector<double> v) {
  int n = v.size();
  lua_createtable(L, n, 0);
  for (int i = 0; i < n; i++) {
    lua_pushnumber(L, v[i]);
    lua_rawseti(L, -2, i+1);
  }
}

static std::vector<double> lua_checkvector(lua_State *L, int narg) {
  if (!lua_istable(L, narg))
    luaL_typerror(L, narg, "vector");
  int n = lua_objlen(L, narg);
  std::vector<double> v(n);
  for (int i = 0; i < n; i++) {
    lua_rawgeti(L, narg, i+1);
    v[i] = lua_tonumber(L, -1);
    lua_pop(L, 1);
  }
  return v;
}

static void lua_pushtransform(lua_State *L, Transform t) {
  lua_createtable(L, 4, 0);
  for (int i = 0; i < 4; i++) {
    lua_createtable(L, 4, 0);
    for (int j = 0; j < 4; j++) {
      lua_pushnumber(L, t(i,j));
      lua_rawseti(L, -2, j+1);
    }
    lua_rawseti(L, -2, i+1);
  }
}


static int forward_head(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_head(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_larm(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_larm(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_rarm(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_rarm(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_lleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_lleg(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_rleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_rleg(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int lleg_torso(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_lleg(&q[0]);
  lua_pushvector(L, position6D(t));
  return 1;
}

static int torso_lleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = inv(nao_kinematics_forward_lleg(&q[0]));
  lua_pushvector(L, position6D(t));
  return 1;
}

static int rleg_torso(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = nao_kinematics_forward_rleg(&q[0]);
  lua_pushvector(L, position6D(t));
  return 1;
}

static int torso_rleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = inv(nao_kinematics_forward_rleg(&q[0]));
  lua_pushvector(L, position6D(t));
  return 1;
}

static int inverse_leg(lua_State *L) {
  std::vector<double> qLeg;
  std::vector<double> pLeg = lua_checkvector(L, 1);
  int leg = luaL_checkint(L, 2);
  double hipYawPitch = luaL_optnumber(L, 3, 1.0);
  Transform trLeg = transform6D(&pLeg[0]);
  qLeg = nao_kinematics_inverse_leg(trLeg, leg, hipYawPitch);
  lua_pushvector(L, qLeg);
  return 1;
}

static int inverse_legs(lua_State *L) {
  std::vector<double> qLegs;
  std::vector<double> pLLeg = lua_checkvector(L, 1);
  std::vector<double> pRLeg = lua_checkvector(L, 2);
  std::vector<double> pTorso = lua_checkvector(L, 3);
  int leg = luaL_checkint(L, 4);
  qLegs = nao_kinematics_inverse_legs(&pLLeg[0], 
				      &pRLeg[0],
				      &pTorso[0], leg);
  lua_pushvector(L, qLegs);
  return 1;
}


std::vector<double> inverse_legs_heeltoe_offset(
  const double *pLLeg,const double *pRLeg,const double *pTorso,
  double leftTilt,double rightTilt,
  const double *qLLegNow,const double *qRLegNow
  ){

  Transform trLLeg = transform6D(&pLLeg[0]);
  Transform trRLeg = transform6D(&pRLeg[0]);
  Transform trTorso = transform6D(&pTorso[0]);
  Transform trTorso_LLeg = inv(trTorso)*trLLeg;
  Transform trTorso_RLeg = inv(trTorso)*trRLeg;

  double qLAnkle = qLLegNow[4];
  double qRAnkle =qRLegNow[4];

  std::vector<double> qLLeg;
  std::vector<double> qRLeg;



  if (leftTilt<0.0) 
    qLLeg = nao_kinematics_inverse_leg_toelift(trTorso_LLeg,LEG_LEFT,qLAnkle,-leftTilt);
  else{
   if (leftTilt>0.0) 
     qLLeg = nao_kinematics_inverse_leg_heellift(trTorso_LLeg,LEG_LEFT,qLAnkle,leftTilt);
   else{
    if(trTorso_LLeg(0,3)>trTorso_RLeg(0,3))
      qLLeg = nao_kinematics_inverse_leg_toelift(trTorso_LLeg,LEG_LEFT,qLAnkle,leftTilt);
    else
      qLLeg = nao_kinematics_inverse_leg_heellift(trTorso_LLeg,LEG_LEFT, qLAnkle,leftTilt) ;
    }
  }

  if (rightTilt<0.0) 
    qRLeg = nao_kinematics_inverse_leg_toelift(trTorso_RLeg,LEG_RIGHT,qRAnkle,-rightTilt);
  else{
    if (rightTilt>0.0) 
      qRLeg = nao_kinematics_inverse_leg_heellift(trTorso_RLeg,LEG_RIGHT,qRAnkle,rightTilt);
    else{
      if(trTorso_LLeg(0,3)>trTorso_RLeg(0,3))       
        qRLeg = nao_kinematics_inverse_leg_heellift(trTorso_RLeg,LEG_RIGHT,qRAnkle,rightTilt);
      else
        qRLeg = nao_kinematics_inverse_leg_toelift(trTorso_RLeg,LEG_RIGHT, qRAnkle,rightTilt);
    }
  }
  std::vector<double> qLeg(12); 
  for (int i=0;i<6;i++){
    qLeg[i]=qLLeg[i];
    qLeg[i+6]=qRLeg[i];
  }   
  return qLeg;
}






static int inverse_legs_heeltoe(lua_State *L) {
  std::vector<double> pLLeg = lua_checkvector(L, 1);
  std::vector<double> pRLeg = lua_checkvector(L, 2);
  std::vector<double> pTorso = lua_checkvector(L, 3);
  std::vector<double> qLLeg = lua_checkvector(L, 4);
  std::vector<double> qRLeg = lua_checkvector(L, 5);  
  double leftTilt = luaL_optnumber(L, 6, 0.0);
  double rightTilt = luaL_optnumber(L, 7, 0.0);
  std::vector<double> qLLegNew(6); 
  std::vector<double> qRLegNew(6); 
  std::vector<double> com; 
  double offsetX = 0.0;
  double offsetY = 0.0;
  int i;

  std::vector<double> pTorsoNew(6);
  for (i=0;i<6;i++) pTorsoNew[i]=pTorso[i];
  std::vector<double> qLeg;
  double errX, errY;

  for (int iter=0;iter<5;iter++){

    pTorsoNew[0]=pTorso[0]+offsetX*cos(pTorso[5]);
    pTorsoNew[1]=pTorso[1]+offsetY*sin(pTorso[5]);
    qLeg=inverse_legs_heeltoe_offset(
      &pLLeg[0],&pRLeg[0],&pTorsoNew[0],leftTilt,rightTilt,
      &qLLeg[0],&qRLeg[0]
    );
    for (i=0;i<6;i++){
      qLLegNew[i]=qLLeg[i];
      qRLegNew[i]=qRLeg[i+6];
    }   
    com = nao_kinematics_calculate_com_positions(&qLLegNew[0],&qRLegNew[0]);
    errX = offsetX + (com[0]/com[3]);
    errY = offsetY + (com[1]/com[3]);
    offsetX = offsetX-0.5*errX;
    offsetY = offsetY-0.5*errY;
  }

//  printf("Com Err: %.3f %.3f  Offset: %.4f %.4f \n", errX, errY, offsetX, offsetY);
    
  lua_pushvector(L, qLeg);  
  return 1;
}



static int calculate_com_positions(lua_State *L) { 
  std::vector<double> qLArm = lua_checkvector(L, 1);
  std::vector<double> qRArm = lua_checkvector(L, 2);
  std::vector<double> qLLeg = lua_checkvector(L, 3);
  std::vector<double> qRLeg = lua_checkvector(L, 4);
  std::vector<double> qHead = lua_checkvector(L, 5);  
  std::vector<double> r = nao_kinematics_calculate_com_positions(
    &qLArm[0],&qRArm[0],&qLLeg[0],&qRLeg[0],&qHead[0]);
  lua_pushvector(L, r);
  return 1;
}









static const struct luaL_reg kinematics_lib [] = {
  {"forward_head", forward_head},
  {"forward_larm", forward_larm},
  {"forward_rarm", forward_rarm},
  {"forward_lleg", forward_lleg},
  {"forward_rleg", forward_rleg},
  {"lleg_torso", lleg_torso},
  {"torso_lleg", torso_lleg},
  {"rleg_torso", rleg_torso},
  {"torso_rleg", torso_rleg},
  {"inverse_leg", inverse_leg},
  {"inverse_legs", inverse_legs},
  {"inverse_legs_heeltoe", inverse_legs_heeltoe},
  {"calculate_com_positions",calculate_com_positions},

  {NULL, NULL}
};

extern "C"
int luaopen_NaoKinematics (lua_State *L) {
  luaL_register(L, "kinematics", kinematics_lib);
  
  return 1;
}
