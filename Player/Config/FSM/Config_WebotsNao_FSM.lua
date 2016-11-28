module(..., package.seeall);
require('vector')

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.tKickOffWear = 15.0;

team.walkSpeed = 0.25; --Average walking speed 
team.turnSpeed = 2.0; --Average turning time for 360 deg
team.ballLostPenalty = 4.0; --ETA penalty per ball loss time
team.fallDownPenalty = 4.0; --ETA penalty per ball loss time
team.nonAttackerPenalty = 0.8; -- dist from ball
team.nonDefenderPenalty = 0.5; -- dist from goal

--if ball is away than this from our goal, go support
team.support_dist = 3.0; 
team.supportPenalty = 0.5; --dist from goal

team.force_defender = 0; --Enable this to force defender

team.use_team_ball = 1;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;

team.avoid_own_team = 1;
team.avoid_other_team = 1;


--FSM parameters

--How much should we slow down all SM timings?
speedFactor = 1.0;

fsm={};

--Should we consider obstacle?
fsm.enable_obstacle_detection = 1;

--fsm.playMode = 1; --For Demo without orbit
--fsm.playMode = 2; --Simple Behavior with orbit
fsm.playMode = 3; --Advanced Behavior 

fsm.enable_walkkick = 1;
--fsm.enable_walkkick = 0;
fsm.enable_sidekick = 0;
--fsm.enable_sidekick = 0;

fsm.enable_dribble = 1;

fsm.fast_approach = 0;

--fsm.enable_evade = 0;
--fsm.enable_evade = 1;--Randomly do evade kick
fsm.enable_evade = 2;--Do evade kick when obstructed

fsm.wait_kickoff = 1 ; --initial wait at opponent's kickoff
fsm.th_front_kick = 10*math.pi/180;

fsm.goalie_type = 1;
fsm.goalie_type = 2
--1: Constantly moving goalie
--2: Goalie stops when in position
--3: Diving goalie (stops in position and never move)
--4: Diving and repositioning goalie (turns to ball position)
--fsm.goalie_reposition = 0; --No  reposition
fsm.goalie_reposition = 2; --Yaw reposition


fsm.goalie_use_walkkick = 1;--should goalie use walkkick or long kick?

fsm.daPost_check = 1;
fsm.daPostmargin = 15*math.pi/180;
fsm.variable_dapost = 1;


--------------------------------------------------
--BodyReady : make robot move to initial position
--------------------------------------------------
fsm.bodyReady={};
fsm.bodyReady.maxStep = 0.06;
fsm.bodyReady.thClose = {0.20,10*math.pi/180} --r and theta
fsm.bodyReady.tStart = 5.0;  --initial localization time

--------------------------------------------------
--BodySearch : make robot turn to search the ball
--------------------------------------------------
fsm.bodySearch={};
fsm.bodySearch.vSpin = 0.3; --Turn velocity
fsm.bodySearch.timeout = 10.0*speedFactor;

--------------------------------------------------
--BodyChase : move the robot directly towards the ball
--------------------------------------------------
fsm.bodyChase={};
fsm.bodyChase.maxStep = 0.06;
fsm.bodyChase.rClose = 0.35;
fsm.bodyChase.timeout = 20.0*speedFactor;
fsm.bodyChase.tLost = 3.0*speedFactor;

--------------------------------------------------
--BodyAnticipate : Sit down and wait for kick (goalie)
--------------------------------------------------
fsm.bodyAnticipate={};

fsm.bodyAnticipate.tStartDelay = 1.0*speedFactor;

fsm.bodyAnticipate.rMinDive = 1.0;
fsm.bodyAnticipate.rCloseDive = 2.0;
fsm.bodyAnticipate.timeout = 3.0
fsm.bodyAnticipate.center_dive_threshold_y = 0.07;
fsm.bodyAnticipate.dive_threshold_y = 1.0;
fsm.bodyAnticipate.ball_velocity_th = 1.0; --min velocity for di$
fsm.bodyAnticipate.ball_velocity_thx = -1.0; --min x velocity fo$



fsm.bodyAnticipate.rClose = 1.7;
fsm.bodyAnticipate.rCloseX = 1.0;
fsm.bodyAnticipate.ball_velocity_th2 = 0.3; --max velocity for s$

-- How far out of position are we allowed to be?
fsm.bodyAnticipate.timeout = 20.0*speedFactor;
fsm.bodyAnticipate.thFar = {0.4,0.1,15*math.pi/180};

fsm.bodyGoaliePosition = {};
fsm.bodyGoaliePosition.thClose = {.2, .1, 10*math.pi/180}

fsm.bodyGoaliePosition.thClose = {.5, .5, 30*math.pi/180}



