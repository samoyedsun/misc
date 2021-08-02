docker run -it -d \
 -p 13004:13003 \
 -e SS_PASS=huanying666 \
 -e SS_MODE=aes-256-cfb \
 --name ssproxy samoyedsun/ssproxy
