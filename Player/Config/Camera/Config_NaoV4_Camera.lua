module(..., package.seeall);
require('vector')

-- Camera Parameters

camera = {};
camera.ncamera = 2;
--camera.switchFreq = 5;
camera.switchFreq = 2;
camera.device = {'/dev/video0', '/dev/video1'}
camera.img_type = 'yuyv'
--[[
camera.width = 640;
camera.height = 480;
--]]

camera.width = {640, 320};
camera.height = {480, 240};

camera.x_center = 320;
camera.y_center = 240;

--Old nao values
--camera.focal_length = 383; -- in pixels
--camera.focal_base = 320; -- image width used in focal length calculation

--NaoV4 values
--60.97 degree horizontal FOV for 640 pixels
--FOV = 2 arcctan(x/2f), x=640
--f=640/2/tan(60.97*pi/180 / 2)
camera.focal_length = 545.6; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation

--New nao params
camera.auto_param = {};
camera.auto_param[1] = {key='White Balance, Automatic', val={0, 0}};
camera.auto_param[2] = {key='Backlight Compensation',     val={0, 0}};
--Top camera is flipped
camera.auto_param[3] = {key='Horizontal Flip',   val={1, 0}};
camera.auto_param[4] = {key='Vertical Flip',   val={1, 0}};


camera.param = {};
camera.param[1] = {key='Brightness',    val={89, 89}};
camera.param[2] = {key='Contrast',      val={64, 64}};
camera.param[3] = {key='Saturation',    val={215, 215}};
camera.param[4] = {key='Hue',           val={0, 0}};
camera.param[5] = {key='Exposure',      val={150, 150}};
camera.param[6] = {key='Gain',          val={113, 113}};
camera.param[7] = {key='Sharpness',  val={160, 160}};
camera.param[8] = {key='Do White Balance',      val={-1, -1}};


camera.lut_file = 'lut_NaoV4_Grasp.raw';