--------------------------------------------------
--BodyChase : move the robot directly towards the ball (for goalie)
--------------------------------------------------
fsm.bodyChase={};
fsm.bodyChase.maxStep = 0.085; --default value 0.08,0.09 quite unstable
fsm.bodyChase.rClose = 0.30;  --default value 0.35
fsm.bodyChase.timeout = 20.0*speedFactor;
fsm.bodyChase.tLost = 3.0*speedFactor;
fsm.bodyChase.rFar = 2.1;
fsm.bodyChase.rFarX = 1.5;

--------------------------------------------------
--BodyOrbit : make the robot orbit around the ball
--------------------------------------------------
fsm.bodyOrbit={};
fsm.bodyOrbit.maxStep = 0.06;
fsm.bodyOrbit.rOrbit = 0.20;
fsm.bodyOrbit.rFar = 0.45;
fsm.bodyOrbit.thAlign = 10*math.pi/180;
fsm.bodyOrbit.timeout = 30.0 * speedFactor;
fsm.bodyOrbit.tLost = 3.0*speedFactor;
fsm.bodyOrbit.walkParam = 'Walk/Config_WebotsNao_Orbit'

--------------------------------------------------
--BodyPosition : Advanced chase-orbit
--------------------------------------------------
fsm.bodyPosition={};

--Trajectory parameters
fsm.bodyPosition.rTurn = 0.25; 
fsm.bodyPosition.rDist1 = 0.40; 
fsm.bodyPosition.rDist2 = 0.20; 
fsm.bodyPosition.rTurn2 = 0.08; 
fsm.bodyPosition.rOrbit = 0.40; 

--Default value 0.60, 0.40 enables ...
-- the bot to get around the ball real fast avoiding wastage of time.

--New params to reduce sidestepping
fsm.bodyPosition.rOrbit = 0.60; 
fsm.bodyPosition.rDist1 = 0.60; 
fsm.bodyPosition.rDist2 = 0.25; 

--define the illegal defender radius
fsm.bodyPosition.dist_defend_goal = 1.6;

fsm.bodyPosition.rClose = 0.35; 




------------------------------------
--Nao values
fsm.bodyPosition.rTurn = 0.25; 
fsm.bodyPosition.rTurn2 = 0.08; 
fsm.bodyPosition.rDist1 = 0.60; 
fsm.bodyPosition.rDist2 = 0.50; 
fsm.bodyPosition.rClose = 0.55; 
fsm.bodyPosition.rOrbit = 0.70; 
 




--fsm.bodyPosition.thClose = {0.15,0.15,10*math.pi/180};
fsm.bodyPosition.thClose = {0.3,0.15,20*math.pi/180};

fsm.bodyPosition.tLost =  5.0*speedFactor; 
fsm.bodyPosition.timeout = 30*speedFactor; 

--Velocity generation parameters

--Slow speed
fsm.bodyPosition.maxStep1 = 0.06;

--Medium speed
fsm.bodyPosition.maxStep2 = 0.08;
fsm.bodyPosition.rVel2 = 0.5;
fsm.bodyPosition.aVel2 = 45*math.pi/180;
fsm.bodyPosition.maxA2 = 0.2;
fsm.bodyPosition.maxY2 = 0.02;

--Full speed front dash
fsm.bodyPosition.maxStep3 = 0.08;
fsm.bodyPosition.rVel3 = 0.8; 
fsm.bodyPosition.aVel3 = 20*math.pi/180;
fsm.bodyPosition.maxA3 = 0.0;
fsm.bodyPosition.maxY3 = 0.0;

--------------------------------------------------
--BodyApproach :  Align the robot for kick
--------------------------------------------------
fsm.bodyApproach={};
fsm.bodyApproach.maxStep = 0.06; --Max walk velocity
fsm.bodyApproach.timeout = 10.0*speedFactor;
fsm.bodyApproach.rFar = 0.45; --Max ball distance
fsm.bodyApproach.tLost = 3.0*speedFactor;--ball detection timeout

fsm.bodyApproach.aThresholdTurn = 10*math.pi/180;
fsm.bodyApproach.aThresholdTurnGoalie = 15*math.pi/180;
fsm.bodyApproach.aThresholdTurnGoalie = 35*math.pi/180;

--x and y target position for stationary straight kick
fsm.bodyApproach.xTarget11={0, 0.16,0.17}; --min, target, max
fsm.bodyApproach.yTarget11={0.03, 0.045, 0.06}; --min, target ,max

--x and y target position for stationary kick to left
fsm.bodyApproach.xTarget12={0, 0.16,0.17}; --min, target, max
fsm.bodyApproach.yTarget12={-0.015, 0, 0.015}; --min, target ,max

--Target position for straight walkkick 
--fsm.bodyApproach.xTarget21={0, 0.16,0.18}; --min, target, max 
fsm.bodyApproach.xTarget21={0, 0.18,0.20}; --min, target, max 
fsm.bodyApproach.yTarget21={0.03, 0.045, 0.06}; --min, target ,max


