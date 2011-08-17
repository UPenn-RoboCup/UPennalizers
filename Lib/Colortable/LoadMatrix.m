function x = LoadMatrix(filename)

magic = uint8(['LUA MAT' 0]);

fid = fopen(filename,'r','ieee-le');

filemagic = fread(fid, length(magic), '*uint8');
classID = fread(fid, 1, 'int32');
%disp(sprintf('LoadMatrix: classID = %d',classID));
switch classID
 case 6,
  xclass = '*double';
 case 9,
  xclass = '*uint8';
 case 12,
  xclass = '*int32';
 case 13,
  xclass = '*uint32';
 otherwise,
  error('Unknown classID');
end

bytesElement = fread(fid, 1, 'int32');
m = fread(fid, 1, 'int32');
n = fread(fid, 1, 'int32');

x = fread(fid, [m n], xclass);
fclose(fid);
