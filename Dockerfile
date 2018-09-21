FROM ruby:2.5.1

# Install essentials
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev postgresql-client libgeos-dev

# Setup /app
RUN mkdir /app
WORKDIR /app

# Install bundler
RUN gem install bundler -v 1.16.5

# Install gems
COPY components /app/components
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install

# Install application
COPY . /app

# Run
CMD bundle exec puma -C config/puma.rb
