FROM php:7.2-fpm-alpine
WORKDIR /app

# Install dev dependencies
RUN apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    curl-dev \
    libtool \
    libxml2-dev

# Install production dependencies
RUN apk add --no-cache \
    bash \
    curl \
    g++ \
    gcc \
    git \
    libc-dev \
    libpng-dev \
    make \
    mysql-client \
    rsync \
    zlib-dev \
    libzip-dev

RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install \
    curl \
    exif \
    iconv \
    mbstring \
    pdo \
    pdo_mysql \
    pcntl \
    tokenizer \
    xml \
    gd \
    zip \
    bcmath

# Install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Cleanup dev dependencies
RUN apk del -f .build-deps

COPY composer.* ./
COPY . .
RUN composer install --no-interaction --no-dev --optimize-autoloader \
    && composer clear-cache

EXPOSE 80

ENTRYPOINT [ "./dockerconf/entrypoint.sh" ]
