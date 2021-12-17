TFC_TOKEN=$1
unseal=$(cat init.json | jq -r '.unseal_keys_b64[0]')
rootToken=$(cat init.json | jq -r '.root_token')
tfh pushvars -org PublicSector-ATARC -name fse-tf-atarc-boundary-config -var "vault_token=${rootToken}" -overwrite vault_token -token $TFC_TOKEN
tfh pushvars -org PublicSector-ATARC -name fse-tf-atarc-boundary-config -var "vault_unseal=${unseal}" -overwrite vault_unseal -token $TFC_TOKEN
