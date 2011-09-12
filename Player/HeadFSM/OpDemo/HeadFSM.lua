module(..., package.seeall);

require('Body')
require('fsm')

require('headIdle')
require('headScan')
require('headTrack')

sm = fsm.new(headIdle);
sm:add_state(headScan);
sm:add_state(headTrack);

sm:set_transition(headIdle, "timeout", headTrack);
sm:set_transition(headTrack, "lost", headScan);
sm:set_transition(headTrack, "timeout", headTrack);
sm:set_transition(headScan, "ball", headTrack);
sm:set_transition(headScan, "timeout", headScan);

function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
