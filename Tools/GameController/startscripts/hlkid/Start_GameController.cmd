@echo off

set /P blue=Enter team number for blue (default is 0): 
set /P red=Enter team number for red (default is 0):

if %blue%x == x set blue=0 
if %red%x == x set red=0 
set broadcast=

echo Starting HL-Kid GameController, team %blue% plays in blue and team %red% plays in red

if %1x == x goto label
set broadcast=-broadcast %1
echo Broadcasting to subnet %1
:label

java -jar GameController.jar -hlkid %broadcast% %blue% %red%
