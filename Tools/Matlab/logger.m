function h=logger()
  %SJ: generate two separate files, yuyvMontage and LOG
  %Now we directly generate yuyv files, so no need for convert
  %Dickens: modified to work with parallel image
  %log both cameras at the same time but save seperately
  global LOGGER LOG yuyvMontagetop yuyvMontagebtm;  
  h.init=@init;
  h.log_data=@log_data;
  h.save_log=@save_log;

  function init()
    yuyvMontagetop=uint32([]);
    yuyvMontagebtm=uint32([]);
    LOG={};
    LOGGER.logging = 0;
    LOGGER.log_count=0;
  end

  function log_data(yuyvtop,yuyvbtm,r_mon)
    LOGGER.log_count=LOGGER.log_count+1;
    yuyvMontagetop(:,:,1,LOGGER.log_count)=yuyvtop;
    yuyvMontagebtm(:,:,1,LOGGER.log_count)=yuyvbtm;
    LOG{LOGGER.log_count}=r_mon;
  end

  function save_log()
    %We still use the file name yuyv_xxxx
    %But now we store every log there as well
    if ~ exist('./logs','dir')
      mkdir('./logs');
    end
    %colortable only recognize keyword "yuyvMontage"
    yuyvMontage = yuyvMontagetop;
    savefile1 = ['./logs/yuyv_top_' datestr(now,30) '.mat'];
    fprintf('\nSaving yuyv file: %s...', savefile1)
    save(savefile1, 'yuyvMontage', 'LOG');
    
    yuyvMontage = yuyvMontagebtm;
    savefile2 = ['./logs/yuyv_bottom_' datestr(now,30) '.mat'];
    fprintf('\nSaving yuyv file: %s...', savefile2)
    save(savefile2, 'yuyvMontage', 'LOG');

    init();
    disp('Done')
  end

end
  

