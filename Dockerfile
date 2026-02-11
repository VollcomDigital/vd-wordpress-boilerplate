# syntax=docker/dockerfile:1.7

ARG PHP_VERSION=8.3
ARG NGINX_VERSION=1.27

FROM composer:2 AS composer

# -----------------------------------------------------------------------------
# PHP base (extensions + runtime libs)
# -----------------------------------------------------------------------------
FROM php:${PHP_VERSION}-fpm-alpine AS php-base

RUN set -eux; \
  apk add --no-cache \
    icu-libs \
    libzip \
    libpng \
    libjpeg-turbo \
    freetype \
  ; \
  apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    icu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
  ; \
  docker-php-ext-configure gd --with-freetype --with-jpeg; \
  docker-php-ext-install -j"$(nproc)" \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    zip \
    gd \
  ; \
  pecl install redis apcu; \
  docker-php-ext-enable redis apcu opcache; \
  apk del .build-deps

# -----------------------------------------------------------------------------
# Build stage: composer install (no-dev) to produce vendor/ + web/wp
# -----------------------------------------------------------------------------
FROM php-base AS build

WORKDIR /var/www/html

COPY --from=composer /usr/bin/composer /usr/local/bin/composer

ENV COMPOSER_ALLOW_SUPERUSER=1 \
  COMPOSER_HOME=/tmp/composer

COPY composer.json composer.lock ./

RUN --mount=type=cache,target=/tmp/composer/cache \
  composer install \
    --no-dev \
    --no-interaction \
    --no-progress \
    --prefer-dist

COPY config/ config/
COPY web/ web/

# -----------------------------------------------------------------------------
# PHP runtime (non-root, production-minded)
# -----------------------------------------------------------------------------
FROM php-base AS php-runtime

WORKDIR /var/www/html

RUN addgroup -g 10001 -S app && adduser -u 10001 -S -G app app

# Replace the default pool with our socket-based pool.
RUN rm -f /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/fpm-pool.conf /usr/local/etc/php-fpm.d/zz-app.conf

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/conf.d/50-apcu.ini /usr/local/etc/php/conf.d/50-apcu.ini
COPY docker/php/conf.d/99-opcache-prod.ini /usr/local/etc/php/conf.d/99-opcache.ini

COPY --from=build --chown=app:app /var/www/html /var/www/html

# Writable paths are expected to be mounted in production:
# - /tmp (tmpfs)
# - /var/run/php (socket)
# - web/app/uploads (uploads)
# - web/app/cache (caches)
RUN mkdir -p /tmp /var/run/php /var/www/html/web/app/uploads /var/www/html/web/app/cache && \
  chown -R app:app /var/run/php /var/www/html/web/app/uploads /var/www/html/web/app/cache

USER app

EXPOSE 9000

CMD ["php-fpm", "-F"]

# -----------------------------------------------------------------------------
# PHP dev (includes Composer + dev-friendly OPcache)
# -----------------------------------------------------------------------------
FROM php-runtime AS php-dev

USER root
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
COPY docker/php/conf.d/99-opcache-dev.ini /usr/local/etc/php/conf.d/99-opcache.ini
USER app

# -----------------------------------------------------------------------------
# Nginx runtime (non-root)
# -----------------------------------------------------------------------------
FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine AS nginx-runtime

WORKDIR /var/www/html

USER root
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY docker/nginx/snippets/ /etc/nginx/snippets/
COPY --from=build --chown=101:101 /var/www/html/web /var/www/html/web
USER 101

EXPOSE 8080

# -----------------------------------------------------------------------------
# Nginx dev (same image; source is bind-mounted in Compose)
# -----------------------------------------------------------------------------
FROM nginx-runtime AS nginx-dev

