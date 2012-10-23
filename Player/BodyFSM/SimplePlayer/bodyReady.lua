module(..., package.seeall);

require('Body')
require('walk')
require('util')
require('vector')
require('Config')
require('wcm')
require('gcm')
require('Team')

t0 = 0;

maxStep = Config.fsm.bodyReady.maxStep;
rClose = Config.fsm.bodyReady.thClose[1];
thClose = Config.fsm.bodyReady.thClose[2];

--Init position for our kickoff
initPosition1 = Config.world.initPosition1;
--Init position for opponents' kickoff
initPosition2 = Config.world.initPosition2;

-- don't start moving right away
tstart = Config.fsm.bodyReady.tStart or 5.0;

phase=0; --0 for wait, 1 for approach, 2 for turn, 3 for end

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  phase=0;
end

function getHomePose()
  role=gcm.get_team_role();
  --Now role-based positioning
  goal_defend=wcm.get_goal_defend();
  --role starts with 0
  if gcm.get_game_kickoff() == 1 then
    home=vector.new(initPosition1[role+1]);
  else
    home=vector.new(initPosition2[role+1]);
  end

  --Goalie moves differently
  if role==0 and phase==1 then 
    home=home*0.7;
  end;

  home=home*util.sign(goal_defend[1]);
  home[3]=goal_defend[3];
  return home;
end

function update()
  local t = Body.get_time();
  pose = wcm.get_pose();
  home =getHomePose();
  homeRelative = util.pose_relative(home, {pose.x, pose.y, pose.a});
  rhome = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  attackBearing = wcm.get_attack_bearing();

  if phase==0 then 
    if t - t0 < tstart then 
      return;
    else walk.start();
      phase=1;
    end
  elseif phase==1 then --Approach phase 
    vx = maxStep * homeRelative[1]/rhome;
    vy = maxStep * homeRelative[2]/rhome;
    va = .2 * math.atan2(homeRelative[2], homeRelative[1]);
    walk.set_velocity(vx, vy, va);
    if rhome < rClose then phase=2; end
  elseif phase==2 then --Turning phase, face center
    vx = maxStep * homeRelative[1]/rhome;
    vy = maxStep * homeRelative[2]/rhome;
    va = .2*attackBearing;
    walk.set_velocity(vx, vy, va);
  end

  if phase~=3 and rhome < rClose and 
     math.abs(attackBearing)<thClose then 
      walk.stop(); 
      phase=3;
  end
end

function exit()
end

