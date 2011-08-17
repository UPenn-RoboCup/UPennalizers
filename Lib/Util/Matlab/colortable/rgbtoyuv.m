function [yuv] = rgbtoyuv(rgb);
% [yuv] = rgbtoyuvc(rgb);

ycbcr = rgb2ycbcr(rgb);
ycbcr = permute(ycbcr,[2 1 3]);

y = double(ycbcr(:,:,1));
u = double(ycbcr(:,:,2));
v = double(ycbcr(:,:,3));

yuv = 2^24*y+2^16*u+2^8*v;
