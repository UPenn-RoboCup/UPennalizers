%% Initialize
clear all;
ml_pred_full = [];
predtype = 'ml';
%% Loop
mydirectory = 'logfiles';
%ml is train, test is test
myfiles = dir( sprintf('./%s',mydirectory) );
for i = 1:size(myfiles,1)
    
    if( myfiles(i).isdir==1 )
        continue;
    end
    myfilename = myfiles(i).name;
    if( strcmp(myfilename,'.DS_Store')==1 )
        continue;
    end
    mytype = myfilename(10:11);
    % Grab the direction
    mydirection = 'Unknown dir';
    if(mytype(1)=='l')
        mydirection = 'left';
        mdir = 1;
    elseif(mytype(1)=='c')
        mydirection = 'center';
        mdir = 2;
    elseif(mytype(1)=='r')
        mydirection = 'right';
        mdir = 3;
    end
    % Grab the speed
    myspeed = 'Unknown speed';
    if(mytype(2)=='s')
        myspeed = 'slow';
    elseif(mytype(2)=='f')
        myspeed = 'fast';
    elseif(mytype(2)=='b')
        myspeed = 'bounce';
    elseif(mytype(2)=='t')
        myspeed = 'throw';
    elseif(mytype(2)=='m')
        myspeed = 'miss';
    end
    
    % iterate through the logs...
    import_ball( sprintf('%s/%s',mydirectory,myfilename) );
    
    % Grab measurements from the robot
    my_t_raw = ball_xyz(:,1);
    my_x_raw = ball_xyz(:,2);
    my_y_raw = ball_xyz(:,3);
    my_z = ball_xyz(:,4);
    filtered_x = ball_xyz(:,5);
    filtered_y = ball_xyz(:,6);
    my_vx = ball_xyz(:,7);
    my_vy = ball_xyz(:,8);
    % Adding the uncertainty measurements
    my_ep = ball_xyz(:,9);
    my_evp = ball_xyz(:,10);
    
    %% Find the critical points...
    %crop_n_save;
    figure(20);
    clf;
    subplot(2,1,2);
    title( sprintf('%s from %s',myspeed,mydirection) );
    crop_n_save_user_sel2;
    pause;
    
    % ML Package
    ml_pred_full = [ml_pred_full; pred_full];
    
end

%% Save it all
save_ml(ml_pred_full,sprintf('logfiles/%s_pred_full.txt', predtype) );