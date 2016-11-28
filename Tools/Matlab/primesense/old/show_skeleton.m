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


joint2draw = [3,4,  6,9,  12,15]; %torso, waist, shoulderL, writsL, shoulderR, wristR


%% Figure
figure(1);
clf;
p_left=plot3( positions(:,1), positions(:,2), positions(:,3), 'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'r', 'MarkerSize',10 );

hold on;
p_right=plot3( positions(:,1), positions(:,2), positions(:,3),'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'g', 'MarkerSize',10 );

p_center=plot3( positions(:,1), positions(:,2),positions(:,3), 'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'b', 'MarkerSize',10 );

%axis([-1000 1000 -1300 1200]);
%axis([-1 1 -1.25 1.25 -2 2]);
axis([-1 1 -1 1 -1 1]);

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

    %% Plot the data
    set(p_left,   'XData', positions( left_idx&confs(:,1)>0,   1));
    set(p_left,   'YData', positions( left_idx&confs(:,1)>0,   3));
    set(p_left,   'ZData', positions( left_idx&confs(:,1)>0,   2));


    set(p_right,  'XData', positions( right_idx&confs(:,1)>0,  1));
    set(p_right,  'YData', positions( right_idx&confs(:,1)>0,  3));
    set(p_right,  'ZData', positions( right_idx&confs(:,1)>0,  2));


    set(p_center, 'XData', positions( center_idx&confs(:,1)>0, 1));
    set(p_center, 'YData', positions( center_idx&confs(:,1)>0, 3));
    set(p_center, 'ZData', positions( center_idx&confs(:,1)>0, 2));

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
