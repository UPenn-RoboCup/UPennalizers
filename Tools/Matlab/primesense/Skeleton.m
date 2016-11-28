function t_passed = Skeleton(varargin)

global SKLOGGER LOG jointNames players

%% Check if running from a log file
%% Run Skeleton('l') to run from a LOG
%% load the log into the workspace
%fprintf('Number of arguments: %d\n',nargin);
%celldisp(varargin);
run_from_log = 0;
if( find([varargin{:}]=='l') )
    run_from_log = 1;
    disp('Running from Logs!');
else
    disp('Running Live!');
end

%% Initialize variables
jointNames = { ...
    'Head', 'Neck', 'Torso', 'Waist', ...
    'CollarL','ShoulderL', 'ElbowL', 'WristL', 'HandL', 'FingerL', ...
    'CollarR','ShoulderR', 'ElbowR', 'WristR', 'HandR', 'FingerR', ...
    'HipL', 'KneeL', 'AnkleL', 'FootL', ...
    'HipR', 'KneeR', 'AnkleR', 'FootR'...
    };
nJoints = numel(jointNames);

nPlayers =1; %2;
if( run_from_log )
    nPlayers = 1;
end

if ~( exist('players','var') && numel( players )>=nPlayers )
    players = cell(nPlayers,1);
    for pl=1:nPlayers
        players{pl}.positions = zeros(nJoints,3);
        players{pl}.rots = zeros(3,3,nJoints);
        players{pl}.confs = zeros(nJoints,2);
    end
end

%% Access SHM quickly
if( ~isfield( players{1},'sk' ) && ~run_from_log )
    disp('Recreating SHM block access...')
    startup;
    team = 18;
    for pl=1:nPlayers
        players{pl}.sk = shm_primesense(team,pl);
    end
end

%% Recording Logs
logging = 0; % Off to start
if( ~run_from_log )
    SKLOGGER=SkeletonLogger();
    SKLOGGER.init();
    sk_data = [];
end

%% Timing settings
%fps = 30;
fps = 60;
twait = 1/fps;

%% Other plots
rotation = 0;
use_3d = 0;

%% Joint Settings
% Set up indexing
left_idx   = zeros(nJoints,1);
right_idx  = zeros(nJoints,1);
center_idx = zeros(nJoints,1);
left_idx([5:10 17:20]) = 1;
right_idx([11:16 21:24]) = 1;
center_idx([1:4]) = 1;

%% Figure
hfig = figure(1);
clf;
% Add key press actions
set(hfig,'KeyPressFcn',@KeyResponse);

    function init_skel(is_3d)
        clf;
        if(is_3d~=1)
            for pll=1:nPlayers
                positions = players{pll}.positions;
                confs = players{pll}.confs;
                players{pll}.p_left=plot( positions(:,1), positions(:,2), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'r', 'MarkerSize',10 );
                hold on;
                players{pll}.p_right=plot( positions(:,1), positions(:,2), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'g', 'MarkerSize',10 );
                players{pll}.p_center=plot( positions(:,1), positions(:,2), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'b', 'MarkerSize',10 );
            end
            axis([-1 1 -1.25 1.25]);
        else
            for pll=1:nPlayers
                positions = players{pll}.positions;
                confs = players{pll}.confs;
                players{pll}.p_left=plot3( positions(:,1), positions(:,2),positions(:,3), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'r', 'MarkerSize',10 );
                hold on;
                players{pll}.p_right=plot3( positions(:,1), positions(:,2),positions(:,3), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'g', 'MarkerSize',10 );
                players{pll}.p_center=plot3( positions(:,1), positions(:,2),positions(:,3), 'o', ...
                    'MarkerEdgeColor','k', 'MarkerFaceColor', 'b', 'MarkerSize',10 );
            end
            axis([-1 1 -1.25 1.25 0 4]);
        end
        
    end
init_skel(use_3d);

