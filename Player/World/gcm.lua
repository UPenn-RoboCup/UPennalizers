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

shared.game.paused = vector.zeros(1);
shared.game.gc_latency = vector.zeros(1);--GC message latency
shared.game.tm_latency = vector.zeros(1);--Team message latency

shared.game.was_penalized = vector.zeros(1);

shared.game.our_score = vector.zeros(1);
shared.game.opponent_score = vector.zeros(1);





shared.team = {};

shared.team.number = vector.zeros(1);
shared.team.player_id = vector.zeros(1);
shared.team.color = vector.zeros(1);
shared.team.role = vector.zeros(1);
shared.team.strat = vector.zeros(2)

shared.team.forced_role = vector.zeros(1); --for role testing

shared.team.pose_target = vector.zeros(3)
shared.team.shoot_target = vector.zeros(3)


--for double pass
shared.team.task_state = vector.zeros(2); 
shared.team.target = vector.zeros(3);
shared.team.balltarget = vector.zeros(3);

shared.team.gpsonly = vector.zeros(1)

shared.team.body_state = '';

shared.fsm = {};
shared.fsm.body_state = '';
shared.fsm.head_state = '';
shared.fsm.motion_state = '';
shared.fsm.game_state = '';



--Now we use nums to denote states
shared.game.bodystate = vector.zeros(1);
--1: bodyIdle
--2: bodyReady
--3: bodySearch
--4: bodyPosition
--5: bodyApproach
--6: bodyKick
--7: bodyWalkKick

shared.game.headstate = vector.zeros(1);

shared.game.walkingto = vector.zeros(2)
shared.game.shootingto = vector.zeros(2)

shared.coach = {}
shared.coach.side = vector.zeros(1)
shared.coach.confirm = vector.zeros(1)



util.init_shm_segment(getfenv(), _NAME, shared, shsize);

-- initialize player id
set_team_player_id( Config.game.playerID );

-- initialize team id
set_team_number(Config.game.teamNumber);

-- Initialize nPlayers
set_game_nplayers(Config.game.nPlayers);

-- initialize state to 'initial'
set_game_state(0);
set_team_role(Config.game.role);
set_game_bodystate(0)

use_gps_only = tonumber(os.getenv('USEGPS')) or 0
set_team_gpsonly(use_gps_only)

-- helper functions
function in_penalty()
  return get_game_penalty()[get_team_player_id()] > 0;
end

function say_id()
  Speak.talk('Player ID '..Config.game.playerID);
  Speak.talk('Team Number '..Config.game.teamNumber);
  Speak.talk("Team color equals " .. Config.game.teamColor)
end

