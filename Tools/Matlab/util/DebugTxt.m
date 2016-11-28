function DebugTxt

global CAMERADATA VISIONDATA WORLD

%fprintf(1, '\nImage: %d\n', CAMERADATA.status.count);
if ~isempty(VISIONDATA),
  if VISIONDATA.ball.detect,
    fprintf(1,'Ball: %.3f %.3f\n', VISIONDATA.ball.v(1:2));
  end
  if VISIONDATA.goalYellow.detect,
    fprintf(1,'Goal Yellow: %.3f %.3f, %.3f %.3f %d\n', VISIONDATA.goalYellow.v(1:2,:));
  end
  if VISIONDATA.goalCyan.detect,
    fprintf(1,'Goal Cyan: %.3f %.3f, %.3f %.3f %d\n', VISIONDATA.goalCyan.v(1:2,:));
  end
end
