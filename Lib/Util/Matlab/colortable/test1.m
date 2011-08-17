if ~exist('xMontage'),
  load test_montage.mat
end

im_rgb = xMontage(:,:,:,2);
im_index = rgb2index(im_rgb);
im_gray = rgb2gray(im_rgb);
im_edge = edge(im_gray,'zerocross',0);

subplot(1,2,1)
image(im_rgb);

[xpt, ypt] = ginput(1);
xpt = round(xpt);
ypt = round(ypt);
cpt = im_index(ypt,xpt);

im_match = (im_index == cpt);
%im_select = bwselect(im_match, xpt, ypt);
im_select = imfill(im_edge,[xpt ypt]);

bounds = bwboundaries(im_select);
b1 = bounds{1};

subplot(1,2,2);
imagesc(im_select);
return


imagesc(im_select);
hold on
plot(b1(:,2), b1(:,1), 'g', 'linewidth', 2);
hold off
