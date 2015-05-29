--Steve
--Ashleigh
--This code is used to broadcast each robot's information over network
--Sent string is in lua format (for monitoring)

module(..., package.seeall);

-- Only send items from shared memory
require('vcm')
require('gcm')
require('wcm')
require('mcm')
require('matcm')
require('serialization');
require('ImageProc')
require('Config');

--CommWired=require('Comm');
CommWired=require('OldComm');


--sendShm = {'wcm','vcm','gcm'}
sendShm = { wcmshm=wcm, gcmshm=gcm, vcmshm=vcm, mcmshm=mcm }
itemReject = 'yuyv, yuyv2, labelA, labelB, map'

-- Initiate Sending Address
enable_online_learning = Config.vision.enable_online_colortable_learning or 0;
print('Enable online Learning: '..enable_online_learning);
if enable_online_learning == 1 then
  loginIP  = io.popen('last -w -d -i -1 | grep "darwin " | cut -d" " -f12-13')
  IP = string.gsub(tostring(loginIP:read()), ' ','')
  PORT = Config.dev.ip_wired_port;
else
  IP = Config.dev.ip_wired;
  PORT = Config.dev.ip_wired_port;
end

--CommWired.init(IP,PORT);
CommWired.init(Config.dev.ip_wired, Config.dev.ip_wired_port);
print('Broadcast to',Config.dev.ip_wired..':'..Config.dev.ip_wired_port);
--print('Broadcast to',IP..':'..PORT);

-- Add a little delay between packet sending
-- pktDelay = 500; -- time in us
-- Empirical value for keeping all packets intact
pktDelay = 1E6 * 0.001; --For image and colortable
pktDelay2 = 1E6 * 0.001; --For info
imageCount=0;

debug = 0;

subsampling=Config.vision.subsampling or 0;
subsampling2=Config.vision.subsampling2 or 0;

