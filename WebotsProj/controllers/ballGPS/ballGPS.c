#include <webots/robot.h>

// Added a new include file
#include <stdio.h>
#include <string.h>
#include <webots/gps.h>
#include <webots/emitter.h>

int main(int argc, char **argv)
{
  wb_robot_init();
  int time_step = wb_robot_get_basic_time_step();

  WbDeviceTag gps = wb_robot_get_device("GPS");
  wb_gps_enable(gps, time_step);
  WbDeviceTag emitter = wb_robot_get_device("emitter");
  wb_emitter_set_channel(emitter,13);

  double* gps_value;
  char message[32];

  while (wb_robot_step(time_step) != -1){
   gps_value = wb_gps_get_values(gps);
   //Something's wrong with deserialization 
   //So we make a fixed width string here
   sprintf(message,"{%0.3f,%0.3f}",gps_value[0]/2+5.0,-gps_value[2]/2+5.0);
   wb_emitter_send(emitter,message,strlen(message)+1);
//   printf("%s\n",message);
  }
  wb_robot_cleanup();
  return 0;
}
