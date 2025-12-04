FROM composer:2 AS vendor
WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --prefer-dist --no-progress --no-interaction --optimize-autoloader --no-scripts --ignore-platform-reqs

FROM node:24-alpine AS assets
WORKDIR /app

COPY . .
RUN npm ci
RUN npm run build

FROM serversideup/php:8.5-frankenphp

WORKDIR /var/www/html
USER www-data

COPY --chown=www-data:www-data . .
COPY --chown=www-data:www-data --from=vendor /app/vendor ./vendor
COPY --chown=www-data:www-data --from=assets /app/public/build ./public/build
