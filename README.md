# docker-swarm-persistent-storage
This repo contains 2 working examples of using Digital Ocean Spaces as a persistent storage solution for docker swarm. 

- In local dev environment, you need to install the docker plugin manual. 
- In production (docker swarm) you can use the used swarm:exec image to install the docker plugin globally on all nodes.

1. Create a new space in Digital Ocean and make sure to upload a file through the DO interface. This is *very* important, otherwise you'll get ```chmod``` or ```input/output``` errors. I've filed a bug report to DO support about this.
2. If you're mounting a subfolder in your DO space, make sure to upload a random file through the DO interface there as well! 
3. Get an API key in Digital Ocean for the spaces API.

I prefer the s3fs option, because it uses secrets in production and doesn't require a config file in 2 necessary folders, along with a fuse install on the server.
The (in my usecases minor-)downside of using s3fs is when mounting several subfolders in one DO space to several volumes, s3fs does something weird with those subfolders; you can't just navigate through them in some use cases. 
When I tested this with rclone, I had no problems and could simply navigate through all those subfolders from within a 'higher level volume mount'. 

Todo:
- I could not get a mongodb container to work with a s3fs mounted volume. I keep getting permission errors for WiredTiger

## s3fs example
You cannot use the same volume names, so if you want to use 1 Digital Ocean Space and create multiple volumes with it, you'll have to use subfolders to mount.


### Local dev environment

install docker plugin:
```
# uid 1000 is the user node which is used in storage/Dockerfile
# replace `yourkey`, `yoursecret` and `https://ams3.digitaloceanspaces.com` with your own values in the following docker plugin command:

docker plugin install --alias s3fs mochoa/s3fs-volume-plugin --grant-all-permissions AWSACCESSKEYID=yourkey AWSSECRETACCESSKEY=yoursecret DEFAULT_S3FSOPTS='allow_other,uid=1000,gid=1000,url=https://ams3.digitaloceanspaces.com,use_path_request_style,nomultipart'
```
In the `docker-compose.s3fs.yml` file, the name option for volume s3fs_do_space needs to be your digital ocean space, for example `name: "testspace"`.

You can rebuild everything using:
```
./rebuild-s3fs.sh
```

If you have a test.txt file in the root of your digital ocean space, you should now see it at
`http://localhost:3000/storage/test.txt`
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

If you have a test.txt file in the root of your digital ocean space, you should now see it at
`http://localhost:3000/storage/test.txt`
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
