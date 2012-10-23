module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')
require('Config')


require('bodyIdle')
require('bodyStart')
require('bodyStop')
require('bodyReady')

require('bodyStepOut')
require('bodyPositionGoalie')
require('bodyAnticipate')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);

sm:add_state(bodyStepOut);
sm:add_state(bodyPositionGoalie);
sm:add_state(bodyAnticipate);

sm:set_transition(bodyStart, 'done', bodyStepOut);

sm:set_transition(bodyStepOut, 'done', bodyAnticipate);
sm:set_transition(bodyAnticipate,'done',bodyPositionGoalie);
sm:set_transition(bodyPositionGoalie, 'fall', bodyPositionGoalie);
sm:set_transition(bodyPositionGoalie, 'done', bodyAnticipate);

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
