CWD= $(shell pwd)
CTC= $(NaoqiCTC)

all: naoqi 

naoqi:
ifeq ($(CTC),)
	@echo Cross compilitation tool not specified. \
				Please download the ctc tool from \
				the aldebaran website and follow the \
				instructions to configure it for your system
else
	rm -rf build
	mkdir build
	cd build && cmake -DCMAKE_TOOLCHAIN_FILE="$(CTC)/toolchain-atom.cmake" .. \
		&& make && cd $(CWD)
endif

clean:
	rm -rf build
