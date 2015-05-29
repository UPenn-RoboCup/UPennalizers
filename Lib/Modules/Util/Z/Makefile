# Makefile used to build libraries
include ../../../Makefile.am

MEXEXT= $(shell mexext)
ZLIB = zlib-src

TARGETS = all clean
.PHONY: $(TARGETS)

SOURCES=\
		lua_z.c \
		$(ZLIB)/deflate.c \
		$(ZLIB)/inflate.c \
		$(ZLIB)/inffast.c \
		$(ZLIB)/inftrees.c \
		$(ZLIB)/trees.c \
		$(ZLIB)/adler32.c \
		$(ZLIB)/crc32.c \
		$(ZLIB)/zutil.c

OBJECTS=$(SOURCES:.c=.o)

#all: serialize deserialize zlibCompress zlibUncompress z
all: Z

serialize:
	mex -O $@.c
	
deserialize:
	mex -O $@.c 
	
zlibCompress: deflate.o adler32.o crc32.o trees.o zutil.o
	mex -O $@.cc $^

zlibUncompress: inflate.o inffast.o inftrees.o adler32.o crc32.o zutil.o
	mex -O $@.cc $^ 

Z: $(OBJECTS)
	@echo "\t" LINK $@
	@$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm $(LUA_LIB)

clean:
	rm -f *.$(MEXEXT) *.$(SHLIBEXT) *.o $(ZLIB)/*.o

