FROM alpine:3.5
MAINTAINER David Losada Carballo "davidlosada@ushahidi.com"

RUN apk update && \
    apk add mysql mysql-client && \
    rm -rf /var/cache/apk/*

COPY my.cnf /etc/mysql/my.cnf
COPY run.sh /etc/mysql/run.sh

RUN mkdir /run/mysqld

EXPOSE 3306

CMD [ "/bin/sh", "/etc/mysql/run.sh" ]
