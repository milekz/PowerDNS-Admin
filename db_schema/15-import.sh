#!/bin/bash

cp -f /docker-entrypoint-initdb.d/20-schema.xxx /tmp/20-schema.yyy

sed -i "s/PGDB_USER/$PGSQL_USER/g" /tmp/20-schema.yyy
sed -i "s/PGDB_PASSWORD/$PGSQL_PASS/g" /tmp/20-schema.yyy
sed -i "s/PGDB_NAME/$PGSQL_DBNAME/g" /tmp/20-schema.yyy


sed -i "s/PDA_USER/$PDA_PGDB_USER/g" /tmp/20-schema.yyy
sed -i "s/PDA_PASSWORD/$PDA_PGDB_PASS/g" /tmp/20-schema.yyy
sed -i "s/PDA_NAME/$PDA_PGDB_DBNAME/g" /tmp/20-schema.yyy


psql  < /tmp/20-schema.yyy

psql -U ${PGSQL_USER} ${PGSQL_DBNAME} < /docker-entrypoint-initdb.d/30-schema.xxx

#unset PGSQL_PASS
#export PGSQL_PASS=xxxxxxxxxxxxxxxxxxx

#rm /tmp/20-schema.yyy
 