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
// manage double arrays
%typemap(out) const double * {
  int len, i;
  if (strcmp("$name", "_vec2f") != 0)
    len = 2;
  else if (strcmp("$name", "_sf_rotation") == 0)
    len = 4;
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
