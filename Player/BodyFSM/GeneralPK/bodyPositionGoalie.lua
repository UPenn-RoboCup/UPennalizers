module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

maxStep = Config.fsm.bodyChase.maxStep;
tLost = Config.fsm.bodyChase.tLost;
timeout = Config.fsm.bodyChase.timeout;
rClose = Config.fsm.bodyChase.rClose;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
end

function update()
print("UPDATING")
  local t = Body.get_time();
  pose = wcm.get_pose();
  homePosition = wcm.get_goal_defend();
  attackBearing = wcm.get_attack_bearing();

--  Don't care about the balls, just rotate to see other goalpost
--  vx = maxStep*homeRelative[1]/rHomeRelative;
--  vy = maxStep*homeRelative[2]/rHomeRelative;

  vx,vy=0,0;
  va = .2*attackBearing;
  print("attackBearing:",attackBearing*180/math.pi)


  walk.set_velocity(vx, vy, va);
  if (math.abs(attackBearing)<10*math.pi/180) then
    return "done";
  end
end

function exit()
end

