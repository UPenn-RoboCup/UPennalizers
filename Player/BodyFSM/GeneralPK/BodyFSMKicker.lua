module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')
require('Config')

require('bodyIdle')
require('bodyStart')
require('bodyStop')
require('bodyReady')

require('bodySearch')
require('bodyApproach')
require('bodyAlign')
require('bodyAlignStep')
require('bodyKick')
require('bodyPositionSimple')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);

sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyAlign);
sm:add_state(bodyAlignStep);
sm:add_state(bodyKick);
sm:add_state(bodyPositionSimple);


------------------------------------------------------
-- Simpler FSM (bodyChase and bodyorbit)
------------------------------------------------------

sm:set_transition(bodyStart, 'done', bodyPositionSimple);

sm:set_transition(bodyPositionSimple, 'timeout', bodyPositionSimple);
sm:set_transition(bodyPositionSimple, 'ballLost', bodySearch);
sm:set_transition(bodyPositionSimple, 'ballClose', bodyApproach);
sm:set_transition(bodyPositionSimple, 'done', bodyApproach);

sm:set_transition(bodySearch, 'ball', bodyPositionSimple);
sm:set_transition(bodySearch, 'timeout', bodySearch);

sm:set_transition(bodyApproach, 'ballFar', bodyPositionSimple);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'timeout', bodyPositionSimple);
sm:set_transition(bodyApproach, 'kick', bodyKick);
sm:set_transition(bodyApproach, 'kick', bodyAlign);

sm:set_transition(bodyKick, 'timeout', bodyApproach);
sm:set_transition(bodyAlign, 'done', bodyKick);
--sm:set_transition(bodyAlign, 'reposition', bodyApproach);
sm:set_transition(bodyAlign, 'reposition', bodyAlignStep);

sm:set_transition(bodyAlignStep, 'done', bodyAlign);

sm:set_transition(bodyKick, 'timeout', bodyPositionSimple);
sm:set_transition(bodyKick, 'done', bodyPositionSimple);


sm:set_transition(bodyAlign, 'fall', bodyPositionSimple);
sm:set_transition(bodyPositionSimple, 'fall', bodyPositionSimple);
sm:set_transition(bodyApproach, 'fall', bodyPositionSimple);
sm:set_transition(bodyKick, 'fall', bodyPositionSimple);

-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_body_state);


function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
