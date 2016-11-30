module(..., package.seeall);

require('Body')
require('fsm')
require('gcm')
require('Config')

require('bodyAnticipate')
require('bodyApproach')
require('bodyChase')
require('bodyCoach')
require('bodyDive')
require('bodyGotoCenter')
require('bodyIdle')
require('bodyKick')
require('bodyOrbit')
require('bodyPosition')
require('bodyPositionGoalie')
require('bodyReady')
require('bodyReadyMove')
require('bodySearch')
require('bodySearchGoalie')
require('bodyStart')
require('bodyStop')
require('bodyStill')
require('bodyUnpenalized')
require('bodyWalkKick')
require('bodyHandleKickOff')
require('bodyDribble')
require('bodySearchTeam')

sm = fsm.new(bodyIdle);
sm:add_state(bodyStart);
sm:add_state(bodyStop);
sm:add_state(bodyReady);
sm:add_state(bodyCoach);
sm:add_state(bodySearch);
sm:add_state(bodySearchGoalie);
sm:add_state(bodyApproach);
sm:add_state(bodyKick);
sm:add_state(bodyWalkKick);
sm:add_state(bodyOrbit);
sm:add_state(bodyGotoCenter);
sm:add_state(bodyPosition);
sm:add_state(bodyPositionGoalie);
sm:add_state(bodyAnticipate);
sm:add_state(bodyDive);
sm:add_state(bodyChase);
sm:add_state(bodyReadyMove);
sm:add_state(bodyUnpenalized);
sm:add_state(bodyHandleKickOff);
sm:add_state(bodyDribble);
sm:add_state(bodyStill);
sm:add_state(bodySearchTeam);


------------------------------------------------------
-- Advanced FSM (bodyPosition)
------------------------------------------------------
sm:set_transition(bodyStart, 'goalie', bodyAnticipate);  -- goto goalie sm
sm:set_transition(bodyStart, 'player', bodyHandleKickOff);	-- goto general player sm
sm:set_transition(bodyStart, 'coach', bodyAnticipate);	-- goto general player sm

sm: set_transition(bodyHandleKickOff, 'ballFree', bodyPosition)
sm: set_transition(bodyHandleKickOff, 'ourTurn', bodyPosition)


sm:set_transition(bodyPosition, 'timeout', bodyPosition);
sm:set_transition(bodyPosition, 'ballLost', bodySearch);
sm:set_transition(bodyPosition, 'ballClose', bodyOrbit);
sm:set_transition(bodyPosition, 'done', bodyApproach);
sm:set_transition(bodyPosition, 'fall', bodyPosition);
sm:set_transition(bodyPosition, 'TeamBall', bodyStill);
sm:set_transition(bodyPosition, 'goalie', bodyPositionGoalie); -- Note: Thought this line is not necessary since goalie never goto bodyPosition sm

sm:set_transition(bodyUnpenalized, 'done', bodyPosition);

sm:set_transition(bodySearch, 'ball', bodyPosition);
sm:set_transition(bodySearch, 'timeout', bodySearchTeam); --Alex: better searching + gotoCenter crashed once we think
sm:set_transition(bodySearch, 'ballgoalie', bodyChase);
sm:set_transition(bodySearch, 'timeoutgoalie', bodyPositionGoalie);
sm:set_transition(bodySearch, 'goalie', bodyPositionGoalie);

sm:set_transition(bodyGotoCenter, 'ballFound', bodyPosition);
sm:set_transition(bodyGotoCenter, 'done', bodySearchTeam);
sm:set_transition(bodyGotoCenter, 'timeout', bodySearchTeam);

sm:set_transition(bodySearchTeam, 'ball', bodyPosition);
sm:set_transition(bodySearchTeam, 'done', bodySearch);
sm:set_transition(bodySearchTeam, 'timeout', bodyPosition);

sm:set_transition(bodyOrbit, 'timeout', bodyPosition);
sm:set_transition(bodyOrbit, 'ballLost', bodySearch);
sm:set_transition(bodyOrbit, 'ballFar', bodyPosition);
sm:set_transition(bodyOrbit, 'done', bodyApproach);

