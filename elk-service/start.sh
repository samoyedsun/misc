#docker run -d -it -v "$PWD/esdata":/usr/share/elasticsearch/data --name elas elasticsearch:6.4.2
docker run -d -it --name elas elasticsearch:6.4.2
docker run -d -it -p 5601:5601 --link elas:elasticsearch --name kibana kibana:6.4.2
docker run -d -it -v "$PWD/beatstart.sh":/root/beatstart.sh -v "$PWD/filebeat.yml":/root/filebeat.yml -p 80:80 --link elas:elasticsearch --name beat samoyedsun/base:v8 bash /root/beatstart.sh
