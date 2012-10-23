module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('Config')

-- This is a dummy state that just recovers from a dive
-- and catches the case when it never ends up falling...

t0 = 0;
goalie_dive = Config.goalie_dive or 0;

if goalie_dive==1 then --arm motion only
  timeout = 2.0;
else
  timeout = 6.0;
end
function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
end

function update()

  t = Body.get_time();

  if (t - t0 > timeout) then
    if goalie_dive==1 then --arm motion only
      return "reanticipate"; --Quick timeout 
    else
      return "timeout";
    end
  end

end

function exit()
end
