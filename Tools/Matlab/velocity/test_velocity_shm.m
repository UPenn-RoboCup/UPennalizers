%% Using the ramp webots test file
%% NOTE: mexBall is in Lib/Velocity
if( ~exist('robot','var') )
    startup;
    disp('Creating shm handle!');
    robot = shm_robot(99,2);
end

nsec = 10; % Capture 10 seconds worth of data
loop_fps = 48;
loop_twait = 1/loop_fps;
tLast = 0;
fps = 24;
tFrame = 1/fps;
nFrames = fps*nsec;
log_ball = zeros(nFrames,6); % Log file

% Predict 1 second into the future
future_sec = 1;

%% Set up plot
figure(1);
clf;
h_q = quiver(0,0,0,0,'k','LineWidth',5,'MarkerSize',10);
hold on;
h_ball = plot(0,0,'mo','MarkerSize',16,'MarkerFaceColor','r');
h_pred = plot(0,0,'ko','MarkerSize',16,'MarkerFaceColor','g');
xlim([-1 5]);
ylim([-5 5]);

rhos = [];

%% Loop
i = 1;
while i<nFrames
    loop_tstart=tic;
    m = robot.get_monitor_struct();
    ball = m.ball;
    
    tdiff = ball.t - tLast;
    if( tdiff==0 )
        continue;
    end
    dFrames = floor( tdiff / tFrame ) + 1;
    tLast = ball.t;
    
    %% Calculate
    filtered_ball = mexBall([ball.x,ball.y],dFrames);
    log_ball(i,:) = filtered_ball;
    %filtered_ball [x y vx vy ep evp]
    x = filtered_ball(1);
    y = filtered_ball(2);
    vx = filtered_ball(3);
    vy = filtered_ball(4);
    
    % Update plots
    [theta rho] = cart2pol( vx, vy );
    % Threshold, at spikes when we don't see the ball
    if(rho>0.05)
        continue;
    end
    set( h_q, 'UData', fps*rho*cos(theta), 'VData', fps*rho*sin(theta),...
        'XData',filtered_ball(1),'YData',filtered_ball(2));
    set( h_ball, 'XData', x,'YData', y );
    set( h_pred, 'XData', x+fps*vx*future_sec, ...
        'YData', y+fps*vy*future_sec );
    drawnow;
    i=i+1;
    loop_tf = toc(loop_tstart);
    pause( max(loop_twait-loop_tf,0) );
end