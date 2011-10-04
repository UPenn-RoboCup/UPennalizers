module(..., package.seeall);

require('shm');
require('util');
require('vector');
require('Config');
require('Speak');

-- shared properties
shared = {};
shsize = {};

shared.game = {};
shared.game.state = vector.zeros(1);
shared.game.nplayers = vector.zeros(1);
shared.game.kickoff = vector.zeros(1);
shared.game.half = vector.zeros(1);
shared.game.penalty = vector.zeros(Config.game.nPlayers);
shared.game.opponent_penalty = vector.zeros(Config.game.nPlayers);
shared.game.time_remaining = vector.zeros(1);
shared.game.last_update = vector.zeros(1);

shared.team = {};
shared.team.number = vector.zeros(1);
shared.team.player_id = vector.zeros(1);
shared.team.color = vector.zeros(1);
shared.team.role = vector.zeros(1);

shared.fsm = {};
shared.fsm.body_state = '';
shared.fsm.head_state = '';
shared.fsm.motion_state = '';
shared.fsm.game_state = '';

util.init_shm_segment(getfenv(), _NAME, shared, shsize);


-- initialize player id
set_team_player_id(Config.game.playerID);
Speak.talk('Player ID '..Config.game.playerID);

-- initialize state to 'initial'
set_game_state(0);

-- helper functions

function in_penalty()
  return get_game_penalty()[get_team_player_id()] > 0;
end

