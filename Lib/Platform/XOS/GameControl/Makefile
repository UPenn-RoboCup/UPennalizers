# Makefile used to build libraries
include ../../../Makefile.am

TARGETS = all clean
.PHONY: $(TARGETS)

LIBNAME=XOSGameControlReceiver

all: game_control_receiver

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

game_control_receiver: luaXOSGameControlReceiver.o timeScalar.o
	$(LD) $(LDFLAGS) -o $(LIBNAME).$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm

clean:
	rm -f *.$(SHLIBEXT) *.o
