#!/bin/bash

cp -f /docker-entrypoint-initdb.d/20-schema.xxx /tmp/20-schema.yyy
cp -f /docker-entrypoint-initdb.d/30-schema.xxx /tmp/30-schema.yyy

sed -i "s/PGDB_USER/$PGSQL_USER/g" /tmp/20-schema.yyy
sed -i "s/PGDB_PASSWORD/$PGSQL_PASS/g" /tmp/20-schema.yyy
sed -i "s/PGDB_NAME/$PGSQL_DBNAME/g" /tmp/20-schema.yyy


sed -i "s/PDA_USER/$PDA_PGDB_USER/g" /tmp/20-schema.yyy
sed -i "s/PDA_PASSWORD/$PDA_PGDB_PASS/g" /tmp/20-schema.yyy
sed -i "s/PDA_NAME/$PDA_PGDB_DBNAME/g" /tmp/20-schema.yyy

sed -i "s/PDNS_PGDB_REPLICA_PASSWORD/$PDNS_PGDB_REPLICA_PASSWORD/g" /tmp/20-schema.yyy


sed -i "s/PDNS_PGDB_REPLICA_USER/$PDNS_PGDB_REPLICA_USER/g" /tmp/30-schema.yyy




psql  < /tmp/20-schema.yyy

psql -U ${PGSQL_USER} ${PGSQL_DBNAME} < /tmp/30-schema.yyy

#unset PGSQL_PASS
#export PGSQL_PASS=xxxxxxxxxxxxxxxxxxx

#rm /tmp/20-schema.yyy


#echo "wal_level = replica" >> ${PGDATA}/postgresql.conf 
#echo "max_wal_senders = 3" >> ${PGDATA}/postgresql.conf 
#echo "wal_keep_segments = 64" >> ${PGDATA}/postgresql.conf 

echo "wal_level = logical" >> ${PGDATA}/postgresql.conf 

echo "host     replication     $PDNS_PGDB_REPLICA_USER       all      md5" >> ${PGDATA}/pg_hba.conf