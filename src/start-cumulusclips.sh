docker run --name cumulusclips-mysql \
	-e MYSQL_ROOT_PASSWORD=mysecretpassword \
	-e MYSQL_DATABASE=cumulusclipsdb \
	-e MYSQL_USER=cumulusclipsuser \
	-e MYSQL_PASSWORD=cumulusclipsdbpasswd -d mysql:5.7
docker run -d -p 2020:80 \
	--link cumulusclips-mysql:db quantumobject/docker-cumulusclips
