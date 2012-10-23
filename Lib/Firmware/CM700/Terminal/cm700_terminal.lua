require('unix')
require('serial')

ttys = unix.readdir("/dev");
ttyname = nil;
for i=1,#ttys do
   if (string.find(ttys[i], "tty.usb")) then
      ttyname = "/dev/"..ttys[i];
      break;
   end
end
print("USB tty:", ttyname);
assert(ttyname, "USB tty not found");

fd = serial.open(ttyname, serial.O_RDWR+serial.O_NOCTTY+serial.O_NONBLOCK);
assert(fd >= 0, "Could not open serial port");

serial.setspeed(fd, 57600)
serial.setvmin(fd, 0)
serial.setvtime(fd, 1)

while true do
   local line = io.read();
   if line == nil then break end
   local nwrite = serial.write(fd, line.."\r\n"); 
   unix.usleep(100000);
--   print("serial write:", nwrite);
   local sread = serial.read(fd);
   if (sread) then
      io.write("serial: ", sread, "\n");
   end
end

serial.close(fd);
