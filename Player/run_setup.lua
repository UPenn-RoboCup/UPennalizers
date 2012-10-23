--[[
Robot- specific setup code 
Can setup all robot-specific calibration parameters
And automatically appends it to calibration file
--]]
module(... or "", package.seeall)

webots = false;
darwin = true;
local cwd = '.';
-- the webots sim is run from the WebotsController dir (not Player)
if string.find(cwd, "WebotsController") then
  webots = true;
  cwd = cwd.."/Player"
  package.path = cwd.."/?.lua;"..package.path;
end

computer = os.getenv('COMPUTER') or "";
--computer = 'Darwin'
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

require('Config');
--This FIXES monitor issue with test_vision trying to send team message
Config.dev.team = 'TeamNull'; 
require('Body')
require('vector')
require("getch")
require('Kinematics');
require('Motion')
require('mcm')
require('Broadcast')
require('unix')

-- initialize state machines

jointNames={"HipYaw","HipRoll","HipPitch","KneePitch","AnklePitch","AnkleRoll"};
jointindex=4;
hardness=vector.new({0,0,0,0,0,0});

if(Config.platform.name == 'OP') then
  darwin = true;
  --SJ: OP specific initialization posing (to prevent twisting)
  Body.set_body_hardness(0.3);
  Body.set_actuator_command(Config.stance.initangle)
  unix.usleep(1E6*0.5);
  Body.set_body_hardness(0);
  Body.set_lleg_hardness({0.2,0.6,0,0,0,0});
  Body.set_rleg_hardness({0.2,0.6,0,0,0,0});
end 
getch.enableblock(1);

-- main loop
isended=false;
count=0;
t0 = unix.time();
Motion.entry();

function init()
  Body.set_larm_hardness(0);
  Body.set_rarm_hardness(0);
  Body.set_head_command({0,0});
  legBias=Config.walk.servoBias;
  bias_offset = 5; --Servo id starts with 6
  bias = vector.zeros(20);
  bias0 = vector.zeros(20);
  for i=1,12 do
    bias[i+bias_offset]=legBias[i];
    bias0[i+bias_offset]=legBias[i];
  end

  --  footXComp0=Config.walk.footXComp;
  footXComp0 = Config.walk.footXComp;
  kickXComp0 = Config.walk.kickXComp;
  footXComp = Config.walk.footXComp;
  kickXComp = Config.walk.kickXComp;

  headPitch = Config.walk.headPitch;
  headPitchComp = Config.walk.headPitchComp;
  headPitchComp0 = Config.walk.headPitchComp0;

  hardness_all = 0;
  targetvel=vector.zeros(3);

  --0 for biasing, 1 for test_walk, 2 for test_vision
  test_mode = 1; 
  headsm_running = 0;
  bodysm_running = 0;
  headangle=vector.new({0,10*math.pi/180});

end

broadcast_enable=0;
function broadcast()
  -- Get a keypress
  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    if byte==string.byte("g") then	--Broadcast selection
      local mymod = 4;
      broadcast_enable = (broadcast_enable+1)%mymod;
      print("Broadcast:", broadcast_enable);
    end
  end
  if vcm.get_image_count()>imagecount then
    imagecount=vcm.get_image_count();
    -- Always send non-image data
    Broadcast.update(broadcast_enable);
    -- Send image data every so often
    if( imagecount % imgRate == 0 ) then
      Broadcast.update_img(broadcast_enable);    
    end
    return true;
  end
  return false;
end


function info()
  if test_mode==0 then
    print(" Key commands \n a/d: Left adjust\n w/x: Right adjust\n");
    print(" 1/2: change joint");
    print(" b: Enable test_walk");
    print(" v: Enable test_vision");
    print(" 0: Save and Exit")
  elseif test_mode==1 then
    print(" Key commands \n i/j/l/,: change walk velocity\n");
    print(" 7/8/9: Sit/Stand/Walk");
    print(" 1/2/3/4: Kick front L / front R/ side L/ side R");
    print(" 5/6/t/y: Walkkick front L / front R/ side L/ side R");
    print(" - / = ;Stance X offset adjustment")
    print(" b: Enable test_vision");
    print(" v: Enable test_bias");
    print(" 0: Save and Exit")
  else
    print(" Key commands \n i/j/l/,: change walk velocity\n");
    print(" 7/8/9: Sit/Stand/Walk");
    print(" a/d/w/x: Change head angle");

    print(" 1: HeadScan");
    print(" 2: HeadReady");
    print(" 5: Enable FSM");
    print(" 6: HeadKick SM");

    print(" g: toggle broadcast");
    print(" b: Enable test_bias");
    print(" v: Enable test_walk");
  end
