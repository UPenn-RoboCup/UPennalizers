require('unix')
require('stty')

firmwareFilename = arg[1];
print("Loading firmware:", firmwareFilename);
fid = io.open(firmwareFilename, "rb");
assert(fid, "Could not open firmware file");
firmware = fid:read("*all");
io.close(fid);

ttys = unix.readdir("/dev");
ttyname = nil;
for i=1,#ttys do
   if (string.find(ttys[i], "tty.usb") or string.find(ttys[i], "ttyUSB")) then
      ttyname = "/dev/"..ttys[i];
      break;
   end
end
print("USB tty:", ttyname);
assert(ttyname, "USB tty not found");

fd = unix.open(ttyname, unix.O_RDWR+unix.O_NOCTTY+unix.O_NONBLOCK);
assert(fd >= 0, "Could not open serial port");

stty.serial(fd)
stty.speed(fd, 57600)

print("Press reset on CM board...");
sread = "";
bootloader = false;
while (not bootloader) do
   unix.write(fd, "####");
   local s = unix.read(fd);
   if (type(s) == "string") then
      sread = sread..s;
      if string.find(sread, "Boot loader") then
	 bootloader = true;
      end
   end
end
unix.write(fd, "\n");
unix.usleep(100000);
unix.read(fd);

print("Entering Robotis bootloader");
unix.write(fd, "VER\n");
unix.usleep(100000);
print("Version:", unix.read(fd));

print("Sending load command");
unix.write(fd, "LD\n");
unix.usleep(500000);
print(unix.read(fd));
for i = 1,string.len(firmware) do
   unix.write(fd, firmware:sub(i,i));
   unix.usleep(100);
end
unix.usleep(1000000);
print(string.format("Done writing %d bytes\n", string.len(firmware)));
print(unix.read(fd));

unix.write(fd, '\nAPP\n');
unix.usleep(100000);
print(unix.read(fd));

unix.write(fd, '\nGO 0\n');
unix.usleep(100000);
print(unix.read(fd));

unix.close(fd);
