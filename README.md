# Bitnami Docker Image for Phabricator

## What is Phabricator?

> [Phabricator](https://www.phacility.com/phabricator/) is a collection of open source web applications that help software companies build better software. Phabricator is built by developers for developers. Every feature is optimized around developer efficiency for however you like to work. Code Quality starts with effective collaboration between team members.

## TL;DR

```console
$ curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-phabricator/master/docker-compose.yml > docker-compose.yml
$ docker-compose up -d
```

You can find the default credentials and available configuration options in the [Environment Variables](#environment-variables) section.

## Why use Bitnami Images?

* Bitnami closely tracks upstream source changes and promptly publishes new versions of this image using our automated systems.
* With Bitnami images the latest bug fixes and features are available as soon as possible.
* Bitnami containers, virtual machines and cloud images use the same components and configuration approach - making it easy to switch between formats based on your project needs.
* All our images are based on [minideb](https://github.com/bitnami/minideb) a minimalist Debian based container image which gives you a small base container image and the familiarity of a leading Linux distribution.
* All Bitnami images available in Docker Hub are signed with [Docker Content Trust (DCT)](https://docs.docker.com/engine/security/trust/content_trust/). You can use `DOCKER_CONTENT_TRUST=1` to verify the integrity of the images.
* Bitnami container images are released daily with the latest distribution packages available.

> This [CVE scan report](https://quay.io/repository/bitnami/phabricator?tab=tags) contains a security report with all open CVEs. To get the list of actionable security issues, find the "latest" tag, click the vulnerability report link under the corresponding "Security scan" field and then select the "Only show fixable" filter on the next page.

## How to deploy Phabricator in Kubernetes?

Deploying Bitnami applications as Helm Charts is the easiest way to get started with our applications on Kubernetes. Read more about the installation in the [Bitnami Phabricator Chart GitHub repository](https://github.com/bitnami/charts/tree/master/bitnami/phabricator).

Bitnami containers can be used with [Kubeapps](https://kubeapps.com/) for deployment and management of Helm Charts in clusters.

## Why use a non-root container?

Non-root container images add an extra layer of security and are generally recommended for production environments. However, because they run as a non-root user, privileged tasks are typically off-limits. Learn more about non-root containers [in our docs](https://docs.bitnami.com/tutorials/work-with-non-root-containers/).

## Supported tags and respective `Dockerfile` links

Learn more about the Bitnami tagging policy and the difference between rolling tags and immutable tags [in our documentation page](https://docs.bitnami.com/tutorials/understand-rolling-tags-containers/).


* [`2021`, `2021-debian-10`, `2021.4.0`, `2021.4.0-debian-10-r2`, `latest` (2021/debian-10/Dockerfile)](https://github.com/bitnami/bitnami-docker-phabricator/blob/2021.4.0-debian-10-r2/2021/debian-10/Dockerfile)

Subscribe to project updates by watching the [bitnami/phabricator GitHub repo](https://github.com/bitnami/bitnami-docker-phabricator).

## Get this image

The recommended way to get the Bitnami Phabricator Docker Image is to pull the prebuilt image from the [Docker Hub Registry](https://hub.docker.com/r/bitnami/phabricator).

```console
$ docker pull bitnami/phabricator:latest
```

To use a specific version, you can pull a versioned tag. You can view the [list of available versions](https://hub.docker.com/r/bitnami/phabricator/tags/) in the Docker Hub Registry.

```console
$ docker pull bitnami/phabricator:[TAG]
```

If you wish, you can also build the image yourself.

```console
$ docker build -t bitnami/phabricator:latest 'https://github.com/bitnami/bitnami-docker-phabricator.git#master:2021/debian-10'
```

## How to use this image

Phabricator requires access to a MySQL or MariaDB database to store information. We'll use the [Bitnami Docker Image for MariaDB](https://www.github.com/bitnami/bitnami-docker-mariadb) for the database requirements.

### Run the application using Docker Compose

The main folder of this repository contains a functional [`docker-compose.yml`](https://github.com/bitnami/bitnami-docker-phabricator/blob/master/docker-compose.yml) file. Run the application using it as shown below:

```console
$ curl -sSL https://raw.githubusercontent.com/bitnami/bitnami-docker-phabricator/master/docker-compose.yml > docker-compose.yml
$ docker-compose up -d
```

### Using the Docker Command Line

If you want to run the application manually instead of using `docker-compose`, these are the basic steps you need to run:

#### Step 1: Create a network

```console
$ docker network create phabricator-network
```

#### Step 2: Create a volume for MariaDB persistence and create a MariaDB container

```console
$ docker volume create --name mariadb_data
$ docker run -d --name mariadb \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --network phabricator-network \
  --volume mariadb_data:/bitnami/mariadb \
  bitnami/mariadb:latest
```

#### Step 3: Create volumes for Phabricator persistence and launch the container

```console
$ docker volume create --name phabricator_data
$ docker run -d --name phabricator \
  -p 8080:8080 -p 8443:8443 \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env PHABRICATOR_DATABASE_HOST=mariadb \
  --network phabricator-network \
  --volume phabricator_data:/bitnami/phabricator \
  bitnami/phabricator:latest
```

Access your application at *http://your-ip/*

## Persisting your application

If you remove the container all your data and configurations will be lost, and the next time you run the image the database will be reinitialized. To avoid this loss of data, you should mount a volume that will persist even after the container is removed.

For persistence you should mount a directory at the `/bitnami/phabricator` path. If the mounted directory is empty, it will be initialized on the first run. Additionally you should mount a volume for persistence of the MariaDB data](https://github.com/bitnami/bitnami-docker-mariadb#persisting-your-database).

The above examples define the Docker volumes named `mariadb_data` and `phabricator_data`. The Phabricator application state will persist as long as volumes are not removed.

To avoid inadvertent removal of volumes, you can [mount host directories as data volumes](https://docs.docker.com/engine/tutorials/dockervolumes/). Alternatively you can make use of volume plugins to host the volume data.

### Mount host directories as data volumes with Docker Compose

This requires a minor change to the [`docker-compose.yml`](https://github.com/bitnami/bitnami-docker-phabricator/blob/master/docker-compose.yml) file present in this repository:

```diff
   mariadb:
     ...
     volumes:
-      - 'mariadb_data:/bitnami/mariadb'
+      - /path/to/mariadb-persistence:/bitnami/mariadb
   ...
   phabricator:
     ...
     volumes:
-      - 'phabricator_data:/bitnami/phabricator'
+      - /path/to/phabricator-persistence:/bitnami/phabricator
   ...
-volumes:
-  mariadb_data:
-    driver: local
-  phabricator_data:
-    driver: local
```

> NOTE: As this is a non-root container, the mounted files and directories must have the proper permissions for the UID `1001`.

### Mount host directories as data volumes using the Docker command line

#### Step 1: Create a network (if it does not exist)

```console
$ docker network create phabricator-network
```

#### Step 2. Create a MariaDB container with host volume

```console
$ docker volume create --name mariadb_data
$ docker run -d --name mariadb \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --network phabricator-network \
  --volume /path/to/mariadb-persistence:/bitnami/mariadb \
  bitnami/mariadb:latest
```

#### Step 3. Create the Phabricator the container with host volumes

```console
$ docker volume create --name phabricator_data
$ docker run -d --name phabricator \
  -p 8080:8080 -p 8443:8443 \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env PHABRICATOR_DATABASE_HOST=mariadb \
  --network phabricator-network \
  --volume /path/to/phabricator-persistence:/bitnami/phabricator \
  bitnami/phabricator:latest
```

## Configuration

### Environment variables

When you start the Phabricator image, you can adjust the configuration of the instance by passing one or more environment variables either on the docker-compose file or on the `docker run` command line. If you want to add a new environment variable:

 * For docker-compose add the variable name and value under the application section in the [`docker-compose.yml`](https://github.com/bitnami/bitnami-docker-phabricator/blob/master/docker-compose.yml) file present in this repository:

```yaml
phabricator:
  ...
  environment:
    - PHABRICATOR_PASSWORD=my_password
  ...
```

 * For manual execution add a `--env` option with each variable and value:

  ```console
  $ docker run -d --name phabricator -p 80:8080 -p 443:8443 \
    --env PHABRICATOR_PASSWORD=my_password \
    --network phabricator-tier \
    --volume /path/to/phabricator-persistence:/bitnami \
    bitnami/phabricator:latest
  ```

Available environment variables:

#### User and Site configuration

- `APACHE_HTTP_PORT_NUMBER`: Port used by Apache for HTTP. Default: **8080**
- `APACHE_HTTPS_PORT_NUMBER`: Port used by Apache for HTTPS. Default: **8443**
- `PHABRICATOR_USERNAME`: Phabricator application username. Default: **user**
- `PHABRICATOR_PASSWORD`: Phabricator application password. Default: **bitnami**
- `PHABRICATOR_EMAIL`: Phabricator application email. Default: **user@example.com**
- `PHABRICATOR_FIRSTNAME`: Phabricator user first name. Default: **FirstName**
- `PHABRICATOR_LASTNAME`: Phabricator user last name. Default: **LastName**
- `PHABRICATOR_HOST`: Hostname used by Phabricator to form URLs. Default: **127.0.0.1**
- `PHABRICATOR_ALTERNATE_FILE_DOMAIN`: Alternate domain to use to upload files. No defaults.
- `PHABRICATOR_USE_LFS`: Whether to configure Phabricator to use GIT Large File Storage (LFS). Default: **no**
- `PHABRICATOR_ENABLE_GIT_SSH_REPOSITORY`: Whether to configure a self-hosted GIT repository with SSH authentication. Default: **no**
- `PHABRICATOR_SSH_PORT_NUMBER`: Port for SSH daemon. Default: **22**
- `PHABRICATOR_ENABLE_PYGMENTS`: Whether to enable syntax highlighting using Pygments. Default: **yes**
- `PHABRICATOR_SKIP_BOOTSTRAP`: Whether to skip the initial bootstrapping for the application (useful to reuse already populated databases). Default: **no**

#### Use an existing database

- `PHABRICATOR_DATABASE_HOST`: Hostname for MariaDB server. Default: **mariadb**
- `PHABRICATOR_DATABASE_PORT_NUMBER`: Port used by MariaDB server. Default: **3306**
- `PHABRICATOR_DATABASE_ADMIN_USER`: Database admin user that Phabricator will use to connect with the database server and create its required databases. Default: **root**
- `PHABRICATOR_DATABASE_ADMIN_PASSWORD`: Database admin password that Phabricator  will use to connect with the database server and create its required databases. No defaults.
- `PHABRICATOR_EXISTING_DATABASE_USER`: Existing user with privileges to modify Phabricator databases when using an already populated database server (ignored unless `PHABRICATOR_SKIP_BOOTSTRAP=yes`). No defaults.
- `PHABRICATOR_DATABASE_ADMIN_PASSWORD`: Password for the existing user mentioned above (ignored unless `PHABRICATOR_SKIP_BOOTSTRAP=yes`). No defaults.
- `ALLOW_EMPTY_PASSWORD`: It can be used to allow blank passwords. Default: **no**

#### SMTP Configuration

To configure Phabricator to send email using SMTP you can set the following environment variables:

- `PHABRICATOR_SMTP_HOST`: SMTP host.
- `PHABRICATOR_SMTP_PORT`: SMTP port.
- `PHABRICATOR_SMTP_USER`: SMTP account user.
- `PHABRICATOR_SMTP_PASSWORD`: SMTP account password.
- `PHABRICATOR_SMTP_PROTOCOL`: SMTP protocol. No defaults.

#### PHP configuration

- `PHP_MAX_EXECUTION_TIME`: Maximum execution time for PHP scripts. No default.
- `PHP_MAX_INPUT_TIME`: Maximum input time for PHP scripts. No default.
- `PHP_MAX_INPUT_VARS`: Maximum amount of input variables for PHP scripts. No default.
- `PHP_MEMORY_LIMIT`: Memory limit for PHP scripts. Default: **256M**
- `PHP_POST_MAX_SIZE`: Maximum size for PHP POST requests. No default.
- `PHP_UPLOAD_MAX_FILESIZE`: Maximum file size for PHP uploads. No default.
- `PHP_EXPOSE_PHP`: Enables HTTP header with PHP version. No default.

#### Example

This would be an example of SMTP configuration using a Gmail account:

 * Modify the [`docker-compose.yml`](https://github.com/bitnami/bitnami-docker-phabricator/blob/master/docker-compose.yml) file present in this repository:

  ```yaml
    phabricator:
      ...
      environment:
        - ALLOW_EMPTY_PASSWORD=yes
        - PHABRICATOR_SMTP_HOST=smtp.gmail.com
        - PHABRICATOR_SMTP_PORT=587
        - PHABRICATOR_SMTP_USER=your_email@gmail.com
        - PHABRICATOR_SMTP_PASSWORD=your_password
        - PHABRICATOR_SMTP_PROTOCOL=tls
    ...
  ```

 * For manual execution:

  ```console
  $ docker run -d --name phabricator -p 80:8080 -p 443:8443 \
    --ennv ALLOW_EMPTY_PASSWORD=yes \
    --env PHABRICATOR_SMTP_HOST=smtp.gmail.com \
    --env PHABRICATOR_SMTP_PORT=587 \
    --env PHABRICATOR_SMTP_USER=your_email@gmail.com \
    --env PHABRICATOR_SMTP_PASSWORD=your_password \
    --network phabricator-tier \
    --volume /path/to/phabricator-persistence:/bitnami \
    bitnami/phabricator:latest
  ```

### MySQL / MariaDB configuration

It is recommended to tune some of the default settings on the database (MariaDB or MySQL) in order to improve Phabricator performance.

If you are using the [Bitnami Docker Image for MariaDB](https://www.github.com/bitnami/bitnami-docker-mariadb), you can do it by extending the default configuration as it's explained [in this guide](https://github.com/bitnami/bitnami-docker-mariadb#configuration-file) or via environment variables as shown below.


```console
$ docker run -d --name mariadb \
  --env ALLOW_EMPTY_PASSWORD=yes \
  --env MARIADB_SQL_MODE="STRICT_ALL_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION" \
  --env MARIADB_EXTRA_FLAGS="--local-infile=0 --max-allowed-packet=32M --innodb-buffer-pool-size=256MB" \
  --network phabricator-network \
  bitnami/mariadb:latest
```

## How to migrate between Phabricator solutions

Bitnami also provides VMs and Cloud Images for Phabricator, find them in the links below:

- [Phabricator Cloud Images](https://bitnami.com/stack/phabricator/cloud)
- [PHabricator VMs](https://bitnami.com/stack/phabricator/virtual-machine)

It's possible to migrate from the the container to the VMs/CloudImages, or viceversa. To do so, follow these steps.

### Migrate from Bitnami Phabricator containers to Bitnami Phabricator VMs

1. Export the data from your Phabricator container (assuming you are running Phabricator using Docker Compose):

  ```console
  $ docker-compose exec phabricator bash -c '/opt/bitnami/phabricator/bin/storage dump | gzip > /tmp/backup-phabricator-mysql-dumps.sql.gz'
  $ docker-compose exec phabricator bash -c 'cd /bitnami/phabricator && tar cfz /tmp/backup-phabricator-data.tar.gz data'
  $ docker-compose exec phabricator bash -c 'cd /bitnami/phabricator/var && tar cfz /tmp/backup-phabricator-repo.tar.gz repo'
  $ docker cp $(docker-compose ps -q phabricator):/tmp/backup-phabricator-mysql-dumps.sql.gz $(pwd)
  $ docker cp $(docker-compose ps -q phabricator):/tmp/backup-phabricator-data.tar.gz $(pwd)
  $ docker cp $(docker-compose ps -q phabricator):/tmp/backup-phabricator-repo.tar.gz $(pwd)
  ```

2. Upload the backup files to the Phabricator VM:

  ```console
  $ scp $(pwd)/backup-phabricator-* YOUR_USERNAME@VM_HOST:~
  ```

3. Access your Phabricator VM via SSH:

  ```console
  $ ssh YOUR_USERNAME@VM_HOST
  ```

4. Stop Phabricator daemon and Apache:

  ```console
  $ sudo /opt/bitnami/ctlscript.sh stop apache
  $ sudo /opt/bitnami/ctlscript.sh stop phabricator
  ```

5. Restore and upgrade the database: (replace ROOT_PASSWORD below with your MariaDB root password)

  ```console
  $ sudo /opt/bitnami/phabricator/bin/storage destroy --force
  $ gunzip -c ~/backup-phabricator-mysql-dumps.sql.gz | mysql -uroot -pROOT_PASSWORD
  $ sudo /opt/bitnami/phabricator/bin/storage upgrade --force
  ```

6. Restore repositories and local storage files from backups:

  ```console
  $ sudo rm -rf /bitnami/phabricator/data /bitnami/phabricator/var/repo
  $ cd /bitnami/phabricator && sudo tar xfz ~/backup-phabricator-data.tar.gz
  $ cd /bitnami/phabricator/var && sudo tar xfz ~/backup-phabricator-repo.tar.gz
  ```

7. Fix Phabricator directory permissions:

  ```console
  $ sudo chown -R phabricator:phabricator /bitnami/phabricator/var/
  $ sudo chown -R daemon:daemon /bitnami/phabricator/data
  ```

8. Start Phabricator daemon and Apache again:

  ```console
  $ sudo /opt/bitnami/ctlscript.sh start phabricator
  $ sudo /opt/bitnami/ctlscript.sh start apache
  ```

### Migrate from Bitnami Phabricator VMs to Bitnami Phabricator containers

1. Create the Phabricator container as described in the section [#How to use this image (Run the application using Docker Compose)](#run-the-application-using-docker-compose)
2. Wait for the initial setup to finish. You can follow it with

  ```console
  $ docker-compose logs -f phabricator
  ```

  and press `Ctrl-C` when you see something like this:

  ```console
  phabricator 15:18:31.70 INFO  ==> ** Phabricator setup finished! **
  ...
  phabricator 15:15:19.57 INFO  ==> ** Starting Phabricator daemons **
  ...
  phabricator 15:18:31.73 INFO  ==> ** Starting Apache **
  ```

3. Access your Phabricator VM via SSH:

  ```console
  $ ssh YOUR_USERNAME@VM_HOST
  ```

4. Export the data from your VM:

  ```console
  $ /opt/bitnami/phabricator/bin/storage dump | gzip > ~/backup-phabricator-mysql-dumps.sql.gz
  $ cd /bitnami/phabricator && tar cfz ~/backup-phabricator-data.tar.gz data
  $ cd /bitnami/phabricator/var && tar cfz ~/backup-phabricator-repo.tar.gz repo
  ```

5. Copy the backup files from your VM, and then to your Phabricator container:

  ```console
  $ scp YOUR_USERNAME@TARGET_HOST:~/backup-phabricator-* $(pwd)
  $ docker cp $(pwd)/backup-phabricator-mysql-dumps.sql.gz $(docker-compose ps -q mariadb):/tmp/
  $ docker cp $(pwd)/backup-phabricator-data.tar.gz $(docker-compose ps -q phabricator):/tmp/
  $ docker cp $(pwd)/backup-phabricator-repo.tar.gz $(docker-compose ps -q phabricator):/tmp/
  ```

6. Stop Phabricator daemon:

  ```console
  $ docker-compose exec phabricator phd stop
  ```

7. Restore and upgrade the database:

  ```console
  $ docker-compose exec phabricator /opt/bitnami/phabricator/bin/storage destroy --force
  $ docker-compose exec mariadb bash -c 'gunzip -c /tmp/backup-phabricator-mysql-dumps.sql.gz | mysql -uroot -p$MARIADB_ROOT_PASSWORD'
  $ docker-compose exec mariadb rm /tmp/backup-phabricator-mysql-dumps.sql.gz
  $ docker-compose exec phabricator /opt/bitnami/phabricator/bin/storage upgrade --force
  ```

8. Restore repositories and local storage files from backups:

  ```console
  $ docker-compose exec phabricator rm -r /bitnami/phabricator/data /bitnami/phabricator/var/repo
  $ docker-compose exec phabricator bash -c 'cd /bitnami/phabricator && tar xfz /tmp/backup-phabricator-data.tar.gz'
  $ docker-compose exec phabricator bash -c 'cd /bitnami/phabricator/var && tar xfz /tmp/backup-phabricator-repo.tar.gz'
  $ docker-compose exec phabricator rm /tmp/backup-phabricator-data.tar.gz /tmp/backup-phabricator-repo.tar.gz
  ```

9. Fix Phabricator directory permissions (if running the container as "root"):

  ```console
  $ docker-compose exec phabricator chown -R phabricator:phabricator /bitnami/phabricator/var/
  $ docker-compose exec phabricator chown -R daemon:daemon /bitnami/phabricator/data
  ```

10. Restart Phabricator container:

  ```console
  $ docker-compose restart phabricator
  ```

## Logging

The Bitnami Phabricator Docker image sends the container logs to `stdout`. To view the logs:

```console
$ docker logs phabricator
```

Or using Docker Compose:

```console
$ docker-compose logs phabricator
```

You can configure the containers [logging driver](https://docs.docker.com/engine/admin/logging/overview/) using the `--log-driver` option if you wish to consume the container logs differently. In the default configuration docker uses the `json-file` driver.

## Maintenance

### Backing up your container

To backup your data, configuration and logs, follow these simple steps:

#### Step 1: Stop the currently running container

```console
$ docker stop phabricator
```

Or using Docker Compose:

```console
$ docker-compose stop phabricator
```

#### Step 2: Run the backup command

We need to mount two volumes in a container we will use to create the backup: a directory on your host to store the backup in, and the volumes from the container we just stopped so we can access the data.

```console
$ docker run --rm -v /path/to/phabricator-backups:/backups --volumes-from phabricator busybox \
  cp -a /bitnami/phabricator /backups/latest
```

### Restoring a backup

Restoring a backup is as simple as mounting the backup as volumes in the containers.

For the MariaDB database container:

```diff
 $ docker run -d --name mariadb \
   ...
-  --volume /path/to/mariadb-persistence:/bitnami/mariadb \
+  --volume /path/to/mariadb-backups/latest:/bitnami/mariadb \
   bitnami/mariadb:latest
```

For the Phabricator container:

```diff
 $ docker run -d --name phabricator \
   ...
-  --volume /path/to/phabricator-persistence:/bitnami/phabricator \
+  --volume /path/to/phabricator-backups/latest:/bitnami/phabricator \
   bitnami/phabricator:latest
```

### Upgrade this image

Bitnami provides up-to-date versions of MariaDB and Phabricator, including security patches, soon after they are made upstream. We recommend that you follow these steps to upgrade your container. We will cover here the upgrade of the Phabricator container. For the MariaDB upgrade see: https://github.com/bitnami/bitnami-docker-mariadb/blob/master/README.md#upgrade-this-image

#### Step 1: Get the updated image

```console
$ docker pull bitnami/phabricator:latest
```

#### Step 2: Stop the running container

Stop the currently running container using the command

```console
$ docker-compose stop phabricator
```

#### Step 3: Take a snapshot of the application state

Follow the steps in [Backing up your container](#backing-up-your-container) to take a snapshot of the current application state.

#### Step 4: Remove the currently running container

Remove the currently running container by executing the following command:

```console
docker-compose rm -v phabricator
```

#### Step 5: Run the new image

Update the image tag in `docker-compose.yml` and re-create your container with the new image:

```console
$ docker-compose up -d
```

## Customize this image

The Bitnami Phabricator Docker image is designed to be extended so it can be used as the base image for your custom web applications.

### Extend this image

Before extending this image, please note there are certain configuration settings you can modify using the original image:

- Settings that can be adapted using environment variables. For instance, you can change the ports used by Apache for HTTP and HTTPS, by setting the environment variables `APACHE_HTTP_PORT_NUMBER` and `APACHE_HTTPS_PORT_NUMBER` respectively.
- [Adding custom virtual hosts](https://github.com/bitnami/bitnami-docker-apache#adding-custom-virtual-hosts).
- [Replacing the 'httpd.conf' file](https://github.com/bitnami/bitnami-docker-apache#full-configuration).
- [Using custom SSL certificates](https://github.com/bitnami/bitnami-docker-apache#using-custom-ssl-certificates).

If your desired customizations cannot be covered using the methods mentioned above, extend the image. To do so, create your own image using a Dockerfile with the format below:

```Dockerfile
FROM bitnami/phabricator
## Put your customizations below
...
```

Here is an example of extending the image with the following modifications:

- Install the `vim` editor
- Modify the Apache configuration file
- Modify the ports used by Apache

```Dockerfile
FROM bitnami/phabricator
LABEL maintainer "Bitnami <containers@bitnami.com>"

## Change user to perform privileged actions
USER 0
## Install 'vim'
RUN install_packages vim
## Revert to the original non-root user
USER 1001

## Enable mod_ratelimit module
RUN sed -i -r 's/#LoadModule ratelimit_module/LoadModule ratelimit_module/' /opt/bitnami/apache/conf/httpd.conf

## Modify the ports used by Apache by default
# It is also possible to change these environment variables at runtime
ENV APACHE_HTTP_PORT_NUMBER=8181
ENV APACHE_HTTPS_PORT_NUMBER=8143
EXPOSE 8181 8143
```

Based on the extended image, you can update the [`docker-compose.yml`](https://github.com/bitnami/bitnami-docker-phabricator/blob/master/docker-compose.yml) file present in this repository to add other features:

```diff
   phabricator:
-    image: bitnami/phabricator:latest
+    build: .
     ports:
-      - '80:8080'
-      - '443:8443'
+      - '80:8181'
+      - '443:8143'
     environment:
+      - PHP_MEMORY_LIMIT=512m
     ...
```

## Notable Changes

### 2021.4.0-debian-10-r0

- The size of the container image has been decreased.
- The configuration logic is now based on Bash scripts in the *rootfs/* folder.
- The 'repo' directory is now under `/opt/bitnami/phabricator/var/repo`.
- The Phabricator container image has been migrated to a "non-root" user approach. Previously the container ran as the `root` user and the Apache daemon was started as the `daemon` while the Phabricator daemons were started as the `phabricator` user. From now on, both the container and the different daemons run as user `1001`. You can revert this behavior by changing `USER 1001` directive to `USER root` in the Dockerfile, or adding `user: root` in `docker-compose.yml`.

Consequences:

- The HTTP/HTTPS ports exposed by the container are now `8080/8443` instead of `80/443`.
- Backwards compatibility is not guaranteed when data is persisted using Docker or Docker Compose. We highly recommend migrating the Phabricator site by exporting its content, and importing it on a new Phabricator container. Follow the steps in Backing up your container and Restoring a backup to migrate the data between the old and new container.

To upgrade a previous Bitnami Phabricator container image, which did not support non-root, the easiest way is to start the new image as a root user following these steps:

- Stop Phabricator daemon and adapt the directories to the new structure:

```console
$ docker-compose exec phabricator phd stop
$ docker-compose exec phabricator mkdir /bitnami/phabricator/var/
$ docker-compose exec phabricator mv /bitnami/phabricator/repo /bitnami/phabricator/var/repo
$ docker-compose exec phabricator config set repository.default-local-path /opt/bitnami/phabricator/var/repo
$ docker-compose exec phabricator config set phd.log-directory /opt/bitnami/phabricator/var/log
```

- Update the user and port numbers in your `docker-compose.yml` file as follows:

```diff
+    user: root
+    environment:
+      - ALLOW_EMPTY_PASSWORD=yes
     ports:
-      - '80:80'
-      - '443:443'
+      - '80:8080'
+      - '443:8443'
     volumes:
```

  - Restart the containers:

```console
$ docker-compose down
$ docker-compose up
```

### 2019.21.0-debian-9-r3 and 2019.21.0-ol-7-r3

- This image has been adapted so it's easier to customize. See the [Customize this image](#customize-this-image) section for more information.
- The Apache configuration volume (`/bitnami/apache`) has been deprecated, and support for this feature will be dropped in the near future. Until then, the container will enable the Apache configuration from that volume if it exists. By default, and if the configuration volume does not exist, the configuration files will be regenerated each time the container is created. Users wanting to apply custom Apache configuration files are advised to mount a volume for the configuration at `/opt/bitnami/apache/conf`, or mount specific configuration files individually
- The PHP configuration volume (`/bitnami/php`) has been deprecated, and support for this feature will be dropped in the near future. Until then, the container will enable the PHP configuration from that volume if it exists. By default, and if the configuration volume does not exist, the configuration files will be regenerated each time the container is created. Users wanting to apply custom PHP configuration files are advised to mount a volume for the configuration at `/opt/bitnami/php/conf`, or mount specific configuration files individually.
- Enabling custom Apache certificates by placing them at `/opt/bitnami/apache/certs` has been deprecated, and support for this functionality will be dropped in the near future. Users wanting to enable custom certificates are advised to mount their certificate files on top of the preconfigured ones at `/certs`/

## Contributing

We'd love for you to contribute to this container. You can request new features by creating an [issue](https://github.com/bitnami/bitnami-docker-phabricator/issues), or submit a [pull request](https://github.com/bitnami/bitnami-docker-phabricator/pulls) with your contribution.

## Issues

If you encountered a problem running this container, you can file an [issue](https://github.com/bitnami/bitnami-docker-phabricator/issues). For us to provide better support, be sure to include the following information in your issue:

- Host OS and version
- Docker version (`docker version`)
- Output of `docker info`
- Version of this container
- The command you used to run the container, and any relevant output you saw (masking any sensitive information)

## License

Copyright (c) 2016-2021 Bitnami

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
