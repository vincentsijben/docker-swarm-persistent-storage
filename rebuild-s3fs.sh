docker context use default
docker-compose -f docker-compose.s3fs.yml down # take down all containers
docker rm -f $(docker ps -a -q) # remove all containers
docker rmi -f $(docker images -q) # remove all images
docker volume rm $(docker volume ls --filter dangling=true -q) #remove all volumes
docker plugin rm $(docker plugin ls -q) -f # remove plugin

#install plugin
# replace key,secret with your own values
AWSACCESSKEYID_FILE=`cat ./secrets/digital_ocean_access_key.txt`
AWSSECRETACCESSKEY_FILE=`cat ./secrets/digital_ocean_secret_key.txt`
docker plugin install --alias s3fs mochoa/s3fs-volume-plugin:v2.0.8 --grant-all-permissions \
  AWSACCESSKEYID=$AWSACCESSKEYID_FILE \
  AWSSECRETACCESSKEY=$AWSSECRETACCESSKEY_FILE

AWSACCESSKEYID_FILE=`cat ./secrets/linode_access_key.txt`
AWSSECRETACCESSKEY_FILE=`cat ./secrets/linode_secret_key.txt`
docker plugin install --alias linode mochoa/s3fs-volume-plugin:v2.0.8 --grant-all-permissions \
  AWSACCESSKEYID=$AWSACCESSKEYID_FILE \
  AWSSECRETACCESSKEY=$AWSSECRETACCESSKEY_FILE

docker-compose -f docker-compose.s3fs.yml up -d # run all containers

echo
echo "------------------------------------------------"
echo "open filebrowser: http://localhost:4000 and login with 'username' and 'password'"
echo "check alpine container and /mnt folder."
echo "------------------------------------------------"

# for testing: docker run -ti --rm -v [volumename]:/mnt ubuntu bash