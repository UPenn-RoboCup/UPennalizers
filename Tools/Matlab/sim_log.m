function sim_log(strtop, strbtm, teamNumber, playerID)
% simulate the robot state from the log file data
  if (nargin < 3)
    teamNumber = 1;
  end
  if (nargin < 4)
    playerID = 1;
  end
  disp ('initializing...')
  r = shm_robot_nao(teamNumber, playerID);

  % set yuyv_type to full size images
  r.vcmCamera.set_yuyvType(1); 
  r.vcmCamera.set_broadcast(1);
  % check that the image size from the log is correct
  ind = 0;  
 
  LOGtop = load(strcat('logs/', strtop));
  LOGbtm = load(strcat('logs/', strbtm));
  
  LOG = LOGtop.LOG; 
  yuyvMontage = {};
  yuyvMontage{1} = LOGtop.yuyvMontage;
  yuyvMontage{2} = LOGbtm.yuyvMontage;

  function go_through ()
    disp ('started');
    while (ind < length(LOG) )
      ind = ind + 1;
      show_image ();  
      stop = getch();
      if (stop == 'p')
        break;
      end
    end
    disp ('stopped');
  end

  function show_image ()
    fprintf('log update %d\n', ind);

    % extract log struct from cell array
    l = LOG{ind};

    % store image in shared memory
    % TODO: this must be the full size
    r.set_yuyv(yuyvMontage{1}(:,:,:,ind),1);
    r.set_yuyv(yuyvMontage{2}(:,:,:,ind),2);


    % store camera status info
    r.vcmImagetop.set_width(l.camera.width);
    r.vcmImagetop.set_height(l.camera.height);
    r.vcmImagetop.set_headAngles(l.camera.headAngles);
    r.vcmImagetop.set_time(time());
  

    % frame number must be the updated after everything is set or you will
    %   end up with race conditions with the vision code
    % use loop index as frame number since it is not stored
    r.vcmImagetop.set_count(ind);
    r.vcmImagebtm.set_count(ind);

    % pause to let vision update
    pause(1);
  end

  disp ('press "+" to see the next frame')
  disp ('press "-" to see the previous frame')
  disp ('press "p" to go through all frames, press "p" again to stop')

 
  while (1)    
    str = getch();
    if (str == 'p')
      go_through();
    end

    if (str == '+')
      if (ind < length(LOG))
        ind = ind + 1;
      end
      show_image();
    end

    if (str == '-')
      if (ind == 0)
        ind = 1;
      end
      if (ind > 1)
        ind = ind - 1;
      end
      show_image();
    end
  end
end
