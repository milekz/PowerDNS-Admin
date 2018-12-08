#!/bin/bash

set -o errexit
set -o pipefail

# make sure pg is ready to accept connections
until PGPASSWORD=${PDA_PGDB_PASSWORD} pg_isready -h ${PDA_PGDB_HOST} -p ${PDA_PGDB_PORT} -U ${PDA_PGDB_USER} 
do
  echo "Waiting for postgres at"
    sleep 2;
done


# == Vars
#
DB_MIGRATION_DIR='/powerdns-admin/migrations'
if [[ -z ${PDNS_PROTO} ]];
 then PDNS_PROTO="http"
fi

if [[ -z ${PDNS_PORT} ]];
 then PDNS_PORT=8081
fi




echo "===> DB management"
# Go in Workdir
cd /powerdns-admin

if [ ! -d "${DB_MIGRATION_DIR}" ]; then
  echo "---> Running DB Init"
  flask db init --directory ${DB_MIGRATION_DIR}
  flask db migrate -m "Init DB" --directory ${DB_MIGRATION_DIR}
  flask db upgrade --directory ${DB_MIGRATION_DIR}
  ./init_data.py

else
  echo "---> Running DB Migration"
  set +e
  flask db migrate -m "Upgrade BD Schema" --directory ${DB_MIGRATION_DIR}
  flask db upgrade --directory ${DB_MIGRATION_DIR}
  set -e
fi

echo "===> Update PDNS API connection info"

echo -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_url', '${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_url') LIMIT 1;" | PGPASSWORD=${PDA_PGDB_PASSWORD} psql -h ${PDA_PGDB_HOST} -p ${PDA_PGDB_PORT} -U ${PDA_PGDB_USER} ${PDA_PGDB_NAME} 

echo -e "INSERT INTO setting (name, value) SELECT * FROM (SELECT 'pdns_api_key', '${PDNS_API_KEY}') AS tmp WHERE NOT EXISTS (SELECT name FROM setting WHERE name = 'pdns_api_key') LIMIT 1;" | PGPASSWORD=${PDA_PGDB_PASSWORD} psql -h ${PDA_PGDB_HOST} -p ${PDA_PGDB_PORT} -U ${PDA_PGDB_USER} ${PDA_PGDB_NAME} 

echo -e "UPDATE setting SET value='${PDNS_PROTO}://${PDNS_HOST}:${PDNS_PORT}' WHERE name='pdns_api_url';" | PGPASSWORD=${PDA_PGDB_PASSWORD} psql -h ${PDA_PGDB_HOST} -p ${PDA_PGDB_PORT} -U ${PDA_PGDB_USER} ${PDA_PGDB_NAME} 
echo -e "UPDATE setting SET value='${PDNS_API_KEY}' WHERE name='pdns_api_key';" | PGPASSWORD=${PDA_PGDB_PASSWORD} psql -h ${PDA_PGDB_HOST} -p ${PDA_PGDB_PORT} -U ${PDA_PGDB_USER} ${PDA_PGDB_NAME} 


echo "===> Assets management"
echo "---> Running Yarn"
chown -R www-data:www-data /powerdns-admin/app/static
chown -R www-data:www-data /powerdns-admin/node_modules
su -s /bin/bash -c 'yarn install --pure-lockfile' www-data

echo "---> Running Flask assets"
chown -R www-data:www-data /powerdns-admin/logs
su -s /bin/bash -c 'flask assets build' www-data


echo "===> Start supervisor"
/usr/bin/supervisord -c /etc/supervisord.conf
