sed -i -e "s#LOCAL_HOST#${LOCAL_HOST}#g" ssweb.yml
sed -i -e "s#LOCAL_HOST#${LOCAL_HOST}#g" ssmgr.yml
docker run --rm -it -d -p 13003:13003 -p 8972:8972 --name ssproxy samoyedsun/ssproxy ss-server -s 0.0.0.0 -p 13000 -k 123 -m aes-256-cfb -u --fast-open --manager-address 0.0.0.0:8972
docker run --rm -it -d -v $PWD/ssmgr.yml:/root/.ssmgr/default.yml -p 8971:8971 --name ssmgr samoyedsun/ssmanager ssmgr
docker run --rm -it -d -v $PWD/ssweb.yml:/root/.ssmgr/default.yml -p 8970:8970 --name ssweb samoyedsun/ssmanager ssmgr
