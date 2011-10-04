module(..., package.seeall);

require('fsm')
require('gcm')

require('gameInitial')
require('gamePlaying')
require('gamePenalized')

sm = fsm.new(gameInitial);
sm:add_state(gamePlaying);
sm:add_state(gamePenalized);

sm:set_transition(gameInitial, "playing", gamePlaying);

sm:set_transition(gamePlaying, "penalized", gamePenalized);

sm:set_transition(gamePenalized, "playing", gamePlaying);

-- set state debug handle to shared memory settor
sm:set_state_debug_handle(gcm.set_fsm_game_state);

function entry()
  sm:entry()
end

function update()
  sm:update();
end

function exit()
  sm:exit();
end
