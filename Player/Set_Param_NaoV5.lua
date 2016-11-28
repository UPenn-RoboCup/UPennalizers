cwd = os.getenv('PWD')
require ('init')
require ('HeadTransform');
require ('unix');
require ('getch');
require ('Broadcast');
require ('Config');
local Camera = require ('uvc');
require ('vcm');
require ('vector');
require ('carray');
ImageProc = require ('ImageProc');
require ('io');
require ('ColorLUT')

camera_idx = 1;

function Entry() 
  ImageProc.setup(640,480,2,2)
  camera = {}
  labelA = {};
  labelB = {};
  lut = {};
  lut_size = {};
  lut_ud = {};

  for cidx = 1, Config.camera.ncamera do
    camera[cidx] = Camera.init(Config.camera.device[cidx],
                         Config.camera.width[cidx],
                         Config.camera.height[cidx],
                         Config.camera.img_type)
    vcm['set_image'..cidx..'_width'](Config.camera.width[cidx]);
    vcm['set_image'..cidx..'_height'](Config.camera.height[cidx]);

    labelA[cidx] = {}
    labelA[cidx].m = camera[cidx]:get_width()/Config.vision.scaleA[cidx];
    labelA[cidx].n = camera[cidx]:get_height()/Config.vision.scaleA[cidx];
    labelA[cidx].npixel = labelA[cidx].m*labelA[cidx].n;

    labelB[cidx] = {}

    labelB[cidx] = {}
    labelB[cidx].m = camera[cidx]:get_width()/Config.vision.scaleA[cidx]/Config.vision.scaleB[cidx];
    labelB[cidx].n = camera[cidx]:get_height()/Config.vision.scaleA[cidx]/Config.vision.scaleB[cidx];
    labelB[cidx].npixel = labelB[cidx].m*labelB[cidx].n;
    vcm['set_image'..cidx..'_scaleB'](Config.vision.scaleB[cidx]);
 
    camera_setting(camera[cidx], cidx);
    lut_ud[cidx] = ColorLUT.load_LUT(Config.camera.lut_file[cidx], cidx);
    lut[cidx], lut_size[cidx] = lut_ud[cidx]:pointer()
  end


  imcount = 0;
end

function Cam_init()
  for cidx = 1, Config.camera.ncamera do
    camera_setting(camera[cidx], cidx)
  end
end

