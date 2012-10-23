module(..., package.seeall);
require('vector')

--Localization parameters 

world={};
world.n = 200;
world.xLineBoundary = 3.0;
world.yLineBoundary = 2.0;
world.xMax = 3.2;
world.yMax = 2.2;
world.goalWidth = 1.40;
world.goalHeight= 0.80;
world.goalDiameter=0.10; -- diameter of a post
world.ballYellow= {{3.0,0.0}};
world.ballCyan= {{-3.0,0.0}};
world.postYellow = {};
world.postYellow[1] = {3.0, 0.70};
world.postYellow[2] = {3.0, -0.70};
world.postCyan = {};
world.postCyan[1] = {-3.0, -0.70};
world.postCyan[2] = {-3.0, 0.70};
world.spot = {};
world.spot[1] = {-1.20, 0};
world.spot[2] = {1.20, 0};
world.landmarkCyan = {0.0, -2.4};
world.landmarkYellow = {0.0, 2.4};
world.cResample = 10; --Resampling interval

--They are SPL values
world.Lcorner={};
--Field edge
world.Lcorner[1]={3.0,2.0};
world.Lcorner[2]={3.0,-2.0};
world.Lcorner[3]={-3.0,2.0};
world.Lcorner[4]={-3.0,-2.0};
--Center T edge
world.Lcorner[5]={0,2.0};
world.Lcorner[6]={0,-2.0};
--Penalty box edge
world.Lcorner[7]={-2.4,1.1};
world.Lcorner[8]={-2.4,-1.1};
world.Lcorner[9]={2.4,1.1};
world.Lcorner[10]={2.4,-1.1};
--Penalty box T edge
world.Lcorner[11]={3.0,1.1};
world.Lcorner[12]={3.0,-1.1};
world.Lcorner[13]={-3.0,1.1};
world.Lcorner[14]={-3.0,-1.1};
--Center circle junction
world.Lcorner[15]={0,0.6};
world.Lcorner[16]={0,-0.6};
world.Lcorner[17]={0.6,0};
world.Lcorner[18]={-0.6,0};

--same-colored goalposts
world.use_same_colored_goal=1;

--should we use new triangulation?
world.use_new_goalposts=0;

-- filter weights
world.rGoalFilter = 0.02;
world.aGoalFilter = 0.05;
world.rPostFilter = 0.02;
world.aPostFilter = 0.05;
world.rKnownGoalFilter = 0.02;
world.aKnownGoalFilter = 0.20;
world.rKnownPostFilter = 0.02;
world.aKnownPostFilter = 0.10;
world.rUnknownGoalFilter = 0.02;
world.aUnknownGoalFilter = 0.05;
world.rUnknownPostFilter = 0.02;
world.aUnKnownPostFilter = 0.05;

world.rCornerFilter = 0.02;
world.aCornerFilter = 0.05;

-- default positions for our kickoff
world.initPosition1={
  {2.7,0},   --Goalie
  {0.5, 0}, --Attacker
  {1.2,-1}, --Defender
  {1.2, 1}, --Supporter
}
-- default positions for opponents' kickoff
-- Penalty mark : {1.2,0}
world.initPosition2={
  {2.7,0},   --Goalie
  {1.3, 0}, --Attacker
  {1.3, -1}, --Defender
  {1.3,1}, --Supporter
}

-- use sound localization
world.enable_sound_localization = 1;

-- Occupancy Map parameters
occ = {};
occ.mapsize = 50;
occ.robot_pos = {occ.mapsize / 2, occ.mapsize * 4 / 5};


