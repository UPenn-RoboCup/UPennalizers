module(..., package.seeall);

-- TODO: use auto UltraSound from naoqi? switching modes takes as long as 1.0sec

require('Body');
require('vector');
require('math');

count = 0;
-- the count when the ultra sound was switched
switchCount = 0;
switchTimeout = 10;

-- switch freq (update is run at 100hz)
switchFreq = 50;

-- update freq (update is run at 100hz)
updateFreq = 10;

-- left/right us
left = vector.zeros(10);
right = vector.zeros(10);


--this works reliably but SLOWLY 
--numSavedValues = 5;
--updateFreq = 20;

numSavedValues = 5;
lastLeftObstacle = 0;
lastRightObstacle = 0;

dLeftObs = vector.zeros(numSavedValues);
dRightObs = vector.zeros(numSavedValues);

dSum = vector.zeros(2);
obstacles = vector.zeros(2);
free = vector.zeros(2);
distance = vector.zeros(2);

obsThresh = .02*numSavedValues/5;--.03;
freeThresh = .1*numSavedValues/5;--.15;
disThresh = .6;

function entry()
  -- auto send and receive on both left/right
  Body.set_actuator_us(68);
  print("UltraSound entry");
end

obsThres = 0.28;
clearThres = 0.50;

leftObsCount = 0;
rightObsCount = 0;

leftZeroCount = 0;
rightZeroCount = 0;

zeroCountThres = 10;

--Renamed the config variable here
enable_obstacle_detection=Config.fsm.enable_obstacle_detection or 0;

function update()
  if enable_obstacle_detection == 1 then
    count = count + 1;

    if (count % updateFreq == 0) then
      left = vector.new(Body.get_sensor_usLeft());
      right = vector.new(Body.get_sensor_usRight());

      -- left
      if (left[1] > 0 and left[1] < 2.55) then
        --print('left '..left[1]);
        if left[1] < obsThres then
          leftObsCount = leftObsCount + 0.5;
        elseif left[1] > clearThres then
          leftObsCount = leftObsCount - 1; 
        end 
        --print('leftObsCount '..leftObsCount);

        leftZeroCount = 0;
      else
        leftZeroCount = leftZeroCount + 1;

        if (leftZeroCount > zeroCountThres) then
          --print('leftZeroCount '..leftZeroCount);
          leftObsCount = leftObsCount - 0.30;
        else
          leftObsCount = leftObsCount - 0.01;
        end
      end
      leftObsCount = math.max(0, math.min(10, leftObsCount));

      -- right 
      if (right[1] > 0 and right[1] < 2.55) then
        --print('right '..right[1]);
        if right[1] < obsThres then
          rightObsCount = rightObsCount + 0.5;
        elseif right[1] > clearThres then
          rightObsCount = rightObsCount - 1; 
        end 
        --print('rightObsCount '..rightObsCount);

        rightZeroCount = 0;
      else
        rightZeroCount = rightZeroCount + 1;

        if (rightZeroCount > zeroCountThres) then
          --print('rightZeroCount '..rightZeroCount);
          rightObsCount = rightObsCount - 0.30;
        else
          rightObsCount = rightObsCount - 0.01;
        end
      end

      rightObsCount = math.max(0, math.min(10, rightObsCount));
    end
  end

end

function check_obstacle()
  return {leftObsCount, rightObsCount};
end

function update2()
  if enable_obstacle_detection == 1 then
    count = count + 1;

    if (count % updateFreq == 0) then
      left = vector.new(Body.get_sensor_usLeft());
      right = vector.new(Body.get_sensor_usRight());

      -- left
      if (left[1] > 0 and left[1] < 2.55) then
        print('left '..left[1]);
        --data is valid, so store it for comparison with last numSavedValues values
        dSum[1] = dSum[1] - dLeftObs[numSavedValues];
        for j = numSavedValues,2,-1 do
          dLeftObs[j] = dLeftObs[j-1];
        end
        dLeftObs[1] = math.abs(lastLeftObstacle - left[1]);
        lastLeftObstacle = left[1];
        dSum[1] = dSum[1] + dLeftObs[1];
        distance[1] = left[2];
      end

      -- right 
      if (right[1] > 0 and right[1] < 2.55) then
        print('right '..right[1]);
        --data is valid, so store it for comparison with last numSavedValues values
        dSum[2] = dSum[2] - dRightObs[numSavedValues];
        for j = numSavedValues,2,-1 do
          dRightObs[j] = dRightObs[j-1];
        end
        dRightObs[1] = math.abs(lastRightObstacle - right[1]);
        lastRightObstacle = right[1];
        dSum[2] = dSum[2] + dRightObs[1];
        distance[2] = right[2];
      end
    end
  end
end

function obstacle()
  -- return (lObs, rObs) where l and rObs are one if there is
  --  a left and right obstacle respectively (otherwise zero)


  obstacles = vector.zeros(2);
  free = vector.zeros(2);
  distance = {2.55,2.55};

 
  if dSum[1] > obsThresh then
    obstacles[1] = 0;
    if dSum[1] > freeThresh then
      free[1] = 1;
    end
  else
    obstacles[1] = 1;
    distance[1] = lastLeftObstacle;
  end
  if dSum[2] > obsThresh then
    obstacles[2] = 0;
    if dSum[2] > freeThresh then
      free[2] = 1;
    end
  else
    obstacles[2] = 1;
    distance[2] = lastRightObstacle;
  end

  mcm.set_us_obstacles(obstacles);
  mcm.set_us_free(free);
  mcm.set_us_dSum(dSum);
  mcm.set_us_distance(distance);
end

function exit()
end

-- for BodyFSM
function checkObstacle()
  -- checks for obstacle IN FRONT of robot.  
  -- TODO implement for obstacle IN THE PATH of robot

  if enable_obstacle_detection == 1 then

    -- goalie does not need to worry about obstacles
    --[[
    if Config.game.playerID == 1 then
      return 0;
    end
    --]]

    UltraSound.obstacle();
    --print("obstacles "..obstacles[1].." "..obstacles[2]);
    --print("free      "..free[1].." "..free[2]);
    ret = vector.zeros(2);
    
    if free[1] == 1 or free[2] == 1 or (obstacles[1] == 0 and obstacles[2] == 0) then -- too far away on either side to be in the path
      return ret;
    end

    if obstacles[1] == 0 and obstacles[2] == 1 then --possibly on right
      if free[1] == 1 then
        return ret; -- too far to right to be in the way
      end
      if distance[1] < disThresh then
        ret[1] = 1;
        return ret; -- obstacle to left
      else
        return ret; -- too far away
      end
    elseif obstacles[1] == 1 and obstacles[2] == 0 then -- possibly on left
      if free[2] == 1 then 
        return ret; -- too far to left to be in front
      end
      if distance[2] < disThresh then
        ret[2] = 1;
        return ret; -- obstacle to right
      else
        return ret; -- too far away
      end
    end
    if (distance[1] < disThresh) and (distance[2] < disThresh) then
      ret = vector.ones(2);
      return ret; -- obstacle in front
    else
      return ret; -- too far away
    end
  end
end


