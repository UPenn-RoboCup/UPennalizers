if ~exist('xMontage'),
  load test_montage.mat
end

cthreshold = 32;
nMontage = size(xMontage,4);

for iMontage = 1:nMontage,

im_rgb = xMontage(:,:,:,iMontage);
im_index = rgb2index(im_rgb);

for iter = 1:5,

subplot(1,2,1)
image(im_rgb);

[xpt, ypt] = ginput(1);
xpt = round(xpt);
ypt = round(ypt);
cpt = im_index(ypt,xpt);

im_select = rgbselect(im_rgb, xpt, ypt, cthreshold);

subplot(1,2,2);
imagesc(im_select);

end

end
