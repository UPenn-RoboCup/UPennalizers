function y = SaveMatrix(filename, x)

magic = uint8(['LUA MAT' 0]);

xsize = size(x);
m = xsize(1);
n = prod(xsize(2:end));
xclass = class(x);

if strcmp(xclass, 'double'),
  classID = 6;
  bytesElement = 8;
elseif strcmp(xclass, 'uint8'),
  classID = 9;
  bytesElement = 1;
elseif strcmp(xclass, 'int32'),
  classID = 12;
  bytesElement = 4;
elseif strcmp(xclass, 'uint32'),
  classID = 13;
  bytesElement = 4;
else
  classID = 6;
  bytesElement = 8;
end

y = 0;

fid = fopen(filename,'w','ieee-le');

y = y+fwrite(fid, magic, 'uint8');
y = y+fwrite(fid, classID, 'int32');
y = y+fwrite(fid, bytesElement, 'int32');
y = y+fwrite(fid, m, 'int32');
y = y+fwrite(fid, n, 'int32');
y = y+fwrite(fid, x, xclass);

fclose(fid);
