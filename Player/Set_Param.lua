require ('init');
require ('HeadTransform');
require ('unix');
require ('getch');
require ('Broadcast');
require ('Config');
require ('Camera');
require ('vcm');
require ('vector');
require ('carray');
require ('ImageProc');
require ('io');


function Entry() 
  vcm.set_image_width(Config.camera.width);
  vcm.set_image_height(Config.camera.height);
  camera = {};
  camera.width = Camera.get_width();
  camera.height = Camera.get_height();
  camera.npixel = camera.width*camera.height;
  camera.image = Camera.get_image();
  camera.status = Camera.get_camera_status();
  camera.switchFreq = Config.camera.switchFreq;
  camera.ncamera = Config.camera.ncamera;

  labelA = {};
  labelA.m = camera.width/2;
  labelA.n = camera.height/2;
  labelA.npixel = labelA.m*labelA.n;
  scaleB = Config.vision.scaleB;
  labelB = {};
  labelB.m = labelA.m/scaleB;
  labelB.n = labelA.n/scaleB;
  labelB.npixel = labelB.m*labelB.n;

  vcm.set_image_scaleB(Config.vision.scaleB);
  camera.lut = carray.new('c', 262144);
  load_lut(Config.camera.lut_file);

  imcount = 0;
  
  Cam_init();
  
end

function Cam_init()
  for c=1,Config.camera.ncamera do
    Camera.select_camera(c-1);   
    Camera.set_param('Brightness', Config.camera.brightness);     
    Camera.set_param('White Balance, Automatic', 1); 
    --Camera.set_param('Auto Exposure', 1);
    Camera.set_param('Auto Exposure',0);
    for i,param in ipairs(Config.camera.param) do
      Camera.set_param(param.key, param.val[c]);
      unix.usleep (100);
    end
    Camera.set_param('White Balance, Automatic', 0);
    local expo = Camera.get_param('Exposure');
    local gain = Camera.get_param('Gain');
    Camera.set_param('Auto Exposure',1);   
    Camera.set_param('Auto Exposure',0);
    Camera.set_param ('Exposure', expo);
    Camera.set_param ('Gain', gain);
    print('Camera #'..c..' set');
  end 
end


