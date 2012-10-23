module(..., package.seeall);

require('Body')
require('keyframe')
require('unix')
require('Config');
require('walk');
require('wcm')

local cwd = unix.getcwd();
if string.find(cwd, "WebotsController") then
  cwd = cwd.."/Player";
end
cwd = cwd.."/Motion/keyframes"

keyframe.load_motion_file(cwd.."/"..Config.km.standup_front,
                          "standupFromFront");
keyframe.load_motion_file(cwd.."/"..Config.km.standup_back,
                          "standupFromBack");

use_rollback_getup = Config.use_rollback_getup or 0;
batt_max = Config.batt_max or 10;

function entry()
  print(_NAME.." entry");

  keyframe.entry();
  Body.set_body_hardness(1);
  -- start standup routine (back/front)
  local imuAngleY = Body.get_sensor_imuAngle(2);
  if (imuAngleY > 0) then
    print("standupFromFront");
    keyframe.do_motion("standupFromFront");
  else
    pose = wcm.get_pose();
    batt_level=Body.get_battery_level();

    if math.abs(pose.x) < 2.0 and
       use_rollback_getup > 0 and
       batt_level*10>batt_max then

      print("standupFromBack");
      keyframe.do_motion("standupFromBack2");
    else
      print("standupFromBack");
      keyframe.do_motion("standupFromBack");
    end
  end
end

function update()
  keyframe.update();
  if (keyframe.get_queue_len() == 0) then
    local imuAngle = Body.get_sensor_imuAngle();
    local maxImuAngle = math.max(math.abs(imuAngle[1]),
                        math.abs(imuAngle[2]));
    if (maxImuAngle > 40*math.pi/180) then
      return "fail";
    else
    	--Set velocity to 0 to prevent falling--
    	walk.still=true;
    	walk.set_velocity(0, 0, 0);
      return "done";
    end
  end
end

function exit()
  keyframe.exit();
end
