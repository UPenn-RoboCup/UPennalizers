key0 = dofile("km_WebotsNao_StandupFromBack.lua");
RAD = math.pi/180;

print("local mot = {};");
print("mot.servos = {");
str="    ";
for i=1,#key0.servos do
  str=str..string.format("%d,",key0.servos[i]);
end
print(str)
print("};");
print("mot.keyframes = {");

for i=1,#key0.keyframes do
  print("   {");
  print("     angles = vector.new({");

  str=  "         ";
  for j=1,2 do
    str=str..string.format("%.1f, ",key0.keyframes[i].angles[j]/RAD);
  end
  print(str)

  str=  "         ";
  for j=3,6 do
    str=str..string.format("%.1f, ",key0.keyframes[i].angles[j]/RAD);
  end
  print(str)

  str=  "         ";
  for j=7,12 do
    str=str..string.format("%.1f, ",key0.keyframes[i].angles[j]/RAD);
  end
  print(str)

  str=  "         ";
  for j=13,18 do
    str=str..string.format("%.1f, ",key0.keyframes[i].angles[j]/RAD);
  end
  print(str)

  str=  "         ";
  for j=19,22 do
    str=str..string.format("%.1f, ",key0.keyframes[i].angles[j]/RAD);
  end
  print(str)

  print("     })*math.pi/180,");
  print(string.format("     duration = %.3f;",key0.keyframes[i].duration));
  print("   },");
end

print("};");
print();
print("return mot;");
