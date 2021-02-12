#!/bin/bash

while ! nc -w 10 -z web $1;
do
  echo Task runner waiting for crucible web app to load on port $1;
  sleep 10;
done;
echo Task runner starting

bin/delayed_job -n 3 start
