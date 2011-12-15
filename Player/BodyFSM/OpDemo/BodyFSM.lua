module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')

require('bodyIdle')
require('bodyStart')
require('bodySearch')
require('bodyApproach')
require('bodyKick')
require('bodyChase')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyChase);

sm:set_transition(bodyStart, 'done', bodySearch);

sm:set_transition(bodyChase, 'timeout', bodyChase);
sm:set_transition(bodyChase, 'ballLost', bodySearch);
sm:set_transition(bodyChase, 'ballClose', bodyApproach);

sm:set_transition(bodySearch, 'ball', bodyChase);
sm:set_transition(bodySearch, 'timeout', bodyChase);

sm:set_transition(bodyApproach, 'ballFar', bodyChase);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'timeout', bodyChase);
sm:set_transition(bodyApproach, 'kick', bodyKick);

sm:set_transition(bodyKick, 'done', bodyChase);

sm:set_transition(bodyChase, 'fall', bodyChase);
sm:set_transition(bodyApproach, 'fall', bodyChase);
sm:set_transition(bodyKick, 'fall', bodyChase);

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