end

function process_keyinput_test_bias(byte)
   if byte==string.byte("1") then jointindex=(jointindex-2)%6+1;
   elseif byte==string.byte("2") then jointindex=jointindex%6+1;
   elseif byte==string.byte("a") then 
     bias[jointindex+bias_offset]=bias[jointindex+bias_offset]-1;
   elseif byte==string.byte("d") then 
     bias[jointindex+bias_offset]=bias[jointindex+bias_offset]+1;
   elseif byte==string.byte("w") then 
     bias[jointindex+bias_offset+6]=bias[jointindex+bias_offset+6]-1;
   elseif byte==string.byte("x") then 
     bias[jointindex+bias_offset+6]=bias[jointindex+bias_offset+6]+1;
   elseif byte==string.byte("s") then
     bias[jointindex+bias_offset]=bias0[jointindex+bias_offset];
     bias[jointindex+bias_offset+6]=bias0[jointindex+bias_offset+6];

   else info();
   end
   print(string.format("\n %s: L%d, R%d)",
        jointNames[jointindex],
        bias[jointindex+bias_offset],bias[jointindex+6+bias_offset]));
    Body.set_actuator_bias(bias);
end

function process_keyinput_set_velocity(byte)
  -- Walk velocity setting
  if byte==string.byte("i") then targetvel[1]=targetvel[1]+0.02;
  elseif byte==string.byte("j") then targetvel[3]=targetvel[3]+0.1;
  elseif byte==string.byte("k") then targetvel[1],targetvel[2],targetvel[3]=0,0,0;
  elseif byte==string.byte("l") then targetvel[3]=targetvel[3]-0.1;
  elseif byte==string.byte(",") then targetvel[1]=targetvel[1]-0.02;
  elseif byte==string.byte("h") then targetvel[2]=targetvel[2]+0.02;
  elseif byte==string.byte(";") then targetvel[2]=targetvel[2]-0.02;
  elseif byte==string.byte("7") then Motion.event("sit");
  elseif byte==string.byte("8") then	
    if walk.active then walk.stop();end
    bodysm_running = 0;
    Motion.event("standup");
  elseif byte==string.byte("9") then	
    Motion.event("walk");
    walk.start();
  end
  walk.set_velocity(unpack(targetvel));
  print("Command velocity:",unpack(walk.velCommand))
end

function process_keyinput_test_walk(byte)
   --Test_walk mode
  if byte==string.byte("1") then 
    kick.set_kick("kickForwardLeft");
    Motion.event("kick");
  elseif byte==string.byte("2") then	
    kick.set_kick("kickForwardRight");
    Motion.event("kick");
  elseif byte==string.byte("3") then	
    kick.set_kick("kickSideLeft");
    Motion.event("kick");
  elseif byte==string.byte("4") then	
    kick.set_kick("kickSideRight");
    Motion.event("kick");
  elseif byte==string.byte("5") then
    walk.doWalkKickLeft();
  elseif byte==string.byte("6") then
    walk.doWalkKickRight();

  elseif byte==string.byte("e") then
    walk.doWalkKickLeft2();
  elseif byte==string.byte("r") then
    walk.doWalkKickRight2();

  elseif byte==string.byte("t") then
    walk.doSideKickLeft();
  elseif byte==string.byte("y") then
    walk.doSideKickRight();

    -- footXComp calibration
  elseif byte==string.byte("-") then
    footXComp = footXComp - 0.001; 
    print(string.format("footXComp Orig: %.3f Now: %.3f\n",
      footXComp0, footXComp));
    mcm.set_walk_footXComp(footXComp);
  elseif byte==string.byte("=") then
    footXComp = footXComp + 0.001; 
    print(string.format("footXComp Orig: %.3f Now: %.3f\n",
      footXComp0, footXComp));
    mcm.set_walk_footXComp(footXComp);

  -- kickXComp calibration
  elseif byte==string.byte("[") then
    kickXComp = kickXComp - 0.005; 
    print(string.format("kickXComp Orig: %.3f Now: %.3f\n",
      kickXComp0, kickXComp));
    mcm.set_walk_kickXComp(kickXComp);
  elseif byte==string.byte("]") then
    kickXComp = kickXComp + 0.005; 
    print(string.format("kickXComp Orig: %.3f Now: %.3f\n",
      kickXComp0, kickXComp));
    mcm.set_walk_kickXComp(kickXComp);
  end
end

