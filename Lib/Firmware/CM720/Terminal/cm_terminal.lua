require('unix')
require('stty')

if (arg[1]) then
   ttyname = arg[1]
else
   ttys = unix.readdir("/dev");
   ttyname = nil;
   for i=1,#ttys do
      if (string.find(ttys[i], "tty.usb") or string.find(ttys[i],"ttyUSB")) then
	 ttyname = "/dev/"..ttys[i];
	 break;
      end
   end
end
assert(ttyname, "Could not find tty");

baud = 57600;
if (arg[2]) then
   baud = arg[2];
end
print(string.format("TTY: %s, baud: %d\n", ttyname, baud));


fd = unix.open(ttyname, unix.O_RDWR+unix.O_NOCTTY+unix.O_NONBLOCK);
assert(fd >= 0, "Could not open serial port");

--Robotis says to set port, close and open again:
stty.serial(fd);
stty.speed(fd, baud);
--[[
unix.close(fd);
fd = unix.open(ttyname, unix.O_RDWR+unix.O_NOCTTY+unix.O_NONBLOCK);
stty.serial(fd);
--]]


while true do
   local line = io.read('*line');
   if line == nil then break end
   local nwrite = unix.write(fd, line.."\r\n"); 
   unix.usleep(100000);
--   print("serial write:", nwrite);
   local sread = unix.read(fd);
   if (sread) then
      io.write("serial: ", sread, "\n");
   end
end

unix.close(fd);
