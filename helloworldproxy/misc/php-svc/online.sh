netstat | grep :13 | awk '{split($5,a,":"); print $4 "    " a[1]}' | sort | uniq

