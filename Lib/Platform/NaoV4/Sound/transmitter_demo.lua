dofile('init.lua')
require('unix')
require('Body')
require('SoundComm')

symbols = {'1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '#', '*', 'A', 'B', 'C', 'D'};

lastPress = unix.time();

-- turn off recevier
SoundComm.pause_receiver();

while (1) do
   
   -- button pressed?
   if (Body.get_sensor_button()[1] == 1 and unix.time() - lastPress > 1) then
      -- pick random tone symbol
      ind = math.random(#symbols);
      if (ind < 1 or ind > #symbols) then
         print('random function returned: ', ind);
         ind = 1;
      end

      symbol = symbols[ind];

      -- play sequence
      SoundComm.play_pnsequence(symbol);

      lastPress = unix.time();
   end
   

   unix.usleep(100000);
end
