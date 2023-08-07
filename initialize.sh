#!/usr/bin/env bash

printf '\n\n   Barry-Wehmiller Design Group - Ignition Project Initialization'
printf '\n ==================================================================== \n'

read -p "Enter project name: " project_name

mv *.code-workspace "${project_name}".code-workspace

# Confiure Environment variables
read -p "Are you using Traefik as a reverse proxy? (Y/N)" answer
touch .env

if [[ ${answer} == [yY] || ${answer} == [yY][eE][sS] ]]
then
cat <<'EOF' >>./.env
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose.yml:docker-compose.traefik.yml
EOF

# Update Traefik compose file replacing the default project name
sed -i "s/ignition-template/${project_name}/g" docker-compose.traefik.yml

fi

printf "COMPOSE_PROJECT_NAME=""${project_name}" >> ./.env

mkdir ignition-data

git add .
git commit -m "Initial commit"

printf '\n\n\n Project initialization finished!'
printf '\n ==================================================================== \n'
