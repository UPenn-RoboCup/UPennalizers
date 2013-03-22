% https://www.mathworks.com/support/solutions/en/data/1-OVUMA/index.html?solution=1-OVUMA
clear all;
javaaddpath('/usr/local/share/java/zmq.jar');
import org.zeromq.*
a = ZContext();
%{
% This works for sending
s = a.createSocket(1); %1-pub, 2-sub.  NOTE: these numbers may change
channel = 'ipc:///tmp/img';
s.bind( channel );
msg = java.lang.String('hello');
s.send( msg.getBytes() );
%}

s = a.createSocket(2); %1-pub, 2-sub
channel = 'ipc:///tmp/img';
s.connect( channel );
mask=java.lang.String('a'); % labelA
s.subscribe( mask.getBytes() );
mask=java.lang.String('i'); % image
% TODO: set mask to use the id of the player we wish to track
s.subscribe( mask.getBytes() );
s.setReceiveTimeOut(1e3); % 1 second timeout, timeout is in ms
% TODO: set high water mark.
%%
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
f = figure(1);
% Speed: http://www.mathworks.com/support/solutions/en/data/1-1B022/?solution=1-1B022
set(gcf,'doublebuffer','off');
subplot(1,2,1);
pc = gca;
hc = image( zeros(160,120,3) );
xlim([1 160]);
ylim([1 120]);
subplot(1,2,2);
pl = gca;
colormap(cmap);
hl = image( uint8(zeros(160,120)) );
xlim([1 160]);
ylim([1 120]);
t0 = tic;
tl = tic;
tc = tic;
fps_c = 0;
fps_l = 0;
target_fps = 16;
inv_target_fps = 1/target_fps;
dirty = 0;
counter = uint32(0);
while 1
    q = s.recv();
    if(~isempty(q))
        dirty = 1;
        myt = q(1);
        %disp(myt);
        qq = q(2:end);
        if myt~=97
            %fps_c = (1/toc(tc))*.8+.2*fps_c;
            %tc = tic;
            img = djpeg(qq);
            set(hc,'Cdata',img);
            %title(pc, sprintf('FPS: %.1f',fps_c) );
        else
            %fps_l = (1/toc(tl))*.8+.2*fps_l;
            %tl = tic;
            rawu8 = typecast(qq, 'uint8');
            label = reshape(rawu8(1:160*120), [160, 120])';
            set(hl,'Cdata',label);
            %title(pl, sprintf('FPS: %.1f',fps_l) );
        end
        % Control the drawing
        t_diff = toc(t0);
        if t_diff>inv_target_fps && dirty==1
            title(pc, sprintf('FPS: %.1f\tCounter: %ld',1/t_diff, counter) );
            dirty = 0;
            drawnow;
            t0 = tic;
        end
        counter = counter+1;
    end
end
