# Makefile used to build Webots files

TARGETS = all clean
.PHONY: $(TARGETS)

include ../../../Makefile.inc

WEBOTS_INCLUDE_DIR = $(WEBOTS_HOME)/include
WEBOTS_LIB_DIR = $(WEBOTS_HOME)/lib

all: controller

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -I$(WEBOTS_INCLUDE_DIR) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -I$(WEBOTS_INCLUDE_DIR) -I$(WEBOTS_INCLUDE_DIR)/controller/c -o $@ -c $<

controller_wrap.c: controller.i
	swig -lua -I$(WEBOTS_HOME)/include/controller/c controller.i

controller: controller_wrap.o
	$(LD) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ -L$(WEBOTS_LIB_DIR) -lController 

clean:
	rm -f controller.$(SHLIBEXT) *.o *.so controller_wrap.c
