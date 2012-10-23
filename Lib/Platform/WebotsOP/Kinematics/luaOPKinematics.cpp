/* 
  Lua interface to OP Kinematics

  To compile on Mac OS X:
  g++ -arch i386 -o OPKinematics.dylib -bundle -undefined dynamic_lookup luaOPKinematics.pp OPKinematics.cc Transform.cc -lm
*/

#include "OPKinematics.h"

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
  Transform t = darwinop_kinematics_forward_head(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_larm(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_larm(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_rarm(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_rarm(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_lleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_lleg(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int forward_rleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_rleg(&q[0]);
  lua_pushtransform(L, t);
  return 1;
}

static int lleg_torso(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_lleg(&q[0]);
  lua_pushvector(L, position6D(t));
  return 1;
}

static int torso_lleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = inv(darwinop_kinematics_forward_lleg(&q[0]));
  lua_pushvector(L, position6D(t));
  return 1;
}

static int rleg_torso(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = darwinop_kinematics_forward_rleg(&q[0]);
  lua_pushvector(L, position6D(t));
  return 1;
}

static int torso_rleg(lua_State *L) {
  std::vector<double> q = lua_checkvector(L, 1);
  Transform t = inv(darwinop_kinematics_forward_rleg(&q[0]));
  lua_pushvector(L, position6D(t));
  return 1;
}

static int inverse_leg(lua_State *L) {
  std::vector<double> qLeg;
  std::vector<double> pLeg = lua_checkvector(L, 1);
  int leg = luaL_checkint(L, 2);
  double hipYawPitch = 0;
  Transform trLeg = transform6D(&pLeg[0]);
  qLeg = darwinop_kinematics_inverse_leg(trLeg, leg, hipYawPitch);
  lua_pushvector(L, qLeg);
  return 1;
}

static int inverse_legs(lua_State *L) {
  std::vector<double> qLegs;
  std::vector<double> pLLeg = lua_checkvector(L, 1);
  std::vector<double> pRLeg = lua_checkvector(L, 2);
  std::vector<double> pTorso = lua_checkvector(L, 3);
  int leg = 0;
  qLegs = darwinop_kinematics_inverse_legs(&pLLeg[0], 
				      &pRLeg[0],
				      &pTorso[0], leg);
  lua_pushvector(L, qLegs);
  return 1;
}

static int inverse_arm(lua_State *L) {
  std::vector<double> qArm;
  std::vector<double> dArm = lua_checkvector(L, 1);
  qArm = darwinop_kinematics_inverse_arm(&dArm[0]);
  if(qArm[0]==-999)
    lua_pushnil(L);    
  else
    lua_pushvector(L, qArm);
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
  {"inverse_arm", inverse_arm},

  {NULL, NULL}
};

extern "C"
int luaopen_OPKinematics (lua_State *L) {
  luaL_register(L, "OPKinematics", kinematics_lib);
  
  return 1;
}
