cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;

require('init')
require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')


print ('Body.get_time() = ' .. Body.get_time())
