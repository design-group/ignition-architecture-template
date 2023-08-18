# Ignition Docker Project Template

___

## Prerequisite

Understand the process of creating docker containers using the [docker-image](https://github.com/design-group/ignition-docker).

This project assumes you have a local Traefik reverse proxy running, if not, the script will set one up or you can set one up using this repository [traefik-proxy](https://github.com/design-group/traefik-proxy)

___

## Setup

1. Follow [this guide from Github](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template) to create a new repository from the template.
1. Go the repository page on GitHub you created in the previous step and copy the clone link under Code-->HTTPS. Navigate to the folder where you want to have the code.
    ```sh
   git clone <clone link for HTTPS>
    ``` 
1. Run the initialization script from the root directory within a bash terminal in VS Code.

    ```sh
   ./initialize.sh
    ```

In a web browser, access the gateway at [http://<project-name>.localtest.me](http://<project-name>.localtest.me)
___

## Gateway Config

The gateway configuration is stored in stripped gateway backups, that have all projects removed. In order to get these backups run the following command:

```sh
bash download-gateway-backups.sh
```

The backups are stored in the `backups` directory, and if configured in the compose file will automatically restore when the container is initially created. 

If you are preparing this repository for another user, after configuration of the gateway is complete, run the above backup command, and then uncomment the volume and command listed in the `docker-compose.yaml` file.
