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
  mv $api_untar_path ${release_target_folder}/platform
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
  ## Additional files for the release
  cp /dist/README.release.md ${release_target_folder}
  mkdir ${release_target_folder}/dist
  cp /dist/apache-vhost.conf ${release_target_folder}/dist
  cp /dist/api-htaccess ${release_target_folder}/dist
}

bundle() {
  tar -C /tmp/release -cz -f /vols/out/ushahidi-platform-release-${release_version}.tar.gz ushahidi-platform-release-${release_version}
}

write_platform_env() {
  cat > /var/www/platform/.env <<EOF
  DB_HOST=${MYSQL_HOST:-mysql}
  DB_NAME=${MYSQL_DATABASE:-ushahidi}
  DB_USER=${MYSQL_USER:-ushahidi}
  DB_PASS=${MYSQL_PASSWORD:-ushahidi}
  DB_TYPE=MySQLi
EOF
}

run() {
  # Install release folders in webroot
  rsync -ar --delete-after ${release_target_folder}/html/ /var/www/html/
  rsync -ar --delete-after ${release_target_folder}/platform/ /var/www/platform/
  #
  # Configure apache and .htaccess
  cp /dist/apache-vhost.conf /etc/apache2/sites-available/000-default.conf
  ( cd /etc/apache2/sites-enabled ; ln -s ../sites-available/000-default.conf . )
  cp /dist/api-htaccess /var/www/platform/httpdocs/.htaccess
  mv /var/www/html/rewrite.htaccess /var/www/html/.htaccess
  ( cd /etc/apache2/mods-enabled ; ln -s ../mods-available/rewrite.load . )
  #
  ## Configure platform environment ensure mysql connection and run migrations
  write_platform_env
  while ! nc -z $MYSQL_HOST 3306 ; do
    sleep 1;
  done 
  ( cd /var/www/platform ; ./bin/phinx migrate -c application/phinx.php )
  #
  ## Run apache (on foreground)
  chown -R www-data:www-data /var/www
  exec apachectl -DFOREGROUND
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
