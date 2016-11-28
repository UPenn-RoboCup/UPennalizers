function [ ] = save_ml( ml_pred, filename )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

nrows = size( ml_pred, 1 );
ncols = size( ml_pred, 2 );

fprintf('Saving to %s...\n',filename)
fid = fopen( filename, 'w');

for i=1:nrows
    fprintf(fid, '%d ', ml_pred(i,ncols) );
    for j=1:ncols-1
        fprintf(fid, '%d:%f ', j, ml_pred(i,j) );
    end
    fprintf(fid,'\n');
end

fclose(fid);
fprintf('Done saving...\n')

end

