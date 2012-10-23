COMMON_DIR = ../Common
INCLUDES   = -I$(COMMON_DIR)


LIBDIRS = -L$(VIS_DIR)/Vis -L../../CircularBuffer

EXECUTABLES = testGateway testDynamixelGateway getIMU getIMU2


all: $(EXECUTABLES)


testGateway: testGateway.cc SerialDevice.o DynamixelPacket.o
	g++ -Wall -o $@ $^ $(INCLUDES)

testDynamixelGateway: testDynamixelGateway.cc SerialDevice.o DynamixelPacket.o DynamixelGateway.o
	g++ -Wall -o $@ $^ $(INCLUDES)
	
getIMU: getIMU.cc SerialDevice.o DynamixelPacket.o DynamixelGateway.o
	g++ -Wall -o $@ $^ $(INCLUDES)
	
getIMU2: getIMU2.cc SerialDevice.o DynamixelPacket.o DynamixelGateway2.o dynamixel_instruction.o
	g++ -Wall -o $@ $^ $(INCLUDES)

DynamixelPacket.o: $(COMMON_DIR)/DynamixelPacket.c
	g++ -c -Wall -fPIC $^
	
dynamixel_instruction.o: ../../Common/dynamixel_instruction.cpp
	g++ -c -Wall -fPIC $^

%.o : %.cc
	g++ -c -Wall -fPIC $^ $(INCLUDES)

%.o : %.c
	g++ -c -Wall -fPIC $^


clean:
	rm -rf *.o $(EXECUTABLES) $(MEX_FILES) *~
