# Crucible Server [![Build Status](https://travis-ci.org/fhir-crucible/crucible.svg?branch=master)](https://travis-ci.org/fhir-crucible/crucible)

A simple Rails app for evaluating FHIR.

## Details ##
  - Ruby 2.0.0+
  - Rails 4.1+
  - Bootstrap
  - MongoDB
  - Bundler
  - Node
  - Bower

## Getting Started ##

### OSX ###

#### Dependencies
- Install [Homebrew](http://brew.sh/)
- Install [RVM](https://rvm.io/)
- Install Ruby 2.0.0+ via ```rvm install 2.0.0```
- Install [MongoDB](https://www.mongodb.org/) via ```brew install mongodb```
- Install [Bundler](http://bundler.io/) via ```gem install bundler```
- Install [Node](https://nodejs.org/) via ```brew install node```
- Install [Bower](http://bower.io/) via ```npm install -g bower```

#### Server
- Checkout Crucible: ```git clone https://github.com/fhir-crucible/crucible.git```
- Install Ruby dependencies with Bundler: ```bundle install```
- Install Javascript dependencies with Bower: ```bower install```
- Start MongoDB: ```mongod```
- Launch the Rails server: ```bundle exec rails server```
- Launch the Job Runner: ```RAILS_ENV=development bin/delayed_job start```

#### Testing Crucible Code
##### Ruby Tests
- Execute ```bundle exec rake test```

##### Front end tests
- Install phantomjs ```brew install phantomjs```
- Install istanbul ```npm install -g istanbul```
- Execute ```bundle exec rake teaspoon```

# License

Copyright 2015 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
