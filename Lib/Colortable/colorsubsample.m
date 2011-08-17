function scoresub = colorsubsample(im, icolor)

persistent BLOCK

if isempty(BLOCK),
  BLOCK.nblk = 4;
  BLOCK.nx = size(im,1);
  BLOCK.nx2 = BLOCK.nx/BLOCK.nblk;
  BLOCK.ny = size(im,2);
  BLOCK.ny2 = BLOCK.ny/BLOCK.nblk;
  BLOCK.x = repmat([1:BLOCK.nx]',[1 BLOCK.ny]);
  BLOCK.y = repmat([1:BLOCK.ny]',[BLOCK.nx 1]);
  blk = reshape(1:BLOCK.nx*BLOCK.ny,[BLOCK.nblk BLOCK.nx/BLOCK.nblk ...
		    BLOCK.nblk BLOCK.ny/BLOCK.nblk]);
  blk = permute(blk,[1 3 2 4]);
  BLOCK.blk = reshape(blk, ...
		      [BLOCK.nblk^2 BLOCK.nx*BLOCK.ny/ ...
		    (BLOCK.nblk^2)]);
  BLOCK.blk = uint32(BLOCK.blk);
end
  
[class, score] = colorclass(im);

score(class ~= icolor) = 0;

blk_score = score(BLOCK.blk);
scoresub = sum(blk_score);

scoresub = reshape(scoresub, [BLOCK.nx2 BLOCK.ny2]);
scoresub = scoresub./(BLOCK.nblk^2);
