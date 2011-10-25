% contruct_array is a matlab struct that can be used to reconstruct 
% segmented arrays broadcasted by the monitor code

function h = construct_array(name)
  h.name = name;
  h.cimg = -1;
  h.part = [];
  h.nparts = -1;
  h.arrparts = {};
  h.update = @update;
  

  function [name, imgnum, partnum, parts] = parse_name(name)
    parse = regexp(name,'\.','split');
    name = parse{1};
    imgnum = str2num(parse{2});
    partnum = str2num(parse{3});
    parts = str2num(parse{4});
  end

  function arr = update(packet)
    arr = [];

    [name, imgnum, partnum, parts] = parse_name(packet.name);
    
    % check to make sure correct array
    if (strcmp(name,h.name) == 0)
      return;
    end

    if imgnum > h.cimg 
      % new image: clear data and start over
      h.cimg = imgnum;
      h.nparts = parts;
      h.part = zeros(parts,1);
    end
    
    % indicate which parts of the array have been received
    h.part(partnum) = 1;

    % add part of array to cell array
    h.arrparts{partnum} = luaarrstruct2mat(packet);

    % if entire array has been received
    if all(h.part)
      % make full array out of cell array
      arr = cat(1,h.arrparts{:});
    end
  end
end
