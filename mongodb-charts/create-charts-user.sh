docker exec -it \
  $(docker container ls --filter name=_charts -q) \
  charts-cli add-user --first-name "John" --last-name "Ma" \
  --email "18344141024@163.com" --password "123456" \
  --role "UserAdmin"
