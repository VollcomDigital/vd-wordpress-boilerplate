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

RUN set -eux; \
  addgroup -g 10001 -S app; \
  adduser -u 10001 -S -G app app; \
  # Ensure the PHP user can create an FPM socket readable by the nginx-unprivileged
  # container (uid/gid 101).
  group101="$(awk -F: '$3==101{print $1; exit}' /etc/group)"; \
  if [ -z "$group101" ]; then addgroup -g 101 -S web; group101="web"; fi; \
  addgroup app "$group101" || true

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
# PHP dev (no app baked; intended for bind-mount local source)
# -----------------------------------------------------------------------------
FROM php-base AS php-dev

ARG APP_UID=1000
ARG APP_GID=1000

WORKDIR /var/www/html

RUN set -eux; \
  addgroup -g "${APP_GID}" -S app; \
  adduser -u "${APP_UID}" -S -G app app; \
  group101="$(awk -F: '$3==101{print $1; exit}' /etc/group)"; \
  if [ -z "$group101" ]; then addgroup -g 101 -S web; group101="web"; fi; \
  addgroup app "$group101" || true

RUN rm -f /usr/local/etc/php-fpm.d/www.conf
COPY docker/php/fpm-pool.conf /usr/local/etc/php-fpm.d/zz-app.conf

COPY docker/php/php.ini /usr/local/etc/php/php.ini
COPY docker/php/conf.d/50-apcu.ini /usr/local/etc/php/conf.d/50-apcu.ini
COPY docker/php/conf.d/99-opcache-dev.ini /usr/local/etc/php/conf.d/99-opcache.ini
COPY --from=composer /usr/bin/composer /usr/local/bin/composer

RUN mkdir -p /tmp /var/run/php /var/www/html/web/app/uploads /var/www/html/web/app/cache && \
  chown -R app:app /var/run/php /var/www/html/web/app/uploads /var/www/html/web/app/cache

USER app

EXPOSE 9000

CMD ["php-fpm", "-F"]

# -----------------------------------------------------------------------------
# Nginx base (non-root)
# -----------------------------------------------------------------------------
FROM nginxinc/nginx-unprivileged:${NGINX_VERSION}-alpine AS nginx-base

WORKDIR /var/www/html

USER root
COPY docker/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf
COPY docker/nginx/snippets/ /etc/nginx/snippets/
USER 101

EXPOSE 8080

# -----------------------------------------------------------------------------
# Nginx runtime (bakes Bedrock web/ for immutable deployments)
# -----------------------------------------------------------------------------
FROM nginx-base AS nginx-runtime

USER root
COPY --from=build --chown=101:101 /var/www/html/web /var/www/html/web
USER 101

# -----------------------------------------------------------------------------
# Nginx dev (no app baked; intended for bind-mount local source)
# -----------------------------------------------------------------------------
FROM nginx-base AS nginx-dev

