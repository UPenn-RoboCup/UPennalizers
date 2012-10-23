module(... or '', package.seeall)


-- Add the required paths
cwd = '.';

uname = io.popen('uname -s')
system = uname:read()

computer = os.getenv('COMPUTER') or system;
package.cpath = cwd.."/Lib/?.so;"..package.cpath;

package.path = cwd.."/Util/?.lua;"..package.path;
package.path = cwd.."/Config/?.lua;"..package.path;
package.path = cwd.."/Lib/?.lua;"..package.path;
package.path = cwd.."/Dev/?.lua;"..package.path;
package.path = cwd.."/World/?.lua;"..package.path;
package.path = cwd.."/Vision/?.lua;"..package.path;
package.path = cwd.."/Motion/?.lua;"..package.path; 

require 'unix'
require ('Config')
--Copy data to shm 1-1
Config.game.teamNumber = 1;
Config.game.playerID = 1;
Config.listen_monitor = 1;

io.write("Enter number of teams to track: ");
io.flush();
team_num=io.read("*number");
if team_num==2 then
  io.write("Enter two team numbers to track: ");
  io.flush();
  team1,team2=io.read("*number","*number");
  teamToTrack={team1, team2};
else
  io.write("Enter the team number to track: ");
  io.flush();
  team1=io.read("*number");
  teamToTrack={team1};
end

--Push to (team,1) shm

require ('cutil')
require ('vector')
require ('serialization')
require ('Comm')
require ('util')
require ('wcm')
require ('gcm')
require ('vcm')

Comm.init(Config.dev.ip_wireless,Config.dev.ip_wireless_port);
print('Receiving Team Message From',Config.dev.ip_wireless);

function push_labelB(obj,teamOffset)
  if not obj.labelB then return; end
  id=obj.id+teamOffset;
  local labelB = cutil.test_array();
  cutil.string2label_rle(labelB,obj.labelB.data);
  if id==1 then
    wcm.set_labelB_p1(labelB);
  elseif id==2 then
    wcm.set_labelB_p2(labelB);
  elseif id==3 then
    wcm.set_labelB_p3(labelB);
  elseif id==4 then
    wcm.set_labelB_p4(labelB);
  elseif id==5 then
    wcm.set_labelB_p5(labelB);
  elseif id==6 then
    wcm.set_labelB_p6(labelB);
  elseif id==7 then
    wcm.set_labelB_p7(labelB);
  elseif id==8 then
    wcm.set_labelB_p8(labelB);
  elseif id==9 then
    wcm.set_labelB_p9(labelB);
  elseif id==10 then
    wcm.set_labelB_p10(labelB);
  end
end


team_t_receive=vector.zeros(10);

function push_team_struct(obj,teamOffset)
  states={};

  states.teamColor=wcm.get_teamdata_teamColor();
  states.robotId=wcm.get_teamdata_robotId();
  states.role=wcm.get_teamdata_role();
  states.time=wcm.get_teamdata_time();
  states.posex=wcm.get_teamdata_posex();
  states.posey=wcm.get_teamdata_posey();
  states.posea=wcm.get_teamdata_posea();

  states.ballx=wcm.get_teamdata_ballx();
  states.bally=wcm.get_teamdata_bally();
  states.ballvx=wcm.get_teamdata_ballx();
  states.ballvy=wcm.get_teamdata_bally();
  states.ballt=wcm.get_teamdata_ballt();

  states.attackBearing=wcm.get_teamdata_attackBearing();
  states.fall=wcm.get_teamdata_fall();
  states.penalty=wcm.get_teamdata_penalty();
  states.battery_level=wcm.get_teamdata_battery_level();

  states.goal=wcm.get_teamdata_goal();
  states.goalv11=wcm.get_teamdata_goalv11();
  states.goalv12=wcm.get_teamdata_goalv12();
  states.goalv21=wcm.get_teamdata_goalv21();
  states.goalv22=wcm.get_teamdata_goalv22();

  states.goalB11=wcm.get_teamdata_goalB11();
  states.goalB12=wcm.get_teamdata_goalB12();
  states.goalB13=wcm.get_teamdata_goalB13();
  states.goalB14=wcm.get_teamdata_goalB14();
  states.goalB15=wcm.get_teamdata_goalB15();
  states.goalB21=wcm.get_teamdata_goalB21();
  states.goalB22=wcm.get_teamdata_goalB22();
  states.goalB23=wcm.get_teamdata_goalB23();
  states.goalB24=wcm.get_teamdata_goalB24();
  states.goalB25=wcm.get_teamdata_goalB25();

  states.landmark=wcm.get_teamdata_landmark();
  states.landmarkv1=wcm.get_teamdata_landmarkv1();
  states.landmarkv2=wcm.get_teamdata_landmarkv2();

--print("Team message from",obj.id)

  --Now index is 1 to 10 (5 robot, 2 teams)
  id=obj.id+teamOffset;


  team_t_receive[id]=obj.tReceive;
  
