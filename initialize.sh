#!/usr/bin/env bash

printf '\n\n   Barry-Wehmiller Design Group - Ignition Project Initialization'
printf '\n ==================================================================== \n'
MAX_WAIT_SECONDS=60
WAIT_INTERVAL=5

read -rep $'Enter project name: \n' project_name

# Update local files with project name
printf '\n\n Renaming file %s.code-workspace... \n' "${project_name}"
mv ./*.code-workspace "${project_name}".code-workspace

printf 'Creating .env file for the %s project... \n' "${project_name}"
cat << EOF > ./.env
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose.yaml:docker-compose.traefik.yaml
COMPOSE_PROJECT_NAME=${project_name}
EOF

printf 'Updating Traefik compose file and README file with %s. \n' "${project_name}"
sed -i "s/ignition-template/${project_name}/g" docker-compose.traefik.yaml
sed -i "s/<project-name>/${project_name}/g" README.md

mkdir ignition-data

# Git
printf '\n\n Commiting changes... \n'
git add .
git commit -m "Initial commit"

# Check for Traefik Proxy
if [ ! -f "../traefik-proxy/docker-compose.yml" ]; 
then
    printf '\n\n Traefik Proxy not found. \n'
    pwd
    ls -al ../
    read -rep $'\n\n Would you like to clone the design-group/traefik-proxy to your local PC in this location? (y/n) \n' install_proxy
    case "${install_proxy}" in
        [yY] ) 
            printf 'Cloning design-group/traefik-proxy...\n';
            git clone https://github.com/design-group/traefik-proxy.git ../traefik-proxy;;
        [nN] )
            printf '\n Please go to https://github.com/design-group/traefik-proxy to manually setup the Traefik proxy and rerun this script. \n';;
    esac
fi

# Docker pull and start containers
while true; do
    read -rep $'\n\n Do you want to pull any changes to the docker image and start the containers? (y/n) \n' start_containers
    case "${start_containers}" in
        [Yy]* ) 
            CONTAINER_GATEWAY="${project_name}-gateway-1"
            CONTAINER_PROXY="proxy"

            printf 'Waiting for Docker container %s to start...\n' "${CONTAINER_GATEWAY}"
            docker-compose pull && docker-compose up -d
            printf 'Waiting for Docker container %s to start...\n' "${CONTAINER_PROXY}"
            docker-compose pull && docker-compose -f ../traefik-proxy/docker-compose.yml up -d

            elapsed_seconds=0
            while [ $elapsed_seconds -lt $MAX_WAIT_SECONDS ]; do
                gateway_status=$(docker ps -f "name=$CONTAINER_GATEWAY" --format "{{.Status}}")
                proxy_status=$(docker ps -f "name=$CONTAINER_PROXY" --format "{{.Status}}")
                
                if [[ $gateway_status == *"Up"* ]] && [[ $proxy_status == *"Up"* ]]; then
                    printf 'access the gateway at http://%s.localtest.me' "${project_name}"
                    break
                fi
                
                sleep $WAIT_INTERVAL
                elapsed_seconds=$((elapsed_seconds + WAIT_INTERVAL))
            done

            if [ $elapsed_seconds -ge $MAX_WAIT_SECONDS ]; then
                printf 'Timed out waiting for container %s or %s to start. \n' "${CONTAINER_GATEWAY}" "${CONTAINER_PROXY}"
                printf 'Container %s status: %s \n' "${CONTAINER_GATEWAY}" "${gateway_status}"
                printf 'Container %s status: %s \n' "${CONTAINER_PROXY}" "${proxy_status}"
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