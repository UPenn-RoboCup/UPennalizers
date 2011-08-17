function write_lut_file(lut, filename)


% open file
fid = fopen(filename, 'w');

% write lut to file
fwrite(fid, lut, 'uint8');

% close file
fclose(fid);