--Target position for side walkkick to left
fsm.bodyApproach.xTarget22={0, 0.15,0.18}; --min, target, max
fsm.bodyApproach.yTarget22={0.01, 0.025, 0.04}; --min, target ,max

fsm.bodyApproach.pFar = 2.8
fsm.bodyApproach.pNear = .3
fsm.bodyApproach.pRight = 1.8 

--------------------------------------------------
--BodyKick : Stationary Kick
--------------------------------------------------

fsm.bodyKick={};

--initial wait 
fsm.bodyKick.tStartWait = 1.0;
fsm.bodyKick.tStartWaitMax = 1.5;
fsm.bodyKick.thGyroMag = 100; 

--ball position checking params
fsm.bodyKick.kickTargetFront = {0.16,0.045};

--For kicking to the left
fsm.bodyKick.kickTargetSide = {0.15,0.0};

--Bal position threshold
fsm.bodyKick.kickTh = {0.03,0.03};

--delay for camera following the ball
fsm.bodyKick.tFollowDelay = 2.2; 
--------------------------------------------------
--BodyWalkKick : Dynamic Kick
--------------------------------------------------
fsm.bodyWalkKick={};
fsm.bodyWalkKick.timeout = 2.0*speedFactor; 
--------------------------------------------------
--BodyGotoCenter : Going to center when ball is lost
--------------------------------------------------
fsm.bodyGotoCenter={};
fsm.bodyGotoCenter.maxStep=0.06;
fsm.bodyGotoCenter.rClose=0.30;
fsm.bodyGotoCenter.timeout=15.0*speedFactor;

--------------------------------------------------
--HeadTrack : Track the ball
--------------------------------------------------
fsm.headTrack = {};
fsm.headTrack.timeout = 3.0 * speedFactor;
fsm.headTrack.tLost = 1.5 * speedFactor;
fsm.headTrack.minDist = 0.30; --If ball is closer than this, don't look up
fsm.headTrack.fixTh={0.20,0.12}; --Fix yaw axis if ball is within this box

--------------------------------------------------
--HeadReady : Track the horizonal line for localization
--------------------------------------------------
fsm.headReady={}
fsm.headReady.dist = 3.0; 
fsm.headReady.height = 0.5; 
fsm.headReady.tScan= 5.0*speedFactor; 

--------------------------------------------------
--HeadReadyLookGoal : Look Goal during bodyReady
--------------------------------------------------
fsm.headReadyLookGoal={}
fsm.headReadyLookGoal.timeout = 1.5 * speedFactor;

--------------------------------------------------
--HeadScan: Scan around for ball
--------------------------------------------------

--SJ: NaoV4 has VERY wide FOV so we don't need to look up and down at all
fsm.headScan={};
fsm.headScan.pitch0 = 15*math.pi/180;
fsm.headScan.pitchMag = 0*math.pi/180;
fsm.headScan.yawMag = 90*math.pi/180;
fsm.headScan.yawMagGoalie =120*math.pi/180; --Currently same scan speed as Gen. Player

fsm.headScan.pitchTurn0 = 15*math.pi/180;
fsm.headScan.pitchTurnMag = 0*math.pi/180;
fsm.headScan.yawMagTurn = 35*math.pi/180;
fsm.headScan.tScan = 3.0*speedFactor;

--------------------------------------------------
--HeadKick: Fix headangle for approaching
--------------------------------------------------
fsm.headKick={};
fsm.headKick.pitch0=20*math.pi/180;
fsm.headKick.xMax = 0.30;
fsm.headKick.yMax = 0.07;
fsm.headKick.tLost = 3.0*speedFactor;
fsm.headKick.timeout = 3.0*speedFactor;

--------------------------------------------------
--HeadKickFollow: Follow ball after kick
--------------------------------------------------
fsm.headKickFollow={};
fsm.headKickFollow.pitch={20*math.pi/180, 0*math.pi/180};
fsm.headKickFollow.pitchSide = 30*math.pi/180;
fsm.headKickFollow.yawMagSide = 90*math.pi/180;
fsm.headKickFollow.tFollow = 1.0*speedFactor;

--------------------------------------------------
--HeadLookGoal: Look up to see the goal
--------------------------------------------------
fsm.headLookGoal={};
fsm.headLookGoal.yawSweep = 50*math.pi/180;
fsm.headLookGoal.tScan = 1.0*speedFactor;
fsm.headLookGoal.minDist = 0.40;

--------------------------------------------------
--HeadSweep: Look around to find the goal
--------------------------------------------------
fsm.headSweep={};
fsm.headSweep.tScan=1.0*speedFactor;
fsm.headSweep.tWait=0.25*speedFactor;
