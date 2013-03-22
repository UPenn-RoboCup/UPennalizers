%http://www.mathworks.com/help/matlab/matlab_external/bringing-java-classes-and-methods-into-matlab-workspace.html
%javaaddpath('/usr/local/share/java/zmq.jar');
%java.lang.System.load('/usr/local/lib/libzmq.dylib');
%java.lang.System.load('/usr/local/lib/libjzmq.dylib');
%zmsq_obj = javaObjectEDT('org.zeromq.ZMsg');
%ctx = javaObjectEDT('org.zeromq.ZContext');
%methodsview org.zeromq.ZMQ$Socket

% SUB: 2 (NOTE: This may change!)
%javaMethodEDT('createSocket',ctx, 2);
%skt = ctx.createSocket( 2 );
%skt.connect('ipc:///tmp/img');
% https://www.mathworks.com/support/solutions/en/data/1-OVUMA/index.html?solution=1-OVUMA
clear all;
javaaddpath('/usr/local/share/java/zmq.jar');
import org.zeromq.*
a = ZContext();
%{
% This works
s = a.createSocket(1); %1-pub, 2-sub
channel = 'ipc:///tmp/img';
s.bind( channel );
msg = java.lang.String('hello');
s.send( msg.getBytes() );
%}

s = a.createSocket(2); %1-pub, 2-sub
channel = 'ipc:///tmp/img';
s.connect( channel );
mask=java.lang.String('a');
s.subscribe( mask.getBytes() );
mask=java.lang.String('i');
s.subscribe( mask.getBytes() );
s.setReceiveTimeOut(1);
%%
cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];
figure(1);
while 1
    q = s.recv();
    if(~isempty(q))
        myt = q(1);
        %disp(myt);
        qq = q(2:end);
        if myt~=97
            %disp('got img');
            subplot(1,2,1);
            img = djpeg(qq);
            imagesc( img );
        else
            %disp('got label');
            rawu8 = typecast(qq, 'uint8');
            label = reshape(rawu8(1:160*120), [160, 120]);
            subplot(1,2,2);
            colormap(cmap);
            image(label');
            %xlim([1 size(label,2)]);
            %ylim([1 size(label,1)]);
        end
        
    end
    drawnow;
    %pause(.05);
end
