###############################################################################
# Production ready dockerfile for Laravel with Frontend
###############################################################################
# Override default arguements at build-time to change PHP version or app env
###############################################################################
# Define the app env
ARG APP_ENV=production
# Define the PHP version to use
ARG PHP_VERSION=8
# Define the composer version
ARG COMPOSER_VERSION=2

###############################################################################
# Base
###############################################################################
# Setup base Laravel box
###############################################################################
FROM php:${PHP_VERSION}-fpm-alpine as base

ARG APP_ENV

# Install Laravel dependencies not included with php-apline docker
RUN apk add --no-cache \
    libzip-dev \
    zlib-dev \
    libpng-dev \
    libwebp-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    && docker-php-ext-configure gd --enable-gd \
    && docker-php-ext-install gd pdo_mysql exif zip \
    && rm -Rf /usr/src/php/*

# If we're building a test image,
#   include pcov for test coverage reporting
RUN if [ ${APP_ENV} = 'testing' ] ; then \
    apk add --no-cache $PHPIZE_DEPS ; \
    pecl install pcov ; \
    docker-php-ext-enable pcov ; \
    fi

###############################################################################
# Composer
###############################################################################
# Layer caching enables us to create a named layer for the APP_ENV we're using
# so no dev deps are included for production.
# This could also be done as an if statement.
###############################################################################
FROM composer:${COMPOSER_VERSION} as composer-base

# Required for laravel composer install command
COPY database database/

# Copy composer.json, and .lock if it exists
COPY composer.json composer.lock* ./

FROM composer-base as vendor-production

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist \
    --no-dev \
    --optimize-autoloader

FROM composer-base as vendor-testing

RUN composer install \
    --ignore-platform-reqs \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

FROM vendor-${APP_ENV} as vendor

###############################################################################
# Node
###############################################################################
# Install NPM modules and compile
###############################################################################
FROM base as node_modules

WORKDIR /var/www/html

# Install NPM (which installs nodejs too)
RUN apk add --no-cache npm

# Package.json (and lock if it exists) are needed for installing npm
COPY package.json package-lock.json* ./

# Laravel Mix requires dev dependencies to be installed too, so you can't just run
# RUN npm install --only=production
RUN npm set progress=false && npm config set depth 0 && npm install

# Copy required files for npm run to work
COPY webpack.mix.js ./
COPY tailwind.config.js ./
COPY package*.json ./
COPY resources resources/
# Without artisan, Laravel Mix errors as it defaults to / instead of /var/www/html
COPY artisan artisan

# Compile for production and remove node modules to save space
RUN npm run production \
 && rm -Rf node_modules

###############################################################################
# Final Laravel app layer
###############################################################################
# Copy in dependencies and set permissions
###############################################################################
FROM base

ARG APP_ENV

# Copy composer installed files, creating a cache layer
COPY --from=vendor /app/vendor /var/www/html/vendor/
COPY --from=vendor /app/composer.json composer.lock* /var/www/html/
COPY --from=vendor /app/database /var/www/html/

# Copy compiled node assets
COPY --from=node_modules /var/www/html/public /var/www/html/public/

# Copy everything else
COPY . /var/www/html

# Set ownership so laravel can write to the directories
# TODO: specify only the directories laravel needs write access to
RUN chown -R www-data /var/www/html

# Laravel docs suggest running cache commands in production to improve performance
RUN if [ ${APP_ENV} = 'production' ] ; then \
    php artisan config:cache || true ; \
    php artisan route:cache || true ; \
    php artisan view:cache || true ; \
    fi

# Expose the /var/www/html directory as a volume
# This allows compiled files to be shared with the nginx container
VOLUME [ "/var/www/html" ]
