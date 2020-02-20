FROM ruby:2.6.2-alpine

# These are needed to support building native extensions during
# bundle install step
RUN apk --update add --virtual build_deps build-base

# Required at runtime by middleman server
RUN apk add --no-cache nodejs

# Required by the CircleCI build pipeline
RUN apk add --no-cache git openssh-client bash

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler
RUN bundle install

RUN chown -R appuser:appgroup /app

COPY . /app
