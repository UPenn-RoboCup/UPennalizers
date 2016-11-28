clear all;
%% Type of make
plot_data = 0;
save_data = 1;
webots = 1;

if( webots==1 )
    %% Loop through all training data and make training data
    % TODO: make robust - take all existing files...
    %startfile = 500;lastfile  = 727; % Initial training
    %startfile = 728;lastfile  = 743; % See what happened
    %startfile = 277;lastfile  = 743; % New training
    %startfile = 1;lastfile  = 743; % New training
    %startfile = 794;lastfile  = 830; % Training after testing on the robot
    
    %startfile = 900;lastfile  = 1071; % Training after less speed and closer
    %startfile = 900;lastfile  = 1228; % Training after less/more speed and closer
    
    %startfile = 788;lastfile  = 1121; % Better tdata and the fast data (200 trials of each)
    %753-777 is bad
    
    %startfile = 1243;lastfile  = 1597; % Training after less/more speed and closer
    %startfile = 1448;lastfile = 1597; % Training after less/more speed and closer
    %startfile = 1597;lastfile = 1676; % Training after less/more speed and closer
    startfile = 1448;lastfile = 1676; % Training after less/more speed and closer
    
    for trialnum=startfile:lastfile
        
        % Get training data per trial
        form_webots_ml_data;
        
        % Save the Training data
        if( save_data == 1 )
            save_ml( training_data, strcat('training_data_dodge_',num2str( Trial(1) ),'.txt' ) );
        end
        
        % Save the training data for direction
        if( save_data == 1 && sum(hit_range)>0 )
            save_ml( training_data_dir, strcat('training_data_dir_',num2str( Trial(1) ),'.txt' ) );
        end
        
        % Plot our data
        if( plot_data == 1 && trialnum>40  ) % Pre 40 or so, we did not record when we recommended dodge...
            plot_webots_decision;
            pause;
        end
    end
    
else
    startfile = 1;lastfile = 3; % Training after less/more speed and closer
    
    for trialnum=startfile:lastfile
        form_webots_ml_data;
        %range(1:3300) = 0;
        plot_real_decision;
        pause;
    end
end