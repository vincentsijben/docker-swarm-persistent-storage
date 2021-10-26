docker-compose -f docker-compose.rclone.yml down # take down all containers
docker rm -f $(docker ps -a -q) # remove all containers
docker rmi -f $(docker images -q) # remove all images
docker volume rm $(docker volume ls --filter dangling=true -q) #remove all volumes
docker plugin rm $(docker plugin ls -q) -f # remove plugin

#install plugin
docker plugin install rclone/docker-volume-rclone --alias rclone --grant-all-permissions \
  config=/Users/vincent.sijben/Documents/GitHub/docker-swarm-persistent-storage/rclone/config \
  cache=/Users/vincent.sijben/Documents/GitHub/docker-swarm-persistent-storage/rclone/cache

docker-compose -f docker-compose.rclone.yml up -d # run all containers

echo
echo "------------------------------------------------"
echo "open filebrowser: http://localhost:4000 and login with 'username' and 'password'"
echo "check alpine container and /mnt folder."
echo "------------------------------------------------"