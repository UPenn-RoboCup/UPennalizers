bhwalk = require'bhwalk'
require'unix'

for k, v in pairs(bhwalk) do

	print(k,v)
end

-- Try to walk
local nJoint = 22
local jAngles, jCurrents = { } , { } 
for i=1,nJoint do

	jAngles[i] = 0
	jCurrents[i] = 0
end
print('Walk request',bhwalk.get_motion_request())

bhwalk.stand_request()
print('Walk request',bhwalk.get_motion_request())
for i=1,5 do

	bhwalk.set_sensor_angles(jAngles)
	bhwalk.set_sensor_currents(jCurrents)
	print("Joints", unpack(bhwalk.get_joint_angles()) )
	print("Odometry", unpack(bhwalk.get_odometry()) )
	-- 100Hz
	bhwalk.update(unix.time_ms())
	unix.usleep(1e4)
end

for i=1,100 do

	bhwalk.walk_request(10,10,0)
	bhwalk.set_sensor_angles(jAngles)
	bhwalk.set_sensor_currents(jCurrents)
	print('Walk request',bhwalk.get_motion_request())
	bhwalk.update(unix.time_ms())
	unix.usleep(1e4)
	print("Joints", unpack(bhwalk.get_joint_angles()) )
	print("Odometry", unpack(bhwalk.get_odometry()) )
end
