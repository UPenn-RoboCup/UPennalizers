%Multi-robot monitoring code using Comm
%-SJ, 110215
clear all;
close all;


data=[];

figure(1);
updatedY=[];
updatedU=[];
updatedV=[];
updatedL=[];

cbk=[0 0 0];
cr=[1 0 0];
cg=[0 1 0];
cb=[0 0 1];
cy=[1 1 0];
cw=[1 1 1];
cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg;cw];

width=640/2;
height=480;
division=255;

tic;
t0=toc;

global CAMERADATA;
get_log=0;
get_log2 = 0;
invert=0;
figure(1);
uicontrol('Style','pushbutton','String','LOG2',...
    'Position',[320 20 80 20],'Callback','get_log2=1-get_log2');

uicontrol('Style','pushbutton','String','LOG1',...
    'Position',[120 20 80 20],'Callback','get_log=1-get_log');

%{
uicontrol('Style','pushbutton','String','Invert',...
    'Position',[400 20 80 20],'Callback','invert=1-invert');
    %}
    
    yuyvY=zeros(1,320*480);
    yuyvU=zeros(1,320*480);
    yuyvV=zeros(1,320*480);
    logcount=0;
    prevID=0;
    
    while 1
        if naoCommWired('getQueueSize')>0
            
            %fprintf('\nLooking for a new frame\n');
            
            while(naoCommWired('getQueueSize')>0)
                rcv=naoCommWired('receive');
                %disp('received a frame!');
                if rcv(1)==14 		%Y
                    width=rcv(2)*256+rcv(3);
                    height=rcv(4)*256+rcv(5);
                    robotID=rcv(6);
                    yuyvY=rcv([7:size(rcv,2)]);
                    updatedY=1;
                elseif rcv(1)==15 	%U
                    width=rcv(2)*256+rcv(3);
                    height=rcv(4)*256+rcv(5);
                    robotID=rcv(6);
                    yuyvU=rcv([7:size(rcv,2)]);
                    updatedU=1;
                elseif rcv(1)==16 	%V
                    width=rcv(2)*256+rcv(3);
                    height=rcv(4)*256+rcv(5);
                    robotID=rcv(6);
                    yuyvV=rcv([7:size(rcv,2)]);
                    updatedV=1;
                elseif rcv(1)==17 	%label
                    widthL=rcv(2)*256+rcv(3);
                    heightL=rcv(4)*256+rcv(5);
                    robotID=rcv(6);
                    label=rcv([7:size(rcv,2)]);
                    %TODO: Hack
                    updatedL(1)=1;
                elseif rcv(1)==18	%Partitioned high-res Y
                    robotID=rcv(2);
                    division=double(rcv(3));
                    section=double(rcv(4));
                    yuyvY([320*480/division*section+1:320*480/division*(section+1)])=rcv([5:size(rcv,2)]);
                    updatedY(section+1)=1;
                elseif rcv(1)==19	%Partitioned high-res U
                    robotID=rcv(2);
                    division=double(rcv(3));
                    section=double(rcv(4));
                    yuyvU([320*480/division*section+1:320*480/division*(section+1)])=rcv([5:size(rcv,2)]);
                    updatedU(section+1)=1;
                elseif rcv(1)==20	%Partitioned high-res Y
                    robotID=rcv(2);
                    division=double(rcv(3));
                    section=double(rcv(4));
                    yuyvV([320*480/division*section+1:320*480/division*(section+1)])=rcv([5:size(rcv,2)]);
                    updatedV(section+1)=1;
                end
            end
        end
        
        % High res
        %    if sum(updatedY)+sum(updatedU)+sum(updatedV)==division*3
        if(updatedY+updatedU+updatedV==3)
            t=toc;
            framerate=1/(t-t0);
            t0=t;
            yuyvY=uint32(yuyvY);
            yuyvU=uint32(yuyvU);
            yuyvV=uint32(yuyvV);
            yuyv= yuyvY*16777216*4+ 256*4*yuyvU + yuyvV*4;
            yuyv=reshape(yuyv,width,height);
            
            rgb=yuyv2rgb(yuyv);
            if invert
                r=rgb([height/2:-1:1],[width:-1:1],1);
                g=rgb([height/2:-1:1],[width:-1:1],2);
                b=rgb([height/2:-1:1],[width:-1:1],3);
                rgb(:,:,1)=r;
                rgb(:,:,2)=g;
                rgb(:,:,3)=b;
            end
            
            %fprintf('Drawing frame...\n');
            if robotID==0 && prevID==0
                subplot(2,2,1);
                do_print = 1;
            elseif robotID==1 && prevID==1
                subplot(2,2,2);
                do_print = 2;
            else
                do_print = 0;
            end
            prevID = robotID;
            
            if( do_print == 1 || do_print==2 )
                fig=image(rgb);
                t_fig=sprintf('%.2f fps',framerate);
                title(t_fig)
                drawnow;
            end
            
            updatedY=[];
            updatedU=[];
            updatedV=[];
            
            % When an updated image arrives, add it to the log
            if get_log && do_print==1
                logcount=logcount+1;
                if mod(logcount,5)==0
                    CAMERADATA.headAngles = [];
                    CAMERADATA.imuAngles = [];
                    CAMERADATA.select = 0;
                    CAMERADATA.yuyv=yuyv;
                    rec_cnt = Logger2;
                    fprintf('Logged %d\n', rec_cnt);
                end
            end
            
            if get_log2 && do_print==2
                logcount=logcount+1;
                if mod(logcount,5)==0
                    CAMERADATA.headAngles = [];
                    CAMERADATA.imuAngles = [];
                    CAMERADATA.select = 1;
                    CAMERADATA.yuyv=yuyv;
                    rec_cnt = Logger2;
                    fprintf('Logged %d\n', rec_cnt);
                end
            end
            
        end
        
        %% Print the labeled Image
        
        if any(updatedL)
            
            if robotID==0
                gca= subplot(2,2,3);
            else
                gca= subplot(2,2,4);
                
            end
            label_m=reshape(label,widthL,heightL);
            if invert
                label_m=label_m([widthL:-1:1],[heightL:-1:1]);
            end
            
            image(label_m');
            
            colormap(cmap);
%            scale=double(widthL)/double(widthL0);
            
            %plot_vision(data(i),scale,1,invert);
            
            % Hack
            updatedL(1)=0;
            drawnow;
            
        end
        
        
        %pause(.5);
    end
    
