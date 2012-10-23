module(... or "", package.seeall)

require('unix')
webots = false;
darwin = false;

-- mv up to Player directory
unix.chdir('~/Player');

local cwd = unix.getcwd();
-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, "WebotsController") then
  webots = true;
  cwd = cwd.."/Player"
  package.path = cwd.."/?.lua;"..package.path;
end

computer = os.getenv('COMPUTER') or "";
if (string.find(computer, "Darwin")) then
   -- MacOS X uses .dylib:
   package.cpath = cwd.."/Lib/?.dylib;"..package.cpath;
else
   package.cpath = cwd.."/Lib/?.so;"..package.cpath;
end

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path;
package.path = cwd.."/Motion/Walk/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/BodyFSM/?.lua;"..package.path;
package.path = cwd.."/HeadFSM/?.lua;"..package.path;

require('Config')
require('shm')
require('vector')
require('Motion')
require('walk')
require('Body')
require("getch")
require('kick')
require('Speak')
require('PoseFilter')
require('World')
--require('Team')
--require('battery')
Vision = require 'vcm' -- Steve
Speak.talk("Starting test parameters.")

--World.entry();
--Team.entry();

-- initialize state machines
Motion.entry();
--Motion.sm:set_state('stance');

walk.stop();
getch.enableblock(1);
targetvel=vector.new({0,0,0});
headangle=vector.new({0,0});

parameters = true

walkKick=true;

--Adding head movement && vision...--
Body.set_head_hardness({0.4,0.4});

Motion.fall_check=0; --auto getup disabled

instructions = " Key commands \n 7:sit down 8:stand up 9:walk\n i/j/l/,/h/; :control walk velocity\n k : walk in place\n [, ', / :Reverse x, y, / directions\n 1/2/3/4 :kick\n w/a/s/d/x :control head\n t/T :alter walk speed\t f/F :alter step phase\t r/R :alter step height\t c/C :alter supportX\t v/V :alter supportY \t q/Q: alter footY\t y/Y: alter bodyHeight\t u/U: alter bodyTilt\n "; 
-- main loop
print(instructions);
local tUpdate = unix.time();
local count=0;
local countInterval=1000;
count_dcm=0;
t0=unix.time();
init = false;
calibrating = false;
ready = false;
calibrated=false;

