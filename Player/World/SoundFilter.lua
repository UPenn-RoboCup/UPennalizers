module(..., package.seeall);

require('Config');
require('vector');
require('unix');
require('util');
require('wcm');
require('gcm');

require('SoundComm');
require('Body');

-- set signal tone, ie. only use one tone and filter on that tone
--    '\0' to accept all signals (tx and accept random tone)
signalTone = '1';

if (gcm.get_team_player_id() == 1) then
  -- if we are the goalie, disable listening
  SoundComm.pause_receiver();
else
  -- if we are a player, disable transmitting
  SoundComm.pause_transmitter();
  -- set receiver volume
  SoundComm.set_receiver_volume(75);
  if (signalTone) then
    SoundComm.set_signal_tone(signalTone);
  end
end

-- touch tone symbols
symbols = {{'1', '2', '3', 'A'},
           {'4', '5', '6', 'B'},
           {'7', '8', '9', 'C'},
           {'*', '0', '#', 'D'}};

-- robot pose
odomPose = {x=0, y=0, a=0};

-- last detection count
lastDet = SoundComm.get_detection();

-- TODO: disparity threshold should come from config
-- max allowed disparity
disparityThres = 10;

-- TODO: disparity conversion should come from config
-- convertion factor for signal disparity to angle (radians)
radPerDisparity = 10 * math.pi/180;

-- TODO: sound histogram filter size should be set in the config
radPerDiv = 30 * math.pi/180;
-- histogram filter
ndiv = math.floor(2*math.pi/radPerDiv);
detFilter = vector.zeros(ndiv);
zeroInd = math.floor(ndiv/2);
-- array to store the time of the last correlation per bin
lastCorr = vector.zeros(ndiv);


-- transmition period
txPeriod = 1.0;
-- only use the left speaker to transmit?
txLeftEarOnly = 1;
-- max detection count (likelihood)
maxDetCount = 100;
-- per detection 
updateRate = 20;
-- decay period (seconds)
decayPeriod = 1.0;
-- decay rate (per period)
decayRate = 2.0;
-- flag indicating if we should decrease non adjacent cells
--    after a good correlation
decreaseNonAdjacent = 1;
decreaseNonAdjacentRate = 4.0;
confidenceThres = 0.6 * maxDetCount;

-- distance decay
--  if the robot has moved this far (translation, meters)
--    decay everything
distanceDecay = 1;
distanceDecayThres = 1.5;
distanceDecayRate = 40;
lastDistanceDecayPose = {x=0, y=0, a=0};

-- last decay time
lastDecay = unix.time();
-- last tx time
lastTx = unix.time();

-- goal distinction threshold (within this angle of the detection direction)
--goalAngleThres = 60*math.pi/180;
goalAngleThres = 45*math.pi/180;

-- update cound
count = 0;


function entry()
end

