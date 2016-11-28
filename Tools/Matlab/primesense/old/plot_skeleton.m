%% Plot the skeleton
%clear all;

%load('primeLogs_sym.mat'); % Symmetric
%load('primeLogs_asym.mat'); % Asymmetric
%load('primeLogs_twist.mat'); % Twist
% Twistmove: left twist, right twist, forward bend,
% forward bend w/ left twist, forward bend w/ right twist
load('primeLogs_20120505T105418.mat');
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
log_xhand = []
log_yhand = []
log_vxhand = [];
log_vyhand = [];

%{
for j=1:nJoints
    axis_angles_loc(j,:) = vrrotmat2vec(local_rots(:,:,j));
end
%}

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

%{
q=quiver3(positions(:,1), positions(:,2), positions(:,3), ...
    axis_angles_loc(:,1),axis_angles_loc(:,2),axis_angles_loc(:,3), ...
    'm-','LineWidth',3 );
    %}
    
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
    h_quiver = quiver(0,0, 'k-' );
    set( h_quiver, 'LineWidth', 2,'MarkerSize',10 );
    axis([-1 1 -1 1]);
    
    % Show hand velocities
    figure(3);
    clf;
    h_vxhand = plot(log_vxhand,'ko');
    hold on;
    h_xhand = plot(log_xhand,'r*');
    
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
        positions = positions / 1000;
        rots = jointLog(i).rots;
        confs = jointLog(i).confs;
        %axis_angles_loc = zeros(nJoints,4);
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
        left_hand = [ s2h(3),s2h(1),s2h(2) ];
        
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
        %disp(dframes)
        if( dt>0 )
            filtered_ball = mexBall([left_hand(1),left_hand(3)],dframes);
            %filtered_ball [x y vx vy ep evp]
            xhand = filtered_ball(1);
            yhand = filtered_ball(2);
            vx_hand = filtered_ball(3) * 30; % Per frame to per second
            vy_hand = filtered_ball(4) * 30;
            %{
            fprintf('\nReading\n======\n')
            fprintf('Raw hand: (%.3f, %.3f)\n', left_hand(1), left_hand(3) );
            fprintf('hand @ (%.3f, %.3f) m going at (%.3f %.3f) m/s\n',xhand,yhand,vx_hand,vy_hand);
            %}
            if( vy_hand>1.25 ) 
                disp('left uppercut!');
            elseif( vx_hand>1 ) 
                disp('left punch!');
            end
            log_xhand = [log_xhand xhand];
            log_yhand = [log_yhand yhand];
            log_vxhand = [log_vxhand vx_hand];
            log_vyhand = [log_vyhand vy_hand];
        end
        
        
        %% Control calculations
        %t2sL = positions(indexTorso,:) - positions(indexShoulderL,:);
        %t2sR = positions(indexTorso,:) - positions(indexShoulderR,:);
        sL2sR = positions(indexShoulderL,:) - positions(indexShoulderR,:);
        h2t = positions(indexHead,:) - positions(indexTorso);
        % Care really only about the xz plane
        vx = -1 * h2t(3) / 100;
        vy = -1 * h2t(1) / 100;
        [va,rho] = cart2pol(sL2sR(1),sL2sR(3));
        va = va - pi/2; % to view ok
        set( h_quiver, 'XData', vx, 'YData', vy, ...
            'UData', cos(va), 'VData', sin(va) );
        
        % Only if we have confidence...
        %axis_angles_mag = axis_angles_loc(:,4);
        %axis_angles_loc = axis_angles_loc(:,1:3) .* ...
        %    repmat(axis_angles_loc(:,4),1,3) .* repmat(confs(:,2)~=0,1,3);
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
        %{
    % Update quiver
    axis_angles_loc = axis_angles_loc .* repmat(pc&rc,1,3);
    set(q, 'XData', positions(:,1), ...
        'YData', positions(:,2), ...
        'ZData', positions(:,3), ...
        'UData', axis_angles_loc(:,1), ...
        'VData', axis_angles_loc(:,2), ...
        'WData', axis_angles_loc(:,3) ...
        );
            %}
            
            % Update Velocity plot
            set(h_vxhand,'XData',[1:numel(log_vxhand)]);
            set(h_vxhand,'YData',log_vxhand(:));
            set(h_xhand,'XData',[1:numel(log_xhand)]);
            set(h_xhand,'YData',log_xhand(:));
            
            %% Timing
            tf = toc(tstart);
            % Realistic pause
            pause( max(twait-tf,0) );
            % Arbitrary pause:
            %pause(.2);
    end