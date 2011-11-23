module(..., package.seeall);

require('fsm')
require('bodyIdle')
require('bodyChase')
require('bodySearch')
require('bodyApproach')
require('bodyPickup')
require('bodyFaceOff');

sm = fsm.new(bodyIdle);
sm:add_state(bodyChase);
sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyPickup);
sm:add_state(bodyFaceOff);

-- Search for the stretcher
sm:set_transition(bodySearch, 'ball', bodyChase);
sm:set_transition(bodySearch, 'timeout', bodySearch);

-- Chase after the stretcher
sm:set_transition(bodyChase, 'ballLost', bodySearch);
sm:set_transition(bodyChase, 'ballClose', bodyApproach);
sm:set_transition(bodyChase, 'timeout', bodyChase);

-- Approach the stretcher (et into position)
sm:set_transition(bodyApproach, 'ballFar', bodyChase);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'pickup', bodyPickup);
sm:set_transition(bodyApproach, 'timeout', bodyChase);

-- Pickup the stretcher
sm:set_transition(bodyPickup, 'done', bodyFaceOff);

-- Face each other with the stretcher
sm:set_transition(bodyFaceOff, 'timeout', bodyFaceOff);

-- If you fall, what do you do?
sm:set_transition(bodyChase, 'fall', bodySearch);
sm:set_transition(bodyApproach, 'fall', bodySearch);
sm:set_transition(bodyPickup, 'fall', bodyIdle);

function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
