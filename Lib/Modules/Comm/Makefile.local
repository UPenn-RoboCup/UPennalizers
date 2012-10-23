# Makefile used to build libraries
include ../../Makefile.inc

TARGETS = all clean
.PHONY: $(TARGETS)

all: comm 

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

comm: luaComm.o 
	$(LD) $(LDFLAGS) -o Comm.$(SHLIBEXT) $(LIBOPTS) $^ $(LIB_DIR) -lm

clean:
	rm -f *.$(SHLIBEXT) *.o