function process_keyinput_test_vision(byte)
  headPitchBiasComp = mcm.get_walk_headPitchBiasComp();
  headPitchBias = mcm.get_headPitchBias()

  -- Move the head around
  if byte==string.byte("w") then
    headsm_running=0;headangle[2]=headangle[2]-5*math.pi/180;
  elseif byte==string.byte("a") then
    headsm_running=0;headangle[1]=headangle[1]+5*math.pi/180;
  elseif byte==string.byte("d") then
    headsm_running=0;headangle[1]=headangle[1]-5*math.pi/180;
  elseif byte==string.byte("x") then
    headsm_running=0;headangle[2]=headangle[2]+5*math.pi/180;
  elseif byte==string.byte("s") then
    headsm_running=0;headangle[1],headangle[2]=0,0;

  -- Head pitch fine tuning (for camera angle calibration)
  elseif byte==string.byte("e") then	
    headsm_running=0;headangle[2]=headangle[2]-1*math.pi/180;
  elseif byte==string.byte("c") then	
    headsm_running=0;headangle[2]=headangle[2]+1*math.pi/180;

  -- Camera angle bias fine tuning 
  elseif byte==string.byte("q") then	
    headsm_running=0;
    headPitchBiasComp = headPitchBiasComp+math.pi/180;
    mcm.set_walk_headPitchBiasComp(headPitchBiasComp);
    print("\nCamera pitch bias:",headPitchBiasComp*180/math.pi);
  elseif byte==string.byte("z") then	
    headsm_running=0;
    headPitchBiasComp = headPitchBiasComp-math.pi/180;
    mcm.set_walk_headPitchBiasComp(headPitchBiasComp);
    print("\nCamera pitch bias:",headPitchBiasComp*180/math.pi);
  -- Head FSM testing
  elseif byte==string.byte("1") then	
    headsm_running = 1;
    HeadFSM.sm:set_state('headScan');
  elseif byte==string.byte("2") then	
    headsm_running = 1;
    HeadFSM.sm:set_state('headReady');
  elseif byte==string.byte("6") then	
    headsm_running = 1;
    HeadFSM.sm:set_state('headKick');
  end

  if headsm_running == 0 then
    Body.set_head_command({headangle[1],headangle[2]-headPitchBias});
    print("\nHead Yaw Pitch:", unpack(headangle*180/math.pi))
  end
end




function process_keyinput()
  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    q1=vector.slice(Body.get_sensor_position(),6,18);

    --Switch mode
    if byte==string.byte("b") then
      test_mode=(test_mode+1)%3;
print("TESTMODE:",test_mode)
      info();
      if test_mode==0 then    
        Body.set_lleg_hardness(1);
        Body.set_rleg_hardness(1);
        Body.set_lleg_command(vector.zeros(6));
        Body.set_rleg_command(vector.zeros(6));
        Body.set_syncread_enable(1);
      else
        Body.set_syncread_enable(0);
     end
    elseif byte==string.byte("v") then
      test_mode=(test_mode+2)%3;
print("TESTMODE:",test_mode)

      info();
      if test_mode==0 then    
        Body.set_syncread_enable(1);
        Body.set_lleg_hardness(1);
        Body.set_rleg_hardness(1);
        Body.set_lleg_command(vector.zeros(6));
        Body.set_rleg_command(vector.zeros(6));
        Body.set_syncread_enable(1);
      else
        Body.set_syncread_enable(0);
      end
    end
 
    if test_mode==0 then
      process_keyinput_test_bias(byte)
    else
      process_keyinput_set_velocity(byte)
      if test_mode==1 then
	process_keyinput_test_walk(byte)
      else
	process_keyinput_test_vision(byte)
      end
    end
    if byte==string.byte("0") then
      isended=true;
    end
  end
end

init();
info();
while not isended do
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  process_keyinput();
  if test_mode>0 then
    Motion.update();
    Body.update();
  end
  unix.usleep(tDelay);
end
Body.set_lleg_hardness(0);
Body.set_rleg_hardness(0);

--append at the end of current configuration file
outfile=assert(io.open("./Config/calibration.lua","a+"));

--TODO: which one should we use?
--data=string.format("\n\-\- Updated date: %s\n" , os.date() );
data=string.format("\n-- Updated date: %s\n" , os.date() );
data=data..string.format("cal[\"%s\"].servoBias={",unix.gethostname());
for i=1,12 do
  data=data..string.format("%d,",bias[i+bias_offset]);
end
data=data.."};\n";
data=data..string.format("cal[\"%s\"].footXComp=%.3f;\n",
	unix.gethostname(), footXComp);
data=data..string.format("cal[\"%s\"].kickXComp=%.3f;\n",
	unix.gethostname(),kickXComp);
outfile:write(data);
outfile:flush();
outfile:close();
