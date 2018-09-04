#!/bin/bash

bower install --allow-root

if [ -f tmp/pids/server.pid ]; then
  rm tmp/pids/server.pid
fi

bundle exec rails s -p $1 -b '0.0.0.0'
