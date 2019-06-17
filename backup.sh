#!/bin/bash

DBNAME=""
EXPIRATION="30"
Green='\033[0;32m'
EC='\033[0m' 
DATESTAMP=`date +%H_%M_%d%m%Y`

# terminate script on any fails
set -e

while [[ $# -gt 1 ]]
do
key="$1"

case $key in
    -exp|--expiration)
    EXPIRATION="$2"
    shift
    ;;
    -db|--dbname)
    DBNAME="$2"
    shift
    ;;
esac
shift
done

if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
  echo "Missing AWS_ACCESS_KEY_ID variable"
  exit 1
fi
if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
  echo "Missing AWS_SECRET_ACCESS_KEY variable"
  exit 1
fi
if [[ -z "$AWS_DEFAULT_REGION" ]]; then
  echo "Missing AWS_DEFAULT_REGION variable"
  exit 1
fi
if [[ -z "$DB_BACKUP_URL" ]]; then
  echo "Missing DB_BACKUP_URL variable"
  exit 1
fi
if [[ -z "$DB_BACKUP_S3_BUCKET_PATH" ]]; then
  echo "Missing DB_BACKUP_S3_BUCKET_PATH variable"
  exit 1
fi
if [[ -z "$DB_BACKUP_FILENAME" ]]; then
  echo "Missing DB_BACKUP_FILENAME variable"
  exit 1
fi

printf "${Green}Start dump${EC}"

time pg_dump $DB_BACKUP_URL | gzip >  /tmp/"${DB_BACKUP_FILENAME}_${DATESTAMP}".gz

EXPIRATION_DATE=$(date -d "$EXPIRATION days" +"%Y-%m-%dT%H:%M:%SZ")

printf "${Green}Move dump to AWS${EC}"
time /app/vendor/awscli/bin/aws s3 cp /tmp/"${DB_BACKUP_FILENAME}_${DATESTAMP}".gz s3://$DB_BACKUP_S3_BUCKET_PATH/$DBNAME/"${DB_BACKUP_FILENAME}_${DATESTAMP}".gz --expires $EXPIRATION_DATE

# cleaning after all
rm -rf /tmp/"${DB_BACKUP_FILENAME}_${DATESTAMP}".gz
