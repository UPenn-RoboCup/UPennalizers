module(..., package.seeall);
require('vector')

--Localization parameters 

world={};
world.n = 100;
world.xLineBoundary = 3.0;
world.yLineBoundary = 2.0;
world.xMax = 3.2;
world.yMax = 2.2;
world.goalWidth = 1.60;
world.ballYellow= {{3.0,0.0}};
world.ballCyan= {{-3.0,0.0}};
world.postYellow = {};
world.postYellow[1] = {3.0, 0.80};
world.postYellow[2] = {3.0, -0.80};
world.postCyan = {};
world.postCyan[1] = {-3.0, -0.80};
world.postCyan[2] = {-3.0, 0.80};
world.spot = {};
world.spot[1] = {-1.20, 0};
world.spot[2] = {1.20, 0};
world.landmarkCyan = {0.0, -2.4};
world.landmarkYellow = {0.0, 2.4};
world.cResample = 10; --Resampling interval
world.odomScale = {1, 1, 0.06};

-- filter weights
world.rGoalFilter = 0.02;
world.aGoalFilter = 0.05;
world.rPostFilter = 0.02;
world.aPostFilter = 0.20;
