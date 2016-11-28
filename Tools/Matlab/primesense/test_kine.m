%% Test the iKine and fKine within the ranges
a_u = .06;
a_l = .129;
tot_len = a_u+a_l;
all_diffs = [];
bad = 0;
good = 0;
% y must be positive
for y=0:tot_len/10:tot_len
    for x=-tot_len:tot_len/10:tot_len
        for z=-tot_len:tot_len/10:tot_len
            c = sqrt(x^2+y^2+z^2);
            if( c<=(a_u+a_l) )
                theta = iKine2( [x y z] );
                coords = fKine( theta );
                diff = [x y z] - coords;
                if( ~isnan(coords) )
                    all_diffs = [all_diffs ; diff];
                end
                
                if( any(isnan(coords)) || ~isreal(coords) || ~isreal(theta) || sum(diff.^2)>0.05 )
                    bad = bad+1;
                    initc = [x y z]
                    %theta
                    %t_1 = (c^2-a_u^2-a_l^2)/(-2*a_u*a_l)
                    %t_2 = a_u+a_l*cos(theta(3))
                    coords
                else
                    good = good+1;
                end
                
            end
        end
    end
end

bad_ratio = bad / (bad+good)

figure(1);
clf;
plot(all_diffs.^2,'*')
