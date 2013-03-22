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
s.subscribe( mask.getBytes() );
s.setReceiveTimeOut(1);
%%
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
figure(1);
% Speed: http://www.mathworks.com/support/solutions/en/data/1-1B022/?solution=1-1B022
set(gcf,'doublebuffer','off');
subplot(1,2,1);
h = image( zeros(160,120,3) );
xlim([1 160]);
ylim([1 120]);
subplot(1,2,2);
colormap(cmap);
h2 = image( uint8(zeros(160,120)) );
xlim([1 160]);
ylim([1 120]);
while 1
    q = s.recv();
    if(~isempty(q))
        myt = q(1);
        %disp(myt);
        qq = q(2:end);
        if myt~=97
            %disp('got img');
            img = djpeg(qq);
            set(h,'Cdata',img);
        else
            %disp('got label');
            rawu8 = typecast(qq, 'uint8');
            label = reshape(rawu8(1:160*120), [160, 120])';
            set(h2,'Cdata',label);
        end
    end
    drawnow;
end
