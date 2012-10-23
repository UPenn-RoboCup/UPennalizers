function h=logger()
  %SJ: generate two separate files, yuyvMontage and LOG
  %Now we directly generate yuyv files, so no need for convert

  global LOGGER LOG yuyvMontage;  
  h.init=@init;
  h.log_data=@log_data;
  h.save_log=@save_log;

  function init()
    yuyvMontage=uint32([]);
    LOG={};
    LOGGER.logging = 0;
    LOGGER.log_count=0;
  end

  function log_data(yuyv,r_mon)
    LOGGER.log_count=LOGGER.log_count+1;
    yuyvMontage(:,:,1,LOGGER.log_count)=yuyv;
    LOG{LOGGER.log_count}=r_mon;
  end

  function save_log()
    %We still use the file name yuyv_xxxx
    %But now we store every log there as well
    if ~ exist('./logs','dir')
      mkdir('./logs');
    end
    savefile1 = ['./logs/yuyv_' datestr(now,30) '.mat'];
    fprintf('\nSaving yuyv file: %s...', savefile1)
    save(savefile1, 'yuyvMontage', 'LOG');
    init();
    disp('Done')
  end

end
  

