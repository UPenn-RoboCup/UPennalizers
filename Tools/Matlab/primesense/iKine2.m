function theta = iKine(coord)

% OP arm lengths
a_u = .06;
a_l = .129;
theta = [nan nan nan];

% Assume it is reachable
x = coord(1);
y = coord(2);
z = coord(3);

c = sqrt(x^2+y^2+z^2);

if(c>(a_u+a_l) || y<0 )
    %disp('Unreachable!')
    return;
end

%c^2 = a_u^2+a_l^2-2*a_u*a_l*cos(theta(3))
theta(3) = real( acos( (a_u^2+a_l^2-c^2)/(2*a_u*a_l) ) );

% Trouble below
%y = (a_u+a_l*cos(theta(3)))*sin(theta(2));
theta(2) = real( asin( y/c ) );

% Here is where we are
z_0 = (a_u+a_l*cos(theta(3)))*cos(theta(2));
x_0 = a_l*sin(theta(3));

% We want to get to x,z
theta(1) = real(atan2(z,x) - theta(3));

end