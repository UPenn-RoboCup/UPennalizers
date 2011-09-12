module(..., package.seeall);

require('Body')
require('walk')
require('Motion')

t0 = 0;

function entry()
  print("BodyFSM:".._NAME.." entry");
  t0 = Body.get_time();
  walk.set_velocity(0,0,0);
  Motion.event("sit");
end

function update()
  t = Body.get_time();

  if (t - t0 > 1.0 and Body.get_sensor_button()[1] > 0) then
    return "button"; 
  end
end

function exit()
  Motion.event("standup");
end
