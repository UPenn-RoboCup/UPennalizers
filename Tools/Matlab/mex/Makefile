include ../../../Lib/Makefile.am
MATLAB=matlab -nosplash -nodesktop -nojvm -nodisplay
MATMEX=mex
MATLAB_V = ""
MEX=$(MATMEX) -O -I/usr/local/include -L/usr/local/lib
MEXEXT=$(shell mexext)
PWD=$(shell pwd)
LIBRT= $(shell [ `uname` != "Darwin" ] && echo "-lrt")

TARGETS=rgbselect time mexshm getch udp_recv udp_send cjpeg djpeg msgpack zmq ImageProc Planner tcpopen mexlua

.PHONY: all clean  $(TARGETS)

all: $(TARGETS)

15a: MATMEX=/Applications/MATLAB_R2015a.app/bin/mex
15a: MATLAB_V=15a
15a: all

15b: MATMEX=/Applications/MATLAB_R2015b.app/bin/mex
15b: MATLAB_V=15b
15b: all


14a: MATMEX=/Applications/MATLAB_R2014a.app/bin/mex
14a: MATLAB_V=14a
14a: all

14b: MATMEX=/Applications/MATLAB_R2014b.app/bin/mex
14b: MATLAB_V=14b
14b: all

13a: MATMEX=/Applications/MATLAB_R2013a.app/bin/mex
13a: MATLAB_V=13a
13a: all

13b: MATMEX=/Applications/MATLAB_R2013b.app/bin/mex
13b: MATLAB_V=13b
13b: all 


rgbselect:
	$(MEX) $@.cc

mexlua:
	$(MEX) $@.cc $(INCLUDES) $(LIBOPTS)-lm $(LUA_LIB)

time:
	$(MEX) $@.cc

mexshm:
	$(MEX) $@.cc $(LIBRT)

getch:
	$(MEX) $@.c

udp_send:
	$(MEX) $@.cc
udp_recv:
	$(MEX) $@.cc
	
cjpeg:
	$(MEX) $@.cc -ljpeg

djpeg:
	$(MEX) $@.cc -ljpeg

zmq:	
	$(MEX) $@.cc -lzmq
	
ImageProc:
	@echo "Building ImageProc"
	cd ImageProc && make $(MATLAB_V) && cd $(PWD)

Planner:
	@echo "Building Planner"
	cd Planner && make $(MATLAB_V) && cd $(PWD)
	
msgpack:
	$(MEX) $@.cc -lmsgpack
	
tcpopen:
	$(MEX) $@.c
	
# Platform dependent modules
serialopen:
	$(MEX) $@.c	
uvc:
	$(MEX) $@.cc
	
test:
	@echo "Testing matlab scripts!"
	$(MATLAB) -r "run_tests"
	@echo "Done!"

clean:
	rm -f *.$(MEXEXT) *.o
	@cd ImageProc && make clean && cd $(PWD)
	@cd Planner && make clean && cd $(PWD)
