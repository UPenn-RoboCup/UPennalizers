require('unix')
require('serial')

firmwareFilename = arg[1];
print("Loading firmware:", firmwareFilename);
fid = io.open(firmwareFilename, "rb");
assert(fid, "Could not open firmware file");
firmware = fid:read("*all");
io.close(fid);

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

print("Press reset on CM700...");
bootloader = false;
while (not bootloader) do
   serial.write(fd, "#");
   local sread = serial.read(fd);
   if (sread) then
      if string.find(sread, "CM700 Boot loader") then
	 bootloader = true;
      end
   end
end
serial.write(fd, "\n");
unix.usleep(100000);
serial.read(fd);

print("Entering CM700 bootloader");
serial.write(fd, "VER\n");
unix.usleep(100000);
print("Version:", serial.read(fd));

print("Sending load command");
serial.write(fd, "LD\n");
unix.usleep(500000);
print(serial.read(fd));
for i = 1,string.len(firmware) do
   serial.write(fd, firmware:sub(i,i));
   unix.usleep(100);
end
unix.usleep(1000000);
print(string.format("Done writing %d bytes\n", string.len(firmware)));
print(serial.read(fd));

serial.write(fd, '\nAPP\n');
unix.usleep(100000);
print(serial.read(fd));

serial.write(fd, '\nGO 0\n');
unix.usleep(100000);
print(serial.read(fd));

serial.close(fd);
