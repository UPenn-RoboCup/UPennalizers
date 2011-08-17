global CAMERADATA

width = 640;
height = 480;

%Corret colormap for labeled image
cbk=[0 0 0];
cr=[1 0 0];
cg=[0 1 0];
cb=[0 0 1];
cy=[1 1 0];
cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

while 1
  figure(1);
  ball=dcmVision('ball');
  goalYellow=dcmVision('goalYellow');

  CAMERADATA.yuyv = dcmVision32('big_img')+0;
  labelA = dcmVision8('big_labelA')+0;
  labelB = dcmVision8('labelB')+0;
  rgb=yuyv2rgb(CAMERADATA.yuyv);
  colormap(cmap);
  CAMERADATA.headAngles = [];
  CAMERADATA.imuAngles = [];
  CAMERADATA.select = 0;

  ball = shm('vcmBall');
  detectBall = ball.get('detect');
  if ( detectBall == 1 )
    ballCent = ball.get('centroid')
  end

  % PANE 1: Plots camera data directly from robot
  figure(1);
  subplot(2,2,1);
  image(rgb);

  % PANE 2: Unmarked rgb values
  subplot(2,2,2);
  image(labelA');

  % PANE 3: Mark the ball & goal posts
  subplot(2,2,3);
  cla;  
  image(reshape(labelB(1:30*40), [40, 30])');
  hold on;
  
  if ( detectBall == 1 )
    h = plot(ballCent(1)/4, ballCent(2)/4, 'ro');
    set(h, 'MarkerSize', 15);
  end
  

  


% Mark the goal posts
  goal = shm('vcmGoal');
  detectGoal = goal.get('detect');
%  v1 = goal.get('v1')

  if ( detectGoal == 1 )
    goalCent1 = goal.get('v1');
    goalCent2 = goal.get('v2');
    postBB1 = goal.get('postBoundingBox1')
    postBB2 = goal.get('postBoundingBox2')
    plot([postBB1(1) postBB1(1) postBB1(2) postBB1(2) postBB1(1)],[postBB1(3) postBB1(4) postBB1(4) postBB1(3) postBB1(3)],'r-', 'LineWidth',2);
    type = goal.get('type');
    if type == 1 % left post, plot crossbar towards right
      plot([postBB1(2) 40],[postBB1(3) postBB1(3)],'r-', 'LineWidth',2)
    elseif type == 2 % right post, plot crossbar towards left
      plot([postBB1(1) 0],[postBB1(3) postBB1(3)],'r-', 'LineWidth',2)
    elseif type == 3 % see both posts
      % plot second post
      postBB2 = goal.get('postBoundingBox2')
      plot([postBB2(1) postBB2(1) postBB2(2) postBB2(2) postBB2(1)],[postBB2(3) postBB2(4) postBB2(4) postBB2(3) postBB2(3)],'r-', 'LineWidth',2);
      % plot crossbar      
      plot([postBB1(2) postBB2(1)],[postBB1(3) postBB2(3)],'r-', 'LineWidth',2);
    end
  end
  hold off;

  %axis([0 160 0 120]);



%  Logger;

  pause(.1);
end

