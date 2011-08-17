module(..., package.seeall);

require('carray');
require('vector');
require('Config');

require('ImageProc');
require('HeadTransform');
require('Camera');
require('Detection');

require('vcm');
require('mcm');


if (Config.camera.width ~= Camera.get_width()
    or Config.camera.height ~= Camera.get_height()) then
  print('Camera width/height mismatch');
  print('Config width/height = ('..Config.camera.width..', '..Config.camera.height..')');
  print('Camera width/height = ('..Camera.get_width()..', '..Camera.get_height()..')');
  error('Config file is not set correctly for this camera. Ensure the camera width and height are correct.');
end


colorOrange = Config.color.orange;
colorYellow = Config.color.yellow;
colorCyan = Config.color.cyan;
colorField = Config.color.field;
colorWhite = Config.color.white;

vcm.set_image_width(Config.camera.width);
vcm.set_image_height(Config.camera.height);

yellowGoalCountThres = Config.vision.yellow_goal_count_thres;

camera = {};

camera.width = Camera.get_width();
camera.height = Camera.get_height();
camera.npixel = camera.width*camera.height;
camera.image = Camera.get_image();
camera.status = Camera.get_camera_status();
camera.switchFreq = Config.camera.switchFreq;
camera.ncamera = Config.camera.ncamera;

-- Initialize the Labeling
labelA = {};
-- labeled image is 1/4 the size of the original
labelA.m = camera.width/2;
labelA.n = camera.height/2;
labelA.npixel = labelA.m*labelA.n;

scaleB = 4;
labelB = {};
labelB.m = labelA.m/scaleB;
labelB.n = labelA.n/scaleB;
labelB.npixel = labelB.m*labelB.n;

print('Vision LabelA size: ('..labelA.m..', '..labelA.n..')');
print('Vision LabelB size: ('..labelB.m..', '..labelB.n..')');


saveCount = 0;

-- debugging settings
use_point_goal = Config.vision.use_point_goal;
vcm.set_debug_enable_shm_copy(Config.vision.copy_image_to_shm);
vcm.set_debug_store_goal_detections(Config.vision.store_goal_detections);
vcm.set_debug_store_ball_detections(Config.vision.store_ball_detections);
vcm.set_debug_store_all_images(Config.vision.store_all_images);

-- Timing
count = 0;
lastImageCount = 0;
t0 = unix.time()

function entry()
  -- Start the HeadTransform machine
  HeadTransform.entry();

  Detection.entry();

  -- Load the lookup table
  print('loading lut: '..Config.camera.lut_file);
  camera.lut = carray.new('c', 262144);
  load_lut(Config.camera.lut_file);

  for c=1,Config.camera.ncamera do
    -- cameras are indexed starting at 0
    Camera.select_camera(c-1);

    for i,auto_param in ipairs(Config.camera.auto_param) do
      print('Camera '..c..': setting '..auto_param.key..': '..auto_param.val[c]);
      Camera.set_param(auto_param.key, auto_param.val[c]);
      unix.usleep(100000);
    end
    for i,param in ipairs(Config.camera.param) do
      print('Camera '..c..': setting '..param.key..': '..param.val[c]);
      Camera.set_param(param.key, param.val[c]);
      unix.usleep(100000);
    end
  end

  ball = {};
  ball.detect = 0;

  ballYellow={};
  ballYellow.detect=0;

  ballCyan={};
  ballCyan.detect=0;

  goalYellow = {};
  goalYellow.detect = 0;

  goalCyan = {};
  goalCyan.detect = 0;

  landmarkYellow = {};
  landmarkYellow.detect = 0;

  landmarkCyan = {};
  landmarkCyan.detect = 0;

  line = {};
  line.detect = 0;

  spot = {};
  spot.detect = 0;

  visionBoundary = {{0,0},{0,0},{0,0},{0,0}};

end


