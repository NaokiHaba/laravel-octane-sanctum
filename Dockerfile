FROM php:8.3

ARG APP_ENV=local
ENV APP_ENV=${APP_ENV}

WORKDIR /app

RUN apt-get update && apt-get install -y \
    libbrotli-dev \
    libzip-dev \
    unzip \
    default-mysql-client

RUN if [ "$APP_ENV" = "local" ]; then \
    apt-get install -y nodejs npm; \
    fi

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install pcntl zip pdo_mysql pdo

RUN pecl install swoole && docker-php-ext-enable swoole

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

COPY . .

RUN composer install --no-scripts --no-autoloader

RUN if [ "$APP_ENV" = "local" ]; then \
    npm install; \
    fi

RUN composer dump-autoload --optimize && \
    php artisan octane:install --server=swoole

RUN chown -R www-data:www-data /app && \
    chmod -R 755 /app/storage

USER www-data

EXPOSE 8000

CMD if [ "$APP_ENV" = "local" ]; then \
        php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000 --watch; \
    else \
        php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000; \
    fi
