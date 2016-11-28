-- Vision running as thread for each camera, need require locally
--WEBOTS SPECIFIC VISION CODE


local Vision = {}

--[[
local ok, _ = pcall(require, 'ffi')
if ok then
  ImageProc2 = require'ImageProcFFI'
end
--]]

require('carray');
require('vector');
require('Config');

-- Enable Webots specific
webots = true


require('ImageProc');
require('HeadTransform');
require('vcm');
require('mcm');
require('Body')
require('ColorLUT');
local camera = require('Camera')

local Detection = require('Detection')


  
local labelA_t, labelB_t, cc_t

-- debugging settings
vcm.set_debug_enable_shm_copy(Config.vision.copy_image_to_shm);
vcm.set_debug_store_goal_detections(Config.vision.store_goal_detections);
vcm.set_debug_store_ball_detections(Config.vision.store_ball_detections);
vcm.set_debug_store_all_images(Config.vision.store_all_images);


local camera_init = function(self, cidx)
  self.camera = Camera.init(cidx)
--  print("Config.camera.width",Config.camera.width,cidx)
  vcm['set_image'..cidx..'_width'](Config.camera.width[cidx]);
  vcm['set_image'..cidx..'_height'](Config.camera.height[cidx]);
end

local update = function(self)
  local cidx = self.camera_index
  -- get image from camera
  if Config.dev.camera == 'SimCam' then
    self.image = Camera.get_image(cidx);
  else
    self.image, self.img_buf_sz, 
      self.img_count, self.img_time = self.camera:get_image();
  end
  if (self.image == -1) then
    return
  end

  vcm['set_image'..cidx..'_yuyv'](self.image);
  vcm['set_image'..cidx..'_time'](self.img_time);
  vcm['set_image'..cidx..'_count'](self.img_count);

  headAngles = Body.get_head_position();
  HeadTransform.update(cidx-1, headAngles);

  if ImageProc2 then
    labelA_t = ImageProc2.yuyv_to_label(self.image, self.lut)
    labelB_t = ImageProc2.block_bitor(labelA_t)
    cc_t = ImageProc2.color_count(labelA_t)
    -- convert to ligth userdata
    self.labelA.data = cutil.torch_to_userdata(labelA_t)
    self.colorCount  = cc_t
    self.labelB.data = cutil.torch_to_userdata(labelB_t)
  else
--SJ: this function is broken, so we just skip this
--But this result in low-resolution label...      
--    if webots then
    if false then
      self.labelA.data = self.camera:get_labelA(self.lut)
    else
      self.labelA.data =
      ImageProc.yuyv_to_label(
      self.image, self.lut,
      self.camera:get_width(), 
      self.camera:get_height(), 
      self.scaleA
      );
    end
    -- determine total number of pixels of each color/label
    self.colorCount = ImageProc.color_count(self.labelA.data, self.labelA.npixel);
    -- bit-or the segmented image
    self.labelB.data = ImageProc.block_bitor(self.labelA.data, self.labelA.m, 
                           self.labelA.n, self.scaleB, self.scaleB);
   --print('ball',self.colorCount[1])
  end

  self:update_shm(cidx, headAngles)
  
  self.Detection:update(self);

  self.Detection:update_shm(self);

--[[
  if string.find(Config.platform.name,'Webots') then
    self:zmq_broadcast(cidx)
  end
--]]

  self.timestamp = unix.time()

  return true;
end

local update_shm_fov = function(self, cidx)
  --This function projects the boundary of current labeled image

  local fovC={Config.camera.width[cidx]/2,Config.camera.height[cidx]/2};
  local fovBL={0,Config.camera.height[cidx]};
  local fovBR={Config.camera.width[cidx],Config.camera.height[cidx]};
  local fovTL={0,0};
  local fovTR={Config.camera.width[cidx],0};

  vcm['set_image'..cidx..'_fovC'](vector.slice(HeadTransform.projectGround(
 	                               HeadTransform.coordinatesA(fovC,0.1)),1,2));
  vcm['set_image'..cidx..'_fovTL'](vector.slice(HeadTransform.projectGround(
 	                               HeadTransform.coordinatesA(fovTL,0.1)),1,2));
  vcm['set_image'..cidx..'_fovTR'](vector.slice(HeadTransform.projectGround(
 	                               HeadTransform.coordinatesA(fovTR,0.1)),1,2));
  vcm['set_image'..cidx..'_fovBL'](vector.slice(HeadTransform.projectGround(
 	                               HeadTransform.coordinatesA(fovBL,0.1)),1,2));
  vcm['set_image'..cidx..'_fovBR'](vector.slice(HeadTransform.projectGround(
 	                    HeadTransform.coordinatesA(fovBR,0.1)),1,2));
end

