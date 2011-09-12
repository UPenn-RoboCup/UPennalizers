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


t0 = 0;
timeout = 1.0;

function entry()
  print(_NAME..' entry');
  t0 = Body.get_time();
  walk.stopAlign();

  HeadFSM.sm:set_state('headIdle');
  BodyFSM.sm:set_state('bodyIdle');

  Speak.talk('Initial');
	count=0;
  -- set indicator
  --Body.set_indicator_state({1,1,1});
end

function update()
	local change = 0;
  
	if Body.get_change_state()==1 then
		count=count+1;
	else
		count=0;
	end
	
	if count > 80 then
		change = 1;
		count = 0;
	end

  if (change == 1) then
    return 'playing';
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
end
