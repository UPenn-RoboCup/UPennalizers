/*
  g++ -arch i386 -I/usr/local/include luafifo.cc -llua -ldl
*/

#include "luafifo.h"

#include <string.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>

// Header to open Lua symbols globally
#include <dlfcn.h>

extern "C"
{
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
}

lua_State *L;
static int fdInput = -1;

//extern int luaL_typerror();

void *luafifo_dlopen_hack() {
  // NaoQi seems to load with RTLD_GLOBAL disabled.
  // In order for lua to dynamically load modules,
  // we need to manually import the liblua library here.
  return dlopen("liblua.so", RTLD_NOW|RTLD_GLOBAL);
}


int luafifo_open() {
 fprintf(stdout, "Starting lua...");
 L = luaL_newstate();

 luaL_openlibs(L);

 fprintf(stdout, "done\n");

 fprintf(stdout, "Opening FIFO...");
 unlink(fifoInputName);
 if (mkfifo(fifoInputName, 0666) != 0) {
   fprintf(stderr, "Could not make FIFO: %s\n", fifoInputName);
   return 1;
 }

 fdInput = open(fifoInputName, O_RDONLY|O_NONBLOCK);
 if (fdInput < 0) {
   fprintf(stderr, "Could not open FIFO\n");
   return 1;
 }
 fprintf(stdout, "done\n");

 return 0;
}

int luafifo_doread() {
  const int buflen = 1024;
  static char buf[buflen+1];
  static int nbuf = 0;

  int nread = read(fdInput, buf+nbuf, buflen-nbuf);
  if (nread > 0) {
    nbuf += nread;
    if ((nbuf == buflen) ||
	(buf[nbuf-1] == '\n') ||
	(buf[nbuf-1] == '\r')) {
      buf[nbuf] = 0;
      luafifo_dostring(buf);
      nbuf = 0;
    }
  }

  return nread;
}

int luafifo_dostring(const char *buf) {
  int ret = luaL_dostring(L, buf);
  if (ret > 0) {
    fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
  }
  return ret;
}

int luafifo_dofile(const char *name) {
  int ret = luaL_dofile(L, name);
  if (ret > 0) {
    fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
  }
  return ret;
}

int luafifo_pcall(const char *fname) {
  lua_getfield(L, LUA_GLOBALSINDEX, fname);
  if (lua_isnil(L, -1)) {
    lua_pop(L, 1);
    return 0;
  }
  return lua_pcall(L, 0, 0, 0);
}

int luafifo_close() {
 close(fdInput);
 unlink(fifoInputName);

 lua_close(L);
 return 0;
}
