boundary aws infrastructure for Boundary demos

Changelog:
===
- Migrated away from BOYK to AWS generated RSA/SSH Keys
- Updated terraform syntax to 1.0+
- Removed indiviudal resource tagging in favor of provider level default tags
- Migrate away from RDS for provisioning/deprovisioning speed + cost savings
- Migrate away from load balencer for cost savings (single controller architecture)

Todo:
===
- Add Vault container
- Northwinds psql Configuration
- Add Worker into Azure

Stretch Goals:
===
- Add an Azure dynamic Host Set: https://learn.hashicorp.com/tutorials/boundary/cloud-host-catalogs
- Target aware worker: https://learn.hashicorp.com/tutorials/boundary/target-aware-workers?in=boundary/configuration

