module(... or '', package.seeall)

-- Add the required paths
cwd = '.';

uname  = io.popen('uname -s')
system = uname:read();

computer = os.getenv('COMPUTER') or system;
package.cpath = cwd.."/Lib/?.so;"..package.cpath;

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path; 



require ('Config')
--We always store data from robot to shm (1,1) 
Config.game.teamNumber = 1; 
Config.game.playerID = 1; 

require ('cutil')
require ('vector')
require ('serialization')
require ('Comm')
require ('util')

require ('wcm')
require ('gcm')
require ('vcm')
require ('ocm')
require ('mcm')

require 'unix'

yuyv_all = {}
yuyv_flag = {}
labelA_all = {}
labelA_flag = {}
yuyv2_all = {}
yuyv2_flag = {}
FIRST_YUYV = true
FIRST_YUYV2 = true
FIRST_LABELA = true
yuyv_t_full = unix.time();
yuyv2_t_full = unix.time();
yuyv3_t_full = unix.time();
labelA_t_full = unix.time();
labelB_t_full = unix.time();
data_t_full = unix.time();
fps_count=0;
fps_interval = 15;
yuyv_type=0;


Comm.init(Config.dev.ip_wired,111111);
print('Receiving from',Config.dev.ip_wired);

function check_flag(flag)
  sum = 0;
  for i = 1 , #flag do
    sum = sum + flag[i];
  end
  return sum;
end

function parse_name(namestr)
  name = {}
  name.str = string.sub(namestr,1,string.find(namestr,"%p")-1);
  namestr = string.sub(namestr,string.find(namestr,"%p")+1);
  name.size = tonumber(string.sub(namestr,1,string.find(namestr,"%p")-1));
  namestr = string.sub(namestr,string.find(namestr,"%p")+1);
  name.partnum = tonumber(string.sub(namestr,1,string.find(namestr,"%p")-1));
  namestr = string.sub(namestr,string.find(namestr,"%p")+1);
  name.parts = tonumber(namestr);
  return name
end


function push_yuyv(obj)
--print('receive yuyv parts');
  yuyv = cutil.test_array();
  name = parse_name(obj.name);
  if (FIRST_YUYV == true) then
    print("initiate yuyv flag");
    yuyv_flag = vector.zeros(name.parts);
    FIRST_YUYV = false;
  end

  yuyv_flag[name.partnum] = 1;
  yuyv_all[name.partnum] = obj.data;

  --Just push the image after all segments are filled at the first scan
  --Because the image will be broken anyway if packet loss occurs

  if (check_flag(yuyv_flag) == name.parts and name.partnum==name.parts ) then
    fps_count=fps_count+1;
    if fps_count%fps_interval ==0 then
      print("full yuyv\t"..1/(unix.time() - yuyv_t_full).." fps" );
    end
    yuyv_t_full = unix.time();
    local yuyv_str = "";
      for i = 1 , name.parts do --fixed
      yuyv_str = yuyv_str .. yuyv_all[i];
    end

    height= string.len(yuyv_str)/obj.width/4;
    cutil.string2userdata2(yuyv,yuyv_str,obj.width,height);
--  cutil.string2userdata(yuyv,yuyv_str,obj.width,height);
    vcm.set_image_yuyv(yuyv);
  end
end



yuyv2_part_last = 0;

function push_yuyv2(obj)
--	print('receive yuyv parts');
  yuyv2 = cutil.test_array();
  name = parse_name(obj.name);
  if (FIRST_YUYV2 == true) then
    print("initiate yuyv2 flag");
    yuyv2_flag = vector.zeros(name.parts);
    FIRST_YUYV2 = false;
  end

--[[
  if name.partnum==yuyv2_part_last then
    print("Duplicated packet");
  elseif name.partnum~=(yuyv2_part_last%name.parts)+1 then
    print("Missing packet");
  end
--]]

  yuyv2_part_last = name.partnum;
  yuyv2_flag[name.partnum] = 1;
  yuyv2_all[name.partnum] = obj.data;

  --Just push the image after all segments are filled at the first scan
  --Because the image will be broken anyway if packet loss occurs
  if (check_flag(yuyv2_flag) == name.parts and name.partnum==name.parts ) then
     fps_count=fps_count+1;
     if fps_count%fps_interval ==0 then
       print("yuyv2\t"..1/(unix.time() - yuyv2_t_full).." fps" );
     end

     yuyv2_t_full = unix.time();
     local yuyv2_str = "";
     for i = 1 , name.parts do --fixed
       yuyv2_str = yuyv2_str .. yuyv2_all[i];
     end
     height= string.len(yuyv2_str)/obj.width/4;
     cutil.string2userdata2(yuyv2,yuyv2_str,obj.width,height);
     vcm.set_image_yuyv2(yuyv2);
   end
