# /bin/bash

set -x

nginx
exec /opt/filebeat/filebeat -e -c ./filebeat.yml
