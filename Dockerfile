FROM ruby:2.5
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm
RUN mkdir /crucible
WORKDIR /crucible
COPY Gemfile /crucible/Gemfile
COPY Gemfile.lock /crucible/Gemfile.lock
RUN bundle install
COPY . /crucible
RUN npm install bower -g
RUN bower install --allow-root
