echo "mongodb://admin:1AAAbbbCCCddd2@test-instance" | docker secret create charts-mongodb-uri -
docker stack deploy -c mongo-charts-docker-swarm.yml mongo
