for port in $@; do
    pid=`sudo netstat -tunlp | grep 0.0.0.0:$port | awk '{print $7}' | awk -F"/" '{ print $1 }'`
    if [ ! $pid ]; then
        echo "port:"$port" not exits!"
    else
	kill -15 $pid
        echo "close port:"$port
    fi
done
echo "done!"
