/*
   Lua BHuman Wrapper
   (c) 2014 Stephen McGill
   */
#include <lua.hpp>
#include "WalkingEngine.h"

static WalkingEngine walkingEngine;

const float INITIAL_BODY_POSE_ANGLES[] =
{
  1.57f, 0.18f, -1.56f, -0.18f,
  0.0f, 0.0f, -0.39f, 0.76f, -0.37f, 0.0f,
  0.0f, 0.0f, -0.39f, 0.76f, -0.37f, 0.0f,
  1.57f, -0.18f, 1.43f, 0.23f
};

static int luaBH_get_motion_request (lua_State *L) {
  lua_pushnumber(L, walkingEngine.theMotionRequest.motion);
  return 1;
}

static int luaBH_stand_request (lua_State *L) {
  MotionRequest motionRequest;
  motionRequest.motion = MotionRequest::stand;
  walkingEngine.theMotionRequest = motionRequest;
  return 0;
}

static int luaBH_walk_request (lua_State *L) {
  MotionRequest motionRequest;
  motionRequest.motion = MotionRequest::walk;
  // Check WalkRequest for more options than speedMode
  motionRequest.walkRequest.mode = WalkRequest::speedMode;
  // Take in the speed in mm/s, rad/s
  motionRequest.walkRequest.speed.translation.x = luaL_checknumber(L, 1);
  motionRequest.walkRequest.speed.translation.y = luaL_checknumber(L, 2);
  motionRequest.walkRequest.speed.rotation = luaL_checknumber(L, 3);
  // Unsure of this, but from code comment:
  // Allows to disable the step size stabilization. set it 
  // when precision is indispensable.
  // NOTE: I will set to false for now
  //motionRequest.walkRequest.pedantic = true;
  motionRequest.walkRequest.pedantic = false;
  // Set the request
  walkingEngine.theMotionRequest = motionRequest;
  return 0;
}

static int luaBH_should_reset (lua_State *L) {
  lua_pushboolean(L, walkingEngine.shouldReset);
  return 1;
}

static int luaBH_is_leaving_possible (lua_State *L) {
  lua_pushboolean(L, walkingEngine.walkingEngineOutput.isLeavingPossible);
  return 1;
}

static int luaBH_is_calibrated (lua_State *L) {
  lua_pushboolean(L, walkingEngine.theInertiaSensorData.calibrated);
  return 1;
}

static int luaBH_get_hand_speeds (lua_State *L) {
  lua_pushnumber(L, walkingEngine.leftHandSpeed);
  lua_pushnumber(L, walkingEngine.rightHandSpeed);
  return 2;
}

static int luaBH_get_odometry (lua_State *L) {
  /*
  lua_pushnumber(L, walkingEngine.theOdometryData.translation.x);
  lua_pushnumber(L, walkingEngine.theOdometryData.translation.y);
  lua_pushnumber(L, walkingEngine.theOdometryData.rotation);
  return 3;
  */
  lua_createtable(L, 3, 0);
  lua_pushnumber(L, walkingEngine.theOdometryData.translation.x);
  lua_rawseti(L, -2, 1);
  lua_pushnumber(L, walkingEngine.theOdometryData.translation.y);
  lua_rawseti(L, -2, 2);
  lua_pushnumber(L, walkingEngine.theOdometryData.rotation);
  lua_rawseti(L, -2, 3);

  return 1;
}

static int luaBH_update (lua_State *L) {
	unsigned int t = luaL_checkinteger(L, 1);
  walkingEngine.update(t);
  return 0;
}


static int luaBH_set_sensor_angles (lua_State *L) {
  // Assume we are given a table
  if(lua_type(L, 1) != LUA_TTABLE){
    return luaL_error(L,"Need a table!");
  }
  if( lua_objlen(L, 1) != JointData::numOfJoints){
    return luaL_error(L, "Need %d joints!", JointData::numOfJoints);
  }

  JointData& bh_joint_data = walkingEngine.theJointData;
  for (int i = 0; i < JointData::numOfJoints; i++) {
    lua_rawgeti(L, 1, i+1);
    bh_joint_data.angles[i] = lua_tonumber(L, -1);
    lua_pop(L, 1); // previous value
  }

  return 0;
}

