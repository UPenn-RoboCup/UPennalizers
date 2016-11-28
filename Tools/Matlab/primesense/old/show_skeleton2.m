%% Plot the skeleton
%clear all;
if( exist('sk','var') == 0 )
    startup;
    sk = shm_primesense(0,1);
end

%% Timing settings
prep_time = 3;
%prep_time = 0;
nseconds_to_log = 45;
run_once = 0;
counter = 0;
fps = 30;
twait = 1/fps;
logsz = nseconds_to_log * fps;

do_log = 0; % if zero, then inf time

%% Joint Settings
jointNames = { ...
    'Head', 'Neck', 'Torso', 'Waist', ... %1-4
    'CollarL','ShoulderL', 'ElbowL', 'WristL', 'HandL', 'FingerL', ... %5-10 % SHOULD BE 7-12!
    'CollarR','ShoulderR', 'ElbowR', 'WristR', 'HandR', 'FingerR', ... %11-16
    'HipL', 'KneeL', 'AnkleL', 'FootL', ... % 17-20
    'HipR', 'KneeR', 'AnkleR', 'FootR'... %21-24
    };
nJoints = numel(jointNames);
% Set up indexing
left_idx   = zeros(nJoints,1);
right_idx  = zeros(nJoints,1);
center_idx = zeros(nJoints,1);
left_idx([5:10 17:20]) = 1;
right_idx([11:16 21:24]) = 1;
center_idx([1:4]) = 1;

joint2track = 'ShoulderL';
index2track = find(ismember(jointNames, joint2track)==1);

%% Initialize variables
positions = zeros(nJoints,3);
rots = zeros(3,3,nJoints);
confs = zeros(nJoints,2);
% Logging variables
jointLog(logsz).t = 0;
jointLog(logsz).positions = positions;
jointLog(logsz).rots = rots;
jointLog(logsz).confs = confs;


%% 5 second prep
for i=prep_time:-1:1
    disp(i);
    pause(1);
end


%% Figure
figure(1);
clf;

%axis([-1000 1000 -1300 1200]);
%axis([-1 1 -1.25 1.25 -2 2]);

%% Go time
t0=tic;
t_passed=toc(t0);
while(do_log == 0 || t_passed<nseconds_to_log)
    tstart=tic;
    counter = counter + 1;
    %% Loop through each joint
    for j=1:nJoints
        jName = jointNames{j};
        joint = sk.get_joint( jName );
        positions(j,:) = joint.position;
        rots(:,:,j) = joint.rot;
        confs(j,:) = joint.confidence;
    end
    t_passed=toc(t0);
    %positions = positions - repmat(positions(1,:),nJoints,1); % Center at waist
    
    %% Append Log
    jointLog(counter).t = joint.t;
    jointLog(counter).positions = positions;
    jointLog(counter).rots = rots;
    jointLog(counter).confs = confs;

    waistPos = positions(3,:);
    torsoPos = positions(4,:);
    LSPos = positions (6,:);
    LHPos = positions (9,:);
    RSPos = positions (12,:);
    RHPos = positions (15,:);

    clf;
    plot3(waistPos(1),waistPos(2),waistPos(3),'o');
    hold on;
    plot3(torsoPos(1),torsoPos(2),torsoPos(3),'o');
    plot3(LSPos(1),LSPos(2),LSPos(3),'o');
    plot3(LHPos(1),LHPos(2),LHPos(3),'o');
    plot3(RSPos(1),RSPos(2),RSPos(3),'o');
    plot3(RHPos(1),RHPos(2),RHPos(3),'o');
    hold off;
    axis([-1 1 -1 1 -1 1]);


    %% Timing
    if( run_once==1 )
        break;
    end
    
    tf = toc(tstart);
    drawnow;
    pause( max(twait-tf,0) );
end

%% Save data
if( do_log==1 )
    save(strcat('primeLogs_',datestr(now,30)),'jointNames','jointLog', ...
        'left_idx','right_idx','center_idx');
end
