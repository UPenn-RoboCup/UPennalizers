module(..., package.seeall);

require('Body')
require('keyframe')
require('unix')
require('Config');
require('walk');
require('wcm')
require('vcm')

local cwd = unix.getcwd();
local getup_flag=0;
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion/keyframes"
keyframe.load_motion_file(cwd.."/"..Config.km.standup_front,
                          "standupFromFront");
keyframe.load_motion_file(cwd.."/"..Config.km.standup_back,
                          "standupFromBack");
keyframe.load_motion_file(cwd.."/"..Config.km.standup_front2,
                          "standupFromFront2");
keyframe.load_motion_file(cwd.."/"..Config.km.standup_back2,
                          "standupFromBack2");




use_rollback_getup = Config.use_rollback_getup or 0;
batt_max = Config.batt_max or 10;

function entry()
  print(_NAME.." entry");

  keyframe.entry();
  Body.set_body_hardness(1);
  -- start standup routine (back/front)
  local imuAngleY = Body.get_sensor_imuAngle(2);
  if (imuAngleY > 0) then
	batt_level=Body.get_battery_level();
	if batt_level<9 then
	print("standupFromFront_slow");
    keyframe.do_motion("standupFromFront2");
	else
		print("standupFromFront");
		keyframe.do_motion("standupFromFront")
end
  else
    pose = wcm.get_pose();
    batt_level=Body.get_battery_level();
--[[
    if batt_level<9 then
      print("standupFromBack_slow");
      keyframe.do_motion("standupFromBack2");
    else
      print("standupFromBack");
      keyframe.do_motion("standupFromBack");
    end
--]]
    if getup_flag==0 and batt_level>9 then
keyframe.do_motion("standupFromBack");
else
keyframe.do_motion("standupFromBack2");
end
end
  --vcm.set_vision_enable(0);
end

function update()
  keyframe.update();
  if (keyframe.get_queue_len() == 0) then
    local imuAngle = Body.get_sensor_imuAngle();
    local maxImuAngle = math.max(math.abs(imuAngle[1]),
                        math.abs(imuAngle[2]));
    if (maxImuAngle > 40*math.pi/180) then
getup_flag=1;     
 return "fail";
    else
    	--Set velocity to 0 to prevent falling--
    	walk.still=true;
getup_flag=0;
    	walk.set_velocity(0, 0, 0);
      return "done";
    end
  end
end

function exit()
  keyframe.exit();
end
