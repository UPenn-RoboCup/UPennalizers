module(..., package.seeall);

require('Config');
require('Body');
require('Comm');
require('Speak');
require('vector');
require('serialization');

require('wcm');
require('gcm');

playerID = gcm.get_team_player_id();

msgTimeout = Config.team.msgTimeout;
nonAttackerPenalty = Config.team.nonAttackerPenalty;
nonDefenderPenalty = Config.team.nonDefenderPenalty;

role = -1;

count = 0;

state = {};
state.teamNumber = gcm.get_team_number();
state.id = playerID;
state.teamColor = gcm.get_team_color();
state.time = Body.get_time();
state.role = role;
state.pose = {x=0, y=0, a=0};
state.ball = {t=0, x=1, y=0};
state.attackBearing = 0.0;
state.penalty = 0;
state.tReceive = Body.get_time();


states = {};
states[playerID] = state;

function recv_msgs()
  while (Comm.size() > 0) do 
    t = serialization.deserialize(Comm.receive());
    if (t and (t.teamNumber) and (t.teamNumber == state.teamNumber) and (t.id) and (t.id ~= playerID)) then
      t.tReceive = Body.get_time();
      states[t.id] = t;
    end
  end
end

function entry()
end

function update()
  count = count + 1;

  state.time = Body.get_time();
  state.teamNumber = gcm.get_team_number();
  state.teamColor = gcm.get_team_color();
  state.pose = wcm.get_pose();
  state.ball = wcm.get_ball();
  state.role = role;
  state.attackBearing = wcm.get_attack_bearing();
  if gcm.in_penalty() then
    state.penalty = 1;
  else
    state.penalty = 0;
  end

  if (math.mod(count, 1) == 0) then
    Comm.send(serialization.serialize(state));
    --Copy of message sent out to other players
    state.tReceive = Body.get_time();
    states[playerID] = state;
  end

  -- receive new messages
  recv_msgs();

  -- eta and defend distance calculation:
  eta = {};
  ddefend = {};
  t = Body.get_time();
  for id = 1,4 do

    if not states[id] or not states[id].ball.x then
      -- no message from player have been received
      eta[id] = math.huge;
      ddefend[id] = math.huge;

    else
      -- eta to ball
      rBall = math.sqrt(states[id].ball.x^2 + states[id].ball.y^2);
      tBall = states[id].time - states[id].ball.t;
      eta[id] = rBall/0.10 + 4*math.max(tBall-1.0,0);
      
      -- distance to goal
      dgoalPosition = vector.new(wcm.get_goal_defend());
      pose = wcm.get_pose();
      ddefend[id] = math.sqrt((pose.x - dgoalPosition[1])^2 + (pose.y - dgoalPosition[2])^2);

      if (states[id].role ~= 1) then
        -- Non attacker penalty:
        eta[id] = eta[id] + nonAttackerPenalty;
      end
      if (states[id].penalty > 0) or (Body.get_time() - states[id].tReceive > msgTimeout) then
        eta[id] = math.huge;
      end

      if (states[id].role ~= 2) then
        -- Non defender penalty:
        ddefend[id] = ddefend[id] + 0.3;
      end
      if (states[id].penalty > 0) or (t - states[id].tReceive > msgTimeout) then
        ddefend[id] = math.huge;
      end

    end
  end
--[[
  if count % 100 == 0 then
    print('---------------');
    print('eta:');
    util.ptable(eta)
    print('ddefend:');
    util.ptable(ddefend)
    print('---------------');
  end
--]]
  -- goalie never changes role
  if playerID ~= 1 then
    eta[1] = math.huge;
    ddefend[1] = math.huge;

    minETA, minEtaID = min(eta);
    if minEtaID == playerID then
      -- attack
      set_role(1);
    else
      -- furthest player back is defender
      minDDefID = 0;
      minDDef = math.huge;
      for id = 2,4 do
        if id ~= minEtaID and ddefend[id] <= minDDef then
          minDDefID = id;
          minDDef = ddefend[id];
        end
      end

      if minDDefID == playerID then
        -- defense 
        set_role(2);
      else
        -- support
        set_role(3);
      end
    end
  end

  -- update shm
  update_shm() 
end

function update_shm() 
  -- update the shm values
  gcm.set_team_role(role);
end

function exit()
end

function get_role()
  return role;
end

function set_role(r)
  if role ~= r then 
    role = r;
    Body.set_indicator_role(role);
    if role == 1 then
      -- attack
      Speak.talk('Attack');
    elseif role == 2 then
      -- defend
      Speak.talk('Defend');
    elseif role == 3 then
      -- support
      Speak.talk('Support');
    elseif role == 0 then
      -- goalier
      Speak.talk('Goalie');
    else
      -- no role
      Speak.talk('ERROR: Unkown Role');
    end
  end
end
-- Webots has id=0 map to goalie.  Real robots has id=1 map to goalie
if (string.find(Config.platform.name,'Webots')) then
  set_role(playerID);
else
  set_role(playerID-1);
end

function get_player_id()
  return playerID; 
end

function min(t)
  local imin = 0;
  local tmin = math.huge;
  for i = 1,#t do
    if (t[i] < tmin) then
      tmin = t[i];
      imin = i;
    end
  end
  return tmin, imin;
end
