function [str textcolor]=robot_info(robot,r_mon,level,name,bodystate)
    robotnames = {'Bot1','Bot2','Bot3','Bot4','Bot5', 'Bot6'};

    rolenames = {'Goalie','Attacker','Defender','Supporter','Defender2',...
							'Coach', 'W. player','W. goalie','Unknown'};

    colornames={'red','blue'};
 
    role=robot.role;
    if isempty(role) 
      role=6;
    end
    if level==1 
      str=sprintf('#%d %s\n%s\n%.1fV\n',...
        robot.id, robotnames{robot.id}, rolenames{role+1},robot.battery_level);
    elseif level==2
      str=sprintf('#%d %s\n%s\n%s %s\n%d\n',...
        robot.id, robotnames{robot.id}, rolenames{role+1},...
        char(r_mon.fsm.head), char(r_mon.fsm.body), robot.battery_level*10);
    elseif level==3
      batt_str='[';
%      batt = max(0,robot.battery_level-11.6);
%      num_batt_bars = floor(batt*10*0.8);

      num_batt_bars = robot.battery_level; %for nao

      for i=1:num_batt_bars
        batt_str=[batt_str '='];
      end
      for i=1:10-num_batt_bars
        batt_str=[batt_str ' '];
      end
      batt_str=[batt_str ']'];
      if nargin >4
        role_str = sprintf('%s (%s)',rolenames{role+1},bodystate);
      else
        role_str = rolenames{role+1};
      end

      str=sprintf('#%d %s\n%s\n%d\n%s\n',...
        robot.id, name, role_str ,robot.battery_level,batt_str);
    end

    %Teammate data
    %Last updated time 

    if robot.battery_level<0.5
      textcolor='r'; %Low battery warning
    elseif robot.role>3 
      textcolor='g'; %Reserve player 
    else
      textcolor='k'; %Normal player 
    end
  end
