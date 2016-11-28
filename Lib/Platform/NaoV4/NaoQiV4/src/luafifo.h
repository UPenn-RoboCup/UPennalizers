#ifndef luafifo_h_DEFINED
#define luafifo_h_DEFINED

#define fifoInputName "/tmp/dcmluaFIFO"

void *luafifo_dlopen_hack();

int luafifo_open();
int luafifo_doread();
int luafifo_dostring(const char *buf);
int luafifo_dofile(const char *name);
int luafifo_pcall(const char *fname);
int luafifo_close();

#endif
