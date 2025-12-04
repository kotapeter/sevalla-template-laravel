FROM serversideup/php:8.5-frankenphp

COPY . /var/www/html/

RUN composer install --ignore-platform-reqs
