function yuv=yuyv2yuv(yuyv);

siz = size(yuyv);
yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);
yuv_u8 = yuyv_u8([1 2 4],:, :, :);
yuv = permute(yuv_u8,[3 2 1 4]);
