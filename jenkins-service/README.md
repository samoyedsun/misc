# jenkins-service
基于docker的jenkins自动化服务

初始化
```shell
sudo yum update -y
sudo yum install git -y
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
git clone https://github.com/samoyedsun/jenkins-service.git
sh jenkins-service/start.sh
```
