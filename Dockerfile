FROM razorpay/containers:base-nginx-php7

ARG GIT_COMMIT_HASH
ENV GIT_COMMIT_HASH=${GIT_COMMIT_HASH}

COPY . /app/

COPY ./dockerconf/entrypoint.sh /entrypoint.sh

RUN 'sh -c "echo $GIT_COMMIT_HASH > /app/public/commit.txt"'
RUN 'sh -c "cat /app/public/commit.txt"'

WORKDIR /app

RUN composer install --no-interaction

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
