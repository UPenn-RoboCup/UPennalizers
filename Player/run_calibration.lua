--append at current file
outfile=assert(io.open("./Config/calibration.lua","a+")); 

data=''
data=data..string.format("\n\-\- Updated date: %s\n" , os.date() );
outfile:write(data);
outfile:flush();
outfile:close();
