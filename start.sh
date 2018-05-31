    #!/usr/bin/env bash

    set -e

    role=${CONTAINER_ROLE:-app}
    env=${APP_ENV:-production}

    if [ "$env" != "local" ]; then
        echo "Caching configuration..."
        (cd /app && php artisan config:cache && php artisan route:cache && php artisan view:cache)
    fi

    if [ "$role" = "php" ]; then

        exec php-fpm
        echo "running php server"
        exit 1

    elif [ "$role" = "app" ]; then
        rsyslogd
        echo "Running cron"
        exec cron -f -L15
        exit 1

    elif [ "$role" = "queue" ]; then

        echo "Queue role"
        (cd /app && php artisan horizon)
        exit 1

    else
        echo "Could not match the container role \"$role\""
        exit 1
    fi
