FROM php:7.0.32-apache

RUN apt-get update && apt-get install -y \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      libpng-dev \
      libmcrypt-dev \
      libc-client2007e-dev \
      libkrb5-dev \
      libcurl4-openssl-dev \
      unzip \
      rsync \
      netcat-openbsd \
      supervisor \
      cron \
      git && \
    docker-php-ext-install curl json mcrypt mysqli pdo pdo_mysql && \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl && \
    docker-php-ext-install imap && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
    docker-php-ext-install gd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /var/www

COPY run.sh /run.sh
COPY build_env.sh /build_env.sh
COPY dist/ /dist

ENV SERVER_FLAVOR apache2

ENTRYPOINT [ "/bin/bash", "/run.sh" ]
