#!/bin/bash

set -e

# Ensure the required environment variables are set

if [ -z "$POSTGRES_HOST" ]; then
  echo "Error: POSTGRES_HOST is not set"
  exit 1
fi

if [ -z "$POSTGRES_PORT" ]; then
  echo "Error: POSTGRES_PORT is not set"
  exit 1
fi

if [ -z "$POSTGRES_USERNAME" ]; then
  echo "Error: POSTGRES_USERNAME is not set"
  exit 1
fi

if [ -z "$POSTGRES_PASSWORD" ]; then
  echo "Error: POSTGRES_PASSWORD is not set"
  exit 1
fi

if [ -z "$POSTGRES_DATABASE" ]; then
  echo "Error: POSTGRES_DATABASE is not set"
  exit 1
fi

if [ -z "$POSTGRES_SCHEMA" ]; then
  echo "Error: POSTGRES_SCHEMA is not set"
  exit 1
fi

if [ -z "$S3_REGION" ]; then
  echo "Error: S3_REGION is not set"
  exit 1
fi

if [ -z "$UNITY_CATALOG_S3_BUCKET_PATH" ]; then
  echo "Error: UNITY_CATALOG_S3_BUCKET_PATH is not set"
  exit 1
fi

if [ -z "$UNITY_CATALOG_S3_BUCKET_ACCESS_ROLE_ARN" ]; then
  echo "Error: UNITY_CATALOG_S3_BUCKET_ACCESS_ROLE_ARN is not set"
  exit 1
fi

# create schema if not exists

PGPASSWORD=$POSTGRES_PASSWORD psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE -c "CREATE SCHEMA IF NOT EXISTS $POSTGRES_SCHEMA;"

SERVER_PROPERTIES_FILE="$HOME/etc/conf/server.properties"
HIBERNATE_PROPERTIES_FILE="$HOME/etc/conf/hibernate.properties"

# WRITE HIBERNATE PROPERTIES TO FILE
echo "hibernate.connection.driver_class=org.postgresql.Driver" > $HIBERNATE_PROPERTIES_FILE
echo "hibernate.connection.url=jdbc:postgresql://$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DATABASE?currentSchema=$POSTGRES_SCHEMA" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.connection.user=$POSTGRES_USERNAME" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.connection.password=$POSTGRES_PASSWORD" >> $HIBERNATE_PROPERTIES_FILE
echo "org.hibernate.SQL=INFO" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.show_sql=false" >> $HIBERNATE_PROPERTIES_FILE
echo "org.hibernate.type.descriptor.sql.BasicBinder=TRACE" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.archive.autodetection=class" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.use_sql_comments=true" >> $HIBERNATE_PROPERTIES_FILE
echo "hibernate.hbm2ddl.auto=create" >> $HIBERNATE_PROPERTIES_FILE

echo "server.env=false" > $SERVER_PROPERTIES_FILE
echo "server.authorization=disable" >> $SERVER_PROPERTIES_FILE
echo "server.authorization-url=" >> $SERVER_PROPERTIES_FILE
echo "server.token-url=" >> $SERVER_PROPERTIES_FILE
echo "server.client-id=" >> $SERVER_PROPERTIES_FILE
echo "server.client-secret=" >> $SERVER_PROPERTIES_FILE
echo "server.redirect-port=" >> $SERVER_PROPERTIES_FILE

echo "server.cookie-timeout=P5D" >> $SERVER_PROPERTIES_FILE
echo "storage-root.models=s3://nekt-unitycatalog-test/root" >> $SERVER_PROPERTIES_FILE

## S3 Storage Config (Multiple configs can be added by incrementing the index)
echo "s3.region.0=" >> $SERVER_PROPERTIES_FILE
echo "s3.bucketPath.0=$UNITY_CATALOG_S3_BUCKET_PATH" >> $SERVER_PROPERTIES_FILE
echo "s3.awsRoleArn.0=$UNITY_CATALOG_S3_BUCKET_ACCESS_ROLE_ARN" >> $SERVER_PROPERTIES_FILE

# Optional (If blank, it will use DefaultCredentialsProviderChain)
echo "s3.accessKey.0=" >> $SERVER_PROPERTIES_FILE
echo "s3.secretKey.0=" >> $SERVER_PROPERTIES_FILE

# Test Only (If you provide a session token, it will just use those session creds, no downscoping)
echo "s3.sessionToken.0=" >> $SERVER_PROPERTIES_FILE

## ADLS Storage Config (Multiple configs can be added by incrementing the index)
echo "adls.storageAccountName.0=" >> $SERVER_PROPERTIES_FILE
echo "adls.tenantId.0=" >> $SERVER_PROPERTIES_FILE
echo "adls.clientId.0=" >> $SERVER_PROPERTIES_FILE
echo "adls.clientSecret.0=" >> $SERVER_PROPERTIES_FILE

echo "===== Hibernate Properties ====="
cat $HIBERNATE_PROPERTIES_FILE

echo "===== Server Properties ====="
cat $SERVER_PROPERTIES_FILE

exec "$@"
