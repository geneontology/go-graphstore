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

#### Docker Images

The production deployment assumes the docker images are pushed to dockerhub. 

As of this writing, the images are:
graphstore_image=geneontology/go-graphstore:v1
apache_proxy_image=geneontology/apache-proxy:v1

Consult [this document](../../docker/DOCKER_README.md). to build and push images.
You will be able to specify your newly pushed images in the steps below.

#### AWS CREDENTIALS/TERRAFORM BACKEND 

Note you would need to create some files and modify them as stated below. 

- backend.tf     
  - Points to terraform backend. See production/backend.tf.sample 

- s3cfg          
  - Credentials used by apache proxy server to upload access logs to s3 bucket. See production/s3cfg.sample

#### Deploy The New Stack

```sh
cd provision

# This file is used to configure the Terraform S3 Backend.
cp ./production/backend.tf.sample ./aws/backend.tf # Modify it with the name of the s3 bucket and the aws profile if it is not default

cat ./aws/backend.tf

# Deploy 
Use Python script to deploy.

>pip install -i https://test.pypi.org/simple/ go-deploy==0.1.0
>go-deploy -h

Copy one the config yaml file and modify as needed. For internal graphstore 
>cp ./production/config-internal.yaml.sample ./production/config-internal.yaml

# We append the date to the terraform workspace name. As as example we will use internal-yy-mm-dd

# Dry Run
>go-deploy -init -c production/config-internal.yaml -w internal-yy-mm-dd -d aws -dry-run -verbose 

# Deploy
>go-deploy -init -c production/config-internal.yaml -w internal-yy-mm-dd -d aws -verbose 

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
