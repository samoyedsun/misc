sudo docker run \
    -u root \
    --rm \
    -d \
    -p 80:8080 \
    -v $HOME/jenkins-home-data:/var/jenkins_home \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/share/zoneinfo/Asia/Shanghai:/etc/localtime \
    --name jenkins samoyedsun/blueocean
