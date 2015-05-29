module(..., package.seeall);

require('Config')
require('carray')
require('ImageProc')
require('vcm')

LUT = {};

enable_lut_for_obstacle = Config.vision.enable_lut_for_obstacle or 0;

function load_LUT(lut_filename, cidx)

  print('loading lut: '..Config.camera.lut_file[cidx]);
  return load_lutfile(lut_filename);

end

function load_lutfile(fname)
  if not string.find(fname,'.raw') then
    fname = fname..'.raw';
  end
  local cwd = unix.getcwd();
  if string.find(cwd, "WebotsController") then
    cwd = cwd.."/Player";
  end
  cwd = cwd.."/Data/";
  local f = io.open(cwd..fname, "r");
  assert(f, "Could not open lut file");
  local s = f:read("*a");
  local lut = carray.byte(s, #s) 
  return lut
end

function save_lutfile(fname, lut)
  if not string.find(fname, '.raw') then
    fname = fname..'.raw';
  end
  local cwd = unix.getcwd();
  if string.find(cwd, "WebotsController") then
    cwd = cwd.."/Player";
  end
  cwd = cwd.."/Data/";
  local f = io.open(cwd..fname, "w+");
  assert(f, "Could not open lut file");
  for i = 1, #lut do
    f:write(string.char(lut[i]));
  end
  f:close();
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

function learn_lut_from_mask()

    -- Enable Webots specific
    if (string.find(Config.platform.name,'Webots')) then
      require('Camera')
      webots = 1;
    end
  load_LUT();
--  util.ptable(LUT)
  -- Learn ball color from mask and rebuild colortable
  if enable_lut_for_obstacle == 1 then
    -- get yuyv image from shm
    yuyv = vcm.get_image_yuyv();
    image_width = vcm.get_image_width();
    image_height = vcm.get_image_height();
    -- get labelA
    if webots == 1 then
      labelA_mask = Camera.get_labelA_obs( carray.pointer(LUT.Obstacle) );
      labelA_m = Config.camera.width;
      labelA_n = Config.camera.height;
    else
      labelA_mask  = ImageProc.yuyv_to_label_obs(vcm.get_image_yuyv(),
                                    carray.pointer(LUT.Obstacle), image_width/2, image_height);
      labelA_m = Config.camera.width/2;
      labelA_n = Config.camera.height/2;
    end
    print("learn new colortable for random ball from mask");
    mask = ImageProc.label_to_mask(labelA_mask, labelA_m, labelA_n);

    if webots == 1 then
      print("learn in webots")
      lut_update = Camera.get_lut_update( mask, carray.pointer(LUT.Detection) );
    else
      print("learn in op")
      lut_update = ImageProc.yuyv_mask_to_lut(vcm.get_image_yuyv(), mask, 
                                              carray.pointer(LUT.Detection), labelA_m, labelA_n);
    end
    LUT.Detection = carray.cast(lut_update, 'c', 262144);
    save_lutfile(Config.camera.lut_file_new, LUT.Detection);
  else
    print('Enable lut for obstacle in Vision to enable lut from mask');
  end
  -- vcm.set_camera_reload_LUT(1)
  vcm.set_camera_learned_new_lut(1)
end
