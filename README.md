# docker-swarm-persistent-storage
This repo contains 2 working examples of using Digital Ocean Spaces as a persistent storage solution for docker compose/swarm. 

- In local dev environment, you need to install the docker plugins manually (see ```rebuild-s3fs.sh``` or ```rebuild-rclone.sh```). 
- In production (docker swarm) you can use the used swarm:exec image to install the docker plugins globally on all nodes.

## Setting up the Digital Ocean Space
1. Create a new space in Digital Ocean
2. If you use s3fs, I currently have no other solution to make it work except for having a random file uploaded through the DO Spaces interface first. This is *very* important, otherwise you'll get ```chmod``` or ```input/output``` errors. 
  * If you're mounting a subfolder in your DO space with s3fs, make sure to upload a random file through the DO interface there as well!
  * I've filed a bug report to DO support about this, but they said it had something to do with s3fs. 
  * When using rclone, you don't have this kind of errors.
 
3. Get an API key in Digital Ocean for the spaces API.

### Important
S3fs is not designed to show you directories and instead shows you it as a file. 
S3fs doesn’t support directories and doesn’t show if it is not created on s3fs. 
S3FS uses special 'hidden' zero byte files to represent directories, 
because S3 doesn't really support directories. 
If you try a mkdir on your mounted s3fs bucket then use the AWS file browser you 
should see this in action. If your S3 bucket contains a directory structure that 
was not created by S3FS then S3FS won't recognise that structure. 
S3FS only works well with buckets that are only ever manipulated using S3FS.

While I don't like to have a config file and 2 necessary folders ánd a fuse install on the server, maybe it's better to use rclone for regular file and folder work

### Todo
- I could not get a mongodb container to work with a s3fs mounted volume. I changed the uid and gid to 999, that helps with WiredTiger permission errors. But the db won't start up and keeps restarting...

## s3fs example
You cannot use the same volume names, so if you want to use 1 Digital Ocean Space and create multiple volumes with it, you'll have to use subfolders to mount.


### Local dev environment
In the `docker-compose.s3fs.yml` file, the name option for volume persistent_data needs to be your digital ocean space, for example `name: "testspace"`.

You can rebuild everything using:
```
./rebuild-s3fs.sh
```

You can check the filebrowser at `http://localhost:4000` using `username` as the username and `password` as the password

### Production environment (docker swarm)

You can use this trick in your docker swarm stack yml, to install the docker plugin globally (based on https://github.com/BretFisher/dogvscat/blob/master/stack-rexray.yml).
It uses secrets (so you'll have to create them).

```
  plugin-s3fs:
    image: mavenugo/swarm-exec:17.03.0-ce
    secrets:
      - aws_accesskey_id
      - aws_secret_accesskey
    environment:
      - AWSACCESSKEYID_FILE=/run/secrets/aws_accesskey_id
      - AWSSECRETACCESSKEY_FILE=/run/secrets/aws_secret_accesskey
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    # you'll need uid=1000,gid=1000,allow_other to be able to get correct file permissions for the node user
    command: sh -c "docker plugin install --alias s3fs mochoa/s3fs-volume-plugin --grant-all-permissions AWSACCESSKEYID=$$(cat $$AWSACCESSKEYID_FILE) AWSSECRETACCESSKEY=$$(cat $$AWSSECRETACCESSKEY_FILE) DEFAULT_S3FSOPTS='uid=1000,gid=1000,allow_other,url=https://ams3.digitaloceanspaces.com,use_path_request_style,nomultipart'"
    deploy:
      mode: global
      restart_policy:
        condition: none
```

## rclone example

### Local dev environment

install docker plugin:
```
# Rename the rclone.conf.example to rclone.conf and put your own key, secret and endpoint into this file. Hence, the 'name' of this config is `digitaloceanspaces`.
# Put this rclone.conf in your desired rclone/config folder.
# For local dev, I used the rclone/config and rclone/cache folders in my project for the necessary config/cache folders. Replace this with your own absolute path

# Run this manually:
docker plugin install rclone/docker-volume-rclone --alias rclone --grant-all-permissions config=/Users/vincent.sijben/Documents/GitHub/docker-swarm-persistent-storage/rclone/config cache=/Users/vincent.sijben/Documents/GitHub/docker-swarm-persistent-storage/rclone/cache
```
In the `docker-compose.rclone.yml` file, you can now set the remote option `[name of config]:[name of digital ocean space]`, for example `digitaloceanspaces:testspace`.

You can rebuild everything using:
```
./rebuild-rclone.sh
```

You can check the filebrowser at `http://localhost:4000` using `username` as the username and `password` as the password

### Production environment (docker swarm)

Your host needs to have fuse installed and 2 folders created:
```
sudo apt-get -y install fuse
sudo mkdir -p /var/lib/docker-plugins/rclone/config
sudo mkdir -p /var/lib/docker-plugins/rclone/cache
```
Copy over your local `rclone.conf` to the config folder on the host.

You can use this trick in your docker swarm stack yml, to install the docker plugin globally (based on https://github.com/BretFisher/dogvscat/blob/master/stack-rexray.yml):
```
  plugin_rclone:
    image: mavenugo/swarm-exec:17.03.0-ce
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    command: sh -c "docker plugin install rclone/docker-volume-rclone args='-v' --alias rclone --grant-all-permissions"
    deploy:
      mode: global
      restart_policy:
        condition: none
```
