#!/bin/bash

set -ex

. $(dirname $0)/build_env.sh

if [[ -z "$client_tar" || -z "$api_tar" ]]; then
  echo "Missing configs!"
  exit 1
fi

if [ -z "$client_url" ]; then
  client_url="https://github.com/ushahidi/platform-client/releases/download/${client_version}/${client_tar}"
fi
if [ -z "$api_url" ]; then
  api_url="https://github.com/ushahidi/platform/releases/download/${api_version}/${api_tar}"
fi

release_target_folder=/tmp/release/ushahidi-platform-release-${release_version}

fetch() {
  if [ ! -d /tars ]; then 
    mkdir /tars
  fi
  if [ ! -f /tars/$client_tar ]; then
    curl -L -o /tars/$client_tar $client_url
  fi
  if [ ! -f /tars/$api_tar ]; then
    curl -L -o /tars/$api_tar $api_url
  fi
  # Added download files size control
  minsize=100000
  size_client=$(stat -c%s /tars/"$client_tar")
  size_api=$(stat -c%s /tars/"$api_tar")
  if [ $size_client -lt $minsize ] || [ $size_api -lt $minsize ] ; then
    echo "Error in downloaded file!"
    exit 1
  fi
}

build() {
  mkdir -p /tmp/client
  tar -C /tmp/client -xz -f /tars/$client_tar
  mkdir -p /tmp/api
  tar -C /tmp/api -xz -f /tars/$api_tar
  #
  local client_untar_path=/tmp/client/ushahidi-platform-client-bundle-${client_version}
  local api_untar_path=/tmp/api/ushahidi-platform-bundle-${api_version}
  #
  ## Untar bundles in a comman folder
  mkdir -p $release_target_folder
  mv $client_untar_path ${release_target_folder}/html
  mv $api_untar_path ${release_target_folder}/html/platform
  #
  ## Configure the client to reach backend at '/platform'
  cat > ${release_target_folder}/html/config.js <<EOF
// Configure platform-client to reach the api at the subpath /platform in the same domain
//
window.ushahidi = {
  backendUrl : "/platform"
};
EOF
  #
  # Add .htaccess files for apache2 users
  cp /dist/api-htaccess ${release_target_folder}/html/platform/.htaccess
  cp /dist/api-httpdocs-htaccess ${release_target_folder}/html/platform/httpdocs/.htaccess
  mv ${release_target_folder}/html/rewrite.htaccess ${release_target_folder}/html/.htaccess
  #
  ## Additional files for the release
  cp /dist/README.release.md ${release_target_folder}
  mkdir ${release_target_folder}/dist
  cp /dist/apache-vhost.conf ${release_target_folder}/dist
  cp /dist/nginx-site.conf ${release_target_folder}/dist
  #
  ## Adjust folder permissions
  chown -R 0:0 ${release_target_folder}
  find ${release_target_folder}/html -type d -a -exec chmod 555 \{\} \;
  find ${release_target_folder}/html -type f -a -exec chmod -w \{\} \;
  ( cd ${release_target_folder}/html/platform ;
    chmod 0777 application/logs application/cache application/media/uploads )
  #
  ## Adjust base_url for the platform api
  ( cd ${release_target_folder}/html/platform ;
    sed -i -E -e 's%(base_url\s*[[:punct:]]+\s*).*$%\1'"=> '/platform',"'%' application/config/init.php )
}

bundle() {
  tar -C /tmp/release -cz -f /vols/out/ushahidi-platform-release-${release_version}.tar.gz ushahidi-platform-release-${release_version}
}

write_platform_env() {
  cat > /var/www/html/platform/.env <<EOF
  DB_HOST=${MYSQL_HOST:-mysql}
  DB_NAME=${MYSQL_DATABASE:-ushahidi}
  DB_USER=${MYSQL_USER:-ushahidi}
  DB_PASS=${MYSQL_PASSWORD:-ushahidi}
  DB_TYPE=MySQLi
EOF
}

