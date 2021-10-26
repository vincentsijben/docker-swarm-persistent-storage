docker-compose -f docker-compose.s3fs.yml down # take down all containers
docker rm -f $(docker ps -a -q) # remove all containers
# docker rmi -f $(docker images -q) # remove all images
docker volume rm $(docker volume ls --filter dangling=true -q) #remove all volumes
# docker plugin rm $(docker plugin ls -q) -f # remove plugin

#install plugin
# replace key,secret with your own values
# AWSACCESSKEYID_FILE=`cat ./secrets/aws_accesskey_id.txt`
# AWSSECRETACCESSKEY_FILE=`cat ./secrets/aws_secret_accesskey.txt`
# docker plugin install --alias s3fs mochoa/s3fs-volume-plugin --grant-all-permissions \
#   AWSACCESSKEYID=$AWSACCESSKEYID_FILE \
#   AWSSECRETACCESSKEY=$AWSSECRETACCESSKEY_FILE

docker-compose -f docker-compose.s3fs.yml up -d # run all containers

echo
echo "------------------------------------------------"
echo "open filebrowser: http://localhost:4000 and login with 'username' and 'password'"
echo "check alpine container and /mnt folder."
echo "------------------------------------------------"

# for testing: docker run -ti --rm -v bm-db6:/mnt ubuntu bash