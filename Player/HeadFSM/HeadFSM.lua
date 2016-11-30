module(..., package.seeall);
require('Body')
require('fsm')
require('gcm')

require('headIdle')
require('headStart')
require('headReady')
require('headReadyLookGoal')
require('headScan')
require('headTrack')
require('headTrackGoalie')
require('headKickFollow')
require('headLookGoal')
require('headSweep')
require('headKick')
require('headLog')
require('headCoach')
require('headReadyCoach')
require('headTrackCoach')

sm = fsm.new(headIdle);
sm:add_state(headStart);
sm:add_state(headReady);
sm:add_state(headReadyLookGoal);
sm:add_state(headScan);
sm:add_state(headTrack);
sm:add_state(headTrackGoalie);
sm:add_state(headKickFollow);
sm:add_state(headLookGoal);
sm:add_state(headSweep);
sm:add_state(headKick);
sm:add_state(headLog);
sm:add_state(headCoach);
sm:add_state(headReadyCoach);
sm:add_state(headTrackCoach);



---------------------------------------------
--Game FSM with looking at the goal
---------------------------------------------
sm:set_transition(headReadyCoach, 'ball', headTrackCoach);
sm:set_transition(headReadyCoach, 'timeout', headTrackCoach);

sm:set_transition(headTrackCoach, 'lost', headReadyCoach);
sm:set_transition(headTrackCoach, 'timeout', headReadyCoach);
sm:set_transition(headTrackCoach, 'sweep', headReadyCoach);
---------------------------------------------

sm:set_transition(headStart, 'done', headTrack);

sm:set_transition(headReady, 'done', headReady);

sm:set_transition(headReadyLookGoal, 'timeout', headReady);
sm:set_transition(headReadyLookGoal, 'lost', headReady);

sm:set_transition(headTrack, 'lost', headScan);
sm:set_transition(headTrack, 'timeout', headSweep); --Alex: removed LookGoal since it isn't very useful now
sm:set_transition(headTrack, 'sweep', headSweep);
--sm:set_transition(headTrack, 'lost coach', headCoach);

sm:set_transition(headTrackGoalie, 'lost', headScan);

sm:set_transition(headKick, 'ballFar', headTrack);
sm:set_transition(headKick, 'ballLost', headScan);
sm:set_transition(headKick, 'timeout', headTrack);

sm:set_transition(headKickFollow, 'lost', headScan);
sm:set_transition(headKickFollow, 'ball', headTrack);

sm:set_transition(headLookGoal, 'timeout', headTrack);
sm:set_transition(headLookGoal, 'lost', headSweep);

sm:set_transition(headSweep, 'done', headTrack);
--sm:set_transition(headSweep, 'done coach', headCoach);

sm:set_transition(headScan, 'ball', headTrack);
sm:set_transition(headScan, 'timeout', headScan);

--Transition between player, moving goalie, diving goalie states

sm:set_transition(headTrack, 'goalie', headTrackGoalie);

sm:set_transition(headTrackGoalie, 'player', headTrack);
sm:set_transition(headTrackGoalie, 'lost', headScan);

sm:set_transition(headCoach,'timeout',headCoach);
sm:set_transition(headCoach,'ball',headTrack);
-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_head_state);

function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
