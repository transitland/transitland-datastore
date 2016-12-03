FROM ruby:2.3.1
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client libgeos-dev
RUN mkdir /app
WORKDIR /app
ADD . /app
RUN gem install bundler -v 1.12.5
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install
