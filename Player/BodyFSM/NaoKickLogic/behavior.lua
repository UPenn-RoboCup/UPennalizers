module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')

function cycle_behavior()
  demo_behavior = demo_behavior%4 + 1;

  if demo_behavior == 1 then 
    Speak.talk("Front kick test");
    kickDir=1;
    kickType=1;
  elseif demo_behavior == 2 then
    Speak.talk("Side kick test");
    kickDir=2;
    kickType=1;
  elseif demo_behavior == 3 then
    Speak.talk("Front walkkick test");
    kickDir=1;
    kickType=2;
  elseif demo_behavior == 4 then
    Speak.talk("Side walkkick test");
    kickDir=2;
    kickType=2;
  end
end

--Initial kick for demo 
if Config.fsm.playMode==1 then 
  demo_behavior = 0;
  cycle_behavior();
end

function update()
  -----------------------------------------------------------
  --Kick dir:1 front, 2 to the left, 3 to the right
  --Kick type: 1 stationary kick, 2 walkkick, (3 dribble)

  -------------------------------
  --Kickoff handling
  ------------------------------
  tKickOffWear = 20.0;

  t=Body.get_time();
  kick_off=wcm.get_kick_kickOff();
  tKickOff=wcm.get_kick_tKickOff();
  --If too long time has passed since game starts
  --Don't care about kickoff kick 
  if (t-tKickOff)>tKickOffWear then
    wcm.set_kick_kickOff(0);
    kick_off=0;
  end

  if Config.fsm.playMode>1 then --skip kick selection in demo mode
    if kick_off>0 then 
      print("Behavior updated, kickoff kick")
      kickAngle = math.pi/6; --30 degree off angle
      kickDir=1;
      kickType=2;
      wcm.set_kick_kickOff(0);
      wcm.set_kick_dir(kickDir);
      wcm.set_kick_type(kickType);
      wcm.set_kick_angle(kickAngle);
      return;
    end
    attackBearing = wcm.get_attack_bearing();
    --Check if front walkkick is available now
    kickType=2;

    --Check kick direction 
    thFrontKick = 45*math.pi/180;  

    if math.abs(attackBearing)<thFrontKick then
      kickDir=1;
      kickAngle = 0;
    elseif attackBearing>0 then --should kick to the left
      kickDir=2;
      kickAngle = math.pi/2;
    else
      kickDir=3;
      kickAngle = -math.pi/2;
    end
  else --Demo mode
    if kickDir>1 then 
      kickDir=5-kickDir; --Switch sidekick direction for demo mode
    end
    kickAngle = 0;
  end

  if walk.canWalkKick ~= 1 or Config.fsm.enable_walkkick == 0 then
    kickType=1;
  end

  if Config.fsm.enable_sidekick==0 then
    kickDir=1;
    kickAngle=0;
  end

  if kickDir==1 then
    print("Behavior updated, straight kick")
  elseif kickDir==2 then
    print("Behavior updated, kick to the left")
  else
    print("Behavior updated, kick to the right")
  end

  wcm.set_kick_dir(kickDir);
  wcm.set_kick_type(kickType);
  wcm.set_kick_angle(kickAngle);
end
