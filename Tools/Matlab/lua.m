function h = lua()
  h.load_config = @load_config;
  h.load_cm_struct = @load_cm_struct;

  % add lua package path and cpath
  mexlua('run', 'dofile(''initm.lua'')');
  %  mexlua('add_path', '../../Player/Vision');
  %  mexlua('add_cpath', '../../Lib/Modules/Util/CArray');
  %  mexlua('get_path');
  %  mexlua('get_cpath');
  
  function [platform, ncamera] = load_config()
    % load Config
    % For require, must to ' module = require 'module' '
    mexlua('run', 'Config = require ''Config''');
    % load selected config fields
    platform = mexlua('get_field', 'Config.platform.name');
    ncamera = mexlua('get_field', 'Config.camera.ncamera');
  end

  function cm = load_cm_struct(cmkey)
    mexlua('run', [cmkey ' = require ''' cmkey '''']);
    cm = mexlua('get_field', [cmkey '.shared']);
  end

end