function update()

  count = count + 1;
  
	if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
      
    elseif (ready) then
    --[[
      -- initialize state machines
      package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;
      require('BodyFSM')
      require('HeadFSM')
      require('GameFSM')

      BodyFSM.entry();
      HeadFSM.entry();
      GameFSM.entry();
      
      if( webots ) then
        BodyFSM.sm:add_event('button');
      end
			--]]
      init = true;
    else
      if (count % 20 == 0) then
        if calibrated==false then
          Speak.talk('Calibrating');
          calibrating = true;
          calibrated=true;
        elseif (Body.get_change_role() == 1) then
          smindex = (smindex + 1) % #Config.fsm.body;
        end
      end

      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end
  end

  t=unix.time();
  Motion.update();
  Body.set_head_hardness(0.2);
  --battery.monitor();

  local str=getch.get();
  if #str>0 then
	local byte=string.byte(str,1);
  if byte==string.byte("\t") then
    parameters=not parameters;
    if parameters then
      instructions = " Key commands \n 7:sit down 8:stand up 9:walk\n i/j/l/,/h/; :control walk velocity\n k : walk in place\n [, ', / :Reverse x, y, / directions\n 1/2/3/4 :kick\n w/a/s/d/x :control head\n t/T :alter walk speed\t f/F :alter step phase\t r/R :alter step height\t c/C :alter supportX\t v/V :alter supportY\n b/B :alter foot sensor threshold \t n/N :alter delay time.\n 3/4/5 :turn imu feedback/joint encoder feedback/foot sensor feedback on or off."; 
    else
      instructions = " Key commands \n 7:sit down 8:stand up 9:walk\n i/j/l/,/h/; :control walk velocity\n k : walk in place\n [, ', / :Reverse x, y, / directions\n 1/2/3/4 :kick\n w/a/s/d/x :control head\n y/u/o/p :alter alpha\t q/e/r/t :alter gain\t c/v/b/n :alter deadband\t Letter to decrease, Shift+letter to increase\n z/Z :adjust odom X\t g/G :adjust odom Y\t m/M :adjust odom angle\t #:Reset pose to center";
    end

  end

  if parameters then
    if byte==string.byte("i") then		
			targetvel[1]=targetvel[1]+0.01;
		elseif byte==string.byte("j") then	
			targetvel[3]=targetvel[3]+0.1;
		elseif byte==string.byte("k") then	
			targetvel[1],targetvel[2],targetvel[3]=0,0,0;
		elseif byte==string.byte("l") then	
			targetvel[3]=targetvel[3]-0.1;
		elseif byte==string.byte(",") then	
			targetvel[1]=targetvel[1]-0.01;
		elseif byte==string.byte("h") then	
			targetvel[2]=targetvel[2]+0.01;
		elseif byte==string.byte(";") then	
			targetvel[2]=targetvel[2]-0.01;
		elseif byte==string.byte("[") then
			targetvel[1]=-targetvel[1];
		elseif byte==string.byte("'") then
			targetvel[2]=-targetvel[2];
		elseif byte==string.byte("/") then
			targetvel[3]=-targetvel[3];

		--Move the head around--
		elseif byte==string.byte("w") then
			headangle[2]=headangle[2]-5*math.pi/180;
		elseif byte==string.byte("a") then	
			headangle[1]=headangle[1]+5*math.pi/180;
		elseif byte==string.byte("s") then	
			headangle[1],headangle[2]=0,0;
		elseif byte==string.byte("d") then	
			headangle[1]=headangle[1]-5*math.pi/180;
		elseif byte==string.byte("x") then	
			headangle[2]=headangle[2]+5*math.pi/180;

		--Change configuration params in real time--
    elseif byte==string.byte("u") then
      Config.walk.bodyTilt = Config.walk.bodyTilt - math.pi/180
    elseif byte==string.byte("U") then
      Config.walk.bodyTilt = Config.walk.bodyTilt + math.pi/180
		elseif byte==string.byte("t") then
			Config.walk.tStep = Config.walk.tStep - .01;
		elseif byte==string.byte("T") then
			Config.walk.tStep = Config.walk.tStep + .01;
		elseif byte==string.byte("f") then
			Config.walk.phSingle[1] = Config.walk.phSingle[1] - .01;
			Config.walk.phSingle[2] = Config.walk.phSingle[2] + .01;
		elseif byte==string.byte("F") then
			Config.walk.phSingle[1] = Config.walk.phSingle[1] + .01;
			Config.walk.phSingle[2] = Config.walk.phSingle[2] - .01;
		elseif byte==string.byte("r") then
			Config.walk.stepHeight = Config.walk.stepHeight - .001;
		elseif byte==string.byte("R") then
			Config.walk.stepHeight = Config.walk.stepHeight + .001;
		elseif byte==string.byte("c") then
			Config.walk.supportX = Config.walk.supportX - .001;
		elseif byte==string.byte("C") then
			Config.walk.supportX = Config.walk.supportX + .001;
		elseif byte==string.byte("v") then
			Config.walk.supportY = Config.walk.supportY - .001;
		elseif byte==string.byte("V") then
			Config.walk.supportY = Config.walk.supportY + .001;
		elseif byte==string.byte('y') then
			Config.walk.bodyHeight = Config.walk.bodyHeight - .001;
		elseif byte== string.byte('Y') then
			Config.walk.bodyHeight = Config.walk.bodyHeight + .001;
    elseif byte==string.byte('q') then
      Config.walk.footY = Config.walk.footY - .001
    elseif byte==string.byte('Q') then
      Config.walk.footY = Config.walk.footY + .001
		elseif byte== string.byte('z') then
			Config.walk.tStepWalkKick = Config.walk.tStepWalkKick - .01;
		elseif byte== string.byte('Z') then
			Config.walk.tStepWalkKick = Config.walk.tStepWalkKick + .01;
		elseif byte== string.byte('m') then
			Config.walk.walkKickHeightFactor = 
        Config.walk.walkKickHeightFactor - .01;
		elseif byte== string.byte('M') then
			Config.walk.walkKickHeightFactor = 
       Config.walk.walkKickHeightFactor + .01;
		elseif byte== string.byte('b') then
			Config.walk.walkKickVel[1] = Config.walk.walkKickVel[1] - .01;
    elseif byte==string.byte('B') then
      Config.walk.walkKickVel[1] = Config.walk.walkKickVel[1] +.01;
		elseif byte== string.byte('n') then
			Config.walk.walkKickVel[2] = Config.walk.walkKickVel[2] - .01;
		elseif byte== string.byte('N') then
			Config.walk.walkKickVel[2] = Config.walk.walkKickVel[2] + .01;
    elseif byte==string.byte('\\') then
      walkKick=not walkKick;
    elseif byte==string.byte("1") then
      if walkKick then	
        walk.doWalkKickLeft();
      else 
        kick.set_kick("kickForwardLeft");	
        Motion.event("kick");
      end
    elseif byte==string.byte("2") then
      if walkKick then
        walk.doWalkKickRight();
      else
        kick.set_kick("kickForwardRight");
        Motion.event("kick");
      end
		--turn assorted stability checks on/off--
		elseif byte==string.byte("3") then
		  Config.walk.imuOn = not Config.walk.imuOn;
		elseif byte==string.byte("4") then
			Config.walk.jointFeedbackOn = not Config.walk.jointFeedbackOn;
		elseif byte==string.byte("5") then
			Config.walk.fsrOn = not Config.walk.fsrOn;

		elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			walk.stop();
			Motion.event("standup");
		elseif byte==string.byte("9") then	
			Motion.event("walk");
			walk.start();
    elseif byte==string.byte("`") then
      print(instructions);
    end
  else
    if byte==string.byte("i") then		
			targetvel[1]=targetvel[1]+0.01;
		elseif byte==string.byte("j") then	
			targetvel[3]=targetvel[3]+0.1;
		elseif byte==string.byte("k") then	
			targetvel[1],targetvel[2],targetvel[3]=0,0,0;
		elseif byte==string.byte("l") then	
			targetvel[3]=targetvel[3]-0.1;
		elseif byte==string.byte(",") then	
			targetvel[1]=targetvel[1]-0.01;
		elseif byte==string.byte("h") then	
			targetvel[2]=targetvel[2]+0.01;
		elseif byte==string.byte(";") then	
			targetvel[2]=targetvel[2]-0.01;
		elseif byte==string.byte("[") then
			targetvel[1]=-targetvel[1];
		elseif byte==string.byte("'") then
			targetvel[2]=-targetvel[2];
		elseif byte==string.byte("/") then
			targetvel[3]=-targetvel[3];

		--Move the head around--
		elseif byte==string.byte("w") then
			headangle[2]=headangle[2]-5*math.pi/180;
		elseif byte==string.byte("a") then	
			headangle[1]=headangle[1]+5*math.pi/180;
		elseif byte==string.byte("s") then	
			headangle[1],headangle[2]=0,0;
		elseif byte==string.byte("d") then	
			headangle[1]=headangle[1]-5*math.pi/180;
		elseif byte==string.byte("x") then	
			headangle[2]=headangle[2]+5*math.pi/180;
		
    elseif byte==string.byte("`") then
      print(instructions);
      
		elseif byte==string.byte("1") then	
			walk.doWalkKickLeft();
		elseif byte==string.byte("2") then	
			walk.doWalkKickRight();

		elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			walk.stop();
			Motion.event("standup");
		elseif byte==string.byte("9") then	
			Motion.event("walk");
			walk.start();

		--Alpha for the gyro feedback--
		elseif byte==string.byte("y") then
			Config.walk.ankleImuParamX[1] = Config.walk.ankleImuParamX[1] - .01;
		elseif byte==string.byte("Y") then
			Config.walk.ankleImuParamX[1] = Config.walk.ankleImuParamX[1] + .01;
		elseif byte==string.byte("u") then
			Config.walk.ankleImuParamY[1] = Config.walk.ankleImuParamY[1] - .01;
		elseif byte==string.byte("U") then
			Config.walk.ankleImuParamY[1] = Config.walk.ankleImuParamY[1] + .01;
		elseif byte==string.byte("o") then
			Config.walk.kneeImuParamX[1] = Config.walk.kneeImuParamX[1] - .01;
		elseif byte==string.byte("O") then
			Config.walk.kneeImuParamX[1] = Config.walk.kneeImuParamX[1] + .01;
		elseif byte==string.byte("p") then
			Config.walk.hipImuParamY[1] = Config.walk.hipImuParamY[1] - .01;
		elseif byte==string.byte("P") then
			Config.walk.hipImuParamY[1] = Config.walk.hipImuParamY[1] + .01;

		--Gain for the gyro feedback--
		elseif byte==string.byte("q") then
			Config.walk.ankleImuParamX[2] = Config.walk.ankleImuParamX[2] - .05*Config.walk.gyroFactor;
		elseif byte==string.byte("Q") then
			Config.walk.ankleImuParamX[2] = Config.walk.ankleImuParamX[2] + .05*Config.walk.gyroFactor;
		elseif byte==string.byte("e") then
			Config.walk.ankleImuParamY[2] = Config.walk.ankleImuParamY[2] - .05*Config.walk.gyroFactor;
		elseif byte==string.byte("E") then
			Config.walk.ankleImuParamY[2] = Config.walk.ankleImuParamY[2] + .05*Config.walk.gyroFactor;
		elseif byte==string.byte("r") then
			Config.walk.kneeImuParamX[2] = Config.walk.kneeImuParamX[2] - .05*Config.walk.gyroFactor;
		elseif byte==string.byte("R") then
			Config.walk.kneeImuParamX[2] = Config.walk.kneeImuParamX[2] + .05*Config.walk.gyroFactor;
		elseif byte==string.byte("t") then
			Config.walk.hipImuParamY[2] = Config.walk.hipImuParamY[2] - .05*Config.walk.gyroFactor;
		elseif byte==string.byte("T") then
			Config.walk.hipImuParamY[2] = Config.walk.hipImuParamY[2] + .05*Config.walk.gyroFactor;

		--Deadband for the gyro feedback--
		elseif byte==string.byte("c") then
			Config.walk.ankleImuParamX[3] = Config.walk.ankleImuParamX[3] - .001;
		elseif byte==string.byte("C") then
			Config.walk.ankleImuParamX[3] = Config.walk.ankleImuParamX[3] + .001;
		elseif byte==string.byte("v") then
			Config.walk.ankleImuParamY[3] = Config.walk.ankleImuParamY[3] - .001;
		elseif byte==string.byte("V") then
			Config.walk.ankleImuParamY[3] = Config.walk.ankleImuParamY[3] + .001;
		elseif byte==string.byte("b") then
			Config.walk.kneeImuParamX[3] = Config.walk.kneeImuParamX[3] - .001;
		elseif byte==string.byte("B") then
			Config.walk.kneeImuParamX[3] = Config.walk.kneeImuParamX[3] + .001;
		elseif byte==string.byte("n") then
			Config.walk.hipImuParamY[3] = Config.walk.hipImuParamY[3] - .001;
		elseif byte==string.byte("N") then
			Config.walk.hipImuParamY[3] = Config.walk.hipImuParamY[3] + .001;
		
    --Adjust odometry values--  
    elseif byte==string.byte("z") then
      Config.walk.odomScale[1] = Config.walk.odomScale[1] + .01;
    elseif byte==string.byte("Z") then
      Config.walk.odomScale[1] = Config.walk.odomScale[1] - .01;
    elseif byte==string.byte("g") then
      Config.walk.odomScale[2] = Config.walk.odomScale[2] + .01;
    elseif byte==string.byte("G") then
      Config.walk.odomScale[2] = Config.walk.odomScale[2] - .01;
    elseif byte==string.byte("m") then
      Config.walk.odomScale[3] = Config.walk.odomScale[3] + .01;
    elseif byte==string.byte("M") then
      Config.walk.odomScale[3] = Config.walk.odomScale[3] - .01;
    elseif byte==string.byte("@") then
      wcm.set_robot_pose(vector.zeros(3));
    end
  end


  if parameters then
		print(string.format("\n Walk Velocity: (%.2f, %.2f, %.2f)",unpack(targetvel)));
		walk.set_velocity(unpack(targetvel));
		print "huh?";
		Body.set_head_command(headangle);
  	print(string.format("Head angle: %d, %d",
			headangle[1]*180/math.pi,
			headangle[2]*180/math.pi));
		print(string.format("Walk settings:\n tStep: %.2f\t phSingle: {%.2f, %.2f}\t stepHeight: %.3f\n supportX: %.3f\t supportY: %.3f\t footY: %.3f\t "..
      "bodyHeight: %.3f\t bodyTilt: %.3f", 
          Config.walk.tStep, Config.walk.phSingle[1], Config.walk.phSingle[2], Config.walk.stepHeight, 
          Config.walk.supportX, Config.walk.supportY, Config.walk.footY,
          Config.walk.bodyHeight,Config.walk.bodyTilt));
    print(string.format("Walk kick settings:\n tStepWalkKick: %.2f\t walkKickHeightFactor: %.2f\t walkKickVel: {%.2f, %.2f}\n", Config.walk.tStepWalkKick or Config.walk.tStep, Config.walk.walkKickHeightFactor, Config.walk.walkKickVel[1], Config.walk.walkKickVel[2]))
  else
    print(string.format("\n Walk Velocity: (%.2f, %.2f, %.2f)",unpack(targetvel)));
		walk.set_velocity(unpack(targetvel));
		Body.set_head_command(headangle);
		print(string.format("Head angle: %d, %d",
			headangle[1]*180/math.pi,
			headangle[2]*180/math.pi));
		print(string.format("Gyro Settings ({alpha, gain, deadband, max}):\n ankleImuParamX: {%.2f, %.5f, %.3f, %.3f}\n ankleImuParamY: {%.2f, %.5f, %.3f, %.3f}\n kneeImuParamX: {%.2f, %.5f, %.3f, %.3f}\n hipImuParamY: {%.2f, %.5f, %.3f, %.3f}\n", Config.walk.ankleImuParamX[1], Config.walk.ankleImuParamX[2], Config.walk.ankleImuParamX[3], Config.walk.ankleImuParamX[4], Config.walk.ankleImuParamY[1], Config.walk.ankleImuParamY[2], Config.walk.ankleImuParamY[3], Config.walk.ankleImuParamY[4], Config.walk.kneeImuParamX[1], Config.walk.kneeImuParamX[2], Config.walk.kneeImuParamX[3], Config.walk.kneeImuParamX[4], Config.walk.hipImuParamY[1], Config.walk.hipImuParamY[2], Config.walk.hipImuParamY[3], Config.walk.hipImuParamY[4]));
    print(string.format("Odometry settings:\n odomScale: {%.2f, %.2f, %.2f}\n", Config.walk.odomScale[1], Config.walk.odomScale[2], Config.walk.odomScale[3]));
  end

 
  wcm.set_robot_odomScale(Config.walk.odomScale)

  end
end

