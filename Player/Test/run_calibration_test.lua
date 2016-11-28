cwd = os.getenv('PWD')
require('init')
--NAO-specific walk tuner + online monitor (just for walk)


require('unix')
require('Config')
require('shm')
require('vector')
require('mcm')
require('Speak')
require('getch')
require('Body')
require('Motion')
require ('UltraSound')
<<<<<<< HEAD
require('Broadcast')
=======
--require('Broadcast')
>>>>>>> bca8c7ebe6dfa2c93f84acc3ae2d4a438590d3c6


Motion.entry();
darwin = false;
webots = false;
newnao = true;

getch.enableblock(1);
unix.usleep(1E6*1.0);
Body.set_body_hardness(0);

--This is robot specific 
init = false;
calibrating = false;
ready = false;
if( webots or darwin) then
  ready = true;
end

initToggle = true;
targetvel=vector.zeros(3);
button_pressed = {0,0};


function process_keyinput()
  local div = 0.5*math.pi/180

  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    -- Walk velocity setting
    if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
    elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
    elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
    elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
    elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
    elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
    elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;

    elseif byte==string.byte("1") then	
      Config.pitch_feedback_enable = 1- Config.pitch_feedback_enable
      print("Pitch feedback:",Config.pitch_feedback_enable)
    elseif byte==string.byte("2") then	
      Config.roll_feedback_enable = 1- Config.roll_feedback_enable
      print("Roll feedback:",Config.roll_feedback_enable)

    elseif byte==string.byte("q") then	
      Config.walk.LHipOffset=Config.walk.LHipOffset-div
--      Config.walk.LAnkleOffset=Config.walk.LAnkleOffset+div
	  print("\n")
	  print("LHipOffset:",Config.walk.LHipOffset)
--	  print("LAnkleOffset:",Config.walk.LAnkleOffset)
    elseif byte==string.byte("w") then	
      Config.walk.LHipOffset=Config.walk.LHipOffset+div
  --    Config.walk.LAnkleOffset=Config.walk.LAnkleOffset-div
	  print("\n")
	  print("LHipOffset:",Config.walk.LHipOffset)
--	  print("LAnkleOffset:",Config.walk.LAnkleOffset)
    elseif byte==string.byte("z") then	
      Config.walk.LAnkleOffset=Config.walk.LAnkleOffset-div
	   print("\n")
	   print("LAnkleOffset:",Config.walk.LAnkleOffset)
    elseif byte==string.byte("x") then	
      Config.walk.LAnkleOffset=Config.walk.LAnkleOffset+div
	   print("\n")
	   print("LAnkleOffset:",Config.walk.LAnkleOffset)


    elseif byte==string.byte("e") then	
      Config.walk.RHipOffset=Config.walk.RHipOffset-div
  --    Config.walk.RAnkleOffset=Config.walk.RAnkleOffset+div
	   print("\n")
	  print("RHipOffset:",Config.walk.RHipOffset)
--	  print("RAnkleOffset:",Config.walk.RAnkleOffset)
    elseif byte==string.byte("r") then	
      Config.walk.RHipOffset=Config.walk.RHipOffset+div
  --    Config.walk.RAnkleOffset=Config.walk.RAnkleOffset-div
	   print("\n")
	  print("RHipOffset:",Config.walk.RHipOffset)
