module(..., package.seeall);
require("shm");
require("carray");

sensorShm = shm.open('dcmSensor');
actuatorShm = shm.open('dcmActuator');

sensor = {};
actuator = {};

function get_sensor_shm(shmkey, index)
  if (index) then
    return sensor[shmkey][index];
  else
    local t = {};
    for i = 1,#sensor[shmkey] do
      t[i] = sensor[shmkey][i];
    end
    return t;
  end
end

function set_actuator_shm(shmkey, val, index)
  index = index or 1;
  if (type(val) == "number") then
    actuator[shmkey][index] = val;
  elseif (type(val) == "table") then
    for i = 1,#val do
      actuator[shmkey][index+i-1] = val[i];
    end
  end
end

function init()
  for k,v in sensorShm.next, sensorShm do
    sensor[k] = carray.cast(sensorShm:pointer(k));
    getfenv()["get_sensor_"..k] =
      function(index)
        return get_sensor_shm(k, index);
      end
  end

  for k,v in actuatorShm.next, actuatorShm do
    actuator[k] = carray.cast(actuatorShm:pointer(k));
    getfenv()["set_actuator_"..k] =
      function(val, index)
        return set_actuator_shm(k, val, index);
      end
  end

  nJoint = #actuator.position;

  -- Initialize actuator commands and positions
  for i = 1,nJoint do
    actuator.command[i] = sensor.position[i];
    actuator.position[i] = sensor.position[i];
  end
end

