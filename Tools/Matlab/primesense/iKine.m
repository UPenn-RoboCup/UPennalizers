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
    disp('Unreachable!')
    return;
end

%c^2 = a_u^2+a_l^2-2*a_u*a_l*cos(theta(3))
%tmp = (a_u^2+a_l^2-c^2)/(2*a_u*a_l)
%acoss = acos( (a_u^2+a_l^2-c^2)/(2*a_u*a_l) )
theta(3) = pi - real( acos( (a_u^2+a_l^2-c^2)/(2*a_u*a_l) ) );
%NOTE: pi - stuff is due to my convention

% Trouble below
%y = (a_u+a_l*cos(theta(3)))*sin(theta(2));
%stuff = y/(a_u+a_l*cos( theta(3) ))
theta(2) = real( asin( y/(a_u+a_l*cos( theta(3) )) ) );

% Here is where we are
z_0 = (a_u+a_l*cos(theta(3)))*cos(theta(2));
x_0 = a_l*sin(theta(3));

% We want to get to x,z
if(isreal([x z x_0 z_0]))
    theta(1) = real(atan2(z,x) - atan2(z_0,x_0));
end

for i=1:3
    if(theta(i)>pi)
        theta(i) = theta(i) - pi;
    elseif(theta(i)<-pi)
        theta(i) = theta(i)+pi;
    end
end

end
