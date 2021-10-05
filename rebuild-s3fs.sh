docker-compose -f docker-compose.s3fs.yml down # take down all containers
docker rm -f $(docker ps -a -q) # remove all containers
docker rmi -f $(docker images -q) # remove all images
docker volume rm $(docker volume ls --filter dangling=true -q) #remove all volumes
docker plugin rm $(docker plugin ls -q) -f # remove plugin

#install plugin
# replace key,secret and the url with your own values
docker plugin install --alias s3fs mochoa/s3fs-volume-plugin --grant-all-permissions AWSACCESSKEYID=key AWSSECRETACCESSKEY=secret DEFAULT_S3FSOPTS='allow_other,uid=1000,gid=1000,url=https://ams3.digitaloceanspaces.com,use_path_request_style,nomultipart'

docker-compose -f docker-compose.s3fs.yml up -d # run all containers

echo
echo "------------------------------------------------"
echo "open filebrowser: http://localhost:4000 and login with 'username' and 'password'"
echo "open website: http://localhost:3000"
echo "------------------------------------------------"