function update()
  tstart = unix.time();

  -- get image from camera
  camera.image = Camera.get_image();
  local status = Camera.get_camera_status();
  if status.count ~= lastImageCount then
    lastImageCount = status.count;
  else
    return false; 
  end
    
  -- Add timer measurements
  count = count + 1;

  HeadTransform.update(status.select, status.joint);

  if camera.image == -2 then
    print "Re-enqueuing of a buffer error...";
    exit()
  end

  -- perform the initial labeling
  labelA.data  = ImageProc.yuyv_to_label(camera.image,
                                          carray.pointer(camera.lut),
                                          camera.width/2,
                                          camera.height);

  -- determine total number of pixels of each color/label
  colorCount = ImageProc.color_count(labelA.data, labelA.npixel);

  -- bit-or the segmented image
  labelB.data = ImageProc.block_bitor(labelA.data, labelA.m, labelA.n, scaleB, scaleB);


  Detection.update();

  update_shm(status)

  -- switch camera
  local cmd = vcm.get_camera_command();
  if (cmd == -1) then
    if (count % camera.switchFreq == 0) then
      Camera.select_camera(1-Camera.get_select()); 
    end
  else
    if (cmd >= 0 and cmd < camera.ncamera) then
      Camera.select_camera(cmd);
    else
      print('WARNING: attempting to switch to unkown camera select = '..cmd);
    end
  end

  return true;
end

function update_shm(status)
  -- Update the shared memory
  -- Shared memory size argument is in number of bytes

  if vcm.get_debug_enable_shm_copy() == 1 then
    if ((vcm.get_debug_store_all_images() == 1)
        or (ball.detect == 1
            and vcm.get_debug_store_ball_detections() == 1)
        or ((goalCyan.detect == 1 or goalYellow.detect == 1) 
            and vcm.get_debug_store_goal_detections() == 1)) then
      vcm.set_image_yuyv(camera.image);
      vcm.set_image_labelA(labelA.data);
      vcm.set_image_labelB(labelB.data);
    end
  end

  vcm.set_image_select(status.select);
  vcm.set_image_count(status.count);
  vcm.set_image_time(status.time);
  vcm.set_image_headAngles({status.joint[1], status.joint[2]});
  vcm.set_image_horizonA(HeadTransform.get_horizonA());
  vcm.set_image_horizonB(HeadTransform.get_horizonB());

  Detection.update_shm();

  -- TODO: add boundary to vcm shm (for NSL support)
  --[[
  for i = 1,5 do
	  vcm.etc.boundaryX[i] = visionBoundary[i][1];
	  vcm.etc.boundaryY[i] = visionBoundary[i][2];
  end
  --]]
end

function exit()
  HeadTransform.exit();
end

function bboxStats(color, bboxB)
  bboxA = {};
  bboxA[1] = scaleB*bboxB[1];
  bboxA[2] = scaleB*bboxB[2] + scaleB - 1;
  bboxA[3] = scaleB*bboxB[3];
  bboxA[4] = scaleB*bboxB[4] + scaleB - 1;
  return ImageProc.color_stats(labelA.data, labelA.m, labelA.n, color, bboxA);
end

function bboxB2A(bboxB)
  bboxA = {};
  bboxA[1] = scaleB*bboxB[1];
  bboxA[2] = scaleB*bboxB[2] + scaleB - 1;
  bboxA[3] = scaleB*bboxB[3];
  bboxA[4] = scaleB*bboxB[4] + scaleB - 1;
  return bboxA;
end

function bboxArea(bbox)
  return (bbox[2] - bbox[1] + 1) * (bbox[4] - bbox[3] + 1);
end

function update_vision_boundary()
  --This function projects the boundary of current labeled image
  --To see where the robot is looking at in local and global coordinate

  local image_boundary={{0,0},{camera.width,0},	{0,camera.height},
	{camera.width,camera.height},{camera.width/2,camera.height/2}};
  local_boundary={};
  for i=1,5 do
	local v=HeadTransform.coordinatesA(image_boundary[i],0.1);
	v=HeadTransform.projectGround(v);
	visionBoundary[i]=vector.new(v);
  end
end

function load_lut(fname)
  local cwd = unix.getcwd();
  if string.find(cwd, "WebotsController") then
    cwd = cwd.."/Player";
  end
  cwd = cwd.."/Data/";
  local f = io.open(cwd..fname, "r");
  assert(f, "Could not open lut file");
  local s = f:read("*a");
  for i = 1,string.len(s) do
    camera.lut[i] = string.byte(s,i,i);
  end
end


function save_rgb(rgb)
  saveCount = saveCount + 1;
  local filename = string.format("/tmp/rgb_%03d.raw", saveCount);
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


