/*
  Lua module to provide access to serial ports
*/

#include <unistd.h>
#include <stdlib.h>
#include <termios.h>
#include <fcntl.h>
#include <string.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/stat.h>

#include <IOKit/serial/ioss.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

typedef const struct const_info {
  const char *name;
  int value;
} const_info;

void lua_install_constants(lua_State *L, const_info constants[]) {
  int i;
  for (i = 0; constants[i].name; i++) {
    lua_pushstring(L, constants[i].name);
    lua_pushinteger(L, constants[i].value);
    lua_rawset(L, -3);
  }
}

static int lua_errno(lua_State *L) {
  lua_pushinteger(L, errno);
  return 1;
}

static int lua_openfd(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int oflag = luaL_optinteger(L, 2, O_RDWR|O_NOCTTY|O_NONBLOCK);
  int fd = open(path, oflag);
  if (fd >= 0) {
    // set default termios parameters
    struct termios t;
    if (tcgetattr(fd, &t) == -1)
      return luaL_error(L, "Could not get termios attr.");
    t.c_cflag = CS8 | CLOCAL | CREAD;
    t.c_iflag = IGNPAR;
    t.c_oflag = 0;
    t.c_iflag = 0;
    t.c_cc[VTIME] = 10;
    t.c_cc[VMIN] = 1;

    if (tcsetattr(fd, TCSANOW, &t) == -1)
      return luaL_error(L, "Could not set termios attr.");
    // set default speed
    speed_t speed = 57600;
    if (ioctl(fd, IOSSIOSPEED, &speed) == -1)
      return luaL_error(L, "Could not set speed.");
  }

  lua_pushinteger(L, fd);
  return 1;
}

static int lua_closefd(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int ret = close(fd);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_setspeed(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int speed = luaL_checkinteger(L, 2);
  struct termios t;
  tcgetattr(fd, &t);
  if (cfsetspeed(&t, speed) != 0) {
    return luaL_error(L, "Could not set speed");
  }
  int ret = tcsetattr(fd, TCSANOW, &t);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_setvtime(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int vtime = luaL_checkinteger(L, 2);
  struct termios t;
  tcgetattr(fd, &t);
  t.c_cc[VTIME] = vtime;
  int ret = tcsetattr(fd, TCSANOW, &t);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_setvmin(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int vmin = luaL_checkinteger(L, 2);
  struct termios t;
  tcgetattr(fd, &t);
  t.c_cc[VMIN] = vmin;
  int ret = tcsetattr(fd, TCSANOW, &t);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fcntl(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int cmd = luaL_checkinteger(L, 2);
  int arg = luaL_optinteger(L, 3, 0);
  int ret = fcntl(fd, cmd, arg);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_readfd(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int nbyte = luaL_optinteger(L, 2, 1024);
  char *buf[nbyte];
  int ret = read(fd, buf, nbyte);
  if (ret > 0)
    lua_pushlstring(L, (const char *) buf, ret);
  else if (ret < 0)
    lua_pushinteger(L, ret);
  else
    lua_pushnil(L);

  return 1;
}

static int lua_writefd(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int ret = 0;
  const char *buf;
  size_t len;
  int i;
  for (i = 2; i <= lua_gettop(L); i++) {
    buf = lua_tolstring(L, i, &len);
    ret += write(fd, buf, len);
  }

  lua_pushinteger(L, ret);
  return 1;
}

static const struct luaL_reg serial_lib [] = {
  {"open", lua_openfd},
  {"close", lua_closefd},
  {"errno", lua_errno},
  {"setspeed", lua_setspeed},
  {"setvtime", lua_setvtime},
  {"setvmin", lua_setvmin},
  {"fcntl", lua_fcntl},
  {"read", lua_readfd},
  {"write", lua_writefd},
  {NULL, NULL}
};

static const const_info serial_constants[] = {
  {"O_RDONLY", O_RDONLY},
  {"O_WRONLY", O_WRONLY},
  {"O_RDWR", O_RDWR},
  {"O_NONBLOCK", O_NONBLOCK},
  {"O_APPEND", O_APPEND},
  {"O_CREAT", O_CREAT},
  {"O_NOCTTY", O_NOCTTY},
  {"O_NDELAY", O_NDELAY},
  {"F_GETFL", F_GETFL},
  {"F_SETFL", F_SETFL},
  {"F_DUPFD", F_DUPFD},
  {NULL, 0}
};

int luaopen_serial (lua_State *L) {
  luaL_register(L, "serial", serial_lib);

  lua_install_constants(L, serial_constants);
  return 1;
}
