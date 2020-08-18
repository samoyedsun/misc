pids=`ps -ef | grep -v grep | grep python | grep main | awk '{print $2}'`
for pid in $pids; do
    kill -15 $pid
    sleep 5
    kill -9 $pid
    echo "close "$pid" success!"
done
echo "done!"
