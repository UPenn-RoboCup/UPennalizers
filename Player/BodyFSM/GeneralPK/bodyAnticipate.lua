module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')

require('walk');
require('dive')

t0 = 0;
tStart = 0;
timeout = 60.0;

started = false;
finished=false;

tFollowDelay = Config.fsm.bodyKick.tFollowDelay;
tStartDelay = 5.0;
ball_velocity_th = -0.5;
rClose = 1.30; --Penalty mark dist is 1.8m from goal line

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  started = false;
  finished=false;
  Motion.event("diveready");
end

function update()
  local t = Body.get_time();
  if finished then
    if t-t0>10.0 then
      return "done";
    else
      return;
    end
  end

  ball = wcm.get_ball();
  if t-t0>tStartDelay and t-ball.t<0.1 then
    --Tracking the ball in ready position. Stop off head movement
    Body.set_head_hardness(0);
    ballR=math.sqrt(ball.x^2+ball.y^2);
    if ball.vx<ball_velocity_th and ballR<rClose then
      t0=t;
      py = ball.y - (ball.vy/ball.vx) * ball.x;

      print("Ball velocity:",ball.vx,ball.vy);
      print("Projected y pos:",py);

      if py>0.07 then 
        dive.set_dive("diveLeft");
      elseif py<-0.07 then
        dive.set_dive("diveRight");
      else
        dive.set_dive("diveCenter");
      end
      Motion.event("dive");
      finished=true;
    end
  end
end

function exit()
end
