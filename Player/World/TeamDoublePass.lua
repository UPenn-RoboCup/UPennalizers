module(..., package.seeall);

require('Config');
require('Body');
require('Comm');
require('Speak');
require('vector');
require('serialization');

require('wcm');
require('gcm');

Comm.init(Config.dev.ip_wireless,Config.dev.ip_wireless_port);
print('Receiving Team Message From',Config.dev.ip_wireless);
playerID = gcm.get_team_player_id();

msgTimeout = Config.team.msgTimeout;
nonAttackerPenalty = Config.team.nonAttackerPenalty;
nonDefenderPenalty = Config.team.nonDefenderPenalty;

--Player ID: 1 and 2

count = 0;

state = {};
state.teamNumber = gcm.get_team_number();
state.id = playerID;
state.teamColor = gcm.get_team_color();
state.time = Body.get_time();
state.role = -1;
state.pose = {x=0, y=0, a=0};
state.ball = {t=0, x=1, y=0};
state.attackBearing = 0.0;
state.penalty = 0;
state.tReceive = Body.get_time();
state.battery_level = wcm.get_robot_battery_level();
state.fall=0;

states = {};
states[playerID] = state;

--Init values
role=1;
team_task_state={0,0};

function recv_msgs()
  while (Comm.size() > 0) do 
    msg = Comm.receive();
    t = serialization.deserialize(msg);

    --Ball GPS Info hadling
    if msg and #msg==14 then --Ball position message
      ball_gpsx=(tonumber(string.sub(msg,2,6))-5)*2;
      ball_gpsy=(tonumber(string.sub(msg,8,12))-5)*2;
      wcm.set_robot_gps_ball({ball_gpsx,ball_gpsy,0});

    elseif (t and (t.teamNumber) and (t.teamNumber == state.teamNumber) and (t.id) and (t.id ~= playerID)) then
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
  state.battery_level = wcm.get_robot_battery_level();
  state.fall = wcm.get_robot_is_fall_down();

  team_task_state = gcm.get_team_task_state();
  state.task_state = team_task_state[role];

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

  -- The player with smaller player ID act as the left player (role 1)
  -- The player with bigger player ID act as the right player (role 2)
  -- After one role change, never change again

  for id = 1,5 do 
    if states[id] then
     --Got message from somebody
      --Change my role if mine is 1 and his player ID is smaller than mine
      if role==1 and id<playerID then
	set_role(2);
      end

      --Only advance task state
      if states[id].task_state> team_task_state[states[id].role] then
        team_task_state[states[id].role] = states[id].task_state;
	print("Team task state updated;",unpack(team_task_state))
      end
    end
  end
  -- update shm
  update_shm() 
end

function update_shm() 
  -- update the shm values
  gcm.set_team_role(role);
  gcm.set_team_task_state(team_task_state);
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
      Speak.talk('Left player');
    elseif role == 2 then     -- defend
      Speak.talk('Right player');
    end
  end
  update_shm();
end

--Default role is 1
set_role(1);

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
