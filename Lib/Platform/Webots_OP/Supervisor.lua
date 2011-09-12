module(..., package.seeall);
require('controller');
require('util');

-- ALways need to initialize a controller
controller.wb_robot_init();

-- Get our timetep intervals
timeStep = controller.wb_robot_get_basic_time_step();

-- Get webots tags for the ball and Darwin
tags = {};
tags.ball = controller.wb_robot_get_device("Ball");
tags.darwin = controller.wb_robot_get_device("DARwIn-OP");

-- Start stepping through our experiment
controller.wb_robot_step(timeStep);

-- Add a function for getting the time
get_time = controller.wb_robot_get_time;

print("I am the Dodgeball supervisor!");

t0 = get_time();
saveCount = 0;

-- Seed the random numbers
math.randomseed( os.time() )
-- TODO: for repeatability, read a seed from a set file

-- Add the update function
function update()

  -- Check if a collision has occurred
  -- if(shm.collision==1)

  t = get_time();
  tDiff = t - t0;

  -- Reset after 10 seconds
  if( tDiff > 20 ) then
    print("Resetting!");
    set_next_ball_position();
    controller.wb_supervisor_simulation_revert();
    controller.wb_robot_step(timeStep);
    os.exit();
  end
  
  -- Update the timestep
  if (controller.wb_robot_step(timeStep) < 0) then
    --Shut down controller:
    os.exit();
  end

end

function save_trial(rgb)
  saveCount = saveCount + 1;
  local filename = string.format("/tmp/trial_%03d.raw", saveCount);
  local f = io.open(filename, "w+");
  assert(f, "Could not open save image file");
  for i = 1,3*camera.width*camera.height do
    local c = rgb[i];
    if (c < 0) then
      c = 256+c;
    end
    f:write(string.char(c));
  end
  f:close();
end

function set_next_ball_position()

  local filename = "/Users/stephen/Desktop/dodgeball_sim/ball_params.txt";
  local f = io.open(filename, "r");
  assert(f, "Could not open ball parameters file");
  -- Read the previous Trial Number
  local line = f:read()
  assert( line, "No first line in ball parameter file" )
  local trial_num = tonumber( line ) + 1;
  print("Setting up for trial number "..trial_num );
  f:close();

  -- Make a target and a starting position
--[[
  target = util.randu(3);  -- 0 to 1 random numbers
  target[2] = (target[2]-.5); -- +/- half a meter on the "baseline"
--]]
  local target = util.randn(3);  -- Normal numbers around 0
  target[2] = .2*target[2];
  target[1] = 0;
  target[3] = 0;

  -- Get an initial position (within some arc)
  local initial = util.randu(2);
  local initial_n = util.randn(2);
  r = initial[1]+1; -- Between 1 and 2 meters out
  --th = initial[1]*math.pi; -- Zero and 180 degrees
  th = (math.pi/6)*initial_n[2]+math.pi/2; -- Zero and 180 degrees
  if( th < 0 or th > math.pi ) then
    th = math.pi/2; -- center
  end
  y0 = r * math.cos( th );
  x0 = r * math.sin( th );
  z0 = 0;
  --print("r: "..r..", th: "..th)
  --print("x0: "..x0..", y0: "..y0)

  -- Set the velocity so that we hit the target
  diffx = x0 - target[1];
  diffy = y0 - target[2];
  diffz = z0 - target[3];
  diffr = math.sqrt( diffx^2+diffy^2+diffz^2 );
  diffth = math.atan2( diffx, diffy );
  desired_speed = 1.5*util.randu(1)[1]+.75; -- Normally .75 m/s initial speed +[0,1.5]
  vx0 = -1*desired_speed * math.sin( diffth );
  vy0 = -1*desired_speed * math.cos( diffth );
  vz0 = 0;

  local f = io.open(filename, "w");
  assert(f, "Could not open ball parameters file");
  f:write(string.format("%d\n", trial_num));
  f:write(string.format("%f %f %f\n", x0, y0, z0));
  f:write(string.format("%f %f %f\n", vx0, vy0, vz0));
  f:close();
end


