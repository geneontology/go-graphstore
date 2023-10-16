#!/usr/bin/env bash

ansible --version
terraform --version
go_deploy_version=`go-deploy -version`
echo "go_deploy_version=$go_deploy_version"

ls -l /tmp

zone_id=`aws route53 list-hosted-zones-by-name --dns-name geneontology.io. --max-items 1  --query "HostedZones[].Id" --output text  | tr "/" " " | awk '{ print $2 }'`
record_name=cicd-test-go-graphstore.geneontology.io
aws route53 list-resource-record-sets --hosted-zone-id $zone_id --max-items 1000 --query "ResourceRecordSets[].Name" | grep $record_name 
ret=$?

if [ "${ret}" == 0 ]
then
   echo "$record_name exists. Cannot proceed. Try again later."
   exit 1
fi

echo "Great. $record_name not found ... Proceeeding"
# Prepare TF backend

s3_terraform_backend=$S3_TF_BACKEND
sed "s/REPLACE_ME_GOGRAPHSTORE_S3_STATE_STORE/$s3_terraform_backend/g" ./github/backend.tf.sample > aws/backend.tf

# Prepare config yaml files.

sed "s/REPLACE_ME_WITH_ZONE_ID/$zone_id/g" ./github/config-instance.yaml.sample > ./github/config-instance.yaml
sed -i "s/REPLACE_ME_WITH_RECORD_NAME/$record_name/g" ./github/config-instance.yaml

s3_cert_bucket=$S3_CERT_BUCKET
ssl_certs="s3:\/\/$s3_cert_bucket\/geneontology.io.tar.gz"
sed "s/REPLACE_ME_WITH_URI/$ssl_certs/g" ./github/config-stack.yaml.sample > ./github/config-stack.yaml
sed -i "s/REPLACE_ME_WITH_RECORD_NAME/$record_name/g" ./github/config-stack.yaml

# Provision aws instance and fast-api stack.

go-deploy -init --working-directory aws -verbose

go-deploy --working-directory aws -w cicd-test-go-deploy-graphstore -c ./github/config-instance.yaml -verbose

go-deploy --working-directory aws -w cicd-test-go-deploy-graphstore -output -verbose

go-deploy --working-directory aws -w cicd-test-go-deploy-graphstore -c ./github/config-stack.yaml -verbose

ret=1
total=${NUM_OF_RETRIES:=12}


for (( c=1; c<=$total; c++ ))
do
   echo wget http://$record_name/blazegraph/#query
   wget  --no-dns-cache http://$record_name/blazegraph/#query
   ret=$?
   if [ "${ret}" == 0 ]
   then
        echo "Success"
        break
   fi
   echo "Got exit_code=$ret.Going to sleep. Will retry.attempt=$c:total=$total"
   sleep 10
done

# Destroy
go-deploy --working-directory aws -w cicd-test-go-deploy-graphstore -destroy -verbose
rm -f ./github/config-instance.yaml ./github/config-stack.yaml index.html
exit $ret 
