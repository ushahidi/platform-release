# Installation instructions

Thank you for downloading this Ushahidi release.

The procedure will vary depending on your setup, but the requirements in all cases are

* A PHP web server (apache2+mod\_php+mod\_rewrite or nginx+php-fpm)
* PHP invokable from command line
* The following PHP modules installed:
    * curl, json, mcrypt, mysqli, pdo, pdo\_mysql, imap and gd
* A MySQL database server

These instructions assume that you know how to create a database in your MySQL server and
obtain user credentials with access to such database.

## Apache2 + mod\_php + mod\_rewrite

1. Ensure `mod_rewrite` is installed and enabled in your apache server

2. Copy the contents of the unzipped ushahidi-platform-release-* folder into your document root.

    * The `dist/` folder contains the suggested configurations for the virtual host (`apache-vhost.conf`).
    The configs are quite default, you just need to ensure that there is an `AllowOverride`
    directive set to `All` for your document root (where the app has been unzipped).

3. Create a `platform/.env` file with your database credentials, such as:

        DB_HOST=<address of your MySQL server>
        DB_NAME=<name of the database in your server>
        DB_USER=<user to connect to the database>
        DB_PASS=<password to connect to the database>
        DB_TYPE=MySQLi

4. Run the database migrations, execute this command from the `platform` folder:

        ./bin/phinx migrate -c application/phinx.php

5. Ensure that the folders `logs`, `cache` and `media/uploads` under `platform/application` are
   all owned by the user that the web server is running as.

    * i.e. in Debian derived Linux distributions, this user is `www-data`, belonging to group `www-data`,
      so you would run:

            chown -R www-data:www-data platform/application/{logs,cache,media/uploads}

6. Set up the cron jobs for tasks like receiving reports and sending e-mail messages.

    * You'll need to know again which user your web server is running as. We'll assume the Debian standard `www-data` here.
    * Run the command `crontab -u www-data -e` and ensure the following lines are present in the crontab:

            MAILTO=<your email address for system alerts>
            */5 * * * * cd <your document root>/platform && ./bin/ushahidi dataprovider outgoing >> /dev/null
            */5 * * * * cd <your document root>/platform && ./bin/ushahidi dataprovider incoming >> /dev/null
            */5 * * * * cd <your document root>/platform && ./bin/ushahidi savedsearch >> /dev/null
            */5 * * * * cd <your document root>/platform && ./bin/ushahidi notification queue >> /dev/null

7. Restart your apache web server and access your virtual host. You should see your website and be able to login with the credentials user name `admin` and password `admin`
     * **Make sure to change the credentials. Specially if the website is exposed to be accessed by anyone other than you** 

## nginx + php-fpm

TBD

## Cpanel, Dreamhost, etc

TBD
