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
require('bodyKick')
require('bodyOrbit')
require('bodyGotoCenter')
require('bodyPositionSimple')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyGotoCenter);
sm:add_state(bodyPositionSimple);


------------------------------------------------------
-- Simpler FSM (bodyChase and bodyorbit)
------------------------------------------------------

sm:set_transition(bodyStart, 'done', bodyPositionSimple);

sm:set_transition(bodyPositionSimple, 'timeout', bodyPositionSimple);
sm:set_transition(bodyPositionSimple, 'ballLost', bodySearch);
sm:set_transition(bodyPositionSimple, 'ballClose', bodyOrbit);
sm:set_transition(bodyPositionSimple, 'done', bodyApproach);

sm:set_transition(bodySearch, 'ball', bodyPositionSimple);
sm:set_transition(bodySearch, 'timeout', bodyGotoCenter);

sm:set_transition(bodyGotoCenter, 'ballFound', bodyPositionSimple);
sm:set_transition(bodyGotoCenter, 'done', bodySearch);
sm:set_transition(bodyGotoCenter, 'timeout', bodySearch);

sm:set_transition(bodyOrbit, 'timeout', bodyPositionSimple);
sm:set_transition(bodyOrbit, 'ballLost', bodySearch);
sm:set_transition(bodyOrbit, 'ballFar', bodyPositionSimple);
sm:set_transition(bodyOrbit, 'done', bodyApproach);

sm:set_transition(bodyApproach, 'ballFar', bodyPositionSimple);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'timeout', bodyPositionSimple);
sm:set_transition(bodyApproach, 'kick', bodyKick);

sm:set_transition(bodyKick, 'done', bodyPositionSimple);
sm:set_transition(bodyKick, 'reposition', bodyApproach);

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
