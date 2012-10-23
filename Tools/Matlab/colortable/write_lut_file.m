function write_lut_file(lut, filename)
% save the LUT to a file

% open file
fid = fopen(filename, 'w');

% write lut to file
fwrite(fid, lut, 'uint8');

% close file
fclose(fid);

