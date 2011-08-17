function ret=Logger

global CAMERADATA
global LOG

if isempty(LOG),
  LOG.camera = [];
end

ilog = length(LOG.camera) + 1;
LOG.camera(ilog).time = ilog;%time;
LOG.camera(ilog).yuyv = CAMERADATA.yuyv + 0;
LOG.camera(ilog).headAngles = CAMERADATA.headAngles;
%LOG.camera(ilog).imuAngles = CAMERADATA.imuAngles;
LOG.camera(ilog).select = CAMERADATA.select;

%by sj - prepare for saving log file
if rem(ilog,5)==0
  ilog
end

if rem(ilog,100)==99
  ret=2;
elseif rem(ilog, 100) == 0,
  disp('Saving.....')
  savefile = ['/tmp/log_' datestr(now,30) '.mat'];
  save(savefile, 'LOG');
  disp('saved file');
  LOG.camera = [];
  ret=0;
else
    ret=1;
end
