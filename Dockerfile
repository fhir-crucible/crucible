FROM ruby:2.5
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs npm netcat
RUN npm install bower -g

RUN mkdir /crucible
WORKDIR /crucible

COPY Gemfile ./
COPY Gemfile.lock ./
RUN bundle install

COPY . ./
