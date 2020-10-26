docker run -d -p 9980:80 -p 3306:3306 \
	-e MYSQL_ROOT_PASSWORD='123456' \
	-v ${HOME}/zentaopms:/www/zentaopms \
	-v ${HOME}/mysqldata:/var/lib/mysql \
	--name zentao-server \
	easysoft/zentao:12.3.3
