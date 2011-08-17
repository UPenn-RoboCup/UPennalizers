function index = yuv2index(im_yuv, nindex);

nY = nindex(1);
nU = nindex(2);
nV = nindex(3);

index_y = floor(nY/256*double(im_yuv(:,:,1)));
index_u = floor(nU/256*double(im_yuv(:,:,2)));
index_v = floor(nV/256*double(im_yuv(:,:,3)));

%index = 1 + index_y + nY*index_u + nY*nU*index_v;
index = 1 + index_v + nV*index_u + nV*nU*index_y;
