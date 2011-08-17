module(..., package.seeall);

require('Body')

function entry()
  print(_NAME.." entry");

end

function update()
  return 'done';
end

function exit()
end
