tagpath="/var/lib/mysql-files/dump.sql"
tmppath="/var/lib/mysql-files/tmp.sql"

mysql -e "SELECT concat('INSERT INTO ssweb.user(username, password, port, mode, hiredate) VALUES(\"', username, '\",\"',  password, '\",', port, ',\"', mode, '\",\"', hiredate, '\");') FROM ssweb.user INTO OUTFILE '"$tmppath"';"

echo "DROP TABLE IF EXISTS \`user\`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
SET character_set_client = utf8mb4 ;
CREATE TABLE \`user\`(
	\`uid\` int(11) NOT NULL AUTO_INCREMENT,
	\`username\` varchar(20) NOT NULL,
	\`password\` varchar(20) NOT NULL,
	\`port\` int(11) DEFAULT NULL,
	\`mode\` varchar(20) NOT NULL,
	\`hiredate\` timestamp NULL DEFAULT NULL,
	PRIMARY KEY (\`uid\`)) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;" > $tagpath

cat $tmppath >> $tagpath
rm $tmppath
cp -f $tagpath ./
