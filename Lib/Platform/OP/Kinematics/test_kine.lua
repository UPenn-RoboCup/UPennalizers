K = require 'OPKinematics'
T = require 'Transform'
require 'vector'

-- Forward kine
	qLArm = math.pi/180*vector.new({0,0,0}) -- Out in front
	qRArm = math.pi/180*vector.new({0,0,0})
--	qLArm = math.pi/180*vector.new({90,0,0}) -- Down
--	qRArm = math.pi/180*vector.new({90,0,0})
--	qLArm = math.pi/180*vector.new({-90,0,0}) -- Up
--	qRArm = math.pi/180*vector.new({-90,0,0})
--	qLArm = math.pi/180*vector.new({90,90,0}) -- Balance
--	qRArm = math.pi/180*vector.new({90,-90,0})
--	qLArm = math.pi/180*vector.new({0,90,0}) -- Balance 2
--	qRArm = math.pi/180*vector.new({0,-90,0})
--	qLArm = math.pi/180*vector.new({90,0,-90}) -- Guns
--	qRArm = math.pi/180*vector.new({90,0,-90})

  fL = K.forward_larm(qLArm);
fR = K.forward_rarm(qRArm);

tL = T.inv(T.inv(fL))
tR = T.inv(T.inv(fR))
pL = vector.slice( tL * vector.new({0,0,0,1}), 1,3 )
pR = vector.slice( tR * vector.new({0,0,0,1}), 1,3 )

qL_inv = vector.new( K.inverse_larm( pL ) );
qR_inv = vector.new( K.inverse_rarm( pR ) );

print('Left Arm\n===')
print('Joint Angles:',qLArm*180/math.pi)
print('Position',pL)
print('IK Angles',qL_inv*180/math.pi)

print('Right Arm\n===')
print('Joint Angles:',qRArm*180/math.pi)
print('Position',pR)
print('IK Angles',qR_inv*180/math.pi)
