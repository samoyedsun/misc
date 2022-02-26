docker exec -it \
  $(docker container ls --filter name=_mongo -q) \
  mongorestore \
    --username=admin \
    --password=1AAAbbbCCCddd2\
    --db=game5 \
    --authenticationDatabase=admin \
    --drop \
    /root/data/20201120050001/game5/
