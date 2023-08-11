#!/usr/bin/env bash

printf '\n\n   Barry-Wehmiller Design Group - Ignition Project Initialization'
printf '\n ==================================================================== \n'

# shellcheck disable=SC2162
read -p "Enter project name: " project_name

printf 'Renaming file %s.code-workspace... \n' "${project_name}"
mv ./*.code-workspace "${project_name}".code-workspace


printf 'Creating .env file for the %s project... \n' "${project_name}"
cat << EOF > ./.env
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose.yml:docker-compose.traefik.yml
COMPOSE_PROJECT_NAME=${project_name}
EOF


printf 'Updating Traefik compose file and README file with %s. \n' "${project_name}"
sed -i "s/ignition-template/${project_name}/g" docker-compose.traefik.yml
sed -i "s/<project-name>/${project_name}/g" README.md

mkdir ignition-data

printf 'Commiting changes... \n'
git add .
git commit -m "Initial commit"

printf '\n\n\n Project initialization finished!'
printf '\n ==================================================================== \n'