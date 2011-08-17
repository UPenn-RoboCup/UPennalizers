global LOG

%for i = 1:length(LOG.camera),
%  yuyvMontage(:,:,1,i) = LOG.camera(i).yuyv;
%end

if isfield(LOG,'camera_bot')
   cam = 'camera_bot';
elseif isfield(LOG, 'camera_top')
   cam = 'camera_top';
else
   cam = 'camera';
end
   
for i = 1:length(LOG.(cam))
   yuyvMontage(:,:,1,i) = LOG.(cam)(i).yuyv;
end
