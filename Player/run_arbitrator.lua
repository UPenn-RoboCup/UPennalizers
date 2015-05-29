module(... or "", package.seeall)
require('init')
require('getch')
require('wcm')
local Arbitrator = require('Parallel_Arbitrator')

maxFPS = Config.vision.maxFPS;
tperiod = 1.0/maxFPS;

-- Do not wait for a carriage return
getch.enableblock(1);


Arbitrator.entry()

local count = 1;
t0 = unix.time()
t1 = unix.time()

local signal = require'signal'
signal.signal("SIGINT", shutdown)
signal.signal("SIGTERM", shutdown)

count_arb = 0
count_v1 = 0
count_v2 = 0
count_bro = 0
count_fsm = 0
t_last_fps = unix.time()

local function show_fps(arb_fps)
   t1 = unix.time() 
   os.execute("clear")
   print (string.format("Arbitrator Frequency %.2f Hz ",arb_fps))

   local v1 = wcm.get_process_v1()
   local v2 = wcm.get_process_v2()

   wcm.set_process_v1({t1,0,v1[3]})  
   wcm.set_process_v2({t1,0,v2[3]})  

   --Process V: t_last_update sum_time_for_loop current_count
   print(string.format("V1: %.1f ms / %.2f Hz\nV2: %.1f ms / %.2f Hz",
    v1[2]/(v1[3]-count_v1)*1000, (v1[3]-count_v1)/(t1-v1[1]), 
    v2[2]/(v2[3]-count_v2)*1000, (v2[3]-count_v2)/(t1-v2[1])
    ))
   --Update local counters   
   count_v1 = v1[3]
   count_v2 = v2[3]


   local v = wcm.get_process_fsm()
   wcm.set_process_fsm({t1,0,v[3]})
   print(string.format("FSM: %.1f ms / %.2f Hz\n",
	v[2]/(v[3]-count_fsm)*1000, (v[3]-count_fsm)/(t1-v[1])
	))
   count_fsm = v[3]


 
   broadcast_enable = wcm.get_process_broadcast()
   if broadcast_enable==0 then
     print("Broadcast OFF")
   else
     local v = wcm.get_process_bro()
     wcm.set_process_bro({t1,0,v[3]})
     print(string.format("Broadcast: %d   %d ms / %.2f Hz\n",
	broadcast_enable,
	v[2]/(v[3]-count_bro)*1000, (v[3]-count_bro)/(t1-v[1])
	))
     count_bro = v[3]
   end  
   
end



while (true) do
  local str=getch.get();
  if #str>0 then
    local byte=string.byte(str,1);
    if byte==string.byte("g") then  --Broadcast selection
      broadcast_enable = wcm.get_process_broadcast()
      broadcast_enable = (broadcast_enable+1)%4;
      print("Broadcast:", broadcast_enable);
      wcm.set_process_broadcast(broadcast_enable)
    end
  end
  tstart = unix.time();

  Arbitrator.update()

  tloop = unix.time() - tstart;

  if (tloop < tperiod) then unix.usleep((tperiod - tloop)*(1E6)) end

  if unix.time()-t_last_fps>1 then 
    show_fps(count/ (unix.time()-t_last_fps))
    t_last_fps = unix.time()
    count = 0
  end

  t0 = t1
  count = count + 1

end
