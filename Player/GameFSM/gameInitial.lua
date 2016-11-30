module(..., package.seeall);

require('Config')
require('Body');
require('walk')
require('BodyFSM')
require('HeadFSM')
require('Speak')
require('vector')
require('unix')
require('gcm')
require('BodyFSM')
require('HeadFSM')


t0 = 0;
timeout = 1.0;

function entry()
  print(_NAME..' entry');
  t0 = Body.get_time();
  walk.stop();

  if Config.game.role == 5 then --COACH
    HeadFSM.sm:set_state('headIdle');
    BodyFSM.sm:set_state('bodyCoach')    
    return
  end

  HeadFSM.sm:set_state('headIdle');
--If it is already idle, we should not go back to idle!

  local bodyState = gcm.get_game_bodystate()
  print("bodystate:", bodyState)
  if bodyState~=1 then
    BodyFSM.sm:set_state('bodyIdle');
  end

  Speak.talk('Initial');

  -- set indicator
  Body.set_indicator_state({0,0,0});


end

function update()
  local state = gcm.get_game_state();  
  
  if (state == 1) then
    return 'ready';
  elseif (state == 2) then
    return 'set';
  elseif (state == 3) then
    return 'playing';
  elseif (state == 4) then
    return 'finished';
  end

  -- if we have not recieved game control packets then left bumper switches team color
  if (unix.time() - gcm.get_game_last_update() > 10.0) then
    if (Body.get_change_team() == 1) then
      gcm.set_team_color(1 - gcm.get_team_color());
    end
    if (Body.get_change_kickoff() == 1) then
      gcm.set_game_kickoff(1 - gcm.get_game_kickoff());
    end
  end
end

function exit()
  walk.start(); 
end