end

function push_yuyv3(obj)
-- 1/4 size, we don't need to divide it 

  fps_count=fps_count+1;
  if fps_count%fps_interval ==0 then
     print("yuyv3\t"..1/(unix.time() - yuyv3_t_full).." fps" );
  end
  yuyv3_t_full = unix.time();
  yuyv3 = cutil.test_array();
  name = parse_name(obj.name);
  height= string.len(obj.data)/obj.width/4;
  cutil.string2userdata2(yuyv3,obj.data,obj.width,height);
  vcm.set_image_yuyv3(yuyv3);
end


--Function to OLD labelA packet
--[[
function push_labelA(obj)
--  print('receive labelA parts');
  local labelA = cutil.test_array();
  local name = parse_name(obj.name);
  if (FIRST_LABELA == true) then
    labelA_flag = vector.zeros(name.parts);
    FIRST_LABELA = false;
  end

  labelA_flag[name.partnum] = 1;
  labelA_all[name.partnum] = obj.data;
  if (check_flag(labelA_flag) == name.parts) then
--  print("full labelA\t",.1/(unix.time() - labelA_t_full).."fps" );
--  labelA_t_full = unix.time();
    labelA_flag = vector.zeros(name.parts);
    local labelA_str = "";
    for i = 1 , name.parts do
      labelA_str = labelA_str .. labelA_all[i];
    end

    cutil.string2userdata(labelA,labelA_str);
    vcm.set_image_labelA(labelA);
    labelA_all = {};
  end
end
--]]

--Function for new compactly encoded labelA
function push_labelA(obj)
  local name = parse_name(obj.name);
  local labelA = cutil.test_array();
--  cutil.string2label_double(labelA,obj.data);	
  cutil.string2label_rle(labelA,obj.data);	
  vcm.set_image_labelA(labelA);
end

function push_labelB(obj)
  local name = parse_name(obj.name);
  local labelB = cutil.test_array();
--cutil.string2userdata(labelB,obj.data);	
--cutil.string2label(labelB,obj.data);	
--  cutil.string2label_double(labelB,obj.data);	
  cutil.string2label_rle(labelB,obj.data);	
  vcm.set_image_labelB(labelB);
end

function push_occmap(obj)
  occmap = cutil.test_array();
  name = parse_name(obj.name);
  cutil.string2userdata2(occmap, obj.data, obj.width, obj.height);
  ocm.set_occ_map(occmap);
end

function push_data(obj)
--	print('receive data');
--  print("data\t",.1/(unix.time() - data_t_full).."fps");
--	data_t_full = unix.time();

  if type(obj)=='string' then print(obj); return end

  for shmkey,shmHandler in pairs(obj) do
    for sharedkey,sharedHandler in pairs(shmHandler) do
      for itemkey,itemHandler in pairs(sharedHandler) do
	local shmk = string.sub(shmkey,1,string.find(shmkey,'shm')-1);
        local shm = _G[shmk];
        shm['set_'..sharedkey..'_'..itemkey](itemHandler);
      end
    end
  end
end

while( true ) do

  msg = Comm.receive();
  if( msg ) then
    local obj = serialization.deserialize(msg);
    if( obj.arr ) then
    	if ( string.find(obj.arr.name,'yuyv') ) then 
     	  push_yuyv(obj.arr);
    	--print("yuyv_type00000000")
    	  yuyv_type=1;
    
    	elseif ( string.find(obj.arr.name,'ysub2') ) then 
     	  push_yuyv2(obj.arr);
    	  yuyv_type=2;
    
    	elseif ( string.find(obj.arr.name,'ysub4') ) then 
     	  push_yuyv3(obj.arr);
    	  yuyv_type=3;
    
    	elseif ( string.find(obj.arr.name,'labelA') ) then 
    	  push_labelA(obj.arr);
    	elseif ( string.find(obj.arr.name,'labelB') ) then 
    	  push_labelB(obj.arr);
      elseif ( string.find(obj.arr.name,'occmap') ) then
        push_occmap(obj.arr);
    	end

    else
	push_data(obj);
    end
  end
  vcm.set_camera_yuyvType(yuyv_type);
  unix.usleep(1E6*0.005);

end
