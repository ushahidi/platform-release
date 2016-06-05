# Ushahidi Platform version 3 releases

Install and run the Ushahidi Platform easily. No builds, no compiling.

The Ushahidi platform is currently composed of two components:

* The API ( [platform repository](https://github.com/ushahidi/platform) )
* The client ( [platform-client repository](https://github.com/ushahidi/platform-client) )

## Installation instructions

Proceed to download a releases available in the "Releases" tab of this repository. That will
contain all the files necessary for running our software.

The procedure will vary depending on your setup, but the requirements in all cases are

* A PHP web server (apache2+mod_php+mod_rewrite or nginx+php-fpm)
* PHP invokable from command line
* The following PHP modules installed:
    * curl, json, mcrypt, mysqli, pdo, pdo_mysql, imap and gd
* A MySQL database server

### Apache2 + mod_php + mod_rewrite

The `dist/` folder contains the suggested configurations for the virtual host (`apache-vhost.conf`),
the  most important thing to note in that file is that `AllowOverride` must be set to `All` for your
document root where the app has been unzipped.

### nginx + php-fpm

TBD

### Cpanel, Dreamhost, etc

TBD

## Run locally with docker

Requirements are `docker-engine` and `docker-compose`.

Just run `docker-compose up` , the Ushahidi platform will be available at port 80 of your
docker engine host. Default credentials: `admin / admin` (**do change these** for any
installation you plan to have exposed)
