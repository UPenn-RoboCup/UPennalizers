cwd = cwd or os.getenv('PWD')
-- this module is used to facilitate interactive debuging

package.cpath = cwd.."/../../../../Player/Lib/?.so;"..package.cpath;

package.path = cwd.."/../../../../Player/Util/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Config/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Lib/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Dev/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Motion/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Motion/keyframes/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Motion/Walk/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Motion/Arms/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Vision/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/World/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/Test/?.lua;"..package.path;
package.path = cwd.."/../../../../Player/?.lua;"..package.path;

require('serialization')
require('string')
require('vector')
require('getch')
require('util')
require('unix')
require('cutil')
require('shm')

local camera = require'uvc'
local vcm = require 'vcm'
require 'Broadcast'
require 'Config'
--local carray = require'carray'
video_ud1 = camera.init('/dev/video0', 640, 480, 'yuyv')
video_ud2 = camera.init('/dev/video1', 640, 480, 'yuyv')

vcm.set_image1_width(640)
vcm.set_image1_height(480)
vcm.set_image2_width(640)
vcm.set_image2_height(480)

function camera_setting(camera, c)
	camera: set_param('Brightness', Config.camera.brightness, c-1); 
	camera: set_param('White Balance, Automatic', 1, c-1); 
	camera: set_param('Auto Exposure',0, c-1);
	for i,param in ipairs(Config.camera.param) do

		print('Camera '..c..':  setting '..param.key..':  '..param.val[c]);
		camera: set_param(param.key, param.val[c], c-1);
		unix.usleep (100);
		print('Camera '..c..':  set to '..param.key..':  '..
		camera: get_param(param.key, c-1));
	end
	camera: set_param('White Balance, Automatic', 0, c-1);
	camera: set_param('Auto Exposure',0, c-1);
	local expo = camera: get_param('Exposure', c-1);
	local gain = camera: get_param('Gain', c-1);
	camera: set_param('Auto Exposure',1, c-1); 
	camera: set_param('Auto Exposure',0, c-1);
	camera: set_param ('Exposure', expo, c-1);
	camera: set_param ('Gain', gain, c-1);
	print('Camera #'..c..' set');
	--camera_setting(video_ud1, 1);
	--camera_setting(video_ud2, 2);
	print("* * * * * * * * * * * * * * * * * * * * * * ")
	camera: set_param('Exposureuiadsf', 85, c-1);
	print(camera: get_param('Exposure', c-1));
end

camera_setting(video_ud1, 1);
camera_setting(video_ud2, 2);

while (true) do

	local img1, size1, count1, time1 = video_ud1: get_image();
	local img2, size2, count2, time2 = video_ud2: get_image();
	if (img1 ~= -1) then

		-- print('img1', img1, size1, time1, count1)
	end
	if (img2 ~= -1) then

		-- print('img2', img2, size2, time2, count2)
	end
	vcm.set_image1_yuyv(img1);
	vcm.set_image2_yuyv(img2);
	vcm.set_image1_count(count1);
	vcm.set_image2_count(count2);

	Broadcast.update_img(2, 1);
	unix.usleep(0.5 *  1e6);
end

--video_ud2 = uvc.init('/dev/video1', 320, 240, 'yuyv')
--video_ud3 = uvc.init('/dev/video2', 640, 480, 'yuyv')
--video_ud4 = uvc.init('/dev/video3', 640, 480, 'mjpeg')
--video_ud5 = uvc.init('/dev/video4', 640, 480, 'mjpeg')

--[[
local file1 = io.open('image1.jpg', 'w')
local counter = 0
while (true) do

local img1, size1 = video_ud1: get_raw();
-- local img2, size2 = video_ud2: get_raw();
-- local img3 = video_ud3: get_raw();
-- local img4 = video_ud4: get_raw();
-- local img5 = video_ud5: get_raw();

if (img1 ~= -1) then
counter = counter +  1
if (counter == 10) then
video_ud1: close()
video_ud1 = uvc.init('/dev/video0', 640, 480, 'mjpeg')
end
print('img1', img1, size1)
-- local ud = carray.byte(img1, size1)
-- file1: write(tostring(ud))
-- file1: close()
-- error()
end
-- if (img2 ~= -1) then
-- print('img2', img2, size2)
-- end
-- if (img3 ~= -1) then
-- print('img3', img3)
-- end
-- if (img4 ~= -1) then
-- print('img4', img4)
-- end
-- if (img5 ~= -1) then
-- print('img5', img5)
-- end 
end
--]]
