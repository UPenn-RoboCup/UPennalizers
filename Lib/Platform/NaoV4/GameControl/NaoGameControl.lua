module(... or "", package.seeall)

require('Config')
require('util')
require('gcm')
require('Speak')
receiver = require('NaoGameControlReceiver')

teamNumber = Config.game.teamNumber;
playerID = gcm.get_team_player_id();
teamIndex = 0;
nPlayers = Config.game.nPlayers;
teamColor = -1;
gcm.set_team_color(Config.game.teamColor);

gamePacket = nil;
gameState = 0;
timeRemaining = 0;
lastUpdate = 0;

kickoff = -1;
half = 1;

teamPenalty = {0,0,0,0};

penalty = {};
for t = 1,2 do
  penalty[t] = {};
  for p = 1,nPlayers do
    penalty[t][p] = 0;
  end
end
-- use if no game packets received
buttonPenalty = {};
for p = 1,nPlayers do
  buttonPenalty[p] = 0;
end

function get_team_color()
  return teamColor;
end

function get_state()
  return gameState;
end

function get_kickoff_team()
  return kickoff;
end

function which_half()
  return half;
end

function get_penalty()
  return teamPenalty;
end

function set_team_color(color)
  if teamColor ~= color then
    teamColor = color;
    if (teamColor == 1) then
      Speak.talk('I am on the red team');
      Body.set_actuator_ledFootLeft({1, 0, 0});
    else
      Speak.talk('I am on the blue team');
      Body.set_actuator_ledFootLeft({0, 0, 1});
    end
  end
end

function set_kickoff(k)
  if (kickoff ~= k) then
    kickoff = k;
    if (kickoff == 1) then
      Speak.talk('We have kickoff');
      Body.set_actuator_ledFootRight({1, 1, 1});
    else
      Speak.talk('Opponents have kickoff');
      Body.set_actuator_ledFootRight({0, 0, 0});
    end
  end   
end

function receive()
  return receiver.receive();
end

function entry()
end

count = 0;
updateCount = 1;
buttonPressed = 0;
function update()
  -- get latest game control packet
  gamePacket = receive();
  count = count + 1;

  if (gamePacket and unix.time() - gamePacket.time < 10) then
    -- if the game control state has not been set check for the teamIndex 
    teamIndex = 0;
    for i = 1,2 do
      if gamePacket.teams[i].teamNumber == teamNumber then
        teamIndex = i;
      end
    end

    if teamIndex ~= 0 then
      updateCount = count; 

      -- we received a game control packet
      lastUpdate = unix.time();

      -- upadate game state
      gameState = gamePacket.state;

      -- update team color
      set_team_color(gamePacket.teams[teamIndex].teamColour); 

      -- update kickoff team
      if (gamePacket.teams[gamePacket.kickOffTeam+1].teamNumber == teamNumber) then
        set_kickoff(1);
      else
        set_kickoff(0);
      end

      -- update which half it is
      if gamePacket.firstHalf == 1 then
        half = 1;
      else
        half = 2;
      end

      -- update game time remaining
      timeRemaining = gamePacket.secsRemaining;

      -- update player penalty info
      for p=1,nPlayers do
        teamPenalty[p] = gamePacket.teams[teamIndex].player[p].penalty;
      end
    end
  end

  if (unix.time() - lastUpdate > 10.0) then
    -- we have not received a game control packet in over 10 seconds
    if (updateCount < count - 1 ) then
      Speak.talk('Off Game Controller');
    end
    updateCount = count; 
    teamIndex = 0;

    -- update team color (it is set in gameInitial)
    set_team_color(gcm.get_team_color());

    -- update kickoff
    set_kickoff(gcm.get_game_kickoff());

    -- use buttons to advance states
    if (Body.get_change_state() == 1) then
      buttonPressed = 1;
    else
      if buttonPressed ==1 then
        -- advance state
        if (gameState < 3) then
          gameState = gameState + 1;
        elseif (gameState == 3) then
          -- playing - toggle penalty state
          teamPenalty[playerID] = 1 - teamPenalty[playerID]; 
        end
      end
      buttonPressed = 0;
    end
  end

  -- update shm
  if (updateCount == count) then
    update_shm();
  end
end

function update_shm()
  -- update the shm values  
  gcm.set_game_state(gameState);
  gcm.set_game_nplayers(nPlayers);
  gcm.set_game_kickoff(kickoff);
  gcm.set_game_half(half);
  gcm.set_game_penalty(get_penalty());
  gcm.set_game_time_remaining(timeRemaining);
  gcm.set_game_last_update(lastUpdate);

  gcm.set_team_number(teamNumber);
  gcm.set_team_color(teamColor);
end

function exit()
end
