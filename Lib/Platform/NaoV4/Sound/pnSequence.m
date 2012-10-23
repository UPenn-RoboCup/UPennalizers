fs = 16000;
nSequence = 512;
nSkip = 8;

rand('state',0);
yc = 2*rand(nSequence,1)-1;

%yScale = 32768/nSequence;
yScale = 32768;
y = round(yScale*yc);
%y = int16(y);

fid = fopen('pnSequence.h','w');
fprintf(fid,'const short pnSequence[%d] = {\n', nSequence);
for i = nSkip:nSkip:nSequence,
  fprintf(fid,' %6d,',y(i-nSkip+1:i-1));
  if (i ~= nSequence),
    fprintf(fid,' %6d,\n',y(i));
  else
    fprintf(fid,' %6d\n};\n',y(i));
  end
end

fclose(fid);

% save sequence as mat file also
save('pnSequence.mat', 'y');

