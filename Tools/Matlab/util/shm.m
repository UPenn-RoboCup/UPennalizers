function h = shm(name)
% function that provides easy access to shared memory
%   for each key in the shared memory block, key,
%   a get_key() and set_key(val) function are created

  h.shmHandle = mexshm('new', name);
  pause(.2);

  % get shm keys
  keys = {};
  k = mexshm('next', h.shmHandle);
  while (strcmp(k, '') == 0)
    keys{end+1} = k;
    k = mexshm('next', h.shmHandle, k);
  end

  % create accessors
  for i = 1:length(keys)
    k = keys{i};
    h.(['get_' k]) = @() mexshm('get', h.shmHandle, k);
    h.(['set_' k]) = @(val) mexshm('set', h.shmHandle, k, double(val));
  end

end
