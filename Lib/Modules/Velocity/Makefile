# Makefile used to build Webots files
include ../../Makefile.inc
TARGETS = all clean
.PHONY: $(TARGETS)

#INCLUDES = -I/usr/local/include -I/usr/include -I/usr/include/lua `pkg-config --cflags opencv`
#LIBS = -L/usr/local/lib -L/usr/lib `pkg-config --libs opencv`

all: velocityfilter

%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

velocityfilter: luavelocityfilter.o BallModel.o
	$(CXX) -o $@.$(SHLIBEXT) $(LIBOPTS) $(LIBS) $^

mex:
	mex -O mexBall.cpp BallModel.cpp $(LIBRT)

clean:
	rm -f *.so *.o *.$(SHLIBEXT) *.$(MEXEXT)

