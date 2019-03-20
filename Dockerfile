FROM ruby:2.6.2-alpine

RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers \
    openssl-dev postgresql-dev libxml2-dev libxslt-dev

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY app.rb ./

RUN chown -R appuser:appgroup /app

USER appuser

CMD ["make", "server"]
