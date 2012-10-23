module(..., package.seeall);

require('Body')
require('walk')
require('util')
require('vector')
require('Config')
require('wcm')
require('gcm')

t0 = 0;

maxStep = 0.06;

rClose = 0.20;

thClose = 10.0 * math.pi/180.0;

-- don't start moving right away
tstart = 5.0;


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
end

function update()
  local t = Body.get_time();

  if t - t0 < tstart then
    return;
  end

  pose = wcm.get_pose();

  id = gcm.get_team_player_id();
  if gcm.get_game_kickoff() == 1 then
    if (id == 1) then
      -- goalie
      home = wcm.get_goal_defend();
    elseif (id == 2) then
      -- attacker 
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * .5;
    elseif (id == 3) then
      -- defender
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * 2;
      home[2] = -0.75;
    else
      -- support
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * .5;
      home[2] = 1.0;
    end
  else
    if (id == 1) then
      -- goalie
      home = wcm.get_goal_defend();
    elseif (id == 2) then
      -- attacker 
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * 1.75;
    elseif (id == 3) then
      -- defender
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * 1.75;
      home[2] = 1.25;
    else
      -- support
      home = wcm.get_goal_defend();
      home[1] = util.sign(home[1]) * 1.75;
      home[2] = -1.25;
    end
  end

  homeRelative = util.pose_relative(home, {pose.x, pose.y, pose.a});
  rhome = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  vx = maxStep * homeRelative[1]/(rhome + 0.1);
  vy = maxStep * homeRelative[2]/(rhome + 0.1);
  va = .2 * math.atan2(homeRelative[2], homeRelative[1]);

  -- close and oriented then stop walking
  if rhome < rClose then
    attackGoal = wcm.get_goal_attack();
    attackGoalRelative = util.pose_relative(attackGoal, {pose.x, pose.y, pose.a});
    home[3] = math.atan2(attackGoalRelative[2], attackGoalRelative[1]);

    if math.abs(home[3]) < thClose then
      walk.set_velocity(0, 0, 0);
      walk.stop();
    else
      -- face center
      va = .2 * home[3];
      walk.start();
      walk.set_velocity(vx, vy, va);
    end
  else
    walk.start();
    walk.set_velocity(vx, vy, va);
  end

end

function exit()
end

