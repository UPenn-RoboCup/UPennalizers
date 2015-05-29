local Z = require('Z')

src = "lua c api:  how to push a string with a null character in the middle?";
print(src);
print(#src);
src_c = Z.compress(src, #src)
print(#src_c);
src_uc = Z.uncompress(src_c, #src_c)
print(#src_uc);
print(src_uc);
