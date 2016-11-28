# Learn to Dodge
cat training_data_dodge_* > master_training_data_dodge.txt
lines=`wc master_training_data_dodge.txt | awk {'print $1'}`
echo "./train master_training_data_dodge.txt $lines 5"
./train master_training_data_dodge.txt $lines 5

# Rename the xml files
mkdir -p dodge
mv *.xml dodge/

# Learn direction
cat training_data_dir_* > master_training_data_dir.txt
lines=`wc master_training_data_dir.txt | awk {'print $1'}`
echo "./train master_training_data_dir.txt $lines 15"
./train master_training_data_dir.txt $lines 15

# Rename the xml files
mkdir -p dir
mv *.xml dir/

