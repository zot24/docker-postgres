#!/bin/sh
set -e

[ ! -z "$DEBUG" ] && set -ex

chown -R postgres "$PGDATA"

if [ -z "$(ls -A "$PGDATA")" ]; then
    gosu postgres initdb
    sed -ri "s/^#(listen_addresses\s*=\s*)\S+/\1'*'/" "$PGDATA"/postgresql.conf

    if [ "$POSTGRES_PASSWORD" ]; then
      pass="PASSWORD '$POSTGRES_PASSWORD'"
      authMethod=md5
    else
      echo "==============================="
      echo "!!! Use \$POSTGRES_PASSWORD env var to secure your database !!!"
      echo "==============================="

      pass=
      authMethod=trust
    fi

    { echo; echo "host all all 0.0.0.0/0 $authMethod"; } >> "$PGDATA/pg_hba.conf"

    gosu postgres pg_ctl -D "$PGDATA" \
      -o "-c listen_addresses=''" \
      -w start

    : ${POSTGRES_USER:=postgres}
    : ${POSTGRES_DB:=$POSTGRES_USER}
    export POSTGRES_USER POSTGRES_DB

    if [ "$POSTGRES_DB" != 'postgres' ]; then
        echo "CREATE DATABASE $POSTGRES_DB;" | psql -v ON_ERROR_STOP=1 --username postgres
    fi

    if [ "$POSTGRES_USER" = 'postgres' ]; then
      op='ALTER'
    else
      op='CREATE'
    fi

    echo "$op USER $POSTGRES_USER WITH SUPERUSER $pass;" | psql -v ON_ERROR_STOP=1 --username postgres

    for f in /docker-entrypoint-initdb.d/*; do
      case "$f" in
        *.sh)     echo "$0: running $f"; . "$f" ;;
        *.sql)    echo "$0: running $f"; psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" < "$f"; echo ;;
        *)        echo "$0: ignoring $f" ;;
      esac
      echo
    done

    gosu postgres pg_ctl -D "$PGDATA" -m fast -w stop

    echo
    echo 'PostgreSQL init process complete; ready for start up.'
    echo
fi

exec gosu postgres "$@"
