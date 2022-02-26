docker stack rm mongo
docker volume rm mongo_db-certs
docker volume rm mongo_keys
docker volume rm mongo_logs
docker volume rm mongo_web-certs
docker secret rm charts-mongodb-uri
