/**
 * Lua module to control usb missile launcher
 * 
 * compatible with Dream Cheeky - Thunder model
 */

#ifdef __cplusplus
extern "C"
{
#endif
  #include "lua.h"
  #include "lualib.h"
  #include "lauxlib.h"
#ifdef __cplusplus
}
#endif

#include <usb.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

#define VID 0x2123
#define PID 0x1010

#define DOWN_CMD    {0x02, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
#define UP_CMD      {0x02, 0x02, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
#define LEFT_CMD    {0x02, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
#define RIGHT_CMD   {0x02, 0x08, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
#define FIRE_CMD    {0x02, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}
#define STOP_CMD    {0x02, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}

char downCmdBuf[]   = DOWN_CMD;
char upCmdBuf[]     = UP_CMD;
char leftCmdBuf[]   = LEFT_CMD;
char rightCmdBuf[]  = RIGHT_CMD;
char fireCmdBuf[]   = FIRE_CMD;
char stopCmdBuf[]   = STOP_CMD;

usb_dev_handle *launcher;

static int connect_launcher() {
  printf("acquiring usb devices...");
  struct usb_bus *busses;
  int ret;

  usb_init();
  usb_find_busses();
  usb_find_devices();
  busses = usb_get_busses();

  printf("done\n");

  struct usb_bus *bus;
  for (bus = busses; bus; bus = bus->next) {
    struct usb_device *dev;

    for (dev = bus->devices; dev; dev = dev->next) {
      //printf("VID = 0x%x :: PID = 0x%x\n", dev->descriptor.idVendor, dev->descriptor.idProduct);
      // is this the device we are looking for?
      if (dev->descriptor.idVendor == VID && dev->descriptor.idProduct == PID) {
        printf("opening usb device %x:%x...", VID, PID);
        launcher = usb_open(dev);
        printf("done\n");

        printf("reseting device...");
        ret = usb_reset(launcher);
        if (ret < 0) {
          printf("failed to reset device (%d:%s)\n", ret, strerror(errno));
          return -1;
        }
        printf("done\n");

        printf("claiming usb device...");
        ret = usb_claim_interface(launcher, 0);
        if (ret < 0) {
          printf("failed to claim device (%d:%s)...", ret, strerror(errno));

          printf("detaching kernel driver...");
          ret = usb_detach_kernel_driver_np(launcher, 0);
          if (ret < 0) {
            printf("failed to detach driver (%d:%s)\n", ret, strerror(errno));
            return -1;
          }

          printf("reclaiming usb device...");
          ret = usb_claim_interface(launcher, 0);
          if (ret < 0) {
            printf("failed to reclaim device (%d:%s)\n", ret, strerror(errno));
            return -1;
          }
        } 
        printf("done\n");

        printf("setting alternate interface...");
        ret = usb_set_altinterface(launcher, 0);
        if (ret < 0) {
          printf("failed to set interface (%d:%s)\n", ret, strerror(errno));
          return -1;
        }
        printf("done\n");

        return 0;
      }
    }
  }

  printf("no usb device with VID = %d found\n", VID);
  
  return -1;
}

static int lua_launcherdown(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, downCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 1;
}

static int lua_launcherup(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, upCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 1;
}

static int lua_launcherleft(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, leftCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 1;
}

static int lua_launcherright(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, rightCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 1;
}

static int lua_launcherfire(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, fireCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 0;
}

static int lua_launcherstop(lua_State *L) {

  int ret = usb_control_msg(launcher, 0x21, 0x09, 0, 0, stopCmdBuf, 8, 100);
  if (ret < 0) {
    printf("failed to send usb control message (%d:%s)\n", ret, strerror(errno));
  }

  lua_pushinteger(L, ret);

  return 1;
}

static const struct luaL_reg launcher_lib [] = {
  {"down", lua_launcherdown},
  {"up", lua_launcherup},
  {"left", lua_launcherleft},
  {"right", lua_launcherright},
  {"fire", lua_launcherfire},
  {"stop", lua_launcherstop},

  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_launcher (lua_State *L) {
  luaL_register(L, "launcher", launcher_lib);
  
  return connect_launcher();
}

