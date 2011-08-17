/* 
  Lua interface to DCM shared memory
*/

#include "luadcm.h"
#include "luafifo.h"
#include "shmmap.h"
#include <vector>

static void lua_pushdouble_array(lua_State *L, double *v, int n) {
  lua_createtable(L, n, 0);
  for (int i = 0; i < n; i++) {
    lua_pushnumber(L, v[i]);
    lua_rawseti(L, -2, i+1);
  }
}

static void lua_pushvector(lua_State *L, std::vector<double> &v) {
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

static int set_actuator_mode(lua_State *L) {
  int mode = luaL_checkint(L, 1);
  pActuator->mode = mode;
  return 0;
}

static int set_actuator_position(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->position[index] = x;
  return 0;
}

static int set_actuator_hardness(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->hardness[index] = x;
  return 0;
}

static int set_actuator_command(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->command[index] = x;
  return 0;
}

static int set_actuator_velocity(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->velocity[index] = x;
  return 0;
}

static int set_actuator_joint_imu_angle_x(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->jointImuAngleX[index] = x;
  return 0;
}

static int set_actuator_joint_imu_angle_y(lua_State *L) {
  double x = luaL_checknumber(L, 1);
  int index = luaL_checkint(L, 2) - 1; // convert to zero-indexed
  pActuator->jointImuAngleY[index] = x;
  return 0;
}

static int get_actuator_position(lua_State *L) {
  int index = luaL_checkint(L, 1) - 1; // convert to zero-indexed
  lua_pushnumber(L, pActuator->position[index]);
  return 1;
}

static int get_actuator_hardness(lua_State *L) {
  int index = luaL_checkint(L, 1) - 1; // convert to zero-indexed
  lua_pushnumber(L, pActuator->hardness[index]);
  return 1;
}

static int get_actuator_command(lua_State *L) {
  int index = luaL_checkint(L, 1) - 1; // convert to zero-indexed
  lua_pushnumber(L, pActuator->command[index]);
  return 1;
}

static int get_actuator_velocity(lua_State *L) {
  int index = luaL_checkint(L, 1) - 1; // convert to zero-indexed
  lua_pushnumber(L, pActuator->velocity[index]);
  return 1;
}

static int set_actuator_positions(lua_State *L) {
  std::vector<double> v = lua_checkvector(L, 1);
  int index = luaL_optint(L, 2, 1) - 1;
  for (unsigned int i = 0; i < v.size(); i++) {
    pActuator->position[index+i] = v[i];
  }
  return 0;
}

static int set_actuator_hardnesses(lua_State *L) {
  std::vector<double> v = lua_checkvector(L, 1);
  int index = luaL_optint(L, 2, 1) - 1;
  for (unsigned int i = 0; i < v.size(); i++) {
    pActuator->hardness[index+i] = v[i];
  }
  return 0;
}

static int get_actuator_hardnesses(lua_State *L) {
  lua_pushdouble_array(L, pActuator->hardness, nJoint);
  return 1;
}

static int get_sensor_position(lua_State *L) {
  int index = luaL_checkint(L, 1) - 1; // convert to zero-indexed
  lua_pushnumber(L, pSensor->position[index]);
  return 1;
}

static int get_sensor_positions(lua_State *L) {
  lua_pushdouble_array(L, pSensor->position, nJoint);
  return 1;
}

static int get_imu_angle(lua_State *L) {
  lua_pushdouble_array(L, pSensor->imu, 2);
  return 1;
}

static int get_imu_acc(lua_State *L) {
  lua_pushdouble_array(L, pSensor->imu+2, 3);
  return 1;
}

static int get_imu_gyr(lua_State *L) {
  lua_pushdouble_array(L, pSensor->imu+5, 3);
  return 1;
}


static const struct luaL_reg dcm_lib [] = {
  {"set_actuator_mode", set_actuator_mode},
  {"set_actuator_position", set_actuator_position},
  {"set_actuator_hardness", set_actuator_hardness},
  {"set_actuator_command", set_actuator_command},
  {"set_actuator_velocity", set_actuator_velocity},
  {"set_actuator_joint_imu_angle_x", set_actuator_joint_imu_angle_x},
  {"set_actuator_joint_imu_angle_y", set_actuator_joint_imu_angle_y},
  {"get_actuator_position", get_actuator_position},
  {"get_actuator_hardness", get_actuator_hardness},
  {"get_actuator_command", get_actuator_command},
  {"get_actuator_velocity", get_actuator_velocity},

  {"set_actuator_positions", set_actuator_positions},
  {"set_actuator_hardnesses", set_actuator_hardnesses},
  {"get_actuator_hardnesses", get_actuator_hardnesses},

  {"get_sensor_position", get_sensor_position},
  {"get_sensor_positions", get_sensor_positions},

  {"get_imu_angle", get_imu_angle},
  {"get_imu_acc", get_imu_acc},
  {"get_imu_gyr", get_imu_gyr},

  {NULL, NULL}
};

extern "C"
int luaopen_luadcm (lua_State *L) {
  luaL_register(L, "dcm", dcm_lib);

  return 1;
}