--	  print("RAnkleOffset:",Config.walk.RAnkleOffset)
    elseif byte==string.byte("c") then	
      Config.walk.RAnkleOffset=Config.walk.RAnkleOffset-div
	   print("\n")
	  print("RAnkleOffset:",Config.walk.RAnkleOffset)
    elseif byte==string.byte("v") then	
      Config.walk.RAnkleOffset=Config.walk.RAnkleOffset+div
	   print("\n")
	  print("RAnkleOffset:",Config.walk.RAnkleOffset)

    elseif byte==string.byte("t") then	
      Config.walk.PIDX[1] = Config.walk.PIDX[1]-0.1
      print("\nX P gain:",Config.walk.PIDX[1])
    elseif byte==string.byte("y") then	
      Config.walk.PIDX[1] = Config.walk.PIDX[1]+0.1
      print("\nX P gain:",Config.walk.PIDX[1])

    elseif byte==string.byte("b") then	
      Config.walk.PIDY[1] = Config.walk.PIDY[1]-0.1
      print("\nY P gain:",Config.walk.PIDY[1])

    elseif byte==string.byte("n") then	
      Config.walk.PIDY[1] = Config.walk.PIDY[1]+0.1
      print("\nY P gain:",Config.walk.PIDY[1])
	  
	  elseif byte==string.byte("[") then
		  Config.walk.stepHeight=Config.walk.stepHeight-0.002;
		  print("\n stepHeight:",Config.walk.stepHeight);
      elseif byte==string.byte("]") then
			Config.walk.stepHeight=Config.walk.stepHeight+0.002;
			print("\n stepHeight:",Config.walk.stepHeight);
	elseif byte==string.byte("-") then
                Config.walk.bodyHeight=Config.walk.bodyHeight-0.001;
                print("\n bodyHeight:",Config.walk.bodyHeight);
        elseif byte==string.byte("+") then
                Config.walk.bodyHeight=Config.walk.bodyHeight+0.001;
                print("\n bodyHeight:",Config.walk.bodyHeight);

    elseif byte==string.byte("7") then	
      Motion.event("sit");
    elseif byte==string.byte("8") then	
      if walk.active then walk.stop();end
      Motion.event("standup");
    elseif byte==string.byte("9") then	
      Motion.event("walk");
      walk.start();
    elseif byte==string.byte("0") then
<<<<<<< HEAD
outfile=assert(io.open("/Config/calibration.lua","a+"));
data=string.format("\n\n --Update date:%s\n",os.date());
data=data..string.format("cal[\"%s\"]")
=======
outfile=assert(io.open("./Config/calibration.lua","a+"));
data=string.format("\n\n --Update date:%s\n",os.date());
data=data..string.format("cal[\"%s\"]={LAnkleOffset=%f,RAnkleOffset=%f,LHipOffset=%f,RHipOffset=%f,stepHeight=%f}",unix.gethostname(),Config.walk.LAnkleOffset,Config.walk.RAnkleOffset,Config.walk.LHipOffset,Config.walk.RHipOffset,Config.walk.stepHeight);
>>>>>>> bca8c7ebe6dfa2c93f84acc3ae2d4a438590d3c6
outfile:write(data);
outfile:flush();
outfile:close();
    end
    walk.set_velocity(unpack(targetvel));
    print("Command velocity:",unpack(walk.velCommand))
  end
end

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();

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
      init = true;
    else
      if (count % 20 == 0) then
-- start calibrating w/o waiting
--        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
--        end
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
  else
    -- update state machines 
    process_keyinput();
    Motion.update();
    Body.update();
<<<<<<< HEAD
    Broadcast.update_motion()
=======
--    Broadcast.update_motion()
>>>>>>> bca8c7ebe6dfa2c93f84acc3ae2d4a438590d3c6
  end
  local dcount = 50;
  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
  end
  
  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
    print('count: '..count)
    print('lcount: '..lcount)
    Speak.talk('missed cycle');
    lcount = count;
  end

  --Stop walking if button is pressed and the released
  if (Body.get_change_state() == 1) then
    button_pressed[1]=1;
  else
    if button_pressed[1]==1 then
      Motion.event("sit");
    end
    button_pressed[1]=0;
  end
end

-- if using Webots simulator just run update
if (webots) then
  while (true) do
    -- update motion process
    update();
    io.stdout:flush();
  end
end

t_start = Body.get_time()
t_last = Body.get_time()

--Now both nao and darwin runs this separately
if (darwin) or (newnao) then
  local tDelay = 0.005 * 1E6; -- Loop every 5ms
  while 1 do
    t=Body.get_time()
    tPassed = t-t_last
    t_last = t
    if tPassed>0.002 then
      update();
    end
    unix.usleep(tDelay);
  end
end
