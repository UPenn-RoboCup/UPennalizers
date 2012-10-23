CWD= $(shell pwd)

all: controller comm game_control

controller::
	cd Controller && MODE=$(MODE) make && cd $(CWD)

comm::
	cd Comm && MODE=$(MODE) make && cd $(CWD)

game_control::
	cd GameControl && MODE=$(MODE) make && cd $(CWD)

clean::
	cd Controller && make clean && cd $(CWD)
	cd Comm && make clean && cd $(CWD)
#	cd GameControl && make clean && cd$(CWD)


