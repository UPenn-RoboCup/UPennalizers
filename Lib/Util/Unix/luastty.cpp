/* 
  Lua module to set termios characteristics
*/

#include <stdio.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <errno.h>

#ifdef __APPLE__
#include <IOKit/serial/ioss.h>
#else
#include <linux/serial.h>
#endif

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

#define LUA_FILEHANDLE "FILE*"
#define tofilep(L) ((FILE **)luaL_checkudata(L, 1, LUA_FILEHANDLE))

static int pushresult (lua_State *L, int i, const char *name) {
  int en = errno;
  if (i) {
    lua_pushboolean(L, 1);
    return 1;
  }
  else {
    lua_pushnil(L);
    if (name)
      lua_pushfstring(L, "%s:%s", name, strerror(en));
    else
      lua_pushfstring(L, "%s", strerror(en));
    lua_pushinteger(L, en);
    return 3;
  }
}

int lua_tofd(lua_State *L, int narg) {
  int ftype = lua_type(L, narg);
  switch (ftype) {
  case LUA_TNUMBER:
    return luaL_checkint(L, narg);
    break;
  case LUA_TUSERDATA:
    FILE **fp = (FILE **)luaL_checkudata(L, narg, LUA_FILEHANDLE);
    if (*fp != NULL)
      return fileno(*fp);
    break;
  }
  return -1;
}

static int lua_stty_raw(lua_State *L) {
  int fd = lua_tofd(L, 1);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }
  cfmakeraw(&tio);

  int ret = tcsetattr(fd, TCSANOW, &tio);
  return pushresult(L, ret, NULL);
}

static int lua_stty_sane(lua_State *L) {
  int fd = lua_tofd(L, 1);

  struct termios tio;
  bzero(&tio, sizeof(tio));
  tio.c_cflag = CS8 | CREAD | HUPCL;
  tio.c_iflag = ICRNL | IXON | IXANY | IMAXBEL | BRKINT;
  tio.c_oflag = OPOST | ONLCR;
  tio.c_lflag = ICANON | ISIG | IEXTEN | ECHO | ECHOE | ECHOKE | ECHOCTL;
  tio.c_cc[VEOF] = 4; // ctrl-d
  tio.c_cc[VINTR] = 3; // ctrl-c
  tio.c_cc[VMIN] = 1; // Min number of characters
  tio.c_cc[VTIME] = 0; // TIME*0.1s

  cfsetispeed(&tio, B9600);
  cfsetospeed(&tio, B9600);

  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }

  return 0;
}

static int lua_stty_serial(lua_State *L) {
  int fd = lua_tofd(L, 1);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }

  tio.c_cflag = B57600 | CS8 | CLOCAL | CREAD;
  tio.c_iflag = IGNPAR;
  tio.c_oflag = 0;
  tio.c_iflag = 0;
  tio.c_cc[VTIME] = 0;
  tio.c_cc[VMIN] = 0;

  /*
  if (cfsetspeed(&tio, B57600) != 0) {
    return luaL_error(L, "Could not set speed");
  }
  */

  if (tcflush(fd, TCIFLUSH) != 0)
    return luaL_error(L, "Could not flush termios");
  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }

  return 0;
}

static int lua_stty_speed(lua_State *L) {
  int fd = lua_tofd(L, 1);
  int speed = luaL_checkint(L,2);

#ifdef __APPLE__
  if (ioctl(fd, IOSSIOSPEED, &speed) == -1)
    return luaL_error(L, "Could not set speed.");
#else
  // Default termios interface
  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }
  if (cfsetspeed(&tio, speed) != 0) {
    return luaL_error(L, "Could not set speed");
  }
  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }

  // For linux:
  struct serial_struct serinfo;
  if (ioctl(fd, TIOCGSERIAL, &serinfo) < 0)
    return luaL_error(L, "Could not get serial info.");
  serinfo.flags &= ~ASYNC_SPD_MASK;
  serinfo.flags |= ASYNC_SPD_CUST;
  serinfo.custom_divisor = serinfo.baud_base/((float)speed);
  if (ioctl(fd, TIOCSSERIAL, &serinfo) < 0)
    return luaL_error(L, "Could not set serial info.");

#endif

  return 0;
}

static int lua_stty_min(lua_State *L) {
  int fd = lua_tofd(L, 1);
  int min = luaL_checkint(L,2);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }

  tio.c_cc[VMIN] = min; // Min number of characters

  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }
  return 0;
}

static int lua_stty_time(lua_State *L) {
  int fd = lua_tofd(L, 1);
  int time = luaL_checkint(L,2);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }

  tio.c_cc[VTIME] = time; // Max time in 0.1 sec

  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }
  return 0;
}

static int lua_stty_echo(lua_State *L) {
  int fd = lua_tofd(L, 1);
  int flag = lua_toboolean(L,2);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }

  if (flag) {
    tio.c_lflag |= ECHO;
  }
  else {
    tio.c_lflag &= ~ECHO;
  }

  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }
  return 0;
}

static int lua_stty_clocal(lua_State *L) {
  int fd = lua_tofd(L, 1);
  int flag = lua_toboolean(L,2);

  struct termios tio;
  if (tcgetattr(fd, &tio) != 0) {
    return luaL_error(L, "Could not get termios");
  }

  if (flag) {
    tio.c_cflag |= CLOCAL;
  }
  else {
    tio.c_cflag &= ~CLOCAL;
  }

  if (tcsetattr(fd, TCSANOW, &tio) != 0) {
    return luaL_error(L, "Could not set termios");
  }
  return 0;
}

static const struct luaL_reg stty_lib [] = {
  {"raw", lua_stty_raw},
  {"sane", lua_stty_sane},
  {"serial", lua_stty_serial},
  {"speed", lua_stty_speed},
  {"min", lua_stty_min},
  {"time", lua_stty_time},
  {"echo", lua_stty_echo},
  {"clocal", lua_stty_clocal},
  {NULL, NULL}
};

extern "C"
int luaopen_stty (lua_State *L) {
  luaL_register(L, "stty", stty_lib);
  
  return 1;
}
