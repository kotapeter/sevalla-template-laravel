FROM serversideup/php:8.5-frankenphp

WORKDIR /var/www/html
USER root
COPY --chown=www-data:www-data . /var/www/html
USER www-data
RUN composer install --ignore-platform-reqs
