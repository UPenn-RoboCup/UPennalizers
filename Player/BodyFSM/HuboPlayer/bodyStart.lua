module(..., package.seeall);

require('Body')
require('walk')

function entry()
  print(_NAME..' entry');
  
  walk.start();
end

function update()
  return 'done';
end

function exit()
end
