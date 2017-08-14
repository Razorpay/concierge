FROM razorpay/containers:base-nginx-php7

ARG GIT_TOKEN
ARG GIT_COMMIT_HASH
ENV GIT_COMMIT_HASH=${GIT_COMMIT_HASH}

COPY . /app/

COPY ./dockerconf/entrypoint.sh /entrypoint.sh

WORKDIR /app

RUN composer config -g github-oauth.github.com ${GIT_TOKEN} && \
    composer install --no-interaction

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]