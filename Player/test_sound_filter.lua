dofile('init.lua')
require('SoundFilter');
require('Comm')
--Comm.init('192.168.0.255', 54321);
Comm.init('192.168.1.255', 54321);
unix.usleep(1000000);

count = 0;
while (1) do
   SoundFilter.update();

   state = {};
   state.time = unix.time();
   state.soundFilter = wcm.get_sound_detFilter();
   state.soundDetection = wcm.get_sound_detection();

   if (count % 10 == 0) then
      s = serialization.serialize_orig(state);
      Comm.send(s);
   end

   if (count % 100 == 0) then
      local v = {{1, 0, 0}, {0, 0, 0}};
      local s = 'unkown';
      local gtype = SoundFilter.resolve_goal_detection(1, v);
      if (gtype < 0) then
         s = 'defending';
      elseif (gtype > 0) then
         s = 'attacking';
      end

      print(string.format('detected goal at (%f, %f) which is the %s goal', v[1][1], v[1][2], s));
   end

   count = count + 1;

   unix.usleep(100000);
end
