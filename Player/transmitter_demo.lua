dofile('init.lua')
require('unix')
require('Body')
require('SoundComm')
require('getch');
getch.enableblock(1);

SoundComm.set_transmitter_volume(100)

symbols = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '#', '*', 'A', 'B', 'C', 'D'};

lastPress = unix.time();

-- turn off recevier
SoundComm.pause_receiver();

-- continuous
continuous = false;
period = 1;
lastTx = unix.time();

while (1) do
  
   local cin = getch.get();
   local byte = nil;
   if (#cin > 0) then
      byte = string.byte(cin,1);
   end

   if (continuous) then
      if (( (Body.get_sensor_bumperLeft()[1] == 1 and Body.get_sensor_bumperRight()[1] == 1)
               or (byte and byte == string.byte(' ')))
            and unix.time() - lastPress > 1) then
         print('chest button mode');
         continuous = false;
         lastPress = unix.time();
      else
         if (unix.time() - lastTx > period) then
            -- pick random tone symbol
            ind = math.random(#symbols);
            symbol = symbols[ind];

            -- play sequence
            SoundComm.play_pnsequence(symbol);

            lastTx = unix.time();
         end
      end 
   else
     -- button pressed?
     if (Body.get_sensor_button()[1] == 1 and unix.time() - lastPress > 1) then
        -- pick random tone symbol
        ind = math.random(#symbols);
        symbol = symbols[ind];

        -- play sequence
        --SoundComm.play_pnsequence(symbol);
        SoundComm.play_pnsequence('1');

        lastPress = unix.time();
     elseif (((Body.get_sensor_bumperLeft()[1] == 1 and Body.get_sensor_bumperRight()[1] == 1)
               or (byte and byte == string.byte(' ')))
               and unix.time() - lastPress > 1) then
        -- enable continuous transmittion
        print('continuous mode');
        continuous = true;
        lastPress = unix.time();
     end
   end
   

   unix.usleep(100000);
end
