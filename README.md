boundary aws infrastructure for Boundary demos

Changelog:
===
- Migrated away from BOYK to AWS generated RSA/SSH Keys
- Updated terraform syntax to 1.0+
- Removed indiviudal resource tagging in favor of provider level default tags
- Migrate away from RDS for provisioning/deprovisioning speed + cost savings
- Migrate away from load balencer for cost savings (single controller architecture)
- Added stand alone ec2 instance hosting a 3 node vault cluster 
- Installed TF push on the vault cluster to send vault connection info to other workspaces
- Northwinds psql database and roles for boundary demo - 12.15.21
- Configured TFC provider to push kms_key_id to the boundary config workspace 12.17.21

Todo:
===
- Update Boundary scope structure to something more ATARC-y
- Add Worker into Azure
- Add Target to Azure (simple SSH)
- Setup worker tags for target aware workers: https://learn.hashicorp.com/tutorials/boundary/target-aware-workers?in=boundary/configuration
    - psql in aws
    - ssh in aws
    - ssh in azure
    - RDP in Azure? 

- Establish demo flow and test all use cases

Stretch Goals:
===
- OIDC with vault or auth0
- Add an Azure dynamic Host Set: https://learn.hashicorp.com/tutorials/boundary/cloud-host-catalogs
