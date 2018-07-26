FROM php:7.2-fpm

RUN DEBIAN_FRONTEND=noninteractive

RUN apt-get update &&\
    apt-get install -f -y \
        apt-utils \
        git \
        cron \
        libc-client-dev \
        libkrb5-dev \
        zlib1g-dev \
        rsyslog \
    && apt-get clean \
    && apt-get autoclean -y \
    && rm -r /var/lib/apt/lists/*

RUN docker-php-ext-install pdo_mysql pcntl zip

RUN docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

RUN curl -s http://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer

RUN usermod -u 1000 www-data

RUN mkdir /app
WORKDIR /app

COPY start.sh /usr/local/bin/start
RUN chmod u+x /usr/local/bin/start

COPY cron /etc/cron.d/cron
RUN chmod 0644 /etc/cron.d/cron

CMD ["/usr/local/bin/start"]
