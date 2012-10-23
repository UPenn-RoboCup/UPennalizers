function [str textcolor]=robot_info(robot,r_mon,level,name)
    robotnames = {'Bot1','Bot2','Bot3','Bot4','Bot5'};
    rolenames = {'Goalie','Attacker','Defender','Supporter','W. player','W. goalie','Unknown'};
    colornames={'red','blue'};
 
    role=robot.role;
    if isempty(role) 
      role=6;
    end
    if level==1 
      str=sprintf('#%d %s\n%s\n%.1fV\n',...
        robot.id, robotnames{robot.id}, rolenames{role+1},robot.battery_level);
    elseif level==2




      str=sprintf('#%d %s\n%s\n%s %s\n%.1fV\n',...
        robot.id, robotnames{robot.id}, rolenames{role+1},...
        char(r_mon.fsm.head), char(r_mon.fsm.body), robot.battery_level);
    elseif level==3


      batt_str='[';
      batt = max(0,robot.battery_level-11.6);
      num_batt_bars = floor(batt*10*0.8);

      for i=1:num_batt_bars
        batt_str=[batt_str '='];
      end
      for i=1:8-num_batt_bars
        batt_str=[batt_str ' '];
      end
      batt_str=[batt_str ']'];

      str=sprintf('#%d %s\n%s\n%.1fV\n%s\n',...
        robot.id, name, rolenames{role+1},robot.battery_level,batt_str);

    end

    %Teammate data
    %Last updated time 

    if robot.battery_level<9.9
      textcolor='r'; %Low battery warning
    elseif robot.role>3 
      textcolor='g'; %Reserve player 
    else
      textcolor='k'; %Normal player 
    end
  end
