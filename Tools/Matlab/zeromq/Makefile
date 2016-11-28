MEXEXT= $(shell mexext)
MATMEX = mex
MEX = $(MATMEX)

all: zmq

14a: MATMEX=/Applications/MATLAB_R2014a.app/bin/mex
14a: all

14b: MATMEX=/Applications/MATLAB_R2014b.app/bin/mex
14b: all


13a: MATMEX=/Applications/MATLAB_R2013a.app/bin/mex
13a: all

13b: MATMEX=/Applications/MATLAB_R2013b.app/bin/mex
13b: all 

include ../../../Lib/Makefile.am

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ -c $<

zmq:
	$(MEX) -O $@.cc -lzmq -L/usr/local/lib -I/usr/local/include

clean:
	rm -f *.$(MEXEXT) *.$(SHLIBEXT) *.o
