module(..., package.seeall);
--SJ: IK based lookGoal to take account of bodytilt


require('Body')
require('Config')
require('vcm')
require('wcm')

t0 = 0;
yawSweep = Config.fsm.headLookGoal.yawSweep;
yawMax = Config.head.yawMax;
dist = Config.fsm.headReady.dist;
tScan = Config.fsm.headLookGoal.tScan;
minDist = Config.fsm.headLookGoal.minDist;
min_eta_look = Config.min_eta_look or 2.0;

yawMax = Config.head.yawMax or 90*math.pi/180;
fovMargin = 30*math.pi/180;


function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();

  --SJ: Check which goal to look at
  --Now we look at the NEARER goal
  pose = wcm.get_pose();
  defendGoal = wcm.get_goal_defend();
  attackGoal = wcm.get_goal_attack();

  dDefendGoal= math.sqrt((pose.x-defendGoal[1])^2 + (pose.y-defendGoal[2])^2);
  dAttackGoal= math.sqrt((pose.x-attackGoal[1])^2 + (pose.y-attackGoal[2])^2);
  attackAngle = wcm.get_attack_angle();
  defendAngle = wcm.get_defend_angle();

  --Can we see both goals?
  if math.abs(attackAngle)<yawMax + fovMargin and 
     math.abs(defendAngle)<yawMax + fovMargin  then
    --Choose the closer one
    if dAttackGoal < dDefendGoal then
      yaw0 = attackAngle;
    else
      yaw0 = defendAngle;
    end
  elseif math.abs(attackAngle)<yawMax + fovMargin then
    yaw0 = attackAngle;
  elseif math.abs(defendAngle)<yawMax + fovMargin then
    yaw0 = defendAngle;
  else --We cannot see any goals from this position
    --We can still try to see the goals?
    if  math.abs(attackAngle) < math.abs(defendAngle) then
      yaw0 = attackAngle;
    else
      yaw0 = defendAngle;
    end
  end
  vcm.set_camera_command(0); --top camera
end

function update()
  local t = Body.get_time();
  local tpassed=t-t0;
  local ph= tpassed/tScan;
  local yawbias = (ph-0.5)* yawSweep;

  height=vcm.get_camera_height();

  yaw1 = math.min(math.max(yaw0+yawbias, -yawMax), yawMax);
  local yaw, pitch =HeadTransform.ikineCam(
	dist*math.cos(yaw1),dist*math.sin(yaw1), height);
  Body.set_head_command({yaw, pitch});

  ball = wcm.get_ball();
  ballR = math.sqrt (ball.x^2 + ball.y^2);

  --If the player is attacker and about to reach the ball

  eta = wcm.get_team_my_eta();
  if eta<min_eta_look and eta>0 then
    return 'timeout';
  end

  if (t - t0 > tScan) then
    tGoal = wcm.get_goal_t();
    if (tGoal - t0 > 0) then
      return 'timeout';
    else      
      return 'lost';
    end
  end
end

function exit()
  vcm.set_camera_command(-1); --switch camera
end

