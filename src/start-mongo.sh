docker run -it -d -p 27017:27017 \
    -v ${HOME}/data/mongo:/data/db \
    -e MONGO_INITDB_ROOT_USERNAME=bcwallet \
    -e MONGO_INITDB_ROOT_PASSWORD=2habYaVFQFKmuji5 \
    --name mongo mongo
