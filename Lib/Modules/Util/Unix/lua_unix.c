/*
  Lua module to provide some standard Unix functions
*/

#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <dirent.h>
#include <sys/time.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/utsname.h>
#include <string.h>
#include <math.h>

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

static int lua_usleep(lua_State *L) {
  int usec = luaL_checkint(L, 1);
  int ret = usleep((useconds_t) usec);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_sleep(lua_State *L) {
  int sec = luaL_checkint(L, 1);
  int ret = sleep(sec);
  lua_pushinteger(L, ret);
  return 1;
}

static int lua_uname(lua_State *L) {
	struct utsname unameData;
	uname(&unameData);
	lua_pushstring(L,unameData.sysname);
	return 1;
}

static int lua_gethostname(lua_State *L) {
  int mlen = 124;
  char hostname[mlen];

  int ret = gethostname(hostname, mlen);
  if (ret == 0) {
    int len = strlen((const char *)hostname);
    lua_pushlstring(L, (const char *)hostname, len);
  } else if (ret < 0) {
    lua_pushinteger(L, ret);
  } else {
    lua_pushnil(L);
  }

  return 1;
}

static int lua_getcwd(lua_State *L) {
  char *path = getcwd(NULL, 0);
  if (path == NULL) {
    lua_pushnil(L);
    return 1;
  }

  lua_pushstring(L, path);
  free(path);
  return 1;
}

static int lua_chdir(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int ret = chdir(path);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_readdir(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  DIR *dirp = opendir(path);
  struct dirent *dp;
  int i = 0;
  lua_createtable(L, 2, 0); // should at least contain "." and ".."
  while ((dp = readdir(dirp)) != NULL) {
    lua_pushstring(L, dp->d_name);
    lua_rawseti(L, -2, ++i);
  }
  closedir(dirp);

  return 1;
}

static int lua_time(lua_State *L) {
  struct timeval t;
  gettimeofday(&t, NULL);

  lua_pushnumber(L, t.tv_sec + 1E-6*t.tv_usec);
  return 1;
}

static int lua_time_ms(lua_State *L) {
	// Answer is in milliseconds
	// Used for BHuman code
#ifdef __APPLE__
  struct timeval t;
  gettimeofday(&t, NULL);
	lua_pushinteger(L, t.tv_sec * 1000 + t.tv_usec / 1000l);
#else
	struct timespec ts;
	clock_gettime(CLOCK_MONOTONIC, &ts);
	lua_pushinteger(L, ts.tv_sec * 1000 + ts.tv_nsec / 1000000l);
#endif
  return 1;
}

static int lua_openfd(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int oflag = luaL_optinteger(L, 2, O_RDONLY);
  int ret = open(path, oflag);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_closefd(lua_State *L) {
  int fd = luaL_checkinteger(L, 1);
  int ret = close(fd);

  lua_pushinteger(L, ret);
  return 1;
}


// Definition of LUA_FILEHANDLE should be in lualib.h
//#define LUA_FILEHANDLE "FILE*"
static int lua_fdopen(lua_State *L) {
  int fd = luaL_checkint(L, 1);
  const char *mode = luaL_optstring(L, 2, "r");

  FILE **pf = (FILE **)lua_newuserdata(L, sizeof(FILE *));
  *pf = fdopen(fd, mode);
  if (*pf != NULL) {
    luaL_getmetatable(L, LUA_FILEHANDLE);
    lua_setmetatable(L, -2);
  } else {
    lua_pushnil(L);
  }

  return 1;
}

static int lua_chmod(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int mode = luaL_checkinteger(L, 2);
  int ret = chmod(path, mode);

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
  size_t len;
  const char *buf;

  int i;
  for (i = 2; i <= lua_gettop(L); i++) {
    buf = lua_tolstring(L, i, &len);
    ret += write(fd, buf, len);
  }

  // TODO: flush immediately?

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_select(lua_State *L) {
  int i;
  int status;
  int fd = 0, nfds = 0, maxfd = 0;

  fd_set fds;
  FD_ZERO(&fds);

  luaL_checktype(L, 1, LUA_TTABLE);
#if LUA_VERSION_NUM == 502
	nfds = lua_rawlen(L, 1);
#else
  nfds = lua_objlen(L, 1);
#endif

  for (i = 1; i <= nfds; i++) {
    lua_rawgeti(L, 1, i);
    fd = luaL_checkinteger(L, -1);
    lua_pop(L, 1);
    maxfd = fd > maxfd ? fd : maxfd;
    FD_SET(fd, &fds);
  }

  if (lua_isnumber(L, 2)) {
    double timeout = lua_tonumber(L, 2);
    struct timeval tv = {
      floor(timeout),
      (timeout - floor(timeout))*1E6
    };
    status = select(maxfd + 1, &fds, 0, 0, &tv);
  }
  else {
    status = select(maxfd + 1, &fds, 0, 0, NULL);
  }
  lua_pushinteger(L, status);

  lua_createtable(L, 0, nfds);
  for (i = 1; i <= nfds; i++) {
    lua_rawgeti(L, 1, i);
    fd = luaL_checkinteger(L, -1);
    lua_pushboolean(L, FD_ISSET(fd, &fds));
    lua_settable(L, -3);
  }
  return 2;
}

static int lua_mkfifo(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int mode = luaL_checkinteger(L, 2);
  int ret = mkfifo(path, mode);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_unlink(lua_State *L) {
  const char *path = luaL_checkstring(L, 1);
  int ret = unlink(path);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_system(lua_State *L) {
  const char *command = luaL_checkstring(L, 1);
  int ret = system(command);

  lua_pushinteger(L, ret);
  return 1;
}

static int lua_fork(lua_State *L) {
  const char *command = luaL_checkstring(L,1);

  int pid = fork();
  if (pid == 0) {
    // Child process
    char *argv[4];
    argv[0] = "sh";
    argv[1] = "-c";
    argv[2] = (char *)command;
    argv[3] = 0;
    execv("/bin/sh", argv);
    exit(-1);
  }

  lua_pushinteger(L, pid);
  return 1;
}


static const struct luaL_Reg unix_lib [] = {
  {"usleep", lua_usleep},
  {"sleep", lua_sleep},
  {"uname", lua_uname},
  {"gethostname", lua_gethostname},
  {"getcwd", lua_getcwd},
  {"chdir", lua_chdir},
  {"readdir", lua_readdir},
  {"time", lua_time},
  {"time_ms", lua_time_ms},
  {"open", lua_openfd},
  {"close", lua_closefd},
  {"fdopen", lua_fdopen},
  {"read", lua_readfd},
  {"write", lua_writefd},
  {"select", lua_select},
  {"chmod", lua_chmod},
  {"fcntl", lua_fcntl},
  {"unlink", lua_unlink},
  {"mkfifo", lua_mkfifo},
  {"system", lua_system},
  {"fork", lua_fork},
  {NULL, NULL}
};

static const const_info unix_constants[] = {
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

int luaopen_unix (lua_State *L) {

#if LUA_VERSION_NUM == 502
	  luaL_newlib(L, unix_lib);
#else
  luaL_register(L, "unix", unix_lib);
#endif

  lua_install_constants(L, unix_constants);
  return 1;
}
