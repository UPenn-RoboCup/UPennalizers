--DARWIN OP specific keyframe playing file


module(..., package.seeall);
name = ...;

require('Body')
require('vector')
require('walk')

--Upperbody only keyframe?
is_upper=false;

--Loaded motion data
motData = {};

--Queued motions
motQueue = {};

--Added for debugging
joints = {};

iFrame = 0;
tFrameStart = 0;
nServo = 0;

function load_motion_file(fname, key)
  -- load the given keyframe motion
  key = key or fname;
  local mot = dofile(fname);
  motData[key] = mot;
  
--  print_motion_file(fname,mot)
end

function print_motion_file(fname,mot)
  print(fname)
  for i=1,#mot.keyframes do
    print("{\nangles=vector.new({")
    ang=vector.new(mot.keyframes[i].angles);
    print(string.format(
	"%d,%d,\n%d,%d,%d,\n%d,%d,%d,%d,%d,%d,\n%d,%d,%d,%d,%d,%d,\n%d,%d,%d",
      unpack(ang*180/math.pi) ));
    print"})*math.pi/180,"
    print(string.format("duration = %.1f;\n},",mot.keyframes[i].duration));
  end
end

function do_motion(key)
  -- add the keyframe motion to the queue
  if (motData[key]) then
    table.insert(motQueue, motData[key]);
  end
end

function get_queue_len()
  return #motQueue;
end

function entry()
  motQueue = {};
  iFrame = 0;

  --OP specific : Wait for a bit to read current joint angles
  Body.set_syncread_enable(1);
  t0=Body.get_time();
  started=false;

  --Remove actuator velocity limits
  for i = 1,Body.nJoint do
    Body.set_actuator_velocity(0, i);
  end
end

function reset_tFrameStart()
  tFrameStart = Body.get_time();
end

function update()
  if (#motQueue == 0) then
    return "done";
  end

  local mot = motQueue[1];
  local t = Body.get_time();
  if not started then
    if t-t0<0.1 then 
        return iFrame;
    end--wait 0.1sec to read joint positions
    started=true;
  end
  if (iFrame == 0) then
    -- starting a new keyframe motion
    iFrame = 1;
    nServo = #(mot.servos);
    tFrameStart = t;
    -- get current joint positions
    q1 = vector.new({});
    for i = 1,nServo do
      q1[i] = Body.get_sensor_position(mot.servos[i]);
    end
    --Added for debugging
    joints = q1;
    Body.set_syncread_enable(0);
  end


  -- linear interpolation of joint position based on the specified duration
  local duration = mot.keyframes[iFrame].duration;
  h = (t-tFrameStart)/duration;
  h = math.min(h, 1);

  q = q1 + h*(mot.keyframes[iFrame].angles - q1);

  if is_upper then --upper body only motion
    print('upper');
    for i=1,5 do
      Body.set_actuator_command(q[i], mot.servos[i]);
    end
    for i=18,20 do
      Body.set_actuator_command(q[i], mot.servos[i]);
    end
  else
    -- set joint stiffnesses if specified
    local stiffnesses = mot.keyframes[iFrame].stiffness;
    if (stiffnesses and (#stiffnesses == nServo)) then
      for i = 1,nServo do
        Body.set_actuator_hardness(stiffnesses[i], mot.servos[i]);
      end
    end
    for i = 1,nServo do
      Body.set_actuator_command(q[i], mot.servos[i]);
    end		
  end



  if (h >= 1) then
    -- finished current frame
    q1 = vector.new(mot.keyframes[iFrame].angles);
    tFrameStart = t;
    iFrame = iFrame + 1;
    if (iFrame > #(mot.keyframes)) then
      table.remove(motQueue, 1);
      iFrame = 0;
    end
  end
  return iFrame;
end

function getJoints()
  return joints;
  --print vector positions for debugging--
  --	local str = vector.tostring(joints);
  --	return str;
end

function exit()
  -- disable joint encoder reading
  -- WHYY?
  Body.set_syncread_enable(0); 
end

