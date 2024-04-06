# Plain Wordpress Site in ECS
This repo will build a WordPress docker image using Packer and deploy it in an ECS cluster using Fargate.\
The image is built on ubuntu 22.04 and configurations are handled by ansible playbooks. Ansible is removed after configuration is completed. The image is tagged and pushed to a private docker registry using provided credentials. The wordpress app is modified to accept environment variables for DB configuration.\
The image is pushed to a protected docker repository. Credentials are required to push and pull images.\
The AWS resources are created to serve the app in ECS using Fargate. Access is open to the world so make sure to secure it before running in production. No steps to ensure HA have been taken.\
Secrets are handled via environment variables so make sure to set them and test them.

## Requirements
### Local:
- docker (v20.10.21+)
- terraform (v1.3.4+)
- packer (v1.8.4+)
### Other:
- password protected private docker registry (tested with Nexus)
- AWS account and user with programmatic access and permissions:
  - AmazonEC2FullAccess
  - AmazonRDSFullAccess 
  - IAMFullAccess
  - SecretsManagerReadWrite
  - AmazonECS_FullAccess
  - AWSKeyManagementServicePowerUser
  - AmazonSESReadOnlyAccess 

## Contents
```
ansible\          # Contains ansible playbooks, templates and configuration to provision the image
packer\           # Contains the resources for packer
  |_scripts\      # Contains bash scripts for packer to run for provisioning the image
  |_vars.pkr.hcl  # Variables for packer
  |_main.pkr.hcl  # The main packer configuration file
terraform\        # Contains the Terraform IaaC configurations 
  |_main.tf       # Creates the mail resources like ECS cluster, secrets and roles/policies
  |_provider.tf   # Configures the provider (AWS) to use
  |_rds.tf        # Creates the RDS database to use
  |_sgs.tf        # Creates the Security Groups for the resources
  |_variables.tf  # Defines the variables used
  |_vpc.tf        # Creates the VPC and subnets for ECS and RDS
```

---
## Packer run steps
To create the image follow the steps below:

1. Go to the `packer/` directory
```
cd packer
```
2. Set the required envirinmental variables:
```
# the registry to push the image to
export DOCKER_REGISTRY_HOST="some.registry.com"
# a user with push permissions to the registry
export DOCKER_REGISTRY_USER="my_username"
# the password for that user
export DOCKER_REGISTRY_PASS="my_password"
```
3. The repository to use in the registry is set in `packer/vars.pkr.hcl` to the default value or `romanos`. It's variable `docker_repository`. I assume that this will be standard and set to something like `my_wp`. Replace it as needed.
4. The version to tag the image with is also set in `packer/vars.pkr.hcl`. This is intentional so that it gets updated with each revision. It's variable `app_version`.
5. Initialize the project to download Packer plugin binaries.
```
packer init .
```
6. Format the HCL2 configuration files.
```
packer fmt .
```
7. Validate the syntax.
```
packer validate .
```
8. Build the image.
```
packer build .
```
9. Finally, if all went well, take note of the created image by looking at the last lines of output.
```
docker.image-builder: Imported Docker image: <DOCKER_REGISTRY_HOST>/<REPOSITORY>/wp:0.1 with tags ...
```

The resulting image requires the following environment variables to configure access to a DB:
- `DB_NAME` - The name of the database to use. Must be prefoxed with `wp_`
- `DB_USER` - The user to login with full access to to the database
- `DB_PASSWORD` - The password for the user
- `DB_HOST` - The host where the database lives in

## Terraform run steps
The Terraform configurations will create a dev setup for this application.\
First a VPC and subnets are created. The region is specified by the user but the AZ used is always `a`. The VPC has a public and a private subnet. There is also a private subnet in region `b` because it is required for creating subnet groups.\
The image is ran in ECS using Fargate. The main benefit of Fargate over EC2 is that no management and maintenance of the hosts is required. The service has a Security Group allowing TCP traffic only to port 80.\
A public RDS database is created with a Security Group allowing only resources using the service security Group to connect.

To create the resources in AWS, follow the steps below:

1. Go to the `terraform/` directory
```
cd ../terraform
```
2. Set the required envirinmental variables:
```
# the image to use including the registry and repository as copied from step 9 above
export TF_VAR_DOCKER_REGISTRY_IMG="<DOCKER_REGISTRY_HOST>/<REPOSITORY>/wp:0.1"
# a user with pull permissions to the registry
export TF_VAR_DOCKER_REGISTRY_USER="my_username"
# the password for that user
export TF_VAR_DOCKER_REGISTRY_PASS="my_password"
# the access key id of the AWS user with the permissions specified in this doc
export TF_VAR_AWS_ACCESS_KEY_ID="AKIAAAAAAAAAAAAAAAAAA"
# the secret key for that user
export TF_VAR_AWS_SECRET_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
# the region to create the resources in
export TF_VAR_AWS_REGION="eu-central-X"
```
3. Initialize the project to download Terraform plugin binaries.
```
terraform init
```
4. Format the TF configuration files.
```
terraform fmt
```
5. Validate the syntax.
```
terraform validate
```
6. Check what resources will be created.
```
terraform plan
```
7. If satisfied, create the resources.
```
terraform apply --auto-approve
```
8. Sometimes the db name is taken and cannot be used (same was happening when I was using a random one). This results in the process failing.\
You can change variable `aws_rds_db_user` to something else in `variables.tf`. Make sure to delete everything with `terraform destroy --auto-approve` and run steps 5-7 again.
9. You can log in to the AWS Console to retrieve the public IP address of the task. Go to the page of ECS and change to the region specified above. Click on the cluster imaginatively named `cluster` and in the Services tab click on the service named `service`. Go to the Tasks tab and click on the single task. It might be in `PENDING` state. Under Network you will find the Public IP. The http service should be listenning on that IP on port 80.

---
## Improvements
1. Use remote ansible execution if possible with docker to save on time since installing and removing ansible on the remote host takes a while.
2. Use more variables with packer to configure the image better like:
   1. path for wp to be served
   2. version of wp to download
   3. version of PHP to install
4. Use a lightweight image of Ubuntu or Debian
5. Add SSL termination by using an application load balancer like HAproxy, or a managed ELB or even a Traefik instance in the cluster.
6. Improve HA by using a multi-az deployment for RDS.
7. Run multiple containers to have a more robust application, balance the load and support more users.
8. Limit the required AWS permissions of the user to the minimum.
9. Use off-the-shelf ansible roles like geerlinguy's install php, nginx, etc.
10. Use the oficial image for worpress and built on top if needed.
11. Use supervisord in the container to run nginx and php processes and push all logs to the docker stdout.
12. Collect logs with loki and use grafana to access them
13. Attatch NFS volumes for persistent storage or use S3
14. Install the nginx waf plugin with some rules tested for WordPress to increase security.
15. Strengthen file permissions for wordpress. I'm not sure what files/folders are required to have write or execute permissions so I went with common permissions for drupal on FPM.
16. Create and use a different RDS user for WordPress with permissions only to the necessary db.
17. Use an RDS instance in a private subnet.
18. General code cleanup (the naming of resources could use a spice-up) and better commenting.

