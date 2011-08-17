%Ashleigh
%parse array and monitor packets for each robot


yuyv = construct_array('yuyv');
labelA = construct_array('labelA');
labelB = construct_array('labelB');
cont = 1;
arr = [];

%% Establish our variables to display
y = [];
a = [];
b = [];
ballB = [];

cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

figure(1);
tDisplay = .1; % Display every .1 seconds
tStart = tic;
while cont
    
    %% Record our information
    if(monitorComm('getQueueSize') > 0)
        msg = monitorComm('receive');
        if ~isempty(msg)
            msg = lua2mat(char(msg))
            if (isfield(msg, 'arr'))
                y = yuyv.update(msg.arr);
                a = labelA.update(msg.arr);
                b = labelB.update(msg.arr);
            elseif( isfield(msg, 'ball') ) % Circle the ball in the images
                scale = 4; % For labelB
                ball = msg.ball;
                ballB = [];
                if(ball.detect==1)                    
                    centroidB = msg.ball.centroid;
                    centroidB.x = centroidB.x/scale;
                    centroidB.y = centroidB.y/scale;
                    radiusB = (msg.ball.axisMajor/scale)/2;
                    ballB = [centroidB.x-radiusB centroidB.y-radiusB 2*radiusB 2*radiusB];
                end
            end
        end
    end
    
    
    %% Draw our information
    tElapsed=toc(tStart);
    if( tElapsed>tDisplay )
        %disp(tElapsed)
        tStart = tic;
        
        if ~isempty(y)
            subplot(2,2,1);
            imagesc(yuyv2rgb(y'));
            %disp('Received image.')
        end
        if ~isempty(a)
            subplot(2,2,2);
            imagesc(a);
            colormap(cmap);
            %disp('Received Label A.')
        end
        if ~isempty(b)
            subplot(2,2,3);
            image(b);
            colormap(cmap);
            %disp('Received Label B.')
        end
        if ~isempty(ballB)
            subplot(2,2,3);
            hold on;
            plot(centroidB.x, centroidB.y,'k+')
            rectangle('Position', ballB, 'Curvature',[1,1])
            hold off;
            %disp('Plotting ball');
        end
        drawnow;
    end
    
end


