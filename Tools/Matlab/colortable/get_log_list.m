function [pathList, nameList, timestampList] = get_log_list(logdir)
% returns the names of all log files the given directory

if(~exist(logdir, 'dir'))
	error('Directory does not exist.');
end

% get contents of the given directory
dirList = dir(logdir);

% init return variables
pathList       = [];
nameList       = [];
timestampList = [];

storeIter = 1;

for fileIter = 1:size(dirList,1)

	fileName = dirList(fileIter).name;

	% if it is not ., .., or a directory
	if(~strcmp(fileName, '.') & ~strcmp(fileName, '..') & ~dirList(fileIter).isdir)

		[pathString name ext] = fileparts(fileName);
		
		% check the extension is .mat and the name starts with log
		if(strcmp(ext,'.mat') && strcmp(name(1:3),'log'))
			pathList(storeIter).name = fullfile(logdir, fileName);
			nameList(storeIter).name = fileName;
			timestampList(storeIter).name = fileName(4:end-length(ext));
			storeIter = storeIter + 1;
		end
		
	end
end

