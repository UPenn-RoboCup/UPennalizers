function mat = luaarray2mat(st)
  % st is a struct in the lua table format with fields
  %   width, height, dtype, data


  % convert hex string to decimal
  sz = st.width*st.height * st.dtype.nbytes;
  dec = uint8(hex2dec(reshape(st.data, [2, sz])'));

  % cast to correct datatype
  mat = typecast(dec, st.dtype.name);

  % reshape wrt to width/height
  mat = reshape(mat, [st.width, st.height])';

end
