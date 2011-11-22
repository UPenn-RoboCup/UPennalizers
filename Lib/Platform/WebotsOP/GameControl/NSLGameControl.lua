module(... or "", package.seeall)

require('Config')
receiver = require('NSLGameControlReceiver')

teamNumber = Config.game.teamNumber;
playerID = Config.game.playerID;
teamIndex = 0;
teamColor = Config.game.team;
goalColor = Config.game.team;
--nPlayers = 3;
nPlayers = 5;

gamePacket = nil;
gameState = 0;

kickoff = true;
half = 1;

penalty = {};

score1=0; --our score
score2=0; --opponents' score
timeRemaining = 600;

-- For use in Broadcast
tLast=unix.time();

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

function get_goal_color()
  return goalColor;
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
  if teamIndex == 0 then
    return buttonPenalty
  else
    return penalty[teamIndex]
  end
end

function get_opponent_penalty()
  return penalty[3-teamIndex]
end

function receive()
  return receiver.receive();
end

function entry()
end

function update()
  -- get latest game control packet
  gamePacket = receive(); 

  if (gamePacket and unix.time() - gamePacket.time < 10) then
    tLast=unix.time();
    -- Assume a teamIndex that is not us until proven otherwise
    -- (listen for which teams are playing)
    -- Always check for the teamIndex!
    teamIndex = 0;
    for i = 1,2 do
      if gamePacket.teams[i].teamNumber == teamNumber then
        teamIndex = i;
        if nPlayers ~= gamePacket.playersPerTeam then
          nPlayers = gamePacket.playersPerTeam;
        end --if
      end --if
    end --for

--[[
    -- if the game control state has not been set check for the teamIndex 
    if gameState == 0 then
      teamIndex = 0;
      for i = 1,2 do
        if gamePacket.teams[i].teamNumber == teamNumber then
          teamIndex = i;
          gameState = gamePacket.state;

          if nPlayers ~= gamePacket.playersPerTeam then
            nPlayers = gamePacket.playersPerTeam;
            penalty = {};
            for t = 1,2 do
              penalty[t] = {};
              for p = 1,nPlayers do
                penalty[t][p] = 0;
              end
            end
          end

        end
      end
    end

  end
--]] 

  if teamIndex ~= 0 then    -- we received a game control packet
    -- Update game state (initial, ready, etc.)
    gameState = gamePacket.state;

    -- update team and goal color
    teamColor = gamePacket.teams[teamIndex].teamColour;
    goalColor = gamePacket.teams[teamIndex].goalColour;

    -- Update the score
    score1=gamePacket.teams[teamIndex].score; --our score
    score2=gamePacket.teams[3-teamIndex].score; --opponents' score

    -- Update the kickoff team
    if( gamePacket.kickOffTeam == 2 ) then -- dropball
      kickoff = -1;
    else
      kickoff = gamePacket.teams[gamePacket.kickOffTeam+1].teamNumber;
    end

    -- Update which half it is
    if gamePacket.firstHalf==1 then
      half = 1;
    else
      half = 2;
    end

    -- Update time remaining
    timeRemaining = gamePacket.secsRemaining;

    -- update player info
    for t=1,2 do
      for p=1,nPlayers do
        penalty[t][p] = gamePacket.teams[t].player[p].penalty;
      end
    end
    end -- team index

  else
    -- no game packets received use buttons to update states
    if (Body.get_sensor_button()[1] > 0) then
      -- advance state
      if gameState < 3 then
        gameState = gameState + 1;
      elseif gameState == 3 then
        -- playing - toggle penalty state
        buttonPenalty[playerID] = 1 - buttonPenalty[playerID]; 
      end
    end
  end

end

function exit()
end
