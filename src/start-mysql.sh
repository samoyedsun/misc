docker run -it -d -p 3306:3306 \
	-v ${HOME}/data/mysql:/var/lib/mysql \
	-e MYSQL_USER=game \
	-e MYSQL_PASSWORD=lyZMD8HKeMe6Gz \
	-e MYSQL_DATABASE=game \
	-e MYSQL_ROOT_PASSWORD=lyZMD8HKeMe6Gz \
	--name mysql mysql:5.7 \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_unicode_ci
