%
% Jordan Brindza
% 04/2009
%
% example code showing how to make a matlab plot update quickly
% 

n = 100;
x = [1:n];
y = zeros(1, n);
d = pi/20;

% plot handle
p = plot(x,y);

% setup axes
xlabel('x');
ylabel('y');
axis([0, n+1, -1.2, 1.2]);

i = 0;
while(1)

  % shift values 
  y(1:n-1) = y(2:n);
  % add new value
  nv = sin(i*d);
  y(n) = nv;

  % set the plots data
  set(p, 'YData', y);

  % pause to allow update 
  pause(0.01);

  i = i + 1;
end


