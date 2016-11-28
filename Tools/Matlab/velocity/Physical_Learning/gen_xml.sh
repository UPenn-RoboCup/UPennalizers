files=`ls logfiles/*.txt`
for f in $files;
do
echo "Training on "$f
lines=`[ -f $f ] && wc $f | awk {'print $1'}`
echo "./train $f $lines"
./train $f $lines
done

# http://stackoverflow.com/questions/3746947/get-just-the-integer-from-wc-in-bash
