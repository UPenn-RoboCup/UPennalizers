require('Dynamixel');

twait = 0.020;

Dynamixel.open();
--Dynamixel.open(nil,57600);
Dynamixel.ping_probe(twait);

--Dynamixel.set_id(1,12);
--Dynamixel.set_baud_1m(12);
