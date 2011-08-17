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

  BodyFSM.sm:set_state('bodyStart');
  HeadFSM.sm:set_state('headStart');

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
  if gcm.in_penalty() then
    return 'penalized';
  end
end

function exit()
end
