FROM alpine:3.21.3 as release

RUN apk --no-cache add ca-certificates \
  && apk --no-cache add \
    curl \
    tar

RUN mkdir /source
WORKDIR /source
RUN curl -Lo strichliste.tar.gz https://github.com/strichliste/strichliste/releases/download/v1.8.2/strichliste-v1.8.2.tar.gz
RUN tar -xf strichliste.tar.gz
RUN rm -r strichliste.tar.gz


FROM alpine:3.21.3

RUN apk --no-cache add ca-certificates \
  && apk --no-cache add \
    curl \
    php82 \
    php82-ctype \
    php82-tokenizer \
    php82-iconv \
    php82-mbstring \
    php82-xml \
    php82-json \
    php82-dom \
    php82-pdo_mysql \
    php82-fpm \
    php82-session \
    php82-sqlite3 \
    php82-pdo_sqlite \
    nginx \
    bash \
    mysql-client \
    yarn

COPY --from=release /source source

COPY entrypoint.sh /source/entrypoint.sh
RUN chmod +x /source/entrypoint.sh

RUN adduser -u 82 -D -S -G www-data www-data
RUN chown -R www-data:www-data /source
RUN chown -R www-data:www-data /var/lib/nginx
RUN chown -R www-data:www-data /var/log/nginx
RUN chown -R www-data:www-data /var/log/php82

USER www-data

COPY ./config/php-fpm.conf /etc/php82/php-fpm.conf
COPY ./config/www.conf /etc/php82/php-fpm.d/www.conf
COPY ./config/nginx.conf /etc/nginx/nginx.conf
COPY ./config/default.conf /etc/nginx/conf.d/default.conf

VOLUME /source/var

WORKDIR /source/public
EXPOSE 8080

ENTRYPOINT ["/source/entrypoint.sh"]
CMD nginx && php-fpm82
