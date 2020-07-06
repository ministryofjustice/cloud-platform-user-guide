FROM ruby:2.7-alpine

# These are needed to support building native extensions during
# bundle install step
RUN apk --update add --virtual build_deps build-base git

# Required at runtime by middleman
RUN apk add --no-cache nodejs

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install
