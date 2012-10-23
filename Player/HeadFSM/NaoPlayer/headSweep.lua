module(..., package.seeall);

require('Body')

t0 = 0;
t1 = 0;
tscan = Config.fsm.headSweep.tScan;
twait = Config.fsm.headSweep.tWait;
yawMag = Config.head.yawMax;
pitch = 0.0;
detectGoal = 0;
function entry()
  print(_NAME..' entry');
  detectGoal = 0;
  t0 = Body.get_time();
  headAngles = Body.get_head_position();
  if (headAngles[1] > 0) then
    direction = 1;
  else
    direction = -1;
  end

   -- only use top camera
  vcm.set_camera_command(-1);
end

function update()
  if (detectGoal == 0) then
    local t = Body.get_time();

    local ph = (t-t0)/tscan;
    local yaw = direction*yawMag*math.cos(math.pi*ph);
    Body.set_head_command({yaw, pitch});

    detectGoal = vcm.get_goal_detect();
    if (detectGoal == 1) then
      t1 = Body.get_time();
      print ('see the goal!')
    end
    if (t - t0 > tscan) then
      print ('time out!')
      return 'lost';
    end
  end

  if (detectGoal == 1)then
    print ('waiting...')  
    local td = Body.get_time();
    if (td - t1 > twait) then
      return 'done';
    end
  end
end

function exit()
end
