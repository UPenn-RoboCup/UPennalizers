CWD= $(shell pwd)

all: controller comm game_control

controller::
	cd Controller && make && cd $(CWD)

comm::
	cd Comm && make && cd $(CWD)

game_control::
	cd GameControl && make && cd $(CWD)

clean::
	cd Controller && make clean && cd $(CWD)
	cd Comm && make clean && cd $(CWD)
