% Points that are within our boundary
r = .15; % meters
distance = filtered_x.^2+filtered_y.^2;
close_selector = (distance < r^2);

%% Predict the position in the next delta of time
dt = 0.50;
%dt = 0.75;

p_x = filtered_x + my_vx*dt;
p_y = filtered_y + my_vy*dt;
filtered_r = sqrt(filtered_x.^2 + filtered_y.^2);
%my_vr = sqrt( my_vx.^2 + my_vy.^2 );
p_r = sqrt(p_x.^2+p_y.^2);


%% Plotting
timescale = [my_t_raw(1):.1:my_t_raw(end)];
zerobar = zeros(size(timescale)) + r;

figure(20);
subplot(2,1,1);
hold on;
plot( my_t_raw, p_r, 'r.' );
plot( my_t_raw, filtered_r, 'b.' );
plot( timescale, zerobar, 'k-' );
%title('Predicted (red) and Filtered (blue) radius');
ylabel('Distance')
xlabel('Time');
ylim([0 3]);

subplot(2,1,2);
ylim([0 1]);
xlim([-.5 .5]);
hold on;
plot( filtered_y, filtered_x, 'k+' );
plot( 0,0,'mo');

%% Select the positive samples
[tsel,ysel] = ginput(2);
if size(tsel,1)<2
    inc_total = zeros( size(filtered_x) );
    inc_total = (inc_total==ones( size(filtered_x) ) );
else
    min = tsel(1);max = tsel(2);
    inc_total = my_t_raw<=max & my_t_raw>=min;
end


%% ML Package
%pred_nodoubt = [p_x p_y inc_total];
%pred_only = [p_x p_y my_ep my_evp inc_total];
%pred_full_nodoubt = [filtered_x filtered_y  my_vx my_vy p_x p_y inc_total];
pred_full = [filtered_x filtered_y filtered_r my_z my_vx my_vy p_x p_y p_r my_ep my_evp inc_total*mdir];

% Put our positive samples on
figure(20);
subplot(2,1,1);
plot( my_t_raw(inc_total), filtered_r(inc_total), 'g+' );


%{
%% Display in a another window the x,y position of the ball during this
%% time
figure(21);
%clf;
hold on;
ylim([-0.5 1]);
xlim([-.5 .5]);
plot( filtered_y(inc_total), filtered_x(inc_total), 'bo' );
plot( p_y(inc_total), p_x(inc_total), 'r+' );
% Plot the circle

%% Uncertainty with distance
figure(22);
plot( filtered_r(inc_total), my_ep(inc_total), 'bo' );

figure(23);
plot( my_t_raw(inc_total), my_vx(inc_total), 'bo' );
%}
