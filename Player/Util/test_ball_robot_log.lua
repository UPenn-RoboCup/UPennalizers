 local torch = require 'torch'
 torch.Tensor = torch.DoubleTensor
 local libBallTrack = require 'libBallTrack'

--  Initialize the filter
 local tracker = libBallTrack.new_tracker()

 file_no = 5;
 read_file = io.open("../Data/ballLog/balllog"..file_no..".txt","r");
 write_file = io.open("../Data/ballLog/balllog"..file_no.."m.txt","w");
 write_file:close();
 write_file = io.open("../Data/ballLog/balllog"..file_no.."m.txt","a");
 prev_x = 0;
 prev_y = 0;
 prev_t = 0;

 -- Begin the test loop
 while true do
 t,x,y,kvx,kvy = read_file:read("*number","*number","*number","*number","*number");


 if not t then break end

 local observation = {x,y}
 local a = x - prev_x;
 local b = y - prev_y;

 local R = math.sqrt(math.pow(a,2) + math.pow(b,2));
 local velx = (x-prev_x)/(t-prev_t);
 local vely = (y-prev_y)/(t-prev_t);
 local dt = t - prev_t;
 local velR = R/dt;
 math.sqrt(math.pow(velx,2) + math.pow(vely,2));

 local position,velocity,confidence;

 if((R>0.3)or(x==0 and y==0)) then
 tracker:reset();
 position, velocity, confidence = tracker:update();
 else	
 position, velocity, confidence = tracker:update(observation);
 end
 local pred_posn_x = velocity[1] + position[1] ;
 local pred_posn_y = velocity[2] + position[2] ;

 write_file:write(t,"\t",x," ",y,"\t",velx," ",vely,"\t",kvx," ",kvy,"\t",velocity[1]*30," ",velocity[2]*30,"\n");

 prev_x = x;
 prev_y = y;
 prev_t = t;

end
read_file:close();
write_file:close();
