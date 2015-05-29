local cwd = '.';
-- Get Computer for Lib suffix
local computer = os.getenv('COMPUTER') or '';
local computer = 'Darwin' -- can get from uname
if (string.find(computer, 'Darwin')) then
  -- MacOS X uses .dylib:
  print('Mac!')
  package.cpath = cwd..'/Lib/?.dylib;' .. package.cpath;
  package.cpath = cwd .. '/?.dylib;' .. package.cpath
else
  print('Comp:', computer)
  package.cpath = cwd .. '/Lib/?.so;' .. package.cpath;
end

kinematics = require('XOSKinematics')

function print_table(t)
  local i;
  local s = "";
  for i = 1,#(t) do 
    s = s..string.format("%.4f ", t[i]);
  end
  print(s);
end

function print_transform(t)
  local i, j;
  local s = "";
  for i = 1,4 do
    for j = 1,4 do
      s = s..string.format("%.4f ",t[i][j]);
    end
    s = s.."\n";
  end
  print(s);
end

pLLeg = {0, .05, 0, 0, 0, 0};
pRLeg = {0, -.05, 0, 0, 0, 0};
--pTorso = {0.015, 0, 0.30, 0, 0, 0};
pTorso = {0.015, 0, 0.21, 0, 0, 0};
pTorso[2] = 0.0;

q = kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 0);
--q[2] = q[2]+.05;
print_table(q);

tLeft = kinematics.forward_lleg({q[1],q[2],q[3],q[4],q[5],q[6]});
print_transform(tLeft);

tRight = kinematics.forward_rleg({q[7],q[8],q[9],q[10],q[11],q[12]});
print_transform(tRight);
