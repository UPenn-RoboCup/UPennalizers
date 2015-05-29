module(... or '', package.seeall)

require("Config")
require("vector")
require("util")
require("shm")

shared = {}
shsize = {}

shared.control = {}
shared.control.lut_updated = vector.zeros(1);
shared.control.key = vector.zeros(1);

util.init_shm_segment(getfenv(), _NAME, shared, shsize);