%% Keypress Actions
    function KeyResponse(~, evt)
        key = lower(evt.Key);
        if key=='l'
            % No toggling either, if running from logs
            if ~run_from_log
                logging=1-logging;
                if( logging==1 )
                    fprintf('Logging: ON\n')
                else
                    fprintf('Logging: OFF\n')
                end
            end
            % Plot the rotation matrix
        elseif key=='r'
            rotation = 1-rotation;
            if( rotation==1 )
                fprintf('Rotation: ON\n')
            else
                init_skel(use_3d);
                fprintf('Rotation: OFF\n')
            end
        elseif key=='3'
            use_3d = 1-use_3d;
            if( use_3d==1 )
                init_skel(use_3d);
                fprintf('3D: ON\n');
            else
                init_skel(use_3d);
                fprintf('3D: OFF\n');
            end
        end
    end

%% Go time
t0=tic;
while( 1 )
    tstart=tic;
    %% Loop through each joint
    if( ~run_from_log )
        for pl=1:nPlayers
            sk = players{pl}.sk;
            for j=1:nJoints
                jName = jointNames{j};
                joint = sk.get_joint( jName );
                players{pl}.positions(j,:) = joint.position;
                players{pl}.rots(:,:,j) = joint.rot;
                players{pl}.confs(j,:) = joint.confidence;
            end
        end
    else
        % Grab data from log file source
        if( ~exist('counter','var') )
            counter = 0;
            logsz = numel(LOG);
        end
        counter = counter+1;
        if(counter>logsz)
            return;
        end
        players{1}.positions = LOG{counter}.positions;
        players{1}.rots = LOG{counter}.rots;
        players{1}.confs = LOG{counter}.confs;
        % Address log file timing concerns
        if(counter+1>logsz)
            twait = 0;
        else
            twait = LOG{counter+1}.t-LOG{counter}.t;
        end
    end
    
    %% Plot the data
    % Do not display while logging, so as to get 30fps
    if(~rotation && ~logging)
        for pl=1:nPlayers
            positions = players{pl}.positions;
            confs = players{pl}.confs;
            p_left = players{pl}.p_left;
            p_right = players{pl}.p_right;
            p_center = players{pl}.p_center;
            set(p_left,   'XData', positions( left_idx&confs(:,1)>0,   1));
            set(p_left,   'YData', positions( left_idx&confs(:,1)>0,   2));
            set(p_left,   'ZData', positions( left_idx&confs(:,1)>0,   3));
            
            set(p_right,  'XData', positions( right_idx&confs(:,1)>0,  1));
            set(p_right,  'YData', positions( right_idx&confs(:,1)>0,  2));
            set(p_right,  'ZData', positions( right_idx&confs(:,1)>0,  3));
            
            set(p_center, 'XData', positions( center_idx&confs(:,1)>0, 1));
            set(p_center, 'YData', positions( center_idx&confs(:,1)>0, 2));
            set(p_center, 'ZData', positions( center_idx&confs(:,1)>0, 3));
        end
    end
    
    %% Show Rotation Matrix
    if(rotation && ~logging)
        pl = 1;
        [roll pitch yaw] = show_rotation(pl);
        players{pl}.roll = roll;
        players{pl}.pitch = pitch;
        players{pl}.yaw = yaw;
        
    end
    %% Execute Logging
    if( logging && ~run_from_log )
        sk_data.t = joint.t;
        sk_data.positions = positions;
        sk_data.rots = rots;
        sk_data.confs = confs;
        SKLOGGER.log_data(sk_data)
        % Save the Log after 10 seconds
        if SKLOGGER.log_count==10*fps
            SKLOGGER.save_log();
        end
    end
    
    %% Execute Timing
    %if(~logging)
    drawnow; % We don't lose that much time with this
    %end
    tf = toc(tstart);
    pause( max(twait-tf,0) );
    
end

%% Return how long we have been watching live PrimeSense
t_passed=toc(t0);

end