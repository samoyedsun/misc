arr=`find . -name *.gz`
for data in ${arr[@]}
do
    gzip -d $data
    echo "gzip -d "$data
done