function update()
   -- increment iteration counter
   count = count + 1;

   -- if we are the goalie, periodically send out the audio signal
   if (gcm.get_team_player_id() == 1) then
      -- only in ready and playing state
      local gameState = gcm.get_game_state();
      if (gameState == 1 or gameState == 3) then
         -- only transmit the sequence when we are in our own goal
         local pose = wcm.get_robot_pose();
         local goalPos = wcm.get_goal_defend();
         local distToGoal = math.sqrt(math.pow((pose[1] - goalPos[1]), 2)
                                    + math.pow((pose[2] - goalPos[2]), 2))
         -- TODO: different check for when to transmit sound?
         if (distToGoal < 1.0) then
            -- play sound every X seconds
            if (unix.time() - lastTx > txPeriod) then
              if (signalTone == '\0') then 
                -- play pseudo random signal with random touch tone
                srow = symbols[math.random(#symbols)];
                symbol = srow[math.random(#srow)];
              else
                symbol = signalTone;
              end

              SoundComm.play_pnsequence(symbol, txLeftEarOnly);
              lastTx = unix.time();
            end
         end
      end

   else

      -- check for new detection
      local det = SoundComm.get_detection();
      if (det.count ~= lastDet.count) then
         -- save a copy of the detection
         lastDet = det;
   
         -- new detection, update histogram accordingly
         --    only accept detections with a reasonable disparity
         if (det.lIndex ~= -1 and det.rIndex ~= -1 
               and math.abs(det.lIndex - det.rIndex) <= disparityThres) then

            -- get the current head angles
            local headAngles = Body.get_head_position();

            print(string.format('pan: %f, lindex: %d, rindex: %d, dindex: %d', 
                                 headAngles[1], det.lIndex, det.rIndex, det.lIndex - det.rIndex));

            -- full orientation of the robot, body + head
            --    only head pan affects the audio detection
            local a = odomPose.a + headAngles[1];

            -- estimate signal direction based on left/right the disparity
            local dir = -1 * util.sign(det.lIndex - det.rIndex);
            local a_wrtHead = dir * radPerDisparity * math.abs(det.lIndex - det.rIndex);

            -- world location of sound
            local afront = util.mod_angle(a + a_wrtHead);

            -- account for cone of confusion
            --    each correlation can correspond to one of two directions
            --    (from the front or from behind)
            local aback = util.mod_angle(a + (math.pi - a_wrtHead));

            -- update histogram
            local ifront = math.max(1, math.min(math.floor(zeroInd + afront / radPerDiv) + 1, ndiv));
            local iback = math.max(1, math.min(math.floor(zeroInd + aback / radPerDiv) + 1, ndiv));

            print(string.format('afront: %f, aback: %f, ifront: %d, iback: %d', afront, aback, ifront, iback));

            detFilter[ifront] = detFilter[ifront] + updateRate;
            detFilter[iback] = detFilter[iback] + updateRate;
            lastCorr[ifront] = unix.time();
            lastCorr[iback] = unix.time();


            -- decrease count for non adjacent cells 
            if (decreaseNonAdjacent > 0) then
               local skipInd = {};
               skipInd[1] = (ifront - 1) % #detFilter;
               skipInd[2] =  ifront;
               skipInd[3] = (ifront + 1) % #detFilter;
               skipInd[4] = (iback - 1) % #detFilter;
               skipInd[5] =  iback;
               skipInd[6] = (iback + 1) % #detFilter;
               if (skipInd[1] == 0) then
                  skipInd[1] = #detFilter;
               end
               if (skipInd[4] == 0) then
                  skipInd[4] = #detFilter;
               end

               for idec = 1,#detFilter do
                  local dec = true;
                  for i,iskip in ipairs(skipInd) do
                     if (idec == iskip) then
                        dec = false;
                     end
                  end
                  if (dec) then
                     detFilter[idec] = detFilter[idec] - decreaseNonAdjacentRate;
                     -- cap count
                     detFilter[idec] = math.max(detFilter[idec], 0);
                  end
               end
            end

            -- cap count
            detFilter[ifront] = math.min(detFilter[ifront], maxDetCount);
            detFilter[iback] = math.min(detFilter[iback], maxDetCount);
         end
      end
   end

   -- decay histogram (this is based off time since the update rate
   --   from World is most likely going to be erratic)
   if (unix.time() - lastDecay > decayPeriod) then
      for i = 1,#detFilter do
         detFilter[i] = detFilter[i] - decayRate;
         detFilter[i] = math.max(0, detFilter[i]);
      end
      lastDecay = unix.time();
   end 
   
   -- distance decay
   if (distanceDecay > 0) then
     local dx = lastDistanceDecayPose.x - odomPose.x;
     local dy = lastDistanceDecayPose.y - odomPose.y;
     local distMag = math.sqrt(dx*dx + dy*dy);

     if (distMag > distanceDecayThres) then
       print('SoundComm: doing distance decay');

       for i = 1,#detFilter do
         detFilter[i] = detFilter[i] - distanceDecayRate;
         detFilter[i] = math.max(0, detFilter[i]);
       end

       -- store last pose
       lastDistanceDecayPose.x = odomPose.x; 
       lastDistanceDecayPose.y = odomPose.y; 
       lastDistanceDecayPose.a = odomPose.a; 
     end
   end

   update_shm();
end


function odometry(dx, dy, da)
   -- update pose based on walking odometry
   ca = math.cos(odomPose.a);
   sa = math.sin(odomPose.a);
   odomPose.x = odomPose.x + dx*ca - dy*sa;
   odomPose.y = odomPose.y + dx*sa + dy*ca;
   odomPose.a = odomPose.a + da;
end

function get_sound_direction()
   -- return the filter index corresponding to the goalie
   --    -1 for unkown
   -- TODO: interpolate between bins?

   -- TODO: better determination of the sound direction
   local mv, mind = util.max(detFilter);
   if (mv < confidenceThres) then
      return -1;
   end

   -- check that the opposite index is not high
   local oind = mind + math.floor(ndiv/2);
   if (oind > ndiv) then
      oind = oind - ndiv;
   end
   local ov = detFilter[oind];
   if (ov > 0.75 * mv) then
      --print('SoundFilter: ambiguous direction');
      return -1;
   end

   -- also check +/- 1 of the opposite index
   local oind_minus1 = oind - 1;
   if (oind_minus1 == 0) then
      oind_minus1 = ndiv;
   end
   local oind_plus1 = oind + 1;
   if (oind_plus1 > ndiv) then
      oind_plus1 = oind_plus1 - ndiv;
   end

   local ov_minus1 = detFilter[oind_minus1];
   local ov_plus1 = detFilter[oind_plus1];
   if (ov_minus1 > 0.75 * mv or ov_plus1 > 0.75 * mv) then
      --print('SoundFilter: ambiguous direction +/- 1');
      return -1;
   end

   return mind;
end

function resolve_goal_detection(gtype, vgoal)
   -- given a goal detection
   --    determine if it is the attacking or defending goal
   --
   -- gtype:   goal detection type (0 - unkown, 1 - left post, 2 - right post, 3 - both posts)
   --             for types (0,1,2) only the first pose of vgoal is set
   -- vgoal:   goal post poses, {(x,y,a), (x,y,a)} relative to the robot
   -- return:  0 - unknown
   --         +1 - attacking
   --         -1 - defending 
   if (gcm.get_team_player_id() == 1) then
      return 0;
   end
   
   -- direction of the goalie (-1 for unknown)
   local mind = get_sound_direction();
   if (mind == -1) then
      return 0;
   end

   -- transform the goalie direction to the robot body frame
   local agoalie_wrtWorld = (mind - zeroInd) * radPerDiv;
   local agoalie_wrtRobot = util.mod_angle(agoalie_wrtWorld - odomPose.a);

   -- angle of goal from the robot
   local post1 = vgoal[1];
   local post2 = vgoal[2];
   local agoal = math.atan2(post1[2], post1[1]);
   if (gtype == 3) then
      -- if both posts were detected then use the angle between the two
      agoal = util.mod_angle(post1[3] + 0.5 * util.mod_angle(math.atan2(post2[2], post2[1]) - post2[3]));
   end
   agoal = util.mod_angle(agoal);

   print(string.format('agoal: %f, agoaliew: %f, agoalier: %f', agoal * 180/math.pi, agoalie_wrtWorld * 180/math.pi, agoalie_wrtRobot * 180/math.pi));

   -- compare the location of the detected goal with the location of the goalie
   if (math.abs(agoalie_wrtRobot - agoal) < goalAngleThres) then
      -- the goal is ours (defending)
      print('------------------ detected goal is the defending goal ------------------');
      -- do we already have the correct orientation
      local goalBeliefFromPose = which_goal_based_on_current_pose(agoal);
      -- if we think it is the attacking goal return defending (to update pose faster)
      if (goalBeliefFromPose == 1) then
         return -1;
      else
         -- otherwise use normal pose filter updates
         print('------------------ already have correct direction ------------------');
         return 0
      end


      return -1;
   elseif (math.abs(agoalie_wrtRobot + math.pi - agoal) < goalAngleThres) then
      -- the goal is theirs (attacking)
      print('++++++++++++++++++ detected goal is the attacking goal ++++++++++++++++++');
      -- do we already have the correct orientation
      local goalBeliefFromPose = which_goal_based_on_current_pose(agoal);
      -- if we think it is the attacking goal return defending (to update pose faster)
      if (goalBeliefFromPose == -1) then
         return 1;
      else
         -- otherwise use normal pose filter updates
         print('++++++++++++++++++ already have correct direction ++++++++++++++++++');
         return 0;
      end

      return 1;
   else
      -- the detected goal posts and goalie do not correlate well
      print('==================       detected goal is unknown      ==================');
      return 0;
   end

   -- if we make it this far then we do not know which goal it is
   return 0;
end

function which_goal_based_on_current_pose(agoal)
   -- get attack and defend angle
   aattack = wcm.get_attack_angle();
   adefend = wcm.get_defend_angle();

   -- which goal do we think the detected one is based on the
   --    particle filter
   dattack = math.abs(util.mod_angle(aattack - agoal));
   ddefend = math.abs(util.mod_angle(adefend - agoal));

   -- first check if neither goal is a good match
   if (dattack > 50 and ddefend > 50) then
      return 0;
   elseif (dattack < ddefend) then
      -- we think it is the attacking goal
      return 1;
   else
      -- we think it is the defending goal
      return -1;
   end
end

function reset()
   -- zero out histogram
   detFilter = 0 * detFilter;

   -- reset odometry?
   odomPose.x = 0;
   odomPose.y = 0;
   odomPose.a = 0;
end


function update_shm()
   wcm.set_sound_odomPose({odomPose.x, odomPose.y, odomPose.a});
   wcm.set_sound_detFilter(detFilter);

   -- store last detection information
   wcm.set_sound_detCount(lastDet.count);
   wcm.set_sound_detTime(lastDet.time);
   wcm.set_sound_detLIndex(lastDet.lIndex);
   wcm.set_sound_detRIndex(lastDet.rIndex);
end


function exit()
end

