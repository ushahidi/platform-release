FROM ushahidi/php-fpm-nginx:php-7.4.33

WORKDIR /var/www

RUN apt-get update && apt-get install -y \
      unzip \
      rsync \
      netcat-openbsd \
      supervisor \
      cron \
      git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY run.sh /run.sh
RUN $DOCKERCES_MANAGE_UTIL endpoint /run.sh

COPY build_env.sh /build_env.sh
COPY dist/ /dist

ENV SERVER_FLAVOR=nginx \
    PHP_FPM_CONFIG=/etc/php/7.4/fpm \
    PHP_FPM_PATH=/usr/sbin/php-fpm7.4 \
    PHP_FPM_LOGFILE=/var/log/php7.4-fpm.log \
    IMAGE_MAX_SIZE=10000000 \
    PHP_UPLOAD_MAX_FILESIZE=10M \
    PHP_POST_MAX_SIZE=10M

CMD [ "run" ]
