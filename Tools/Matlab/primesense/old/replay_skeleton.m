%% Plot the skeleton
%clear all;
if( exist('sk','var') == 0 )
    startup;
    sk = shm_primesense(0,1);
end

load('primeLogs_calibrate.mat');
% Key Points
% 123 (Field goal no good)
% 200 (Field goal is good)
set_shm = 1;
debug = 1;
infloop = 1; % Loop the logs infinitely

nLogs = numel(jointLog);
nJoints = numel(jointNames);
positions = jointLog(1).positions;
rots = jointLog(1).rots;
confs = jointLog(1).confs;
indexWaist = find(ismember(jointNames, 'Waist')==1);

% For IK testing
indexShoulder = find(ismember(jointNames, 'ShoulderL')==1);
indexElbow = find(ismember(jointNames, 'ElbowL')==1);
indexHand = find(ismember(jointNames, 'HandL')==1);

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

%p_right=plot3( positions(ri,1), positions(ri,2), positions(ri,3),'o', ...
%    'MarkerEdgeColor','k', 'MarkerFaceColor', 'g', 'MarkerSize',10 );
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

while(1)
    
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
        positions = jointLog(i).positions;
        rots = jointLog(i).rots;
        confs = jointLog(i).confs;
        jtime = jointLog(i).t;
        if( set_shm==1 )
            for j=1:nJoints
                tmp.t = jtime;
                tmp.position = positions(j,:);
                tmp.rot = rots(:,:,j);
                tmp.confidence = confs(j,:);
                sk.set_joint( jointNames{j}, tmp );
            end
        end
        
        %% Update Figure
        positions = positions - repmat(jointLog(i).positions(indexWaist,:), nJoints,1);
        positions = positions / 1000;
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
        %{
        set(p_right, 'XData', positions( ri, 1), ...
            'YData', positions( ri, 2), ...
            'ZData', positions( ri, 3));
            %}
        set(p_center, 'XData', positions( ci, 1), ...
            'YData', positions( ci, 2), ...
            'ZData', positions( ci, 3));
        drawnow;
        title(i);
        if( debug == 1)
            dArm = positions(indexHand,:) - positions(indexShoulder,:);
            s2e  = sqrt( sum( (positions(indexShoulder,:) - positions(indexElbow,:)).^2) );
            e2h  = sqrt( sum( (positions(indexElbow,:)    - positions(indexHand,: )).^2) );
            dArm = dArm/(s2e+e2h) * (1+1); % upper/lower lengths
            dArmOP_frame = [-1*dArm(3), -1*dArm(1), dArm(2)];
            qArm = kine_map( dArmOP_frame );
            title(qArm);
        end
        
        %% Timing
        %[ i tf max(twait-tf,0)]
        tf = toc(tstart);
        % Realistic pause
        pause( max(twait-tf,0) );
        % Arbitrary pause:
        %pause(.2);
    end
    
    if(infloop==0)
        break;
    end
    
end