sm:set_transition(bodyApproach, 'ballFar', bodyPosition);
sm:set_transition(bodyApproach, 'ballLost', bodySearch);
sm:set_transition(bodyApproach, 'timeout', bodyPosition);
sm:set_transition(bodyApproach, 'kick', bodyKick);
sm:set_transition(bodyApproach, 'walkkick', bodyWalkKick);
sm:set_transition(bodyApproach, 'fall', bodyPositionGoalie);
sm:set_transition(bodyApproach, 'fall', bodyPosition);

sm:set_transition(bodyKick, 'done', bodyPosition);
sm:set_transition(bodyKick, 'doneGoalie', bodyAnticipate);
sm:set_transition(bodyKick, 'timeout', bodyPosition);
sm:set_transition(bodyKick, 'reposition', bodyApproach);
sm:set_transition(bodyKick, 'fall', bodyPositionGoalie);
sm:set_transition(bodyKick, 'fall', bodyPosition); 
sm:set_transition(bodyWalkKick, 'done', bodyPosition);

sm:set_transition(bodyDribble, 'done', bodyPosition);
sm:set_transition(bodyDribble, 'timeout', bodyPosition);
sm:set_transition(bodyDribble, 'reposition', bodyApproach);
sm:set_transition(bodyDribble, 'fall', bodyPosition); 
sm:set_transition(bodyDribble, 'kick', bodyWalkKick); 

sm:set_transition(bodyReady, 'done', bodyReadyMove);
sm:set_transition(bodyReadyMove, 'fall', bodyReadyMove);

sm:set_transition(bodyStill, 'timeout', bodyPosition);
sm:set_transition(bodyStill, 'fall', bodyPosition); 
sm:set_transition(bodyStill, 'roleChange', bodyPosition); 
sm:set_transition(bodyStill, 'ballLost', bodySearch); 


--Escape transitions for goalie
sm:set_transition(bodyPositionGoalie, 'ready', bodyAnticipate);
sm:set_transition(bodyPositionGoalie, 'ballClose', bodyChase)
sm:set_transition(bodyPositionGoalie, 'player', bodyPosition);
sm:set_transition(bodyPositionGoalie, 'fall', bodyPositionGoalie);
sm:set_transition(bodyPositionGoalie, 'ballLost', bodySearchGoalie);
sm:set_transition(bodyPositionGoalie, 'timeout', bodyPositionGoalie);

sm:set_transition(bodyAnticipate,'player',bodyPosition);

----------------- Goalie States ---------------------
sm:set_transition(bodyAnticipate, 'timeout', bodyAnticipate); -- Timeout should stay in position, not start moving again
sm:set_transition(bodyAnticipate, 'ballClose', bodyChase); -- Chase the ball if it is close enough, since a shot will go in
sm:set_transition(bodyAnticipate, 'dive', bodyDive); -- Add a dive when a shot is detected
sm:set_transition(bodyAnticipate, 'position', bodyPositionGoalie); -- If out of position, then position self again
sm:set_transition(bodyAnticipate, 'search', bodySearchGoalie); -- If ball was seen recently and is to the side, transition to bodySearch

sm:set_transition(bodyChase, 'ballLost', bodyPositionGoalie);
sm:set_transition(bodyChase, 'ballFar', bodyPositionGoalie);
sm:set_transition(bodyChase, 'ballClose', bodyApproach);
sm:set_transition(bodyChase, 'fall', bodyPositionGoalie);

--The transition after a dive should just come from a fall (or timeout in case)
sm:set_transition(bodyDive, 'timeout', bodySearch);
sm:set_transition(bodyDive, 'reanticipate', bodyAnticipate);
sm:set_transition(bodyDive, 'fall', bodyChase); -- Chase the ball, since this could have been caused by a dive

sm:set_transition(bodySearchGoalie, 'ball', bodyChase);
sm:set_transition(bodySearchGoalie, 'done', bodyPositionGoalie);
sm:set_transition(bodySearchGoalie, 'timeout', bodyPositionGoalie);

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