--states.role[id]=obj.id; --robot id?
  states.teamColor[id]=obj.teamColor;
  states.robotId[id]=obj.id;
  states.role[id]=obj.role;
  states.time[id]=obj.time;
  states.posex[id]=obj.pose.x;
  states.posey[id]=obj.pose.y;
  states.posea[id]=obj.pose.a;
  states.ballx[id]=obj.ball.x;
  states.bally[id]=obj.ball.y;
  states.ballt[id]=obj.ball.t;
  states.ballvx[id]=obj.ball.velx;
  states.ballvy[id]=obj.ball.vely;

  states.attackBearing[id]=obj.attackBearing;
  states.fall[id]=obj.fall;
  states.penalty[id]=obj.penalty;
  states.battery_level[id]=obj.battery_level;

  states.goal[id]=obj.goal;
  states.goalv11[id]=obj.goalv1[1];
  states.goalv12[id]=obj.goalv1[2];
  states.goalv21[id]=obj.goalv2[1];
  states.goalv22[id]=obj.goalv2[2];

  if obj.goalB1 then
    states.goalB11[id]=obj.goalB1[1];
    states.goalB12[id]=obj.goalB1[2];
    states.goalB13[id]=obj.goalB1[3];
    states.goalB14[id]=obj.goalB1[4];
    states.goalB15[id]=obj.goalB1[5];

    states.goalB21[id]=obj.goalB2[1];
    states.goalB22[id]=obj.goalB2[2];
    states.goalB23[id]=obj.goalB2[3];
    states.goalB24[id]=obj.goalB2[4];
    states.goalB25[id]=obj.goalB2[5];
  end

  states.landmark[id]=obj.landmark;
  states.landmarkv1[id]=obj.landmarkv[1];
  states.landmarkv2[id]=obj.landmarkv[2];

  if id==1 then  
    wcm.set_robotNames_n1(obj.robotName);
  elseif id==2 then  
    wcm.set_robotNames_n2(obj.robotName);
  elseif id==3 then  
    wcm.set_robotNames_n3(obj.robotName);
  elseif id==4 then  
    wcm.set_robotNames_n4(obj.robotName);
  elseif id==5 then  
    wcm.set_robotNames_n5(obj.robotName);
  elseif id==6 then  
    wcm.set_robotNames_n6(obj.robotName);
  elseif id==7 then  
    wcm.set_robotNames_n7(obj.robotName);
  elseif id==8 then  
    wcm.set_robotNames_n8(obj.robotName);
  elseif id==9 then  
    wcm.set_robotNames_n9(obj.robotName);
  elseif id==10 then  
    wcm.set_robotNames_n10(obj.robotName);
  end



--print("Ballx:",obj.ball.x);

--print("robotID:",unpack(states.robotId))

  wcm.set_teamdata_teamColor(states.teamColor);
  wcm.set_teamdata_robotId(states.robotId);
  wcm.set_teamdata_role(states.role);
  wcm.set_teamdata_time(states.time)

  wcm.set_teamdata_posex(states.posex)
  wcm.set_teamdata_posey(states.posey)
  wcm.set_teamdata_posea(states.posea)

  wcm.set_teamdata_ballx(states.ballx)
  wcm.set_teamdata_bally(states.bally)
  wcm.set_teamdata_ballt(states.ballt)
  wcm.set_teamdata_ballx(states.ballvx)
  wcm.set_teamdata_bally(states.ballvy)

  wcm.set_teamdata_attackBearing(states.attackBearing)
  wcm.set_teamdata_fall(states.fall)
  wcm.set_teamdata_penalty(states.penalty)
  wcm.set_teamdata_battery_level(states.battery_level)

  wcm.set_teamdata_goal(states.goal);
  wcm.set_teamdata_goalv11(states.goalv11);
  wcm.set_teamdata_goalv12(states.goalv12);
  wcm.set_teamdata_goalv21(states.goalv21);
  wcm.set_teamdata_goalv22(states.goalv22);

  wcm.set_teamdata_goalB11(states.goalB11);
  wcm.set_teamdata_goalB12(states.goalB12);
  wcm.set_teamdata_goalB13(states.goalB13);
  wcm.set_teamdata_goalB14(states.goalB14);
  wcm.set_teamdata_goalB15(states.goalB15);

  wcm.set_teamdata_goalB21(states.goalB21);
  wcm.set_teamdata_goalB22(states.goalB22);
  wcm.set_teamdata_goalB23(states.goalB23);
  wcm.set_teamdata_goalB24(states.goalB24);
  wcm.set_teamdata_goalB25(states.goalB25);

  wcm.set_teamdata_landmark(states.landmark);
  wcm.set_teamdata_landmarkv1(states.landmarkv1);
  wcm.set_teamdata_landmarkv2(states.landmarkv2);
end

count=0;
tStart=unix.time();

while( true ) do
  while (Comm.size() > 0) do
    msg=Comm.receive();

    t = serialization.deserialize(msg);
    if t and (t.teamNumber) then
      t.tReceive = unix.time();
      count=count+1;
      if #teamToTrack==1 then 
        if (t.teamNumber == teamToTrack[1]) and (t.id) then
          push_team_struct(t,0);
	  push_labelB(t,0);
        end
      else
        if (t.teamNumber == teamToTrack[1]) and (t.id) then
          push_team_struct(t,0);
	  push_labelB(t,0);

        elseif (t.teamNumber == teamToTrack[2]) and (t.id) then
          push_team_struct(t,5);
	  push_labelB(t,5);

        end
      end
      if count%30==0 then
        print(string.format("Team message: %d fps",count/(t.tReceive-tStart)));
	tStart=t.tReceive;
        count=0;
      end
    end
  end
--TODO: timeout
--[[
  for i=1,10 do
    t_current = unix.time();
    if t.tReceive-team_t_receive[i]>5.0 then

    end
  end
--]]
  unix.usleep(1E6*0.01);
end
