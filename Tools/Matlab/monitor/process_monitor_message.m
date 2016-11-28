function [needs_draw] = process_monitor_message(metadata, raw, cam, cidx)
  global DB_SELECT;
% Process each type of message
    msg_id = char(metadata.id);
    needs_draw = 0;
    if strcmp(msg_id,'detect')
        % Set the debug information
        if cidx == 1 %top
          if DB_SELECT==0
          	% TODO: it seems this is slow...
            set(cam.h_debug, 'String', char(metadata.debug_goal));
          else
            set(cam.h_debug, 'String', char(metadata.debug_ball));
          end
        else  %bottom
        	set(cam.h_debug, 'String', char(metadata.debug_ball));
        end
        % Process the ball detection result
        if isfield(metadata,'ball')
            % Show our ball on the YUYV image plot
            ball_c = metadata.ball.centroid * cam.scale;
            set(cam.p_ball,'Xdata', ball_c(1));
            set(cam.p_ball,'Ydata', ball_c(2));
        else
            % Remove from the plot
            set(cam.p_ball,'Xdata', []);
            set(cam.p_ball,'Ydata', []);
        end
        if isfield(metadata,'posts')
            % Show on the plot
            metadata.posts
        else
            % Remove from the plot
        end
        
    elseif strcmp(msg_id,'world')

    elseif strcmp(msg_id,'yuyv')
        % Assume always JPEG
        cam.yuyv = djpeg(raw);
        set(cam.im_yuyv,'Cdata', cam.yuyv);
        % Set limits always, should not cost much CPU
        xlim(cam.f_yuyv,[0 metadata.w]);
        ylim(cam.f_yuyv,[0 metadata.h]);
        needs_draw = 1;
    elseif strcmp(msg_id,'labelA')
        cam.labelA = reshape(zlibUncompress(raw),[metadata.w,metadata.h])';
        set(cam.im_lA,'Cdata', cam.labelA);
        xlim(cam.f_lA,[0 metadata.w]);
        ylim(cam.f_lA,[0 metadata.h]);
        needs_draw = 1;
    elseif strcmp(msg_id,'labelB')
        cam.labelB = reshape(zlibUncompress(raw),[metadata.w,metadata.h])';
        set(cam.im_lB,'Cdata', cam.labelB);
        xlim(cam.f_lB,[0 metadata.w]);
        ylim(cam.f_lB,[0 metadata.h]);
        needs_draw = 1;
    end
end


function debug_select(varargin)
  global h_button, DB_SELECT;
  DB_SELECT = 1 - DB_SELECT;
  if DE_SELECT>0
  	set(h_button,'String', 'BALL');
  else
  	set(h_button,'String', 'GOAL');
  end
end
