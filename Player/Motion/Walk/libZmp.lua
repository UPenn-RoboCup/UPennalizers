module(..., package.seeall);


require('Config');
require('vector')
require('util')
require('Body')
require('invhyp')




function zmp_solve(zs, z1, z2, x1, x2,p)
  --[[
  Solves ZMP equation:
  x(t) = z(t) + aP*exp(t/tZmp) + aN*exp(-t/tZmp) - tZmp*mi*sinh((t-Ti)/tZmp)
  where the ZMP point is piecewise linear:
  z(0) = z1, z(T1 < t < T2) = zs, z(tStep) = z2
  --]]
  local expTStep = math.exp(p.tStep/p.tZmp);
  if p.zmp_type==1 then --Trapzoidal zmp
    local T1,T2 = p.tStep*p.phSingleRatio/2, p.tStep*(1-p.phSingleRatio/2)
    local m1,m2 = (zs-z1)/T1, -(zs-z2)/(p.tStep-T2)
    local c1 = x1-z1+p.tZmp*m1*math.sinh(-T1/p.tZmp);
    local c2 = x2-z2+p.tZmp*m2*math.sinh((p.tStep-T2)/p.tZmp);
    local aP = (c2 - c1/expTStep)/(expTStep-1/expTStep);
    local aN = (c1*expTStep - c2)/(expTStep-1/expTStep);
    return aP, aN;
  else --Square ZMP
    local c1 = x1-z1
    local c2 = x2-z2
    local aP = (c2 - c1/expTStep)/(expTStep-1/expTStep)
    local aN = (c1*expTStep - c2)/(expTStep-1/expTStep)
    return aP, aN
  end
end

--Finds the necessary COM for stability and returns it
function zmp_com(uSupport,ph,p)
  local com = vector.new({0, 0, 0});
  local tStep,ph1Zmp,ph2Zmp,tZmp =p.tStep, p.phSingleRatio/2,1-p.phSingleRatio/2, p.tZmp
  local m1X,m1Y,m2X,m2Y = p.zmpparam.m1X,p.zmpparam.m1Y,p.zmpparam.m2X,p.zmpparam.m2Y
  local aXP,aXN,aYP,aYN = p.zmpparam.aXP,p.zmpparam.aXN,p.zmpparam.aYP,p.zmpparam.aYN
  expT = math.exp(tStep*ph/tZmp);
  com[1] = uSupport[1] + aXP*expT + aXN/expT;
  com[2] = uSupport[2] + aYP*expT + aYN/expT;
  if p.zmp_type==1 then
    if (ph < ph1Zmp) then
      com[1] = com[1] + m1X*tStep*(ph-ph1Zmp) - tZmp*m1X*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
      com[2] = com[2] + m1Y*tStep*(ph-ph1Zmp) - tZmp*m1Y*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
    elseif (ph > ph2Zmp) then
      com[1] = com[1] + m2X*tStep*(ph-ph2Zmp) - tZmp*m2X*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
      com[2] = com[2] + m2Y*tStep*(ph-ph2Zmp) - tZmp*m2Y*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
    end
  end  
  return com;
end

function calculate_zmp_param(uSupport,uTorso1,uTorso2,p)
  local zmpparam={}
  if p.zmp_type==1 then
    zmpparam.m1X = (uSupport[1]-uTorso1[1])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m2X = (uTorso2[1]-uSupport[1])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m1Y = (uSupport[2]-uTorso1[2])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m2Y = (uTorso2[2]-uSupport[2])/(p.tStep*p.phSingleRatio/2)
  end
  zmpparam.aXP, zmpparam.aXN = zmp_solve(uSupport[1], uTorso1[1], uTorso2[1],uTorso1[1], uTorso2[1],p)
  zmpparam.aYP, zmpparam.aYN = zmp_solve(uSupport[2], uTorso1[2], uTorso2[2],uTorso1[2], uTorso2[2],p)
  p.zmpparam = zmpparam
    --Compute COM speed at the end of step 
    --[[
    dx0=(aXP-aXN)/tZmp + m1X* (1-math.cosh(ph1Zmp*tStep/tZmp));
    dy0=(aYP-aYN)/tZmp + m1Y* (1-math.cosh(ph1Zmp*tStep/tZmp));
    print("max DY:",dy0);
    --]]
end


function calculate_swap(uLeft1,uLeft2,uRight1,uRight2,cp)
  if (not Config.walk.variable_step) or Config.walk.variable_step==0 then
    return Config.walk.tStep
  end
  
  --x = p + x0 cosh((t-t0)/t_zmp)
  --local tStep = cp.tStep
  local tStep = Config.walk.tStep
  local tZmp = cp.tZmp
 
  local stepY
  local t_start
  local p,x0
  if supportLeg==0 then --ls
    p = -(cp.footY + cp.supportY)
    x0 = -p/math.cosh(tStep/tZmp/2)
    local uSupport1 = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft1);    
    local uSupport2 = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight2);
    local uSupportMove = util.pose_relative(uSupport2,uSupport1)
    stepY = uSupportMove[2]+2*(cp.footY+cp.supportY)
--   print("ls",stepY)
  else  --rs
    p = (cp.footY + cp.supportY)
    x0 = -p/math.cosh(tStep/tZmp/2)
    local uSupport1 = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight1);
    local uSupport2 = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft2);    
    uSupportMove = util.pose_relative(uSupport2,uSupport1)
    stepY = uSupportMove[2]-2*(cp.footY+cp.supportY)
--   print("rs",stepY)
  end
  if (stepY/2-p)/x0<1 then return Config.walk.tStep end
  local t_start = -invhyp.acosh( (stepY/2 - p)/x0 )*tZmp + tStep/2
  local tStep_next = math.max(Config.walk.tStep, tStep-t_start)
--  print("tStep_next:",tStep_next)
  return tStep_next
end