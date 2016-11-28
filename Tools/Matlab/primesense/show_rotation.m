function [ r p y ] = show_rotation( playerID )
%SHOW ROTATION Plot the rotation box based on the kinect data
%   Return roll pitch yaw angles
global jointNames players
positions = players{playerID}.positions;

%iNeck = ismember(jointNames, 'Neck')==1;
iNeck = ismember(jointNames, 'Head')==1;
iTorso = ismember(jointNames, 'Torso')==1;
iShoulderL = ismember(jointNames, 'ShoulderL')==1;
iShoulderR = ismember(jointNames, 'ShoulderR')==1;

%n2t = positions(iTorso,:)-positions(iNeck,:);
%s2s = positions(iShoulderL,:)-positions(iShoulderR,:);
t2n = positions(iNeck,:)-positions(iTorso,:);
s2s = positions(iShoulderR,:)-positions(iShoulderL,:);

% In default coordinates
s2s = s2s / norm(s2s); % x
t2n = t2n / norm(t2n); % y
chest = cross(s2s,t2n); %z
%M = [s2s' t2n' chest'];

% Remap so that:
% rotations about chest cause roll
% rotations about s2s cause pitch
% rotations about t2n cause yaw
map = [ 3, 1, 2 ];
u = intrlv(chest,map)';
v = intrlv(s2s,map)';
w = intrlv(t2n,map)';
M = [u v w];

R = M*(M'*M)^-1/2;

r = atan2(R(3,2),R(3,3));
y = atan2(R(2,1),R(1,1));
p = atan2(-1*R(3,1),cos(y)*R(1,1)+sin(y)*R(2,1));

rd = 180/pi * r;
pd = 180/pi * p;
yd = 180/pi * y;

rotplot(R,[0;0;0],1);
h_t = title( sprintf('Roll %.1f Pitch %.1f  Yaw %.1f',rd,pd,yd) );
set(h_t,'FontSize',28);

end