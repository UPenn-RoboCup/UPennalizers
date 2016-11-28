importfile( 1 );
abs_vy = abs_vy * -1;
abs_y = abs_y * -1;
%range = [180:280];
range = [1:size(abs_x,1)];


figure(1);
clf;
hold on;
plot( abs_x(range), 'b-' );
plot( obs_x(range), 'r-' );
hold off;

figure(2);
clf;
hold on;
plot( abs_y(range), 'b-' );
plot( obs_y(range), 'r-' );
hold off;

figure(3);
clf;
hold on;
plot( abs_vx(range), 'b-' );
plot( obs_vx(range), 'r-' );
%plot( 24*diff( obs_x(range) ), 'g-' );
hold off;

figure(4);
clf;
hold on;
plot( abs_vy(range), 'b-' );
plot( obs_vy(range), 'r-' );
%plot( 24*diff( obs_y(range) ), 'g-' );
hold off;

figure(5);
clf;
hold on;
%plot( obs_ep(range), 'k-' );
plot( obs_evp(range), 'm-' );
hold off;
