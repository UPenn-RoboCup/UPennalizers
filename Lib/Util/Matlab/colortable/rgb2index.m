function index = rgb2index(im_rgb, nindex);

nY = nindex(1);
nU = nindex(2);
nV = nindex(3);

im_yuv = rgb2ycbcr(im_rgb);

index_y = floor(nY/256*double(im_yuv(:,:,1)));
index_u = floor(nU/256*double(im_yuv(:,:,2)));
index_v = floor(nV/256*double(im_yuv(:,:,3)));

index = 1 + index_y + nY*index_u + nY*nU*index_v;

