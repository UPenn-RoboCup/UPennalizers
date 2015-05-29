module(..., package.seeall);
require('vector')

-- Camera Parameters

camera = {};
camera.ncamera = 2;
camera.device = {'/dev/video0', '/dev/video1'}
camera.switchFreq = 5;
camera.x_center = 320;
camera.y_center = 240;
camera.width =  {640, 320};
camera.height = {480, 240};


camera.focal_length = 545.6; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation

--New nao params

camera.param = {};
-- Contrast should be set between 17 and 64
camera.param[1] = {key='Contrast'       , val={40 , 20}};

camera.param[2] = {key='Saturation'       , val={200 , 200}};
-- Hue will automatically change to 0 if set to a number between -5 and 5, but cannot be set by other numbers
camera.param[3] = {key='Hue'            , val={0 , 0}};

camera.param[4] = {key='Exposure'       , val={60 , 40}};
-- Gain should be set between 32 and 255
camera.param[5] = {key='Gain'       , val={32 , 40}};
-- Sharpness should be set between 0 and 7
camera.param[6] = {key='Sharpness'      , val={3  , 3}};

camera.param[7] = {key='Horizontal Flip', val={1  , 0}};

camera.param[8] = {key='Vertical Flip'  , val={1  , 0}};

camera.param[9] = {key='Fade to Black'  , val={0  , 0}}; 
camera.param[10]  = {key='Do White Balance'       , val={3400 , 3000}}

-- brightness has to be set seperately from other parameters, and it can only be set to multiple of 4
camera.brightness = 200;

camera.lut_file = {'ChouApr11Top2.raw','ChouApr11Bot.raw'};

