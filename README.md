[![CircleCI](https://circleci.com/gh/bitnami/bitnami-docker-phabricator/tree/master.svg?style=shield)](https://circleci.com/gh/bitnami/bitnami-docker-phabricator/tree/master)
[![Docker Hub Automated Build](http://container.checkforupdates.com/badges/bitnami/phabricator)](https://hub.docker.com/r/bitnami/phabricator/)
# What is Phabricator?

> Phabricator is a collection of open source web applications that help software companies build better software. Phabricator is built by developers for developers. Every feature is optimized around developer efficiency for however you like to work. Code Quality starts with effective collaboration between team members.

https://www.phacility.com/phabricator/

# Prerequisites

To run this application you need [Docker Engine](https://www.docker.com/products/docker-engine) >= `1.10.0`. [Docker Compose](https://www.docker.com/products/docker-compose) is recommended with a version `1.6.0` or later.

# How to use this image

Phabricator requires access to a MySQL database or MariaDB database to store information. We'll use our very own [MariaDB image](https://www.github.com/bitnami/bitnami-docker-mariadb) for the database requirements.

## Using Docker Compose

The recommended way to run Phabricator is using Docker Compose using the following `docker-compose.yml` template:

```yaml
version: '2'

services:
  mariadb:
    image: bitnami/mariadb:latest
    volumes:
      - mariadb_data:/bitnami/mariadb
  phabricator:
    image: bitnami/phabricator:latest
    depends_on:
      - mariadb
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - phabricator_data:/bitnami/phabricator
      - apache_data:/bitnami/apache

volumes:
  mariadb_data:
    driver: local
  phabricator_data:
    driver: local
  apache_data:
    driver: local
```

Launch the containers using:

```bash
$ docker-compose up -d
```

## Using the Docker Command Line

If you want to run the application manually instead of using `docker-compose`, these are the basic steps you need to run:

1. Create a network

  ```bash
  $ docker network create phabricator-tier
  ```

2. Create a volume for MariaDB persistence and create a MariaDB container

  ```bash
  $ docker volume create --name mariadb_data
  $ docker run -d --name mariadb \
    --net phabricator-tier \
    --volume mariadb_data:/bitnami/mariadb \
    bitnami/mariadb:latest
  ```

3. Create volumes for Phabricator persistence and launch the container

  ```bash
  $ docker volume create --name phabricator_data
  $ docker volume create --name apache_data
  $ docker run -d --name phabricator -p 80:80 -p 443:443 \
    --net phabricator-tier \
    --volume phabricator_data:/bitnami/phabricator \
    --volume apache_data:/bitnami/apache \
    bitnami/phabricator:latest
  ```

Access your application at <http://your-ip/>

## Persisting your application

For persistence of the Phabricator deployment, the above examples define docker volumes namely `mariadb_data`, `phabricator_data` and `apache_data`. The Phabricator application state will persist as long as these volumes are not removed.

If avoid inadvertent removal of these volumes you can [mount host directories as data volumes](https://docs.docker.com/engine/userguide/containers/dockervolumes/#mount-a-host-directory-as-a-data-volume). Alternatively you can make use of volume plugins to host the volume data.

### Mount host directories as data volumes with Docker Compose

The following `docker-compose.yml` template demonstrates the use of host directories as data volumes.

```yaml
version: '2'

services:
  mariadb:
    image: bitnami/mariadb:latest
    volumes:
      - /path/to/mariadb-persistence:/bitnami/mariadb
  phabricator:
    image: bitnami/phabricator:latest
    depends_on:
      - mariadb
    ports:
      - '80:80'
      - '443:443'
    volumes:
      - /path/to/phabricator-persistence:/bitnami/phabricator
      - /path/to/apache-persistence:/bitnami/apache
```

### Mount host directories as data volumes using the Docker command line

1. Create a network (if it does not exist)

  ```bash
  $ docker network create phabricator-tier
  ```

2. Create a MariaDB container with host volume

  ```bash
  $ docker run -d --name mariadb \
    --net phabricator-tier \
    --volume /path/to/mariadb-persistence:/bitnami/mariadb \
    bitnami/mariadb:latest
  ```

3. Create the Phabricator the container with host volumes

  ```bash
  $ docker run -d --name phabricator -p 80:80 -p 443:443 \
    --net phabricator-tier \
    --volume /path/to/phabricator-persistence:/bitnami/phabricator \
    --volume /path/to/apache-persistence:/bitnami/apache \
    bitnami/phabricator:latest
  ```

# Upgrading Phabricator

Bitnami provides up-to-date versions of MariaDB and Phabricator, including security patches, soon after they are made upstream. We recommend that you follow these steps to upgrade your container. We will cover here the upgrade of the Phabricator container. For the MariaDB upgrade see https://github.com/bitnami/bitnami-docker-mariadb/blob/master/README.md#upgrade-this-image

The `bitnami/phabricator:latest` tag always points to the most recent release. To get the most recent release you can simple repull the `latest` tag from the Docker Hub with `docker pull bitnami/phabricator:latest`. However it is recommended to use [tagged versions](https://hub.docker.com/r/bitnami/phabricator/tags/).

Get the updated image:

```
$ docker pull bitnami/phabricator:latest
```

## Using Docker Compose

1. Stop the running Phabricator container

  ```bash
  $ docker-compose stop phabricator
  ```

2. Remove the stopped container

  ```bash
  $ docker-compose rm phabricator
  ```

3. Launch the updated Phabricator image

  ```bash
  $ docker-compose start phabricator
  ```

## Using Docker command line

1. Stop the running Phabricator container

  ```bash
  $ docker stop phabricator
  ```

2. Remove the stopped container

  ```bash
  $ docker rm phabricator
  ```

3. Launch the updated Phabricator image

  ```bash
  $ docker run -d --name phabricator -p 80:80 -p 443:443 \
    --net phabricator-tier \
    --volume phabricator_data:/bitnami/phabricator \
    --volume apache_data:/bitnami/apache \
    bitnami/phabricator:latest
  ```

> **NOTE**:
>
> The above command assumes that local docker volumes are in use. Edit the command according to your usage.

# Configuration

## Environment variables

The Phabricator instance can be customized by specifying environment variables on the first run. The following environment values are provided to customize Phabricator:

- `PHABRICATOR_HOST`: Phabricator host name. Default: **127.0.0.1**
- `PHABRICATOR_USERNAME`: Phabricator application username. Default: **user**
- `PHABRICATOR_PASSWORD`: Phabricator application password. Default: **bitnami1**
- `PHABRICATOR_EMAIL`: Phabricator application email. Default: **user@example.com**
- `PHABRICATOR_FIRSTNAME`: Phabricator user first name. Default: **FirstName**
- `PHABRICATOR_LASTNAME`: Phabricator user last name. Default: **LastName**
- `MARIADB_USER`: Root user for the MariaDB database. Default: **root**
- `MARIADB_PASSWORD`: Root password for the MariaDB.
- `MARIADB_HOST`: Hostname for MariaDB server. Default: **mariadb**
- `MARIADB_PORT`: Port used by MariaDB server. Default: **3306**

### Specifying Environment variables using Docker Compose

```yaml
version: '2'

services:
  mariadb:
    image: bitnami/mariadb:latest
    volumes:
      - mariadb_data:/bitnami/mariadb
  phabricator:
    image: bitnami/phabricator:latest
    depends_on:
      - mariadb
    ports:
      - '80:80'
      - '443:443'
    environment:
      - PHABRICATOR_PASSWORD=my_password
    volumes:
      - phabricator_data:/bitnami/phabricator
      - apache_data:/bitnami/apache

volumes:
  mariadb_data:
    driver: local
  phabricator_data:
    driver: local
  apache_data:
    driver: local
```

### Specifying Environment variables on the Docker command line

```bash
$ docker run -d --name phabricator -p 80:80 -p 443:443 \
  --net phabricator-tier \
  --env PHABRICATOR_PASSWORD=my_password \
  --volume phabricator_data:/bitnami/phabricator \
  --volume apache_data:/bitnami/apache \
  bitnami/phabricator:latest
```

### SMTP Configuration

To configure phabricator to send email using SMTP you can set the following environment variables:
 - `SMTP_HOST`: SMTP host.
 - `SMTP_PORT`: SMTP port.
 - `SMTP_USER`: SMTP account user.
 - `SMTP_PASSWORD`: SMTP account password.
 - `SMTP_PROTOCOL`: SMTP protocol.

This would be an example of SMTP configuration using a GMail account:

 * docker-compose:

```
  application:
    image: bitnami/phabricator:latest
    ports:
      - 80:80
    environment:
      - SMTP_HOST=smtp.gmail.com
      - SMTP_PORT=587
      - SMTP_USER=your_email@gmail.com
      - SMTP_PASSWORD=your_password
    volumes_from:
      - application_data
```

 * For manual execution:

```
 $ docker run -d -e SMTP_HOST=smtp.gmail.com -e SMTP_PORT=587 -e SMTP_USER=your_email@gmail.com -e SMTP_PASSWORD=your_password -p 80:80 --name phabricator -v /your/local/path/bitnami/phabricator:/bitnami/phabricator --net=phabricator_network bitnami/phabricator
```

# Backing up your application

To backup your application data follow these steps:

## Backing up using Docker Compose

1. Stop the Phabricator container:

  ```bash
  $ docker-compose stop phabricator
  ```

2. Copy the Phabricator and Apache data

  ```bash
  $ docker cp $(docker-compose ps -q phabricator):/bitnami/phabricator/ /path/to/backups/phabricator/latest/
  $ docker cp $(docker-compose ps -q phabricator):/bitnami/apache/ /path/to/backups/apache/latest/
  ```

3. Start the Phabricator container

  ```bash
  $ docker-compose start phabricator
  ```

## Backing up using the Docker command line

1. Stop the Phabricator container:

  ```bash
  $ docker stop phabricator
  ```

2. Copy the Phabricator and Apache data

  ```bash
  $ docker cp phabricator:/bitnami/phabricator/ /path/to/backups/phabricator/latest/
  $ docker cp phabricator:/bitnami/apache/ /path/to/backups/apache/latest/
  ```

3. Start the Phabricator container

  ```bash
  $ docker start phabricator
  ```

# Restoring a backup

To restore your application using backed up data simply mount the folder with Phabricator and Apache data in the container. See [persisting your application](#persisting-your-application) section for more info.

# Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/bitnami/bitnami-docker-phabricator/issues), or submit a [pull request](https://github.com/bitnami/bitnami-docker-phabricator/pulls) with your contribution.

# Issues

If you encountered a problem running this container, you can file an [issue](https://github.com/bitnami/bitnami-docker-phabricator/issues). For us to provide better support, be sure to include the following information in your issue:

- Host OS and version
- Docker version (`docker version`)
- Output of `docker info`
- Version of this container (`echo $BITNAMI_IMAGE_VERSION` inside the container)
- The command you used to run the container, and any relevant output you saw (masking any sensitive information)

# License

Copyright 2016 Bitnami

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
