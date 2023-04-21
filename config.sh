#!/bin/bash

# https://docs.pulpproject.org/pulp_operator/configuring/storage/#configuring-pulp-operator-to-use-object-storage
PULP_NAMESPACE=$(oc project | grep -oE 'ephemeral-......')
S3_ACCESS_KEY_ID=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.objectStore.buckets[0].accessKey')
S3_SECRET_ACCESS_KEY=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.objectStore.buckets[0].secretKey')
S3_BUCKET_NAME=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.objectStore.buckets[0].name')
#S3_REGION='us-east-1'
S3_HOSTNAME=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.objectStore.hostname')

kubectl -n $PULP_NAMESPACE apply -f- <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: 'test-s3'
stringData:
  s3-access-key-id: $S3_ACCESS_KEY_ID
  s3-secret-access-key: $S3_SECRET_ACCESS_KEY
  s3-bucket-name: $S3_BUCKET_NAME
EOF
# s3-region: $S3_REGION

# https://docs.pulpproject.org/pulp_operator/configuring/cache/#configuring-pulp-operator-to-use-an-external-redis-installation

kubectl -n $PULP_NAMESPACE create secret generic external-redis \
        --from-literal=REDIS_HOST=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.inMemoryDb.hostname') \
        --from-literal=REDIS_PORT=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.inMemoryDb.port') \
        --from-literal=REDIS_PASSWORD=""  \
        --from-literal=REDIS_DB=""

# https://docs.pulpproject.org/pulp_operator/configuring/database/#configuring-pulp-operator-to-use-an-external-postgresql-installation

kubectl -n $PULP_NAMESPACE create secret generic external-database \
        --from-literal=POSTGRES_HOST=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.database.hostname')  \
        --from-literal=POSTGRES_PORT=5432  \
        --from-literal=POSTGRES_USERNAME=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.database.adminUsername')  \
        --from-literal=POSTGRES_PASSWORD=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.database.adminPassword')  \
        --from-literal=POSTGRES_DB_NAME=$(oc exec $(oc get pod | grep cr-generator | cut -f 1 -d " ") cat /cdapp/cdappconfig.json | jq -r '.database.name') \
        --from-literal=POSTGRES_SSLMODE=disable

kubectl -n $PULP_NAMESPACE apply -f- <<EOF
apiVersion: repo-manager.pulpproject.org/v1alpha1
kind: Pulp
metadata:
  name: pulp
spec:
  api:
    replicas: 2
  content:
    replicas: 2
  worker:
    replicas: 2
  web:
    replicas: 2
  ingress_type: nodeport
  pulp_settings:
    aws_s3_endpoint_url: http://${S3_HOSTNAME}:9000
  database:
    external_db_secret: external-database
  cache:
    enabled: true
    external_cache_secret: external-redis
  object_storage_s3_secret: test-s3
EOF
