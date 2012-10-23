include ../../../Makefile.inc

all: launcher

CWD= $(shell pwd)
CHAIN= $(CTCDIR)

CXXFLAGS=-O1 -fpic

%.o: %.cc
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.cpp
	$(CXX) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<
%.o: %.c
	$(CC) $(CXXFLAGS) $(INCLUDES) -o $@ -c $<

launcher: lualauncher.o
	$(CXX) -o $@.$(SHLIBEXT) $(LIBOPTS) $^ $(LIBRT)


cross:
ifeq ($(CHAIN),)
	@echo Cross compilitation tool not specified. \
				Please download the ctc tool from \
				the aldebaran website and follow the \
				instructions to configure it for your system.
else
	rm -rf build
	mkdir build
	cd build && cmake -DCMAKE_TOOLCHAIN_FILE="$(CHAIN)/toolchain-atom.cmake" .. \
		&& make && cd $(CWD)
endif

clean:
	rm -rf build 
	rm -f *.o *.$(SHLIBEXT) *.$(MEXEXT)
