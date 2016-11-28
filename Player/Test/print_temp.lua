dofile('init.lua');
require('Body');
--temperature
util.ptable(Body.get_sensor_temperature());
