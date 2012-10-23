module(..., package.seeall);

require('controller')
require('GameControlPacket')
require('Config')
require('vector')
require('util')
require('gcm')
require('Speak')
require('Comm')


teamNumber = Config.game.teamNumber;
playerID = gcm.get_team_player_id();
teamIndex = 0;
nPlayers = Config.game.nPlayers;
teamColor = -1;
gcm.set_team_color(Config.game.teamColor);

gameState = 0;
timeRemaining = 0;
lastUpdate = 0;

kickoff = -1;
half = 1;

teamPenalty = vector.zeros(Config.game.nPlayers);

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
      Body.set_indicator_team({1, 0, 0});
    else
      Speak.talk('I am on the blue team');
      Body.set_indicator_team({0, 0, 1});
    end
  end
end

function set_kickoff(k)
  if (kickoff ~= k) then
    kickoff = k;
    if (kickoff == 1) then
      Speak.talk('We have kickoff');
      Body.set_indicator_kickoff({1, 1, 1});
    else
      Speak.talk('Opponents have kickoff');
      Body.set_indicator_kickoff({0, 0, 0});
    end
  end   
end

function entry()
end

function update()
  gamePacket = Comm.get_game_control_data();

  if (gamePacket) then
    -- find team index
    teamIndex = 0;
    for i = 1,2 do
      if (gamePacket.teams[i].teamNumber == teamNumber) then
        teamIndex = i;
      end
    end

    -- was our team in the game controller message
    if (teamIndex ~= 0) then
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
      if (gamePacket.firstHalf == 1) then
        half = 1;
      else
        half = 2;
      end

      -- update game time remaining
      timeRemaining = gamePacket.secsRemaining;

      -- update player penalty info
      for p = 1,nPlayers do
        teamPenalty[p] = gamePacket.teams[teamIndex].player[p].penalty;
      end

      update_shm();
    end
  end

end

function exit()
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

