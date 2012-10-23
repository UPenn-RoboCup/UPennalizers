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

require('bodyPositionGoalie')
require('bodyAnticipate')
require('bodyChase')


sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodySearch);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyGotoCenter);

sm:add_state(bodyPositionGoalie);
sm:add_state(bodyAnticipate);
sm:add_state(bodyChase);

------------------------------------------------------
-- Simpler FSM (bodyChase and bodyorbit)
------------------------------------------------------

sm:set_transition(bodyStart, 'done', bodyPositionGoalie);

sm:set_transition(bodyPositionGoalie, 'ready', bodyAnticipate);
sm:set_transition(bodyPositionGoalie, 'ballClose', bodyChase)

sm:set_transition(bodyAnticipate,'timeout',bodyPositionGoalie);
sm:set_transition(bodyAnticipate,'done',bodyPositionGoalie);
sm:set_transition(bodyAnticipate, 'ballClose', bodyChase);

sm:set_transition(bodyChase, 'ballLost', bodyPositionGoalie);
sm:set_transition(bodyChase, 'ballFar', bodyPositionGoalie);
sm:set_transition(bodyChase, 'ballClose', bodyApproach);

sm:set_transition(bodyApproach, 'ballFar', bodyPositionGoalie);
sm:set_transition(bodyApproach, 'ballLost', bodyPositionGoalie);
sm:set_transition(bodyApproach, 'timeout', bodyPositionGoalie);
sm:set_transition(bodyApproach, 'kick', bodyKick);

sm:set_transition(bodyKick, 'done', bodyPositionGoalie);
sm:set_transition(bodyKick, 'reposition', bodyApproach);

sm:set_transition(bodyPositionGoalie, 'fall', bodyPositionGoalie);
sm:set_transition(bodyApproach, 'fall', bodyPositionGoalie);
sm:set_transition(bodyChase, 'fall', bodyPositionGoalie);
sm:set_transition(bodyKick, 'fall', bodyPositionGoalie);


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
