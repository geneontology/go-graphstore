# Production Provisioning

#### Introduction

You are here because you are planning on deploying a new graphstore server and destroying the old one if any.

- If you want to get familiar with terraform and deploy on AWS, refer to [this document](../PROVISION_AWS_README.md).
- If you want to test the graphstore locally refer to [this document](../PROVISION_README.md).

We use terraform workspaces and S3 backend to store terraform state. 

- https://www.terraform.io/language/state/workspaces
- https://www.terraform.io/language/settings/backends/s3

#### Preparation

You need the following before you begin:

- Terraform
  - Terraform version v1.1.4 or higher
  - The aws credentials to access AWS account stored in ~/.aws/credentials.
    - see aws/provider.tf and note the default aws profile
  - The name of the s3 bucket used to store terraform state and read/write access to it.
  - The ssh keys used for this stack

- Ansible
  -  The s3cfg credentials to access the s3 bucket used to store the server's access log

#### Deploy The New Stack

Note you would need to create some files and modify them as stated below. These are listed in the .gitignore file 
and so git command will not list them.

These 2 are needed to deploy a new aws instance using terraform.
- backend.tf     
  - Points to terraform backend
- go-ssh.pub   
  - Public ssh key which will get added to the authorized keys of the new instance

These 2 are needed to deploy the server using ansible.
- s3cfg          
  - Needed by the server to populate the s3 bucket with apache logs
- go-ssh       
  - Private ssh key for ansible to access the remote aws instance

```sh
cd provision
cp production/backend.tf.sample aws/backend.tf # Now modify it with the name of the s3 bucket and the aws profile if it is not default
cp production/s3cfg.sample production/s3cfg    # Now populate this with the correct access/secret keys
cp production/production-vars.txt.sample production/production-vars.txt # Modify as needed. Used to override ansible variables from vars.yaml. 

cat aws/backend.tf
cat production/s3cfg
cat production/production-vars.txt

# Copy "ssh keys to the production directory production/go-ssh and production/go-ssh.pub"
cat production/go-ssh
cat production/go-ssh.pub

# Initialize using s3 backend
terraform -chdir=aws init                      # This is critical. The s3 backend must be configured correctly
terraform -chdir=aws workspace list            # This should list the existing workspaces.

# Create a workspace. Note how we append the date to the workspace name 
terraform -chdir=aws workspace new production-mm-dd-yy
terraform -chdir=aws workspace list            # confirm the new workspace is listed and is highlighted 
terraform -chdir=aws workspace show            # confirm this is the new workspace
terraform -chdir=aws show                      # should show nothing since nothing has been deployed in this new workspace

# Provision
chmod +x production/provision.sh
# You may want to change provision.sh          # for instance type, disk_size 
./production/provision.sh

# Overriden terraform variables 
cat production/production-vars.tfvars          # tags, disk_size, instance type

# What just happened?
terraform -chdir=aws output -raw public_ip     # shows elastic ip
terraform -chdir=aws output                    # shows all output 
terraform -chdir=aws show                      # shows what was deployed vpc, instance, ....

# On AWS Console,  you should see the new workspace listed under s3://bucket_name/env:/
```

#### Testing

Access using the browser at http://{{ GRAPHSTORE_SERVER_NAME `}}/blazegraph

- For details refer to testing section [this document](../PROVISION_AWS_README.md).

#### Destroy The Old Stack 

First make sure the server's public DNS record is pointing to the elastic ip from the new stack you just deployed.

- Note you would need the select the old workspace. 

```sh
terraform -chdir=aws workspace select production-mm-dd-yy
terraform -chdir=aws workspace show   # confirm this the workspace before calling destroy.
terraform -chdir=aws show             # confirm this is the state you intend to destroy.
terraform -chdir=aws output           # confirm this is the old ip address
terraform -chdir=aws destroy          # you will be prompted one last time before destroying, enter yes
terraform -chdir=aws show             # should show nothing
```
