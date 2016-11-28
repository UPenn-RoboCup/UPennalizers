module(..., package.seeall);
require('util')
require('parse_hostname')
require('vector')
require('os')


platform = {};
platform.name = 'WebotsNao'

listen_monitor = 1
webots = 1

-- Parameters Files
params = {}
params.name = {"Walk", "World", "Kick", "Vision", "FSM", "Camera", "Robot"};
util.LoadConfig(params, platform)




params.kick = 'Kick/Config_WebotsNao_Kick'
params.vision = 'Vision/Config_WebotsNao_Vision'
params.camera = 'Vision/Config_WebotsNao_Camera'
params.fsm = 'FSM/Config_WebotsNao_FSM'

-- Device Interface Libraries
dev = {};
dev.comm = 'WebotsComm'
dev.body = 'NaoWebotsBody'; 
dev.camera = 'NaoWebotsCam';
dev.kinematics = 'NaoKinematics';
dev.game_control='WebotsGameControl';
dev.team= 'TeamSPL';
largestep_enable = true;


-- Game Parameters
game = {};
game.teamNumber = (os.getenv('TEAM_ID') or 0) + 0;
-- Player: 1~5, Role: 0~4
game.playerID = tonumber(os.getenv('PLAYER_ID') or 0)
game.robotID = (game.playerID);
game.role = game.playerID-1; -- default role, 0 for goalie 

game.nPlayers = 6; --now we have coach!

-- Auto-detect GPS enabling for webots
use_gps_only = tonumber(os.getenv('USEGPS')) or 0;
if use_gps_only then print("GPS based perception being used") end

--To handle non-gamecontroller-based team handling for webots
if game.teamNumber==0 then game.teamColor = 0; --Blue team
else game.teamColor = 1; --Red team
end

fsm.game = '';
fsm.body = {''};
fsm.head = {''};

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.tKickOffWear =7.0;

team.walkSpeed = 0.25; --Average walking speed 
team.turnSpeed = 2.0; --Average turning time for 360 deg
team.ballLostPenalty = 4.0; --ETA penalty per ball loss time
team.fallDownPenalty = 4.0; --ETA penalty per ball loss time
team.nonAttackerPenalty = 0.8; -- distance penalty from ball
team.nonDefenderPenalty = 0.5; -- distance penalty from goal
team.force_defender = 0;--Enable this to force defender mode
team.force_attacker = 0;--Enable this to force defender mode
team.test_teamplay = 0; --Enable this to immobilize attacker to test team behavior

--if ball is away than this from our goal, go support
team.support_dist = 3.0; 
team.supportPenalty = 0.5; --dist from goal
team.use_team_ball = 1;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;

team.avoid_own_team = 1;
team.avoid_other_team = 1;

--defender pos: (dist from goal, side offset)
team.defender_pos_0={1.5,0}; --In case we don't have a goalie
team.defender_pos_1={2,0.3}; --In case we have only one defender
team.defender_pos_2={2,0.5}; --two defenders, left one
team.defender_pos_3={3,-0.5}; --two defenders, right one

team.supporter_pos = {1.5,2.0};




goalie_dive = 2; --1 for arm only, 2 for actual diving
goalie_dive_waittime = 6.0; --How long does goalie lie down?
--fsm.goalie_type = 1;--moving/move+stop/stop+dive/stop+dive+move
--fsm.goalie_type = 2;--moving/move+stop/stop+dive/stop+dive+move
fsm.goalie_type = 3;--moving/move+stop/stop+dive/stop+dive+move
--fsm.goalie_type = 4;--moving/move+stop/stop+dive/stop+dive+move
--fsm.goalie_reposition=0; --No reposition
fsm.goalie_reposition=1; --Yaw reposition
--fsm.goalie_reposition=2; --Position reposition
fsm.bodyAnticipate.thFar = {0.4,0.4,30*math.pi/180};
fsm.goalie_use_walkkick = 1;--should goalie use walkkick or long kick?

--Diving detection parameters
fsm.bodyAnticipate.timeout = 3.0;
fsm.bodyAnticipate.center_dive_threshold_y = 0.05; 
fsm.bodyAnticipate.dive_threshold_y = 1.0;
fsm.bodyAnticipate.ball_velocity_th = 1.0; --min velocity for diving
fsm.bodyAnticipate.ball_velocity_thx = -1.0; --min x velocity for diving
fsm.bodyAnticipate.rCloseDive = 2.0; --ball distance threshold for diving


fsm.headLookGoal.yawSweep = 30*math.pi/180;


--FILP CORRECTION VARIABLES-------------------------
team.flip_correction = 1;
team.confused_threshold_x = 4.0;
team.confused_threshold_y = 4.0;
team.flip_threshold_x = 1.0;
team.flip_threshold_y = 2;
team.flip_threshold_hard_x = 2.0;


team.flip_check_t = 5.0; --keep confused for 5 sec
----------------------------------------------------

walk.variable_step = 1
--camera_tStep = 100 --in ms
fsm.new_head_fsm = 1

--[[
walk.tStep = 0.50
walk.stanceLimitA={-0*math.pi/180,90*math.pi/180};
walk.velLimitA={-1.2,1.2};
--]]

--use_planner = true
planner_div =0.1
use_planner = false

largestep_enable = false


--[[
walk.tStep = 0.26;
walk.tZmp = 0.17;
walk.supportY = 0.002;
walk.stepHeight = 0.020;
walk.phSingle={0.02,0.98};
walk.hipRollCompensation = 1.5*math.pi/180;
--]]

--CUSTOMIZED WALK PARAM  (FOR WEBOTS)


walk.PIDX = {0,0,-0.08}
walk.filterX = {0, 1.5*math.pi/180,8*math.pi/180}
walk.PIDY = {0,0,-0.08}
walk.filterY = {1, 1.5*math.pi/180,8*math.pi/180}

walk.phSingle={0.15,0.85};
walk.supportY = 0.04;
walk.hipRollCompensation = 0*math.pi/180;
walk.tZmp = 0.16;
walk.stepHeight = 0.030;



enable_getup = true
--enable_getup = false
camera_tStep = 33 --30fps webots camera

ik_testing=true





fsm.bodyApproach.xTarget21 = {0,0.21,0.23} --little away


largestep_enable = true;
