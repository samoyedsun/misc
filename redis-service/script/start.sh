#!/bin/sh
DBDIR="./db/"
if [ ! -x $DBDIR ]; then
	mkdir $DBDIR
fi
LOGDIR="./logs/"
if [ ! -x $LOGDIR ]; then
	mkdir $LOGDIR
fi
redis-server ./etc/redis.conf