function camera_setting(camera, c)
  for i,param in ipairs(Config.camera.param) do
    print('Camera '..c..': setting '..param.key..': '..param.val[c]);
    camera:set_param(param.key, param.val[c], c-1);
    unix.usleep (100);
    print('Camera '..c..': set to '..param.key..': '..
    camera:get_param(param.key, c-1));
  end
  camera:set_param('Brightness', Config.camera.brightness, c-1);     
  camera:set_param('White Balance, Automatic', 1, c-1); 
  camera:set_param('Auto Exposure',0, c-1);
  camera:set_param('White Balance, Automatic', 0, c-1);
  camera:set_param('Auto Exposure',0, c-1);
  local expo = camera:get_param('Exposure', c-1);
  local gain = camera:get_param('Gain', c-1);
  camera:set_param('Auto Exposure',1, c-1);   
  camera:set_param('Auto Exposure',0, c-1);
  camera:set_param('Exposure', expo, c-1);
  camera:set_param('Gain', gain, c-1);
  camera:set_param('Do White Balance',Config.camera.param[10].val[c],c-1);
  camera:set_param('White Balance Temperature', Config.camera.param[12].val[c], c-1);
  print('Camera #'..c..' set');
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
  end  local result = 0;
  for i = 1, #num do
    result = result + (num [i]- 48)*(10 ^ (#num - i));
  end
  return result;
end


function Switch_to_Top_Camera()
  camera_idx = 1;
  print ('Switched to Top Camera (Camera 0)')
end

function Switch_to_Bottom_Camera()
  camera_idx = 2;
  print ('Switched to Bottom Camera (Camera 1)')
end

function Set_Brightness()
  print ('Current brightness is: '..camera[camera_idx]:get_param('Brightness')..' type in an integer which is multiple of 4 between 0 and 255');
  local param = Read_Num();
  --local expo = camera[camera_idx]:get_param('Exposure');
  --local gain = camera[camera_idx]:get_param('Gain');
  while (param == -1 or param > 255 or (param % 4) ~= 0) do
    unix.usleep (10000);
    param = Read_Num(); 
  end
  --camera[camera_idx]:set_param ('Auto Exposure', 1);
  --camera[camera_idx]:set_param ('White Balance, Automatic', 1);
  camera[camera_idx]:set_param ('Brightness', param);
  --camera[camera_idx]:set_param ('Auto Exposure', 0);
  --camera[camera_idx]:set_param ('White Balance, Automatic', 0);
  --camera[camera_idx]:set_param ('Exposure', expo);
  --camera[camera_idx]:set_param ('Gain', gain);
  print('Brightness: ' , camera[camera_idx]:get_param('Brightness'))
end

function Set_Contrast()
  print ('Current contrast is: '..camera[camera_idx]:get_param('Contrast')..' type in an integer between 16 and 64');
  local param = Read_Num();
  while (param < 16 or param > 64) do
    unix.usleep (10000);
    print ('Type in an integer between 16 and 64');
    param = Read_Num(); 
  end
  camera[camera_idx]:set_param ('Contrast', param);
  print('Contrast: ', camera[camera_idx]:get_param('Contrast'))
end

function Set_White_Balance()
  print ('Current white balance is: '..camera[camera_idx]:get_param('Do White Balance')..' type in an integer between 0 and 1');
  local param = Read_Num();
  while (param < 0 or param > 1) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 1');
    param = Read_Num(); 
  end
  camera[camera_idx]:set_param ('Do White Balance', param);
  print('Do White Balance: ', camera[camera_idx]:get_param('Do White Balance'))
end

function Set_White_Balance_Temperature()
  print ('Current white balance temperature is: '..camera[camera_idx]:get_param('White Balance Temperature')..' type in an integer between 2700 and 6500');
  local param = Read_Num();
  while (param < 2700 or param > 6500) do
    unix.usleep (10000);
    print ('Type in an integer between 2700 and 6500');
    param = Read_Num(); 
  end
  camera[camera_idx]:set_param ('White Balance Temperature', param);
  print('White Balance Temperature: ', camera[camera_idx]:get_param('White Balance Temperature'))
end

function Set_Saturation()
  print ('Current saturation is: '..camera[camera_idx]:get_param('Saturation')..' type in an integer between 0 and 255');
  local param = Read_Num();
  while (param < 0 or param > 255) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 255');
    param = Read_Num(); 
  end 
  camera[camera_idx]:set_param ('Saturation', param);
  print('Saturation: ', camera[camera_idx]:get_param('Saturation'))
end

function Set_Exposure()
  print ('Current exposure is: '..camera[camera_idx]:get_param('Exposure')..' type in an integer between 0 and 1000');
  local param = Read_Num();
  while (param < 0 or param > 1000) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 1000');
    param = Read_Num(); 
  end    
  --local backup = camera[camera_idx]:get_param ('Gain');
  --camera[camera_idx]:set_param ('White Balance, Automatic', 0);
  --camera[camera_idx]:set_param ('Auto Exposure', 1)
  camera[camera_idx]:set_param ('Exposure', param);
  --camera[camera_idx]:set_param ('Gain', backup);
  --camera[camera_idx]:set_param ('White Balance, Automatic', 0);
  --camera[camera_idx]:set_param ('Auto Exposure', 0);
  print('Exposure: ' , camera[camera_idx]:get_param('Exposure'))
end

function Set_Gain()
  print ('Current gain is: '..camera[camera_idx]:get_param('Gain')..' type in an integer between 0 and 255');
  local param = Read_Num();
  while (param < 0 or param > 255) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 255');
    param = Read_Num(); 
  end
  --local backup = camera[camera_idx]:get_param ('Exposure');
  --camera[camera_idx]:set_param ('White Balance, Automatic', 1);
  --camera[camera_idx]:set_param ('Auto Exposure', 0);
  camera[camera_idx]:set_param ('Gain', param);
  --camera[camera_idx]:set_param ('Exposure', backup);
  --camera[camera_idx]:set_param ('White Balance, Automatic', 0);
  --camera[camera_idx]:set_param ('Auto Exposure', 1);
  print('Gain: ' , camera[camera_idx]:get_param('Gain'))
end

function Set_Sharpness()
  print ('Current sharpness is: '..camera[camera_idx]:get_param('Sharpness')..' type in an integer between 0 and 5');
  local param = Read_Num();
  while (param < 0 or param > 5) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 5');
    param = Read_Num(); 
  end 
  camera[camera_idx]:set_param ('Sharpness', param);
  print('Sharpness: ' , camera[camera_idx]:get_param('Sharpness'))
end

function Set_Gamma() 
        print ('Current gamma is: ' ..camera[camera_idx]:get_param('Gamma')..' type in an integer bewteen 0 and 1000');
  local param = Read_Num();
  while (param < 0 or param > 1000) do
    unix.usleep (10000);
    print ('Type in an integer between 0 and 1000');
    param = Read_Num();
  end
  camera[camera_idx]:set_param ('Gamma', param);
  print('Gamma: ' , camera[camera_idx]:get_param('Gamma'))
end

function Set_PowerLineFrequency()
        print ('Current Power Line Frequency is: ' ..camera[camera_idx]:get_param('Power Line Frequency')..' type in an integer between 1 and 2');
  local param = Read_Num();
  while (param < 1 or param > 2) do
    unix.usleep (10000);
    print ('Type in an integer between 1 and 2');
    param = Read_Num();
  end
  camera[camera_idx]:set_param ('Power Line Frequency', param);
  print('Power Line Frequency: ' , camera[camera_idx]:get_param('Power Line Frequency'));
end

function Set_FileName()
        curr = FindParamFile();
        print('The current camera param file is '..curr..'. Enter a filename, but do not include Config_NaoV4_Camera_ or .lua');
        str = io.read(); 
        while (str == nil) do
                unix.usleep(10000);
                str = io.read();
        end
        if (curr == str) then
                print('File already exists, do you want to overwrite? y/n');
                opt = io.read();
                while (opt == nil and opt ~= 'y' and opt ~= 'n') do
                        unix.usleep (10000);
                        opt = io.read();
                end
                if(opt == 'y') then
                        NewParam(curr, str);
                        print('File write complete. Please restart to save another file');
                        return
                end
                return Set_FileName()
        end
        SetCamPointerName(curr, str);
        NewParam(curr, str);
        print('File write complete. Please restart to save another file');
end
-- Returns the name of the current camera params file in Config_NaoV4.lua
function FindParamFile()
    --local file = 'Config/Config_NaoV4.lua';
    --local value;
    --for line in io.lines(file) do
    --    if string.sub(line, 1, 13) == 'params.Camera' then
    --            value = string.match(line, '\".*\"');
    --            value = string.sub(value, 2, string.len(value) - 1); 
    --    end
    --end
    value = Config.params.Camera;
    if(value == nil) then
        print ('Could not find '..file);
    end
    return value
end

function SetCamPointerName(curr, str)
        file = io.open('Config/Config_NaoV4.lua', 'r');
        local contents = file:read('*all');
        contents = string.gsub(contents, "params.Camera(%s*)=(%s*)\""..curr, "params.Camera = \""..str);
        file:close();
        file = io.open('Config/Config_NaoV4.lua', 'w');
        file:write(contents);
        file:close();
end

function NewParam(curr, str)
        file = io.open('Config/Camera/Config_NaoV4_Camera_'..curr..'.lua', 'r');
        local contents = file:read('*all');
        contents = string.gsub(contents,"key='Contrast'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Contrast'       , val={"..camera[1]:get_param('Contrast').." , "..camera[2]:get_param('Contrast').."}}");

        contents = string.gsub(contents,"key='Saturation'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Saturation'       , val={"..camera[1]:get_param('Saturation').." , "..camera[2]:get_param('Saturation').."}}");

        contents = string.gsub(contents,"key='Exposure'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Exposure'       , val={"..camera[1]:get_param('Exposure').." , "..camera[2]:get_param('Exposure').."}}");

        contents = string.gsub(contents,"key='Gain'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Gain'       , val={"..camera[1]:get_param('Gain').." , "..camera[2]:get_param('Gain').."}}");

        contents = string.gsub(contents,"key='Do White Balance'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Do White Balance'       , val={"..camera[1]:get_param('Do White Balance').." , "..camera[2]:get_param('Do White Balance').."}}");

        contents = string.gsub(contents,"key='Gamma'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Gamma'       , val={"..camera[1]:get_param('Gamma').." , "..camera[2]:get_param('Gamma').."}}");

        contents = string.gsub(contents,"key='White Balance Temperature'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='White Balance Temperature'       , val={"..camera[1]:get_param('White Balance Temperature').." , "..camera[2]:get_param('White Balance Temperature').."}}");

        contents = string.gsub(contents,"key='Power Line Frequency'(%s*),(%s*)val={(%d*)(%s*),(%s*)(%d*)}}", "key='Power Line Frequency'       , val={"..camera[1]:get_param('Power Line Frequency').." , "..camera[2]:get_param('Power Line Frequency').."}}");

        file:close();
        file = io.open('Config/Camera/Config_NaoV4_Camera_'..str..'.lua', 'w');
        file:write(contents);
        file:close();
end


function Print_All()
  for c=1,Config.camera.ncamera do
    print ('Camera No. '..c-1)
    print ('Brightness: '..camera[c]:get_param('Brightness') ) 
    for i,param in ipairs(Config.camera.param) do
      print (param.key..': '..camera[c]:get_param(param.key))
    end
    print ('Auto Exposure: '..camera[c]:get_param('Auto Exposure'))
    print ('White Balance, Automatic: '..camera[c]:get_param('White Balance, Automatic'))
    print ('');
  end
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
  print ('Press "y" to set Gamma;')
  print ('Press "wb" to set White Balance;')
  print ('Press "w" to set White Balance Temperature;') 
  print ('Press "l" to set Power Line Frequency;')
  print ('press "i" to go back to initial parameters from the Config file;')
  print ('Press "p" to see all the current parameters;')
  print ('Press "h" to see the instruction.')
  print ('Press "f" to write your changes to the Camera Param file')
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
                 Set_Gamma,        
		 Print_All,
                 Help,
                 Set_White_Balance,
                 Set_White_Balance_Temperature,
                 Set_PowerLineFrequency,
                 Set_FileName
                }

utilCommands =  {'i','+','-','b','c','s','e','g','a','y','p','h','t','w','l','f'}

function broadcast()
  vcm.set_camera_broadcast(1);
  imcount = imcount + 1;
  Broadcast.update(1);
  Broadcast.update_img(1, imcount);    
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
  for cidx = 1, Config.camera.ncamera do
    image, img_buf_sz, img_count, img_time = camera[cidx]:get_image();
    vcm['set_image'..cidx..'_yuyv'](image);
    vcm['set_image'..cidx..'_time'](img_time);
    vcm['set_image'..cidx..'_count'](img_count);

    labelA[cidx].data  = ImageProc.old_yuyv_to_label(image, lut[cidx],
           camera[cidx]:get_width(), camera[cidx]:get_height(), Config.vision.scaleA[cidx]);
    labelB[cidx].data = ImageProc.old_block_bitor(labelA[cidx].data, labelA[cidx].m, 
                         labelA[cidx].n, Config.vision.scaleB[cidx], Config.vision.scaleB[cidx]);

    vcm['set_image'..cidx..'_labelA'](labelA[cidx].data);
    vcm['set_image'..cidx..'_labelB'](labelB[cidx].data);
    
  end
end


Entry();
print ('Press "h" for instructions')
while (true) do
  update();
  broadcast();
  unix.usleep (100000);
end

