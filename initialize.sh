#!/usr/bin/env bash

pull_start_containers () {
    # Docker pull and start containers
    local MAX_WAIT_SECONDS=60
    local WAIT_INTERVAL=5
    local project="$1"
    local container_name="$2"
    local compose_file="$3"

    while true; do

        printf '\n\n Waiting for Docker container %s to start...\n' "${container_name}"
        if [[ ! "${container_name}" == "proxy" ]]; then
            docker-compose pull && docker-compose up -d
        else
            docker-compose pull && docker-compose -f "${compose_file}" up -d
        fi

        elapsed_seconds=0
        while [ $elapsed_seconds -lt $MAX_WAIT_SECONDS ]; do
            container_status=$(docker ps -f "name=$container_name" --format "{{.Status}}")

            if [[ $container_status == *"Up"* ]] && [[ ! "${container_name}" == "proxy" ]]; then
                printf 'Container %s status: %s \n' "${container_name}" "${container_status}"
                printf 'access the gateway at http://%s.localtest.me' "${project}"
                break
            elif [[ $container_status == *"Up"* ]] && [[ "${container_name}" == "proxy" ]]; then
                sleep $WAIT_INTERVAL
                printf 'Container %s status: %s \n' "${container_name}" "${container_status}"
                break
            fi

            sleep $WAIT_INTERVAL
            elapsed_seconds=$((elapsed_seconds + WAIT_INTERVAL))
        done

        if [ $elapsed_seconds -ge $MAX_WAIT_SECONDS ]; then
            printf 'Timed out waiting for container %s to start. \n' "${container_name}"
            printf 'Container %s status: %s \n' "${container_name}" "${container_status}"
        fi
        
        break
    done
}

printf '\n\n Ignition Architecture Initialization'
printf '\n ==================================================================== \n'

read -rep $' Enter project name: ' project_name

# Setup and start Docker for reverse proxy
# Run a command to check proxy.localtest.me for Traefik dashboard, if its not there then wait 5 seconds and try again
printf '\n Checking Traefik dashboard at http(s)://proxy.localtest.me/dashboard/#/ \n'

while true; do
    http_response=$(curl -s -o /dev/null -w "%{http_code}" "http://proxy.localtest.me/dashboard/#/")
    https_response=$(curl -s -o /dev/null -w "%{http_code}" "https://proxy.localtest.me/dashboard/#/")

    if [ "$http_response" == "200" ] || [ "$https_response" == "200" ]; then
        printf '\n Traefik dashboard is up and running! \n'
        break
    else
        printf '\n Traefik Proxy dashboard not accessible. \n'
        install_path="${HOME}"/traefik-proxy/
        echo -n ' Default location is: '"${install_path}"
        read -rep $' Would you like to use this default path (y/n)?' use_default

        case "${use_default}" in
            [yY]* ) 
                mkdir -p "${install_path}";;
            [nN]* )
                install_path=""
                while true; do
                    if [ -d "${install_path}" ]; then
                        echo "${install_path}"
                        ls -al "${install_path}"
                        read -rep $'\n\n Would you like to clone the design-group/traefik-proxy to your local PC in this location? (y/n) \n' install_proxy
                        case "${install_proxy}" in
                            [yY]* )
                                break;;
                            [nN]* )
                                install_path="";;
                            * ) 
                                printf ' Please answer y or n. \n';;
                        esac
                    else
                        read -rep $'\n Please enter a valid empty folder path to clone into [Format: /home/user/traefik-proxy/]: ' install_path
                        if [[ "$install_path" =~ ^(/[^/ ]*)+/?$ ]]; then
                            mkdir -p "${install_path}"
                        fi
                    fi;
                done;;
            * )
                printf ' Please answer y or n. \n'
        esac

    printf ' Cloning design-group/traefik-proxy into %s...\n' "${install_path}"
    git clone https://github.com/design-group/traefik-proxy.git "${install_path}"
    pull_start_containers "${project_name}" proxy "${install_path}"/docker-compose.yml
    fi
done

# Update local files with project name
printf '\n\n Renaming file %s.code-workspace... \n' "${project_name}"
mv ./*.code-workspace "${project_name}".code-workspace

printf ' Creating .env file for the %s project... \n' "${project_name}"
cat << EOF > ./.env
COMPOSE_PATH_SEPARATOR=:
COMPOSE_FILE=docker-compose.yaml:docker-compose.traefik.yaml
COMPOSE_PROJECT_NAME=${project_name}
EOF

printf ' Updating Traefik compose file and README file with %s. \n' "${project_name}"
sed -i.bak "s/ignition-template/${project_name}/g" docker-compose.traefik.yaml
sed -i.bak "s/<project-name>/${project_name}/g" README.md

if [ -f "docker-compose.traefik.yaml" ] && [ -f "docker-compose.traefik.yaml.bak" ]; then
    rm docker-compose.traefik.yaml.bak
fi

if [ -f "README.md" ] && [ -f "README.md.bak" ]; then
    rm README.md.bak
fi

mkdir -p ignition-data

# Git
printf '\n Creating initial commit for repository. \n'
git add .
git commit --quiet -m "Initial commit"

# Setup and start Docker for Gateway
while true; do
    read -rep $'\n\n Do you want to pull any changes to the Docker image and start the Ignition Gateway container? (y/n) \n' start_container
    case "${start_container}" in
        [yY]* ) 
            pull_start_containers "${project_name}" "${project_name}-gateway-1" ./docker-compose.yaml;
            break;;
        [nN]* ) 
            printf '\n On Mac, please run: \n docker compose pull && docker compose up -d'
            printf '\n In WSL, please run: \n docker-compose pull && docker-compose up -d'
            printf '\n Once the container is started, in a web browser, access the gateway at http://%s.localtest.me' "${project_name}";
            break;;
        * ) 
            printf ' Please answer y or n.';;
    esac
done

printf '\n\n\n Ignition architecture initialization finished!'
printf '\n ==================================================================== \n'