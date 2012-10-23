function label = raw2label(raw, width, height)
% converts the raw data matrix to labeled image format
rawu8 = typecast(raw(:), 'uint8');
label = reshape(rawu8(1:width*height), [width, height]);

