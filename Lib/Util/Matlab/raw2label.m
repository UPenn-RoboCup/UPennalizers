function label = raw2label(raw, width, height);
% converts the raw data matrix to labeled image format

label = reshape(typecast(raw(:), 'uint8'), [width, height]);

