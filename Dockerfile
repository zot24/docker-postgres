FROM alpine:3.3
MAINTAINER Israel Sotomayor <sotoisra24@gmail.com>

ENV GOSU_VERSION=1.7 \
    ARCHITECTURE=amd64 \
    LANG=en_GB.utf8 \
    PGDATA=/var/lib/postgresql/data

RUN set -ex \
  && apk --no-cache add \
    curl \
    bash \
    postgresql \
  \
  && curl -fsSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${ARCHITECTURE} -o /usr/local/bin/gosu \
  && chmod +x /usr/local/bin/gosu \
  \
  && apk del curl

#ENV PATH /usr/lib/postgresql/$PG_MAJOR/bin:$PATH
VOLUME /var/lib/postgresql/data

COPY docker-entrypoint.sh /
RUN chmod +x docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5432
CMD [ "postgres" ]
