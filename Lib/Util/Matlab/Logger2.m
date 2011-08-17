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
LOG.camera(ilog).imuAngles = CAMERADATA.imuAngles;
LOG.camera(ilog).select = CAMERADATA.select;

if rem(ilog, 100) == 0,
  disp('Saving.....')
  savefile = ['./colortable/log_' datestr(now,30) '.mat'];
  save(savefile, 'LOG');
  disp('Saving done');
  LOG.camera = [];
  ret=0;
end

ret=ilog;
