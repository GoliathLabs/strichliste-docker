# Stage 1: Build stage
FROM alpine:3.21.3 AS builder

RUN apk add --no-cache \
    ca-certificates \
    curl \
    tar

WORKDIR /source
RUN curl -fsSL -o strichliste.tar.gz \
    https://github.com/strichliste/strichliste/releases/download/v1.8.2/strichliste-v1.8.2.tar.gz \
    && tar -xzf strichliste.tar.gz \
    && rm strichliste.tar.gz

# Stage 2: Runtime stage
FROM alpine:3.21.3

# Install runtime dependencies
RUN apk add --no-cache \
    ca-certificates \
    nginx \
    bash \
    mysql-client \
    yarn \
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
    && rm -rf /var/cache/apk/*

# Create www-data user and set up permissions
RUN adduser -u 82 -D -S -G www-data www-data \
    && mkdir -p /var/lib/nginx /var/log/nginx /var/log/php82 \
    && chown -R www-data:www-data /var/lib/nginx /var/log/nginx /var/log/php82

# Copy application files from builder
COPY --from=builder --chown=www-data:www-data /source /source

# Copy configuration files
COPY --chown=www-data:www-data ./config/php-fpm.conf /etc/php82/php-fpm.conf
COPY --chown=www-data:www-data ./config/www.conf /etc/php82/php-fpm.d/www.conf
COPY --chown=www-data:www-data ./config/nginx.conf /etc/nginx/nginx.conf
COPY --chown=www-data:www-data ./config/default.conf /etc/nginx/conf.d/default.conf

# Copy and prepare entrypoint
COPY --chown=www-data:www-data entrypoint.sh /source/entrypoint.sh
RUN chmod +x /source/entrypoint.sh

# Set up volumes and ports
VOLUME /source/var
WORKDIR /source/public
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/ || exit 1

# Run as non-root user
USER www-data

ENTRYPOINT ["/source/entrypoint.sh"]
CMD ["sh", "-c", "nginx && php-fpm82"]
