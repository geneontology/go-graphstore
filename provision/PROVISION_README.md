# Provision Locally

## Requirements 

- The steps below were successfully tested using:
    - Ansible   (2.10.7) Python (3.8.5)

#### DNS 

You can just add a record to /etc/hosts.

The hostname specified by this record will be used by the apache proxy 
to forward traffic to the graphstore container.

Replace variable GRAPHSTORE_SERVER_NAME with the hostname accordingly in vars.yaml.

Note: This variable can also be passed using the -e option.

```
# /etc/hosts for default value for GRAPHSTORE_SERVER_NAME
# use the ip address of the host machine
# On mac for example use `ipconfig getifaddr en0`
XXX.XXX.XXX.XXX graphstore.example.com
```

#### About Journal
The journal is downloaded from url specified by the variavle `remote_journal_gzip`. see vars.yaml

Note: The download is skipped if a journal is already in place.

#### Stage Locally

Clone the repo, build the docker image and finally copy all template files such as docker-compose.yaml 

```sh
cd provision

// Make sure this is an abosulte path.
export STAGE_DIR=...

// Using this repo and master branch
ansible-playbook -e "stage_dir=$STAGE_DIR" -i "localhost," --connection=local build_image.yaml 
ansible-playbook -e "stage_dir=$STAGE_DIR" -i "localhost," --connection=local stage.yaml 

// Or to specify a forked repo and different branch ...
ansible-playbook -e "stage_dir=$STAGE_DIR" -e "repo=https://github.com/..." -e "branch=..." -i "localhost," --connection=local build_image.yaml 
ansible-playbook -e "stage_dir=$STAGE_DIR" -e "repo=https://github.com/..." -e "branch=..." -i "localhost," --connection=local stage.yaml 
```

#### Start Docker Containers using docker-compose

Start containers access graphstore using the browser 
at http://{{ GRAPHSTORE_SERVER_NAME }}/blazegraph  (http://graphstore.example.com/blazegraph if using default)

```
cd $STAGE_DIR

docker-compose -f docker-compose.yaml up -d
```

#### Other useful docker-compose commands

```
// Tail logs of all containers amigo and apache_amigo
docker-compose -f docker-compose.yaml logs -f  

// Bring all containers and remove them
docker-compose -f docker-compose.yaml down
```

#### Accessing Containers using docker command

```sh
// List containers.
docker ps

// Amigo
docker exec -it graphstore /bin/bash

// Proxy
docker exec -it apache_graphstore /bin/bash
```
