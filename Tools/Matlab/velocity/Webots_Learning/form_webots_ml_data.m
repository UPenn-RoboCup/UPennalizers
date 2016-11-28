importfile( trialnum, webots );

%% Modify and add data

%% Observational truth
% Get the distance
obs_r = sqrt(obs_x.^2 + obs_y.^2);
% Absolute knowledge for learning
obs_vr = sqrt(obs_vx.^2 + obs_vy.^2);
% Get the velocity angle
obs_vth = atan2( obs_vy, obs_vx );
obs_th = atan2( obs_y, obs_x );
% Perform mod_angle
obs_th = mod_angle( obs_th ) * 180/pi;
obs_vth = mod_angle( obs_vth ) * 180/pi;
% Add predicted position (1 second in future)
obs_px = obs_x + obs_vx * 1;
obs_py = obs_y + obs_vy * 1;
obs_pr = sqrt(obs_px.^2 + obs_py.^2);
obs_pth = atan2( obs_py, obs_px );
obs_pth = mod_angle( obs_pth ) * 180/pi;

if( webots==0 )
    range = true( size(obs_time) );
    range = range & obs_detect==1;
    obs_time = obs_time - obs_time(1); 
    return;
end

%% Absolute Truth
% Add the ep and evp
abs_ep = obs_ep;
abs_evp = obs_evp;
% mirroring
abs_vy = abs_vy * -1;
abs_y = abs_y * -1;
% Get the distance
abs_r = sqrt(abs_x.^2 + abs_y.^2);
% Absolute knowledge for learning
abs_vr = sqrt(abs_vx.^2 + abs_vy.^2);
% Get the velocity angle
abs_vth = atan2( abs_vy, abs_vx );
abs_th = atan2( abs_y, abs_x );
% Perform mod_angle
abs_th = mod_angle( abs_th ) * 180/pi;
abs_vth = mod_angle( abs_vth ) * 180/pi;
% Add predicted position (1 second in future)
abs_px = abs_x + abs_vx * 1;
abs_py = abs_y + abs_vy * 1;
abs_pr = sqrt(abs_px.^2 + abs_py.^2);
abs_pth = atan2( abs_py, abs_px );
abs_pth = mod_angle( abs_pth ) * 180/pi;

%% Valid for learning
range = (obs_stillTime>1.5);
range = range & (abs_x>0);
% Ball is moving
range = range & (abs_vr>0.01); % The ball is moving
range = range & (abs_count>150); % A little dead time
range = range & (obs_detect>0); % We detect the ball

% Remove a few points just after the ball is moving
range = range & (abs_r<2.5); % The ball is moving
%{
range_tmp = range( range );
range_tmp(1:10) = 0;
range( range ) = range_tmp;
%}


%% Mark the data as "Hit Data" or "Miss Data"
%% Assign "Dodge Left" or "Dodge Right"

if( Trial(2)==1 ) % There was a hit
    % Modify the range to be only those points before the hit
    range = range & (abs_count<Trial(3));
    % Remove a few points before getting hit
    range_tmp = range( range );
    range_tmp(end-4:end) = 0;
    range( range ) = range_tmp;
    
    % Should we only dodge the points immediately before being hit, or all
    % of the points?
    % When do we decide to doddge?  .5 seconds before getting hit and never
    % after getting hit
    % Make a one second reaction time?
    DECISION_TIME = 1.5 / 0.04; % 0.04 seconds per count.
    hit_range1 = range & (Trial(3)-abs_count<DECISION_TIME) & (Trial(3)-abs_count>=0);
    %hit_range = true( size(range) ); % All points
    %hit_range(1:10) = 0; % First 10 points don't dount    
    %hit_range = range & (abs_r<.5 | hit_range1);
    hit_range = range & abs_pr<.25;
    
    miss_range  = false( size(range) ) ; % No hits
    
    % Set the direction to dodge
    dodge_dir = abs_y( Trial(3) ) / abs( abs_y( Trial(3) ) );
    
else
    
    % Remove a few points before the end
    range_tmp = range( range );
    range_tmp(end-10:end) = 0;
    range( range ) = range_tmp;
    
    hit_range  = false( size(range) ) ; % No hits
    miss_range = true( size(range) ); % Al points

    % Set the direction to dodge
    dodge_dir = abs_y( end ) / abs( abs_y( end ) );
    
end

fprintf( 'dodge dir: %d\n', dodge_dir );
hit_range = range & abs_pr<.25;
miss_range = ~hit_range & range;

if( dodge_dir==-1 )
    dodge_dir = 0;
end

%training_data = [obs_x(range) obs_y(range) obs_vx(range) obs_vy(range) obs_ep(range) obs_evp(range) obs_r(range) obs_vr(range) hit_range(range)];
%training_data = [obs_x(range) obs_y(range) obs_vx(range) obs_vy(range) obs_ep(range) obs_evp(range) obs_th(range) obs_vth(range) obs_r(range) obs_vr(range) obs_px(range) obs_py(range) obs_pr(range) obs_pth(range) hit_range(range)];
%training_data = [abs_x(range) abs_y(range) abs_vx(range) abs_vy(range) abs_ep(range) abs_evp(range) abs_th(range) abs_vth(range) abs_r(range) abs_vr(range) abs_px(range) abs_py(range) abs_pr(range) abs_pth(range) hit_range(range)];
%training_data = [abs_ep(range) abs_evp(range) abs_th(range) abs_px(range) abs_py(range) abs_pr(range) abs_pth(range) hit_range(range)];
%prediction = obs_px<.3 & obs_py<.1;
%training_data = [obs_ep(range) obs_evp(range) obs_th(range) obs_px(range) obs_py(range) obs_pr(range) obs_pth(range) hit_range(range)];
training_data = [obs_ep(range) obs_evp(range) obs_th(range) obs_pr(range) obs_pth(range) hit_range(range)];

%% For Learning the direction
% ONly use the hit range
th_diff = 180/pi*mod_angle( pi/180*(abs_pth - abs_th) );
%training_data_dir = [obs_ep(hit_range) obs_evp(hit_range) obs_th(hit_range) obs_pr(hit_range) obs_pth(hit_range) th_diff(hit_range) hit_range(hit_range)*0+dodge_dir];
training_data_dir = [obs_x(hit_range) obs_y(hit_range) obs_vx(hit_range) obs_vy(hit_range) obs_ep(hit_range) obs_evp(hit_range) obs_th(hit_range) obs_vth(hit_range) obs_r(hit_range) obs_vr(hit_range) obs_px(hit_range) obs_py(hit_range) obs_pr(hit_range) obs_pth(hit_range) th_diff(hit_range) hit_range(hit_range)*0+dodge_dir];