run() {
  install_app
  #
  case "$SERVER_FLAVOR" in
    apache2)
      setup_apache
      ;;
    nginx)
      setup_fpm
      setup_nginx
      ;;
    *)
      echo "Unknown server flavor! $SERVER_FLAVOR"
      exit 1
      ;;
  esac
  # Setup cron and supervisor
  setup_cron
  setup_supervisord
  # Start supervisor
  exec supervisord -n -c /etc/supervisor/supervisord.conf
}

install_app() {
  # Install release folders in webroot
  rsync -ar --delete-after ${release_target_folder}/html/ /var/www/html/
  #
  ## Configure platform environment ensure mysql connection and run migrations
  write_platform_env
  while ! nc -z $MYSQL_HOST 3306 ; do
    sleep 1;
  done 
  ( cd /var/www/html/platform ;
    # Run migrations
    ./bin/phinx migrate -c application/phinx.php 
    #
    ## Adjust permissions
    chown -R www-data:www-data application/logs application/cache application/media/uploads
  )
}

setup_apache() {
  # Configure apache and .htaccess
  cp /dist/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
  ( cd /etc/apache2/sites-enabled ; ln -sf ../sites-available/000-default.conf . )
  ( cd /etc/apache2/mods-enabled ; ln -sf ../mods-available/rewrite.load . )
  #
  cat > /etc/supervisor/conf.d/apache2 <<EOF
[program:apache2]
autorestart=false  
command=/usr/sbin/apache2ctl -DFOREGROUND  
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
}

setup_fpm() {
  cat > /etc/supervisor/conf.d/php-fpm <<EOF
[program:phpfpm]
autorestart=false  
command=/usr/local/sbin/php-fpm
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
}

setup_nginx() {
  cp /dist/nginx-site.conf /etc/nginx/sites-available/default
  cat > /etc/supervisor/conf.d/nginx <<EOF
[program:nginx]
autorestart=false  
command=/usr/sbin/nginx -g "daemon off;"  
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
}

setup_cron() {
  ## Install crontab
  local cron_file=$(tempfile)
  touch /var/log/cronjobs.out
  chmod 777 /var/log/cronjobs.out
  cat > ${cron_file} <<EOF
PATH=/usr/local/bin:/usr/bin:/bin
SHELL=/bin/bash
*/5 * * * * cd /var/www/html/platform && ./bin/ushahidi dataprovider outgoing 2>&1 >> /var/log/cronjobs.out
*/5 * * * * cd /var/www/html/platform && ./bin/ushahidi dataprovider incoming 2>&1 >> /var/log/cronjobs.out
*/5 * * * * cd /var/www/html/platform && ./bin/ushahidi savedsearch 2>&1 >> /var/log/cronjobs.out
*/5 * * * * cd /var/www/html/platform && ./bin/ushahidi notification queue 2>&1 >> /var/log/cronjobs.out
*/5 * * * * cd /var/www/html/platform && ./bin/ushahidi webhook send 2>&1 >> /var/log/cronjobs.out
EOF
  crontab -u www-data ${cron_file}
  rm -f ${cron_file}
  #
  cat > /etc/supervisor/conf.d/cron <<EOF
[program:cron]
autorestart=false  
command=cron -f

[program:tail-cron]
autorestart=false
command=tail -f /var/log/cronjobs.out
stdout_logfile=/dev/fd/1
stdout_logfile_maxbytes=0
stderr_logfile=/dev/fd/2
stderr_logfile_maxbytes=0
EOF
}

setup_supervisord() {
  cat > /etc/supervisor/supervisord.conf <<EOF
[supervisord]
nodaemon=true  
logfile = /var/log/supervisord.log  
logfile_maxbytes = 50MB  
logfile_backups=10

[include]
files = conf.d/*
EOF
}

case "$1" in
  build)
    fetch
    build
    bundle
    ;;
  run)
    fetch
    build
    run
    ;;
esac
