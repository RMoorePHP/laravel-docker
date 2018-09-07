FROM ubuntu:bionic

# Add S6 supervisor (for graceful stop)
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.21.1.1/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
ENTRYPOINT ["/init"]
CMD []

# Disable frontend dialogs
ENV DEBIAN_FRONTEND noninteractive
ENV PHP_VERSION 7.2
ENV FPM_PORT 9000
# Add ppa, curl and syslogd
RUN apt-get update && apt-get install -y software-properties-common curl inetutils-syslogd && \
    LC_ALL=C.UTF-8 apt-add-repository ppa:ondrej/php -y && \
    apt-get update && apt-get install -y \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-json \
    php${PHP_VERSION}-mysql \
    php-gettext \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-mbstring \
    php-ast \
    php${PHP_VERSION}-zip \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-apcu \
    zip \
    git \
    cron \
    rsyslog \
    unzip && \
    apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/php && chmod -R 755 /run/php && \
    sed -i 's|.*listen =.*|listen=${FPM_PORT}|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|.*error_log =.*|error_log=/proc/self/fd/2|g' /etc/php/${PHP_VERSION}/fpm/php-fpm.conf && \
    sed -i 's|.*access.log =.*|access.log=/proc/self/fd/2|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|.*user =.*|user=root|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's|.*group =.*|group=root|g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's#.*variables_order.*#variables_order=EGPCS#g' /etc/php/${PHP_VERSION}/fpm/php.ini && \
    sed -i 's#.*date.timezone.*#date.timezone=UTC#g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf && \
    sed -i 's#.*clear_env.*#clear_env=no#g' /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

RUN pecl channel-update pecl.php.net && pecl install xdebug-2.6.1

# Copy PHP-FPM service script
COPY start.sh /etc/services.d/php/run
RUN chmod 755 /etc/services.d/php/run

RUN curl -s http://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

RUN usermod -u 1000 www-data

RUN mkdir /app
WORKDIR /app

COPY cron /etc/cron.d/cron
RUN chmod 0644 /etc/cron.d/cron

RUN mkdir /var/www
RUN chown -R www-data:www-data /var/www
