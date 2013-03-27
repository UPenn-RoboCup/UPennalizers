MEXEXT= $(shell mexext)

all: zmq

include ../../../Lib/Makefile.inc

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<

zmq:
	mex -O $@.cc -lzmq -L/usr/local/lib -I/usr/local/include

clean:
	rm -f *.$(MEXEXT) *.$(SHLIBEXT) *.o
