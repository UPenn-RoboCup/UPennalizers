function h=SkeletonLogger()
% Steve: generate two separate files, LOG and lualog
% Now we directly generate lua files, so no need to convert

global SKLOGGER LOG;
h.init=@init;
h.log_data=@log_data;
h.save_log=@save_log;

    function init()
        LOG={};
        SKLOGGER.logging = 0;
        SKLOGGER.log_count=0;
    end

    function log_data(sk_data)
        SKLOGGER.log_count=SKLOGGER.log_count+1;
        LOG{SKLOGGER.log_count}=sk_data;
    end

    function save_log()
        % Check if the logging directory exists
        if ~ exist('./logs','dir')
            % Create it if not
            mkdir('./logs');
        end
        savefile1 = ['./logs/skel_' datestr(now,30) '.mat'];
        fprintf('\nSaving matlab log: %s...', savefile1)
        save(savefile1,'LOG');
        % Generate the lua file
        fprintf('\nSaving lua keyframe...\n')
        log2lua(savefile1)
        % Reinitialize Variables for next Logging session
        init();
        disp('Done');
    end

end
