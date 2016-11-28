function log2lua(skel_logfile)

L = load( skel_logfile );

% Replace the file extension if given with .mat
skel_logfile_lua = strrep(skel_logfile, '.mat', '.lua');

% Add extension if none given
if(strcmp(skel_logfile_lua,skel_logfile))
    skel_logfile_lua = strcat(skel_logfile_lua,'.lua');
end
fid = fopen( skel_logfile_lua,'w');

fprintf(fid,'log={\n');
for i=1:numel(L.LOG)
    entry = L.LOG{i};
    if( isempty(entry.positions) )
        break;
    end
    fprintf(fid,'{t=%f,',entry.t);
    fprintf(fid,'x={');
    fprintf(fid,'%f,',entry.positions(:,1));
    fprintf(fid,'},');
    fprintf(fid,'y={');
    fprintf(fid,'%f,',entry.positions(:,2));
    fprintf(fid,'},');
    fprintf(fid,'z={');
    fprintf(fid,'%f,',entry.positions(:,3));
    fprintf(fid,'},');
    % Confidence
    fprintf(fid,'posconf={');
    fprintf(fid,'%f,',entry.confs(:,1));
    fprintf(fid,'},');
    fprintf(fid,'rotconf={');
    fprintf(fid,'%f,',entry.confs(:,2));
    fprintf(fid,'},');
    % End
    fprintf(fid,'},\n');
end
fprintf(fid,'}');

fclose(fid);

end