static int luaBH_set_sensor_currents (lua_State *L) {
  // Assume we are given a table
  if(lua_type(L, 1) != LUA_TTABLE){
    return luaL_error(L,"Need a table!");
  }
  if( lua_objlen(L, 1) != JointData::numOfJoints){
    return luaL_error(L, "Need %d joints!", JointData::numOfJoints);
  }

  SensorData& bh_sensors = walkingEngine.theSensorData;
  for (int i = 0; i < JointData::numOfJoints; i++) {
    lua_rawgeti(L, 1, i+1);
    bh_sensors.currents[i] = lua_tonumber(L, -1);
    lua_pop(L, 1); // previous value
  }

  return 0;
}

static int luaBH_set_sensor_gyro (lua_State *L) {
  SensorData& bh_sensors = walkingEngine.theSensorData;
  bh_sensors.data[SensorData::gyroX] = luaL_checknumber(L, 1);
  bh_sensors.data[SensorData::gyroY] = luaL_checknumber(L, 2);
  return 0;
}

static int luaBH_set_sensor_acc (lua_State *L) {
  SensorData& bh_sensors = walkingEngine.theSensorData;
  bh_sensors.data[SensorData::accX] = luaL_checknumber(L, 1);
  bh_sensors.data[SensorData::accY] = luaL_checknumber(L, 2);
  bh_sensors.data[SensorData::accZ] = luaL_checknumber(L, 3);
  return 0;
}

static int luaBH_set_sensor_lfsr (lua_State *L) {
  SensorData& bh_sensors = walkingEngine.theSensorData;
  bh_sensors.data[SensorData::fsrLFL] = luaL_checknumber(L, 1);
  bh_sensors.data[SensorData::fsrLFR] = luaL_checknumber(L, 2);
  bh_sensors.data[SensorData::fsrLBL] = luaL_checknumber(L, 3);
  bh_sensors.data[SensorData::fsrLBR] = luaL_checknumber(L, 4);
  return 0;
}

static int luaBH_set_sensor_rfsr (lua_State *L) {
  SensorData& bh_sensors = walkingEngine.theSensorData;
  bh_sensors.data[SensorData::fsrRFL] = luaL_checknumber(L, 1);
  bh_sensors.data[SensorData::fsrRFR] = luaL_checknumber(L, 2);
  bh_sensors.data[SensorData::fsrRBL] = luaL_checknumber(L, 3);
  bh_sensors.data[SensorData::fsrRBR] = luaL_checknumber(L, 4);
  return 0;
}

static int luaBH_get_joint_angles (lua_State *L) {
  // Make the table
  lua_createtable(L, JointData::numOfJoints, 0);
  for(int i = 0; i < JointData::numOfJoints; ++i) {
    float j = walkingEngine.joint_angles[i];
    lua_pushnumber(L, j);
    lua_rawseti(L, -2, i+1);
  }
  return 1;
}

static int luaBH_get_joint_hardnesses (lua_State *L) {
  // Make the table
  lua_createtable(L, JointData::numOfJoints, 0);
  for(int i = 0; i < JointData::numOfJoints; ++i) {
    float j = walkingEngine.joint_hardnesses[i];
    lua_pushnumber(L, j);
    lua_rawseti(L, -2, i+1);
  }
  return 1;
}

static const struct luaL_Reg bhwalk_lib [] = {
  {"get_motion_request", luaBH_get_motion_request},
  {"is_leaving_possible", luaBH_is_leaving_possible},
  {"is_calibrated", luaBH_is_calibrated},
  {"get_hand_speeds", luaBH_get_hand_speeds},
  {"get_odometry", luaBH_get_odometry},
  {"update", luaBH_update},
  {"get_joint_angles", luaBH_get_joint_angles},
  {"get_joint_hardnesses", luaBH_get_joint_hardnesses},
  {"set_sensor_angles", luaBH_set_sensor_angles},
  {"set_sensor_currents", luaBH_set_sensor_currents},
  {"stand_request", luaBH_stand_request},
  {"walk_request", luaBH_walk_request},
  {NULL, NULL}
};

extern "C" int luaopen_bhwalk(lua_State *L) {
#if LUA_VERSION_NUM == 502
  luaL_newlib(L, bhwalk_lib);
#else
  luaL_register(L, "bhwalk", bhwalk_lib);
#endif
  return 1;
}
