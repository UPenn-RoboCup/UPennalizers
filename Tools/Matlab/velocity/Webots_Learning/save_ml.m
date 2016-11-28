function [ ] = save_ml( ml_data, filename )

nrows = size( ml_data, 1 );
ncols = size( ml_data, 2 );

fprintf('Saving to %s...\n',filename);
fid = fopen( filename, 'w');

for i=1:nrows
    % Write the class of the datum
    fprintf(fid, '%d ', ml_data(i,ncols) );
    % Write the (parameter number):(observed value of parameter) of the datum
    for j=1:ncols-1
        fprintf(fid, '%d:%f ', j, ml_data(i,j) );
    end
    fprintf(fid,'\n');
end

fclose(fid);
fprintf('Done saving...\n')

end

