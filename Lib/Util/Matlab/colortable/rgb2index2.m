function index = rgb2index2(im_rgb, nindex);

nY = nindex(1);
nYbits = log2(nY);
nU = nindex(2);
nUbits = log2(nU);
nV = nindex(3);
nVbits = log2(nV);

im_yuv = rgb2ycbcr(im_rgb);

index_y = bitshift(uint32(im_yuv(:,:,1)), -(8-nYbits));
index_u = bitshift(uint32(im_yuv(:,:,2)), -(8-nUbits));
index_v = bitshift(uint32(im_yuv(:,:,3)), -(8-nVbits));

index_yu = bitor(index_y, bitshift(index_u,nYbits));
index = bitor(index_yu, bitshift(index_v,nYbits+nUbits));

index = index + 1;
