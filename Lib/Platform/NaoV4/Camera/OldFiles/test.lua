package.cpath = './../../../Modules/Comm/?.so;'..package.cpath
package.cpath = './../../../Modules/Utils/Z/?.so;'..package.cpath
package.path = './../../../../Player/Util/?.lua;'..package.path
package.cpath = './../../../../Player/Lib/?.so;'..package.cpath

local camera = require 'NaoCam'
local CommWired = require 'Comm'
local unix = require 'unix'
local Z = require 'Z'
local serialization = require 'serialization'
local util = require 'util'

CommWired.init('192.168.123.255', 111111)

local pktDelay = 1E6 *  0.001; --For image and colortable
local debug = 0
function sendImg(image, icount)
	-- yuyv --
	yuyv = image;
	width = 640/2; -- number of yuyv packages
	height = 480;
	count = icount;

	array = serialization.serialize_array2(yuyv, width, height, 
	'int32', 'yuyv', count);
	-- array = serialization.serialize_array(yuyv, width, height, 
	-- 'int32', 'yuyv', count);

	sendyuyv = { } ;
	sendyuyv.team = { } ;
	sendyuyv.team.number = 1;
	sendyuyv.team.player_id = 1;

	local tSerialize=0;
	local tSend=0; 
	local totalSize=0;
	for i=1,#array do

		sendyuyv.arr = array[i];
		t0 = unix.time();
		senddata=serialization.serialize(sendyuyv); 
		senddata = Z.compress(senddata, #senddata);
		t1 = unix.time();
		tSerialize= tSerialize +  t1-t0;
		CommWired.send(senddata, #senddata);
		t2 = unix.time();
		tSend=tSend+ t2-t1;
		totalSize=totalSize+ #senddata;

		-- Need to sleep in order to stop drinking out of firehose
		unix.usleep(pktDelay);
	end
	if debug>0 then

		print("Image info array num: ",#array,"Total size",totalSize);
		print("Total Serialize time: ",#array,"Total",tSerialize);
		print("Total Send time: ",tSend);
	end
end

maxFPS = 40;
tperiod = 1.0/maxFPS;

camera.select_camera(1)
local count = 0
while (1) do

	count = count +  1
	image1 = camera.get_image(0)
	print('image1 ', image1)
	sendImg(image1, count) 
	image2 = camera.get_image(1)
	print('image2 ', image2)
	sendImg(image2, count)
	-- unix.usleep(1e6 *  0.1)
	-- tloop = unix.time() - tstart;

	-- if (tloop < tperiod) then
	-- unix.usleep((tperiod - tloop)* (1E6));
	-- end
	local status = camera.get_camera_status()
	util.ptable(status)
end
