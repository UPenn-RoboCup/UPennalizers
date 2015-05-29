module(..., package.seeall);
require('vector')

--Localization parameters 

world={};
world.n = 200;
world.xLineBoundary = 4.5;
world.yLineBoundary = 3.0;
--the boundary is 70 cm wide than the actual field
--use 20 cm boundary for detection and localization
world.xMax = 4.7;
world.yMax = 3.2;
world.goalWidth = 1.60;
world.goalHeight= 0.85;
world.goalDiameter=0.10; -- diameter of a post
world.ballYellow= {{4.5,0.0}};
world.ballCyan= {{-4.6,0.0}};
world.postYellow = {};
world.postYellow[1] = {4.5, 0.80};
world.postYellow[2] = {4.5, -0.80};
world.postCyan = {};
world.postCyan[1] = {-4.5, -0.80};
world.postCyan[2] = {-4.5, 0.80};
world.spot = {};
world.spot[1] = {-3.2, 0};
world.spot[2] = {3.2, 0};
world.cResample = 10; --Resampling interval

--They are SPL 2013 values
world.Lcorner={};
--Field edge
world.Lcorner[1]={4.5,3.0};
world.Lcorner[2]={4.5,-3.0};
world.Lcorner[3]={-4.5,3.0};
world.Lcorner[4]={-4.5,-3.0};
--Center T edge
world.Lcorner[5]={0,3.0};
world.Lcorner[6]={0,-3.0};
--Penalty box edge
world.Lcorner[7]={-3.9,1.1};
world.Lcorner[8]={-3.9,-1.1};
world.Lcorner[9]={3.9,1.1};
world.Lcorner[10]={3.9,-1.1};
--Penalty box T edge
world.Lcorner[11]={4.5,1.1};
world.Lcorner[12]={4.5,-1.1};
world.Lcorner[13]={-4.5,1.1};
world.Lcorner[14]={-4.5,-1.1};
--Center circle junction
world.Lcorner[15]={0,0.75};
world.Lcorner[16]={0,-0.75};

--Goalie only uses corners near goals

world.Lgoalie_corner = {}
--Field edge
world.Lgoalie_corner[1]=world.Lcorner[1];
world.Lgoalie_corner[2]=world.Lcorner[2];
world.Lgoalie_corner[3]=world.Lcorner[3];
world.Lgoalie_corner[4]=world.Lcorner[4];

--Penalty box edge
world.Lgoalie_corner[5]=world.Lcorner[7];
world.Lgoalie_corner[6]=world.Lcorner[8];
world.Lgoalie_corner[7]=world.Lcorner[9];
world.Lgoalie_corner[8]=world.Lcorner[10];

--Penalty box T edge
world.Lgoalie_corner[9]=world.Lcorner[11];
world.Lgoalie_corner[10]=world.Lcorner[12];
world.Lgoalie_corner[11]=world.Lcorner[13];
world.Lgoalie_corner[12]=world.Lcorner[14];






--same-colored goalposts
world.use_same_colored_goal=1;

--should we use new triangulation?
world.use_new_goalposts=1;


--Two post observation
--world.rGoalFilter = 0.02;
world.rGoalFilter = 0.06;
world.aGoalFilter = 0.15;

--Single post observation
world.rPostFilter = 0.02;
world.aPostFilter = 0.05;

--Single known post observation
world.rPostFilter2 = 0.05;
world.aPostFilter2 = 0.10;

--Corner observation
world.rCornerFilter = 0.01;
world.aCornerFilter = 0.02;

--Line observation
--world.aLineFilter = 0.02;
world.aLineFilter = 0.04;

--Single landmark determing param
world.rSigmaSingle1 = .15;
world.rSigmaSingle2 = .10;
world.aSigmaSingle = 5*math.pi/180; --Original value

--Two post determining param
world.rSigmaDouble1 = .25;
world.rSigmaDouble2 = .20;
world.aSigmaDouble = 30*math.pi/180;

-- default positions for our kickoff
world.initPosition1={
  {4.0, 0},   --Goalie
  {0.7, 0}, --Attacker
  {1.2,-1.5}, --Defender
  {1.2, 1.5}, --Supporter
  {2.2, 0}, --Defender2
}
-- default positions for opponents' kickoff
-- Penalty mark : {1.2,0}
world.initPosition2={
  {4.0, 0},   --Goalie
  {1.0, 0}, --Attacker
  {2.0,-1}, --Defender
  {2.0, 1}, --Supporter
  {3.0, 0.5}, --Defender2
}

-- use sound localization
world.enable_sound_localization = 0;

world.triangulation_threshold = 5.0;
world.position_update_threshold = 8.0;
world.position_update_threshold = 7.0;
world.triangulation_threshold_goalie = 4.0;
world.position_update_threshold_goalie = 4.0;

--should we use new triangulation?
world.use_new_goalposts=1;
