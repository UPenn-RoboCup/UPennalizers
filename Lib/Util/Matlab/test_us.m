us = shm('mcmUs');
us_count = 1;
top = 100;
side = 'right';
data = us.get(side);
while (us_count < top)
  d = us.get(side);
  %disp(d);
  data = cat(1,data,d);
  us_count = us_count + 1;
pause(.01);
end

filename = genvarname(strcat('us_test_data_',side,'_',datestr(now,30)));
save /tmp/test_us_data data;

x = 1:1:top;
plot(x,data(:,1),':or',x,data(:,2),':sb',x,data(:,3),':*g');
title(strcat(side,' us readings'));
legend('1','2','3');


