#!/bin/bash

VAULT_CONTAINERS=('vault-0' 'vault-1' 'vault-2')

for container in ${VAULT_CONTAINERS[@]}
do
    sudo docker rm ${container?} --force
    sudo docker volume rm ${container?}
done

sudo docker network rm vault

sudo docker logs vault-1

 sudo docker ps -a



docker exec -ti vault-1 vault operator raft join http://vault-0:8200
docker exec -ti vault-1  vault operator unseal $unseal