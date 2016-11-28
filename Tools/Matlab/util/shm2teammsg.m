function msg = shm2teammsg(gcmTeamWrapper, wcmRobotWrapper, wcmBallWrapper)
% function create the same struct as the team message from
% shared memory. for local debugging use
  try
    gcmTeam = gcmTeamWrapper;
    wcmRobot = wcmRobotWrapper;
    wcmBall = wcmBallWrapper;

    msg = [];
    
    msg.teamNumber = gcmTeam.get_number();
    msg.teamColor = gcmTeam.get_color();
    msg.id = gcmTeam.get_player_id();
    msg.role = gcmTeam.get_role();

    pose = wcmRobot.get_pose();
    msg.pose = struct('x', pose(1), 'y', pose(2), 'a', pose(3));

    ballxy = wcmBall.get_xy();
    ballt = wcmBall.get_t();
    msg.ball = struct('x', ballxy(1), 'y', ballxy(2), 't', ballt);
  catch
    msg = [];
end
