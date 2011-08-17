if ~exist('xMontage'),
  load ../Test/test_montage.mat
end

hspace = 8;
hcolor = 16;
cthreshold = 16;

im_rgb = xMontage(:,:,:,2);
im_mean(:,:,1) = mean_shift(im_rgb(:,:,1),hspace,hcolor);
im_mean(:,:,2) = mean_shift(im_rgb(:,:,2),hspace,hcolor);
im_mean(:,:,3) = mean_shift(im_rgb(:,:,3),hspace,hcolor);
im_mean = im_rgb;


subplot(1,2,1)
image(im_rgb);

for iter = 1:100,

[ptx, pty] = ginput(1);
ptx = round(ptx);
pty = round(pty);
ptrgb = double(im_mean(pty,ptx,:));

im_match = abs(double(im_mean(:,:,1))-ptrgb(1)) < cthreshold & ...
  abs(double(im_mean(:,:,2))-ptrgb(2)) < cthreshold & ...
  abs(double(im_mean(:,:,3))-ptrgb(3)) < cthreshold;
im_select = bwselect(im_match, ptx, pty);

bounds = bwboundaries(im_select);
b1 = bounds{1};

subplot(1,2,2);
imagesc(im_select);

subplot(1,2,1);
hold on
plot(b1(:,2), b1(:,1), 'g', 'linewidth', 2);
hold off

end
