function st = lua2mat(str)
% function that will convert serialized Lua data into
% a matlab struct
%
% NOTE: This is not a complete solution, some serialized 
%       types are not supported

  str = char(str);
  str = regexprep(str, '\{', 'struct(');  
  str = regexprep(str, '\}', ')');  
  str = regexprep(str, '=', ',');  
  str = regexprep(str, '\[\"', '''');  
  str = regexprep(str, '\"\]', '''');  
  str = regexprep(str, '\"', '''');  
  str = regexprep(str, ',\)', ')');  

  % convert any arrays to array format (only 1D arrays are supported)
  [matched, split] = regexp(str, 'struct\(\[.+?\)', 'match', 'split');
  if ~isempty(matched)
    str = split{1};
    for i = 1:length(matched)
      % convert table/array format to array
      match = regexprep(matched{i}, 'struct\(', '[');
      match = regexprep(match, '\[[0-9]*\],', '');
      match = regexprep(match, '\)', ']');
      str = strcat(str, match, split{i+1});
    end
  end

  str=str(2:end);
  st = eval(str);

end
