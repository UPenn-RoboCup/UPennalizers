% convert_logs('.'); colortable;

function runner( name )
colortable_smear;
lut = colortable_lut();
lut_montage(lut);
write_lut_file( lut, sprintf('lut_%s.raw',name) );
end
