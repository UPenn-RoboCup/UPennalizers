module(..., package.seeall);
require('vector')
--require('vcm')

-- Camera Parameters

camera = {};
camera.ncamera = 1;
camera.switchFreq = 0; --unused for OP
camera.width = 640;
camera.height = 480;
camera.x_center = 328;
camera.y_center = 248;

camera.focal_length = 533; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation

--[[
queryctrl: "White Balance Temperature" 0x98091a
queryctrl: "Sharpness" 0x98091b
queryctrl: "Backlight Compensation" 0x98091c
queryctrl: "Exposure, Auto" 0x9a0901
querymenu: Auto Mode
querymenu: Manual Mode
querymenu: Shutter Priority Mode
querymenu: Aperture Priority Mode
queryctrl: "Exposure (Absolute)" 0x9a0902
queryctrl: "Exposure, Auto Priority" 0x9a0903
queryctrl: "Pan (Absolute)" 0x9a0908
queryctrl: "Tilt (Absolute)" 0x9a0909
queryctrl: "Brightness" 0x980900
queryctrl: "Contrast" 0x980901
queryctrl: "Saturation" 0x980902
queryctrl: "White Balance Temperature, Auto" 0x98090c
queryctrl: "Gain" 0x980913
queryctrl: "Power Line Frequency" 0x980918
--]]

camera.auto_param = {};
camera.auto_param[1] = {key='white balance temperature, auto', val={0}};
camera.auto_param[2] = {key='power line frequency',   val={0}};
camera.auto_param[3] = {key='backlight compensation', val={0}};
camera.auto_param[4] = {key='exposure, auto',val={1}}; --1 for manual
camera.auto_param[5] = {key="exposure, auto priority",val={0}};
--camera.auto_param[6] = {key='autogain',               val={0}};


camera.param = {};
camera.param[1] = {key='brightness',    val={216}};
camera.param[2] = {key='contrast',      val={2}};
camera.param[3] = {key='saturation',    val={48}};
camera.param[4] = {key='gain',          val={255}};
camera.param[5] = {key='white balance temperature', val={1000}};
camera.param[6] = {key='sharpness',     val={0}};
camera.param[7] = {key='exposure (absolute)',      val={1005}};

camera.lut_file = 'lut_low_contrast_pink_n_green.raw';
