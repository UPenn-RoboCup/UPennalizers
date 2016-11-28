cwd = os.getenv('PWD')
require('init')

require('Config')
require('carray')
require('ImageProc')
require('vcm')
require('util')

-- Enable Webots specific
--[[
if (string.find(Config.platform.name,'Webots')) then
  webots = 1;
  require('Camera')
end
--]]

enable_lut_for_obstacle = Config.vision.enable_lut_for_obstacle or 0;

function load_LUT()
  ColorLUT = {};

  print('loading lut: '..Config.camera.lut_file);
  ColorLUT.Detection = carray.new('c', 262144);
  load_lutfile(Config.camera.lut_file, ColorLUT.Detection);

  --ADDED to prevent crashing with old camera config
  if Config.camera.lut_file_obs == null then
    Config.camera.lut_file_obs = Config.camera.lut_file;
  end

  -- Load the obstacle LUT as well
  if enable_lut_for_obstacle == 1 then
    print('loading obs lut: '..Config.camera.lut_file_obs);
    ColorLUT.Obstacle = carray.new('c', 262144);
    load_lutfile(Config.camera.lut_file_obs, ColorLUT.Obstacle);
  end

  return ColorLUT;
end

function load_lutfile(fname, lut)
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
  for i = 1,string.len(s) do
    lut[i] = string.byte(s,i,i);
  end
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

LUT = load_LUT();
util.ptable(LUT)

-- Generate empty lut
--for i = 1, 262144 do
--  LUT.Obstacle[i] = 0;
--end

--save_lutfile('lut_empty', LUT.Obstacle)

--[[
for i = 1, 262144 do
  if LUT.Obstacle[i] ~= 0 then
    print(i, LUT.Obstacle[i]);
    LUT.Obstacle[i] = LUT.Obstacle[i] * 2;
  end
end

save_lutfile(Config.camera.lut_file_obs, LUT.Obstacle);
LUT = load_LUT();
util.ptable(LUT)
--]]
for i = 1, 262144 do
--  if LUT.Obstacle[i] ~= 0 then
--    print(LUT.Obstacle[i]);
--  end
  if LUT.Detection[i] == 0 then
    LUT.Detection[i] = 8;
  elseif LUT.Detection[i] == 8 then
    LUT.Detection[i] = 0;
  end
end

save_lutfile('lut_0811_L512_5PM', LUT.Detection);
