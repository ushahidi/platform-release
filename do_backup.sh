#!/bin/bash

set -e

echo_err() { echo "$@" 1>&2; }

wd=$(dirname $0)
cd ${wd:-.}

tstamp=$(date -u '+%Y%m%d_%H%M%S')
mkdir -p ./backups

echo_err "Backing up database..."
sql_fname="backups/db_${tstamp}.sql"
docker-compose exec mysql /bin/bash -c 'MYSQL_PWD=${MYSQL_ROOT_PASSWORD} mysqldump -u root ushahidi' > ${sql_fname}

echo_err "Backing up public folder (uploaded files)..."
public_fname="backups/public_${tstamp}.tar.gz"
docker-compose exec ushahidi tar -cz -C /var/www/html/platform/storage/app public > ${public_fname}

echo_err
echo_err "Backups complete!"
echo_err " - database: ${sql_fname}"
echo_err " - public folder: ${public_fname}"
echo_err
