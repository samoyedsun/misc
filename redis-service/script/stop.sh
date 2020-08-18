#!/bin/sh 
IP="127.0.0.1"
redis-cli -h $IP -p 6379 -a DyDXgw60nhSMO0O7 shutdown
#如果无效就只能使用kill -9了
