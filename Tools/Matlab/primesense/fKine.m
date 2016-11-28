function coord = fKine(theta)

coord = [nan nan nan];

% OP arm lengths
a_u = .5;
a_l = .5;

if(theta(2)<0 || theta(2)>pi || theta(3)>pi || theta(3)<0)
    disp('illegal angle');
    return;
end

% Get the Y dist
y = (a_u+a_l*cos(theta(3)))*sin(theta(2));
z_0 = (a_u+a_l*cos(theta(3)))*cos(theta(2));
x_0 = a_l*sin(theta(3));
%th_0 = atan2(z_0,x_0);
%th_d = th_0 + theta(1);

% Rotate x_0,z_0 by theta(1)
R = [cos(theta(1)) -sin(theta(1)) ; sin(theta(1)) cos(theta(1))];
coords = R*[x_0;z_0];
x = coords(1);
z = coords(2);

coord = [x y z];

end