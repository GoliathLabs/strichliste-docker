FROM alpine:3.22.6 as release

RUN apk --no-cache add ca-certificates \
  && apk --no-cache add \
    curl \
    tar

RUN mkdir /source
WORKDIR /source
RUN curl -Lo strichliste.tar.gz https://github.com/strichliste/strichliste/releases/download/v2.1.0/strichliste-v2.1.0.tar.gz
RUN tar -xf strichliste.tar.gz
RUN rm -r strichliste.tar.gz


FROM php:8.2-fpm-alpine

RUN apk --no-cache add \
    ca-certificates \
    curl \
    nginx \
    bash \
    mysql-client \
    yarn \
  && docker-php-ext-install pdo_mysql \
  && cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

COPY --from=release /source /source

COPY entrypoint.sh /source/entrypoint.sh
RUN chmod +x /source/entrypoint.sh

RUN chown -R www-data:www-data /source /var/lib/nginx /var/log/nginx

USER www-data

COPY ./config/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/default.conf /etc/nginx/conf.d/default.conf

VOLUME /source/var

WORKDIR /source/public
EXPOSE 8080

ENTRYPOINT ["/source/entrypoint.sh"]
CMD nginx && php-fpm
