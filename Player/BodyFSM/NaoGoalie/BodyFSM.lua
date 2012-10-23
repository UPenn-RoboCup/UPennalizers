module(..., package.seeall);

require('fsm')
require('gcm')

require('bodyIdle')
require('bodyStart')
require('bodyReady')
require('bodyStop')
require('bodyApproach')
require('bodyKick')
require('bodyOrbit')
require('bodyPosition')
require('bodyGotoCenter')
require('bodyChase')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyPosition);
sm:add_state(bodyGotoCenter);
sm:add_state(bodyChase);

sm:set_transition(bodyStart, 'done', bodyPosition);

sm:set_transition(bodyPosition, 'timeout', bodyPosition);
sm:set_transition(bodyPosition, 'ballClose', bodyChase);
sm:set_transition(bodyPosition, 'ballLost', bodyGotoCenter);

sm:set_transition(bodyGotoCenter, 'ballFound', bodyPosition);
sm:set_transition(bodyGotoCenter, 'done', bodyGotoCenter);
sm:set_transition(bodyGotoCenter, 'timeout', bodyGotoCenter);
sm:set_transition(bodyGotoCenter, 'ballClose', bodyChase);

sm:set_transition(bodyOrbit, 'timeout', bodyPosition);
sm:set_transition(bodyOrbit, 'ballLost', bodyPosition);
sm:set_transition(bodyOrbit, 'ballFar', bodyPosition);
sm:set_transition(bodyOrbit, 'done', bodyApproach);

sm:set_transition(bodyApproach, 'ballFar', bodyPosition);
sm:set_transition(bodyApproach, 'ballLost', bodyPosition);
sm:set_transition(bodyApproach, 'timeout', bodyPosition);
sm:set_transition(bodyApproach, 'kick', bodyKick);
sm:set_transition(bodyApproach, 'ballAlign', bodyOrbit);

sm:set_transition(bodyChase, 'ballClose', bodyOrbit);
sm:set_transition(bodyChase, 'ballFar', bodyPosition);
sm:set_transition(bodyChase, 'ballLost', bodyPosition);
sm:set_transition(bodyChase, 'timeout', bodyPosition);

sm:set_transition(bodyKick, 'done', bodyPosition);

sm:set_transition(bodyPosition, 'fall', bodyPosition);
sm:set_transition(bodyApproach, 'fall', bodyPosition);
sm:set_transition(bodyKick, 'fall', bodyPosition);

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
