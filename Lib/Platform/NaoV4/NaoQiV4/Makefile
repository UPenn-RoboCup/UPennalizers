# Makefile used to build libraries
include ../../../Makefile.am

TARGETS = all clean
.PHONY: $(TARGETS)

NaoQiSDK=/usr
NaoQi_INC=-I$(NaoQiSDK)/include
NaoQi_LIB=-L$(NaoQiSDK)/lib -lalmemoryfastaccess

INCLUDES=$(NaoQi_INC)

CXXFLAGS+=-DDEBUG
CXXFLAGS += -std=c++0x
all: luadcm

%.o: src/%.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: src/%.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: src/%.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

luadcm: actuator_process.o dcmprocess.o luadcm.o luafifo.o \
				sensor_process.o shmmap.o shm_util.o
#	$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm -lluajit-5.1 $(NaoQi_LIB)
	$(LD) $(LDFLAGS) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm -llua $(NaoQi_LIB)

clean:
	rm -f *.$(SHLIBEXT) *.o


