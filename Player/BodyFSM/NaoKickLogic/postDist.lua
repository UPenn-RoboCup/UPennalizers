module(..., package.seeall);

-- goalpost distance threshold
pNear = Config.fsm.bodyApproach.pNear or 0.3;
pRight = Config.fsm.bodyApproach.pRight or 1.2;
pFar = Config.fsm.bodyApproach.pFar or 3.0;

function kick()
  -- get attack goalpost positions and goal angle
  posts = {wcm.get_goal_attack_post1(), wcm.get_goal_attack_post2()}

  -- calculate the relative distance to each post, find closest
  pose = wcm.get_pose();
  p1Relative = util.pose_relative({posts[1][1], posts[1][2], 0}, {pose.x, pose.y, pose.a});
  p2Relative = util.pose_relative({posts[2][1], posts[2][2], 0}, {pose.x, pose.y, pose.a});
  p1Dist = math.sqrt(p1Relative[1]^2 + p1Relative[2]^2);
  p2Dist = math.sqrt(p2Relative[1]^2 + p2Relative[2]^2);
  pClosest = math.min(p1Dist, p2Dist);
  pFarthest = math.max(p1Dist, p2Dist);

  print("My current distance is... ",pClosest)

  if ((pClosest > pNear) and (pClosest < pRight)) then
    return true;
  elseif pClosest > pFar then
    return true;
  else
    return false;
  end
end