function Read_Num()
  str = io.read();
  while (str == nil) do
    unix.usleep (10000);
    str = io.read();
  end 
  num = {};
  for i = 1, #str do
    num[i] = tonumber (string.byte(str, i));
    if (num[i] < 48 or num [i] > 57) then
      print ('not an integer!');
      return -1;
    end 
  end 
  local result = 0;
  for i = 1, #num do
    result = result + (num [i]- 48)*(10 ^ (#num - i));
  end
  return result;
end


function Switch_to_Top_Camera()
  Camera.select_camera (0);
  print ('Switched to Top Camera (Camera 0)')
end

function Switch_to_Bottom_Camera()
  Camera.select_camera(1);
  print ('Switched to Bottom Camera (Camera 1)')
end

function Set_Brightness()
  print ('Current brightness is: '..Camera.get_param('Brightness')..' type in a integer which is multiple of 4 between 0 and 255');
  local param = Read_Num();
  local expo = Camera.get_param('Exposure');
  local gain = Camera.get_param('Gain');
  while (param == -1 or param > 255 or (param % 4) ~= 0) do
    unix.usleep (10000);
    param = Read_Num(); 
  end
  Camera.set_param ('Auto Exposure', 1);
  Camera.set_param ('White Balance, Automatic', 1);
  Camera.set_param ('Brightness', param);
  Camera.set_param ('Auto Exposure', 0);
  Camera.set_param ('White Balance, Automatic', 0);
  Camera.set_param ('Exposure', expo);
  Camera.set_param ('Gain', gain);
  print('Brightness: ' , Camera.get_param('Brightness'))
end

function Set_Contrast()
  print ('Current contrast is: '..Camera.get_param('Contrast')..' type in a integer between 16 and 64');
  local param = Read_Num();
  while (param < 16 or param > 64) do
    unix.usleep (10000);
    print ('Type in a integer between 16 and 64');
    param = Read_Num(); 
  end
  Camera.set_param ('Contrast', param);
  print('Contrast: ', Camera.get_param('Contrast'))
end

function Set_Saturation()
  print ('Current saturation is: '..Camera.get_param('Saturation')..' type in a integer between 0 and 255');
  local param = Read_Num();
  while (param < 0 or param > 255) do
    unix.usleep (10000);
    print ('Type in a integer between 0 and 255');
    param = Read_Num(); 
  end 
  Camera.set_param ('Saturation', param);
  print('Saturation: ', Camera.get_param('Saturation'))
end

function Set_Exposure()
  print ('Current exposure is: '..Camera.get_param('Exposure')..' type in a integer between 0 and 255');
  local param = Read_Num();
  while (param < 0 or param > 255) do
    unix.usleep (10000);
    print ('Type in a integer between 0 and 255');
    param = Read_Num(); 
  end    
  --local backup = Camera.get_param ('Gain');
  --Camera.set_param ('White Balance, Automatic', 0);
  --Camera.set_param ('Auto Exposure', 1)
  Camera.set_param ('Exposure', param);
  --Camera.set_param ('Gain', backup);
  --Camera.set_param ('White Balance, Automatic', 0);
  --Camera.set_param ('Auto Exposure', 0);
  print('Exposure: ' , Camera.get_param('Exposure'))
end

function Set_Gain()
  print ('Current gain is: '..Camera.get_param('Gain')..' type in a integer between 0 and 255');
  local param = Read_Num();
  while (param < 0 or param > 255) do
    unix.usleep (10000);
    print ('Type in a integer between 0 and 255');
    param = Read_Num(); 
  end
  --local backup = Camera.get_param ('Exposure');
  --Camera.set_param ('White Balance, Automatic', 1);
  --Camera.set_param ('Auto Exposure', 0);
  Camera.set_param ('Gain', param);
  --Camera.set_param ('Exposure', backup);
  --Camera.set_param ('White Balance, Automatic', 0);
  --Camera.set_param ('Auto Exposure', 1);
  print('Gain: ' , Camera.get_param('Gain'))
end

function Set_Sharpness()
  print ('Current sharpness is: '..Camera.get_param('Sharpness')..' type in a integer between 0 and 5');
  local param = Read_Num();
  while (param < 0 or param > 5) do
    unix.usleep (10000);
    print ('Type in a integer between 0 and 5');
    param = Read_Num(); 
  end 
  Camera.set_param ('Sharpness', param);
  print('Sharpness: ' , Camera.get_param('Sharpness'))
end

function Print_All()
  local index = Camera.get_select();
  for c=1,Config.camera.ncamera do
    Camera.select_camera (c-1);
    print ('Camera No. '..c-1)
    print ('Brightness: '..Camera.get_param('Brightness') ) 
    for i,param in ipairs(Config.camera.param) do
      print (param.key..': '..Camera.get_param(param.key))
    end
    print ('Auto Exposure: '..Camera.get_param('Auto Exposure'))
    print ('White Balance, Automatic: '..Camera.get_param('White Balance, Automatic'))
    print ('');
  end
  Camera.select_camera (index);
end  

function Help()
  print ('This is a tool to set camera parameters for NaoV4')
  print ('Press "+" to switch to the top camera;')
  print ('Press "-" to switch to the bottom camera;')
  print ('Press "c" to set Contrast;')
  print ('Press "b" to set Brightness;')
  print ('Press "s" to set Saturation;')
  print ('Press "e" to set Exposure;');
  print ('Press "g" to set Gain;')
  print ('Press "a" to set Sharpness;')
  print ('press "i" to go back to initial parameters from the Config file;')
  print ('Press "p" to see all the current parameters;')
  print ('Press "h" to see the instruction.')
end  



utilFunctions = {Cam_init,
                 Switch_to_Top_Camera,
                 Switch_to_Bottom_Camera,
                 Set_Brightness,
                 Set_Contrast,
                 Set_Saturation,
                 Set_Exposure,
                 Set_Gain,
                 Set_Sharpness,            
		 Print_All,
                 Help
                }

utilCommands =  {'i',
                 '+',
                 '-',
                 'b',
		 'c',
                 's',
                 'e',
                 'g',
                 'a',
                 'p',
                 'h'
                 }


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


function broadcast()
  vcm.set_camera_broadcast(2);
  imcount = imcount + 1;
  Broadcast.update(2);
  Broadcast.update_img(2, imcount);    
end


function update()
  getch.enableblock(1);
  local command =  getch.get();
  if #command >0 then
    getch.enableblock(0);
    local byte = string.byte (command,1);
    for i = 1, #utilCommands do
      if (byte == string.byte (utilCommands [i])) then
        print ('')
        utilFunctions[i]();
      end
    end   
  end
  camera.image = Camera.get_image();
  vcm.set_image_yuyv(camera.image);
  vcm.set_image_yuyv2(ImageProc.subsample_yuyv2yuyv(
                                         vcm.get_image_yuyv(),
                                         camera.width/2, camera.height,2));
  labelA.data = ImageProc.yuyv_to_label(vcm.get_image_yuyv(),
                                          carray.pointer(camera.lut),
                                          camera.width/2,
                                          camera.height);
  labelB.data = ImageProc.block_bitor(labelA.data, labelA.m, labelA.n, scaleB, scaleB);
 
  vcm.set_image_labelA(labelA.data);
  vcm.set_image_labelB(labelB.data);
end


Entry();
print ('Press "h" for instructions')
while (true) do
  update();
  broadcast();
  unix.usleep (100000);
end

