%% Plot the skeleton
clear all;
load('primeLogs_control.mat');
fps = 30;
tperiod = 1/fps;
debug = 0;

joint2track = 'ElbowL';
index2track = find(ismember(jointNames, joint2track)==1);

%% For quick calculations
%const double upperArmLength = .060;  //OP, spec
%const double lowerArmLength = .129;  //OP, spec
op_arm_len = .189;
indexTorso = find(ismember(jointNames, 'Torso')==1);
indexHead = find(ismember(jointNames, 'Head')==1);
indexShoulderL = find(ismember(jointNames, 'ShoulderL')==1);
indexElbowL = find(ismember(jointNames, 'ElbowL')==1);
indexHandL = find(ismember(jointNames, 'HandL')==1);
indexFootL = find(ismember(jointNames, 'FootL')==1);
indexShoulderR = find(ismember(jointNames, 'ShoulderR')==1);
indexElbowR = find(ismember(jointNames, 'ElbowR')==1);
indexHandR = find(ismember(jointNames, 'HandR')==1);
indexFootR = find(ismember(jointNames, 'FootR')==1);

nLogs = numel(jointLog);
nJoints = numel(jointNames);
positions = jointLog(1).positions;
rots = jointLog(1).rots;
confs = jointLog(1).confs;
axis_angles_loc = zeros(nJoints,4);
rpy_loc = zeros(nJoints,3);
[ local_rots ] = abs2local_rot( rots );

% Velocity vars
last_va = 0;
last_vx = 0;
last_vy = 0;
log_va = [0];
log_vx = [0];
log_vy = [0];

