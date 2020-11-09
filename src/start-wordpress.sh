docker run -d --privileged=true --name videoms -v ${HOME}/data/mysql:/var/lib/mysql -e MYSQL_DATABASE=wordpress -e MYSQL_ROOT_PASSWORD=233333  mysql
docker run -d --name videowp -e WORDPRESS_DB_HOST=mysql -e WORDPRESS_DB_PASSWORD=233333 -p 2020:80 --link videoms:mysql wordpress
