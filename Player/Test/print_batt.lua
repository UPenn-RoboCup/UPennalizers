--Run in player folder with "lua Test/print_batt.lua"
dofile('init.lua');
require('Body');
print("Battery: ",Body.get_battery_level());