--NEW MORE COMPACT ENCODING (1/4 previous size)
--We don't need to divide packet any more 
function sendB()
  -- labelB --
  for nc=1, Config.camera.ncamera do
    local labelB = vcm['get_image'..nc..'_labelB']()
    local width = vcm['get_image'..nc..'_width']() /
                    Config.vision.scaleA[nc] / Config.vision.scaleB[nc] -- number of yuyv packages
    local height = vcm['get_image'..nc..'_height']() /
                    Config.vision.scaleA[nc] / Config.vision.scaleB[nc] -- number of yuyv packages
    local count = vcm['get_image'..nc..'_count']();
  --  array = serialization.serialize_label_double(
  --	labelB, width, height, 'uint8', 'labelB',count);
    array = serialization.serialize_label_rle(
	  labelB, width, height, 'uint8', 'labelB'..tostring(nc), count);

    local sendlabelB = {};
    sendlabelB.team = {};
    sendlabelB.team.number = gcm.get_team_number();
    sendlabelB.team.player_id = gcm.get_team_player_id();

    stime1,stime2,infosize=0,0,0;
    sendlabelB.arr = array;
    t0 = unix.time();
    local senddata=serialization.serialize(sendlabelB);
    senddata = Z.compress(senddata, #senddata);
    infosize=infosize+#senddata;
    t1=unix.time();
    stime1=stime1+t1-t0;
    CommWired.send(senddata, #senddata);
    t2=unix.time();
    stime2=stime2+t2-t1;

    if debug>0 then
      print("LabelB info size:",infosize);
      print("Total serialization time:",stime1);
      print("Total comm time:",stime2);
    end
  end
end

--NEW MORE COMPACT ENCODING (1/4 previous size)
--We don't need to divide packet any more 
function sendA()
-- labelA --
  for nc = 1, Config.camera.ncamera do
    local labelA = vcm['get_image'..nc..'_labelA']()
    local width = vcm['get_image'..nc..'_width']() / Config.vision.scaleA[nc]
    local height = vcm['get_image'..nc..'_height']() / Config.vision.scaleA[nc]
    local count = vcm['get_image'..nc..'_count']();
--  array = serialization.serialize_label_double(
--	labelA, width, height, 'uint8', 'labelA',count);
    array = serialization.serialize_label_rle(
	  labelA, width, height, 'uint8', 'labelA'..tostring(nc),count);
  
    local sendlabelA = {};
    sendlabelA.team = {};
    sendlabelA.team.number = gcm.get_team_number();
    sendlabelA.team.player_id = gcm.get_team_player_id();

    stime1,stime2,infosize=0,0,0;
    sendlabelA.arr = array;
    t0 = unix.time();
    local senddata=serialization.serialize(sendlabelA);
    senddata = Z.compress(senddata, #senddata);
    infosize=infosize+#senddata;
    t1=unix.time();
    stime1=stime1+t1-t0;
    CommWired.send(senddata, #senddata);
    t2=unix.time();
    stime2=stime2+t2-t1;

    if debug>0 then
      print("LabelA info size:",infosize);
      print("Total serialization time:",stime1);
      print("Total comm time:",stime2);
    end
  end
end

function sendImg()
  -- yuyv --
  for nc = 1, Config.camera.ncamera do
    local yuyv = vcm['get_image'..nc..'_yuyv']()
    local width = vcm['get_image'..nc..'_width']()/2 -- number of yuyv packages
    local height = vcm['get_image'..nc..'_height']()
    local count = vcm['get_image'..nc..'_count']()
    array = serialization.serialize_array2(yuyv, width, height, 
    'int32', 'yuyv'..tostring(nc), count);
  --  array = serialization.serialize_array(yuyv, width, height, 
  --	'int32', 'yuyv', count);

    local sendyuyv = {};
    sendyuyv.team = {};
    sendyuyv.team.number = gcm.get_team_number();
    sendyuyv.team.player_id = gcm.get_team_player_id();

    local tSerialize=0;
    local tSend=0;  
    local totalSize=0;
    for i=1,#array do
      sendyuyv.arr = array[i];
      t0 = unix.time();
      senddata=serialization.serialize(sendyuyv);     
      senddata = Z.compress(senddata, #senddata);
      t1 = unix.time();
      tSerialize= tSerialize + t1-t0;
      CommWired.send(senddata, #senddata);
      t2 = unix.time();
      tSend=tSend+t2-t1;
      totalSize=totalSize+#senddata;

      -- Need to sleep in order to stop drinking out of firehose
      unix.usleep(pktDelay);
    end
    if debug>0 then
      print("Image info array num:",#array,"Total size",totalSize);
      print("Total Serialize time:",#array,"Total",tSerialize);
      print("Total Send time:",tSend);
    end
  end
end

--At this moment Sub2 is not needed. Dickens
function sendImgSub2()
  -- yuyv2 --
  for nc=1, 2 do
    local yuyv2 = vcm['get_image'..nc..'_yuyv2']()
    local width = vcm['get_image'..nc..'_width']()/4; -- number of yuyv packages
    local height = vcm['get_image'..nc..'_height']()/2;
    local count = vcm['get_image'..nc..'_count']()
    
  --  array = serialization.serialize_array(yuyv2, width, height, 
  --		'int32', 'ysub2', count);
    array = serialization.serialize_array2(yuyv2, width, height, 
      'int32', 'ysub'..tostring(nc), count);
    local sendyuyv2 = {};
    sendyuyv2.team = {};
    sendyuyv2.team.number = gcm.get_team_number();
    sendyuyv2.team.player_id = gcm.get_team_player_id();

    local tSerialize=0;
    local tSend=0;  
    local totalSize=0;
    for i=1,#array do
      sendyuyv2.arr = array[i];
      t0 = unix.time();
      senddata=serialization.serialize(sendyuyv2);
      senddata = Z.compress(senddata, #senddata);
      t1 = unix.time();
      tSerialize= tSerialize + t1-t0;
      CommWired.send(senddata, #senddata);
      t2 = unix.time();
      tSend=tSend+t2-t1;
      totalSize=totalSize+#senddata;

      -- Need to sleep in order to stop drinking out of firehose
  --    unix.usleep(pktDelay);
    end

    if debug>0 then
      print("Image2 info array num:",#array,"Total size",totalSize);
      print("Total Serialize time:",#array,"Total",tSerialize);
      print("Total Send time:",tSend);
    end
  end
end

--[[
function sendImgSub4()
  -- yuyv3 --
  yuyv3 = vcm.get_image_yuyv3();
  width = vcm.get_image_width()/8; -- number of yuyv packages
  height = vcm.get_image_height()/4;
  count = vcm.get_image_count();

  array = serialization.serialize_array2(yuyv3, width, height, 
		'int32', 'ysub4', count);
  sendyuyv3 = {};
  sendyuyv3.team = {};
  sendyuyv3.team.number = gcm.get_team_number();
  sendyuyv3.team.player_id = gcm.get_team_player_id();

  local tSerialize=0;
  local tSend=0;  
  for i=1,#array do
    sendyuyv3.arr = array[i];
    t0 = unix.time();
    senddata=serialization.serialize(sendyuyv3);
    senddata = Z.compress(senddata, #senddata);
    t1 = unix.time();
    tSerialize= tSerialize + t1-t0;
    CommWired.send(senddata, #senddata);
    t2 = unix.time();
    tSend=tSend+t2-t1;

    -- Need to sleep in order to stop drinking out of firehose
    unix.usleep(pktDelay);
  end
  if debug>0 then
    print("Image3 info array num:",#array,"Total size",#senddata*#array);
    print("Total Serialize time:",#array,"Total",tSerialize);
    print("Total Send time:",tSend);
  end
end
lut_count = 0;
function send_lut()
  lut_count = lut_count + 1;
  -- send lut
--  if matcm.get_control_lut_updated() ~= lut_updated  then
--    lut_updated = matcm.get_control_lut_updated();
  if lut_count % 5 == 0 then
    sendlut = {}
--    print("send lut, since it changed");
    lut = vcm.get_image_lut();
    width = 512;
    height = 512;
    count = vcm.get_image_count();

    array = serialization.serialize_array(lut, width,
                    height, 'uint8', 'lut', count);
    
    sendlut.updated = 0; --lut_updated;
    sendlut.ctrl_key = matcm.get_control_key();
    sendlut.arr = array;
    local tSerialize = 0;
    local tSend = 0;
    local totalSize = 0;
    for i = 1, #array do
      sendlut.arr = array[i];
--     print(sendlut.arr.name, i)
      t0 = unix.time();
      senddata = serialization.serialize(sendlut);
      senddata = Z.compress(senddata, #senddata);
      t1 = unix.time();
      tSerialize = tSerialize + t1 - t0;
      CommWired.send(senddata, #senddata);
      t2 = unix.time();
      totalSize = totalSize + #senddata;
      tSend = tSend + t2 - t1

    -- Need to sleep in order to stop drinking out of firehose
--      unix.usleep(pktDelay);
    end

    if debug>0 then
      print("LUT info array num:",#array,"Total size",totalSize);
      print("Total Serialize time:",#array,"Total",tSerialize);
      print("Total Send time:",tSend);
    end
  end
end

--]]

function update(enable)
  if enable == 0 then return; end
  --At level 3, we only send yuyv for logging and nothing else
--  if enable == 3 then return; end
	
  send = {};	
  for shmHandlerkey,shmHandler in pairs(sendShm) do
    send[shmHandlerkey] = {};
    for sharedkey,sharedvalue in pairs(shmHandler.shared) do
      send[shmHandlerkey][sharedkey] = {};
      for itemkey,itemvalue in pairs(shmHandler.shared[sharedkey]) do
	    --String can partially match
	      m_1,m_2=string.find(itemReject, itemkey);
	      sendokay=false;
        if m_1==nil or not (m_1==1 and m_2==itemReject:len()) then
        --print(string.format("shmHandlerKey %s sharedkey %s itemkey %s\n",
        --	shmHandlerkey,sharedkey,itemkey));

  	      send[shmHandlerkey][sharedkey][itemkey] = 
          shmHandler['get_'..sharedkey..'_'..itemkey]();
 	      end
      end
    end
  end
  t0 = unix.time();
  senddata=serialization.serialize(send);
  senddata = Z.compress(senddata, #senddata);
  t1 = unix.time();
  CommWired.send(senddata, #senddata);
  t2 = unix.time();
  unix.usleep(pktDelay2);

  if debug>0 then
    print("SHM Info byte:",#senddata)
    print("Serialize time:",t1-t0);
    print("Comm time:",t2-t1);
  end
end

function update_img( enable, imagecount )
  if(enable==1) then
    --[[
    --1: Fast debug mode
    --send 1/4 image and labelB
    if subsampling2>0 then
      sendImgSub4();
      sendB();
    end
    --]]
      sendImg();
      sendA();
      sendB();
  elseif(enable==2) then
    --2: Vision debug mode
    --Send everything 
      sendImgSub2();
      sendA();
      sendB();
  elseif enable==3 then
    --[[
    --3: Logging mode
    if subsampling>0 then
      sendImgSub2();
    else
      sendImg();
    end
    --]]
  end
end


function update_motion()
  local send={}
  local sendShmMotion = { mcmshm=mcm}
  for shmHandlerkey,shmHandler in pairs(sendShmMotion) do
    send[shmHandlerkey] = {};
    for sharedkey,sharedvalue in pairs(shmHandler.shared) do
      send[shmHandlerkey][sharedkey] = {};
      for itemkey,itemvalue in pairs(shmHandler.shared[sharedkey]) do
      --String can partially match
        m_1,m_2=string.find(itemReject, itemkey);
        sendokay=false;
        if m_1==nil or not (m_1==1 and m_2==itemReject:len()) then
        --print(string.format("shmHandlerKey %s sharedkey %s itemkey %s\n",
        --  shmHandlerkey,sharedkey,itemkey));
          send[shmHandlerkey][sharedkey][itemkey] = 
          shmHandler['get_'..sharedkey..'_'..itemkey]();
        end
      end
    end
  end
  t0 = unix.time();
  senddata=serialization.serialize(send);
  senddata = Z.compress(senddata, #senddata);
  t1 = unix.time();
  CommWired.send(senddata, #senddata);
  t2 = unix.time();
  unix.usleep(pktDelay2);
  if debug>0 then
    print("SHM Info byte:",#senddata)
    print("Serialize time:",t1-t0);
    print("Comm time:",t2-t1);
  end
end
