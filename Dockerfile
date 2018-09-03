FROM ruby:2.5
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /crucible
WORKDIR /crucible
COPY Gemfile /crucible/Gemfile
COPY Gemfile.lock /crucible/Gemfile.lock
RUN bundle install
COPY . /crucible
