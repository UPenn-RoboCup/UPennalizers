function  qArm = kine_map( dArm )
%KINE_MAP Summary of this function goes here
%   Detailed explanation goes here
% Real numbers
%upperArmLength = .060;
%lowerArmLength = .129;
% Dummy number
upperArmLength = 1;
lowerArmLength = 1;
qArm = -999 * ones(3,1);
% Law of cosines to find end effector distance from shoulder
c_sq = dArm(1)^2+dArm(2)^2+dArm(3)^2;
c = sqrt( c_sq );
if( c>lowerArmLength+upperArmLength )
    disp('Distance not reachable!');
    return;
end
tmp = ((upperArmLength^2)+(lowerArmLength^2)-c_sq) / ...
    (2*upperArmLength*lowerArmLength);
if( tmp>1 ) % Impossible configuration
    disp('Impossible confirguration!');
    return;
end
qArm(3) = acos( tmp );
% Angle of desired point with the y-axis
qArm(2) = acos( dArm(2) / c );
% How much rotation about the y-axis (in the xz plane
qArm(1) = atan2( dArm(3), dArm(1) ) - qArm(3);

% Condition for OP default joint position
qArm(3) = qArm(3) - pi;
qArm(2) = qArm(2) - pi/2;
qArm(1) = qArm(1) + pi;

qArm = qArm * 180/pi;

end

