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

tfh pushvars -org PublicSector-ATARC -name fse-tf-atarc-boundary-config -var 'public_vault_ip=' -overwrite public_vault_ip
tfh pushvars -org PublicSector-ATARC -name fse-tf-atarc-boundary-config -var 'private_vault_ip=' -overwrite private_vault_ip
tfh pushvars -org PublicSector-ATARC -name fse-tf-atarc-boundary-config -svar 'vault_token=' -overwrite vault_token

