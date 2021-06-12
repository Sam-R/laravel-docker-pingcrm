# Ping CRM in Docker

A demo of using Docker to run Laravel with Mix to produce production ready docker images.

## Running the docker containers

`docker-compose up -d` will build and run the Docker containers in `.docker`, one for nginx and the other for PHP-FPM.

The volume `laravel` shares the compiled node modules and Laravel source code from the PHP-FPM container with the nginx webserver.

Once the Docker containers are started run `docker-compose exec php-fpm ash` to connect to the PHP-FPM container and then run `php artisan migrate --seed` to migrate to the default `.sqlite` database.

## Goals of this Docker setup

When looking at Docker containers for running Laravel with a front end framework, all the examples I could find seemed to do a bad job and utilising Docker caching properly. They'd copy in the whole codebase early on, busting the cache and causing longer build times. This image is specifically designed to work with Laravel Mix to handle node based dependencies and build in a way that will not bust the cache for the front end build if only the PHP side has been updated.

It's also quite hard to find production ready Laravel images. This Docker file has been setup in a way that should provide a production ready setup. It does not include dev dependencies in the final Docker file, these are isolated in the multi-stage build so composer does not exist in the final image, nor does node/npm; only the compiled assets.

Due to the complexities with tightly copled front and backend code, the PHP-FPM container needs to build the node modules and share them with the front end container, which is done by a volume (which can be seen in the `docker-compose.yml` file and the `.docker/Dockerfile.*` files).

This container is not intended for development, but could be used in a CI/CD pipeline with a `--build-arg` to define it's a test environemt in order to pull in PHPunit and pconv for test code coverage.


---

# Ping CRM

A demo application to illustrate how Inertia.js works.

![](https://raw.githubusercontent.com/inertiajs/pingcrm/master/screenshot.png)

## Installation

Clone the repo locally:

```sh
git clone https://github.com/inertiajs/pingcrm.git pingcrm
cd pingcrm
```

Install PHP dependencies:

```sh
composer install
```

Install NPM dependencies:

```sh
npm ci
```

Build assets:

```sh
npm run dev
```

Setup configuration:

```sh
cp .env.example .env
```

Generate application key:

```sh
php artisan key:generate
```

Create an SQLite database. You can also use another database (MySQL, Postgres), simply update your configuration accordingly.

```sh
touch database/database.sqlite
```

Run database migrations:

```sh
php artisan migrate
```

Run database seeder:

```sh
php artisan db:seed
```

Run the dev server (the output will give the address):

```sh
php artisan serve
```

You're ready to go! Visit Ping CRM in your browser, and login with:

- **Username:** johndoe@example.com
- **Password:** secret

## Running tests

To run the Ping CRM tests, run:

```
phpunit
```
