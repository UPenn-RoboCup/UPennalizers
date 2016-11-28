%
% Jordan Brindza
% 06/22/2009
%
% convert_logs
%
% This function will convert all the log files in a given directory into yuyvMontage files
%

function convert_logs(logdir)

[pathList nameList timestampList] = get_log_list(logdir);


for fileIter = 1:length(nameList);

	fprintf('converting log: %s...', pathList(fileIter).name);

	% load the log
	logmat = load(pathList(fileIter).name);
  
  % get the field the images are stored in
  %   will usually be 'camera'
  if (isfield(logmat, 'LOG'))
    if isfield(logmat.LOG,'camera_bot')
      cam = 'camera_bot';
    elseif isfield(logmat.LOG, 'camera_top')
      cam = 'camera_top';
    else
      cam = 'camera';
    end
	
    % create the yuyv montage array
    %   an array of just the image data
%    size(logmat.LOG.(cam)(1).yuyv)
    for i = 1:length(logmat.LOG.(cam))
      yuyvMontage(:,:,1,i) = logmat.LOG.(cam)(i).yuyv;
    end

    % save yuyv array
    if (~strcmp(logdir(end),'/'))
      logdir(end+1) = '/';
    end
    save([logdir 'yuyv' timestampList(fileIter).name], 'yuyvMontage');

    fprintf('done\n');
  else
    fprintf('malformed log file: no LOG field\n');
  end
end

