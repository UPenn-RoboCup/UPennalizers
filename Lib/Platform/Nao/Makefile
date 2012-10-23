CWD= $(shell pwd)

all: body camera kinematics game_control

body:
	cd Body && make && cd $(CWD)

camera:
	cd Camera && make && cd $(CWD)

kinematics:
	cd Kinematics && make && cd $(CWD)

game_control:
	cd GameControl && make && cd $(CWD)

clean:
	cd Body && make clean && cd $(CWD)
	cd Camera && make clean && cd $(CWD)
	cd Kinematics && make clean && cd $(CWD)
	cd GameControl && make clean && cd $(CWD)

