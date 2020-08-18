#!/bin/bash
logdir="./log/"
if [ ! -x $logdir ]; then
	mkdir $logdir
fi
ip="0.0.0.0"
port=$1
pass=$2
mode=$3
logp=$logdir"$1"".log"
nohup ss-server -s ${ip} -p $port -k ${pass} -m ${mode} > ${logp} 2>&1 & 
#  --fast-open
echo "port "$port" open done!"
