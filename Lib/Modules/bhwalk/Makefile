## Makefile Method for making BHuman Walk from nbites
## Stephen McGill, Apr 2014
## <smcgill3@seas.upenn.edu>

ifndef OSTYPE 
	OSTYPE = $(shell uname -s|awk '{print tolower($$0)}')
endif

CXX=g++

BH_SOURCES=\
					 MotionSelector.cpp \
					 WalkingEngine.cpp \
					 WalkingEngineKick.cpp \
					 Modules/Sensing/TorsoMatrixProvider.cpp \
					 Modules/Sensing/RobotModelProvider.cpp \
					 Modules/Sensing/FallDownStateDetector.cpp \
					 Modules/Sensing/GroundContactDetector.cpp \
					 Modules/Sensing/InertiaSensorCalibrator.cpp \
					 Modules/Sensing/InertiaSensorFilter.cpp \
					 Modules/Sensing/InertiaSensorInspector.cpp \
					 Modules/Sensing/JointFilter.cpp \
					 Modules/Sensing/SensorFilter.cpp \
					 Representations/Sensing/RobotModel.cpp \
					 Representations/MotionControl/MotionSelection.cpp \
					 Platform/BHAssert.cpp \
					 Platform/File.cpp \
					 Tools/Global.cpp \
					 Tools/Enum.cpp \
					 Tools/Math/Matrix.cpp \
					 Tools/Math/Pose2D.cpp \
					 Tools/Math/RotationMatrix.cpp \
					 Tools/Streams/InOut.cpp \
					 Tools/Streams/InStreams.cpp \
					 Tools/Streams/OutStreams.cpp \
					 Tools/Streams/StreamHandler.cpp \
					 Tools/Streams/Streamable.cpp \
					 Tools/Configuration/ConfigMap.cpp \
					 Tools/Configuration/ConfigMapParser.cpp
					 
#					 Modules/Infrastructure/NaoProvider.cpp
#					 Platform/SystemCall.cpp
#					 Representations/MotionControl/BikeRequest.cpp
#					 Representations/MotionControl/MotionRequest.cpp

BH_OBJECTS=$(BH_SOURCES:.cpp=.o)

CXXFLAGS= \
					-c -g \
					-fpic \
					-I. \
					-DRELEASE
#	-fno-stack-protector -fomit-frame-pointer
#	-pedantic -Wall -Wno-unused-function -Wno-unknown-pragmas
#	-march=native -mtune=native -O3
#-std=c++11

ifeq ($(OSTYPE),darwin)
	LD=ld -macosx_version_min 10.8
	LDFLAGS= \
					 -undefined dynamic_lookup \
					 -lm \
					 -L/usr/local/lib
	CXX=clang++
	SHLIBEXT=dylib
else
	LD=g++
	LDFLAGS=-shared -fpic -lm -lrt
	SHLIBEXT=so
endif

all: bhwalk

.cpp.o:
	$(CXX) $(CXXFLAGS) $< -o $@

lua_bhwalk.o:
	$(CXX) $(CXXFLAGS) -I/usr/local/include lua_bhwalk.cpp -o lua_bhwalk.o

install:
	cp libbhwalk.$(SHLIBEXT) /usr/local/lib
	mkdir -p /usr/local/share/bhwalk
	cp -r config /usr/local/share/bhwalk/

clean:
	rm -f $(BH_OBJECTS)
	rm -f *.so *.o

ifeq ($(OSTYPE),darwin)
	# OSX linking and installation
	# Mach-O means BUNDLE for lua loading, DYLIB for linking (2 diff files...)
	# GCC is -dynamiclib, clang is -dylib for the DYLIB
	# lua loads .so files, dylib files are linked

libbhwalk: $(BH_OBJECTS)
	$(LD) -dylib $^ $(LDFLAGS) -o $@.dylib

bhwalk: lua_bhwalk.o
	$(LD) -bundle $^ $(LDFLAGS) -lbhwalk -o $@.so

else
	# Linux linking and installation

libbhwalk: $(BH_OBJECTS)
	$(LD) $^ $(LDFLAGS) -o $@.so

bhwalk: lua_bhwalk.o
	$(LD) $^ $(LDFLAGS) -lbhwalk -o $@.so

endif
