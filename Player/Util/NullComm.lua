module(..., package.seeall);
--[[
   {"size", lua_darwinopcomm_size},
  {"receive", lua_darwinopcomm_receive}, 
  {"send", lua_darwinopcomm_send},
  {"send_label", lua_darwinopcomm_send_label},
  {"send_yuyv", lua_darwinopcomm_send_yuyv},
  {"send_yuyv2", lua_darwinopcomm_send_yuyv2},
  {"send_particle", lua_darwinopcomm_send_particle},
--]]

function size()
  return 0;
end

function receive()
  return;
end

function send(var)
end

function send_label(var)
end

function send_yuyv(var)
end

function send_yuyv2(var)
end

function send_particle(var)
end