pc = confs(:,1)>0;
rc = confs(:,2)>0;
ci = center_idx & pc;
li = left_idx & pc;
ri = right_idx & pc;
f = figure(1);
clf;
p_left=plot3( positions(li,1), positions(li,2), positions(li,3),'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'r', 'MarkerSize',10 );
hold on;
p_right=plot3( positions(ri,1), positions(ri,2), positions(ri,3),'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'g', 'MarkerSize',10 );
p_center=plot3( positions(ci,1), positions(ci,2), positions(ci,3),'o', ...
    'MarkerEdgeColor','k', 'MarkerFaceColor', 'b', 'MarkerSize',10 );

% Front view
view(0,90);
% Side view
%view(-90,0);
% Top View
%view(0,0);
axis([-1 1 -1.2 1.5 -1 1]);
xlabel('X');
ylabel('Y');
zlabel('Z');

% Show direction controls of Kinect Data
figure(2);
clf;
h_va = plot( log_va, 'r+' );

figure(3);
clf;
h_vx = plot( log_vx, 'bx' );
hold on;
h_vy = plot( log_vy, 'y*' );
maxStep = 0.08;
ylim([-0.1 0.1]);

for i=1:nLogs-1
    tstart=tic;
    
    % Check data limits
    if( isempty(jointLog(i).t) )
        break;
    end
    if( isempty(jointLog(i+1).t) )
        twait = 0;
    else
        twait = jointLog(i+1).t - jointLog(i).t;
    end
    %% Get data
    positions = jointLog(i).positions - repmat(jointLog(i).positions(indexTorso,:), nJoints,1);
    %positions = positions / 1000;
    rots = jointLog(i).rots;
    confs = jointLog(i).confs;
    [ local_rots ] = abs2local_rot( rots );
    for j=1:nJoints
        %        axis_angles_loc(j,:) = vrrotmat2vec(local_rots(:,:,j));
        rpy_loc(j,:) = dcm2angle( local_rots(:,:,j) ) * 180/pi;
    end
    
    %% Arm calculations
    e2h = positions(indexElbowL,:) - positions(indexHandL,:);
    s2e = positions(indexShoulderL,:) - positions(indexElbowL,:);
    s2h = positions(indexShoulderL,:) - positions(indexHandL,:);
    arm_lenL = sqrt(norm(e2h)) + sqrt(norm(s2e));
    offsetL = s2h * (op_arm_len / arm_lenL);
    left_hand = [ s2h(3),s2h(1),s2h(2) ] / arm_lenL;
    
    e2h = positions(indexElbowR,:) - positions(indexHandR,:);
    s2e = positions(indexShoulderR,:) - positions(indexElbowR,:);
    s2h = positions(indexShoulderR,:) - positions(indexHandR,:);
    arm_lenR = sqrt(norm(e2h)) + sqrt(norm(s2e));
    offsetR = s2h * (op_arm_len / arm_lenR);
    right_hand = [ s2h(3),s2h(1),s2h(2) ];
    
    %% Punch calculations
    %left_hand  = [ offsetL(3),offsetL(1),offsetL(2) ];
    %right_hand  = [ offsetL(3),offsetL(1),offsetL(2) ];
    if( i>1 )
        dt = jointLog(i).t - jointLog(i-1).t;
    else
        dt = 0;
    end
    %disp(dt)
    dframes = round( dt/tperiod );
    doing_punch = 0;
    %disp(dframes)
    if( dt>0 )
        left_hand = left_hand / arm_lenL;
        filtered_left = track_left_hand([left_hand(1),left_hand(3)],dframes);
        right_hand = right_hand / arm_lenL;
        filtered_right = track_right_hand([right_hand(1),right_hand(3)],dframes);
        %filtered_ball [x y vx vy ep evp]
        xhandL = filtered_left(1);
        zhandL = filtered_left(2);
        vx_handL = filtered_left(3) * 30; % Per frame to per second
        vz_handL = filtered_left(4) * 30;
        xhandR = filtered_right(1);
        zhandR = filtered_right(2);
        vx_handR = filtered_right(3) * 30; % Per frame to per second
        vz_handR = filtered_right(4) * 30;
        
        vels = sqrt( [ vx_handL^2+vz_handL^2 vx_handR^2+vz_handR^2] );
        
        % Signs are mixed in the y direction...
        if( dframes==1 )
            if( sum(abs(vels)>.4)>0 )
                doing_punch = 1;
            end
        end
    end
    
    %% Control calculations
    %t2sL = positions(indexTorso,:) - positions(indexShoulderL,:);
    %t2sR = positions(indexTorso,:) - positions(indexShoulderR,:);
    sL2sR = positions(indexShoulderL,:) - positions(indexShoulderR,:);
    h2t = positions(indexHead,:) - positions(indexTorso);
    % Care really only about the xz plane
    maxStep = 0.08;
    offset_x = 0.02;
    deadband = 0.01;
    beta = 0.8;
    vx = (-1 * h2t(3) / 5) - offset_x;
    vx = beta*vx+(1-beta)*last_vx;
    % Clamp
    if(vx>maxStep)
        vx = maxStep;
    elseif(vx<-1*maxStep)
        vx = -1*maxStep;
    end
    % Deadband
    if(vx<deadband && vx>-1*deadband)
        vx = 0;
    end
    last_vx = vx;
    
    % y control
    vy = -1 * h2t(1) / 5;
    vy = beta*vy+(1-beta)*last_vy;
    % Clamp
    if(vy>maxStep)
        vy = maxStep;
    elseif(vx<-1*maxStep)
        vy = -1*maxStep;
    end
    % Deadband
    if(vy<deadband && vy>-1*deadband)
        vy = 0;
    end
    last_vy = vy;
    
    % a control
    beta = 0.9;
    va = atan2( sL2sR(1),sL2sR(3) ) + pi/2;
    va = beta*va + (1-beta)*last_va;
    last_va = va;
    if(doing_punch)
        vx = 0;
        vy = 0;
        va = 0;
        last_vx = vx;
        last_vy = vy;
        last_va = va;
    end
    %{
    if( confs(indexHead,1)>0 && confs(indexTorso,1)>0 )
        fprintf('%f {%f %f %f}\n',jointLog(i).t-jointLog(1).t, vx,vy,va);
    else
        fprintf('Not confident\n');
    end
    %}
    
    log_va = [log_va va];
    log_vx = [log_vx vx];
    log_vy = [log_vy vy];
    %% Update Figure
    % Update plot3
    pc = confs(:,1)>0;
    rc = confs(:,2)>0;
    ci = center_idx & pc;
    li = left_idx & pc;
    ri = right_idx & pc;
    set(p_left, 'XData', positions( li, 1), ...
        'YData', positions( li, 2), ...
        'ZData', positions( li, 3) ...
        );
    set(p_right, 'XData', positions( ri, 1), ...
        'YData', positions( ri, 2), ...
        'ZData', positions( ri, 3));
    set(p_center, 'XData', positions( ci, 1), ...
        'YData', positions( ci, 2), ...
        'ZData', positions( ci, 3));
    
    % Update Velocity plot
    set(h_va,'XData',[1:numel(log_va)]);
    set(h_va,'YData',log_va(:));
    set(h_vx,'XData',[1:numel(log_vx)]);
    set(h_vx,'YData',log_vx(:));
    set(h_vy,'XData',[1:numel(log_vy)]);
    set(h_vy,'YData',log_vy(:));
    
    %% Timing
    tf = toc(tstart);
    % Realistic pause
    %pause( max(twait-tf,0) );
    % Arbitrary pause:
    pause(.01);
end