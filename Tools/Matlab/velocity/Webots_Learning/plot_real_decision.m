%% Plot the data
%time stillTime detect x y z vx vy vz ep evp ldodge ldir idodge idir

reward = human_reward(trialnum);
reward_title = 'Bad';
if( reward == 1 )
    reward_title = 'Good';
end
%{
figure(1);
clf;
hold on;
plot( obs_vth(range), 'r-' );
hold off;
ylim([-180, 180]);
title('Observed Velocity angle (Degrees)')

figure(2);
clf;
hold on;
plot( obs_th(range), 'r-' );
hold off;
ylim([-180, 180]);
title('Observed Position angle (Degrees)')
%}

figure(3);
clf;
hold on;
plot( obs_time(range), obs_detect(range)*max(obs_r(range))*1.2,    'k+' );
plot( obs_time(range), obs_r(range), 'r-' );
plot( obs_time(range), obs_ldodge(range)*max(obs_r(range)),    'g*' );
plot( obs_time(range), obs_idodge(range)*max(obs_r(range))*1.1,    'b*' );
plot( obs_time(range), obs_pr(range), 'm-' );
hold off;
title(strcat(num2str(trialnum),' | Position Radial | ',reward_title));

figure( 4 );
clf;
hold on;
plot( obs_y( obs_ldodge==1 ),  obs_x(obs_ldodge==1),  'r+' );
plot( obs_y( obs_ldodge==0 ),  obs_x(obs_ldodge==0),  'g*' );
rectangle('Position', [-.2 -.2 .4 .4], 'Curvature',[1,1]);
axis([-2 2 0 2]);
hold off;
title(strcat(num2str(trialnum),' | Position Path | ',reward_title));

figure(5);
clf;
hold on;
plot( obs_time(range), obs_vr(range), 'r-' );
%plot( abs( 30*diff(obs_r(range)) ), 'b-' );
plot( obs_time(range), obs_ldodge(range)*max(obs_r(range)),    'g*' );
plot( obs_time(range), obs_idodge(range)*max(obs_r(range))*1.1,    'b*' );
hold off;
title(strcat(num2str(trialnum),' | Velocity Radial | ',reward_title));



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

prediction = obs_px<.3 & obs_py<.1;

figure(8);
clf;
hold on;
plot( obs_time(range), obs_x(range), 'r-' );
plot( obs_time(range), obs_px(range), 'm-' );
plot( obs_time(range), obs_ldodge(range)*abs(max(obs_r(range))),    'g*' );
plot( obs_time(range), obs_idodge(range)*abs(max(obs_r(range)))*1.1,    'b*' );
hold off;
title(strcat(num2str(trialnum),' | Position X | ',reward_title));


figure(9);
clf;
hold on;
plot( obs_time(range), obs_y(range), 'r-' );
plot( obs_time(range), obs_py(range), 'm-' );
plot( obs_time(range), obs_ldodge(range)*max(obs_r(range)),    'g*' );
plot( obs_time(range), obs_idodge(range)*max(obs_r(range))*1.1,    'b*' );
hold off;
title(strcat(num2str(trialnum),' | Position Y | ',reward_title));
