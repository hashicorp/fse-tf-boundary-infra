set -e
sudo chmod 666 /var/run/docker.sock

VAULT_IMAGE="hashicorp/vault"
declare VAULT_CONTAINERS=("vault-0" "vault-1" "vault-2")
export VAULT_ADDR=http://localhost:8201
export DIR=~

docker network create --driver bridge vault

port=8201
echo "starting vault port address mapping is ::8200 >> $port
"
for container in ${VAULT_CONTAINERS[@]}
do
    echo "Creating ${container?}...
    "
    echo "${container?} vault mapped port is localhost:$port
    "
    sudo docker create \
        --name=${container?} \
        --hostname=${container?} \
        --network=vault \
        -p ${port?}:8200 \
        -e VAULT_ADDR="http://localhost:8200" \
        -e VAULT_CLUSTER_ADDR="http://${container?}:8201" \
        -e VAULT_API_ADDR="http://${container?}:8200" \
        -e VAULT_RAFT_NODE_ID="${container?}" \
        -v ${container?}:/vault/file:z \
        --privileged \
        ${VAULT_IMAGE?} vault server -config=/vault/config.hcl

    docker cp /home/ubuntu/vault/config.hcl ${container?}:/vault

    port=$((port+1))
done

echo 'starting docker containers'
for container in ${VAULT_CONTAINERS[@]}
do
    echo "Starting ${container?}"
    sudo docker start ${container?}
done

sleep 5

echo 'initilizing cluster + exporting seal keys and tokens...
'
# -n = number of key shares. 
# -t threshold for unseal.
initRaw=$(docker exec -ti ${VAULT_CONTAINERS[0]?} vault operator init -format=json -n 1 -t 1)
unseal=$(echo ${initRaw?} | jq -r '.unseal_keys_b64[0]')
rootToken=$(echo ${initRaw?} | jq -r '.root_token')

echo "unsealing ${VAULT_CONTAINERS[0]?}..."
docker exec -ti ${VAULT_CONTAINERS[0]?} vault operator unseal ${unseal}

echo 'Waiting cluster initialization and unseal operation...
'
sleep 10

for container in "${VAULT_CONTAINERS[@]}"
do
    if [[ "${container?}" == "${VAULT_CONTAINERS[0]?}" ]]
    then
        continue
    fi
    echo "joining ${container?} to raft cluster...
    "
    docker exec -ti ${container?} vault operator raft join http://${VAULT_CONTAINERS[0]?}:8200 &> /dev/null

    echo "unsealing ${container?}
    "
    sleep 2
    docker exec -ti ${container?} vault operator unseal $unseal &> /dev/null

done

echo "Attempting login...
"
vault login $rootToken

echo "Displaying Raft Peers...
"
vault operator raft list-peers

sudo cat << EOF > /home/ubuntu/vault/init
rootToken: $rootToken
unsealKey: $unseal
EOF