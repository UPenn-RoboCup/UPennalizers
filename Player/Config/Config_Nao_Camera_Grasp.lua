module(..., package.seeall);
require('vector')

-- Camera Parameters

camera = {};
camera.ncamera = 2;
camera.switchFreq = 5;
camera.width = 320;
camera.height = 240;
camera.x_center = 160;
camera.y_center = 120;

camera.focal_length = 383; -- in pixels
camera.focal_base = 320; -- image width used in focal length calculation

camera.auto_param = {};
camera.auto_param[1] = {key='auto_exposure',      val={0, 0}};
camera.auto_param[2] = {key='auto_white_balance', val={0, 0}};
camera.auto_param[3] = {key='autogain',           val={0, 0}};

camera.param = {};
camera.param[1] = {key='exposure',      val={150, 150}};
camera.param[2] = {key='gain',          val={113, 113}};
camera.param[3] = {key='brightness',    val={89, 89}};
camera.param[4] = {key='contrast',      val={64, 64}};
camera.param[5] = {key='saturation',    val={215, 215}};
camera.param[6] = {key='red_balance',   val={67, 67}};
camera.param[7] = {key='blue_balance',  val={160, 160}};
camera.param[8] = {key='hue',           val={0, 0}};

camera.lut_file = 'lut_grasp_green_lines.raw';

