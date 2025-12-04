FROM serversideup/php:8.5-frankenphp

WORKDIR /var/www/html

USER www-data
COPY --chown=www-data:www-data . /var/www/html

RUN composer install --ignore-platform-reqs
