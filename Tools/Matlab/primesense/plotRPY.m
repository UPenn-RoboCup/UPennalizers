global jointNames positions
jointNames = { ...
    'Head', 'Neck', 'Torso', 'Waist', ... %1-4
    'CollarL','ShoulderL', 'ElbowL', 'WristL', 'HandL', 'FingerL', ... %5-10 % SHOULD BE 7-12!
    'CollarR','ShoulderR', 'ElbowR', 'WristR', 'HandR', 'FingerR', ... %11-16
    'HipL', 'KneeL', 'AnkleL', 'FootL', ... % 17-20
    'HipR', 'KneeR', 'AnkleR', 'FootR'... %21-24
    };

% Grab data
nLog = numel(LOG);
roll = zeros(nLog,1);
pitch = zeros(nLog,1);
yaw = zeros(nLog,1);
beta = .75;
for i=1:nLog
    positions = LOG{i}.positions;
    [r p y] = show_rotation(0);
    roll(i) = r;
    pitch(i) = p;
    yaw(i) = y;
    if(i>1)
        yaw(i) = (1-beta)*yaw(i-1)+beta*y;
    end
end

%% Filter
roll = roll/pi*180;
pitch = pitch/pi*180;
yaw = yaw/pi*180;
RLIM = 5; % 5 degrees
PLIM = 20;
YLIM = 45; % 45 degrees
bad = abs(roll)>RLIM | abs(pitch)>PLIM | abs(yaw)>YLIM;

%% Plot
figure(2);
clf;
hold on;
plot(roll(~bad),'r','LineWidth',4);
plot(pitch(~bad),'b','LineWidth',4);
plot(yaw(~bad),'g+','LineWidth',4);