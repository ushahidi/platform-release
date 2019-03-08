# Ushahidi Platform version 4 releases

Install and run the Ushahidi Platform easily. No builds, no compiling.

The Ushahidi platform is currently composed of two components:

* The API ( [platform repository](https://github.com/ushahidi/platform) )
* The client ( [platform-client repository](https://github.com/ushahidi/platform-client) )

## Installation instructions

Proceed to download a releases available in the "Releases" tab of this repository. That will
contain all the files necessary for running our software. The included `README.release.md`
file will contain more specific instructions for installation.

## Run locally with docker

Requirements are `docker-engine` and `docker-compose`.

Just run `docker-compose up` , the Ushahidi platform will be available at port 80 of your
docker engine host. Default credentials: `admin / admin` (**do change these** for any
installation you plan to have exposed)

Versions of the software will be automatically downloaded for you, based on the contents
of `build_env.sh` 

Step 1: Clone the Repo

`git clone https://github.com/ushahidi/platform-release.git`

Step2 : Change to Ushahidi platform release directory 

`cd platform-release/`

Step3: Run docker-compose 

`docker-compose up`
