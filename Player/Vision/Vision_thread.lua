-- Vision running as thread for each camera, need require locally

local Vision = {}
require('carray');
require('vector');
require('Config');

-- Enable Webots specific
if (string.find(Config.platform.name,'Webots')) then
  webots = true
end

ImageProc=require('ImageProc');
require('HeadTransform');
require('vcm');
require('mcm');
require('Body')
require('ColorLUT');

local Detection = require('Detection')
if webots then
  require('Camera')
else  
  local Camera = require('Camera')
end
  
local labelA_t, labelB_t, cc_t

-- debugging settings
vcm.set_debug_enable_shm_copy(Config.vision.copy_image_to_shm);
vcm.set_debug_store_goal_detections(Config.vision.store_goal_detections);
vcm.set_debug_store_ball_detections(Config.vision.store_ball_detections);
vcm.set_debug_store_all_images(Config.vision.store_all_images);

local camera_init = function(self, cidx)
  if webots then
    self.camera = Camera.init(cidx)
  elseif Config.dev.camera == 'SimCam' then
    self.camera = Camera;
  else
    self.camera = Camera.init(Config.camera.device[cidx],
                         Config.camera.width[cidx],
                         Config.camera.height[cidx],
                         Config.camera.img_type)
  end
  
  if Config.dev.camera ~= 'SimCam' and 
      (Config.camera.width[cidx] ~= self.camera:get_width()
      or Config.camera.height[cidx] ~= self.camera:get_height()) then
    print('Camera width/height mismatch');
    print('Config width/height = ('..Config.camera.width[cidx]..', '
                                   ..Config.camera.height[cidx]..')');
    print('Camera width/height = ('..self.camera:get_width()..', '
                                   ..self.camera:get_height()..')');
    error('Config file is not set correctly for this camera. Ensure the camera width and height are correct.');
  end
  print("Config.camera.width",Config.camera.width[cidx],cidx)
  vcm['set_image'..cidx..'_width'](Config.camera.width[cidx]);
  vcm['set_image'..cidx..'_height'](Config.camera.height[cidx]);
  
end

local camera_setting_Naov4 = function(self, c)
  for i,param in ipairs(Config.camera.param) do
    print('Camera '..c..': setting '..param.key..': '..param.val[c]);
    self.camera:set_param(param.key, param.val[c], c-1);
    unix.usleep (100);
    print('Camera '..c..': set to '..param.key..': '..
            self.camera:get_param(param.key, c-1));
  end
  self.camera:set_param('Brightness', Config.camera.brightness, c-1);     
  self.camera:set_param('White Balance, Automatic', 1, c-1); 
  self.camera:set_param('Auto Exposure',0, c-1);
  self.camera:set_param('White Balance, Automatic', 0, c-1);
  self.camera:set_param('Auto Exposure',0, c-1);
  local expo = self.camera:get_param('Exposure', c-1);
  local gain = self.camera:get_param('Gain', c-1);
  self.camera:set_param('Auto Exposure',1, c-1);   
  self.camera:set_param('Auto Exposure',0, c-1);
  self.camera:set_param ('Exposure', expo, c-1);
  self.camera:set_param ('Gain', gain, c-1);
  self.camera:set_param('White Balance Temperature', Config.camera.param[12].val[c],c-1);
  self.camera:set_param ('Do White Balance', Config.camera.param[10].val[c], c-1);
  local rname = Config.game.robotName;
--  if rname == 'ticktock' or rname == 'ruffio' or rname == 'dickens' then
  self.camera:set_param('White Balance Temperature', Config.camera.param[12].val[c],c-1);
  --end

  print('Camera #'..c..' set');
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

  
  labelA_t = ImageProc.yuyv_to_label(self.image, self.lut)
  labelB_t = ImageProc.block_bitor(labelA_t)
  cc_t = ImageProc.color_count(labelA_t)
  -- convert to ligth userdata
  self.labelA.data = cutil.torch_to_userdata(labelA_t)
  self.colorCount  = cc_t
  self.labelB.data = cutil.torch_to_userdata(labelB_t)
  self:update_shm(cidx, headAngles)
  
  self.Detection:update(self);

  self.Detection:update_shm(self);
  self.timestamp = unix.time()

  --flush buffer
  self.debug_message = self.debug_message_buf
  self.debug_message_buf=''

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
    end
    if vcm.get_camera_broadcast() > 0 then --Wired monitor broadcasting
      vcm['set_image'..cidx..'_labelA'](t.labelA.data);
      vcm['set_image'..cidx..'_labelB'](t.labelB.data);
      if #t.debug_message <= 600 then
        vcm['set_debug'..cidx..'_message'](t.debug_message);
      else
        vcm['set_debug'..cidx..'_message'](string.sub(t.debug_message,1,599));
      end
      
    elseif vcm.get_camera_teambroadcast() > 0 then --Wireless Team broadcasting
      --Only copy labelB
      vcm['set_image'..cidx..'_labelB'](t.labelB.data);
    end
  end
  vcm['set_image'..cidx..'_headAngles'](headAngles);
  vcm['set_image'..cidx..'_horizonA'](HeadTransform.get_horizonA());
  vcm['set_image'..cidx..'_horizonB'](HeadTransform.get_horizonB());
  vcm['set_image'..cidx..'_horizonDir'](HeadTransform.get_horizonDir())
  t:update_shm_fov(cidx);
