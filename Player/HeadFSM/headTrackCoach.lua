module(..., package.seeall);

require('Body')
require('HeadTransform')
require('Config')
require('wcm')

t0 = 0;

minDist = Config.fsm.headTrack.minDist;
fixTh = Config.fsm.headTrack.fixTh;
trackZ = Config.vision.ball_diameter; 
timeout = Config.fsm.headTrack.timeout;
tLost = Config.fsm.headTrack.tLost;

min_eta_look = Config.min_eta_look or 2.0;


goalie_dive = Config.goalie_dive or 0;
goalie_type = Config.fsm.goalie_type;


new_head_fsm = Config.fsm.new_head_fsm or 0



function entry()
  print("Head SM:".._NAME.." entry");
  print('running headTrackCoach')
  t0 = Body.get_time();
  vcm.set_camera_command(-1); --switch camera

end

function update()
  print('Updating headtrack')
  role = gcm.get_team_role();
  --Force attacker for demo code
  if Config.fsm.playMode==1 then role=1; end
  --if role==0 and goalie_type>2 then --Escape if diving goalie
    --return "goalie"; end

  local t = Body.get_time();

  -- update head position based on ball location
  ball = wcm.get_ball();
  --print('ball x y: '..ball.x..' '..ball.y);
  ballR = math.sqrt (ball.x^2 + ball.y^2);
  local yaw,pitch;
  --top:0 bottom: 1

  --Bottom camera check
  yaw, pitchBottom = HeadTransform.ikineCam(ball.x, ball.y, trackZ, 1);
  --Max pitch angle: 15 degree
  pitch = 0
  if pitchBottom > 5*math.pi/180 then pitch = math.min(20*math.pi/180, pitchBottom - 5*math.pi/180) end

  local pose = wcm.get_pose();
  local defendGoal = wcm.get_goal_defend();
  local attackGoal = wcm.get_goal_attack();
  local dDefendGoal= math.sqrt((pose.x-defendGoal[1])^2 + (pose.y-defendGoal[2])^2);
  local dAttackGoal= math.sqrt((pose.x-attackGoal[1])^2 + (pose.y-attackGoal[2])^2);
  local attackAngle = wcm.get_attack_angle();
  local defendAngle = wcm.get_defend_angle();

  local attackGoalVisible = false
  local defendGoalVisible = false
  local goalAngleMinAngle
  local goalAngleMinDist

  if defendAngle<Config.head.yawMax_coach and defendAngle>-Config.head.yawMax_coach then defendGoalVisible = true end
  if attackAngle<Config.head.yawMax_coach and attackAngle>-Config.head.yawMax_coach then attackGoalVisible = true end
  if dDefendGoal<dAttackGoal and defendGoalVisible then goalAngleMinDist = defendAngle end
  if (dDefendGoal>dAttackGoal or not goalAngleMinDist) and attackGoalVisible then goalAngleMinDist = attackAngle end
  
  --Nao FOV: 60.8 deg / 47.5 deg
  local fovMargin = 15*math.pi/180
  if math.abs(attackAngle - yaw) < fovMargin then goalAngleMinAngle = attackAngle 
  elseif math.abs(defendAngle - yaw) < fovMargin then goalAngleMinAngle = defendAngle end

  if new_head_fsm>0 then
    --[[
    local FOV_x = 2*math.atan(640/2/545.6)
    local FOV_y = 2*math.atan(480/2/545.6)
    print("FOX:",FOV_x*180/math.pi,FOV_y*180/math.pi)
    --]]
    local r = math.max(math.min(1, (ballR-0.4)/0.4))
    if goalAngleMinAngle then yaw = r*goalAngleMinAngle + (1-r)*yaw end
  end   

  -- Fix head yaw while approaching (to reduce position error)
  if ball.x<fixTh[1] and math.abs(ball.y) < fixTh[2] then yaw=0.0 end

  Body.set_head_command({yaw, pitch});

  --print('\nball.t is '..ball.t)
  --print('tlost is '..tlost)
  if (t - ball.t > tLost) then
    print('Ball lost!');    
    return "lost";
  end

  eta = wcm.get_team_my_eta();
  if eta<min_eta_look and eta>0 then return end --don't look elsewhere if we are very close to the ball

  if role==5 then return end --Coach don't look at goals!
   
  if (t - t0 > timeout) then
    if t-wcm.get_goal_t()<0.50 then --We just saw the goalpost!
--      print("angle for min dist:",goalAngleMinDist)
--      print("angle for min angle:",goalAngleMinAngle)
      if goalAngleMinDist and goalAngleMinAngle and (goalAngleMinDist==goalAngleMinAngle) then
--We just saw closer goal, no need to look elsewhere        
--        print("NO TIMEOUT!")
      else
        print("Checking different goal")
        if role==0 then return "sweep" --Goalie, sweep to localize
        else return "timeout" end --Player, look at the goalpost
      end
    else
      print("Checking goal")
      if role==0 then return "sweep" --Goalie, sweep to localize

      else return "timeout" end --Player, look at the goalpost
    end
  end
end

function exit()
end
