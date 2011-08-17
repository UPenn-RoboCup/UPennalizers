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

	% load the log
	load(pathList(fileIter).name);

	fprintf('converting log: %s...', pathList(fileIter).name);
	
	% convert to yuyv
	log2yuyv;
	
	% save yuyv
	if (~strcmp(logdir(end),'/'))
		logdir(end+1) = '/';
	end
	
	save([logdir 'yuyv' timestampList(fileIter).name], 'yuyvMontage');
	
	fprintf('done\n');

end
