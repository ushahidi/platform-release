# Ushahidi Platform version 6 releases

Install and run the Ushahidi Platform easily. No builds, no compiling.

The Ushahidi platform is currently composed of two components:

* The API ( [platform repository](https://github.com/ushahidi/platform) )
* The client ( [platform-client repository](https://github.com/ushahidi/platform-client-mzima) )

## Installation instructions

Proceed to download a releases available in the "Releases" tab of this repository. That will
contain all the files necessary for running our software. The included `README.release.md`
file will contain more specific instructions for installation.

## Run with Docker

This is an easy way to get started and get a fairly stable service running.

Requirements are `docker-engine` and `docker-compose`.

Just run `docker-compose up` , the Ushahidi platform will be available at port 80 of your
docker engine host. Default credentials: `admin@example.com / admin` (**do change these** for any
installation you plan to have exposed)

Versions of the software will be automatically downloaded for you, based on the contents
of `build_env.sh` 

Step 1: Clone the Repo

`git clone https://github.com/ushahidi/platform-release.git`

Step2 : Change to Ushahidi platform release directory 

`cd platform-release/`

Step3: Run docker-compose 

`docker-compose up`

### Docker: Backups

Run `./do_backup.sh` on this folder to make a backup of your database and uploaded files.

### Docker: SSL/TLS

1. You will need a folder with your certificates, and this should be mounted as a volume
   in your pertinent container.

2. You will need a properly configured web server.

The configuration for the web servers is found under the `dist/` folder and you may modify
it in order to enable TLS and point at your certificate files.

However, a secure TLS configuration actually requires you to get a number of things right.
Because of this, we rather prefer the approach of using a known well maintained
implementation and configuration. 

Our current suggestion to run a SSL/TLS docker setup is with the very excellent
[jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy) container.

You will find an example of usage of nginx-proxy in the [docker-compose.tls.yml](docker-compose.tls.yml)
file. In order to make that example work for you, please adjust a couple things:

* Change the occurrences of `127.0.0.1.xip.io` for the hostname URL that you will
  use to publish your Ushahidi deployment.

* Ensure your certificates are in the `tls-certs/` folder, using the proper naming
  conventions. i.e. if your publishing URL is ushahidi.example.com , you will need to have
  `ushahidi.example.com.crt` and `ushahidi.example.com.key` files.

Also note that you will need to run
`docker-compose -f docker-compose.tls.yml ... rest of the command ...`,
instead of plain `docker-compose`, or set the the `COMPOSE_FILE` environment variable
to `docker-compose.tls.yml`.

### Docker: SSL/TLS with Let's Encrypt

This should be fairly doable with a variation of the nginx-proxy approach described above.

Contributions welcome!

### Docker: Connecting the mobile app

Please note that the mobile app relies on the contents of the config.json file in order to
connect to the API backend.

In order to help the app find the backend, ensure that the key `backend_url` in the
JSON file is set appropriately to the absolute public URL of your deployment
(i.e. `"backend_url": "https://example.deployment.com"` )

If you are running the Docker container, you may set this variable using the
`SITE_URL` environment variable. (In the default install the site URL **is** the backend URL).

# Other documentation

For other documentation, please check out our [Developer and Contributor docs](https://docs.ushahidi.com/platform-developer-documentation/v/dev-legacy-v3/development-and-code/setup_alternatives/platform_release_install/) !
