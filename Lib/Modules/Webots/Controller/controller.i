/*
  Swig interface which maps Webots C API into a Lua module
*/

%module controller

%{
#include <webots/types.h>

#include <webots/accelerometer.h>
#include <webots/camera.h>
#include <webots/compass.h>
#include <webots/connector.h>
#include <webots/differential_wheels.h>
#include <webots/display.h>
#include <webots/distance_sensor.h>
#include <webots/emitter.h>
#include <webots/gps.h>
#include <webots/gyro.h>
#include <webots/led.h>
#include <webots/light_sensor.h>
#include <webots/microphone.h>
#include <webots/nodes.h>
#include <webots/pen.h>
#include <webots/radio.h>
#include <webots/receiver.h>
#include <webots/robot.h>
#include <webots/servo.h>
#include <webots/speaker.h>
#include <webots/supervisor.h>
#include <webots/touch_sensor.h>
%}

%include <webots/types.h>

%{
#include <string.h>
%}

%{
int match_suffix(char *str1, char* str2) {
  int i, match = 1;
  size_t len1 = strlen(str1);
  size_t len2 = strlen(str2);
  if (len1 >= len2) {
    for (i = 1; i <= len2; i++)
      match = match & (str1[len1-i] == str2[len2-i]);
    return match;
  }
  return 0;
}
%}


// manage double arrays
%typemap(out) const double * {
  int i, len;
  if (match_suffix("$name", "_vec2f"))
    len = 2;
  else if (match_suffix("$name", "_sf_rotation"))
    len = 4;
  else if (match_suffix("$name", "_orientation"))
    len = 9;
  else
    len = 3;
  lua_createtable(L, len, 0);
  for (i = 0; i < len; i++) {
    lua_pushnumber(L, $1[i]);
    lua_rawseti(L, -2, i+1);
  }
  SWIG_arg++;
}

%include <webots/accelerometer.h>


// Camera: unsigned char array
%typemap(out) unsigned char * {
  lua_pushlightuserdata(L, $1);
  SWIG_arg++;
}
%include <webots/camera.h>
%typemap(out) unsigned char *;

%include <webots/compass.h>
%include <webots/connector.h>
%include <webots/differential_wheels.h>
%include <webots/display.h>
%include <webots/distance_sensor.h>

// Emitter:
%typemap(in) (const void *data, int size) {
  size_t len;
  $1 = (void *) lua_tolstring(L, $input, &len);
  $2 = len;
}
%include <webots/emitter.h>
%typemap(in) (const void *data, int size);

%include <webots/gps.h>
%include <webots/gyro.h>
%include <webots/led.h>
%include <webots/light_sensor.h>
%include <webots/microphone.h>
%include <webots/nodes.h>
%include <webots/pen.h>
%include <webots/radio.h>

# Receiver:
%typemap(out) const void * {
  lua_pushlstring(L, (const char*) $1, wb_receiver_get_data_size(arg1));
  SWIG_arg++;
}
%include <webots/receiver.h>
%typemap(out) const void *;

%include <webots/robot.h>
%include <webots/servo.h>
%include <webots/speaker.h>
%include <webots/supervisor.h>
%include <webots/touch_sensor.h>
