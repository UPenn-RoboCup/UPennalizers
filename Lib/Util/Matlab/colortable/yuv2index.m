function index = yuv2index(im_yuv, nindex);
% convert the YUV colors to the LUT index
%   The index is made up of the concatenated bits of the
%   most significant n bits of the Y, U, and V values

nY = nindex(1);
nU = nindex(2);
nV = nindex(3);

index_y = floor(nY/256*double(im_yuv(:,:,1)));
index_u = floor(nU/256*double(im_yuv(:,:,2)));
index_v = floor(nV/256*double(im_yuv(:,:,3)));

index = 1 + index_v + nV*index_u + nV*nU*index_y;

%{
% alternative algorithm using bitwise operations

% number of bits used per color channel
nY = floor(log(nindex(1))/log(2));
nU = floor(log(nindex(2))/log(2));
nV = floor(log(nindex(3))/log(2));

% shift out unused least sigficant bits
index_y = uint32(bitshift(im_yuv(:, :, 1), nY-8));
index_u = uint32(bitshift(im_yuv(:, :, 2), nU-8));
index_v = uint32(bitshift(im_yuv(:, :, 3), nV-8));

% create index from concatenated bits (YUV)
index = bitor(bitor(bitshift(index_y, nU + nV), bitshift(index_u, nV)), index_v);

% matlab uses 1-based indexing
index = 1 + index;
%}

