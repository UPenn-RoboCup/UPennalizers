function yuv = yuyv2yuv(yuyv);
% convert the packed 2-D yuyv format to 3-D YUV
%   yuyv - WxH int32 packed values. each element is y1-u-y2-v packed bytes
%   yuv - HxWx3 uint8 YUV values 


% cast the int32 data as uint8 and split the y1, u, y2, v bytes
siz = size(yuyv);
yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);

% we dont use the y2 values (consider each yuyv element as 1 pixel, not 2)
yuv_u8 = yuyv_u8([1 2 4],:, :, :);

% permute the array so it is WxHx3 (from 3xHxW)
yuv = permute(yuv_u8, [3 2 1 4]);

