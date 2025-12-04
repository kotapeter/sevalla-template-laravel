FROM serversideup/php:8.5-frankenphp

WORKDIR /var/www/html
COPY . .
RUN composer install --ignore-platform-reqs
