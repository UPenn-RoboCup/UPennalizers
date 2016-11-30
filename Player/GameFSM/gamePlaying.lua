module(..., package.seeall);

require('Body')
require('walk')
require('BodyFSM')
require('HeadFSM')
require('Speak')
require('vector')
require('gcm')
require('BodyFSM')
require('HeadFSM')

t0 = 0;

function entry()
  print(_NAME..' entry');

  t0 = Body.get_time();


  if Config.game.role == 5 then --COACH
--    HeadFSM.sm:set_state('headCoach')
    HeadFSM.sm:set_state('headStart')
    BodyFSM.sm:set_state('bodyCoach')    
    return
  end

  was_penalized = gcm.get_game_was_penalized();
  print('Was Penalized:',was_penalized)
  if was_penalized>0 then
    BodyFSM.sm:set_state('bodyUnpenalized');
    HeadFSM.sm:set_state('headStart');
    walk.start();
  else
    BodyFSM.sm:set_state('bodyStart');
    HeadFSM.sm:set_state('headStart');
  end

  gcm.set_game_was_penalized(0);

  Speak.talk('Playing');

  -- set indicator
  Body.set_indicator_state({0,1,0});
end

function update()
  local state = gcm.get_game_state();

  if (state == 0) then
    return 'initial';
  elseif (state == 1) then
    return 'ready';
  elseif (state == 2) then
    return 'set';
  elseif (state == 4) then
    return 'finished';
  end

  -- check for penalty 
  if gcm.in_penalty() and Config.game.role<5 then
    return 'penalized';
  end
end

function exit()
end
