tmp=1
while true
do
	tmp=$[tmp+1];
	echo $((tmp%10));
	sleep $((tmp%10));
	sh ./dump.sh;
done
