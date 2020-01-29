#!/usr/bin/with-contenv sh
set -e;

role=${CONTAINER_ROLE:-app}
env=${APP_ENV:-production}

if [ "$env" != "local" && -f /app/artisan ]; then
    echo "Caching configuration..."
    (cd /app && php artisan config:cache && php artisan route:cache && php artisan view:cache)
fi

if [ "$role" = "php" ]; then

    /usr/sbin/php-fpm${PHP_VERSION} -R --nodaemonize
    echo "running php server"

elif [ "$role" = "app" ]; then
    rsyslogd
    echo "Running cron"
    cron -f -L15

elif [ "$role" = "queue" ]; then

    echo "Queue role"
    (cd /app && php artisan horizon)

else
    echo "Could not match the container role \"$role\""
    exit 1
fi
