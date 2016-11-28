function yuvMontage=load_yuv_montage()
  % open file select gui
  [filename, pathname] = uigetfile('*.mat', 'Select montage file');
  yuvMontage=[];
  if (filename ~= 0)
    % if a file was selected
    s = load([pathname filename]);
    % make sure it has a yuyvMontage
    if (isfield(s, 'yuyvMontage'))
        % convert the yuyv montage to yuv data
      yuvMontage = yuyv2yuv(s.yuyvMontage);
    end
  end
return;
