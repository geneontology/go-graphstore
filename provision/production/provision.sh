#!/bin/bash
set -ex

INSTANCE_TYPE="t2.large"
DISK_SIZE=100

ls -l aws/backend.tf production/go-ssh production/go-ssh.pub production/s3cfg production/production-vars.txt > /dev/null
WORKSPACE=`terraform -chdir=aws workspace show`

if [ "$WORKSPACE" = "default" ]; then
   echo "default workspace should not be used. create a workspace production-yy-mm-dd"
   exit 1
fi

PROVISION_DIR=`pwd`
PUBLIC_KEY="$PROVISION_DIR/production/go-ssh.pub"

printf 'tags = { Name = "go-graphstore", Workspace = "%s" }\n' $WORKSPACE > production/production-vars.tfvars
printf 'instance_type = "%s"\n' $INSTANCE_TYPE >> production/production-vars.tfvars
printf 'disk_size = %d\n' $DISK_SIZE >> production/production-vars.tfvars
printf 'public_key_path = "%s"\n' $PUBLIC_KEY >> production/production-vars.tfvars

cat $PROVISION_DIR/production/production-vars.tfvars
chmod 400 production/go-ssh
chmod 400 production/go-ssh.pub

diff -s <(ssh-keygen -l -f production/go-ssh | cut -d' ' -f2) <(ssh-keygen -l -f production/go-ssh.pub | cut -d' ' -f2)

# Provision aws instance
terraform -chdir=aws apply -auto-approve -var-file=$PROVISION_DIR/production/production-vars.tfvars

HOST=`terraform -chdir=aws output -raw public_ip`
PRIVATE_KEY=$PROVISION_DIR/production/go-ssh
S3_CRED_FILE=$PROVISION_DIR/production/s3cfg
STAGE_DIR=/home/ubuntu/stage_dir

ansible-playbook -e "stage_dir=$STAGE_DIR" -u ubuntu -i "$HOST," --private-key $PRIVATE_KEY build_images.yaml

EXTRAS=`cat production/production-vars.txt | grep -v "#" | tr '\n' ' '`
ansible-playbook -e "stage_dir=$STAGE_DIR S3_CRED_FILE=$S3_CRED_FILE $EXTRAS" -u ubuntu -i "$HOST," --private-key $PRIVATE_KEY stage.yaml

ansible-playbook -e "stage_dir=$STAGE_DIR" -u ubuntu -i "$HOST," --private-key $PRIVATE_KEY start_services.yaml
echo "Done"
