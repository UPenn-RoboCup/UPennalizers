module(..., package.seeall);

require('walk')
require('gcm')
require('Config')

function entry()
  print(_NAME..' entry');
end

function update()
  return 'done';
end


function exit()
  walk.stop()
end
