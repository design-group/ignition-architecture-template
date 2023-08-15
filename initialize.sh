#!/usr/bin/env bash

printf '\n\n   Barry-Wehmiller Design Group - Ignition Project Initialization'
printf '\n ==================================================================== \n'

read -rp "Enter project name: " project_name

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

while true; do
    printf '\n\n'
    read -rp "Do you want to pull any changes to the docker image and start the container? (y/n) " answer
    case "${answer}" in
        [Yy]* ) 
            CONTAINER_NAME="${project_name}-gateway-1"
            MAX_WAIT_SECONDS=60
            WAIT_INTERVAL=5

            printf 'Waiting for Docker container %s to start...\n' "${CONTAINER_NAME}"
            docker-compose pull && docker-compose up -d

            elapsed_seconds=0
            while [ $elapsed_seconds -lt $MAX_WAIT_SECONDS ]; do
                container_status=$(docker ps -f "name=$CONTAINER_NAME" --format "{{.Status}}")
                
                if [[ $container_status == *"Up"* ]]; then
                    printf 'access the gateway at http://%s.localtest.me' "${project_name}"
                    break
                fi
                
                sleep $WAIT_INTERVAL
                elapsed_seconds=$((elapsed_seconds + WAIT_INTERVAL))
            done

            if [ $elapsed_seconds -ge $MAX_WAIT_SECONDS ]; then
                printf 'Timed out waiting for container %s to start.' "${CONTAINER_NAME}"
            fi

            break;;
        [Nn]* ) 
            printf '\n\n Please run: \n docker-compose pull && docker-compose up -d \n'
            printf '\n Once the container is started, in a web browser, access the gateway at http://%s.localtest.me' "${project_name}"
            break;;
        * ) 
            printf 'Please anser yes or no.';;
    esac
done

printf '\n\n\n Project initialization finished!'
printf '\n ==================================================================== \n'