end

local zmq_broadcast = function(t, cidx)
--  print('sending zmq')
  local yuyv = vcm['get_image'..cidx..'_yuyv']()
  local width = vcm['get_image'..cidx..'_width']() 
  local height = vcm['get_image'..cidx..'_height']()
  local img_packet = {}
  img_packet.width = width
  img_packet.height = height
 
----[[
  local img_ud = carray.byte(yuyv, width * height * 2);
  local img_str = tostring(img_ud)
  img_packet.channel = 4
  img_packet.type = 'yuyv'
--]]
  -- webots always send raw yuyv
--[[
  local img_str = jpeg.compress_yuyv(yuyv, width, height)
  img_packet.channel = 3
  img_packet.type = 'jpg'
--]]

  img_packet.data = img_str

  t.yuyv_channel:send(msgpack.pack(img_packet))

  local labelA_ud = carray.byte(t.labelA.data, t.labelA.m * t.labelA.n)
  local labelA_str = tostring(labelA_ud)
  img_packet = {}
  img_packet.width = width / t.scaleA
  img_packet.height = height / t.scaleA
  img_packet.channel = 1
  img_packet.type = 'raw'
  img_packet.data = labelA_str
  t.labelA_channel:send(msgpack.pack(img_packet))

  local labelB_ud = carray.byte(t.labelB.data, t.labelB.m * t.labelB.n)
  local labelB_str = tostring(labelB_ud)
  img_packet = {}
  img_packet.width = width / t.scaleA / t.scaleB
  img_packet.height = height / t.scaleA / t.scaleB
  img_packet.channel = 1
  img_packet.type = 'raw'
  img_packet.data = labelB_str
  t.labelB_channel:send(msgpack.pack(img_packet))

  -- pack vcm
  for sharedkey, sharedvalue in pairs(vcm.shared) do
    local send_vcm = {}
    for itemkey, itemvalue in pairs(vcm.shared[sharedkey]) do
      local itemdata = vcm['get_'..sharedkey..'_'..itemkey]();
      -- for string, only pack non-zero length
      if type(itemdata) == 'string' or --  and #itemdata > 0) or
         -- pack number and table and string 
         type(itemdata) == 'table' or 
         type(itemdata) == 'number' 
         then
        send_vcm[itemkey] = itemdata
      end
    end
    t['vcm_'..sharedkey..'_channel']:send(msgpack.pack(send_vcm))
  end
end

local add_debug_message = function(self, message)
  --[[
  if string.len(self.debug_message)>600 then
    --something is wrong, just reset it 
    self.debug_message_buf='';
  end
  --]]
  self.debug_message_buf = self.debug_message_buf..message;
end

function Vision.exit()
  HeadTransform.exit();
end

function Vision.entry(cidx)
  local self = {}
  -- timestamp for detection synchronization
  
  self.timestamp = unix.time()
  -- add method
  self.camera_init = camera_init
  self.camera_setting_Naov4 = camera_setting_Naov4
  self.update = update
  self.zmq_broadcast = zmq_broadcast
  self.update_shm = update_shm
  self.update_shm_fov = update_shm_fov -- for debug message
  self.debug_message_buf = ''
  self.debug_message = ''
  self.add_debug_message = add_debug_message

  local cidx = cidx or 1
  
  -- init camera
  self:camera_init(cidx)
  self.camera_index = cidx
  

  if Config.platform.name == 'NaoV4' then
    self:camera_setting_Naov4(cidx)
  else
    print ('Platform Error!')
  end
  print('camera '..cidx..' setting done')

  -- Initialize the Labeling
  self.scaleA = Config.vision.scaleA[cidx]
  self.labelA = {}
  self.labelA.m = Config.camera.width[cidx] / self.scaleA
  self.labelA.n = Config.camera.height[cidx] / self.scaleA
  self.labelA.npixel = self.labelA.m * self.labelA.n;
  if  webots == 1 then
    self.labelA.m = self.camera:get_width();
    self.labelA.n = self.camera:get_height();
    self.labelA.npixel = self.labelA.m*self.labelA.n;
  end
 
  self.scaleB = Config.vision.scaleB[cidx];
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
  print"TORCH FFI LABELING"
  -- Setup the new vision labeling mechanism
  local w, h = Config.camera.width[cidx], Config.camera.height[cidx]
  ImageProc.setup(w, h, self.scaleA, self.scaleB)

  local lut_filename = "./Data/"..Config.camera.lut_file[cidx]
  local lut_id = ImageProc.load_lut(lut_filename)

  self.lut = ImageProc.get_lut(lut_id):data()
  print("LOADED "..lut_filename)
  return self 
end

return Vision
