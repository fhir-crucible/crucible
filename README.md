# Crucible Server [![Build Status](https://travis-ci.org/fhir-crucible/crucible.svg?branch=master)](https://travis-ci.org/fhir-crucible/crucible)

A simple Rails app for evaluating FHIR.

## Details ##
  - Ruby 2.0.0+
  - Rails 4.1+
  - Devise
  - Bootstrap
  - Ember CLI
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
- Install [Ember CLI](http://www.ember-cli.com/) via ```npm install -g ember-cli```

#### API Server
- Checkout Crucible: ```git clone https://github.com/fhir-crucible/crucible.git```
- Install Ruby dependencies with Bundler: ```bundle install```
- Start MongoDB: ```mongod```
- Launch the Rails server: ```bundle exec rails server```

#### Client
- Checkout Crucible Frontend (Ember CLI): ```git clone https://github.com/fhir-crucible/crucible-frontend.git```
- Install Node & Bower dependencies: ```ember install```
- Serve client via ember-cli: ```ember server --proxy http://localhost:3000```
- View application: ```http://localhost:4200```

# License

Copyright 2014 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
