function yuyv = raw2yuyv(raw, width, height)
% converts the raw data matrix to yuyv format
yuyv = reshape(typecast(raw(:), 'uint32'), [width, height]);

