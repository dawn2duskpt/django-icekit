#!/bin/bash

set -e

DEST_DIR="$1"
BRANCH="${2:-master}"

# Validate dependencies.
if [[ -z $(which curl) ]]; then
	echo "'curl' is not available. Please install it and try again."
	exit 1
fi

# Validate destination directory.
if [[ -z "$DEST_DIR" ]];
then
	>&2 echo 'You must specify a destination directory.'
	exit 1
fi

if [[ -d "$DEST_DIR" ]];
then
	>&2 echo "Destination directory '$DEST_DIR' already exists."
	exit 1
fi

DEST_DIR_BASENAME="$(basename $DEST_DIR)"

# Prompt before we do anything.
cat <<EOF

This script will create a new ICEkit project in directory '${DEST_DIR}'.

EOF

read -p 'Press CTRL-C to abort or any other key to continue...'
echo

# Get commit SHA for branch reference.
COMMIT="$(curl -H 'Accept: application/vnd.github.VERSION.sha' https://api.github.com/repos/ic-labs/django-icekit/commits/$BRANCH)"

# Create destination directory.
mkdir -p "$DEST_DIR"
cd "$DEST_DIR"

# Download project template.
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.coveragerc"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.dockerignore"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.editorconfig"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.env.local.sample"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.env.production"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.env.staging"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.gitignore"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/.travis.yml"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/bower.json"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/docker-cloud.yml"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/docker-compose.override.sample.yml"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/docker-compose.travis.yml"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/docker-compose.yml"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/Dockerfile"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/go.sh"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/package.json"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/project_settings.py"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/project_settings_local.sample.py"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/requirements-icekit.txt"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/requirements.in"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/requirements.txt"
curl -#fLO "https://raw.githubusercontent.com/ic-labs/django-icekit/${COMMIT}/project_template/test_initial_data.sql"

# Change permissions on executable files.
chmod +x go.sh

# Find and replace 'project_template' with destination directory basename.
find . -type f -exec sed -e "s/project_template/$DEST_DIR_BASENAME/g" -i.deleteme {} \;
find . -type f -iname "*.deleteme" -delete

# Pin ICEkit version.
sed -e "s|:local|:${COMMIT}|" Dockerfile > Dockerfile.replaced
mv Dockerfile.replaced Dockerfile
for EXT in 'in' txt; do
	sed -e "s|django-icekit.git#egg|django-icekit.git@${COMMIT}#egg|" "requirements.$EXT" > "requirements.$EXT.replaced"
	mv "requirements.$EXT.replaced" "requirements.$EXT"
done

if [[ -n $(which git) ]]; then
	echo
	read -p 'Would you like to initialize a Git repository for your new project and create an initial commit? (Y/n) ' -n 1 -r
	echo
	if [[ "${REPLY:-y}" =~ ^[Yy]$ ]]; then
		git init
		git add -A
		git commit -m 'Initial commit.'
	fi
fi

cat <<EOF

All done! What now? First, change to the project directory:

	$ cd ${DEST_DIR}

# Run with Docker

The easiest way to run an ICEkit project is with Docker. It works on macOS,
Linux, and Windows, takes care of all the project dependencies like the
database and search engine, and makes deployment easy.

If you haven't already, go install Docker:

  * [Linux](https://docs.docker.com/engine/installation/#supported-platforms)
  * [macOS](https://download.docker.com/mac/stable/Docker.dmg)
  * [Windows](https://download.docker.com/win/stable/InstallDocker.msi)

Build a Docker image:

	$ docker-compose build --pull

Run a 'django' container and all of its dependancies:

	$ docker-compose run --rm --service-ports django

Create a superuser account:

	# manage.py createsuperuser

Run the Django dev server:

	# runserver.sh

Open the site in a browser:

	http://${DEST_DIR}.lvh.me:8000

When you're done, exit the container and stop all of its dependencies:

	# exit
	$ docker-compose stop

Read our [Docker guide](http://docs.glamkit.com/en/latest/install/docker.html)
guide for more info on running an ICEkit project with Docker.

# Run without Docker

Read our [Manual Setup](http://docs.glamkit.com/en/latest/install/manual-install.html)
guide for more info on running an ICEkit project without Docker.

EOF
