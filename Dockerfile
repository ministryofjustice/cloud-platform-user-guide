FROM ruby:2.6.2-alpine

# These are needed to support building native extensions during
# bundle install step

ENV RUNTIME_PACKAGES "python git nodejs make"
ENV DEV_PACKAGES "py-pip python-dev musl-dev gcc ruby-dev g++ zlib-dev libffi-dev"

COPY requirements.txt /tmp/requirements.txt

RUN apk --update add --virtual build_deps build-base

# Required at runtime by middleman server
RUN apk add --no-cache nodejs

RUN apk add $DEV_PACKAGES \
  && pip install -r /tmp/requirements.txt

# Required by the CircleCI build pipeline
RUN apk add --no-cache git openssh-client bash

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN gem install bundler
RUN bundle install

RUN chown -R appuser:appgroup /app

COPY . /app

USER appuser