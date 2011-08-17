require('unix')

print("Starting DCM lua initialization");

unix.chdir('/home/nao/Player/');

require('player');

print("setting post process...");

postProcess = player.update;

