mytitle = strcat( num2str(trialnum),'|Not hit...' );
if( Trial(2)==1 ) % There was a hit
    mytitle = strcat(num2str(trialnum),'| Hit at: ', num2str( Trial(3) ) );
end


%% Plot the data
%{
figure(1);
clf;
hold on;
plot( abs_vth(range), 'b-' );
plot( obs_vth(range), 'r-' );
hold off;
ylim([-180, 180]);
title('Observed Velocity angle (Degrees)')

figure(2);
clf;
hold on;
plot( abs_th(range), 'b-' );
plot( obs_th(range), 'r-' );
hold off;
ylim([-180, 180]);
title('Observed Position angle (Degrees)')
%}

figure(3);
clf;
hold on;
plot( abs_count(range)*0.04, abs_r(range), 'b-' );
plot( obs_time(range), obs_r(range), 'r-' );
plot( obs_time(range), hit_range(range)*max(obs_r(range)),    'k.' );
plot( obs_time(range), obs_dodge(range)*max(obs_r(range))*1.2,    'g*' );
plot( obs_time(range), obs_pr(range), 'm-' );
plot( obs_time(range), abs_pr(range), 'y-' );

prediction = obs_pr<.2;
plot( obs_time(range), prediction(range)*max(obs_r(range)), 'c+' );
%prediction = obs_pr<.2;
%plot( obs_time(range), prediction(range)*max(obs_r(range))*1.2, 'c*' );
hold off;
title(mytitle);


figure( 4 );
clf;
hold on;
plot( obs_y( miss_range ), obs_x( miss_range ), 'bo' );
plot( obs_y( hit_range ),  obs_x( hit_range ),  'r+' );
rectangle('Position', [-.2 -.2 .4 .4], 'Curvature',[1,1]);
axis([-2 2 0 2]);
hold off;



figure(5);
clf;
hold on;
plot( abs_vr(range), 'b-' );
plot( obs_vr(range), 'r-' );
plot( hit_range(range),    'k.' );
plot( obs_dodge(range)*1.2,    'g*' );
hold off;
title('Velocity Radial');


%{
figure(6);
clf;
hold on;
plot( obs_evp(range), 'b-' );
hold off;

figure(7);
clf;
hold on;
plot( obs_ep(range), 'b-' );
hold off;
%}

figure(8);
clf;
hold on;
plot( 180/pi*mod_angle( pi/180*(abs_pth(range) - abs_th(range)) ), 'b-' );
plot( 180/pi*mod_angle( pi/180*(obs_pth(range) - obs_th(range)) ), 'r-' );
hold off;
ylim([-180, 180]);
title(strcat('Dodge dir: ',num2str(dodge_dir) ))
