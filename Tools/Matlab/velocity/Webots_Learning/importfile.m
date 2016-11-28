function importfile( trial_num, webots )

% Import the file
fileToRead1 = strcat('/Users/stephen/Desktop/dodgeball_sim/ball_obs_truth_',num2str(trial_num),'.txt');
if( webots == 0 )
    fileToRead1 = strcat('/Users/stephen/Desktop/dodgeball_trials/ball_obs_truth_',num2str(trial_num),'.txt');
end
newData1 = importdata(fileToRead1);

% Break the data up into a new structure with one field per column.
%colheaders = genvarname( strcat('obs_',num2str(trial_num),'_',newData1.textdata) );
colheaders = genvarname( strcat('obs_',newData1.textdata) );
for i = 1:length(colheaders)
    dataByColumn1.(colheaders{i}) = newData1.data(:, i);
end

% Create new variables in the base workspace from those fields.
vars = fieldnames(dataByColumn1);
for i = 1:length(vars)
    assignin('base', vars{i}, dataByColumn1.(vars{i}));
end

if( webots == 0 )
    % Import the file
    fileToRead1 = strcat('/Users/stephen/Desktop/dodgeball_trials/ball_rewards.txt');
    newData1 = importdata(fileToRead1);
    
    % Break the data up into a new structure with one field per column.
    colheaders = genvarname( strcat('human_',newData1.textdata) );
    for i = 1:length(colheaders)
        dataByColumn1.(colheaders{i}) = newData1.data(:, i);
    end
    
    % Create new variables in the base workspace from those fields.
    vars = fieldnames(dataByColumn1);
    for i = 1:length(vars)
        assignin('base', vars{i}, dataByColumn1.(vars{i}));
    end
    return;
end

% Import the file
fileToRead1 = strcat('/Users/stephen/Desktop/dodgeball_sim/ball_abs_truth_',num2str(trial_num),'.txt');
newData1 = importdata(fileToRead1);

% Break the data up into a new structure with one field per column.
%colheaders = genvarname( strcat('abs_',num2str(trial_num),'_',newData1.textdata) );
colheaders = genvarname( strcat('abs_',newData1.textdata) );
for i = 1:length(colheaders)
    dataByColumn1.(colheaders{i}) = newData1.data(:, i);
end

% Create new variables in the base workspace from those fields.
vars = fieldnames(dataByColumn1);
for i = 1:length(vars)
    assignin('base', vars{i}, dataByColumn1.(vars{i}));
end


% Import the file
fileToRead1 = strcat('/Users/stephen/Desktop/dodgeball_sim/ball_params_',num2str(trial_num),'.txt');
newData1 = importdata(fileToRead1);

% Break the data up into a new structure with one field per row.
rowheaders = genvarname(newData1.textdata);
for i = 1:length(rowheaders)
    dataByRow1.(rowheaders{i}) = newData1.data(i, :);
end

% Create new variables in the base workspace from those fields.
vars = fieldnames(dataByRow1);
for i = 1:length(vars)
    assignin('base', vars{i}, dataByRow1.(vars{i}));
end