local update_shm = function(t, cidx, headAngles)
  -- Update the shared memory
  if vcm.get_debug_enable_shm_copy() == 1 and (vcm.get_debug_store_all_images() == 1) then
    if webots then
    	vcm.set_camera_yuyvType(1)
      vcm['set_image'..cidx..'_labelA'](t.labelA.data);
      vcm['set_image'..cidx..'_labelB'](t.labelB.data);
      vcm['set_debug'..cidx..'_message'](t.debug_message);

--      print('set_image'..cidx..'_labelB'..' Set')

    end
    if vcm.get_camera_broadcast() > 0 then --Wired monitor broadcasting
      vcm['set_image'..cidx..'_labelA'](t.labelA.data);
      vcm['set_image'..cidx..'_labelB'](t.labelB.data);
      vcm['set_debug'..cidx..'_message'](t.debug_message_out);
      if vcm.get_camera_broadcast() == 2 then
        vcm['set_image'..cidx..'_yuyv2'](ImageProc.subsample_yuyv2yuyv(
                vcm['get_image'..cidx..'_yuyv'](),
                Config.camera.width[cidx]/2,
                Config.camera.height[cidx], 2));
      end
    elseif vcm.get_camera_teambroadcast() > 0 then --Wireless Team broadcasting
      --Only copy labelB
      vcm['set_image'..cidx..'_labelB'](t.labelB.data);
    end
  end

  --cycle debug message buffer
  t.debug_message_out = t.debug_message
  t.debug_message=''


  vcm['set_image'..cidx..'_headAngles'](headAngles);
  vcm['set_image'..cidx..'_horizonA'](HeadTransform.get_horizonA());
  vcm['set_image'..cidx..'_horizonB'](HeadTransform.get_horizonB());
  vcm['set_image'..cidx..'_horizonDir'](HeadTransform.get_horizonDir())
  t:update_shm_fov(cidx);
end


local add_debug_message = function(self, message)
  if string.len(self.debug_message)>1000 then
    --something is wrong, just reset it 
    self.debug_message='';
  end
  self.debug_message = self.debug_message..message;
end

function Vision.exit()
  HeadTransform.exit();
end

function Vision.entry(cidx)
  local self = {}
  -- timestamp for detection synchronization
  
  self.timestamp = unix.time()
  self.camera_init = camera_init
  self.update = update
  self.update_shm = update_shm
  self.update_shm_fov = update_shm_fov -- for debug message
  self.debug_message = '' 
  self.debug_message_out = '' --Now we double-buffer message
  self.add_debug_message = add_debug_message

  local cidx = cidx or 1
    -- init camera
  self:camera_init(cidx)
  self.camera_index = cidx
  
  -- Initialize the Labeling
  self.scaleA = Config.vision.scaleA
  self.scaleB = Config.vision.scaleB;

  
  if type(self.scaleA)=='table' then
    self.scaleA = Config.vision.scaleA[cidx]
    self.scaleB = Config.vision.scaleB[cidx]
  end



  self.labelA = {}
  self.labelA.m = self.camera:get_width() / self.scaleA
  self.labelA.n = self.camera:get_height() / self.scaleA
  self.labelA.npixel = self.labelA.m * self.labelA.n;
  
  
  self.labelB = {}
  self.labelB.m = self.labelA.m / self.scaleB;
  self.labelB.n = self.labelA.n / self.scaleB;
  self.labelB.npixel = self.labelB.m * self.labelB.n;
 

  vcm['set_image'..cidx..'_scaleA'](Config.vision.scaleA[cidx]);
  vcm['set_image'..cidx..'_scaleB'](Config.vision.scaleB[cidx]);
  print('Vision LabelA size: ('..self.labelA.m..', '..self.labelA.n..')');
  print('Vision LabelB size: ('..self.labelB.m..', '..self.labelB.n..')');

  --Temporary value.. updated at body FSM at next frame
  vcm.set_camera_bodyHeight(Config.walk.bodyHeight);
  vcm.set_camera_bodyTilt(0);
  vcm.set_camera_height(Config.walk.bodyHeight+Config.head.neckZ);

  -- Start the HeadTransform machine
  HeadTransform.entry(cidx);

  -- Initiate Detection
  self.Detection = Detection.entry(self);

  -- Load the lookup table
  if ImageProc2 then
    print"NEW LABELING"
    -- Setup the new vision labeling mechanism
    local w, h = self.camera:get_width(), self.camera:get_height()
    ImageProc2.setup(w, h, self.scaleA, self.scaleB)

    local lut_filename = "Player/Data/"..Config.camera.lut_file[cidx]
    local lut_id = ImageProc2.load_lut(lut_filename)
    self.lut = ImageProc2.get_lut(lut_id):data()
    print("LOADED "..lut_filename)
  else
    self.lut_ud = ColorLUT.load_LUT(Config.camera.lut_file[cidx], cidx);
    self.lut, self.lut_size = self.lut_ud:pointer()
  end
  return self 
end

return Vision
