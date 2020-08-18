docker run -it \
    --rm \
    -d \
    -p 80:8000 \
    --workdir /root/src/ \
    -v $PWD/src/:/root/src/ \
    --name laravel samoyedsun/base \
    bash start.sh
