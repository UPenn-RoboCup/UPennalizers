module(..., package.seeall);

require('Body')
require('walk')
require('Speak')
require('vector')
require('gcm')
require('BodyFSM')
require('HeadFSM')

t0 = 0;
timeout = 2.0;

function entry()
  print(_NAME..' entry');

  t0 = Body.get_time();


  if Config.game.role == 5 then --COACH
    HeadFSM.sm:set_state('headReadyCoach');    
    BodyFSM.sm:set_state('bodyCoach')     
    return
  end
  
  walk.start();

  -- body ready state
  BodyFSM.sm:set_state('bodyReady');
  HeadFSM.sm:set_state('headReady');

  Speak.talk('Ready');

  -- set indicator
  Body.set_indicator_state({0,0,1});
end

function update()
  
  local state = gcm.get_game_state();

  if (state == 0) then
    return 'initial';
  elseif (state == 2) then
    return 'set';
  elseif (state == 3) then
    return 'playing';
  elseif (state == 4) then
    return 'finished';
  end
  if Config.game.role == 5 then return end --COACH

  -- check for penalty
  if gcm.in_penalty() then
    return 'penalized';
  end
end

function exit()
end
